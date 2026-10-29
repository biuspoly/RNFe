# Os valores esperados são os escritos à mão nas notas de inst/exemplos (validadas contra o schema
# oficial com ferramentas/validar_notas_de_teste.R).
NOTA_SP = system.file("exemplos", "nfe_proc_sp.xml", package = "RNfe")
NOTA_CE = system.file("exemplos", "nfe_ce_simples_cpf.xml", package = "RNfe")
CHAVE_SP = "35261011222333000181550010000010011123456785"
CHAVE_CE = "23261012ABC34501DE35550020000000421876543213"

test_that("a nota com protocolo: cabe\u00e7alho, totais e autoriza\u00e7\u00e3o", {
  nota = nfe_ler(NOTA_SP)$notas
  expect_identical(nota$chave, CHAVE_SP)
  expect_true(chave_valida(nota$chave))
  expect_identical(nota$versao, "4.00")
  expect_identical(nota$modelo, "55")
  expect_identical(nota$serie, 1L)
  expect_identical(nota$numero, 1001L)
  expect_identical(nota$data_emissao, as.Date("2026-10-15"))
  expect_equal(as.numeric(nota$emissao), as.numeric(as.POSIXct("2026-10-15 13:30:00", tz = "UTC")))
  expect_identical(attr(nota$emissao, "tzone"), "America/Sao_Paulo")
  expect_identical(nota$tipo_operacao, 1L)
  expect_identical(nota$destino_operacao, 2L)
  expect_identical(nota$emitente_documento, "11222333000181")
  expect_identical(nota$emitente_nome, "EMPRESA DE TESTE LTDA")
  expect_identical(nota$emitente_municipio, "S\u00c3O PAULO")
  expect_identical(nota$emitente_uf, "SP")
  expect_identical(nota$emitente_regime, 3L)
  expect_identical(nota$destinatario_documento, "11444777000161")
  expect_identical(nota$destinatario_uf, "RJ")
  expect_true(is.na(nota$avulsa_cnpj))
  expect_equal(nota$valor_produtos, 110)
  expect_equal(nota$valor_icms, 6)
  expect_equal(nota$valor_ipi, 5)
  expect_equal(nota$valor_pis, 0.83)
  expect_equal(nota$valor_cofins, 3.8)
  expect_equal(nota$valor_nota, 115)
  expect_equal(nota$base_ibs_cbs, 110)
  expect_equal(nota$valor_ibs, 0.11)
  expect_equal(nota$valor_cbs, 0.99)
  expect_equal(nota$valor_nota_com_ibs_cbs_is, 116.1)
  expect_identical(nota$modalidade_frete, 0L)
  expect_identical(nota$transportadora_documento, "12ABC34501DE35")
  expect_equal(nota$fatura_valor_liquido, 115)
  expect_identical(nota$informacoes_complementares, "NOTA DE TESTE DO PACOTE RNFE - SEM VALOR FISCAL")
  expect_identical(nota$protocolo, "135260000012345")
  expect_identical(nota$situacao, 100L)
  expect_equal(as.numeric(nota$autorizacao), as.numeric(as.POSIXct("2026-10-15 13:31:02", tz = "UTC")))
  expect_identical(nota$arquivo, NOTA_SP)
})

test_that("os itens, com os impostos em colunas", {
  itens = nfe_ler(NOTA_SP)$itens
  expect_identical(itens$item, 1:2)
  expect_identical(itens$chave, rep(CHAVE_SP, 2))
  expect_identical(itens$descricao[1], "\u00c1GUA MINERAL DE TESTE 500 ML")
  expect_identical(itens$ncm, c("22011000", "22021000"))
  expect_identical(itens$cfop, c("6102", "6404"))
  expect_equal(itens$quantidade, c(10, 24))
  expect_equal(itens$valor_unitario, c(5, 2.5))
  expect_equal(itens$valor_produto, c(50, 60))
  expect_identical(itens$pedido, c("PEDIDO-77", NA))
  expect_identical(itens$informacoes_adicionais, c("LOTE 123", NA))
  expect_equal(itens$valor_tributos_aproximado, c(15.68, NA))
  expect_identical(itens$origem, c("0", "0"))
  expect_identical(itens$cst_icms, c("00", "60"))
  expect_identical(itens$csosn, c(NA_character_, NA_character_))
  expect_equal(itens$base_icms, c(50, NA))
  expect_equal(itens$aliquota_icms, c(12, NA))
  expect_equal(itens$valor_icms, c(6, NA))
  expect_equal(itens$base_icms_st_retido, c(NA, 60))
  expect_equal(itens$valor_icms_st_retido, c(NA, 10.8))
  expect_identical(itens$cst_ipi, c("50", NA))
  expect_equal(itens$valor_ipi, c(5, NA))
  expect_identical(itens$cst_pis, c("01", "04"))
  expect_equal(itens$valor_pis, c(0.83, NA))
  expect_identical(itens$cst_cofins, c("01", "04"))
  expect_equal(itens$valor_cofins, c(3.8, NA))
  expect_identical(itens$cst_ibs_cbs, c("000", "000"))
  expect_identical(itens$classificacao_ibs_cbs, c("000001", "000001"))
  expect_equal(itens$base_ibs_cbs, c(50, 60))
  expect_equal(itens$aliquota_ibs_uf, c(0.1, 0.1))
  expect_equal(itens$aliquota_ibs_municipio, c(0, 0))
  expect_equal(itens$valor_ibs, c(0.05, 0.06))
  expect_equal(itens$aliquota_cbs, c(0.9, 0.9))
  expect_equal(itens$valor_cbs, c(0.45, 0.54))
})

