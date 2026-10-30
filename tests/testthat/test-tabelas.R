# Os textos e as datas esperados foram lidos direto dos arquivos oficiais baixados (a planilha de CFOP do
# Portal da NF-e e as tabelas do SPED), não das cópias que vão no pacote.

test_that("cada tabela tem as colunas e os tipos certos", {
  for (nome in c("origem", "cst_icms", "csosn", "cst_ipi", "cst_pis", "cst_cofins", "cst_ibs_cbs")) {
    tabela = tabela_fiscal(nome)
    expect_identical(names(tabela), c("codigo", "descricao", "inicio", "fim"))
    expect_s3_class(tabela$inicio, "Date")
    expect_s3_class(tabela$fim, "Date")
    expect_false(any(is.na(tabela$codigo) | is.na(tabela$descricao)))
  }
  cfop = tabela_fiscal("cfop")
  expect_identical(names(cfop)[1:5], c("codigo", "titulo", "nota_explicativa", "inicio", "fim"))
  expect_type(cfop$devolucao, "integer")
  expect_false(any(duplicated(cfop$codigo)))
  expect_error(tabela_fiscal("tabela_que_nao_existe"), "Tabela desconhecida")
})

test_that("CFOP como na tabela oficial da NF-e", {
  cfop = tabela_fiscal("cfop")
  linha_6404 = cfop[cfop$codigo == "6404", ]
  expect_identical(linha_6404$titulo, "Venda de mercadoria sujeita ao regime de substitui\u00e7\u00e3o tribut\u00e1ria, cujo imposto j\u00e1 tenha sido retido anteriormente.")
  expect_identical(linha_6404$inicio, as.Date("2006-01-01"))
  expect_true(is.na(linha_6404$fim))
  expect_match(cfop$titulo[cfop$codigo == "5102"], "^Venda de mercadoria adquirida ou recebida de terceiros, ou qualquer venda de mercadoria efetuada pelo MEI")
})

test_that("as corre\u00e7\u00f5es sobre as tabelas do SPED: origem 8, CST de combust\u00edvel e CSOSN sem datas", {
  origem = tabela_fiscal("origem")
  expect_identical(origem$inicio[origem$codigo == "8"], as.Date("2013-08-01"))
  expect_identical(sort(unique(origem$codigo)), as.character(0:8))
  cst_icms = tabela_fiscal("cst_icms")
  expect_identical(cst_icms$inicio[cst_icms$codigo == "61"], as.Date("2023-04-01"))
  expect_identical(cst_icms$descricao[cst_icms$codigo == "61"], "Tributa\u00e7\u00e3o monof\u00e1sica sobre combust\u00edveis cobrada anteriormente")
  csosn = tabela_fiscal("csosn")
  expect_identical(csosn$codigo, c("101", "102", "103", "201", "202", "203", "300", "400", "500", "900"))
  expect_true(all(is.na(csosn$inicio) & is.na(csosn$fim)))
  # Windows-1252, não Latin-1: o travessão do CST 51 do PIS é o byte 0x96 no arquivo do SPED.
  expect_match(tabela_fiscal("cst_pis")$descricao[tabela_fiscal("cst_pis")$codigo == "51"], "Cr\u00e9dito \u2013 Vinculada", fixed = TRUE)
})

test_that("NCM como no Siscomex, com a descri\u00e7\u00e3o completa", {
  ncm = tabela_fiscal("ncm")
  reprodutores = ncm[ncm$codigo == "01012100", ]
  expect_identical(reprodutores$descricao, "-- Reprodutores de ra\u00e7a pura")
  expect_identical(reprodutores$inicio, as.Date("2022-04-01"))
  expect_true(is.na(reprodutores$fim))
  expect_identical(reprodutores$ato_inicio, "Res Gecex 272/2021")
  expect_false(any(duplicated(ncm$codigo)))
  expect_identical(
    ncm$descricao_completa[ncm$codigo == "22011000"],
    paste(
      "\u00c1guas, incluindo as \u00e1guas minerais, naturais ou artificiais, e as \u00e1guas gaseificadas, n\u00e3o adicionadas de a\u00e7\u00facar ou de outros edulcorantes nem aromatizadas; gelo e neve.",
      "- \u00c1guas minerais e \u00e1guas gaseificadas"
    )
  )
  expect_identical(ncm$descricao_completa[ncm$codigo == "01"], "Animais vivos.")
  expect_identical(
    ncm$descricao_completa[ncm$codigo == "01012100"],
    "Cavalos, asininos e muares, vivos. - Cavalos: -- Reprodutores de ra\u00e7a pura"
  )
})

