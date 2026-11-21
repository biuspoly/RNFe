# Os erros do schema da NF-e (o nfe_v4.00.xsd do pacote) no elemento NFe de um XML já assinado, dentro ou não do
# nfeProc; vazio quando ele passa.
erros_do_schema_da_nfe = function(xml) {
  nota = xml2::xml_find_first(xml2::read_xml(xml), "//*[local-name()='NFe']")
  erros_no_arquivo_do_schema(xml2::xml_new_root(nota), system.file("schemas", "nfe", "nfe_v4.00.xsd", package = "RNFe"))
}
