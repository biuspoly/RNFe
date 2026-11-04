# Sem rede: o httr2 devolve a resposta no lugar da NFS-e Nacional. As respostas reais da Produção Restrita (04/11/2026),
# sem dado de empresa: respostas/nfse_consulta_homologacao_sefin.json (a Sefin, para uma chave inventada: 404, E2401),
# nfse_eventos_homologacao_adn.json (o ADN, os eventos da mesma chave: 404, E2240),
# nfse_distribuicao_homologacao_adn.json (o ADN, a distribuição com o CNPJ do certificado de teste: 404, E2220) e
# nfse_distribuicao_sem_cnpj_homologacao_adn.json (o mesmo pedido sem o cnpjConsulta: REJEICAO sem erro nenhum). As
# respostas com documentos são montadas com a NFS-e e o cancelamento de exemplo, em gzip dentro do base64.
CERTIFICADO_DA_NFSE = test_path("certificados", "pessoa_juridica.pfx")
CHAVE_DA_NFSE_DE_EXEMPLO = "35503082211222333000181000000000012326101234567898"
CHAVE_DA_NFSE_INVENTADA = "23044002211222333000181000000000000126111234567890"
ENDERECO_DA_SEFIN = "https://sefin.producaorestrita.nfse.gov.br/SefinNacional"
ENDERECO_DO_ADN = "https://adn.producaorestrita.nfse.gov.br/contribuintes"

resposta_em_json = function(situacao_http, texto) {
  httr2::response(status_code = situacao_http, headers = "Content-Type: application/json; charset=utf-8",
                  body = charToRaw(enc2utf8(texto)))
}

resposta_gravada = function(situacao_http, nome_do_arquivo) {
  resposta_em_json(situacao_http, paste(readLines(test_path("respostas", nome_do_arquivo), encoding = "UTF-8", warn = FALSE),
                                        collapse = ""))
}

exemplo_em_gzip_e_base64 = function(nome_do_arquivo) {
  texto = paste(readLines(system.file("exemplos", nome_do_arquivo, package = "RNFe"), encoding = "UTF-8", warn = FALSE),
                collapse = "\n")
  arquivo = tempfile(fileext = ".gz")
  conexao = gzfile(arquivo, "wb")
  writeChar(enc2utf8(texto), conexao, eos = NULL, useBytes = TRUE)
  close(conexao)
  openssl::base64_encode(readBin(arquivo, "raw", file.size(arquivo)))
}

# A Sefin com a NFS-e de exemplo, como o NFSeGetResponseSucesso da especificação.
nota_achada_na_sefin = function(chave = CHAVE_DA_NFSE_DE_EXEMPLO, tipo_do_ambiente = 2) {
  resposta_em_json(200, paste0(
    '{"tipoAmbiente":', tipo_do_ambiente, ',"versaoAplicativo":"TESTE","dataHoraProcessamento":"2026-11-04T09:56:17.795351-03:00",',
    '"chaveAcesso":"', chave, '","nfseXmlGZipB64":"', exemplo_em_gzip_e_base64("nfse_sp_v101.xml"), '"}'
  ))
}

# Um lote do ADN com os documentos dados (uma lista de NSU, tipo, tipo do evento e arquivo de exemplo).
lote_do_adn = function(documentos, tipo_da_consulta = "CnpjBase") {
  itens = character()
  for (documento in documentos) {
    tipo_do_evento = "null"
    if (!is.na(documento$tipo_evento)) {
      tipo_do_evento = paste0('"', documento$tipo_evento, '"')
    }
    itens = c(itens, paste0(
      '{"NSU":', documento$nsu, ',"ChaveAcesso":"', CHAVE_DA_NFSE_DE_EXEMPLO, '","TipoDocumento":"', documento$tipo, '",',
      '"TipoEvento":', tipo_do_evento, ',"ArquivoXml":"', exemplo_em_gzip_e_base64(documento$arquivo), '",',
      '"DataHoraGeracao":"2026-10-20T17:30:05.123-03:00"}'
    ))
  }
  resposta_em_json(200, paste0(
    '{"TipoConsulta":"', tipo_da_consulta, '","StatusProcessamento":"DOCUMENTOS_LOCALIZADOS","LoteDFe":[', paste(itens, collapse = ","),
    '],"Alertas":[{"Codigo":"A001","Descricao":"Alerta de teste"}],"Erros":[],"TipoAmbiente":"HOMOLOGACAO",',
    '"VersaoAplicativo":"1.0.0.0","DataHoraProcessamento":"2026-11-04T09:56:44.7392434-03:00"}'
  ))
}

