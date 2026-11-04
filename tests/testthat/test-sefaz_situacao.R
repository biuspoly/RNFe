# Sem rede: o httr2 devolve a resposta no lugar da SEFAZ. respostas/consulta_homologacao_svrs.xml é a resposta real
# da SVRS de homologação (03/11/2026) a uma chave inventada do CE (CNPJ de exemplo), que não consta lá. A resposta da
# nota cancelada é montada com o protocolo de nfe_proc_sp.xml e o cancelamento de evento_nfe_cancelamento.xml.
CERTIFICADO_DO_TESTE = test_path("certificados", "pessoa_juridica.pfx")
CONSULTA_DA_SVRS = test_path("respostas", "consulta_homologacao_svrs.xml")
CHAVE_INVENTADA_DO_CE = "23261011222333000181550010000010011123456784"
CHAVE_DA_NOTA_SP = "35261011222333000181550010000010011123456785"

resposta_da_sefaz = function(texto) {
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(enc2utf8(texto)))
}

texto_do_arquivo = function(arquivo) {
  paste(readLines(arquivo, encoding = "UTF-8", warn = FALSE), collapse = "\n")
}

# O retConsSitNFe de uma nota cancelada: a resposta de 101, o protocolo de autorização e o evento de cancelamento.
resposta_da_nota_cancelada = function() {
  nota = texto_do_arquivo(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"))
  cancelamento = texto_do_arquivo(system.file("exemplos", "evento_nfe_cancelamento.xml", package = "RNFe"))
  protocolo = regmatches(nota, regexpr("(?s)<protNFe.*</protNFe>", nota, perl = TRUE))
  evento = regmatches(cancelamento, regexpr("(?s)<procEventoNFe.*</procEventoNFe>", cancelamento, perl = TRUE))
  paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>',
    '<nfeResultMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeConsultaProtocolo4">',
    '<retConsSitNFe versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>2</tpAmb><verAplic>TESTE</verAplic>',
    "<cStat>101</cStat><xMotivo>Cancelamento de NF-e homologado</xMotivo><cUF>35</cUF>",
    "<dhRecbto>2026-10-16T09:00:00-03:00</dhRecbto><chNFe>", CHAVE_DA_NOTA_SP, "</chNFe>", protocolo, evento,
    "</retConsSitNFe></nfeResultMsg></soap:Body></soap:Envelope>"
  )
}

test_that("a produ\u00e7\u00e3o \u00e9 recusada antes de qualquer conex\u00e3o", {
  expect_error(sefaz_situacao(CHAVE_DA_NOTA_SP, "qualquer.pfx", "senha", ambiente = "producao"), "homologa\u00e7\u00e3o")
})

test_that("a chave que n\u00e3o consta: o pedido que vai e a resposta da SVRS em colunas", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_sefaz(texto_do_arquivo(CONSULTA_DA_SVRS))
  })
  consulta = sefaz_situacao(paste0("NFe", CHAVE_INVENTADA_DO_CE), CERTIFICADO_DO_TESTE, "teste")
  situacao = consulta$situacoes
  expect_identical(situacao$chave, CHAVE_INVENTADA_DO_CE)
  expect_identical(situacao$documento, "NF-e")
  expect_identical(situacao$uf, "CE")
  expect_identical(situacao$autorizador, "SVRS")
  expect_identical(situacao$ambiente, "homologacao")
  expect_identical(situacao$situacao, 217L)
  expect_identical(situacao$motivo, "Rejeicao: NF-e nao consta na base de dados da SEFAZ")
  expect_equal(as.numeric(situacao$recebimento), as.numeric(as.POSIXct("2026-11-03 13:20:16", tz = "UTC")))
  expect_identical(attr(situacao$recebimento, "tzone"), "America/Sao_Paulo")
  expect_true(is.na(situacao$protocolo))
  expect_true(is.na(situacao$autorizacao))
  expect_identical(situacao$versao_aplicativo, "SVRS2606241626")
  expect_true(is.na(situacao$problema))
  expect_identical(nrow(consulta$eventos), 0L)
  # O pedido: o endereço da consulta na Relação de Serviços Web, a action do WSDL e o consSitNFe com o ambiente 2.
  expect_length(pedidos, 1)
  expect_identical(pedidos[[1]]$url, "https://nfe-homologacao.svrs.rs.gov.br/ws/NfeConsulta/NfeConsulta4.asmx")
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeConsultaProtocolo4">', fixed = TRUE)
  expect_match(corpo, paste0('<consSitNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00"><tpAmb>2</tpAmb>',
                             "<xServ>CONSULTAR</xServ><chNFe>", CHAVE_INVENTADA_DO_CE, "</chNFe></consSitNFe>"), fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type,
               'action="http://www.portalfiscal.inf.br/nfe/wsdl/NFeConsultaProtocolo4/nfeConsultaNF"', fixed = TRUE)
})

