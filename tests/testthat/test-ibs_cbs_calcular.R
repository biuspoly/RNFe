# Os valores esperados dos itens soltos são as respostas da calculadora oficial da Receita (piloto, versão 1.6.2, base
# V0066) para os mesmos itens, em 04/11/2026; os da nota de exemplo, a conta à mão.
NOTA_DE_EXEMPLO = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")

item_solto = function(cst, classificacao, ...) {
  data.frame(cst_ibs_cbs = cst, classificacao_ibs_cbs = classificacao, ...)
}

texto_da_nota_de_exemplo = function() {
  paste(readLines(NOTA_DE_EXEMPLO, encoding = "UTF-8"), collapse = "\n")
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
  expect_equal(calculado$valor_ibs_municipio, c(0, 0, 0))
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

test_that("cada componente da base s\u00f3 entra no ano, na natureza e no modelo em que vale", {
  todos = item_solto("000", "000001", valor_produto = 1000, valor_frete = 50, valor_seguro = 10, valor_outros = 5,
                     valor_ii = 40, valor_is = 12, valor_desconto = 20, valor_pis = 16.5, valor_cofins = 76,
                     valor_icms = 180, valor_icms_uf_destino = 30, valor_fcp = 20, valor_fcp_uf_destino = 10,
                     valor_icms_monofasico = 7, valor_issqn = 3, servico = FALSE)
  # As bases que a calculadora oficial deu (base-calculo-unificada): em 2026 o IS e o ISSQN do bem ficam de fora; em
  # 2027 o PIS e a COFINS saem e o IS entra; no serviço, o II e o ICMS saem e o ISSQN entra; em 2033, só o desconto sai.
  expect_equal(ibs_cbs_calcular(todos, data = "2026-11-04")$itens$base, 745.5)
  expect_equal(ibs_cbs_calcular(todos, data = "2027-03-10", aliquotas = c(cbs = 8.7))$itens$base, 850)
  servico = todos
  servico$servico = TRUE
  expect_equal(ibs_cbs_calcular(servico, data = "2026-11-04")$itens$base, 949.5)
  ate_2033 = c(ibs_uf = 10, ibs_municipio = 7, cbs = 8.7)
  expect_equal(ibs_cbs_calcular(todos, data = "2033-06-01", aliquotas = ate_2033)$itens$base, 1097)
  # Em 2025, a NT aceita as regras de 2026.
  expect_equal(ibs_cbs_calcular(todos, data = "2025-12-10")$itens$base, 745.5)
  # Na NFC-e, o II, o ICMS da UF de destino e o FCP dele não entram (a calculadora oficial só os aceita na NF-e).
  nfce = todos
  nfce$valor_icms_uf_destino = 100
  expect_equal(ibs_cbs_calcular(nfce, data = "2026-11-04")$itens$base, 675.5)
  nfce$modelo = "65"
  expect_equal(ibs_cbs_calcular(nfce, data = "2026-11-04")$itens$base, 745.5)
  # Sem a coluna servico, o item com ISSQN acima de zero é serviço; com zero (uma planilha com a coluna toda zerada,
  # por exemplo), é bem.
  sem_a_coluna = todos[, setdiff(names(todos), "servico")]
  expect_true(ibs_cbs_calcular(sem_a_coluna, data = "2026-11-04")$itens$servico)
  sem_a_coluna$valor_issqn = 0
  expect_false(ibs_cbs_calcular(sem_a_coluna, data = "2026-11-04")$itens$servico)
  expect_equal(ibs_cbs_calcular(sem_a_coluna, data = "2026-11-04")$itens$base, 745.5)
  # A base pronta vale no lugar dos componentes.
  pronta = item_solto("000", "000001", base = 77.77)
  calculado = ibs_cbs_calcular(pronta, data = "2026-11-04")$itens
  expect_equal(c(calculado$base, calculado$valor_ibs_uf, calculado$valor_cbs), c(77.77, 0.08, 0.7))
})

test_that("a redu\u00e7\u00e3o, o diferimento e a suspens\u00e3o com a tributa\u00e7\u00e3o regular", {
  itens = data.frame(cst_ibs_cbs = c("200", "510", "550", "410"),
                     classificacao_ibs_cbs = c("200047", "510001", "550001", "410001"),
                     valor_produto = 100, diferimento_ibs_uf = c(NA, 100, NA, NA),
                     diferimento_ibs_municipio = c(NA, 100, NA, NA), diferimento_cbs = c(NA, 100, NA, NA),
                     cst_regular = c(NA, NA, "000", NA), classificacao_regular = c(NA, NA, "000001", NA))
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
  expect_equal(c(calculado$valor_regular_ibs_uf[3], calculado$valor_regular_ibs_municipio[3],
                 calculado$valor_regular_cbs[3]), c(0.1, 0, 0.9))
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
  expect_equal(calculado$valor_ibs_municipio, c(0.04, 0.05))
  expect_equal(calculado$valor_cbs, c(7.13, 8.7))
  # Sem a CBS de referência publicada, ela fica vazia, com o motivo; o IBS sai.
  sem_cbs = ibs_cbs_calcular(itens, data = "2027-03-10")$itens
  expect_true(all(is.na(sem_cbs$valor_cbs)))
  expect_equal(sem_cbs$valor_ibs, c(0.08, 0.1))
  expect_false(any(sem_cbs$calculado))
  expect_match(sem_cbs$observacao[1], "Sem a al\u00edquota da CBS do ano")
  # De 2029 em diante a tabela não tem o IBS: também fica vazio, com o motivo.
  em_2030 = ibs_cbs_calcular(itens, data = "2030-06-15", aliquotas = c(cbs = 8.7))$itens
  expect_true(all(is.na(em_2030$valor_ibs_uf)))
  expect_match(em_2030$observacao[1], "Sem a al\u00edquota do IBS da UF do ano")
})

test_that("o que fica sem calcular vem com o motivo", {
  itens = data.frame(cst_ibs_cbs = c("620", "830", "510", "550", "000", NA, "000", "000"),
                     classificacao_ibs_cbs = c("620001", "830001", "510001", "550001", "200047", NA, "000001", "000001"),
                     valor_produto = c(100, 100, 100, 100, 100, 100, 100, NA), valor_desconto = c(0, 0, 0, 0, 0, 0, 150, 0))
  calculado = ibs_cbs_calcular(itens, data = "2026-11-04")$itens
  expect_false(any(calculado$calculado))
  expect_match(calculado$observacao[1], "CST 620")
  expect_match(calculado$observacao[2], "CST 830")
  expect_match(calculado$observacao[3], "percentual do diferimento")
  expect_match(calculado$observacao[4], "tributa\u00e7\u00e3o regular")
  expect_match(calculado$observacao[5], "n\u00e3o \u00e9 do CST")
  expect_match(calculado$observacao[6], "Sem o CST")
  expect_match(calculado$observacao[7], "base ficou negativa")
  expect_match(calculado$observacao[8], "Sem a base nem o valor do produto")
  depois = ibs_cbs_calcular(itens[1, ], data = "2034-01-10", aliquotas = c(ibs_uf = 10, ibs_municipio = 7, cbs = 8.7))$itens
  expect_match(depois$observacao, "2025 a 2033")
  sem_data = ibs_cbs_calcular(item_solto("000", "000001", valor_produto = 100))$itens
  expect_match(sem_data$observacao, "Sem a data do c\u00e1lculo")
  # A nota que não é normal depende da operação original.
  devolucao = item_solto("000", "000001", valor_produto = 100, finalidade = "4")
  expect_match(ibs_cbs_calcular(devolucao, data = "2026-11-04")$itens$observacao, "finNFe 4")
})

test_that("o cr\u00e9dito presumido e a devolu\u00e7\u00e3o de tributos ficam sem calcular", {
  texto = texto_da_nota_de_exemplo()
  credito = paste0("<gCredPresOper><vBCCredPres>50.00</vBCCredPres><cCredPres>04</cCredPres><gIBSCredPres>",
                   "<pCredPres>1.0000</pCredPres><vCredPres>0.50</vCredPres></gIBSCredPres></gCredPresOper>")
  com_credito = sub("</gIBSCBS>", paste0("</gIBSCBS>", credito), texto, fixed = TRUE)
  expect_match(ibs_cbs_calcular(com_credito)$itens$observacao[1], "Cr\u00e9dito presumido")
  com_devolucao = sub("<vCBS>0.45</vCBS>", "<gDevTrib><vDevTrib>0.10</vDevTrib></gDevTrib><vCBS>0.35</vCBS>", texto,
                      fixed = TRUE)
  calculado = ibs_cbs_calcular(com_devolucao)$itens
  expect_match(calculado$observacao[1], "Devolu\u00e7\u00e3o de tributos")
  expect_identical(calculado$calculado, c(FALSE, TRUE))
  # Com o valor devolvido zero, a conta é a mesma (o vDevTrib só é subtraído): calcula.
  com_zero = sub("<vCBS>0.45</vCBS>", "<gDevTrib><vDevTrib>0.00</vDevTrib></gDevTrib><vCBS>0.45</vCBS>", texto,
                 fixed = TRUE)
  expect_identical(ibs_cbs_calcular(com_zero)$itens$calculado, c(TRUE, TRUE))
})

test_that("a nota inteira: a data dela, os totais, a compra governamental e a finalidade", {
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
  # A mesma nota em dois arquivos conta uma vez.
  duas_vezes = ibs_cbs_calcular(c(NOTA_DE_EXEMPLO, NOTA_DE_EXEMPLO))
  expect_identical(nrow(duas_vezes$itens), 2L)
  expect_equal(duas_vezes$notas$base, 99.37)
  # Com a compra governamental na nota, fica sem calcular; a imunidade, que não tem o grupo, não.
  texto = texto_da_nota_de_exemplo()
  texto = sub("</ide>", paste0("<gCompraGov><tpEnteGov>1</tpEnteGov><pRedutor>0.0000</pRedutor>",
                               "<tpOperGov>1</tpOperGov></gCompraGov></ide>"), texto, fixed = TRUE)
  expect_match(ibs_cbs_calcular(texto)$itens$observacao[1], "Compra governamental")
  # A devolução fica sem calcular.
  devolucao = sub("<finNFe>1</finNFe>", "<finNFe>4</finNFe>", texto_da_nota_de_exemplo(), fixed = TRUE)
  expect_match(ibs_cbs_calcular(devolucao)$itens$observacao[1], "finNFe 4")
})

test_that("pelo resultado do nfe_ler(): a mesma conta, com o que vem da nota", {
  lida = nfe_ler(NOTA_DE_EXEMPLO)
  pela_lista = ibs_cbs_calcular(lida)$itens
  expect_equal(pela_lista$base, c(39.37, 60))
  expect_identical(pela_lista$data_calculo, as.Date(c("2026-10-15", "2026-10-15")))
  # Só os itens não servem: a função pede a lista.
  expect_error(ibs_cbs_calcular(lida$itens), "resultado inteiro do nfe_ler")
  # O serviço, a compra governamental e a devolução chegam pela lista.
  texto = sub("<finNFe>1</finNFe>", "<finNFe>4</finNFe>", texto_da_nota_de_exemplo(), fixed = TRUE)
  expect_match(ibs_cbs_calcular(nfe_ler(texto))$itens$observacao[1], "finNFe 4")
  com_compra = sub("</ide>", paste0("<gCompraGov><tpEnteGov>1</tpEnteGov><pRedutor>10.0000</pRedutor>",
                                    "<tpOperGov>1</tpOperGov></gCompraGov></ide>"), texto_da_nota_de_exemplo(), fixed = TRUE)
  expect_match(ibs_cbs_calcular(nfe_ler(com_compra))$itens$observacao[1], "Compra governamental")
  com_diferimento = sub("<CST>000</CST>", "<CST>510</CST>", texto_da_nota_de_exemplo(), fixed = TRUE)
  com_diferimento = sub("<cClassTrib>000001</cClassTrib>", "<cClassTrib>510001</cClassTrib>", com_diferimento, fixed = TRUE)
  com_diferimento = sub("<pIBSUF>0.10</pIBSUF>", "<pIBSUF>0.10</pIBSUF><gDif><pDif>100.0000</pDif><vDif>0.05</vDif></gDif>",
                        com_diferimento, fixed = TRUE)
  diferido = ibs_cbs_calcular(nfe_ler(com_diferimento))$itens
  expect_equal(diferido$diferimento_ibs_uf[1], 100)
})

test_that("os argumentos e as colunas erradas s\u00e3o recusados", {
  item = item_solto("000", "000001", valor_produto = 100)
  expect_error(ibs_cbs_calcular(item, data = "ontem"), "data")
  expect_error(ibs_cbs_calcular(item, data = "10/03/2027"), "AAAA-MM-DD")
  expect_error(ibs_cbs_calcular(item, data = 2027), "AAAA-MM-DD")
  expect_error(ibs_cbs_calcular(item, data = "2026-11-04", aliquotas = c(icms = 18)), "ibs_uf, ibs_municipio e cbs")
  expect_error(ibs_cbs_calcular(item, data = "2026-11-04", aliquotas = c(cbs = Inf)), "ibs_uf, ibs_municipio e cbs")
  expect_error(ibs_cbs_calcular(data.frame(cst_ibs_cbs = "000", classificacao_ibs_cbs = "000001"), data = "2026-11-04"),
               "base pronta")
  expect_error(ibs_cbs_calcular(data.frame(valor_produto = 1), data = "2026-11-04"), "cst_ibs_cbs")
  expect_error(ibs_cbs_calcular(item_solto("000", "000001", valor_produto = factor(c("100.00", "250.00"))),
                                data = "2026-11-04"), "valor_produto")
  expect_error(ibs_cbs_calcular(item_solto("000", "000001", valor_produto = "100,50"), data = "2026-11-04"),
               "separador decimal")
  expect_equal(ibs_cbs_calcular(item_solto("000", "000001", valor_produto = "100.50"), data = "2026-11-04")$itens$base,
               100.5)
  # A data e hora vale no horário de Brasília: 31/12/2026 às 22h ainda é 2026.
  na_virada = as.POSIXct("2026-12-31 22:00", tz = "America/Sao_Paulo")
  expect_identical(ibs_cbs_calcular(item, data = na_virada)$itens$data_calculo, as.Date("2026-12-31"))
  vazio = ibs_cbs_calcular(item[0, ], data = "2026-11-04")
  expect_identical(nrow(vazio$itens), 0L)
  expect_identical(nrow(vazio$notas), 0L)
})
