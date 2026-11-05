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
# - CST e classificação tributária do IBS e da CBS: a tabela do Informe Técnico 2025.002, no Portal da NF-e; e o que
#   mudou de uma versão publicada da tabela para a seguinte, desde a 1.20 (mudancas_ibs_cbs). O crédito presumido
#   (cCredPres): a tabela de crédito presumido do mesmo IT.
# - O local da operação da Reforma (cIndOp): o Anexo VII da documentação da NFS-e Nacional (gov.br/nfse), a versão
#   mais alta publicada; se a página não responder, fica a cópia do pacote, com um aviso.
# - O etanol anidro obrigatório na gasolina C: a Tabela de Índice de Biocombustível (IT 2025.004), com o histórico; os
#   combustíveis do ICMS monofásico: a tabela do Portal da NF-e, com os dados históricos e os atuais.
# - NCM: a nomenclatura vigente do Portal Único Siscomex.
# - Meios de pagamento e bandeiras de cartão: as tabelas do Portal da NF-e (seção Diversos).
# - Municípios: a API de localidades do IBGE, que a NF-e, o CT-e, o MDF-e e a NFS-e usam para o código do
#   município.
# - Serviços web da SEFAZ (o endereço de cada serviço da NF-e e o autorizador de cada UF): a Relação de Serviços
#   Web do Portal da NF-e. Só a de homologação, por enquanto: o RNFe ainda não fala com a produção.

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

# Os links da página de Diversos do portal cujo texto cumpre o `filtro_do_xpath`, do mais novo para o mais antigo (como
# a página lista): o título de cada um (que traz a data de publicação) e o endereço.
links_do_portal = function(filtro_do_xpath, pasta_temporaria) {
  # O portal só entrega o arquivo para quem abriu a página antes (cookie de sessão).
  arquivo_de_cookies = file.path(pasta_temporaria, "cookies_do_portal.txt")
  pedido_da_pagina = httr2::req_cookie_preserve(httr2::request(paste0(ENDERECO_DO_PORTAL, PAGINA_COM_A_TABELA_DE_CFOP)), arquivo_de_cookies)
  pagina_do_portal = xml2::read_html(httr2::resp_body_string(httr2::req_perform(pedido_da_pagina)))
  links_achados = xml2::xml_find_all(pagina_do_portal, paste0("//a[", filtro_do_xpath, "]"))
  # O código do arquivo no link tem "+", que vai como %2B; em alguns links a página traz um espaço no lugar dele (o da
  # tabela de crédito presumido de 07/10/2025).
  data.frame(
    titulo = trimws(xml2::xml_text(links_achados)),
    endereco = gsub("[+ ]", "%2B", xml2::xml_attr(links_achados, "href"))
  )
}

baixar_link_do_portal = function(endereco_do_arquivo, pasta_temporaria) {
  arquivo_de_cookies = file.path(pasta_temporaria, "cookies_do_portal.txt")
  arquivo_baixado = tempfile(tmpdir = pasta_temporaria, fileext = ".xlsx")
  pedido_do_arquivo = httr2::req_cookie_preserve(httr2::request(paste0(ENDERECO_DO_PORTAL, endereco_do_arquivo)), arquivo_de_cookies)
  httr2::req_perform(pedido_do_arquivo, path = arquivo_baixado)
  arquivo_baixado
}

