# Os valores esperados são os escritos à mão nas NFS-e de inst/exemplos (validadas contra o schema oficial
# com ferramentas/validar_exemplos.R).
NFSE_SP = system.file("exemplos", "nfse_sp_v101.xml", package = "RNfe")
NFSE_CE = system.file("exemplos", "nfse_ce_mei_v100.xml", package = "RNfe")
CHAVE_SP = "35503082211222333000181000000000012326101234567898"
CHAVE_CE = "23044002211444777000161000000000000726109876543210"

test_that("a NFS-e 1.01: o que o sistema gerou e o que a DPS declarou", {
  nfse = nfse_ler(NFSE_SP)$nfses
  expect_identical(nfse$chave, CHAVE_SP)
  expect_identical(nchar(nfse$chave), 50L)
  expect_identical(nfse$versao, "1.01")
  expect_identical(nfse$numero, "123")
  expect_identical(nfse$numero_dfse, "456")
  expect_identical(nfse$situacao, 100L)
  expect_identical(nfse$ambiente_gerador, 2L)
  expect_identical(nfse$processo_emissao, 1L)
  expect_equal(as.numeric(nfse$processamento), as.numeric(as.POSIXct("2026-10-20 13:00:05", tz = "UTC")))
  expect_identical(attr(nfse$emissao, "tzone"), "America/Sao_Paulo")
  expect_identical(nfse$data_emissao, as.Date("2026-10-20"))
  expect_identical(nfse$competencia, as.Date("2026-10-20"))
  expect_identical(nfse$ambiente, 2L)
  expect_identical(nfse$serie_dps, "1")
  expect_identical(nfse$numero_dps, "123")
  expect_identical(nfse$tipo_emitente, 1L)
  expect_identical(nfse$local_emissao_codigo_municipio, "3550308")
  expect_identical(nfse$local_emissao_municipio, "S\u00e3o Paulo")
  expect_identical(nfse$incidencia_codigo_municipio, "3550308")
  expect_identical(nfse$emitente_documento, "11222333000181")
  expect_identical(nfse$emitente_im, "12345")
  expect_identical(nfse$emitente_uf, "SP")
  expect_identical(nfse$prestador_documento, "11222333000181")
  expect_identical(nfse$prestador_simples_nacional, 1L)
  expect_identical(nfse$tomador_documento, "11444777000161")
  expect_identical(nfse$tomador_codigo_municipio, "3304557")
  expect_true(is.na(nfse$intermediario_documento))
  expect_identical(nfse$codigo_tributacao_nacional, "010501")
  expect_identical(nfse$tributacao_nacional, "Licenciamento ou cess\u00e3o de direito de uso de programas de computa\u00e7\u00e3o.")
  expect_identical(nfse$descricao_servico, "LICENCA DE USO DE SOFTWARE DE TESTE")
  expect_identical(nfse$pedido, "PEDIDO-55")
  expect_identical(nfse$informacoes_complementares, "NFS-E DE TESTE DO PACOTE RNFE - SEM VALOR FISCAL")
  expect_identical(nfse$arquivo, NFSE_SP)
})

test_that("os valores: ISSQN, tributos federais e reten\u00e7\u00f5es", {
  nfse = nfse_ler(NFSE_SP)$nfses
  expect_equal(nfse$valor_servico, 1000)
  expect_identical(nfse$tributacao_issqn, 1L)
  expect_identical(nfse$retencao_issqn, 1L)
  expect_equal(nfse$base_issqn, 1000)
  expect_equal(nfse$aliquota_issqn, 2)
  expect_equal(nfse$valor_issqn, 20)
  expect_identical(nfse$cst_pis_cofins, "01")
  expect_equal(nfse$valor_pis, 6.5)
  expect_equal(nfse$valor_cofins, 30)
  expect_identical(nfse$retencao_pis_cofins, 2L)
  expect_equal(nfse$valor_retido_irrf, 15)
  expect_equal(nfse$valor_total_retido, 15)
  expect_equal(nfse$valor_liquido, nfse$valor_servico - nfse$valor_total_retido)
})

test_that("o IBS e a CBS: o declarado na DPS e o calculado pelo sistema, com os nomes na data", {
  nfse = nfse_ler(NFSE_SP)$nfses
  expect_identical(nfse$finalidade, 0L)
  expect_identical(nfse$indicador_operacao, "100301")
  expect_identical(nfse$cst_ibs_cbs, "000")
  expect_identical(nfse$cst_ibs_cbs_descricao, "Tributa\u00e7\u00e3o integral")
  expect_identical(nfse$classificacao_ibs_cbs, "000001")
  expect_identical(nfse$classificacao_ibs_cbs_nome, "Situa\u00e7\u00f5es tributadas integralmente pelo IBS e CBS.")
  expect_identical(match("cst_ibs_cbs_descricao", names(nfse)), match("cst_ibs_cbs", names(nfse)) + 1L)
  expect_equal(nfse$base_ibs_cbs, 1000)
  expect_equal(nfse$aliquota_efetiva_ibs_uf, 0.1)
  expect_equal(nfse$aliquota_efetiva_cbs, 0.9)
  expect_equal(nfse$valor_ibs_uf, 1)
  expect_equal(nfse$valor_ibs, 1)
  expect_equal(nfse$valor_cbs, 9)
  expect_equal(nfse$valor_total_com_ibs_cbs, nfse$valor_servico + nfse$valor_ibs + nfse$valor_cbs)
})

