# O exemplo efd_icms_ipi_sp.txt foi gerado por ferramentas/gerar_efd_de_exemplo.py, pelo leiaute: outubro de 2026, a
# venda da nota 1001 do nfe_proc_sp.xml e uma compra com o item, em Latin-1 e com CR LF.
EFD_DE_EXEMPLO = system.file("exemplos", "efd_icms_ipi_sp.txt", package = "RNFe")

# Um arquivo de janeiro de 2016 (leiaute 010), em texto: o C170 tinha 37 campos (o VL_ABAT_NT entrou em 2019) e o
# E310, a versão antiga.
linhas_de_2016 = function(...) {
  paste(c("|0000|010|0|01012016|31012016|EMPRESA DE TESTE LTDA|11222333000181||SP|123456789012|3550308|||A|1|",
          "|C001|0|",
          paste0("|C100|0|1|P001|55|00|1|555|33261011444777000161550010000005551876543218|10012016|12012016|100,00|1|",
                 "0,00|0,00|100,00|1|0,00|0,00|0,00|100,00|12,00|0,00|0,00|0,00|0,00|0,00|0,00|0,00|"),
          ..., "|9999|9|"), collapse = "\r\n")
}
ITEM_DE_2016 = "|C170|1|001||20|UN|100,00|0,00|0|000|2102||100,00|12,00|12,00|0,00|0,00|0,00|||||||50|100,00|1,6500|||1,65|50|100,00|7,6000|||7,60||"

test_that("o exemplo: as tabelas de cada registro, nos tipos do leiaute", {
  efd = efd_icms_ipi_ler(EFD_DE_EXEMPLO)
  expect_identical(efd$arquivos$inicio, as.Date("2026-10-01"))
  expect_identical(efd$arquivos$fim, as.Date("2026-10-31"))
  expect_identical(c(efd$arquivos$versao, efd$arquivos$linhas), c("020", "77"))
  expect_true(is.na(efd$arquivos$problema))
  expect_identical(nrow(efd$problemas), 0L)
  expect_identical(names(efd)[1:4], c("arquivos", "problemas", "0000", "0001"))
  expect_identical(names(efd)[length(names(efd))], "9999")
  nota = efd$C100[efd$C100$IND_OPER == "1", ]
  expect_identical(nota$NUM_DOC, "1001")
  expect_identical(nota$CHV_NFE, "35261011222333000181550010000010011123456785")
  expect_identical(nota$DT_DOC, as.Date("2026-10-15"))
  expect_identical(c(nota$VL_DOC, nota$VL_ICMS, nota$VL_IPI), c(115, 6, 5))
  expect_identical(names(efd$C100)[1:4], c("arquivo", "linha", "linha_pai", "REG"))
  # O texto fica com os zeros: o CST, o CFOP, o tipo do item.
  expect_identical(efd$C190$CST_ICMS, c("000", "060", "000"))
  expect_identical(efd$`0200`$TIPO_ITEM, c("00", "00"))
  # O Latin-1 do arquivo vira UTF-8.
  expect_identical(efd$`0200`$DESCR_ITEM[1], "\u00c1GUA MINERAL DE TESTE 500 ML")
  # O mesmo nome duas vezes no C170: cada um com o número do campo.
  expect_identical(c(efd$C170$ALIQ_PIS_27, efd$C170$ALIQ_PIS_29), c(1.65, NA))
  expect_false("ALIQ_PIS" %in% names(efd$C170))
  # O vazio fica NA.
  expect_true(is.na(efd$`0000`$CPF))
})

test_that("cada registro liga ao de n\u00edvel acima pela linha", {
  efd = efd_icms_ipi_ler(EFD_DE_EXEMPLO)
  compra = efd$C100[efd$C100$IND_OPER == "0", ]
  expect_identical(efd$C170$linha_pai, compra$linha)
  expect_identical(efd$C190$linha_pai, c(rep(efd$C100$linha[1], 2), compra$linha))
  expect_identical(unique(efd$C100$linha_pai), efd$C001$linha)
  expect_identical(efd$C001$linha_pai, efd$`0000`$linha)
  expect_true(is.na(efd$`0000`$linha_pai))
  # As contagens do bloco 9 conferem com as tabelas.
  contagem = efd$`9900`
  for (registro in c("C100", "C170", "C190", "0200")) {
    expect_identical(as.integer(contagem$QTD_REG_BLC[contagem$REG_BLC == registro]), nrow(efd[[registro]]))
  }
  expect_identical(as.integer(efd$`9999`$QTD_LIN), efd$arquivos$linhas)
})

