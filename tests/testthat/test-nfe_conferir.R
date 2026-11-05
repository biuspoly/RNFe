# O texto de um XML de exemplo do pacote, para os testes mudarem um campo.
xml_do_exemplo = function(nome) {
  paste(readLines(system.file("exemplos", nome, package = "RNFe"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
}

# Troca um trecho do XML, e o teste para se o trecho não estiver lá (a troca não teria efeito).
trocar = function(texto, antigo, novo) {
  stopifnot(grepl(antigo, texto, fixed = TRUE))
  sub(antigo, novo, texto, fixed = TRUE)
}

linhas_da_regra_conferida = function(conferencias, regra) {
  conferencias[conferencias$regra == regra, ]
}

test_that("os exemplos: a nota de SP acusa o cNF e o intermediador, e as outras passam", {
  exemplos = system.file("exemplos", c("nfe_proc_sp.xml", "nfce_ce_contingencia.xml", "nfe_ce_simples_cpf.xml"),
                         package = "RNFe")
  # O momento do envio fixo: a nota do CE não tem protocolo, e a B09-20 depende de quanto ela atrasou.
  resultado = nfe_conferir(exemplos, agora = as.POSIXct("2026-10-25 12:00:00", tz = "America/Sao_Paulo"))
  expect_equal(resultado$notas$regras_erradas, c(2L, 0L, 0L))
  expect_equal(resultado$notas$regras_sem_conferir, c(0L, 0L, 0L))
  expect_true(all(resultado$notas$regras_conferidas > 50))
  expect_true(all(resultado$notas$schema_valido))
  expect_true(all(resultado$notas$assinada))
  expect_equal(nrow(resultado$schema), 0)
  expect_setequal(resultado$conferencias$regra, c("B03-10", "B25c-10"))
  b03 = linhas_da_regra_conferida(resultado$conferencias, "B03-10")
  expect_equal(b03$no_documento, "12345678")
  expect_equal(b03$codigo_sefaz, "897")
  expect_equal(b03$aplicacao, "obrigat\u00f3ria")
  expect_equal(resultado$arquivos$notas, c(1L, 1L, 1L))
})

test_that("a mesma nota em dois arquivos \u00e9 conferida uma vez, a do arquivo com o protocolo", {
  texto = xml_do_exemplo("nfe_proc_sp.xml")
  sem_protocolo = sub("(?s)<protNFe.*</protNFe>", "", texto, perl = TRUE)
  sem_protocolo = trocar(sem_protocolo, "<CFOP>6102</CFOP>", "<CFOP>61020</CFOP>")
  resultado = nfe_conferir(c(sem_protocolo, texto, texto))
  expect_equal(nrow(resultado$notas), 1)
  expect_equal(resultado$arquivos$notas, c(1L, 1L, 1L))
  # A escolhida é a do segundo arquivo: o schema dela confere, e as regras não saem repetidas.
  expect_true(resultado$notas$schema_valido)
  expect_equal(nrow(resultado$schema), 0)
  expect_setequal(resultado$conferencias$regra, c("B03-10", "B25c-10"))
  expect_equal(nrow(resultado$conferencias), 2)
})

test_that("a B03-10 compara o cNF com o nNF como texto (h\u00e1 NF-e autorizada com o cNF 00000856 e o nNF 856)", {
  texto = xml_do_exemplo("nfe_proc_sp.xml")
  zeros_a_esquerda = nfe_conferir(trocar(texto, "<cNF>12345678</cNF>", "<cNF>00001001</cNF>"), todas_as_regras = TRUE)
  expect_true(linhas_da_regra_conferida(zeros_a_esquerda$conferencias, "B03-10")$confere)
  igual = trocar(trocar(texto, "<cNF>12345678</cNF>", "<cNF>23456781</cNF>"), "<nNF>1001</nNF>", "<nNF>23456781</nNF>")
  expect_false(linhas_da_regra_conferida(nfe_conferir(igual)$conferencias, "B03-10")$confere)
})

test_that("o schema: o campo errado aparece, e a falta da assinatura n\u00e3o conta", {
  texto = xml_do_exemplo("nfe_proc_sp.xml")
  resultado = nfe_conferir(trocar(texto, "<CFOP>6102</CFOP>", "<CFOP>61020</CFOP>"))
  expect_false(resultado$notas$schema_valido)
  expect_equal(resultado$notas$erros_de_schema, 1L)
  expect_match(resultado$schema$mensagem, "CFOP")
  sem_assinatura = sub("(?s)<Signature.*</Signature>", "", texto, perl = TRUE)
  resultado = nfe_conferir(sem_assinatura)
  expect_false(resultado$notas$assinada)
  expect_true(resultado$notas$schema_valido)
  expect_equal(nrow(resultado$schema), 0)
})

test_that("a chave: o Id que n\u00e3o bate com os campos e o d\u00edgito errado", {
  texto = trocar(xml_do_exemplo("nfe_proc_sp.xml"), "<cDV>5</cDV>", "<cDV>4</cDV>")
  conferencias = nfe_conferir(texto)$conferencias
  expect_true(all(c("A03-10", "B23-10") %in% conferencias$regra))
  expect_equal(linhas_da_regra_conferida(conferencias, "B23-10")$esperado, "5")
})

test_that("os totais: a soma dos itens at\u00e9 o centavo e o valor da nota com R$ 0,50 de toler\u00e2ncia", {
  texto = xml_do_exemplo("nfe_proc_sp.xml")
  dentro = nfe_conferir(trocar(texto, "<vNF>115.00</vNF>", "<vNF>115.40</vNF>"), todas_as_regras = TRUE)$conferencias
  expect_true(linhas_da_regra_conferida(dentro, "W16-10")$confere)
  fora = nfe_conferir(trocar(texto, "<vNF>115.00</vNF>", "<vNF>116.00</vNF>"))$conferencias
  w16 = linhas_da_regra_conferida(fora, "W16-10")
  expect_false(w16$confere)
  expect_equal(w16$diferenca, 1)
  icms = nfe_conferir(trocar(texto, "<vICMS>6.00</vICMS>", "<vICMS>6.10</vICMS>"))$conferencias
  expect_equal(linhas_da_regra_conferida(icms, "W04-10")$diferenca, -0.1)
  n17 = linhas_da_regra_conferida(icms, "N17-20")
  expect_equal(n17$item, 1L)
  expect_equal(n17$esperado, "6.00")
})

test_that("a NF-e com DANFE Simplificado Tipo 2 segue as regras da NFC-e", {
  texto = trocar(xml_do_exemplo("nfe_proc_sp.xml"), "<tpImp>1</tpImp>", "<tpImp>6</tpImp>")
  conferencias = nfe_conferir(texto)$conferencias
  erradas = conferencias$regra[conferencias$confere %in% FALSE]
  expect_true(all(c("B10-10", "B11a-10", "B25a-10", "B25b-20", "I08-150", "N12-40", "N12-44", "O01-10", "X02-10",
                    "Y01-10", "ZX02-10") %in% erradas))
  expect_false(any(c("B25b-10", "ZX01-10") %in% conferencias$regra))
  sem_destinatario = sub("(?s)<dest>.*</dest>", "", texto, perl = TRUE)
  e01 = linhas_da_regra_conferida(nfe_conferir(sem_destinatario)$conferencias, "E01-10")
  expect_true(is.na(e01$confere))
  expect_match(e01$observacao, "2026.002")
})

test_that("a NFC-e n\u00e3o pode ter o grupo do IPI, e em homologa\u00e7\u00e3o o 1\u00ba item tem a descri\u00e7\u00e3o fixa", {
  texto = xml_do_exemplo("nfce_ce_contingencia.xml")
  com_ipi = trocar(texto, "</ICMS>", "</ICMS>\n<IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI>")
  o01 = linhas_da_regra_conferida(nfe_conferir(com_ipi)$conferencias, "O01-10")
  expect_equal(o01$item, 1L)
  expect_false(o01$confere)
  outra_descricao = trocar(texto, "<xProd>NOTA FISCAL EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL</xProd>",
                           "<xProd>PAO DE TESTE</xProd>")
  expect_true("I04-10" %in% nfe_conferir(outra_descricao)$conferencias$regra)
})

test_that("a regra vale como na data da emiss\u00e3o: a C17-10 sai e a C17-42 entra em 16/11/2026", {
  texto = trocar(xml_do_exemplo("nfce_ce_contingencia.xml"), "<IE>987654321</IE>", "")
  antes = nfe_conferir(texto, todas_as_regras = TRUE)$conferencias
  expect_false(linhas_da_regra_conferida(antes, "C17-10")$confere)
  expect_false("C17-42" %in% antes$regra)
  depois = trocar(texto, "<dhEmi>2026-10-21T19:12:40-03:00</dhEmi>", "<dhEmi>2026-11-20T19:12:40-03:00</dhEmi>")
  depois = nfe_conferir(depois, todas_as_regras = TRUE)$conferencias
  expect_false(linhas_da_regra_conferida(depois, "C17-42")$confere)
  expect_false("C17-10" %in% depois$regra)
})

test_that("os documentos referenciados: o d\u00edgito, a mesma chave, a repetida e a NF modelo 1 proibida", {
  texto = xml_do_exemplo("nfe_proc_sp.xml")
  referencias = paste0(
    "<verProc>RNFe-testes</verProc>\n",
    "<NFref><refNFe>35261011222333000181550010000010011123456780</refNFe></NFref>\n",
    "<NFref><refNFe>35261011222333000181550010000010011123456785</refNFe></NFref>\n",
    "<NFref><refNFe>35261011222333000181550010000010011123456785</refNFe></NFref>\n",
    "<NFref><refNF><cUF>35</cUF><AAMM>2601</AAMM><CNPJ>11222333000181</CNPJ><mod>01</mod><serie>1</serie>",
    "<nNF>10</nNF></refNF></NFref>"
  )
  conferencias = nfe_conferir(trocar(texto, "<verProc>RNFe-testes</verProc>", referencias))$conferencias
  erradas = conferencias[conferencias$confere %in% FALSE, ]
  expect_equal(linhas_da_regra_conferida(erradas, "BA02-10")$campo, "NFref[1]/refNFe")
  expect_equal(nrow(linhas_da_regra_conferida(erradas, "BA02-50")), 2)
  expect_equal(linhas_da_regra_conferida(erradas, "BA02-44")$campo, "NFref[3]/refNFe")
  expect_equal(linhas_da_regra_conferida(erradas, "BA03-10")$campo, "NFref[4]/refNF")
})

test_that("a NFC-e referenciada na NF-e de sa\u00edda s\u00f3 \u00e9 rejeitada a partir de 14/12/2026 (BA02-35)", {
  texto = trocar(xml_do_exemplo("nfe_proc_sp.xml"), "<verProc>RNFe-testes</verProc>", paste0(
    "<verProc>RNFe-testes</verProc>\n<NFref><refNFe>23261011444777000161650030000000779135724686</refNFe></NFref>"
  ))
  expect_false("BA02-35" %in% nfe_conferir(texto, todas_as_regras = TRUE)$conferencias$regra)
  em_dezembro = trocar(texto, "<dhEmi>2026-10-15T10:30:00-03:00</dhEmi>", "<dhEmi>2026-12-20T10:30:00-03:00</dhEmi>")
  ba02 = linhas_da_regra_conferida(nfe_conferir(em_dezembro)$conferencias, "BA02-35")
  expect_false(ba02$confere)
})

test_that("a regra que ficou mais r\u00edgida depois da emiss\u00e3o fica sem conferir, com o motivo", {
  texto = trocar(xml_do_exemplo("nfce_ce_contingencia.xml"), "<tPag>01</tPag>", "<tPag>91</tPag>")
  depois = linhas_da_regra_conferida(nfe_conferir(texto)$conferencias, "YA03-30")
  expect_false(depois$confere)
  antes = trocar(texto, "<dhEmi>2026-10-21T19:12:40-03:00</dhEmi>", "<dhEmi>2025-10-21T19:12:40-03:00</dhEmi>")
  antes = linhas_da_regra_conferida(nfe_conferir(antes)$conferencias, "YA03-30")
  expect_true(is.na(antes$confere))
  expect_match(antes$observacao, "mudou na NT 2025.001")
})

test_that("o NCM de antes do come\u00e7o da tabela fica sem conferir", {
  texto = trocar(xml_do_exemplo("nfe_proc_sp.xml"), "<dhEmi>2026-10-15T10:30:00-03:00</dhEmi>",
                 "<dhEmi>2021-10-15T10:30:00-03:00</dhEmi>")
  i05 = linhas_da_regra_conferida(nfe_conferir(texto, todas_as_regras = TRUE)$conferencias, "I05-20")
  expect_true(all(is.na(i05$confere)))
  expect_match(i05$observacao[1], "01/04/2022")
})

test_that("o momento do envio vale para a nota sem protocolo", {
  texto = sub("(?s)<protNFe.*</protNFe>", "", xml_do_exemplo("nfe_proc_sp.xml"), perl = TRUE)
  no_dia = nfe_conferir(texto, agora = as.POSIXct("2026-10-15 10:40:00", tz = "America/Sao_Paulo"),
                        todas_as_regras = TRUE)$conferencias
  expect_true(linhas_da_regra_conferida(no_dia, "B09-10")$confere)
  antes = nfe_conferir(texto, agora = as.POSIXct("2026-10-15 10:00:00", tz = "America/Sao_Paulo"))$conferencias
  b09 = linhas_da_regra_conferida(antes, "B09-10")
  expect_false(b09$confere)
  expect_match(b09$observacao, "agora")
})

test_that("o vencimento das parcelas: nunca antes da emiss\u00e3o nem da parcela anterior", {
  texto = xml_do_exemplo("nfe_proc_sp.xml")
  antes_da_emissao = nfe_conferir(trocar(texto, "<dVenc>2026-11-14</dVenc>", "<dVenc>2026-10-01</dVenc>"))$conferencias
  y09 = linhas_da_regra_conferida(antes_da_emissao, "Y09-20")
  expect_identical(y09$campo, "cobr/dup[1]/dVenc")
  expect_identical(y09$codigo_sefaz, "900")
  fora_de_ordem = nfe_conferir(trocar(texto, "<dVenc>2026-12-14</dVenc>", "<dVenc>2026-11-01</dVenc>"))$conferencias
  expect_identical(linhas_da_regra_conferida(fora_de_ordem, "Y09-30")$campo, "cobr/dup[2]/dVenc")
})

test_that("o GTIN, a posi\u00e7\u00e3o na nota e os argumentos", {  expect_equal(gtin_confere(c("4006381333931", "96385074", "4006381333932", "SEM GTIN", NA)),
               c(TRUE, TRUE, FALSE, FALSE, FALSE))
  expect_equal(ordem_na_nota(c("a", "b", "a", "a", "b")), c(1L, 1L, 2L, 3L, 2L))
  nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")
  expect_error(nfe_conferir(nota, agora = "2026-11-05"), "agora")
  expect_error(nfe_conferir(nota, todas_as_regras = NA), "todas_as_regras")
  outro = nfe_conferir(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  expect_equal(nrow(outro$notas), 0)
  expect_false(is.na(outro$arquivos$problema))
})

test_that("cada regra da tabela tem a fonte, o c\u00f3digo e a aplica\u00e7\u00e3o", {
  regras = regras_da_nfe()
  expect_false(anyDuplicated(regras$regra) > 0)
  expect_true(all(regras$aplicacao %in% c("obrigat\u00f3ria", "facultativa")))
  expect_true(all(grepl("^[0-9]{3,4}$", regras$codigo_sefaz)))
  expect_true(all(regras$modelos %in% c("55", "65", "55/65")))
  expect_false(any(is.na(regras$fonte) | is.na(regras$mensagem)))
})

# A regra conferida de uma nota (ou do item), pelo resultado com todas as regras.
confere_na_regra = function(texto, regra, item = NULL) {
  conferencias = nfe_conferir(texto, todas_as_regras = TRUE)$conferencias
  linhas = conferencias[conferencias$regra == regra, ]
  if (!is.null(item)) {
    linhas = linhas[linhas$item %in% item, ]
  }
  linhas$confere
}

test_that("os pagamentos da NFC-e: o cart\u00e3o, a integra\u00e7\u00e3o, a data do pagamento e o limite da nota", {
  nfce = xml_do_exemplo("nfce_ce_contingencia.xml")
  expect_false(confere_na_regra(trocar(nfce, "<tPag>01</tPag>", "<tPag>03</tPag>"), "YA04-10"))
  integrado = trocar(nfce, "<vPag>50.00</vPag>", "<vPag>50.00</vPag><card><tpIntegra>1</tpIntegra></card>")
  expect_false(confere_na_regra(trocar(integrado, "<tPag>01</tPag>", "<tPag>03</tPag>"), "YA05-10"))
  # O pagamento dia 25, e a SEFAZ recebeu dia 21.
  expect_false(confere_na_regra(trocar(nfce, "<vPag>50.00</vPag>", "<vPag>50.00</vPag><dPag>2026-10-25</dPag>"), "YA03a-10"))
  expect_true(confere_na_regra(trocar(nfce, "<vPag>50.00</vPag>", "<vPag>50.00</vPag><dPag>2026-10-21</dPag>"), "YA03a-10"))
  expect_false(confere_na_regra(trocar(nfce, "<vNF>35.00</vNF>", "<vNF>250000.00</vNF>"), "W16-30"))
  expect_true(confere_na_regra(nfce, "W16-30"))
})

test_that("a NFC-e do MEI, a conting\u00eancia que ela n\u00e3o usa e a chave do QR-Code", {
  nfce = xml_do_exemplo("nfce_ce_contingencia.xml")
  mei = trocar(nfce, "<CRT>1</CRT>", "<CRT>4</CRT>")
  expect_identical(confere_na_regra(mei, "N12a-81"), c(TRUE, TRUE))
  expect_identical(confere_na_regra(trocar(mei, "<CSOSN>102</CSOSN>", "<CSOSN>103</CSOSN>"), "N12a-81"), c(FALSE, TRUE))
  expect_identical(confere_na_regra(trocar(mei, "<CFOP>5102</CFOP>", "<CFOP>5101</CFOP>"), "N12a-91"), c(FALSE, TRUE))
  expect_false(confere_na_regra(trocar(nfce, "<tpEmis>9</tpEmis>", "<tpEmis>5</tpEmis>"), "B22-34"))
  expect_true(is.na(confere_na_regra(trocar(nfce, "<tpEmis>9</tpEmis>", "<tpEmis>4</tpEmis>"), "B22-34")))
  expect_true(confere_na_regra(nfce, "ZX02-228"))
  expect_false(confere_na_regra(trocar(nfce, "?p=2326", "?p=3526"), "ZX02-228"))
})

test_that("a NF-e com DANFE Simplificado Tipo 2 s\u00f3 aceita o QR-Code da vers\u00e3o 3", {
  texto = trocar(xml_do_exemplo("nfe_proc_sp.xml"), "<tpImp>1</tpImp>", "<tpImp>6</tpImp>")
  texto = trocar(texto, "</infNFe>", paste0("</infNFe><infNFeSupl><qrCode>https://nfce.exemplo.invalid/qrcode?p=",
                                            "35261011222333000181550010000010011123456785|2|2|1|ABC</qrCode>",
                                            "<urlChave>https://nfce.exemplo.invalid/consulta</urlChave></infNFeSupl>"))
  expect_false(confere_na_regra(texto, "ZX02-220"))
  expect_true(confere_na_regra(texto, "ZX02-228"))
})

# O item 1 com o grupo do ICMS para a UF de destino, a alíquota interestadual e a origem pedidas.
nota_com_partilha = function(texto, aliquota, origem) {
  com_grupo = trocar(texto, "</ICMS>\n          <IPI>", paste0(
    "</ICMS><ICMSUFDest><vBCUFDest>50.00</vBCUFDest><pICMSUFDest>18.00</pICMSUFDest><pICMSInter>", aliquota,
    "</pICMSInter><pICMSInterPart>100.00</pICMSInterPart><vICMSUFDest>3.00</vICMSUFDest><vICMSUFRemet>0.00</vICMSUFRemet>",
    "</ICMSUFDest>\n          <IPI>"))
  trocar(com_grupo, "<orig>0</orig>", paste0("<orig>", origem, "</orig>"))
}

test_that("o ICMS do item: a exporta\u00e7\u00e3o, a desonera\u00e7\u00e3o da ZFM e a al\u00edquota interestadual do importado", {
  texto = xml_do_exemplo("nfe_proc_sp.xml")
  expect_false(confere_na_regra(trocar(texto, "<CFOP>6102</CFOP>", "<CFOP>7101</CFOP>"), "N12-10"))
  icms00 = regmatches(texto, regexpr("(?s)<ICMS00>.*?</ICMS00>", texto, perl = TRUE))
  suframa = trocar(texto, icms00, paste0("<ICMS40><orig>0</orig><CST>40</CST><vICMSDeson>1.00</vICMSDeson>",
                                         "<motDesICMS>7</motDesICMS><indDeduzDeson>0</indDeduzDeson></ICMS40>"))
  expect_false(confere_na_regra(suframa, "N28-12"))
  expect_false(confere_na_regra(nota_com_partilha(texto, "4.00", "0"), "NA09-10"))
  expect_true(confere_na_regra(nota_com_partilha(texto, "4.00", "1"), "NA09-10"))
  expect_false(confere_na_regra(nota_com_partilha(texto, "12.00", "1"), "NA09-20"))
})

test_that("a importa\u00e7\u00e3o por conta e ordem: o adquirente e a UF dele", {
  texto = xml_do_exemplo("nfe_proc_sp.xml")
  importacao = paste0("<DI><nDI>123</nDI><dDI>2026-10-01</dDI><xLocDesemb>SANTOS</xLocDesemb><UFDesemb>SP</UFDesemb>",
                      "<dDesemb>2026-10-02</dDesemb><tpViaTransp>1</tpViaTransp><tpIntermedio>2</tpIntermedio>",
                      "<cExportador>X</cExportador></DI><xPed>")
  sem_adquirente = trocar(texto, "<xPed>", importacao)
  expect_false(confere_na_regra(sem_adquirente, "I23d-10", 1))
  expect_false(confere_na_regra(sem_adquirente, "I23e-10", 1))
  com_cnpj_errado = trocar(sem_adquirente, "<tpIntermedio>2</tpIntermedio>",
                           "<tpIntermedio>2</tpIntermedio><CNPJ>11222333000180</CNPJ><UFTerceiro>SP</UFTerceiro>")
  expect_true(confere_na_regra(com_cnpj_errado, "I23d-10", 1))
  expect_false(confere_na_regra(com_cnpj_errado, "I23d-20", 1))
  expect_true(confere_na_regra(com_cnpj_errado, "I23e-10", 1))
})
