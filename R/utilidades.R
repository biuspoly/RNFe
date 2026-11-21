# Peças pequenas que vários arquivos usam, e as tabelas que o pacote guarda para uso próprio (os endereços da SEFAZ,
# os autorizadores de cada UF e os municípios do IBGE).

#' @include chave.R
NULL

# Cache da sessão: as tabelas internas, os schemas compilados e o que mais for lido uma vez só.
tabelas_ja_lidas = new.env(parent = emptyenv())

CODIGO_DA_UF = names(UF_PELO_CODIGO)
names(CODIGO_DA_UF) = UF_PELO_CODIGO

# Os cNF que o MOC não aceita (regra B03-10): os repetidos e as sequências.
CODIGOS_NUMERICOS_PROIBIDOS = c("00000000", "11111111", "22222222", "33333333", "44444444", "55555555", "66666666",
                                "77777777", "88888888", "99999999", "12345678", "23456789", "34567890", "45678901",
                                "56789012", "67890123", "78901234", "89012345", "90123456", "01234567")

# TRUE onde o campo veio no XML com algum conteúdo.
informado = function(textos) {
  !is.na(textos) & textos != ""
}

codigo_da_uf = function(ufs) {
  unname(CODIGO_DA_UF[ufs])
}

texto_da_data = function(datas) {
  textos = format(datas, "%d/%m/%Y")
  textos[is.na(datas)] = "(vazio)"
  textos
}

# Uma tabela de inst/extdata/tabelas, lida uma vez por sessão, toda em texto.
tabela_interna = function(nome_da_tabela) {
  if (is.null(tabelas_ja_lidas[[nome_da_tabela]])) {
    arquivo_csv = system.file("extdata", "tabelas", paste0(nome_da_tabela, ".csv"), package = "RNFe")
    tabelas_ja_lidas[[nome_da_tabela]] = utils::read.csv(arquivo_csv, colClasses = "character", fileEncoding = "UTF-8",
                                                         na.strings = "")
  }
  tabelas_ja_lidas[[nome_da_tabela]]
}
