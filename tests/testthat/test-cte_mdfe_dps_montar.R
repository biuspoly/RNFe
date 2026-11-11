CERTIFICADO_DA_MONTAGEM = test_path("certificados", "pessoa_juridica.pfx")

# O elemento assinado de um XML, na forma canônica.
canonico_de = function(xml, nome) {
  documento = xml2::read_xml(xml, options = "NOBLANKS")
  xml_canonico(xml2::xml_find_first(documento, paste0("//*[local-name()='", nome, "']")))
}

test_that("o CT-e, o CT-e OS, a GTV-e, o CT-e simplificado e o MDF-e de exemplo voltam iguais pela lista", {
  for (exemplo in c("cte_proc_sp.xml", "cte_os_sp.xml", "gtve_proc_sp.xml", "cte_simp_proc_sp.xml",
                    "cte_ce_simples_toma4.xml")) {
    arquivo = system.file("exemplos", exemplo, package = "RNFe")
    montado = cte_montar(xml_para_lista(arquivo), manter_vazios = TRUE)
    expect_identical(canonico_de(montado, "infCte"), canonico_de(arquivo, "infCte"), info = exemplo)
  }
  for (exemplo in c("mdfe_proc_sp.xml", "mdfe_ce_carga_propria.xml")) {
    arquivo = system.file("exemplos", exemplo, package = "RNFe")
    montado = mdfe_montar(xml_para_lista(arquivo), manter_vazios = TRUE)
    expect_identical(canonico_de(montado, "infMDFe"), canonico_de(arquivo, "infMDFe"), info = exemplo)
  }
})

test_that("o documento do CT-e sai do mod e do tpCTe, e o modelo que falta vem do documento", {
  simplificado = xml_para_lista(system.file("exemplos", "cte_simp_proc_sp.xml", package = "RNFe"))
  expect_identical(documento_do_cte(simplificado, NULL), "CT-e simplificado")
  os = xml_para_lista(system.file("exemplos", "cte_os_sp.xml", package = "RNFe"))
  expect_identical(documento_do_cte(os, NULL), "CT-e OS")
  gtve = xml_para_lista(system.file("exemplos", "gtve_proc_sp.xml", package = "RNFe"))
  expect_identical(documento_do_cte(gtve, NULL), "GTV-e")
  sem_modelo = os
  sem_modelo$ide$mod = NULL
  expect_error(cte_montar(sem_modelo), "Informe o modelo")
  expect_match(cte_montar(sem_modelo, documento = "CT-e OS"), "^<CTeOS ")
  expect_error(cte_montar(os, documento = "CTe"), "Informe o documento")
})

test_that("a chave do CT-e e do MDF-e sai dos campos, igual \u00e0 do exemplo", {
  for (exemplo in c("cte_proc_sp.xml", "cte_os_sp.xml", "gtve_proc_sp.xml")) {
    cte = xml_para_lista(system.file("exemplos", exemplo, package = "RNFe"))
    identificador = cte$Id
    cte$Id = NULL
    cte$ide$cDV = NULL
    expect_match(cte_montar(cte), paste0('Id="', identificador, '"'), fixed = TRUE, info = exemplo)
  }
  mdfe = xml_para_lista(system.file("exemplos", "mdfe_ce_carga_propria.xml", package = "RNFe"))
  identificador = mdfe$Id
  mdfe$Id = NULL
  mdfe$ide$cDV = NULL
  mdfe$ide$mod = NULL
  montado = mdfe_montar(mdfe)
  expect_match(montado, paste0('Id="', identificador, '"'), fixed = TRUE)
  expect_match(montado, "<mod>58</mod>", fixed = TRUE)
})

