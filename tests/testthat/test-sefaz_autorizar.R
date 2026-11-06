# Sem rede: o httr2 devolve respostas montadas à mão com a estrutura das da SVRS de homologação (05/11/2026, quando o
# RNFe autorizou, corrigiu, manifestou e cancelou NF-e de teste por lá), com os dados fictícios dos exemplos.
CERTIFICADO_DA_AUTORIZACAO = test_path("certificados", "pessoa_juridica.pfx")
CHAVE_DA_NOTA_DO_CE = "23261012ABC34501DE35550020000000421876543213"

nota_assinada_do_ce = function() {
  xml_assinar(system.file("exemplos", "nfe_ce_simples_cpf.xml", package = "RNFe"), CERTIFICADO_DA_AUTORIZACAO, "teste")
}

protocolo_da_nota = function(situacao, motivo, chave = CHAVE_DA_NOTA_DO_CE) {
  paste0('<protNFe versao="4.00"><infProt><tpAmb>2</tpAmb><verAplic>SVRS202611051200</verAplic><chNFe>', chave,
         "</chNFe><dhRecbto>2026-10-20T15:46:00-03:00</dhRecbto><nProt>323260000099999</nProt>",
         "<digVal>Ywt9NO+1/P+62NVWMHZHTS3KiQM=</digVal><cStat>", situacao, "</cStat><xMotivo>", motivo,
         "</xMotivo></infProt></protNFe>")
}

resposta_da_sefaz = function(servico, retorno) {
  texto = paste0('<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">',
                 '<soap:Body><nfeResultMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/', servico, '">', retorno,
                 "</nfeResultMsg></soap:Body></soap:Envelope>")
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(texto))
}

retorno_do_lote = function(situacao, motivo, conteudo) {
  paste0('<retEnviNFe versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>2</tpAmb>',
         "<verAplic>SVRS202611051200</verAplic><cStat>", situacao, "</cStat><xMotivo>", motivo,
         "</xMotivo><cUF>23</cUF><dhRecbto>2026-10-20T15:46:00-03:00</dhRecbto>", conteudo, "</retEnviNFe>")
}

test_that("a produ\u00e7\u00e3o \u00e9 recusada, e a nota de produ\u00e7\u00e3o ou sem assinatura n\u00e3o vai", {
  expect_error(sefaz_autorizar("nota.xml", "qualquer.pfx", "senha", ambiente = "producao"), "homologa\u00e7\u00e3o")
  de_producao = sub("<tpAmb>2</tpAmb>", "<tpAmb>1</tpAmb>", nota_assinada_do_ce(), fixed = TRUE)
  expect_match(notas_para_autorizar(de_producao, "homologacao")$linhas$problema, "tpAmb 1")
  sem_assinatura = paste(readLines(system.file("exemplos", "nfe_ce_simples_cpf.xml", package = "RNFe"), encoding = "UTF-8"),
                         collapse = "\n")
  sem_assinatura = sub("(?s)<Signature.*</Signature>", "", sem_assinatura, perl = TRUE)
  expect_match(notas_para_autorizar(sem_assinatura, "homologacao")$linhas$problema, "assinada")
  expect_match(notas_para_autorizar("nao_existe.xml", "homologacao")$linhas$problema, "n\u00e3o encontrado")
})

test_that("a nota autorizada: o lote s\u00edncrono que vai, o protocolo e o nfeProc que o nfe_ler l\u00ea", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_sefaz("NFeAutorizacao4", retorno_do_lote(104, "Lote processado",
                                                         protocolo_da_nota(100, "Autorizado o uso da NF-e")))
  })
  resposta = sefaz_autorizar(nota_assinada_do_ce(), CERTIFICADO_DA_AUTORIZACAO, "teste")
  expect_identical(resposta$chave, CHAVE_DA_NOTA_DO_CE)
  expect_identical(resposta$autorizador, "SVRS")
  expect_identical(resposta$situacao_lote, 104L)
  expect_identical(resposta$situacao, 100L)
  expect_identical(resposta$protocolo, "323260000099999")
  expect_true(is.na(resposta$problema))
  expect_identical(attr(resposta$autorizacao, "tzone"), "America/Sao_Paulo")
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, '<enviNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00"><idLote>[0-9]{15}</idLote><indSinc>1</indSinc><NFe xmlns="http://www.portalfiscal.inf.br/nfe">')
  expect_match(pedidos[[1]]$body$content_type, "NFeAutorizacao4/nfeAutorizacaoLote", fixed = TRUE)
  expect_match(pedidos[[1]]$url, "NfeAutorizacao")
  # O nfeProc: a nota como foi e o protocolo; o nfe_ler lê a situação.
  lida = nfe_ler(resposta$xml_autorizado)
  expect_identical(lida$notas$chave, CHAVE_DA_NOTA_DO_CE)
  expect_identical(lida$notas$situacao, 100L)
  expect_identical(lida$notas$protocolo, "323260000099999")
})