# Baixa o arquivo do link mais recente cujo texto começa por `comeco_do_link` e devolve o caminho dele e o
# texto do link (que traz a data de publicação).
baixar_do_portal = function(comeco_do_link, pasta_temporaria) {
  links_achados = links_do_portal(paste0("starts-with(normalize-space(.), '", comeco_do_link, "')"), pasta_temporaria)
  if (nrow(links_achados) == 0) {
    stop("A página do portal não tem mais o link '", comeco_do_link, "'", call. = FALSE)
  }
  list(arquivo = baixar_link_do_portal(links_achados$endereco[1], pasta_temporaria), titulo = links_achados$titulo[1])
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

# Repete para baixo o valor da linha de cima onde a célula está vazia (as planilhas com histórico só escrevem o código
# na primeira linha de cada um).
repetir_para_baixo = function(valores) {
  for (posicao in seq_along(valores)[-1]) {
    if (is.na(valores[posicao])) {
      valores[posicao] = valores[posicao - 1]
    }
  }
  valores
}

# A Tabela de Código de Índice de Biocombustível do IBS e CBS (Informe Técnico 2025.004): o percentual obrigatório de
# etanol anidro em cada gasolina C (o pBioObrig das regras da NT 2025.002), como fração (0,32 = 32%), com a vigência.
# A aba principal tem o de hoje e a de histórico os anteriores.
baixar_indice_biocombustivel = function(pasta_temporaria) {
  planilha_baixada = baixar_do_portal("Tabela de Código de Índice de Biocombustível", pasta_temporaria)
  partes = list()
  for (nome_da_aba in c("pBioObrigatorio", "pBioObrigatorio_Historico")) {
    aba = readxl::read_excel(planilha_baixada$arquivo, sheet = nome_da_aba)
    names(aba) = gsub("\\s+", " ", names(aba))
    conferir_colunas(aba, c("cProdANP", "Descrição", "pBio (% Anidro Obrigatorio)", "Início de vigência", "Fim de vigência"),
                     paste("de índice de biocombustível, aba", nome_da_aba))
    aba = aba[!(is.na(aba[["cProdANP"]]) & is.na(aba[["pBio (% Anidro Obrigatorio)"]])), ]
    partes[[nome_da_aba]] = data.frame(
      codigo = repetir_para_baixo(as.character(aba[["cProdANP"]])),
      descricao = repetir_para_baixo(trimws(aba[["Descrição"]])),
      mistura_obrigatoria = as.numeric(aba[["pBio (% Anidro Obrigatorio)"]]),
      inicio = data_da_planilha(aba[["Início de vigência"]]),
      fim = data_da_planilha(aba[["Fim de vigência"]])
    )
  }
  biocombustivel = do.call(rbind, partes)
  biocombustivel = biocombustivel[order(biocombustivel$codigo, biocombustivel$inicio), ]
  list(tabela = biocombustivel, titulo = planilha_baixada$titulo)
}

# A Tabela de códigos de combustíveis sujeitos à tributação monofásica de ICMS (a da regra N12-110): cada produto da
# ANP com a alíquota ad rem do ICMS de cada período (aba de histórico) e, da aba de hoje, se ele pede o pBio, a origem do
# combustível e a unidade tributável.
baixar_combustiveis_monofasicos = function(pasta_temporaria) {
  planilha_baixada = baixar_do_portal("Tabela de códigos de combustíveis sujeitos à tributação monofásica de ICMS",
                                      pasta_temporaria)
  historico = readxl::read_excel(planilha_baixada$arquivo, sheet = "Dados históricos")
  conferir_colunas(historico, c("cProdANP", "Descrição", "adRemICMS", "Início da vigência", "Fim da vigência"),
                   "de combustíveis monofásicos, aba Dados históricos")
  atuais = readxl::read_excel(planilha_baixada$arquivo, sheet = "Dados atuais", col_types = "text")
  conferir_colunas(atuais, c("cProdANP", "pBio", "origComb", "uTrib"), "de combustíveis monofásicos, aba Dados atuais")
  historico = historico[!is.na(historico[["cProdANP"]]), ]
  codigos = as.character(historico[["cProdANP"]])
  do_atual = match(codigos, atuais[["cProdANP"]])
  origem = atuais[["origComb"]][do_atual]
  origem[origem %in% "-"] = NA
  combustiveis = data.frame(
    codigo = codigos,
    descricao = trimws(historico[["Descrição"]]),
    aliquota_ad_rem_icms = as.numeric(historico[["adRemICMS"]]),
    inicio = data_da_planilha(historico[["Início da vigência"]]),
    fim = data_da_planilha(historico[["Fim da vigência"]]),
    exige_pbio = as.integer(atuais[["pBio"]][do_atual]),
    origem_combustivel = origem,
    unidade_tributavel = atuais[["uTrib"]][do_atual]
  )
  list(tabela = combustiveis[order(combustiveis$codigo, combustiveis$inicio), ], titulo = planilha_baixada$titulo)
}

# A tabela do código indicador do local da operação (cIndOp, art. 11 da LC 214/2025) é o Anexo VII da documentação da
# NFS-e Nacional (Portal da NFS-e, documentação técnica da RTC); a NT 2025.002 manda consultá-la na regra B25d-20. A
# página tem as versões; vale a de número maior. Só ela traz em que documento cada código vale (indNFe, indNFSe).
PAGINA_DA_DOCUMENTACAO_DA_NFSE = "https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica/rtc"

baixar_local_operacao = function(pasta_temporaria) {
  pagina = xml2::read_html(httr2::resp_body_string(httr2::req_perform(httr2::request(PAGINA_DA_DOCUMENTACAO_DA_NFSE))))
  # A página também lista documentos só da Produção Restrita: esses ficam de fora.
  enderecos = xml2::xml_attr(xml2::xml_find_all(
    pagina, "//a[contains(@href, 'anexovii-indop') and not(contains(@href, 'producao-restrita'))]"), "href")
  if (length(enderecos) == 0) {
    stop("A página da documentação da NFS-e não tem mais o Anexo VII (anexovii-indop)", call. = FALSE)
  }
  versoes = regmatches(enderecos, regexpr("v[0-9]+-[0-9]+-[0-9]+", enderecos))
  if (length(versoes) != length(enderecos)) {
    stop("Link do Anexo VII sem a versão no nome: ", paste(enderecos, collapse = ", "), call. = FALSE)
  }
  partes_da_versao = do.call(rbind, lapply(strsplit(sub("^v", "", versoes), "-"), as.integer))
  mais_nova = order(partes_da_versao[, 1], partes_da_versao[, 2], partes_da_versao[, 3], decreasing = TRUE)[1]
  arquivo_baixado = tempfile(tmpdir = pasta_temporaria, fileext = ".xlsx")
  httr2::req_perform(httr2::request(enderecos[mais_nova]), path = arquivo_baixado)
  anexo = readxl::read_excel(arquivo_baixado, sheet = 1, col_types = "text")
  colunas = c("Código indOp", "Tipo de operação", "Característica do fornecimento",
              "Local do fornecimento a ser identificado no DFe", "Dispositivo Legal: LC 214/2025", "Observação", "indNFe",
              "indNFSe", "indNFSe Via", "NFSeLocIncidIBS")
  conferir_colunas(anexo, colunas, "do código indicador do local da operação (Anexo VII da NFS-e)")
  anexo = anexo[!is.na(anexo[["Código indOp"]]), ]
  local_operacao = data.frame(
    codigo = formatC(as.integer(anexo[["Código indOp"]]), width = 6, flag = "0"),
    tipo_operacao = trimws(anexo[["Tipo de operação"]]),
    caracteristica = trimws(anexo[["Característica do fornecimento"]]),
    local = trimws(anexo[["Local do fornecimento a ser identificado no DFe"]]),
    dispositivo_lc_214 = trimws(anexo[["Dispositivo Legal: LC 214/2025"]]),
    observacao = trimws(anexo[["Observação"]]),
    # "S" quer dizer que o código vale no documento; vazio, que não vale.
    permitido_na_nfe = as.integer(anexo[["indNFe"]] %in% "S"),
    permitido_na_nfse = as.integer(anexo[["indNFSe"]] %in% "S"),
    permitido_na_nfse_via = as.integer(anexo[["indNFSe Via"]] %in% "S"),
    local_incidencia_nfse = trimws(anexo[["NFSeLocIncidIBS"]])
  )
  versao = gsub("-", ".", sub("^v", "", versoes[mais_nova]))
  list(tabela = local_operacao, titulo = paste0("Anexo VII (IndOp_IBSCBS) v", versao))
}

# Os indicadores da Tabela de Classificação Tributária do IBS e CBS: o nome na planilha e o nome no pacote. Nos
# indicadores de grupo, 1 quer dizer que o grupo é exigido e 0 que não é permitido (a legenda da aba de CST); nos de
# documento, 1 quer dizer que a classificação pode ser usada nele.
INDICADORES_DA_CLASSIFICACAO = c(
  indNFe = "permitido_na_nfe", indNFCe = "permitido_na_nfce", indNFeABI = "permitido_na_nfe_abi",
  indCTe = "permitido_no_cte", indCTeOS = "permitido_no_cte_os", indBPe = "permitido_no_bpe",
  indBPeTA = "permitido_no_bpe_ta", indBPeTM = "permitido_no_bpe_tm", indNF3e = "permitido_na_nf3e",
  indNFSe = "permitido_na_nfse", "indNFSe Via" = "permitido_na_nfse_via", indNFCom = "permitido_na_nfcom",
  indNFAg = "permitido_na_nfag", indNFGas = "permitido_na_nfgas", indDERE = "permitido_na_dere",
  indDIR = "permitido_na_dir", indDUIMP = "permitido_na_duimp",
  ind_gTribRegular = "grupo_tributacao_regular", ind_gCredPresOper = "grupo_credito_presumido",
  ind_gMonoPadrao = "grupo_monofasico_padrao", ind_gMonoReten = "grupo_monofasico_retencao",
  ind_gMonoRet = "grupo_monofasico_retido", ind_gpBioDiferenca = "grupo_diferenca_biocombustivel",
  ind_gEstornoCred = "grupo_estorno_credito"
)
INDICADORES_DO_CST = c(
  ind_gIBSCBS = "grupo_ibs_cbs", ind_gIBSCBSMono = "grupo_monofasico", ind_gRed = "grupo_reducao",
  ind_gDif = "grupo_diferimento", ind_gTransfCred = "grupo_transferencia_credito",
  ind_gCredPresIBSZFM = "grupo_credito_presumido_zfm", ind_gAjusteCompet = "grupo_ajuste_competencia",
  ind_RedutorBC = "redutor_base_calculo"
)

# Uma aba pequena da planilha (tpRBSN, tpDoacao): abaixo do título, o código numa coluna e o significado na seguinte.
# O readxl pula a coluna vazia da esquerda, então a coluna do código é achada pelo conteúdo. Devolve o significado de
# cada código.
significados_da_aba = function(arquivo_da_planilha, nome_da_aba) {
  aba = readxl::read_excel(arquivo_da_planilha, sheet = nome_da_aba, col_names = FALSE, col_types = "text")
  coluna_do_codigo = NA
  for (posicao in seq_len(ncol(aba) - 1)) {
    if (any(grepl("^[0-9]+$", aba[[posicao]]))) {
      coluna_do_codigo = posicao
      break
    }
  }
  if (is.na(coluna_do_codigo)) {
    stop("A aba ", nome_da_aba, " da tabela de classificação do IBS e CBS não tem mais os códigos", call. = FALSE)
  }
  codigos = aba[[coluna_do_codigo]]
  textos = aba[[coluna_do_codigo + 1]]
  linhas_de_codigo = !is.na(codigos) & grepl("^[0-9]+$", codigos) & !is.na(textos)
  significados = trimws(textos[linhas_de_codigo])
  names(significados) = codigos[linhas_de_codigo]
  significados
}

# As abas da planilha da Reforma, achadas pelo nome ("cClass 2026-09-01", "CST 2026-09-01"): a ordem muda de uma
# versão para outra (na de 23/06/2026 o CST vinha primeiro).
abas_da_planilha_da_reforma = function(arquivo_da_planilha) {
  nomes_das_abas = readxl::excel_sheets(arquivo_da_planilha)
  aba_da_classificacao = nomes_das_abas[startsWith(tolower(nomes_das_abas), "cclass")]
  aba_do_cst = nomes_das_abas[startsWith(toupper(nomes_das_abas), "CST")]
  if (length(aba_da_classificacao) != 1 || length(aba_do_cst) != 1) {
    stop("A planilha da Reforma não tem uma aba de cClassTrib e uma de CST: ", paste(nomes_das_abas, collapse = ", "),
         call. = FALSE)
  }
  list(classificacao = aba_da_classificacao, cst = aba_do_cst)
}

ler_aba_de_cst = function(arquivo_da_planilha, nome_da_aba, tipos_das_colunas = NULL) {
  csts = readxl::read_excel(arquivo_da_planilha, sheet = nome_da_aba, col_types = tipos_das_colunas)
  # Desde a planilha de 19/11/2025 um nome vem com espaço ("ind_ gCredPresIBSZFM").
  names(csts) = sub("^ind_ ", "ind_", names(csts))
  csts[!is.na(csts[["CST-IBS/CBS"]]), ]
}

# A Tabela de Classificação Tributária do IBS e CBS (Informe Técnico 2025.002): a aba cClass tem as classificações
# (cClassTrib), a aba CST os CST, e as abas tpRBSN e tpDoacao o significado desses dois códigos. O Excel guarda alguns
# CST como número (400 em vez de "400"): todo CST volta a ter três dígitos.
baixar_tabelas_da_reforma = function(pasta_temporaria) {
  planilha_baixada = baixar_planilha_mais_nova_da_reforma("classificacao", pasta_temporaria)
  abas = abas_da_planilha_da_reforma(planilha_baixada$arquivo)
  classificacoes = readxl::read_excel(planilha_baixada$arquivo, sheet = abas$classificacao)
  conferir_colunas(classificacoes, c(
    "CST-IBS/CBS", "cClassTrib", "Nome cClassTrib", "Descrição cClassTrib", "LC 214/25", "Tipo de Alíquota",
    "pRedIBS", "pRedCBS", "dIniVig", "dFimVig", "tpRBSN", "tpDoacao", names(INDICADORES_DA_CLASSIFICACAO)
  ), "de classificação do IBS e CBS")
  classificacoes = classificacoes[!is.na(classificacoes[["cClassTrib"]]), ]
  significados_do_tipo_de_receita = significados_da_aba(planilha_baixada$arquivo, "tpRBSN")
  significados_da_doacao = significados_da_aba(planilha_baixada$arquivo, "tpDoacao")
  tipo_de_receita = as.character(as.integer(classificacoes[["tpRBSN"]]))
  doacao = as.character(as.integer(classificacoes[["tpDoacao"]]))
  # O código volta a ter seis dígitos: a planilha guarda alguns como número (o CST dos 400003 e 400004, na 1.70).
  classificacao = data.frame(
    codigo = formatC(as.integer(classificacoes[["cClassTrib"]]), width = 6, flag = "0"),
    cst = sprintf("%03d", as.integer(classificacoes[["CST-IBS/CBS"]])),
    nome = trimws(classificacoes[["Nome cClassTrib"]]),
    descricao = trimws(classificacoes[["Descrição cClassTrib"]]),
    artigo_lc_214 = trimws(classificacoes[["LC 214/25"]]),
    tipo_aliquota = trimws(classificacoes[["Tipo de Alíquota"]]),
    reducao_ibs = as.numeric(classificacoes[["pRedIBS"]]),
    reducao_cbs = as.numeric(classificacoes[["pRedCBS"]]),
    inicio = as.Date(classificacoes[["dIniVig"]]),
    fim = as.Date(classificacoes[["dFimVig"]])
  )
  for (nome_na_planilha in names(INDICADORES_DA_CLASSIFICACAO)) {
    classificacao[[INDICADORES_DA_CLASSIFICACAO[[nome_na_planilha]]]] = as.integer(classificacoes[[nome_na_planilha]])
  }
  classificacao$tipo_receita_simples = tipo_de_receita
  classificacao$tipo_receita_simples_descricao = unname(significados_do_tipo_de_receita[tipo_de_receita])
  classificacao$doacao = doacao
  classificacao$doacao_descricao = unname(significados_da_doacao[doacao])
  if (anyNA(classificacao$tipo_receita_simples_descricao) || anyNA(classificacao$doacao_descricao)) {
    stop("A tabela de classificação do IBS e CBS tem tpRBSN ou tpDoacao sem significado na aba deles", call. = FALSE)
  }

  csts = ler_aba_de_cst(planilha_baixada$arquivo, abas$cst)
  conferir_colunas(csts, c("CST-IBS/CBS", "Descrição CST-IBS/CBS", names(INDICADORES_DO_CST)), "de CST do IBS e CBS")
  cst = data.frame(
    codigo = sprintf("%03d", as.integer(csts[["CST-IBS/CBS"]])),
    descricao = trimws(csts[["Descrição CST-IBS/CBS"]]),
    inicio = as.Date(NA),
    fim = as.Date(NA)
  )
  for (nome_na_planilha in names(INDICADORES_DO_CST)) {
    cst[[INDICADORES_DO_CST[[nome_na_planilha]]]] = as.integer(csts[[nome_na_planilha]])
  }
  list(classificacao = classificacao, cst = cst, titulo = planilha_baixada$titulo)
}

# A Tabela de Código de Crédito Presumido do IBS e CBS (Informe Técnico 2025.002): o código (cCredPres, com dois
# dígitos, como no XML), o que cada um permite e exige no documento e a vigência na CBS e no IBS. Na planilha de
# 23/06/2026 a dedução se chamava "ind_DeduzCredPres". As colunas de texto são orientações (a alíquota "calculada e
# divulgada anualmente", o cClassTrib da nota referenciada), como o IT as descreve.
COLUNAS_DO_CREDITO_PRESUMIDO = c(
  "Apropria via NF?" = "apropria_no_documento", "Apropria via evento?" = "apropria_por_evento",
  indDeduzCredPres = "deduz_do_tributo", ind_gCBSCredPres = "grupo_credito_cbs", ind_gIBSCredPres = "grupo_credito_ibs",
  indDecPag = "declaracao_pagamento", indNFe = "permitido_na_nfe", indNFCe = "permitido_na_nfce",
  indCTe = "permitido_no_cte", indNFSe = "permitido_na_nfse"
)

# O texto de uma coluna de orientação. A célula de número vem do Excel com 17 dígitos ("7.0000000000000007E-2" para
# os 7%): volta ao número que a planilha mostra, em 10 algarismos e sem notação científica ("0.07").
texto_da_orientacao = function(valores) {
  textos = trimws(as.character(valores))
  numeros = suppressWarnings(as.numeric(textos))
  de_numero = !is.na(numeros) & grepl("^[-+0-9.eE]+$", textos)
  textos[de_numero] = format(signif(numeros[de_numero], 10), scientific = FALSE, drop0trailing = TRUE, trim = TRUE)
  textos
}

ler_aba_de_credito_presumido = function(arquivo_da_planilha, tipos_das_colunas = NULL) {
  creditos = readxl::read_excel(arquivo_da_planilha, sheet = "cCredPres", col_types = tipos_das_colunas)
  names(creditos)[names(creditos) == "ind_DeduzCredPres"] = "indDeduzCredPres"
  creditos[!is.na(creditos[["cCredPres"]]), ]
}

baixar_credito_presumido = function(pasta_temporaria) {
  planilha_baixada = baixar_planilha_mais_nova_da_reforma("credito_presumido", pasta_temporaria)
  creditos = ler_aba_de_credito_presumido(planilha_baixada$arquivo)
  conferir_colunas(creditos, c(
    "cCredPres", "Descrição", "LC 214/2025", "Alíquota CBS", "Alíquota IBS", "pAliqCredPresCBS", "pAliqCredPresIBS",
    "pRedTransicaoIBS", "cClassTrib nota referenciada", "dIniVigCBS", "dFimVigCBS", "dIniVigIBS", "dFimVigIBS",
    names(COLUNAS_DO_CREDITO_PRESUMIDO)
  ), "de crédito presumido do IBS e CBS")
  credito_presumido = data.frame(
    codigo = sprintf("%02d", as.integer(creditos[["cCredPres"]])),
    descricao = trimws(creditos[["Descrição"]]),
    texto_da_lc_214 = trimws(creditos[["LC 214/2025"]]),
    orientacao_aliquota_cbs = texto_da_orientacao(creditos[["Alíquota CBS"]]),
    orientacao_aliquota_ibs = texto_da_orientacao(creditos[["Alíquota IBS"]]),
    orientacao_percentual_cbs = texto_da_orientacao(creditos[["pAliqCredPresCBS"]]),
    orientacao_percentual_ibs = texto_da_orientacao(creditos[["pAliqCredPresIBS"]]),
    orientacao_reducao_transicao_ibs = texto_da_orientacao(creditos[["pRedTransicaoIBS"]]),
    orientacao_classificacao_referenciada = texto_da_orientacao(creditos[["cClassTrib nota referenciada"]]),
    inicio_cbs = as.Date(creditos[["dIniVigCBS"]]),
    fim_cbs = as.Date(creditos[["dFimVigCBS"]]),
    inicio_ibs = as.Date(creditos[["dIniVigIBS"]]),
    fim_ibs = as.Date(creditos[["dFimVigIBS"]])
  )
  for (nome_na_planilha in names(COLUNAS_DO_CREDITO_PRESUMIDO)) {
    credito_presumido[[COLUNAS_DO_CREDITO_PRESUMIDO[[nome_na_planilha]]]] = as.integer(creditos[[nome_na_planilha]])
  }
  list(tabela = credito_presumido, titulo = planilha_baixada$titulo)
}

# O controle de versões do Informe Técnico 2025.002 (v1.71): o prazo de produção de cada versão ("Até 04/05/26"). A
# mudança de uma versão sem prazo lá está em produção, no máximo, no prazo da versão mais nova que ainda a traz (a que a
# SEFAZ teria de ter implantado até lá). O prazo da primeira versão seguinte não serve: a 1.40 tirou a 200001 da NF-e,
# a 1.50 (prazo de 04/05/2026) já trazia isso, e a SEFAZ autorizou NF-e com a 200001 em 01/06/2026. Versão nova: uma
# linha aqui, com o prazo do IT dela; enquanto não tiver, as mudanças só dela ficam sem prazo conhecido.
VERSOES_DO_INFORME_TECNICO = data.frame(
  versao = c("1.20", "1.21", "1.30", "1.31", "1.40", "1.50", "1.60", "1.70", "1.71"),
  prazo_de_producao = as.Date(c(NA, NA, NA, NA, NA, "2026-05-04", "2026-07-06", "2026-10-16", "2026-10-30"))
)

# As planilhas da Reforma publicadas no portal desde a versão 1.20 do IT (a que estava publicada quando as regras de
# validação da NT 2025.002 entraram em produção, em 10/11/2025): a de classificação (com a aba de CST) e a de crédito
# presumido, com a data de publicação e a versão do IT de cada uma.
PUBLICACOES_DA_REFORMA = data.frame(
  planilha = c(rep("classificacao", 8), rep("credito_presumido", 5)),
  publicada_em = as.Date(c("2025-10-03", "2025-11-24", "2025-12-15", "2026-01-28", "2026-04-15", "2026-06-23",
                           "2026-10-01", "2026-10-30",
                           "2025-10-03", "2025-10-07", "2025-12-15", "2026-06-23", "2026-10-01")),
  versao = c("1.20", "1.30", "1.31", "1.40", "1.50", "1.60", "1.70", "1.71",
             "1.20", "1.21", "1.31", "1.60", "1.70")
)

# O que acha os links de cada planilha na página do portal.
LINKS_DAS_PLANILHAS_DA_REFORMA = c(
  classificacao = "contains(normalize-space(.), 'Classificação Tributária do IBS')",
  credito_presumido = "contains(normalize-space(.), 'Crédito Presumido do IBS')"
)

# A planilha da Reforma publicada por último, pela data no texto do link ("Publicada em 30/10/2026"), com o mesmo
# filtro da história: o começo do título já mudou três vezes, e a página não é ordenada por data.
baixar_planilha_mais_nova_da_reforma = function(planilha, pasta_temporaria) {
  links_achados = links_do_portal(LINKS_DAS_PLANILHAS_DA_REFORMA[[planilha]], pasta_temporaria)
  publicada_em = as.Date(sub(".*Publicad[ao] em (\\d{2}/\\d{2}/\\d{4}).*", "\\1", links_achados$titulo), format = "%d/%m/%Y")
  if (nrow(links_achados) == 0 || anyNA(publicada_em)) {
    stop("A página do portal não tem a planilha da Reforma (", planilha, ") com a data de publicação no link", call. = FALSE)
  }
  mais_nova = which.max(publicada_em)
  list(arquivo = baixar_link_do_portal(links_achados$endereco[mais_nova], pasta_temporaria),
       titulo = links_achados$titulo[mais_nova])
}

# O prazo de produção de cada versão do IT, pelo nome da versão (NA quando o IT não diz).
prazo_de_cada_versao = function() {
  prazos = VERSOES_DO_INFORME_TECNICO$prazo_de_producao
  names(prazos) = VERSOES_DO_INFORME_TECNICO$versao
  prazos
}

# O valor como texto, para comparar uma versão com a outra: "60" e "60.0" são o mesmo número; vazio fica NA.
valor_para_comparar = function(valores) {
  numeros = suppressWarnings(as.numeric(valores))
  textos = as.character(numeros)
  textos[is.na(numeros)] = NA
  textos
}

# De uma versão da planilha de classificação, os valores que a história acompanha, um por linha: a tabela do pacote, o
# código, a coluna (com o nome do pacote; "existe" diz que o código está na versão) e o valor. Só as colunas que a
# versão tem.
valores_da_classificacao = function(arquivo_da_planilha) {
  abas = abas_da_planilha_da_reforma(arquivo_da_planilha)
  classificacoes = readxl::read_excel(arquivo_da_planilha, sheet = abas$classificacao, col_types = "text")
  classificacoes = classificacoes[!is.na(classificacoes[["cClassTrib"]]), ]
  codigos_da_classificacao = formatC(as.integer(classificacoes[["cClassTrib"]]), width = 6, flag = "0")
  csts = ler_aba_de_cst(arquivo_da_planilha, abas$cst, "text")
  codigos_do_cst = sprintf("%03d", as.integer(csts[["CST-IBS/CBS"]]))
  partes = list(
    data.frame(tabela = "classificacao_ibs_cbs", codigo = codigos_da_classificacao, coluna = "existe", valor = "1"),
    data.frame(tabela = "cst_ibs_cbs", codigo = codigos_do_cst, coluna = "existe", valor = "1")
  )
  colunas_da_classificacao = c(pRedIBS = "reducao_ibs", pRedCBS = "reducao_cbs", INDICADORES_DA_CLASSIFICACAO)
  for (nome_na_planilha in intersect(names(colunas_da_classificacao), names(classificacoes))) {
    partes[[length(partes) + 1]] = data.frame(
      tabela = "classificacao_ibs_cbs", codigo = codigos_da_classificacao,
      coluna = colunas_da_classificacao[[nome_na_planilha]], valor = valor_para_comparar(classificacoes[[nome_na_planilha]])
    )
  }
  for (nome_na_planilha in intersect(names(INDICADORES_DO_CST), names(csts))) {
    partes[[length(partes) + 1]] = data.frame(
      tabela = "cst_ibs_cbs", codigo = codigos_do_cst, coluna = INDICADORES_DO_CST[[nome_na_planilha]],
      valor = valor_para_comparar(csts[[nome_na_planilha]])
    )
  }
  do.call(rbind, partes)
}

valores_do_credito_presumido = function(arquivo_da_planilha) {
  creditos = ler_aba_de_credito_presumido(arquivo_da_planilha, "text")
  codigos = sprintf("%02d", as.integer(creditos[["cCredPres"]]))
  partes = list(data.frame(tabela = "credito_presumido_ibs_cbs", codigo = codigos, coluna = "existe", valor = "1"))
  for (nome_na_planilha in intersect(names(COLUNAS_DO_CREDITO_PRESUMIDO), names(creditos))) {
    partes[[length(partes) + 1]] = data.frame(
      tabela = "credito_presumido_ibs_cbs", codigo = codigos, coluna = COLUNAS_DO_CREDITO_PRESUMIDO[[nome_na_planilha]],
      valor = valor_para_comparar(creditos[[nome_na_planilha]])
    )
  }
  do.call(rbind, partes)
}

# O que mudou de uma versão para a seguinte: o código que entrou ou saiu (coluna "existe") e o valor que mudou num
# código que está nas duas, só nas colunas que as duas têm.
mudancas_entre_versoes = function(valores_antes, valores_depois) {
  juntos = merge(valores_antes, valores_depois, by = c("tabela", "codigo", "coluna"), all = TRUE,
                 suffixes = c("_antes", "_depois"))
  colunas_das_duas = intersect(paste(valores_antes$tabela, valores_antes$coluna), paste(valores_depois$tabela, valores_depois$coluna))
  codigos_antes = paste(valores_antes$tabela, valores_antes$codigo)
  codigos_depois = paste(valores_depois$tabela, valores_depois$codigo)
  existe = juntos$coluna == "existe"
  juntos$valor_antes[existe & is.na(juntos$valor_antes)] = "0"
  juntos$valor_depois[existe & is.na(juntos$valor_depois)] = "0"
  nas_duas = paste(juntos$tabela, juntos$codigo) %in% intersect(codigos_antes, codigos_depois) &
    paste(juntos$tabela, juntos$coluna) %in% colunas_das_duas
  mudou = (is.na(juntos$valor_antes) != is.na(juntos$valor_depois)) |
    (!is.na(juntos$valor_antes) & !is.na(juntos$valor_depois) & juntos$valor_antes != juntos$valor_depois)
  juntos[mudou & (existe | nas_duas), c("tabela", "codigo", "coluna", "valor_antes", "valor_depois")]
}

# As versões publicadas de uma planilha da Reforma, da mais antiga para a mais nova, com a versão do IT e o prazo de
# produção de cada uma.
versoes_publicadas = function(planilha, pasta_temporaria) {
  links_achados = links_do_portal(LINKS_DAS_PLANILHAS_DA_REFORMA[[planilha]], pasta_temporaria)
  links_achados$publicada_em = as.Date(sub(".*Publicad[ao] em (\\d{2}/\\d{2}/\\d{4}).*", "\\1", links_achados$titulo),
                                       format = "%d/%m/%Y")
  if (anyNA(links_achados$publicada_em)) {
    stop("Link da planilha da Reforma sem a data de publicação: ",
         paste(links_achados$titulo[is.na(links_achados$publicada_em)], collapse = "; "), call. = FALSE)
  }
  publicacoes = PUBLICACOES_DA_REFORMA[PUBLICACOES_DA_REFORMA$planilha == planilha, ]
  links_achados = links_achados[links_achados$publicada_em >= min(publicacoes$publicada_em), ]
  links_achados = links_achados[order(links_achados$publicada_em), ]
  sem_versao = !(links_achados$publicada_em %in% publicacoes$publicada_em)
  if (any(sem_versao)) {
    cat("::warning::Planilha da Reforma publicada sem versão em PUBLICACOES_DA_REFORMA (as mudanças dela ficam sem prazo",
        "de produção):", paste(links_achados$titulo[sem_versao], collapse = "; "), "\n")
  }
  faltam = publicacoes$publicada_em[!(publicacoes$publicada_em %in% links_achados$publicada_em)]
  if (length(faltam) > 0) {
    stop("O portal não tem mais a planilha de ", planilha, " publicada em ", paste(format(faltam, "%d/%m/%Y"), collapse = ", "),
         call. = FALSE)
  }
  links_achados$versao = publicacoes$versao[match(links_achados$publicada_em, publicacoes$publicada_em)]
  links_achados$em_producao_ate = prazo_de_cada_versao()[links_achados$versao]
  links_achados
}

# O prazo de produção de cada mudança da versão na `posicao`: o da própria versão; sem ele, o da versão mais nova
# (com prazo) que ainda traz o mesmo valor, sem ter mudado de novo no caminho; NA quando nenhuma traz. O da primeira
# versão com prazo não serve: a SEFAZ autorizou NF-e com a 200001, que a 1.40 tirou da NF-e, depois do prazo da 1.50.
prazo_de_quem_traz_a_mudanca = function(mudancas_da_versao, posicao, versoes, valores_de_cada_versao) {
  prazos = rep(as.Date(unname(versoes$em_producao_ate[posicao])), nrow(mudancas_da_versao))
  if (!anyNA(prazos)) {
    return(prazos)
  }
  chaves_das_mudancas = paste(mudancas_da_versao$tabela, mudancas_da_versao$codigo, mudancas_da_versao$coluna)
  da_coluna_existe = mudancas_da_versao$coluna == "existe"
  ainda_traz = is.na(prazos)
  for (seguinte in seq_len(nrow(versoes))[seq_len(nrow(versoes)) > posicao]) {
    valores = valores_de_cada_versao[[seguinte]]
    valor_na_seguinte = valores$valor[match(chaves_das_mudancas, paste(valores$tabela, valores$codigo, valores$coluna))]
    valor_na_seguinte[da_coluna_existe & is.na(valor_na_seguinte)] = "0"
    mesmo_valor = (is.na(valor_na_seguinte) & is.na(mudancas_da_versao$valor_depois)) |
      (!is.na(valor_na_seguinte) & !is.na(mudancas_da_versao$valor_depois) & valor_na_seguinte == mudancas_da_versao$valor_depois)
    ainda_traz = ainda_traz & mesmo_valor
    prazo_da_seguinte = as.Date(unname(versoes$em_producao_ate[seguinte]))
    if (!is.na(prazo_da_seguinte)) {
      prazos[ainda_traz] = prazo_da_seguinte
    }
  }
  prazos
}

# A mudança que ficou sem prazo porque outra versão a desfez antes de alguma com prazo trazer o valor dela (o 000002
# na NFGas entrou na 1.30 e saiu na 1.31) vale até o prazo de quem a desfez: depois dele, a produção já passou dela. As
# mudanças vêm da mais antiga para a mais nova; a conta vai de trás para a frente, para a seguinte já ter o prazo.
prazo_de_quem_desfaz_a_mudanca = function(mudancas_da_planilha) {
  chaves = paste(mudancas_da_planilha$tabela, mudancas_da_planilha$codigo, mudancas_da_planilha$coluna)
  for (linha in rev(seq_len(nrow(mudancas_da_planilha)))) {
    if (!is.na(mudancas_da_planilha$em_producao_ate[linha])) {
      next
    }
    seguintes = which(chaves == chaves[linha] & mudancas_da_planilha$publicada_em > mudancas_da_planilha$publicada_em[linha])
    if (length(seguintes) > 0) {
      quem_desfaz = seguintes[which.min(mudancas_da_planilha$publicada_em[seguintes])]
      mudancas_da_planilha$em_producao_ate[linha] = mudancas_da_planilha$em_producao_ate[quem_desfaz]
    }
  }
  mudancas_da_planilha
}

# A história das planilhas da Reforma: baixa do portal cada versão publicada desde a 1.20 e lista o que mudou em cada
# uma, com o prazo de produção dela. É o que a conferência do IBS e da CBS consulta para uma nota emitida antes de uma
# mudança, que a SEFAZ conferiu pela versão da época.
baixar_historia_da_reforma = function(pasta_temporaria) {
  mudancas = list()
  publicadas = list()
  for (planilha in names(LINKS_DAS_PLANILHAS_DA_REFORMA)) {
    versoes = versoes_publicadas(planilha, pasta_temporaria)
    publicadas[[planilha]] = versoes$publicada_em
    valores_de_cada_versao = list()
    for (posicao in seq_len(nrow(versoes))) {
      arquivo_da_versao = baixar_link_do_portal(versoes$endereco[posicao], pasta_temporaria)
      if (planilha == "classificacao") {
        valores_de_cada_versao[[posicao]] = valores_da_classificacao(arquivo_da_versao)
      } else {
        valores_de_cada_versao[[posicao]] = valores_do_credito_presumido(arquivo_da_versao)
      }
    }
    mudancas_da_planilha = list()
    for (posicao in seq_len(nrow(versoes))[-1]) {
      mudancas_da_versao = mudancas_entre_versoes(valores_de_cada_versao[[posicao - 1]], valores_de_cada_versao[[posicao]])
      if (nrow(mudancas_da_versao) > 0) {
        mudancas_da_versao$versao = versoes$versao[posicao]
        mudancas_da_versao$publicada_em = versoes$publicada_em[posicao]
        mudancas_da_versao$em_producao_ate = prazo_de_quem_traz_a_mudanca(mudancas_da_versao, posicao, versoes,
                                                                           valores_de_cada_versao)
        mudancas_da_planilha[[length(mudancas_da_planilha) + 1]] = mudancas_da_versao
      }
    }
    if (length(mudancas_da_planilha) > 0) {
      mudancas[[length(mudancas) + 1]] = prazo_de_quem_desfaz_a_mudanca(do.call(rbind, mudancas_da_planilha))
    }
  }
  historia = do.call(rbind, mudancas)
  names(historia)[names(historia) == "valor_antes"] = "antes"
  names(historia)[names(historia) == "valor_depois"] = "depois"
  historia = historia[order(historia$publicada_em, historia$tabela, historia$codigo, historia$coluna), ]
  todas_as_datas = do.call(c, publicadas)
  list(tabela = historia, primeira = min(todas_as_datas), ultima = max(todas_as_datas))
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

# ---- serviços web da SEFAZ ----

PAGINA_DOS_SERVICOS_DE_HOMOLOGACAO = "https://hom.nfe.fazenda.gov.br/portal/webServices.aspx"
SIGLAS_DAS_UFS = c("AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", "MA", "MG", "MS", "MT", "PA", "PB", "PE", "PI",
                   "PR", "RJ", "RN", "RO", "RR", "RS", "SC", "SE", "SP", "TO")
# Antes das tabelas, a página diz que UFs usam cada SEFAZ virtual, num elemento com este id.
LISTAS_DE_UFS_DA_PAGINA = utils::read.table(header = TRUE, sep = ";", strip.white = TRUE, stringsAsFactors = FALSE, text = "
id                                               ; autorizador ; uso
ctl00_ContentPlaceHolder1_lblUsuariosSVAN         ; SVAN        ; todos os serviços
ctl00_ContentPlaceHolder1_lblUsuarioSVRS_ConsCad  ; SVRS        ; consulta de cadastro
ctl00_ContentPlaceHolder1_lblUsuarioSVRS_DemServ  ; SVRS        ; demais serviços
ctl00_ContentPlaceHolder1_lblUsuariosSVCAN        ; SVC-AN      ; contingência
ctl00_ContentPlaceHolder1_lblUsuariosSVCRS        ; SVC-RS      ; contingência
")

# A Relação de Serviços Web: uma tabela por autorizador (a legenda traz a sigla entre parênteses, como
# "Sefaz Amazonas - (AM)"), com o serviço, a versão e o endereço. A UF com tabela própria usa a própria SEFAZ em
# todos os serviços; as outras, as SEFAZ virtuais que a página lista.
baixar_servicos_da_sefaz = function(endereco_da_pagina, ambiente) {
  pedido_da_pagina = httr2::req_timeout(httr2::request(endereco_da_pagina), 120)
  pagina = xml2::read_html(httr2::resp_body_raw(httr2::req_perform(pedido_da_pagina)))
  servicos = data.frame()
  for (tabela_do_autorizador in xml2::xml_find_all(pagina, "//table[caption]")) {
    legenda = trimws(xml2::xml_text(xml2::xml_find_first(tabela_do_autorizador, "caption")))
    autorizador = sub("^.*\\((.*)\\)$", "\\1", legenda)
    for (linha in xml2::xml_find_all(tabela_do_autorizador, ".//tr[td]")) {
      celulas = trimws(xml2::xml_text(xml2::xml_find_all(linha, "td")))
      if (length(celulas) == 3 && nzchar(celulas[3])) {
        servicos = rbind(servicos, data.frame(documento = "NF-e", ambiente = ambiente, autorizador = autorizador,
                                              servico = celulas[1], versao = celulas[2], endereco = celulas[3]))
      }
    }
  }
  if (nrow(servicos) == 0 || !all(startsWith(servicos$endereco, "https://"))) {
    stop("A Relação de Serviços Web mudou de formato: ", endereco_da_pagina, call. = FALSE)
  }
  ufs_com_sefaz_propria = intersect(SIGLAS_DAS_UFS, servicos$autorizador)
  autorizadores = data.frame(documento = "NF-e", ambiente = ambiente, uf = ufs_com_sefaz_propria,
                             uso = "todos os serviços", autorizador = ufs_com_sefaz_propria)
  for (numero_da_lista in seq_len(nrow(LISTAS_DE_UFS_DA_PAGINA))) {
    lista = LISTAS_DE_UFS_DA_PAGINA[numero_da_lista, ]
    elemento = xml2::xml_find_first(pagina, paste0("//*[@id='", lista$id, "']"))
    if (inherits(elemento, "xml_missing")) {
      stop("A Relação de Serviços Web não traz mais a lista ", lista$id, ": ", endereco_da_pagina, call. = FALSE)
    }
    ufs_da_lista = trimws(strsplit(xml2::xml_text(elemento), ",")[[1]])
    if (!all(ufs_da_lista %in% SIGLAS_DAS_UFS)) {
      stop("A lista ", lista$id, " traz o que não é UF: ", xml2::xml_text(elemento), call. = FALSE)
    }
    autorizadores = rbind(autorizadores, data.frame(documento = "NF-e", ambiente = ambiente, uf = ufs_da_lista,
                                                    uso = lista$uso, autorizador = lista$autorizador))
  }
  list(
    servicos = servicos[order(servicos$autorizador, servicos$servico), ],
    autorizadores = autorizadores[order(autorizadores$uf, autorizadores$uso), ]
  )
}

# A NFC-e tem endereços próprios em quase toda UF, publicados no Portal da NFC-e (mantido pela SVRS), uma tabela por
# autorizador e ambiente, com a legenda "SEFAZ Amazonas (AM) - Homologação". MG tem NFC-e própria que esse portal não
# lista: os endereços dela vêm da página da SEFAZ-MG.
PAGINA_DOS_SERVICOS_DA_NFCE = "https://dfe-portal.svrs.rs.gov.br/Nfce/Servicos"
PAGINA_DOS_SERVICOS_DA_NFCE_DE_MG = "https://portalsped.fazenda.mg.gov.br/spedmg/nfce/web-services/"
# Os nomes de serviço da página de MG, nos nomes que o Portal da NFC-e usa.
SERVICO_PELO_NOME_DE_MG = c(
  "Recepção Evento" = "RecepcaoEvento", "Consulta" = "NFeConsultaProtocolo", "Status Serviço" = "NFeStatusServico",
  "Inutilização" = "NFeInutilizacao", "Autorização" = "NFeAutorizacao", "Retorno Autorização" = "NFeRetAutorizacao"
)
NOME_DE_CADA_AMBIENTE = c(homologacao = "Homologação", producao = "Produção")

# Os portais que a SVRS mantém (NFC-e, MDF-e): uma tabela por autorizador e ambiente, com a legenda
# "SEFAZ Amazonas (AM) - Homologação" e as linhas com o serviço, a versão e o endereço.
servicos_do_portal_da_svrs = function(endereco_da_pagina, documento, ambiente) {
  nome_do_ambiente = NOME_DE_CADA_AMBIENTE[[ambiente]]
  pagina = xml2::read_html(httr2::resp_body_raw(httr2::req_perform(httr2::req_timeout(httr2::request(endereco_da_pagina), 120))))
  servicos = data.frame()
  for (tabela_do_autorizador in xml2::xml_find_all(pagina, "//table[caption]")) {
    legenda = trimws(gsub("\\s+", " ", xml2::xml_text(xml2::xml_find_first(tabela_do_autorizador, "caption"))))
    if (!endsWith(legenda, paste0("- ", nome_do_ambiente))) {
      next
    }
    autorizador = sub("^.*\\((.*)\\) - .*$", "\\1", legenda)
    for (linha in xml2::xml_find_all(tabela_do_autorizador, ".//tr[td]")) {
      celulas = trimws(xml2::xml_text(xml2::xml_find_all(linha, "td")))
      if (length(celulas) >= 4 && startsWith(celulas[4], "https://")) {
        servicos = rbind(servicos, data.frame(documento = documento, ambiente = ambiente, autorizador = autorizador,
                                              servico = celulas[2], versao = celulas[3], endereco = celulas[4]))
      }
    }
  }
  servicos
}

baixar_servicos_da_nfce = function(ambiente) {
  nome_do_ambiente = NOME_DE_CADA_AMBIENTE[[ambiente]]
  servicos = servicos_do_portal_da_svrs(PAGINA_DOS_SERVICOS_DA_NFCE, "NFC-e", ambiente)
  # MG: a página tem uma tabela por ambiente, logo depois do título "Ambiente de Homologação:"; ela não diz a versão.
  pagina_de_mg = xml2::read_html(httr2::resp_body_raw(httr2::req_perform(httr2::req_timeout(httr2::request(PAGINA_DOS_SERVICOS_DA_NFCE_DE_MG), 120))))
  for (tabela_de_mg in xml2::xml_find_all(pagina_de_mg, "//table")) {
    titulo = xml2::xml_find_first(tabela_de_mg, "preceding::*[self::h1 or self::h2 or self::h3 or self::h4 or self::strong][1]")
    if (!grepl(paste0("Ambiente de ", nome_do_ambiente), xml2::xml_text(titulo))) {
      next
    }
    for (linha in xml2::xml_find_all(tabela_de_mg, ".//tr[td]")) {
      celulas = trimws(xml2::xml_text(xml2::xml_find_all(linha, "td")))
      servico = unname(SERVICO_PELO_NOME_DE_MG[celulas[1]])
      if (length(celulas) == 2 && !is.na(servico)) {
        servicos = rbind(servicos, data.frame(documento = "NFC-e", ambiente = ambiente, autorizador = "MG",
                                              servico = servico, versao = NA, endereco = celulas[2]))
      }
    }
  }
  if (nrow(servicos) == 0 || !all(startsWith(servicos$endereco, "https://")) || !("MG" %in% servicos$autorizador) ||
      !("SVRS" %in% servicos$autorizador)) {
    stop("A página de serviços da NFC-e (do Portal ou de MG) mudou de formato", call. = FALSE)
  }
  # As UFs com autorizador próprio usam o dele; as outras, a SVRS. O Portal da NFC-e não lista as UFs da SVRS: em
  # homologação (03/11/2026) ela respondeu a todas as outras 19 e recusou (410) as 8 de autorizador próprio.
  ufs_com_sefaz_propria = intersect(SIGLAS_DAS_UFS, servicos$autorizador)
  ufs_da_svrs = setdiff(SIGLAS_DAS_UFS, ufs_com_sefaz_propria)
  autorizadores = data.frame(documento = "NFC-e", ambiente = ambiente, uf = c(ufs_com_sefaz_propria, ufs_da_svrs),
                             uso = "todos os serviços", autorizador = c(ufs_com_sefaz_propria, rep("SVRS", length(ufs_da_svrs))))
  list(
    servicos = servicos[order(servicos$autorizador, servicos$servico), ],
    autorizadores = autorizadores[order(autorizadores$uf), ]
  )
}

# O MDF-e tem um autorizador só, a SVRS, para todas as UFs; a página dela segue o molde da NFC-e.
PAGINA_DOS_SERVICOS_DO_MDFE = "https://dfe-portal.svrs.rs.gov.br/Mdfe/Servicos"

baixar_servicos_do_mdfe = function(ambiente) {
  servicos = servicos_do_portal_da_svrs(PAGINA_DOS_SERVICOS_DO_MDFE, "MDF-e", ambiente)
  if (nrow(servicos) == 0 || !identical(unique(servicos$autorizador), "SVRS")) {
    stop("A página de serviços do MDF-e mudou de formato: ", PAGINA_DOS_SERVICOS_DO_MDFE, call. = FALSE)
  }
  list(
    servicos = servicos[order(servicos$servico), ],
    autorizadores = data.frame(documento = "MDF-e", ambiente = ambiente, uf = SIGLAS_DAS_UFS, uso = "todos os serviços",
                               autorizador = "SVRS")
  )
}

# A Relação de Serviços Web do Portal do CT-e, no molde da do Portal da NF-e. A legenda das SEFAZ virtuais traz duas
# siglas ("Sefaz Virtual Rio Grande do Sul - (SVRS) e Sefaz Virtual de Contingência do RS (SVC-RS)"): vale a primeira.
PAGINA_DOS_SERVICOS_DO_CTE_DE_HOMOLOGACAO = "https://hom.cte.fazenda.gov.br/portal/webServices.aspx"
LISTAS_DE_UFS_DA_PAGINA_DO_CTE = utils::read.table(header = TRUE, sep = ";", strip.white = TRUE, stringsAsFactors = FALSE, text = "
id                                         ; autorizador
ctl00_ContentPlaceHolder1_lblUsuariosSVSP   ; SVSP
ctl00_ContentPlaceHolder1_lblUsuarioSVRS    ; SVRS
")

baixar_servicos_do_cte = function(endereco_da_pagina, ambiente) {
  pagina = xml2::read_html(httr2::resp_body_raw(httr2::req_perform(httr2::req_timeout(httr2::request(endereco_da_pagina), 120))))
  servicos = data.frame()
  for (tabela_do_autorizador in xml2::xml_find_all(pagina, "//table[caption]")) {
    legenda = trimws(gsub("\\s+", " ", xml2::xml_text(xml2::xml_find_first(tabela_do_autorizador, "caption"))))
    autorizador = sub("^[^(]*\\(([^)]*)\\).*$", "\\1", legenda)
    for (linha in xml2::xml_find_all(tabela_do_autorizador, ".//tr[td]")) {
      celulas = trimws(xml2::xml_text(xml2::xml_find_all(linha, "td")))
      if (length(celulas) == 3 && startsWith(celulas[3], "https://")) {
        servicos = rbind(servicos, data.frame(documento = "CT-e", ambiente = ambiente, autorizador = autorizador,
                                              servico = celulas[1], versao = celulas[2], endereco = celulas[3]))
      }
    }
  }
  ufs_com_sefaz_propria = intersect(SIGLAS_DAS_UFS, servicos$autorizador)
  autorizadores = data.frame(documento = "CT-e", ambiente = ambiente, uf = ufs_com_sefaz_propria,
                             uso = "todos os serviços", autorizador = ufs_com_sefaz_propria)
  for (numero_da_lista in seq_len(nrow(LISTAS_DE_UFS_DA_PAGINA_DO_CTE))) {
    lista = LISTAS_DE_UFS_DA_PAGINA_DO_CTE[numero_da_lista, ]
    elemento = xml2::xml_find_first(pagina, paste0("//*[@id='", lista$id, "']"))
    if (inherits(elemento, "xml_missing")) {
      stop("A Relação de Serviços Web do CT-e não traz mais a lista ", lista$id, ": ", endereco_da_pagina, call. = FALSE)
    }
    ufs_da_lista = trimws(strsplit(xml2::xml_text(elemento), ",")[[1]])
    autorizadores = rbind(autorizadores, data.frame(documento = "CT-e", ambiente = ambiente, uf = ufs_da_lista,
                                                    uso = "todos os serviços", autorizador = lista$autorizador))
  }
  if (nrow(servicos) == 0 || !setequal(autorizadores$uf, SIGLAS_DAS_UFS) || anyDuplicated(autorizadores$uf) > 0) {
    stop("A Relação de Serviços Web do CT-e mudou de formato: ", endereco_da_pagina, call. = FALSE)
  }
  list(
    servicos = servicos[order(servicos$autorizador, servicos$servico), ],
    autorizadores = autorizadores[order(autorizadores$uf), ]
  )
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
credito_presumido_do_portal = baixar_credito_presumido(pasta_temporaria)
historia_da_reforma = baixar_historia_da_reforma(pasta_temporaria)
ncm_baixada = baixar_ncm()
meios_do_portal = baixar_meios_de_pagamento(pasta_temporaria)
bandeiras_do_portal = baixar_bandeiras_de_cartao(pasta_temporaria)
biocombustivel_do_portal = baixar_indice_biocombustivel(pasta_temporaria)
combustiveis_do_portal = baixar_combustiveis_monofasicos(pasta_temporaria)
servicos_de_homologacao = baixar_servicos_da_sefaz(PAGINA_DOS_SERVICOS_DE_HOMOLOGACAO, "homologacao")
for (servicos_do_documento in list(baixar_servicos_da_nfce("homologacao"),
                                    baixar_servicos_do_cte(PAGINA_DOS_SERVICOS_DO_CTE_DE_HOMOLOGACAO, "homologacao"),
                                    baixar_servicos_do_mdfe("homologacao"))) {
  servicos_de_homologacao$servicos = rbind(servicos_de_homologacao$servicos, servicos_do_documento$servicos)
  servicos_de_homologacao$autorizadores = rbind(servicos_de_homologacao$autorizadores, servicos_do_documento$autorizadores)
}
fontes = rbind(fontes, data.frame(
  tabela = c("cst_ibs_cbs", "classificacao_ibs_cbs", "credito_presumido_ibs_cbs", "mudancas_ibs_cbs", "ncm",
             "meios_pagamento", "bandeiras_cartao", "biocombustivel_ibs_cbs", "combustiveis_monofasicos",
             "servicos_sefaz", "autorizadores_sefaz"),
  fonte = c(
    paste0("Portal da NF-e, ", tabelas_da_reforma$titulo, " (Informe Técnico 2025.002), aba de CST"),
    paste0("Portal da NF-e, ", tabelas_da_reforma$titulo, " (Informe Técnico 2025.002), aba de cClassTrib"),
    paste0("Portal da NF-e, ", credito_presumido_do_portal$titulo, " (Informe Técnico 2025.002)"),
    paste0("Portal da NF-e, as versões das tabelas de Classificação Tributária e de Crédito Presumido do IBS e CBS ",
           "publicadas de ", format(historia_da_reforma$primeira, "%d/%m/%Y"), " a ",
           format(historia_da_reforma$ultima, "%d/%m/%Y"), ", comparadas uma com a seguinte; prazos de produção do ",
           "controle de versões do Informe Técnico 2025.002"),
    paste0("Portal Único Siscomex, nomenclatura NCM (", ncm_baixada$situacao, ", ", ncm_baixada$ato, ")"),
    paste0("Portal da NF-e, ", meios_do_portal$titulo),
    paste0("Portal da NF-e, ", bandeiras_do_portal$titulo),
    paste0("Portal da NF-e, ", biocombustivel_do_portal$titulo, " (Informe Técnico 2025.004)"),
    paste0("Portal da NF-e, ", combustiveis_do_portal$titulo),
    paste0("Portal da NF-e, Relação de Serviços Web de homologação (", PAGINA_DOS_SERVICOS_DE_HOMOLOGACAO,
           "); NFC-e: Portal da NFC-e (", PAGINA_DOS_SERVICOS_DA_NFCE, ") e, para MG, a página da SEFAZ-MG (",
           PAGINA_DOS_SERVICOS_DA_NFCE_DE_MG, "); CT-e: Portal do CT-e (", PAGINA_DOS_SERVICOS_DO_CTE_DE_HOMOLOGACAO,
           "); MDF-e: Portal do MDF-e (", PAGINA_DOS_SERVICOS_DO_MDFE, ")"),
    paste0("Portal da NF-e, Relação de Serviços Web de homologação (", PAGINA_DOS_SERVICOS_DE_HOMOLOGACAO,
           "), UFs de cada SEFAZ virtual; NFC-e: as UFs com autorizador próprio no Portal da NFC-e e em MG, e as outras ",
           "na SVRS (conferido em homologação em 03/11/2026); CT-e: as UFs de cada SEFAZ virtual da página do Portal do ",
           "CT-e; MDF-e: todas na SVRS")
  ),
  versao = NA,
  data_da_versao = NA,
  baixada_em = baixada_em
))

# A tabela dos códigos dos campos e a das alíquotas do IBS e da CBS não são baixadas: são escritas à mão, a primeira a
# partir da documentação dos schemas (conferida por ferramentas/conferir_codigos_dos_campos.R), a segunda a partir da
# LC 214/2025 e da NT 2025.002. O leiaute da EFD ICMS/IPI sai de PDFs, por ferramentas/gerar_leiaute_efd.py. A linha
# de cada uma nas fontes passa adiante como está.
fontes_de_antes = utils::read.csv(file.path(PASTA_DAS_TABELAS, "fontes.csv"), colClasses = "character", na.strings = "")
fontes = rbind(fontes, fontes_de_antes[fontes_de_antes$tabela %in% c("codigos_dos_campos", "aliquotas_ibs_cbs",
                                                                     "leiaute_efd_icms_ipi"), ])

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

# O Portal da NFS-e (gov.br) pode não responder aos servidores do GitHub, como o IBGE: fica a cópia do pacote, com o
# aviso na rodada do robô.
local_operacao_da_nfse = tryCatch(baixar_local_operacao(pasta_temporaria), error = function(erro) erro)
if (inherits(local_operacao_da_nfse, "error")) {
  cat("::warning::Local da operação (cIndOp): o Portal da NFS-e não respondeu, fica a cópia do pacote (",
      gsub("\\s+", " ", conditionMessage(local_operacao_da_nfse)), ")\n")
  fontes_de_antes = utils::read.csv(file.path(PASTA_DAS_TABELAS, "fontes.csv"), colClasses = "character", na.strings = "")
  fontes = rbind(fontes, fontes_de_antes[fontes_de_antes$tabela == "local_operacao_ibs_cbs", ])
  local_operacao_da_nfse = NULL
} else {
  fontes = rbind(fontes, data.frame(
    tabela = "local_operacao_ibs_cbs",
    fonte = paste0("Portal da NFS-e, documentação técnica da RTC (", PAGINA_DA_DOCUMENTACAO_DA_NFSE, "), ",
                   local_operacao_da_nfse$titulo),
    versao = NA,
    data_da_versao = NA,
    baixada_em = baixada_em
  ))
}

gravar_tabela(cfop_do_portal$tabela, "cfop")
gravar_tabela(tabelas_da_reforma$cst, "cst_ibs_cbs")
gravar_tabela(tabelas_da_reforma$classificacao, "classificacao_ibs_cbs")
gravar_tabela(credito_presumido_do_portal$tabela, "credito_presumido_ibs_cbs")
gravar_tabela(historia_da_reforma$tabela, "mudancas_ibs_cbs")
gravar_tabela(ncm_baixada$tabela, "ncm")
gravar_tabela(meios_do_portal$tabela, "meios_pagamento")
gravar_tabela(bandeiras_do_portal$tabela, "bandeiras_cartao")
gravar_tabela(biocombustivel_do_portal$tabela, "biocombustivel_ibs_cbs")
gravar_tabela(combustiveis_do_portal$tabela, "combustiveis_monofasicos")
if (!is.null(local_operacao_da_nfse)) {
  gravar_tabela(local_operacao_da_nfse$tabela, "local_operacao_ibs_cbs")
}
gravar_tabela(servicos_de_homologacao$servicos, "servicos_sefaz")
gravar_tabela(servicos_de_homologacao$autorizadores, "autorizadores_sefaz")
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

# A lista de conferência que o tabelas_atualizar() usa: as linhas e o md5 de cada tabela, e a versão do conjunto.
source("ferramentas/gerar_conferencia_das_tabelas.R", encoding = "UTF-8")
gravar_conferencia_das_tabelas(PASTA_DAS_TABELAS)
