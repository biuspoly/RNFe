# Tabelas fiscais: as cópias das fontes oficiais que vão dentro do pacote (inst/extdata/tabelas),
# geradas por ferramentas/gerar_tabelas.R.

NOMES_DAS_TABELAS = c(
  "cfop", "ncm", "origem", "cst_icms", "csosn", "cst_ipi", "cst_pis", "cst_cofins", "cst_ibs_cbs",
  "classificacao_ibs_cbs", "municipios", "fontes"
)
COLUNAS_DE_DATA = c("inicio", "fim", "data_da_versao", "baixada_em")
COLUNAS_DE_INDICADOR = c(
  "permitido_na_nfe", "permitido_na_nfce", "comunicacao", "transporte", "devolucao", "retorno", "anulacao",
  "remessa", "combustivel", "exclusivo_ibs_cbs"
)
COLUNAS_DE_NUMERO = c("reducao_ibs", "reducao_cbs")
# Cada tabela é lida do disco uma vez por sessão.
tabelas_ja_lidas = new.env(parent = emptyenv())

#' Tabelas fiscais: CFOP, NCM, CSTs, IBS e CBS e municípios
#'
#' Devolve uma tabela de códigos dos documentos fiscais, copiada da fonte
#' oficial. Escolha pelo nome: `"cfop"`, `"ncm"`, `"origem"`, `"cst_icms"`,
#' `"csosn"`, `"cst_ipi"`, `"cst_pis"`, `"cst_cofins"`, `"cst_ibs_cbs"`,
#' `"classificacao_ibs_cbs"`, `"municipios"` ou `"fontes"` (de onde veio cada
#' uma, com a data). Cada tabela de códigos traz o `codigo`, a descrição e a vigência:
#' `inicio` (desde quando vale) e `fim` (até quando valeu, vazio quando ainda
#' vale). Um código que mudou de descrição tem uma linha por período.
#'
#' O que cada tabela tem:
#' - `"cfop"`: os CFOP aceitos hoje na NF-e, com o `titulo` e a
#'   `nota_explicativa` literais do Anexo II do Convênio SINIEF s/nº de 1970 e
#'   os indicadores da tabela da NF-e (1 = sim): `permitido_na_nfe`,
#'   `comunicacao`, `transporte`, `devolucao`, `retorno`, `anulacao`,
#'   `remessa`, `combustivel` (0, 1 ou 2, como na tabela oficial) e
#'   `exclusivo_ibs_cbs`. A tabela oficial só traz os códigos vigentes: um CFOP
#'   revogado não está nela.
#' - `"ncm"`: a nomenclatura vigente, em todos os níveis (capítulo, posição,
#'   subposição, item e subitem), com o código sem os pontos, como na NF-e, e o
#'   ato que criou cada linha (`ato_inicio`). Ao ler, ganha a
#'   `descricao_completa`, que junta a descrição da posição com a de cada nível
#'   abaixo dela (sozinho, o subitem costuma dizer só "-- Outros"). Só traz os
#'   códigos vigentes, desde a versão atual da NCM (01/04/2022).
#' - `"origem"`: a origem da mercadoria (o primeiro dígito do CST do ICMS). Os
#'   códigos 0 a 2 mudaram de descrição em 2013, quando vieram os de 3 a 8.
#' - `"cst_icms"`: o CST do ICMS, de dois dígitos, como vai na NF-e.
#' - `"csosn"`: o código do Simples Nacional, sem datas (veja abaixo).
#' - `"cst_ipi"`, `"cst_pis"` e `"cst_cofins"`: o CST de cada um.
#' - `"cst_ibs_cbs"`: o CST do IBS e da CBS (Reforma Tributária).
#' - `"classificacao_ibs_cbs"`: a classificação tributária do IBS e da CBS
#'   (`cClassTrib`), com o `cst` dela, o `nome`, a `descricao`, o artigo da LC
#'   214/2025 (`artigo_lc_214`), o `tipo_aliquota`, os percentuais de redução
#'   (`reducao_ibs` e `reducao_cbs`) e se vale na NF-e e na NFC-e.
#' - `"municipios"`: os municípios vigentes do IBGE, com o `codigo` de 7
#'   dígitos que vai nos documentos (`cMun`, `cMunFG`, `cLocIncid`...), o `nome`,
#'   a `uf` e o `codigo_uf` (o que abre a chave de acesso). Sem datas: o IBGE só
#'   publica a lista de hoje. O código 9999999, que a NF-e usa para o exterior,
#'   não é do IBGE e não está nela.
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
#' @param nome_da_tabela Qual tabela: `"cfop"` (CFOP), `"ncm"` (NCM),
#'   `"origem"` (origem da mercadoria), `"cst_icms"` (CST do ICMS), `"csosn"`
#'   (CSOSN, do Simples Nacional), `"cst_ipi"`, `"cst_pis"`, `"cst_cofins"`,
#'   `"cst_ibs_cbs"` (CST do IBS e da CBS), `"classificacao_ibs_cbs"`
#'   (cClassTrib da Reforma), `"municipios"` (código IBGE, nome e UF) ou
#'   `"fontes"` (de onde veio cada tabela).
#' @return Um `data.frame` com `codigo`, a descrição (`titulo` e
#'   `nota_explicativa` no CFOP, `nome` nos municípios, `descricao` nas outras),
#'   `inicio` e `fim`.
#' @source CFOP: a Tabela de CFOP do Portal Nacional da NF-e (Informe Técnico
#'   2023.002, publicada em 04/09/2026). IBS e CBS: a Tabela de Classificação
#'   Tributária do Portal da NF-e (Informe Técnico 2025.002, publicada em
#'   01/10/2026). NCM: a nomenclatura vigente do Portal Único Siscomex
#'   (29/10/2026). Municípios: a API de localidades do IBGE
#'   (servicodados.ibge.gov.br, 30/10/2026). Origem e CSTs do ICMS, do IPI, do PIS e da COFINS: as tabelas externas do SPED
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
tabela_fiscal = function(nome_da_tabela) {
  if (length(nome_da_tabela) != 1 || !(nome_da_tabela %in% NOMES_DAS_TABELAS)) {
    stop(
      "Tabela desconhecida: ", paste(nome_da_tabela, collapse = ", "), ". As tabelas s\u00e3o: ",
      paste(NOMES_DAS_TABELAS, collapse = ", "),
      call. = FALSE
    )
  }
  if (is.null(tabelas_ja_lidas[[nome_da_tabela]])) {
    tabelas_ja_lidas[[nome_da_tabela]] = ler_tabela_do_pacote(nome_da_tabela)
  }
  tabelas_ja_lidas[[nome_da_tabela]]
}

