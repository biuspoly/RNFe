# Os valores esperados são os escritos à mão nos CT-e de inst/exemplos (validados contra o schema
# oficial com ferramentas/validar_exemplos.R).
CTE_SP = system.file("exemplos", "cte_proc_sp.xml", package = "RNFe")
CTE_CE = system.file("exemplos", "cte_ce_simples_toma4.xml", package = "RNFe")
CTE_OS = system.file("exemplos", "cte_os_sp.xml", package = "RNFe")
CHAVE_SP = "35261012ABC34501DE35570010000005551876543210"
CHAVE_CE = "23261011444777000161570020000000771135724689"
CHAVE_OS = "35261011444777000161670010000000091246813571"

test_that("o CT-e com protocolo: cabe\u00e7alho, pessoas, valores e autoriza\u00e7\u00e3o", {
  cte = cte_ler(CTE_SP)$ctes
  expect_identical(cte$chave, CHAVE_SP)
  expect_true(chave_valida(cte$chave))
  expect_identical(cte$versao, "4.00")
  expect_identical(cte$modelo, "57")
  expect_identical(cte$serie, 1L)
  expect_identical(cte$numero, 555L)
  expect_identical(cte$data_emissao, as.Date("2026-10-15"))
  expect_equal(as.numeric(cte$emissao), as.numeric(as.POSIXct("2026-10-15 17:00:00", tz = "UTC")))
  expect_identical(attr(cte$emissao, "tzone"), "America/Sao_Paulo")
  expect_identical(cte$cfop, "6353")
  expect_identical(cte$tipo_cte, 0L)
  expect_identical(cte$tipo_servico, 0L)
  expect_identical(cte$modal, "01")
  expect_identical(cte$inicio_uf, "SP")
  expect_identical(cte$fim_municipio, "RIO DE JANEIRO")
  expect_identical(cte$fim_codigo_municipio, "3304557")
  expect_identical(cte$emitente_documento, "12ABC34501DE35")
  expect_identical(cte$emitente_nome, "TRANSPORTADORA DE TESTE LTDA")
  expect_identical(cte$emitente_municipio, "S\u00c3O PAULO")
  expect_identical(cte$emitente_regime, 3L)
  expect_identical(cte$remetente_documento, "11222333000181")
  expect_identical(cte$destinatario_documento, "11444777000161")
  expect_identical(cte$destinatario_uf, "RJ")
  expect_true(is.na(cte$expedidor_documento))
  expect_true(is.na(cte$recebedor_documento))
  expect_equal(cte$valor_prestacao, 350)
  expect_equal(cte$valor_receber, 350)
  expect_equal(cte$valor_carga, 150)
  expect_identical(cte$produto_predominante, "BEBIDAS")
  expect_identical(cte$rntrc, "12345678")
  expect_identical(cte$observacoes_gerais, "CT-E DE TESTE DO PACOTE RNFE - SEM VALOR FISCAL")
  expect_identical(cte$protocolo, "135260000098765")
  expect_identical(cte$situacao, 100L)
  expect_identical(cte$motivo, "Autorizado o uso do CT-e")
  expect_equal(as.numeric(cte$autorizacao), as.numeric(as.POSIXct("2026-10-15 17:01:30", tz = "UTC")))
  expect_identical(cte$arquivo, CTE_SP)
})

test_that("o tomador: pelo papel no toma3, do toma4 e do toma do CT-e OS", {
  ctes = cte_ler(c(CTE_SP, CTE_CE, CTE_OS))$ctes
  expect_identical(ctes$tomador_papel, c(0L, 4L, NA))
  expect_identical(ctes$tomador_indicador_ie, c(1L, 9L, 1L))
  # Papel 0: o remetente.
  expect_identical(ctes$tomador_documento[1], ctes$remetente_documento[1])
  expect_identical(ctes$tomador_nome[1], "EMPRESA DE TESTE LTDA")
  expect_identical(ctes$tomador_ie[1], "123456789012")
  expect_identical(ctes$tomador_uf[1], "SP")
  # toma4: pessoa física, sem IE.
  expect_identical(ctes$tomador_documento[2], "12345678909")
  expect_identical(ctes$tomador_nome[2], "TOMADOR DE TESTE")
  expect_true(is.na(ctes$tomador_ie[2]))
  expect_identical(ctes$tomador_codigo_municipio[2], "2304400")
  # CT-e OS: o grupo toma, sem remetente nem destinatário.
  expect_identical(ctes$tomador_documento[3], "11222333000181")
  expect_identical(ctes$tomador_municipio[3], "S\u00c3O PAULO")
  expect_true(is.na(ctes$remetente_documento[3]))
  expect_true(is.na(ctes$destinatario_documento[3]))
})

