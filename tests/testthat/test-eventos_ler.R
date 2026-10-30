# Os valores esperados são os escritos à mão nos eventos de inst/exemplos (validados contra os schemas oficiais
# com ferramentas/validar_exemplos.R).
exemplo = function(nome_do_arquivo) system.file("exemplos", nome_do_arquivo, package = "RNfe")
CANCELAMENTO_NFE = exemplo("evento_nfe_cancelamento.xml")
CARTA_CORRECAO_NFE = exemplo("evento_nfe_carta_correcao.xml")
RESUMO_NFE = exemplo("evento_nfe_resumo_ciencia.xml")
CANCELAMENTO_CTE = exemplo("evento_cte_cancelamento.xml")
ENCERRAMENTO_MDFE = exemplo("evento_mdfe_encerramento.xml")
CANCELAMENTO_NFSE = exemplo("evento_nfse_cancelamento.xml")
TODOS_OS_EVENTOS = c(CANCELAMENTO_NFE, CARTA_CORRECAO_NFE, RESUMO_NFE, CANCELAMENTO_CTE, ENCERRAMENTO_MDFE, CANCELAMENTO_NFSE)
CHAVE_NFE_SP = "35261011222333000181550010000010011123456785"

test_that("o cancelamento da NF-e: o pedido e o retorno da SEFAZ", {
  evento = eventos_ler(CANCELAMENTO_NFE)$eventos
  expect_identical(evento$documento, "NF-e")
  expect_identical(evento$chave, CHAVE_NFE_SP)
  expect_identical(evento$tipo, "110111")
  expect_identical(evento$descricao, "Cancelamento")
  expect_identical(evento$sequencia, 1L)
  expect_equal(as.numeric(evento$data_evento), as.numeric(as.POSIXct("2026-10-15 19:20:00", tz = "UTC")))
  expect_identical(attr(evento$data_evento, "tzone"), "America/Sao_Paulo")
  expect_identical(evento$autor_documento, "11222333000181")
  expect_identical(evento$orgao, "35")
  expect_identical(evento$ambiente, 2L)
  expect_identical(evento$justificativa, "PEDIDO CANCELADO PELO CLIENTE ANTES DA SAIDA")
  expect_true(is.na(evento$correcao))
  expect_identical(evento$protocolo_documento, "135260000012345")
  expect_identical(evento$situacao, 135L)
  expect_identical(evento$motivo, "Evento registrado e vinculado a NF-e")
  expect_identical(evento$protocolo, "135260000054321")
  expect_equal(as.numeric(evento$registro), as.numeric(as.POSIXct("2026-10-15 19:20:03", tz = "UTC")))
  expect_false(evento$resumo)
  expect_identical(evento$versao, "1.00")
  expect_identical(evento$arquivo, CANCELAMENTO_NFE)
})

test_that("a carta de corre\u00e7\u00e3o da NF-e, de emitente com CNPJ alfanum\u00e9rico", {
  lido = eventos_ler(CARTA_CORRECAO_NFE)
  evento = lido$eventos
  expect_identical(evento$tipo, "110110")
  expect_identical(evento$descricao, "Carta de Correcao")
  expect_identical(evento$autor_documento, "12ABC34501DE35")
  expect_identical(evento$correcao, "ONDE SE LE RUA DO CLIENTE, 10, LEIA-SE RUA DO CLIENTE, 100")
  expect_true(is.na(evento$justificativa))
  expect_identical(evento$protocolo, "323260000006789")
  campos = lido$campos
  expect_identical(campos$valor[campos$caminho == "retEvento/infEvento/CPFDest"], "12345678909")
  expect_match(campos$valor[campos$caminho == "evento/infEvento/detEvento/xCondUso"], "^A Carta de Correcao e disciplinada")
})

test_that("o resumo de evento (resEvento) n\u00e3o tem detalhe nem retorno", {
  evento = eventos_ler(RESUMO_NFE)$eventos
  expect_true(evento$resumo)
  expect_identical(evento$documento, "NF-e")
  expect_identical(evento$chave, CHAVE_NFE_SP)
  expect_identical(evento$tipo, "210210")
  expect_identical(evento$descricao, "Ciencia da Operacao")
  expect_identical(evento$autor_documento, "11444777000161")
  expect_identical(evento$orgao, "91")
  expect_identical(evento$protocolo, "891260000011111")
  expect_equal(as.numeric(evento$registro), as.numeric(as.POSIXct("2026-10-15 14:00:02", tz = "UTC")))
  expect_true(is.na(evento$situacao))
  expect_true(is.na(evento$ambiente))
  expect_identical(evento$versao, "1.01")
})

