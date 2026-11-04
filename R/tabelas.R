# Tabelas fiscais: as cópias das fontes oficiais que vão dentro do pacote (inst/extdata/tabelas),
# geradas por ferramentas/gerar_tabelas.R.

NOMES_DAS_TABELAS = c(
  "cfop", "ncm", "origem", "cst_icms", "csosn", "cst_ipi", "cst_pis", "cst_cofins", "cst_ibs_cbs",
  "classificacao_ibs_cbs", "meios_pagamento", "bandeiras_cartao", "municipios", "codigos_dos_campos", "fontes"
)
COLUNAS_DE_DATA = c("inicio", "fim", "data_da_versao", "baixada_em")
COLUNAS_DE_INDICADOR = c(
  "permitido_na_nfe", "permitido_na_nfce", "comunicacao", "transporte", "devolucao", "retorno", "anulacao",
  "remessa", "combustivel", "exclusivo_ibs_cbs"
)
COLUNAS_DE_NUMERO = c("reducao_ibs", "reducao_cbs")
# Cada tabela é lida do disco uma vez por sessão.
tabelas_ja_lidas = new.env(parent = emptyenv())
# As tabelas que tabelas_atualizar() baixa: as fiscais e os endereços da SEFAZ. Vêm do ramo main do repositório, onde
# só entram depois de uma pessoa conferir o que o robô semanal achou nas fontes oficiais.
TABELAS_QUE_SE_ATUALIZAM = c(NOMES_DAS_TABELAS, "servicos_sefaz", "autorizadores_sefaz")
ENDERECO_DAS_TABELAS_NO_REPOSITORIO = "https://raw.githubusercontent.com/biuspoly/RNFe/main/inst/extdata/tabelas/"

#' Tabelas fiscais: CFOP, NCM, CSTs, IBS e CBS, pagamentos, municípios e o significado de cada código
#'
#' Devolve uma tabela de códigos dos documentos fiscais, copiada da fonte
#' oficial. Escolha pelo nome: `"cfop"`, `"ncm"`, `"origem"`, `"cst_icms"`,
#' `"csosn"`, `"cst_ipi"`, `"cst_pis"`, `"cst_cofins"`, `"cst_ibs_cbs"`,
#' `"classificacao_ibs_cbs"`, `"meios_pagamento"`, `"bandeiras_cartao"`,
#' `"municipios"`, `"codigos_dos_campos"` (o que quer dizer cada código dos
#' campos dos documentos) ou `"fontes"` (de onde veio cada uma, com a data).
#' Cada tabela de códigos traz o `codigo`, a descrição e a vigência:
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
#' - `"meios_pagamento"`: os meios de pagamento da tabela do Portal da NF-e
#'   (dinheiro, cartão, boleto, PIX...), com a `observacao` de quando usar
#'   cada um. É o código do `tPag` da NF-e e do meio de pagamento vinculado da
#'   Reforma (`tpMeioPgto`).
#' - `"bandeiras_cartao"`: as bandeiras de cartão de crédito e débito da
#'   tabela do Portal da NF-e (o `tBand`).
#' - `"codigos_dos_campos"`: o que quer dizer cada código dos campos dos
#'   documentos que não têm tabela própria (forma de emissão, finalidade,
#'   modal, tipo de carga, regime do Simples Nacional...): `documento`
#'   (`"NF-e"`, `"CT-e"`, `"MDF-e"`, `"NFS-e"` ou `"evento"`), `campo` (o nome
#'   no leiaute, como `tpEmis`), `contexto` (quando o significado depende de
#'   outra coisa: o modelo do CT-e ou o grupo do documento), `codigo` e
#'   `descricao`. Os textos vêm da documentação dos schemas oficiais; os
#'   leitores os põem ao lado de cada coluna de código (`*_descricao`).
#' - `"municipios"`: os municípios vigentes do IBGE, com o `codigo` de 7
#'   dígitos que vai nos documentos (`cMun`, `cMunFG`, `cLocIncid`...), o `nome`,
#'   a `uf` e o `codigo_uf` (o que abre a chave de acesso). Sem datas: o IBGE só
#'   publica a lista de hoje. O código 9999999, que a NF-e usa para o exterior,
#'   não é do IBGE e não está nela.
#' - `"fontes"`: de onde veio cada tabela, com a versão e o dia em que foi
#'   baixada.
#'
#' As tabelas vêm dentro do pacote. Para usar as mais novas sem esperar uma
#' versão nova, chame [tabelas_atualizar()]: a partir daí, elas vêm da cópia
#' baixada do repositório do RNFe.
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
#'   (cClassTrib da Reforma), `"meios_pagamento"` (dinheiro, cartão, PIX...),
#'   `"bandeiras_cartao"`, `"municipios"` (código IBGE, nome e UF),
#'   `"codigos_dos_campos"` (o significado dos códigos dos documentos) ou
#'   `"fontes"` (de onde veio cada tabela).
#' @return Um `data.frame` com `codigo`, a descrição (`titulo` e
#'   `nota_explicativa` no CFOP, `nome` nos municípios, `descricao` nas outras),
#'   `inicio` e `fim`.
#' @source CFOP: a Tabela de CFOP do Portal Nacional da NF-e (Informe Técnico
#'   2023.002, publicada em 04/09/2026). IBS e CBS: a Tabela de Classificação
#'   Tributária do Portal da NF-e (Informe Técnico 2025.002, publicada em
#'   30/10/2026). NCM: a nomenclatura vigente do Portal Único Siscomex
#'   (30/10/2026). Municípios: a API de localidades do IBGE
#'   (servicodados.ibge.gov.br, 30/10/2026). Meios de pagamento e bandeiras de
#'   cartão: as tabelas do Portal da NF-e (publicadas em 06/03/2026 e
#'   16/03/2021). Códigos dos campos: a documentação dos schemas oficiais que os
#'   leitores seguem, conferida por `ferramentas/conferir_codigos_dos_campos.R`;
#'   o tipo de transportador do MDF-e, pela Lei 11.442/2007 (art. 2º), e a
#'   tributação do ISSQN da NFS-e (`tribISSQN`), pelo Anexo I do leiaute da
#'   NFS-e Nacional, que corrige a ordem errada da documentação do schema 1.00.
#'   Origem e CSTs do ICMS, do IPI, do PIS e da COFINS: as tabelas externas do SPED
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
  arquivo_csv = arquivo_da_tabela(nome_da_tabela)
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

