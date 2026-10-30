# Baixa as tabelas fiscais das fontes oficiais e grava as cópias que vão dentro do pacote
# (inst/extdata/tabelas). Uso, na raiz do repositório:
#   Rscript ferramentas/gerar_tabelas.R
# Precisa de internet e dos pacotes httr2, xml2, readxl e jsonlite (só esta ferramenta usa os dois últimos).
#
# Fontes:
# - CFOP: a Tabela de CFOP do Portal da NF-e (a do Informe Técnico 2023.002), com o título e a nota
#   explicativa literais do Convênio SINIEF s/nº de 1970 e o início de vigência de cada código.
# - Origem, CST do ICMS, CSOSN e CST do IPI, do PIS e da COFINS: as tabelas externas do SPED Fiscal, que a
#   Receita publica com o início e o fim de cada código, baixadas pelo serviço do próprio SPED.
# - CST e classificação tributária do IBS e da CBS: a tabela do Informe Técnico 2025.002, no Portal da NF-e.
# - NCM: a nomenclatura vigente do Portal Único Siscomex.
# - Meios de pagamento e bandeiras de cartão: as tabelas do Portal da NF-e (seção Diversos).
# - Municípios: a API de localidades do IBGE, que a NF-e, o CT-e, o MDF-e e a NFS-e usam para o código do
#   município.

PASTA_DAS_TABELAS = "inst/extdata/tabelas"
ENDERECO_DO_PORTAL = "https://www.nfe.fazenda.gov.br/portal/"
PAGINA_COM_A_TABELA_DE_CFOP = "listaConteudo.aspx?tipoConteudo=/NJarYc9nus="
SERVICO_DO_SPED = "http://www.sped.fazenda.gov.br/spedtabelas/WsConsulta/WsConsulta.asmx"
DOWNLOAD_DO_SPED = "http://www.sped.fazenda.gov.br/spedtabelas/wsconsulta/obterTabela.ashx"
ENDERECO_DA_NCM = "https://portalunico.siscomex.gov.br/classif/api/publico/nomenclatura/download/json"
# A visão nivelada traz a UF de todos os municípios. Na visão completa, a UF vem dentro da microrregião, e um
# município vinha sem microrregião em 30/10/2026: ficaria sem a UF.
ENDERECO_DOS_MUNICIPIOS = "https://servicodados.ibge.gov.br/api/v1/localidades/municipios?view=nivelado"
# O tipo de cada tabela no SPED Fiscal (atributo "tipo" dos metadados).
TABELAS_DO_SPED = c(
  origem = "SIT_TRIB_ICMS_A",
  cst_icms_b = "SIT_TRIB_ICMS_B",
  cst_icms_tres_digitos = "SIT_TRIB_ICMS",
  cst_ipi = "SIT_TRIB_IPI",
  cst_pis = "SIT_TRIB_PIS",
  cst_cofins = "SIT_TRIB_COFINS"
)

# ---- SPED ----

versoes_das_tabelas_do_sped = function() {
  corpo_do_pedido = paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">',
    '<soap:Body><consultarVersoesTabelasExternas xmlns="http://www.sped.fazenda.gov.br/sped/tabelas/ConsultaVersoes">',
    '<codigoSistema>SpedFiscal</codigoSistema></consultarVersoesTabelasExternas></soap:Body></soap:Envelope>'
  )
  pedido_ao_sped = httr2::request(SERVICO_DO_SPED)
  pedido_ao_sped = httr2::req_headers(pedido_ao_sped, SOAPAction = '"http://www.sped.fazenda.gov.br/sped/tabelas/ConsultaVersoes/consultarVersoesTabelasExternas"')
  pedido_ao_sped = httr2::req_body_raw(pedido_ao_sped, corpo_do_pedido, "text/xml; charset=utf-8")
  resposta_do_sped = xml2::read_xml(httr2::resp_body_string(httr2::req_perform(pedido_ao_sped)))
  xml2::xml_ns_strip(resposta_do_sped)
  metadados_em_texto = xml2::xml_text(xml2::xml_find_first(resposta_do_sped, "//metadadosXml"))
  metadados = xml2::read_xml(sub("^\ufeff", "", metadados_em_texto))
  xml2::xml_ns_strip(metadados)
  tabelas_listadas = xml2::xml_find_all(metadados, "//tabela")
  data.frame(
    id = xml2::xml_attr(tabelas_listadas, "id"),
    tipo = xml2::xml_attr(tabelas_listadas, "tipo"),
    descricao = xml2::xml_attr(tabelas_listadas, "desc"),
    versao = xml2::xml_attr(tabelas_listadas, "versao"),
    data_da_versao = xml2::xml_attr(tabelas_listadas, "dtVersao")
  )
}

