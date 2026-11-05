# O exemplo nfe_proc_sp.xml foi montado com o IBS e a CBS de 2026 certos (0,1% de IBS da UF e 0,9% de CBS) e emitido
# em 15/10/2026, depois de todas as regras entrarem em produção. Cada teste troca um pedaço do texto do XML.

texto_do_exemplo = function() {
  paste(readLines(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), encoding = "UTF-8"), collapse = "\n")
}

# Troca a primeira vez que o pedaço aparece (no item, o item 1) e confere que ele estava lá.
trocar_no_xml = function(texto, antes, depois) {
  expect_true(grepl(antes, texto, fixed = TRUE), info = antes)
  sub(antes, depois, texto, fixed = TRUE)
}

com_emissao_em = function(texto, data) {
  trocar_no_xml(texto, "<dhEmi>2026-10-15T10:30:00-03:00</dhEmi>", paste0("<dhEmi>", data, "T10:30:00-03:00</dhEmi>"))
}

linha_da_regra = function(conferencias, regras, item = 1) {
  conferencias[conferencias$regra %in% regras & conferencias$item %in% item, ]
}

test_that("o exemplo certo confere em todas as regras", {
  conferida = ibs_cbs_conferir(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"))
  expect_identical(nrow(conferida$notas), 1L)
  expect_identical(conferida$notas$itens_com_ibs_cbs, 2L)
  expect_identical(conferida$notas$regras_erradas, 0L)
  expect_identical(conferida$notas$regras_sem_conferir, 0L)
  # Sem todas_as_regras, só vem o que não confere.
  expect_identical(nrow(conferida$conferencias), 0L)
  expect_identical(names(conferida$conferencias), c("chave", "item", "regra", "campo", "no_documento", "esperado",
                                                    "diferenca", "confere", "codigo_sefaz", "mensagem", "observacao"))
  todas = ibs_cbs_conferir(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), todas_as_regras = TRUE)
  expect_identical(nrow(todas$conferencias), todas$notas$regras_conferidas)
  expect_true(all(todas$conferencias$confere))
  expect_false(anyNA(todas$conferencias$codigo_sefaz))
  # Toda regra da conferência está na lista das regras, com o código e a data de produção.
  regras = regras_do_ibs_cbs()
  expect_true(all(todas$conferencias$regra %in% regras$regra))
  expect_false(anyNA(regras$em_producao_desde))
  valor_da_cbs = linha_da_regra(todas$conferencias, "UB67-10")
  expect_identical(c(valor_da_cbs$no_documento, valor_da_cbs$esperado), c("0.45", "0.45"))
  expect_identical(valor_da_cbs$mensagem, "Valor da CBS difere do calculado")
})

test_that("os erros de al\u00edquota, de conta e de total, com o c\u00f3digo da rejei\u00e7\u00e3o", {
  texto = trocar_no_xml(texto_do_exemplo(), "<vIBSUF>0.05</vIBSUF>", "<vIBSUF>0.07</vIBSUF>")
  texto = trocar_no_xml(texto, "<pCBS>0.90</pCBS>", "<pCBS>1.00</pCBS>")
  erradas = ibs_cbs_conferir(texto)$conferencias
  expect_identical(sort(erradas$regra), sort(c("UB56-10", "UB35-10", "UB67-10", "UB54a-10", "W41-10")))
  expect_true(all(erradas$confere %in% FALSE))
  ibs_da_uf = linha_da_regra(erradas, "UB35-10")
  expect_identical(ibs_da_uf$codigo_sefaz, "1041")
  expect_equal(ibs_da_uf$diferenca, 0.02)
  # A CBS de 1% calcula 0,50 sobre a base de 50,00.
  expect_identical(linha_da_regra(erradas, "UB67-10")$esperado, "0.50")
  expect_identical(linha_da_regra(erradas, "UB56-10")$codigo_sefaz, "1037")
  total = linha_da_regra(erradas, "W41-10", NA)
  expect_identical(c(total$no_documento, total$esperado), c("0.11", "0.13"))
})

test_that("o valor calculado vai a 2 casas antes da toler\u00e2ncia de 0,01", {
  # Base de 50,50: a CBS calculada é 0,4545, que vai a 0,45. O 0,44 fica a 0,01 dela (sem arredondar, 0,0145) e
  # confere; o 0,43, a 0,02, não.
  texto = trocar_no_xml(texto_do_exemplo(), "<vBC>50.00</vBC>", "<vBC>50.50</vBC>")
  com_044 = trocar_no_xml(texto, "<vCBS>0.45</vCBS>", "<vCBS>0.44</vCBS>")
  conferida = ibs_cbs_conferir(com_044, todas_as_regras = TRUE)$conferencias
  expect_true(linha_da_regra(conferida, "UB67-10")$confere)
  expect_equal(linha_da_regra(conferida, "UB67-10")$diferenca, -0.01)
  com_043 = trocar_no_xml(texto, "<vCBS>0.45</vCBS>", "<vCBS>0.43</vCBS>")
  expect_false(linha_da_regra(ibs_cbs_conferir(com_043)$conferencias, "UB67-10")$confere)
  # Meio centavo vai para cima, também no negativo.
  expect_identical(arredondar_no_centavo(c(0.125, -0.125, 0.4545, 10.06507)), c(0.13, -0.13, 0.45, 10.07))
})

test_that("a regra s\u00f3 vale para a nota emitida depois de entrar em produ\u00e7\u00e3o", {
  # A UB24-10 (devolução de tributos no IBS da UF) entrou em produção em 03/08/2026; a maioria, em 10/11/2025.
  em_outubro = ibs_cbs_conferir(texto_do_exemplo(), todas_as_regras = TRUE)$conferencias
  expect_true("UB24-10" %in% em_outubro$regra)
  em_marco = ibs_cbs_conferir(com_emissao_em(texto_do_exemplo(), "2026-03-02"), todas_as_regras = TRUE)
  expect_false("UB24-10" %in% em_marco$conferencias$regra)
  expect_true("UB35-10" %in% em_marco$conferencias$regra)
  # Antes de 10/11/2025, nenhuma regra estava em produção.
  em_2025 = ibs_cbs_conferir(com_emissao_em(texto_do_exemplo(), "2025-11-07"), todas_as_regras = TRUE)
  expect_identical(nrow(em_2025$conferencias), 0L)
  expect_identical(em_2025$notas$regras_conferidas, 0L)
})

