# Os valores esperados são os escritos à mão nos MDF-e de inst/exemplos (validados contra o schema
# oficial com ferramentas/validar_exemplos.R).
MDFE_SP = system.file("exemplos", "mdfe_proc_sp.xml", package = "RNfe")
MDFE_CE = system.file("exemplos", "mdfe_ce_carga_propria.xml", package = "RNfe")
CHAVE_SP = "35261033344455500070580010000003211112233448"
CHAVE_CE = "23261011444777000161580020000000121556677880"

test_that("o MDF-e com protocolo: cabe\u00e7alho, emitente, totais e autoriza\u00e7\u00e3o", {
  mdfe = mdfe_ler(MDFE_SP)$mdfes
  expect_identical(mdfe$chave, CHAVE_SP)
  expect_true(chave_valida(mdfe$chave))
  expect_identical(mdfe$versao, "3.00")
  expect_identical(mdfe$modelo, "58")
  expect_identical(mdfe$serie, 1L)
  expect_identical(mdfe$numero, 321L)
  expect_identical(mdfe$data_emissao, as.Date("2026-10-15"))
  expect_equal(as.numeric(mdfe$emissao), as.numeric(as.POSIXct("2026-10-15 18:00:00", tz = "UTC")))
  expect_identical(attr(mdfe$emissao, "tzone"), "America/Sao_Paulo")
  expect_equal(as.numeric(mdfe$inicio_viagem), as.numeric(as.POSIXct("2026-10-15 19:00:00", tz = "UTC")))
  expect_identical(mdfe$tipo_emitente, 1L)
  expect_true(is.na(mdfe$tipo_transportador))
  expect_identical(mdfe$modal, "1")
  expect_identical(mdfe$inicio_uf, "SP")
  expect_identical(mdfe$fim_uf, "RJ")
  expect_identical(mdfe$emitente_documento, "33344455500070")
  expect_identical(mdfe$emitente_nome, "LOGISTICA DE TESTE LTDA")
  expect_identical(mdfe$emitente_municipio, "S\u00c3O PAULO")
  expect_identical(mdfe$versao_modal, "3.00")
  expect_identical(mdfe$rntrc, "12345678")
  expect_identical(mdfe$placa, "ABC1D23")
  expect_identical(mdfe$quantidade_cte, 1L)
  expect_true(is.na(mdfe$quantidade_nfe))
  expect_equal(mdfe$valor_carga, 150)
  expect_identical(mdfe$unidade_peso, "01")
  expect_equal(mdfe$peso_bruto, 120.5)
  expect_identical(mdfe$tipo_carga, "05")
  expect_identical(mdfe$produto_predominante, "AGUA MINERAL")
  expect_identical(mdfe$produto_ncm, "22011000")
  expect_identical(mdfe$informacoes_complementares, "MDF-E DE TESTE DO PACOTE RNFE - SEM VALOR FISCAL")
  expect_identical(mdfe$protocolo, "935260000011111")
  expect_identical(mdfe$situacao, 100L)
  expect_identical(mdfe$motivo, "Autorizado o uso do MDF-e")
  expect_equal(as.numeric(mdfe$autorizacao), as.numeric(as.POSIXct("2026-10-15 18:00:40", tz = "UTC")))
  expect_identical(mdfe$arquivo, MDFE_SP)
})

test_that("ao lado do NCM do produto predominante, a descri\u00e7\u00e3o dele na data do MDF-e", {
  mdfes = mdfe_ler(c(MDFE_SP, MDFE_CE))$mdfes
  expect_identical(match("produto_ncm_descricao", names(mdfes)), match("produto_ncm", names(mdfes)) + 1L)
  expect_match(mdfes$produto_ncm_descricao[1], "- \u00c1guas minerais e \u00e1guas gaseificadas$")
  expect_true(is.na(mdfes$produto_ncm_descricao[2]))
})

