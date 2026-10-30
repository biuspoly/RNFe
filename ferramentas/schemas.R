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

ler_csv = function(caminho_do_csv) {
  utils::read.csv(caminho_do_csv, colClasses = "character", encoding = "UTF-8")
}

gravar_csv = function(tabela_para_gravar, caminho_do_csv) {
  conexao_com_o_arquivo = file(caminho_do_csv, "wb")
  utils::write.csv(tabela_para_gravar, conexao_com_o_arquivo, row.names = FALSE, fileEncoding = "UTF-8", eol = "\n")
  close(conexao_com_o_arquivo)
}

# ---- portais ----

arquivo_de_cookies_do_portal = function(documento, pasta_temporaria) {
  file.path(pasta_temporaria, paste0("cookies_", documento, ".txt"))
}

# Abre a página da lista guardando o cookie de sessão: o Portal da NF-e e o do CT-e só entregam o arquivo
# para quem abriu a página antes.
abrir_pagina = function(documento, pasta_temporaria) {
  pedido_da_pagina = httr2::request(PAGINA_DOS_SCHEMAS[[documento]])
  pedido_da_pagina = httr2::req_cookie_preserve(pedido_da_pagina, arquivo_de_cookies_do_portal(documento, pasta_temporaria))
  pedido_da_pagina = httr2::req_timeout(pedido_da_pagina, 120)
  resposta_da_pagina = httr2::req_perform(pedido_da_pagina)
  xml2::read_html(httr2::resp_body_string(resposta_da_pagina))
}

# Uma linha por publicação da página: documento, título (o texto do link) e endereço para baixar.
listar_publicacoes = function(documento, pasta_temporaria) {
  pagina_da_lista = abrir_pagina(documento, pasta_temporaria)
  if (documento == "mdfe") {
    # No portal do MDF-e o link é montado por JavaScript: download_arquivo_estatico('MDFE', 2, 'arquivo.zip'),
    # em que o 2 é o tipo "schemas".
    links_de_download = xml2::xml_find_all(pagina_da_lista, "//a[contains(@onclick, 'download_arquivo_estatico')]")
    chamadas_do_javascript = xml2::xml_attr(links_de_download, "onclick")
    links_que_sao_schemas = grepl("download_arquivo_estatico\\('MDFE', *2, *'", chamadas_do_javascript)
    links_de_download = links_de_download[links_que_sao_schemas]
    nomes_dos_arquivos = sub("^.*download_arquivo_estatico\\('MDFE', *2, *'([^']+)'.*$", "\\1", chamadas_do_javascript[links_que_sao_schemas])
    enderecos_para_baixar = paste0(DOWNLOAD_DO_PORTAL_DO_MDFE, vapply(nomes_dos_arquivos, utils::URLencode, character(1), reserved = TRUE))
  } else {
    links_de_download = xml2::xml_find_all(pagina_da_lista, "//a[contains(@href, 'exibirArquivo.aspx')]")
    comeco_do_endereco = sub("listaConteudo\\.aspx.*$", "", PAGINA_DOS_SCHEMAS[[documento]])
    # O endereço vem com espaços e quebras de linha em volta. O código do arquivo é Base64, e o portal às
    # vezes publica o "+" dele como espaço: os dois vão como %2B (o portal aceita, conferido em 30/10/2026).
    codigos_dos_arquivos = gsub("[+ ]", "%2B", trimws(xml2::xml_attr(links_de_download, "href")))
    enderecos_para_baixar = paste0(comeco_do_endereco, codigos_dos_arquivos)
  }
  if (length(links_de_download) == 0) {
    stop("A página de schemas do ", documento, " não tem mais os links de download: ", PAGINA_DOS_SCHEMAS[[documento]], call. = FALSE)
  }
  titulos_das_publicacoes = gsub("\\s+", " ", trimws(xml2::xml_text(links_de_download)))
  publicacoes = data.frame(documento = documento, titulo = titulos_das_publicacoes, endereco = unname(enderecos_para_baixar))
  publicacoes[!duplicated(publicacoes$endereco), ]
}

