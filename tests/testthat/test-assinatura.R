CERTIFICADO_DA_ASSINATURA = test_path("certificados", "pessoa_juridica.pfx")

valor_no_xml = function(texto, campo) {
  xml2::xml_text(xml2::xml_find_first(xml2::read_xml(texto), paste0("//*[local-name()='", campo, "']")))
}

test_that("a assinatura da NF-e sai igual \u00e0 do PyNFe", {
  skip_if_not_installed("openssl")
  # O PyNFe 0.6.5 assinou o mesmo XML (sem a assinatura de mentira) com o mesmo certificado em 05/11/2026 e deu o
  # mesmo resumo e a mesma assinatura. O exemplo não tem acento: o PyNFe tira os acentos antes de assinar.
  assinada = xml_assinar(system.file("exemplos", "nfe_ce_simples_cpf.xml", package = "RNFe"), CERTIFICADO_DA_ASSINATURA,
                         "teste")
  expect_identical(valor_no_xml(assinada, "DigestValue"), "Ywt9NO+1/P+62NVWMHZHTS3KiQM=")
  expect_match(valor_no_xml(assinada, "SignatureValue"), "^TrxIxvxGhPDMqgmtJidyZViqBzatSUVuNuWVvGhnK5hOVt1BuDqq")
  expect_match(valor_no_xml(assinada, "SignatureValue"), "DWEYug49UWqqIA==$")
})

test_that("a assinatura confere com a chave p\u00fablica do certificado e substitui a antiga", {
  skip_if_not_installed("openssl")
  assinada = xml_assinar(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), CERTIFICADO_DA_ASSINATURA, "teste")
  documento = xml2::read_xml(assinada)
  expect_length(xml2::xml_find_all(documento, "//*[local-name()='Signature']"), 1)
  # A assinatura é o último filho da NFe, depois do infNFe.
  filhos = xml2::xml_name(xml2::xml_children(xml2::xml_find_first(documento, "//*[local-name()='NFe']")))
  expect_identical(filhos, c("infNFe", "Signature"))
  informacao = xml_canonico(xml2::xml_find_first(documento, "//*[local-name()='SignedInfo']"))
  expect_match(informacao, '^<SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#"><CanonicalizationMethod')
  certificado = openssl::read_p12(CERTIFICADO_DA_ASSINATURA, password = "teste")$cert
  valor = openssl::base64_decode(valor_no_xml(assinada, "SignatureValue"))
  expect_true(openssl::signature_verify(charToRaw(enc2utf8(informacao)), valor, hash = openssl::sha1, pubkey = certificado$pubkey))
  resumo = openssl::base64_encode(openssl::sha1(charToRaw(enc2utf8(xml_canonico(
    xml2::xml_find_first(documento, "//*[local-name()='infNFe']"))))))
  expect_identical(valor_no_xml(assinada, "DigestValue"), resumo)
  expect_identical(valor_no_xml(assinada, "X509Certificate"), openssl::base64_encode(openssl::write_der(certificado)))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(documento, "//*[local-name()='Reference']"), "URI"),
                   "#NFe35261011222333000181550010000010011123456785")
  # Sem espaço entre as tags (a SEFAZ rejeita o XML formatado) e sem quebra de linha no fim.
  expect_false(grepl(">\\s+<", sub("^<\\?xml[^>]*\\?>\\s*(<!--.*?-->\\s*)*", "", assinada, perl = TRUE)))
  expect_false(grepl("\\s$", assinada))
})

test_that("a forma can\u00f4nica: o namespace onde muda, os atributos em ordem, os escapes e a tag vazia aberta e fechada", {
  documento = xml2::read_xml('<a xmlns="urn:x"><b z="1" a="&quot;&lt;" xmlns="urn:x">t&amp;x&gt;<c/></b></a>')
  b = xml2::xml_find_first(documento, "//*[local-name()='b']")
  expect_identical(xml_canonico(b), '<b xmlns="urn:x" a="&quot;&lt;" z="1">t&amp;x&gt;<c></c></b>')
  # No meio do documento, o namespace que não muda não se repete.
  expect_identical(xml_canonico(xml2::xml_root(documento)),
                   '<a xmlns="urn:x"><b a="&quot;&lt;" z="1">t&amp;x&gt;<c></c></b></a>')
  expect_identical(escapar_atributo_canonico("a\tb\nc\rd"), "a&#x9;b&#xA;c&#xD;d")
})

test_that("a DPS da NFS-e Nacional vai com o SHA-256, e o evento com o SHA-1", {
  skip_if_not_installed("openssl")
  dps = paste0('<DPS xmlns="http://www.sped.fazenda.gov.br/nfse" versao="1.01"><infDPS Id="DPS230440021122233300018100',
               '9000000000000001"><tpAmb>2</tpAmb></infDPS></DPS>')
  assinada = xml_assinar(dps, CERTIFICADO_DA_ASSINATURA, "teste")
  documento = xml2::read_xml(assinada)
  algoritmo_da_assinatura = xml2::xml_attr(xml2::xml_find_first(documento, "//*[local-name()='SignatureMethod']"), "Algorithm")
  algoritmo_do_resumo = xml2::xml_attr(xml2::xml_find_first(documento, "//*[local-name()='DigestMethod']"), "Algorithm")
  expect_identical(algoritmo_da_assinatura, "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")
  expect_identical(algoritmo_do_resumo, "http://www.w3.org/2001/04/xmlenc#sha256")
  evento = xml_assinar(system.file("exemplos", "evento_nfe_cancelamento.xml", package = "RNFe"), CERTIFICADO_DA_ASSINATURA,
                       "teste")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(xml2::read_xml(evento), "//*[local-name()='SignatureMethod']"),
                                  "Algorithm"), "http://www.w3.org/2000/09/xmldsig#rsa-sha1")
})

test_that("os erros: a senha errada, o XML sem documento que se assina e o elemento sem Id", {
  skip_if_not_installed("openssl")
  expect_error(xml_assinar(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"), CERTIFICADO_DA_ASSINATURA, "errada"),
               "senha")
  expect_error(xml_assinar("<qualquer/>", CERTIFICADO_DA_ASSINATURA, "teste"), "n\u00e3o tem um documento")
  expect_error(xml_assinar('<NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe versao="4.00"/></NFe>',
                           CERTIFICADO_DA_ASSINATURA, "teste"), "Id")
  expect_error(xml_assinar("nao_existe.xml", CERTIFICADO_DA_ASSINATURA, "teste"), "n\u00e3o encontrado")
})
