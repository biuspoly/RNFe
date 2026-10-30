# Olha as listas de schemas dos portais da NF-e, do CT-e, do MDF-e e da NFS-e Nacional e escreve um aviso
# para cada publicação que ainda não está em ferramentas/schemas_vistos.csv. Uso, na raiz do repositório:
#   Rscript ferramentas/vigiar_schemas.R <pasta dos avisos>
#   Rscript ferramentas/vigiar_schemas.R --registrar
# Cada aviso é um arquivo .md: a primeira linha é o título, o resto é o texto. Quando a publicação traz o
# schema principal do documento (o de schemas_usados.csv), o aviso diz os campos que entraram, que saíram e
# que mudaram de regra em relação ao pacote que o RNFe segue. O robô (.github/workflows/vigiar-schemas.yml)
# abre um aviso (issue) por arquivo. "--registrar" grava em schemas_vistos.csv tudo o que os portais listam
# hoje: rodar depois de atualizar os leitores para um pacote novo.
# Termina com erro quando algum portal não respondeu, depois de escrever os avisos dos outros.

source("ferramentas/schemas.R", encoding = "UTF-8")

NOME_DO_PORTAL = c(nfe = "portal da NF-e", cte = "portal do CT-e", mdfe = "portal do MDF-e", nfse = "portal da NFS-e Nacional")
# O texto da issue tem limite (65.536 caracteres); a lista de campos para antes.
TAMANHO_MAXIMO_DO_AVISO = 60000

listar_todos_os_portais = function(pasta_temporaria) {
  publicacoes = data.frame(documento = character(), titulo = character(), endereco = character())
  portais_com_erro = character()
  for (documento in names(PAGINA_DOS_SCHEMAS)) {
    publicacoes_do_portal = tryCatch(listar_publicacoes(documento, pasta_temporaria), error = function(erro) erro)
    if (inherits(publicacoes_do_portal, "error")) {
      portais_com_erro = c(portais_com_erro, paste0(NOME_DO_PORTAL[[documento]], ": ", conditionMessage(publicacoes_do_portal)))
    } else {
      publicacoes = rbind(publicacoes, publicacoes_do_portal)
    }
  }
  list(publicacoes = publicacoes, portais_com_erro = portais_com_erro)
}

# Uma linha de lista em Markdown para cada campo, com o caminho e as regras entre crases.
linhas_dos_campos = function(caminhos, regras) {
  if (length(caminhos) == 0) {
    return(character())
  }
  paste0("- `", caminhos, "`: `", ifelse(regras == "", "(sem regra)", regras), "`")
}

texto_das_diferencas = function(diferencas) {
  linhas_do_texto = c(
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
    linhas_do_texto = c(linhas_do_texto, paste0("- `", diferencas$mudaram$caminho, "`\n  - antes: `", diferencas$mudaram$antes,
                                                "`\n  - agora: `", diferencas$mudaram$agora, "`"))
  }
  linhas_do_texto
}

# Corta o texto quando passa do tamanho que a issue aceita, dizendo quantas linhas ficaram de fora.
cortar_texto = function(linhas_do_aviso) {
  tamanho_ate_cada_linha = cumsum(nchar(linhas_do_aviso) + 1)
  linhas_que_cabem = tamanho_ate_cada_linha <= TAMANHO_MAXIMO_DO_AVISO
  if (all(linhas_que_cabem)) {
    return(linhas_do_aviso)
  }
  c(linhas_do_aviso[linhas_que_cabem], "",
    paste0("(... mais ", sum(!linhas_que_cabem), " linhas: rode ferramentas/vigiar_schemas.R para ver tudo)"))
}