test_that("a nota cancelada: o protocolo de autoriza\u00e7\u00e3o e o evento de cancelamento", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_sefaz(resposta_da_nota_cancelada())
  })
  consulta = sefaz_situacao(CHAVE_DA_NOTA_SP, CERTIFICADO_DO_TESTE, "teste")
  situacao = consulta$situacoes
  expect_identical(situacao$autorizador, "SP")
  expect_identical(pedidos[[1]]$url, "https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeconsultaprotocolo4.asmx")
  expect_identical(situacao$situacao, 101L)
  expect_identical(situacao$protocolo, "135260000012345")
  expect_equal(as.numeric(situacao$autorizacao), as.numeric(as.POSIXct("2026-10-15 13:31:02", tz = "UTC")))
  expect_identical(situacao$digest_value, "AAAAAAAAAAAAAAAAAAAAAAAAAAA=")
  expect_true(is.na(situacao$problema))
  eventos = consulta$eventos
  expect_identical(eventos$chave, CHAVE_DA_NOTA_SP)
  expect_identical(eventos$tipo, "110111")
  expect_identical(eventos$descricao, "Cancelamento")
  expect_identical(eventos$situacao, 135L)
  expect_false("arquivo" %in% names(eventos))
  # O mesmo evento lido do arquivo dá a mesma linha.
  do_arquivo = eventos_ler(system.file("exemplos", "evento_nfe_cancelamento.xml", package = "RNFe"), todos_os_campos = FALSE)$eventos
  do_arquivo$arquivo = NULL
  expect_identical(eventos, do_arquivo)
})

test_that("chave errada ou respondida com outra chave fica em problema", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_sefaz(texto_do_arquivo(CONSULTA_DA_SVRS))
  })
  digito_errado = paste0(substr(CHAVE_INVENTADA_DO_CE, 1, 43), "0")
  consulta = sefaz_situacao(c(digito_errado, NA, CHAVE_DA_NOTA_SP), CERTIFICADO_DO_TESTE, "teste")
  problemas = consulta$situacoes$problema
  expect_match(problemas[1], "^chave inv\u00e1lida: o d\u00edgito verificador n\u00e3o confere")
  expect_match(problemas[2], "^chave inv\u00e1lida")
  # A SVRS (de mentira) respondeu sobre a chave do CE a uma pergunta sobre a de SP.
  expect_identical(problemas[3], "a SEFAZ respondeu sobre outra chave")
  expect_length(pedidos, 1)
})

# Uma chave inventada do modelo e da UF (CNPJ de exemplo).
chave_inventada = function(codigo_da_uf, modelo) {
  sem_digito = paste0(codigo_da_uf, "2610", "11222333000181", modelo, "001", "000001001", "1", "12345678")
  paste0(sem_digito, chave_digito(sem_digito))
}