test_that("os impostos em colunas, com o nome de cada c\u00f3digo na data do CT-e", {
  ctes = cte_ler(c(CTE_SP, CTE_CE, CTE_OS))$ctes
  expect_identical(ctes$grupo_icms, c("ICMS00", "ICMSSN", "ICMS00"))
  expect_identical(ctes$cst_icms, c("00", "90", "00"))
  expect_equal(ctes$base_icms, c(350, NA, 1000))
  expect_equal(ctes$aliquota_icms, c(12, NA, 12))
  expect_equal(ctes$valor_icms, c(42, NA, 120))
  expect_identical(ctes$simples_nacional, c(NA, 1L, NA))
  expect_identical(ctes$cst_ibs_cbs, c("000", NA, NA))
  expect_identical(ctes$classificacao_ibs_cbs, c("000001", NA, NA))
  expect_equal(ctes$base_ibs_cbs, c(350, NA, NA))
  expect_equal(ctes$valor_ibs_uf, c(0.35, NA, NA))
  expect_equal(ctes$valor_ibs, c(0.35, NA, NA))
  expect_equal(ctes$aliquota_cbs, c(0.9, NA, NA))
  expect_equal(ctes$valor_cbs, c(3.15, NA, NA))
  expect_identical(match("cfop_titulo", names(ctes)), match("cfop", names(ctes)) + 1L)
  expect_identical(ctes$cfop_titulo[1], "Presta\u00e7\u00e3o de servi\u00e7o de transporte a estabelecimento comercial.")
  expect_identical(ctes$cst_ibs_cbs_descricao, c("Tributa\u00e7\u00e3o integral", NA, NA))
  expect_identical(ctes$classificacao_ibs_cbs_nome[1], "Situa\u00e7\u00f5es tributadas integralmente pelo IBS e CBS.")
})

test_that("os componentes somam o valor da presta\u00e7\u00e3o", {
  lido = cte_ler(CTE_SP)
  expect_identical(lido$componentes$nome, c("FRETE PESO", "PEDAGIO"))
  expect_equal(lido$componentes$valor, c(300, 50))
  expect_equal(sum(lido$componentes$valor), lido$ctes$valor_prestacao)
})

test_that("os documentos transportados s\u00e3o as NF-e de exemplo", {
  documentos = cte_ler(CTE_SP)$documentos
  expect_identical(documentos$chave, rep(CHAVE_SP, 2))
  expect_identical(documentos$tipo, c("infNFe", "infNFe"))
  notas = nfe_ler(system.file("exemplos", c("nfe_proc_sp.xml", "nfe_ce_simples_cpf.xml"), package = "RNFe"))$notas
  expect_identical(documentos$documento_chave, notas$chave)
  expect_true(all(is.na(documentos$numero)))
})

test_that("outros documentos e os de transporte anterior, com o emitente", {
  documentos = cte_ler(CTE_CE)$documentos
  expect_identical(documentos$tipo, c("infOutros", "idDocAntEle", "idDocAntPap"))
  expect_identical(documentos$documento_chave, c(NA, CHAVE_SP, NA))
  expect_identical(documentos$tipo_documento, c("99", NA, "07"))
  expect_identical(documentos$descricao, c("PEDIDO DE TESTE", NA, NA))
  expect_identical(documentos$serie, c(NA, NA, "1"))
  expect_identical(documentos$numero, c("123", NA, "4567"))
  expect_identical(documentos$emissao, as.Date(c("2026-10-20", NA, "2026-10-14")))
  expect_equal(documentos$valor, c(35, NA, NA))
  expect_identical(documentos$emitente_documento, c(NA, "12ABC34501DE35", "12ABC34501DE35"))
  expect_identical(documentos$emitente_nome, c(NA, "TRANSPORTADORA DE TESTE LTDA", "TRANSPORTADORA DE TESTE LTDA"))
  expect_identical(documentos$emitente_uf, c(NA, "SP", "SP"))
})