escrever_aviso = function(publicacao, pacote_usado, campos_do_pacote_usado, pasta_temporaria, pasta_dos_avisos, numero_do_aviso) {
  nome_do_portal = NOME_DO_PORTAL[[publicacao$documento]]
  titulo_do_aviso = substr(paste0("Schema novo no ", nome_do_portal, ": ", publicacao$titulo), 1, 250)
  linhas_do_aviso = c(
    titulo_do_aviso,
    paste0("O ", nome_do_portal, " publicou: **", publicacao$titulo, "**"),
    "",
    paste0("Endereço: ", publicacao$endereco),
    "",
    paste0("O RNFe segue hoje: ", pacote_usado$titulo, "."),
    ""
  )
  pasta_do_pacote_novo = tryCatch(baixar_pacote(publicacao$documento, publicacao$endereco, pasta_temporaria), error = function(erro) erro)
  if (inherits(pasta_do_pacote_novo, "error")) {
    linhas_do_aviso = c(linhas_do_aviso, paste0("Não deu para baixar o arquivo: ", conditionMessage(pasta_do_pacote_novo)))
  } else if (is.na(pasta_do_pacote_novo)) {
    # O gov.br devolve uma página de "Conteúdo Restrito" no lugar do arquivo da área de produção restrita.
    linhas_do_aviso = c(linhas_do_aviso, paste0("O endereço não devolveu um arquivo .zip (pode ser uma página de acesso restrito): ",
                                                "abra o endereço e confira à mão."))
  } else {
    arquivo_principal_novo = arquivo_na_versao_mais_nova(pasta_do_pacote_novo, pacote_usado$arquivo_principal)
    if (is.na(arquivo_principal_novo)) {
      linhas_do_aviso = c(linhas_do_aviso, paste0("A publicação não traz o `", pacote_usado$arquivo_principal, "` (nem em outra versão): ",
                                                  "é de eventos, de outro serviço ou de outro documento. Confira se ela afeta algum leitor do RNFe."))
    } else {
      o_que_comparar = O_QUE_COMPARAR[[publicacao$documento]]
      campos_do_pacote_novo = campos_do_schema(dirname(arquivo_principal_novo), o_que_comparar)
      linhas_do_aviso = c(linhas_do_aviso, paste0("Comparado com o pacote que o RNFe segue (", paste(o_que_comparar, collapse = ", "),
                                                  "), pelo `", basename(arquivo_principal_novo), "` da publicação:"),
                          "", texto_das_diferencas(comparar_campos(campos_do_pacote_usado, campos_do_pacote_novo)))
    }
  }
  linhas_do_aviso = c(linhas_do_aviso, "", paste0(
    "O que fazer: conferir a nota técnica, atualizar o leitor (`R/", publicacao$documento, "_ler.R`), os exemplos e ",
    "`ferramentas/schemas_usados.csv`, validar com `ferramentas/validar_exemplos.R` e rodar ",
    "`Rscript ferramentas/vigiar_schemas.R --registrar`. Se a publicação não muda nada no RNFe, só o último passo."
  ))
  linhas_do_aviso = cortar_texto(linhas_do_aviso)
  arquivo_do_aviso = file.path(pasta_dos_avisos, sprintf("%03d.md", numero_do_aviso))
  conexao_com_o_arquivo = file(arquivo_do_aviso, "w", encoding = "UTF-8")
  writeLines(linhas_do_aviso, conexao_com_o_arquivo)
  close(conexao_com_o_arquivo)
  titulo_do_aviso
}

# Este bloco só roda quando o script é chamado pelo Rscript; quando outro script o carrega com source(), só
# as funções acima ficam disponíveis.
if (sys.nframe() == 0) {
  argumentos = commandArgs(trailingOnly = TRUE)
  if (length(argumentos) != 1) {
    stop("Informe a pasta dos avisos, ou --registrar", call. = FALSE)
  }
  pasta_temporaria = file.path(tempdir(), "vigia")
  dir.create(pasta_temporaria, showWarnings = FALSE)
  listagem_dos_portais = listar_todos_os_portais(pasta_temporaria)

  if (argumentos[1] == "--registrar") {
    if (length(listagem_dos_portais$portais_com_erro) > 0) {
      stop("Algum portal não respondeu, nada foi gravado: ", paste(listagem_dos_portais$portais_com_erro, collapse = "; "), call. = FALSE)
    }
    gravar_csv(listagem_dos_portais$publicacoes, SCHEMAS_VISTOS)
    cat(nrow(listagem_dos_portais$publicacoes), "publicações gravadas em", SCHEMAS_VISTOS, "\n")
  } else {
    pasta_dos_avisos = argumentos[1]
    dir.create(pasta_dos_avisos, showWarnings = FALSE, recursive = TRUE)
    publicacoes_vistas = ler_csv(SCHEMAS_VISTOS)
    pacotes_usados = ler_csv(SCHEMAS_USADOS)
    publicacoes_nos_portais = listagem_dos_portais$publicacoes
    identificacao_das_vistas = paste(publicacoes_vistas$documento, publicacoes_vistas$titulo, publicacoes_vistas$endereco)
    identificacao_das_listadas = paste(publicacoes_nos_portais$documento, publicacoes_nos_portais$titulo, publicacoes_nos_portais$endereco)
    publicacoes_novas = publicacoes_nos_portais[!(identificacao_das_listadas %in% identificacao_das_vistas), ]
    cat(nrow(publicacoes_nos_portais), "publicações nos portais,", nrow(publicacoes_novas), "novas\n")

    # Os campos do pacote que cada leitor segue, baixado uma vez só por documento.
    campos_usados_por_documento = list()
    for (numero_da_publicacao in seq_len(nrow(publicacoes_novas))) {
      publicacao = publicacoes_novas[numero_da_publicacao, ]
      pacote_usado = pacotes_usados[pacotes_usados$documento == publicacao$documento, ]
      if (is.null(campos_usados_por_documento[[publicacao$documento]])) {
        pasta_do_pacote_usado = baixar_pacote(pacote_usado$documento, pacote_usado$endereco, pasta_temporaria)
        pasta_do_schema_usado = pasta_do_arquivo(pasta_do_pacote_usado, pacote_usado$arquivo_principal)
        campos_usados_por_documento[[publicacao$documento]] = campos_do_schema(pasta_do_schema_usado, O_QUE_COMPARAR[[publicacao$documento]])
      }
      titulo_do_aviso = escrever_aviso(publicacao, pacote_usado, campos_usados_por_documento[[publicacao$documento]],
                                       pasta_temporaria, pasta_dos_avisos, numero_da_publicacao)
      cat("aviso:", titulo_do_aviso, "\n")
    }
    if (length(listagem_dos_portais$portais_com_erro) > 0) {
      cat("Portais que não responderam:\n", paste0("  ", listagem_dos_portais$portais_com_erro, "\n"), sep = "")
      quit(status = 1)
    }
  }
}
