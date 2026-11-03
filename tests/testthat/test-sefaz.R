# Sem rede: o httr2 devolve a resposta gravada no lugar da SEFAZ. respostas/status_homologacao_svrs.xml é a
# resposta real da SVRS de homologação ao status do CE (30/10/2026), que não traz dado de empresa nenhuma. Nos
# testes com a SEFAZ de mentira, os pedidos vão por este processo (o processo separado não veria o httr2 simulado).
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
  local_mocked_bindings(usar_processo_separado = function() FALSE)
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
  # O certificado vai em PEM, com a chave à parte (cifrada pela senha).
  expect_identical(pedidos[[1]]$options$sslcerttype, "PEM")
  expect_false(is.null(pedidos[[1]]$options$sslkey))
  expect_identical(pedidos[[1]]$options$keypasswd, "teste")
})

# respostas/status_cte_homologacao_svrs.xml e status_mdfe_homologacao_svrs.xml: as respostas reais da SVRS de
# homologação ao status do CE (03/11/2026).
test_that("o status do CT-e e do MDF-e: o pedido de cada um e a resposta em colunas", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    if (grepl("mdfe", req$url, fixed = TRUE)) {
      arquivo = test_path("respostas", "status_mdfe_homologacao_svrs.xml")
    } else {
      arquivo = test_path("respostas", "status_cte_homologacao_svrs.xml")
    }
    resposta_gravada(paste(readLines(arquivo, encoding = "UTF-8", warn = FALSE), collapse = ""))
  })
  # O CT-e do CE vai à SVRS, o de PE à SVSP e o de SP à SEFAZ de SP.
  cte = sefaz_status(c("CE", "PE", "SP"), CERTIFICADO_DE_TESTE, "teste", documento = "CT-e")
  expect_identical(cte$documento, rep("CT-e", 3))
  expect_identical(cte$autorizador, c("SVRS", "SVSP", "SP"))
  expect_identical(cte$situacao, rep(107L, 3))
  expect_identical(cte$versao_aplicativo[1], "RS20240708154036")
  expect_true(all(is.na(cte$problema)))
  expect_identical(pedidos[[1]]$url, "https://cte-homologacao.svrs.rs.gov.br/ws/CTeStatusServicoV4/CTeStatusServicoV4.asmx")
  expect_identical(pedidos[[2]]$url, "https://homologacao.nfe.fazenda.sp.gov.br/CTeWS/WS/CTeStatusServicoV4.asmx")
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, '<cteDadosMsg xmlns="http://www.portalfiscal.inf.br/cte/wsdl/CTeStatusServicoV4">', fixed = TRUE)
  expect_match(corpo, paste0('<consStatServCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="4.00"><tpAmb>2</tpAmb>',
                             "<cUF>23</cUF><xServ>STATUS</xServ></consStatServCTe>"), fixed = TRUE)
  expect_false(grepl("Header", corpo, fixed = TRUE))
  expect_match(pedidos[[1]]$body$content_type,
               'action="http://www.portalfiscal.inf.br/cte/wsdl/CTeStatusServicoV4/cteStatusServicoCT"', fixed = TRUE)
  # O MDF-e vai sempre à SVRS, com a UF no cabeçalho mdfeCabecMsg em vez do pedido.
  mdfe = sefaz_status("CE", CERTIFICADO_DE_TESTE, "teste", documento = "MDF-e")
  expect_identical(mdfe$documento, "MDF-e")
  expect_identical(mdfe$autorizador, "SVRS")
  expect_identical(mdfe$situacao, 107L)
  expect_true(is.na(mdfe$problema))
  expect_identical(pedidos[[4]]$url, "https://mdfe-homologacao.svrs.rs.gov.br/ws/MDFeStatusServico/MDFeStatusServico.asmx")
  corpo = rawToChar(pedidos[[4]]$body$data)
  expect_match(corpo, paste0('<soap12:Header><mdfeCabecMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeStatusServico">',
                             "<cUF>23</cUF><versaoDados>3.00</versaoDados></mdfeCabecMsg></soap12:Header>"), fixed = TRUE)
  expect_match(corpo, paste0('<mdfeDadosMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeStatusServico">',
                             '<consStatServMDFe xmlns="http://www.portalfiscal.inf.br/mdfe" versao="3.00"><tpAmb>2</tpAmb>',
                             "<xServ>STATUS</xServ></consStatServMDFe></mdfeDadosMsg>"), fixed = TRUE)
  expect_match(pedidos[[4]]$body$content_type,
               'action="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeStatusServico/mdfeStatusServicoMDF"', fixed = TRUE)
  # Documento que não tem status para antes de conectar.
  expect_error(sefaz_status("CE", CERTIFICADO_DE_TESTE, "teste", documento = "NFS-e"), "Informe documento")
  expect_length(pedidos, 4)
})

