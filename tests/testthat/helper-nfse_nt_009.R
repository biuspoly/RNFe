# A NFS-e de exemplo com os campos que a NT SE/CGNFS-e 009 mudou de lugar: a finalidade (item 2.2) e o indDest
# (item 2.11) no infDPS, o CST e a classificação fora do gIBSCBS (item 2.16), a dedução do ISSQN no vAjusteBC e o
# vCalcAjusteBCISSQN (item 2.3). Usada nos testes do nfse_ler() e do danfse_pdf().
nfse_no_leiaute_da_nt_009 = function() {
  arquivo = system.file("exemplos", "nfse_sp_v101.xml", package = "RNFe")
  texto = paste(readLines(arquivo, encoding = "UTF-8"), collapse = "\n")
  texto = trocar_uma_vez(texto, "          <finNFSe>0</finNFSe>\n", "")
  texto = trocar_uma_vez(texto, "          <indDest>0</indDest>\n", "")
  texto = trocar_uma_vez(texto, "        </toma>\n", "        </toma>\n        <indDest>0</indDest>\n")
  texto = trocar_uma_vez(texto, "        </valores>\n        <IBSCBS>", "        </valores>\n        <finNFSe>0</finNFSe>\n        <IBSCBS>")
  texto = trocar_uma_vez(texto, paste0("<gIBSCBS>\n                <CST>000</CST>\n                <cClassTrib>000001</cClassTrib>\n",
                                       "              </gIBSCBS>"),
                         "<CST>000</CST>\n              <cClassTrib>000001</cClassTrib>")
  texto = trocar_uma_vez(texto, "          </vServPrest>\n",
                         "          </vServPrest>\n          <vAjusteBC>\n            <vAjusteBCISSQN>100.00</vAjusteBCISSQN>\n          </vAjusteBC>\n")
  trocar_uma_vez(texto, "    <valores>\n      <vBC>", "    <valores>\n      <vCalcAjusteBCISSQN>100.00</vCalcAjusteBCISSQN>\n      <vBC>")
}

# Troca um trecho que aparece uma vez só no texto (senão o teste não está mexendo onde pensa).
trocar_uma_vez = function(texto, antes, depois) {
  vezes = lengths(regmatches(texto, gregexpr(antes, texto, fixed = TRUE)))
  if (vezes != 1) {
    stop("o trecho aparece ", vezes, " vezes: ", antes)
  }
  sub(antes, depois, texto, fixed = TRUE)
}
