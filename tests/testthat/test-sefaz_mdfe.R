# Sem rede: o httr2 devolve respostas montadas à mão com a estrutura das da SVRS de homologação (05/11/2026, quando o
# RNFe autorizou um MDF-e de teste, incluiu um condutor e o encerrou por lá), com os dados fictícios dos exemplos.
CERTIFICADO_DO_MDFE = test_path("certificados", "pessoa_juridica.pfx")
CHAVE_DO_MDFE_DO_CE = "23261011444777000161580020000000121556677880"
# Nos eventos, o autor é o emitente da chave, que tem de ter o CNPJ-base do certificado de teste.
CHAVE_DO_MDFE_DO_CERTIFICADO = "23261011222333000181580020000000121556677880"

mdfe_assinado_do_ce = function() {
  xml_assinar(system.file("exemplos", "mdfe_ce_carga_propria.xml", package = "RNFe"), CERTIFICADO_DO_MDFE, "teste")
}

resposta_da_svrs = function(servico, retorno) {
  texto = paste0('<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">',
                 '<soap:Body><mdfeRecepcaoResult xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/', servico, '">', retorno,
                 "</mdfeRecepcaoResult></soap:Body></soap:Envelope>")
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(texto))
}

retorno_do_evento_do_mdfe = function(evento) {
  paste0('<retEventoMDFe versao="3.00" xmlns="http://www.portalfiscal.inf.br/mdfe"><infEvento><tpAmb>2</tpAmb>',
         "<verAplic>RS20261105</verAplic><cOrgao>23</cOrgao><cStat>135</cStat><xMotivo>Evento registrado e vinculado ao ",
         "MDF-e</xMotivo><chMDFe>", CHAVE_DO_MDFE_DO_CERTIFICADO, "</chMDFe><tpEvento>", evento, "</tpEvento><xEvento>Evento</xEvento>",
         "<nSeqEvento>1</nSeqEvento><dhRegEvento>2026-11-05T16:30:00-03:00</dhRegEvento><nProt>923260000077777</nProt>",
         "</infEvento></retEventoMDFe>")
}

test_that("a autoriza\u00e7\u00e3o: o MDF-e compactado, o QR-Code acrescentado e o mdfeProc que o mdfe_ler l\u00ea", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_svrs("MDFeRecepcaoSinc", paste0(
      '<retMDFe versao="3.00" xmlns="http://www.portalfiscal.inf.br/mdfe"><tpAmb>2</tpAmb><cUF>23</cUF>',
      "<verAplic>RS20261105</verAplic><cStat>100</cStat><xMotivo>Autorizado o uso do MDF-e</xMotivo>",
      '<protMDFe versao="3.00"><infProt><tpAmb>2</tpAmb><verAplic>RS20261105</verAplic><chMDFe>', CHAVE_DO_MDFE_DO_CE,
      "</chMDFe><dhRecbto>2026-11-05T16:20:00-03:00</dhRecbto><nProt>923260000012345</nProt>",
      "<digVal>AAAAAAAAAAAAAAAAAAAAAAAAAAA=</digVal><cStat>100</cStat><xMotivo>Autorizado o uso do MDF-e</xMotivo>",
      "</infProt></protMDFe></retMDFe>"))
  })
  autorizado = sefaz_mdfe_autorizar(mdfe_assinado_do_ce(), CERTIFICADO_DO_MDFE, "teste")
  expect_identical(autorizado$situacao, 100L)
  expect_identical(autorizado$protocolo, "923260000012345")
  expect_true(is.na(autorizado$problema))
  lido = mdfe_ler(autorizado$xml_autorizado)
  expect_identical(lido$mdfes$chave, CHAVE_DO_MDFE_DO_CE)
  expect_identical(lido$mdfes$situacao, 100L)
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_false(grepl("Header", corpo, fixed = TRUE))
  expect_match(pedidos[[1]]$body$content_type, "MDFeRecepcaoSinc/mdfeRecepcao", fixed = TRUE)
  compactado = sub(".*<mdfeDadosMsg[^>]*>([^<]*)</mdfeDadosMsg>.*", "\\1", corpo)
  enviado = texto_do_gzip_em_base64(compactado)
  expect_match(enviado, '^<MDFe xmlns="http://www.portalfiscal.inf.br/mdfe">')
  # O grupo do QR-Code entre o infMDFe e a assinatura (a declaração do namespace repetida não muda nada).
  expect_match(enviado, paste0("</infMDFe><infMDFeSupl[^>]*><qrCodMDFe>https://dfe-portal\\.svrs\\.rs\\.gov\\.br/mdfe/qrCode",
                               "\\?chMDFe=", CHAVE_DO_MDFE_DO_CE, "&amp;tpAmb=2</qrCodMDFe></infMDFeSupl><Signature"))
})