test_that("o lote processado depois: o recibo \u00e9 consultado at\u00e9 vir o protocolo", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE, esperar_antes_do_recibo = function() NULL)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    if (length(pedidos) == 1) {
      return(resposta_da_sefaz("NFeAutorizacao4", retorno_do_lote(103, "Lote recebido com sucesso",
                                                                  "<infRec><nRec>231000000012345</nRec><tMed>1</tMed></infRec>")))
    }
    if (length(pedidos) == 2) {
      return(resposta_da_sefaz("NFeRetAutorizacao4", paste0(
        '<retConsReciNFe versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>2</tpAmb><verAplic>SVRS</verAplic>',
        "<nRec>231000000012345</nRec><cStat>105</cStat><xMotivo>Lote em processamento</xMotivo><cUF>23</cUF></retConsReciNFe>")))
    }
    resposta_da_sefaz("NFeRetAutorizacao4", paste0(
      '<retConsReciNFe versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>2</tpAmb><verAplic>SVRS</verAplic>',
      "<nRec>231000000012345</nRec><cStat>104</cStat><xMotivo>Lote processado</xMotivo><cUF>23</cUF>",
      protocolo_da_nota(100, "Autorizado o uso da NF-e"), "</retConsReciNFe>"))
  })
  resposta = sefaz_autorizar(nota_assinada_do_ce(), CERTIFICADO_DA_AUTORIZACAO, "teste")
  expect_length(pedidos, 3)
  expect_identical(resposta$recibo, "231000000012345")
  expect_identical(resposta$situacao, 100L)
  expect_match(rawToChar(pedidos[[2]]$body$data), "<consReciNFe xmlns=\"http://www.portalfiscal.inf.br/nfe\" versao=\"4.00\"><tpAmb>2</tpAmb><nRec>231000000012345</nRec></consReciNFe>", fixed = TRUE)
  expect_match(pedidos[[2]]$body$content_type, "NFeRetAutorizacao4/nfeRetAutorizacaoLote", fixed = TRUE)
})

test_that("a rejei\u00e7\u00e3o n\u00e3o tem nfeProc, e o protocolo de outra chave n\u00e3o vale", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) {
    resposta_da_sefaz("NFeAutorizacao4", retorno_do_lote(104, "Lote processado",
                                                         protocolo_da_nota(434, "Rejeicao: NF-e sem indicativo do intermediador")))
  })
  rejeitada = sefaz_autorizar(nota_assinada_do_ce(), CERTIFICADO_DA_AUTORIZACAO, "teste")
  expect_identical(rejeitada$situacao, 434L)
  expect_true(is.na(rejeitada$xml_autorizado))
  httr2::local_mocked_responses(function(req) {
    resposta_da_sefaz("NFeAutorizacao4", retorno_do_lote(104, "Lote processado", protocolo_da_nota(
      100, "Autorizado o uso da NF-e", chave = "35261011222333000181550010000010011123456785")))
  })
  de_outra = sefaz_autorizar(nota_assinada_do_ce(), CERTIFICADO_DA_AUTORIZACAO, "teste")
  expect_match(de_outra$problema, "outra chave")
  expect_true(is.na(de_outra$situacao))
})

test_that("a nota denegada tem o nfeProc com o protocolo da denega\u00e7\u00e3o (o item 5.1.6 do MOC)", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  httr2::local_mocked_responses(function(req) {
    resposta_da_sefaz("NFeAutorizacao4", retorno_do_lote(104, "Lote processado",
                                                         protocolo_da_nota(302, "Uso Denegado: Irregularidade fiscal do destinatario")))
  })
  denegada = sefaz_autorizar(nota_assinada_do_ce(), CERTIFICADO_DA_AUTORIZACAO, "teste")
  expect_identical(denegada$situacao, 302L)
  expect_match(denegada$xml_autorizado, "<cStat>302</cStat>", fixed = TRUE)
  expect_identical(nfe_ler(denegada$xml_autorizado)$notas$situacao, 302L)
})

test_that("o recibo que volta sem o lote (106) n\u00e3o \u00e9 consultado de novo", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE, esperar_antes_do_recibo = function() NULL)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    if (length(pedidos) == 1) {
      return(resposta_da_sefaz("NFeAutorizacao4", retorno_do_lote(103, "Lote recebido com sucesso",
                                                                  "<infRec><nRec>231000000012345</nRec><tMed>1</tMed></infRec>")))
    }
    resposta_da_sefaz("NFeRetAutorizacao4", paste0(
      '<retConsReciNFe versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>2</tpAmb><verAplic>SVRS</verAplic>',
      "<nRec>231000000012345</nRec><cStat>106</cStat><xMotivo>Lote nao localizado</xMotivo><cUF>23</cUF></retConsReciNFe>"))
  })
  resposta = sefaz_autorizar(nota_assinada_do_ce(), CERTIFICADO_DA_AUTORIZACAO, "teste")
  expect_length(pedidos, 2)
  expect_identical(resposta$situacao_lote, 106L)
  expect_match(resposta$problema, "106")
})
