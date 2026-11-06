NFSE_DE_SAO_PAULO = system.file("exemplos", "nfse_prefeitura_sp.xml", package = "RNFe")
NFSE_DA_ABRASF_1 = system.file("exemplos", "nfse_prefeitura_abrasf1.xml", package = "RNFe")
NFSE_DA_ABRASF_2 = system.file("exemplos", "nfse_prefeitura_abrasf2.xml", package = "RNFe")

test_that("o leiaute de S\u00e3o Paulo: a nota, o status, a fra\u00e7\u00e3o da al\u00edquota e os c\u00f3digos", {
  lida = nfse_prefeitura_ler(NFSE_DE_SAO_PAULO)
  nota = lida$nfses
  expect_identical(nrow(nota), 1L)
  expect_identical(nota$leiaute, "S\u00e3o Paulo")
  expect_identical(nota$numero, "4321")
  expect_identical(nota$codigo_verificacao, "ABCD1234")
  expect_identical(nota$chave_nacional, "35503082211222333000181000000000432126101234567893")
  expect_identical(nota$identificacao, "11222333000181-4321-ABCD1234")
  expect_identical(nota$prestador_documento, "11222333000181")
  expect_identical(nota$prestador_inscricao_municipal, "12345678")
  expect_identical(nota$tomador_documento, "11444777000161")
  expect_identical(nota$tomador_codigo_municipio, "3304557")
  # A hora como está no XML (sem o fuso); a data, como data.
  expect_identical(nota$emissao, "2026-10-15T10:30:00")
  expect_identical(nota$data_emissao, as.Date("2026-10-15"))
  expect_identical(nota$competencia, as.Date("2026-10-15"))
  expect_identical(nota$situacao, "Cancelada")
  expect_identical(nota$cancelamento, "2026-10-16T09:00:00")
  expect_identical(nota$tributacao_descricao, "Tributado em S\u00e3o Paulo")
  expect_identical(nota$optante_simples_descricao, "Optante pelo Simples Nacional - DAS")
  # O CodigoServico de São Paulo é o da tabela do município; o item da LC 116 só a ABRASF traz.
  expect_identical(nota$codigo_tributacao_municipio, "2658")
  expect_true(is.na(nota$item_lista_servico))
  expect_identical(nota$municipio_prestacao, "3550308")
  expect_identical(nota$rps_tipo_descricao, "Recibo Provis\u00f3rio de Servi\u00e7os")
  expect_identical(nota$valor_servicos, 1000)
  expect_identical(nota$valor_iss, 45)
  expect_true(nota$iss_retido)
  # São Paulo manda a fração: 0,05 é 5%.
  expect_identical(nota$aliquota, 0.05)
  expect_identical(nota$aliquota_percentual, 5)
  expect_identical(nota$nbs, "101010100")
  expect_true(is.na(nota$valor_liquido))
  expect_true(any(lida$campos$campo == "ValorFinalCobrado"))
  expect_true(all(lida$campos$identificacao == nota$identificacao))
  # A Assinatura de São Paulo é a assinatura digital da NFS-e: fica fora dos campos.
  expect_false("Assinatura" %in% lida$campos$campo)
})

# O texto de um dos XMLs de exemplo, sem a declaração do XML, para montar as variações.
texto_do_exemplo = function(arquivo) {
  linhas = readLines(arquivo, encoding = "UTF-8")
  paste(linhas[!startsWith(linhas, "<?xml")], collapse = "\n")
}

test_that("S\u00e3o Paulo: o ISS retido em 0 e 1, a op\u00e7\u00e3o pelo Simples do schema v02 e o cLocPrestacao", {
  texto = texto_do_exemplo(NFSE_DE_SAO_PAULO)
  sem_retencao = sub("<ISSRetido>true</ISSRetido>", "<ISSRetido>0</ISSRetido>", texto, fixed = TRUE)
  sem_retencao = sub("<OpcaoSimples>4</OpcaoSimples>", "<OpcaoSimples>6</OpcaoSimples>", sem_retencao, fixed = TRUE)
  nota = nfse_prefeitura_ler(sem_retencao)$nfses
  expect_false(nota$iss_retido)
  expect_identical(nota$optante_simples_descricao, "Optante pelo Simples Nacional - DAMSP")
  com_retencao = sub("<ISSRetido>true</ISSRetido>", "<ISSRetido>1</ISSRetido>", texto, fixed = TRUE)
  com_retencao = sub("<OpcaoSimples>4</OpcaoSimples>", "<OpcaoSimples>0</OpcaoSimples>", com_retencao, fixed = TRUE)
  nota = nfse_prefeitura_ler(com_retencao)$nfses
  expect_true(nota$iss_retido)
  expect_identical(nota$optante_simples_descricao, "N\u00e3o-optante pelo Simples Federal nem Municipal")
  # Na Reforma, o município da prestação pode vir no cLocPrestacao.
  local_da_reforma = gsub("MunicipioPrestacao", "cLocPrestacao", texto, fixed = TRUE)
  expect_identical(nfse_prefeitura_ler(local_da_reforma)$nfses$municipio_prestacao, "3550308")
})

