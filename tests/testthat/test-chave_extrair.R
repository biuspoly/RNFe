# As imagens de tests/testthat/documentos são geradas por ferramentas/gerar_imagens_de_teste.R, com uma chave inventada
# (o CNPJ de exemplo). Cada jeito de achar a chave precisa de um pacote opcional: sem ele, o teste é pulado.
CHAVE_DAS_IMAGENS = "26261011222333000181650010000010011123456789"

imagem_de_teste = function(nome_do_arquivo) {
  test_path("documentos", nome_do_arquivo)
}

test_that("os n\u00fameros com cara de chave num texto: em blocos, emendados e com CNPJ de letras", {
  # Um número de 4 dígitos logo antes (um telefone) não esconde a chave.
  achadas = chaves_no_texto("fone 3333 2626 1011 2223 3300 0181 6500 1000 0010 0111 2345 6789 fim")
  expect_identical(achadas$validas, CHAVE_DAS_IMAGENS)
  expect_true(length(achadas$que_nao_conferem) >= 1)
  # Emendada, como no QR-Code da NFC-e, e em duas linhas.
  expect_identical(chaves_no_texto(paste0("consulta?p=", CHAVE_DAS_IMAGENS, "|2|2|1|ABC"))$validas, CHAVE_DAS_IMAGENS)
  expect_identical(chaves_no_texto("2626 1011 2223 3300 0181 6500\n1000 0010 0111 2345 6789")$validas, CHAVE_DAS_IMAGENS)
  # O CNPJ alfanumérico (o exemplo da Receita) dentro da chave.
  expect_identical(chaves_no_texto("3526 1012 ABC3 4501 DE35 5500 1000 0001 2311 2345 6784")$validas,
                   "35261012ABC34501DE35550010000001231123456784")
  nenhuma = chaves_no_texto("texto sem chave nenhuma 1234 5678")
  expect_length(nenhuma$validas, 0)
  expect_length(nenhuma$que_nao_conferem, 0)
  # Emendada, com um número colado antes ("Protocolo 1" e a chave sem espaço).
  expect_identical(chaves_no_texto(paste0("Protocolo 1", CHAVE_DAS_IMAGENS))$validas, CHAVE_DAS_IMAGENS)
  expect_identical(chaves_no_texto(paste0("NFe", CHAVE_DAS_IMAGENS, "99"))$validas, CHAVE_DAS_IMAGENS)
})

test_that("arquivo que n\u00e3o abre n\u00e3o derruba os outros; pasta com nome de PDF; ocr s\u00f3 TRUE ou FALSE", {
  skip_if_not_installed("pdftools")
  estragado = tempfile(fileext = ".pdf")
  writeLines("isto n\u00e3o \u00e9 um PDF", estragado)
  pasta = file.path(tempdir(), "uma_pasta.pdf")
  dir.create(pasta, showWarnings = FALSE)
  extraidas = suppressWarnings(chave_extrair(c(estragado, pasta)))
  expect_match(extraidas$problema[1], "^o arquivo n\u00e3o abriu: ")
  expect_identical(extraidas$problema[2], "arquivo n\u00e3o encontrado")
  expect_error(chave_extrair(estragado, ocr = NA), "ocr")
  unlink(pasta, recursive = TRUE)
})

test_that("o TIFF de duas p\u00e1ginas, com o QR-Code na segunda", {
  skip_if_not_installed("opencv")
  skip_if_not_installed("magick")
  qrcode = magick::image_read(imagem_de_teste("qrcode_nfce.png"))
  em_branco = magick::image_blank(magick::image_info(qrcode)$width, magick::image_info(qrcode)$height, "white")
  tiff = tempfile(fileext = ".tif")
  magick::image_write(c(em_branco, qrcode), tiff, format = "tiff")
  extraida = chave_extrair(tiff, ocr = FALSE)
  expect_identical(extraida$chave, CHAVE_DAS_IMAGENS)
  expect_identical(extraida$origem, "QR-Code")
})

test_that("a chave pelo texto do PDF", {
  skip_if_not_installed("pdftools")
  pdf = tempfile(fileext = ".pdf")
  grDevices::pdf(pdf)
  graphics::par(mar = c(0, 0, 0, 0))
  graphics::plot.new()
  graphics::text(0.5, 0.5, "Chave 2626 1011 2223 3300 0181 6500 1000 0010 0111 2345 6789", cex = 0.8)
  grDevices::dev.off()
  extraida = chave_extrair(pdf)
  expect_identical(extraida$chave, CHAVE_DAS_IMAGENS)
  expect_identical(extraida$origem, "texto do PDF")
  expect_true(is.na(extraida$problema))
})

test_that("a chave pelo QR-Code, com o texto dele", {
  skip_if_not_installed("opencv")
  extraida = chave_extrair(imagem_de_teste("qrcode_nfce.png"))
  expect_identical(extraida$chave, CHAVE_DAS_IMAGENS)
  expect_identical(extraida$origem, "QR-Code")
  expect_identical(extraida$qrcode, paste0("https://nfce.sefaz.pe.gov.br/nfce/consulta?p=", CHAVE_DAS_IMAGENS,
                                           "|2|2|1|ABCDEF0123456789ABCDEF0123456789ABCDEF01"))
})

test_that("a chave impressa, por OCR; a que n\u00e3o confere fica em problema", {
  skip_if_not_installed("tesseract")
  extraidas = chave_extrair(imagem_de_teste(c("cupom_com_a_chave.png", "cupom_com_a_chave_errada.png")))
  expect_identical(extraidas$chave, c(CHAVE_DAS_IMAGENS, NA))
  expect_identical(extraidas$origem, c("OCR", NA))
  expect_match(extraidas$problema[2], "^nenhuma chave que confere; com cara de chave, mas n\u00e3o confere")
  expect_match(extraidas$problema[2], "26261011222333000181650010000010011123456780", fixed = TRUE)
  # Sem o OCR, a imagem impressa fica sem chave.
  expect_match(chave_extrair(imagem_de_teste("cupom_com_a_chave.png"), ocr = FALSE)$problema, "^nenhuma chave que confere")
})

test_that("arquivo que n\u00e3o existe, que n\u00e3o \u00e9 PDF nem imagem, e nenhum arquivo", {
  texto = tempfile(fileext = ".txt")
  writeLines("2626 1011 2223 3300 0181 6500 1000 0010 0111 2345 6789", texto)
  extraidas = chave_extrair(c("nao_existe.pdf", texto))
  expect_identical(extraidas$problema, c("arquivo n\u00e3o encontrado", "n\u00e3o \u00e9 PDF nem imagem"))
  expect_true(all(is.na(extraidas$chave)))
  vazia = chave_extrair(character())
  expect_identical(nrow(vazia), 0L)
  expect_identical(names(vazia), c("arquivo", "chave", "origem", "qrcode", "problema"))
})
