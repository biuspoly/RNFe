texto_do_pdf = function(arquivo) {
  texto = paste(pdftools::pdf_text(arquivo), collapse = " ")
  gsub("\\s+", " ", gsub("\u00ad", "-", texto, fixed = TRUE))
}

test_that("o DANFSe v2.0: uma folha, o QR-Code da consulta, os blocos e a marca da Produ\u00e7\u00e3o Restrita", {
  skip_if_not_installed("pdftools")
  skip_if_not_installed("qrcode")
  arquivo = tempfile(fileext = ".pdf")
  expect_identical(danfse_pdf(system.file("exemplos", "nfse_sp_v101.xml", package = "RNFe"), arquivo), arquivo)
  expect_identical(pdftools::pdf_info(arquivo)$pages, 1L)
  texto = texto_do_pdf(arquivo)
  expect_match(texto, "DANFSe v2.0", fixed = TRUE)
  expect_match(texto, "SEM VALIDADE JUR\u00cdDICA", fixed = TRUE)
  expect_match(texto, "35503082211222333000181000000000012326101234567898", fixed = TRUE)
  expect_match(texto, "11.222.333/0001-81", fixed = TRUE)
  expect_match(texto, "S\u00e3o Paulo / SP", fixed = TRUE)
  expect_match(texto, "R$ 1.010,00", fixed = TRUE)
  # As exclusões da base do IBS e da CBS: o ISSQN, o PIS e a COFINS da nota (20 + 6,50 + 30).
  expect_match(texto, "R$ 56,50", fixed = TRUE)
  expect_match(texto, "DESTINAT\u00c1RIO DA OPERA\u00c7\u00c3O N\u00c3O IDENTIFICADO NA NFS", fixed = TRUE)
  expect_match(texto, "Federais: 10,00%; Estaduais: 0,00%; Municipais: 2,00%", fixed = TRUE)
})

test_that("o DANFSe sem tomador e sem ISSQN: as linhas \u00fanicas da NT 008", {
  skip_if_not_installed("pdftools")
  skip_if_not_installed("qrcode")
  nota = paste(readLines(system.file("exemplos", "nfse_sp_v101.xml", package = "RNFe"), encoding = "UTF-8"), collapse = "\n")
  nota = sub("(?s)<toma>.*</toma>", "", nota, perl = TRUE)
  nota = sub("<tribISSQN>1</tribISSQN>", "<tribISSQN>4</tribISSQN>", nota, fixed = TRUE)
  arquivo = tempfile(fileext = ".pdf")
  danfse_pdf(nota, arquivo)
  texto = texto_do_pdf(arquivo)
  expect_match(texto, "TOMADOR/ADQUIRENTE DA OPERA\u00c7\u00c3O N\u00c3O IDENTIFICADO NA NFS", fixed = TRUE)
  expect_match(texto, "OPERA\u00c7\u00c3O N\u00c3O SUJEITA AO ISSQN", fixed = TRUE)
  # A nota do MEI, sem o IBS e a CBS: os campos sem valor levam o traço.
  arquivo_mei = tempfile(fileext = ".pdf")
  danfse_pdf(system.file("exemplos", "nfse_ce_mei_v100.xml", package = "RNFe"), arquivo_mei)
  expect_match(texto_do_pdf(arquivo_mei), "Federais: -; Estaduais: -; Municipais: -", fixed = TRUE)
  expect_error(danfse_pdf(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), tempfile(fileext = ".pdf")),
               "NFS-e Nacional")
})
