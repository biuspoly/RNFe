# Sem rede: o httr2 devolve a resposta no lugar da SEFAZ. respostas/distribuicao_homologacao_an.xml é a resposta real
# do Ambiente Nacional de homologação (03/11/2026) ao primeiro pedido pelo último NSU: 137, nenhum documento; a
# distribuicao_cte_homologacao_an.xml, a do CT-e (04/11/2026), também 137. As respostas com documentos são montadas com
# exemplos do pacote, compactados como a SEFAZ manda (gzip dentro do base64).
CERTIFICADO_DA_DISTRIBUICAO = test_path("certificados", "pessoa_juridica.pfx")
CNPJ_DA_DISTRIBUICAO = "11222333000181"
ENDERECO_DA_DISTRIBUICAO = "https://hom1.nfe.fazenda.gov.br/NFeDistribuicaoDFe/NFeDistribuicaoDFe.asmx"
ENDERECO_DA_DISTRIBUICAO_DO_CTE = "https://hom1.cte.fazenda.gov.br/CTeDistribuicaoDFe/CTeDistribuicaoDFe.asmx"

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

# Um retDistDFeInt do CT-e com 138: o CT-e (NSU 1), o cancelamento dele (NSU 2) e uma GTV-e (NSU 3). O dhResp vem sem o
# fuso, como na resposta real.
resposta_do_cte_com_documentos = function() {
  paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>',
    '<cteDistDFeInteresseResponse xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CTeDistribuicaoDFe"><cteDistDFeInteresseResult>',
    '<retDistDFeInt versao="1.00" xmlns="http://www.portalfiscal.inf.br/cte"><tpAmb>2</tpAmb><verAplic>TESTE</verAplic>',
    "<cStat>138</cStat><xMotivo>Documento localizado.</xMotivo><dhResp>2026-11-04T09:44:12</dhResp>",
    "<ultNSU>000000000000003</ultNSU><maxNSU>000000000000003</maxNSU><loteDistDFeInt>",
    '<docZip NSU="000000000000001" schema="procCTe_v4.00.xsd">', compactado_em_base64(texto_do_exemplo("cte_proc_sp.xml")), "</docZip>",
    '<docZip NSU="000000000000002" schema="procEventoCTe_v4.00.xsd">',
    compactado_em_base64(texto_do_exemplo("evento_cte_cancelamento.xml")), "</docZip>",
    '<docZip NSU="000000000000003" schema="procGTVe_v4.00.xsd">', compactado_em_base64(texto_do_exemplo("gtve_proc_sp.xml")), "</docZip>",
    "</loteDistDFeInt></retDistDFeInt></cteDistDFeInteresseResult></cteDistDFeInteresseResponse></soap:Body></soap:Envelope>"
  )
}

# A resposta real de cada distribui\u00e7\u00e3o, pelo endere\u00e7o pedido.
resposta_real_sem_documentos = function(req) {
  arquivo = "distribuicao_homologacao_an.xml"
  if (grepl("hom1.cte.fazenda.gov.br", req$url, fixed = TRUE)) {
    arquivo = "distribuicao_cte_homologacao_an.xml"
  }
  resposta_da_distribuicao(paste(readLines(test_path("respostas", arquivo), warn = FALSE), collapse = ""))
}

test_that("a produ\u00e7\u00e3o, um documento, um NSU ou uma chave fora do formato s\u00e3o recusados antes de conectar", {
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", ambiente = "producao"), "homologa\u00e7\u00e3o")
  expect_error(sefaz_distribuicao("123", "qualquer.pfx", "senha"), "CNPJ")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", ultimo_nsu = "12a"), "15 d\u00edgitos")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", nsu = "1234567890123456"), "15 d\u00edgitos")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha",
                                  chave = "35261011222333000181550010000010011123456780"), "d\u00edgito verificador")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", distribuicao = "MDF-e"), "distribuicao")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", uf = "XX"), "UF desconhecida")
  # O CT-e: a UF de quem pede \u00e9 obrigat\u00f3ria, o CNPJ s\u00f3 com n\u00fameros e n\u00e3o h\u00e1 busca pela chave.
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", distribuicao = "CT-e"), "cUFAutor")
  expect_error(sefaz_distribuicao("12ABC34501DE35", "qualquer.pfx", "senha", distribuicao = "CT-e", uf = "SP"), "letras")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", distribuicao = "CT-e", uf = "SP",
                                  chave = "35261011222333000181570010000010011123456785"), "pela chave")
  # Pela chave, só NF-e (NT 2014.002, regra H122); uma chave, um NSU e uma UF por pedido; o NSU é inteiro.
  sem_digito = "3526101122233300018165001000001001112345678"
  chave_de_nfce = paste0(sem_digito, chave_digito(sem_digito))
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", chave = chave_de_nfce), "modelo 55")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha",
                                  chave = rep("35261011222333000181550010000010011123456785", 2)), "uma chave")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", nsu = c(1, 2)), "um NSU")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", nsu = 1.5), "inteiro")
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, "qualquer.pfx", "senha", uf = c("SP", "CE")), "uma UF")
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
  expect_identical(consulta$distribuicao, "NF-e")
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
  sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", nsu = 12, uf = "sp")
  expect_length(pedidos, 3)
  expect_match(rawToChar(pedidos[[2]]$body$data), "<consChNFe><chNFe>35261011222333000181550010000010011123456785</chNFe></consChNFe>",
               fixed = TRUE)
  # Na NF-e a UF de quem pede é opcional: vai quando informada.
  expect_match(rawToChar(pedidos[[3]]$body$data),
               "<tpAmb>2</tpAmb><cUFAutor>35</cUFAutor><CNPJ>11222333000181</CNPJ><consNSU><NSU>000000000000012</NSU></consNSU>",
               fixed = TRUE)
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

