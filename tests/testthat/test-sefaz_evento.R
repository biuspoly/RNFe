# Sem rede: o httr2 devolve o retorno do lote de eventos montado à mão com a estrutura do da SVRS de homologação
# (05/11/2026), com a chave fictícia da nota de exemplo de SP.
CERTIFICADO_DO_EVENTO = test_path("certificados", "pessoa_juridica.pfx")
CHAVE_DA_NOTA_DE_SP = "35261011222333000181550010000010011123456785"

retorno_dos_eventos = function(situacao, motivo, evento, orgao = "35") {
  texto = paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>',
    '<nfeResultMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeRecepcaoEvento4"><retEnvEvento versao="1.00" ',
    'xmlns="http://www.portalfiscal.inf.br/nfe"><idLote>1</idLote><tpAmb>2</tpAmb><verAplic>SVRS</verAplic><cOrgao>', orgao,
    "</cOrgao><cStat>128</cStat><xMotivo>Lote de Evento Processado</xMotivo><retEvento versao=\"1.00\"><infEvento>",
    "<tpAmb>2</tpAmb><verAplic>SVRS</verAplic><cOrgao>", orgao, "</cOrgao><cStat>", situacao, "</cStat><xMotivo>", motivo,
    "</xMotivo><chNFe>", CHAVE_DA_NOTA_DE_SP, "</chNFe><tpEvento>", evento, "</tpEvento><nSeqEvento>1</nSeqEvento>",
    "<dhRegEvento>2026-10-15T16:21:00-03:00</dhRegEvento><nProt>135260000054321</nProt></infEvento></retEvento>",
    "</retEnvEvento></nfeResultMsg></soap:Body></soap:Envelope>"
  )
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(texto))
}

test_that("o cancelamento: o evento assinado que vai e o procEventoNFe que o eventos_ler l\u00ea", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "110111")
  })
  cancelado = sefaz_cancelar(CHAVE_DA_NOTA_DE_SP, "135260000012345", "PEDIDO CANCELADO PELO CLIENTE", CERTIFICADO_DO_EVENTO,
                             "teste")
  expect_identical(cancelado$situacao, 135L)
  expect_identical(cancelado$protocolo, "135260000054321")
  expect_identical(cancelado$evento, "110111")
  expect_true(is.na(cancelado$problema))
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, paste0('<infEvento Id="ID110111', CHAVE_DA_NOTA_DE_SP, '01"><cOrgao>35</cOrgao><tpAmb>2</tpAmb><CNPJ>11222333000181</CNPJ>'), fixed = TRUE)
  expect_match(corpo, "<descEvento>Cancelamento</descEvento><nProt>135260000012345</nProt><xJust>PEDIDO CANCELADO PELO CLIENTE</xJust>", fixed = TRUE)
  expect_match(corpo, "<Signature xmlns=\"http://www.w3.org/2000/09/xmldsig#\">", fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type, "NFeRecepcaoEvento4/nfeRecepcaoEvento", fixed = TRUE)
  # Nada de quebra de linha no meio da mensagem (a SEFAZ rejeita com o 588).
  expect_false(grepl("\n", sub("^<\\?xml[^>]*\\?>", "", corpo)))
  lido = eventos_ler(cancelado$xml_evento)$eventos
  expect_identical(lido$tipo, "110111")
  expect_identical(lido$situacao, 135L)
})

test_that("a carta de corre\u00e7\u00e3o leva o texto fixo da condi\u00e7\u00e3o de uso, e a manifesta\u00e7\u00e3o vai ao Ambiente Nacional", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    if (length(pedidos) == 1) {
      return(retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "110110"))
    }
    retorno_dos_eventos(136, "Evento registrado, mas nao vinculado a NF-e", "210210", orgao = "91")
  })
  carta = sefaz_carta_correcao(CHAVE_DA_NOTA_DE_SP, "ONDE SE LE RUA DO CLIENTE, 10, LEIA-SE 100", 2, CERTIFICADO_DO_EVENTO,
                               "teste")
  expect_identical(carta$situacao, 135L)
  expect_identical(carta$sequencia, 2L)
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, paste0("ID110110", CHAVE_DA_NOTA_DE_SP, "02"), fixed = TRUE)
  expect_match(corpo, paste0("<xCondUso>", CONDICAO_DE_USO_DA_CARTA_DE_CORRECAO, "</xCondUso>"), fixed = TRUE)
  ciencia = sefaz_manifestar(CHAVE_DA_NOTA_DE_SP, "ciencia", certificado = CERTIFICADO_DO_EVENTO, senha = "teste")
  expect_identical(ciencia$situacao, 136L)
  expect_match(pedidos[[2]]$url, "hom1.nfe.fazenda.gov.br", fixed = TRUE)
  expect_match(rawToChar(pedidos[[2]]$body$data), "<cOrgao>91</cOrgao>", fixed = TRUE)
  expect_match(rawToChar(pedidos[[2]]$body$data), "<descEvento>Ciencia da Operacao</descEvento></detEvento>", fixed = TRUE)
})

