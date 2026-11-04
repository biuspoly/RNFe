# Os valores esperados dos itens soltos são as respostas da calculadora oficial da Receita (piloto, versão 1.6.2, base
# V0066) para os mesmos itens, em 04/11/2026; os da nota de exemplo, a conta à mão.
NOTA_DE_EXEMPLO = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")

item_solto = function(cst, classificacao, ...) {
  data.frame(cst_ibs_cbs = cst, classificacao_ibs_cbs = classificacao, ...)
}

test_that("a base pelos componentes e o valor de cada parte, como na calculadora oficial", {
  itens = rbind(
    item_solto("000", "000001", valor_produto = 100, valor_frete = 10, valor_seguro = 2, valor_outros = 3,
               valor_desconto = 5, valor_icms = 18, valor_pis = 1.65, valor_cofins = 7.6),
    item_solto("000", "000001", valor_produto = 123.45, valor_frete = 0, valor_seguro = 0, valor_outros = 0,
               valor_desconto = 0, valor_icms = 0, valor_pis = 0, valor_cofins = 0),
    item_solto("000", "000001", valor_produto = 50.5, valor_frete = 0, valor_seguro = 0, valor_outros = 0,
               valor_desconto = 0, valor_icms = 0, valor_pis = 0, valor_cofins = 0)
  )
  calculado = ibs_cbs_calcular(itens, data = "2026-11-04")$itens
  expect_equal(calculado$base, c(82.75, 123.45, 50.5))
  expect_equal(calculado$valor_ibs_uf, c(0.08, 0.12, 0.05))
  expect_equal(calculado$valor_ibs_mun, c(0, 0, 0))
  expect_equal(calculado$valor_cbs, c(0.74, 1.11, 0.45))
  expect_equal(calculado$valor_ibs, c(0.08, 0.12, 0.05))
  expect_true(all(calculado$calculado))
})

test_that("o meio centavo vai para o par, como na calculadora oficial", {
  # Bases que dão meio centavo: 125,00 (0,125 e 1,125), 5,00 (0,005 e 0,045), 105,00 (0,105 e 0,945) e 55,00 (0,055 e
  # 0,495). A calculadora oficial deu 0,12/1,12, 0,00/0,04, 0,10/0,94 e 0,06/0,50.
  itens = item_solto("000", "000001", base = c(125, 5, 105, 55))
  calculado = ibs_cbs_calcular(itens, data = "2026-11-04")$itens
  expect_equal(calculado$valor_ibs_uf, c(0.12, 0, 0.1, 0.06))
  expect_equal(calculado$valor_cbs, c(1.12, 0.04, 0.94, 0.5))
  # A conta é exata também com a base grande e com o percentual do diferimento.
  expect_identical(valor_no_centavo_ao_par(c(123456789.25, -125), c(0.9, 0.1)), c(1111111.10, -0.12))
  expect_identical(valor_no_centavo_ao_par(100, 0.9, 50), 0.45)
  expect_identical(valor_no_centavo_ao_par(1, 0.9, 50), 0)
  expect_true(is.na(valor_no_centavo_ao_par(NA_real_, 0.9)))
})

test_that("cada componente da base s\u00f3 entra no ano e na natureza em que vale", {
  todos = item_solto("000", "000001", valor_produto = 1000, valor_frete = 50, valor_seguro = 10, valor_outros = 5,
                     valor_ii = 40, valor_is = 12, valor_desconto = 20, valor_pis = 16.5, valor_cofins = 76,
                     valor_icms = 180, valor_icms_uf_destino = 30, valor_fcp = 20, valor_fcp_uf_destino = 10,
                     valor_icms_monofasico = 7, valor_issqn = 3)
  # As bases que a calculadora oficial deu (base-calculo-unificada): em 2026 o IS e o ISSQN do bem ficam de fora; em
  # 2027 o PIS e a COFINS saem e o IS entra; no serviço, o II e o ICMS saem e o ISSQN entra; em 2033, só o desconto sai.
  expect_equal(ibs_cbs_calcular(todos, data = "2026-11-04")$itens$base, 745.5)
  expect_equal(ibs_cbs_calcular(todos, data = "2027-03-10", aliquotas = c(cbs = 8.7))$itens$base, 850)
  servico = todos
  servico$servico = TRUE
  expect_equal(ibs_cbs_calcular(servico, data = "2026-11-04")$itens$base, 949.5)
  expect_equal(ibs_cbs_calcular(todos, data = "2033-06-01", aliquotas = c(ibs_uf = 10, ibs_mun = 7, cbs = 8.7))$itens$base,
               1097)
  # Em 2025, a NT aceita as regras de 2026.
  expect_equal(ibs_cbs_calcular(todos, data = "2025-12-10")$itens$base, 745.5)
  # A base pronta vale no lugar dos componentes.
  pronta = item_solto("000", "000001", base = 77.77)
  calculado = ibs_cbs_calcular(pronta, data = "2026-11-04")$itens
  expect_equal(c(calculado$base, calculado$valor_ibs_uf, calculado$valor_cbs), c(77.77, 0.08, 0.7))
})