test_that("a NFC-e vai ao autorizador dela: SVRS, a SEFAZ pr\u00f3pria ou MG", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  # A resposta da SVRS gravada, com a chave que foi perguntada.
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    chave_perguntada = regmatches(rawToChar(req$body$data), regexpr("(?<=<chNFe>)[0-9]{44}", rawToChar(req$body$data), perl = TRUE))
    resposta_da_sefaz(sub(CHAVE_INVENTADA_DO_CE, chave_perguntada, texto_do_arquivo(CONSULTA_DA_SVRS), fixed = TRUE))
  })
  # PE (o cupom de exemplo do usuário), MA (SVAN na NF-e, SVRS na NFC-e), SP (própria) e MG (fora do Portal da NFC-e).
  consulta = sefaz_situacao(c(chave_inventada("26", "65"), chave_inventada("21", "65"), chave_inventada("35", "65"), chave_inventada("31", "65")),
                            CERTIFICADO_DO_TESTE, "teste")
  situacoes = consulta$situacoes
  expect_identical(situacoes$documento, rep("NFC-e", 4))
  expect_identical(situacoes$uf, c("PE", "MA", "SP", "MG"))
  expect_identical(situacoes$autorizador, c("SVRS", "SVRS", "SP", "MG"))
  urls = vapply(pedidos, function(pedido) pedido$url, character(1))
  expect_identical(urls, c(
    "https://nfce-homologacao.svrs.rs.gov.br/ws/NfeConsulta/NfeConsulta4.asmx",
    "https://nfce-homologacao.svrs.rs.gov.br/ws/NfeConsulta/NfeConsulta4.asmx",
    "https://homologacao.nfce.fazenda.sp.gov.br/ws/NFeConsultaProtocolo4.asmx",
    "https://hnfce.fazenda.mg.gov.br/nfce/services/NFeConsultaProtocolo4"
  ))
  expect_identical(situacoes$situacao, rep(217L, 4))
  expect_true(all(is.na(situacoes$problema)))
  # O pedido é o mesmo da NF-e: o consSitNFe no NFeConsultaProtocolo4.
  expect_match(rawToChar(pedidos[[1]]$body$data), paste0("<chNFe>", chave_inventada("26", "65"), "</chNFe>"), fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type, "NFeConsultaProtocolo4/nfeConsultaNF", fixed = TRUE)
})

# respostas/consulta_cte_homologacao_svrs.xml, consulta_cte_homologacao_sp.xml e consulta_mdfe_homologacao_svrs.xml são
# as respostas reais de homologação (03/11/2026) a chaves inventadas do CE e de SP (CNPJ de exemplo), que não constam lá.
CONSULTA_DO_CTE_NA_SVRS = test_path("respostas", "consulta_cte_homologacao_svrs.xml")
CONSULTA_DO_CTE_EM_SP = test_path("respostas", "consulta_cte_homologacao_sp.xml")
CONSULTA_DO_MDFE_NA_SVRS = test_path("respostas", "consulta_mdfe_homologacao_svrs.xml")
CHAVE_DO_CTE_SP = "35261012ABC34501DE35570010000005551876543210"
CHAVE_DO_MDFE_SP = "35261033344455500070580010000003211112233448"

