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

test_that("a al\u00edquota uniforme: a nacional (011) \u00e9 a do ano; a setorial (010), a do ano at\u00e9 2026, depois a informada", {
  itens = data.frame(cst_ibs_cbs = c("010", "011", "000"), classificacao_ibs_cbs = c("010002", "011002", "000001"),
                     base = 1000)
  em_2026 = ibs_cbs_calcular(itens, data = "2026-11-04")$itens
  expect_true(all(em_2026$calculado))
  expect_equal(em_2026$aliquota_cbs, c(0.9, 0.9, 0.9))
  # O 011 leva a redução da classificação (60% nos planos de saúde).
  expect_equal(em_2026$reducao_cbs, c(NA, 60, NA))
  expect_equal(em_2026$aliquota_efetiva_cbs[2], 0.36)
  expect_equal(em_2026$valor_cbs, c(9, 3.6, 9))
  expect_equal(em_2026$valor_ibs_uf, c(1, 0.4, 1))
  # De 2027 em diante a setorial é a da lei do regime: sem a que você informa, fica sem calcular. A nacional (a de
  # referência) segue a tabela, como o 000: o IBS sai e a CBS, ainda sem publicar, fica vazia.
  em_2027 = ibs_cbs_calcular(itens, data = "2027-03-10")$itens
  expect_identical(em_2027$calculado, c(FALSE, FALSE, FALSE))
  expect_match(em_2027$observacao[1], "regime espec\u00edfico")
  expect_equal(em_2027$aliquota_ibs_uf, c(NA, 0.05, 0.05))
  expect_equal(em_2027$valor_ibs_uf, c(NA, 0.2, 0.5))
  expect_match(em_2027$observacao[2:3], "Sem a al\u00edquota da CBS do ano")
  expect_no_match(em_2027$observacao[2:3], "regime espec\u00edfico")
  # Com as alíquotas informadas, calcula, como a calculadora oficial.
  informadas = ibs_cbs_calcular(itens[1:2, ], data = "2027-03-10",
                                aliquotas = c(ibs_uf = 0, ibs_municipio = 0, cbs = 10.85))$itens
  expect_true(all(informadas$calculado))
  expect_equal(informadas$valor_cbs, c(108.5, 43.4))
})

# Troca, na memória da sessão, a tabela das classificações que o cálculo lê.
usar_estas_classificacoes = function(classificacoes) {
  tabelas_ja_lidas[["classificacao_ibs_cbs"]] = classificacoes
}

test_that("a redu\u00e7\u00e3o da base (CST 222): a metade do valor cobrado, com o meio centavo para o par", {
  itens = item_solto("222", "222001", valor_produto = c(200, 200.01, 200.03))
  calculado = ibs_cbs_calcular(itens, data = "2026-11-04")$itens
  expect_equal(calculado$base, c(100, 100, 100.02))
  expect_equal(calculado$valor_cbs, c(0.9, 0.9, 0.9))
  expect_equal(calculado$valor_ibs_uf, c(0.1, 0.1, 0.1))
  expect_true(all(calculado$calculado))
  # O valor sai da base que vai no XML (9,44 vezes 0,9%), como a NT confere; a calculadora multiplica a metade com 8
  # casas (9,445) e daria 0,09.
  centavo_impar = ibs_cbs_calcular(item_solto("222", "222001", valor_produto = 18.89), data = "2026-11-04")$itens
  expect_equal(c(centavo_impar$base, centavo_impar$valor_cbs), c(9.44, 0.08))
  # A base pronta já é a reduzida.
  pronta = ibs_cbs_calcular(item_solto("222", "222001", base = 100), data = "2026-11-04")$itens
  expect_equal(pronta$base, 100)
  # A classificação nova do CST 222, sem a parte da base no RNFe, fica sem calcular, a não ser com a base pronta.
  classificacoes = tabela_fiscal("classificacao_ibs_cbs")
  nova = classificacoes[classificacoes$codigo == "222001", ]
  nova$codigo = "222999"
  usar_estas_classificacoes(rbind(classificacoes, nova))
  sem_a_parte = tryCatch(ibs_cbs_calcular(item_solto("222", "222999", valor_produto = 200), data = "2026-11-04")$itens,
                         finally = usar_estas_classificacoes(classificacoes))
  expect_false(sem_a_parte$calculado)
  expect_match(sem_a_parte$observacao, "redu\u00e7\u00e3o da base desta classifica\u00e7\u00e3o")
  usar_estas_classificacoes(rbind(classificacoes, nova))
  com_a_base = tryCatch(ibs_cbs_calcular(item_solto("222", "222999", base = 80), data = "2026-11-04")$itens,
                        finally = usar_estas_classificacoes(classificacoes))
  expect_true(com_a_base$calculado)
  expect_equal(com_a_base$valor_cbs, 0.72)
})

# Os campos que a régua da calculadora oficial compara.
campos_da_regua = function() {
  campos = c("base", "valor_ibs")
  for (comeco in c("aliquota_", "reducao_", "aliquota_efetiva_", "diferimento_", "valor_diferido_", "valor_",
                   "aliquota_regular_", "valor_regular_")) {
    campos = c(campos, paste0(comeco, PARTES_DO_CALCULO))
  }
  campos
}