test_that("o modal vai no infModal e \u00e9 conferido pelo schema dele", {
  cte = xml_para_lista(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  expect_false(is.null(cte$infCTeNorm$infModal$rodo))
  cte$infCTeNorm$infModal$rodo$RNTRC = "ABC"
  expect_error(cte_montar(cte), "RNTRC")
  mdfe = xml_para_lista(system.file("exemplos", "mdfe_proc_sp.xml", package = "RNFe"))
  mdfe$infModal$rodo$campoInventado = "1"
  expect_error(mdfe_montar(mdfe), "\"campoInventado\" n\u00e3o existe em MDFe/infMDFe/infModal/rodo")
})

test_that("o documento de produ\u00e7\u00e3o \u00e9 recusado, e o tpAmb que falta vem do ambiente", {
  cte = xml_para_lista(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  cte$ide$tpAmb = "1"
  expect_error(cte_montar(cte), "homologa\u00e7\u00e3o \\(tpAmb 2\\)")
  mdfe = xml_para_lista(system.file("exemplos", "mdfe_proc_sp.xml", package = "RNFe"))
  mdfe$ide$tpAmb = NULL
  expect_match(mdfe_montar(mdfe), "<tpAmb>2</tpAmb>", fixed = TRUE)
})

test_that("a DPS da NT 009 volta igual pela lista, com a vers\u00e3o do schema e o Id dos campos", {
  for (variante in list(nfse_no_leiaute_da_nt_009(), nfse_da_nt_009_com_destinatario(), nfse_da_nt_009_com_imoveis())) {
    montada = nfse_dps_montar(xml_para_lista(variante), manter_vazios = TRUE)
    expect_identical(canonico_de(montada, "infDPS"), canonico_de(variante, "infDPS"))
    expect_match(montada, '^<DPS xmlns="http://www.sped.fazenda.gov.br/nfse" versao="1.01">')
  }
  dps = xml_para_lista(nfse_no_leiaute_da_nt_009())
  identificador = dps$Id
  dps$Id = NULL
  expect_match(nfse_dps_montar(dps), paste0('Id="', identificador, '"'), fixed = TRUE)
})

test_that("o espa\u00e7o nas pontas fica onde o tipo aceita (o xNome da NFS-e) e sai onde n\u00e3o aceita", {
  dps = xml_para_lista(nfse_no_leiaute_da_nt_009())
  dps$toma$xNome = " TOMADOR COM ESPACO "
  montada = nfse_dps_montar(dps)
  expect_match(montada, "<xNome> TOMADOR COM ESPACO </xNome>", fixed = TRUE)
  # O texto só de espaços é vazio: o campo opcional fica de fora.
  dps$toma$fone = "   "
  expect_false(grepl("<fone>", nfse_dps_montar(dps), fixed = TRUE))
})

test_that("o Id da DPS leva a inscri\u00e7\u00e3o do emitente que o tpEmit aponta, e o CPF com zeros", {
  dps = xml_para_lista(nfse_no_leiaute_da_nt_009())
  dps$Id = NULL
  dps$serie = 7
  dps$nDPS = 45
  completada = dps_com_o_identificador(dps)
  cnpj_do_prestador = dps$prest$CNPJ
  expect_identical(completada$Id, paste0("DPS", dps$cLocEmi, "2", cnpj_do_prestador, "00007", "000000000000045"))
  # Emitida pelo tomador (tpEmit 2), com CPF: o tipo 1 e o CPF com três zeros na frente.
  dps$tpEmit = "2"
  dps$toma = list(CPF = "12345678909", xNome = "TOMADOR DE TESTE")
  expect_identical(dps_com_o_identificador(dps)$Id,
                   paste0("DPS", dps$cLocEmi, "1", "00012345678909", "00007", "000000000000045"))
  dps$tpEmit = "4"
  expect_error(dps_com_o_identificador(dps), "tpEmit da DPS tem de ser 1")
  dps$tpEmit = "3"
  expect_error(dps_com_o_identificador(dps), "faltam: interm/CNPJ")
  errada = xml_para_lista(nfse_no_leiaute_da_nt_009())
  errada$Id = "DPS1234567"
  expect_error(nfse_dps_montar(errada), "n\u00e3o confere com os campos da DPS")
  producao = xml_para_lista(nfse_no_leiaute_da_nt_009())
  producao$tpAmb = "1"
  expect_error(nfse_dps_montar(producao), "homologa\u00e7\u00e3o \\(tpAmb 2\\)")
})

# A resposta da SEFAZ com a estrutura do retorno da recepção do CT-e (o MOC 4.00, item 4.2.2), com os dados do exemplo.
resposta_da_recepcao_do_cte = function(servico, operacao, retorno) {
  texto = paste0('<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">',
                 '<soap:Body><', operacao, 'Result xmlns="http://www.portalfiscal.inf.br/cte/wsdl/', servico, '">', retorno,
                 "</", operacao, "Result></soap:Body></soap:Envelope>")
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(texto))
}

retorno_do_cte = function(raiz_do_retorno, chave, situacao) {
  paste0("<", raiz_do_retorno, ' versao="4.00" xmlns="http://www.portalfiscal.inf.br/cte"><tpAmb>2</tpAmb><cUF>35</cUF>',
         "<verAplic>SP_CTE_TESTE</verAplic><cStat>", situacao, "</cStat><xMotivo>Autorizado o uso do CT-e</xMotivo>",
         '<protCTe versao="4.00"><infProt><tpAmb>2</tpAmb><verAplic>SP_CTE_TESTE</verAplic><chCTe>', chave,
         "</chCTe><dhRecbto>2026-11-11T10:20:00-03:00</dhRecbto><nProt>135260000012345</nProt>",
         "<digVal>AAAAAAAAAAAAAAAAAAAAAAAAAAA=</digVal><cStat>", situacao, "</cStat><xMotivo>Autorizado o uso do CT-e</xMotivo>",
         "</infProt></protCTe></", raiz_do_retorno, ">")
}

test_that("a autoriza\u00e7\u00e3o do CT-e: compactado, o QR-Code acrescentado e o cteProc que o cte_ler l\u00ea", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  cte = xml_para_lista(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  assinado = xml_assinar(cte_montar(cte), CERTIFICADO_DA_MONTAGEM, "teste")
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_recepcao_do_cte("CTeRecepcaoSincV4", "cteRecepcao", retorno_do_cte("retCTe", sub("^CTe", "", cte$Id), 100))
  })
  autorizado = sefaz_cte_autorizar(assinado, CERTIFICADO_DA_MONTAGEM, "teste")
  expect_identical(autorizado$situacao, 100L)
  expect_identical(autorizado$documento, "CT-e")
  expect_identical(autorizado$protocolo, "135260000012345")
  expect_true(is.na(autorizado$problema))
  expect_match(autorizado$endereco, "CTeRecepcaoSincV4", fixed = TRUE)
  lido = cte_ler(autorizado$xml_autorizado)
  expect_identical(lido$ctes$chave, sub("^CTe", "", cte$Id))
  expect_identical(lido$ctes$situacao, 100L)
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_false(grepl("Header", corpo, fixed = TRUE))
  expect_match(pedidos[[1]]$body$content_type, "CTeRecepcaoSincV4/cteRecepcao\"", fixed = TRUE)
  enviado = texto_do_gzip_em_base64(sub(".*<cteDadosMsg[^>]*>([^<]*)</cteDadosMsg>.*", "\\1", corpo))
  expect_match(enviado, '^<CTe xmlns="http://www.portalfiscal.inf.br/cte">')
  # O QR-Code do autorizador de SP, entre o infCte e a assinatura, sem o sign (a emissão é normal).
  expect_match(enviado, paste0("</infCte><infCTeSupl[^>]*><qrCodCTe>https://homologacao\\.nfe\\.fazenda\\.sp\\.gov\\.br/",
                               "CTeConsulta/qrCode\\?chCTe=", sub("^CTe", "", cte$Id), "&amp;tpAmb=2</qrCodCTe>",
                               "</infCTeSupl><Signature"))
  # O cteProc passa no schema dele.
  schema_do_processado = xml2::read_xml(system.file("schemas", "cte", "procCTe_v4.00.xsd", package = "RNFe"))
  expect_true(xml2::xml_validate(xml2::read_xml(autorizado$xml_autorizado), schema_do_processado))
})