test_that("a redu\u00e7\u00e3o, o diferimento e a suspens\u00e3o com a tributa\u00e7\u00e3o regular", {
  itens = data.frame(cst_ibs_cbs = c("200", "510", "550", "410"),
                     classificacao_ibs_cbs = c("200047", "510001", "550001", "410001"),
                     valor_produto = 100, diferimento_ibs_uf = c(NA, 100, NA, NA), diferimento_ibs_mun = c(NA, 100, NA, NA),
                     diferimento_cbs = c(NA, 100, NA, NA), cst_regular = c(NA, NA, "000", NA),
                     classificacao_regular = c(NA, NA, "000001", NA))
  calculado = ibs_cbs_calcular(itens, data = "2026-11-04")$itens
  # Redução de 40%: alíquota efetiva 0,06 no IBS da UF e 0,54 na CBS.
  expect_equal(c(calculado$reducao_ibs_uf[1], calculado$aliquota_efetiva_ibs_uf[1], calculado$aliquota_efetiva_cbs[1]),
               c(40, 0.06, 0.54))
  expect_equal(c(calculado$valor_ibs_uf[1], calculado$valor_cbs[1]), c(0.06, 0.54))
  # Diferimento de 100%: tudo diferido, nada a pagar.
  expect_equal(c(calculado$valor_diferido_ibs_uf[2], calculado$valor_diferido_cbs[2]), c(0.1, 0.9))
  expect_equal(c(calculado$valor_ibs_uf[2], calculado$valor_cbs[2]), c(0, 0))
  # Suspensão: alíquotas zero e a tributação regular da 000001 ao lado.
  expect_equal(c(calculado$aliquota_ibs_uf[3], calculado$aliquota_cbs[3], calculado$valor_cbs[3]), c(0, 0, 0))
  expect_equal(c(calculado$aliquota_regular_ibs_uf[3], calculado$aliquota_regular_cbs[3]), c(0.1, 0.9))
  expect_equal(c(calculado$valor_regular_ibs_uf[3], calculado$valor_regular_ibs_mun[3], calculado$valor_regular_cbs[3]),
               c(0.1, 0, 0.9))
  # Imunidade: sem o grupo, nada a calcular, e conta como calculado.
  expect_false(calculado$tem_grupo_ibs_cbs[4])
  expect_true(is.na(calculado$valor_cbs[4]))
  expect_true(all(calculado$calculado))
})

test_that("2027 com a CBS que voc\u00ea informa, sem o PIS e a COFINS na base", {
  itens = rbind(item_solto("000", "000001", valor_produto = 100, valor_icms = 18, valor_pis = 0),
                item_solto("000", "000001", valor_produto = 100, valor_icms = 0, valor_pis = 1.65))
  calculado = ibs_cbs_calcular(itens, data = "2027-03-10", aliquotas = c(cbs = 8.7))$itens
  expect_equal(calculado$base, c(82, 100))
  expect_equal(calculado$aliquota_ibs_uf, c(0.05, 0.05))
  expect_equal(calculado$valor_ibs_uf, c(0.04, 0.05))
  expect_equal(calculado$valor_ibs_mun, c(0.04, 0.05))
  expect_equal(calculado$valor_cbs, c(7.13, 8.7))
  # Sem a CBS de referência publicada, ela fica vazia, com o motivo; o IBS sai.
  sem_cbs = ibs_cbs_calcular(itens, data = "2027-03-10")$itens
  expect_true(all(is.na(sem_cbs$valor_cbs)))
  expect_equal(sem_cbs$valor_ibs, c(0.08, 0.1))
  expect_false(any(sem_cbs$calculado))
  expect_match(sem_cbs$observacao[1], "Sem a al\u00edquota da CBS do ano")
})

