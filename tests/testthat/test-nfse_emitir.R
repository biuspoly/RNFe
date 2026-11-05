# Sem rede: o httr2 devolve respostas montadas à mão com a estrutura das da Sefin Nacional na Produção Restrita
# (05/11/2026, quando o RNFe gerou e cancelou uma NFS-e de teste por lá), com os dados fictícios dos exemplos.
CERTIFICADO_DA_NFSE = test_path("certificados", "pessoa_juridica.pfx")
CHAVE_DA_NFSE_DE_SP = "35503082211222333000181000000000012326101234567898"
DPS_DE_TESTE = paste0('<DPS xmlns="http://www.sped.fazenda.gov.br/nfse" versao="1.01"><infDPS Id="DPS35503082112223330001810',
                      '0001000000000000001"><tpAmb>2</tpAmb><serie>1</serie><nDPS>1</nDPS></infDPS></DPS>')

texto_do_exemplo_da_nfse = function(nome) {
  paste(readLines(system.file("exemplos", nome, package = "RNFe"), encoding = "UTF-8"), collapse = "\n")
}

resposta_da_sefin = function(situacao_http, conteudo) {
  httr2::response(status_code = situacao_http, headers = "Content-Type: application/json; charset=utf-8",
                  body = charToRaw(enc2utf8(as.character(jsonlite::toJSON(conteudo, auto_unbox = TRUE)))))
}

# O XML que foi no pedido, descompactado do JSON.
xml_do_pedido = function(pedido, campo) {
  json = jsonlite::fromJSON(rawToChar(pedido$body$data))
  texto_do_gzip_em_base64(json[[campo]])
}

test_that("o gzip vai com o cabe\u00e7alho do formato, e volta igual", {
  skip_if_not_installed("openssl")
  texto = "<DPS>servi\u00e7o de teste</DPS>"
  compactado = gzip_em_base64(texto)
  expect_identical(openssl::base64_decode(compactado)[1:2], as.raw(c(0x1f, 0x8b)))
  expect_identical(texto_do_gzip_em_base64(compactado), enc2utf8(texto))
})

test_that("a emiss\u00e3o: a DPS assinada com o SHA-256, com a declara\u00e7\u00e3o, e a NFS-e que o nfse_ler l\u00ea", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  skip_if_not_installed("jsonlite")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_sefin(201, list(tipoAmbiente = 2, versaoAplicativo = "SefinNacional_1.6.0",
                                dataHoraProcessamento = "2026-11-05T16:13:22.019884-03:00",
                                idDps = "DPS355030821122233300018100001000000000000001", chaveAcesso = CHAVE_DA_NFSE_DE_SP,
                                nfseXmlGZipB64 = gzip_em_base64(texto_do_exemplo_da_nfse("nfse_sp_v101.xml"))))
  })
  emitida = nfse_emitir(DPS_DE_TESTE, CERTIFICADO_DA_NFSE, "teste")
  expect_identical(emitida$situacao_http, 201L)
  expect_identical(emitida$chave, CHAVE_DA_NFSE_DE_SP)
  expect_true(is.na(emitida$problema))
  expect_identical(nfse_ler(emitida$xml)$nfses$chave, CHAVE_DA_NFSE_DE_SP)
  expect_match(pedidos[[1]]$url, "sefin.producaorestrita.nfse.gov.br/SefinNacional/nfse$")
  enviada = xml_do_pedido(pedidos[[1]], "dpsXmlGZipB64")
  expect_match(enviada, '^<\\?xml version="1.0" encoding="UTF-8"\\?><DPS ')
  expect_match(enviada, "xmldsig-more#rsa-sha256", fixed = TRUE)
})

