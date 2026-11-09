# As datas da Reforma que a conferência e o cálculo usam vêm da tabela_fiscal("marcos_ibs_cbs"), nunca escritas no
# código: quando a lei ou a NT muda uma data, muda a linha da tabela, e tabelas_atualizar() leva a mudança a quem já
# tem o pacote. Cada marco é o primeiro dia em que a mudança vale; "até o marco" é até a véspera dele.

#' @include tabelas.R
NULL

marco_da_reforma = function(nome_do_marco) {
  marcos = tabela_fiscal("marcos_ibs_cbs")
  linha = match(nome_do_marco, marcos$marco)
  if (is.na(linha) || is.na(marcos$inicio[linha])) {
    stop("O marco \"", nome_do_marco, "\" n\u00e3o est\u00e1 na tabela_fiscal(\"marcos_ibs_cbs\"), ou est\u00e1 sem a data.",
         call. = FALSE)
  }
  marcos$inicio[linha]
}

# O marco começa no dia 1º de janeiro: o texto fala do ano; senão, da data.
marco_no_comeco_do_ano = function(data_do_marco) {
  format(data_do_marco, "%m-%d") == "01-01"
}

# "a partir de 2029", ou "a partir de 16/11/2026" quando o marco não começa num 1º de janeiro.
texto_a_partir_do_marco = function(nome_do_marco) {
  data_do_marco = marco_da_reforma(nome_do_marco)
  if (marco_no_comeco_do_ano(data_do_marco)) {
    return(paste0("a partir de ", format(data_do_marco, "%Y")))
  }
  paste0("a partir de ", format(data_do_marco, "%d/%m/%Y"))
}

# "até 2028" (o ano antes do marco), ou "até 15/11/2026" (a véspera) quando o marco não começa num 1º de janeiro.
texto_ate_o_marco = function(nome_do_marco) {
  data_do_marco = marco_da_reforma(nome_do_marco)
  if (marco_no_comeco_do_ano(data_do_marco)) {
    return(paste0("at\u00e9 ", as.integer(format(data_do_marco, "%Y")) - 1))
  }
  paste0("at\u00e9 ", format(data_do_marco - 1, "%d/%m/%Y"))
}

# "de 2025 a 2033", do primeiro marco até a véspera do segundo.
texto_entre_os_marcos = function(nome_do_comeco, nome_do_fim) {
  comeco = marco_da_reforma(nome_do_comeco)
  fim = marco_da_reforma(nome_do_fim)
  if (marco_no_comeco_do_ano(comeco) && marco_no_comeco_do_ano(fim)) {
    return(paste0("de ", format(comeco, "%Y"), " a ", as.integer(format(fim, "%Y")) - 1))
  }
  paste0("de ", format(comeco, "%d/%m/%Y"), " a ", format(fim - 1, "%d/%m/%Y"))
}
