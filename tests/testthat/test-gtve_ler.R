# Os valores esperados são os escritos à mão em inst/exemplos/gtve_proc_sp.xml (validado contra o schema oficial com
# ferramentas/validar_exemplos.R).
GTVE_SP = system.file("exemplos", "gtve_proc_sp.xml", package = "RNFe")
CHAVE_GTVE = "35261011444777000161640010000005011246813570"

test_that("a GTV-e com protocolo: cabe\u00e7alho, pessoas, hor\u00e1rios e autoriza\u00e7\u00e3o", {
  gtve = gtve_ler(GTVE_SP)$gtves
  expect_identical(gtve$chave, CHAVE_GTVE)
  expect_true(chave_valida(gtve$chave))
  expect_identical(gtve$versao, "4.00")
  expect_identical(gtve$modelo, "64")
  expect_identical(gtve$modelo_descricao, "GTV-e (Guia de Transporte de Valores Eletr\u00f4nica)")
  expect_identical(gtve$serie, 1L)
  expect_identical(gtve$numero, 501L)
  expect_identical(gtve$data_emissao, as.Date("2026-10-20"))
  expect_equal(as.numeric(gtve$emissao), as.numeric(as.POSIXct("2026-10-20 11:00:00", tz = "UTC")))
  expect_equal(as.numeric(gtve$saida_origem), as.numeric(as.POSIXct("2026-10-20 11:30:00", tz = "UTC")))
  expect_equal(as.numeric(gtve$chegada_destino), as.numeric(as.POSIXct("2026-10-20 13:15:00", tz = "UTC")))
  expect_identical(gtve$cfop, "5353")
  expect_identical(gtve$cfop_titulo, "Presta\u00e7\u00e3o de servi\u00e7o de transporte a estabelecimento comercial.")
  expect_identical(gtve$tipo_cte, 4L)
  expect_identical(gtve$tipo_cte_descricao, "GTV-e")
  expect_identical(gtve$tipo_servico_descricao, "GTV")
  expect_identical(gtve$modal_descricao, "Rodovi\u00e1rio")
  expect_identical(gtve$formato_dacte_descricao, "Retrato")
  expect_identical(gtve$forma_emissao_descricao, "Normal")
  expect_identical(gtve$ambiente_descricao, "Homologa\u00e7\u00e3o")
  expect_identical(gtve$emitente_documento, "11444777000161")
  expect_identical(gtve$emitente_nome, "TRANSPORTADORA DE VALORES DE TESTE LTDA")
  expect_identical(gtve$remetente_documento, "11222333000181")
  expect_identical(gtve$destinatario_documento, "12ABC34501DE35")
  expect_identical(gtve$destinatario_municipio, "CAMPINAS")
  expect_identical(gtve$origem_codigo_municipio, "3550308")
  expect_identical(gtve$destino_codigo_municipio, "3509502")
  expect_identical(gtve$quantidade_volumes, 3)
  expect_identical(gtve$observacoes_gerais, "RECOLHIMENTO DE TESTE")
  expect_match(gtve$qrcode, paste0("chCTe=", CHAVE_GTVE, "&tpAmb=2$"))
  expect_identical(gtve$protocolo, "135260000054321")
  expect_identical(gtve$situacao, 100L)
  expect_equal(as.numeric(gtve$autorizacao), as.numeric(as.POSIXct("2026-10-20 11:01:10", tz = "UTC")))
  expect_identical(gtve$arquivo, GTVE_SP)
})

test_that("o tomador: o remetente, o destinat\u00e1rio ou outra pessoa", {
  texto = paste(readLines(GTVE_SP, encoding = "UTF-8"), collapse = "\n")
  remetente = gtve_ler(texto)$gtves
  expect_identical(remetente$tomador_papel, 0L)
  expect_identical(remetente$tomador_papel_descricao, "Remetente")
  expect_identical(remetente$tomador_documento, "11222333000181")
  expect_identical(remetente$tomador_nome, "EMPRESA DE TESTE LTDA")
  expect_identical(remetente$tomador_indicador_ie_descricao, "Contribuinte ICMS")

  # Na GTV-e o papel 1 é o destinatário (no CT-e seria o expedidor).
  destinatario = gtve_ler(sub("<toma>0</toma>", "<toma>1</toma>", texto, fixed = TRUE))$gtves
  expect_identical(destinatario$tomador_papel_descricao, "Destinat\u00e1rio")
  expect_identical(destinatario$tomador_documento, "12ABC34501DE35")
  expect_identical(destinatario$tomador_municipio, "CAMPINAS")

  outra_pessoa = paste0("<tomaTerceiro><toma>4</toma><CPF>12345678909</CPF><xNome>TOMADOR DE TESTE</xNome>",
                        "<enderToma><xLgr>RUA DO TOMADOR</xLgr><nro>1</nro><xBairro>CENTRO</xBairro><cMun>2304400</cMun>",
                        "<xMun>FORTALEZA</xMun><UF>CE</UF></enderToma></tomaTerceiro>")
  texto_com_terceiro = sub("(?s)<toma>\\s*<toma>0</toma>\\s*</toma>", outra_pessoa, texto, perl = TRUE)
  terceiro = gtve_ler(texto_com_terceiro)$gtves
  expect_identical(terceiro$tomador_papel, 4L)
  expect_identical(terceiro$tomador_papel_descricao, "Outros")
  expect_identical(terceiro$tomador_documento, "12345678909")
  expect_identical(terceiro$tomador_nome, "TOMADOR DE TESTE")
  expect_identical(terceiro$tomador_uf, "CE")
})