test_that("a NFS-e 1.00: MEI, tomador pessoa f\u00edsica, desconto e o xOutInf no lugar antigo", {
  nfse = nfse_ler(NFSE_CE)$nfses
  expect_identical(nfse$chave, CHAVE_CE)
  expect_identical(nfse$versao, "1.00")
  expect_identical(nfse$numero, "7")
  expect_true(is.na(nfse$processo_emissao))
  expect_identical(nfse$competencia, as.Date("2026-10-21"))
  expect_identical(nfse$prestador_simples_nacional, 2L)
  expect_identical(nfse$tomador_documento, "12345678909")
  expect_identical(nfse$codigo_tributacao_nacional, "140201")
  expect_equal(nfse$valor_servico, 300)
  expect_equal(nfse$desconto_incondicionado, 20)
  expect_equal(nfse$base_issqn, 280)
  expect_true(is.na(nfse$valor_issqn))
  expect_equal(nfse$valor_liquido, 280)
  expect_identical(nfse$outras_informacoes, "INFORMACAO DE TESTE DA PREFEITURA")
  expect_true(is.na(nfse$cst_ibs_cbs))
  expect_true(is.na(nfse$valor_cbs))
})

test_that("a tabela campos tem todos os campos, sem a assinatura", {
  campos = nfse_ler(c(NFSE_SP, NFSE_CE))$campos
  for (arquivo in c(NFSE_SP, NFSE_CE)) {
    documento = xml2::read_xml(arquivo)
    xml2::xml_ns_strip(documento)
    folhas = xml2::xml_find_all(documento, "//infNFSe//*[not(*)][not(ancestor::Signature)]")
    chave = nfse_ler(arquivo)$nfses$chave
    expect_identical(sum(campos$chave == chave), length(folhas))
    expect_identical(campos$valor[campos$chave == chave], xml2::xml_text(folhas))
  }
  expect_false(any(grepl("Signature|DigestValue|X509", campos$caminho)))
  do_sp = campos[campos$chave == CHAVE_SP, ]
  expect_identical(do_sp$valor[do_sp$caminho == "DPS/infDPS/valores/trib/totTrib/pTotTrib/pTotTribMun"], "2.00")
  expect_identical(do_sp$grupo[do_sp$caminho == "DPS/infDPS/IBSCBS/valores/trib/gIBSCBS/CST"], "gIBSCBS")
})

test_that("sem a tabela campos, quando ela n\u00e3o \u00e9 pedida, o resto n\u00e3o muda", {
  com_campos = nfse_ler(c(NFSE_SP, NFSE_CE))
  sem_campos = nfse_ler(c(NFSE_SP, NFSE_CE), todos_os_campos = FALSE)
  expect_null(sem_campos$campos)
  expect_identical(names(sem_campos), c("nfses", "arquivos"))
  expect_identical(sem_campos$nfses, com_campos$nfses)
  expect_identical(sem_campos$arquivos, com_campos$arquivos)
  expect_identical(names(nfse_ler(character(), todos_os_campos = FALSE)), names(sem_campos))
})

test_that("v\u00e1rios arquivos de uma vez, e o texto do XML no lugar do arquivo", {
  lida = nfse_ler(c(NFSE_SP, NFSE_CE))
  expect_identical(lida$nfses$chave, c(CHAVE_SP, CHAVE_CE))
  expect_identical(lida$arquivos$nfses, c(1L, 1L))
  texto = paste(readLines(NFSE_SP, encoding = "UTF-8"), collapse = "\n")
  pelo_texto = nfse_ler(texto)
  expect_identical(pelo_texto$arquivos$arquivo, "(texto 1)")
  pelo_arquivo = nfse_ler(NFSE_SP)
  pelo_texto$nfses$arquivo = NFSE_SP
  expect_identical(pelo_texto$nfses, pelo_arquivo$nfses)
  expect_identical(pelo_texto$campos, pelo_arquivo$campos)
})

test_that("arquivo que n\u00e3o d\u00e1 para ler n\u00e3o atrapalha os outros, e os leitores n\u00e3o se confundem", {
  nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNfe")
  de_prefeitura = '<CompNfse><Nfse><InfNfse><Numero>1</Numero></InfNfse></Nfse></CompNfse>'
  lida = nfse_ler(c("nao_existe.xml", NFSE_SP, nota, de_prefeitura, NA))
  expect_identical(lida$nfses$chave, CHAVE_SP)
  expect_identical(lida$arquivos$nfses, c(0L, 1L, 0L, 0L, 0L))
  problemas = lida$arquivos$problema
  expect_identical(problemas[1], "arquivo n\u00e3o encontrado")
  expect_true(is.na(problemas[2]))
  expect_identical(problemas[3], "n\u00e3o \u00e9 uma NFS-e Nacional (o XML come\u00e7a por <nfeProc>)")
  expect_identical(problemas[4], "n\u00e3o \u00e9 uma NFS-e Nacional (o XML come\u00e7a por <CompNfse>)")
  expect_identical(problemas[5], "vazio")
  expect_identical(nrow(nfe_ler(NFSE_SP)$notas), 0L)
  expect_identical(nrow(cte_ler(NFSE_SP)$ctes), 0L)
  expect_identical(nrow(mdfe_ler(NFSE_SP)$mdfes), 0L)
})

test_that("sem arquivo nenhum, as tabelas v\u00eam vazias com as colunas certas", {
  vazia = nfse_ler(character())
  cheia = nfse_ler(c(NFSE_SP, NFSE_CE))
  for (nome in names(cheia)) {
    expect_identical(nrow(vazia[[nome]]), 0L)
    expect_identical(names(vazia[[nome]]), names(cheia[[nome]]))
    expect_identical(vapply(vazia[[nome]], function(coluna) class(coluna)[1], character(1)),
                     vapply(cheia[[nome]], function(coluna) class(coluna)[1], character(1)))
  }
})
