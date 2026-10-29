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

PASTA_DAS_TABELAS = "inst/extdata/tabelas"
ENDERECO_DO_PORTAL = "https://www.nfe.fazenda.gov.br/portal/"
PAGINA_COM_A_TABELA_DE_CFOP = "listaConteudo.aspx?tipoConteudo=/NJarYc9nus="
SERVICO_DO_SPED = "http://www.sped.fazenda.gov.br/spedtabelas/WsConsulta/WsConsulta.asmx"
DOWNLOAD_DO_SPED = "http://www.sped.fazenda.gov.br/spedtabelas/wsconsulta/obterTabela.ashx"
ENDERECO_DA_NCM = "https://portalunico.siscomex.gov.br/classif/api/publico/nomenclatura/download/json"
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
  corpo = paste0(
    '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">',
    '<soap:Body><consultarVersoesTabelasExternas xmlns="http://www.sped.fazenda.gov.br/sped/tabelas/ConsultaVersoes">',
    '<codigoSistema>SpedFiscal</codigoSistema></consultarVersoesTabelasExternas></soap:Body></soap:Envelope>'
  )
  pedido = httr2::request(SERVICO_DO_SPED)
  pedido = httr2::req_headers(pedido, SOAPAction = '"http://www.sped.fazenda.gov.br/sped/tabelas/ConsultaVersoes/consultarVersoesTabelasExternas"')
  pedido = httr2::req_body_raw(pedido, corpo, "text/xml; charset=utf-8")
  resposta = xml2::read_xml(httr2::resp_body_string(httr2::req_perform(pedido)))
  xml2::xml_ns_strip(resposta)
  metadados_em_texto = xml2::xml_text(xml2::xml_find_first(resposta, "//metadadosXml"))
  metadados = xml2::read_xml(sub("^﻿", "", metadados_em_texto))
  xml2::xml_ns_strip(metadados)
  tabelas = xml2::xml_find_all(metadados, "//tabela")
  data.frame(
    id = xml2::xml_attr(tabelas, "id"),
    tipo = xml2::xml_attr(tabelas, "tipo"),
    descricao = xml2::xml_attr(tabelas, "desc"),
    versao = xml2::xml_attr(tabelas, "versao"),
    data_da_versao = xml2::xml_attr(tabelas, "dtVersao")
  )
}

# O arquivo vem em Windows-1252 (não Latin-1: o travessão do CST 51 do PIS é o byte 0x96), uma linha por código: código|descrição|início (DDMMAAAA)|fim. A primeira
# linha é o cabeçalho com a versão. Uma descrição pode vir quebrada em duas linhas (a do CFOP 5909 vem):
# linha que não começa por um código continua a anterior.
baixar_tabela_do_sped = function(id, versao) {
  pedido = httr2::request(paste0(DOWNLOAD_DO_SPED, "?idTabela=", id, "&versao=", versao))
  bruto = httr2::resp_body_raw(httr2::req_perform(pedido))
  linhas = strsplit(iconv(rawToChar(bruto), from = "CP1252", to = "UTF-8"), "\r?\n")[[1]]
  linhas = linhas[-1]
  linhas_inteiras = character()
  for (linha in linhas) {
    if (trimws(linha) == "") {
      next
    }
    if (grepl("^[0-9A-Z]+\\|", linha) || length(linhas_inteiras) == 0) {
      linhas_inteiras = c(linhas_inteiras, linha)
    } else {
      ultima = length(linhas_inteiras)
      linhas_inteiras[ultima] = paste0(linhas_inteiras[ultima], linha)
    }
  }
  campos = strsplit(linhas_inteiras, "|", fixed = TRUE)
  data.frame(
    codigo = vapply(campos, function(campo) campo[1], character(1)),
    descricao = vapply(campos, function(campo) trimws(campo[2]), character(1)),
    inicio = data_do_sped(vapply(campos, function(campo) campo[3], character(1))),
    fim = data_do_sped(vapply(campos, function(campo) campo[4], character(1)))
  )
}

data_do_sped = function(texto) {
  as.Date(ifelse(is.na(texto) | texto == "", NA, texto), format = "%d%m%Y")
}

# ---- Portal da NF-e ----

