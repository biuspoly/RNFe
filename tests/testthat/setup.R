# Os testes nunca usam a pasta de cache do R de quem roda: uma cópia baixada por tabelas_atualizar() faria as tabelas
# lidas não serem as do pacote. Durante todos os testes ela é uma pasta temporária, e no fim volta a de antes.
withr::local_envvar(R_USER_CACHE_DIR = file.path(tempdir(), "cache_dos_testes_do_rnfe"),
                    .local_envir = testthat::teardown_env())
rm(list = ls(tabelas_ja_lidas), envir = tabelas_ja_lidas)