test_that("o autor do evento \u00e9 o emitente da chave, e o certificado pode ser o da matriz", {
  skip_if_not_installed("openssl")
  # A nota da filial (0002) com o certificado da matriz (0001): o autor é a filial (a regra P12-44 do MOC 7.0).
  nota_da_filial = "35261011222333000262550010000010011123456788"
  montado = montar_o_evento(nota_da_filial, "110111", 1L, "<descEvento>Cancelamento</descEvento>", CERTIFICADO_DO_EVENTO,
                            "teste", "homologacao", no_ambiente_nacional = FALSE)
  expect_match(montado$evento_assinado, "<CNPJ>11222333000262</CNPJ>", fixed = TRUE)
  # Na série do emitente pessoa física, o autor é o CPF, que o certificado da empresa não tem.
  nota_de_cpf = "35261000012345678909559200000010011123456784"
  expect_error(montar_o_evento(nota_de_cpf, "110111", 1L, "", CERTIFICADO_DO_EVENTO, "teste", "homologacao", FALSE),
               "12345678909")
  # Outra empresa (outro CNPJ-base): nada é montado.
  nota_de_outra_empresa = "35261011444777000161550010000010011123456785"
  expect_error(montar_o_evento(nota_de_outra_empresa, "110111", 1L, "", CERTIFICADO_DO_EVENTO, "teste", "homologacao",
                               FALSE), "CNPJ-base")
  # Na manifestação, o destinatário informado (uma filial) é o autor; sem ele, o CNPJ do certificado.
  manifestacao = montar_o_evento(nota_de_outra_empresa, "210210", 1L, "<descEvento>Ciencia da Operacao</descEvento>",
                                 CERTIFICADO_DO_EVENTO, "teste", "homologacao", TRUE, destinatario = "11.222.333/0002-62")
  expect_match(manifestacao$evento_assinado, "<CNPJ>11222333000262</CNPJ>", fixed = TRUE)
  sem_destinatario = montar_o_evento(nota_de_outra_empresa, "210210", 1L, "", CERTIFICADO_DO_EVENTO, "teste", "homologacao",
                                     TRUE)
  expect_match(sem_destinatario$evento_assinado, "<CNPJ>11222333000181</CNPJ>", fixed = TRUE)
  expect_error(montar_o_evento(nota_de_outra_empresa, "210210", 1L, "", CERTIFICADO_DO_EVENTO, "teste", "homologacao", TRUE,
                               destinatario = "11444777000161"), "CNPJ-base")
})

test_that("os erros antes de qualquer conex\u00e3o", {
  expect_error(sefaz_cancelar(CHAVE_DA_NOTA_DE_SP, "135260000012345", "CURTA", CERTIFICADO_DO_EVENTO, "teste"), "15 a 255")
  expect_error(sefaz_cancelar(CHAVE_DA_NOTA_DE_SP, "123", "PEDIDO CANCELADO PELO CLIENTE", CERTIFICADO_DO_EVENTO, "teste"),
               "protocolo")
  expect_error(sefaz_cancelar(CHAVE_DA_NOTA_DE_SP, "135260000012345", "PEDIDO CANCELADO PELO CLIENTE", CERTIFICADO_DO_EVENTO,
                              "teste", ambiente = "producao"), "homologa\u00e7\u00e3o")
  expect_error(sefaz_carta_correcao(CHAVE_DA_NOTA_DE_SP, "CORRECAO DO ENDERECO DO CLIENTE", 21, CERTIFICADO_DO_EVENTO, "teste"),
               "1 a 20")
  expect_error(sefaz_carta_correcao(CHAVE_DA_NOTA_DE_SP, "CORRECAO DO ENDERECO DO CLIENTE", 1.5, CERTIFICADO_DO_EVENTO, "teste"),
               "1 a 20")
  # O texto com o que o TString do schema não aceita (a quebra de linha) é recusado antes de ir à SEFAZ.
  expect_error(sefaz_carta_correcao(CHAVE_DA_NOTA_DE_SP, "CORRECAO DO ENDERECO\nDO CLIENTE", 1, CERTIFICADO_DO_EVENTO, "teste"),
               "quebra de linha")
  expect_error(sefaz_carta_correcao("23261011444777000161650030000000779135724686", "CORRECAO DO ENDERECO DO CLIENTE", 1,
                                    CERTIFICADO_DO_EVENTO, "teste"), "modelo 55")
  expect_error(sefaz_manifestar(CHAVE_DA_NOTA_DE_SP, "outro", certificado = CERTIFICADO_DO_EVENTO, senha = "teste"), "tipo")
  expect_error(sefaz_manifestar(CHAVE_DA_NOTA_DE_SP, "nao_realizada", certificado = CERTIFICADO_DO_EVENTO, senha = "teste"),
               "justificativa")
})
