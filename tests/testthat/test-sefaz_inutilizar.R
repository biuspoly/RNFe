# Sem rede: a resposta montada à mão com a estrutura da SVRS de homologação (23/11/2026, quando o RNFe inutilizou um
# número de teste por lá), com o CNPJ do certificado de teste.
CERTIFICADO_DA_INUTILIZACAO = test_path("certificados", "pessoa_juridica.pfx")

resposta_da_inutilizacao = function(situacao, motivo, com_protocolo = TRUE) {
  protocolo = if (com_protocolo) "<nProt>124260000012345</nProt>" else ""
  texto = paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>',
    '<nfeResultMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeInutilizacao4"><retInutNFe versao="4.00" ',
    'xmlns="http://www.portalfiscal.inf.br/nfe"><infInut><tpAmb>2</tpAmb><verAplic>SVRS202611231000</verAplic><cStat>',
    situacao, "</cStat><xMotivo>", motivo, "</xMotivo><cUF>23</cUF><ano>26</ano><CNPJ>11222333000181</CNPJ><mod>55</mod>",
    "<serie>1</serie><nNFIni>120</nNFIni><nNFFin>122</nNFFin><dhRecbto>2026-11-23T16:30:00-03:00</dhRecbto>", protocolo,
    "</infInut></retInutNFe></nfeResultMsg></soap:Body></soap:Envelope>"
  )
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(texto))
}

inutilizar_de_teste = function(...) {
  argumentos = list(cnpj = "11.222.333/0001-81", uf = "CE", serie = 1, numero_inicial = 120, numero_final = 122,
                    justificativa = "NUMERACAO PULADA NA EMISSAO", certificado = CERTIFICADO_DA_INUTILIZACAO,
                    senha = "teste", ano = 2026)
  mudancas = list(...)
  argumentos[names(mudancas)] = mudancas
  do.call(sefaz_inutilizar, argumentos)
}

test_that("a inutiliza\u00e7\u00e3o homologada: o pedido assinado, o Id e o procInutNFe", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_inutilizacao(102, "Inutilizacao de numero homologado")
  })
  inutilizada = inutilizar_de_teste()
  expect_identical(inutilizada$situacao, 102L)
  expect_identical(inutilizada$protocolo, "124260000012345")
  expect_true(is.na(inutilizada$problema))
  expect_match(inutilizada$endereco, "nfeinutilizacao4", ignore.case = TRUE)
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(pedidos[[1]]$body$content_type, "NFeInutilizacao4/nfeInutilizacaoNF", fixed = TRUE)
  expect_match(corpo, paste0('<inutNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00"><infInut Id="ID2326',
                             "1122233300018155001000000120000000122\"><tpAmb>2</tpAmb><xServ>INUTILIZAR</xServ><cUF>23</cUF>",
                             "<ano>26</ano><CNPJ>11222333000181</CNPJ><mod>55</mod><serie>1</serie><nNFIni>120</nNFIni>",
                             "<nNFFin>122</nNFFin><xJust>NUMERACAO PULADA NA EMISSAO</xJust></infInut><Signature"),
               fixed = TRUE)
  processada = xml2::read_xml(inutilizada$xml_inutilizacao)
  expect_identical(xml2::xml_name(processada), "procInutNFe")
  expect_length(xml2::xml_find_all(processada, "/*/*"), 2)
})

test_that("a inutiliza\u00e7\u00e3o rejeitada: a situa\u00e7\u00e3o e o motivo, sem o procInutNFe", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) {
    resposta_da_inutilizacao(241, "Rejeicao: Um numero da faixa ja foi utilizado", com_protocolo = FALSE)
  })
  rejeitada = inutilizar_de_teste()
  expect_identical(rejeitada$situacao, 241L)
  expect_true(is.na(rejeitada$xml_inutilizacao))
  expect_true(is.na(rejeitada$protocolo))
})

test_that("a inutiliza\u00e7\u00e3o: os erros antes de qualquer conex\u00e3o", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) stop("n\u00e3o devia ter conectado"))
  expect_error(inutilizar_de_teste(ambiente = "producao"), "homologa\u00e7\u00e3o")
  expect_error(inutilizar_de_teste(cnpj = "11222333000180"), "CNPJ")
  expect_error(inutilizar_de_teste(uf = "XX"), "UF")
  expect_error(inutilizar_de_teste(modelo = "57"), "modelo")
  expect_error(inutilizar_de_teste(serie = 1000), "s\u00e9rie")
  expect_error(inutilizar_de_teste(numero_inicial = 0), "n\u00famero inicial")
  expect_error(inutilizar_de_teste(numero_final = 100), "menor")
  expect_error(inutilizar_de_teste(ano = 202), "ano")
  expect_error(inutilizar_de_teste(justificativa = "CURTA"), "15 a 255")
  # A NF-e do AC, da BA e de SP não se inutiliza desde 01/11/2026 (Ajuste SINIEF 40/26).
  expect_error(inutilizar_de_teste(uf = "SP"), "Ajuste SINIEF 40/26")
  # O CNPJ de outra empresa: o certificado não é do emitente.
  expect_error(inutilizar_de_teste(cnpj = "11444777000161"), "CNPJ-base")
})
