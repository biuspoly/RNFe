# A montagem dos documentos fiscais pelo schema oficial. O documento chega como uma lista do R com os nomes do leiaute
# (os mesmos do XML); o schema que vem no pacote (inst/schemas) diz a ordem dos campos, o que é atributo, o que se
# repete, como escrever cada valor, o que tem um valor só e se o resultado vale. Quando a SEFAZ muda o leiaute, trocar
# os arquivos do schema basta: este código não tem a lista dos campos de nenhum documento.
#
# Cada tipo do schema é lido do XSD uma vez por sessão e guardado numa lista do R (o modelo "compilado"): percorrer o
# XSD a cada nota custava mais de 100 ms por NF-e, porque o xml2 relê os namespaces do arquivo inteiro a cada busca.
# O formato de cada valor é testado contra o próprio padrão do tipo (xs:pattern, a lista de valores, o tamanho): o
# número ganha as casas decimais e os zeros à esquerda que o padrão aceita, sem regra escrita à mão para cada tipo.

#' @include tabelas.R assinatura.R chave.R sefaz.R
NULL

# As construções do XSD que guardam o modelo de conteúdo de um tipo.
PARTICULAS_DO_MODELO = c("sequence", "choice", "all", "group")
# O padrão que é um valor só, como "4\.00" (a versão do leiaute).
PADRAO_DE_UM_VALOR_SO = "^([A-Za-z0-9]|\\\\\\.)+$"
CARACTERES_DE_ESPACO = c(" ", "\t", "\n", "\r")
# Os caracteres que o XML 1.0 não aceita (os de controle, fora a tabulação e as quebras de linha).
CARACTERES_DE_CONTROLE = "[\001-\010\013\014\016-\037]"
# Os tipos básicos do XSD que são números: neles o zero à esquerda não muda o valor.
BASES_NUMERICAS = c("decimal", "integer", "int", "long", "short", "byte", "nonNegativeInteger", "positiveInteger",
                    "nonPositiveInteger", "negativeInteger", "unsignedLong", "unsignedInt", "unsignedShort",
                    "unsignedByte", "double", "float")
# O maior inteiro que o R guarda sem perder algarismos (2^53).
MAIOR_NUMERO_EXATO = 9007199254740992
# Os algarismos que o round() do R confere: com mais (a parte inteira mais as casas pedidas), ele devolve o próprio
# número, e não dá para saber se o valor é exato com aquelas casas.
ALGARISMOS_QUE_O_ROUND_CONFERE = 15
CASAS_DECIMAIS_TENTADAS = 1:15
REGRAS_DE_TIPO_BASICO = list(padroes_por_nivel = list(), padroes_originais = character(), valores_aceitos = character(),
                             comprimento_minimo = NA_integer_, comprimento_maximo = NA_integer_, base = "string",
                             decimal = FALSE, numerica = FALSE, unico = NA_character_, casas_aceitas = integer(),
                             aceita_zero_a_esquerda = TRUE)

# Cada documento que o RNFe monta: a raiz, o elemento com o conteúdo (o assinado), o namespace, a pasta do schema em
# inst/schemas e os arquivos principais (o do documento e os dos modais, que entram num xs:any). A DPS segue o schema
# da Produção Restrita, que é a homologação da NFS-e Nacional.
DOCUMENTOS_PARA_MONTAR = list(
  "NF-e" = list(raiz = "NFe", conteudo = "infNFe", namespace = "http://www.portalfiscal.inf.br/nfe", pasta = "nfe",
                arquivos = "nfe_v4.00.xsd"),
  "CT-e" = list(raiz = "CTe", conteudo = "infCte", namespace = "http://www.portalfiscal.inf.br/cte", pasta = "cte",
                arquivos = c("cte_v4.00.xsd", "cteModalRodoviario_v4.00.xsd", "cteModalAereo_v4.00.xsd",
                             "cteModalAquaviario_v4.00.xsd", "cteModalFerroviario_v4.00.xsd",
                             "cteModalDutoviario_v4.00.xsd", "cteMultiModal_v4.00.xsd")),
  "CT-e simplificado" = list(raiz = "CTeSimp", conteudo = "infCte", namespace = "http://www.portalfiscal.inf.br/cte",
                             pasta = "cte",
                             arquivos = c("cteSimp_v4.00.xsd", "cteModalRodoviario_v4.00.xsd", "cteModalAereo_v4.00.xsd",
                                          "cteModalAquaviario_v4.00.xsd", "cteModalFerroviario_v4.00.xsd",
                                          "cteModalDutoviario_v4.00.xsd", "cteMultiModal_v4.00.xsd")),
  "CT-e OS" = list(raiz = "CTeOS", conteudo = "infCte", namespace = "http://www.portalfiscal.inf.br/cte", pasta = "cte",
                   arquivos = c("cteOS_v4.00.xsd", "cteModalRodoviarioOS_v4.00.xsd")),
  "GTV-e" = list(raiz = "GTVe", conteudo = "infCte", namespace = "http://www.portalfiscal.inf.br/cte", pasta = "cte",
                 arquivos = "GTVe_v4.00.xsd"),
  "MDF-e" = list(raiz = "MDFe", conteudo = "infMDFe", namespace = "http://www.portalfiscal.inf.br/mdfe", pasta = "mdfe",
                 arquivos = c("mdfe_v3.00.xsd", "mdfeModalRodoviario_v3.00.xsd", "mdfeModalAereo_v3.00.xsd",
                              "mdfeModalAquaviario_v3.00.xsd", "mdfeModalFerroviario_v3.00.xsd")),
  "DPS" = list(raiz = "DPS", conteudo = "infDPS", namespace = "http://www.sped.fazenda.gov.br/nfse",
               pasta = "nfse_producao_restrita", arquivos = "DPS_v1.01.xsd")
)
# Os elementos assinados de cada documento e as raízes em que cada um fica (o infEvento do retorno do evento não
# conta: ele é a resposta, não o documento).
RAIZES_DE_CADA_CONTEUDO = list(infNFe = "NFe", infCte = c("CTe", "CTeOS", "GTVe", "CTeSimp"), infMDFe = "MDFe",
                               infDPS = "DPS", infEvento = c("evento", "eventoCTe", "eventoMDFe"),
                               infPedReg = "pedRegEvento")

#' Passar um documento fiscal para uma lista
#'
#' Lê o XML de uma NF-e, NFC-e, CT-e, MDF-e, DPS ou evento e devolve o
#' conteúdo do elemento assinado (`infNFe`, `infCte`, `infMDFe`, `infDPS`,
#' `infEvento`) numa lista do R, com os nomes do leiaute: a mesma forma que
#' [nfe_montar()], [cte_montar()], [mdfe_montar()] e [nfse_dps_montar()]
#' recebem. Serve para montar um documento novo a partir de um que já existe
#' (trocar o que muda e montar de novo) e para ver como o leiaute organiza
#' cada grupo.
#'
#' Cada grupo vira uma lista com nome. O grupo que o leiaute deixa repetir
#' (os itens, `det`; as duplicatas, `dup`; as formas de pagamento, `detPag`)
#' vira sempre uma lista de listas, uma por vez que ele aparece, mesmo quando
#' aparece uma vez só: `nota$det[[1]]` vale em toda nota. O campo que se
#' repete vira um vetor. Os atributos (`versao`, `Id`, `nItem`) entram com os
#' campos, pelo nome. Todo valor vem como texto, como está no XML; o grupo
#' vazio (`<compra/>`), como texto vazio. A assinatura fica de fora. No
#' evento, o grupo que algum schema oficial de evento deixa repetir (como a
#' `infCorrecao` da carta de correção do CT-e) também vira sempre uma lista de
#' listas.
#'
#' @param xml O XML: o caminho do arquivo ou o próprio texto (começando por
#'   `<`). No XML autorizado (`nfeProc`, `cteProc`...), o documento de dentro.
#'   Um lote com mais de um documento é recusado: passe um por vez.
#' @return Uma lista com os campos e os grupos do elemento assinado (ou da
#'   raiz, quando o XML não tem um deles).
#' @seealso [nfe_montar()]
#' @examples
#' nota = xml_para_lista(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"))
#' names(nota)
#' nota$ide$nNF
#' nota$det[[1]]$prod$xProd
#' @export
xml_para_lista = function(xml) {
  documento = ler_o_xml_para_assinar(xml)
  elemento = elemento_com_o_conteudo(documento)
  tipo = NULL
  schema = NULL
  definicao = documento_do_elemento(elemento)
  if (!is.null(definicao)) {
    schema = schema_para_montar(definicao$pasta, definicao$arquivos)
    raiz = elemento_do_topo(definicao$raiz, schema)
    elemento_do_conteudo = elementos_do_tipo(tipo_do_elemento(raiz, schema), schema)$elementos[[definicao$conteudo]]
    tipo = tipo_do_elemento(elemento_do_conteudo, schema)
  }
  repetidos_sem_schema = character()
  if (is.null(tipo) && xml2::xml_name(elemento) %in% c("infEvento", "infPedReg")) {
    repetidos_sem_schema = nomes_que_repetem_nos_eventos()
  }
  lista_do_elemento(elemento, tipo, schema, repetidos_sem_schema)
}

# Os nomes dos elementos que algum schema de evento do pacote deixa repetir (o maxOccurs dele, ou o da sequence ou da
# choice em volta, até o elemento de cima), lidos uma vez por sessão: no evento, que o xml_para_lista() lê sem o schema,
# eles viram sempre lista de listas.
nomes_que_repetem_nos_eventos = function() {
  if (!is.null(tabelas_ja_lidas[["repetidos_dos_eventos"]])) {
    return(tabelas_ja_lidas[["repetidos_dos_eventos"]])
  }
  arquivos = c(list.files(system.file("schemas", "nfe_eventos", package = "RNFe"), pattern = "^[^x].*\\.xsd$", full.names = TRUE),
               list.files(system.file("schemas", "cte", package = "RNFe"), pattern = "^ev.*\\.xsd$", full.names = TRUE),
               list.files(system.file("schemas", "mdfe", package = "RNFe"), pattern = "^ev.*\\.xsd$", full.names = TRUE),
               list.files(system.file("schemas", "nfse", package = "RNFe"), pattern = "(Evento|evento).*\\.xsd$",
                          full.names = TRUE))
  nomes = character()
  for (arquivo in arquivos) {
    for (definicao in xml2::xml_find_all(xml2::read_xml(arquivo), "//*[local-name()='element' and @name]")) {
      if (elemento_repete_no_schema(definicao)) {
        nomes = c(nomes, xml2::xml_attr(definicao, "name"))
      }
    }
  }
  nomes = unique(nomes)
  tabelas_ja_lidas[["repetidos_dos_eventos"]] = nomes
  nomes
}

# O elemento do XSD repete quando ele, ou a sequence ou a choice em volta dele (até o elemento de cima), tem o maxOccurs
# diferente de 1.
elemento_repete_no_schema = function(definicao) {
  no = definicao
  repeat {
    maximo = xml2::xml_attr(no, "maxOccurs")
    if (!is.na(maximo) && maximo != "1") {
      return(TRUE)
    }
    no = xml2::xml_parent(no)
    if (inherits(no, "xml_missing") || !(xml2::xml_name(no) %in% c("sequence", "choice", "all", "complexType", "group"))) {
      return(FALSE)
    }
  }
}