# O arquivo vem em Windows-1252 (não Latin-1: o travessão do CST 51 do PIS é o byte 0x96), uma linha por
# código: código|descrição|início (DDMMAAAA)|fim. A primeira linha é o cabeçalho com a versão. Uma
# descrição pode vir quebrada em duas linhas (a do CFOP 5909 vem): linha que não começa por um código
# continua a anterior.
baixar_tabela_do_sped = function(id_da_tabela, versao_da_tabela) {
  pedido_da_tabela = httr2::request(paste0(DOWNLOAD_DO_SPED, "?idTabela=", id_da_tabela, "&versao=", versao_da_tabela))
  conteudo_bruto = httr2::resp_body_raw(httr2::req_perform(pedido_da_tabela))
  linhas_do_arquivo = strsplit(iconv(rawToChar(conteudo_bruto), from = "CP1252", to = "UTF-8"), "\r?\n")[[1]]
  linhas_do_arquivo = linhas_do_arquivo[-1]
  linhas_inteiras = character()
  for (linha_do_arquivo in linhas_do_arquivo) {
    if (trimws(linha_do_arquivo) == "") {
      next
    }
    if (grepl("^[0-9A-Z]+\\|", linha_do_arquivo) || length(linhas_inteiras) == 0) {
      linhas_inteiras = c(linhas_inteiras, linha_do_arquivo)
    } else {
      posicao_da_ultima = length(linhas_inteiras)
      linhas_inteiras[posicao_da_ultima] = paste0(linhas_inteiras[posicao_da_ultima], linha_do_arquivo)
    }
  }
  campos_de_cada_linha = strsplit(linhas_inteiras, "|", fixed = TRUE)
  quantidade_de_codigos = length(campos_de_cada_linha)
  codigos = character(quantidade_de_codigos)
  descricoes = character(quantidade_de_codigos)
  inicios_em_texto = character(quantidade_de_codigos)
  fins_em_texto = character(quantidade_de_codigos)
  for (posicao in seq_len(quantidade_de_codigos)) {
    campos_da_linha = campos_de_cada_linha[[posicao]]
    codigos[posicao] = campos_da_linha[1]
    descricoes[posicao] = trimws(campos_da_linha[2])
    inicios_em_texto[posicao] = campos_da_linha[3]
    fins_em_texto[posicao] = campos_da_linha[4]
  }
  data.frame(
    codigo = codigos,
    descricao = descricoes,
    inicio = data_do_sped(inicios_em_texto),
    fim = data_do_sped(fins_em_texto)
  )
}

data_do_sped = function(datas_em_texto) {
  as.Date(ifelse(is.na(datas_em_texto) | datas_em_texto == "", NA, datas_em_texto), format = "%d%m%Y")
}

# ---- Portal da NF-e ----

