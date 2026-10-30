# O que as ferramentas de schema fazem igual: listar o que cada portal publica, baixar um pacote de schemas e
# tirar de um schema a lista de campos, com as regras de cada um. Usado por baixar_schemas.R,
# vigiar_schemas.R e validar_exemplos.R (com source()). Precisa dos pacotes httr2 e xml2.

# A página de cada portal que lista os pacotes de schemas.
PAGINA_DOS_SCHEMAS = c(
  nfe = "https://www.nfe.fazenda.gov.br/portal/listaConteudo.aspx?tipoConteudo=BMPFMBoln3w=",
  cte = "https://www.cte.fazenda.gov.br/portal/listaConteudo.aspx?tipoConteudo=0xlG1bdBass=",
  mdfe = "https://dfe-portal.svrs.rs.gov.br/Mdfe/Documentos"
)
DOWNLOAD_DO_PORTAL_DO_MDFE = "https://dfe-portal.svrs.rs.gov.br/MDFE/DownloadArquivoEstatico/?sistema=MDFE&tipoArquivo=2&nomeArquivo="

# O pacote de schemas que cada leitor do RNfe segue, o arquivo principal dele e o que é comparado quando sai
# um pacote novo: tipos (TNFe...) e elementos soltos (o modal rodoviário, que o infModal não confere).
SCHEMAS_USADOS = "ferramentas/schemas_usados.csv"
SCHEMAS_VISTOS = "ferramentas/schemas_vistos.csv"
O_QUE_COMPARAR = list(
  nfe = c("TNFe", "TProtNFe"),
  cte = c("TCTe", "TCTeOS", "TProtCTe", "rodo", "rodoOS"),
  mdfe = c("TMDFe", "TProtMDFe", "rodo")
)

NAMESPACE_DO_XSD = c(xs = "http://www.w3.org/2001/XMLSchema")

ler_csv = function(arquivo) {
  utils::read.csv(arquivo, colClasses = "character", encoding = "UTF-8")
}

gravar_csv = function(tabela, arquivo) {
  conexao = file(arquivo, "wb")
  utils::write.csv(tabela, conexao, row.names = FALSE, fileEncoding = "UTF-8", eol = "\n")
  close(conexao)
}

# ---- portais ----

# Abre a página da lista guardando o cookie de sessão: o Portal da NF-e e o do CT-e só entregam o arquivo
# para quem abriu a página antes.
abrir_pagina = function(documento, pasta_temporaria) {
  arquivo_de_cookies = file.path(pasta_temporaria, paste0("cookies_", documento, ".txt"))
  pedido = httr2::req_cookie_preserve(httr2::request(PAGINA_DOS_SCHEMAS[[documento]]), arquivo_de_cookies)
  pedido = httr2::req_timeout(pedido, 120)
  xml2::read_html(httr2::resp_body_string(httr2::req_perform(pedido)))
}

# Uma linha por publicação da página: documento, título (o texto do link) e endereço para baixar.
listar_publicacoes = function(documento, pasta_temporaria) {
  pagina = abrir_pagina(documento, pasta_temporaria)
  if (documento == "mdfe") {
    # No portal do MDF-e o link é montado por JavaScript: download_arquivo_estatico('MDFE', 2, 'arquivo.zip'),
    # em que o 2 é o tipo "schemas".
    links = xml2::xml_find_all(pagina, "//a[contains(@onclick, 'download_arquivo_estatico')]")
    chamadas = xml2::xml_attr(links, "onclick")
    sao_schemas = grepl("download_arquivo_estatico\\('MDFE', *2, *'", chamadas)
    links = links[sao_schemas]
    nomes_dos_arquivos = sub("^.*download_arquivo_estatico\\('MDFE', *2, *'([^']+)'.*$", "\\1", chamadas[sao_schemas])
    enderecos = paste0(DOWNLOAD_DO_PORTAL_DO_MDFE, vapply(nomes_dos_arquivos, utils::URLencode, character(1), reserved = TRUE))
  } else {
    links = xml2::xml_find_all(pagina, "//a[contains(@href, 'exibirArquivo.aspx')]")
    comeco_do_endereco = sub("listaConteudo\\.aspx.*$", "", PAGINA_DOS_SCHEMAS[[documento]])
    # O endereço vem com espaços e quebras de linha em volta. O código do arquivo é Base64, e o portal às
    # vezes publica o "+" dele como espaço: os dois vão como %2B (o portal aceita, conferido em 30/10/2026).
    enderecos = paste0(comeco_do_endereco, gsub("[+ ]", "%2B", trimws(xml2::xml_attr(links, "href"))))
  }
  titulos = gsub("\\s+", " ", trimws(xml2::xml_text(links)))
  if (length(links) == 0) {
    stop("A página de schemas do ", documento, " não tem mais os links de download: ", PAGINA_DOS_SCHEMAS[[documento]], call. = FALSE)
  }
  publicacoes = data.frame(documento = documento, titulo = titulos, endereco = unname(enderecos))
  publicacoes[!duplicated(publicacoes$endereco), ]
}