# O elemento assinado do documento (o infNFe de dentro do NFe, por exemplo); a raiz, quando não há nenhum. Um dentro do
# outro é um documento só, e vale o de fora: o evento da NFS-e (evento/infEvento) traz dentro o pedido assinado pelo
# autor (pedRegEvento/infPedReg).
elemento_com_o_conteudo = function(documento) {
  condicoes = character()
  for (nome_do_conteudo in names(RAIZES_DE_CADA_CONTEUDO)) {
    raizes = RAIZES_DE_CADA_CONTEUDO[[nome_do_conteudo]]
    condicoes = c(condicoes, paste0("(local-name()='", nome_do_conteudo, "' and (",
                                    paste0("local-name(..)='", raizes, "'", collapse = " or "), "))"))
  }
  condicao = paste(condicoes, collapse = " or ")
  achados = xml2::xml_find_all(documento, paste0("//*[(", condicao, ") and not(ancestor::*[", condicao, "])]"))
  if (length(achados) > 1) {
    stop("O XML traz ", length(achados), " documentos (um lote?): passe um por vez.", call. = FALSE)
  }
  if (length(achados) == 0) {
    return(xml2::xml_root(documento))
  }
  achados[[1]]
}

# O documento do DOCUMENTOS_PARA_MONTAR a que o elemento assinado pertence, pela raiz e pelo namespace (NULL quando
# não é nenhum deles, como um evento).
documento_do_elemento = function(elemento) {
  pai = xml2::xml_parent(elemento)
  if (inherits(pai, "xml_missing") || !inherits(pai, "xml_node")) {
    return(NULL)
  }
  nome_do_pai = xml2::xml_name(pai)
  namespace = xml2::xml_find_chr(elemento, "string(namespace-uri(.))")
  for (definicao in DOCUMENTOS_PARA_MONTAR) {
    if (identical(definicao$raiz, nome_do_pai) && identical(definicao$namespace, namespace) &&
        identical(definicao$conteudo, xml2::xml_name(elemento))) {
      return(definicao)
    }
  }
  NULL
}

# Os atributos e os filhos de um elemento numa lista: o grupo vira lista, o campo vira texto. O que o schema deixa
# repetir vira sempre lista de listas (o grupo) ou vetor (o campo); sem o schema (um evento), o que os schemas dos
# eventos deixam repetir também, e o que aparece mais de uma vez junta.
lista_do_elemento = function(elemento, tipo, schema, repetidos_sem_schema = character()) {
  conteudo = list()
  atributos = atributos_do_documento(elemento)
  for (nome_do_atributo in names(atributos)) {
    conteudo[[nome_do_atributo]] = unname(atributos[[nome_do_atributo]])
  }
  mapa = NULL
  if (!is.null(tipo)) {
    mapa = elementos_do_tipo(tipo, schema)
  }
  nomes_repetidos = character()
  for (filho in xml2::xml_children(elemento)) {
    nome_do_filho = xml2::xml_name(filho)
    if (nome_do_filho == "Signature") {
      next
    }
    definicao_do_filho = NULL
    if (!is.null(mapa)) {
      definicao_do_filho = mapa$elementos[[nome_do_filho]]
      if (is.null(definicao_do_filho) && mapa$tem_any) {
        definicao_do_filho = elemento_do_topo(nome_do_filho, schema)
      }
    }
    tipo_do_filho = NULL
    if (!is.null(definicao_do_filho)) {
      tipo_do_filho = tipo_do_elemento(definicao_do_filho, schema)
    }
    tem_filhos = length(xml2::xml_children(filho)) > 0
    tem_atributos = length(atributos_do_documento(filho)) > 0
    if (!tem_filhos && tem_atributos && nzchar(trimws(xml2::xml_text(filho)))) {
      stop("O elemento ", nome_do_filho, " tem atributo e texto ao mesmo tempo: a lista n\u00e3o guarda os dois.", call. = FALSE)
    }
    if (tem_filhos || tem_atributos) {
      valor_do_filho = lista_do_elemento(filho, tipo_do_filho, schema, repetidos_sem_schema)
    } else {
      valor_do_filho = xml2::xml_text(filho)
    }
    repetido = (!is.null(definicao_do_filho) && isTRUE(definicao_do_filho$repetido)) ||
      (is.null(mapa) && nome_do_filho %in% repetidos_sem_schema)
    e_grupo = is.list(valor_do_filho) || !is.null(tipo_do_filho)
    if (repetido && e_grupo) {
      conteudo[[nome_do_filho]] = c(conteudo[[nome_do_filho]], list(valor_do_filho))
    } else if (repetido) {
      conteudo[[nome_do_filho]] = c(conteudo[[nome_do_filho]], valor_do_filho)
    } else if (is.null(conteudo[[nome_do_filho]])) {
      conteudo[[nome_do_filho]] = valor_do_filho
    } else if (is.list(valor_do_filho)) {
      # Sem o schema: o grupo que aparece de novo vira uma lista sem nome, com uma lista por vez.
      if (!(nome_do_filho %in% nomes_repetidos)) {
        conteudo[[nome_do_filho]] = list(conteudo[[nome_do_filho]])
        nomes_repetidos = c(nomes_repetidos, nome_do_filho)
      }
      conteudo[[nome_do_filho]] = c(conteudo[[nome_do_filho]], list(valor_do_filho))
    } else {
      conteudo[[nome_do_filho]] = c(conteudo[[nome_do_filho]], valor_do_filho)
    }
  }
  conteudo
}

# Os atributos de um elemento, sem as declarações de namespace (o xmlns repetido num modal, como <rodo xmlns="...">,
# que o xml2 devolve como atributo e não é um campo do documento).
atributos_do_documento = function(elemento) {
  atributos = xml2::xml_attrs(elemento)
  nomes = names(atributos)
  if (length(nomes) == 0) {
    return(atributos)
  }
  atributos[!(nomes == "xmlns" | startsWith(nomes, "xmlns:"))]
}

# ---- o que as montagens dos documentos fazem igual ----

conferir_manter_vazios = function(manter_vazios) {
  if (!isTRUE(manter_vazios) && !isFALSE(manter_vazios)) {
    stop("manter_vazios tem de ser TRUE ou FALSE.", call. = FALSE)
  }
}

# O documento tem de ser uma lista com nomes (o conteúdo do elemento assinado), e os textos dele, em UTF-8 e sem
# caractere de controle (conferidos antes de qualquer campo ser usado na chave).
conferir_a_lista_do_documento = function(conteudo, nome_do_documento, grupos_do_conteudo, elemento) {
  nomes = names(conteudo)
  if (!is.list(conteudo) || is.data.frame(conteudo) || is.null(nomes) || any(is.na(nomes) | nomes == "")) {
    stop("Informe ", nome_do_documento, " numa lista com os grupos ", grupos_do_conteudo, ", com os nomes do leiaute.",
         call. = FALSE)
  }
  conferir_os_textos_do_documento(conteudo, elemento)
}

# O tpAmb do ide: o do ambiente quando falta; o de outro ambiente é recusado.
com_o_ambiente = function(conteudo, ambiente, nome_do_documento) {
  if (!is.list(conteudo[["ide"]]) || is.null(names(conteudo[["ide"]]))) {
    stop(nome_do_documento, " precisa do grupo ide (a identifica\u00e7\u00e3o), numa lista.", call. = FALSE)
  }
  tipo_de_ambiente = as.character(AMBIENTES_LIBERADOS[[ambiente]])
  informado = texto_do_campo(conteudo[["ide"]][["tpAmb"]], "ide/tpAmb")
  if (is.na(informado)) {
    conteudo[["ide"]][["tpAmb"]] = tipo_de_ambiente
  } else if (informado != tipo_de_ambiente) {
    stop(nome_do_documento, " tem de ser do ambiente de homologa\u00e7\u00e3o (tpAmb 2).", call. = FALSE)
  }
  conteudo
}

# O XML de um documento do DOCUMENTOS_PARA_MONTAR, conferido no schema oficial. `atributos_da_raiz` são os atributos
# do elemento de fora (a versao da DPS), que a lista do conteúdo não traz.
montar_o_documento = function(documento, conteudo, manter_vazios, atributos_da_raiz = list()) {
  definicao = DOCUMENTOS_PARA_MONTAR[[documento]]
  schema = schema_para_montar(definicao$pasta, definicao$arquivos)
  conteudo_da_raiz = atributos_da_raiz
  conteudo_da_raiz[[definicao$conteudo]] = conteudo
  xml_montado = montar_pelo_schema(schema, definicao$raiz, conteudo_da_raiz, manter_vazios)
  parar_se_o_schema_recusar(erros_do_documento_montado(xml_montado, schema, definicao$raiz))
  xml_montado
}

# O código numérico (sorteado quando falta), o dígito e o Id dos documentos de chave de 44 posições (NF-e, CT-e, MDF-e),
# pelos campos do ide e do emitente. O CNPJ ou o CPF que veio como número volta com os zeros, igual na chave e no XML.
# `cnpj_no_lugar` é o CNPJ da chave quando não é o do emitente (o órgão do Fisco, na NF-e avulsa).
completar_a_chave = function(conteudo, prefixo, nome_do_numero, nome_do_codigo, modelo_que_falta = NA_character_,
                             cnpj_no_lugar = NA_character_) {
  ide = conteudo[["ide"]]
  emitente = conteudo[["emit"]]
  if (!is.list(emitente)) {
    emitente = list()
  }
  for (nome_do_campo in c("cUF", "dhEmi", "mod", "serie", nome_do_numero, "tpEmis", nome_do_codigo, "cDV")) {
    if (length(ide[[nome_do_campo]]) > 1) {
      stop("O campo ide/", nome_do_campo, " recebeu mais de um valor.", call. = FALSE)
    }
  }
  for (nome_do_campo in c("CNPJ", "CPF")) {
    if (length(emitente[[nome_do_campo]]) > 1) {
      stop("O campo emit/", nome_do_campo, " recebeu mais de um valor.", call. = FALSE)
    }
  }
  if (is.numeric(emitente[["CNPJ"]])) {
    emitente[["CNPJ"]] = com_zeros(emitente[["CNPJ"]], 14, "emit/CNPJ")
  }
  if (is.numeric(emitente[["CPF"]])) {
    emitente[["CPF"]] = com_zeros(emitente[["CPF"]], 11, "emit/CPF")
  }
  if (is.na(texto_do_campo(ide[["mod"]], "ide/mod")) && !is.na(modelo_que_falta)) {
    ide[["mod"]] = modelo_que_falta
  }
  caminho_do_codigo = paste0("ide/", nome_do_codigo)
  if (is.na(texto_do_campo(ide[[nome_do_codigo]], caminho_do_codigo))) {
    ide[[nome_do_codigo]] = sortear_codigo_numerico(ide[[nome_do_numero]])
  } else if (is.numeric(ide[[nome_do_codigo]])) {
    ide[[nome_do_codigo]] = com_zeros(ide[[nome_do_codigo]], 8, caminho_do_codigo)
  }
  faltam = character()
  for (nome_do_campo in c("cUF", "dhEmi", "mod", "serie", nome_do_numero, "tpEmis")) {
    if (is.na(texto_do_campo(ide[[nome_do_campo]], paste0("ide/", nome_do_campo)))) {
      faltam = c(faltam, paste0("ide/", nome_do_campo))
    }
  }
  cnpj = texto_do_campo(emitente[["CNPJ"]], "emit/CNPJ")
  cpf = texto_do_campo(emitente[["CPF"]], "emit/CPF")
  if (!is.na(cnpj_no_lugar)) {
    cnpj = cnpj_no_lugar
  }
  if (is.na(cnpj) && is.na(cpf)) {
    faltam = c(faltam, "emit/CNPJ (ou emit/CPF)")
  }
  if (length(faltam) > 0) {
    stop("Para montar a chave de acesso faltam: ", paste(faltam, collapse = ", "), ".", call. = FALSE)
  }
  chave = chave_montada(texto_do_campo(ide[["cUF"]], "ide/cUF"), ide[["dhEmi"]], cnpj, cpf, texto_do_campo(ide[["mod"]], "ide/mod"),
                        com_zeros(ide[["serie"]], 3, "ide/serie"),
                        com_zeros(ide[[nome_do_numero]], 9, paste0("ide/", nome_do_numero)),
                        texto_do_campo(ide[["tpEmis"]], "ide/tpEmis"), texto_do_campo(ide[[nome_do_codigo]], caminho_do_codigo))
  digito = substr(chave, 44, 44)
  digito_informado = texto_do_campo(ide[["cDV"]], "ide/cDV")
  if (!is.na(digito_informado) && digito_informado != digito) {
    stop("O cDV informado (", digito_informado, ") n\u00e3o confere com os campos da chave: o certo \u00e9 ", digito, ".",
         call. = FALSE)
  }
  identificador = paste0(prefixo, chave)
  identificador_informado = texto_do_campo(conteudo[["Id"]], "Id")
  if (!is.na(identificador_informado) && identificador_informado != identificador) {
    stop("O Id informado (", identificador_informado, ") n\u00e3o confere com os campos do documento: o certo \u00e9 ",
         identificador, ".", call. = FALSE)
  }
  ide[["cDV"]] = digito
  conteudo[["ide"]] = ide
  if (length(emitente) > 0) {
    conteudo[["emit"]] = emitente
  }
  conteudo[["Id"]] = identificador
  conteudo
}