# Baixa o pacote e o abre numa pasta. Devolve a pasta, ou NA quando o arquivo não é um zip.
baixar_pacote = function(documento, endereco, pasta_temporaria) {
  abrir_pagina(documento, pasta_temporaria)
  arquivo_zip = tempfile(tmpdir = pasta_temporaria, fileext = ".zip")
  pedido_do_arquivo = httr2::request(endereco)
  pedido_do_arquivo = httr2::req_cookie_preserve(pedido_do_arquivo, arquivo_de_cookies_do_portal(documento, pasta_temporaria))
  pedido_do_arquivo = httr2::req_timeout(pedido_do_arquivo, 300)
  httr2::req_perform(pedido_do_arquivo, path = arquivo_zip)
  pasta_do_pacote = sub("\\.zip$", "", arquivo_zip)
  arquivos_abertos = tryCatch(utils::unzip(arquivo_zip, exdir = pasta_do_pacote),
                              error = function(erro) character(), warning = function(aviso) character())
  if (length(arquivos_abertos) == 0) {
    return(NA_character_)
  }
  pasta_do_pacote
}

# A pasta, dentro do pacote aberto, que tem o arquivo principal (os pacotes guardam os schemas em
# subpastas com nomes que mudam). NA quando o pacote não tem esse arquivo.
pasta_do_arquivo = function(pasta_do_pacote, arquivo_principal) {
  if (is.na(pasta_do_pacote)) {
    return(NA_character_)
  }
  nome_exato = paste0("^", gsub(".", "\\.", arquivo_principal, fixed = TRUE), "$")
  arquivos_achados = list.files(pasta_do_pacote, pattern = nome_exato, recursive = TRUE, full.names = TRUE)
  if (length(arquivos_achados) == 0) {
    return(NA_character_)
  }
  dirname(arquivos_achados[1])
}

# ---- campos de um schema ----

# Os tipos (complexType e simpleType) e os elementos com nome no topo de cada .xsd da pasta.
ler_definicoes = function(pasta_do_schema) {
  tipos = list()
  elementos = list()
  for (arquivo_xsd in list.files(pasta_do_schema, pattern = "\\.xsd$", full.names = TRUE)) {
    for (definicao in xml2::xml_children(xml2::xml_root(xml2::read_xml(arquivo_xsd)))) {
      nome_da_definicao = xml2::xml_attr(definicao, "name")
      if (is.na(nome_da_definicao)) {
        next
      }
      if (xml2::xml_name(definicao) %in% c("complexType", "simpleType")) {
        tipos[[nome_da_definicao]] = definicao
      } else if (xml2::xml_name(definicao) == "element") {
        elementos[[nome_da_definicao]] = definicao
      }
    }
  }
  list(tipos = tipos, elementos = elementos)
}

# "xs:string" vira "string": o prefixo do namespace não importa para achar o tipo.
sem_prefixo = function(nome_com_prefixo) {
  sub("^.*:", "", nome_com_prefixo)
}

# As regras de uma restrição: padrões, valores aceitos e tamanhos, e as do tipo de onde ela vem. No schema
# do MDF-e, por exemplo, o procEmi é uma restrição sem regra própria do tipo TProcEmi, onde estão os valores
# aceitos.
descrever_restricao = function(restricao, definicoes, tipos_ja_vistos) {
  regras_achadas = character()
  padroes = xml2::xml_attr(xml2::xml_find_all(restricao, "xs:pattern", NAMESPACE_DO_XSD), "value")
  valores_aceitos = xml2::xml_attr(xml2::xml_find_all(restricao, "xs:enumeration", NAMESPACE_DO_XSD), "value")
  limites_de_tamanho = xml2::xml_find_all(restricao, "xs:length|xs:minLength|xs:maxLength|xs:totalDigits|xs:fractionDigits", NAMESPACE_DO_XSD)
  if (length(padroes) > 0) {
    regras_achadas = c(regras_achadas, paste0("padrão ", paste(padroes, collapse = " ou ")))
  }
  if (length(valores_aceitos) > 0) {
    regras_achadas = c(regras_achadas, paste0("valores ", paste(valores_aceitos, collapse = ",")))
  }
  if (length(limites_de_tamanho) > 0) {
    regras_achadas = c(regras_achadas, paste0(xml2::xml_name(limites_de_tamanho), " ", xml2::xml_attr(limites_de_tamanho, "value")))
  }
  tipo_de_origem = sem_prefixo(xml2::xml_attr(restricao, "base"))
  if (!is.na(tipo_de_origem) && !(tipo_de_origem %in% tipos_ja_vistos)) {
    regras_do_tipo_de_origem = descrever_tipo_simples(tipo_de_origem, definicoes, c(tipos_ja_vistos, tipo_de_origem))
    if (regras_do_tipo_de_origem != "") {
      regras_achadas = c(regras_achadas, paste0("de ", tipo_de_origem, ": ", regras_do_tipo_de_origem))
    }
  }
  paste(regras_achadas, collapse = "; ")
}

