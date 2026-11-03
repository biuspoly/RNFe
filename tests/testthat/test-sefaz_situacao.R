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

test_that("chave errada, de outro modelo ou respondida com outra chave fica em problema", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_sefaz(texto_do_arquivo(CONSULTA_DA_SVRS))
  })
  nfce = "23261011444777000161650030000000779135724686"
  digito_errado = paste0(substr(CHAVE_INVENTADA_DO_CE, 1, 43), "0")
  consulta = sefaz_situacao(c(digito_errado, nfce, NA, CHAVE_DA_NOTA_SP), CERTIFICADO_DO_TESTE, "teste")
  problemas = consulta$situacoes$problema
  expect_match(problemas[1], "^chave inv\u00e1lida: o d\u00edgito verificador n\u00e3o confere")
  expect_identical(problemas[2], "por enquanto s\u00f3 a NF-e (modelo 55) \u00e9 consultada")
  expect_match(problemas[3], "^chave inv\u00e1lida")
  # A SVRS (de mentira) respondeu sobre a chave do CE a uma pergunta sobre a de SP.
  expect_identical(problemas[4], "a SEFAZ respondeu sobre outra chave")
  expect_length(pedidos, 1)
})

test_that("sem chave nenhuma, as tabelas v\u00eam vazias com as colunas certas", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) stop("n\u00e3o devia ter conectado"))
  vazia = sefaz_situacao(character(), CERTIFICADO_DO_TESTE, "teste")
  expect_identical(nrow(vazia$situacoes), 0L)
  expect_identical(names(vazia$situacoes), c("chave", "uf", "autorizador", "ambiente", "situacao", "motivo", "recebimento",
                                             "protocolo", "autorizacao", "digest_value", "versao_aplicativo", "endereco",
                                             "problema"))
  expect_identical(nrow(vazia$eventos), 0L)
})
