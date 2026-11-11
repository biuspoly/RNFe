# Sem rede: o httr2 devolve o retorno do lote de eventos montado à mão com a estrutura do da SVRS de homologação
# (05/11/2026), com a chave fictícia da nota de exemplo de SP.
CERTIFICADO_DO_EVENTO = test_path("certificados", "pessoa_juridica.pfx")
CHAVE_DA_NOTA_DE_SP = "35261011222333000181550010000010011123456785"

retorno_dos_eventos = function(situacao, motivo, evento, orgao = "35", chave = CHAVE_DA_NOTA_DE_SP, pendentes = "",
                               sequencia = 1) {
  texto = paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>',
    '<nfeResultMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeRecepcaoEvento4"><retEnvEvento versao="1.00" ',
    'xmlns="http://www.portalfiscal.inf.br/nfe"><idLote>1</idLote><tpAmb>2</tpAmb><verAplic>SVRS</verAplic><cOrgao>', orgao,
    "</cOrgao><cStat>128</cStat><xMotivo>Lote de Evento Processado</xMotivo><retEvento versao=\"1.00\"><infEvento>",
    "<tpAmb>2</tpAmb><verAplic>SVRS</verAplic><cOrgao>", orgao, "</cOrgao><cStat>", situacao, "</cStat><xMotivo>", motivo,
    "</xMotivo><chNFe>", chave, "</chNFe><tpEvento>", evento, "</tpEvento><nSeqEvento>", sequencia, "</nSeqEvento>",
    "<dhRegEvento>2026-10-15T16:21:00-03:00</dhRegEvento><nProt>135260000054321</nProt>", pendentes, "</infEvento>",
    "</retEvento></retEnvEvento></nfeResultMsg></soap:Body></soap:Envelope>"
  )
  httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(texto))
}

test_that("o cancelamento: o evento assinado que vai e o procEventoNFe que o eventos_ler l\u00ea", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "110111")
  })
  cancelado = sefaz_cancelar(CHAVE_DA_NOTA_DE_SP, "135260000012345", "PEDIDO CANCELADO PELO CLIENTE", CERTIFICADO_DO_EVENTO,
                             "teste")
  expect_identical(cancelado$situacao, 135L)
  expect_identical(cancelado$protocolo, "135260000054321")
  expect_identical(cancelado$evento, "110111")
  expect_true(is.na(cancelado$problema))
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, paste0('<infEvento Id="ID110111', CHAVE_DA_NOTA_DE_SP, '01"><cOrgao>35</cOrgao><tpAmb>2</tpAmb><CNPJ>11222333000181</CNPJ>'), fixed = TRUE)
  expect_match(corpo, "<descEvento>Cancelamento</descEvento><nProt>135260000012345</nProt><xJust>PEDIDO CANCELADO PELO CLIENTE</xJust>", fixed = TRUE)
  expect_match(corpo, "<Signature xmlns=\"http://www.w3.org/2000/09/xmldsig#\">", fixed = TRUE)
  expect_match(pedidos[[1]]$body$content_type, "NFeRecepcaoEvento4/nfeRecepcaoEvento", fixed = TRUE)
  # Nada de quebra de linha no meio da mensagem (a SEFAZ rejeita com o 588).
  expect_false(grepl("\n", sub("^<\\?xml[^>]*\\?>", "", corpo)))
  lido = eventos_ler(cancelado$xml_evento)$eventos
  expect_identical(lido$tipo, "110111")
  expect_identical(lido$situacao, 135L)
})

test_that("a carta de corre\u00e7\u00e3o leva o texto fixo da condi\u00e7\u00e3o de uso, e a manifesta\u00e7\u00e3o vai ao Ambiente Nacional", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    if (length(pedidos) == 1) {
      return(retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "110110", sequencia = 2))
    }
    retorno_dos_eventos(136, "Evento registrado, mas nao vinculado a NF-e", "210210", orgao = "91")
  })
  carta = sefaz_carta_correcao(CHAVE_DA_NOTA_DE_SP, "ONDE SE LE RUA DO CLIENTE, 10, LEIA-SE 100", 2, CERTIFICADO_DO_EVENTO,
                               "teste")
  expect_identical(carta$situacao, 135L)
  expect_identical(carta$sequencia, 2L)
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, paste0("ID110110", CHAVE_DA_NOTA_DE_SP, "02"), fixed = TRUE)
  expect_match(corpo, paste0("<xCondUso>", CONDICAO_DE_USO_DA_CARTA_DE_CORRECAO, "</xCondUso>"), fixed = TRUE)
  ciencia = sefaz_manifestar(CHAVE_DA_NOTA_DE_SP, "ciencia", certificado = CERTIFICADO_DO_EVENTO, senha = "teste")
  expect_identical(ciencia$situacao, 136L)
  expect_match(pedidos[[2]]$url, "hom1.nfe.fazenda.gov.br", fixed = TRUE)
  expect_match(rawToChar(pedidos[[2]]$body$data), "<cOrgao>91</cOrgao>", fixed = TRUE)
  expect_match(rawToChar(pedidos[[2]]$body$data), "<descEvento>Ciencia da Operacao</descEvento></detEvento>", fixed = TRUE)
})