# A chave de acesso de 44 posições (NF-e, NFC-e, CT-e, MDF-e): a UF, o ano e o mês, o CNPJ ou o CPF do emitente (com três
# zeros na frente), o modelo, a série, o número, a forma de emissão, o código numérico e o dígito.
chave_montada = function(uf, emissao, cnpj, cpf, modelo, serie, numero, forma_de_emissao, codigo_numerico) {
  if (!is.na(cnpj)) {
    emitente = cnpj
  } else {
    emitente = paste0("000", cpf)
  }
  sem_digito = paste0(uf, ano_e_mes_da_emissao(emissao), emitente, modelo, com_zeros(serie, 3), com_zeros(numero, 9),
                      forma_de_emissao, codigo_numerico)
  digito = chave_digito(sem_digito)
  if (is.na(digito)) {
    stop("Os campos da chave de acesso n\u00e3o formam uma chave: ", sem_digito, " (a UF, o ano e o m\u00eas, o CNPJ ou o CPF ",
         "do emitente, o modelo, a s\u00e9rie, o n\u00famero, a forma de emiss\u00e3o e o c\u00f3digo num\u00e9rico).", call. = FALSE)
  }
  paste0(sem_digito, digito)
}

# O AAMM da data de emissão: da data e hora do R, ou do texto do leiaute (AAAA-MM-DDThh:mm:ss-03:00).
ano_e_mes_da_emissao = function(emissao) {
  if (inherits(emissao, "POSIXt") || inherits(emissao, "Date")) {
    return(format(emissao, "%y%m"))
  }
  texto = trimws(as.character(emissao))
  paste0(substr(texto, 3, 4), substr(texto, 6, 7))
}

# O número com zeros à esquerda até a largura (no texto, sem passar por número do R); o que não é só algarismos fica como
# veio (e a chave, ou o schema, o recusa depois).
com_zeros = function(valor, largura, caminho = "de controle") {
  texto = texto_do_campo(valor, caminho)
  if (is.na(texto) || !grepl("^[0-9]+$", texto)) {
    return(texto)
  }
  paste0(strrep("0", max(0, largura - nchar(texto))), texto)
}

# O texto de um campo simples de controle (os da chave, o Id, o ambiente): o número inteiro, o texto sem os espaços das
# pontas; NA quando não veio. O número com casas, o grande demais para o R e o campo com mais de um valor são recusados
# (arredondar ou escolher um mudaria a chave sem aviso).
texto_do_campo = function(valor, caminho = "de controle") {
  if (is.null(valor) || length(valor) == 0 || all(is.na(valor))) {
    return(NA_character_)
  }
  if (length(valor) > 1) {
    stop("O campo ", caminho, " recebeu mais de um valor.", call. = FALSE)
  }
  if (inherits(valor, "integer64")) {
    valor = texto_do_inteiro_de_64_bits(valor, caminho)
  }
  if (is.factor(valor)) {
    valor = as.character(valor)
  }
  if (inherits(valor, "POSIXt") || inherits(valor, "Date")) {
    return(format(valor))
  }
  if (is.numeric(valor)) {
    if (!is.finite(valor) || valor != round(valor)) {
      stop("O campo ", caminho, " recebeu ", format(valor, digits = 15), ": informe um n\u00famero inteiro (ou o texto).",
           call. = FALSE)
    }
    if (abs(valor) >= MAIOR_NUMERO_EXATO) {
      stop("O campo ", caminho, " recebeu um n\u00famero grande demais para o R guardar sem perder algarismos: informe ",
           "como texto.", call. = FALSE)
    }
    return(formatC(valor, format = "f", digits = 0))
  }
  if (!is.character(valor)) {
    stop("O campo ", caminho, " recebeu um valor do tipo ", class(valor)[1], ": informe um texto ou um n\u00famero.",
         call. = FALSE)
  }
  conferir_os_textos(valor, caminho)
  texto = trimws(enc2utf8(valor))
  if (texto == "") {
    return(NA_character_)
  }
  texto
}

# O integer64 (do pacote bit64, como chega um BIGINT do banco) em texto: o R o veria como um número minúsculo.
texto_do_inteiro_de_64_bits = function(valor, caminho) {
  if (!requireNamespace("bit64", quietly = TRUE)) {
    stop("O campo ", caminho, " veio como integer64 (do pacote bit64), que n\u00e3o est\u00e1 instalado: informe como texto.",
         call. = FALSE)
  }
  textos = as.character(valor)
  textos[is.na(valor)] = NA_character_
  unname(textos)
}

# Um código numérico de 8 algarismos para a chave, sorteado, fora dos que a SEFAZ recusa (a B03-10 da NF-e: as
# sequências e os repetidos, e o número do próprio documento, também com os zeros à esquerda, por cautela).
sortear_codigo_numerico = function(numero_do_documento) {
  numero_em_texto = texto_do_campo(numero_do_documento)
  recusados = c(CODIGOS_NUMERICOS_PROIBIDOS, numero_em_texto)
  if (!is.na(numero_em_texto) && grepl("^[0-9]+$", numero_em_texto)) {
    recusados = c(recusados, formatC(as.numeric(numero_em_texto), format = "f", digits = 0, width = 8, flag = "0"))
  }
  repeat {
    codigo = formatC(numero_sorteado(), format = "f", digits = 0, width = 8, flag = "0")
    if (!(codigo %in% recusados)) {
      return(codigo)
    }
  }
}

# Um número de 0 a 99999999 do gerador do sistema (pelo openssl), que não se adivinha e não mexe no gerador do R (o
# set.seed de quem usa o pacote). Os quatro bytes vão de 0 a 2^32 - 1; acima de 42 x 10^8 o número é sorteado de novo,
# para todos os finais terem a mesma chance.
numero_sorteado = function() {
  exigir_pacotes("openssl")
  repeat {
    bytes = as.integer(openssl::rand_bytes(4))
    numero = bytes[1] * 16777216 + bytes[2] * 65536 + bytes[3] * 256 + bytes[4]
    if (numero < 4200000000) {
      return(numero %% 100000000)
    }
  }
}

# ---- o schema ----

# O schema de um documento para a montagem: os arquivos .xsd da pasta de inst/schemas, lidos a partir dos principais
# (cada um com os que ele inclui), com os elementos, os tipos e os grupos do topo de cada arquivo. Lido uma vez por
# sessão. Os principais além do primeiro são os que declaram os elementos que entram num xs:any (os modais do CT-e e do
# MDF-e).
schema_para_montar = function(pasta, arquivos_principais) {
  nome_no_cache = paste0("montagem:", pasta, ":", paste(arquivos_principais, collapse = ","))
  if (!is.null(tabelas_ja_lidas[[nome_no_cache]])) {
    return(tabelas_ja_lidas[[nome_no_cache]])
  }
  pasta_no_pacote = system.file("schemas", pasta, package = "RNFe")
  schema = list(pasta = pasta_no_pacote, arquivos_principais = arquivos_principais, namespace = NA_character_,
                elementos = list(), arquivo_de_cada_elemento = character(), elementos_dos_outros_principais = character(),
                tipos_complexos = list(), tipos_simples = list(), grupos = list(),
                tipos_compilados = new.env(parent = emptyenv()), elementos_compilados = new.env(parent = emptyenv()),
                regras_compiladas = new.env(parent = emptyenv()), mapas_dos_tipos = new.env(parent = emptyenv()),
                ordens_ja_calculadas = new.env(parent = emptyenv()), contador = new.env(parent = emptyenv()))
  schema$contador$tipos = 0
  arquivos_a_ler = arquivos_principais
  arquivos_lidos = character()
  while (length(arquivos_a_ler) > 0) {
    arquivo = arquivos_a_ler[1]
    arquivos_a_ler = arquivos_a_ler[-1]
    if (arquivo %in% arquivos_lidos) {
      next
    }
    arquivos_lidos = c(arquivos_lidos, arquivo)
    caminho_do_arquivo = file.path(pasta_no_pacote, arquivo)
    if (!file.exists(caminho_do_arquivo)) {
      stop("O schema ", arquivo, " n\u00e3o est\u00e1 no pacote (inst/schemas/", pasta, ").", call. = FALSE)
    }
    documento_xsd = xml2::read_xml(caminho_do_arquivo)
    if (is.na(schema$namespace)) {
      schema$namespace = xml2::xml_attr(documento_xsd, "targetNamespace")
    }
    for (definicao in xml2::xml_children(documento_xsd)) {
      tipo_da_definicao = xml2::xml_name(definicao)
      if (tipo_da_definicao == "include") {
        arquivos_a_ler = c(arquivos_a_ler, basename(xml2::xml_attr(definicao, "schemaLocation")))
        next
      }
      nome = xml2::xml_attr(definicao, "name")
      if (is.na(nome)) {
        next
      }
      if (tipo_da_definicao == "element" && is.null(schema$elementos[[nome]])) {
        schema$elementos[[nome]] = definicao
        schema$arquivo_de_cada_elemento[[nome]] = arquivo
        if (arquivo %in% arquivos_principais[-1]) {
          schema$elementos_dos_outros_principais = c(schema$elementos_dos_outros_principais, nome)
        }
      } else if (tipo_da_definicao == "complexType" && is.null(schema$tipos_complexos[[nome]])) {
        schema$tipos_complexos[[nome]] = definicao
      } else if (tipo_da_definicao == "simpleType" && is.null(schema$tipos_simples[[nome]])) {
        schema$tipos_simples[[nome]] = definicao
      } else if (tipo_da_definicao == "group" && is.null(schema$grupos[[nome]])) {
        schema$grupos[[nome]] = definicao
      }
    }
  }
  tabelas_ja_lidas[[nome_no_cache]] = schema
  schema
}

# As partes de uma definição do schema, sem a documentação.
partes_da_definicao = function(definicao) {
  partes = xml2::xml_children(definicao)
  partes[xml2::xml_name(partes) != "annotation"]
}