DOCUMENTO_NFSE = list(nsu = 11, tipo = "NFSE", tipo_evento = NA, arquivo = "nfse_sp_v101.xml")
DOCUMENTO_CANCELAMENTO = list(nsu = 12, tipo = "EVENTO", tipo_evento = "CANCELAMENTO", arquivo = "evento_nfse_cancelamento.xml")

test_that("a produ\u00e7\u00e3o, um documento ou um NSU fora do formato s\u00e3o recusados antes de conectar", {
  expect_error(nfse_situacao(CHAVE_DA_NFSE_DE_EXEMPLO, "qualquer.pfx", "senha", ambiente = "producao"), "homologa\u00e7\u00e3o")
  expect_error(nfse_distribuicao("11222333000181", "qualquer.pfx", "senha", ambiente = "producao"), "homologa\u00e7\u00e3o")
  expect_error(nfse_distribuicao("123", "qualquer.pfx", "senha"), "CNPJ")
  expect_error(nfse_distribuicao("11222333000181", "qualquer.pfx", "senha", ultimo_nsu = "12a"), "19 d\u00edgitos")
  expect_identical(nsu_do_adn(0), "0")
  expect_identical(nsu_do_adn("000000000000012"), "12")
  expect_identical(nsu_do_adn(1e15), "1000000000000000")
})

test_that("situa\u00e7\u00e3o: a nota que n\u00e3o existe (resposta real), os pedidos que v\u00e3o e a chave que nem vai", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  skip_if_not_installed("jsonlite")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    if (startsWith(req$url, ENDERECO_DA_SEFIN)) {
      return(resposta_gravada(404, "nfse_consulta_homologacao_sefin.json"))
    }
    resposta_gravada(404, "nfse_eventos_homologacao_adn.json")
  })
  consulta = nfse_situacao(c(paste0("NFS", CHAVE_DA_NFSE_INVENTADA), "123"), CERTIFICADO_DA_NFSE, "teste")
  situacoes = consulta$situacoes
  expect_identical(situacoes$chave, c(CHAVE_DA_NFSE_INVENTADA, "123"))
  expect_identical(situacoes$encontrada, c(FALSE, FALSE))
  expect_identical(situacoes$situacao_http, c(404L, NA))
  expect_identical(situacoes$codigo, c("E2401", NA))
  expect_identical(situacoes$motivo, c("Chave de acesso n\u00e3o encontrada.", NA))
  expect_equal(as.numeric(situacoes$processamento[1]), as.numeric(as.POSIXct("2026-11-04 12:56:17", tz = "UTC")))
  expect_identical(situacoes$versao_aplicativo[1], "SefinNacional_1.6.0")
  expect_true(is.na(situacoes$xml[1]))
  expect_identical(situacoes$endereco[1], paste0(ENDERECO_DA_SEFIN, "/nfse/", CHAVE_DA_NFSE_INVENTADA))
  # A nota que não existe é resposta, não problema; nem a falta de eventos (E2240).
  expect_true(is.na(situacoes$problema[1]))
  expect_match(situacoes$problema[2], "50 n\u00fameros")
  expect_identical(nrow(consulta$eventos), 0L)
  # Dois GET por chave que vai, pedindo JSON: a nota na Sefin e os eventos no ADN. A chave curta nem vai.
  expect_length(pedidos, 2)
  expect_identical(pedidos[[1]]$url, paste0(ENDERECO_DA_SEFIN, "/nfse/", CHAVE_DA_NFSE_INVENTADA))
  expect_identical(pedidos[[2]]$url, paste0(ENDERECO_DO_ADN, "/NFSe/", CHAVE_DA_NFSE_INVENTADA, "/Eventos"))
  expect_null(pedidos[[1]]$body)
  expect_identical(pedidos[[1]]$headers$Accept, "application/json")
})

