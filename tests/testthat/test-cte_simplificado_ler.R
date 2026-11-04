# Os valores esperados são os escritos à mão em inst/exemplos/cte_simp_proc_sp.xml (validado contra o schema oficial
# com ferramentas/validar_exemplos.R).
CTE_SIMPLIFICADO_SP = system.file("exemplos", "cte_simp_proc_sp.xml", package = "RNFe")
CHAVE_SIMPLIFICADO = "35261012ABC34501DE35570010000007771135792467"

test_that("o CT-e simplificado com protocolo: cabe\u00e7alho, emitente, totais e autoriza\u00e7\u00e3o", {
  cte = cte_simplificado_ler(CTE_SIMPLIFICADO_SP)$ctes
  expect_identical(cte$chave, CHAVE_SIMPLIFICADO)
  expect_true(chave_valida(cte$chave))
  expect_identical(cte$versao, "4.00")
  expect_identical(cte$modelo, "57")
  expect_identical(cte$modelo_descricao, "CT-e")
  expect_identical(cte$serie, 1L)
  expect_identical(cte$numero, 777L)
  expect_identical(cte$data_emissao, as.Date("2026-10-22"))
  expect_equal(as.numeric(cte$emissao), as.numeric(as.POSIXct("2026-10-22 12:00:00", tz = "UTC")))
  expect_identical(cte$cfop, "6353")
  expect_match(cte$cfop_titulo, "^Presta\u00e7\u00e3o de servi\u00e7o de transporte")
  expect_identical(cte$tipo_cte, 5L)
  expect_identical(cte$tipo_cte_descricao, "CT-e simplificado")
  expect_identical(cte$tipo_servico_descricao, "Normal")
  expect_identical(cte$modal_descricao, "Rodovi\u00e1rio")
  expect_identical(cte$forma_emissao_descricao, "Normal")
  expect_identical(cte$ambiente_descricao, "Homologa\u00e7\u00e3o")
  expect_identical(cte$processo_emissao_descricao, "Emiss\u00e3o com aplicativo do contribuinte")
  expect_identical(cte$inicio_uf, "SP")
  expect_identical(cte$fim_uf, "RJ")
  expect_identical(cte$retira_descricao, "N\u00e3o")
  expect_identical(cte$emitente_documento, "12ABC34501DE35")
  expect_identical(cte$emitente_nome, "TRANSPORTADORA DE TESTE LTDA")
  expect_identical(cte$emitente_regime_descricao, "Regime Normal")
  expect_identical(cte$valor_prestacao, 350)
  expect_identical(cte$valor_receber, 350)
  expect_true(is.na(cte$valor_prestacao_sem_tributos))
  expect_identical(cte$grupo_icms, "ICMS00")
  expect_identical(cte$cst_icms_descricao, "Tributa\u00e7\u00e3o normal do ICMS")
  expect_identical(cte$base_icms, 350)
  expect_identical(cte$aliquota_icms, 12)
  expect_identical(cte$valor_icms, 42)
  expect_identical(cte$base_ibs_cbs, 350)
  expect_identical(cte$valor_ibs_uf, 0.35)
  expect_identical(cte$valor_ibs_municipio, 0)
  expect_identical(cte$valor_ibs, 0.35)
  expect_identical(cte$valor_cbs, 3.15)
  expect_true(is.na(cte$valor_total_documento))
  expect_identical(cte$valor_carga, 1500)
  expect_identical(cte$produto_predominante, "BEBIDAS")
  expect_identical(cte$rntrc, "12345678")
  expect_identical(cte$fatura_numero, "FAT-777")
  expect_identical(cte$fatura_valor_original, 350)
  expect_identical(cte$fatura_desconto, 10)
  expect_identical(cte$fatura_valor_liquido, 340)
  expect_identical(cte$observacoes_gerais, "CT-E SIMPLIFICADO DE TESTE DO PACOTE RNFE - SEM VALOR FISCAL")
  expect_match(cte$qrcode, paste0("chCTe=", CHAVE_SIMPLIFICADO, "&tpAmb=2$"))
  expect_identical(cte$protocolo, "135260000077777")
  expect_identical(cte$situacao, 100L)
  expect_equal(as.numeric(cte$autorizacao), as.numeric(as.POSIXct("2026-10-22 12:01:15", tz = "UTC")))
  expect_identical(cte$arquivo, CTE_SIMPLIFICADO_SP)
})