# Baixa o pacote e o abre numa pasta. Devolve a pasta, ou NA quando o arquivo não é um zip.
baixar_pacote = function(documento, endereco, pasta_temporaria) {
  abrir_pagina(documento, pasta_temporaria)
  arquivo_de_cookies = file.path(pasta_temporaria, paste0("cookies_", documento, ".txt"))
  arquivo = tempfile(tmpdir = pasta_temporaria, fileext = ".zip")
  pedido = httr2::req_cookie_preserve(httr2::request(endereco), arquivo_de_cookies)
  pedido = httr2::req_timeout(pedido, 300)
  httr2::req_perform(pedido, path = arquivo)
  pasta = sub("\\.zip$", "", arquivo)
  abertos = tryCatch(utils::unzip(arquivo, exdir = pasta), error = function(erro) character(), warning = function(aviso) character())
  if (length(abertos) == 0) {
    return(NA_character_)
  }
  pasta
}

# A pasta, dentro do pacote aberto, que tem o arquivo principal (os pacotes guardam os schemas em
# subpastas com nomes que mudam). NA quando o pacote não tem esse arquivo.
pasta_do_arquivo = function(pasta_do_pacote, arquivo_principal) {
  if (is.na(pasta_do_pacote)) {
    return(NA_character_)
  }
  achados = list.files(pasta_do_pacote, pattern = paste0("^", gsub(".", "\\.", arquivo_principal, fixed = TRUE), "$"),
                       recursive = TRUE, full.names = TRUE)
  if (length(achados) == 0) {
    return(NA_character_)
  }
  dirname(achados[1])
}

# ---- campos de um schema ----

# Os tipos (complexType e simpleType) e os elementos com nome no topo de cada .xsd da pasta.
ler_definicoes = function(pasta_do_schema) {
  tipos = list()
  elementos = list()
  for (arquivo in list.files(pasta_do_schema, pattern = "\\.xsd$", full.names = TRUE)) {
    for (definicao in xml2::xml_children(xml2::xml_root(xml2::read_xml(arquivo)))) {
      nome = xml2::xml_attr(definicao, "name")
      if (is.na(nome)) {
        next
      }
      if (xml2::xml_name(definicao) %in% c("complexType", "simpleType")) {
        tipos[[nome]] = definicao
      } else if (xml2::xml_name(definicao) == "element") {
        elementos[[nome]] = definicao
      }
    }
  }
  list(tipos = tipos, elementos = elementos)
}

sem_prefixo = function(nome) {
  sub("^.*:", "", nome)
}

# As regras de uma restrição: padrões, valores aceitos e tamanhos, e as do tipo de onde ela vem (base). No
# schema do MDF-e, por exemplo, o procEmi é uma restrição sem regra própria do tipo TProcEmi, onde estão os
# valores aceitos.
descrever_restricao = function(restricao, definicoes, tipos_ja_vistos) {
  partes = character()
  padroes = xml2::xml_attr(xml2::xml_find_all(restricao, "xs:pattern", NAMESPACE_DO_XSD), "value")
  valores = xml2::xml_attr(xml2::xml_find_all(restricao, "xs:enumeration", NAMESPACE_DO_XSD), "value")
  tamanhos = xml2::xml_find_all(restricao, "xs:length|xs:minLength|xs:maxLength|xs:totalDigits|xs:fractionDigits", NAMESPACE_DO_XSD)
  if (length(padroes) > 0) {
    partes = c(partes, paste0("padrão ", paste(padroes, collapse = " ou ")))
  }
  if (length(valores) > 0) {
    partes = c(partes, paste0("valores ", paste(valores, collapse = ",")))
  }
  if (length(tamanhos) > 0) {
    partes = c(partes, paste0(xml2::xml_name(tamanhos), " ", xml2::xml_attr(tamanhos, "value")))
  }
  base = sem_prefixo(xml2::xml_attr(restricao, "base"))
  if (!is.na(base) && !(base %in% tipos_ja_vistos)) {
    da_base = descrever_tipo_simples(base, definicoes, c(tipos_ja_vistos, base))
    if (da_base != "") {
      partes = c(partes, paste0("de ", base, ": ", da_base))
    }
  }
  paste(partes, collapse = "; ")
}

