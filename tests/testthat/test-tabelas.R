# Os textos e as datas esperados foram lidos direto dos arquivos oficiais baixados (a planilha de CFOP do
# Portal da NF-e e as tabelas do SPED), não das cópias que vão no pacote.

test_that("cada tabela tem as colunas e os tipos certos", {
  for (nome in c("origem", "cst_icms", "csosn", "cst_ipi", "cst_pis", "cst_cofins", "cst_ibs_cbs")) {
    tabela = tabela_fiscal(nome)
    expect_identical(names(tabela)[1:4], c("codigo", "descricao", "inicio", "fim"))
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

test_that("o CST e a classifica\u00e7\u00e3o do IBS e da CBS trazem os indicadores da planilha oficial", {
  # Os valores da planilha do Informe Técnico 2025.002 de 30/10/2026: na aba de CST, 1 = o grupo é exigido e 0 = não
  # é permitido; na de cClassTrib, os indicadores de cada documento e as abas tpRBSN e tpDoacao.
  cst = tabela_fiscal("cst_ibs_cbs")
  expect_identical(cst$grupo_reducao[cst$codigo == "011"], 1L)
  expect_identical(cst$grupo_diferimento[cst$codigo == "510"], 1L)
  expect_identical(cst$grupo_ibs_cbs[cst$codigo == "400"], 0L)
  expect_identical(cst$grupo_monofasico[cst$codigo == "620"], 1L)
  expect_identical(cst$redutor_base_calculo[cst$codigo == "222"], 1L)
  for (coluna in names(cst)[5:12]) {
    expect_type(cst[[coluna]], "integer")
    expect_false(anyNA(cst[[coluna]]))
  }
  classificacao = tabela_fiscal("classificacao_ibs_cbs")
  integral = classificacao[classificacao$codigo == "000001", ]
  expect_identical(c(integral$permitido_na_nfe, integral$permitido_no_cte, integral$permitido_na_nfse), c(1L, 1L, 1L))
  expect_identical(integral$tipo_receita_simples, "1")
  expect_identical(integral$tipo_receita_simples_descricao, "Receita bruta - interna")
  expect_false(anyNA(classificacao$tipo_receita_simples_descricao))
  expect_false(anyNA(classificacao$doacao_descricao))
  expect_identical(sum(classificacao$grupo_tributacao_regular), 31L)
  expect_type(classificacao$permitido_na_duimp, "integer")
})

test_that("as al\u00edquotas do IBS e da CBS de cada per\u00edodo", {
  aliquotas = tabela_fiscal("aliquotas_ibs_cbs")
  expect_s3_class(aliquotas$inicio, "Date")
  de_2026 = aliquotas[aliquotas$inicio == as.Date("2026-01-01"), ]
  expect_identical(c(de_2026$aliquota_ibs_uf, de_2026$aliquota_ibs_municipio, de_2026$aliquota_cbs), c(0.1, 0, 0.9))
  expect_identical(de_2026$base_legal, "LC 214/2025, arts. 343 e 346")
  de_2027 = aliquotas[aliquotas$inicio == as.Date("2027-01-01"), ]
  expect_identical(de_2027$fim, as.Date("2028-12-31"))
  expect_identical(c(de_2027$aliquota_ibs_uf, de_2027$aliquota_ibs_municipio), c(0.05, 0.05))
  # A CBS de 2027 depende da alíquota de referência do Senado, que ainda não foi publicada.
  expect_true(is.na(de_2027$aliquota_cbs))
  # Os períodos não se sobrepõem.
  expect_true(all(utils::head(aliquotas$fim, -1) < utils::tail(aliquotas$inicio, -1)))
})

test_that("o que mudou na tabela da Reforma de uma vers\u00e3o para a outra", {
  # Conferido com o Informe Técnico 2025.002 v1.71 (seção 7): na 1.40, a 200001 deixou de valer na NF-e; na 1.70, a
  # 410014 deixou de permitir o crédito presumido; na 1.30, os CST 010 e 011 passaram a exigir o grupo do IBS e da CBS.
  mudancas = tabela_fiscal("mudancas_ibs_cbs")
  expect_identical(names(mudancas), c("tabela", "codigo", "coluna", "antes", "depois", "versao", "publicada_em",
                                      "em_producao_ate"))
  expect_s3_class(mudancas$publicada_em, "Date")
  expect_s3_class(mudancas$em_producao_ate, "Date")
  da_200001 = mudancas[mudancas$codigo == "200001" & mudancas$coluna == "permitido_na_nfe", ]
  expect_identical(c(da_200001$antes, da_200001$depois, da_200001$versao), c("1", "0", "1.40"))
  expect_identical(da_200001$publicada_em, as.Date("2026-01-28"))
  # A 1.40 não tem prazo no IT: vale o da 1.50, que já traz a mudança.
  expect_identical(da_200001$em_producao_ate, as.Date("2026-05-04"))
  da_410014 = mudancas[mudancas$codigo == "410014", ]
  expect_identical(c(da_410014$coluna, da_410014$versao, da_410014$depois), c("grupo_credito_presumido", "1.70", "0"))
  expect_identical(da_410014$em_producao_ate, as.Date("2026-10-16"))
  do_cst_010 = mudancas[mudancas$tabela == "cst_ibs_cbs" & mudancas$codigo == "010", ]
  expect_identical(c(do_cst_010$coluna, do_cst_010$antes, do_cst_010$depois), c("grupo_ibs_cbs", "0", "1"))
  # O código que saiu na 1.30.
  saiu = mudancas[mudancas$codigo == "210001", ]
  expect_identical(c(saiu$coluna, saiu$antes, saiu$depois), c("existe", "1", "0"))
  # Cada mudança muda alguma coisa, e cada versão vem depois da anterior.
  expect_false(any(!is.na(mudancas$antes) & !is.na(mudancas$depois) & mudancas$antes == mudancas$depois))
  expect_false(is.unsorted(mudancas$publicada_em))
  expect_true(all(mudancas$em_producao_ate >= mudancas$publicada_em))
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

# O repositório de mentira: cada tabela do pacote como está, menos as trocadas, e a lista de conferência delas com a
# versão pedida. `trocadas` é uma lista nome = corpo (raw); `fora_da_lista` são as tabelas que a lista não traz.
texto_da_tabela_do_pacote = function(nome_da_tabela) {
  arquivo = system.file("extdata", "tabelas", paste0(nome_da_tabela, ".csv"), package = "RNFe")
  readBin(arquivo, "raw", file.size(arquivo))
}

texto_trocado = function(nome_da_tabela, de, para) {
  charToRaw(enc2utf8(sub(de, para, rawToChar(texto_da_tabela_do_pacote(nome_da_tabela)), fixed = TRUE)))
}

repositorio_de_mentira = function(versao, trocadas = list(), fora_da_lista = character()) {
  corpos = list()
  linhas_da_lista = data.frame()
  for (nome_da_tabela in TABELAS_QUE_SE_ATUALIZAM) {
    corpo = trocadas[[nome_da_tabela]]
    if (is.null(corpo)) {
      corpo = texto_da_tabela_do_pacote(nome_da_tabela)
    }
    corpos[[nome_da_tabela]] = corpo
    arquivo_temporario = tempfile(fileext = ".csv")
    writeBin(corpo, arquivo_temporario)
    linhas = nrow(utils::read.csv(arquivo_temporario, colClasses = "character", fileEncoding = "UTF-8", na.strings = ""))
    linhas_da_lista = rbind(linhas_da_lista, data.frame(tabela = nome_da_tabela, linhas = linhas,
                                                        md5 = unname(tools::md5sum(arquivo_temporario)),
                                                        versao_do_conjunto = versao))
    unlink(arquivo_temporario)
  }
  linhas_da_lista = linhas_da_lista[!(linhas_da_lista$tabela %in% fora_da_lista), ]
  arquivo_temporario = tempfile(fileext = ".csv")
  utils::write.csv(linhas_da_lista, arquivo_temporario, row.names = FALSE)
  corpos[["conferencia"]] = readBin(arquivo_temporario, "raw", file.size(arquivo_temporario))
  unlink(arquivo_temporario)
  corpos
}

# Responde como o GitHub, com os corpos do repositório de mentira; `especiais` troca a resposta de alguns arquivos
# (uma função que devolve a resposta ou dá erro). Guarda os endereços pedidos em `pedidos`, no ambiente de quem chamou.
responder_com = function(corpos, especiais = list(), ambiente = parent.frame()) {
  assign("pedidos", character(), envir = ambiente)
  function(req) {
    assign("pedidos", c(get("pedidos", envir = ambiente), req$url), envir = ambiente)
    nome = sub("\\.csv$", "", basename(req$url))
    if (!is.null(especiais[[nome]])) {
      return(especiais[[nome]]())
    }
    httr2::response(status_code = 200, headers = "Content-Type: text/plain; charset=utf-8", body = corpos[[nome]])
  }
}

# A pasta de cache do R numa pasta temporária, para o teste começar sem nada baixado. Devolve o valor de antes.
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

VERSAO_NOVA = "2099-01-01 00:00:00"
ARQUIVO_DO_CST_ICMS_DO_PACOTE = system.file("extdata", "tabelas", "cst_icms.csv", package = "RNFe")

test_that("os testes n\u00e3o usam a pasta de cache do R de quem roda", {
  expect_identical(Sys.getenv("R_USER_CACHE_DIR"), file.path(tempdir(), "cache_dos_testes_do_rnfe"))
})

test_that("a lista de confer\u00eancia est\u00e1 em dia com as tabelas do pacote", {
  pasta_das_tabelas = system.file("extdata", "tabelas", package = "RNFe")
  conferencia = ler_conferencia(file.path(pasta_das_tabelas, "conferencia.csv"))
  expect_false(is.null(conferencia))
  arquivos_das_tabelas = setdiff(list.files(pasta_das_tabelas, pattern = "\\.csv$"), "conferencia.csv")
  expect_setequal(paste0(conferencia$tabela, ".csv"), arquivos_das_tabelas)
  expect_true(all(TABELAS_QUE_SE_ATUALIZAM %in% conferencia$tabela))
  for (numero_da_linha in seq_len(nrow(conferencia))) {
    arquivo = file.path(pasta_das_tabelas, paste0(conferencia$tabela[numero_da_linha], ".csv"))
    # Se falhar: rode ferramentas/gerar_conferencia_das_tabelas.R depois de mexer numa tabela.
    expect_identical(unname(tools::md5sum(arquivo)), conferencia$md5[numero_da_linha], label = conferencia$tabela[numero_da_linha])
    expect_identical(contar_linhas_da_tabela(arquivo), as.integer(conferencia$linhas[numero_da_linha]))
  }
})

test_that("tabelas_atualizar(): baixa do reposit\u00f3rio, usa a nova e volta \u00e0 do pacote", {
  skip_if_not_installed("httr2")
  pasta = tempfile("cache_do_rnfe_")
  antes = apontar_o_cache_para(pasta)
  on.exit(voltar_o_cache(antes, pasta), add = TRUE)
  corpos = repositorio_de_mentira(VERSAO_NOVA, list(
    cst_icms = texto_trocado("cst_icms", "Tributada integralmente", "Tributada integralmente (texto novo)")
  ))
  httr2::local_mocked_responses(responder_com(corpos))
  atualizacao = tabelas_atualizar()
  expect_identical(atualizacao$tabela, TABELAS_QUE_SE_ATUALIZAM)
  expect_identical(atualizacao$tabela[atualizacao$mudou], "cst_icms")
  expect_true(all(is.na(atualizacao$problema)))
  expect_identical(atualizacao$linhas_agora, atualizacao$linhas_antes)
  # A lista de conferência vem primeiro.
  expect_identical(pedidos[1], "https://raw.githubusercontent.com/biuspoly/RNFe/main/inst/extdata/tabelas/conferencia.csv")
  expect_identical(pedidos[2], "https://raw.githubusercontent.com/biuspoly/RNFe/main/inst/extdata/tabelas/cfop.csv")
  # A tabela nova já vale nesta sessão e nas leituras dos documentos.
  expect_identical(tabela_fiscal("cst_icms")$descricao[1], "Tributada integralmente (texto novo)")
  expect_identical(descricao_na_data("cst_icms", "00", as.Date("2026-01-01")), "Tributada integralmente (texto novo)")
  expect_false(dir.exists(paste0(pasta_das_tabelas_baixadas(), "_preparando")))
  # De novo, nada mudou; e a volta às do pacote, que apaga a pasta.
  expect_false(any(tabelas_atualizar()$mudou))
  tabelas_atualizar(usar_as_do_pacote = TRUE)
  expect_identical(tabela_fiscal("cst_icms")$descricao[1], "Tributada integralmente")
  expect_false(dir.exists(pasta_das_tabelas_baixadas()))
  expect_error(tabelas_atualizar(usar_as_do_pacote = NA), "usar_as_do_pacote")
})

test_that("tabelas_atualizar(): quando o pacote j\u00e1 tem o conjunto do reposit\u00f3rio, s\u00f3 a lista \u00e9 baixada", {
  skip_if_not_installed("httr2")
  pasta = tempfile("cache_do_rnfe_")
  antes = apontar_o_cache_para(pasta)
  on.exit(voltar_o_cache(antes, pasta), add = TRUE)
  httr2::local_mocked_responses(responder_com(repositorio_de_mentira(VERSAO_NOVA, list(
    cst_icms = texto_trocado("cst_icms", "Tributada integralmente", "Tributada integralmente (texto novo)")
  ))))
  tabelas_atualizar()
  expect_identical(tabela_fiscal("cst_icms")$descricao[1], "Tributada integralmente (texto novo)")
  # O repositório volta a ter o que o pacote tem: a cópia baixada antes deixa de servir e sai.
  versao_do_pacote = versao_da_conferencia(arquivo_da_conferencia_do_pacote())
  httr2::local_mocked_responses(responder_com(repositorio_de_mentira(versao_do_pacote)))
  atualizacao = tabelas_atualizar()
  expect_identical(pedidos, "https://raw.githubusercontent.com/biuspoly/RNFe/main/inst/extdata/tabelas/conferencia.csv")
  expect_identical(atualizacao$tabela[atualizacao$mudou], "cst_icms")
  expect_true(all(is.na(atualizacao$problema)))
  expect_false(dir.exists(pasta_das_tabelas_baixadas()))
  expect_identical(tabela_fiscal("cst_icms")$descricao[1], "Tributada integralmente")
})

test_that("tabelas_atualizar(): uma tabela com problema e nenhuma \u00e9 trocada", {
  skip_if_not_installed("httr2")
  pasta = tempfile("cache_do_rnfe_")
  antes = apontar_o_cache_para(pasta)
  on.exit(voltar_o_cache(antes, pasta), add = TRUE)
  corpos = repositorio_de_mentira(VERSAO_NOVA, trocadas = list(
    cfop = charToRaw('"codigo","coluna_nova"\n"5102","x"\n'),
    cst_icms = texto_trocado("cst_icms", "Tributada integralmente", "Tributada integralmente (texto novo)")
  ), fora_da_lista = "csosn")
  # A tabela pela metade: a lista confere o arquivo inteiro, e vem só o começo.
  cst_ipi_pela_metade = utils::head(corpos$cst_ipi, 150)
  httr2::local_mocked_responses(responder_com(corpos, especiais = list(
    ncm = function() httr2::response(status_code = 404, body = charToRaw("404: Not Found")),
    origem = function() stop("Could not resolve host"),
    cst_ipi = function() httr2::response(status_code = 200, body = cst_ipi_pela_metade),
    cst_pis = function() httr2::response(status_code = 200, body = charToRaw("<html><body>Acesso bloqueado</body></html>")),
    cst_cofins = function() httr2::response(status_code = 200)
  )))
  atualizacao = tabelas_atualizar()
  problemas = atualizacao$problema
  names(problemas) = atualizacao$tabela
  expect_identical(problemas[["cfop"]], "a tabela mudou de formato: atualize o pacote RNFe para usar as tabelas novas")
  expect_identical(problemas[["ncm"]], "n\u00e3o baixou: HTTP 404")
  expect_match(problemas[["origem"]], "^n\u00e3o baixou: .*Could not resolve host")
  expect_match(problemas[["cst_ipi"]], "^n\u00e3o confere com a lista de confer\u00eancia")
  expect_match(problemas[["cst_pis"]], "^veio como p\u00e1gina da web")
  expect_identical(problemas[["cst_cofins"]], "veio vazia")
  expect_identical(problemas[["csosn"]], "a lista de confer\u00eancia do reposit\u00f3rio n\u00e3o traz esta tabela")
  expect_match(problemas[["cst_icms"]], "^n\u00e3o trocada: as tabelas s\u00f3 s\u00e3o trocadas todas juntas")
  expect_false(any(atualizacao$mudou))
  expect_identical(atualizacao$linhas_agora, atualizacao$linhas_antes)
  # Nenhuma foi trocada: nem a que veio certa.
  expect_identical(tabela_fiscal("cst_icms")$descricao[1], "Tributada integralmente")
  expect_true("titulo" %in% names(tabela_fiscal("cfop")))
  expect_false(dir.exists(pasta_das_tabelas_baixadas()))
  expect_false(dir.exists(paste0(pasta_das_tabelas_baixadas(), "_preparando")))
})

test_that("tabelas_atualizar(): a lista de confer\u00eancia que n\u00e3o vem ou vem fora do formato", {
  skip_if_not_installed("httr2")
  pasta = tempfile("cache_do_rnfe_")
  antes = apontar_o_cache_para(pasta)
  on.exit(voltar_o_cache(antes, pasta), add = TRUE)
  corpos = repositorio_de_mentira(VERSAO_NOVA)
  httr2::local_mocked_responses(responder_com(corpos, especiais = list(
    conferencia = function() httr2::response(status_code = 503)
  )))
  atualizacao = tabelas_atualizar()
  expect_true(all(atualizacao$problema == "a lista de confer\u00eancia do reposit\u00f3rio n\u00e3o baixou: HTTP 503"))
  expect_false(any(atualizacao$mudou))
  httr2::local_mocked_responses(responder_com(corpos, especiais = list(
    conferencia = function() httr2::response(status_code = 200, body = charToRaw('"tabela","md5"\n"cfop","x"\n'))
  )))
  expect_true(all(tabelas_atualizar()$problema == "a lista de confer\u00eancia do reposit\u00f3rio veio fora do formato"))
})

test_that("as baixadas valem pela vers\u00e3o do conjunto, n\u00e3o pela data dos arquivos", {
  skip_if_not_installed("httr2")
  pasta = tempfile("cache_do_rnfe_")
  antes = apontar_o_cache_para(pasta)
  on.exit(voltar_o_cache(antes, pasta), add = TRUE)
  httr2::local_mocked_responses(responder_com(repositorio_de_mentira(VERSAO_NOVA)))
  tabelas_atualizar()
  baixadas = pasta_das_tabelas_baixadas()
  na_pasta_baixada = function(arquivo) startsWith(normalizePath(arquivo, winslash = "/"), normalizePath(baixadas, winslash = "/"))
  expect_true(na_pasta_baixada(arquivo_da_tabela("cst_icms")))
  # Um arquivo com data antiga continua valendo: a data não conta.
  Sys.setFileTime(file.path(baixadas, "cst_icms.csv"), as.POSIXct("2020-01-01"))
  rm(list = ls(tabelas_ja_lidas), envir = tabelas_ja_lidas)
  expect_true(na_pasta_baixada(arquivo_da_tabela("cst_icms")))
  # Um conjunto mais velho que o do pacote não vale.
  arquivo_da_lista = file.path(baixadas, "conferencia.csv")
  lista = utils::read.csv(arquivo_da_lista, colClasses = "character")
  lista$versao_do_conjunto = "2000-01-01 00:00:00"
  utils::write.csv(lista, arquivo_da_lista, row.names = FALSE)
  rm(list = ls(tabelas_ja_lidas), envir = tabelas_ja_lidas)
  expect_identical(arquivo_da_tabela("cst_icms"), ARQUIVO_DO_CST_ICMS_DO_PACOTE)
  # Mais novo, vale; mas a tabela com outras colunas que a do pacote fica com a do pacote.
  lista$versao_do_conjunto = VERSAO_NOVA
  utils::write.csv(lista, arquivo_da_lista, row.names = FALSE)
  writeLines(c('"codigo","outra_coluna"', '"00","x"'), file.path(baixadas, "cst_icms.csv"))
  rm(list = ls(tabelas_ja_lidas), envir = tabelas_ja_lidas)
  expect_identical(arquivo_da_tabela("cst_icms"), ARQUIVO_DO_CST_ICMS_DO_PACOTE)
  expect_true(na_pasta_baixada(arquivo_da_tabela("cst_ipi")))
})

test_that("a troca que falha deixa as tabelas como estavam", {
  skip_if_not_installed("httr2")
  pasta = tempfile("cache_do_rnfe_")
  antes = apontar_o_cache_para(pasta)
  on.exit(voltar_o_cache(antes, pasta), add = TRUE)
  httr2::local_mocked_responses(responder_com(repositorio_de_mentira(VERSAO_NOVA, list(
    cst_icms = texto_trocado("cst_icms", "Tributada integralmente", "Tributada integralmente (primeira)")
  ))))
  tabelas_atualizar()
  # A segunda atualização não consegue pôr a pasta nova no lugar (no Windows, um arquivo aberto por outro programa):
  # a primeira renomeação (a em uso sai do caminho) dá certo, a segunda não, e a em uso volta.
  renomeacoes = 0
  local_mocked_bindings(renomear = function(de, para) {
    renomeacoes <<- renomeacoes + 1
    if (renomeacoes == 2) {
      return(FALSE)
    }
    suppressWarnings(file.rename(de, para))
  })
  httr2::local_mocked_responses(responder_com(repositorio_de_mentira("2100-01-01 00:00:00", list(
    cst_icms = texto_trocado("cst_icms", "Tributada integralmente", "Tributada integralmente (segunda)")
  ))))
  atualizacao = tabelas_atualizar()
  expect_true(all(atualizacao$problema == "n\u00e3o deu para trocar as tabelas: a pasta nova n\u00e3o p\u00f4de entrar no lugar"))
  expect_false(any(atualizacao$mudou))
  expect_identical(tabela_fiscal("cst_icms")$descricao[1], "Tributada integralmente (primeira)")
  expect_false(dir.exists(paste0(pasta_das_tabelas_baixadas(), "_preparando")))
  # A volta às do pacote que não consegue apagar a pasta dá erro, em vez de seguir com as baixadas sem dizer.
  local_mocked_bindings(apagar_pasta = function(pasta) FALSE)
  expect_error(tabelas_atualizar(usar_as_do_pacote = TRUE), "N\u00e3o deu para apagar as tabelas baixadas")
})