# Baixa o arquivo do link mais recente cujo texto começa por `comeco_do_link` e devolve o caminho dele e o
# texto do link (que traz a data de publicação).
baixar_do_portal = function(comeco_do_link, pasta_temporaria) {
  # O portal só entrega o arquivo para quem abriu a página antes (cookie de sessão).
  arquivo_de_cookies = file.path(pasta_temporaria, "cookies_do_portal.txt")
  pedido = httr2::req_cookie_preserve(httr2::request(paste0(ENDERECO_DO_PORTAL, PAGINA_COM_A_TABELA_DE_CFOP)), arquivo_de_cookies)
  pagina = xml2::read_html(httr2::resp_body_string(httr2::req_perform(pedido)))
  links = xml2::xml_find_all(pagina, paste0("//a[starts-with(normalize-space(.), '", comeco_do_link, "')]"))
  if (length(links) == 0) {
    stop("A página do portal não tem mais o link '", comeco_do_link, "'", call. = FALSE)
  }
  # O primeiro é o mais recente (a página lista do mais novo para o mais antigo).
  titulo = trimws(xml2::xml_text(links[1]))
  endereco = gsub("+", "%2B", xml2::xml_attr(links[1], "href"), fixed = TRUE)
  arquivo = tempfile(tmpdir = pasta_temporaria, fileext = ".xlsx")
  pedido = httr2::req_cookie_preserve(httr2::request(paste0(ENDERECO_DO_PORTAL, endereco)), arquivo_de_cookies)
  httr2::req_perform(pedido, path = arquivo)
  list(arquivo = arquivo, titulo = titulo)
}

conferir_colunas = function(planilha, colunas_esperadas, nome_da_tabela) {
  faltando = setdiff(colunas_esperadas, names(planilha))
  if (length(faltando) > 0) {
    stop("A tabela ", nome_da_tabela, " não tem mais as colunas: ", paste(faltando, collapse = ", "), call. = FALSE)
  }
}

baixar_tabela_de_cfop = function(pasta_temporaria) {
  baixado = baixar_do_portal("Tabela de CFOP", pasta_temporaria)
  titulo = baixado$titulo
  planilha = readxl::read_excel(baixado$arquivo, sheet = 1, range = readxl::cell_cols("A:N"))
  nomes_na_planilha = c(
    "CFOP", "Início de vigência", "Fim de vigência", "indNFe", "indComunica", "indTransp", "indDevol",
    "indRetor", "indAnula", "indRemes", "indComb", "indExcIBSCBS", "Título do CFOP", "Descrição (nota explicativa)"
  )
  if (!identical(names(planilha), nomes_na_planilha)) {
    stop("As colunas da tabela de CFOP mudaram: ", paste(names(planilha), collapse = ", "), call. = FALSE)
  }
  cfop = data.frame(
    codigo = as.character(as.integer(planilha[["CFOP"]])),
    titulo = trimws(planilha[["Título do CFOP"]]),
    nota_explicativa = trimws(planilha[["Descrição (nota explicativa)"]]),
    inicio = as.Date(planilha[["Início de vigência"]]),
    fim = as.Date(planilha[["Fim de vigência"]]),
    permitido_na_nfe = as.integer(planilha[["indNFe"]]),
    comunicacao = as.integer(planilha[["indComunica"]]),
    transporte = as.integer(planilha[["indTransp"]]),
    devolucao = as.integer(planilha[["indDevol"]]),
    retorno = as.integer(planilha[["indRetor"]]),
    anulacao = as.integer(planilha[["indAnula"]]),
    remessa = as.integer(planilha[["indRemes"]]),
    combustivel = as.integer(planilha[["indComb"]]),
    exclusivo_ibs_cbs = as.integer(planilha[["indExcIBSCBS"]])
  )
  cfop = cfop[!is.na(cfop$codigo), ]
  list(tabela = cfop, titulo = titulo)
}

# A Tabela de Classificação Tributária do IBS e CBS (Informe Técnico 2025.002): a primeira aba tem as
# classificações (cClassTrib), a segunda os CST. O Excel guarda alguns CST como número (400 em vez de
# "400"): todo CST volta a ter três dígitos.
baixar_tabelas_da_reforma = function(pasta_temporaria) {
  baixado = baixar_do_portal("Tabela de Classificação Tributária do IBS e CBS", pasta_temporaria)
  classificacoes = readxl::read_excel(baixado$arquivo, sheet = 1)
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
  csts = readxl::read_excel(baixado$arquivo, sheet = 2)
  conferir_colunas(csts, c("CST-IBS/CBS", "Descrição CST-IBS/CBS"), "de CST do IBS e CBS")
  csts = csts[!is.na(csts[["CST-IBS/CBS"]]), ]
  cst = data.frame(
    codigo = sprintf("%03d", as.integer(csts[["CST-IBS/CBS"]])),
    descricao = trimws(csts[["Descrição CST-IBS/CBS"]]),
    inicio = as.Date(NA),
    fim = as.Date(NA)
  )
  list(classificacao = classificacao, cst = cst, titulo = baixado$titulo)
}