test_that("ao lado de cada c\u00f3digo do item, o nome dele na data da nota", {
  itens = nfe_ler(c(NOTA_SP, NOTA_CE))$itens
  expect_identical(match("cfop_titulo", names(itens)), match("cfop", names(itens)) + 1L)
  expect_identical(itens$cfop_titulo[2], "Venda de mercadoria sujeita ao regime de substitui\u00e7\u00e3o tribut\u00e1ria, cujo imposto j\u00e1 tenha sido retido anteriormente.")
  expect_match(itens$cfop_titulo[3], "^Venda de mercadoria adquirida ou recebida de terceiros")
  expect_identical(itens$origem_descricao[1], "Nacional, exceto as indicadas nos c\u00f3digos 3 a 5")
  expect_identical(itens$cst_icms_descricao, c("Tributada integralmente", "ICMS cobrado anteriormente por substitui\u00e7\u00e3o tribut\u00e1ria", NA))
  expect_identical(itens$csosn_descricao, c(NA, NA, "Tributada pelo Simples Nacional sem permiss\u00e3o de cr\u00e9dito"))
  expect_identical(itens$cst_ipi_descricao, c("Sa\u00edda tributada", NA, NA))
  expect_identical(itens$cst_pis_descricao, c("Opera\u00e7\u00e3o Tribut\u00e1vel com Al\u00edquota B\u00e1sica", "Opera\u00e7\u00e3o Tribut\u00e1vel Monof\u00e1sica - Revenda a Al\u00edquota Zero", "Outras Opera\u00e7\u00f5es"))
  expect_identical(itens$cst_cofins_descricao, itens$cst_pis_descricao)
  expect_match(itens$ncm_descricao[1], "- \u00c1guas minerais e \u00e1guas gaseificadas$")
  expect_match(itens$ncm_descricao[2], "^\u00c1guas, incluindo as \u00e1guas minerais e as \u00e1guas gaseificadas, adicionadas de a\u00e7\u00facar")
  expect_identical(itens$cst_ibs_cbs_descricao, c("Tributa\u00e7\u00e3o integral", "Tributa\u00e7\u00e3o integral", NA))
  expect_identical(itens$classificacao_ibs_cbs_nome[1], "Situa\u00e7\u00f5es tributadas integralmente pelo IBS e CBS.")
  expect_true(is.na(itens$classificacao_ibs_cbs_nome[3]))
})

test_that("os itens somam os totais da nota", {
  lida = nfe_ler(NOTA_SP)
  expect_equal(sum(lida$itens$valor_produto), lida$notas$valor_produtos)
  expect_equal(sum(lida$itens$valor_icms, na.rm = TRUE), lida$notas$valor_icms)
  expect_equal(sum(lida$itens$valor_ibs), lida$notas$valor_ibs)
  expect_equal(sum(lida$itens$valor_cbs), lida$notas$valor_cbs)
  expect_equal(sum(lida$parcelas$valor), lida$notas$fatura_valor_liquido)
})

test_that("a tabela de impostos tem todos os campos de imposto de cada item", {
  impostos = nfe_ler(NOTA_SP)$impostos
  # Item 1: vTotTrib, ICMS00 (6), IPI (cEnq + 4), PISAliq (4), COFINSAliq (4), IBSCBS (10) = 30.
  # Item 2: ICMS60 (5), PISNT (1), COFINSNT (1), IBSCBS (10) = 17.
  expect_identical(nrow(impostos), 47L)
  expect_identical(as.vector(table(impostos$item)), c(30L, 17L))
  icms = impostos[impostos$item == 1 & impostos$tributo == "ICMS", ]
  expect_identical(icms$grupo, rep("ICMS00", 6))
  expect_identical(icms$campo, c("orig", "CST", "modBC", "vBC", "pICMS", "vICMS"))
  expect_identical(icms$valor, c("0", "00", "3", "50.00", "12.00", "6.00"))
  cbs = impostos[impostos$item == 2 & impostos$grupo == "gCBS", ]
  expect_identical(cbs$campo, c("pCBS", "vCBS"))
  expect_identical(cbs$valor, c("0.90", "0.54"))
  expect_identical(impostos$grupo[impostos$campo == "cEnq"], "IPI")
  expect_identical(impostos$tributo[impostos$campo == "vTotTrib"], "vTotTrib")
})