test_that("MDF-e de carga pr\u00f3pria, sem protocolo", {
  mdfe = mdfe_ler(MDFE_CE)$mdfes
  expect_identical(mdfe$chave, CHAVE_CE)
  expect_true(chave_valida(mdfe$chave))
  expect_identical(mdfe$tipo_emitente, 2L)
  expect_identical(mdfe$emitente_documento, "11444777000161")
  expect_true(is.na(mdfe$rntrc))
  expect_identical(mdfe$placa, "XYZ9A87")
  expect_identical(mdfe$quantidade_nfe, 1L)
  expect_identical(mdfe$unidade_peso, "02")
  expect_equal(mdfe$peso_bruto, 0.036)
  expect_true(is.na(mdfe$inicio_viagem))
  expect_true(is.na(mdfe$protocolo))
  expect_true(is.na(mdfe$situacao))
  expect_true(is.na(mdfe$autorizacao))
})

test_that("os lugares da viagem: carregamento, percurso e descarregamento, na ordem", {
  locais = mdfe_ler(MDFE_CE)$locais
  expect_identical(locais$chave, rep(CHAVE_CE, 4))
  expect_identical(locais$tipo, c("infMunCarrega", "infPercurso", "infPercurso", "infMunDescarga"))
  expect_identical(locais$codigo_municipio, c("2304400", NA, NA, "2611606"))
  expect_identical(locais$municipio, c("FORTALEZA", NA, NA, "RECIFE"))
  expect_identical(locais$uf, c(NA, "RN", "PB", NA))
})

test_that("os documentos, com o munic\u00edpio de descarregamento", {
  documentos = mdfe_ler(c(MDFE_SP, MDFE_CE))$documentos
  expect_identical(documentos$chave, c(CHAVE_SP, CHAVE_CE))
  expect_identical(documentos$tipo, c("infCTe", "infNFe"))
  cte = cte_ler(system.file("exemplos", "cte_proc_sp.xml", package = "RNfe"))$ctes
  nota = nfe_ler(system.file("exemplos", "nfe_ce_simples_cpf.xml", package = "RNfe"))$notas
  expect_identical(documentos$documento_chave, c(cte$chave, nota$chave))
  expect_identical(documentos$descarga_codigo_municipio, c("3304557", "2611606"))
  expect_identical(documentos$descarga_municipio, c("RIO DE JANEIRO", "RECIFE"))
  expect_identical(documentos$reentrega, c(NA, 1L))
})

test_that("os ve\u00edculos e os condutores", {
  lido = mdfe_ler(c(MDFE_SP, MDFE_CE))
  veiculos = lido$veiculos
  expect_identical(veiculos$chave, c(CHAVE_SP, CHAVE_CE, CHAVE_CE))
  expect_identical(veiculos$tipo, c("veicTracao", "veicTracao", "veicReboque"))
  expect_identical(veiculos$placa, c("ABC1D23", "XYZ9A87", "QWE4R56"))
  expect_identical(veiculos$renavam, c("12345678901", NA, NA))
  expect_identical(veiculos$codigo_interno, c(NA, "CAV-07", NA))
  expect_identical(veiculos$tara, c(8000L, 9500L, 6000L))
  expect_identical(veiculos$capacidade_kg, c(14000L, 0L, 30000L))
  expect_identical(veiculos$tipo_rodado, c("01", "03", NA))
  expect_identical(veiculos$tipo_carroceria, c("02", "00", "05"))
  expect_identical(veiculos$uf, c("SP", "CE", "CE"))
  expect_identical(veiculos$proprietario_documento, c(NA, "12345678909", NA))
  expect_identical(veiculos$proprietario_nome, c(NA, "TRANSPORTADOR AUTONOMO DE TESTE", NA))
  expect_identical(veiculos$proprietario_rntrc, c(NA, "87654321", NA))
  expect_identical(veiculos$proprietario_tipo, c(NA, 1L, NA))

  condutores = lido$condutores
  expect_identical(condutores$chave, c(CHAVE_SP, CHAVE_CE, CHAVE_CE))
  expect_identical(condutores$nome, c("MOTORISTA DE TESTE", "PRIMEIRO MOTORISTA DE TESTE", "SEGUNDO MOTORISTA DE TESTE"))
  expect_identical(condutores$cpf, c("12345678909", "12345678909", "98765432100"))
})

