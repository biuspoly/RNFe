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

linha_da_regra = function(conferencias, regra, item = 1) {
  conferencias[conferencias$regra == regra & conferencias$item %in% item, ]
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

test_that("a linha da tabela que mudou depois da emiss\u00e3o fica sem conferir em vez de errada", {
  # A classificação 200001 deixou de valer na NF-e na versão 1.40 da tabela (publicada em 28/01/2026, em produção até
  # 04/05/2026).
  texto = trocar_no_xml(texto_do_exemplo(), "<cClassTrib>000001</cClassTrib>", "<cClassTrib>200001</cClassTrib>")
  texto = trocar_no_xml(texto, "<CST>000</CST>", "<CST>200</CST>")
  depois_do_prazo = linha_da_regra(ibs_cbs_conferir(com_emissao_em(texto, "2026-06-01"))$conferencias, "UB14-25")
  expect_false(depois_do_prazo$confere)
  expect_identical(depois_do_prazo$codigo_sefaz, "1025")
  no_meio = linha_da_regra(ibs_cbs_conferir(com_emissao_em(texto, "2026-03-02"))$conferencias, "UB14-25")
  expect_true(is.na(no_meio$confere))
  expect_match(no_meio$observacao, "vers\u00e3o 1.40 da tabela de classifica\u00e7\u00e3o tribut\u00e1ria", fixed = TRUE)
  expect_match(no_meio$observacao, "permitido_na_nfe do c\u00f3digo 200001 mudou de 1 para 0", fixed = TRUE)
  expect_match(no_meio$observacao, "pode ter conferido", fixed = TRUE)
  # Antes de a versão ser publicada, a SEFAZ certamente usou a anterior.
  antes_de_publicar = linha_da_regra(ibs_cbs_conferir(com_emissao_em(texto, "2026-01-12"))$conferencias, "UB14-25")
  expect_true(is.na(antes_de_publicar$confere))
  expect_match(antes_de_publicar$observacao, "a SEFAZ conferiu a nota pela vers\u00e3o anterior", fixed = TRUE)
})

test_that("as regras de um modelo s\u00f3 valem nele", {
  # A UB120-10 (crédito presumido na NFC-e) é só do modelo 65.
  na_nfe = ibs_cbs_conferir(texto_do_exemplo(), todas_as_regras = TRUE)$conferencias
  expect_false("UB120-10" %in% na_nfe$regra)
  na_nfce = ibs_cbs_conferir(trocar_no_xml(texto_do_exemplo(), "<mod>55</mod>", "<mod>65</mod>"),
                             todas_as_regras = TRUE)$conferencias
  expect_true("UB120-10" %in% na_nfce$regra)
  expect_true(all(na_nfce$confere))
})

test_that("nota sem IBS e CBS, documento que n\u00e3o \u00e9 NF-e e par\u00e2metro errado", {
  sem_ibs_cbs = ibs_cbs_conferir(system.file("exemplos", "nfe_ce_simples_cpf.xml", package = "RNFe"),
                                 todas_as_regras = TRUE)
  expect_identical(sem_ibs_cbs$notas$itens_com_ibs_cbs, 0L)
  # Só a regra do total: sem item com IBSCBS, a nota não tem o IBSCBSTot.
  expect_identical(sem_ibs_cbs$conferencias$regra, "W34-20")
  expect_true(sem_ibs_cbs$conferencias$confere)
  do_cte = ibs_cbs_conferir(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  expect_identical(nrow(do_cte$notas), 0L)
  expect_identical(names(do_cte$notas), c("chave", "numero", "modelo", "data_emissao", "itens_com_ibs_cbs",
                                          "regras_conferidas", "regras_erradas", "regras_sem_conferir"))
  expect_match(do_cte$arquivos$problema, "NF-e")
  expect_error(ibs_cbs_conferir(texto_do_exemplo(), todas_as_regras = NA), "todas_as_regras")
})