test_that("o teste de 262 itens da calculadora oficial: tudo igual, menos as duas escolhas da NT", {
  regua = utils::read.csv(test_path("calculadora_oficial", "teste_varios_itens.csv"), encoding = "UTF-8",
                          colClasses = c(cst_ibs_cbs = "character", classificacao_ibs_cbs = "character",
                                         cst_regular = "character", classificacao_regular = "character"))
  expect_identical(nrow(regua), 262L)
  # A calculadora recebe as alíquotas nominais por item; o RNFe, por chamada: um cálculo para cada grupo.
  grupos = paste(regua$aliquota_nominal_ibs_uf, regua$aliquota_nominal_ibs_municipio, regua$aliquota_nominal_cbs)
  calculados = list()
  for (grupo in unique(grupos)) {
    do_grupo = regua[grupos == grupo, ]
    aliquotas = c(ibs_uf = do_grupo$aliquota_nominal_ibs_uf[1], ibs_municipio = do_grupo$aliquota_nominal_ibs_municipio[1],
                  cbs = do_grupo$aliquota_nominal_cbs[1])
    aliquotas = aliquotas[!is.na(aliquotas)]
    if (length(aliquotas) == 0) {
      aliquotas = NULL
    }
    entrada = data.frame(item = do_grupo$item, cst_ibs_cbs = do_grupo$cst_ibs_cbs,
                         classificacao_ibs_cbs = do_grupo$classificacao_ibs_cbs, cst_regular = do_grupo$cst_regular,
                         classificacao_regular = do_grupo$classificacao_regular, base = do_grupo$base,
                         valor_produto = do_grupo$valor_produto, diferimento_ibs_uf = do_grupo$diferimento,
                         diferimento_ibs_municipio = do_grupo$diferimento, diferimento_cbs = do_grupo$diferimento)
    calculados[[length(calculados) + 1]] = ibs_cbs_calcular(entrada, data = "2027-01-01", aliquotas = aliquotas)$itens
  }
  calculados = do.call(rbind, calculados)
  calculados = calculados[order(calculados$item), ]
  # Só a 221001 fica de fora: nela a calculadora usa uma alíquota que ela mesma chama de fictícia.
  expect_identical(sum(calculados$calculado), 260L)
  expect_identical(unique(calculados$classificacao_ibs_cbs[!calculados$calculado]), "221001")
  # A base da redução da base (CST 222) saiu dos componentes: a metade dos 200,00 cobrados, como na calculadora.
  expect_equal(calculados$base[calculados$cst_ibs_cbs == "222"], c(100, 100))

  colunas_oficiais = c("item", grep("^oficial_", names(regua), value = TRUE))
  comparados = merge(calculados[calculados$calculado, ], regua[, colunas_oficiais], by = "item")
  tabela_da_classificacao = tabela_fiscal("classificacao_ibs_cbs")
  com_tributacao_regular = tabela_da_classificacao$codigo[tabela_da_classificacao$grupo_tributacao_regular %in% 1]
  regular_no_200 = comparados$cst_ibs_cbs == "200" & comparados$classificacao_ibs_cbs %in% com_tributacao_regular
  campos_do_grupo_de_reducao = c(paste0("reducao_", PARTES_DO_CALCULO), paste0("aliquota_efetiva_", PARTES_DO_CALCULO))
  escolha_da_ub26_20 = 0
  escolha_da_ub54a_10 = 0
  outras_diferencas = character()
  for (campo in campos_da_regua()) {
    do_rnfe = comparados[[campo]]
    oficial = comparados[[paste0("oficial_", campo)]]
    igual = (is.na(do_rnfe) & is.na(oficial)) | (!is.na(do_rnfe) & !is.na(oficial) & abs(do_rnfe - oficial) < 1e-9)
    for (posicao in which(!igual)) {
      # A UB26-20 exige o grupo da redução na classificação com tributação regular do CST 200; a calculadora não o traz.
      pela_ub26_20 = campo %in% campos_do_grupo_de_reducao & regular_no_200[posicao] & is.na(oficial[posicao])
      # A UB54a-10: o IBS do item é a soma da UF e do município; a calculadora arredonda o total à parte.
      soma_das_partes = comparados$valor_ibs_uf[posicao] + comparados$valor_ibs_municipio[posicao]
      pela_ub54a_10 = campo == "valor_ibs" & abs(do_rnfe[posicao] - soma_das_partes) < 1e-9 &
        abs(do_rnfe[posicao] - oficial[posicao]) < 0.01 + 1e-9
      if (pela_ub26_20) {
        escolha_da_ub26_20 = escolha_da_ub26_20 + 1
      } else if (pela_ub54a_10) {
        escolha_da_ub54a_10 = escolha_da_ub54a_10 + 1
      } else {
        outras_diferencas = c(outras_diferencas, paste("item", comparados$item[posicao], campo, do_rnfe[posicao],
                                                       oficial[posicao]))
      }
    }
  }
  expect_identical(outras_diferencas, character())
  expect_identical(escolha_da_ub26_20, 24)
  expect_identical(escolha_da_ub54a_10, 11)
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
