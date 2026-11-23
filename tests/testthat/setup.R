# As tabelas internas lidas ficam guardadas na sessão: cada rodada de testes começa sem nenhuma.
rm(list = ls(tabelas_ja_lidas), envir = tabelas_ja_lidas)