filhos_chamados = function(definicao, nome) {
  filhos = xml2::xml_children(definicao)
  filhos[xml2::xml_name(filhos) == nome]
}

# Um elemento do topo do schema, compilado (NULL quando o schema não o tem).
elemento_do_topo = function(nome, schema) {
  if (!is.null(schema$elementos_compilados[[nome]])) {
    return(schema$elementos_compilados[[nome]])
  }
  definicao = schema$elementos[[nome]]
  if (is.null(definicao)) {
    return(NULL)
  }
  compilado = compilar_elemento(definicao, schema, nome, FALSE)
  schema$elementos_compilados[[nome]] = compilado
  compilado
}

# Um tipo complexo com nome, compilado.
tipo_complexo_pelo_nome = function(nome_do_tipo, schema) {
  if (!is.null(schema$tipos_compilados[[nome_do_tipo]])) {
    return(schema$tipos_compilados[[nome_do_tipo]])
  }
  compilado = compilar_tipo_complexo(schema$tipos_complexos[[nome_do_tipo]], schema, nome_do_tipo)
  schema$tipos_compilados[[nome_do_tipo]] = compilado
  compilado
}

# O tipo complexo de um elemento compilado (NULL quando ele guarda um valor).
tipo_do_elemento = function(elemento, schema) {
  if (is.null(elemento)) {
    return(NULL)
  }
  if (!is.null(elemento$complexo)) {
    return(elemento$complexo)
  }
  if (!is.null(elemento$nome_do_tipo_complexo) && !is.na(elemento$nome_do_tipo_complexo)) {
    return(tipo_complexo_pelo_nome(elemento$nome_do_tipo_complexo, schema))
  }
  NULL
}

# Um elemento do modelo: o nome, se é opcional, se repete (o maxOccurs dele, ou o de uma sequence ou choice em volta),
# o tipo (o complexo de dentro compilado junto; o complexo com nome, na primeira vez que for usado) ou as regras do
# valor, e o valor único, quando o tipo só aceita um. O que referencia um elemento de outro schema (a assinatura, que o
# xml_assinar() põe) fica marcado.
compilar_elemento = function(definicao, schema, caminho, dentro_de_repeticao) {
  referencia = xml2::xml_attr(definicao, "ref")
  opcional = identical(xml2::xml_attr(definicao, "minOccurs"), "0")
  maximo = xml2::xml_attr(definicao, "maxOccurs")
  repetido = dentro_de_repeticao || (!is.na(maximo) && maximo != "1")
  if (!is.na(referencia)) {
    nome = sub("^.*:", "", referencia)
    if (is.null(schema$elementos[[nome]])) {
      return(list(construcao = "element", nome = nome, opcional = opcional, repetido = repetido, de_outro_schema = TRUE))
    }
    do_topo = elemento_do_topo(nome, schema)
    do_topo$opcional = opcional
    do_topo$repetido = repetido
    return(do_topo)
  }
  nome = xml2::xml_attr(definicao, "name")
  elemento = list(construcao = "element", nome = nome, opcional = opcional, repetido = repetido, de_outro_schema = FALSE,
                  complexo = NULL, nome_do_tipo_complexo = NA_character_, regras = REGRAS_DE_TIPO_BASICO,
                  unico = NA_character_)
  nome_do_tipo = xml2::xml_attr(definicao, "type")
  if (!is.na(nome_do_tipo)) {
    nome_do_tipo = sub("^.*:", "", nome_do_tipo)
    if (!is.null(schema$tipos_complexos[[nome_do_tipo]])) {
      elemento$nome_do_tipo_complexo = nome_do_tipo
    } else {
      elemento$regras = regras_do_tipo_simples(schema$tipos_simples[[nome_do_tipo]], nome_do_tipo, schema)
    }
  } else {
    tipo_complexo = filhos_chamados(definicao, "complexType")
    tipo_simples = filhos_chamados(definicao, "simpleType")
    if (length(tipo_complexo) > 0) {
      elemento$complexo = compilar_tipo_complexo(tipo_complexo[[1]], schema, paste0(caminho, "/", nome))
    } else if (length(tipo_simples) > 0) {
      elemento$regras = regras_do_tipo_simples(tipo_simples[[1]], NA_character_, schema)
    }
  }
  if (!is.na(xml2::xml_attr(definicao, "fixed"))) {
    elemento$unico = xml2::xml_attr(definicao, "fixed")
  } else if (is.null(elemento$complexo) && is.na(elemento$nome_do_tipo_complexo)) {
    elemento$unico = elemento$regras$unico
  }
  elemento
}

# Um tipo complexo: o modelo dos filhos (sequence, choice...) e os atributos, com as regras e o valor automático de
# cada um. O id distingue os tipos na memória das ordens já calculadas.
compilar_tipo_complexo = function(definicao, schema, caminho) {
  schema$contador$tipos = schema$contador$tipos + 1
  tipo = list(id = paste0(caminho, "#", schema$contador$tipos), particula = NULL, atributos = list())
  for (parte in partes_da_definicao(definicao)) {
    nome_da_parte = xml2::xml_name(parte)
    if (nome_da_parte %in% PARTICULAS_DO_MODELO) {
      tipo$particula = compilar_particula(parte, schema, caminho, FALSE)
    } else if (nome_da_parte == "attribute") {
      tipo$atributos[[xml2::xml_attr(parte, "name")]] = compilar_atributo(parte, schema)
    } else {
      stop("O schema usa uma constru\u00e7\u00e3o que a montagem ainda n\u00e3o conhece (", nome_da_parte, ", em ", caminho, ").",
           call. = FALSE)
    }
  }
  tipo
}

compilar_atributo = function(definicao, schema) {
  nome_do_tipo = xml2::xml_attr(definicao, "type")
  if (!is.na(nome_do_tipo)) {
    nome_do_tipo = sub("^.*:", "", nome_do_tipo)
    regras = regras_do_tipo_simples(schema$tipos_simples[[nome_do_tipo]], nome_do_tipo, schema)
  } else {
    tipo_simples = filhos_chamados(definicao, "simpleType")
    regras = REGRAS_DE_TIPO_BASICO
    if (length(tipo_simples) > 0) {
      regras = regras_do_tipo_simples(tipo_simples[[1]], NA_character_, schema)
    }
  }
  # O que não vier: o valor fixo do schema, ou, no obrigatório cujo tipo só aceita um valor, esse valor (a versão do
  # leiaute, por exemplo).
  automatico = character()
  if (!is.na(xml2::xml_attr(definicao, "fixed"))) {
    automatico = xml2::xml_attr(definicao, "fixed")
  } else if (identical(xml2::xml_attr(definicao, "use"), "required") && !is.na(regras$unico)) {
    automatico = regras$unico
  }
  list(regras = regras, automatico = automatico)
}

compilar_particula = function(definicao, schema, caminho, dentro_de_repeticao) {
  construcao = xml2::xml_name(definicao)
  opcional = identical(xml2::xml_attr(definicao, "minOccurs"), "0")
  if (construcao == "element") {
    return(compilar_elemento(definicao, schema, caminho, dentro_de_repeticao))
  }
  if (construcao == "any") {
    return(list(construcao = "any", opcional = opcional))
  }
  if (construcao == "group") {
    grupo = schema$grupos[[sub("^.*:", "", xml2::xml_attr(definicao, "ref"))]]
    if (is.null(grupo)) {
      stop("O schema referencia um grupo que n\u00e3o tem (", xml2::xml_attr(definicao, "ref"), ", em ", caminho, ").",
           call. = FALSE)
    }
    compilado = compilar_particula(partes_da_definicao(grupo)[[1]], schema, caminho, dentro_de_repeticao)
    compilado$opcional = compilado$opcional || opcional
    return(compilado)
  }
  maximo = xml2::xml_attr(definicao, "maxOccurs")
  repetida = !is.na(maximo) && maximo != "1"
  partes = list()
  for (parte in partes_da_definicao(definicao)) {
    partes[[length(partes) + 1]] = compilar_particula(parte, schema, caminho, dentro_de_repeticao || repetida)
  }
  list(construcao = construcao, opcional = opcional, repetida = repetida, partes = partes)
}

# Os elementos que um tipo aceita, pelo nome (para o xml_para_lista() saber o tipo de cada filho e se ele repete), e se
# o modelo tem um xs:any. Calculado uma vez por tipo.
elementos_do_tipo = function(tipo, schema) {
  if (!is.null(schema$mapas_dos_tipos[[tipo$id]])) {
    return(schema$mapas_dos_tipos[[tipo$id]])
  }
  mapa = list(elementos = list(), tem_any = FALSE)
  particulas_a_ver = list(tipo$particula)
  while (length(particulas_a_ver) > 0) {
    particula = particulas_a_ver[[1]]
    particulas_a_ver = particulas_a_ver[-1]
    if (is.null(particula)) {
      next
    }
    if (particula$construcao == "element") {
      if (!isTRUE(particula$de_outro_schema) && is.null(mapa$elementos[[particula$nome]])) {
        mapa$elementos[[particula$nome]] = particula
      }
    } else if (particula$construcao == "any") {
      mapa$tem_any = TRUE
    } else {
      particulas_a_ver = c(particulas_a_ver, particula$partes)
    }
  }
  schema$mapas_dos_tipos[[tipo$id]] = mapa
  mapa
}

# As regras de um tipo simples, seguindo a base até o tipo básico do XSD: os padrões de cada nível (num nível, vale
# um deles; entre os níveis, todos), traduzidos para o PCRE do R; os valores aceitos (os do tipo mais derivado que tem
# a lista); o tamanho; se o tipo é decimal (o padrão tem o ponto, ou a base é decimal) e se a base é um número; e o
# valor único. Os tipos com nome são lidos uma vez.
regras_do_tipo_simples = function(tipo_simples, nome_do_tipo, schema) {
  if (is.null(tipo_simples)) {
    regras = REGRAS_DE_TIPO_BASICO
    if (!is.na(nome_do_tipo)) {
      regras$base = nome_do_tipo
      regras$numerica = nome_do_tipo %in% BASES_NUMERICAS
      regras$decimal = nome_do_tipo %in% c("decimal", "double", "float")
    }
    return(com_o_que_o_tipo_aceita_de_numero(regras))
  }
  if (!is.na(nome_do_tipo) && !is.null(schema$regras_compiladas[[nome_do_tipo]])) {
    return(schema$regras_compiladas[[nome_do_tipo]])
  }
  regras = REGRAS_DE_TIPO_BASICO
  tipo_atual = tipo_simples
  while (!is.null(tipo_atual)) {
    restricao = filhos_chamados(tipo_atual, "restriction")
    if (length(restricao) == 0) {
      break
    }
    restricao = restricao[[1]]
    padroes_do_nivel = xml2::xml_attr(filhos_chamados(restricao, "pattern"), "value")
    if (length(padroes_do_nivel) > 0) {
      regras$padroes_originais = c(regras$padroes_originais, padroes_do_nivel)
      regras$padroes_por_nivel[[length(regras$padroes_por_nivel) + 1]] = padroes_em_r(padroes_do_nivel)
    }
    if (length(regras$valores_aceitos) == 0) {
      regras$valores_aceitos = xml2::xml_attr(filhos_chamados(restricao, "enumeration"), "value")
    }
    regras = com_o_tamanho_do_nivel(regras, restricao)
    nome_da_base = xml2::xml_attr(restricao, "base")
    tipo_atual = NULL
    if (is.na(nome_da_base)) {
      tipo_de_dentro = filhos_chamados(restricao, "simpleType")
      if (length(tipo_de_dentro) > 0) {
        tipo_atual = tipo_de_dentro[[1]]
      }
    } else {
      nome_da_base = sub("^.*:", "", nome_da_base)
      tipo_atual = schema$tipos_simples[[nome_da_base]]
      if (is.null(tipo_atual)) {
        regras$base = nome_da_base
      }
    }
  }
  regras$numerica = regras$base %in% BASES_NUMERICAS
  regras$decimal = regras$base %in% c("decimal", "double", "float") || any(grepl("\\.", regras$padroes_originais,
                                                                                    fixed = TRUE))
  regras$unico = valor_unico_do_tipo(regras)
  regras = com_o_que_o_tipo_aceita_de_numero(regras)
  if (!is.na(nome_do_tipo)) {
    schema$regras_compiladas[[nome_do_tipo]] = regras
  }
  regras
}