test_that("s\u00f3 os registros pedidos, e o texto do arquivo no lugar do caminho", {
  pedidos = efd_icms_ipi_ler(EFD_DE_EXEMPLO, registros = c("C100", "C170"))
  expect_identical(names(pedidos), c("arquivos", "problemas", "C100", "C170"))
  texto = paste(readLines(EFD_DE_EXEMPLO, encoding = "latin1"), collapse = "\n")
  pelo_texto = efd_icms_ipi_ler(texto, registros = "C100")
  expect_identical(pelo_texto$arquivos$arquivo, "(texto 1)")
  expect_identical(pelo_texto$C100$NUM_DOC, c("1001", "555"))
  expect_error(efd_icms_ipi_ler(EFD_DE_EXEMPLO, registros = "C999"), "C999")
  expect_error(efd_icms_ipi_ler(EFD_DE_EXEMPLO, registros = NA), "registros")
})

test_that("a assinatura depois do 9999 e o arquivo em UTF-8", {
  bytes = readBin(EFD_DE_EXEMPLO, "raw", file.size(EFD_DE_EXEMPLO))
  assinado = withr::local_tempfile(fileext = ".txt")
  writeBin(c(bytes, as.raw(c(0x53, 0x42, 0x52, 0x43, 0x00, 0x01, 0xff, 0x00, 0x7c))), assinado)
  efd = efd_icms_ipi_ler(assinado)
  expect_identical(efd$arquivos$linhas, 77L)
  expect_identical(nrow(efd$problemas), 0L)
  em_utf8 = withr::local_tempfile(fileext = ".txt")
  writeBin(charToRaw(iconv(rawToChar(bytes), "latin1", "UTF-8")), em_utf8)
  expect_identical(efd_icms_ipi_ler(em_utf8)$`0200`$DESCR_ITEM[1], "\u00c1GUA MINERAL DE TESTE 500 ML")
})

test_that("o arquivo antigo pelo leiaute do per\u00edodo dele", {
  antigo = efd_icms_ipi_ler(linhas_de_2016(ITEM_DE_2016, "|E310|0|0,00|0,00|0,00|0,00|0,00|0,00|0,00|0,00|0,00|0,00|0,00|0,00|"))
  expect_identical(nrow(antigo$problemas), 0L)
  expect_identical(antigo$C170$VL_ITEM, 100)
  expect_false("VL_ABAT_NT" %in% names(antigo$C170))
  # O E310 de 2016 é a versão antiga, com outros campos.
  expect_true(all(c("IND_MOV_DIFAL", "VL_RECOL", "DEB_ESP_DIFAL") %in% names(antigo$E310)))
  expect_false("IND_MOV_FCP_DIFAL" %in% names(antigo$E310))
  # Com o arquivo de 2026, o C170 junta os dois, e o campo que não existia em 2016 fica vazio.
  juntos = efd_icms_ipi_ler(c(EFD_DE_EXEMPLO, linhas_de_2016(ITEM_DE_2016)), registros = "C170")
  expect_identical(juntos$C170$VL_ABAT_NT, c(0, NA))
})

