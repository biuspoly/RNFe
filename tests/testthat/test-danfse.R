texto_do_pdf = function(arquivo) {
  texto = paste(pdftools::pdf_text(arquivo), collapse = " ")
  gsub("\\s+", " ", gsub("\u00ad", "-", texto, fixed = TRUE))
}

# A marca d'água: o texto girado sai em pedaços; ficam os de letra grande, da esquerda para a direita.
marca_dagua_do_pdf = function(arquivo) {
  palavras = suppressMessages(pdftools::pdf_data(arquivo, font_info = TRUE)[[1]])
  da_marca = palavras[palavras$font_size > 50, ]
  paste(da_marca$text[order(da_marca$x)], collapse = "")
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

test_that("o DANFSe da nota no leiaute da NT 009: o destinat\u00e1rio, o CST e as dedu\u00e7\u00f5es somadas", {
  skip_if_not_installed("pdftools")
  skip_if_not_installed("qrcode")
  arquivo = tempfile(fileext = ".pdf")
  danfse_pdf(nfse_no_leiaute_da_nt_009(), arquivo)
  texto = texto_do_pdf(arquivo)
  # O indDest 0: o destinatário é o próprio tomador.
  expect_match(texto, "O DESTINAT\u00c1RIO \u00c9 O PR\u00d3PRIO TOMADOR/ADQUIRENTE DA OPERA\u00c7\u00c3O", fixed = TRUE)
  expect_match(texto, "000 / 000001", fixed = TRUE)
  # A base do ISSQN desconta o vAjusteBCISSQN e o vCalcAjusteBCISSQN somados (100 + 100, item 2.3).
  expect_match(texto, "R$ 200,00", fixed = TRUE)
  # O destinatário que não é o tomador: com o grupo dest no IBSCBS (o XSD) e no infDPS (o texto do item 2.11).
  for (nota_com_destinatario in c(nfse_da_nt_009_com_destinatario(), nfse_da_nt_009_com_destinatario_no_infdps())) {
    arquivo_com_destinatario = tempfile(fileext = ".pdf")
    danfse_pdf(nota_com_destinatario, arquivo_com_destinatario)
    texto_com_destinatario = texto_do_pdf(arquivo_com_destinatario)
    expect_match(texto_com_destinatario, "DESTINATARIO DE TESTE", fixed = TRUE)
    expect_match(texto_com_destinatario, "11.444.777/0001-61", fixed = TRUE)
    expect_false(grepl("DESTINAT\u00c1RIO DA OPERA\u00c7\u00c3O N\u00c3O IDENTIFICADO", texto_com_destinatario, fixed = TRUE))
  }
  # A inscrição de cada unidade imobiliária do imóvel (o gUnidImob da NT 009).
  arquivo_com_imoveis = tempfile(fileext = ".pdf")
  danfse_pdf(nfse_da_nt_009_com_imoveis(), arquivo_com_imoveis)
  expect_match(texto_do_pdf(arquivo_com_imoveis), "Insc. Imob.: 0001112223, 0004445556", fixed = TRUE)
})

test_that("o DANFSe da NT 008 v1.02: as datas do XML, a marca d'\u00e1gua, o PIS e a COFINS retidos e os itens do pedido", {
  skip_if_not_installed("pdftools")
  skip_if_not_installed("qrcode")
  exemplo = system.file("exemplos", "nfse_sp_v101.xml", package = "RNFe")
  nota = paste(readLines(exemplo, encoding = "UTF-8"), collapse = "\n")
  texto = texto_do_pdf(danfse_pdf(exemplo, tempfile(fileext = ".pdf")))
  expect_match(texto, "20/10/2026 10:00:05", fixed = TRUE)
  expect_match(texto, "20/10/2026 10:00:00", fixed = TRUE)
  # A data e a hora como estão no XML (o campo representa o conteúdo da tag), mesmo noutro fuso: no horário de
  # Brasília, o processamento em UTC seria 19/10/2026 21:30:05.
  em_utc = sub("<dhProc>2026-10-20T10:00:05-03:00</dhProc>", "<dhProc>2026-10-20T00:30:05+00:00</dhProc>", nota,
               fixed = TRUE)
  texto_em_utc = texto_do_pdf(danfse_pdf(em_utc, tempfile(fileext = ".pdf")))
  expect_match(texto_em_utc, "20/10/2026 00:30:05", fixed = TRUE)
  expect_false(grepl("21:30:05", texto_em_utc, fixed = TRUE))
  # O PIS e a COFINS de apuração própria (tpRetPisCofins 2), e as retidas sem a CSLL: o traço.
  expect_match(texto, "Contribui\u00e7\u00f5es Sociais - Retidas R$ 15,00 - -", fixed = TRUE)
  expect_match(texto, "Descri\u00e7\u00e3o Contrib. Sociais - Retidas R$ 6,50 R$ 30,00", fixed = TRUE)
  expect_identical(marca_dagua_do_pdf(danfse_pdf(exemplo, tempfile(fileext = ".pdf"))), "")
  # A marca d'água da nota cancelada e da substituída; outra situação é recusada.
  expect_identical(marca_dagua_do_pdf(danfse_pdf(exemplo, tempfile(fileext = ".pdf"), situacao = "cancelada")),
                   "CANCELADA")
  expect_identical(marca_dagua_do_pdf(danfse_pdf(exemplo, tempfile(fileext = ".pdf"), situacao = "substituida")),
                   "SUBSTITU\u00cdDA")
  expect_error(danfse_pdf(exemplo, tempfile(fileext = ".pdf"), situacao = "anulada"), "situa\u00e7\u00e3o")
  # Retidos (tpRetPisCofins 1): as retidas somam o PIS e a COFINS (6,50 + 30,00), e os próprios saem zerados.
  retidos = sub("<tpRetPisCofins>2</tpRetPisCofins>", "<tpRetPisCofins>1</tpRetPisCofins>", nota, fixed = TRUE)
  texto_retidos = texto_do_pdf(danfse_pdf(retidos, tempfile(fileext = ".pdf")))
  expect_match(texto_retidos, "Contribui\u00e7\u00f5es Sociais - Retidas R$ 15,00 - R$ 36,50", fixed = TRUE)
  expect_match(texto_retidos, "Descri\u00e7\u00e3o Contrib. Sociais - Retidas R$ 0,00 R$ 0,00 PIS e COFINS retidos",
               fixed = TRUE)
  # Nos outros códigos, o valor informado (a NT diz "= 1" e "nos demais casos"); a descrição, no tamanho do campo (35).
  codigo_4 = sub("<tpRetPisCofins>2</tpRetPisCofins>", "<tpRetPisCofins>4</tpRetPisCofins>", nota, fixed = TRUE)
  descricao_do_4 = "PIS e COFINS retidos, CSLL n\u00e3o retida"
  expect_gt(nchar(descricao_do_4), 35)
  texto_do_4 = texto_do_pdf(danfse_pdf(codigo_4, tempfile(fileext = ".pdf")))
  expect_match(texto_do_4, paste("R$ 6,50 R$ 30,00", paste0(substr(descricao_do_4, 1, 32), "...")), fixed = TRUE)
  # Os itens do pedido (gItemPed): todos, separados por vírgula.
  com_itens = sub("</xPed>", "</xPed><gItemPed><xItemPed>10</xItemPed><xItemPed>20</xItemPed></gItemPed>", nota,
                  fixed = TRUE)
  expect_match(texto_do_pdf(danfse_pdf(com_itens, tempfile(fileext = ".pdf"))), "Item Ped.: 10, 20", fixed = TRUE)
})

test_that("o DANFSe: o texto que passa do tamanho da NT leva retic\u00eancias", {
  skip_if_not_installed("pdftools")
  skip_if_not_installed("qrcode")
  expect_identical(conteudo_do_danfse(strrep("A", 80), 77), paste0(strrep("A", 77), "..."))
  expect_identical(conteudo_do_danfse(strrep("A", 77), 77), strrep("A", 77))
  # No campo que só traz o tamanho, o texto com as reticências cabe nele.
  expect_identical(conteudo_do_danfse(strrep("A", 40), tamanho = 35), paste0(strrep("A", 32), "..."))
  expect_identical(conteudo_do_danfse(strrep("A", 35), tamanho = 35), strrep("A", 35))
  expect_identical(conteudo_do_danfse(NA), "-")
  # A largura do texto se mede num dispositivo gráfico: um vazio, para não gravar o Rplots.pdf.
  grDevices::pdf(NULL)
  com_reticencias = tryCatch(linhas_com_reticencias(c("um", "dois", "tres"), 2, 20), finally = grDevices::dev.off())
  expect_identical(com_reticencias, c("um", "dois..."))
  expect_identical(linhas_com_reticencias(c("um", "dois"), 2, 20), c("um", "dois"))
  nota = paste(readLines(system.file("exemplos", "nfse_sp_v101.xml", package = "RNFe"), encoding = "UTF-8"),
               collapse = "\n")
  # A descrição do serviço vai até 1297 caracteres (76 vezes a frase de 17, e o começo da seguinte; só pelas 12 linhas,
  # caberiam 96); o nome, até 77, com letras estreitas, que cabem no quadro.
  descricao_longa = trimws(strrep("SERVICO DE TESTE ", 100))
  longa = sub("LICENCA DE USO DE SOFTWARE DE TESTE", descricao_longa, nota, fixed = TRUE)
  longa = sub("<xNome>EMPRESA DE TESTE LTDA</xNome>", paste0("<xNome>", strrep("l", 90), "</xNome>"), longa, fixed = TRUE)
  texto = texto_do_pdf(danfse_pdf(longa, tempfile(fileext = ".pdf")))
  expect_match(texto, paste0(" ", strrep("l", 77), "... "), fixed = TRUE)
  expect_false(grepl(strrep("l", 78), texto, fixed = TRUE))
  expect_match(texto, "TESTE SERVI...", fixed = TRUE)
  vezes_da_descricao = lengths(regmatches(texto, gregexpr("SERVICO DE TESTE", texto, fixed = TRUE)))
  expect_identical(vezes_da_descricao, 76L)
})

test_that("a logomarca da NFS-e: no tamanho m\u00ednimo da NT, sem deformar, antes do quadro seguinte", {
  logomarca = readRDS(system.file("extdata", "logo_nfse.rds", package = "RNFe"))
  expect_s3_class(logomarca, "raster")
  # O quadro do Anexo I (4,00 cm por 0,85 cm) é o mínimo: na altura dele, a largura passa de 4,00 e acaba antes de 5,41.
  largura_na_altura_minima = 0.85 * ncol(logomarca) / nrow(logomarca)
  expect_gte(largura_na_altura_minima, 4.00)
  expect_lte(0.49 + largura_na_altura_minima, 5.41)
  expect_gte(nrow(logomarca), 100)
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