# Para a montagem não testar o padrão em cada valor: as quantidades de casas decimais que o tipo aceita num número
# comum (o 5,5 com uma casa, 5,55 com duas...) e se ele aceita zero à esquerda (o 05, o 005...). O número que sai nesse
# formato ainda é conferido no schema no fim.
com_o_que_o_tipo_aceita_de_numero = function(regras) {
  regras$casas_aceitas = integer()
  regras$aceita_inteiro = FALSE
  regras$aceita_zero_a_esquerda = FALSE
  if (regras$decimal) {
    exemplos = paste0("5.", strrep("5", CASAS_DECIMAIS_TENTADAS))
    regras$casas_aceitas = CASAS_DECIMAIS_TENTADAS[regras_aceitam(exemplos, regras)]
    regras$aceita_inteiro = regras_aceitam("5", regras)
  }
  maior_tamanho = 20
  if (!is.na(regras$comprimento_maximo)) {
    maior_tamanho = regras$comprimento_maximo
  }
  if (length(regras$valores_aceitos) > 0) {
    regras$aceita_zero_a_esquerda = any(grepl("^0[0-9]", regras$valores_aceitos))
  } else if (maior_tamanho >= 2) {
    com_zeros = c(sprintf("%0*d", 2:maior_tamanho, 1L), sprintf("%0*d", 2:maior_tamanho, 5L))
    regras$aceita_zero_a_esquerda = any(regras_aceitam(com_zeros, regras))
  }
  regras
}

# O tamanho de um nível da restrição (length, minLength, maxLength), somado ao dos outros: vale o mais estreito.
com_o_tamanho_do_nivel = function(regras, restricao) {
  exato = xml2::xml_attr(filhos_chamados(restricao, "length"), "value")
  minimo = c(exato, xml2::xml_attr(filhos_chamados(restricao, "minLength"), "value"))
  maximo = c(exato, xml2::xml_attr(filhos_chamados(restricao, "maxLength"), "value"))
  if (length(minimo) > 0) {
    regras$comprimento_minimo = max(c(regras$comprimento_minimo, as.integer(minimo)), na.rm = TRUE)
  }
  if (length(maximo) > 0) {
    regras$comprimento_maximo = min(c(regras$comprimento_maximo, as.integer(maximo)), na.rm = TRUE)
  }
  regras
}

# Os padrões do XSD no PCRE do R: inteiros (o XSD confere o valor todo) e com o ^ e o $ fora de colchete como letras,
# que é o que eles são no XSD (e no libxml2, que confere o documento no fim).
padroes_em_r = function(padroes) {
  traduzidos = character(length(padroes))
  for (posicao in seq_along(padroes)) {
    caracteres = strsplit(padroes[posicao], "")[[1]]
    partes = character()
    dentro_do_colchete = FALSE
    indice = 1
    while (indice <= length(caracteres)) {
      caractere = caracteres[indice]
      if (caractere == "\\" && indice < length(caracteres)) {
        partes = c(partes, caractere, caracteres[indice + 1])
        indice = indice + 2
        next
      }
      if (caractere == "[") {
        dentro_do_colchete = TRUE
      } else if (caractere == "]") {
        dentro_do_colchete = FALSE
      } else if (!dentro_do_colchete && caractere %in% c("^", "$")) {
        caractere = paste0("\\", caractere)
      }
      partes = c(partes, caractere)
      indice = indice + 1
    }
    traduzidos[posicao] = paste0("^(?:", paste(partes, collapse = ""), ")$")
  }
  traduzidos
}

valor_unico_do_tipo = function(regras) {
  if (length(regras$valores_aceitos) == 1) {
    return(regras$valores_aceitos)
  }
  if (length(regras$valores_aceitos) == 0 && length(regras$padroes_originais) == 1 &&
      grepl(PADRAO_DE_UM_VALOR_SO, regras$padroes_originais)) {
    return(gsub("\\.", ".", regras$padroes_originais, fixed = TRUE))
  }
  NA_character_
}

# Quais dos textos o tipo aceita: a lista de valores, os padrões de cada nível e o tamanho.
regras_aceitam = function(textos, regras) {
  aceitos = !is.na(textos)
  if (length(regras$valores_aceitos) > 0) {
    aceitos = aceitos & textos %in% regras$valores_aceitos
  }
  for (padroes_do_nivel in regras$padroes_por_nivel) {
    aceitos_no_nivel = rep(FALSE, length(textos))
    for (padrao in padroes_do_nivel) {
      aceitos_no_nivel = aceitos_no_nivel | grepl(padrao, textos, perl = TRUE)
    }
    aceitos = aceitos & aceitos_no_nivel
  }
  comprimentos = comprimentos_no_tipo(textos, regras$base)
  if (!is.na(regras$comprimento_minimo)) {
    aceitos = aceitos & !is.na(comprimentos) & comprimentos >= regras$comprimento_minimo
  }
  if (!is.na(regras$comprimento_maximo)) {
    aceitos = aceitos & !is.na(comprimentos) & comprimentos <= regras$comprimento_maximo
  }
  aceitos
}

# O tamanho de cada texto como o XSD conta: os caracteres, ou, no base64Binary e no hexBinary, os bytes que o texto
# guarda (o hash de 28 caracteres em Base64 tem 20 bytes). NA quando o texto não é do formato do tipo.
comprimentos_no_tipo = function(textos, base) {
  if (identical(base, "base64Binary")) {
    sem_espacos = gsub("[ \t\r\n]", "", textos)
    validos = !is.na(textos) & grepl("^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$", sem_espacos)
    comprimentos = rep(NA_real_, length(textos))
    comprimentos[validos] = nchar(sem_espacos[validos]) / 4 * 3 - nchar(gsub("[^=]", "", sem_espacos[validos]))
    return(comprimentos)
  }
  if (identical(base, "hexBinary")) {
    validos = !is.na(textos) & grepl("^([0-9A-Fa-f]{2})*$", textos)
    comprimentos = rep(NA_real_, length(textos))
    comprimentos[validos] = nchar(textos[validos]) / 2
    return(comprimentos)
  }
  nchar(textos)
}

# O que o tipo aceita, para a mensagem do campo recusado: a lista de valores (até dez), o padrão e o tamanho.
descricao_das_regras = function(regras) {
  partes = character()
  if (length(regras$valores_aceitos) > 0) {
    valores = utils::head(regras$valores_aceitos, 10)
    lista = paste0("\"", valores, "\"", collapse = ", ")
    if (length(regras$valores_aceitos) > 10) {
      lista = paste0(lista, "...")
    }
    partes = c(partes, paste("valores aceitos:", lista))
  }
  if (length(regras$padroes_originais) > 0) {
    partes = c(partes, paste("padr\u00e3o:", paste(regras$padroes_originais, collapse = " e ")))
  }
  if (!is.na(regras$comprimento_minimo) || !is.na(regras$comprimento_maximo)) {
    minimo = if (is.na(regras$comprimento_minimo)) 0 else regras$comprimento_minimo
    maximo = if (is.na(regras$comprimento_maximo)) "sem limite" else regras$comprimento_maximo
    partes = c(partes, paste0("tamanho de ", minimo, " a ", maximo))
  }
  if (length(partes) == 0) {
    return(paste("o tipo", regras$base))
  }
  paste(partes, collapse = "; ")
}

# ---- a montagem ----

# O XML do documento inteiro: a raiz, com o namespace do schema, e o conteúdo dela. Com manter_vazios, o texto vazio
# ("") sai como tag vazia também no campo e no grupo opcionais.
montar_pelo_schema = function(schema, nome_da_raiz, conteudo_da_raiz, manter_vazios = FALSE) {
  raiz = elemento_do_topo(nome_da_raiz, schema)
  if (is.null(raiz)) {
    stop("O schema n\u00e3o tem o elemento ", nome_da_raiz, ".", call. = FALSE)
  }
  conferir_os_textos_do_documento(conteudo_da_raiz, nome_da_raiz)
  xml_do_grupo(nome_da_raiz, conteudo_da_raiz, tipo_do_elemento(raiz, schema), schema, nome_da_raiz, manter_vazios,
               schema$namespace)
}

# Os textos do documento inteiro de uma vez: fora do UTF-8 ou com caractere de controle (que o XML não aceita). Só
# quando há um, o documento é percorrido de novo para dizer qual campo é.
conferir_os_textos_do_documento = function(conteudo, caminho) {
  textos = unlist(conteudo, use.names = FALSE)
  if (!is.character(textos)) {
    return(invisible(NULL))
  }
  textos = enc2utf8(textos)
  if (all(is.na(textos) | validUTF8(textos)) && !any(grepl(CARACTERES_DE_CONTROLE, textos, perl = TRUE))) {
    return(invisible(NULL))
  }
  achar_o_texto_com_problema(conteudo, caminho)
}

achar_o_texto_com_problema = function(conteudo, caminho) {
  nomes = names(conteudo)
  for (posicao in seq_along(conteudo)) {
    valor = conteudo[[posicao]]
    caminho_do_valor = caminho
    if (!is.null(nomes) && !is.na(nomes[posicao]) && nomes[posicao] != "") {
      caminho_do_valor = paste0(caminho, "/", nomes[posicao])
    }
    if (is.list(valor)) {
      achar_o_texto_com_problema(valor, caminho_do_valor)
    } else if (is.character(valor) || is.factor(valor)) {
      conferir_os_textos(as.character(valor), caminho_do_valor)
    }
  }
  invisible(NULL)
}

conferir_os_textos = function(textos, caminho) {
  textos = enc2utf8(textos)
  if (any(!is.na(textos) & !validUTF8(textos))) {
    stop("O campo ", caminho, " tem um texto que n\u00e3o est\u00e1 em UTF-8: converta antes (por exemplo, ",
         "iconv(texto, \"latin1\", \"UTF-8\")).", call. = FALSE)
  }
  if (any(grepl(CARACTERES_DE_CONTROLE, textos, perl = TRUE))) {
    stop("O campo ", caminho, " tem um caractere de controle, que o XML n\u00e3o aceita.", call. = FALSE)
  }
}

