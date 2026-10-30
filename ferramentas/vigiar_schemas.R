# Olha as listas de schemas dos portais da NF-e, do CT-e e do MDF-e e escreve um aviso para cada publicação
# que ainda não está em ferramentas/schemas_vistos.csv. Uso, na raiz do repositório:
#   Rscript ferramentas/vigiar_schemas.R <pasta dos avisos>
#   Rscript ferramentas/vigiar_schemas.R --registrar
# Cada aviso é um arquivo .md: a primeira linha é o título, o resto é o texto. Quando a publicação traz o
# schema principal do documento (o de schemas_usados.csv), o aviso diz os campos que entraram, que saíram e
# que mudaram de regra em relação ao pacote que o RNfe segue. O robô (.github/workflows/vigiar-schemas.yml)
# abre um aviso (issue) por arquivo. "--registrar" grava em schemas_vistos.csv tudo o que os portais listam
# hoje: rodar depois de atualizar os leitores para um pacote novo.
# Termina com erro quando algum portal não respondeu, depois de escrever os avisos dos outros.

source("ferramentas/schemas.R", encoding = "UTF-8")

NOME_DO_DOCUMENTO = c(nfe = "NF-e", cte = "CT-e", mdfe = "MDF-e")
# O texto da issue tem limite (65.536 caracteres); a lista de campos para antes.
TAMANHO_MAXIMO_DO_AVISO = 60000

listar_todos_os_portais = function(pasta_temporaria) {
  publicacoes = data.frame(documento = character(), titulo = character(), endereco = character())
  erros = character()
  for (documento in names(PAGINA_DOS_SCHEMAS)) {
    do_portal = tryCatch(listar_publicacoes(documento, pasta_temporaria), error = function(erro) erro)
    if (inherits(do_portal, "error")) {
      erros = c(erros, paste0(NOME_DO_DOCUMENTO[[documento]], ": ", conditionMessage(do_portal)))
    } else {
      publicacoes = rbind(publicacoes, do_portal)
    }
  }
  list(publicacoes = publicacoes, erros = erros)
}

# Uma linha de lista em Markdown para cada campo, com o caminho e as regras entre crases.
linhas_dos_campos = function(caminhos, regras) {
  if (length(caminhos) == 0) {
    return(character())
  }
  paste0("- `", caminhos, "`: `", ifelse(regras == "", "(sem regra)", regras), "`")
}

texto_das_diferencas = function(diferencas) {
  linhas = c(
    paste0("**Campos que entraram (", nrow(diferencas$entraram), "):**"),
    "",
    linhas_dos_campos(diferencas$entraram$caminho, diferencas$entraram$regras),
    "",
    paste0("**Campos que saíram (", nrow(diferencas$sairam), "):**"),
    "",
    linhas_dos_campos(diferencas$sairam$caminho, diferencas$sairam$regras),
    "",
    paste0("**Campos que mudaram de regra (", nrow(diferencas$mudaram), "):**"),
    ""
  )
  if (nrow(diferencas$mudaram) > 0) {
    linhas = c(linhas, paste0("- `", diferencas$mudaram$caminho, "`\n  - antes: `", diferencas$mudaram$antes,
                              "`\n  - agora: `", diferencas$mudaram$agora, "`"))
  }
  linhas
}

# Corta o texto quando passa do tamanho que a issue aceita, dizendo quantas linhas ficaram de fora.
cortar_texto = function(linhas) {
  tamanho_acumulado = cumsum(nchar(linhas) + 1)
  cabem = tamanho_acumulado <= TAMANHO_MAXIMO_DO_AVISO
  if (all(cabem)) {
    return(linhas)
  }
  c(linhas[cabem], "", paste0("(... mais ", sum(!cabem), " linhas: rode ferramentas/vigiar_schemas.R para ver tudo)"))
}

