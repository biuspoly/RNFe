# Roda os testes do pacote e escreve o resumo em Markdown, para o aviso do robô dos schemas (a troca pronta num ramo).
# Uso, na raiz do repositório:
#   Rscript ferramentas/testar_para_o_aviso.R <resumo.md>
# Termina com 1 quando algum teste falhou.

argumentos = commandArgs(trailingOnly = TRUE)
if (length(argumentos) != 1) {
  stop("Uso: Rscript ferramentas/testar_para_o_aviso.R <resumo.md>", call. = FALSE)
}
# Os testes que o CRAN pula (o processo separado) rodam também.
Sys.setenv(NOT_CRAN = "true")
pkgload::load_all(".", quiet = TRUE)
resultados = as.data.frame(testthat::test_dir("tests/testthat", reporter = "silent", stop_on_failure = FALSE,
                                              load_package = "none"))
com_falha = resultados[resultados$failed > 0 | resultados$error, ]
linhas = c(
  paste0("**Testes do pacote:** ", nrow(resultados), " blocos, ", sum(resultados$nb), " conferências; ",
         nrow(com_falha), " blocos com falha, ", sum(resultados$skipped), " pulados."),
  ""
)
# Até 40 blocos com falha no aviso (o texto da issue tem limite); o resto, pela quantidade.
MAXIMO_DE_BLOCOS_NO_AVISO = 40
if (nrow(com_falha) > 0) {
  mostrados = utils::head(com_falha, MAXIMO_DE_BLOCOS_NO_AVISO)
  linhas = c(linhas, "Os blocos com falha:", "", paste0("- `", mostrados$file, "`: ", mostrados$test))
  if (nrow(com_falha) > MAXIMO_DE_BLOCOS_NO_AVISO) {
    linhas = c(linhas, paste0("- e mais ", nrow(com_falha) - MAXIMO_DE_BLOCOS_NO_AVISO, " (na execução, em Actions)"))
  }
  linhas = c(linhas, "")
}
conexao = file(argumentos[1], "w", encoding = "UTF-8")
writeLines(linhas, conexao)
close(conexao)
cat(linhas, sep = "\n")
if (nrow(com_falha) > 0) {
  quit(status = 1)
}