# As regras de um tipo simples com nome (TCnpj, TProcEmi...); "" quando o nome não é um tipo do pacote
# (xs:string, por exemplo).
descrever_tipo_simples = function(nome_do_tipo, definicoes, tipos_ja_vistos) {
  tipo = definicoes$tipos[[nome_do_tipo]]
  if (is.null(tipo) || xml2::xml_name(tipo) != "simpleType") {
    return("")
  }
  restricao = xml2::xml_find_first(tipo, "xs:restriction", NAMESPACE_DO_XSD)
  if (!inherits(restricao, "xml_missing")) {
    return(descrever_restricao(restricao, definicoes, tipos_ja_vistos))
  }
  uniao = xml2::xml_find_first(tipo, "xs:union", NAMESPACE_DO_XSD)
  if (!inherits(uniao, "xml_missing")) {
    return(paste0("um de ", xml2::xml_attr(uniao, "memberTypes")))
  }
  ""
}

# As regras de um campo num texto só: quantas vezes aparece, o tipo, o padrão e os valores aceitos. É o que
# se compara entre um pacote e outro.
regras_do_campo = function(definicao_do_campo, definicoes) {
  minimo = xml2::xml_attr(definicao_do_campo, "minOccurs")
  maximo = xml2::xml_attr(definicao_do_campo, "maxOccurs")
  uso = xml2::xml_attr(definicao_do_campo, "use")
  tipo = sem_prefixo(xml2::xml_attr(definicao_do_campo, "type"))
  partes = character()
  if (!is.na(uso)) {
    partes = c(partes, paste0("uso ", uso))
  } else if (xml2::xml_name(definicao_do_campo) == "element") {
    partes = c(partes, paste0("[", ifelse(is.na(minimo), "1", minimo), "..", ifelse(is.na(maximo), "1", maximo), "]"))
  }
  if (!is.na(tipo)) {
    partes = c(partes, paste0("tipo ", tipo))
    do_tipo = descrever_tipo_simples(tipo, definicoes, tipo)
    if (do_tipo != "") {
      partes = c(partes, do_tipo)
    }
  }
  restricao_de_dentro = xml2::xml_find_first(definicao_do_campo, "xs:simpleType/xs:restriction", NAMESPACE_DO_XSD)
  if (!inherits(restricao_de_dentro, "xml_missing")) {
    de_dentro = descrever_restricao(restricao_de_dentro, definicoes, character())
    if (de_dentro != "") {
      partes = c(partes, de_dentro)
    }
  }
  paste(partes, collapse = "; ")
}

