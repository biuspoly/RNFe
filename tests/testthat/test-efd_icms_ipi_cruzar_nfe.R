# A EFD de exemplo escritura a venda da nota 1001 do nfe_proc_sp.xml (C100 da emissão própria) e uma compra, a nota
# 555, sem XML entre os exemplos.
EFD_PARA_CRUZAR = system.file("exemplos", "efd_icms_ipi_sp.txt", package = "RNFe")
NOTA_PARA_CRUZAR = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")
CANCELAMENTO_DA_NOTA = system.file("exemplos", "evento_nfe_cancelamento.xml", package = "RNFe")

texto_da_nota_para_cruzar = function() {
  paste(readLines(NOTA_PARA_CRUZAR, encoding = "UTF-8"), collapse = "\n")
}

test_that("a nota escriturada confere com o XML, e a sem XML vem como s\u00f3 na EFD", {
  cruzamento = efd_icms_ipi_cruzar_nfe(EFD_PARA_CRUZAR, NOTA_PARA_CRUZAR)
  notas = cruzamento$notas
  expect_identical(nrow(notas), 2L)
  venda = notas[notas$numero == "1001", ]
  expect_identical(c(venda$onde, venda$chave), c("nas duas", "35261011222333000181550010000010011123456785"))
  expect_identical(c(venda$diferencas, venda$linha_efd), c(0L, 13L))
  expect_true(venda$emissao_propria)
  compra = notas[notas$numero == "555", ]
  expect_identical(compra$onde, "s\u00f3 na EFD")
  expect_false(compra$emissao_propria)
  expect_match(compra$observacao, "XML da nota")
  expect_identical(nrow(cruzamento$diferencas), 0L)
  # Pelo que os leitores já leram, o mesmo.
  pelos_lidos = efd_icms_ipi_cruzar_nfe(efd_icms_ipi_ler(EFD_PARA_CRUZAR), nfe_ler(NOTA_PARA_CRUZAR))
  expect_identical(pelos_lidos$notas, notas)
})

test_that("os valores, o n\u00famero e o participante diferentes", {
  texto = sub("<vNF>115.00</vNF>", "<vNF>116.00</vNF>", texto_da_nota_para_cruzar(), fixed = TRUE)
  # O ICMS do item e o do total.
  texto = gsub("<vICMS>6.00</vICMS>", "<vICMS>7.00</vICMS>", texto, fixed = TRUE)
  texto = sub("<CNPJ>11444777000161</CNPJ>", "<CNPJ>11222333000181</CNPJ>", texto, fixed = TRUE)
  diferencas = efd_icms_ipi_cruzar_nfe(EFD_PARA_CRUZAR, texto)$diferencas
  expect_identical(sort(diferencas$campo_efd), sort(c("VL_DOC", "VL_ICMS", "COD_PART (0150)")))
  valor = diferencas[diferencas$campo_efd == "VL_DOC", ]
  expect_identical(c(valor$na_efd, valor$no_xml), c("115.00", "116.00"))
  expect_equal(valor$diferenca, -1)
  expect_identical(diferencas$no_xml[diferencas$campo_efd == "COD_PART (0150)"], "11222333000181")
})

test_that("na nota de terceiros, os impostos da EFD s\u00e3o os do cr\u00e9dito e n\u00e3o se comparam", {
  # A mesma nota escriturada como entrada de terceiros (IND_EMIT 1) por quem a recebeu: o ICMS diferente não conta,
  # o valor do documento sim.
  linhas = readLines(EFD_PARA_CRUZAR, encoding = "latin1")
  linhas[1] = sub("|11222333000181|", "|11444777000161|", linhas[1], fixed = TRUE)
  linhas[5] = sub("|11444777000161|", "|11222333000181|", linhas[5], fixed = TRUE)
  linhas[13] = sub("|C100|1|0|P001|", "|C100|0|1|P001|", linhas[13], fixed = TRUE)
  linhas[13] = sub("|50,00|6,00|", "|50,00|0,00|", linhas[13], fixed = TRUE)
  linhas[13] = sub("|115,00|", "|114,00|", linhas[13], fixed = TRUE)
  recebida = efd_icms_ipi_cruzar_nfe(paste(linhas, collapse = "\r\n"), NOTA_PARA_CRUZAR)
  expect_identical(recebida$diferencas$campo_efd, "VL_DOC")
  expect_false(recebida$notas$emissao_propria[recebida$notas$numero == "1001"])
})

test_that("a nota que falta na EFD e a situa\u00e7\u00e3o pelos eventos", {
  linhas = readLines(EFD_PARA_CRUZAR, encoding = "latin1")
  sem_a_venda = paste(linhas[-c(13:15)], collapse = "\r\n")
  falta = efd_icms_ipi_cruzar_nfe(sem_a_venda, NOTA_PARA_CRUZAR)$notas
  venda = falta[falta$numero == "1001", ]
  expect_identical(venda$onde, "s\u00f3 nos XML")
  expect_true(venda$emissao_propria)
  expect_match(venda$observacao, "Emiss\u00e3o pr\u00f3pria")
  # Com o cancelamento: a venda escriturada como regular não confere.
  cancelada = efd_icms_ipi_cruzar_nfe(EFD_PARA_CRUZAR, NOTA_PARA_CRUZAR, eventos = CANCELAMENTO_DA_NOTA)$diferencas
  expect_identical(c(cancelada$campo_efd, cancelada$na_efd, cancelada$no_xml), c("COD_SIT", "00", "cancelada"))
  # Escriturada como cancelada (COD_SIT 02, só a identificação), confere.
  linhas[13] = paste0("|C100|1|0||55|02|1|1001|35261011222333000181550010000010011123456785|", strrep("|", 20))
  como_cancelada = efd_icms_ipi_cruzar_nfe(paste(linhas[-c(14, 15)], collapse = "\r\n"), NOTA_PARA_CRUZAR,
                                           eventos = CANCELAMENTO_DA_NOTA)
  expect_identical(nrow(como_cancelada$diferencas), 0L)
  expect_error(efd_icms_ipi_cruzar_nfe(efd_icms_ipi_ler(EFD_PARA_CRUZAR, registros = "C100"), NOTA_PARA_CRUZAR),
               "0000")
})