# O XML de um grupo (elemento de tipo complexo): os atributos e os filhos, na ordem do schema. O grupo só sai quando
# algo informado nele saiu (o campo automático sozinho não conta).
xml_do_grupo = function(nome, conteudo, tipo, schema, caminho, manter_vazios, namespace = NULL) {
  conteudo = sem_os_nulos(valores_preparados(conteudo, caminho))
  # Sem manter_vazios, o texto vazio só sai no campo obrigatório (em ocorrencias_em_xml): há campo obrigatório que
  # aceita o vazio, como o cEAN. Na escolha e na mensagem do campo que não existe, só conta o que foi informado.
  nomes_com_valor = nomes_informados(conteudo, manter_vazios)
  if (length(nomes_com_valor) == 0) {
    return("")
  }
  nomes_dados = names(conteudo)
  nomes_dos_atributos = nomes_dados[nomes_dados %in% names(tipo$atributos)]
  nomes_dos_filhos = nomes_dados[!(nomes_dados %in% names(tipo$atributos))]
  colocados = colocar_na_ordem_do_tipo(tipo, nomes_dos_filhos, nomes_com_valor, schema)
  sobrando = nomes_dos_filhos[!(nomes_dos_filhos %in% colocados$nomes) & nomes_dos_filhos %in% nomes_com_valor]
  if (length(sobrando) > 0) {
    aceitos = unique(c(names(tipo$atributos), nomes_do_modelo(tipo$particula)))
    if (sobrando[1] %in% aceitos) {
      rivais = rivais_na_escolha(tipo$particula, sobrando[1], colocados$nomes[colocados$nomes %in% nomes_com_valor])
      if (length(rivais) == 0) {
        rivais = "os outros campos informados"
      }
      stop("O campo \"", sobrando[1], "\" n\u00e3o cabe em ", caminho, " junto com ", paste(rivais, collapse = ", "),
           ": o schema deixa um ou outro (uma escolha).", call. = FALSE)
    }
    stop("O campo \"", sobrando[1], "\" n\u00e3o existe em ", caminho, " (o schema aceita ali: ",
         paste(aceitos, collapse = ", "), ").", call. = FALSE)
  }
  saiu_algo_informado = FALSE
  texto_dos_atributos = ""
  for (nome_do_atributo in names(tipo$atributos)) {
    atributo = tipo$atributos[[nome_do_atributo]]
    informado = nome_do_atributo %in% nomes_com_valor
    if (informado) {
      caminho_do_atributo = paste0(caminho, "/@", nome_do_atributo)
      textos = textos_do_valor(conteudo[[nome_do_atributo]], atributo$regras, caminho_do_atributo)
      if (!manter_vazios) {
        textos = textos[textos != ""]
      }
      recusados = !regras_aceitam(textos, atributo$regras)
      if (any(recusados)) {
        stop("O atributo ", caminho_do_atributo, " recebeu \"", textos[recusados][1], "\", que o tipo dele n\u00e3o aceita (",
             descricao_das_regras(atributo$regras), ").", call. = FALSE)
      }
    } else {
      textos = atributo$automatico
    }
    if (length(textos) > 1) {
      stop("O atributo ", caminho, "/@", nome_do_atributo, " recebeu mais de um valor.", call. = FALSE)
    }
    if (length(textos) == 1) {
      texto_dos_atributos = paste0(texto_dos_atributos, " ", nome_do_atributo, "=\"", escapar_atributo_canonico(textos),
                                   "\"")
      saiu_algo_informado = saiu_algo_informado || informado
    }
  }
  ocorrencias_de_cada_filho = list()
  for (posicao in seq_along(colocados$nomes)) {
    nome_do_filho = colocados$nomes[posicao]
    informado = nome_do_filho %in% nomes_dos_filhos
    if (informado) {
      valor_do_filho = conteudo[[nome_do_filho]]
    } else {
      valor_do_filho = colocados$automaticos[[nome_do_filho]]
    }
    ocorrencias = ocorrencias_em_xml(nome_do_filho, valor_do_filho, colocados$elementos[[posicao]], schema,
                                     paste0(caminho, "/", nome_do_filho), manter_vazios)
    ocorrencias_de_cada_filho[[posicao]] = ocorrencias
    if (length(ocorrencias) > 0 && nome_do_filho %in% nomes_com_valor) {
      saiu_algo_informado = TRUE
    }
  }
  if (!saiu_algo_informado) {
    return("")
  }
  declaracao_do_namespace = ""
  if (!is.null(namespace)) {
    declaracao_do_namespace = paste0(" xmlns=\"", namespace, "\"")
  }
  paste0("<", nome, declaracao_do_namespace, texto_dos_atributos, ">",
         conteudo_na_ordem(ocorrencias_de_cada_filho, colocados$blocos, colocados$nomes, caminho), "</", nome, ">")
}

# O conteúdo do grupo: cada filho com todas as vezes que ele aparece; nos campos que o schema repete juntos (uma
# sequence com maxOccurs), uma vez de cada um por rodada (a1, b1, a2, b2...). Quantidades diferentes ali não dizem a
# que rodada cada um pertence, e são recusadas.
conteudo_na_ordem = function(ocorrencias_de_cada_filho, blocos, nomes, caminho) {
  partes = character()
  posicao = 1
  while (posicao <= length(ocorrencias_de_cada_filho)) {
    if (is.na(blocos[posicao])) {
      partes = c(partes, ocorrencias_de_cada_filho[[posicao]])
      posicao = posicao + 1
      next
    }
    no_bloco = which(blocos == blocos[posicao])
    quantidades = lengths(ocorrencias_de_cada_filho[no_bloco])
    if (length(unique(quantidades)) > 1) {
      stop("Os campos ", paste(nomes[no_bloco], collapse = ", "), " se repetem juntos em ", caminho, " e vieram em ",
           "quantidades diferentes (", paste(quantidades, collapse = ", "), "): n\u00e3o d\u00e1 para saber de que vez \u00e9 cada um.",
           call. = FALSE)
    }
    for (vez in seq_len(quantidades[1])) {
      for (posicao_no_bloco in no_bloco) {
        partes = c(partes, ocorrencias_de_cada_filho[[posicao_no_bloco]][vez])
      }
    }
    posicao = max(no_bloco) + 1
  }
  paste(partes, collapse = "")
}

# Os valores do grupo prontos para a montagem, ou o erro com o nome do campo: o nome repetido, o fator (vira texto,
# conferido aqui: o unlist() da conferência do documento inteiro vê o código do fator, não o texto), o número que não é
# número (o NaN passaria como não informado). O texto vai em UTF-8.
valores_preparados = function(conteudo, caminho) {
  if (length(conteudo) == 0) {
    return(list())
  }
  nomes = names(conteudo)
  if (is.null(nomes) || any(is.na(nomes) | nomes == "")) {
    stop("O grupo ", caminho, " tem campos sem nome.", call. = FALSE)
  }
  repetidos = unique(nomes[duplicated(nomes)])
  if (length(repetidos) > 0) {
    stop("O campo \"", repetidos[1], "\" aparece mais de uma vez em ", caminho, ": para repetir, use um vetor (no campo) ",
         "ou uma lista de listas (no grupo).", call. = FALSE)
  }
  for (posicao in seq_along(conteudo)) {
    valor = conteudo[[posicao]]
    caminho_do_campo = paste0(caminho, "/", nomes[posicao])
    # A data do POSIXlt é uma lista por dentro (passaria por grupo); o integer64 o R veria como um número minúsculo.
    if (inherits(valor, "POSIXlt")) {
      valor = as.POSIXct(valor)
    } else if (inherits(valor, "integer64")) {
      valor = texto_do_inteiro_de_64_bits(valor, caminho_do_campo)
    }
    if (is.factor(valor)) {
      valor = as.character(valor)
      conferir_os_textos(valor, caminho_do_campo)
    }
    if (is.character(valor)) {
      valor = enc2utf8(valor)
    } else if (is.numeric(valor) && any(is.nan(valor) | is.infinite(valor))) {
      stop("O campo ", caminho_do_campo, " recebeu um n\u00famero inv\u00e1lido (NaN ou Inf).", call. = FALSE)
    }
    if (!is.null(valor)) {
      conteudo[[posicao]] = valor
    }
  }
  conteudo
}

# Tira do grupo o NULL, o NA e a lista vazia: o texto vazio fica para o campo obrigatório que o aceita.
sem_os_nulos = function(conteudo) {
  if (length(conteudo) == 0) {
    return(list())
  }
  ficam = rep(TRUE, length(conteudo))
  for (posicao in seq_along(conteudo)) {
    valor = conteudo[[posicao]]
    if (is.null(valor) || length(valor) == 0 || (is.atomic(valor) && all(is.na(valor)))) {
      ficam[posicao] = FALSE
    }
  }
  conteudo[ficam]
}

# Os campos que vieram com valor: o texto que não é vazio (com manter_vazios, também o vazio), o número, a data, o
# grupo com algo dentro (se ele sai mesmo, o grupo de dentro decide).
nomes_informados = function(conteudo, manter_vazios) {
  informados = character()
  for (nome in names(conteudo)) {
    valor = conteudo[[nome]]
    if (is.list(valor)) {
      tem_valor = length(valor) > 0
    } else if (is.character(valor) && !manter_vazios) {
      tem_valor = any(!is.na(valor) & sem_espacos_nas_pontas(valor) != "")
    } else {
      tem_valor = any(!is.na(valor))
    }
    if (tem_valor) {
      informados = c(informados, nome)
    }
  }
  informados
}

# O texto sem os espaços das pontas; o trimws() só onde há espaço (ele é a parte mais lenta da montagem).
sem_espacos_nas_pontas = function(textos) {
  primeiros = substr(textos, 1, 1)
  ultimos = substr(textos, nchar(textos), nchar(textos))
  com_espaco = !is.na(textos) & (primeiros %in% CARACTERES_DE_ESPACO | ultimos %in% CARACTERES_DE_ESPACO)
  if (any(com_espaco)) {
    textos[com_espaco] = trimws(textos[com_espaco])
  }
  textos
}

# O XML de um campo, um texto por vez que ele aparece: o grupo pelo modelo dele, o valor pelas regras do tipo simples.
ocorrencias_em_xml = function(nome, valor, elemento, schema, caminho, manter_vazios) {
  tipo = tipo_do_elemento(elemento, schema)
  if (!is.null(tipo)) {
    # O grupo que veio como texto vazio (o xml_para_lista() lê assim o grupo vazio do XML, como um <compra/>): o
    # opcional fica de fora (com manter_vazios, sai vazio), o obrigatório sai vazio.
    if (is.atomic(valor) && all(is.na(valor) | valor == "")) {
      if (elemento$opcional && !manter_vazios) {
        return(character())
      }
      return(paste0("<", nome, "></", nome, ">"))
    }
    partes = character()
    for (ocorrencia in ocorrencias_do_grupo(valor, caminho)) {
      if (is.atomic(ocorrencia)) {
        if (manter_vazios || !elemento$opcional) {
          partes = c(partes, paste0("<", nome, "></", nome, ">"))
        }
      } else {
        parte = xml_do_grupo(nome, ocorrencia, tipo, schema, caminho, manter_vazios)
        if (parte != "") {
          partes = c(partes, parte)
        }
      }
    }
    return(partes)
  }
  if (is.list(valor)) {
    stop("O campo ", caminho, " guarda um valor, n\u00e3o um grupo: informe um texto, um n\u00famero ou uma data.",
         call. = FALSE)
  }
  textos = textos_do_valor(valor, elemento$regras, caminho)
  if (elemento$opcional && !manter_vazios) {
    textos = textos[textos != ""]
  }
  if (length(textos) == 0) {
    return(character())
  }
  # O texto que o tipo recusa para aqui, com o nome do campo: a conferência final do libxml2 deixa passar o tamanho
  # errado em padrões com alternativas (o NCM de 9 algarismos, o cEAN de 19).
  recusados = !regras_aceitam(textos, elemento$regras)
  if (any(recusados)) {
    stop("O campo ", caminho, " recebeu \"", textos[recusados][1], "\", que o tipo dele n\u00e3o aceita (",
         descricao_das_regras(elemento$regras), ").", call. = FALSE)
  }
  # O escape só onde há o que escapar (os quatro gsub em todo valor pesavam na nota de muitos itens).
  com_caractere_especial = grepl("[&<>\r]", textos)
  if (any(com_caractere_especial)) {
    textos[com_caractere_especial] = escapar_texto_canonico(textos[com_caractere_especial])
  }
  paste0("<", nome, ">", textos, "</", nome, ">")
}

