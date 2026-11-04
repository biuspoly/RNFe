# Grava inst/extdata/tabelas/conferencia.csv: de cada tabela, o número de linhas e a soma de conferência (md5) do
# arquivo, e a versão do conjunto (a data e a hora, em UTC, em que alguma tabela mudou). O tabelas_atualizar() baixa
# esta lista antes das tabelas, confere cada uma por ela e só usa as baixadas quando a versão delas é mais nova que a do
# pacote instalado. Uso, na raiz do repositório, depois de mexer em qualquer tabela (o gerar_tabelas.R já roda no fim):
#   Rscript ferramentas/gerar_conferencia_das_tabelas.R
# O test-tabelas.R reclama quando a lista fica para trás das tabelas.

gravar_conferencia_das_tabelas = function(pasta_das_tabelas) {
  arquivo_da_conferencia = file.path(pasta_das_tabelas, "conferencia.csv")
  arquivos_das_tabelas = sort(setdiff(list.files(pasta_das_tabelas, pattern = "\\.csv$"), "conferencia.csv"))
  linhas_de_cada = integer(length(arquivos_das_tabelas))
  for (posicao in seq_along(arquivos_das_tabelas)) {
    tabela_lida = utils::read.csv(file.path(pasta_das_tabelas, arquivos_das_tabelas[posicao]), colClasses = "character",
                                  fileEncoding = "UTF-8", na.strings = "")
    linhas_de_cada[posicao] = nrow(tabela_lida)
  }
  conferencia = data.frame(
    tabela = sub("\\.csv$", "", arquivos_das_tabelas),
    linhas = linhas_de_cada,
    md5 = unname(tools::md5sum(file.path(pasta_das_tabelas, arquivos_das_tabelas)))
  )
  # A versão só muda quando alguma tabela mudou: gravar de novo a mesma lista não faz as baixadas parecerem mais novas.
  versao_do_conjunto = format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")
  if (file.exists(arquivo_da_conferencia)) {
    conferencia_de_antes = utils::read.csv(arquivo_da_conferencia, colClasses = "character", na.strings = "")
    mesmas_tabelas = identical(paste(conferencia_de_antes$tabela, conferencia_de_antes$linhas, conferencia_de_antes$md5),
                               paste(conferencia$tabela, conferencia$linhas, conferencia$md5))
    if (mesmas_tabelas) {
      versao_do_conjunto = conferencia_de_antes$versao_do_conjunto[1]
    }
  }
  conferencia$versao_do_conjunto = versao_do_conjunto
  # Fim de linha sempre "\n", como as tabelas (a conexão binária impede o Windows de trocar por "\r\n").
  conexao_com_o_arquivo = file(arquivo_da_conferencia, open = "wb")
  utils::write.csv(conferencia, conexao_com_o_arquivo, row.names = FALSE, na = "", eol = "\n")
  close(conexao_com_o_arquivo)
  cat("conferencia  ", nrow(conferencia), "tabelas, versão do conjunto", versao_do_conjunto, "\n")
}

# Rodado sozinho (Rscript), grava a lista; lido pelo gerar_tabelas.R (source), só define a função.
if (sys.nframe() == 0) {
  gravar_conferencia_das_tabelas("inst/extdata/tabelas")
}