test_that("o cancelamento do CT-e e o encerramento do MDF-e, com o detalhe no grupo de cada evento", {
  lido = eventos_ler(c(CANCELAMENTO_CTE, ENCERRAMENTO_MDFE))
  cte = lido$eventos[1, ]
  expect_identical(cte$documento, "CT-e")
  expect_identical(cte$chave, "35261012ABC34501DE35570010000005551876543210")
  expect_identical(cte$descricao, "Cancelamento")
  expect_identical(cte$justificativa, "CT-E EMITIDO EM DUPLICIDADE PARA O MESMO FRETE")
  expect_identical(cte$protocolo_documento, "135260000098765")
  expect_identical(cte$situacao, 135L)
  expect_identical(cte$motivo, "Evento registrado e vinculado a CT-e")
  expect_identical(cte$versao, "4.00")
  mdfe = lido$eventos[2, ]
  expect_identical(mdfe$documento, "MDF-e")
  expect_identical(mdfe$tipo, "110112")
  expect_identical(mdfe$descricao, "Encerramento")
  expect_identical(mdfe$protocolo_documento, "935260000011111")
  expect_identical(mdfe$protocolo, "935260000022222")
  campos = lido$campos
  expect_identical(campos$valor[campos$caminho == "eventoCTe/infEvento/detEvento/evCancCTe/xJust"], cte$justificativa)
  do_mdfe = campos[campos$chave == mdfe$chave, ]
  expect_identical(do_mdfe$valor[do_mdfe$caminho == "eventoMDFe/infEvento/detEvento/evEncMDFe/cMun"], "3304557")
  expect_identical(do_mdfe$grupo[do_mdfe$campo == "dtEnc"], "evEncMDFe")
  expect_identical(do_mdfe$valor[do_mdfe$caminho == "retEventoMDFe/infEvento/cStat"], "135")
})

test_that("a presta\u00e7\u00e3o em desacordo do CT-e: o motivo vai em observacao", {
  texto = paste(readLines(CANCELAMENTO_CTE, encoding = "UTF-8"), collapse = "\n")
  grupo_do_desacordo = paste0("<evPrestDesacordo><descEvento>Prestacao do Servico em Desacordo</descEvento>",
                              "<indDesacordoOper>1</indDesacordoOper><xObs>MERCADORIA ENTREGUE EM OUTRO ENDERECO</xObs></evPrestDesacordo>")
  texto = sub("(?s)<evCancCTe>.*</evCancCTe>", grupo_do_desacordo, texto, perl = TRUE)
  texto = gsub("110111", "610110", texto, fixed = TRUE)
  evento = eventos_ler(texto)$eventos
  expect_identical(evento$tipo, "610110")
  expect_identical(evento$descricao, "Prestacao do Servico em Desacordo")
  expect_identical(evento$observacao, "MERCADORIA ENTREGUE EM OUTRO ENDERECO")
  expect_true(is.na(evento$justificativa))
})

test_that("o cancelamento da NFS-e: o tipo pelo nome do grupo e o registro pelo sistema nacional", {
  lido = eventos_ler(CANCELAMENTO_NFSE)
  evento = lido$eventos
  expect_identical(evento$documento, "NFS-e")
  expect_identical(evento$chave, "35503082211222333000181000000000012326101234567898")
  expect_identical(evento$tipo, "101101")
  expect_identical(evento$descricao, "Cancelamento de NFS-e")
  expect_identical(evento$sequencia, 1L)
  expect_identical(evento$autor_documento, "11222333000181")
  expect_identical(evento$ambiente, 2L)
  expect_identical(evento$justificativa, "VALOR DO SERVICO INFORMADO ERRADO NA EMISSAO")
  expect_equal(as.numeric(evento$registro), as.numeric(as.POSIXct("2026-10-20 20:30:05", tz = "UTC")))
  expect_true(is.na(evento$orgao))
  expect_true(is.na(evento$situacao))
  expect_identical(evento$versao, "1.01")
  campos = lido$campos
  expect_identical(campos$valor[campos$caminho == "evento/infEvento/pedRegEvento/infPedReg/e101101/cMotivo"], "1")
  expect_identical(campos$valor[campos$caminho == "evento/infEvento/nDFSe"], "789")
})

test_that("a NFS-e 1.00 de substitui\u00e7\u00e3o, com o nPedRegEvento entre a chave e o grupo do evento", {
  texto = paste(readLines(CANCELAMENTO_NFSE, encoding = "UTF-8"), collapse = "\n")
  texto = sub('versao="1.01"', 'versao="1.00"', texto, fixed = TRUE)
  texto = sub("</chNFSe>", "</chNFSe>\n        <nPedRegEvento>1</nPedRegEvento>", texto, fixed = TRUE)
  texto = gsub("e101101", "e105102", texto, fixed = TRUE)
  evento = eventos_ler(texto)$eventos
  expect_identical(evento$tipo, "105102")
  expect_identical(evento$descricao, "Cancelamento de NFS-e")
})

