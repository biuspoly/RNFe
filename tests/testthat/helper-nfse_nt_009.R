# A NFS-e de exemplo no leiaute da NT SE/CGNFS-e 009, como o XSD oficial da Produção Restrita (20/10/2026) pede: a
# finalidade no infDPS, logo depois do tpEmit (item 2.2), o CST e a classificação fora do gIBSCBS (item 2.16), a
# dedução do ISSQN no vAjusteBC e o vCalcAjusteBCISSQN (item 2.3). O indDest continua no IBSCBS, como no XSD. Passa na
# validação contra esse XSD (conferido em 10/11/2026). Usada nos testes do nfse_ler() e do danfse_pdf().
nfse_no_leiaute_da_nt_009 = function() {
  arquivo = system.file("exemplos", "nfse_sp_v101.xml", package = "RNFe")
  texto = paste(readLines(arquivo, encoding = "UTF-8"), collapse = "\n")
  texto = trocar_uma_vez(texto, "          <finNFSe>0</finNFSe>\n", "")
  texto = trocar_uma_vez(texto, "        <tpEmit>1</tpEmit>\n", "        <tpEmit>1</tpEmit>\n        <finNFSe>0</finNFSe>\n")
  texto = trocar_uma_vez(texto, paste0("<gIBSCBS>\n                <CST>000</CST>\n                <cClassTrib>000001</cClassTrib>\n",
                                       "              </gIBSCBS>"),
                         "<CST>000</CST>\n              <cClassTrib>000001</cClassTrib>")
  texto = trocar_uma_vez(texto, "          </vServPrest>\n",
                         "          </vServPrest>\n          <vAjusteBC>\n            <vAjusteBCISSQN>100.00</vAjusteBCISSQN>\n          </vAjusteBC>\n")
  trocar_uma_vez(texto, "    <valores>\n      <vBC>", "    <valores>\n      <vCalcAjusteBCISSQN>100.00</vCalcAjusteBCISSQN>\n      <vBC>")
}

# A mesma nota com um destinatário que não é o tomador (indDest 1), com o grupo dest no IBSCBS, como no XSD.
nfse_da_nt_009_com_destinatario = function() {
  trocar_uma_vez(nfse_no_leiaute_da_nt_009(), "          <indDest>0</indDest>\n",
                 paste0("          <indDest>1</indDest>\n          <dest>\n            <CNPJ>11444777000161</CNPJ>\n",
                        "            <xNome>DESTINATARIO DE TESTE</xNome>\n          </dest>\n"))
}

# A mesma nota com o indDest e o dest no infDPS, como o texto do item 2.11 da NT põe (o XSD não aceita): o leitor e o
# DANFSe leem os dois lugares.
nfse_da_nt_009_com_destinatario_no_infdps = function() {
  texto = trocar_uma_vez(nfse_no_leiaute_da_nt_009(), "          <indDest>0</indDest>\n", "")
  trocar_uma_vez(texto, "        </toma>\n",
                 paste0("        </toma>\n        <indDest>1</indDest>\n        <dest>\n          <CNPJ>11444777000161</CNPJ>\n",
                        "          <xNome>DESTINATARIO DE TESTE</xNome>\n        </dest>\n"))
}

# A mesma nota com um imóvel de duas unidades imobiliárias (o gUnidImob da NT 009), cada uma com a sua inscrição.
nfse_da_nt_009_com_imoveis = function() {
  trocar_uma_vez(nfse_no_leiaute_da_nt_009(), "          <indDest>0</indDest>\n",
                 paste0("          <indDest>0</indDest>\n          <imovel>\n            <cMun>3550308</cMun>\n",
                        "            <gUnidImob>\n              <inscImobFisc>0001112223</inscImobFisc>\n",
                        "              <cCIB>12345678</cCIB>\n            </gUnidImob>\n",
                        "            <gUnidImob>\n              <inscImobFisc>0004445556</inscImobFisc>\n",
                        "              <cCIB>87654321</cCIB>\n            </gUnidImob>\n          </imovel>\n"))
}

# Troca um trecho que aparece uma vez só no texto (senão o teste não está mexendo onde pensa).
trocar_uma_vez = function(texto, antes, depois) {
  vezes = lengths(regmatches(texto, gregexpr(antes, texto, fixed = TRUE)))
  if (vezes != 1) {
    stop("o trecho aparece ", vezes, " vezes: ", antes)
  }
  sub(antes, depois, texto, fixed = TRUE)
}