# Baixa o arquivo do link mais recente cujo texto começa por `comeco_do_link` e devolve o caminho dele e o
# texto do link (que traz a data de publicação).
baixar_do_portal = function(comeco_do_link, pasta_temporaria) {
  # O portal só entrega o arquivo para quem abriu a página antes (cookie de sessão).
  arquivo_de_cookies = file.path(pasta_temporaria, "cookies_do_portal.txt")
  pedido_da_pagina = httr2::req_cookie_preserve(httr2::request(paste0(ENDERECO_DO_PORTAL, PAGINA_COM_A_TABELA_DE_CFOP)), arquivo_de_cookies)
  pagina_do_portal = xml2::read_html(httr2::resp_body_string(httr2::req_perform(pedido_da_pagina)))
  links_achados = xml2::xml_find_all(pagina_do_portal, paste0("//a[starts-with(normalize-space(.), '", comeco_do_link, "')]"))
  if (length(links_achados) == 0) {
    stop("A página do portal não tem mais o link '", comeco_do_link, "'", call. = FALSE)
  }
  # O primeiro é o mais recente (a página lista do mais novo para o mais antigo).
  titulo_do_link = trimws(xml2::xml_text(links_achados[1]))
  endereco_do_arquivo = gsub("+", "%2B", xml2::xml_attr(links_achados[1], "href"), fixed = TRUE)
  arquivo_baixado = tempfile(tmpdir = pasta_temporaria, fileext = ".xlsx")
  pedido_do_arquivo = httr2::req_cookie_preserve(httr2::request(paste0(ENDERECO_DO_PORTAL, endereco_do_arquivo)), arquivo_de_cookies)
  httr2::req_perform(pedido_do_arquivo, path = arquivo_baixado)
  list(arquivo = arquivo_baixado, titulo = titulo_do_link)
}

conferir_colunas = function(planilha, colunas_esperadas, nome_da_tabela) {
  colunas_que_faltam = setdiff(colunas_esperadas, names(planilha))
  if (length(colunas_que_faltam) > 0) {
    stop("A tabela ", nome_da_tabela, " não tem mais as colunas: ", paste(colunas_que_faltam, collapse = ", "), call. = FALSE)
  }
}

baixar_tabela_de_cfop = function(pasta_temporaria) {
  planilha_baixada = baixar_do_portal("Tabela de CFOP", pasta_temporaria)
  planilha_de_cfop = readxl::read_excel(planilha_baixada$arquivo, sheet = 1, range = readxl::cell_cols("A:N"))
  nomes_na_planilha = c(
    "CFOP", "Início de vigência", "Fim de vigência", "indNFe", "indComunica", "indTransp", "indDevol",
    "indRetor", "indAnula", "indRemes", "indComb", "indExcIBSCBS", "Título do CFOP", "Descrição (nota explicativa)"
  )
  if (!identical(names(planilha_de_cfop), nomes_na_planilha)) {
    stop("As colunas da tabela de CFOP mudaram: ", paste(names(planilha_de_cfop), collapse = ", "), call. = FALSE)
  }
  cfop = data.frame(
    codigo = as.character(as.integer(planilha_de_cfop[["CFOP"]])),
    titulo = trimws(planilha_de_cfop[["Título do CFOP"]]),
    nota_explicativa = trimws(planilha_de_cfop[["Descrição (nota explicativa)"]]),
    inicio = as.Date(planilha_de_cfop[["Início de vigência"]]),
    fim = as.Date(planilha_de_cfop[["Fim de vigência"]]),
    permitido_na_nfe = as.integer(planilha_de_cfop[["indNFe"]]),
    comunicacao = as.integer(planilha_de_cfop[["indComunica"]]),
    transporte = as.integer(planilha_de_cfop[["indTransp"]]),
    devolucao = as.integer(planilha_de_cfop[["indDevol"]]),
    retorno = as.integer(planilha_de_cfop[["indRetor"]]),
    anulacao = as.integer(planilha_de_cfop[["indAnula"]]),
    remessa = as.integer(planilha_de_cfop[["indRemes"]]),
    combustivel = as.integer(planilha_de_cfop[["indComb"]]),
    exclusivo_ibs_cbs = as.integer(planilha_de_cfop[["indExcIBSCBS"]])
  )
  cfop = cfop[!is.na(cfop$codigo), ]
  list(tabela = cfop, titulo = planilha_baixada$titulo)
}