test_that("o tomador vem do pr\u00f3prio grupo, e o 4 \u00e9 o terceiro", {
  texto = paste(readLines(CTE_SIMPLIFICADO_SP, encoding = "UTF-8"), collapse = "\n")
  terceiro = cte_simplificado_ler(texto)$ctes
  expect_identical(terceiro$tomador_papel, 4L)
  expect_identical(terceiro$tomador_papel_descricao, "Terceiro")
  expect_identical(terceiro$tomador_indicador_ie_descricao, "Contribuinte ICMS")
  expect_identical(terceiro$tomador_documento, "11222333000181")
  expect_identical(terceiro$tomador_nome, "EMPRESA DE TESTE LTDA")
  expect_identical(terceiro$tomador_ie, "123456789012")
  expect_identical(terceiro$tomador_municipio, "S\u00c3O PAULO")
  expect_identical(terceiro$tomador_codigo_municipio, "3550308")
  expect_identical(terceiro$tomador_uf, "SP")

  # Com outro papel, os dados continuam os do grupo toma: o CT-e simplificado não tem as outras pessoas.
  remetente = cte_simplificado_ler(sub("<toma>4</toma>", "<toma>0</toma>", texto, fixed = TRUE))$ctes
  expect_identical(remetente$tomador_papel_descricao, "Remetente")
  expect_identical(remetente$tomador_documento, "11222333000181")

  # O de substituição (tipo 6) também chama o 4 de terceiro; no CT-e ele é "Outros".
  substituicao = cte_simplificado_ler(sub("<tpCTe>5</tpCTe>", "<tpCTe>6</tpCTe>", texto, fixed = TRUE))$ctes
  expect_identical(substituicao$tipo_cte_descricao, "Substitui\u00e7\u00e3o de CT-e simplificado")
  expect_identical(substituicao$tomador_papel_descricao, "Terceiro")
  cte_com_toma4 = cte_ler(system.file("exemplos", "cte_ce_simples_toma4.xml", package = "RNFe"))$ctes
  expect_identical(cte_com_toma4$tomador_papel_descricao, "Outros")
})

test_that("as entregas, com o valor, o IBS e a CBS de cada uma", {
  entregas = cte_simplificado_ler(CTE_SIMPLIFICADO_SP)$entregas
  expect_identical(entregas$chave, rep(CHAVE_SIMPLIFICADO, 2))
  expect_identical(entregas$entrega, c(1L, 2L))
  expect_identical(entregas$inicio_codigo_municipio, c("3550308", "3550308"))
  expect_identical(entregas$fim_codigo_municipio, c("3304557", "3303302"))
  expect_identical(entregas$fim_municipio, c("RIO DE JANEIRO", "NITER\u00d3I"))
  expect_identical(entregas$valor_prestacao, c(200, 150))
  expect_identical(entregas$valor_receber, c(200, 150))
  expect_identical(entregas$cst_ibs_cbs, c("000", "000"))
  expect_false(anyNA(entregas$cst_ibs_cbs_descricao))
  expect_identical(entregas$classificacao_ibs_cbs, c("000001", "000001"))
  expect_false(anyNA(entregas$classificacao_ibs_cbs_nome))
  expect_identical(entregas$base_ibs_cbs, c(200, 150))
  expect_identical(entregas$aliquota_ibs_uf, c(0.1, 0.1))
  expect_identical(entregas$valor_ibs_uf, c(0.2, 0.15))
  expect_identical(entregas$valor_ibs, c(0.2, 0.15))
  expect_identical(entregas$aliquota_cbs, c(0.9, 0.9))
  expect_identical(entregas$valor_cbs, c(1.8, 1.35))
  # As entregas somam o total do CT-e.
  cte = cte_simplificado_ler(CTE_SIMPLIFICADO_SP)$ctes
  expect_equal(sum(entregas$valor_prestacao), cte$valor_prestacao)
  expect_equal(sum(entregas$valor_cbs), cte$valor_cbs)
})