test_that("situa\u00e7\u00e3o: a nota achada vem descompactada, com os eventos do ADN", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  skip_if_not_installed("jsonlite")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) {
    if (startsWith(req$url, ENDERECO_DA_SEFIN)) {
      return(nota_achada_na_sefin())
    }
    lote_do_adn(list(DOCUMENTO_CANCELAMENTO), tipo_da_consulta = "InscricaoCertificado")
  })
  consulta = nfse_situacao(CHAVE_DA_NFSE_DE_EXEMPLO, CERTIFICADO_DA_NFSE, "teste")
  situacoes = consulta$situacoes
  expect_true(situacoes$encontrada)
  expect_identical(situacoes$situacao_http, 200L)
  expect_true(is.na(situacoes$codigo))
  expect_true(is.na(situacoes$problema))
  expect_identical(nfse_ler(situacoes$xml)$nfses$chave, CHAVE_DA_NFSE_DE_EXEMPLO)
  # O cancelamento vem pelo ADN e passa pelo eventos_ler().
  expect_identical(consulta$eventos$chave, CHAVE_DA_NFSE_DE_EXEMPLO)
  expect_identical(consulta$eventos$tipo, "101101")
  expect_identical(consulta$eventos$descricao, "Cancelamento de NFS-e")
})

test_that("situa\u00e7\u00e3o: outro ambiente, outra chave e a recusa dos eventos v\u00e3o para problema", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  skip_if_not_installed("jsonlite")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  recusa_dos_eventos = resposta_em_json(400, paste0(
    '{"StatusProcessamento":"REJEICAO","LoteDFe":[],"Alertas":[],"Erros":[{"Codigo":"E2241","Descricao":"Chave de acesso ',
    'da NFS-e n\\u00e3o referencia o contribuinte solicitante e por isso n\\u00e3o pode ser compartilhada."}],',
    '"TipoAmbiente":"HOMOLOGACAO","VersaoAplicativo":"1.0.0.0","DataHoraProcessamento":"2026-11-04T09:56:18-03:00"}'
  ))
  httr2::local_mocked_responses(function(req) {
    if (startsWith(req$url, ENDERECO_DA_SEFIN)) {
      return(nota_achada_na_sefin(tipo_do_ambiente = 1))
    }
    recusa_dos_eventos
  })
  situacoes = nfse_situacao(CHAVE_DA_NFSE_DE_EXEMPLO, CERTIFICADO_DA_NFSE, "teste")$situacoes
  expect_false(situacoes$encontrada)
  expect_identical(situacoes$problema,
                   "a NFS-e Nacional respondeu de outro ambiente; nos eventos: o ADN rejeitou o pedido: E2241 Chave de acesso da NFS-e n\u00e3o referencia o contribuinte solicitante e por isso n\u00e3o pode ser compartilhada.")
  httr2::local_mocked_responses(function(req) {
    if (startsWith(req$url, ENDERECO_DA_SEFIN)) {
      return(nota_achada_na_sefin(chave = CHAVE_DA_NFSE_INVENTADA))
    }
    resposta_gravada(404, "nfse_eventos_homologacao_adn.json")
  })
  situacoes = nfse_situacao(CHAVE_DA_NFSE_DE_EXEMPLO, CERTIFICADO_DA_NFSE, "teste")$situacoes
  expect_false(situacoes$encontrada)
  expect_identical(situacoes$problema, "a Sefin respondeu com outra chave")
  # Sem resposta, ou resposta que não é JSON.
  httr2::local_mocked_responses(function(req) httr2::response(status_code = 502, body = charToRaw("<html>Bad Gateway</html>")))
  situacoes = nfse_situacao(CHAVE_DA_NFSE_DE_EXEMPLO, CERTIFICADO_DA_NFSE, "teste")$situacoes
  expect_match(situacoes$problema, "^HTTP 502: a resposta n\u00e3o veio em JSON; nos eventos: HTTP 502")
})