# Cada vez que o grupo aparece: uma lista com nomes é uma vez; uma lista sem nomes, uma por elemento, que pode ser
# uma lista com os campos ou o texto vazio (o grupo vazio que o xml_para_lista() leu).
ocorrencias_do_grupo = function(valor, caminho) {
  if (is.data.frame(valor) || !is.list(valor)) {
    stop("O campo ", caminho, " \u00e9 um grupo: informe uma lista com os campos dele (ou uma lista de listas, quando ",
         "ele aparece mais de uma vez).", call. = FALSE)
  }
  nomes = names(valor)
  if (!is.null(nomes)) {
    nomes[is.na(nomes)] = ""
  }
  if (!is.null(nomes) && all(nomes != "")) {
    return(list(valor))
  }
  if (!is.null(nomes) && any(nomes != "")) {
    stop("O grupo ", caminho, " mistura campos com nome e sem nome.", call. = FALSE)
  }
  ocorrencias = list()
  for (ocorrencia in valor) {
    if (is.null(ocorrencia)) {
      next
    }
    vazia = is.atomic(ocorrencia) && all(is.na(ocorrencia) | ocorrencia == "")
    nomes_da_ocorrencia = names(ocorrencia)
    com_os_campos = is.list(ocorrencia) && !is.data.frame(ocorrencia) && !is.null(nomes_da_ocorrencia) &&
      !any(is.na(nomes_da_ocorrencia) | nomes_da_ocorrencia == "")
    if (!vazia && !com_os_campos && !(is.list(ocorrencia) && length(ocorrencia) == 0)) {
      stop("O grupo ", caminho, " aparece mais de uma vez: cada uma tem de ser uma lista com os campos, todos com ",
           "nome.", call. = FALSE)
    }
    if (is.list(ocorrencia) && length(ocorrencia) == 0) {
      next
    }
    ocorrencias[[length(ocorrencias) + 1]] = ocorrencia
  }
  ocorrencias
}

# A ordem dos filhos de um tipo para os nomes informados, guardada: os itens de uma nota têm quase sempre os mesmos
# campos, e a ordem calculada uma vez serve para todos.
colocar_na_ordem_do_tipo = function(tipo, nomes_dos_filhos, nomes_com_valor, schema) {
  chave = paste0(tipo$id, "|", paste(nomes_dos_filhos, collapse = ","), "|", paste(nomes_com_valor, collapse = ","))
  guardado = schema$ordens_ja_calculadas[[chave]]
  if (!is.null(guardado)) {
    return(guardado)
  }
  colocados = colocar_na_ordem(tipo$particula, nomes_dos_filhos, nomes_com_valor, schema, TRUE)
  schema$ordens_ja_calculadas[[chave]] = colocados
  colocados
}

# Os filhos informados, na ordem em que o modelo do schema os aceita. Cada nome colocado sai de "faltam"; o que sobrar
# no fim não existe ali. No caminho obrigatório (fora de escolha e de parte opcional), o elemento obrigatório cujo tipo
# só aceita um valor entra sozinho, com esse valor, quando não veio com valor. Os campos de uma sequence repetida ficam
# marcados com o mesmo bloco, para saírem intercalados.
colocar_na_ordem = function(particula, faltam, nomes_com_valor, schema, obrigatorio) {
  colocados = list(nomes = character(), elementos = list(), automaticos = list(), blocos = character())
  if (is.null(particula)) {
    return(colocados)
  }
  obrigatorio = obrigatorio && !particula$opcional
  if (particula$construcao == "element") {
    if (particula$de_outro_schema) {
      return(colocados)
    }
    if (obrigatorio && !is.na(particula$unico) && !(particula$nome %in% nomes_com_valor)) {
      colocados$nomes = particula$nome
      colocados$elementos = list(particula)
      colocados$automaticos[[particula$nome]] = particula$unico
      colocados$blocos = NA_character_
    } else if (particula$nome %in% faltam) {
      colocados$nomes = particula$nome
      colocados$elementos = list(particula)
      colocados$blocos = NA_character_
    }
    return(colocados)
  }
  if (particula$construcao == "any") {
    # No xs:any entram só os elementos dos outros schemas principais (os modais), conferidos no schema deles no fim.
    for (nome in faltam[faltam %in% schema$elementos_dos_outros_principais]) {
      do_topo = elemento_do_topo(nome, schema)
      if (!is.null(do_topo)) {
        colocados$nomes = c(colocados$nomes, nome)
        colocados$elementos = c(colocados$elementos, list(do_topo))
        colocados$blocos = c(colocados$blocos, NA_character_)
      }
    }
    return(colocados)
  }
  if (particula$construcao != "choice" || particula$repetida) {
    # A sequence opcional em que veio algum campo informado sai, e com ela os campos obrigatórios dela (o de valor
    # único entra sozinho, como fora dela).
    presente = obrigatorio || (particula$construcao == "sequence" && any(nomes_do_modelo(particula) %in% nomes_com_valor))
    obrigatorio_nas_partes = presente && particula$construcao != "choice"
    for (parte in particula$partes) {
      if (length(faltam) == 0 && !obrigatorio_nas_partes) {
        break
      }
      colocados_da_parte = colocar_na_ordem(parte, faltam, nomes_com_valor, schema, obrigatorio_nas_partes)
      if (length(colocados_da_parte$nomes) > 0) {
        colocados = list(nomes = c(colocados$nomes, colocados_da_parte$nomes),
                         elementos = c(colocados$elementos, colocados_da_parte$elementos),
                         automaticos = c(colocados$automaticos, colocados_da_parte$automaticos),
                         blocos = c(colocados$blocos, colocados_da_parte$blocos))
        faltam = faltam[!(faltam %in% colocados_da_parte$nomes)]
      }
    }
    # Na sequence repetida com mais de um campo, cada vez leva um de cada (a escolha repetida não precisa: nela a
    # ordem entre as alternativas é livre).
    if (particula$construcao == "sequence" && particula$repetida && length(colocados$nomes) > 1) {
      colocados$blocos = rep(paste(colocados$nomes, collapse = ","), length(colocados$nomes))
    }
    return(colocados)
  }
  # Na escolha, vale a alternativa que coloca mais dos nomes que vieram com valor; no empate, a que coloca mais nomes
  # (os que vieram vazios contam aqui), e depois a primeira.
  if (length(faltam) == 0) {
    return(colocados)
  }
  melhor_com_valor = 0
  for (parte in particula$partes) {
    tentativa = colocar_na_ordem(parte, faltam, nomes_com_valor, schema, FALSE)
    tentativa_com_valor = sum(tentativa$nomes %in% nomes_com_valor)
    if (tentativa_com_valor > melhor_com_valor ||
        (tentativa_com_valor == melhor_com_valor && length(tentativa$nomes) > length(colocados$nomes))) {
      colocados = tentativa
      melhor_com_valor = tentativa_com_valor
    }
  }
  colocados
}

# Os campos já colocados que estão noutra alternativa da escolha onde está o campo que sobrou (para a mensagem).
rivais_na_escolha = function(particula, nome, nomes_colocados) {
  if (is.null(particula) || particula$construcao %in% c("element", "any")) {
    return(character())
  }
  rivais = character()
  if (particula$construcao == "choice") {
    alternativa_do_nome = 0
    for (posicao in seq_along(particula$partes)) {
      if (nome %in% nomes_do_modelo(particula$partes[[posicao]])) {
        alternativa_do_nome = posicao
      }
    }
    if (alternativa_do_nome > 0) {
      for (posicao in seq_along(particula$partes)) {
        if (posicao != alternativa_do_nome) {
          nomes_da_alternativa = nomes_do_modelo(particula$partes[[posicao]])
          rivais = c(rivais, nomes_colocados[nomes_colocados %in% nomes_da_alternativa])
        }
      }
    }
  }
  for (parte in particula$partes) {
    rivais = c(rivais, rivais_na_escolha(parte, nome, nomes_colocados))
  }
  unique(rivais)
}

# Os nomes que um modelo aceita direto (sem descer nos grupos de dentro), para a mensagem do campo que não existe.
nomes_do_modelo = function(particula) {
  if (is.null(particula)) {
    return(character())
  }
  if (particula$construcao == "element") {
    return(particula$nome)
  }
  if (particula$construcao == "any") {
    return("o grupo de um dos modais")
  }
  nomes = character()
  for (parte in particula$partes) {
    nomes = c(nomes, nomes_do_modelo(parte))
  }
  nomes
}

# ---- os valores ----

# O texto de cada valor de um campo simples, no formato que o tipo dele aceita: o número com as casas decimais e os
# zeros à esquerda, a data e hora com o fuso. O NA fica de fora; o texto vai como veio, ou, quando é um número com casas
# de menos ou de zeros a mais, com as casas do tipo.
textos_do_valor = function(valor, regras, caminho) {
  if (is.null(valor) || length(valor) == 0) {
    return(character())
  }
  if (is.factor(valor)) {
    valor = as.character(valor)
  }
  if (is.character(valor)) {
    textos = textos_sem_os_espacos_que_o_tipo_recusa(valor, regras)
    if (regras$decimal) {
      textos = textos_numericos_com_as_casas(textos, regras, caminho)
    }
  } else if (inherits(valor, "POSIXt")) {
    textos = textos_da_data_e_hora(valor, regras)
  } else if (inherits(valor, "Date")) {
    textos = format(valor, "%Y-%m-%d")
  } else if (is.numeric(valor)) {
    textos = character(length(valor))
    for (posicao in seq_along(valor)) {
      if (is.na(valor[posicao])) {
        textos[posicao] = NA_character_
      } else {
        textos[posicao] = numero_no_formato_do_tipo(valor[posicao], regras, caminho)
      }
    }
  } else {
    stop("O campo ", caminho, " recebeu um valor do tipo ", class(valor)[1], ": informe um texto, um n\u00famero ou ",
         "uma data.", call. = FALSE)
  }
  textos[!is.na(textos)]
}

# O espaço nas pontas sai só quando o tipo não aceita o texto com ele (o TString da NF-e não aceita; o xNome da NFS-e
# aceita, e a Sefin autorizou notas assim). O texto só de espaços é um texto vazio.
textos_sem_os_espacos_que_o_tipo_recusa = function(textos, regras) {
  sem_espacos = sem_espacos_nas_pontas(textos)
  com_espaco = !is.na(textos) & sem_espacos != textos
  for (posicao in which(com_espaco)) {
    if (sem_espacos[posicao] == "" || !regras_aceitam(textos[posicao], regras)) {
      textos[posicao] = sem_espacos[posicao]
    }
  }
  textos
}

