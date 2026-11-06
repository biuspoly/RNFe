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
  # O indDest 0: o destinatário é o próprio tomador (a nota 3 da NT 008).
  expect_match(texto, "O DESTINAT\u00c1RIO \u00c9 O PR\u00d3PRIO TOMADOR/ADQUIRENTE DA OPERA\u00c7\u00c3O", fixed = TRUE)
  expect_match(texto, "Federais: 10,00%; Estaduais: 0,00%; Municipais: 2,00%", fixed = TRUE)
  # As máscaras da NT 008: o código de tributação (nn.nn.nn), o CEP (nn.nnn-nnn) e o município do cabeçalho.
  expect_match(texto, "01.05.01", fixed = TRUE)
  expect_match(texto, "3550308 / 01.001-000", fixed = TRUE)
  expect_match(texto, "Munic\u00edpio: S\u00e3o Paulo / SP", fixed = TRUE)
  expect_match(texto, "100301 / 3550308 / S\u00e3o Paulo / SP", fixed = TRUE)
})

test_that("o DANFSe: o benef\u00edcio municipal e as dedu\u00e7\u00f5es dos lugares da tabela da NT 008", {
  skip_if_not_installed("pdftools")
  skip_if_not_installed("qrcode")
  nota = paste(readLines(system.file("exemplos", "nfse_sp_v101.xml", package = "RNFe"), encoding = "UTF-8"), collapse = "\n")
  # O tpBM e o vCalcBM ficam nos valores da NFS-e (o infNFSe), não nos da DPS.
  nota = sub("<valores>\\s*<vBC>", "<valores><tpBM>2</tpBM><vCalcBM>100.00</vCalcBM><vBC>", nota, perl = TRUE)
  arquivo = tempfile(fileext = ".pdf")
  danfse_pdf(nota, arquivo)
  texto = texto_do_pdf(arquivo)
  expect_match(texto, "Redu\u00e7\u00e3o da BC em %", fixed = TRUE)
  expect_match(texto, "R$ 100,00", fixed = TRUE)
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
  texto_mei = texto_do_pdf(arquivo_mei)
  expect_match(texto_mei, "Federais: -; Estaduais: -; Municipais: -", fixed = TRUE)
  # Sem o grupo do IBS e da CBS, o leiaute não diz o destinatário.
  expect_match(texto_mei, "DESTINAT\u00c1RIO DA OPERA\u00c7\u00c3O N\u00c3O IDENTIFICADO NA NFS", fixed = TRUE)
  expect_error(danfse_pdf(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), tempfile(fileext = ".pdf")),
               "NFS-e Nacional")
})