test_that("munic\u00edpios como na API de localidades do IBGE", {
  municipios = tabela_fiscal("municipios")
  expect_identical(names(municipios), c("codigo", "nome", "uf", "codigo_uf", "inicio", "fim"))
  expect_s3_class(municipios$inicio, "Date")
  expect_true(all(is.na(municipios$inicio) & is.na(municipios$fim)))
  # 5.571 em 30/10/2026; o rob\u00f4 atualiza a lista, ent\u00e3o o teste s\u00f3 confere que ela est\u00e1 inteira.
  expect_gt(nrow(municipios), 5500)
  expect_true(all(grepl("^[0-9]{7}$", municipios$codigo)))
  expect_false(any(duplicated(municipios$codigo)))
  expect_identical(municipios$codigo_uf, substr(municipios$codigo, 1, 2))
  expect_identical(length(unique(municipios$uf)), 27L)
  expect_identical(municipios$nome[municipios$codigo == "3550308"], "S\u00e3o Paulo")
  expect_identical(municipios$uf[municipios$codigo == "2304400"], "CE")
  expect_identical(municipios$nome[municipios$codigo == "3304557"], "Rio de Janeiro")
  # Os munic\u00edpios dos documentos de exemplo est\u00e3o todos na tabela.
  exemplos = system.file("exemplos", c("nfe_proc_sp.xml", "cte_proc_sp.xml", "mdfe_proc_sp.xml"), package = "RNfe")
  codigos_nos_exemplos = c(nfe_ler(exemplos[1])$notas$emitente_codigo_municipio, cte_ler(exemplos[2])$ctes$fim_codigo_municipio,
                           mdfe_ler(exemplos[3])$locais$codigo_municipio)
  codigos_nos_exemplos = codigos_nos_exemplos[!is.na(codigos_nos_exemplos)]
  expect_gt(length(codigos_nos_exemplos), 0)
  expect_true(all(codigos_nos_exemplos %in% municipios$codigo))
})

test_that("IBS e CBS como na tabela de classifica\u00e7\u00e3o tribut\u00e1ria do Portal da NF-e", {
  cst = tabela_fiscal("cst_ibs_cbs")
  expect_identical(cst$descricao[cst$codigo == "000"], "Tributa\u00e7\u00e3o integral")
  classificacao = tabela_fiscal("classificacao_ibs_cbs")
  integral = classificacao[classificacao$codigo == "000001", ]
  expect_identical(integral$cst, "000")
  expect_identical(integral$nome, "Situa\u00e7\u00f5es tributadas integralmente pelo IBS e CBS.")
  expect_identical(integral$inicio, as.Date("2026-01-01"))
  expect_type(classificacao$reducao_ibs, "double")
  expect_false(any(duplicated(classificacao$codigo)))
  # O Excel guardava alguns CST como n\u00famero (400): voltam com tr\u00eas d\u00edgitos.
  expect_true(all(nchar(classificacao$cst) == 3))
  expect_true(all(classificacao$cst[startsWith(classificacao$codigo, "400")] == "400"))
  expect_true(all(classificacao$cst %in% cst$codigo))
})

test_that("a descri\u00e7\u00e3o muda com a data da nota", {
  datas = as.Date(c("2012-06-01", "2013-06-01", "2008-12-31"))
  expect_identical(
    descricao_na_data("origem", c("0", "0", "0"), datas),
    c("Nacional", "Nacional, exceto as indicadas nos c\u00f3digos 3 a 5", NA)
  )
  expect_identical(descricao_na_data("origem", "8", as.Date("2013-07-31")), NA_character_)
  expect_identical(
    descricao_na_data("cst_pis", c("01", "01"), as.Date(c("2009-12-15", "2009-12-16"))),
    c("Opera\u00e7\u00e3o Tribut\u00e1vel - Base de C\u00e1lculo = Valor da Opera\u00e7\u00e3o Al\u00edquota Normal (Cumulativo/N\u00e3o Cumulativo)",
      "Opera\u00e7\u00e3o Tribut\u00e1vel com Al\u00edquota B\u00e1sica")
  )
  expect_identical(descricao_na_data("csosn", "102", as.Date("2026-10-20")), "Tributada pelo Simples Nacional sem permiss\u00e3o de cr\u00e9dito")
  expect_identical(descricao_na_data("cst_icms", c("99", NA), as.Date(c("2026-01-01", "2026-01-01"))), c(NA_character_, NA_character_))
})