test_that("o motor de TLS pelo texto do curl: o que est\u00e1 entre par\u00eanteses est\u00e1 desligado", {
  expect_identical(motor_de_tls("(OpenSSL/3.5.8) Schannel"), "Schannel")
  expect_identical(motor_de_tls("OpenSSL/3.5.8 (Schannel)"), "OpenSSL")
  expect_identical(motor_de_tls("OpenSSL/3.0.13"), "OpenSSL")
})

test_that("a conex\u00e3o: o certificado em PEM com a chave cifrada e as ra\u00edzes com a da ICP-Brasil", {
  skip_if_not_installed("openssl")
  pasta = tempfile("teste_da_conexao_")
  dir.create(pasta)
  conexao = preparar_conexao(CERTIFICADO_DE_TESTE, "teste", pasta)
  expect_identical(conexao$opcoes$sslcerttype, "PEM")
  expect_match(openssl::read_cert(conexao$opcoes$sslcert)$subject, "EMPRESA DE TESTE LTDA")
  expect_true(any(grepl("ENCRYPTED", readLines(conexao$opcoes$sslkey))))
  expect_error(openssl::read_key(conexao$opcoes$sslkey, password = "errada"))
  expect_s3_class(openssl::read_key(conexao$opcoes$sslkey, password = "teste"), "key")
  expect_identical(conexao$processo_separado, identical(motor_de_tls(), "Schannel"))
  # As raízes: a lista padrão e, no fim, a v10 da ICP-Brasil.
  lista_de_teste = file.path(pasta, "lista_padrao.pem")
  writeLines(c("-----BEGIN CERTIFICATE-----", "RAIZ DE TESTE", "-----END CERTIFICATE-----"), lista_de_teste)
  raizes = readLines(juntar_raizes(pasta, lista_de_teste))
  expect_identical(raizes[2], "RAIZ DE TESTE")
  expect_identical(sum(grepl("BEGIN CERTIFICATE", raizes)), 2L)
  expect_true(is.na(juntar_raizes(pasta, NA_character_)))
  unlink(pasta, recursive = TRUE)
})

test_that("o processo separado roda com o OpenSSL, devolve o erro da conex\u00e3o e n\u00e3o muda esta sess\u00e3o", {
  skip_on_cran()
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  pasta = tempfile("teste_do_processo_")
  dir.create(pasta)
  conexao = preparar_conexao(CERTIFICADO_DE_TESTE, "teste", pasta)
  variaveis_de_antes = Sys.getenv(c("CURL_SSL_BACKEND", "RNFE_SENHA_DO_CERTIFICADO"), unset = NA)
  # Uma porta fechada deste computador: a conexão falha na hora, sem sair para a internet.
  pedido = montar_pedido("https://127.0.0.1:9/", "NFeStatusServico4", "nfeStatusServicoNF", "<teste/>")
  resultado = enviar_num_processo_separado(list(pedido), conexao)
  expect_match(resultado$motor, "^OpenSSL")
  expect_length(resultado$respostas, 1)
  expect_false(is.na(resultado$respostas[[1]]$erro))
  expect_match(ler_resposta(resultado$respostas[[1]], "retConsStatServ")$problema, "^sem resposta da SEFAZ")
  expect_identical(Sys.getenv(c("CURL_SSL_BACKEND", "RNFE_SENHA_DO_CERTIFICADO"), unset = NA), variaveis_de_antes)
  # A senha não vai para o arquivo da tarefa.
  tarefa = readRDS(file.path(pasta, "tarefa.rds"))
  expect_null(tarefa$opcoes$keypasswd)
  unlink(pasta, recursive = TRUE)
})