# As regras de um tipo simples com nome (TCnpj, TProcEmi...); "" quando o nome não é um tipo do pacote
# (xs:string, por exemplo).
descrever_tipo_simples = function(nome_do_tipo, definicoes, tipos_ja_vistos) {
  definicao_do_tipo = definicoes$tipos[[nome_do_tipo]]
  if (is.null(definicao_do_tipo) || xml2::xml_name(definicao_do_tipo) != "simpleType") {
    return("")
  }
  restricao = xml2::xml_find_first(definicao_do_tipo, "xs:restriction", NAMESPACE_DO_XSD)
  if (!inherits(restricao, "xml_missing")) {
    return(descrever_restricao(restricao, definicoes, tipos_ja_vistos))
  }
  uniao_de_tipos = xml2::xml_find_first(definicao_do_tipo, "xs:union", NAMESPACE_DO_XSD)
  if (!inherits(uniao_de_tipos, "xml_missing")) {
    return(paste0("um de ", xml2::xml_attr(uniao_de_tipos, "memberTypes")))
  }
  ""
}

# As regras de um campo num texto só: quantas vezes aparece, o tipo, o padrão e os valores aceitos. É o que
# se compara entre um pacote e outro.
regras_do_campo = function(definicao_do_campo, definicoes) {
  minimo_de_vezes = xml2::xml_attr(definicao_do_campo, "minOccurs")
  maximo_de_vezes = xml2::xml_attr(definicao_do_campo, "maxOccurs")
  uso_do_atributo = xml2::xml_attr(definicao_do_campo, "use")
  nome_do_tipo = sem_prefixo(xml2::xml_attr(definicao_do_campo, "type"))
  regras_achadas = character()
  if (!is.na(uso_do_atributo)) {
    regras_achadas = c(regras_achadas, paste0("uso ", uso_do_atributo))
  } else if (xml2::xml_name(definicao_do_campo) == "element") {
    regras_achadas = c(regras_achadas, paste0("[", ifelse(is.na(minimo_de_vezes), "1", minimo_de_vezes), "..",
                                              ifelse(is.na(maximo_de_vezes), "1", maximo_de_vezes), "]"))
  }
  if (!is.na(nome_do_tipo)) {
    regras_achadas = c(regras_achadas, paste0("tipo ", nome_do_tipo))
    regras_do_tipo = descrever_tipo_simples(nome_do_tipo, definicoes, nome_do_tipo)
    if (regras_do_tipo != "") {
      regras_achadas = c(regras_achadas, regras_do_tipo)
    }
  }
  restricao_de_dentro = xml2::xml_find_first(definicao_do_campo, "xs:simpleType/xs:restriction", NAMESPACE_DO_XSD)
  if (!inherits(restricao_de_dentro, "xml_missing")) {
    regras_da_restricao = descrever_restricao(restricao_de_dentro, definicoes, character())
    if (regras_da_restricao != "") {
      regras_achadas = c(regras_achadas, regras_da_restricao)
    }
  }
  paste(regras_achadas, collapse = "; ")
}