test_that("parcelas e pagamentos", {
  lida = nfe_ler(NOTA_SP)
  expect_identical(lida$parcelas$numero, c("001", "002"))
  expect_identical(lida$parcelas$vencimento, as.Date(c("2026-11-14", "2026-12-14")))
  expect_equal(lida$parcelas$valor, c(57.5, 57.5))
  expect_identical(lida$pagamentos$forma, "15")
  expect_identical(lida$pagamentos$indicador, 1L)
  expect_equal(lida$pagamentos$valor, 115)
})

test_that("nota sem protocolo, emitente com CNPJ alfanum\u00e9rico e destinat\u00e1rio com CPF", {
  lida = nfe_ler(NOTA_CE)
  nota = lida$notas
  expect_identical(nota$chave, CHAVE_CE)
  expect_true(chave_valida(nota$chave))
  expect_identical(nota$emitente_documento, "12ABC34501DE35")
  expect_identical(nota$emitente_regime, 1L)
  expect_identical(nota$destinatario_documento, "12345678909")
  expect_true(is.na(nota$protocolo))
  expect_true(is.na(nota$situacao))
  expect_true(is.na(nota$autorizacao))
  expect_true(is.na(nota$base_ibs_cbs))
  expect_equal(nota$valor_desconto, 2.5)
  expect_equal(nota$valor_nota, 35)
  expect_identical(lida$itens$csosn, "102")
  expect_true(is.na(lida$itens$cst_icms))
  expect_true(is.na(lida$itens$cst_ibs_cbs))
  expect_identical(lida$itens$cst_pis, "99")
  expect_equal(lida$itens$valor_desconto, 2.5)
  expect_identical(nrow(lida$parcelas), 0L)
  expect_identical(lida$pagamentos$forma, "17")
})

test_that("v\u00e1rios arquivos de uma vez, e o texto do XML no lugar do arquivo", {
  lida = nfe_ler(c(NOTA_SP, NOTA_CE))
  expect_identical(lida$notas$chave, c(CHAVE_SP, CHAVE_CE))
  expect_identical(nrow(lida$itens), 3L)
  expect_identical(lida$arquivos$notas, c(1L, 1L))
  expect_identical(lida$arquivos$problema, c(NA_character_, NA_character_))

  texto = paste(readLines(NOTA_SP, encoding = "UTF-8"), collapse = "\n")
  pelo_texto = nfe_ler(texto)
  expect_identical(pelo_texto$arquivos$arquivo, "(texto 1)")
  pelo_arquivo = nfe_ler(NOTA_SP)
  pelo_texto$notas$arquivo = NOTA_SP
  expect_identical(pelo_texto$notas, pelo_arquivo$notas)
  expect_identical(pelo_texto$itens, pelo_arquivo$itens)
})

test_that("arquivo que n\u00e3o d\u00e1 para ler n\u00e3o atrapalha os outros", {
  resumo = '<resNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.01"><chNFe>1</chNFe></resNFe>'
  lida = nfe_ler(c("nao_existe.xml", NOTA_SP, "<NFe><infNFe>", "<cteProc/>", resumo, NA))
  expect_identical(lida$notas$chave, CHAVE_SP)
  expect_identical(lida$arquivos$notas, c(0L, 1L, 0L, 0L, 0L, 0L))
  problemas = lida$arquivos$problema
  expect_identical(problemas[1], "arquivo n\u00e3o encontrado")
  expect_true(is.na(problemas[2]))
  expect_match(problemas[3], "^n\u00e3o \u00e9 um XML v\u00e1lido")
  expect_identical(problemas[4], "n\u00e3o \u00e9 uma NF-e (o XML come\u00e7a por <cteProc>)")
  expect_identical(problemas[5], "\u00e9 o resumo da NF-e (resNFe), sem os itens")
  expect_identical(problemas[6], "vazio")
})

test_that("sem arquivo nenhum, as tabelas v\u00eam vazias com as colunas certas", {
  vazia = nfe_ler(character())
  cheia = nfe_ler(NOTA_SP)
  for (nome in names(cheia)) {
    expect_identical(nrow(vazia[[nome]]), 0L)
    expect_identical(names(vazia[[nome]]), names(cheia[[nome]]))
    expect_identical(vapply(vazia[[nome]], function(coluna) class(coluna)[1], character(1)),
                     vapply(cheia[[nome]], function(coluna) class(coluna)[1], character(1)))
  }
})