test_that("o CT-e, o CT-e OS e a GTV-e v\u00e3o ao autorizador do CT-e; o MDF-e, \u00e0 SVRS", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    if (grepl("mdfe", req$url, fixed = TRUE)) {
      return(resposta_da_sefaz(texto_do_arquivo(CONSULTA_DO_MDFE_NA_SVRS)))
    }
    if (grepl("fazenda.sp.gov.br", req$url, fixed = TRUE)) {
      return(resposta_da_sefaz(texto_do_arquivo(CONSULTA_DO_CTE_EM_SP)))
    }
    resposta_da_sefaz(texto_do_arquivo(CONSULTA_DO_CTE_NA_SVRS))
  })
  # CT-e do CE (SVRS), de PE (SVSP) e de SP (própria), CT-e OS do RS (própria), GTV-e de SP e MDF-e do CE.
  chaves = c(chave_inventada("23", "57"), chave_inventada("26", "57"), chave_inventada("35", "57"),
             chave_inventada("43", "67"), chave_inventada("35", "64"), chave_inventada("23", "58"))
  consulta = sefaz_situacao(chaves, CERTIFICADO_DO_TESTE, "teste")
  situacoes = consulta$situacoes
  expect_identical(situacoes$documento, c("CT-e", "CT-e", "CT-e", "CT-e OS", "GTV-e", "MDF-e"))
  expect_identical(situacoes$autorizador, c("SVRS", "SVSP", "SP", "RS", "SP", "SVRS"))
  urls = vapply(pedidos, function(pedido) pedido$url, character(1))
  expect_identical(urls, c(
    "https://cte-homologacao.svrs.rs.gov.br/ws/CTeConsultaV4/CTeConsultaV4.asmx",
    "https://homologacao.nfe.fazenda.sp.gov.br/CTeWS/WS/CTeConsultaV4.asmx",
    "https://homologacao.nfe.fazenda.sp.gov.br/CTeWS/WS/CTeConsultaV4.asmx",
    "https://cte-homologacao.svrs.rs.gov.br/ws/CTeConsultaV4/CTeConsultaV4.asmx",
    "https://homologacao.nfe.fazenda.sp.gov.br/CTeWS/WS/CTeConsultaV4.asmx",
    "https://mdfe-homologacao.svrs.rs.gov.br/ws/MDFeConsulta/MDFeConsulta.asmx"
  ))
  expect_identical(situacoes$situacao, rep(217L, 6))
  expect_identical(situacoes$motivo[1], "Rejeicao: CT-e nao consta na base de dados da SEFAZ")
  expect_identical(situacoes$motivo[3], "Rejei\u00e7\u00e3o: CTe n\u00e3o consta na base de dados da SEFAZ.")
  expect_identical(situacoes$motivo[6], "Rejeicao: MDF-e nao consta na base de dados da SEFAZ")
  # O retorno do CT-e e do MDF-e não traz a hora do recebimento.
  expect_true(all(is.na(situacoes$recebimento)))
  expect_true(all(is.na(situacoes$problema)))
  # O pedido do CT-e: o consSitCTe no CTeConsultaV4, sem cabeçalho.
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, '<cteDadosMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CTeConsultaV4">', fixed = TRUE)
  expect_match(corpo, paste0('<consSitCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="4.00"><tpAmb>2</tpAmb>',
                             "<xServ>CONSULTAR</xServ><chCTe>", chaves[1], "</chCTe></consSitCTe>"), fixed = TRUE)
  expect_false(grepl("Header", corpo, fixed = TRUE))
  expect_match(pedidos[[1]]$body$content_type,
               'action="http://www.portalfiscal.inf.br/cte/wsdl/CTeConsultaV4/cteConsultaCT"', fixed = TRUE)
  # O do MDF-e: o consSitMDFe no MDFeConsulta, com a UF da chave e a versão no cabeçalho mdfeCabecMsg.
  corpo = rawToChar(pedidos[[6]]$body$data)
  expect_match(corpo, paste0('<soap12:Header><mdfeCabecMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsulta">',
                             "<cUF>23</cUF><versaoDados>3.00</versaoDados></mdfeCabecMsg></soap12:Header>"), fixed = TRUE)
  expect_match(corpo, paste0('<mdfeDadosMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsulta">',
                             '<consSitMDFe xmlns="http://www.portalfiscal.inf.br/mdfe" versao="3.00"><tpAmb>2</tpAmb>',
                             "<xServ>CONSULTAR</xServ><chMDFe>", chaves[6], "</chMDFe></consSitMDFe></mdfeDadosMsg>"),
               fixed = TRUE)
  expect_match(pedidos[[6]]$body$content_type,
               'action="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsulta/mdfeConsultaMDF"', fixed = TRUE)
})