test_that("os componentes e os documentos de cada entrega", {
  lido = cte_simplificado_ler(CTE_SIMPLIFICADO_SP)
  componentes = lido$componentes
  expect_identical(componentes$entrega, c(1L, 1L, 2L))
  expect_identical(componentes$nome, c("FRETE PESO", "PEDAGIO", "FRETE PESO"))
  expect_identical(componentes$valor, c(180, 20, 150))

  documentos = lido$documentos
  expect_identical(documentos$chave, rep(CHAVE_SIMPLIFICADO, 3))
  expect_identical(documentos$entrega, c(1L, 2L, 2L))
  expect_identical(documentos$tipo, c("infNFe", "infDocAnt", "infNFeTranspParcial"))
  expect_identical(documentos$documento_chave, c("35261011222333000181550010000010011123456785",
                                                 "35261012ABC34501DE35570010000005551876543210",
                                                 "23261012ABC34501DE35550020000000421876543213"))
  expect_identical(documentos$previsao_entrega, as.Date(c("2026-10-24", NA, NA)))
  expect_identical(documentos$tipo_prestacao, c(NA, 2L, NA))
  expect_identical(documentos$tipo_prestacao_descricao, c(NA, "Parcial", NA))
  expect_identical(documentos$cte_anterior_chave, c(NA, NA, "35261012ABC34501DE35570010000005551876543210"))
  expect_true(all(chave_valida(documentos$documento_chave)))
})

test_that("o CT-e substitu\u00eddo vem em documentos, sem entrega, com a troca do tomador", {
  texto = paste(readLines(CTE_SIMPLIFICADO_SP, encoding = "UTF-8"), collapse = "\n")
  substituido = "35261012ABC34501DE35570010000007761135792460"
  com_substituicao = sub("<imp>", paste0("<infCteSub><chCte>", substituido, "</chCte><indAlteraToma>1</indAlteraToma>",
                                         "</infCteSub><imp>"), texto, fixed = TRUE)
  com_substituicao = sub("<tpCTe>5</tpCTe>", "<tpCTe>6</tpCTe>", com_substituicao, fixed = TRUE)
  documentos = cte_simplificado_ler(com_substituicao)$documentos
  expect_identical(documentos$tipo[4], "infCteSub")
  expect_identical(documentos$documento_chave[4], substituido)
  expect_true(is.na(documentos$entrega[4]))
  expect_identical(documentos$altera_tomador, c(NA, NA, NA, 1L))
  expect_identical(documentos$altera_tomador_descricao[4], "CT-e de altera\u00e7\u00e3o de tomador")
})

# Os grupos da Reforma no fim do ide: a compra governamental (com o documento anterior) e o pagamento antecipado.
COMPRA_GOVERNAMENTAL_E_PAGAMENTO_ANTECIPADO = paste0(
  "<gCompraGov><tpEnteGov>1</tpEnteGov><pRedutor>5.0000</pRedutor><tpOperGov>2</tpOperGov>",
  "<refDFeAnt>35261011222333000181550010000010011123456785</refDFeAnt></gCompraGov>",
  "<tpPagAnt>3</tpPagAnt><gPagAntecipado><chDFePagAnt>35261012ABC34501DE35570010000007761135792460</chDFePagAnt>",
  "</gPagAntecipado>"
)

test_that("os documentos da Reforma no ide: o da compra governamental e o do pagamento antecipado", {
  texto = paste(readLines(CTE_SIMPLIFICADO_SP, encoding = "UTF-8"), collapse = "\n")
  com_reforma = sub("<retira>1</retira>", paste0("<retira>1</retira>", COMPRA_GOVERNAMENTAL_E_PAGAMENTO_ANTECIPADO), texto,
                    fixed = TRUE)
  documentos = cte_simplificado_ler(com_reforma)$documentos
  expect_identical(documentos$tipo, c("refDFeAnt", "chDFePagAnt", "infNFe", "infDocAnt", "infNFeTranspParcial"))
  expect_identical(documentos$documento_chave[1:2], c("35261011222333000181550010000010011123456785",
                                                      "35261012ABC34501DE35570010000007761135792460"))
  expect_identical(documentos$entrega, c(NA, NA, 1L, 2L, 2L))
  cte = system.file("exemplos", "cte_proc_sp.xml", package = "RNFe")
  texto_do_cte = paste(readLines(cte, encoding = "UTF-8"), collapse = "\n")
  cte_com_reforma = sub("</toma3>", paste0("</toma3>", COMPRA_GOVERNAMENTAL_E_PAGAMENTO_ANTECIPADO), texto_do_cte, fixed = TRUE)
  documentos_do_cte = cte_ler(cte_com_reforma)$documentos
  expect_identical(documentos_do_cte$tipo, c("refDFeAnt", "chDFePagAnt", "infNFe", "infNFe"))
  expect_true(all(is.na(documentos_do_cte$altera_tomador)))
})