# Onde o campo está, quando isso muda o que é obrigatório: num grupo que pode faltar ou se repetir
# ("num grupo [0..1]") ou numa escolha entre campos ("numa escolha"). Uma sequência simples não conta.
descrever_grupo = function(grupo_do_schema) {
  minimo_de_vezes = xml2::xml_attr(grupo_do_schema, "minOccurs")
  maximo_de_vezes = xml2::xml_attr(grupo_do_schema, "maxOccurs")
  descricoes_do_grupo = character()
  if (xml2::xml_name(grupo_do_schema) == "choice") {
    descricoes_do_grupo = c(descricoes_do_grupo, "numa escolha")
  }
  if (!is.na(minimo_de_vezes) || !is.na(maximo_de_vezes)) {
    descricoes_do_grupo = c(descricoes_do_grupo, paste0("num grupo [", ifelse(is.na(minimo_de_vezes), "1", minimo_de_vezes), "..",
                                                        ifelse(is.na(maximo_de_vezes), "1", maximo_de_vezes), "]"))
  }
  descricoes_do_grupo
}

# As regras do campo e, no fim, os grupos em que ele está (descrever_grupo).
regras_com_os_grupos = function(regras_do_campo_sozinho, grupos_de_cima) {
  if (length(grupos_de_cima) == 0) {
    return(regras_do_campo_sozinho)
  }
  paste(c(regras_do_campo_sozinho[regras_do_campo_sozinho != ""], grupos_de_cima), collapse = "; ")
}

# Todos os campos dentro de uma parte do schema, cada um com o caminho e as regras. `tipos_ja_abertos` evita
# entrar de novo num tipo que contém a si mesmo. `grupos_de_cima` são os grupos opcionais ou de escolha em
# que os campos estão, dentro do mesmo elemento.
campos_dentro = function(parte_do_schema, caminho_de_cima, definicoes, tipos_ja_abertos, grupos_de_cima = character()) {
  caminhos = character()
  regras = character()
  for (item_do_schema in xml2::xml_children(parte_do_schema)) {
    tipo_do_item = xml2::xml_name(item_do_schema)
    if (tipo_do_item %in% c("sequence", "choice", "all", "complexType", "extension", "restriction")) {
      # Uma extensão ou restrição de outro tipo começa com os campos dele.
      if (tipo_do_item %in% c("extension", "restriction")) {
        tipo_de_origem = sem_prefixo(xml2::xml_attr(item_do_schema, "base"))
        if (!is.na(tipo_de_origem) && !is.null(definicoes$tipos[[tipo_de_origem]]) && !(tipo_de_origem %in% tipos_ja_abertos)) {
          campos_do_tipo_de_origem = campos_dentro(definicoes$tipos[[tipo_de_origem]], caminho_de_cima, definicoes,
                                                   c(tipos_ja_abertos, tipo_de_origem), grupos_de_cima)
          caminhos = c(caminhos, campos_do_tipo_de_origem$caminhos)
          regras = c(regras, campos_do_tipo_de_origem$regras)
        }
      }
      grupos_ate_aqui = grupos_de_cima
      if (tipo_do_item %in% c("sequence", "choice", "all")) {
        grupos_ate_aqui = c(grupos_de_cima, descrever_grupo(item_do_schema))
      }
      campos_do_grupo = campos_dentro(item_do_schema, caminho_de_cima, definicoes, tipos_ja_abertos, grupos_ate_aqui)
      caminhos = c(caminhos, campos_do_grupo$caminhos)
      regras = c(regras, campos_do_grupo$regras)
    } else if (tipo_do_item %in% c("complexContent", "simpleContent")) {
      campos_do_conteudo = campos_dentro(item_do_schema, caminho_de_cima, definicoes, tipos_ja_abertos, grupos_de_cima)
      caminhos = c(caminhos, campos_do_conteudo$caminhos)
      regras = c(regras, campos_do_conteudo$regras)
    } else if (tipo_do_item == "attribute") {
      caminhos = c(caminhos, paste0(caminho_de_cima, "/@", xml2::xml_attr(item_do_schema, "name")))
      regras = c(regras, regras_com_os_grupos(regras_do_campo(item_do_schema, definicoes), grupos_de_cima))
    } else if (tipo_do_item == "any") {
      caminhos = c(caminhos, paste0(caminho_de_cima, "/(qualquer elemento)"))
      regras = c(regras, regras_com_os_grupos("", grupos_de_cima))
    } else if (tipo_do_item == "element") {
      nome_do_campo = xml2::xml_attr(item_do_schema, "name")
      # Um elemento que só aponta para outro (ref, como a Signature) entra pelo nome, sem abrir.
      if (is.na(nome_do_campo)) {
        caminhos = c(caminhos, paste0(caminho_de_cima, "/", sem_prefixo(xml2::xml_attr(item_do_schema, "ref"))))
        regras = c(regras, regras_com_os_grupos("", grupos_de_cima))
        next
      }
      caminho_do_campo = paste0(caminho_de_cima, "/", nome_do_campo)
      caminhos = c(caminhos, caminho_do_campo)
      regras = c(regras, regras_com_os_grupos(regras_do_campo(item_do_schema, definicoes), grupos_de_cima))
      nome_do_tipo = sem_prefixo(xml2::xml_attr(item_do_schema, "type"))
      tipo_escrito_dentro = xml2::xml_find_first(item_do_schema, "xs:complexType", NAMESPACE_DO_XSD)
      if (!inherits(tipo_escrito_dentro, "xml_missing")) {
        campos_do_elemento = campos_dentro(tipo_escrito_dentro, caminho_do_campo, definicoes, tipos_ja_abertos)
      } else if (!is.na(nome_do_tipo) && !is.null(definicoes$tipos[[nome_do_tipo]])
                 && xml2::xml_name(definicoes$tipos[[nome_do_tipo]]) == "complexType" && !(nome_do_tipo %in% tipos_ja_abertos)) {
        campos_do_elemento = campos_dentro(definicoes$tipos[[nome_do_tipo]], caminho_do_campo, definicoes, c(tipos_ja_abertos, nome_do_tipo))
      } else {
        next
      }
      caminhos = c(caminhos, campos_do_elemento$caminhos)
      regras = c(regras, campos_do_elemento$regras)
    }
  }
  list(caminhos = caminhos, regras = regras)
}

