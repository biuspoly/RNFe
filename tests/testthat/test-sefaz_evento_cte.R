# Sem rede: o httr2 devolve o retorno montado à mão com a estrutura do retEventoCTe da SVRS de homologação (05/11/2026:
# o desacordo de um CT-e inventado voltou 217, "CT-e não consta na base de dados", com o evento aceito no schema e na
# assinatura), com a chave fictícia do CT-e de exemplo de SP.
CERTIFICADO_DO_EVENTO_DO_CTE = test_path("certificados", "pessoa_juridica.pfx")
CHAVE_DO_CTE_DE_SP = "35261012ABC34501DE35570010000005551876543210"

retorno_do_evento_do_cte = function(situacao, motivo, evento) {
  texto = paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>',
    '<cteRecepcaoEventoResult xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CTeRecepcaoEventoV4"><retEventoCTe ',
    'versao="4.00" xmlns="http://www.portalfiscal.inf.br/cte"><infEvento><tpAmb>2</tpAmb><verAplic>SP-CTe</verAplic>',
    "<cOrgao>35</cOrgao><cStat>", situacao, "</cStat><xMotivo>", motivo, "</xMotivo><chCTe>", CHAVE_DO_CTE_DE_SP,
    "</chCTe><tpEvento>", evento, "</tpEvento><xEvento>Prestacao do Servico em Desacordo</xEvento><nSeqEvento>1",
    "</nSeqEvento><dhRegEvento>2026-11-05T16:21:00-03:00</dhRegEvento><nProt>135260000077777</nProt></infEvento>",
    "</retEventoCTe></cteRecepcaoEventoResult></soap:Body></soap:Envelope>"
  )
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(texto))
}

test_that("o desacordo: o evento sozinho, sem lote, e o procEventoCTe que o eventos_ler l\u00ea", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    retorno_do_evento_do_cte(135, "Evento registrado e vinculado ao CT-e", "610110")
  })
  desacordo = sefaz_cte_desacordo(CHAVE_DO_CTE_DE_SP, "FRETE COBRADO EM DUPLICIDADE NA MESMA VIAGEM",
                                  CERTIFICADO_DO_EVENTO_DO_CTE, "teste")
  expect_identical(desacordo$situacao, 135L)
  expect_identical(desacordo$protocolo, "135260000077777")
  expect_true(is.na(desacordo$problema))
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, paste0('<cteDadosMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CTeRecepcaoEventoV4"><eventoCTe ',
                             'xmlns="http://www.portalfiscal.inf.br/cte" versao="4.00"><infEvento Id="ID610110',
                             CHAVE_DO_CTE_DE_SP, '001"><cOrgao>35</cOrgao><tpAmb>2</tpAmb><CNPJ>11222333000181</CNPJ>'),
               fixed = TRUE)
  expect_match(corpo, paste0("<evPrestDesacordo><descEvento>Prestacao do Servico em Desacordo</descEvento>",
                             "<indDesacordoOper>1</indDesacordoOper><xObs>FRETE COBRADO"), fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type, "CTeRecepcaoEventoV4/cteRecepcaoEvento", fixed = TRUE)
  lido = eventos_ler(desacordo$xml_evento)$eventos
  expect_identical(lido$tipo, "610110")
  expect_identical(lido$chave, CHAVE_DO_CTE_DE_SP)
})

test_that("o cancelamento do desacordo leva o protocolo dele", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    retorno_do_evento_do_cte(135, "Evento registrado e vinculado ao CT-e", "610111")
  })
  cancelado = sefaz_cte_cancelar_desacordo(CHAVE_DO_CTE_DE_SP, "135260000077777", CERTIFICADO_DO_EVENTO_DO_CTE, "teste")
  expect_identical(cancelado$situacao, 135L)
  expect_match(rawToChar(pedidos[[1]]$body$data),
               "<nProtEvPrestDes>135260000077777</nProtEvPrestDes></evCancPrestDesacordo>", fixed = TRUE)
})

test_that("o autor do desacordo \u00e9 o tomador: o informado (uma filial) ou o do certificado", {
  skip_if_not_installed("openssl")
  da_filial = montar_o_evento_do_cte(CHAVE_DO_CTE_DE_SP, "610110", 1L, "", CERTIFICADO_DO_EVENTO_DO_CTE, "teste", "homologacao",
                                     tomador = "11222333000262")
  expect_match(da_filial$evento_assinado, "<CNPJ>11222333000262</CNPJ>", fixed = TRUE)
  expect_error(montar_o_evento_do_cte(CHAVE_DO_CTE_DE_SP, "610110", 1L, "", CERTIFICADO_DO_EVENTO_DO_CTE, "teste",
                                      "homologacao", tomador = "11444777000161"), "CNPJ-base")
  expect_error(montar_o_evento_do_cte(CHAVE_DO_CTE_DE_SP, "610110", 1L, "", CERTIFICADO_DO_EVENTO_DO_CTE, "teste",
                                      "homologacao", tomador = "11222333000100"), "d\u00edgitos")
})

test_that("os erros antes de qualquer conex\u00e3o", {
  expect_error(sefaz_cte_desacordo(CHAVE_DO_CTE_DE_SP, "CURTA", CERTIFICADO_DO_EVENTO_DO_CTE, "teste"), "15 a 255")
  expect_error(sefaz_cte_desacordo("35261011222333000181550010000010011123456785", "FRETE COBRADO EM DUPLICIDADE",
                                   CERTIFICADO_DO_EVENTO_DO_CTE, "teste"), "CT-e")
  expect_error(sefaz_cte_desacordo(CHAVE_DO_CTE_DE_SP, "FRETE COBRADO EM DUPLICIDADE", CERTIFICADO_DO_EVENTO_DO_CTE, "teste",
                                   sequencia = 21), "1 a 20")
  expect_error(sefaz_cte_cancelar_desacordo(CHAVE_DO_CTE_DE_SP, "123", CERTIFICADO_DO_EVENTO_DO_CTE, "teste"), "protocolo")
  expect_error(sefaz_cte_desacordo(CHAVE_DO_CTE_DE_SP, "FRETE COBRADO EM DUPLICIDADE", CERTIFICADO_DO_EVENTO_DO_CTE, "teste",
                                   ambiente = "producao"), "homologa\u00e7\u00e3o")
})