test_that("a regra que mudou depois da emiss\u00e3o fica sem conferir em vez de errada", {
  # A UB56-10 mudou na NT v1.51 (produção em 05/10/2026): a nota de setembro com a CBS errada fica sem conferir, com o
  # motivo; a UB67-10, que não mudou depois disso, continua errada.
  texto = com_emissao_em(trocar_no_xml(texto_do_exemplo(), "<pCBS>0.90</pCBS>", "<pCBS>1.00</pCBS>"), "2026-09-01")
  conferida = ibs_cbs_conferir(texto)
  aliquota_da_cbs = linha_da_regra(conferida$conferencias, "UB56-10")
  expect_true(is.na(aliquota_da_cbs$confere))
  expect_match(aliquota_da_cbs$observacao, "mudou na NT 2025.002 v1.51 (em produ\u00e7\u00e3o desde 05/10/2026)", fixed = TRUE)
  expect_false(linha_da_regra(conferida$conferencias, "UB67-10")$confere)
  expect_identical(conferida$notas$regras_sem_conferir, 1L)
  # Em outubro, depois da mudança, a mesma nota está errada.
  em_outubro = ibs_cbs_conferir(trocar_no_xml(texto_do_exemplo(), "<pCBS>0.90</pCBS>", "<pCBS>1.00</pCBS>"))
  expect_false(linha_da_regra(em_outubro$conferencias, "UB56-10")$confere)
})

test_that("a mesma nota duas vezes no arquivo \u00e9 conferida uma vez", {
  nota = regmatches(texto_do_exemplo(), regexpr("(?s)<NFe .*?</NFe>", texto_do_exemplo(), perl = TRUE))
  repetida = ibs_cbs_conferir(paste0("<lote>", nota, nota, "</lote>"), todas_as_regras = TRUE)
  uma_vez = ibs_cbs_conferir(texto_do_exemplo(), todas_as_regras = TRUE)
  expect_identical(nrow(repetida$notas), 1L)
  expect_identical(nrow(repetida$conferencias), nrow(uma_vez$conferencias))
  expect_identical(repetida$notas$regras_conferidas, uma_vez$notas$regras_conferidas)
})

# A tabela de alíquotas com uma CBS de 2027 inventada (8,8%), para conferir a UB56-20 quando ela for publicada.
TABELA_FISCAL_DO_PACOTE = tabela_fiscal
tabela_com_a_cbs_de_2027 = function(nome_da_tabela) {
  tabela = TABELA_FISCAL_DO_PACOTE(nome_da_tabela)
  if (nome_da_tabela == "aliquotas_ibs_cbs") {
    tabela$aliquota_cbs[tabela$inicio == as.Date("2027-01-01")] = 8.8
  }
  tabela
}

test_that("a CBS de 2027 em diante vale pela UB56-20, pelo ano da nota", {
  em_2027 = sub("<dhEmi>2026-10-15", "<dhEmi>2027-03-10", texto_do_exemplo(), fixed = TRUE)
  sem_referencia = linha_da_regra(ibs_cbs_conferir(em_2027, todas_as_regras = TRUE)$conferencias, c("UB56-10", "UB56-20"))
  expect_identical(sem_referencia$regra, "UB56-20")
  expect_true(is.na(sem_referencia$confere))
  expect_identical(sem_referencia$esperado, "a al\u00edquota do ano, a ser publicada")
  # Com a alíquota publicada na tabela, a nota de 2027 continua na UB56-20 (não na UB56-10, que é de 2025 e 2026).
  local_mocked_bindings(tabela_fiscal = tabela_com_a_cbs_de_2027)
  com_a_de_2026 = linha_da_regra(ibs_cbs_conferir(em_2027, todas_as_regras = TRUE)$conferencias, c("UB56-10", "UB56-20"))
  expect_identical(com_a_de_2026$regra, "UB56-20")
  expect_false(com_a_de_2026$confere)
  expect_identical(com_a_de_2026$esperado, "8.8")
  com_a_de_2027 = trocar_no_xml(em_2027, "<pCBS>0.90</pCBS>", "<pCBS>8.8000</pCBS>")
  expect_true(linha_da_regra(ibs_cbs_conferir(com_a_de_2027, todas_as_regras = TRUE)$conferencias, "UB56-20")$confere)
})

test_that("de 2029 em diante, as al\u00edquotas a ser publicadas ficam sem conferir, com o motivo", {
  em_2029 = com_emissao_em(texto_do_exemplo(), "2029-03-10")
  conferida = ibs_cbs_conferir(em_2029, todas_as_regras = TRUE)$conferencias
  ibs_da_uf = linha_da_regra(conferida, "UB18-10")
  expect_true(is.na(ibs_da_uf$confere))
  expect_identical(ibs_da_uf$esperado, "a al\u00edquota do ano, a ser publicada")
  expect_match(ibs_da_uf$observacao, "IBS deste ano ainda n\u00e3o foi publicada")
  expect_true(is.na(linha_da_regra(conferida, "UB37-10")$confere))
  cbs = linha_da_regra(conferida, "UB56-20")
  expect_true(is.na(cbs$confere))
  expect_match(cbs$observacao, "CBS deste ano ainda n\u00e3o foi publicada")
})

test_that("a linha da tabela que mudou depois da emiss\u00e3o fica sem conferir em vez de errada", {
  # A classificação 550002 deixou de valer na NF-e na versão 1.60 da tabela (publicada em 23/06/2026, em produção até
  # 06/07/2026).
  texto = trocar_no_xml(texto_do_exemplo(), "<cClassTrib>000001</cClassTrib>", "<cClassTrib>550002</cClassTrib>")
  texto = trocar_no_xml(texto, "<CST>000</CST>", "<CST>550</CST>")
  depois_do_prazo = linha_da_regra(ibs_cbs_conferir(com_emissao_em(texto, "2026-08-03"))$conferencias, "UB14-25")
  expect_false(depois_do_prazo$confere)
  expect_identical(depois_do_prazo$codigo_sefaz, "1025")
  no_meio = linha_da_regra(ibs_cbs_conferir(com_emissao_em(texto, "2026-07-01"))$conferencias, "UB14-25")
  expect_true(is.na(no_meio$confere))
  expect_match(no_meio$observacao, "vers\u00e3o 1.60 da tabela de classifica\u00e7\u00e3o tribut\u00e1ria", fixed = TRUE)
  expect_match(no_meio$observacao, "permitido_na_nfe do c\u00f3digo 550002 mudou de 1 para 0", fixed = TRUE)
  expect_match(no_meio$observacao, "pode ter conferido", fixed = TRUE)
  # Antes de a versão ser publicada, a SEFAZ certamente usou a anterior.
  antes_de_publicar = linha_da_regra(ibs_cbs_conferir(com_emissao_em(texto, "2026-06-10"))$conferencias, "UB14-25")
  expect_true(is.na(antes_de_publicar$confere))
  expect_match(antes_de_publicar$observacao, "a SEFAZ conferiu a nota pela vers\u00e3o anterior", fixed = TRUE)
  # A 200001 saiu da NF-e na 1.40, que não tem prazo no Informe Técnico: vale o da versão mais nova que ainda a traz
  # assim, a 1.71 (30/10/2026); o da 1.50 não serve (a SEFAZ autorizou NF-e com ela em 01/06/2026).
  texto_200001 = trocar_no_xml(texto_do_exemplo(), "<cClassTrib>000001</cClassTrib>", "<cClassTrib>200001</cClassTrib>")
  texto_200001 = trocar_no_xml(texto_200001, "<CST>000</CST>", "<CST>200</CST>")
  em_junho = linha_da_regra(ibs_cbs_conferir(com_emissao_em(texto_200001, "2026-06-01"))$conferencias, "UB14-25")
  expect_true(is.na(em_junho$confere))
  expect_match(em_junho$observacao, "em produ\u00e7\u00e3o at\u00e9 30/10/2026", fixed = TRUE)
  expect_match(em_junho$observacao, "pode ter conferido", fixed = TRUE)
  em_novembro = linha_da_regra(ibs_cbs_conferir(com_emissao_em(texto_200001, "2026-11-04"))$conferencias, "UB14-25")
  expect_false(em_novembro$confere)
})