test_that("o CT-e complementar e o de substitui\u00e7\u00e3o citam o CT-e original", {
  complementar = paste0(
    '<CTe xmlns="http://www.portalfiscal.inf.br/cte"><infCte versao="4.00" Id="CTe', CHAVE_CE, '">',
    '<ide><mod>57</mod><tpCTe>1</tpCTe></ide>',
    '<infCteComp><chCTe>', CHAVE_SP, '</chCTe></infCteComp></infCte></CTe>'
  )
  substituto = paste0(
    '<CTe xmlns="http://www.portalfiscal.inf.br/cte"><infCte versao="4.00" Id="CTe', CHAVE_CE, '">',
    '<ide><mod>57</mod><tpCTe>3</tpCTe></ide>',
    '<infCTeNorm><infCteSub><chCte>', CHAVE_SP, '</chCte></infCteSub></infCTeNorm></infCte></CTe>'
  )
  documentos = cte_ler(c(complementar, substituto))$documentos
  expect_identical(documentos$tipo, c("infCteComp", "infCteSub"))
  expect_identical(documentos$documento_chave, c(CHAVE_SP, CHAVE_SP))
})

test_that("as quantidades da carga", {
  cargas = cte_ler(c(CTE_SP, CTE_CE))$cargas
  expect_identical(cargas$chave, c(CHAVE_SP, CHAVE_SP, CHAVE_CE))
  expect_identical(cargas$unidade, c("01", "03", "03"))
  expect_identical(cargas$tipo_medida, c("PESO BRUTO", "CAIXAS", "CAIXAS"))
  expect_equal(cargas$quantidade, c(120.5, 34, 3))
})

test_that("a tabela de impostos tem todos os campos de imposto", {
  impostos = cte_ler(c(CTE_SP, CTE_CE, CTE_OS))$impostos
  # CT-e de SP: ICMS00 (4) e IBSCBS (10). Do Ceará: ICMSSN (2). CT-e OS: ICMS00 (4) e infTribFed (4).
  expect_identical(as.vector(table(factor(impostos$chave, c(CHAVE_SP, CHAVE_CE, CHAVE_OS)))), c(14L, 2L, 8L))
  simples = impostos[impostos$chave == CHAVE_CE, ]
  expect_identical(simples$grupo, c("ICMSSN", "ICMSSN"))
  expect_identical(simples$campo, c("CST", "indSN"))
  expect_identical(simples$valor, c("90", "1"))
  cbs = impostos[impostos$grupo == "gCBS", ]
  expect_identical(cbs$campo, c("pCBS", "vCBS"))
  expect_identical(cbs$valor, c("0.90", "3.15"))
  expect_identical(unique(impostos$tributo[impostos$chave == CHAVE_OS]), c("ICMS", "infTribFed"))
})

test_that("o CT-e OS: servi\u00e7o, tributos federais, fatura e observa\u00e7\u00f5es", {
  lido = cte_ler(CTE_OS)
  cte = lido$ctes
  expect_identical(cte$chave, CHAVE_OS)
  expect_true(chave_valida(cte$chave))
  expect_identical(cte$modelo, "67")
  expect_identical(cte$tipo_servico, 6L)
  expect_identical(cte$servico_descricao, "FRETAMENTO EVENTUAL")
  expect_equal(cte$servico_quantidade, 40)
  expect_true(is.na(cte$valor_carga))
  expect_true(is.na(cte$rntrc))
  expect_equal(cte$valor_pis, 6.5)
  expect_equal(cte$valor_cofins, 30)
  expect_equal(cte$valor_ir, 15)
  expect_true(is.na(cte$valor_inss))
  expect_equal(cte$valor_csll, 10)
  expect_identical(cte$fatura_numero, "9")
  expect_equal(cte$fatura_valor_liquido, 1000)
  expect_identical(cte$protocolo, "135260000054321")
  expect_identical(lido$parcelas$numero, "001")
  expect_identical(lido$parcelas$vencimento, as.Date("2026-11-20"))
  expect_equal(lido$parcelas$valor, 1000)
  expect_identical(lido$observacoes$tipo, "ObsCont")
  expect_identical(lido$observacoes$campo, "CONTRATO")
  expect_identical(lido$observacoes$texto, "CONTRATO DE TESTE 123")
  expect_identical(nrow(lido$documentos), 0L)
})

test_that("o pagamento vinculado da Reforma (pgtoVinc)", {
  lido = cte_ler(c(CTE_SP, CTE_CE, CTE_OS))
  vinculados = lido$pagamentos_vinculados
  expect_identical(vinculados$chave, CHAVE_SP)
  expect_identical(vinculados$numero, 1L)
  expect_identical(vinculados$transacao, "TRANSACAO-DE-TESTE-2")
  expect_identical(vinculados$meio_pagamento, "17")
  expect_identical(vinculados$cnpj_recebedor, "12ABC34501DE35")
  expect_identical(vinculados$cnpj_base_instituicao, "11444777")
  expect_true(all(is.na(lido$ctes$valor_icms_previsto)))
})