test_that("na conting\u00eancia off-line, o QR-Code do CT-e leva a chave assinada; o CT-e OS vai pelo servi\u00e7o dele", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  os = xml_para_lista(system.file("exemplos", "cte_os_sp.xml", package = "RNFe"))
  os$ide$tpEmis = "2"
  os$ide$dhCont = "2026-10-15T09:00:00-03:00"
  os$ide$xJust = "SEM CONEXAO COM A SEFAZ AUTORIZADORA"
  os$Id = NULL
  os$ide$cDV = NULL
  assinado = xml_assinar(cte_montar(os), CERTIFICADO_DA_MONTAGEM, "teste")
  chave = sub(".*Id=\"CTe([0-9A-Z]{44})\".*", "\\1", assinado)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_recepcao_do_cte("CTeRecepcaoOSV4", "cteRecepcaoOS", retorno_do_cte("retCTeOS", chave, 100))
  })
  autorizado = sefaz_cte_autorizar(assinado, CERTIFICADO_DA_MONTAGEM, "teste")
  expect_identical(autorizado$documento, "CT-e OS")
  expect_match(pedidos[[1]]$body$content_type, "CTeRecepcaoOSV4/cteRecepcaoOS\"", fixed = TRUE)
  expect_match(autorizado$xml_autorizado, "<cteOSProc ", fixed = TRUE)
  enviado = texto_do_gzip_em_base64(sub(".*<cteDadosMsg[^>]*>([^<]*)</cteDadosMsg>.*", "\\1", rawToChar(pedidos[[1]]$body$data)))
  qrcode = xml2::xml_text(xml2::xml_find_first(xml2::read_xml(enviado), "//*[local-name()='qrCodCTe']"))
  assinatura = sub("^.*&sign=", "", qrcode)
  certificado = openssl::read_p12(CERTIFICADO_DA_MONTAGEM, password = "teste")$cert
  expect_true(openssl::signature_verify(charToRaw(chave), openssl::base64_decode(assinatura), hash = openssl::sha1,
                                        pubkey = certificado$pubkey))
})

