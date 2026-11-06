test_that("o DANFE Simplificado: os campos m\u00ednimos do manual, com os itens", {
  skip_if_not_installed("pdftools")
  arquivo = tempfile(fileext = ".pdf")
  expect_identical(danfe_simplificado_pdf(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), arquivo), arquivo)
  expect_identical(pdftools::pdf_info(arquivo)$pages, 1L)
  # O papel de 10 cm (em pontos), acima da largura mínima de 55 mm.
  expect_equal(pdftools::pdf_pagesize(arquivo)$width, 10 / 2.54 * 72, tolerance = 1)
  texto = gsub("\\s+", " ", gsub("\u00ad", "-", pdftools::pdf_text(arquivo), fixed = TRUE))
  expect_match(texto, "DANFE SIMPLIFICADO", fixed = TRUE)
  expect_match(texto, "3526 1011 2223 3300 0181 5500 1000 0010 0111 2345 6785", fixed = TRUE)
  expect_match(texto, "135260000012345", fixed = TRUE)
  expect_match(texto, "1 - SA\u00cdDA", fixed = TRUE)
  expect_match(texto, "1 / 000.001.001 / 15/10/2026", fixed = TRUE)
  expect_match(texto, "10,00 UN x 5,00 = 50,00", fixed = TRUE)
  expect_match(texto, "VALOR TOTAL DA NOTA R$ 115,00", fixed = TRUE)
})

test_that("o DANFE Simplificado - Etiqueta: sem os itens, com o protocolo do EPEC", {
  skip_if_not_installed("pdftools")
  arquivo = tempfile(fileext = ".pdf")
  danfe_simplificado_pdf(system.file("exemplos", "nfe_ce_simples_cpf.xml", package = "RNFe"), arquivo, etiqueta = TRUE,
                         protocolo_epec = "891260000001234")
  texto = gsub("\\s+", " ", gsub("\u00ad", "-", pdftools::pdf_text(arquivo), fixed = TRUE))
  expect_match(texto, "DANFE SIMPLIFICADO - ETIQUETA", fixed = TRUE)
  expect_match(texto, "PROTOCOLO DO EVENTO EPEC 891260000001234", fixed = TRUE)
  expect_match(texto, "123.456.789-09", fixed = TRUE)
  expect_no_match(texto, "VL UNIT", fixed = TRUE)
  expect_error(danfe_simplificado_pdf(system.file("exemplos", "nfce_ce_contingencia.xml", package = "RNFe"),
                                      tempfile(fileext = ".pdf")), "danfce_pdf")
  expect_error(danfe_simplificado_pdf(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), tempfile(fileext = ".pdf"),
                                      etiqueta = NA), "TRUE ou FALSE")
  # O DANFE Simplificado (sem ser a Etiqueta) não admite o EPEC (o item 3.11 do manual).
  expect_error(danfe_simplificado_pdf(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), tempfile(fileext = ".pdf"),
                                      protocolo_epec = "891260000001234"), "Etiqueta")
})