test_that("o autor do evento \u00e9 o emitente da chave, e o certificado pode ser o da matriz", {
  skip_if_not_installed("openssl")
  # A nota da filial (0002) com o certificado da matriz (0001): o autor é a filial (a regra P12-44 do MOC 7.0).
  nota_da_filial = "35261011222333000262550010000010011123456788"
  cancelamento = list(nProt = "135260000012345", xJust = "PEDIDO CANCELADO PELO CLIENTE")
  montado = montar_o_evento(nota_da_filial, "110111", 1L, cancelamento, CERTIFICADO_DO_EVENTO, "teste", "homologacao")
  expect_match(montado$evento_assinado, "<CNPJ>11222333000262</CNPJ>", fixed = TRUE)
  # Na série do emitente pessoa física, o autor é o CPF, que o certificado da empresa não tem.
  nota_de_cpf = "35261000012345678909559200000010011123456784"
  expect_error(montar_o_evento(nota_de_cpf, "110111", 1L, cancelamento, CERTIFICADO_DO_EVENTO, "teste", "homologacao"),
               "12345678909")
  # Outra empresa (outro CNPJ-base): nada é montado.
  nota_de_outra_empresa = "35261011444777000161550010000010011123456785"
  expect_error(montar_o_evento(nota_de_outra_empresa, "110111", 1L, cancelamento, CERTIFICADO_DO_EVENTO, "teste",
                               "homologacao"), "CNPJ-base")
  # Na manifestação, o destinatário informado (uma filial) é o autor; sem ele, o CNPJ do certificado.
  manifestacao = montar_o_evento(nota_de_outra_empresa, "210210", 1L, list(), CERTIFICADO_DO_EVENTO, "teste", "homologacao",
                                 autor = "destinatario", documento_do_autor = "11.222.333/0002-62")
  expect_match(manifestacao$evento_assinado, "<CNPJ>11222333000262</CNPJ>", fixed = TRUE)
  sem_destinatario = montar_o_evento(nota_de_outra_empresa, "210210", 1L, list(), CERTIFICADO_DO_EVENTO, "teste",
                                     "homologacao", autor = "destinatario")
  expect_match(sem_destinatario$evento_assinado, "<CNPJ>11222333000181</CNPJ>", fixed = TRUE)
  expect_error(montar_o_evento(nota_de_outra_empresa, "210210", 1L, list(), CERTIFICADO_DO_EVENTO, "teste", "homologacao",
                               autor = "destinatario", documento_do_autor = "11444777000161"), "CNPJ-base")
})

