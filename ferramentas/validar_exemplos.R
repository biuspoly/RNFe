# Confere os documentos de exemplo (inst/exemplos, usados nos testes e na ajuda) contra os schemas
# oficiais que os leitores seguem (ferramentas/schemas_usados.csv). Uso, na raiz do repositório:
#   Rscript ferramentas/validar_exemplos.R
#   Rscript ferramentas/validar_exemplos.R <schema da NF-e> <schema do CT-e> <schema do MDF-e>
# Sem argumentos, baixa os pacotes dos portais (ferramentas/baixar_schemas.R). Com eles, usa as pastas
# dadas: a da NF-e tem o leiauteNFe_v4.00.xsd, a do CT-e o cte_v4.00.xsd e a do MDF-e o mdfe_v3.00.xsd.
# Todo documento nessa pasta tem de passar: documento com defeito de propósito vai como texto dentro do teste.

argumentos = commandArgs(trailingOnly = TRUE)
if (length(argumentos) == 0) {
  source("ferramentas/baixar_schemas.R", encoding = "UTF-8")
  pastas_baixadas = baixar_schemas_usados(file.path(tempdir(), "schemas"))
  argumentos = unname(pastas_baixadas[c("nfe", "cte", "mdfe")])
}
if (length(argumentos) != 3
    || !file.exists(file.path(argumentos[1], "leiauteNFe_v4.00.xsd"))
    || !file.exists(file.path(argumentos[2], "cte_v4.00.xsd"))
    || !file.exists(file.path(argumentos[3], "mdfe_v3.00.xsd"))) {
  stop("Informe a pasta do schema da NF-e (com o leiauteNFe_v4.00.xsd), a do CT-e (com o cte_v4.00.xsd) e a do MDF-e (com o mdfe_v3.00.xsd), ou nada para baixar", call. = FALSE)
}
pasta_do_schema_da_nfe = argumentos[1]
pasta_do_schema_do_cte = argumentos[2]
pasta_do_schema_do_mdfe = argumentos[3]

# Copia a pasta do schema e acrescenta nela um raizes.xsd com as linhas pedidas, para validar o arquivo
# pela raiz que ele tiver.
schema_com_as_raizes = function(pasta_do_schema, nome_da_copia, namespace, linhas_das_raizes) {
  copia_do_schema = file.path(tempdir(), nome_da_copia)
  dir.create(copia_do_schema, showWarnings = FALSE)
  invisible(file.copy(list.files(pasta_do_schema, full.names = TRUE), copia_do_schema, overwrite = TRUE))
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
  } else {
    cat("FALHOU  ", basename(arquivo_de_exemplo), "\n         namespace desconhecido:", namespace_do_documento, "\n")
    passou = FALSE
  }
  todos_passaram = todos_passaram && passou
}
if (!todos_passaram) {
  quit(status = 1)
}
