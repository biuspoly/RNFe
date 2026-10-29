# Compara as tabelas fiscais de antes e de depois de rodar gerar_tabelas.R e escreve o resumo em Markdown
# (o texto do aviso que o robô abre no GitHub). Uso:
#   Rscript ferramentas/resumir_mudancas.R <pasta das tabelas de antes> <pasta das tabelas de depois>

argumentos = commandArgs(trailingOnly = TRUE)
pasta_de_antes = argumentos[1]
pasta_de_depois = argumentos[2]

ler_tabela = function(arquivo) {
  if (!file.exists(arquivo)) {
    return(NULL)
  }
  utils::read.csv(arquivo, colClasses = "character", fileEncoding = "UTF-8", na.strings = "")
}

# Uma linha da tabela é o código num período: o mesmo código pode ter várias linhas, uma por início.
chave_da_linha = function(tabela) {
  paste(tabela$codigo, tabela$inicio)
}

listar = function(codigos, maximo = 20) {
  if (length(codigos) == 0) {
    return("nenhum")
  }
  texto = paste(utils::head(codigos, maximo), collapse = ", ")
  if (length(codigos) > maximo) {
    texto = paste0(texto, " e mais ", length(codigos) - maximo)
  }
  texto
}

linhas_do_resumo = c("As fontes oficiais mudaram. Confira antes de juntar ao pacote.", "")
arquivos = setdiff(list.files(pasta_de_depois, pattern = "\\.csv$"), "fontes.csv")
for (arquivo in arquivos) {
  antes = ler_tabela(file.path(pasta_de_antes, arquivo))
  depois = ler_tabela(file.path(pasta_de_depois, arquivo))
  nome_da_tabela = sub("\\.csv$", "", arquivo)
  if (is.null(antes)) {
    linhas_do_resumo = c(linhas_do_resumo, paste0("- **", nome_da_tabela, "**: tabela nova, ", nrow(depois), " linhas"))
    next
  }
  if (identical(antes, depois)) {
    next
  }
  codigos_novos = setdiff(depois$codigo, antes$codigo)
  codigos_que_sairam = setdiff(antes$codigo, depois$codigo)
  chaves_de_antes = chave_da_linha(antes)
  chaves_de_depois = chave_da_linha(depois)
  em_comum = intersect(chaves_de_antes, chaves_de_depois)
  linhas_alteradas = character()
  for (chave in em_comum) {
    linha_de_antes = antes[chaves_de_antes == chave, ]
    linha_de_depois = depois[chaves_de_depois == chave, ]
    rownames(linha_de_antes) = NULL
    rownames(linha_de_depois) = NULL
    if (!identical(linha_de_antes, linha_de_depois)) {
      linhas_alteradas = c(linhas_alteradas, chave)
    }
  }
  linhas_novas = setdiff(chaves_de_depois, chaves_de_antes)
  linhas_que_sairam = setdiff(chaves_de_antes, chaves_de_depois)
  linhas_do_resumo = c(
    linhas_do_resumo,
    paste0("- **", nome_da_tabela, "**: ", nrow(antes), " linhas antes, ", nrow(depois), " depois"),
    paste0("  - códigos novos: ", listar(codigos_novos)),
    paste0("  - códigos que saíram: ", listar(codigos_que_sairam)),
    paste0("  - linhas novas (código e início): ", listar(linhas_novas)),
    paste0("  - linhas que saíram (código e início): ", listar(linhas_que_sairam)),
    paste0("  - linhas com algum campo diferente: ", listar(linhas_alteradas))
  )
}
writeLines(linhas_do_resumo)