# As datas das planilhas de pagamento vêm como número de série do Excel (dias desde 30/12/1899) ou já como data.
data_da_planilha = function(valores_da_coluna) {
  if (inherits(valores_da_coluna, "POSIXct") || inherits(valores_da_coluna, "Date")) {
    return(as.Date(valores_da_coluna))
  }
  as.Date(as.numeric(valores_da_coluna), origin = "1899-12-30")
}

# A Tabela de Meios de Pagamento do Portal da NF-e: o código vai no tPag da NF-e e no tpMeioPgto do pagamento
# vinculado da Reforma (Informe Técnico 2026.001). A primeira linha é o título; a segunda, os nomes das colunas.
# O começo do link é o comum às publicações, que mudam a letra de "Pagamento".
baixar_meios_de_pagamento = function(pasta_temporaria) {
  planilha_baixada = baixar_do_portal("Tabela de Meios de", pasta_temporaria)
  planilha_de_meios = readxl::read_excel(planilha_baixada$arquivo, sheet = 1, skip = 1)
  conferir_colunas(planilha_de_meios, c("tPag", "Descrição", "dIniVig", "dFimVig", "Observações"), "de meios de pagamento")
  planilha_de_meios = planilha_de_meios[!is.na(planilha_de_meios[["tPag"]]), ]
  meios_pagamento = data.frame(
    codigo = sprintf("%02d", as.integer(planilha_de_meios[["tPag"]])),
    descricao = trimws(planilha_de_meios[["Descrição"]]),
    observacao = trimws(planilha_de_meios[["Observações"]]),
    inicio = data_da_planilha(planilha_de_meios[["dIniVig"]]),
    fim = data_da_planilha(planilha_de_meios[["dFimVig"]])
  )
  list(tabela = meios_pagamento, titulo = planilha_baixada$titulo)
}

# A Tabela de bandeiras de cartões de crédito e débito do Portal da NF-e (o tBand do pagamento com cartão).
baixar_bandeiras_de_cartao = function(pasta_temporaria) {
  planilha_baixada = baixar_do_portal("Tabela de bandeiras", pasta_temporaria)
  planilha_de_bandeiras = readxl::read_excel(planilha_baixada$arquivo, sheet = 1, skip = 1)
  conferir_colunas(planilha_de_bandeiras, c("tBand", "Operadora", "dIniVig", "dFimVig"), "de bandeiras de cartão")
  planilha_de_bandeiras = planilha_de_bandeiras[!is.na(planilha_de_bandeiras[["tBand"]]), ]
  bandeiras_cartao = data.frame(
    codigo = sprintf("%02d", as.integer(planilha_de_bandeiras[["tBand"]])),
    descricao = trimws(planilha_de_bandeiras[["Operadora"]]),
    inicio = data_da_planilha(planilha_de_bandeiras[["dIniVig"]]),
    fim = data_da_planilha(planilha_de_bandeiras[["dFimVig"]])
  )
  list(tabela = bandeiras_cartao, titulo = planilha_baixada$titulo)
}

