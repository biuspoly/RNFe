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
  # 5.571 em 30/10/2026; o robô atualiza a lista, então o teste só confere que ela está inteira.
  expect_gt(nrow(municipios), 5500)
  expect_true(all(grepl("^[0-9]{7}$", municipios$codigo)))
  expect_false(any(duplicated(municipios$codigo)))
  expect_identical(municipios$codigo_uf, substr(municipios$codigo, 1, 2))
  expect_identical(length(unique(municipios$uf)), 27L)
  expect_identical(municipios$nome[municipios$codigo == "3550308"], "S\u00e3o Paulo")
  expect_identical(municipios$uf[municipios$codigo == "2304400"], "CE")
  expect_identical(municipios$nome[municipios$codigo == "3304557"], "Rio de Janeiro")
  # Os municípios dos documentos de exemplo estão todos na tabela.
  exemplos = system.file("exemplos", c("nfe_proc_sp.xml", "cte_proc_sp.xml", "mdfe_proc_sp.xml"), package = "RNFe")
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
  # O Excel guardava alguns CST como número (400): voltam com três dígitos.
  expect_true(all(nchar(classificacao$cst) == 3))
  expect_true(all(classificacao$cst[startsWith(classificacao$codigo, "400")] == "400"))
  expect_true(all(classificacao$cst %in% cst$codigo))
})

test_that("meios de pagamento e bandeiras de cart\u00e3o como nas planilhas do Portal da NF-e", {
  meios = tabela_fiscal("meios_pagamento")
  expect_identical(names(meios), c("codigo", "descricao", "observacao", "inicio", "fim"))
  expect_s3_class(meios$inicio, "Date")
  expect_false(any(duplicated(meios$codigo)))
  expect_identical(meios$descricao[meios$codigo == "17"], "Pagamento Instant\u00e2neo (PIX) - Din\u00e2mico")
  expect_identical(meios$descricao[meios$codigo == "24"], "TEF - \"Book Transfer\"")
  # A planilha guarda a data como número do Excel: 45474 é 01/07/2024 e 46146, 04/05/2026.
  expect_identical(meios$inicio[meios$codigo %in% c("05", "17", "23", "99")], as.Date(c("2024-07-01", "2024-07-01", "2026-05-04", "2020-01-01")))
  expect_match(meios$observacao[meios$codigo == "05"], "^Cart\u00e3o da loja \\(na forma de credi\u00e1rio\\)")
  bandeiras = tabela_fiscal("bandeiras_cartao")
  expect_identical(names(bandeiras), c("codigo", "descricao", "inicio", "fim"))
  expect_false(any(duplicated(bandeiras$codigo)))
  expect_identical(bandeiras$descricao[bandeiras$codigo %in% c("06", "18", "27", "99")], c("Elo", "JcB", "Ticket", "Outros"))
  expect_true(all(bandeiras$inicio == as.Date("2020-01-01")))
})

test_that("o significado dos c\u00f3digos de cada campo do leiaute", {
  codigos = tabela_fiscal("codigos_dos_campos")
  expect_identical(names(codigos), c("documento", "campo", "contexto", "codigo", "descricao", "inicio", "fim"))
  expect_setequal(codigos$documento, c("NF-e", "CT-e", "GTV-e", "MDF-e", "NFS-e", "evento"))
  expect_false(any(is.na(codigos$descricao) | is.na(codigos$codigo)))
  expect_false(any(duplicated(codigos[, c("documento", "campo", "contexto", "codigo")])))
  # O órgão dos eventos pelo código da UF: as 27 UFs, iguais às da tabela de municípios do IBGE.
  orgaos_de_uf = codigos[codigos$campo == "cOrgao" & is.na(codigos$contexto), ]
  ufs_do_ibge = unique(tabela_fiscal("municipios")[, c("codigo_uf", "uf")])
  expect_identical(nrow(orgaos_de_uf), 27L)
  expect_identical(orgaos_de_uf$descricao, ufs_do_ibge$uf[match(orgaos_de_uf$codigo, ufs_do_ibge$codigo_uf)])
  forma_de_emissao = codigos[codigos$campo == "tpEmis" & codigos$codigo == "2", ]
  expect_identical(forma_de_emissao$descricao[forma_de_emissao$documento == "NF-e"], "Conting\u00eancia FS")
  expect_identical(forma_de_emissao$descricao[forma_de_emissao$documento == "CT-e"], "Conting\u00eancia offline")
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
  # O PIX dinâmico (17) só entrou na tabela de meios de pagamento em 01/07/2024.
  expect_identical(descricao_na_data("meios_pagamento", c("17", "17"), as.Date(c("2024-06-30", "2024-07-01"))),
                   c(NA, "Pagamento Instant\u00e2neo (PIX) - Din\u00e2mico"))
})

# O repositório de mentira: cada tabela do pacote como está, menos as que o teste troca. A pasta de cache do R vai para
# uma pasta temporária, que é apagada no fim.
texto_da_tabela_do_pacote = function(nome_da_tabela) {
  arquivo = system.file("extdata", "tabelas", paste0(nome_da_tabela, ".csv"), package = "RNFe")
  readBin(arquivo, "raw", file.size(arquivo))
}