# O arquivo da tabela: a cópia que tabelas_atualizar() baixou, quando ela é mais nova que a instalação do pacote; senão,
# a do pacote. Quem instala uma versão nova do pacote volta a ter as tabelas dela, até atualizar de novo.
arquivo_da_tabela = function(nome_da_tabela) {
  do_pacote = system.file("extdata", "tabelas", paste0(nome_da_tabela, ".csv"), package = "RNFe")
  baixado = file.path(pasta_das_tabelas_baixadas(), paste0(nome_da_tabela, ".csv"))
  # O DESCRIPTION do pacote instalado é gravado na instalação.
  instalado_em = file.mtime(system.file("DESCRIPTION", package = "RNFe"))
  if (file.exists(baixado) && !is.na(instalado_em) && file.mtime(baixado) > instalado_em) {
    return(baixado)
  }
  do_pacote
}

pasta_das_tabelas_baixadas = function() {
  file.path(tools::R_user_dir("RNFe", which = "cache"), "tabelas")
}

#' Atualizar as tabelas fiscais pelo repositório do RNFe
#'
#' Baixa as tabelas fiscais (as de [tabela_fiscal()]) e os endereços da SEFAZ
#' do repositório do RNFe no GitHub e passa a usá-las no lugar das que vieram
#' no pacote. Lá, um robô confere toda semana as fontes oficiais (o Portal da
#' NF-e, o SPED, o Siscomex, o IBGE), e uma pessoa junta ao repositório o que
#' mudou depois de conferir: assim as tabelas ficam em dia sem esperar uma
#' versão nova do pacote.
#'
#' Nada é baixado sem esta função ser chamada. As tabelas ficam na pasta de
#' cache do R para o RNFe ([tools::R_user_dir()]) e valem para as próximas
#' sessões também. Uma tabela só é trocada quando a nova tem as mesmas colunas
#' que a do pacote; se o formato mudou, ela fica como está, e o resultado diz
#' que é preciso atualizar o pacote. Quem instala uma versão nova do pacote
#' volta a ter as tabelas dela, que já vêm atualizadas, até chamar esta função
#' de novo.
#'
#' Precisa do pacote `httr2`.
#'
#' @param usar_as_do_pacote `TRUE` apaga as tabelas baixadas e volta a usar as
#'   que vieram no pacote, sem baixar nada.
#' @return Um `data.frame` com uma linha por tabela: `tabela`,
#'   `linhas_antes` (as da tabela em uso antes de baixar), `linhas_agora`,
#'   `mudou` (`TRUE` quando a tabela baixada é diferente da que estava em uso)
#'   e `problema` (por que a tabela não foi trocada; vazio quando foi). Com
#'   `usar_as_do_pacote = TRUE`, nada (invisível).
#' @seealso [tabela_fiscal()]
#' @examples
#' \dontrun{
#' atualizacao = tabelas_atualizar()
#' atualizacao[atualizacao$mudou, ]
#' tabela_fiscal("fontes")   # de onde veio e quando foi baixada cada tabela
#' tabelas_atualizar(usar_as_do_pacote = TRUE)   # volta às do pacote
#' }
#' @export
tabelas_atualizar = function(usar_as_do_pacote = FALSE) {
  if (!isTRUE(usar_as_do_pacote) && !isFALSE(usar_as_do_pacote)) {
    stop("Informe usar_as_do_pacote = TRUE ou FALSE.", call. = FALSE)
  }
  pasta = pasta_das_tabelas_baixadas()
  if (usar_as_do_pacote) {
    unlink(pasta, recursive = TRUE)
    rm(list = ls(tabelas_ja_lidas), envir = tabelas_ja_lidas)
    return(invisible(NULL))
  }
  exigir_pacotes("httr2")
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  linhas = list()
  for (nome_da_tabela in TABELAS_QUE_SE_ATUALIZAM) {
    linhas[[length(linhas) + 1]] = atualizar_uma_tabela(nome_da_tabela, pasta)
  }
  # A próxima leitura de cada tabela já pega a nova.
  rm(list = ls(tabelas_ja_lidas), envir = tabelas_ja_lidas)
  do.call(rbind, linhas)
}