test_that("ao lado de cada c\u00f3digo do leiaute, o significado dele", {
  lido = cte_ler(c(CTE_SP, CTE_CE, CTE_OS))
  ctes = lido$ctes
  expect_identical(match("tipo_servico_descricao", names(ctes)), match("tipo_servico", names(ctes)) + 1L)
  expect_identical(ctes$tipo_servico_descricao, c("Normal", "Subcontrata\u00e7\u00e3o", "Transporte de pessoas"))
  expect_identical(ctes$modal_descricao, rep("Rodovi\u00e1rio", 3))
  expect_identical(ctes$tipo_cte_descricao, rep("CT-e normal", 3))
  expect_identical(ctes$modelo_descricao, c("CT-e", "CT-e", "CT-e OS (Outros Servi\u00e7os)"))
  expect_identical(ctes$cst_icms_descricao, c("Tributa\u00e7\u00e3o normal do ICMS", "ICMS do Simples Nacional", "Tributa\u00e7\u00e3o normal do ICMS"))
  expect_identical(ctes$tomador_papel_descricao, c("Remetente", "Outros", NA))
  expect_identical(ctes$retira_descricao, c("N\u00e3o", "N\u00e3o", NA))
  expect_identical(ctes$simples_nacional_descricao, c(NA, "Sim", NA))
  expect_identical(lido$cargas$unidade_descricao, c("KG", "Unidade", "Unidade"))
  expect_identical(lido$documentos$tipo_documento_descricao[lido$documentos$chave == CHAVE_CE], c("Outros", NA, "ATRE"))
  expect_identical(lido$pagamentos_vinculados$meio_pagamento_descricao, "Pagamento Instant\u00e2neo (PIX) - Din\u00e2mico")
})

test_that("o mesmo c\u00f3digo com outro significado no CT-e OS", {
  # procEmi 3: no CT-e, o aplicativo do SEBRAE; no CT-e OS, o aplicativo do Fisco.
  texto_do_cte = sub("<procEmi>0</procEmi>", "<procEmi>3</procEmi>", paste(readLines(CTE_SP, encoding = "UTF-8"), collapse = "\n"), fixed = TRUE)
  texto_do_os = sub("<procEmi>0</procEmi>", "<procEmi>3</procEmi>", paste(readLines(CTE_OS, encoding = "UTF-8"), collapse = "\n"), fixed = TRUE)
  ctes = cte_ler(c(texto_do_cte, texto_do_os))$ctes
  expect_identical(ctes$processo_emissao, c(3L, 3L))
  expect_identical(ctes$processo_emissao_descricao, c("Emiss\u00e3o pelo contribuinte com aplicativo fornecido pelo SEBRAE",
                                                      "Emiss\u00e3o pelo contribuinte com aplicativo fornecido pelo Fisco"))
})

test_that("o CST do ICMS pelo grupo: o 90 tem tr\u00eas sentidos, e o ICMS45 leva o 40, o 41 e o 51", {
  icms = data.frame(grupo_icms = c("ICMS90", "ICMSOutraUF", "ICMSSN", "ICMS45", "ICMS45", "ICMS45", "ICMS60"),
                    cst_icms = c("90", "90", "90", "40", "41", "51", "60"))
  significado_do_cst = data.frame(coluna_do_codigo = "cst_icms", campo = "CST", coluna_do_contexto = "grupo_icms")
  icms = acrescentar_significados(icms, "CT-e", significado_do_cst)
  expect_identical(icms$cst_icms_descricao, c(
    "ICMS outros", "ICMS devido \u00e0 UF de origem da presta\u00e7\u00e3o, quando diferente da UF do emitente", "ICMS do Simples Nacional",
    "Isen\u00e7\u00e3o do ICMS", "N\u00e3o tributada pelo ICMS", "ICMS diferido", "ICMS cobrado por substitui\u00e7\u00e3o tribut\u00e1ria"
  ))
  # O CST num grupo que não é o dele fica sem significado, em vez de pegar o de outro grupo.
  errado = acrescentar_significados(data.frame(grupo_icms = "ICMS00", cst_icms = "90"), "CT-e", significado_do_cst)
  expect_true(is.na(errado$cst_icms_descricao))
})

test_that("CT-e sem protocolo", {
  cte = cte_ler(CTE_CE)$ctes
  expect_identical(cte$chave, CHAVE_CE)
  expect_true(chave_valida(cte$chave))
  expect_true(is.na(cte$protocolo))
  expect_true(is.na(cte$situacao))
  expect_true(is.na(cte$autorizacao))
  expect_identical(cte$tipo_servico, 1L)
})