test_that("a raiz v10 da ICP-Brasil que vem no pacote \u00e9 a do reposit\u00f3rio do ITI", {
  skip_if_not_installed("openssl")
  raiz = openssl::read_cert(system.file("certificados", "icp_brasil_raiz_v10.pem", package = "RNFe"))
  expect_identical(paste(as.character(openssl::sha256(openssl::write_der(raiz))), collapse = ""),
                   "6e0bff069a26994c15de2c4888cc54af84882e5495b7fbf66be9ccffec7489f6")
  expect_match(raiz$subject, "Autoridade Certificadora Raiz Brasileira v10")
})

test_that("UF desconhecida e SEFAZ fora do ar n\u00e3o atrapalham as outras UFs", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
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
  local_mocked_bindings(usar_processo_separado = function() FALSE)
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
  local_mocked_bindings(usar_processo_separado = function() FALSE)
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
  # A consulta de cadastro: a SVRS atende todas as UFs dela (a página só lista 5, entre elas SC); o MA, da SVAN, fica sem.
  expect_identical(servico_da_uf("SC", "NfeConsultaCadastro", "homologacao")$autorizador, "SVRS")
  expect_identical(servico_da_uf("CE", "NfeConsultaCadastro", "homologacao")$autorizador, "SVRS")
  expect_identical(servico_da_uf("SP", "NfeConsultaCadastro", "homologacao")$autorizador, "SP")
  expect_null(servico_da_uf("MA", "NfeConsultaCadastro", "homologacao"))
  # A NFC-e tem lista própria: 8 UFs com autorizador próprio (MG pela página da SEFAZ-MG) e as outras 19 na SVRS.
  autorizadores_da_nfce = character()
  for (uf in ufs) {
    autorizadores_da_nfce = c(autorizadores_da_nfce, servico_da_uf(uf, "NFeConsultaProtocolo", "homologacao", "NFC-e")$autorizador)
  }
  expect_identical(sort(ufs[autorizadores_da_nfce != "SVRS"]), c("AM", "GO", "MG", "MS", "MT", "PR", "RS", "SP"))
  expect_identical(sum(autorizadores_da_nfce == "SVRS"), 19L)
  expect_identical(servico_da_uf("MA", "NFeConsultaProtocolo", "homologacao", "NFC-e")$endereco,
                   "https://nfce-homologacao.svrs.rs.gov.br/ws/NfeConsulta/NfeConsulta4.asmx")
  # O CT-e: 6 UFs com autorizador próprio, AP, PE e RR na SVSP e as outras 18 na SVRS. O MDF-e é todo da SVRS.
  autorizadores_do_cte = character()
  autorizadores_do_mdfe = character()
  for (uf in ufs) {
    autorizadores_do_cte = c(autorizadores_do_cte, servico_da_uf(uf, "CteConsultaV4", "homologacao", "CT-e")$autorizador)
    autorizadores_do_mdfe = c(autorizadores_do_mdfe, servico_da_uf(uf, "MDFeConsulta", "homologacao", "MDF-e")$autorizador)
  }
  expect_identical(ufs[!(autorizadores_do_cte %in% c("SVRS", "SVSP"))], c("MG", "MS", "MT", "PR", "RS", "SP"))
  expect_identical(ufs[autorizadores_do_cte == "SVSP"], c("AP", "PE", "RR"))
  expect_identical(sum(autorizadores_do_cte == "SVRS"), 18L)
  expect_identical(unique(autorizadores_do_mdfe), "SVRS")
  expect_length(autorizadores_do_mdfe, 27)
})