# ---- Siscomex ----

# A nomenclatura vigente, em todos os níveis (capítulo, posição, subposição, item e subitem). O código vai
# sem os pontos, como na NF-e; a data de fim 31/12/9999 quer dizer "ainda vale".
baixar_ncm = function() {
  pedido = httr2::request(ENDERECO_DA_NCM)
  ncm_do_siscomex = jsonlite::fromJSON(httr2::resp_body_string(httr2::req_perform(pedido)))
  nomenclaturas = ncm_do_siscomex$Nomenclaturas
  conferir_colunas(nomenclaturas, c("Codigo", "Descricao", "Data_Inicio", "Data_Fim", "Tipo_Ato_Ini", "Numero_Ato_Ini", "Ano_Ato_Ini"), "NCM")
  fim = as.Date(nomenclaturas$Data_Fim, format = "%d/%m/%Y")
  fim[fim == as.Date("9999-12-31")] = NA
  ncm = data.frame(
    codigo = gsub(".", "", nomenclaturas$Codigo, fixed = TRUE),
    descricao = trimws(nomenclaturas$Descricao),
    inicio = as.Date(nomenclaturas$Data_Inicio, format = "%d/%m/%Y"),
    fim = fim,
    ato_inicio = paste0(nomenclaturas$Tipo_Ato_Ini, " ", nomenclaturas$Numero_Ato_Ini, "/", nomenclaturas$Ano_Ato_Ini)
  )
  list(tabela = ncm, situacao = ncm_do_siscomex$Data_Ultima_Atualizacao_NCM, ato = ncm_do_siscomex$Ato)
}

# ---- montar as tabelas do pacote ----

# A tabela B do SPED parou em 2009: os quatro CST de combustível monofásico (02, 15, 53 e 61, desde
# 01/04/2023) só estão na tabela de três dígitos (origem + tributação). Vêm das linhas de origem 0, com
# o texto depois de " - " (o que vem antes é a descrição da origem).
cst_icms_com_os_monofasicos = function(cst_b, cst_tres_digitos) {
  origem_nacional = cst_tres_digitos[substr(cst_tres_digitos$codigo, 1, 1) == "0", ]
  codigo_de_dois_digitos = substr(origem_nacional$codigo, 2, 3)
  faltando = origem_nacional[!(codigo_de_dois_digitos %in% cst_b$codigo), ]
  faltando$codigo = substr(faltando$codigo, 2, 3)
  faltando$descricao = sub("^.*? - ", "", faltando$descricao, perl = TRUE)
  juntas = rbind(cst_b, faltando)
  juntas[order(juntas$codigo, juntas$inicio), ]
}

# A tabela A do SPED parou em 2012 e não tem a origem 8 (desde 01/08/2013), que está na tabela de três
# dígitos. A origem que falta vem de lá: a descrição é o texto antes do último " - " (o que vem depois é a
# tributação) e o início é o mais antigo entre as linhas dela.
origem_com_as_que_faltam = function(origem_a, cst_tres_digitos) {
  primeiro_digito = substr(cst_tres_digitos$codigo, 1, 1)
  # As linhas do Simples Nacional (CSOSN) também começam por um dígito, mas não têm origem.
  com_origem = !startsWith(cst_tres_digitos$descricao, "Simples Nacional") & !startsWith(cst_tres_digitos$descricao, "Para Simples Nacional")
  faltando = setdiff(unique(primeiro_digito[com_origem]), origem_a$codigo)
  juntas = origem_a
  for (codigo_da_origem in faltando) {
    linhas_da_origem = cst_tres_digitos[com_origem & primeiro_digito == codigo_da_origem, ]
    juntas = rbind(juntas, data.frame(
      codigo = codigo_da_origem,
      descricao = sub(" - [^-]*$", "", linhas_da_origem$descricao[1]),
      inicio = min(linhas_da_origem$inicio),
      fim = as.Date(NA)
    ))
  }
  juntas
}