test_that("o CT-e simplificado e a GTV-e montados s\u00e3o assinados e autorizados pelo servi\u00e7o de cada um", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  simplificado = xml_para_lista(system.file("exemplos", "cte_simp_proc_sp.xml", package = "RNFe"))
  assinado = xml_assinar(cte_montar(simplificado), CERTIFICADO_DA_MONTAGEM, "teste")
  chave = sub("^CTe", "", simplificado$Id)
  gtve = xml_para_lista(system.file("exemplos", "gtve_proc_sp.xml", package = "RNFe"))
  gtve_assinada = xml_assinar(cte_montar(gtve), CERTIFICADO_DA_MONTAGEM, "teste")
  chave_da_gtve = sub("^CTe", "", gtve$Id)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    if (length(pedidos) == 1) {
      return(resposta_da_recepcao_do_cte("CTeRecepcaoSimpV4", "cteRecepcaoSimp", retorno_do_cte("retCTeSimp", chave, 100)))
    }
    resposta_da_recepcao_do_cte("CTeRecepcaoGTVeV4", "cteRecepcaoGTVe", retorno_do_cte("retGTVe", chave_da_gtve, 100))
  })
  autorizado = sefaz_cte_autorizar(assinado, CERTIFICADO_DA_MONTAGEM, "teste")
  expect_identical(autorizado$documento, "CT-e simplificado")
  expect_match(pedidos[[1]]$body$content_type, "CTeRecepcaoSimpV4/cteRecepcaoSimp\"", fixed = TRUE)
  schema_do_simplificado = xml2::read_xml(system.file("schemas", "cte", "procCTeSimp_v4.00.xsd", package = "RNFe"))
  expect_true(xml2::xml_validate(xml2::read_xml(autorizado$xml_autorizado), schema_do_simplificado))
  expect_identical(cte_simplificado_ler(autorizado$xml_autorizado)$ctes$chave, chave)
  da_gtve = sefaz_cte_autorizar(gtve_assinada, CERTIFICADO_DA_MONTAGEM, "teste")
  expect_identical(da_gtve$documento, "GTV-e")
  schema_da_gtve = xml2::read_xml(system.file("schemas", "cte", "procGTVe_v4.00.xsd", package = "RNFe"))
  expect_true(xml2::xml_validate(xml2::read_xml(da_gtve$xml_autorizado), schema_da_gtve))
  expect_identical(gtve_ler(da_gtve$xml_autorizado)$gtves$chave, chave_da_gtve)
})

test_that("a GTV-e em conting\u00eancia sem QR-Code e o documento da SVC n\u00e3o v\u00e3o \u00e0 SEFAZ", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) stop("n\u00e3o devia ter conectado"))
  gtve = xml_para_lista(system.file("exemplos", "gtve_proc_sp.xml", package = "RNFe"))
  gtve$ide$tpEmis = "2"
  gtve$ide$dhCont = "2026-10-15T09:00:00-03:00"
  gtve$ide$xJust = "SEM CONEXAO COM A SEFAZ AUTORIZADORA"
  gtve$Id = NULL
  gtve$ide$cDV = NULL
  expect_error(sefaz_cte_autorizar(xml_assinar(cte_montar(gtve), CERTIFICADO_DA_MONTAGEM, "teste"), CERTIFICADO_DA_MONTAGEM,
                                   "teste"), "informe o infCTeSupl")
  cte = xml_para_lista(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  cte$ide$tpEmis = "7"
  cte$ide$dhCont = "2026-10-15T09:00:00-03:00"
  cte$ide$xJust = "SEFAZ AUTORIZADORA FORA DO AR"
  cte$Id = NULL
  cte$ide$cDV = NULL
  pela_svc = sefaz_cte_autorizar(xml_assinar(cte_montar(cte), CERTIFICADO_DA_MONTAGEM, "teste"), CERTIFICADO_DA_MONTAGEM,
                                 "teste")
  expect_match(pela_svc$problema, "conting\u00eancia SVC")
  expect_true(is.na(pela_svc$situacao))
})

