# Compara as tabelas fiscais de antes e de depois de rodar gerar_tabelas.R e escreve o resumo em Markdown
# (o texto do aviso que o robô abre no GitHub). Uso:
#   Rscript ferramentas/resumir_mudancas.R <pasta das tabelas de antes> <pasta das tabelas de depois>

argumentos = commandArgs(trailingOnly = TRUE)
pasta_de_antes = argumentos[1]
pasta_de_depois = argumentos[2]

ler_tabela_gravada = function(arquivo_csv) {
  if (!file.exists(arquivo_csv)) {
    return(NULL)
  }
  utils::read.csv(arquivo_csv, colClasses = "character", fileEncoding = "UTF-8", na.strings = "")
}

# Uma linha da tabela é o código num período: o mesmo código pode ter várias linhas, uma por início. A tabela sem
# código (os endereços dos serviços da SEFAZ) é comparada pela linha inteira.
identificacao_de_cada_linha = function(tabela_gravada) {
  if (!("codigo" %in% names(tabela_gravada))) {
    return(do.call(paste, c(as.list(tabela_gravada), sep = " | ")))
  }
  paste(tabela_gravada$codigo, tabela_gravada$inicio)
}

# Os códigos separados por vírgula, no máximo 20, dizendo quantos ficaram de fora.
listar_codigos = function(codigos, maximo_na_lista = 20) {
  if (length(codigos) == 0) {
    return("nenhum")
  }
  codigos_listados = paste(utils::head(codigos, maximo_na_lista), collapse = ", ")
  if (length(codigos) > maximo_na_lista) {
    codigos_listados = paste0(codigos_listados, " e mais ", length(codigos) - maximo_na_lista)
  }
  codigos_listados
}

linhas_do_resumo = c("As fontes oficiais mudaram. Confira antes de juntar ao pacote.", "")
arquivos_das_tabelas = setdiff(list.files(pasta_de_depois, pattern = "\\.csv$"), "fontes.csv")
for (arquivo_da_tabela in arquivos_das_tabelas) {
  tabela_de_antes = ler_tabela_gravada(file.path(pasta_de_antes, arquivo_da_tabela))
  tabela_de_depois = ler_tabela_gravada(file.path(pasta_de_depois, arquivo_da_tabela))
  nome_da_tabela = sub("\\.csv$", "", arquivo_da_tabela)
  if (is.null(tabela_de_antes)) {
    linhas_do_resumo = c(linhas_do_resumo, paste0("- **", nome_da_tabela, "**: tabela nova, ", nrow(tabela_de_depois), " linhas"))
    next
  }
  if (identical(tabela_de_antes, tabela_de_depois)) {
    next
  }
  codigos_novos = setdiff(tabela_de_depois$codigo, tabela_de_antes$codigo)
  codigos_que_sairam = setdiff(tabela_de_antes$codigo, tabela_de_depois$codigo)
  linhas_de_antes = identificacao_de_cada_linha(tabela_de_antes)
  linhas_de_depois = identificacao_de_cada_linha(tabela_de_depois)
  linhas_nas_duas = intersect(linhas_de_antes, linhas_de_depois)
  linhas_alteradas = character()
  for (identificacao_da_linha in linhas_nas_duas) {
    linha_de_antes = tabela_de_antes[linhas_de_antes == identificacao_da_linha, ]
    linha_de_depois = tabela_de_depois[linhas_de_depois == identificacao_da_linha, ]
    rownames(linha_de_antes) = NULL
    rownames(linha_de_depois) = NULL
    if (!identical(linha_de_antes, linha_de_depois)) {
      linhas_alteradas = c(linhas_alteradas, identificacao_da_linha)
    }
  }
  linhas_novas = setdiff(linhas_de_depois, linhas_de_antes)
  linhas_que_sairam = setdiff(linhas_de_antes, linhas_de_depois)
  if (!("codigo" %in% names(tabela_de_depois))) {
    linhas_do_resumo = c(
      linhas_do_resumo,
      paste0("- **", nome_da_tabela, "**: ", nrow(tabela_de_antes), " linhas antes, ", nrow(tabela_de_depois), " depois"),
      paste0("  - linhas novas: ", listar_codigos(linhas_novas)),
      paste0("  - linhas que saíram: ", listar_codigos(linhas_que_sairam))
    )
    next
  }
  linhas_do_resumo = c(
    linhas_do_resumo,
    paste0("- **", nome_da_tabela, "**: ", nrow(tabela_de_antes), " linhas antes, ", nrow(tabela_de_depois), " depois"),
    paste0("  - códigos novos: ", listar_codigos(codigos_novos)),
    paste0("  - códigos que saíram: ", listar_codigos(codigos_que_sairam)),
    paste0("  - linhas novas (código e início): ", listar_codigos(linhas_novas)),
    paste0("  - linhas que saíram (código e início): ", listar_codigos(linhas_que_sairam)),
    paste0("  - linhas com algum campo diferente: ", listar_codigos(linhas_alteradas))
  )
}
writeLines(linhas_do_resumo)