test_that("o prefixo no namespace e o CT-e simplificado dentro de outro grupo", {
  com_prefixo = '<cte:CTeSimp xmlns:cte="http://www.portalfiscal.inf.br/cte"><cte:infCte versao="4.00" Id="CTe1"/></cte:CTeSimp>'
  mensagem = "o XML usa prefixo no namespace do documento (<cte:CTeSimp>), que a SEFAZ n\u00e3o aceita e o RNFe n\u00e3o l\u00ea"
  expect_identical(cte_simplificado_ler(com_prefixo)$arquivos$problema, mensagem)
  expect_identical(cte_ler(com_prefixo)$arquivos$problema, mensagem)
  dentro_de_outro = '<lote><CTeSimp xmlns="http://www.portalfiscal.inf.br/cte"><infCte versao="4.00" Id="CTe1"/></CTeSimp></lote>'
  expect_identical(cte_ler(dentro_de_outro)$arquivos$problema, "\u00e9 um CT-e simplificado, lido por cte_simplificado_ler()")
  expect_identical(cte_simplificado_ler(dentro_de_outro)$arquivos$ctes, 1L)
})

test_that("a carga, com o tipo da medida em c\u00f3digo", {
  cargas = cte_simplificado_ler(CTE_SIMPLIFICADO_SP)$cargas
  expect_identical(cargas$unidade, c("01", "03"))
  expect_identical(cargas$unidade_descricao, c("KG", "Unidade"))
  expect_identical(cargas$tipo_medida, c("02", "07"))
  expect_identical(cargas$tipo_medida_descricao, c("Peso bruto da NF-e", "Caixas"))
  expect_identical(cargas$quantidade, c(320, 48))
})

test_that("os impostos: os de cada entrega, os do CT-e inteiro e os totais", {
  impostos = cte_simplificado_ler(CTE_SIMPLIFICADO_SP)$impostos
  expect_identical(unique(impostos$tributo), c("IBSCBS", "ICMS", "IBSCBSTot"))
  da_entrega_2 = impostos[impostos$entrega %in% 2L, ]
  expect_identical(da_entrega_2$valor[da_entrega_2$campo == "vCBS"], "1.35")
  expect_identical(da_entrega_2$grupo[da_entrega_2$campo == "vCBS"], "gCBS")
  do_icms = impostos[impostos$tributo == "ICMS", ]
  expect_true(all(is.na(do_icms$entrega)))
  expect_identical(do_icms$grupo, rep("ICMS00", 4))
  expect_identical(do_icms$valor[do_icms$campo == "vICMS"], "42.00")
  dos_totais = impostos[impostos$tributo == "IBSCBSTot", ]
  expect_true(all(is.na(dos_totais$entrega)))
  expect_identical(dos_totais$valor[dos_totais$campo == "vCBS"], "3.15")
  expect_identical(sum(dos_totais$campo == "vDif"), 3L)
})

test_that("as parcelas, o pagamento vinculado e as observa\u00e7\u00f5es", {
  lido = cte_simplificado_ler(CTE_SIMPLIFICADO_SP)
  expect_identical(lido$parcelas$numero, "001")
  expect_identical(lido$parcelas$vencimento, as.Date("2026-11-21"))
  expect_identical(lido$parcelas$valor, 340)
  expect_identical(lido$pagamentos_vinculados$transacao, "TRANSACAO-DE-TESTE-3")
  expect_identical(lido$pagamentos_vinculados$meio_pagamento, "17")
  expect_false(is.na(lido$pagamentos_vinculados$meio_pagamento_descricao))
  expect_identical(lido$observacoes$tipo, "ObsCont")
  expect_identical(lido$observacoes$campo, "ROTA")
  expect_identical(lido$observacoes$texto, "LITORAL")
})