test_that("os seguros: uma linha por averba\u00e7\u00e3o, e uma para o seguro sem averba\u00e7\u00e3o", {
  seguros = mdfe_ler(c(MDFE_SP, MDFE_CE))$seguros
  expect_identical(seguros$chave, c(CHAVE_SP, CHAVE_SP, CHAVE_CE, CHAVE_CE))
  expect_identical(seguros$responsavel, c(1L, 1L, 2L, 1L))
  expect_identical(seguros$responsavel_documento, c(NA, NA, "11222333000181", NA))
  expect_identical(seguros$seguradora_nome, c("SEGURADORA DE TESTE", "SEGURADORA DE TESTE", "SEGURADORA DE TESTE", NA))
  expect_identical(seguros$apolice, c("APOLICE-001", "APOLICE-001", "APOLICE-777", NA))
  expect_identical(seguros$averbacao, c("AVERBACAO-001", "AVERBACAO-002", NA, "AVERBACAO-999"))
})

test_that("ao lado de cada c\u00f3digo do leiaute, o significado dele", {
  lido = mdfe_ler(c(MDFE_SP, MDFE_CE))
  mdfes = lido$mdfes
  expect_identical(match("tipo_emitente_descricao", names(mdfes)), match("tipo_emitente", names(mdfes)) + 1L)
  expect_identical(mdfes$tipo_emitente_descricao, c("Prestador de servi\u00e7o de transporte", "Transportador de carga pr\u00f3pria"))
  expect_identical(mdfes$modal_descricao, rep("Rodovi\u00e1rio", 2))
  expect_identical(mdfes$modelo_descricao, rep("MDF-e", 2))
  expect_identical(mdfes$unidade_peso_descricao, c("KG", "TON"))
  expect_identical(mdfes$tipo_carga_descricao[1], "Carga geral")
  expect_identical(lido$documentos$reentrega_descricao, c(NA, "Reentrega"))
  veiculos = lido$veiculos
  expect_identical(veiculos$tipo_rodado_descricao, c("Truck", "Cavalo mec\u00e2nico", NA))
  expect_identical(veiculos$tipo_carroceria_descricao, c("Fechada/Ba\u00fa", "N\u00e3o aplic\u00e1vel", "Sider"))
  expect_identical(veiculos$proprietario_tipo_descricao, c(NA, "TAC Independente", NA))
  emitente = "Emitente do MDF-e"
  contratante = "Respons\u00e1vel pela contrata\u00e7\u00e3o do servi\u00e7o de transporte (contratante)"
  expect_identical(lido$seguros$responsavel_descricao, c(emitente, emitente, contratante, emitente))
  # O tipo de transportador pelo nome da Lei 11.442/2007, art. 2º (o schema só traz a sigla).
  texto_do_mdfe = sub("</tpEmit>", "</tpEmit><tpTransp>1</tpTransp>", paste(readLines(MDFE_SP, encoding = "UTF-8"), collapse = "\n"), fixed = TRUE)
  expect_true(is.na(mdfes$tipo_transportador_descricao[1]))
  expect_identical(mdfe_ler(texto_do_mdfe)$mdfes$tipo_transportador_descricao, "ETC: Empresa de Transporte Rodovi\u00e1rio de Cargas")
})

test_that("a tabela campos tem todos os campos do MDF-e, com o caminho", {
  campos = mdfe_ler(c(MDFE_SP, MDFE_CE))$campos
  for (arquivo in c(MDFE_SP, MDFE_CE)) {
    documento = xml2::read_xml(arquivo)
    xml2::xml_ns_strip(documento)
    folhas = xml2::xml_find_all(documento, "//infMDFe//*[not(*)]")
    chave = mdfe_ler(arquivo)$mdfes$chave
    expect_identical(sum(campos$chave == chave), length(folhas))
    expect_identical(campos$valor[campos$chave == chave], xml2::xml_text(folhas))
  }
  do_ce = campos[campos$chave == CHAVE_CE, ]
  segundo_condutor = do_ce[do_ce$caminho == "infModal/rodo/veicTracao/condutor[2]/CPF", ]
  expect_identical(segundo_condutor$valor, "98765432100")
  expect_identical(segundo_condutor$grupo, "condutor")
  expect_identical(segundo_condutor$campo, "CPF")
  parcelas = do_ce[do_ce$grupo == "infPrazo" & do_ce$campo == "vParcela", ]
  expect_identical(parcelas$caminho, c("infModal/rodo/infANTT/infPag/infPrazo[1]/vParcela", "infModal/rodo/infANTT/infPag/infPrazo[2]/vParcela"))
  expect_identical(do_ce$valor[do_ce$caminho == "lacres/nLacre"], "LACRE-1")
  do_sp = campos[campos$chave == CHAVE_SP, ]
  expect_identical(do_sp$valor[do_sp$caminho == "infModal/rodo/infANTT/infCIOT/CIOT"], "123456789012")
  expect_identical(do_sp$valor[do_sp$caminho == "infModal/rodo/infANTT/infPag/Comp[2]/tpComp"], "01")
})