test_that("a ABRASF 1.00 do Ginfes, com prefixo no namespace", {
  nota = nfse_prefeitura_ler(NFSE_DA_ABRASF_1)$nfses
  expect_identical(nota$leiaute, "ABRASF 1")
  expect_identical(nota$numero, "202600000000123")
  expect_identical(nota$prestador_documento, "11444777000161")
  expect_identical(nota$tomador_documento, "11222333000181")
  expect_identical(nota$municipio_gerador, "2304400")
  expect_identical(nota$natureza_operacao_descricao, "Tributa\u00e7\u00e3o no munic\u00edpio")
  expect_identical(nota$regime_especial_descricao, "Sociedade de Profissionais")
  expect_identical(nota$optante_simples_descricao, "N\u00e3o")
  expect_identical(nota$competencia, as.Date("2026-10-01"))
  expect_identical(nota$item_lista_servico, "1401")
  expect_identical(nota$codigo_tributacao_municipio, "140101")
  expect_identical(nota$incentivador_cultural_descricao, "N\u00e3o")
  expect_true(is.na(nota$incentivo_fiscal))
  expect_identical(nota$valor_liquido, 500)
  expect_false(nota$iss_retido)
  # A ABRASF 1.00 não diz a escala da alíquota: fica como veio, e o percentual, NA.
  expect_identical(nota$aliquota, 0.02)
  expect_true(is.na(nota$aliquota_percentual))
  # Sem o CompNfse, o XML não diz se a nota foi cancelada.
  expect_true(is.na(nota$situacao))
  campos = nfse_prefeitura_ler(NFSE_DA_ABRASF_1)$campos
  expect_true("Servico/Valores/ValorServicos" %in% campos$caminho)
  expect_false(any(grepl(":", campos$caminho, fixed = TRUE)))
})

test_that("ABRASF 1.00: a compet\u00eancia em AAAAMM, o formato que n\u00e3o \u00e9 data e o cancelamento no CompNfse", {
  texto = texto_do_exemplo(NFSE_DA_ABRASF_1)
  em_mes_e_ano = sub("2026-10-01T00:00:00", "202610", texto, fixed = TRUE)
  em_outro_formato = sub("2026-10-01T00:00:00", "01/10/2026", texto, fixed = TRUE)
  # O formato que não é data, mesmo no primeiro arquivo, não para a leitura: fica NA, com o texto nos campos.
  lida = nfse_prefeitura_ler(c(em_outro_formato, em_mes_e_ano, NFSE_DA_ABRASF_1))
  expect_identical(lida$nfses$competencia, as.Date(c(NA, "2026-10-01", "2026-10-01")))
  expect_true("01/10/2026" %in% lida$campos$valor)
  # O CompNfse da 1.00 traz a data no DataHoraCancelamento; outros provedores, noutro grupo. Vale a que estiver lá.
  nota_sem_declaracao = sub("^<!--[^>]*-->\\s*", "", texto)
  abertura = "<ns4:CompNfse xmlns:ns4=\"http://www.ginfes.com.br/tipos_v03.xsd\">"
  cancelamento_da_1 = paste0(abertura, nota_sem_declaracao, "<ns4:NfseCancelamento><ns4:Confirmacao><ns4:Pedido/>",
                             "<ns4:DataHoraCancelamento>2026-10-21T10:00:00</ns4:DataHoraCancelamento>",
                             "</ns4:Confirmacao></ns4:NfseCancelamento></ns4:CompNfse>")
  cancelamento_noutro_grupo = paste0(abertura, nota_sem_declaracao, "<ns4:NfseCancelamento><ns4:Confirmacao>",
                                     "<ns4:InfConfirmacaoCancelamento><ns4:Sucesso>true</ns4:Sucesso>",
                                     "<ns4:DataHora>2026-10-22T10:00:00</ns4:DataHora></ns4:InfConfirmacaoCancelamento>",
                                     "</ns4:Confirmacao></ns4:NfseCancelamento></ns4:CompNfse>")
  cancelamento_sem_data = paste0(abertura, nota_sem_declaracao, "<ns4:NfseCancelamento/></ns4:CompNfse>")
  so_a_nota = paste0(abertura, nota_sem_declaracao, "</ns4:CompNfse>")
  notas = nfse_prefeitura_ler(c(cancelamento_da_1, cancelamento_noutro_grupo, cancelamento_sem_data, so_a_nota))$nfses
  expect_identical(notas$situacao, c("Cancelada", "Cancelada", "Cancelada", "Normal"))
  expect_identical(notas$cancelamento, c("2026-10-21T10:00:00", "2026-10-22T10:00:00", NA, NA))
})