# Baixa uma tabela e a grava na pasta, se ela abre e tem as colunas da do pacote. Grava num arquivo temporário e só
# depois troca, para uma tabela pela metade nunca ficar no lugar.
atualizar_uma_tabela = function(nome_da_tabela, pasta) {
  em_uso = utils::read.csv(arquivo_da_tabela(nome_da_tabela), colClasses = "character", fileEncoding = "UTF-8", na.strings = "")
  do_pacote = utils::read.csv(system.file("extdata", "tabelas", paste0(nome_da_tabela, ".csv"), package = "RNFe"),
                              colClasses = "character", fileEncoding = "UTF-8", na.strings = "", nrows = 1)
  linha = data.frame(tabela = nome_da_tabela, linhas_antes = nrow(em_uso), linhas_agora = nrow(em_uso), mudou = FALSE,
                     problema = NA_character_)
  pedido = httr2::request(paste0(ENDERECO_DAS_TABELAS_NO_REPOSITORIO, nome_da_tabela, ".csv"))
  pedido = httr2::req_user_agent(pedido, "RNFe (https://github.com/biuspoly/RNFe)")
  pedido = httr2::req_timeout(pedido, 120)
  pedido = httr2::req_error(pedido, is_error = function(resposta) FALSE)
  resposta = tryCatch(httr2::req_perform(pedido), error = function(erro) erro)
  if (inherits(resposta, "error")) {
    linha$problema = paste("n\u00e3o baixou:", gsub("\\s+", " ", conditionMessage(resposta)))
    return(linha)
  }
  if (httr2::resp_status(resposta) != 200 || !httr2::resp_has_body(resposta)) {
    linha$problema = paste("n\u00e3o baixou: HTTP", httr2::resp_status(resposta))
    return(linha)
  }
  temporario = file.path(pasta, paste0(nome_da_tabela, ".csv.baixando"))
  writeBin(httr2::resp_body_raw(resposta), temporario)
  baixada = tryCatch(utils::read.csv(temporario, colClasses = "character", fileEncoding = "UTF-8", na.strings = ""),
                     error = function(erro) NULL)
  if (is.null(baixada) || nrow(baixada) == 0) {
    unlink(temporario)
    linha$problema = "a tabela baixada n\u00e3o abriu ou veio vazia"
    return(linha)
  }
  if (!identical(names(baixada), names(do_pacote))) {
    unlink(temporario)
    linha$problema = "a tabela mudou de formato: atualize o pacote RNFe para usar a nova"
    return(linha)
  }
  file.rename(temporario, file.path(pasta, paste0(nome_da_tabela, ".csv")))
  linha$linhas_agora = nrow(baixada)
  linha$mudou = !identical(baixada, em_uso)
  linha
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