test_that("o detalhe de cada evento sai do schema oficial dele, e a mensagem assinada passa no schema geral", {
  skip_if_not_installed("openssl")
  # A descrição e a versão vêm do schema; o campo que o schema não tem, ou o texto que ele recusa, para antes da SEFAZ.
  ciencia = montar_o_evento("35261011444777000161550010000010011123456785", "210210", 1L, list(), CERTIFICADO_DO_EVENTO,
                            "teste", "homologacao", autor = "destinatario")
  expect_match(ciencia$evento_assinado, '<verEvento>1.00</verEvento><detEvento versao="1.00"><descEvento>Ciencia da Operacao</descEvento></detEvento>',
               fixed = TRUE)
  expect_false(grepl('<detEvento xmlns=', ciencia$evento_assinado, fixed = TRUE))
  expect_error(montar_o_evento(CHAVE_DA_NOTA_DE_SP, "110111", 1L, list(nProt = "135260000012345", xJust = "CANCELADO",
                                                                      campoInventado = "1"),
                               CERTIFICADO_DO_EVENTO, "teste", "homologacao"), "campoInventado")
  expect_error(montar_o_evento(CHAVE_DA_NOTA_DE_SP, "110111", 1L, list(nProt = "135260000012345", xJust = "CURTA"),
                               CERTIFICADO_DO_EVENTO, "teste", "homologacao"), "detEvento/xJust recebeu \"CURTA\"")
  # O protocolo de 17 algarismos (o do PAA, NT 2026.001) passa no TProt do pacote 010d.
  com_protocolo_do_paa = montar_o_evento(CHAVE_DA_NOTA_DE_SP, "110111", 1L,
                                         list(nProt = "13526000001234567", xJust = "PEDIDO CANCELADO PELO CLIENTE"),
                                         CERTIFICADO_DO_EVENTO, "teste", "homologacao")
  expect_match(com_protocolo_do_paa$evento_assinado, "<nProt>13526000001234567</nProt>", fixed = TRUE)
  # O modelo da chave: a NFC-e só tem o cancelamento.
  chave_da_nfce = "23261011444777000161650030000000779135724686"
  expect_error(montar_o_evento(chave_da_nfce, "210210", 1L, list(), CERTIFICADO_DO_EVENTO, "teste", "homologacao",
                               autor = "destinatario"), "manifesta\u00e7\u00e3o do destinat\u00e1rio")
})

test_that("cada manifesta\u00e7\u00e3o conclusiva vai at\u00e9 duas vezes (a segunda com a sequ\u00eancia 2); a ci\u00eancia, uma", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "210200", orgao = "91", sequencia = 2)
  })
  confirmacao = sefaz_manifestar(CHAVE_DA_NOTA_DE_SP, "confirmacao", certificado = CERTIFICADO_DO_EVENTO, senha = "teste",
                                 sequencia = 2)
  expect_identical(confirmacao$sequencia, 2L)
  expect_match(rawToChar(pedidos[[1]]$body$data), paste0('Id="ID210200', CHAVE_DA_NOTA_DE_SP, '02"'), fixed = TRUE)
  expect_error(sefaz_manifestar(CHAVE_DA_NOTA_DE_SP, "ciencia", certificado = CERTIFICADO_DO_EVENTO, senha = "teste",
                                sequencia = 2), "uma vez s\u00f3")
  expect_error(sefaz_manifestar(CHAVE_DA_NOTA_DE_SP, "confirmacao", certificado = CERTIFICADO_DO_EVENTO, senha = "teste",
                                sequencia = 3), "de 1 a 2")
  expect_error(sefaz_manifestar(CHAVE_DA_NOTA_DE_SP, "ciencia", justificativa = "QUALQUER JUSTIFICATIVA",
                                certificado = CERTIFICADO_DO_EVENTO, senha = "teste"), "s\u00f3 na opera\u00e7\u00e3o")
})