# O retConsSitCTe de um CT-e cancelado: o protocolo de cte_proc_sp.xml e o cancelamento de evento_cte_cancelamento.xml.
resposta_do_cte_cancelado = function() {
  cte = texto_do_arquivo(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  cancelamento = texto_do_arquivo(system.file("exemplos", "evento_cte_cancelamento.xml", package = "RNFe"))
  protocolo = regmatches(cte, regexpr("(?s)<protCTe.*</protCTe>", cte, perl = TRUE))
  evento = regmatches(cancelamento, regexpr("(?s)<procEventoCTe.*</procEventoCTe>", cancelamento, perl = TRUE))
  paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>',
    '<cteConsultaCTResult xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CTeConsultaV4">',
    '<retConsSitCTe versao="4.00" xmlns="http://www.portalfiscal.inf.br/cte"><tpAmb>2</tpAmb><verAplic>TESTE</verAplic>',
    "<cStat>101</cStat><xMotivo>Cancelamento de CT-e homologado</xMotivo><cUF>35</cUF>", protocolo, evento,
    "</retConsSitCTe></cteConsultaCTResult></soap:Body></soap:Envelope>"
  )
}

# O retConsSitMDFe de um MDF-e encerrado: o protocolo de mdfe_proc_sp.xml e o encerramento de evento_mdfe_encerramento.xml.
resposta_do_mdfe_encerrado = function() {
  mdfe = texto_do_arquivo(system.file("exemplos", "mdfe_proc_sp.xml", package = "RNFe"))
  encerramento = texto_do_arquivo(system.file("exemplos", "evento_mdfe_encerramento.xml", package = "RNFe"))
  protocolo = regmatches(mdfe, regexpr("(?s)<protMDFe.*</protMDFe>", mdfe, perl = TRUE))
  evento = regmatches(encerramento, regexpr("(?s)<procEventoMDFe.*</procEventoMDFe>", encerramento, perl = TRUE))
  paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>',
    '<mdfeConsultaMDFResult xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsulta">',
    '<retConsSitMDFe versao="3.00" xmlns="http://www.portalfiscal.inf.br/mdfe"><tpAmb>2</tpAmb><verAplic>TESTE</verAplic>',
    "<cStat>132</cStat><xMotivo>Encerramento de MDF-e homologado</xMotivo><cUF>35</cUF>", protocolo, evento,
    "</retConsSitMDFe></mdfeConsultaMDFResult></soap:Body></soap:Envelope>"
  )
}

test_that("o CT-e cancelado e o MDF-e encerrado: o protocolo, a chave dele e o evento", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) {
    if (grepl("mdfe", req$url, fixed = TRUE)) {
      return(resposta_da_sefaz(resposta_do_mdfe_encerrado()))
    }
    resposta_da_sefaz(resposta_do_cte_cancelado())
  })
  # A terceira chave é de outro CT-e de SP, respondida com o protocolo do cancelado.
  consulta = sefaz_situacao(c(CHAVE_DO_CTE_SP, CHAVE_DO_MDFE_SP, chave_inventada("35", "57")), CERTIFICADO_DO_TESTE, "teste")
  situacoes = consulta$situacoes
  expect_identical(situacoes$documento, c("CT-e", "MDF-e", "CT-e"))
  # A resposta sobre outra chave não fica na linha da terceira: só o problema.
  expect_identical(situacoes$situacao, c(101L, 132L, NA))
  expect_true(is.na(situacoes$protocolo[3]))
  expect_identical(situacoes$protocolo[1:2], c("135260000098765", "935260000011111"))
  expect_equal(as.numeric(situacoes$autorizacao[1]), as.numeric(as.POSIXct("2026-10-15 17:01:30", tz = "UTC")))
  expect_equal(as.numeric(situacoes$autorizacao[2]), as.numeric(as.POSIXct("2026-10-15 18:00:40", tz = "UTC")))
  expect_identical(situacoes$digest_value[1], "AAAAAAAAAAAAAAAAAAAAAAAAAAA=")
  expect_true(all(is.na(situacoes$problema[1:2])))
  # O retorno do CT-e não repete a chave: é a do protocolo que mostra que a SEFAZ respondeu sobre outra.
  expect_identical(situacoes$problema[3], "a SEFAZ respondeu sobre outra chave")
  # Os eventos das duas respostas certas, iguais aos lidos dos arquivos.
  eventos = consulta$eventos
  expect_identical(eventos$chave, c(CHAVE_DO_CTE_SP, CHAVE_DO_MDFE_SP))
  expect_identical(eventos$tipo, c("110111", "110112"))
  do_arquivo = eventos_ler(system.file("exemplos", c("evento_cte_cancelamento.xml", "evento_mdfe_encerramento.xml"),
                                       package = "RNFe"), todos_os_campos = FALSE)$eventos
  do_arquivo$arquivo = NULL
  expect_identical(eventos, do_arquivo)
})

