# As datas da Reforma vêm da tabela_fiscal("marcos_ibs_cbs"), não do código: mudar uma data é mudar a linha da tabela.
ARQUIVOS_DA_REFORMA = c("ibs_cbs_conferir.R", "ibs_cbs_calcular.R", "ibs_cbs_monofasico.R", "ibs_cbs_regras_da_nota.R",
                        "efd_icms_ipi_cruzar_nfe.R", "ibs_cbs_marcos.R")

# As linhas de código (sem os comentários) dos arquivos da Reforma, quando o código-fonte está à mão.
linhas_de_codigo_da_reforma = function() {
  pasta_do_codigo = test_path("..", "..", "R")
  linhas = character()
  for (arquivo in ARQUIVOS_DA_REFORMA) {
    caminho = file.path(pasta_do_codigo, arquivo)
    if (file.exists(caminho)) {
      todas = readLines(caminho, encoding = "UTF-8")
      linhas = c(linhas, todas[!grepl("^\\s*#", todas)])
    }
  }
  linhas
}

# Troca, na memória da sessão, a tabela dos marcos que a conferência e o cálculo leem.
usar_estes_marcos = function(marcos) {
  tabelas_ja_lidas[["marcos_ibs_cbs"]] = marcos
}

test_that("a tabela dos marcos: um nome por linha, todos com a data e a base legal", {
  marcos = tabela_fiscal("marcos_ibs_cbs")
  expect_identical(names(marcos), c("marco", "inicio", "descricao", "base_legal", "usado_em"))
  expect_s3_class(marcos$inicio, "Date")
  expect_false(anyNA(marcos$inicio))
  expect_false(any(duplicated(marcos$marco)))
  expect_false(anyNA(marcos$base_legal))
  expect_identical(marco_da_reforma("nota_de_credito_02_desde"), as.Date("2029-01-01"))
  expect_error(marco_da_reforma("nao_existe"), "n\u00e3o est\u00e1 na tabela")
})

test_that("o texto de cada marco: pelo ano no 1\u00ba de janeiro, pela data nos outros dias", {
  expect_identical(texto_a_partir_do_marco("nota_de_credito_02_desde"), "a partir de 2029")
  expect_identical(texto_ate_o_marco("ibs_monofasico_ad_rem_desde"), "at\u00e9 2028")
  expect_identical(texto_entre_os_marcos("inicio_do_calculo", "fim_do_calculo"), "de 2025 a 2033")
  expect_identical(texto_a_partir_do_marco("devolucao_nova_desde"), "a partir de 16/11/2026")
  expect_identical(texto_ate_o_marco("devolucao_nova_desde"), "at\u00e9 15/11/2026")
})

test_that("nenhum ano da Reforma escrito no c\u00f3digo, e todo marco usado est\u00e1 na tabela", {
  linhas = linhas_de_codigo_da_reforma()
  # No pacote instalado (o R CMD check) o código-fonte não está aqui: o teste vale onde está.
  if (length(linhas) > 0) {
    com_ano = linhas[grepl("(?<![0-9.])20(2[5-9]|3[0-9])(?![0-9.])", linhas, perl = TRUE)]
    expect_identical(com_ano, character())
    texto_do_codigo = paste(linhas, collapse = "\n")
    chamados = regmatches(texto_do_codigo, gregexpr("(marco_da_reforma|_marco|_marcos)\\(\"[a-z0-9_]+\"", texto_do_codigo))[[1]]
    nomes_chamados = unique(sub("^.*\\(\"", "", sub("\"$", "", chamados)))
    nomes_chamados = c(nomes_chamados, COMPONENTES_DA_BASE$entra_no_marco, COMPONENTES_DA_BASE$sai_no_marco)
    marcos = tabela_fiscal("marcos_ibs_cbs")
    expect_identical(setdiff(nomes_chamados, marcos$marco), character())
    # E todo marco da tabela é usado em algum lugar (os do texto entre dois marcos aparecem como o segundo argumento).
    sem_uso = marcos$marco[!vapply(marcos$marco, grepl, logical(1), x = texto_do_codigo, fixed = TRUE)]
    expect_identical(sem_uso, character())
  }
})

test_that("as regras de implementa\u00e7\u00e3o futura est\u00e3o na tabela sem data, e o c\u00f3digo ainda n\u00e3o as usa", {
  regras = tabela_fiscal("regras_ibs_cbs")
  futuras = regras[is.na(regras$em_producao_desde), ]
  expect_identical(nrow(futuras), 31L)
  expect_true(all(c("UB01-10", "UB16-10", "UB13-40", "W60-10", "11BC01-30") %in% futuras$regra))
  expect_true(all(grepl("mplementa\u00e7\u00e3o futura", futuras$observacao)))
  expect_false(any(duplicated(regras$regra)))
  linhas = linhas_de_codigo_da_reforma()
  if (length(linhas) > 0) {
    texto_do_codigo = paste(linhas, collapse = "\n")
    usadas = futuras$regra[vapply(paste0("\"", futuras$regra, "\""), grepl, logical(1), x = texto_do_codigo, fixed = TRUE)]
    # Quem passar a conferir uma regra futura põe também a data de produção dela na tabela.
    expect_identical(usadas, character())
  }
})

test_that("mudar a data na tabela muda o resultado, sem mexer no c\u00f3digo", {
  item = data.frame(cst_ibs_cbs = "000", classificacao_ibs_cbs = "000001", valor_produto = 100, valor_pis = 1.65)
  # Em 2026 o PIS sai da base (até o marco fim_do_pis_e_da_cofins_na_base, em 2027).
  expect_equal(ibs_cbs_calcular(item, data = "2026-11-04")$itens$base, 98.35)
  marcos_do_pacote = tabela_fiscal("marcos_ibs_cbs")
  marcos_com_outra_data = marcos_do_pacote
  marcos_com_outra_data$inicio[marcos_com_outra_data$marco == "fim_do_pis_e_da_cofins_na_base"] = as.Date("2026-06-01")
  usar_estes_marcos(marcos_com_outra_data)
  base_com_outra_data = tryCatch(ibs_cbs_calcular(item, data = "2026-11-04")$itens$base,
                                 finally = usar_estes_marcos(marcos_do_pacote))
  expect_equal(base_com_outra_data, 100)
  expect_identical(tabela_fiscal("marcos_ibs_cbs"), marcos_do_pacote)
})