# A Tabela de Classificação Tributária do IBS e CBS (Informe Técnico 2025.002): a primeira aba tem as
# classificações (cClassTrib), a segunda os CST. O Excel guarda alguns CST como número (400 em vez de
# "400"): todo CST volta a ter três dígitos.
baixar_tabelas_da_reforma = function(pasta_temporaria) {
  planilha_baixada = baixar_do_portal("Tabela de Classificação Tributária do IBS e CBS", pasta_temporaria)
  classificacoes = readxl::read_excel(planilha_baixada$arquivo, sheet = 1)
  conferir_colunas(classificacoes, c(
    "CST-IBS/CBS", "cClassTrib", "Nome cClassTrib", "Descrição cClassTrib", "LC 214/25", "Tipo de Alíquota",
    "pRedIBS", "pRedCBS", "dIniVig", "dFimVig", "indNFe", "indNFCe"
  ), "de classificação do IBS e CBS")
  classificacoes = classificacoes[!is.na(classificacoes[["cClassTrib"]]), ]
  classificacao = data.frame(
    codigo = classificacoes[["cClassTrib"]],
    cst = sprintf("%03d", as.integer(classificacoes[["CST-IBS/CBS"]])),
    nome = trimws(classificacoes[["Nome cClassTrib"]]),
    descricao = trimws(classificacoes[["Descrição cClassTrib"]]),
    artigo_lc_214 = trimws(classificacoes[["LC 214/25"]]),
    tipo_aliquota = trimws(classificacoes[["Tipo de Alíquota"]]),
    reducao_ibs = as.numeric(classificacoes[["pRedIBS"]]),
    reducao_cbs = as.numeric(classificacoes[["pRedCBS"]]),
    inicio = as.Date(classificacoes[["dIniVig"]]),
    fim = as.Date(classificacoes[["dFimVig"]]),
    permitido_na_nfe = as.integer(classificacoes[["indNFe"]]),
    permitido_na_nfce = as.integer(classificacoes[["indNFCe"]])
  )
  csts = readxl::read_excel(planilha_baixada$arquivo, sheet = 2)
  conferir_colunas(csts, c("CST-IBS/CBS", "Descrição CST-IBS/CBS"), "de CST do IBS e CBS")
  csts = csts[!is.na(csts[["CST-IBS/CBS"]]), ]
  cst = data.frame(
    codigo = sprintf("%03d", as.integer(csts[["CST-IBS/CBS"]])),
    descricao = trimws(csts[["Descrição CST-IBS/CBS"]]),
    inicio = as.Date(NA),
    fim = as.Date(NA)
  )
  list(classificacao = classificacao, cst = cst, titulo = planilha_baixada$titulo)
}

# ---- Siscomex ----

# A nomenclatura vigente, em todos os níveis (capítulo, posição, subposição, item e subitem). O código vai
# sem os pontos, como na NF-e; a data de fim 31/12/9999 quer dizer "ainda vale".
baixar_ncm = function() {
  pedido_da_ncm = httr2::request(ENDERECO_DA_NCM)
  ncm_do_siscomex = jsonlite::fromJSON(httr2::resp_body_string(httr2::req_perform(pedido_da_ncm)))
  nomenclaturas = ncm_do_siscomex$Nomenclaturas
  conferir_colunas(nomenclaturas, c("Codigo", "Descricao", "Data_Inicio", "Data_Fim", "Tipo_Ato_Ini", "Numero_Ato_Ini", "Ano_Ato_Ini"), "NCM")
  fim_de_cada_codigo = as.Date(nomenclaturas$Data_Fim, format = "%d/%m/%Y")
  fim_de_cada_codigo[fim_de_cada_codigo == as.Date("9999-12-31")] = NA
  ncm = data.frame(
    codigo = gsub(".", "", nomenclaturas$Codigo, fixed = TRUE),
    descricao = trimws(nomenclaturas$Descricao),
    inicio = as.Date(nomenclaturas$Data_Inicio, format = "%d/%m/%Y"),
    fim = fim_de_cada_codigo,
    ato_inicio = paste0(nomenclaturas$Tipo_Ato_Ini, " ", nomenclaturas$Numero_Ato_Ini, "/", nomenclaturas$Ano_Ato_Ini)
  )
  list(tabela = ncm, situacao = ncm_do_siscomex$Data_Ultima_Atualizacao_NCM, ato = ncm_do_siscomex$Ato)
}

# ---- IBGE ----

