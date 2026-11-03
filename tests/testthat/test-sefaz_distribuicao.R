# Sem rede: o httr2 devolve a resposta no lugar da SEFAZ. respostas/distribuicao_homologacao_an.xml é a resposta real
# do Ambiente Nacional de homologação (03/11/2026) ao primeiro pedido pelo último NSU: 137, nenhum documento. A resposta
# com documentos é montada com dois exemplos do pacote, compactados como a SEFAZ manda (gzip dentro do base64).
CERTIFICADO_DA_DISTRIBUICAO = test_path("certificados", "pessoa_juridica.pfx")
CNPJ_DA_DISTRIBUICAO = "11222333000181"
ENDERECO_DA_DISTRIBUICAO = "https://hom1.nfe.fazenda.gov.br/NFeDistribuicaoDFe/NFeDistribuicaoDFe.asmx"

esquecer_as_respostas_sem_documentos = function() {
  rm(list = ls(quando_nao_havia_mais_documentos), envir = quando_nao_havia_mais_documentos)
}

resposta_da_distribuicao = function(texto) {
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(enc2utf8(texto)))
}

texto_do_exemplo = function(nome_do_arquivo) {
  paste(readLines(system.file("exemplos", nome_do_arquivo, package = "RNFe"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
}

# O texto em gzip e base64, como vem no docZip.
compactado_em_base64 = function(texto) {
  arquivo = tempfile(fileext = ".gz")
  conexao = gzfile(arquivo, "wb")
  writeChar(enc2utf8(texto), conexao, eos = NULL, useBytes = TRUE)
  close(conexao)
  openssl::base64_encode(readBin(arquivo, "raw", file.size(arquivo)))
}

# Um retDistDFeInt com 138, o resumo da NF-e (NSU 1) e o cancelamento dela (NSU 2).
resposta_com_documentos = function(ultimo_nsu, maior_nsu) {
  paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>',
    '<nfeDistDFeInteresseResponse xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeDistribuicaoDFe"><nfeDistDFeInteresseResult>',
    '<retDistDFeInt versao="1.01" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>2</tpAmb><verAplic>TESTE</verAplic>',
    "<cStat>138</cStat><xMotivo>Documento localizado</xMotivo><dhResp>2026-11-03T14:34:32-03:00</dhResp>",
    "<ultNSU>", ultimo_nsu, "</ultNSU><maxNSU>", maior_nsu, "</maxNSU><loteDistDFeInt>",
    '<docZip NSU="000000000000001" schema="resNFe_v1.01.xsd">', compactado_em_base64(texto_do_exemplo("nfe_resumo_sp.xml")), "</docZip>",
    '<docZip NSU="000000000000002" schema="procEventoNFe_v1.00.xsd">', compactado_em_base64(texto_do_exemplo("evento_nfe_cancelamento.xml")),
    "</docZip></loteDistDFeInt></retDistDFeInt></nfeDistDFeInteresseResult></nfeDistDFeInteresseResponse></soap:Body></soap:Envelope>"
  )
}

test_that("a produ\u00e7\u00e3o, um documento, um NSU ou uma chave fora do formato s\u00e3o recusados antes de conectar", {
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", ambiente = "producao"), "homologa\u00e7\u00e3o")
  expect_error(sefaz_distribuicao("123", "qualquer.pfx", "senha"), "CNPJ")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", ultimo_nsu = "12a"), "15 d\u00edgitos")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", nsu = "1234567890123456"), "15 d\u00edgitos")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha",
                                  chave = "35261011222333000181550010000010011123456780"), "d\u00edgito verificador")
})

