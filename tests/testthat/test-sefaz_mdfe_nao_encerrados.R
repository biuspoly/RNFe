# Sem rede: o httr2 devolve a resposta no lugar da SEFAZ. respostas/nao_encerrados_homologacao_svrs.xml é a resposta real
# da SVRS de homologação (03/11/2026) para um CNPJ sem MDF-e aberto; a resposta com MDF-e abertos é montada a partir dela.
CERTIFICADO_DO_TESTE = test_path("certificados", "pessoa_juridica.pfx")
RESPOSTA_SEM_MDFE_ABERTO = test_path("respostas", "nao_encerrados_homologacao_svrs.xml")
ENDERECO_DOS_NAO_ENCERRADOS = "https://mdfe-homologacao.svrs.rs.gov.br/ws/MDFeConsNaoEnc/MDFeConsNaoEnc.asmx"

resposta_da_sefaz = function(texto) {
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(enc2utf8(texto)))
}

texto_do_arquivo = function(arquivo) {
  paste(readLines(arquivo, encoding = "UTF-8", warn = FALSE), collapse = "\n")
}

# A resposta gravada com dois MDF-e abertos (chave e protocolo do exemplo mdfe_proc_sp.xml e de outro inventado).
resposta_com_dois_abertos = function() {
  abertos = paste0(
    "<infMDFe><chMDFe>35261033344455500070580010000003211112233448</chMDFe><nProt>935260000011111</nProt></infMDFe>",
    "<infMDFe><chMDFe>35261033344455500070580010000003221112233445</chMDFe><nProt>935260000022222</nProt></infMDFe>"
  )
  texto = texto_do_arquivo(RESPOSTA_SEM_MDFE_ABERTO)
  texto = sub("<cStat>112</cStat>", "<cStat>111</cStat>", texto, fixed = TRUE)
  sub("</retConsMDFeNaoEnc>", paste0(abertos, "</retConsMDFeNaoEnc>"), texto, fixed = TRUE)
}

test_that("a produ\u00e7\u00e3o e o documento que n\u00e3o \u00e9 CNPJ nem CPF s\u00e3o recusados antes de qualquer conex\u00e3o", {
  expect_error(sefaz_mdfe_nao_encerrados("11222333000181", "qualquer.pfx", "senha", ambiente = "producao"), "homologa\u00e7\u00e3o")
  expect_error(sefaz_mdfe_nao_encerrados("123", "qualquer.pfx", "senha"), "CNPJ \\(14 posi\u00e7\u00f5es\\) ou um CPF")
  expect_error(sefaz_mdfe_nao_encerrados(c("11222333000181", "12345678909"), "qualquer.pfx", "senha"), "CNPJ")
})

test_that("sem MDF-e aberto: o pedido que vai e a resposta da SVRS", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_sefaz(texto_do_arquivo(RESPOSTA_SEM_MDFE_ABERTO))
  })
  abertos = sefaz_mdfe_nao_encerrados("11.222.333/0001-81", CERTIFICADO_DO_TESTE, "teste")
  consulta = abertos$consulta
  expect_identical(consulta$documento, "11222333000181")
  expect_identical(consulta$ambiente, "homologacao")
  expect_identical(consulta$situacao, 112L)
  expect_identical(consulta$motivo, "Consulta n\u00e3o encerrados n\u00e3o localizou MDF-e nessa situa\u00e7\u00e3o")
  expect_identical(consulta$mdfes, 0L)
  expect_identical(consulta$versao_aplicativo, "RS20240709143503")
  expect_identical(consulta$endereco, ENDERECO_DOS_NAO_ENCERRADOS)
  expect_true(is.na(consulta$problema))
  expect_identical(nrow(abertos$mdfes), 0L)
  expect_identical(names(abertos$mdfes), c("chave", "protocolo"))
  # O pedido: o consMDFeNaoEnc com o CNPJ, a versão no cabeçalho mdfeCabecMsg e a action do WSDL.
  expect_length(pedidos, 1)
  expect_identical(pedidos[[1]]$url, ENDERECO_DOS_NAO_ENCERRADOS)
  corpo = rawToChar(pedidos[[1]]$body$data)
  Encoding(corpo) = "UTF-8"
  expect_match(corpo, paste0('<soap12:Header><mdfeCabecMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsNaoEnc">',
                             "<versaoDados>3.00</versaoDados></mdfeCabecMsg></soap12:Header>"), fixed = TRUE)
  expect_match(corpo, paste0('<mdfeDadosMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsNaoEnc">',
                             '<consMDFeNaoEnc xmlns="http://www.portalfiscal.inf.br/mdfe" versao="3.00"><tpAmb>2</tpAmb>',
                             "<xServ>CONSULTAR N\u00c3O ENCERRADOS</xServ><CNPJ>11222333000181</CNPJ></consMDFeNaoEnc>",
                             "</mdfeDadosMsg>"), fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type,
               'action="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsNaoEnc/mdfeConsNaoEnc"', fixed = TRUE)
})

test_that("com MDF-e abertos: a chave e o protocolo de cada um, pelo CPF", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_sefaz(resposta_com_dois_abertos())
  })
  abertos = sefaz_mdfe_nao_encerrados("123.456.789-09", CERTIFICADO_DO_TESTE, "teste")
  expect_identical(abertos$consulta$documento, "12345678909")
  expect_identical(abertos$consulta$situacao, 111L)
  expect_identical(abertos$consulta$mdfes, 2L)
  expect_true(is.na(abertos$consulta$problema))
  expect_identical(abertos$mdfes$chave, c("35261033344455500070580010000003211112233448",
                                          "35261033344455500070580010000003221112233445"))
  expect_identical(abertos$mdfes$protocolo, c("935260000011111", "935260000022222"))
  expect_match(rawToChar(pedidos[[1]]$body$data), "<CPF>12345678909</CPF></consMDFeNaoEnc>", fixed = TRUE)
})

test_that("a resposta de outro ambiente e a SEFAZ fora do ar v\u00e3o para `problema`", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) {
    resposta_da_sefaz(sub("<tpAmb>2</tpAmb>", "<tpAmb>1</tpAmb>", texto_do_arquivo(RESPOSTA_SEM_MDFE_ABERTO), fixed = TRUE))
  })
  expect_identical(sefaz_mdfe_nao_encerrados("11222333000181", CERTIFICADO_DO_TESTE, "teste")$consulta$problema,
                   "a SEFAZ respondeu de outro ambiente")
  httr2::local_mocked_responses(function(req) stop("Could not resolve host"))
  fora_do_ar = sefaz_mdfe_nao_encerrados("11222333000181", CERTIFICADO_DO_TESTE, "teste")
  expect_match(fora_do_ar$consulta$problema, "^sem resposta da SEFAZ")
  expect_true(is.na(fora_do_ar$consulta$situacao))
  expect_identical(nrow(fora_do_ar$mdfes), 0L)
})