# Os municípios vigentes, com o código de 7 dígitos que vai nos documentos. O IBGE só publica a lista de hoje,
# então a tabela vai sem datas, como o CSOSN.
baixar_municipios = function() {
  pedido_dos_municipios = httr2::req_timeout(httr2::request(ENDERECO_DOS_MUNICIPIOS), 120)
  municipios_do_ibge = jsonlite::fromJSON(httr2::resp_body_string(httr2::req_perform(pedido_dos_municipios)))
  conferir_colunas(municipios_do_ibge, c("municipio-id", "municipio-nome", "UF-id", "UF-sigla"), "municípios")
  municipios = data.frame(
    codigo = as.character(municipios_do_ibge$`municipio-id`),
    nome = municipios_do_ibge$`municipio-nome`,
    uf = municipios_do_ibge$`UF-sigla`,
    codigo_uf = as.character(municipios_do_ibge$`UF-id`),
    inicio = as.Date(NA),
    fim = as.Date(NA)
  )
  if (any(nchar(municipios$codigo) != 7) || anyDuplicated(municipios$codigo) > 0 || anyNA(municipios$uf)) {
    stop("A lista de municípios do IBGE mudou de formato: código sem 7 dígitos, repetido ou sem UF", call. = FALSE)
  }
  municipios[order(municipios$codigo), ]
}

# ---- montar as tabelas do pacote ----

# A tabela B do SPED parou em 2009: os quatro CST de combustível monofásico (02, 15, 53 e 61, desde
# 01/04/2023) só estão na tabela de três dígitos (origem + tributação). Vêm das linhas de origem 0, com
# o texto depois de " - " (o que vem antes é a descrição da origem).
cst_icms_com_os_monofasicos = function(cst_b, cst_tres_digitos) {
  origem_nacional = cst_tres_digitos[substr(cst_tres_digitos$codigo, 1, 1) == "0", ]
  codigo_de_dois_digitos = substr(origem_nacional$codigo, 2, 3)
  csts_que_faltam = origem_nacional[!(codigo_de_dois_digitos %in% cst_b$codigo), ]
  csts_que_faltam$codigo = substr(csts_que_faltam$codigo, 2, 3)
  csts_que_faltam$descricao = sub("^.*? - ", "", csts_que_faltam$descricao, perl = TRUE)
  cst_icms_completo = rbind(cst_b, csts_que_faltam)
  cst_icms_completo[order(cst_icms_completo$codigo, cst_icms_completo$inicio), ]
}

# A tabela A do SPED parou em 2012 e não tem a origem 8 (desde 01/08/2013), que está na tabela de três
# dígitos. A origem que falta vem de lá: a descrição é o texto antes do último " - " (o que vem depois é a
# tributação) e o início é o mais antigo entre as linhas dela.
origem_com_as_que_faltam = function(origem_a, cst_tres_digitos) {
  primeiro_digito = substr(cst_tres_digitos$codigo, 1, 1)
  # As linhas do Simples Nacional (CSOSN) também começam por um dígito, mas não têm origem.
  com_origem = !startsWith(cst_tres_digitos$descricao, "Simples Nacional") & !startsWith(cst_tres_digitos$descricao, "Para Simples Nacional")
  origens_que_faltam = setdiff(unique(primeiro_digito[com_origem]), origem_a$codigo)
  origens_completas = origem_a
  for (codigo_da_origem in origens_que_faltam) {
    linhas_da_origem = cst_tres_digitos[com_origem & primeiro_digito == codigo_da_origem, ]
    origens_completas = rbind(origens_completas, data.frame(
      codigo = codigo_da_origem,
      descricao = sub(" - [^-]*$", "", linhas_da_origem$descricao[1]),
      inicio = min(linhas_da_origem$inicio),
      fim = as.Date(NA)
    ))
  }
  origens_completas
}