test_that("a tabela campos tem todos os campos de cada evento, sem a assinatura", {
  campos = eventos_ler(TODOS_OS_EVENTOS)$campos
  eventos = eventos_ler(TODOS_OS_EVENTOS)$eventos
  for (posicao in seq_along(TODOS_OS_EVENTOS)) {
    documento = xml2::read_xml(TODOS_OS_EVENTOS[posicao])
    xml2::xml_ns_strip(documento)
    folhas = xml2::xml_find_all(documento, "//*[not(*)][not(ancestor::Signature)]")
    do_evento = campos$chave == eventos$chave[posicao] & campos$tipo == eventos$tipo[posicao]
    expect_identical(sum(do_evento), length(folhas))
    expect_identical(campos$valor[do_evento], xml2::xml_text(folhas))
  }
  expect_false(any(grepl("Signature|DigestValue|X509", campos$caminho)))
})

test_that("sem a tabela campos, quando ela n\u00e3o \u00e9 pedida, o resto n\u00e3o muda", {
  com_campos = eventos_ler(TODOS_OS_EVENTOS)
  sem_campos = eventos_ler(TODOS_OS_EVENTOS, todos_os_campos = FALSE)
  expect_identical(names(sem_campos), c("eventos", "arquivos"))
  expect_identical(sem_campos$eventos, com_campos$eventos)
})

test_that("o evento s\u00f3 assinado, sem o retorno, e o retorno de cada pedido no envelope dele", {
  texto = paste(readLines(CANCELAMENTO_NFE, encoding = "UTF-8"), collapse = "\n")
  so_o_pedido = regmatches(texto, regexpr("(?s)<evento versao.*</evento>", texto, perl = TRUE))
  evento = eventos_ler(so_o_pedido)$eventos
  expect_identical(evento$descricao, "Cancelamento")
  expect_true(is.na(evento$situacao))
  expect_true(is.na(evento$protocolo))

  # Dois envelopes no mesmo arquivo: cada pedido fica com o retorno do seu.
  envelope_do_cancelamento = regmatches(texto, regexpr("(?s)<procEventoNFe.*</procEventoNFe>", texto, perl = TRUE))
  texto_da_carta = paste(readLines(CARTA_CORRECAO_NFE, encoding = "UTF-8"), collapse = "\n")
  envelope_da_carta = regmatches(texto_da_carta, regexpr("(?s)<procEventoNFe.*</procEventoNFe>", texto_da_carta, perl = TRUE))
  dois_envelopes = paste0("<lote>", envelope_do_cancelamento, envelope_da_carta, "</lote>")
  eventos = eventos_ler(dois_envelopes)$eventos
  expect_identical(eventos$tipo, c("110111", "110110"))
  expect_identical(eventos$protocolo, c("135260000054321", "323260000006789"))
})

test_that("as notas canceladas: o cancelamento junta com a nota pela chave", {
  notas = nfe_ler(exemplo("nfe_proc_sp.xml"))$notas
  eventos = eventos_ler(TODOS_OS_EVENTOS)$eventos
  canceladas = eventos$chave[eventos$tipo == "110111" & eventos$documento == "NF-e"]
  expect_identical(notas$situacao, 100L)
  expect_true(notas$chave %in% canceladas)
})

test_that("arquivo que n\u00e3o d\u00e1 para ler n\u00e3o atrapalha os outros, e os leitores n\u00e3o se confundem", {
  nota = exemplo("nfe_proc_sp.xml")
  lido = eventos_ler(c("nao_existe.xml", CANCELAMENTO_NFE, nota, "<retEnvEvento/>", NA))
  expect_identical(lido$eventos$tipo, "110111")
  expect_identical(lido$arquivos$eventos, c(0L, 1L, 0L, 0L, 0L))
  problemas = lido$arquivos$problema
  expect_identical(problemas[1], "arquivo n\u00e3o encontrado")
  expect_true(is.na(problemas[2]))
  expect_identical(problemas[3], "n\u00e3o \u00e9 um evento (o XML come\u00e7a por <nfeProc>)")
  expect_identical(problemas[4], "n\u00e3o \u00e9 um evento (o XML come\u00e7a por <retEnvEvento>)")
  expect_identical(problemas[5], "vazio")
  # O evento cita a chave do documento, mas não é o documento.
  expect_identical(nrow(nfe_ler(CANCELAMENTO_NFE)$notas), 0L)
  expect_identical(nrow(cte_ler(CANCELAMENTO_CTE)$ctes), 0L)
  expect_identical(nrow(mdfe_ler(ENCERRAMENTO_MDFE)$mdfes), 0L)
  expect_identical(nrow(nfse_ler(CANCELAMENTO_NFSE)$nfses), 0L)
})

test_that("sem arquivo nenhum, as tabelas v\u00eam vazias com as colunas certas", {
  vazio = eventos_ler(character())
  cheio = eventos_ler(TODOS_OS_EVENTOS)
  for (nome in names(cheio)) {
    expect_identical(nrow(vazio[[nome]]), 0L)
    expect_identical(names(vazio[[nome]]), names(cheio[[nome]]))
    expect_identical(vapply(vazio[[nome]], function(coluna) class(coluna)[1], character(1)),
                     vapply(cheio[[nome]], function(coluna) class(coluna)[1], character(1)))
  }
})
