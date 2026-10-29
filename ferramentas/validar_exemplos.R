# Confere os documentos de exemplo (inst/exemplos, usados nos testes e na ajuda) contra os schemas
# oficiais, os pacotes de liberação baixados do Portal da NF-e e do Portal do CT-e. Uso, na raiz do
# repositório:
#   Rscript ferramentas/validar_exemplos.R <pasta do schema da NF-e> <pasta do schema do CT-e>
# A pasta da NF-e é a que tem o leiauteNFe_v4.00.xsd; a do CT-e, a que tem o cte_v4.00.xsd.
# Todo documento nessa pasta tem de passar: documento com defeito de propósito vai como texto dentro do teste.

argumentos = commandArgs(trailingOnly = TRUE)
if (length(argumentos) != 2
    || !file.exists(file.path(argumentos[1], "leiauteNFe_v4.00.xsd"))
    || !file.exists(file.path(argumentos[2], "cte_v4.00.xsd"))) {
  stop("Informe a pasta do schema da NF-e (com o leiauteNFe_v4.00.xsd) e a do CT-e (com o cte_v4.00.xsd)", call. = FALSE)
}
pasta_do_schema_da_nfe = argumentos[1]
pasta_do_schema_do_cte = argumentos[2]

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

mostrar_resultado = function(nome, resultado) {
  if (resultado) {
    cat("ok      ", nome, "\n")
  } else {
    cat("FALHOU  ", nome, "\n")
    cat(paste0("        ", attr(resultado, "errors"), collapse = "\n"), "\n")
  }
  resultado
}

documentos = list.files("inst/exemplos", pattern = "\\.xml$", full.names = TRUE)
todos_passaram = TRUE
for (arquivo in documentos) {
  documento = xml2::read_xml(arquivo)
  namespace = xml2::xml_ns(documento)[["d1"]]
  if (identical(namespace, "http://www.portalfiscal.inf.br/nfe")) {
    passou = mostrar_resultado(basename(arquivo), xml2::xml_validate(documento, schema_da_nfe))
  } else if (identical(namespace, "http://www.portalfiscal.inf.br/cte")) {
    passou = mostrar_resultado(basename(arquivo), xml2::xml_validate(documento, schema_do_cte))
    for (modal in xml2::xml_find_all(documento, "//d1:infModal/*", xml2::xml_ns(documento))) {
      so_o_modal = xml2::xml_new_root(modal)
      nome = paste0(basename(arquivo), " (modal ", xml2::xml_name(modal), ")")
      passou = mostrar_resultado(nome, xml2::xml_validate(so_o_modal, schema_do_cte)) && passou
    }
  } else {
    cat("FALHOU  ", basename(arquivo), "\n         namespace desconhecido:", namespace, "\n")
    passou = FALSE
  }
  todos_passaram = todos_passaram && passou
}
if (!todos_passaram) {
  quit(status = 1)
}
