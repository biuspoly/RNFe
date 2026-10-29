# Tabelas fiscais: as cópias das fontes oficiais que vão dentro do pacote (inst/extdata/tabelas),
# geradas por ferramentas/gerar_tabelas.R.

NOMES_DAS_TABELAS = c("cfop", "origem", "cst_icms", "csosn", "cst_ipi", "cst_pis", "cst_cofins", "fontes")
COLUNAS_DE_DATA = c("inicio", "fim", "data_da_versao", "baixada_em")
COLUNAS_DE_INDICADOR = c(
  "permitido_na_nfe", "comunicacao", "transporte", "devolucao", "retorno", "anulacao", "remessa",
  "combustivel", "exclusivo_ibs_cbs"
)
# Cada tabela é lida do disco uma vez por sessão.
tabelas_ja_lidas = new.env(parent = emptyenv())

#' Tabelas fiscais
#'
#' As tabelas de códigos da NF-e, copiadas das fontes oficiais, com a data em
#' que cada linha passou a valer (`inicio`) e a última em que valeu (`fim`,
#' vazio quando ainda vale). Um código que mudou de descrição tem uma linha
#' por período.
#'
#' - `"cfop"`: os CFOP aceitos hoje na NF-e, com o `titulo` e a
#'   `nota_explicativa` literais do Anexo II do Convênio SINIEF s/nº de 1970 e
#'   os indicadores da tabela da NF-e (1 = sim): `permitido_na_nfe`,
#'   `comunicacao`, `transporte`, `devolucao`, `retorno`, `anulacao`,
#'   `remessa`, `combustivel` (0, 1 ou 2, como na tabela oficial) e
#'   `exclusivo_ibs_cbs`. A tabela oficial só traz os códigos vigentes: um CFOP
#'   revogado não está nela.
#' - `"origem"`: a origem da mercadoria (o primeiro dígito do CST do ICMS). Os
#'   códigos 0 a 2 mudaram de descrição em 2013, quando vieram os de 3 a 8.
#' - `"cst_icms"`: o CST do ICMS, de dois dígitos, como vai na NF-e.
#' - `"csosn"`: o código do Simples Nacional, sem datas (veja abaixo).
#' - `"cst_ipi"`, `"cst_pis"` e `"cst_cofins"`: o CST de cada um.
#' - `"fontes"`: de onde veio cada tabela, com a versão e o dia em que foi
#'   baixada.
#'
#' As tabelas do SPED começam em 2009, quando o SPED Fiscal começou: uma nota
#' mais antiga fica sem a descrição, em vez de receber uma que talvez não fosse
#' a da época. O CSOSN não tem datas porque as do SPED não servem para a NF-e:
#' lá o CSOSN e o CST dividem o mesmo campo, e o SPED encerrou o 300, o 400 e o
#' 500 em 2012 e o 102 e o 202 em 2023 só porque passaram a coincidir com CSTs
#' novos; na NF-e eles continuam aceitos.
#'
#' @param nome O nome da tabela: `"cfop"`, `"origem"`, `"cst_icms"`,
#'   `"csosn"`, `"cst_ipi"`, `"cst_pis"`, `"cst_cofins"` ou `"fontes"`.
#' @return Um `data.frame` com `codigo`, a descrição (`titulo` e
#'   `nota_explicativa` no CFOP, `descricao` nas outras), `inicio` e `fim`.
#' @source CFOP: a Tabela de CFOP do Portal Nacional da NF-e (Informe Técnico
#'   2023.002, publicada em 04/09/2026). As outras: as tabelas externas do SPED
#'   Fiscal (Receita Federal), versão de 28/10/2026, com a origem 8 e os CST de
#'   combustível monofásico (de 2023) tirados da tabela de CST de três dígitos,
#'   porque as tabelas A e B do SPED não foram atualizadas. A data de cada uma
#'   está em `tabela_fiscal("fontes")`.
#' @examples
#' tabela_fiscal("cst_icms")
#' cfop = tabela_fiscal("cfop")
#' cfop[cfop$codigo == "5102", c("codigo", "titulo")]
#' tabela_fiscal("fontes")
#' @export
tabela_fiscal = function(nome) {
  if (length(nome) != 1 || !(nome %in% NOMES_DAS_TABELAS)) {
    stop(
      "Tabela desconhecida: ", paste(nome, collapse = ", "), ". As tabelas s\u00e3o: ",
      paste(NOMES_DAS_TABELAS, collapse = ", "),
      call. = FALSE
    )
  }
  if (is.null(tabelas_ja_lidas[[nome]])) {
    tabelas_ja_lidas[[nome]] = ler_tabela_do_pacote(nome)
  }
  tabelas_ja_lidas[[nome]]
}

ler_tabela_do_pacote = function(nome) {
  arquivo = system.file("extdata", "tabelas", paste0(nome, ".csv"), package = "RNfe")
  tabela = utils::read.csv(arquivo, colClasses = "character", fileEncoding = "UTF-8", na.strings = "")
  for (nome_da_coluna in names(tabela)) {
    if (nome_da_coluna %in% COLUNAS_DE_DATA) {
      tabela[[nome_da_coluna]] = as.Date(tabela[[nome_da_coluna]])
    } else if (nome_da_coluna %in% COLUNAS_DE_INDICADOR) {
      tabela[[nome_da_coluna]] = as.integer(tabela[[nome_da_coluna]])
    }
  }
  tabela
}

# O texto de cada código como a tabela registrava na data de cada nota. Código que a tabela não tem, ou
# data fora do período em que ela registra o código (antes do início ou depois do fim), fica NA.
descricao_na_data = function(nome_da_tabela, codigos, datas, coluna_do_texto = "descricao") {
  tabela = tabela_fiscal(nome_da_tabela)
  tabela = tabela[tabela$codigo %in% codigos, ]
  descricoes = rep(NA_character_, length(codigos))
  for (numero_da_linha in seq_len(nrow(tabela))) {
    do_codigo = !is.na(codigos) & codigos == tabela$codigo[numero_da_linha]
    ja_valia = is.na(tabela$inicio[numero_da_linha]) | (!is.na(datas) & datas >= tabela$inicio[numero_da_linha])
    ainda_valia = is.na(tabela$fim[numero_da_linha]) | (!is.na(datas) & datas <= tabela$fim[numero_da_linha])
    descricoes[do_codigo & ja_valia & ainda_valia] = tabela[[coluna_do_texto]][numero_da_linha]
  }
  descricoes
}
