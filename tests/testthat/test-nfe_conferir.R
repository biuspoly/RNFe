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
  resultado = nfe_conferir(exemplos)
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

test_that("o GTIN, a posi\u00e7\u00e3o na nota e os argumentos", {
  expect_equal(gtin_confere(c("4006381333931", "96385074", "4006381333932", "SEM GTIN", NA)),
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