test_that("o comprovante de entrega vai ao Ambiente Nacional com o hash da imagem, e o cancelamento leva o protocolo", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "110130", orgao = "91")
  })
  imagem = charToRaw("a imagem da assinatura de quem recebeu")
  # O hash da NT 2021.001: o SHA-1, em Base64, da chave seguida da imagem em Base64.
  hash_esperado = openssl::base64_encode(as.raw(openssl::sha1(charToRaw(paste0(CHAVE_DA_NOTA_DE_SP,
                                                                                openssl::base64_encode(imagem))))))
  entregue = sefaz_comprovante_entrega(CHAVE_DA_NOTA_DE_SP, as.POSIXct("2026-10-15 14:30:00", tz = "America/Sao_Paulo"),
                                       "123456789", "MARIA DA SILVA", imagem, CERTIFICADO_DO_EVENTO, "teste",
                                       latitude = -23.55052, longitude = -46.633308)
  expect_identical(entregue$situacao, 135L)
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(pedidos[[1]]$url, "hom1.nfe.fazenda.gov.br", fixed = TRUE)
  expect_match(corpo, "<cOrgao>91</cOrgao>", fixed = TRUE)
  expect_match(corpo, paste0("<descEvento>Comprovante de Entrega da NF-e</descEvento><cOrgaoAutor>35</cOrgaoAutor>",
                             "<tpAutor>1</tpAutor><verAplic>RNFe</verAplic><dhEntrega>2026-10-15T14:30:00-03:00</dhEntrega>",
                             "<nDoc>123456789</nDoc><xNome>MARIA DA SILVA</xNome><latGPS>-23.550520</latGPS>",
                             "<longGPS>-46.633308</longGPS><hashComprovante>", hash_esperado, "</hashComprovante>",
                             "<dhHashComprovante>"), fixed = TRUE)
  # O hash já calculado vai como veio, sem a data do hash; a coordenada com mais de 6 casas é recusada.
  sefaz_comprovante_entrega(CHAVE_DA_NOTA_DE_SP, "2026-10-15T14:30:00-03:00", "123456789", "MARIA DA SILVA", hash_esperado,
                            CERTIFICADO_DO_EVENTO, "teste")
  expect_false(grepl("dhHashComprovante", rawToChar(pedidos[[2]]$body$data), fixed = TRUE))
  expect_error(sefaz_comprovante_entrega(CHAVE_DA_NOTA_DE_SP, Sys.time(), "123456789", "MARIA DA SILVA", imagem,
                                         CERTIFICADO_DO_EVENTO, "teste", latitude = -23.5505201), "latGPS")
  expect_error(sefaz_comprovante_entrega(CHAVE_DA_NOTA_DE_SP, Sys.time(), "123456789", "MARIA DA SILVA",
                                         "arquivo_que_nao_existe.png", CERTIFICADO_DO_EVENTO, "teste"), "comprovante")
  expect_error(sefaz_comprovante_entrega(CHAVE_DA_NOTA_DE_SP, Sys.time(), "1", "MARIA DA SILVA", imagem,
                                         CERTIFICADO_DO_EVENTO, "teste"), "2 a 20")
  cancelado = sefaz_cancelar_comprovante_entrega(CHAVE_DA_NOTA_DE_SP, "891260000012345", CERTIFICADO_DO_EVENTO, "teste")
  expect_match(rawToChar(pedidos[[3]]$body$data),
               paste0("<tpEvento>110131</tpEvento><nSeqEvento>1</nSeqEvento><verEvento>1.00</verEvento>",
                      "<detEvento versao=\"1.00\"><descEvento>Cancelamento Comprovante de Entrega da NF-e</descEvento>",
                      "<cOrgaoAutor>35</cOrgaoAutor><tpAutor>1</tpAutor><verAplic>RNFe</verAplic>",
                      "<nProtEvento>891260000012345</nProtEvento></detEvento>"), fixed = TRUE)
  expect_identical(cancelado$evento, "110131")
  expect_error(sefaz_comprovante_entrega("23261011444777000161650030000000779135724686", Sys.time(), "123456789",
                                         "MARIA DA SILVA", imagem, CERTIFICADO_DO_EVENTO, "teste"), "modelo 55")
})

test_that("o insucesso na entrega vai \u00e0 SVRS (\u00f3rg\u00e3o 92), com o motivo e a justificativa s\u00f3 no outro", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "110192", orgao = "92")
  })
  imagem = charToRaw("a foto do portao fechado")
  sem_sucesso = sefaz_insucesso_entrega(CHAVE_DA_NOTA_DE_SP, "2026-10-15T14:30:00-03:00", "outro", imagem,
                                        CERTIFICADO_DO_EVENTO, "teste",
                                        justificativa = "PORTAO FECHADO E NINGUEM ATENDEU A CAMPAINHA",
                                        numero_da_tentativa = 2)
  expect_identical(sem_sucesso$situacao, 135L)
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(pedidos[[1]]$url, "nfe-homologacao.svrs.rs.gov.br", fixed = TRUE)
  expect_match(corpo, "<cOrgao>92</cOrgao>", fixed = TRUE)
  expect_match(corpo, paste0("<dhTentativaEntrega>2026-10-15T14:30:00-03:00</dhTentativaEntrega><nTentativa>2</nTentativa>",
                             "<tpMotivo>4</tpMotivo><xJustMotivo>PORTAO FECHADO E NINGUEM ATENDEU A CAMPAINHA</xJustMotivo>",
                             "<hashTentativaEntrega>"), fixed = TRUE)
  sefaz_insucesso_entrega(CHAVE_DA_NOTA_DE_SP, Sys.time(), "recusa", imagem, CERTIFICADO_DO_EVENTO, "teste")
  expect_match(rawToChar(pedidos[[2]]$body$data), "<tpMotivo>2</tpMotivo><hashTentativaEntrega>", fixed = TRUE)
  expect_error(sefaz_insucesso_entrega(CHAVE_DA_NOTA_DE_SP, Sys.time(), "outro", imagem, CERTIFICADO_DO_EVENTO, "teste"),
               "25 a 250")
  expect_error(sefaz_insucesso_entrega(CHAVE_DA_NOTA_DE_SP, Sys.time(), "recusa", imagem, CERTIFICADO_DO_EVENTO, "teste",
                                       justificativa = "O RECEBEDOR RECUSOU A MERCADORIA NA PORTA"), "s\u00f3 no motivo")
  expect_error(sefaz_insucesso_entrega(CHAVE_DA_NOTA_DE_SP, Sys.time(), "sumiu", imagem, CERTIFICADO_DO_EVENTO, "teste"),
               "motivo")
  expect_error(sefaz_insucesso_entrega(CHAVE_DA_NOTA_DE_SP, Sys.time(), "recusa", imagem, CERTIFICADO_DO_EVENTO, "teste",
                                       numero_da_tentativa = 1000), "de 1 a 999")
  sefaz_cancelar_insucesso_entrega(CHAVE_DA_NOTA_DE_SP, "391260000012345", CERTIFICADO_DO_EVENTO, "teste")
  expect_match(rawToChar(pedidos[[3]]$body$data),
               paste0("<descEvento>Cancelamento Insucesso na Entrega da NF-e</descEvento><cOrgaoAutor>35</cOrgaoAutor>",
                      "<verAplic>RNFe</verAplic><nProtEvento>391260000012345</nProtEvento>"), fixed = TRUE)
})