test_that("o encerramento e a inclus\u00e3o de condutor: o evento sozinho e o procEventoMDFe", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    evento = if (length(pedidos) == 1) "110112" else "110114"
    resposta_da_svrs("MDFeRecepcaoEvento", retorno_do_evento_do_mdfe(evento))
  })
  encerrado = sefaz_mdfe_encerrar(CHAVE_DO_MDFE_DO_CERTIFICADO, "923260000012345", "PE", "2611606", as.Date("2026-11-05"),
                                  CERTIFICADO_DO_MDFE, "teste")
  expect_identical(encerrado$situacao, 135L)
  expect_identical(eventos_ler(encerrado$xml_evento)$eventos$tipo, "110112")
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, paste0('<eventoMDFe xmlns="http://www.portalfiscal.inf.br/mdfe" versao="3.00"><infEvento Id="ID110112',
                             CHAVE_DO_MDFE_DO_CERTIFICADO, '01"><cOrgao>23</cOrgao><tpAmb>2</tpAmb><CNPJ>11222333000181</CNPJ>'),
               fixed = TRUE)
  expect_match(corpo, paste0("<evEncMDFe><descEvento>Encerramento</descEvento><nProt>923260000012345</nProt>",
                             "<dtEnc>2026-11-05</dtEnc><cUF>26</cUF><cMun>2611606</cMun></evEncMDFe>"), fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type, "MDFeRecepcaoEvento/mdfeRecepcaoEvento", fixed = TRUE)
  condutor = sefaz_mdfe_incluir_condutor(CHAVE_DO_MDFE_DO_CERTIFICADO, "SEGUNDO MOTORISTA DE TESTE", "98765432100",
                                         certificado = CERTIFICADO_DO_MDFE, senha = "teste")
  expect_identical(condutor$situacao, 135L)
  expect_match(rawToChar(pedidos[[2]]$body$data), paste0("<condutor><xNome>SEGUNDO MOTORISTA DE TESTE</xNome><CPF>98765432100",
                                                         "</CPF></condutor>"), fixed = TRUE)
})

# Duas NF-e fictícias do emitente do certificado de teste.
NFE_INCLUIDA_1 = "35261011222333000181550010000010011123456785"
NFE_INCLUIDA_2 = "35261011222333000181550010000010021123456782"

test_that("a inclus\u00e3o de DF-e: o evento 110115 com as NF-e e o procEventoMDFe", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_svrs("MDFeRecepcaoEvento", retorno_do_evento_do_mdfe("110115"))
  })
  incluida = sefaz_mdfe_incluir_dfe(CHAVE_DO_MDFE_DO_CERTIFICADO, "923260000012345", "2304400", "Fortaleza",
                                    c(NFE_INCLUIDA_1, NFE_INCLUIDA_2), "2304400", "Fortaleza",
                                    certificado = CERTIFICADO_DO_MDFE, senha = "teste")
  expect_identical(incluida$situacao, 135L)
  expect_identical(incluida$evento, "110115")
  expect_identical(eventos_ler(incluida$xml_evento)$eventos$tipo, "110115")
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, paste0('<infEvento Id="ID110115', CHAVE_DO_MDFE_DO_CERTIFICADO, '01">'), fixed = TRUE)
  expect_match(corpo, paste0("<evIncDFeMDFe><descEvento>Inclusao DF-e</descEvento><nProt>923260000012345</nProt>",
                             "<cMunCarrega>2304400</cMunCarrega><xMunCarrega>Fortaleza</xMunCarrega>",
                             "<infDoc><cMunDescarga>2304400</cMunDescarga><xMunDescarga>Fortaleza</xMunDescarga><chNFe>",
                             NFE_INCLUIDA_1, "</chNFe></infDoc><infDoc><cMunDescarga>2304400</cMunDescarga><xMunDescarga>",
                             "Fortaleza</xMunDescarga><chNFe>", NFE_INCLUIDA_2, "</chNFe></infDoc></evIncDFeMDFe>"), fixed = TRUE)
  # A segunda inclusão no mesmo MDF-e vai com a sequência 2 (a SVRS aceitou em homologação, em 10/11/2026).
  # E a NF-e com o CNPJ alfanumérico (o exemplo da Receita) entra como as outras.
  segunda = sefaz_mdfe_incluir_dfe(CHAVE_DO_MDFE_DO_CERTIFICADO, "923260000012345", "2304400", "Fortaleza",
                                   "35261012ABC34501DE35550010000001231123456784", "2307304", "Juazeiro do Norte",
                                   sequencia = 2, certificado = CERTIFICADO_DO_MDFE, senha = "teste")
  expect_identical(segunda$sequencia, 2L)
  expect_match(rawToChar(pedidos[[2]]$body$data), paste0('Id="ID110115', CHAVE_DO_MDFE_DO_CERTIFICADO, '02"'), fixed = TRUE)
  expect_match(rawToChar(pedidos[[2]]$body$data), paste0("<cMunDescarga>2307304</cMunDescarga><xMunDescarga>Juazeiro do Norte",
                                                         "</xMunDescarga><chNFe>35261012ABC34501DE35550010000001231123456784"),
               fixed = TRUE)
})