test_that("a tabela campos s\u00f3 vem quando pedida, com todos os campos do CT-e e do CT-e OS", {
  sem_campos = cte_ler(c(CTE_SP, CTE_CE, CTE_OS))
  com_campos = cte_ler(c(CTE_SP, CTE_CE, CTE_OS), todos_os_campos = TRUE)
  expect_null(sem_campos$campos)
  expect_identical(names(com_campos), c(setdiff(names(sem_campos), "arquivos"), "campos", "arquivos"))
  for (nome in names(sem_campos)) {
    expect_identical(com_campos[[nome]], sem_campos[[nome]])
  }
  campos = com_campos$campos
  for (arquivo in c(CTE_SP, CTE_CE, CTE_OS)) {
    documento = xml2::read_xml(arquivo)
    xml2::xml_ns_strip(documento)
    folhas = xml2::xml_find_all(documento, "//infCte//*[not(*)]")
    chave = cte_ler(arquivo)$ctes$chave
    expect_identical(sum(campos$chave == chave), length(folhas))
    expect_identical(campos$valor[campos$chave == chave], xml2::xml_text(folhas))
  }
  do_sp = campos[campos$chave == CHAVE_SP, ]
  expect_identical(do_sp$valor[do_sp$caminho == "vPrest/Comp[2]/vComp"], "50.00")
  do_os = campos[campos$chave == CHAVE_OS, ]
  expect_identical(do_os$caminho[1], "ide/cUF")
})

test_that("v\u00e1rios arquivos de uma vez, e o texto do XML no lugar do arquivo", {
  lido = cte_ler(c(CTE_SP, CTE_CE, CTE_OS))
  expect_identical(lido$ctes$chave, c(CHAVE_SP, CHAVE_CE, CHAVE_OS))
  expect_identical(lido$arquivos$ctes, c(1L, 1L, 1L))
  expect_identical(lido$arquivos$problema, rep(NA_character_, 3))

  texto = paste(readLines(CTE_SP, encoding = "UTF-8"), collapse = "\n")
  pelo_texto = cte_ler(texto)
  expect_identical(pelo_texto$arquivos$arquivo, "(texto 1)")
  pelo_arquivo = cte_ler(CTE_SP)
  pelo_texto$ctes$arquivo = CTE_SP
  expect_identical(pelo_texto$ctes, pelo_arquivo$ctes)
  expect_identical(pelo_texto$documentos, pelo_arquivo$documentos)
})

test_that("arquivo que n\u00e3o d\u00e1 para ler n\u00e3o atrapalha os outros", {
  nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")
  guia = '<GTVe xmlns="http://www.portalfiscal.inf.br/cte"><infCte versao="4.00" Id="CTe1"/></GTVe>'
  simplificado = '<CTeSimp xmlns="http://www.portalfiscal.inf.br/cte"><infCte versao="4.00" Id="CTe1"/></CTeSimp>'
  lido = cte_ler(c("nao_existe.xml", CTE_SP, "<CTe><infCte>", nota, guia, simplificado, NA))
  expect_identical(lido$ctes$chave, CHAVE_SP)
  expect_identical(lido$arquivos$ctes, c(0L, 1L, 0L, 0L, 0L, 0L, 0L))
  problemas = lido$arquivos$problema
  expect_identical(problemas[1], "arquivo n\u00e3o encontrado")
  expect_true(is.na(problemas[2]))
  expect_match(problemas[3], "^n\u00e3o \u00e9 um XML v\u00e1lido")
  expect_identical(problemas[4], "n\u00e3o \u00e9 um CT-e (o XML come\u00e7a por <nfeProc>)")
  expect_identical(problemas[5], "n\u00e3o \u00e9 um CT-e (o XML come\u00e7a por <GTVe>)")
  expect_identical(problemas[6], "\u00e9 um CT-e simplificado, que ainda n\u00e3o \u00e9 lido")
  expect_identical(problemas[7], "vazio")
})

test_that("sem arquivo nenhum, as tabelas v\u00eam vazias com as colunas certas", {
  vazio = cte_ler(character(), todos_os_campos = TRUE)
  cheio = cte_ler(c(CTE_SP, CTE_CE, CTE_OS), todos_os_campos = TRUE)
  for (nome in names(cheio)) {
    expect_identical(nrow(vazio[[nome]]), 0L)
    expect_identical(names(vazio[[nome]]), names(cheio[[nome]]))
    expect_identical(vapply(vazio[[nome]], function(coluna) class(coluna)[1], character(1)),
                     vapply(cheio[[nome]], function(coluna) class(coluna)[1], character(1)))
  }
})