# A data e hora do R: com o fuso (AAAA-MM-DDThh:mm:ss-03:00), ou sem ele, ou só a data, no primeiro que o tipo aceita.
textos_da_data_e_hora = function(valor, regras) {
  com_o_fuso = sub("([+-][0-9]{2})([0-9]{2})$", "\\1:\\2", format(valor, "%Y-%m-%dT%H:%M:%S%z"))
  sem_o_fuso = format(valor, "%Y-%m-%dT%H:%M:%S")
  so_a_data = format(valor, "%Y-%m-%d")
  textos = com_o_fuso
  for (posicao in seq_along(valor)) {
    if (is.na(valor[posicao]) || regras_aceitam(com_o_fuso[posicao], regras)) {
      next
    }
    if (regras_aceitam(sem_o_fuso[posicao], regras)) {
      textos[posicao] = sem_o_fuso[posicao]
    } else if (regras_aceitam(so_a_data[posicao], regras)) {
      textos[posicao] = so_a_data[posicao]
    }
  }
  textos
}

# O número no formato que o tipo aceita. No tipo decimal, as casas que o padrão aceita (a menor quantidade que dá o
# valor exato); o número com mais casas do que o tipo aceita é recusado, sem arredondar (a regra do arredondamento é de
# quem emite). No código, o número inteiro, com os zeros à esquerda que o padrão exige; quando o padrão aceita o número
# com e sem o zero (a IE, o telefone, o GTIN), o número não diz qual é, e é recusado: vai como texto.
numero_no_formato_do_tipo = function(numero, regras, caminho) {
  if (abs(numero) >= MAIOR_NUMERO_EXATO) {
    stop("O campo ", caminho, " recebeu um n\u00famero grande demais para o R guardar sem perder algarismos: informe como ",
         "texto.", call. = FALSE)
  }
  if (regras$decimal) {
    # O caminho curto: a menor quantidade de casas que o tipo aceita num número comum e que dá o valor exato, conferida
    # no padrão uma vez. Se o padrão recusar (o zero num tipo que não aceita zero, por exemplo), as casas são
    # tentadas uma a uma.
    for (casas in regras$casas_aceitas) {
      arredondado = round(numero, casas) + 0
      if (numero_exato(numero, arredondado, casas)) {
        texto = formatC(arredondado, format = "f", digits = casas)
        if (regras_aceitam(texto, regras)) {
          return(texto)
        }
        break
      }
    }
    maior_aceito = NA_integer_
    for (casas in CASAS_DECIMAIS_TENTADAS) {
      arredondado = round(numero, casas) + 0
      texto = formatC(arredondado, format = "f", digits = casas)
      if (regras_aceitam(texto, regras)) {
        if (numero_exato(numero, arredondado, casas)) {
          return(texto)
        }
        maior_aceito = casas
      }
    }
    inteiro = round(numero) + 0
    texto_do_inteiro = formatC(inteiro, format = "f", digits = 0)
    if (numero_exato(numero, inteiro, 0) && regras_aceitam(texto_do_inteiro, regras)) {
      return(texto_do_inteiro)
    }
    if (!is.na(maior_aceito) && algarismos_da_parte_inteira(numero) + maior_aceito > ALGARISMOS_QUE_O_ROUND_CONFERE) {
      stop("O campo ", caminho, " recebeu ", format(numero, digits = 17), ", que passa dos ",
           ALGARISMOS_QUE_O_ROUND_CONFERE, " algarismos que o R confere sem perder nenhum: informe como texto.",
           call. = FALSE)
    }
    if (!is.na(maior_aceito)) {
      stop("O campo ", caminho, " aceita at\u00e9 ", maior_aceito, " casas decimais e recebeu ", format(numero, digits = 16),
           ": arredonde antes (round(valor, ", maior_aceito, ")).", call. = FALSE)
    }
    stop("O campo ", caminho, " n\u00e3o aceita o n\u00famero ", format(numero, digits = 16), " (veja o tipo dele no schema).",
         call. = FALSE)
  }
  if (numero != round(numero)) {
    stop("O campo ", caminho, " n\u00e3o aceita casas decimais e recebeu ", format(numero, digits = 16), ".", call. = FALSE)
  }
  texto = formatC(numero + 0, format = "f", digits = 0)
  # O tipo que não aceita zero à esquerda (o nItem, o nNF) leva o número como ele é; o schema confere no fim.
  if (numero < 0 || !regras$aceita_zero_a_esquerda) {
    return(texto)
  }
  maior_tamanho = 20
  if (!is.na(regras$comprimento_maximo)) {
    maior_tamanho = regras$comprimento_maximo
  }
  candidatos = texto
  if (maior_tamanho > nchar(texto)) {
    for (largura in (nchar(texto) + 1):maior_tamanho) {
      candidatos = c(candidatos, formatC(numero + 0, format = "f", digits = 0, width = largura, flag = "0"))
    }
  }
  aceitos = candidatos[regras_aceitam(candidatos, regras)]
  if (length(aceitos) == 1) {
    return(aceitos)
  }
  # Nenhum: o schema recusa no fim, com a mensagem dele. A quantidade (nos leiautes da SEFAZ, o campo que começa por q
  # e uma maiúscula: qNFe, qVol, qCTe) é um número, e o zero à esquerda nela não quer dizer nada.
  nome_do_campo = sub("^.*/@?", "", caminho)
  e_quantidade = grepl("^q[A-Z]", nome_do_campo)
  if (length(aceitos) == 0 || ((regras$numerica || e_quantidade) && texto %in% aceitos)) {
    return(texto)
  }
  stop("O campo ", caminho, " aceita zeros \u00e0 esquerda (o n\u00famero ", texto, " pode ser \"", aceitos[1], "\" ou \"",
       aceitos[2], "\"): informe como texto.", call. = FALSE)
}

# O número arredondado é o mesmo, a menos da sobra da conta de máquina (0.1 + 0.2 dá 0.30000000000000004): até oito vezes
# a precisão do R, relativa ao tamanho do número, e menos de meia unidade da casa seguinte à última (nos trilhões, a
# precisão do R passa da terceira casa, e o 1234567890123.451 não pode virar 1234567890123.45). Com mais de 15
# algarismos (a parte inteira e as casas), o round() devolve o próprio número: não é exato, e ele vai como texto.
numero_exato = function(numero, arredondado, casas) {
  if (casas > 0 && algarismos_da_parte_inteira(numero) + casas > ALGARISMOS_QUE_O_ROUND_CONFERE) {
    return(FALSE)
  }
  diferenca = abs(numero - arredondado)
  diferenca <= 8 * .Machine$double.eps * max(1, abs(numero)) && diferenca < 10^(-casas) / 20
}

# Os algarismos da parte inteira do número (1 no número menor que 1).
algarismos_da_parte_inteira = function(numero) {
  nchar(formatC(floor(abs(numero)), format = "f", digits = 0))
}

# O número em texto num campo decimal ("10.5" onde o tipo pede duas casas) ganha as casas do tipo quando o valor não
# muda: as casas que passam são zeros, e as que faltam viram zeros, sem conta de máquina. O que o tipo já aceita fica
# como veio (a nota lida volta igual).
textos_numericos_com_as_casas = function(textos, regras, caminho) {
  for (posicao in seq_along(textos)) {
    texto = textos[posicao]
    if (is.na(texto) || !grepl("^-?[0-9]+(\\.[0-9]+)?$", texto)) {
      next
    }
    # O caminho curto: o número que já está numa forma que o tipo aceita fica como veio, sem testar o padrão (o schema
    # confere no fim).
    posicao_do_ponto = regexpr(".", texto, fixed = TRUE)
    casas_do_texto = 0
    if (posicao_do_ponto > 0) {
      casas_do_texto = nchar(texto) - posicao_do_ponto
    }
    forma_aceita = (casas_do_texto == 0 && regras$aceita_inteiro) || casas_do_texto %in% regras$casas_aceitas
    if (forma_aceita || regras_aceitam(texto, regras)) {
      next
    }
    parte_inteira = sub("\\..*$", "", texto)
    parte_decimal = ""
    if (posicao_do_ponto > 0) {
      parte_decimal = substr(texto, posicao_do_ponto + 1, nchar(texto))
    }
    maior_aceito = NA_integer_
    novo_texto = NA_character_
    for (casas in CASAS_DECIMAIS_TENTADAS) {
      if (casas < nchar(parte_decimal)) {
        exato = !grepl("[1-9]", substr(parte_decimal, casas + 1, nchar(parte_decimal)))
        decimais = substr(parte_decimal, 1, casas)
      } else {
        exato = TRUE
        decimais = gsub(" ", "0", formatC(parte_decimal, width = casas, flag = "-"), fixed = TRUE)
      }
      candidato = paste0(parte_inteira, ".", decimais)
      if (regras_aceitam(candidato, regras)) {
        if (exato) {
          novo_texto = candidato
          break
        }
        maior_aceito = casas
      }
    }
    if (is.na(novo_texto) && !grepl("[1-9]", parte_decimal) && regras_aceitam(parte_inteira, regras)) {
      novo_texto = parte_inteira
    }
    if (is.na(novo_texto) && !is.na(maior_aceito)) {
      stop("O campo ", caminho, " aceita at\u00e9 ", maior_aceito, " casas decimais e recebeu ", texto, ": arredonde antes.",
           call. = FALSE)
    }
    if (!is.na(novo_texto)) {
      textos[posicao] = novo_texto
    }
  }
  textos
}

# ---- a conferência no schema oficial ----

# Os erros do schema oficial no documento montado; a falta da assinatura, que o xml_assinar() põe depois, não conta.
# O que entra num xs:any (o modal) é conferido no schema dele. O schema de cada arquivo é lido uma vez.
erros_do_documento_montado = function(xml_montado, schema, nome_da_raiz) {
  documento = tryCatch(xml2::read_xml(xml_montado), error = function(erro) erro)
  if (inherits(documento, "error")) {
    stop("O XML montado n\u00e3o p\u00f4de ser lido: ", conditionMessage(documento), call. = FALSE)
  }
  erros = erros_no_arquivo_do_schema(documento, file.path(schema$pasta, schema$arquivos_principais[1]))
  falta_so_a_assinatura = paste0("^Element '\\{[^}]*\\}", nome_da_raiz, "': Missing child element\\(s\\)\\. Expected is ",
                                 ".*xmldsig#\\}Signature")
  erros = erros[!grepl(falta_so_a_assinatura, erros)]
  for (nome in schema$elementos_dos_outros_principais) {
    for (elemento in xml2::xml_find_all(documento, paste0("//*[local-name()='", nome, "']"))) {
      erros = c(erros, erros_no_arquivo_do_schema(xml2::xml_new_root(elemento),
                                                  file.path(schema$pasta, schema$arquivo_de_cada_elemento[[nome]])))
    }
  }
  gsub("\\{https?://[^}]*\\}", "", erros)
}

erros_no_arquivo_do_schema = function(documento, arquivo_do_schema) {
  nome_no_cache = paste0("validacao:", arquivo_do_schema)
  if (is.null(tabelas_ja_lidas[[nome_no_cache]])) {
    tabelas_ja_lidas[[nome_no_cache]] = xml2::read_xml(arquivo_do_schema)
  }
  resultado = xml2::xml_validate(documento, tabelas_ja_lidas[[nome_no_cache]])
  trimws(attr(resultado, "errors"))
}

# Para quando o documento montado não passa no schema oficial, com os primeiros erros.
parar_se_o_schema_recusar = function(erros) {
  if (length(erros) == 0) {
    return(invisible(NULL))
  }
  primeiros = utils::head(erros, 5)
  if (length(erros) == 1) {
    quantos = "1 erro"
  } else {
    quantos = paste(length(erros), "erros")
  }
  stop("O documento montado n\u00e3o passa no schema oficial (", quantos, "):\n", paste0("- ", primeiros, collapse = "\n"),
       call. = FALSE)
}