test_that("as regras de um modelo s\u00f3 valem nele", {
  # A UB120-10 (crédito presumido na NFC-e) é só do modelo 65.
  na_nfe = ibs_cbs_conferir(texto_do_exemplo(), todas_as_regras = TRUE)$conferencias
  expect_false("UB120-10" %in% na_nfe$regra)
  # A NFC-e é presencial: o exemplo (indPres 9) vira presencial (1) junto.
  nfce = trocar_no_xml(texto_do_exemplo(), "<mod>55</mod>", "<mod>65</mod>")
  na_nfce = ibs_cbs_conferir(nfce, todas_as_regras = TRUE)$conferencias
  expect_false(linha_da_regra(na_nfce, "B25b-20", NA)$confere)
  na_nfce = ibs_cbs_conferir(trocar_no_xml(nfce, "<indPres>9</indPres>", "<indPres>1</indPres>"),
                             todas_as_regras = TRUE)$conferencias
  expect_true("UB120-10" %in% na_nfce$regra)
  expect_true(all(na_nfce$confere))
})

test_that("nota sem IBS e CBS, documento que n\u00e3o \u00e9 NF-e e par\u00e2metro errado", {
  sem_ibs_cbs = ibs_cbs_conferir(system.file("exemplos", "nfe_ce_simples_cpf.xml", package = "RNFe"),
                                 todas_as_regras = TRUE)
  expect_identical(sem_ibs_cbs$notas$itens_com_ibs_cbs, 0L)
  # As regras da NT só valem no documento com o IBS e a CBS preenchidos (nota ** do cronograma).
  expect_identical(nrow(sem_ibs_cbs$conferencias), 0L)
  expect_identical(sem_ibs_cbs$notas$regras_conferidas, 0L)
  do_cte = ibs_cbs_conferir(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  expect_identical(nrow(do_cte$notas), 0L)
  expect_identical(names(do_cte$notas), c("chave", "numero", "modelo", "data_emissao", "itens_com_ibs_cbs",
                                          "regras_conferidas", "regras_erradas", "regras_sem_conferir"))
  expect_match(do_cte$arquivos$problema, "NF-e")
  expect_error(ibs_cbs_conferir(texto_do_exemplo(), todas_as_regras = NA), "todas_as_regras")
})

# Troca o gIBSCBS do item 1 por outro pedaço (a transferência de crédito e o ajuste de competência ficam no lugar dele).
trocar_o_grupo_do_item_1 = function(texto, pedaco_novo) {
  expect_true(grepl("<gIBSCBS>", texto, fixed = TRUE))
  sub("(?s)<gIBSCBS>.*?</gIBSCBS>", pedaco_novo, texto, perl = TRUE)
}

# Põe um pedaço logo depois do gIBSCBS do item 1 (o estorno e o crédito presumido da ZFM ficam ali).
depois_do_grupo_do_item_1 = function(texto, pedaco_novo) {
  sub("(?s)(<gIBSCBS>.*?</gIBSCBS>)", paste0("\\1", pedaco_novo), texto, perl = TRUE)
}

com_tipo_de_nota = function(texto, finalidade, campo, tipo) {
  trocar_no_xml(texto, "<finNFe>1</finNFe>", paste0("<finNFe>", finalidade, "</finNFe><", campo, ">", tipo, "</", campo, ">"))
}

test_that("a classifica\u00e7\u00e3o e o tipo da nota de d\u00e9bito ou de cr\u00e9dito combinam", {
  # Nota de débito de perda em estoque (07) pede a 410030; a 811001 (anulação de crédito) pede o débito do tipo 02.
  perda = com_tipo_de_nota(texto_do_exemplo(), "6", "tpNFDebito", "07")
  na_perda = linha_da_regra(ibs_cbs_conferir(perda)$conferencias, "UB14-70")
  expect_false(na_perda$confere)
  expect_identical(na_perda$esperado, "cClassTrib 410030")
  expect_identical(na_perda$codigo_sefaz, "1200")
  anulacao = trocar_no_xml(texto_do_exemplo(), "<cClassTrib>000001</cClassTrib>", "<cClassTrib>811001</cClassTrib>")
  sem_o_debito = linha_da_regra(ibs_cbs_conferir(anulacao)$conferencias, "UB14-60")
  expect_false(sem_o_debito$confere)
  expect_identical(sem_o_debito$esperado, "tpNFDebito 02")
  com_o_debito = ibs_cbs_conferir(com_tipo_de_nota(anulacao, "6", "tpNFDebito", "02"), todas_as_regras = TRUE)
  expect_true(linha_da_regra(com_o_debito$conferencias, "UB14-60")$confere)
  expect_true(linha_da_regra(com_o_debito$conferencias, "UB14-70")$confere)
  # A 800001 (sucessão) vale no débito ou no crédito do tipo 05.
  expect_identical(tipos_de_nota_da_classificacao("800001"), "tpNFDebito 05 ou tpNFCredito 05")
  # Nota de crédito do tipo 02 pede a 810001 e o grupo do crédito presumido da ZFM.
  credito_da_zfm = ibs_cbs_conferir(com_tipo_de_nota(texto_do_exemplo(), "5", "tpNFCredito", "02"))$conferencias
  expect_identical(linha_da_regra(credito_da_zfm, "UB14-80")$esperado, "cClassTrib 810001")
  expect_false(linha_da_regra(credito_da_zfm, "UB131-50")$confere)
  # Antes de 03/08/2026 essas três não estavam em produção.
  em_julho = ibs_cbs_conferir(com_emissao_em(perda, "2026-07-01"), todas_as_regras = TRUE)$conferencias
  expect_false("UB14-70" %in% em_julho$regra)
})

test_that("transfer\u00eancia de cr\u00e9dito, ajuste de compet\u00eancia e estorno com valor", {
  transferencia = trocar_no_xml(texto_do_exemplo(), "<cClassTrib>000001</cClassTrib>", "<cClassTrib>800001</cClassTrib>")
  transferencia = trocar_no_xml(transferencia, "<CST>000</CST>", "<CST>800</CST>")
  zerada = trocar_o_grupo_do_item_1(transferencia, "<gTransfCred><vIBS>0.00</vIBS><vCBS>0.00</vCBS></gTransfCred>")
  erradas = ibs_cbs_conferir(zerada)$conferencias
  expect_identical(linha_da_regra(erradas, "UB106-30")$no_documento, "1")
  expect_false(linha_da_regra(erradas, "UB106-31")$confere)
  expect_identical(linha_da_regra(erradas, "UB106-40")$no_documento, "IBS 0.00, CBS 0.00")
  certa = trocar_o_grupo_do_item_1(transferencia, "<gTransfCred><vIBS>1.00</vIBS><vCBS>0.00</vCBS></gTransfCred>")
  certa = ibs_cbs_conferir(com_tipo_de_nota(certa, "6", "tpNFDebito", "05"), todas_as_regras = TRUE)$conferencias
  expect_true(all(linha_da_regra(certa, c("UB106-30", "UB106-31", "UB106-40"))$confere))

  ajuste = trocar_o_grupo_do_item_1(texto_do_exemplo(),
                                    "<gAjusteCompet><competApur>2026-09</competApur><vIBS>0.00</vIBS><vCBS>0.00</vCBS></gAjusteCompet>")
  expect_false(linha_da_regra(ibs_cbs_conferir(ajuste)$conferencias, "UB112-30")$confere)

  estorno = depois_do_grupo_do_item_1(texto_do_exemplo(),
                                      "<gEstornoCred><vIBSEstCred>0.00</vIBSEstCred><vCBSEstCred>0.00</vCBSEstCred></gEstornoCred>")
  expect_false(linha_da_regra(ibs_cbs_conferir(estorno)$conferencias, "UB116-30")$confere)
  # Na perda em estoque o estorno pode vir zerado.
  na_perda = ibs_cbs_conferir(com_tipo_de_nota(estorno, "6", "tpNFDebito", "07"), todas_as_regras = TRUE)$conferencias
  expect_false("UB116-30" %in% na_perda$regra)
})

test_that("o cr\u00e9dito presumido da ZFM: s\u00f3 na nota de cr\u00e9dito 02, compet\u00eancia e tipo sem repetir", {
  grupo = "<gCredPresIBSZFM><competApur>2026-12</competApur><tpCredPresIBSZFM>1</tpCredPresIBSZFM><vCredPresIBSZFM>1.00</vCredPresIBSZFM></gCredPresIBSZFM>"
  # O mesmo grupo nos dois itens.
  texto = gsub("(?s)(<gIBSCBS>.*?</gIBSCBS>)", paste0("\\1", grupo), texto_do_exemplo(), perl = TRUE)
  conferida = ibs_cbs_conferir(texto, todas_as_regras = TRUE)$conferencias
  expect_false(any(linha_da_regra(conferida, "UB131-40", 1:2)$confere))
  competencia = linha_da_regra(conferida, "UB132-10")
  expect_false(competencia$confere)
  expect_identical(competencia$esperado, "at\u00e9 2026-10 (o m\u00eas da autoriza\u00e7\u00e3o)")
  sem_protocolo = regmatches(texto, regexpr("(?s)<NFe .*?</NFe>", texto, perl = TRUE))
  sem_saber = linha_da_regra(ibs_cbs_conferir(sem_protocolo)$conferencias, "UB132-10")
  expect_true(is.na(sem_saber$confere))
  expect_match(sem_saber$observacao, "protocolo", fixed = TRUE)
  do_mes_da_emissao = sub("<competApur>2026-12</competApur>", "<competApur>2026-10</competApur>", sem_protocolo, fixed = TRUE)
  expect_true(linha_da_regra(ibs_cbs_conferir(do_mes_da_emissao, todas_as_regras = TRUE)$conferencias, "UB132-10")$confere)
  repetido = linha_da_regra(conferida, "UB133-10", 1:2)
  expect_identical(repetido$confere, c(TRUE, FALSE))
})

test_that("a CBS zero na \u00e1rea incentivada", {
  grupo = paste0("<pCBS>0.00</pCBS><gALCZFMCBS><tpALCZFMCBS>2</tpALCZFMCBS><nProcSuframa>000</nProcSuframa>",
                 "<pAliqEfetRegCBS>0.90</pAliqEfetRegCBS><vTribRegCBS>0.46</vTribRegCBS></gALCZFMCBS>")
  texto = trocar_no_xml(texto_do_exemplo(), "<pCBS>0.90</pCBS>", grupo)
  texto = trocar_no_xml(texto, "<vCBS>0.45</vCBS>", "<vCBS>0.00</vCBS>")
  # Emitente em São Paulo, sem inscrição na Suframa, e o valor sem a área a 0,01 da conta (sem tolerância).
  erradas = ibs_cbs_conferir(texto)$conferencias
  expect_false(linha_da_regra(erradas, "UB66a-10")$confere)
  expect_identical(linha_da_regra(erradas, "UB66a-20")$no_documento, "NCM 22011000, munic\u00edpios 3550308 e 3304557")
  expect_identical(linha_da_regra(erradas, "UB66c-10")$no_documento, "000")
  sem_area = linha_da_regra(erradas, "UB66e-10")
  expect_identical(c(sem_area$no_documento, sem_area$esperado), c("0.46", "0.45"))
  # Em Manaus os dois, com a inscrição, o processo e o valor certo: confere.
  em_manaus = gsub("<cMun>[0-9]{7}</cMun>", "<cMun>1302603</cMun>", texto)
  # A tag do schema é ISUFEmit (o texto da NT escreve ISUFemit); 123456789 é o exemplo do MOC 7.0, com o dígito certo.
  em_manaus = trocar_no_xml(em_manaus, "</emit>", "<ISUFEmit>123456789</ISUFEmit></emit>")
  em_manaus = trocar_no_xml(em_manaus, "<nProcSuframa>000</nProcSuframa>", "<nProcSuframa>12345</nProcSuframa>")
  em_manaus = trocar_no_xml(em_manaus, "<vTribRegCBS>0.46</vTribRegCBS>", "<vTribRegCBS>0.45</vTribRegCBS>")
  certa = ibs_cbs_conferir(em_manaus, todas_as_regras = TRUE)$conferencias
  expect_true(all(linha_da_regra(certa, c("UB66a-10", "UB66a-20", "UB66c-10", "UB66e-10"))$confere))
})

# O grupo do crédito presumido da operação no item 1, com o código e os grupos do IBS e da CBS pedidos.
com_credito_presumido = function(texto, codigo, grupo_do_ibs = "", grupo_da_cbs = "") {
  depois_do_grupo_do_item_1(texto, paste0("<gCredPresOper><vBCCredPres>50.00</vBCCredPres><cCredPres>", codigo,
                                          "</cCredPres>", grupo_do_ibs, grupo_da_cbs, "</gCredPresOper>"))
}

test_that("o cr\u00e9dito presumido pela tabela de cr\u00e9dito presumido", {
  do_ibs = "<gIBSCredPres><pCredPres>1.0000</pCredPres><vCredPres>0.02</vCredPres></gIBSCredPres>"
  da_cbs = "<gCBSCredPres><pCredPres>1.0000</pCredPres><vCredPres>0.50</vCredPres></gCBSCredPres>"
  # O código 99 não existe: e sem ele não dá para saber se o crédito sai do IBS do item.
  inexistente = ibs_cbs_conferir(com_credito_presumido(texto_do_exemplo(), "99", do_ibs))$conferencias
  expect_false(linha_da_regra(inexistente, "UB122-10")$confere)
  ibs_do_item = linha_da_regra(inexistente, "UB54a-10")
  expect_true(is.na(ibs_do_item$confere))
  expect_match(ibs_do_item$observacao, "n\u00e3o est\u00e1 na tabela")
  # O 05 exige o grupo da CBS e não permite o do IBS.
  so_da_cbs = ibs_cbs_conferir(com_credito_presumido(texto_do_exemplo(), "05", do_ibs))$conferencias
  expect_false(linha_da_regra(so_da_cbs, "UB123-10")$confere)
  expect_false(linha_da_regra(so_da_cbs, "UB127-20")$confere)
  expect_identical(linha_da_regra(so_da_cbs, "UB127-20")$codigo_sefaz, "1058")
  # O 04 (bem móvel de pessoa física) desconta o crédito do IBS do item e não passa do valor do produto (50,00).
  bem_movel = com_credito_presumido(texto_do_exemplo(), "04", do_ibs,
                                    "<gCBSCredPres><pCredPres>1.0000</pCredPres><vCredPres>60.00</vCredPres></gCBSCredPres>")
  conferida = ibs_cbs_conferir(bem_movel, todas_as_regras = TRUE)$conferencias
  expect_identical(linha_da_regra(conferida, "UB54a-10")$esperado, "0.03")
  expect_false(linha_da_regra(conferida, "UB54a-10")$confere)
  expect_true(linha_da_regra(conferida, "UB125-10")$confere)
  expect_identical(linha_da_regra(conferida, "UB129-10")$esperado, "at\u00e9 50.00 (vProd)")
  expect_false(linha_da_regra(conferida, "UB129-10")$confere)
  expect_true(all(linha_da_regra(conferida, c("UB122-10", "UB123-20", "UB127-20"))$confere))
  descontado = ibs_cbs_conferir(trocar_no_xml(bem_movel, "<vIBS>0.05</vIBS>", "<vIBS>0.03</vIBS>"),
                                todas_as_regras = TRUE)$conferencias
  expect_true(linha_da_regra(descontado, "UB54a-10")$confere)
  # O 05 não desconta: o IBS do item continua o da UF mais o do município.
  sem_desconto = ibs_cbs_conferir(com_credito_presumido(texto_do_exemplo(), "05", "", da_cbs),
                                  todas_as_regras = TRUE)$conferencias
  expect_true(linha_da_regra(sem_desconto, "UB54a-10")$confere)
  # O crédito em condição suspensiva: só no código 04, na CBS a partir de 2027 (a nota é de 2026).
  suspenso = com_credito_presumido(
    texto_do_exemplo(), "04", "",
    "<gCBSCredPres><pCredPres>1.0000</pCredPres><vCredPresCondSus>0.50</vCredPresCondSus></gCBSCredPres>"
  )
  na_cbs = linha_da_regra(ibs_cbs_conferir(suspenso)$conferencias, "UB130-10")
  expect_false(na_cbs$confere)
  expect_identical(c(na_cbs$no_documento, na_cbs$esperado), c("cCredPres 04, emitida em 2026", "cCredPres 04, a partir de 2027"))
})

# As regras da nota (fora do grupo UB) e do monofásico.

test_that("a previs\u00e3o de entrega, a nota de d\u00e9bito e de cr\u00e9dito e o local da opera\u00e7\u00e3o", {
  # Previsão de mais de 3 meses depois da saída (15/10/2026: até 15/01/2027).
  com_previsao = trocar_no_xml(texto_do_exemplo(), "<tpNF>1</tpNF>", "<dPrevEntrega>2027-03-01</dPrevEntrega><tpNF>1</tpNF>")
  previsao = ibs_cbs_conferir(com_previsao, todas_as_regras = TRUE)$conferencias
  expect_false(linha_da_regra(previsao, "B10a-20", NA)$confere)
  expect_identical(linha_da_regra(previsao, "B10a-20", NA)$esperado, "at\u00e9 2027-01-15")
  expect_true(linha_da_regra(previsao, "B10a-30", NA)$confere)
  sem_frete = trocar_no_xml(com_previsao, "<modFrete>0</modFrete>", "<modFrete>9</modFrete>")
  expect_false(linha_da_regra(ibs_cbs_conferir(sem_frete)$conferencias, "B10a-50", NA)$confere)
  expect_identical(tres_meses_depois(as.Date(c("2026-11-30", NA))), as.Date(c("2027-02-28", NA)))
  # Nota de crédito de 2026 do tipo 02 (só a partir de 2029), de saída (tem de ser de entrada) e com o ICMS no item.
  credito = com_tipo_de_nota(texto_do_exemplo(), "5", "tpNFCredito", "02")
  conferida = ibs_cbs_conferir(credito)$conferencias
  expect_false(linha_da_regra(conferida, "B25.2-30", NA)$confere)
  expect_false(linha_da_regra(conferida, "B25-110", NA)$confere)
  tributos_a_mais = linha_da_regra(conferida, "B25-80", 1)
  expect_identical(tributos_a_mais$no_documento, "ICMS, IPI, PIS, COFINS")
  expect_identical(tributos_a_mais$codigo_sefaz, "1001")
  # Na nota de débito sem o tipo, e na de crédito de multa e juros sem a nota referenciada.
  expect_false(linha_da_regra(ibs_cbs_conferir(trocar_no_xml(texto_do_exemplo(), "<finNFe>1</finNFe>", "<finNFe>6</finNFe>"))$conferencias,
                              "B25.1-20", NA)$confere)
  multa = ibs_cbs_conferir(com_tipo_de_nota(texto_do_exemplo(), "5", "tpNFCredito", "01"))$conferencias
  expect_false(linha_da_regra(multa, "B25-30", NA)$confere)
  # O cIndOp 010104 vale na NF-e e pede o local de retirada; o 100301 não vale na NF-e.
  leilao = ibs_cbs_conferir(trocar_no_xml(texto_do_exemplo(), "<tpNF>1</tpNF>", "<cIndOp>010104</cIndOp><tpNF>1</tpNF>"),
                            todas_as_regras = TRUE)$conferencias
  expect_true(linha_da_regra(leilao, "B25d-20", NA)$confere)
  expect_false(linha_da_regra(leilao, "B25d-30", NA)$confere)
  servico = ibs_cbs_conferir(trocar_no_xml(texto_do_exemplo(), "<tpNF>1</tpNF>", "<cIndOp>100301</cIndOp><tpNF>1</tpNF>"))
  expect_false(linha_da_regra(servico$conferencias, "B25d-20", NA)$confere)
})

test_that("a compra governamental: as chaves dos documentos anteriores", {
  # Recebimento do pagamento (tpOperGov 2) com duas chaves: a da própria nota e uma com o dígito errado.
  propria = "35261011222333000181550010000010011123456785"
  digito_errado = "35261011222333000181550010000010011123456780"
  grupo = paste0("<gCompraGov><tpEnteGov>1</tpEnteGov><pRedutor>0.0000</pRedutor><tpOperGov>2</tpOperGov><refDFeAnt>",
                 propria, "</refDFeAnt><refDFeAnt>", digito_errado, "</refDFeAnt></gCompraGov>")
  texto = trocar_no_xml(texto_do_exemplo(), "<indFinal>0</indFinal>", paste0(grupo, "<indFinal>0</indFinal>"))
  conferida = ibs_cbs_conferir(texto, todas_as_regras = TRUE)$conferencias
  expect_false(linha_da_regra(conferida, "BB05-30", NA)$confere)
  da_chave = conferida[conferida$regra %in% c("BB05-70", "BB05-150", "BB05-180"), c("regra", "no_documento", "confere")]
  expect_identical(da_chave$confere[da_chave$regra == "BB05-70"], c(TRUE, FALSE))
  expect_identical(da_chave$confere[da_chave$regra == "BB05-150"], c(FALSE, TRUE))
  expect_true(all(da_chave$confere[da_chave$regra == "BB05-180"]))
  # No recebimento do pagamento, o item não leva o ICMS, o PIS e a COFINS (B25-80) e a regra do ICMS ou ISSQN não vale.
  expect_false("B25-90" %in% conferida$regra)
})

test_that("a inscri\u00e7\u00e3o na Suframa do emitente e do destinat\u00e1rio", {
  # O dígito do MOC 7.0 (seção 8.4): 12345678 dá 9; a de 8 dígitos é a de 9 sem o zero da frente; setor 00 não vale.
  expect_identical(inscricao_suframa_confere(c("123456789", "12345679", "123456780", "001234567", NA)),
                   c(TRUE, TRUE, FALSE, FALSE, FALSE))
  texto = trocar_no_xml(texto_do_exemplo(), "<CRT>3</CRT>", "<CRT>3</CRT><ISUFEmit>123456780</ISUFEmit>")
  texto = trocar_no_xml(texto, "<indIEDest>1</indIEDest>", "<indIEDest>1</indIEDest><ISUF>123456789</ISUF>")
  conferida = ibs_cbs_conferir(texto)$conferencias
  # Emitente em São Paulo com a inscrição (fora da área), e com o dígito errado; destinatário no Rio de Janeiro.
  expect_false(linha_da_regra(conferida, "C22-10", NA)$confere)
  expect_false(linha_da_regra(conferida, "C22-20", NA)$confere)
  expect_identical(linha_da_regra(conferida, "E18-30", NA)$no_documento, "RJ 3304557")
})

test_that("os tributos, o CFOP e o documento referenciado de cada item", {
  # O item 1 sem o PIS, sem a origem do ICMS e com um CFOP de devolução numa venda.
  texto = sub("(?s)<PIS>.*?</PIS>", "", texto_do_exemplo(), perl = TRUE)
  texto = trocar_no_xml(texto, "<orig>0</orig>", "")
  texto = trocar_no_xml(texto, "<CFOP>6102</CFOP>", "<CFOP>5202</CFOP>")
  conferida = ibs_cbs_conferir(texto)$conferencias
  expect_identical(linha_da_regra(conferida, "Q01-20", 1)$codigo_sefaz, "745")
  expect_false(linha_da_regra(conferida, "N11-10", 1)$confere)
  expect_false(linha_da_regra(conferida, "I08-144", 1)$confere)
  # Documento referenciado no item e no cabeçalho ao mesmo tempo; e na NFC-e não pode.
  referenciada = "35261011222333000181550010000009991123456781"
  com_os_dois = trocar_no_xml(texto_do_exemplo(), "<tpNF>1</tpNF>", paste0("<NFref><refNFe>", referenciada, "</refNFe></NFref><tpNF>1</tpNF>"))
  com_os_dois = trocar_no_xml(com_os_dois, "<infAdProd>", paste0("<DFeReferenciado><chaveAcesso>", referenciada,
                                                                 "</chaveAcesso></DFeReferenciado><infAdProd>"))
  expect_false(linha_da_regra(ibs_cbs_conferir(com_os_dois)$conferencias, "VC02-05", 1)$confere)
  # O total dos produtos que não é a soma dos itens, e o total do Imposto Seletivo sem item com ele.
  totais = trocar_no_xml(texto_do_exemplo(), "<vProd>110.00</vProd>", "<vProd>111.00</vProd>")
  totais = trocar_no_xml(totais, "<vNFTot>", "<ISTot><vIS>0.00</vIS></ISTot><vNFTot>")
  conferida = ibs_cbs_conferir(totais)$conferencias
  expect_identical(linha_da_regra(conferida, "W07-10", NA)$esperado, "110.00")
  expect_false(linha_da_regra(conferida, "W31-10", NA)$confere)
})

test_that("a devolu\u00e7\u00e3o referencia um documento: a reda\u00e7\u00e3o antiga e a da v1.53 (VC02-14)", {
  devolucao = trocar_no_xml(texto_do_exemplo(), "<finNFe>1</finNFe>", "<finNFe>4</finNFe>")
  referenciada = "35261011222333000181550010000009991123456781"
  no_cabecalho = trocar_no_xml(devolucao, "<tpNF>1</tpNF>", paste0("<NFref><refNFe>", referenciada, "</refNFe></NFref><tpNF>1</tpNF>"))
  # Em 15/10/2026 vale a redação antiga: o documento no cabeçalho ou no item.
  expect_identical(linha_da_regra(ibs_cbs_conferir(devolucao)$conferencias, "VC02-14", 1:2)$confere, c(FALSE, FALSE))
  expect_true(all(linha_da_regra(ibs_cbs_conferir(no_cabecalho, todas_as_regras = TRUE)$conferencias, "VC02-14", 1:2)$confere))
  # Com o CFOP 1202, a redação antiga não vale; a da v1.53, sim.
  com_1202 = trocar_no_xml(devolucao, "<CFOP>6102</CFOP>", "<CFOP>1202</CFOP>")
  expect_identical(linha_da_regra(ibs_cbs_conferir(com_1202)$conferencias, "VC02-14", 1:2)$item, 2L)
  # Desde 16/11/2026: sem o refNFe no cabeçalho, cada item referencia; com ele, a regra não vale.
  nova = sub("<dhEmi>2026-10-15", "<dhEmi>2026-11-20", com_1202, fixed = TRUE)
  expect_identical(linha_da_regra(ibs_cbs_conferir(nova)$conferencias, "VC02-14", 1:2)$item, 1:2)
  com_refnfe_nova = sub("<dhEmi>2026-10-15", "<dhEmi>2026-11-20", no_cabecalho, fixed = TRUE)
  expect_false("VC02-14" %in% ibs_cbs_conferir(com_refnfe_nova, todas_as_regras = TRUE)$conferencias$regra)
  # Entre a publicação da v1.53 (30/10/2026) e 15/11/2026, a SEFAZ podia aplicar as duas: onde elas discordam (o item 1,
  # com o CFOP 1202), fica sem conferir; onde concordam (o item 2), errada.
  na_janela = linha_da_regra(ibs_cbs_conferir(com_emissao_em(com_1202, "2026-11-05"))$conferencias, "VC02-14", 1:2)
  expect_identical(na_janela$item, 1:2)
  expect_identical(na_janela$confere, c(NA, FALSE))
  expect_match(na_janela$observacao[1], "30/10 e 15/11/2026")
})

test_that("o total dos produtos soma s\u00f3 os itens com ICMS, IBS, CBS ou IS (W07-10)", {
  # Nota conjugada: o item 2 vira serviço, só com o ISSQN; o total dos produtos é o do item 1.
  partes = strsplit(texto_do_exemplo(), "<det nItem=\"2\">", fixed = TRUE)[[1]]
  partes[2] = sub("(?s)<ICMS>.*?</ICMS>", paste0(
    "<ISSQN><vBC>60.00</vBC><vAliq>5.0000</vAliq><vISSQN>3.00</vISSQN><cMunFG>3550308</cMunFG>",
    "<cListServ>01.01</cListServ><indISS>1</indISS><indIncentivo>2</indIncentivo></ISSQN>"), partes[2], perl = TRUE)
  partes[2] = sub("(?s)<IBSCBS>.*?</IBSCBS>", "", partes[2], perl = TRUE)
  conjugada = trocar_no_xml(paste(partes, collapse = "<det nItem=\"2\">"), "<vProd>110.00</vProd>", "<vProd>50.00</vProd>")
  total = linha_da_regra(ibs_cbs_conferir(conjugada, todas_as_regras = TRUE)$conferencias, "W07-10", NA)
  expect_true(total$confere)
  expect_identical(total$esperado, "50.00")
})

test_that("o grupo de totais do IBS e da CBS s\u00f3 com algum item com IBSCBS (W34)", {
  # Os itens sem o IBSCBS e o IBSCBSTot informado: a W34-10 acusa.
  sem_ibs_cbs = gsub("(?s)<IBSCBS>.*?</IBSCBS>", "", texto_do_exemplo(), perl = TRUE)
  expect_false(linha_da_regra(ibs_cbs_conferir(sem_ibs_cbs)$conferencias, "W34-10", NA)$confere)
  # Só o Imposto Seletivo, sem o IBS e a CBS: sem o IBSCBSTot, a W34-20 confere.
  so_imposto_seletivo = trocar_no_xml(sem_ibs_cbs, "</imposto>", paste0(
    "<IS><CSTIS>000</CSTIS><cClassTribIS>000001</cClassTribIS><vBCIS>50.00</vBCIS><pIS>1.0000</pIS><vIS>0.50</vIS></IS>",
    "</imposto>"))
  so_imposto_seletivo = sub("(?s)<IBSCBSTot>.*?</IBSCBSTot>", "<ISTot><vIS>0.50</vIS></ISTot>", so_imposto_seletivo, perl = TRUE)
  conferida = ibs_cbs_conferir(so_imposto_seletivo, todas_as_regras = TRUE)$conferencias
  expect_true(linha_da_regra(conferida, "W34-20", NA)$confere)
})

test_that("o que a SEFAZ autorizou em notas reais contra o texto da regra fica sem conferir", {
  # W07-10: um centavo de diferença fica sem conferir; dois, errado.
  um_centavo = ibs_cbs_conferir(trocar_no_xml(texto_do_exemplo(), "<vProd>110.00</vProd>", "<vProd>110.01</vProd>"))$conferencias
  expect_true(is.na(linha_da_regra(um_centavo, "W07-10", NA)$confere))
  expect_match(linha_da_regra(um_centavo, "W07-10", NA)$observacao, "0,01")
  dois_centavos = ibs_cbs_conferir(trocar_no_xml(texto_do_exemplo(), "<vProd>110.00</vProd>", "<vProd>110.02</vProd>"))$conferencias
  expect_false(linha_da_regra(dois_centavos, "W07-10", NA)$confere)
  # I05k-20: o 0 (sem crédito presumido) num emitente de São Paulo fica sem conferir; o 1, errado.
  com_zero = trocar_no_xml(texto_do_exemplo(), "<CFOP>6102</CFOP>", "<tpCredPresIBSZFM>0</tpCredPresIBSZFM><CFOP>6102</CFOP>")
  zero = linha_da_regra(ibs_cbs_conferir(com_zero)$conferencias, "I05k-20", 1)
  expect_true(is.na(zero$confere))
  expect_identical(zero$no_documento, "SP, tpCredPresIBSZFM 0")
  com_um = trocar_no_xml(com_zero, "<tpCredPresIBSZFM>0</tpCredPresIBSZFM>", "<tpCredPresIBSZFM>1</tpCredPresIBSZFM>")
  expect_false(linha_da_regra(ibs_cbs_conferir(com_um)$conferencias, "I05k-20", 1)$confere)
})

test_that("o ICMS da UF de destino na venda a consumidor final n\u00e3o contribuinte", {
  # Venda interestadual (idDest 2) a consumidor final não contribuinte: o item 1 (ICMS00) pede o ICMSUFDest; o item 2
  # (ICMS60, CFOP 6404) também.
  texto = trocar_no_xml(texto_do_exemplo(), "<indFinal>0</indFinal>", "<indFinal>1</indFinal>")
  texto = trocar_no_xml(texto, "<indIEDest>1</indIEDest>", "<indIEDest>9</indIEDest>")
  conferida = ibs_cbs_conferir(texto, todas_as_regras = TRUE)$conferencias
  expect_identical(linha_da_regra(conferida, "NA01-20", 1:2)$confere, c(FALSE, FALSE))
  # Do Simples Nacional, não.
  simples = ibs_cbs_conferir(trocar_no_xml(texto, "<CRT>3</CRT>", "<CRT>1</CRT>"), todas_as_regras = TRUE)$conferencias
  expect_false("NA01-20" %in% simples$regra)
  # Na devolução de uma NF-e de antes de 2016 (exceção 3), também pela chave referenciada no próprio item.
  devolucao = trocar_no_xml(texto, "<finNFe>1</finNFe>", "<finNFe>4</finNFe>")
  devolucao = trocar_no_xml(devolucao, "<infAdProd>", paste0("<DFeReferenciado><chaveAcesso>",
                                                             "35151011222333000181550010000009991123456781",
                                                             "</chaveAcesso></DFeReferenciado><infAdProd>"))
  na_devolucao = linha_da_regra(ibs_cbs_conferir(devolucao, todas_as_regras = TRUE)$conferencias, "NA01-20", 1:2)
  expect_identical(na_devolucao$item, 2L)
})

# Um item 1 de combustível com o grupo monofásico (no lugar do gIBSCBS) e o grupo comb, emitido em 20/11/2026.
item_de_combustivel = function(classificacao, grupo_monofasico, percentual_biocombustivel = "30.0000") {
  texto = com_emissao_em(texto_do_exemplo(), "2026-11-20")
  texto = trocar_no_xml(texto, "<CST>000</CST>", "<CST>620</CST>")
  texto = trocar_no_xml(texto, "<cClassTrib>000001</cClassTrib>", paste0("<cClassTrib>", classificacao, "</cClassTrib>"))
  texto = trocar_no_xml(texto, "<indTot>1</indTot>", paste0("<indTot>1</indTot><comb><cProdANP>320102001</cProdANP>",
                                                            "<descANP>GASOLINA C COMUM</descANP><pBio>",
                                                            percentual_biocombustivel, "</pBio><UFCons>SP</UFCons></comb>"))
  trocar_o_grupo_do_item_1(texto, paste0("<gIBSCBSMono>", grupo_monofasico,
                                         "<vTotIBSMonoItem>0.10</vTotIBSMonoItem><vTotCBSMonoItem>0.90</vTotCBSMonoItem>",
                                         "</gIBSCBSMono>"))
}

test_that("o monof\u00e1sico ad valorem de 2026 e o grupo de cada ano", {
  ad_valorem = paste0(
    "<gIBSMonoAdValorem><gMonoPadrao><vBCMono>100.00</vBCMono><pAliqMonoUF>0.1000</pAliqMonoUF><vIBSMonoUF>0.10</vIBSMonoUF>",
    "<pAliqMonoMun>0.0000</pAliqMonoMun><vIBSMonoMun>0.00</vIBSMonoMun><vIBSMono>0.10</vIBSMono></gMonoPadrao></gIBSMonoAdValorem>",
    "<gCBSMonoAdValorem><gMonoPadrao><vBCMono>100.00</vBCMono><pAliqMonoCBS>0.9000</pAliqMonoCBS><vCBSMono>0.90</vCBSMono>",
    "</gMonoPadrao></gCBSMonoAdValorem>"
  )
  conferida = ibs_cbs_conferir(item_de_combustivel("620001", ad_valorem), todas_as_regras = TRUE)$conferencias
  do_item = linha_da_regra(conferida, c("UB90-20", "UB100-20", "UB91-10", "UB101-10", "UB91c-10", "UB91f-10", "UB101c-10",
                                        "LA01-30"))
  expect_identical(nrow(do_item), 8L)
  expect_true(all(do_item$confere))
  # O valor da alíquota sem dividir por 100 não confere em percentual: fica sem conferir, com o motivo.
  literal = sub("<vIBSMonoUF>0.10</vIBSMonoUF>", "<vIBSMonoUF>10.00</vIBSMonoUF>", ad_valorem, fixed = TRUE)
  sem_conferir = linha_da_regra(ibs_cbs_conferir(item_de_combustivel("620001", literal))$conferencias, "UB91c-10")
  expect_true(is.na(sem_conferir$confere))
  expect_match(sem_conferir$observacao, "percentual")
  # Em 2029 o ad valorem do IBS e o da CBS não podem mais.
  em_2029 = sub("<dhEmi>2026-11-20", "<dhEmi>2029-01-10", item_de_combustivel("620001", ad_valorem), fixed = TRUE)
  depois = ibs_cbs_conferir(em_2029)$conferencias
  expect_false(linha_da_regra(depois, "UB90-10")$confere)
  expect_false(linha_da_regra(depois, "UB100-10")$confere)
  # Antes de 16/11/2026, o leiaute novo do monofásico não estava em produção.
  antes = sub("<dhEmi>2026-11-20", "<dhEmi>2026-11-10", item_de_combustivel("620001", ad_valorem), fixed = TRUE)
  expect_false("UB90-20" %in% ibs_cbs_conferir(antes, todas_as_regras = TRUE)$conferencias$regra)
  # LA01-30: a classificação 620 sem o grupo comb fica sem conferir antes de 16/11/2026 (há NF-e autorizada assim) e
  # errada depois.
  sem_comb = sub("(?s)<comb>.*?</comb>", "", item_de_combustivel("620001", ad_valorem), perl = TRUE)
  expect_false(linha_da_regra(ibs_cbs_conferir(sem_comb)$conferencias, "LA01-30")$confere)
  sem_comb_antes = sub("<dhEmi>2026-11-20", "<dhEmi>2026-08-10", sem_comb, fixed = TRUE)
  linha_antes = linha_da_regra(ibs_cbs_conferir(sem_comb_antes)$conferencias, "LA01-30")
  expect_true(is.na(linha_antes$confere))
  expect_match(linha_antes$observacao, "16/11/2026")
})

test_that("o etanol anidro fora do obrigat\u00f3rio (620004) e a quantidade de biocombust\u00edvel", {
  # A mistura obrigatória da gasolina C comum: 30% até 31/07/2026, 32% desde 01/08/2026.
  expect_identical(mistura_obrigatoria_na_data(c("320102001", "320102001", "999"), as.Date(c("2026-07-31", "2026-08-01", "2026-08-01"))),
                   c(0.30, 0.32, NA))
  # 620004 com pBio 35%: acima dos 32%. A quantidade a recolher: 10 x (0,35 - 0,32) / (1 - 0,32) = 0,4412.
  grupo = paste0(
    "<gIBSMonoAdValorem><gMonoRet><vIBSMonoRet>0.00</vIBSMonoRet></gMonoRet><gpBioDiferenca><qBCBioComb>0.4412</qBCBioComb>",
    "<vIBSDiferenca>0.00</vIBSDiferenca></gpBioDiferenca></gIBSMonoAdValorem>",
    "<gCBSMonoAdValorem><gMonoRet><vCBSMonoRet>0.00</vCBSMonoRet></gMonoRet><gpBioDiferenca><qBCBioComb>0.5000</qBCBioComb>",
    "<vCBSDiferenca>0.00</vCBSDiferenca></gpBioDiferenca></gCBSMonoAdValorem>"
  )
  conferida = ibs_cbs_conferir(item_de_combustivel("620004", grupo, "35.0000"), todas_as_regras = TRUE)$conferencias
  expect_true(linha_da_regra(conferida, "UB14-30")$confere)
  expect_true(linha_da_regra(conferida, "UB94a-10")$confere)
  na_cbs = linha_da_regra(conferida, "UB104a-10")
  expect_false(na_cbs$confere)
  expect_identical(na_cbs$esperado, "0.4412")
  # Com 30%, a 620004 (acima do obrigatório) não vale.
  abaixo = ibs_cbs_conferir(item_de_combustivel("620004", grupo, "30.0000"))$conferencias
  expect_false(linha_da_regra(abaixo, "UB14-30")$confere)
})

test_that("a NF-e avulsa referenciada: o emitente fica sem conferir, a UF confere (B25-50 e B25-60)", {
  # A chave da avulsa (série 890 a 899) traz o CNPJ do Fisco; esta é do Rio de Janeiro, e a nota é de São Paulo.
  avulsa = "33261000394460000141558900000012341123456780"
  complementar = trocar_no_xml(texto_do_exemplo(), "<finNFe>1</finNFe>", "<finNFe>2</finNFe>")
  complementar = trocar_no_xml(complementar, "<tpNF>1</tpNF>",
                               paste0("<NFref><refNFe>", avulsa, "</refNFe></NFref><tpNF>1</tpNF>"))
  conferida = ibs_cbs_conferir(complementar, todas_as_regras = TRUE)$conferencias
  emitente = linha_da_regra(conferida, "B25-50", NA)
  expect_true(is.na(emitente$confere))
  expect_identical(emitente$no_documento, "NF-e avulsa")
  expect_match(emitente$observacao, "CNPJ do Fisco")
  expect_false(linha_da_regra(conferida, "B25-60", NA)$confere)
})