test_that("o ator interessado: o tipo de autoriza\u00e7\u00e3o e a condi\u00e7\u00e3o de uso s\u00f3 quando a NT pede", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "110150", orgao = "91")
  })
  sefaz_ator_interessado(CHAVE_DA_NOTA_DE_SP, "11.444.777/0001-61", CERTIFICADO_DO_EVENTO, "teste")
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(corpo, "<cOrgao>91</cOrgao>", fixed = TRUE)
  expect_match(corpo, paste0("<descEvento>Ator interessado na NF-e</descEvento><cOrgaoAutor>35</cOrgaoAutor><tpAutor>1</tpAutor>",
                             "<verAplic>RNFe</verAplic><autXML><CNPJ>11444777000161</CNPJ></autXML>",
                             "<tpAutorizacao>0</tpAutorizacao></detEvento>"), fixed = TRUE)
  # Com a permissão de repassar, a condição de uso vai no texto que o schema aceita.
  sefaz_ator_interessado(CHAVE_DA_NOTA_DE_SP, "12345678909", CERTIFICADO_DO_EVENTO, "teste", permite_repassar = TRUE)
  corpo = rawToChar(pedidos[[2]]$body$data)
  expect_match(corpo, "<autXML><CPF>12345678909</CPF></autXML><tpAutorizacao>1</tpAutorizacao><xCondUso>O emitente ou",
               fixed = TRUE)
  # O transportador contratado: a UF dele, sem tipo de autorização; o autor é o CNPJ do certificado.
  nota_de_outra_empresa = "35261011444777000161550010000010011123456785"
  sefaz_ator_interessado(nota_de_outra_empresa, "12345678909", CERTIFICADO_DO_EVENTO, "teste", autor = "transportador",
                         uf_do_autor = "RS")
  corpo = rawToChar(pedidos[[3]]$body$data)
  expect_match(corpo, "<CNPJ>11222333000181</CNPJ><chNFe>", fixed = TRUE)
  expect_match(corpo, "<cOrgaoAutor>43</cOrgaoAutor><tpAutor>3</tpAutor>", fixed = TRUE)
  expect_false(grepl("tpAutorizacao", corpo, fixed = TRUE))
  expect_error(sefaz_ator_interessado(nota_de_outra_empresa, "12345678909", CERTIFICADO_DO_EVENTO, "teste",
                                      autor = "transportador"), "uf_do_autor")
  expect_error(sefaz_ator_interessado(nota_de_outra_empresa, "12345678909", CERTIFICADO_DO_EVENTO, "teste",
                                      autor = "transportador", uf_do_autor = "RS", permite_repassar = TRUE), "repassar")
  expect_error(sefaz_ator_interessado(CHAVE_DA_NOTA_DE_SP, "12345678909", CERTIFICADO_DO_EVENTO, "teste", uf_do_autor = "RJ"),
               "a da chave")
  expect_error(sefaz_ator_interessado(CHAVE_DA_NOTA_DE_SP, "11444777000162", CERTIFICADO_DO_EVENTO, "teste"), "autorizado")
  expect_error(sefaz_ator_interessado(CHAVE_DA_NOTA_DE_SP, "12345678909", CERTIFICADO_DO_EVENTO, "teste", sequencia = 21),
               "de 1 a 20")
})