# O CSOSN está na tabela de três dígitos do SPED, nas linhas "Simples Nacional - ...". As datas de lá
# não servem para a NF-e: na EFD o CSOSN e o CST dividem o mesmo campo, e o SPED encerrou o 300, o 400 e o
# 500 em 2012 e o 102 e o 202 em 2023 porque passaram a coincidir com códigos novos de CST. Na NF-e o
# CSOSN tem campo próprio e o schema PL_010g (26/10/2026) ainda aceita todos. Por isso o CSOSN vai sem datas.
csosn_do_sped = function(cst_tres_digitos) {
  linhas_do_simples = cst_tres_digitos[startsWith(cst_tres_digitos$descricao, "Simples Nacional - "), ]
  csosn = data.frame(
    codigo = linhas_do_simples$codigo,
    descricao = sub("^Simples Nacional - ", "", linhas_do_simples$descricao),
    inicio = as.Date(NA),
    fim = as.Date(NA)
  )
  csosn[!duplicated(csosn$codigo), ]
}

# O arquivo tem de sair igual no Windows e no Linux (onde o robô roda), senão o robô veria mudança toda
# semana: quebra de linha dentro de uma célula (a planilha da Reforma tem uma) vira espaço, e o fim de linha
# é sempre "\n" (a conexão binária impede o Windows de trocar por "\r\n").
gravar_tabela = function(tabela_para_gravar, nome_da_tabela) {
  rownames(tabela_para_gravar) = NULL
  for (nome_da_coluna in names(tabela_para_gravar)) {
    if (is.character(tabela_para_gravar[[nome_da_coluna]])) {
      tabela_para_gravar[[nome_da_coluna]] = gsub("\\s*[\r\n]+\\s*", " ", tabela_para_gravar[[nome_da_coluna]])
    }
  }
  conexao_com_o_arquivo = file(file.path(PASTA_DAS_TABELAS, paste0(nome_da_tabela, ".csv")), open = "wb")
  utils::write.csv(tabela_para_gravar, conexao_com_o_arquivo, row.names = FALSE, na = "", eol = "\n")
  close(conexao_com_o_arquivo)
  cat(sprintf("%-12s %4d linhas\n", nome_da_tabela, nrow(tabela_para_gravar)))
}

pasta_temporaria = tempfile("tabelas_oficiais_")
dir.create(pasta_temporaria)
dir.create(PASTA_DAS_TABELAS, recursive = TRUE, showWarnings = FALSE)
baixada_em = format(Sys.Date())

versoes_no_sped = versoes_das_tabelas_do_sped()
tabelas_do_sped = list()
fontes = data.frame()
for (nome_da_tabela in names(TABELAS_DO_SPED)) {
  tabela_no_sped = versoes_no_sped[versoes_no_sped$tipo == TABELAS_DO_SPED[[nome_da_tabela]], ]
  if (nrow(tabela_no_sped) != 1) {
    stop("O SPED não tem uma tabela do tipo ", TABELAS_DO_SPED[[nome_da_tabela]], call. = FALSE)
  }
  tabelas_do_sped[[nome_da_tabela]] = baixar_tabela_do_sped(tabela_no_sped$id, tabela_no_sped$versao)
  fontes = rbind(fontes, data.frame(
    tabela = nome_da_tabela,
    fonte = paste0("SPED Fiscal, tabela externa ", tabela_no_sped$id, " (", tabela_no_sped$descricao, ")"),
    versao = tabela_no_sped$versao,
    data_da_versao = tabela_no_sped$data_da_versao,
    baixada_em = baixada_em
  ))
}
cfop_do_portal = baixar_tabela_de_cfop(pasta_temporaria)
fontes = rbind(fontes, data.frame(
  tabela = "cfop",
  fonte = paste0("Portal da NF-e, ", cfop_do_portal$titulo, " (Informe Técnico 2023.002)"),
  versao = NA,
  data_da_versao = NA,
  baixada_em = baixada_em
))

