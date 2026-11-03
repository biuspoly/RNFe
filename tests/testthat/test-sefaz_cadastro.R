# Sem rede: o httr2 devolve a resposta no lugar da SEFAZ. As respostas reais de homologação (03/11/2026) são ao CNPJ de
# exemplo 11222333000181: a da SVRS (SC) recusa quem pergunta (257) e a do PR diz que ele não é contribuinte lá (259).
# respostas/cadastro_montado_mg.xml é montada, com dados inventados, no envelope que MG usou.
CERTIFICADO_DO_CADASTRO = test_path("certificados", "pessoa_juridica.pfx")
CNPJ_DE_EXEMPLO = "11222333000181"

texto_da_resposta = function(nome_do_arquivo) {
  paste(readLines(test_path("respostas", nome_do_arquivo), encoding = "UTF-8", warn = FALSE), collapse = "\n")
}

resposta_do_cadastro = function(texto) {
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(enc2utf8(texto)))
}

test_that("a produ\u00e7\u00e3o, um tipo desconhecido e UFs a mais s\u00e3o recusados antes de conectar", {
  expect_error(sefaz_cadastro(CNPJ_DE_EXEMPLO, "SP", "qualquer.pfx", "senha", ambiente = "producao"), "homologa\u00e7\u00e3o")
  expect_error(sefaz_cadastro(CNPJ_DE_EXEMPLO, "SP", "qualquer.pfx", "senha", tipo = "RG"), "CNPJ")
  expect_error(sefaz_cadastro(CNPJ_DE_EXEMPLO, c("SP", "PR"), "qualquer.pfx", "senha"), "uma UF para cada documento")
})

test_that("a SVRS recusa quem pergunta: o pedido que vai e a resposta em colunas", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_do_cadastro(texto_da_resposta("cadastro_homologacao_svrs.xml"))
  })
  cadastro = sefaz_cadastro("11.222.333/0001-81", "sc", CERTIFICADO_DO_CADASTRO, "teste")
  consulta = cadastro$consultas
  expect_identical(consulta$documento, CNPJ_DE_EXEMPLO)
  expect_identical(consulta$tipo, "CNPJ")
  expect_identical(consulta$uf, "SC")
  expect_identical(consulta$autorizador, "SVRS")
  expect_identical(consulta$situacao, 257L)
  expect_identical(consulta$motivo, "Rejeicao: Solicitante nao habilitado para emissao da NF-e")
  expect_equal(as.numeric(consulta$consulta), as.numeric(as.POSIXct("2026-11-03 14:14:38", tz = "UTC")))
  expect_identical(attr(consulta$consulta, "tzone"), "America/Sao_Paulo")
  expect_identical(consulta$contribuintes, 0L)
  expect_identical(consulta$versao_aplicativo, "SVRS2607161500")
  expect_true(is.na(consulta$problema))
  expect_identical(nrow(cadastro$cadastros), 0L)
  # O pedido: o endereço da consulta de cadastro da SVRS, a action do WSDL e o ConsCad 2.00 (sem tpAmb).
  expect_length(pedidos, 1)
  expect_identical(pedidos[[1]]$url, "https://cad-homologacao.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro4.asmx")
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, paste0('<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/CadConsultaCadastro4">',
                             '<ConsCad xmlns="http://www.portalfiscal.inf.br/nfe" versao="2.00"><infCons><xServ>CONS-CAD</xServ>',
                             "<UF>SC</UF><CNPJ>", CNPJ_DE_EXEMPLO, "</CNPJ></infCons></ConsCad></nfeDadosMsg>"), fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type,
               'action="http://www.portalfiscal.inf.br/nfe/wsdl/CadConsultaCadastro4/consultaCadastro"', fixed = TRUE)
})

test_that("o MT recebe o nfeDadosMsg dentro de consultaCadastro e responde com um elemento no meio", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  # A resposta do PR no envelope do MT: nfeResultMsg, consultaCadastroResult e o retConsCad dentro.
  do_pr = texto_da_resposta("cadastro_homologacao_pr.xml")
  no_envelope_do_mt = sub("(<retConsCad.*</retConsCad>)", "<consultaCadastroResult>\\1</consultaCadastroResult>", do_pr)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_do_cadastro(no_envelope_do_mt)
  })
  consulta = sefaz_cadastro(CNPJ_DE_EXEMPLO, "MT", CERTIFICADO_DO_CADASTRO, "teste")$consultas
  expect_identical(consulta$autorizador, "MT")
  expect_match(rawToChar(pedidos[[1]]$body$data),
               '<consultaCadastro xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/CadConsultaCadastro4"><nfeDadosMsg><ConsCad ',
               fixed = TRUE)
  expect_identical(consulta$situacao, 259L)
  # O PR manda a hora com milésimos.
  expect_equal(as.numeric(consulta$consulta), as.numeric(as.POSIXct("2026-11-03 14:14:36", tz = "UTC")))
  expect_true(is.na(consulta$problema))
})