test_that("sem a tabela campos, quando ela n\u00e3o \u00e9 pedida, o resto n\u00e3o muda", {
  com_campos = mdfe_ler(c(MDFE_SP, MDFE_CE))
  sem_campos = mdfe_ler(c(MDFE_SP, MDFE_CE), todos_os_campos = FALSE)
  expect_null(sem_campos$campos)
  expect_identical(names(sem_campos), setdiff(names(com_campos), "campos"))
  for (nome in names(sem_campos)) {
    expect_identical(sem_campos[[nome]], com_campos[[nome]])
  }
  expect_identical(names(mdfe_ler(character(), todos_os_campos = FALSE)), names(sem_campos))
})

test_that("v\u00e1rios arquivos de uma vez, e o texto do XML no lugar do arquivo", {
  lido = mdfe_ler(c(MDFE_SP, MDFE_CE))
  expect_identical(lido$mdfes$chave, c(CHAVE_SP, CHAVE_CE))
  expect_identical(lido$arquivos$mdfes, c(1L, 1L))
  expect_identical(lido$arquivos$problema, c(NA_character_, NA_character_))

  texto = paste(readLines(MDFE_SP, encoding = "UTF-8"), collapse = "\n")
  pelo_texto = mdfe_ler(texto)
  expect_identical(pelo_texto$arquivos$arquivo, "(texto 1)")
  pelo_arquivo = mdfe_ler(MDFE_SP)
  pelo_texto$mdfes$arquivo = MDFE_SP
  expect_identical(pelo_texto$mdfes, pelo_arquivo$mdfes)
  expect_identical(pelo_texto$campos, pelo_arquivo$campos)
})

test_that("arquivo que n\u00e3o d\u00e1 para ler n\u00e3o atrapalha os outros, e cada leitor recusa os outros documentos", {
  nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNfe")
  lido = mdfe_ler(c("nao_existe.xml", MDFE_SP, "<MDFe><infMDFe>", nota, NA))
  expect_identical(lido$mdfes$chave, CHAVE_SP)
  expect_identical(lido$arquivos$mdfes, c(0L, 1L, 0L, 0L, 0L))
  problemas = lido$arquivos$problema
  expect_identical(problemas[1], "arquivo n\u00e3o encontrado")
  expect_true(is.na(problemas[2]))
  expect_match(problemas[3], "^n\u00e3o \u00e9 um XML v\u00e1lido")
  expect_identical(problemas[4], "n\u00e3o \u00e9 um MDF-e (o XML come\u00e7a por <nfeProc>)")
  expect_identical(problemas[5], "vazio")

  # O MDF-e cita NF-e (infNFe) e CT-e (infCTe), mas não é nem uma coisa nem outra.
  expect_identical(nrow(nfe_ler(MDFE_CE)$notas), 0L)
  expect_identical(nrow(cte_ler(MDFE_SP)$ctes), 0L)
})

test_that("sem arquivo nenhum, as tabelas v\u00eam vazias com as colunas certas", {
  vazio = mdfe_ler(character())
  cheio = mdfe_ler(c(MDFE_SP, MDFE_CE))
  for (nome in names(cheio)) {
    expect_identical(nrow(vazio[[nome]]), 0L)
    expect_identical(names(vazio[[nome]]), names(cheio[[nome]]))
    expect_identical(vapply(vazio[[nome]], function(coluna) class(coluna)[1], character(1)),
                     vapply(cheio[[nome]], function(coluna) class(coluna)[1], character(1)))
  }
})