# Todos os campos dentro de um nó do schema, cada um com o caminho e as regras. `tipos_ja_abertos` evita
# entrar de novo num tipo que contém a si mesmo.
campos_dentro = function(no, caminho_de_cima, definicoes, tipos_ja_abertos) {
  caminhos = character()
  regras = character()
  for (filho in xml2::xml_children(no)) {
    tag = xml2::xml_name(filho)
    if (tag %in% c("sequence", "choice", "all", "complexType", "extension", "restriction")) {
      if (tag %in% c("extension", "restriction")) {
        base = sem_prefixo(xml2::xml_attr(filho, "base"))
        if (!is.na(base) && !is.null(definicoes$tipos[[base]]) && !(base %in% tipos_ja_abertos)) {
          de_dentro = campos_dentro(definicoes$tipos[[base]], caminho_de_cima, definicoes, c(tipos_ja_abertos, base))
          caminhos = c(caminhos, de_dentro$caminhos)
          regras = c(regras, de_dentro$regras)
        }
      }
      de_dentro = campos_dentro(filho, caminho_de_cima, definicoes, tipos_ja_abertos)
      caminhos = c(caminhos, de_dentro$caminhos)
      regras = c(regras, de_dentro$regras)
    } else if (tag %in% c("complexContent", "simpleContent")) {
      de_dentro = campos_dentro(filho, caminho_de_cima, definicoes, tipos_ja_abertos)
      caminhos = c(caminhos, de_dentro$caminhos)
      regras = c(regras, de_dentro$regras)
    } else if (tag == "attribute") {
      caminhos = c(caminhos, paste0(caminho_de_cima, "/@", xml2::xml_attr(filho, "name")))
      regras = c(regras, regras_do_campo(filho, definicoes))
    } else if (tag == "any") {
      caminhos = c(caminhos, paste0(caminho_de_cima, "/(qualquer elemento)"))
      regras = c(regras, "")
    } else if (tag == "element") {
      nome = xml2::xml_attr(filho, "name")
      referencia = sem_prefixo(xml2::xml_attr(filho, "ref"))
      if (is.na(nome)) {
        caminhos = c(caminhos, paste0(caminho_de_cima, "/", referencia))
        regras = c(regras, "")
        next
      }
      caminho = paste0(caminho_de_cima, "/", nome)
      caminhos = c(caminhos, caminho)
      regras = c(regras, regras_do_campo(filho, definicoes))
      tipo = sem_prefixo(xml2::xml_attr(filho, "type"))
      complexo_de_dentro = xml2::xml_find_first(filho, "xs:complexType", NAMESPACE_DO_XSD)
      if (!inherits(complexo_de_dentro, "xml_missing")) {
        de_dentro = campos_dentro(complexo_de_dentro, caminho, definicoes, tipos_ja_abertos)
      } else if (!is.na(tipo) && !is.null(definicoes$tipos[[tipo]]) && xml2::xml_name(definicoes$tipos[[tipo]]) == "complexType" && !(tipo %in% tipos_ja_abertos)) {
        de_dentro = campos_dentro(definicoes$tipos[[tipo]], caminho, definicoes, c(tipos_ja_abertos, tipo))
      } else {
        next
      }
      caminhos = c(caminhos, de_dentro$caminhos)
      regras = c(regras, de_dentro$regras)
    }
  }
  list(caminhos = caminhos, regras = regras)
}

# Os campos de cada tipo ou elemento pedido, com o caminho começando pelo nome dele (TNFe/infNFe/ide/mod) e
# as regras. Um nome que não está no schema volta como uma linha avisando.
campos_do_schema = function(pasta_do_schema, nomes) {
  definicoes = ler_definicoes(pasta_do_schema)
  caminhos = character()
  regras = character()
  for (nome in nomes) {
    if (!is.null(definicoes$tipos[[nome]])) {
      de_dentro = campos_dentro(definicoes$tipos[[nome]], nome, definicoes, nome)
    } else if (!is.null(definicoes$elementos[[nome]])) {
      elemento_sozinho = xml2::xml_new_root("xs:schema", "xmlns:xs" = NAMESPACE_DO_XSD[["xs"]])
      xml2::xml_add_child(elemento_sozinho, definicoes$elementos[[nome]])
      de_dentro = campos_dentro(elemento_sozinho, "", definicoes, character())
      de_dentro$caminhos = sub("^/", "", de_dentro$caminhos)
    } else {
      de_dentro = list(caminhos = nome, regras = "(não está neste pacote)")
    }
    caminhos = c(caminhos, de_dentro$caminhos)
    regras = c(regras, de_dentro$regras)
  }
  data.frame(caminho = caminhos, regras = regras)
}

# O que mudou de um pacote para o outro: campos que entraram, que saíram e que mudaram de regra.
comparar_campos = function(campos_de_antes, campos_de_agora) {
  entraram = campos_de_agora[!(campos_de_agora$caminho %in% campos_de_antes$caminho), ]
  sairam = campos_de_antes[!(campos_de_antes$caminho %in% campos_de_agora$caminho), ]
  nos_dois = intersect(campos_de_antes$caminho, campos_de_agora$caminho)
  regras_de_antes = campos_de_antes$regras[match(nos_dois, campos_de_antes$caminho)]
  regras_de_agora = campos_de_agora$regras[match(nos_dois, campos_de_agora$caminho)]
  mudaram = data.frame(caminho = nos_dois, antes = regras_de_antes, agora = regras_de_agora)
  mudaram = mudaram[mudaram$antes != mudaram$agora, ]
  list(entraram = entraram, sairam = sairam, mudaram = mudaram)
}