test_that("no xs:any do modal entram s\u00f3 os modais", {
  cte = xml_para_lista(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  cte$infCTeNorm$infModal = list(versaoModal = "4.00", CTe = list(infCte = list(versao = "4.00")))
  expect_error(cte_montar(cte), "\"CTe\" n\u00e3o existe em CTe/infCte/infCTeNorm/infModal")
})

test_that("na sequence opcional que veio, o campo obrigat\u00f3rio de valor \u00fanico entra sozinho", {
  manifesto = xml_para_lista(system.file("exemplos", "mdfe_proc_sp.xml", package = "RNFe"))
  manifesto$infDoc$infMunDescarga = list(list(
    cMunDescarga = "3550308", xMunDescarga = "SAO PAULO",
    infCTe = list(list(chCTe = "35261011444777000161570010000000011000000019",
                       infNFePrestParcial = list(list(chNFe = "35261011222333000181550010000010011123456785"))))
  ))
  manifesto$tot$qCTe = 1
  manifesto$tot$qNFe = NULL
  montado = mdfe_montar(manifesto)
  expect_match(montado, "<indPrestacaoParcial>1</indPrestacaoParcial><infNFePrestParcial>", fixed = TRUE)
})

test_that("no evento, o grupo que o schema do evento deixa repetir vira sempre lista de listas", {
  um = paste0('<eventoCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="4.00"><infEvento ',
              'Id="ID1101103526101144477700016157001000000001100000001901"><cOrgao>35</cOrgao><tpAmb>2</tpAmb>',
              "<CNPJ>11444777000161</CNPJ><chCTe>35261011444777000161570010000000011000000019</chCTe>",
              "<dhEvento>2026-10-15T10:00:00-03:00</dhEvento><tpEvento>110110</tpEvento><nSeqEvento>1</nSeqEvento>",
              '<detEvento versaoEvento="4.00"><evCCeCTe><descEvento>Carta de Correcao</descEvento><infCorrecao>',
              "<grupoAlterado>ide</grupoAlterado><campoAlterado>natOp</campoAlterado><valorAlterado>X</valorAlterado>",
              "</infCorrecao></evCCeCTe></detEvento></infEvento></eventoCTe>")
  lido = xml_para_lista(um)
  expect_null(names(lido$detEvento$evCCeCTe$infCorrecao))
  expect_identical(lido$detEvento$evCCeCTe$infCorrecao[[1]]$campoAlterado, "natOp")
})

test_that("o evento da NFS-e \u00e9 um documento s\u00f3: o infEvento de fora, com o pedido assinado dentro", {
  evento = xml_para_lista(system.file("exemplos", "evento_nfse_cancelamento.xml", package = "RNFe"))
  expect_identical(evento$Id, "EVT35503082211222333000181000000000012326101234567898101101001")
  expect_identical(evento$pedRegEvento$infPedReg$e101101$cMotivo, "1")
  expect_null(evento$Signature)
  # Dois documentos lado a lado continuam sendo um lote.
  um = paste0('<eventoCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="4.00"><infEvento Id="A"/></eventoCTe>')
  expect_error(xml_para_lista(paste0("<lote>", um, um, "</lote>")), "2 documentos")
})

test_that("a autoriza\u00e7\u00e3o do CT-e: os erros antes de qualquer conex\u00e3o", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) stop("n\u00e3o devia ter conectado"))
  cte = xml_para_lista(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  expect_error(sefaz_cte_autorizar(cte_montar(cte), CERTIFICADO_DA_MONTAGEM, "teste"), "n\u00e3o est\u00e1 assinado")
  expect_error(sefaz_cte_autorizar(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), CERTIFICADO_DA_MONTAGEM,
                                   "teste"), "um documento do CT-e")
  expect_error(sefaz_cte_autorizar(cte_montar(cte), CERTIFICADO_DA_MONTAGEM, "teste", ambiente = "producao"),
               "homologacao")
})
