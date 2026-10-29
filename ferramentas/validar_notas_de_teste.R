# Confere as notas de exemplo (inst/exemplos, usadas nos testes e na ajuda) contra o schema oficial
# da NF-e, o pacote de liberação baixado do Portal da NF-e. Uso, na raiz do repositório:
#   Rscript ferramentas/validar_notas_de_teste.R <pasta com o leiauteNFe_v4.00.xsd>
# Toda nota nessa pasta tem de passar: nota com defeito de propósito vai como texto dentro do teste.

argumentos = commandArgs(trailingOnly = TRUE)
if (length(argumentos) != 1 || !file.exists(file.path(argumentos[1], "leiauteNFe_v4.00.xsd"))) {
  stop("Informe a pasta do schema que tem o leiauteNFe_v4.00.xsd", call. = FALSE)
}

# O pacote de liberação só declara o NFe como raiz. O nfeProc (a nota com o protocolo de
# autorização) é declarado aqui, numa cópia do schema, para validar o arquivo inteiro.
copia_do_schema = file.path(tempdir(), "schema_nfe")
dir.create(copia_do_schema, showWarnings = FALSE)
invisible(file.copy(list.files(argumentos[1], full.names = TRUE), copia_do_schema, overwrite = TRUE))
writeLines(c(
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.portalfiscal.inf.br/nfe"',
  '  targetNamespace="http://www.portalfiscal.inf.br/nfe" elementFormDefault="qualified" attributeFormDefault="unqualified">',
  '  <xs:include schemaLocation="leiauteNFe_v4.00.xsd"/>',
  '  <xs:element name="NFe" type="TNFe"/>',
  '  <xs:element name="nfeProc" type="TNfeProc"/>',
  '</xs:schema>'
), file.path(copia_do_schema, "raizes.xsd"))
schema = xml2::read_xml(file.path(copia_do_schema, "raizes.xsd"))

notas = list.files("inst/exemplos", pattern = "\\.xml$", full.names = TRUE)
todas_passaram = TRUE
for (nota in notas) {
  resultado = xml2::xml_validate(xml2::read_xml(nota), schema)
  if (resultado) {
    cat("ok      ", basename(nota), "\n")
  } else {
    todas_passaram = FALSE
    cat("FALHOU  ", basename(nota), "\n")
    cat(paste0("        ", attr(resultado, "errors"), collapse = "\n"), "\n")
  }
}
if (!todas_passaram) {
  quit(status = 1)
}