test_that("nenhum documento: o pedido que vai, a resposta e a espera de uma hora", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  esquecer_as_respostas_sem_documentos()
  on.exit(esquecer_as_respostas_sem_documentos(), add = TRUE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_distribuicao(paste(readLines(test_path("respostas", "distribuicao_homologacao_an.xml"), warn = FALSE), collapse = ""))
  })
  distribuicao = sefaz_distribuicao("11.222.333/0001-81", CERTIFICADO_DA_DISTRIBUICAO, "teste")
  consulta = distribuicao$consulta
  expect_identical(consulta$documento, CNPJ_DA_DISTRIBUICAO)
  expect_identical(consulta$situacao, 137L)
  expect_identical(consulta$motivo, "Nenhum documento localizado")
  expect_equal(as.numeric(consulta$processamento), as.numeric(as.POSIXct("2026-11-03 17:34:32", tz = "UTC")))
  expect_identical(consulta$ultimo_nsu, "000000000000000")
  expect_identical(consulta$maior_nsu, "000000000000000")
  expect_identical(consulta$documentos, 0L)
  expect_identical(consulta$versao_aplicativo, "1.7.8")
  expect_identical(consulta$endereco, ENDERECO_DA_DISTRIBUICAO)
  expect_true(is.na(consulta$problema))
  expect_identical(nrow(distribuicao$documentos), 0L)
  # O pedido: o nfeDadosMsg dentro de nfeDistDFeInteresse, como o WSDL do Ambiente Nacional pede, e o NSU com 15 dígitos.
  expect_identical(pedidos[[1]]$url, ENDERECO_DA_DISTRIBUICAO)
  expect_match(rawToChar(pedidos[[1]]$body$data), paste0(
    '<nfeDistDFeInteresse xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeDistribuicaoDFe"><nfeDadosMsg>',
    '<distDFeInt xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.01"><tpAmb>2</tpAmb><CNPJ>', CNPJ_DA_DISTRIBUICAO,
    "</CNPJ><distNSU><ultNSU>000000000000000</ultNSU></distNSU></distDFeInt></nfeDadosMsg></nfeDistDFeInteresse>"
  ), fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type,
               'action="http://www.portalfiscal.inf.br/nfe/wsdl/NFeDistribuicaoDFe/nfeDistDFeInteresse"', fixed = TRUE)
  # Antes de uma hora, um novo pedido pelo último NSU é recusado sem ir à SEFAZ; pela chave ou por um NSU, não.
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", ultimo_nsu = 0), "esperar uma hora")
  expect_length(pedidos, 1)
  sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", chave = "35261011222333000181550010000010011123456785")
  sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", nsu = 12)
  expect_length(pedidos, 3)
  expect_match(rawToChar(pedidos[[2]]$body$data), "<consChNFe><chNFe>35261011222333000181550010000010011123456785</chNFe></consChNFe>",
               fixed = TRUE)
  expect_match(rawToChar(pedidos[[3]]$body$data), "<consNSU><NSU>000000000000012</NSU></consNSU>", fixed = TRUE)
  # Outro CNPJ não está preso à espera deste.
  sefaz_distribuicao("11444777000161", CERTIFICADO_DA_DISTRIBUICAO, "teste")
  expect_length(pedidos, 4)
})

test_that("os documentos chegam descompactados e passam pelos leitores", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  esquecer_as_respostas_sem_documentos()
  on.exit(esquecer_as_respostas_sem_documentos(), add = TRUE)
  httr2::local_mocked_responses(function(req) resposta_da_distribuicao(resposta_com_documentos("000000000000002", "000000000000005")))
  distribuicao = sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste")
  expect_identical(distribuicao$consulta$situacao, 138L)
  expect_identical(distribuicao$consulta$documentos, 2L)
  documentos = distribuicao$documentos
  expect_identical(documentos$nsu, c("000000000000001", "000000000000002"))
  expect_identical(documentos$schema, c("resNFe_v1.01.xsd", "procEventoNFe_v1.00.xsd"))
  expect_identical(documentos$tipo, c("resNFe", "procEventoNFe"))
  expect_identical(documentos$xml[1], texto_do_exemplo("nfe_resumo_sp.xml"))
  expect_identical(nfe_ler(documentos$xml)$resumos$chave, "35261011222333000181550010000010011123456785")
  expect_identical(eventos_ler(documentos$xml)$eventos$tipo, "110111")
  # O último NSU (2) ainda não é o maior (5): o próximo pedido pode ir já.
  sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", ultimo_nsu = distribuicao$consulta$ultimo_nsu)
  # Quando o último é o maior, não há mais documentos: o seguinte só depois de uma hora.
  httr2::local_mocked_responses(function(req) resposta_da_distribuicao(resposta_com_documentos("000000000000005", "000000000000005")))
  sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", ultimo_nsu = 2)
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", ultimo_nsu = 5), "esperar uma hora")
})