tabelas_da_reforma = baixar_tabelas_da_reforma(pasta_temporaria)
ncm_baixada = baixar_ncm()
meios_do_portal = baixar_meios_de_pagamento(pasta_temporaria)
bandeiras_do_portal = baixar_bandeiras_de_cartao(pasta_temporaria)
fontes = rbind(fontes, data.frame(
  tabela = c("cst_ibs_cbs", "classificacao_ibs_cbs", "ncm", "meios_pagamento", "bandeiras_cartao"),
  fonte = c(
    paste0("Portal da NF-e, ", tabelas_da_reforma$titulo, " (Informe Técnico 2025.002), aba de CST"),
    paste0("Portal da NF-e, ", tabelas_da_reforma$titulo, " (Informe Técnico 2025.002), aba de cClassTrib"),
    paste0("Portal Único Siscomex, nomenclatura NCM (", ncm_baixada$situacao, ", ", ncm_baixada$ato, ")"),
    paste0("Portal da NF-e, ", meios_do_portal$titulo),
    paste0("Portal da NF-e, ", bandeiras_do_portal$titulo)
  ),
  versao = NA,
  data_da_versao = NA,
  baixada_em = baixada_em
))

# A tabela dos códigos dos campos não é baixada: é escrita à mão a partir da documentação dos schemas e conferida
# por ferramentas/conferir_codigos_dos_campos.R. A linha dela nas fontes passa adiante como está.
fontes_de_antes = utils::read.csv(file.path(PASTA_DAS_TABELAS, "fontes.csv"), colClasses = "character", na.strings = "")
fontes = rbind(fontes, fontes_de_antes[fontes_de_antes$tabela == "codigos_dos_campos", ])

# O IBGE não aceita conexão dos servidores do GitHub (tempo esgotado em 120 s, testado em 30/10/2026). Quando ele não
# responde, fica a cópia que já está no pacote, com a data dela, e as outras tabelas seguem; o aviso aparece na
# rodada do robô. Os municípios se atualizam rodando esta ferramenta numa máquina no Brasil.
municipios_do_ibge = tryCatch(baixar_municipios(), error = function(erro) erro)
if (inherits(municipios_do_ibge, "error")) {
  cat("::warning::Municípios: o IBGE não respondeu, fica a cópia do pacote (",
      gsub("\\s+", " ", conditionMessage(municipios_do_ibge)), ")\n")
  fontes_de_antes = utils::read.csv(file.path(PASTA_DAS_TABELAS, "fontes.csv"), colClasses = "character", na.strings = "")
  fontes = rbind(fontes, fontes_de_antes[fontes_de_antes$tabela == "municipios", ])
  municipios_do_ibge = NULL
} else {
  fontes = rbind(fontes, data.frame(
    tabela = "municipios",
    fonte = "IBGE, API de localidades (servicodados.ibge.gov.br), municípios vigentes",
    versao = NA,
    data_da_versao = NA,
    baixada_em = baixada_em
  ))
}

gravar_tabela(cfop_do_portal$tabela, "cfop")
gravar_tabela(tabelas_da_reforma$cst, "cst_ibs_cbs")
gravar_tabela(tabelas_da_reforma$classificacao, "classificacao_ibs_cbs")
gravar_tabela(ncm_baixada$tabela, "ncm")
gravar_tabela(meios_do_portal$tabela, "meios_pagamento")
gravar_tabela(bandeiras_do_portal$tabela, "bandeiras_cartao")
if (!is.null(municipios_do_ibge)) {
  gravar_tabela(municipios_do_ibge, "municipios")
}
gravar_tabela(origem_com_as_que_faltam(tabelas_do_sped$origem, tabelas_do_sped$cst_icms_tres_digitos), "origem")
gravar_tabela(cst_icms_com_os_monofasicos(tabelas_do_sped$cst_icms_b, tabelas_do_sped$cst_icms_tres_digitos), "cst_icms")
gravar_tabela(csosn_do_sped(tabelas_do_sped$cst_icms_tres_digitos), "csosn")
gravar_tabela(tabelas_do_sped$cst_ipi, "cst_ipi")
gravar_tabela(tabelas_do_sped$cst_pis, "cst_pis")
gravar_tabela(tabelas_do_sped$cst_cofins, "cst_cofins")
gravar_tabela(fontes, "fontes")