test_that("o cadastro encontrado: uma linha por inscri\u00e7\u00e3o, com o significado dos c\u00f3digos", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) resposta_do_cadastro(texto_da_resposta("cadastro_montado_mg.xml")))
  cadastro = sefaz_cadastro(CNPJ_DE_EXEMPLO, "MG", CERTIFICADO_DO_CADASTRO, "teste")
  consulta = cadastro$consultas
  expect_identical(consulta$situacao, 112L)
  expect_identical(consulta$contribuintes, 2L)
  # Sem o fuso, a hora é a de Brasília.
  expect_equal(as.numeric(consulta$consulta), as.numeric(as.POSIXct("2026-11-03 14:14:33", tz = "UTC")))
  inscricoes = cadastro$cadastros
  expect_identical(inscricoes$documento, rep(CNPJ_DE_EXEMPLO, 2))
  expect_identical(inscricoes$ie, c("0012345678901", "0012345678902"))
  expect_identical(inscricoes$contribuinte_documento, rep(CNPJ_DE_EXEMPLO, 2))
  expect_identical(inscricoes$situacao_cadastral, c(1L, 0L))
  expect_identical(inscricoes$situacao_cadastral_descricao, c("Habilitado", "N\u00e3o habilitado"))
  expect_identical(inscricoes$credenciado_nfe_descricao,
                   c("Credenciado com obrigatoriedade para todas opera\u00e7\u00f5es", "N\u00e3o credenciado para emiss\u00e3o da NF-e"))
  expect_identical(inscricoes$credenciado_cte_descricao[1], "A SEFAZ n\u00e3o fornece a informa\u00e7\u00e3o")
  expect_identical(inscricoes$nome, rep("EMPRESA DE TESTE LTDA", 2))
  expect_identical(inscricoes$fantasia, c("TESTE", NA))
  expect_identical(inscricoes$regime_apuracao, c("NORMAL", NA))
  expect_identical(inscricoes$cnae, c("4635402", NA))
  expect_identical(inscricoes$inicio_atividade, as.Date(c("2010-05-03", "2005-02-01")))
  expect_identical(inscricoes$baixa, as.Date(c(NA, "2009-12-31")))
  expect_identical(inscricoes$logradouro, c("RUA DE TESTE", NA))
  expect_identical(inscricoes$codigo_municipio, c("3106200", NA))
  expect_identical(inscricoes$municipio, c("BELO HORIZONTE", NA))
  expect_identical(inscricoes$cep, c("30110000", NA))
})

test_that("a resposta sobre outro documento n\u00e3o entra", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  # Como GO e AM em homologação: a resposta fala do CNPJ do certificado, não do consultado.
  sobre_outro = sub(paste0("<UF>MG</UF><CNPJ>", CNPJ_DE_EXEMPLO), "<UF>MG</UF><CNPJ>11444777000161",
                    texto_da_resposta("cadastro_montado_mg.xml"), fixed = TRUE)
  httr2::local_mocked_responses(function(req) resposta_do_cadastro(sobre_outro))
  cadastro = sefaz_cadastro(CNPJ_DE_EXEMPLO, "MG", CERTIFICADO_DO_CADASTRO, "teste")
  expect_identical(cadastro$consultas$problema, "a SEFAZ respondeu sobre outro documento")
  expect_identical(nrow(cadastro$cadastros), 0L)
})

test_that("documento fora do formato, UF desconhecida e UF sem o servi\u00e7o ficam em problema, sem pedido", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) stop("n\u00e3o devia ter conectado"))
  consultas = sefaz_cadastro(c("123.456.789-09", CNPJ_DE_EXEMPLO, CNPJ_DE_EXEMPLO, NA), c("SP", "XX", "CE", "SP"),
                             CERTIFICADO_DO_CADASTRO, "teste")$consultas
  expect_identical(consultas$problema, c("n\u00e3o tem o formato de CNPJ", "UF desconhecida",
                                         "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz este servi\u00e7o para a UF",
                                         "n\u00e3o tem o formato de CNPJ"))
  # O mesmo CPF, com tipo = "CPF", tem o formato certo (e vai para a SEFAZ).
  expect_identical(comeco_do_cadastro("12345678909", "SP", "CPF", "homologacao")$linha$autorizador, "SP")
})

test_that("sem documento nenhum, as tabelas v\u00eam vazias com as colunas certas", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) stop("n\u00e3o devia ter conectado"))
  vazio = sefaz_cadastro(character(), "SP", CERTIFICADO_DO_CADASTRO, "teste")
  expect_identical(nrow(vazio$consultas), 0L)
  expect_identical(names(vazio$consultas), c("documento", "tipo", "uf", "autorizador", "ambiente", "situacao", "motivo",
                                             "consulta", "contribuintes", "versao_aplicativo", "endereco", "problema"))
  expect_identical(nrow(vazio$cadastros), 0L)
  expect_identical(names(vazio$cadastros)[1:3], c("documento", "ie", "contribuinte_documento"))
  expect_true("situacao_cadastral_descricao" %in% names(vazio$cadastros))
})