# Os campos de cada tipo ou elemento pedido, com o caminho começando pelo nome dele (TNFe/infNFe/ide/mod) e
# as regras. Um nome que não está no schema volta como uma linha avisando.
campos_do_schema = function(pasta_do_schema, nomes_para_comparar) {
  definicoes = ler_definicoes(pasta_do_schema)
  caminhos = character()
  regras = character()
  for (nome_para_comparar in nomes_para_comparar) {
    if (!is.null(definicoes$tipos[[nome_para_comparar]])) {
      campos_achados = campos_dentro(definicoes$tipos[[nome_para_comparar]], nome_para_comparar, definicoes, nome_para_comparar)
    } else if (!is.null(definicoes$elementos[[nome_para_comparar]])) {
      # Um elemento solto (o rodo) é posto sozinho num schema, para ser lido como os outros.
      schema_so_com_o_elemento = xml2::xml_new_root("xs:schema", "xmlns:xs" = NAMESPACE_DO_XSD[["xs"]])
      xml2::xml_add_child(schema_so_com_o_elemento, definicoes$elementos[[nome_para_comparar]])
      campos_achados = campos_dentro(schema_so_com_o_elemento, "", definicoes, character())
      campos_achados$caminhos = sub("^/", "", campos_achados$caminhos)
    } else {
      campos_achados = list(caminhos = nome_para_comparar, regras = "(não está neste pacote)")
    }
    caminhos = c(caminhos, campos_achados$caminhos)
    regras = c(regras, campos_achados$regras)
  }
  data.frame(caminho = caminhos, regras = regras)
}

# O que mudou de um pacote para o outro: campos que entraram, que saíram e que mudaram de regra.
comparar_campos = function(campos_de_antes, campos_de_agora) {
  entraram = campos_de_agora[!(campos_de_agora$caminho %in% campos_de_antes$caminho), ]
  sairam = campos_de_antes[!(campos_de_antes$caminho %in% campos_de_agora$caminho), ]
  caminhos_nos_dois = intersect(campos_de_antes$caminho, campos_de_agora$caminho)
  regras_de_antes = campos_de_antes$regras[match(caminhos_nos_dois, campos_de_antes$caminho)]
  regras_de_agora = campos_de_agora$regras[match(caminhos_nos_dois, campos_de_agora$caminho)]
  mudaram = data.frame(caminho = caminhos_nos_dois, antes = regras_de_antes, agora = regras_de_agora)
  mudaram = mudaram[mudaram$antes != mudaram$agora, ]
  list(entraram = entraram, sairam = sairam, mudaram = mudaram)
}
