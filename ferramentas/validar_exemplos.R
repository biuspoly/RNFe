# Confere os documentos de exemplo (inst/exemplos, usados nos testes e na ajuda) contra os schemas
# oficiais que os leitores seguem (ferramentas/schemas_usados.csv). Uso, na raiz do repositório:
#   Rscript ferramentas/validar_exemplos.R
#   Rscript ferramentas/validar_exemplos.R <schema da NF-e> <schema do CT-e> <schema do MDF-e> <schema da NFS-e>
# Sem argumentos, baixa os pacotes dos portais (ferramentas/baixar_schemas.R). Com eles, usa as pastas
# dadas: a da NF-e tem o leiauteNFe_v4.00.xsd, a do CT-e o cte_v4.00.xsd, a do MDF-e o mdfe_v3.00.xsd e a da
# NFS-e o NFSe_v1.01.xsd (a pasta da versão 1.00 fica ao lado dela, no mesmo pacote).
# Todo documento nessa pasta tem de passar: documento com defeito de propósito vai como texto dentro do teste.

argumentos = commandArgs(trailingOnly = TRUE)
if (length(argumentos) == 0) {
  source("ferramentas/baixar_schemas.R", encoding = "UTF-8")
  pastas_baixadas = baixar_schemas_usados(file.path(tempdir(), "schemas"))
  argumentos = unname(pastas_baixadas[c("nfe", "cte", "mdfe", "nfse")])
}
if (length(argumentos) != 4
    || !file.exists(file.path(argumentos[1], "leiauteNFe_v4.00.xsd"))
    || !file.exists(file.path(argumentos[2], "cte_v4.00.xsd"))
    || !file.exists(file.path(argumentos[3], "mdfe_v3.00.xsd"))
    || !file.exists(file.path(argumentos[4], "NFSe_v1.01.xsd"))) {
  stop("Informe a pasta do schema da NF-e (com o leiauteNFe_v4.00.xsd), a do CT-e (com o cte_v4.00.xsd), a do MDF-e (com o mdfe_v3.00.xsd) e a da NFS-e (com o NFSe_v1.01.xsd), ou nada para baixar", call. = FALSE)
}
pasta_do_schema_da_nfe = argumentos[1]
pasta_do_schema_do_cte = argumentos[2]
pasta_do_schema_do_mdfe = argumentos[3]
pasta_do_schema_da_nfse = argumentos[4]

# Copia a pasta do schema e acrescenta nela um raizes.xsd com as linhas pedidas, para validar o arquivo
# pela raiz que ele tiver.
schema_com_as_raizes = function(pasta_do_schema, nome_da_copia, namespace, linhas_das_raizes, tirar_ancoras = FALSE) {
  copia_do_schema = file.path(tempdir(), nome_da_copia)
  dir.create(copia_do_schema, showWarnings = FALSE)
  invisible(file.copy(list.files(pasta_do_schema, full.names = TRUE), copia_do_schema, overwrite = TRUE))
  # O schema da NFS-e escreve um padrão como "^0{0,4}\d{1,5}$" (o da série da DPS). No padrão XML Schema o "^" e
  # o "$" são letras, não início e fim, e o libxml2 recusaria até a série "1". O padrão XML Schema já compara o
  # valor inteiro, então tirar os dois dá a regra que o portal quis escrever.
  if (tirar_ancoras) {
    for (arquivo_xsd in list.files(copia_do_schema, pattern = "\\.xsd$", full.names = TRUE)) {
      texto_do_xsd = readLines(arquivo_xsd, encoding = "UTF-8", warn = FALSE)
      texto_do_xsd = gsub('(<xs:pattern value=")\\^([^"]*)\\$("\\s*/>)', "\\1\\2\\3", texto_do_xsd)
      writeLines(texto_do_xsd, arquivo_xsd, useBytes = TRUE)
    }
  }
  writeLines(c(
    '<?xml version="1.0" encoding="UTF-8"?>',
    paste0('<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="', namespace, '"'),
    paste0('  targetNamespace="', namespace, '" elementFormDefault="qualified" attributeFormDefault="unqualified">'),
    linhas_das_raizes,
    '</xs:schema>'
  ), file.path(copia_do_schema, "raizes.xsd"))
  xml2::read_xml(file.path(copia_do_schema, "raizes.xsd"))
}

# O pacote da NF-e só declara o NFe como raiz. O nfeProc (a nota com o protocolo de autorização) é
# declarado aqui.
schema_da_nfe = schema_com_as_raizes(pasta_do_schema_da_nfe, "schema_nfe", "http://www.portalfiscal.inf.br/nfe", c(
  '  <xs:include schemaLocation="leiauteNFe_v4.00.xsd"/>',
  '  <xs:element name="NFe" type="TNFe"/>',
  '  <xs:element name="nfeProc" type="TNfeProc"/>'
))

# O pacote do CT-e declara cada raiz num arquivo: o CTe e o CTeOS, o cteProc e o cteOSProc (com o
# protocolo) e o rodo e o rodoOS (o modal rodoviário). O infModal aceita qualquer coisa sem conferir,
# então o modal é validado à parte.
schema_do_cte = schema_com_as_raizes(pasta_do_schema_do_cte, "schema_cte", "http://www.portalfiscal.inf.br/cte", c(
  '  <xs:include schemaLocation="cte_v4.00.xsd"/>',
  '  <xs:include schemaLocation="procCTe_v4.00.xsd"/>',
  '  <xs:include schemaLocation="cteOS_v4.00.xsd"/>',
  '  <xs:include schemaLocation="procCTeOS_v4.00.xsd"/>',
  '  <xs:include schemaLocation="cteModalRodoviario_v4.00.xsd"/>',
  '  <xs:include schemaLocation="cteModalRodoviarioOS_v4.00.xsd"/>'
))