test_that("distribui\u00e7\u00e3o: nenhum documento (resposta real), o pedido com o CNPJ ou o CPF", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  skip_if_not_installed("jsonlite")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_gravada(404, "nfse_distribuicao_homologacao_adn.json")
  })
  distribuicao = nfse_distribuicao("11.222.333/0001-81", CERTIFICADO_DA_NFSE, "teste")
  consulta = distribuicao$consulta
  expect_identical(consulta$documento, "11222333000181")
  expect_identical(consulta$situacao, "NENHUM_DOCUMENTO_LOCALIZADO")
  expect_identical(consulta$situacao_http, 404L)
  expect_identical(consulta$tipo_consulta, "CnpjBase")
  expect_identical(consulta$codigo, "E2220")
  expect_match(consulta$motivo, "^Nenhum documento localizado")
  expect_true(is.na(consulta$alertas))
  expect_equal(as.numeric(consulta$processamento), as.numeric(as.POSIXct("2026-11-04 13:01:39", tz = "UTC")))
  expect_identical(consulta$ultimo_nsu, "0")
  expect_identical(consulta$documentos, 0L)
  expect_identical(consulta$versao_aplicativo, "1.0.0.0")
  expect_true(is.na(consulta$problema))
  expect_identical(nrow(distribuicao$documentos), 0L)
  expect_identical(pedidos[[1]]$url, paste0(ENDERECO_DO_ADN, "/DFe/0?cnpjConsulta=11222333000181"))
  expect_null(pedidos[[1]]$body)
  nfse_distribuicao("123.456.789-09", CERTIFICADO_DA_NFSE, "teste", ultimo_nsu = "000000000000012")
  expect_identical(pedidos[[2]]$url, paste0(ENDERECO_DO_ADN, "/DFe/12?cpfConsulta=12345678909"))
})

test_that("distribui\u00e7\u00e3o: os documentos chegam descompactados, e o \u00faltimo NSU \u00e9 o maior que veio", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  skip_if_not_installed("jsonlite")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) lote_do_adn(list(DOCUMENTO_NFSE, DOCUMENTO_CANCELAMENTO)))
  distribuicao = nfse_distribuicao("11222333000181", CERTIFICADO_DA_NFSE, "teste", ultimo_nsu = 10)
  consulta = distribuicao$consulta
  expect_identical(consulta$situacao, "DOCUMENTOS_LOCALIZADOS")
  expect_identical(consulta$documentos, 2L)
  expect_identical(consulta$ultimo_nsu, "12")
  expect_identical(consulta$alertas, "A001 Alerta de teste")
  expect_true(is.na(consulta$codigo))
  documentos = distribuicao$documentos
  expect_identical(documentos$nsu, c("11", "12"))
  expect_identical(documentos$chave, rep(CHAVE_DA_NFSE_DE_EXEMPLO, 2))
  expect_identical(documentos$tipo_documento, c("NFSE", "EVENTO"))
  expect_identical(documentos$tipo_evento, c(NA, "CANCELAMENTO"))
  expect_equal(as.numeric(documentos$gerado_em), rep(as.numeric(as.POSIXct("2026-10-20 20:30:05", tz = "UTC")), 2))
  expect_identical(nfse_ler(documentos$xml)$nfses$chave, CHAVE_DA_NFSE_DE_EXEMPLO)
  expect_identical(eventos_ler(documentos$xml)$eventos$tipo, "101101")
})

test_that("distribui\u00e7\u00e3o: a rejei\u00e7\u00e3o sem motivo (resposta real), a de outro ambiente e a sem resposta", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  skip_if_not_installed("jsonlite")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) resposta_gravada(400, "nfse_distribuicao_sem_cnpj_homologacao_adn.json"))
  consulta = nfse_distribuicao("11222333000181", CERTIFICADO_DA_NFSE, "teste")$consulta
  expect_identical(consulta$situacao, "REJEICAO")
  expect_identical(consulta$problema, "o ADN rejeitou o pedido sem dizer o motivo")
  httr2::local_mocked_responses(function(req) {
    resposta_em_json(404, sub("HOMOLOGACAO", "PRODUCAO", paste(readLines(test_path("respostas", "nfse_distribuicao_homologacao_adn.json"),
                                                                        encoding = "UTF-8", warn = FALSE), collapse = "")))
  })
  consulta = nfse_distribuicao("11222333000181", CERTIFICADO_DA_NFSE, "teste")$consulta
  expect_identical(consulta$problema, "o ADN respondeu de outro ambiente")
  httr2::local_mocked_responses(function(req) stop("Could not resolve host"))
  consulta = nfse_distribuicao("11222333000181", CERTIFICADO_DA_NFSE, "teste")$consulta
  expect_match(consulta$problema, "^sem resposta da NFS-e Nacional")
  expect_true(is.na(consulta$documentos))
})
