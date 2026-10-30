# Sem rede: o httr2 devolve a resposta gravada no lugar da SEFAZ. respostas/status_homologacao_svrs.xml é a
# resposta real da SVRS de homologação ao status do CE (30/10/2026), que não traz dado de empresa nenhuma.
CERTIFICADO_DE_TESTE = test_path("certificados", "pessoa_juridica.pfx")
RESPOSTA_DA_SVRS = test_path("respostas", "status_homologacao_svrs.xml")
ENDERECO_DA_SVRS = "https://nfe-homologacao.svrs.rs.gov.br/ws/NfeStatusServico/NfeStatusServico4.asmx"

resposta_gravada = function(texto = NULL) {
  if (is.null(texto)) {
    texto = paste(readLines(RESPOSTA_DA_SVRS, encoding = "UTF-8", warn = FALSE), collapse = "")
  }
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(texto))
}

test_that("a produ\u00e7\u00e3o \u00e9 recusada antes de qualquer conex\u00e3o", {
  expect_error(sefaz_status("SP", "qualquer.pfx", "senha", ambiente = "producao"), "homologa\u00e7\u00e3o")
  expect_error(sefaz_status("SP", "qualquer.pfx", "senha", ambiente = c("homologacao", "producao")), "homologa\u00e7\u00e3o")
})

test_that("o status pela SVRS: o pedido que vai e a resposta da SEFAZ em colunas", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_gravada()
  })
  status = sefaz_status("ce", CERTIFICADO_DE_TESTE, "teste")
  expect_identical(status$uf, "CE")
  expect_identical(status$autorizador, "SVRS")
  expect_identical(status$ambiente, "homologacao")
  expect_identical(status$situacao, 107L)
  expect_identical(status$motivo, "Servico em Operacao")
  expect_equal(as.numeric(status$recebimento), as.numeric(as.POSIXct("2026-10-30 20:00:40", tz = "UTC")))
  expect_identical(attr(status$recebimento, "tzone"), "America/Sao_Paulo")
  expect_identical(status$tempo_medio, 1L)
  expect_true(is.na(status$retorno_previsto))
  expect_true(is.na(status$observacao))
  expect_identical(status$versao_aplicativo, "SVRS202401251654")
  expect_identical(status$endereco, ENDERECO_DA_SVRS)
  expect_true(is.na(status$problema))
  # O pedido: o endereço da Relação de Serviços Web, o envelope SOAP 1.2 com a action do WSDL e o ambiente 2.
  expect_length(pedidos, 1)
  expect_identical(pedidos[[1]]$url, ENDERECO_DA_SVRS)
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeStatusServico4">', fixed = TRUE)
  expect_match(corpo, '<consStatServ xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00"><tpAmb>2</tpAmb><cUF>23</cUF><xServ>STATUS</xServ></consStatServ>', fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type, 'action="http://www.portalfiscal.inf.br/nfe/wsdl/NFeStatusServico4/nfeStatusServicoNF"', fixed = TRUE)
  expect_identical(pedidos[[1]]$options$sslcerttype, "P12")
  expect_identical(pedidos[[1]]$options$sslcert, CERTIFICADO_DE_TESTE)
})

test_that("UF desconhecida e SEFAZ fora do ar n\u00e3o atrapalham as outras UFs", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  httr2::local_mocked_responses(function(req) {
    if (grepl("fazenda.sp.gov.br", req$url, fixed = TRUE)) {
      stop("Empty reply from server")
    }
    resposta_gravada()
  })
  status = sefaz_status(c("XX", "SP", "CE"), CERTIFICADO_DE_TESTE, "teste")
  expect_identical(status$uf, c("XX", "SP", "CE"))
  expect_identical(status$problema[1], "UF desconhecida")
  expect_match(status$problema[2], "^sem resposta da SEFAZ")
  expect_identical(status$autorizador[2], "SP")
  expect_identical(status$situacao, c(NA, NA, 107L))
  expect_true(is.na(status$problema[3]))
})

test_that("a falha SOAP e a resposta de outro ambiente v\u00e3o para `problema`", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  falha = paste0(
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body><soap:Fault>',
    "<soap:Code><soap:Value>soap:Receiver</soap:Value></soap:Code>",
    '<soap:Reason><soap:Text xml:lang="pt">Falha de teste</soap:Text></soap:Reason>',
    "</soap:Fault></soap:Body></soap:Envelope>"
  )
  httr2::local_mocked_responses(function(req) {
    httr2::response(status_code = 500, headers = "Content-Type: application/soap+xml", body = charToRaw(falha))
  })
  expect_identical(sefaz_status("CE", CERTIFICADO_DE_TESTE, "teste")$problema, "HTTP 500: Falha de teste")
  de_producao = sub("<tpAmb>2</tpAmb>", "<tpAmb>1</tpAmb>", paste(readLines(RESPOSTA_DA_SVRS, warn = FALSE), collapse = ""), fixed = TRUE)
  httr2::local_mocked_responses(function(req) resposta_gravada(de_producao))
  status = sefaz_status("CE", CERTIFICADO_DE_TESTE, "teste")
  expect_identical(status$problema, "a SEFAZ respondeu de outro ambiente")
  expect_identical(status$situacao, 107L)
})

test_that("certificado que n\u00e3o abre ou vencido para tudo antes de conectar", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  httr2::local_mocked_responses(function(req) stop("n\u00e3o devia ter conectado"))
  expect_error(sefaz_status("CE", CERTIFICADO_DE_TESTE, "errada"), "n\u00e3o abriu")
  expect_error(sefaz_status("CE", test_path("certificados", "vencido.pfx"), "teste"), "venceu em 01/01/2021")
  expect_error(sefaz_status("CE", "nao_existe.pfx", "teste"), "n\u00e3o encontrado")
})

test_that("o autorizador de cada UF, como a Rela\u00e7\u00e3o de Servi\u00e7os Web diz", {
  ufs = c("AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", "MA", "MG", "MS", "MT", "PA", "PB", "PE", "PI", "PR",
          "RJ", "RN", "RO", "RR", "RS", "SC", "SE", "SP", "TO")
  autorizadores = character()
  for (uf in ufs) {
    servico = servico_da_uf(uf, "NfeStatusServico", "homologacao")
    expect_false(is.null(servico))
    expect_match(servico$endereco, "^https://")
    autorizadores = c(autorizadores, servico$autorizador)
  }
  expect_identical(autorizadores[ufs == "CE"], "SVRS")
  expect_identical(autorizadores[ufs == "MA"], "SVAN")
  expect_identical(autorizadores[ufs == "SP"], "SP")
  expect_identical(sort(unique(autorizadores)),
                   c("AM", "BA", "GO", "MG", "MS", "MT", "PE", "PR", "RS", "SP", "SVAN", "SVRS"))
  # A consulta de cadastro tem lista própria na SVRS: SC está nela, o CE não.
  expect_identical(servico_da_uf("SC", "NfeConsultaCadastro", "homologacao")$autorizador, "SVRS")
  expect_null(servico_da_uf("CE", "NfeConsultaCadastro", "homologacao"))
})