test_that("o que n\u00e3o p\u00f4de ser lido vai para os problemas, com o motivo", {
  com_campo_a_mais = sub("\\|$", "|0,00|", ITEM_DE_2016)
  com_valor_errado = sub("|100,00|0,00|0|000|", "|1OO,00|0,00|0|000|", ITEM_DE_2016, fixed = TRUE)
  nota_de_2016 = strsplit(linhas_de_2016(), "\r\n", fixed = TRUE)[[1]][3]
  com_data_errada = sub("|555|33261011444777000161550010000005551876543218|10012016|", "|556||32012016|", nota_de_2016,
                        fixed = TRUE)
  efd = efd_icms_ipi_ler(linhas_de_2016(com_campo_a_mais, com_valor_errado, com_data_errada, "|D700|1|", "linha solta"))
  problemas = efd$problemas
  expect_match(problemas$problema[problemas$linha == 4], "38 campos; o leiaute do per\u00edodo do arquivo tem 37")
  expect_identical(problemas$campo[problemas$linha == 5], "VL_ITEM")
  expect_match(problemas$problema[problemas$linha == 5], "1OO,00")
  expect_true(is.na(efd$C170$VL_ITEM))
  expect_identical(problemas$campo[problemas$linha == 6], "DT_DOC")
  # O D700 entrou em 2023: num arquivo de 2016 o leiaute não o tem.
  expect_match(problemas$problema[problemas$linha == 7], "n\u00e3o tem o registro")
  expect_match(problemas$problema[problemas$linha == 8], "fora do formato|n\u00e3o est\u00e1 no formato")
})

test_that("o arquivo que n\u00e3o \u00e9 uma EFD", {
  outro = withr::local_tempfile(fileext = ".txt")
  writeLines(c("|C100|0|", "|9999|2|"), outro)
  lidos = efd_icms_ipi_ler(c(outro, "nao_existe.txt", ""))
  expect_match(lidos$arquivos$problema[1], "registro 0000")
  expect_identical(lidos$arquivos$problema[2:3], c("arquivo n\u00e3o encontrado", "vazio"))
  expect_identical(names(lidos), c("arquivos", "problemas"))
})

test_that("o leiaute: os registros, as vers\u00f5es e a vig\u00eancia de cada campo", {
  leiaute = tabela_fiscal("leiaute_efd_icms_ipi")
  expect_identical(names(leiaute), c("registro", "inicio", "fim", "nivel", "numero", "campo", "coluna", "tipo", "tamanho",
                                     "decimais", "descricao"))
  expect_s3_class(leiaute$inicio, "Date")
  # Todo registro começa pelo REG, e nenhum nome de coluna se repete no mesmo registro e na mesma versão.
  primeiros = leiaute[leiaute$numero == "01", ]
  expect_true(all(primeiros$campo == "REG"))
  versao = paste(leiaute$registro, leiaute$fim)
  expect_false(anyDuplicated(paste(versao, leiaute$coluna)) > 0)
  # Conferido com o Guia Prático 3.2.2: o C100 de hoje tem 29 campos, e o VL_MERC (que a NT 2025.001 não traz) é o 16.
  c100 = leiaute[leiaute$registro == "C100", ]
  expect_identical(nrow(c100), 29L)
  expect_identical(c100$campo[c100$numero == "16"], "VL_MERC")
  # O VL_ABAT_NT do C170 entrou em 2019; o D700, em 2023; o E310 e o C177 têm a versão antiga, com o fim.
  expect_identical(leiaute$inicio[leiaute$registro == "C170" & leiaute$campo == "VL_ABAT_NT"], as.Date("2019-01-01"))
  expect_true(all(leiaute$inicio[leiaute$registro == "D700"] >= as.Date("2023-01-01")))
  expect_identical(sort(unique(leiaute$fim[leiaute$registro %in% c("E310", "C177")])),
                   as.Date(c("2016-12-31", "2018-12-31")))
  expect_identical(leiaute$coluna[leiaute$registro == "C170" & leiaute$campo == "ALIQ_PIS"], c("ALIQ_PIS_27", "ALIQ_PIS_29"))
  expect_true(all(leiaute$tipo %in% c("C", "N")))
})

test_that("o arquivo em UTF-8 com a marca de ordem dos bytes (BOM) \u00e9 lido", {
  linhas = readLines(system.file("exemplos", "efd_icms_ipi_sp.txt", package = "RNFe"), encoding = "latin1")
  arquivo = tempfile(fileext = ".txt")
  conexao = file(arquivo, "wb")
  writeBin(as.raw(c(0xef, 0xbb, 0xbf)), conexao)
  writeBin(charToRaw(enc2utf8(paste(linhas, collapse = "\r\n"))), conexao)
  close(conexao)
  lida = efd_icms_ipi_ler(arquivo, registros = c("0000", "0150"))
  expect_true(is.na(lida$arquivos$problema))
  expect_identical(lida$`0150`$NOME, "DESTINAT\u00c1RIO DE TESTE LTDA")
})