ler_tabela_do_pacote = function(nome_da_tabela) {
  arquivo_csv = system.file("extdata", "tabelas", paste0(nome_da_tabela, ".csv"), package = "RNfe")
  tabela_do_pacote = utils::read.csv(arquivo_csv, colClasses = "character", fileEncoding = "UTF-8", na.strings = "")
  for (nome_da_coluna in names(tabela_do_pacote)) {
    if (nome_da_coluna %in% COLUNAS_DE_DATA) {
      tabela_do_pacote[[nome_da_coluna]] = as.Date(tabela_do_pacote[[nome_da_coluna]])
    } else if (nome_da_coluna %in% COLUNAS_DE_INDICADOR) {
      tabela_do_pacote[[nome_da_coluna]] = as.integer(tabela_do_pacote[[nome_da_coluna]])
    } else if (nome_da_coluna %in% COLUNAS_DE_NUMERO) {
      tabela_do_pacote[[nome_da_coluna]] = as.numeric(tabela_do_pacote[[nome_da_coluna]])
    }
  }
  if (nome_da_tabela == "ncm") {
    tabela_do_pacote$descricao_completa = descricao_completa_do_ncm(tabela_do_pacote)
  }
  tabela_do_pacote
}

# No NCM, o subitem diz pouco sozinho ("-- Outros"). A descrição completa junta a da posição (4 dígitos)
# com a de cada nível abaixo dela, até o próprio código. O capítulo (2 dígitos) fica com a dele.
descricao_completa_do_ncm = function(ncm) {
  descricoes_completas = rep("", nrow(ncm))
  for (tamanho in 4:8) {
    descricao_do_nivel = ncm$descricao[match(substr(ncm$codigo, 1, tamanho), ncm$codigo)]
    tem_o_nivel = nchar(ncm$codigo) >= tamanho & !is.na(descricao_do_nivel)
    descricoes_completas[tem_o_nivel] = trimws(paste(descricoes_completas[tem_o_nivel], descricao_do_nivel[tem_o_nivel]))
  }
  sem_nivel_abaixo_do_capitulo = descricoes_completas == ""
  descricoes_completas[sem_nivel_abaixo_do_capitulo] = ncm$descricao[sem_nivel_abaixo_do_capitulo]
  descricoes_completas
}

# O texto de cada código como a tabela registrava na data de cada nota. Código que a tabela não tem, ou
# data fora do período em que ela registra o código (antes do início ou depois do fim), fica NA.
descricao_na_data = function(nome_da_tabela, codigos, datas, coluna_do_texto = "descricao") {
  tabela_completa = tabela_fiscal(nome_da_tabela)
  linhas_dos_codigos = tabela_completa[tabela_completa$codigo %in% codigos, ]
  descricoes = rep(NA_character_, length(codigos))
  for (numero_da_linha in seq_len(nrow(linhas_dos_codigos))) {
    do_codigo = !is.na(codigos) & codigos == linhas_dos_codigos$codigo[numero_da_linha]
    ja_valia = is.na(linhas_dos_codigos$inicio[numero_da_linha]) | (!is.na(datas) & datas >= linhas_dos_codigos$inicio[numero_da_linha])
    ainda_valia = is.na(linhas_dos_codigos$fim[numero_da_linha]) | (!is.na(datas) & datas <= linhas_dos_codigos$fim[numero_da_linha])
    descricoes[do_codigo & ja_valia & ainda_valia] = linhas_dos_codigos[[coluna_do_texto]][numero_da_linha]
  }
  descricoes
}
