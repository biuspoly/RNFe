CERTIFICADO_DO_QRCODE = test_path("certificados", "pessoa_juridica.pfx")
NFCE_DE_CONTINGENCIA = system.file("exemplos", "nfce_ce_contingencia.xml", package = "RNFe")
ENDERECO_DO_QRCODE = "https://nfce.exemplo.invalid/qrcode"
ENDERECO_DA_CONSULTA = "https://nfce.exemplo.invalid/consulta"

texto_do_grupo = function(texto, campo) {
  xml2::xml_text(xml2::xml_find_first(xml2::read_xml(texto), paste0("//*[local-name()='", campo, "']")))
}

test_that("na conting\u00eancia off-line, os sete par\u00e2metros e a assinatura deles com o certificado", {
  skip_if_not_installed("openssl")
  com_qrcode = nfce_qrcode(NFCE_DE_CONTINGENCIA, ENDERECO_DO_QRCODE, ENDERECO_DA_CONSULTA, CERTIFICADO_DO_QRCODE, "teste")
  qrcode = texto_do_grupo(com_qrcode, "qrCode")
  parametros = "23261011444777000161650030000000779135724686|3|2|21|35.00||"
  expect_identical(substr(qrcode, 1, nchar(ENDERECO_DO_QRCODE) + 3 + nchar(parametros)),
                   paste0(ENDERECO_DO_QRCODE, "?p=", parametros))
  assinatura = sub(".*\\|", "", qrcode)
  certificado = openssl::read_p12(CERTIFICADO_DO_QRCODE, password = "teste")$cert
  expect_true(openssl::signature_verify(charToRaw(parametros), openssl::base64_decode(assinatura), hash = openssl::sha1,
                                        pubkey = certificado$pubkey))
  expect_identical(texto_do_grupo(com_qrcode, "urlChave"), ENDERECO_DA_CONSULTA)
  # O grupo antigo sai, e o novo fica entre o infNFe e a assinatura, no padrão do schema.
  nota = xml2::xml_find_first(xml2::read_xml(com_qrcode), "//*[local-name()='NFe']")
  expect_identical(xml2::xml_name(xml2::xml_children(nota)), c("infNFe", "infNFeSupl", "Signature"))
  conferida = nfe_conferir(com_qrcode)
  expect_true(conferida$notas$schema_valido)
  expect_equal(nrow(conferida$schema), 0)
})

test_that("o destinat\u00e1rio entra no QR-Code da conting\u00eancia: 1 e o CNPJ, 2 e o CPF, 3 e vazio", {
  skip_if_not_installed("openssl")
  texto = paste(readLines(NFCE_DE_CONTINGENCIA, encoding = "UTF-8"), collapse = "\n")
  com_cpf = sub("</emit>", "</emit><dest><CPF>12345678909</CPF></dest>", texto, fixed = TRUE)
  expect_match(texto_do_grupo(nfce_qrcode(com_cpf, ENDERECO_DO_QRCODE, ENDERECO_DA_CONSULTA, CERTIFICADO_DO_QRCODE, "teste"),
                              "qrCode"), "\\|21\\|35\\.00\\|2\\|12345678909\\|")
  com_cnpj = sub("</emit>", "</emit><dest><CNPJ>11222333000181</CNPJ></dest>", texto, fixed = TRUE)
  expect_match(texto_do_grupo(nfce_qrcode(com_cnpj, ENDERECO_DO_QRCODE, ENDERECO_DA_CONSULTA, CERTIFICADO_DO_QRCODE, "teste"),
                              "qrCode"), "\\|35\\.00\\|1\\|11222333000181\\|")
  estrangeiro = sub("</emit>", "</emit><dest><idEstrangeiro>AB123</idEstrangeiro></dest>", texto, fixed = TRUE)
  expect_match(texto_do_grupo(nfce_qrcode(estrangeiro, ENDERECO_DO_QRCODE, ENDERECO_DA_CONSULTA, CERTIFICADO_DO_QRCODE,
                                          "teste"), "qrCode"), "\\|35\\.00\\|3\\|\\|")
})

test_that("na emiss\u00e3o normal, s\u00f3 a chave, a vers\u00e3o e o ambiente, sem certificado", {
  texto = paste(readLines(NFCE_DE_CONTINGENCIA, encoding = "UTF-8"), collapse = "\n")
  # A mesma nota em emissão normal: a forma de emissão muda também na chave (a posição 35) e no dígito.
  normal = sub("<tpEmis>9</tpEmis>", "<tpEmis>1</tpEmis>", texto, fixed = TRUE)
  normal = gsub("23261011444777000161650030000000779135724686", "23261011444777000161650030000000771135724680", normal,
                fixed = TRUE)
  normal = sub("<cDV>6</cDV>", "<cDV>0</cDV>", normal, fixed = TRUE)
  com_qrcode = nfce_qrcode(normal, paste0(ENDERECO_DO_QRCODE, "?"), ENDERECO_DA_CONSULTA)
  expect_identical(texto_do_grupo(com_qrcode, "qrCode"),
                   paste0(ENDERECO_DO_QRCODE, "?p=23261011444777000161650030000000771135724680|3|2"))
})

test_that("os erros: sem certificado na conting\u00eancia, a NF-e e o endere\u00e7o sem http", {
  expect_error(nfce_qrcode(NFCE_DE_CONTINGENCIA, ENDERECO_DO_QRCODE, ENDERECO_DA_CONSULTA), "certificado e a senha")
  expect_error(nfce_qrcode(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), ENDERECO_DO_QRCODE,
                           ENDERECO_DA_CONSULTA), "modelo 65")
  expect_error(nfce_qrcode(NFCE_DE_CONTINGENCIA, "nfce.exemplo.invalid", ENDERECO_DA_CONSULTA), "http")
})
