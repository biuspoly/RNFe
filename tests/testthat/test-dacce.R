test_that("a carta de corre\u00e7\u00e3o da NF-e: a chave, o protocolo, a corre\u00e7\u00e3o e as condi\u00e7\u00f5es de uso", {
  skip_if_not_installed("pdftools")
  arquivo = tempfile(fileext = ".pdf")
  expect_identical(dacce_pdf(system.file("exemplos", "evento_nfe_carta_correcao.xml", package = "RNFe"), arquivo), arquivo)
  expect_identical(pdftools::pdf_info(arquivo)$pages, 1L)
  texto = gsub("\\s+", " ", gsub("\u00ad", "-", pdftools::pdf_text(arquivo), fixed = TRUE))
  expect_match(texto, "CARTA DE CORRE\u00c7\u00c3O ELETR\u00d4NICA", fixed = TRUE)
  expect_match(texto, "2326 1012 ABC3 4501 DE35 5500 2000 0000 4218 7654 3213", fixed = TRUE)
  expect_match(texto, "323260000006789", fixed = TRUE)
  expect_match(texto, "135 - Evento registrado e vinculado a NF-e", fixed = TRUE)
  expect_match(texto, "LEIA-SE RUA DO CLIENTE, 100", fixed = TRUE)
  # O ";" das condições de uso fica no texto: nenhum manual manda quebrar a linha nele.
  expect_match(texto, "prestacao; II", fixed = TRUE)
  expect_match(texto, "Homologa\u00e7\u00e3o", fixed = TRUE)
})

test_that("a carta de corre\u00e7\u00e3o do CT-e, em tabela, e sem o retorno da SEFAZ", {
  skip_if_not_installed("pdftools")
  carta = paste0(
    '<procEventoCTe versao="4.00" xmlns="http://www.portalfiscal.inf.br/cte"><eventoCTe versao="4.00">',
    '<infEvento Id="ID1101103526101122233300018157001000000123112345678001"><cOrgao>35</cOrgao><tpAmb>2</tpAmb>',
    '<CNPJ>11222333000181</CNPJ><chCTe>35261011222333000181570010000001231123456780</chCTe>',
    '<dhEvento>2026-10-21T10:00:00-03:00</dhEvento><tpEvento>110110</tpEvento><nSeqEvento>1</nSeqEvento>',
    '<detEvento versaoEvento="4.00"><evCCeCTe><descEvento>Carta de Correcao</descEvento>',
    '<infCorrecao><grupoAlterado>infQ</grupoAlterado><campoAlterado>tpMed</campoAlterado>',
    '<valorAlterado>PESO BRUTO</valorAlterado><nroItemAlterado>1</nroItemAlterado></infCorrecao>',
    '<xCondUso>A Carta de Correcao e disciplinada pelo Art. 58-B do CONVENIO/SINIEF 06/89.</xCondUso>',
    '</evCCeCTe></detEvento></infEvento></eventoCTe></procEventoCTe>')
  arquivo = tempfile(fileext = ".pdf")
  dacce_pdf(carta, arquivo)
  texto = gsub("\\s+", " ", gsub("\u00ad", "-", pdftools::pdf_text(arquivo), fixed = TRUE))
  expect_match(texto, "Corre\u00e7\u00e3o do CT-e", fixed = TRUE)
  expect_match(texto, "GRUPO ALTERADO", fixed = TRUE)
  expect_match(texto, "tpMed", fixed = TRUE)
  expect_match(texto, "PESO BRUTO", fixed = TRUE)
  expect_match(texto, "Sem o retorno da SEFAZ", fixed = TRUE)
  expect_error(dacce_pdf(system.file("exemplos", "evento_nfe_cancelamento.xml", package = "RNFe"), tempfile(fileext = ".pdf")),
               "110110")
})