test_that("o que fica sem calcular vem com o motivo", {
  itens = data.frame(cst_ibs_cbs = c("620", "830", "510", "550", "000", NA),
                     classificacao_ibs_cbs = c("620001", "830001", "510001", "550001", "200047", NA),
                     valor_produto = 100)
  calculado = ibs_cbs_calcular(itens, data = "2026-11-04")$itens
  expect_false(any(calculado$calculado))
  expect_match(calculado$observacao[1], "CST 620")
  expect_match(calculado$observacao[2], "CST 830")
  expect_match(calculado$observacao[3], "percentual do diferimento")
  expect_match(calculado$observacao[4], "tributa\u00e7\u00e3o regular")
  expect_match(calculado$observacao[5], "n\u00e3o \u00e9 do CST")
  expect_match(calculado$observacao[6], "Sem o CST")
  depois = ibs_cbs_calcular(itens[1, ], data = "2034-01-10", aliquotas = c(ibs_uf = 10, ibs_mun = 7, cbs = 8.7))$itens
  expect_match(depois$observacao, "2025 a 2033")
})

test_that("a nota inteira: a data dela, os totais e a compra governamental", {
  calculada = ibs_cbs_calcular(NOTA_DE_EXEMPLO)
  itens = calculada$itens
  # Item 1: 50,00 menos o ICMS (6,00), o PIS (0,83) e a COFINS (3,80); o IPI não entra. Item 2: ICMS-ST retido, sem PIS.
  expect_equal(itens$base, c(39.37, 60))
  expect_equal(itens$valor_ibs_uf, c(0.04, 0.06))
  expect_equal(itens$valor_cbs, c(0.35, 0.54))
  expect_identical(itens$data_calculo, as.Date(c("2026-10-15", "2026-10-15")))
  expect_identical(calculada$notas$chave, "35261011222333000181550010000010011123456785")
  expect_equal(c(calculada$notas$base, calculada$notas$valor_ibs, calculada$notas$valor_cbs), c(99.37, 0.1, 0.89))
  expect_identical(calculada$arquivos$problema, NA_character_)
  # Pelos itens do nfe_ler(), a mesma conta.
  lidos = nfe_ler(NOTA_DE_EXEMPLO)$itens
  expect_equal(ibs_cbs_calcular(lidos, data = "2026-10-15")$itens$base, c(39.37, 60))
  # Com a compra governamental na nota, fica sem calcular.
  texto = paste(readLines(NOTA_DE_EXEMPLO, encoding = "UTF-8"), collapse = "\n")
  texto = sub("<indFinal>0</indFinal>", paste0("<gCompraGov><tpEnteGov>1</tpEnteGov><pRedutor>0.0000</pRedutor>",
                                               "<tpOperGov>1</tpOperGov></gCompraGov><indFinal>0</indFinal>"), texto, fixed = TRUE)
  expect_match(ibs_cbs_calcular(texto)$itens$observacao[1], "Compra governamental")
})

test_that("os argumentos errados s\u00e3o recusados", {
  item = item_solto("000", "000001", valor_produto = 100)
  expect_error(ibs_cbs_calcular(item, data = "ontem"), "data")
  expect_error(ibs_cbs_calcular(item, data = "2026-11-04", aliquotas = c(icms = 18)), "ibs_uf, ibs_mun e cbs")
  expect_error(ibs_cbs_calcular(data.frame(cst_ibs_cbs = "000", classificacao_ibs_cbs = "000001"), data = "2026-11-04"),
               "base pronta")
  expect_error(ibs_cbs_calcular(data.frame(valor_produto = 1), data = "2026-11-04"), "cst_ibs_cbs")
  vazio = ibs_cbs_calcular(item[0, ], data = "2026-11-04")
  expect_identical(nrow(vazio$itens), 0L)
  expect_identical(nrow(vazio$notas), 0L)
})
