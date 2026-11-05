test_that("o CODE-128C da chave sai como o exemplo do Manual do DANFE (09758364, d\u00edgito 48)", {
  # O item 2.2 do Anexo II do MOC 7.0: START C, 09, 75, 83, 64, DV 48 e STOP, em larguras de barra e espaço.
  esperado = "2 1 1 2 3 2 2 2 1 2 1 3 2 4 1 2 1 1 1 1 4 2 1 2 1 1 1 4 2 2 3 1 3 1 2 1 2 3 3 1 1 1 2"
  expect_identical(paste(larguras_do_codigo_128("09758364"), collapse = " "), esperado)
  expect_identical(utils::tail(valores_do_codigo_128("09758364"), 1), 48)
  # Cada símbolo tem 11 módulos; a parada, 13.
  expect_equal(sum(larguras_do_codigo_128("35261011222333000181550010000010011123456785")), (1 + 22 + 1) * 11 + 13)
})

test_that("a chave com o CNPJ alfanum\u00e9rico: o modelo h\u00edbrido C e A da NT Conjunta 2025.001", {
  valores = valores_do_codigo_128("23261012ABC34501DE35550020000000421876543213")
  # Início C, os pares, CODE A (101), as letras e o algarismo que sobra no A (ASCII menos 32), CODE C (99) diante de
  # quatro algarismos ou mais.
  expect_identical(valores[1:17], c(105, 23, 26, 10, 12, 101, 33, 34, 35, 19, 99, 45, 1, 101, 36, 37, 99))
  digito = (valores[1] + sum(valores[2:(length(valores) - 1)] * seq_len(length(valores) - 2))) %% 103
  expect_identical(utils::tail(valores, 1), digito)
  expect_error(valores_do_codigo_128("35261a"), "mai\u00fasculas")
})

test_that("os n\u00fameros, os documentos e a chave no formato do DANFE", {
  expect_identical(numero_brasileiro(c(1234.5, 0.1, -5.5, NA)), c("1.234,50", "0,10", "-5,50", ""))
  expect_identical(numero_brasileiro(c(10, 1.2345, 1234567.891), 2, 4), c("10,00", "1,2345", "1.234.567,891"))
  expect_identical(documento_formatado(c("11222333000181", "12ABC34501DE35", "12345678909", NA)),
                   c("11.222.333/0001-81", "12.ABC.345/01DE-35", "123.456.789-09", ""))
  expect_identical(chave_em_blocos("35261011222333000181550010000010011123456785"),
                   "3526 1011 2223 3300 0181 5500 1000 0010 0111 2345 6785")
  expect_identical(numero_da_nota_formatado("1001"), "000.001.001")
})

test_that("o DANFE da NF-e: uma folha com o que o XML traz, e as folhas adicionais quando os itens n\u00e3o cabem", {
  skip_if_not_installed("pdftools")
  arquivo = tempfile(fileext = ".pdf")
  danfe_pdf(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), arquivo)
  expect_identical(pdftools::pdf_info(arquivo)$pages, 1L)
  texto = gsub("\\s+", " ", pdftools::pdf_text(arquivo))
  expect_match(texto, "DANFE", fixed = TRUE)
  expect_match(texto, "3526 1011 2223 3300 0181 5500 1000 0010 0111 2345 6785", fixed = TRUE)
  expect_match(texto, "135260000012345", fixed = TRUE)
  expect_match(texto, "FOLHA 1/1", fixed = TRUE)
  expect_match(texto, "SEM VALOR FISCAL", fixed = TRUE)
  # Setenta itens: três folhas, cada uma com o cabeçalho.
  nota = paste(readLines(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), encoding = "UTF-8"), collapse = "\n")
  item = regmatches(nota, regexpr("(?s)<det nItem=\"1\">.*?</det>", nota, perl = TRUE))
  itens = character()
  for (numero in 1:70) {
    itens = c(itens, sub('nItem="1"', paste0('nItem="', numero, '"'), item, fixed = TRUE))
  }
  longa = sub("(?s)<det nItem=\"1\">.*</det>", paste(itens, collapse = ""), nota, perl = TRUE)
  arquivo_longo = tempfile(fileext = ".pdf")
  danfe_pdf(longa, arquivo_longo)
  paginas = pdftools::pdf_text(arquivo_longo)
  expect_gt(length(paginas), 1)
  expect_match(paginas[length(paginas)], sprintf("FOLHA %d/%d", length(paginas), length(paginas)), fixed = TRUE)
  expect_error(danfe_pdf(system.file("exemplos", "nfce_ce_contingencia.xml", package = "RNFe"), tempfile(fileext = ".pdf")),
               "danfce_pdf")
  expect_error(danfe_pdf(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), "sem_extensao"), "\\.pdf")
})
