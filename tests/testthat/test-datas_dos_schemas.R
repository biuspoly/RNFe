# O robô dos schemas só troca um arquivo de inst/schemas pelo de data mais nova, pela tabela de
# ferramentas/datas_dos_schemas.csv: ela tem de ter cada arquivo, com o conteúdo de hoje. As ferramentas não vão no
# pacote, então o teste roda só no repositório.
test_that("cada schema de inst/schemas está em ferramentas/datas_dos_schemas.csv, com o conteúdo de hoje", {
  tabela_das_datas = test_path("..", "..", "ferramentas", "datas_dos_schemas.csv")
  skip_if_not(file.exists(tabela_das_datas), "as ferramentas ficam só no repositório")
  datas = utils::read.csv(tabela_das_datas, colClasses = "character", encoding = "UTF-8")
  pasta_dos_schemas = system.file("schemas", package = "RNFe")
  arquivos = list.files(pasta_dos_schemas, pattern = "\\.xsd$", recursive = TRUE)
  na_tabela = paste(datas$pasta, datas$arquivo, sep = "/")
  expect_setequal(na_tabela, arquivos)
  md5_de_hoje = unname(tools::md5sum(file.path(pasta_dos_schemas, na_tabela)))
  expect_identical(datas$md5, md5_de_hoje)
  expect_true(all(grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$", datas$data)))
})