escrever_aviso = function(publicacao, usado, campos_usados, pasta_temporaria, pasta_dos_avisos, numero) {
  nome = NOME_DO_DOCUMENTO[[publicacao$documento]]
  titulo = substr(paste0("Schema novo no portal do ", nome, ": ", publicacao$titulo), 1, 250)
  linhas = c(
    titulo,
    paste0("O portal do ", nome, " publicou: **", publicacao$titulo, "**"),
    "",
    paste0("Endereço: ", publicacao$endereco),
    "",
    paste0("O RNfe segue hoje: ", usado$titulo, "."),
    ""
  )
  pasta_do_pacote = tryCatch(baixar_pacote(publicacao$documento, publicacao$endereco, pasta_temporaria), error = function(erro) erro)
  if (inherits(pasta_do_pacote, "error")) {
    linhas = c(linhas, paste0("Não deu para baixar o arquivo: ", conditionMessage(pasta_do_pacote)))
  } else {
    pasta_do_schema = pasta_do_arquivo(pasta_do_pacote, usado$arquivo_principal)
    if (is.na(pasta_do_schema)) {
      linhas = c(linhas, paste0("A publicação não traz o `", usado$arquivo_principal, "`: é de eventos, de ",
                                "outro serviço ou de outro documento. Confira se ela afeta algum leitor do RNfe."))
    } else {
      campos_novos = campos_do_schema(pasta_do_schema, O_QUE_COMPARAR[[publicacao$documento]])
      linhas = c(linhas, paste0("Comparado com o pacote que o RNfe segue (", paste(O_QUE_COMPARAR[[publicacao$documento]], collapse = ", "), "):"),
                 "", texto_das_diferencas(comparar_campos(campos_usados, campos_novos)))
    }
  }
  linhas = c(linhas, "", paste0(
    "O que fazer: conferir a nota técnica, atualizar o leitor (`R/", publicacao$documento, "_ler.R`), os exemplos e ",
    "`ferramentas/schemas_usados.csv`, validar com `ferramentas/validar_exemplos.R` e rodar ",
    "`Rscript ferramentas/vigiar_schemas.R --registrar`. Se a publicação não muda nada no RNfe, só o último passo."
  ))
  linhas = cortar_texto(linhas)
  arquivo = file.path(pasta_dos_avisos, sprintf("%03d.md", numero))
  conexao = file(arquivo, "w", encoding = "UTF-8")
  writeLines(linhas, conexao)
  close(conexao)
  titulo
}

if (sys.nframe() == 0) {
  argumentos = commandArgs(trailingOnly = TRUE)
  if (length(argumentos) != 1) {
    stop("Informe a pasta dos avisos, ou --registrar", call. = FALSE)
  }
  pasta_temporaria = file.path(tempdir(), "vigia")
  dir.create(pasta_temporaria, showWarnings = FALSE)
  listado = listar_todos_os_portais(pasta_temporaria)

  if (argumentos[1] == "--registrar") {
    if (length(listado$erros) > 0) {
      stop("Algum portal não respondeu, nada foi gravado: ", paste(listado$erros, collapse = "; "), call. = FALSE)
    }
    gravar_csv(listado$publicacoes, SCHEMAS_VISTOS)
    cat(nrow(listado$publicacoes), "publicações gravadas em", SCHEMAS_VISTOS, "\n")
  } else {
    pasta_dos_avisos = argumentos[1]
    dir.create(pasta_dos_avisos, showWarnings = FALSE, recursive = TRUE)
    vistos = ler_csv(SCHEMAS_VISTOS)
    usados = ler_csv(SCHEMAS_USADOS)
    ja_vistas = paste(vistos$documento, vistos$titulo, vistos$endereco)
    novas = listado$publicacoes[!(paste(listado$publicacoes$documento, listado$publicacoes$titulo, listado$publicacoes$endereco) %in% ja_vistas), ]
    cat(nrow(listado$publicacoes), "publicações nos portais,", nrow(novas), "novas\n")

    # Os campos do pacote que cada leitor segue, baixado uma vez só por documento.
    campos_usados_por_documento = list()
    for (numero in seq_len(nrow(novas))) {
      publicacao = novas[numero, ]
      usado = usados[usados$documento == publicacao$documento, ]
      if (is.null(campos_usados_por_documento[[publicacao$documento]])) {
        pasta_usada = pasta_do_arquivo(baixar_pacote(usado$documento, usado$endereco, pasta_temporaria), usado$arquivo_principal)
        campos_usados_por_documento[[publicacao$documento]] = campos_do_schema(pasta_usada, O_QUE_COMPARAR[[publicacao$documento]])
      }
      titulo = escrever_aviso(publicacao, usado, campos_usados_por_documento[[publicacao$documento]], pasta_temporaria, pasta_dos_avisos, numero)
      cat("aviso:", titulo, "\n")
    }
    if (length(listado$erros) > 0) {
      cat("Portais que não responderam:\n", paste0("  ", listado$erros, "\n"), sep = "")
      quit(status = 1)
    }
  }
}