# O pacote do MDF-e declara o MDFe, o mdfeProc (com o protocolo) e o rodo do MDF-e, que também é
# validado à parte.
schema_do_mdfe = schema_com_as_raizes(pasta_do_schema_do_mdfe, "schema_mdfe", "http://www.portalfiscal.inf.br/mdfe", c(
  '  <xs:include schemaLocation="mdfe_v3.00.xsd"/>',
  '  <xs:include schemaLocation="procMDFe_v3.00.xsd"/>',
  '  <xs:include schemaLocation="mdfeModalRodoviario_v3.00.xsd"/>'
))

# O pacote da NFS-e traz um schema por versão do leiaute (1.00 e 1.01), cada um na sua pasta. A NFS-e é
# validada pelo da versão que ela declara no atributo versao.
schema_de_cada_versao_da_nfse = list()
arquivos_nfse_do_pacote = list.files(dirname(pasta_do_schema_da_nfse), pattern = "^NFSe_v[0-9.]+\\.xsd$", recursive = TRUE, full.names = TRUE)
for (arquivo_nfse in arquivos_nfse_do_pacote) {
  versao_do_leiaute = sub("^NFSe_v([0-9.]+)\\.xsd$", "\\1", basename(arquivo_nfse))
  schema_de_cada_versao_da_nfse[[versao_do_leiaute]] = schema_com_as_raizes(
    dirname(arquivo_nfse), paste0("schema_nfse_", versao_do_leiaute), "http://www.sped.fazenda.gov.br/nfse",
    paste0('  <xs:include schemaLocation="', basename(arquivo_nfse), '"/>'), tirar_ancoras = TRUE
  )
}

mostrar_resultado = function(nome_do_que_foi_validado, resultado_da_validacao) {
  if (resultado_da_validacao) {
    cat("ok      ", nome_do_que_foi_validado, "\n")
  } else {
    cat("FALHOU  ", nome_do_que_foi_validado, "\n")
    cat(paste0("        ", attr(resultado_da_validacao, "errors"), collapse = "\n"), "\n")
  }
  resultado_da_validacao
}

# O documento inteiro e, depois, cada modal sozinho, contra o mesmo schema.
validar_com_o_modal = function(arquivo_de_exemplo, documento_lido, schema) {
  passou = mostrar_resultado(basename(arquivo_de_exemplo), xml2::xml_validate(documento_lido, schema))
  for (grupo_do_modal in xml2::xml_find_all(documento_lido, "//d1:infModal/*", xml2::xml_ns(documento_lido))) {
    so_o_modal = xml2::xml_new_root(grupo_do_modal)
    nome_do_modal = paste0(basename(arquivo_de_exemplo), " (modal ", xml2::xml_name(grupo_do_modal), ")")
    passou = mostrar_resultado(nome_do_modal, xml2::xml_validate(so_o_modal, schema)) && passou
  }
  passou
}

arquivos_de_exemplo = list.files("inst/exemplos", pattern = "\\.xml$", full.names = TRUE)
todos_passaram = TRUE
for (arquivo_de_exemplo in arquivos_de_exemplo) {
  documento_lido = xml2::read_xml(arquivo_de_exemplo)
  namespace_do_documento = xml2::xml_ns(documento_lido)[["d1"]]
  if (identical(namespace_do_documento, "http://www.portalfiscal.inf.br/nfe")) {
    passou = mostrar_resultado(basename(arquivo_de_exemplo), xml2::xml_validate(documento_lido, schema_da_nfe))
  } else if (identical(namespace_do_documento, "http://www.portalfiscal.inf.br/cte")) {
    passou = validar_com_o_modal(arquivo_de_exemplo, documento_lido, schema_do_cte)
  } else if (identical(namespace_do_documento, "http://www.portalfiscal.inf.br/mdfe")) {
    passou = validar_com_o_modal(arquivo_de_exemplo, documento_lido, schema_do_mdfe)
  } else if (identical(namespace_do_documento, "http://www.sped.fazenda.gov.br/nfse")) {
    versao_do_leiaute = xml2::xml_attr(xml2::xml_root(documento_lido), "versao")
    nome_com_a_versao = paste0(basename(arquivo_de_exemplo), " (leiaute ", versao_do_leiaute, ")")
    if (is.null(schema_de_cada_versao_da_nfse[[versao_do_leiaute]])) {
      cat("FALHOU  ", nome_com_a_versao, "\n         o pacote não tem o schema dessa versão\n")
      passou = FALSE
    } else {
      passou = mostrar_resultado(nome_com_a_versao, xml2::xml_validate(documento_lido, schema_de_cada_versao_da_nfse[[versao_do_leiaute]]))
    }
  } else {
    cat("FALHOU  ", basename(arquivo_de_exemplo), "\n         namespace desconhecido:", namespace_do_documento, "\n")
    passou = FALSE
  }
  todos_passaram = todos_passaram && passou
}
if (!todos_passaram) {
  quit(status = 1)
}
