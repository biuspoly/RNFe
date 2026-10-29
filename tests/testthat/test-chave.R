# Chaves de exemplo: o dígito foi calculado à parte, com os algoritmos dos anexos I e II da
# NT Conjunta 2025.001. CNPJs e CPF fictícios (o 12.ABC.345/01DE-35 é o exemplo da Receita).
NFE_SP = "35261011444777000161550010000001231123456783"
NFE_CNPJ_COM_LETRAS = "35261012ABC34501DE35550010000001231123456784"
NFCE_CE_CONTINGENCIA = "23260711222333000181650020000045679876543218"
CTE_RS_EMITENTE_CPF = "43260100012345678909570010000000421000000017"
MDFE_BA = "29251211222333000181580010000000011135792461"
CHAVES_VALIDAS = c(NFE_SP, NFE_CNPJ_COM_LETRAS, NFCE_CE_CONTINGENCIA, CTE_RS_EMITENTE_CPF, MDFE_BA)

test_that("chaves certas passam", {
  expect_identical(chave_valida(CHAVES_VALIDAS), rep(TRUE, 5))
  expect_identical(chave_digito(substr(CHAVES_VALIDAS, 1, 43)), c(3L, 4L, 8L, 7L, 1L))
})

test_that("as partes da chave", {
  partes = chave_decompor(NFE_SP)
  expect_identical(partes$uf, "SP")
  expect_identical(partes$codigo_uf, "35")
  expect_identical(partes$ano, 2026L)
  expect_identical(partes$mes, 10L)
  expect_identical(partes$documento_emitente, "11444777000161")
  expect_identical(partes$tipo_documento, "CNPJ")
  expect_identical(partes$modelo, "55")
  expect_identical(partes$documento, "NF-e")
  expect_identical(partes$serie, 1L)
  expect_identical(partes$numero, 123L)
  expect_identical(partes$forma_emissao, 1L)
  expect_identical(partes$codigo_numerico, "12345678")
  expect_identical(partes$digito, 3L)
  expect_true(is.na(partes$problema))
})

test_that("CNPJ com letras, CPF no lugar do CNPJ e os outros modelos", {
  partes = chave_decompor(c(NFE_CNPJ_COM_LETRAS, CTE_RS_EMITENTE_CPF, NFCE_CE_CONTINGENCIA, MDFE_BA))
  expect_identical(partes$documento_emitente[1], "12ABC34501DE35")
  expect_identical(partes$tipo_documento, c("CNPJ", "CPF", "CNPJ", "CNPJ"))
  expect_identical(partes$documento, c("NF-e", "CT-e", "NFC-e", "MDF-e"))
  expect_identical(partes$forma_emissao[3], 9L)
  expect_identical(partes$ano[4], 2025L)
})

test_that("espa\u00e7os, min\u00fasculas e o prefixo do Id do XML s\u00e3o ignorados", {
  com_espacos = "3526 1011 4447 7700 0161 5500 1000 0001 2311 2345 6783"
  expect_identical(chave_decompor(com_espacos)$chave, NFE_SP)
  expect_true(chave_valida(paste0("NFe", NFE_SP)))
  expect_true(chave_valida(tolower(NFE_CNPJ_COM_LETRAS)))
})

test_that("chave errada diz o que est\u00e1 errado", {
  digito_trocado = paste0(substr(NFE_SP, 1, 43), "4")
  partes = chave_decompor(digito_trocado)
  expect_false(partes$valida)
  expect_match(partes$problema, "deveria ser 3")

  curta = chave_decompor(substr(NFE_SP, 1, 40))
  expect_false(curta$valida)
  expect_match(curta$problema, "40 posi")

  letra_no_numero = paste0(substr(NFE_SP, 1, 30), "A", substr(NFE_SP, 32, 44))
  expect_match(chave_decompor(letra_no_numero)$problema, "fora do CNPJ")

  uf_e_mes_errados = paste0("99", "2613", substr(NFE_SP, 7, 43))
  uf_e_mes_errados = paste0(uf_e_mes_errados, chave_digito(uf_e_mes_errados))
  partes = chave_decompor(uf_e_mes_errados)
  expect_match(partes$problema, "UF desconhecido: 99")
  expect_match(partes$problema, "inv\u00e1lido: 13")
  expect_true(is.na(partes$uf))
})

test_that("CNPJ que n\u00e3o confere invalida a chave, mesmo com o d\u00edgito da chave certo", {
  cnpj_errado = paste0(substr(NFE_SP, 1, 19), "2", substr(NFE_SP, 21, 43))
  cnpj_errado = paste0(cnpj_errado, chave_digito(cnpj_errado))
  partes = chave_decompor(cnpj_errado)
  expect_false(partes$valida)
  expect_true(is.na(partes$tipo_documento))
  expect_match(partes$problema, "emitente")
})

test_that("vazio, NA e vetor vazio", {
  partes = chave_decompor(c(NA, ""))
  expect_identical(partes$valida, c(FALSE, FALSE))
  expect_identical(nrow(chave_decompor(character())), 0L)
  expect_identical(chave_digito(c("123", NA)), c(NA_integer_, NA_integer_))
})