test_that("as esp\u00e9cies levadas, o ve\u00edculo e as observa\u00e7\u00f5es", {
  lida = gtve_ler(GTVE_SP)
  especies = lida$especies
  expect_identical(especies$chave, rep(CHAVE_GTVE, 3))
  expect_identical(especies$tipo, c(1L, 3L, 1L))
  expect_identical(especies$tipo_descricao, c("C\u00e9dula", "Moeda", "C\u00e9dula"))
  expect_identical(especies$valor, c(1500, 120.5, 200))
  expect_identical(especies$numerario_descricao, c("Nacional", "Nacional", "Estrangeiro"))
  expect_identical(especies$moeda_estrangeira, c(NA, NA, "DOLAR AMERICANO"))
  expect_identical(lida$veiculos$placa, "ABC1D23")
  expect_identical(lida$veiculos$uf, "SP")
  expect_identical(lida$veiculos$rntrc, "12345678")
  expect_identical(lida$observacoes$tipo, "ObsCont")
  expect_identical(lida$observacoes$campo, "LACRE")
  expect_identical(lida$observacoes$texto, "MALOTE 001")
})

test_that("a tabela campos tem todos os campos da GTV-e, com a posi\u00e7\u00e3o do grupo que se repete", {
  campos = gtve_ler(GTVE_SP, todos_os_campos = TRUE)$campos
  expect_identical(campos$valor[campos$caminho == "detGTV/infEspecie[2]/vEspecie"], "120.50")
  expect_identical(campos$grupo[campos$caminho == "detGTV/infVeiculo/placa"], "infVeiculo")
  expect_identical(campos$valor[campos$caminho == "emit/enderEmit/xLgr"], "AVENIDA DE TESTE")
  expect_false(any(grepl("Signature|infCTeSupl", campos$caminho)))
  expect_null(gtve_ler(GTVE_SP)$campos)
})

test_that("o pr\u00f3prio texto do XML d\u00e1 o mesmo que o arquivo", {
  texto = paste(readLines(GTVE_SP, encoding = "UTF-8"), collapse = "\n")
  pelo_texto = gtve_ler(texto)
  pelo_arquivo = gtve_ler(GTVE_SP)
  pelo_arquivo$gtves$arquivo = "(texto 1)"
  expect_identical(pelo_texto$gtves, pelo_arquivo$gtves)
  expect_identical(pelo_texto$especies, pelo_arquivo$especies)
})

test_that("arquivo que n\u00e3o d\u00e1 para ler n\u00e3o atrapalha os outros", {
  cte = system.file("exemplos", "cte_proc_sp.xml", package = "RNFe")
  lida = gtve_ler(c("nao_existe.xml", GTVE_SP, "<GTVe><infCte>", cte, NA))
  expect_identical(lida$gtves$chave, CHAVE_GTVE)
  expect_identical(lida$arquivos$gtves, c(0L, 1L, 0L, 0L, 0L))
  problemas = lida$arquivos$problema
  expect_identical(problemas[1], "arquivo n\u00e3o encontrado")
  expect_true(is.na(problemas[2]))
  expect_match(problemas[3], "^n\u00e3o \u00e9 um XML v\u00e1lido")
  expect_identical(problemas[4], "n\u00e3o \u00e9 uma GTV-e (o XML come\u00e7a por <cteProc>)")
  expect_identical(problemas[5], "vazio")
  # Os outros leitores dizem onde a GTV-e é lida.
  expect_identical(nfe_ler(GTVE_SP)$arquivos$problema, "\u00e9 uma GTV-e, lida por gtve_ler()")
})

test_that("sem arquivo nenhum, as tabelas v\u00eam vazias com as colunas certas", {
  vazia = gtve_ler(character(), todos_os_campos = TRUE)
  cheia = gtve_ler(GTVE_SP, todos_os_campos = TRUE)
  for (nome in names(cheia)) {
    expect_identical(nrow(vazia[[nome]]), 0L)
    expect_identical(names(vazia[[nome]]), names(cheia[[nome]]))
    expect_identical(vapply(vazia[[nome]], function(coluna) class(coluna)[1], character(1)),
                     vapply(cheia[[nome]], function(coluna) class(coluna)[1], character(1)))
  }
})