# O CSOSN está na tabela de três dígitos do SPED, nas linhas "Simples Nacional - ...". As datas de lá
# não servem para a NF-e: na EFD o CSOSN e o CST dividem o mesmo campo, e o SPED encerrou o 300, o 400 e o
# 500 em 2012 e o 102 e o 202 em 2023 porque passaram a coincidir com códigos novos de CST. Na NF-e o
# CSOSN tem campo próprio e o schema PL_010g (26/10/2026) ainda aceita todos. Por isso o CSOSN vai sem datas.
csosn_do_sped = function(cst_tres_digitos) {
  do_simples = cst_tres_digitos[startsWith(cst_tres_digitos$descricao, "Simples Nacional - "), ]
  csosn = data.frame(
    codigo = do_simples$codigo,
    descricao = sub("^Simples Nacional - ", "", do_simples$descricao),
    inicio = as.Date(NA),
    fim = as.Date(NA)
  )
  csosn[!duplicated(csosn$codigo), ]
}

gravar_tabela = function(tabela, nome) {
  rownames(tabela) = NULL
  utils::write.csv(tabela, file.path(PASTA_DAS_TABELAS, paste0(nome, ".csv")), row.names = FALSE, na = "", fileEncoding = "UTF-8")
  cat(sprintf("%-12s %4d linhas\n", nome, nrow(tabela)))
}

pasta_temporaria = tempfile("tabelas_oficiais_")
dir.create(pasta_temporaria)
dir.create(PASTA_DAS_TABELAS, recursive = TRUE, showWarnings = FALSE)
baixada_em = format(Sys.Date())

versoes = versoes_das_tabelas_do_sped()
tabelas_do_sped = list()
fontes = data.frame()
for (nome in names(TABELAS_DO_SPED)) {
  linha = versoes[versoes$tipo == TABELAS_DO_SPED[[nome]], ]
  if (nrow(linha) != 1) {
    stop("O SPED não tem uma tabela do tipo ", TABELAS_DO_SPED[[nome]], call. = FALSE)
  }
  tabelas_do_sped[[nome]] = baixar_tabela_do_sped(linha$id, linha$versao)
  fontes = rbind(fontes, data.frame(
    tabela = nome,
    fonte = paste0("SPED Fiscal, tabela externa ", linha$id, " (", linha$descricao, ")"),
    versao = linha$versao,
    data_da_versao = linha$data_da_versao,
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

reforma = baixar_tabelas_da_reforma(pasta_temporaria)
ncm = baixar_ncm()
fontes = rbind(fontes, data.frame(
  tabela = c("cst_ibs_cbs", "classificacao_ibs_cbs", "ncm"),
  fonte = c(
    paste0("Portal da NF-e, ", reforma$titulo, " (Informe Técnico 2025.002), aba de CST"),
    paste0("Portal da NF-e, ", reforma$titulo, " (Informe Técnico 2025.002), aba de cClassTrib"),
    paste0("Portal Único Siscomex, nomenclatura NCM (", ncm$situacao, ", ", ncm$ato, ")")
  ),
  versao = NA,
  data_da_versao = NA,
  baixada_em = baixada_em
))

gravar_tabela(cfop_do_portal$tabela, "cfop")
gravar_tabela(reforma$cst, "cst_ibs_cbs")
gravar_tabela(reforma$classificacao, "classificacao_ibs_cbs")
gravar_tabela(ncm$tabela, "ncm")
gravar_tabela(origem_com_as_que_faltam(tabelas_do_sped$origem, tabelas_do_sped$cst_icms_tres_digitos), "origem")
gravar_tabela(cst_icms_com_os_monofasicos(tabelas_do_sped$cst_icms_b, tabelas_do_sped$cst_icms_tres_digitos), "cst_icms")
gravar_tabela(csosn_do_sped(tabelas_do_sped$cst_icms_tres_digitos), "csosn")
gravar_tabela(tabelas_do_sped$cst_ipi, "cst_ipi")
gravar_tabela(tabelas_do_sped$cst_pis, "cst_pis")
gravar_tabela(tabelas_do_sped$cst_cofins, "cst_cofins")
gravar_tabela(fontes, "fontes")