test_that("o EPEC sai dos dados da pr\u00f3pria nota em conting\u00eancia e traz as chaves pendentes", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  nota = xml_para_lista(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"))
  nota$Id = NULL
  nota$ide$cDV = NULL
  nota$ide$cNF = "12345678"
  nota$ide$tpEmis = "4"
  nota$ide$dhCont = nota$ide$dhEmi
  nota$ide$xJust = "SEFAZ DA UF SEM RESPOSTA NO MOMENTO"
  em_contingencia = nfe_montar(nota)
  chave = sub("^.*Id=\"NFe([0-9A-Z]{44})\".*$", "\\1", em_contingencia)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    if (length(pedidos) == 1) {
      return(retorno_dos_eventos(136, "Evento registrado, mas nao vinculado a NF-e", "110140", orgao = "91", chave = chave))
    }
    retorno_dos_eventos(142, "Rejeicao: Ambiente de Contingencia EPEC bloqueado para o Emitente", "110140", orgao = "91",
                        chave = chave, pendentes = paste0("<chNFePend>", CHAVE_DA_NOTA_DE_SP, "</chNFePend><chNFePend>",
                                                          CHAVE_DA_NOTA_DE_SP, "</chNFePend>"))
  })
  registrado = sefaz_epec(em_contingencia, CERTIFICADO_DO_EVENTO, "teste")
  expect_identical(registrado$situacao, 136L)
  expect_true(is.na(registrado$chaves_pendentes))
  expect_false(is.na(registrado$xml_evento))
  corpo = rawToChar(pedidos[[1]]$body$data)
  expect_match(pedidos[[1]]$url, "hom1.nfe.fazenda.gov.br", fixed = TRUE)
  expect_match(corpo, paste0('Id="ID110140', chave, '01"><cOrgao>91</cOrgao>'), fixed = TRUE)
  expect_match(corpo, paste0("<descEvento>EPEC</descEvento><cOrgaoAutor>35</cOrgaoAutor><tpAutor>1</tpAutor>",
                             "<verAplic>RNFe</verAplic><dhEmi>", nota$ide$dhEmi, "</dhEmi><tpNF>", nota$ide$tpNF,
                             "</tpNF><IE>", nota$emit$IE, "</IE><dest><UF>", nota$dest$enderDest$UF, "</UF>"), fixed = TRUE)
  expect_match(corpo, paste0("<vNF>", nota$total$ICMSTot$vNF, "</vNF><vICMS>", nota$total$ICMSTot$vICMS, "</vICMS><vST>",
                             nota$total$ICMSTot$vST, "</vST></dest></detEvento>"), fixed = TRUE)
  bloqueado = sefaz_epec(em_contingencia, CERTIFICADO_DO_EVENTO, "teste")
  expect_identical(bloqueado$situacao, 142L)
  expect_identical(bloqueado$chaves_pendentes, paste(CHAVE_DA_NOTA_DE_SP, CHAVE_DA_NOTA_DE_SP))
  # A nota que não é de contingência EPEC e a de UF sem EPEC (o PR e a PB) param antes de qualquer conexão.
  expect_error(sefaz_epec(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), CERTIFICADO_DO_EVENTO, "teste"),
               "tpEmis 4")
  # A nota de outro ambiente, a de cUF diferente do da chave e o lote com mais de uma nota também param antes.
  expect_error(sefaz_epec(sub("<tpAmb>2</tpAmb>", "<tpAmb>1</tpAmb>", em_contingencia, fixed = TRUE), CERTIFICADO_DO_EVENTO,
                          "teste"), "tpAmb 1, e o EPEC vai ao ambiente de tpAmb 2")
  expect_error(sefaz_epec(sub("<cUF>35</cUF>", "<cUF>33</cUF>", em_contingencia, fixed = TRUE), CERTIFICADO_DO_EVENTO,
                          "teste"), "cUF da nota \\(33\\) n\u00e3o \u00e9 o da chave \\(35\\)")
  sem_declaracao = sub("^<\\?xml[^>]*\\?>", "", em_contingencia)
  lote = paste0('<enviNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00"><idLote>1</idLote><indSinc>1</indSinc>',
                sem_declaracao, sem_declaracao, "</enviNFe>")
  expect_error(sefaz_epec(lote, CERTIFICADO_DO_EVENTO, "teste"), "traz 2 notas")
  nota$ide$cUF = "41"
  expect_error(sefaz_epec(nfe_montar(nota), CERTIFICADO_DO_EVENTO, "teste"), "n\u00e3o permite o EPEC")
  expect_length(pedidos, 2)
})