test_that("CT-e: o pedido que vai, a resposta real (hora sem o fuso) e a espera separada da NF-e", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  esquecer_as_respostas_sem_documentos()
  on.exit(esquecer_as_respostas_sem_documentos(), add = TRUE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_real_sem_documentos(req)
  })
  distribuicao = sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", distribuicao = "CT-e", uf = "ce")
  consulta = distribuicao$consulta
  expect_identical(consulta$distribuicao, "CT-e")
  expect_identical(consulta$situacao, 137L)
  expect_identical(consulta$motivo, "Nenhum documento localizado.")
  # O dhResp do CT-e vem sem o fuso: é a hora de Brasília.
  expect_equal(as.numeric(consulta$processamento), as.numeric(as.POSIXct("2026-11-04 12:44:12", tz = "UTC")))
  expect_identical(consulta$ultimo_nsu, "000000000000000")
  expect_identical(consulta$maior_nsu, "000000000000000")
  expect_identical(consulta$versao_aplicativo, "2.1.2_2611040944")
  expect_identical(consulta$endereco, ENDERECO_DA_DISTRIBUICAO_DO_CTE)
  expect_true(is.na(consulta$problema))
  # O pedido: o cteDadosMsg dentro de cteDistDFeInteresse, como o WSDL pede, e o cUFAutor logo depois do ambiente.
  expect_identical(pedidos[[1]]$url, ENDERECO_DA_DISTRIBUICAO_DO_CTE)
  expect_match(rawToChar(pedidos[[1]]$body$data), paste0(
    '<cteDistDFeInteresse xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CTeDistribuicaoDFe"><cteDadosMsg>',
    '<distDFeInt xmlns="http://www.portalfiscal.inf.br/cte" versao="1.00"><tpAmb>2</tpAmb><cUFAutor>23</cUFAutor><CNPJ>',
    CNPJ_DA_DISTRIBUICAO, "</CNPJ><distNSU><ultNSU>000000000000000</ultNSU></distNSU></distDFeInt></cteDadosMsg>",
    "</cteDistDFeInteresse>"
  ), fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type,
               'action="http://www.portalfiscal.inf.br/cte/wsdl/CTeDistribuicaoDFe/cteDistDFeInteresse"', fixed = TRUE)
  # A espera do CT-e não prende a NF-e do mesmo CNPJ, e a da NF-e não prende o CT-e.
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", distribuicao = "CT-e", uf = "CE"),
               "NT 2015.002 manda esperar uma hora")
  sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste")
  expect_length(pedidos, 2)
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste"), "NT 2014.002 manda esperar uma hora")
  # O NSU que faltou ainda vai.
  sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", nsu = 7, distribuicao = "CT-e", uf = "CE")
  expect_length(pedidos, 3)
  expect_match(rawToChar(pedidos[[3]]$body$data), "<consNSU><NSU>000000000000007</NSU></consNSU>", fixed = TRUE)
})

test_that("CT-e: os documentos chegam descompactados e passam pelos leitores do CT-e, da GTV-e e dos eventos", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  esquecer_as_respostas_sem_documentos()
  on.exit(esquecer_as_respostas_sem_documentos(), add = TRUE)
  httr2::local_mocked_responses(function(req) resposta_da_distribuicao(resposta_do_cte_com_documentos()))
  distribuicao = sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", distribuicao = "CT-e", uf = "SP")
  expect_identical(distribuicao$consulta$situacao, 138L)
  expect_identical(distribuicao$consulta$documentos, 3L)
  documentos = distribuicao$documentos
  expect_identical(documentos$nsu, c("000000000000001", "000000000000002", "000000000000003"))
  expect_identical(documentos$tipo, c("procCTe", "procEventoCTe", "procGTVe"))
  expect_identical(documentos$xml[1], texto_do_exemplo("cte_proc_sp.xml"))
  # Cada leitor pega o que é dele e aponta o resto em problema.
  expect_identical(cte_ler(documentos$xml)$ctes$chave, "35261012ABC34501DE35570010000005551876543210")
  expect_identical(gtve_ler(documentos$xml)$gtves$chave, "35261011444777000161640010000005011246813570")
  expect_identical(eventos_ler(documentos$xml)$eventos$tipo, "110111")
  # O último NSU já é o maior: o seguinte pelo último NSU, só depois de uma hora.
  expect_error(sefaz_distribuicao(CNPJ_DA_DISTRIBUICAO, CERTIFICADO_DA_DISTRIBUICAO, "teste", ultimo_nsu = 3,
                                  distribuicao = "CT-e", uf = "SP"), "esperar uma hora")
})