test_that("a tabela campos tem todos os campos do CT-e simplificado, com a posi\u00e7\u00e3o do grupo que se repete", {
  campos = cte_simplificado_ler(CTE_SIMPLIFICADO_SP, todos_os_campos = TRUE)$campos
  expect_identical(campos$valor[campos$caminho == "det[2]/Comp/vComp"], "150.00")
  expect_identical(campos$valor[campos$caminho == "det[1]/Comp[2]/xNome"], "PEDAGIO")
  expect_identical(campos$valor[campos$caminho == "toma/enderToma/xLgr"], "RUA DE TESTE")
  expect_false(any(grepl("Signature|infCTeSupl", campos$caminho)))
  expect_null(cte_simplificado_ler(CTE_SIMPLIFICADO_SP)$campos)
})

test_that("o pr\u00f3prio texto do XML d\u00e1 o mesmo que o arquivo", {
  texto = paste(readLines(CTE_SIMPLIFICADO_SP, encoding = "UTF-8"), collapse = "\n")
  pelo_texto = cte_simplificado_ler(texto)
  pelo_arquivo = cte_simplificado_ler(CTE_SIMPLIFICADO_SP)
  pelo_arquivo$ctes$arquivo = "(texto 1)"
  expect_identical(pelo_texto$ctes, pelo_arquivo$ctes)
  expect_identical(pelo_texto$entregas, pelo_arquivo$entregas)
  expect_identical(pelo_texto$documentos, pelo_arquivo$documentos)
})

test_that("arquivo que n\u00e3o d\u00e1 para ler n\u00e3o atrapalha os outros", {
  cte = system.file("exemplos", "cte_proc_sp.xml", package = "RNFe")
  sem_infcte = '<CTeSimp xmlns="http://www.portalfiscal.inf.br/cte"/>'
  lido = cte_simplificado_ler(c("nao_existe.xml", CTE_SIMPLIFICADO_SP, "<CTeSimp><infCte>", cte, sem_infcte, NA))
  expect_identical(lido$ctes$chave, CHAVE_SIMPLIFICADO)
  expect_identical(lido$arquivos$ctes, c(0L, 1L, 0L, 0L, 0L, 0L))
  problemas = lido$arquivos$problema
  expect_identical(problemas[1], "arquivo n\u00e3o encontrado")
  expect_true(is.na(problemas[2]))
  expect_match(problemas[3], "^n\u00e3o \u00e9 um XML v\u00e1lido")
  expect_identical(problemas[4], "n\u00e3o \u00e9 um CT-e simplificado (o XML come\u00e7a por <cteProc>)")
  expect_identical(problemas[5], "o XML come\u00e7a por <CTeSimp>, mas sem o infCte")
  expect_identical(problemas[6], "vazio")
  # Os outros leitores dizem onde o CT-e simplificado é lido.
  expect_identical(cte_ler(CTE_SIMPLIFICADO_SP)$arquivos$problema,
                   "\u00e9 um CT-e simplificado, lido por cte_simplificado_ler()")
  expect_identical(gtve_ler(CTE_SIMPLIFICADO_SP)$arquivos$problema,
                   "\u00e9 um CT-e simplificado, lido por cte_simplificado_ler()")
  # E o CT-e simplificado não entra no cte_ler() nem no gtve_ler().
  expect_identical(nrow(cte_ler(CTE_SIMPLIFICADO_SP)$ctes), 0L)
})

test_that("os eventos do CT-e simplificado s\u00e3o os do CT-e", {
  evento = paste(readLines(system.file("exemplos", "evento_cte_cancelamento.xml", package = "RNFe"), encoding = "UTF-8"),
                 collapse = "\n")
  chave_do_evento = eventos_ler(evento)$eventos$chave
  do_simplificado = gsub(chave_do_evento, CHAVE_SIMPLIFICADO, evento, fixed = TRUE)
  lido = eventos_ler(do_simplificado)$eventos
  expect_identical(lido$chave, CHAVE_SIMPLIFICADO)
  expect_identical(lido$documento, "CT-e")
})

test_that("sem arquivo nenhum, as tabelas v\u00eam vazias com as colunas certas", {
  vazia = cte_simplificado_ler(character(), todos_os_campos = TRUE)
  cheia = cte_simplificado_ler(CTE_SIMPLIFICADO_SP, todos_os_campos = TRUE)
  for (nome in names(cheia)) {
    expect_identical(nrow(vazia[[nome]]), 0L)
    expect_identical(names(vazia[[nome]]), names(cheia[[nome]]))
    expect_identical(vapply(vazia[[nome]], function(coluna) class(coluna)[1], character(1)),
                     vapply(cheia[[nome]], function(coluna) class(coluna)[1], character(1)))
  }
})