test_that("a resposta sobre outro evento (outro tipo ou outra sequ\u00eancia) vira problema, e nada dela fica na linha", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  respostas = list(retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "110111"),
                   retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "110110", sequencia = 2),
                   retorno_dos_eventos(135, "Evento registrado e vinculado a NF-e", "110110"))
  numero_da_resposta = 0
  httr2::local_mocked_responses(function(req) {
    numero_da_resposta <<- numero_da_resposta + 1
    respostas[[numero_da_resposta]]
  })
  for (tentativa in 1:2) {
    carta = sefaz_carta_correcao(CHAVE_DA_NOTA_DE_SP, "ONDE SE LE RUA DO CLIENTE, 10, LEIA-SE 100", 1,
                                 CERTIFICADO_DO_EVENTO, "teste")
    expect_match(carta$problema, "outro evento", fixed = TRUE)
    expect_true(is.na(carta$situacao))
    expect_true(is.na(carta$xml_evento))
  }
  carta = sefaz_carta_correcao(CHAVE_DA_NOTA_DE_SP, "ONDE SE LE RUA DO CLIENTE, 10, LEIA-SE 100", 1,
                               CERTIFICADO_DO_EVENTO, "teste")
  expect_identical(carta$situacao, 135L)
  expect_true(is.na(carta$problema))
})

test_that("os erros antes de qualquer conex\u00e3o", {
  expect_error(sefaz_cancelar(CHAVE_DA_NOTA_DE_SP, "135260000012345", "CURTA", CERTIFICADO_DO_EVENTO, "teste"), "15 a 255")
  expect_error(sefaz_cancelar(CHAVE_DA_NOTA_DE_SP, "123", "PEDIDO CANCELADO PELO CLIENTE", CERTIFICADO_DO_EVENTO, "teste"),
               "protocolo")
  expect_error(sefaz_cancelar(CHAVE_DA_NOTA_DE_SP, "135260000012345", "PEDIDO CANCELADO PELO CLIENTE", CERTIFICADO_DO_EVENTO,
                              "teste", ambiente = "producao"), "homologa\u00e7\u00e3o")
  expect_error(sefaz_carta_correcao(CHAVE_DA_NOTA_DE_SP, "CORRECAO DO ENDERECO DO CLIENTE", 21, CERTIFICADO_DO_EVENTO, "teste"),
               "1 a 20")
  expect_error(sefaz_carta_correcao(CHAVE_DA_NOTA_DE_SP, "CORRECAO DO ENDERECO DO CLIENTE", 1.5, CERTIFICADO_DO_EVENTO, "teste"),
               "1 a 20")
  # O texto com o que o TString do schema não aceita (a quebra de linha) é recusado antes de ir à SEFAZ.
  expect_error(sefaz_carta_correcao(CHAVE_DA_NOTA_DE_SP, "CORRECAO DO ENDERECO\nDO CLIENTE", 1, CERTIFICADO_DO_EVENTO, "teste"),
               "quebra de linha")
  expect_error(sefaz_carta_correcao("23261011444777000161650030000000779135724686", "CORRECAO DO ENDERECO DO CLIENTE", 1,
                                    CERTIFICADO_DO_EVENTO, "teste"), "modelo 55")
  expect_error(sefaz_manifestar(CHAVE_DA_NOTA_DE_SP, "outro", certificado = CERTIFICADO_DO_EVENTO, senha = "teste"), "tipo")
  expect_error(sefaz_manifestar(CHAVE_DA_NOTA_DE_SP, "nao_realizada", certificado = CERTIFICADO_DO_EVENTO, senha = "teste"),
               "justificativa")
})