test_that("a rejei\u00e7\u00e3o: o c\u00f3digo e a descri\u00e7\u00e3o, com a inicial mai\u00fascula como a Sefin manda", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  skip_if_not_installed("jsonlite")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) {
    resposta_da_sefin(400, list(tipoAmbiente = 2, versaoAplicativo = "SefinNacional_1.6.0",
                                dataHoraProcessamento = "2026-11-05T16:13:22-03:00",
                                erros = list(list(Codigo = "E0010", Descricao = "A s\u00e9rie informada na DPS n\u00e3o pertence \u00e0 faixa"))))
  })
  rejeitada = nfse_emitir(DPS_DE_TESTE, CERTIFICADO_DA_NFSE, "teste")
  expect_identical(rejeitada$situacao_http, 400L)
  expect_identical(rejeitada$codigo, "E0010")
  expect_match(rejeitada$motivo, "s\u00e9rie")
  expect_true(is.na(rejeitada$xml))
})

test_that("o cancelamento: o pedido de registro assinado e o evento que o eventos_ler l\u00ea", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  skip_if_not_installed("jsonlite")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_sefin(201, list(tipoAmbiente = 2, versaoAplicativo = "SefinNacional_1.6.0",
                                dataHoraProcessamento = "2026-11-05T16:15:00-03:00",
                                eventoXmlGZipB64 = gzip_em_base64(texto_do_exemplo_da_nfse("evento_nfse_cancelamento.xml"))))
  })
  cancelada = nfse_cancelar(CHAVE_DA_NFSE_DE_SP, "erro_na_emissao", "VALOR DO SERVICO INFORMADO ERRADO", CERTIFICADO_DA_NFSE,
                            "teste")
  expect_identical(cancelada$situacao_http, 201L)
  expect_identical(eventos_ler(cancelada$xml_evento)$eventos$tipo, "101101")
  expect_match(pedidos[[1]]$url, paste0("/nfse/", CHAVE_DA_NFSE_DE_SP, "/eventos$"))
  pedido = xml_do_pedido(pedidos[[1]], "pedidoRegistroEventoXmlGZipB64")
  expect_match(pedido, paste0('<infPedReg Id="PRE', CHAVE_DA_NFSE_DE_SP, '101101"><tpAmb>2</tpAmb>'), fixed = TRUE)
  expect_match(pedido, "<CNPJAutor>11222333000181</CNPJAutor>", fixed = TRUE)
  expect_match(pedido, "<cMotivo>1</cMotivo><xMotivo>VALOR DO SERVICO INFORMADO ERRADO</xMotivo>", fixed = TRUE)
  expect_match(pedido, "xmldsig-more#rsa-sha256", fixed = TRUE)
})

test_that("os erros antes de qualquer conex\u00e3o", {
  expect_error(nfse_emitir(DPS_DE_TESTE, CERTIFICADO_DA_NFSE, "teste", ambiente = "producao"), "homologa\u00e7\u00e3o")
  skip_if_not_installed("openssl")
  skip_if_not_installed("httr2")
  skip_if_not_installed("jsonlite")
  expect_error(nfse_emitir(sub("<tpAmb>2</tpAmb>", "<tpAmb>1</tpAmb>", DPS_DE_TESTE, fixed = TRUE), CERTIFICADO_DA_NFSE,
                           "teste"), "tpAmb 2")
  expect_error(nfse_emitir("<qualquer/>", CERTIFICADO_DA_NFSE, "teste"), "DPS")
  expect_error(nfse_cancelar(CHAVE_DA_NFSE_DE_SP, "outro", "VALOR DO SERVICO INFORMADO ERRADO", CERTIFICADO_DA_NFSE, "teste"),
               "motivo")
  expect_error(nfse_cancelar("123", "outros", "VALOR DO SERVICO INFORMADO ERRADO", CERTIFICADO_DA_NFSE, "teste"), "50")
  expect_error(nfse_cancelar(CHAVE_DA_NFSE_DE_SP, "outros", "CURTA", CERTIFICADO_DA_NFSE, "teste"), "15 a 255")
})