# A pasta de cache do R numa pasta temporária, para o teste não mexer na de quem roda. Devolve o valor de antes.
apontar_o_cache_para = function(pasta) {
  antes = Sys.getenv("R_USER_CACHE_DIR", unset = NA)
  Sys.setenv(R_USER_CACHE_DIR = pasta)
  rm(list = ls(tabelas_ja_lidas), envir = tabelas_ja_lidas)
  antes
}

voltar_o_cache = function(antes, pasta) {
  if (is.na(antes)) {
    Sys.unsetenv("R_USER_CACHE_DIR")
  } else {
    Sys.setenv(R_USER_CACHE_DIR = antes)
  }
  rm(list = ls(tabelas_ja_lidas), envir = tabelas_ja_lidas)
  unlink(pasta, recursive = TRUE)
}

test_that("tabelas_atualizar(): baixa do reposit\u00f3rio, usa a nova e volta \u00e0 do pacote", {
  skip_if_not_installed("httr2")
  pasta = tempfile("cache_do_rnfe_")
  antes = apontar_o_cache_para(pasta)
  on.exit(voltar_o_cache(antes, pasta), add = TRUE)
  pedidos = character()
  httr2::local_mocked_responses(function(req) {
    pedidos <<- c(pedidos, req$url)
    nome = sub("\\.csv$", "", basename(req$url))
    corpo = texto_da_tabela_do_pacote(nome)
    if (nome == "cst_icms") {
      corpo = charToRaw(enc2utf8(sub("Tributada integralmente", "Tributada integralmente (texto novo)", rawToChar(corpo), fixed = TRUE)))
    }
    httr2::response(status_code = 200, headers = "Content-Type: text/plain; charset=utf-8", body = corpo)
  })
  atualizacao = tabelas_atualizar()
  expect_identical(atualizacao$tabela, TABELAS_QUE_SE_ATUALIZAM)
  expect_identical(atualizacao$tabela[atualizacao$mudou], "cst_icms")
  expect_true(all(is.na(atualizacao$problema)))
  expect_identical(pedidos[1], "https://raw.githubusercontent.com/biuspoly/RNFe/main/inst/extdata/tabelas/cfop.csv")
  # A tabela nova já vale nesta sessão e nas leituras dos documentos.
  expect_identical(tabela_fiscal("cst_icms")$descricao[1], "Tributada integralmente (texto novo)")
  expect_identical(descricao_na_data("cst_icms", "00", as.Date("2026-01-01")), "Tributada integralmente (texto novo)")
  # De novo, nada mudou; e a volta às do pacote.
  expect_false(any(tabelas_atualizar()$mudou))
  tabelas_atualizar(usar_as_do_pacote = TRUE)
  expect_identical(tabela_fiscal("cst_icms")$descricao[1], "Tributada integralmente")
})

test_that("tabelas_atualizar(): formato novo, tabela que n\u00e3o baixa e c\u00f3pia mais velha que a instala\u00e7\u00e3o", {
  skip_if_not_installed("httr2")
  pasta = tempfile("cache_do_rnfe_")
  antes = apontar_o_cache_para(pasta)
  on.exit(voltar_o_cache(antes, pasta), add = TRUE)
  httr2::local_mocked_responses(function(req) {
    nome = sub("\\.csv$", "", basename(req$url))
    if (nome == "cfop") {
      return(httr2::response(status_code = 200, body = charToRaw('"codigo","coluna_nova"\n"5102","x"\n')))
    }
    if (nome == "ncm") {
      return(httr2::response(status_code = 404, body = charToRaw("404: Not Found")))
    }
    if (nome == "origem") {
      stop("Could not resolve host")
    }
    httr2::response(status_code = 200, body = texto_da_tabela_do_pacote(nome))
  })
  atualizacao = tabelas_atualizar()
  problemas = atualizacao$problema
  names(problemas) = atualizacao$tabela
  expect_identical(problemas[["cfop"]], "a tabela mudou de formato: atualize o pacote RNFe para usar a nova")
  expect_identical(problemas[["ncm"]], "n\u00e3o baixou: HTTP 404")
  expect_match(problemas[["origem"]], "^n\u00e3o baixou: .*Could not resolve host")
  # As que não foram trocadas seguem as do pacote.
  expect_true("titulo" %in% names(tabela_fiscal("cfop")))
  expect_false(file.exists(file.path(pasta, "R", "RNFe", "tabelas", "cfop.csv")))
  # Uma cópia baixada antes da instalação do pacote não vale.
  baixada = arquivo_da_tabela("cst_icms")
  expect_true(startsWith(normalizePath(baixada, winslash = "/"), normalizePath(pasta, winslash = "/")))
  Sys.setFileTime(baixada, as.POSIXct("2020-01-01"))
  expect_identical(arquivo_da_tabela("cst_icms"), system.file("extdata", "tabelas", "cst_icms.csv", package = "RNFe"))
  expect_error(tabelas_atualizar(usar_as_do_pacote = NA), "usar_as_do_pacote")
})