test_that("modelo que n\u00e3o \u00e9 consultado, chave repetida, hora com mil\u00e9simos e evento que n\u00e3o foi lido", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  com_milesimos = sub("2026-10-16T09:00:00-03:00", "2026-10-16T09:00:00.218-03:00", resposta_da_nota_cancelada(), fixed = TRUE)
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_sefaz(com_milesimos)
  })
  # A chave do CF-e SAT (modelo 59) confere, mas n\u00e3o \u00e9 consultada: n\u00e3o derruba as outras.
  cupom_sat = chave_inventada("35", "59")
  consulta = sefaz_situacao(c(CHAVE_DA_NOTA_SP, cupom_sat, CHAVE_DA_NOTA_SP), CERTIFICADO_DO_TESTE, "teste")
  situacoes = consulta$situacoes
  expect_identical(situacoes$problema[2], "o modelo 59 n\u00e3o \u00e9 consultado pelo RNFe")
  # A chave repetida foi uma vez s\u00f3, e a linha dela \u00e9 igual \u00e0 da primeira; o evento n\u00e3o sai em dobro.
  expect_length(pedidos, 1)
  expect_identical(as.list(situacoes[3, ]), as.list(situacoes[1, ]))
  expect_identical(nrow(consulta$eventos), 1L)
  expect_equal(as.numeric(situacoes$recebimento[1]), as.numeric(as.POSIXct("2026-10-16 12:00:00", tz = "UTC")))
  # Um evento que veio e n\u00e3o foi lido n\u00e3o some calado.
  evento_vazio = sub("(?s)<procEventoNFe.*</procEventoNFe>", '<procEventoNFe versao="1.00"></procEventoNFe>',
                     resposta_da_nota_cancelada(), perl = TRUE)
  httr2::local_mocked_responses(function(req) resposta_da_sefaz(evento_vazio))
  situacao = sefaz_situacao(CHAVE_DA_NOTA_SP, CERTIFICADO_DO_TESTE, "teste")$situacoes
  expect_identical(situacao$problema, "a SEFAZ mandou 1 evento(s), e o RNFe leu 0")
})

test_that("sem chave nenhuma, as tabelas v\u00eam vazias com as colunas certas", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) stop("n\u00e3o devia ter conectado"))
  vazia = sefaz_situacao(character(), CERTIFICADO_DO_TESTE, "teste")
  expect_identical(nrow(vazia$situacoes), 0L)
  expect_identical(names(vazia$situacoes), c("chave", "documento", "uf", "autorizador", "ambiente", "situacao", "motivo",
                                             "recebimento", "protocolo", "autorizacao", "digest_value", "versao_aplicativo",
                                             "endereco", "problema"))
  expect_identical(nrow(vazia$eventos), 0L)
})