# A inclusão no MDF-e de teste, mudando só o que cada caso de erro precisa.
incluir_no_mdfe_de_teste = function(chaves_nfe, municipios = "2304400", nomes = "Fortaleza", protocolo = "923260000012345") {
  sefaz_mdfe_incluir_dfe(CHAVE_DO_MDFE_DO_CERTIFICADO, protocolo, "2304400", "Fortaleza", chaves_nfe, municipios, nomes,
                         certificado = CERTIFICADO_DO_MDFE, senha = "teste")
}

test_that("a inclus\u00e3o de DF-e: os erros antes de qualquer conex\u00e3o", {
  skip_if_not_installed("openssl")
  expect_error(incluir_no_mdfe_de_teste(CHAVE_DO_MDFE_DO_CE), "modelo 55")
  expect_error(incluir_no_mdfe_de_teste(c(NFE_INCLUIDA_1, NFE_INCLUIDA_1)), "mais de uma vez")
  expect_error(incluir_no_mdfe_de_teste(c(NFE_INCLUIDA_1, NFE_INCLUIDA_2), c("2304400", "2307304", "2311306")), "um para cada")
  expect_error(incluir_no_mdfe_de_teste(NFE_INCLUIDA_1, "230440"), "7 n\u00fameros")
  expect_error(incluir_no_mdfe_de_teste(NFE_INCLUIDA_1, nomes = " Fortaleza"), "espa\u00e7o")
  expect_error(incluir_no_mdfe_de_teste(NFE_INCLUIDA_1, protocolo = "123"), "protocolo")
  expect_error(incluir_no_mdfe_de_teste("35261011222333000181550010000010011123456780"), "d\u00edgito")
  # O TString do schema só aceita do espaço ao U+00FF: o travessão e a quebra de linha não passam.
  expect_error(incluir_no_mdfe_de_teste(NFE_INCLUIDA_1, nomes = "Juazeiro \u2013 Norte"), "Latin-1")
  expect_error(incluir_no_mdfe_de_teste(NFE_INCLUIDA_1, nomes = "Juazeiro\ndo Norte"), "quebra de linha")
  expect_error(sefaz_mdfe_incluir_dfe(CHAVE_DO_MDFE_DO_CERTIFICADO, "923260000012345", "2304400", "Fortaleza", NFE_INCLUIDA_1,
                                      "2304400", "Fortaleza", sequencia = 100, certificado = CERTIFICADO_DO_MDFE,
                                      senha = "teste"), "1 a 99")
  expect_error(sefaz_mdfe_incluir_dfe(CHAVE_DO_MDFE_DO_CERTIFICADO, "923260000012345", "2304400", "Fortaleza", NFE_INCLUIDA_1,
                                      "2304400", "Fortaleza", sequencia = 1.5, certificado = CERTIFICADO_DO_MDFE,
                                      senha = "teste"), "1 a 99")
})

test_that("os erros antes de qualquer conex\u00e3o", {
  skip_if_not_installed("openssl")
  expect_error(sefaz_mdfe_autorizar(system.file("exemplos", "mdfe_ce_carga_propria.xml", package = "RNFe"),
                                    CERTIFICADO_DO_MDFE, "teste", ambiente = "producao"), "homologa\u00e7\u00e3o")
  sem_assinatura = sub("(?s)<Signature.*</Signature>", "",
                       paste(readLines(system.file("exemplos", "mdfe_ce_carga_propria.xml", package = "RNFe"),
                                       encoding = "UTF-8"), collapse = "\n"), perl = TRUE)
  expect_error(sefaz_mdfe_autorizar(sem_assinatura, CERTIFICADO_DO_MDFE, "teste"), "assinado")
  expect_error(sefaz_mdfe_encerrar(CHAVE_DO_MDFE_DO_CE, "923260000012345", "XX", "2611606", Sys.Date(), CERTIFICADO_DO_MDFE,
                                   "teste"), "UF")
  expect_error(sefaz_mdfe_encerrar(CHAVE_DO_MDFE_DO_CE, "123", "PE", "2611606", Sys.Date(), CERTIFICADO_DO_MDFE, "teste"),
               "protocolo")
  expect_error(sefaz_mdfe_incluir_condutor(CHAVE_DO_MDFE_DO_CE, "MOTORISTA", "12345678900", certificado = CERTIFICADO_DO_MDFE,
                                           senha = "teste"), "CPF")
  expect_error(sefaz_mdfe_encerrar("35261011222333000181550010000010011123456785", "923260000012345", "PE", "2611606",
                                   Sys.Date(), CERTIFICADO_DO_MDFE, "teste"), "MDF-e")
  # O MDF-e de outra empresa (o emitente da chave com outro CNPJ-base): o certificado não é do autor.
  expect_error(sefaz_mdfe_encerrar(CHAVE_DO_MDFE_DO_CE, "923260000012345", "PE", "2611606", Sys.Date(), CERTIFICADO_DO_MDFE,
                                   "teste"), "CNPJ-base")
})