test_that("a ABRASF 2.04 dentro do CompNfse, cancelada", {
  nota = nfse_prefeitura_ler(NFSE_DA_ABRASF_2)$nfses
  expect_identical(nota$leiaute, "ABRASF 2")
  expect_identical(nota$versao, "2.04")
  expect_identical(nota$prestador_documento, "11444777000161")
  expect_identical(nota$prestador_inscricao_municipal, "55555")
  expect_identical(nota$tomador_documento, "12345678909")
  expect_identical(nota$exigibilidade_iss_descricao, "Exig\u00edvel")
  expect_identical(nota$regime_especial_descricao, "Microempresa ou Empresa de Pequeno Porte (ME EPP)")
  expect_identical(nota$cnae, "7020400")
  expect_identical(nota$base_calculo, 2000)
  expect_identical(nota$valor_liquido, 1950)
  expect_identical(nota$valor_ir, 30)
  expect_true(nota$iss_retido)
  # A ABRASF 2.04 manda o percentual: 5 é 5%.
  expect_identical(nota$aliquota_percentual, 5)
  expect_identical(nota$situacao, "Cancelada")
  expect_identical(nota$cancelamento, "2026-10-26T11:00:00")
  expect_identical(nota$item_lista_servico, "17.01")
  expect_identical(nota$incentivo_fiscal_descricao, "N\u00e3o")
  expect_true(is.na(nota$incentivador_cultural))
})

test_that("ABRASF 2: a substitu\u00edda com o cancelamento, a vers\u00e3o sem a escala da al\u00edquota e a assinatura", {
  texto = texto_do_exemplo(NFSE_DA_ABRASF_2)
  # A substituta cancela a nota: com os dois no CompNfse, a situação é substituída.
  substituicao = paste0("<NfseSubstituicao versao=\"2.04\"><SubstituicaoNfse Id=\"S1\">",
                        "<NfseSubstituidora>790</NfseSubstituidora></SubstituicaoNfse></NfseSubstituicao></CompNfse>")
  substituida = sub("</CompNfse>", substituicao, texto, fixed = TRUE)
  nota = nfse_prefeitura_ler(substituida)$nfses
  expect_identical(nota$situacao, "Substitu\u00edda")
  expect_identical(nota$nfse_substituidora, "790")
  expect_identical(nota$cancelamento, "2026-10-26T11:00:00")
  # Os manuais da 2.02, da 2.03 e da 2.04 dizem que a alíquota vem em percentual; de outra versão, o RNFe não sabe.
  versao_2_02 = sub("<Nfse versao=\"2.04\">", "<Nfse versao=\"2.02\">", texto, fixed = TRUE)
  expect_identical(nfse_prefeitura_ler(versao_2_02)$nfses$aliquota_percentual, 5)
  versao_2_01 = sub("<Nfse versao=\"2.04\">", "<Nfse versao=\"2.01\">", texto, fixed = TRUE)
  nota = nfse_prefeitura_ler(versao_2_01)$nfses
  expect_identical(nota$aliquota, 5)
  expect_true(is.na(nota$aliquota_percentual))
  # A assinatura da declaração fica dentro do InfNfse, e fora dos campos.
  assinatura = paste0("</InfDeclaracaoPrestacaoServico><Signature xmlns=\"http://www.w3.org/2000/09/xmldsig#\">",
                      "<SignedInfo><Reference URI=\"#D1\"><DigestValue>QUJD</DigestValue></Reference></SignedInfo>",
                      "<SignatureValue>WFla</SignatureValue></Signature>")
  assinada = sub("</InfDeclaracaoPrestacaoServico>", assinatura, texto, fixed = TRUE)
  campos = nfse_prefeitura_ler(assinada)$campos
  expect_true("DeclaracaoPrestacaoServico/InfDeclaracaoPrestacaoServico/Competencia" %in% campos$caminho)
  expect_false(any(grepl("Signature|SignedInfo", campos$caminho)))
  expect_false(any(campos$valor %in% c("QUJD", "WFla")))
})

test_that("v\u00e1rios arquivos de uma vez, o texto do XML e o que n\u00e3o \u00e9 NFS-e de prefeitura", {
  nacional = system.file("exemplos", "nfse_sp_v101.xml", package = "RNFe")
  lida = nfse_prefeitura_ler(c(NFSE_DE_SAO_PAULO, NFSE_DA_ABRASF_1, NFSE_DA_ABRASF_2, nacional, "nao_existe.xml"),
                             todos_os_campos = FALSE)
  expect_identical(lida$nfses$leiaute, c("S\u00e3o Paulo", "ABRASF 1", "ABRASF 2"))
  expect_identical(lida$arquivos$nfses, c(1L, 1L, 1L, 0L, 0L))
  expect_match(lida$arquivos$problema[4], "NFS-e de prefeitura")
  expect_match(lida$arquivos$problema[5], "n\u00e3o encontrado")
  expect_null(lida$campos)
  texto = paste(readLines(NFSE_DA_ABRASF_2, encoding = "UTF-8"), collapse = "\n")
  expect_identical(nfse_prefeitura_ler(texto)$nfses$numero, "789")
  vazia = nfse_prefeitura_ler(character())
  expect_identical(nrow(vazia$nfses), 0L)
  expect_true("aliquota_percentual" %in% names(vazia$nfses))
})
