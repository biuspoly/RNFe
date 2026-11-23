# A contingência pelo parâmetro das montagens e o caminho dos documentos da SVC. Sem rede: as respostas são as dos
# outros testes da autorização e dos eventos; os endereços, os da tabela interna (a SVC de cada UF pela Relação de
# Serviços Web da NF-e e pela página de Web Services do CT-e). Conferido na homologação em 23/11/2026: a NF-e do RN pela
# SVC-AN e o CT-e do MA pela SVC-SP, autorizados, consultados e cancelados na SVC.
CERTIFICADO_DA_CONTINGENCIA = test_path("certificados", "pessoa_juridica.pfx")
JUSTIFICATIVA_DE_TESTE = "SEFAZ DA UF FORA DO AR DESDE AS 10H"

lista_sem_a_chave = function(exemplo) {
  lista = xml_para_lista(system.file("exemplos", exemplo, package = "RNFe"))
  lista$Id = NULL
  lista$ide$cDV = NULL
  lista
}

# A chave com outra forma de emissão (a posição 35) e o dígito de novo.
chave_com_a_forma = function(chave, forma_de_emissao) {
  sem_o_digito = paste0(substr(chave, 1, 34), forma_de_emissao, substr(chave, 36, 43))
  paste0(sem_o_digito, chave_digito(sem_o_digito))
}

test_that("a NF-e em conting\u00eancia: a SVC da UF no tpEmis e na chave, a justificativa e o dhCont", {
  skip_if_not_installed("openssl")
  nota = lista_sem_a_chave("nfe_proc_sp.xml")
  montada = xml_para_lista(nfe_montar(nota, contingencia = TRUE, justificativa = JUSTIFICATIVA_DE_TESTE))
  # SP usa a SVC-AN (6); o tpEmis 1 da nota lida dá lugar ao da contingência.
  expect_identical(montada$ide$tpEmis, "6")
  expect_identical(substr(montada$Id, 38, 38), "6")
  expect_identical(montada$ide$xJust, JUSTIFICATIVA_DE_TESTE)
  expect_identical(montada$ide$dhCont, montada$ide$dhEmi)
  # A BA usa a SVC-RS (7).
  da_bahia = nota
  da_bahia$ide$cUF = "29"
  expect_identical(xml_para_lista(nfe_montar(da_bahia, contingencia = TRUE, justificativa = JUSTIFICATIVA_DE_TESTE))$ide$tpEmis,
                   "7")
  # O EPEC, o formulário de segurança e o dhCont informado.
  nota$ide$dhCont = "2026-10-15T09:00:00-03:00"
  epec = xml_para_lista(nfe_montar(nota, contingencia = TRUE, tipo_contingencia = "epec", justificativa = JUSTIFICATIVA_DE_TESTE))
  expect_identical(epec$ide$tpEmis, "4")
  expect_identical(epec$ide$dhCont, "2026-10-15T09:00:00-03:00")
  expect_identical(xml_para_lista(nfe_montar(nota, contingencia = TRUE, tipo_contingencia = "fs-da",
                                             justificativa = JUSTIFICATIVA_DE_TESTE))$ide$tpEmis, "5")
})

test_that("a justificativa \u00e9 obrigat\u00f3ria na NF-e, do tamanho do leiaute, e vale tamb\u00e9m a do ide", {
  skip_if_not_installed("openssl")
  nota = lista_sem_a_chave("nfe_proc_sp.xml")
  expect_error(nfe_montar(nota, contingencia = TRUE), "informe a justificativa")
  expect_error(nfe_montar(nota, contingencia = TRUE, justificativa = "SEM SEFAZ"), "tem 9 caracteres")
  expect_error(nfe_montar(nota, contingencia = TRUE, justificativa = strrep("A", 257)), "tem 257 caracteres")
  pelo_ide = nota
  pelo_ide$ide$xJust = JUSTIFICATIVA_DE_TESTE
  expect_identical(xml_para_lista(nfe_montar(pelo_ide, contingencia = TRUE))$ide$xJust, JUSTIFICATIVA_DE_TESTE)
  expect_error(nfe_montar(pelo_ide, contingencia = TRUE, justificativa = "OUTRO MOTIVO QUALQUER AQUI"), "deixe s\u00f3 um")
})

test_that("o que n\u00e3o combina com a conting\u00eancia \u00e9 recusado", {
  skip_if_not_installed("openssl")
  nota = lista_sem_a_chave("nfe_proc_sp.xml")
  expect_error(nfe_montar(nota, contingencia = "sim"), "TRUE ou FALSE")
  expect_error(nfe_montar(nota, justificativa = JUSTIFICATIVA_DE_TESTE), "s\u00f3 valem com contingencia = TRUE")
  expect_error(nfe_montar(nota, tipo_contingencia = "svc"), "s\u00f3 valem com contingencia = TRUE")
  expect_error(nfe_montar(nota, contingencia = TRUE, tipo_contingencia = "off-line", justificativa = JUSTIFICATIVA_DE_TESTE),
               "\"svc\", \"epec\", \"fs-ia\" ou \"fs-da\"")
  # O tpEmis de outra contingência na lista.
  nota$ide$tpEmis = "4"
  expect_error(nfe_montar(nota, contingencia = TRUE, justificativa = JUSTIFICATIVA_DE_TESTE), "n\u00e3o \u00e9 o da conting\u00eancia svc")
  # Sem a UF não dá para escolher a SVC.
  nota$ide$tpEmis = NULL
  nota$ide$cUF = NULL
  expect_error(nfe_montar(nota, contingencia = TRUE, justificativa = JUSTIFICATIVA_DE_TESTE), "informe o ide/cUF")
})

test_that("sem conting\u00eancia, o tpEmis que falta \u00e9 o 1, e o informado fica", {
  skip_if_not_installed("openssl")
  nota = lista_sem_a_chave("nfe_proc_sp.xml")
  nota$ide$tpEmis = NULL
  expect_identical(xml_para_lista(nfe_montar(nota))$ide$tpEmis, "1")
  nota$ide$tpEmis = "6"
  nota$ide$dhCont = "2026-10-15T09:00:00-03:00"
  nota$ide$xJust = JUSTIFICATIVA_DE_TESTE
  expect_identical(xml_para_lista(nfe_montar(nota))$ide$tpEmis, "6")
})

test_that("a NFC-e s\u00f3 tem a conting\u00eancia off-line", {
  skip_if_not_installed("openssl")
  nfce = lista_sem_a_chave("nfce_ce_contingencia.xml")
  nfce$ide$tpEmis = "1"
  nfce$ide$dhCont = NULL
  nfce$ide$xJust = NULL
  montada = xml_para_lista(nfe_montar(nfce, contingencia = TRUE, justificativa = JUSTIFICATIVA_DE_TESTE))
  expect_identical(montada$ide$tpEmis, "9")
  expect_identical(montada$ide$xJust, JUSTIFICATIVA_DE_TESTE)
  expect_error(nfe_montar(nfce, contingencia = TRUE, tipo_contingencia = "svc", justificativa = JUSTIFICATIVA_DE_TESTE),
               "\u00e9 \"off-line\"", fixed = TRUE)
})

test_that("o CT-e: a SVC da UF sem a justificativa, a off-line com ela; a GTV-e e o MDF-e", {
  skip_if_not_installed("openssl")
  cte = lista_sem_a_chave("cte_proc_sp.xml")
  # SP autoriza na própria SEFAZ e usa a SVC-RS (7); a SVC não leva o dhCont nem o xJust (rejeição 586).
  pela_svc = xml_para_lista(cte_montar(cte, contingencia = TRUE))
  expect_identical(pela_svc$ide$tpEmis, "7")
  expect_null(pela_svc$ide$xJust)
  expect_null(pela_svc$ide$dhCont)
  expect_error(cte_montar(cte, contingencia = TRUE, justificativa = JUSTIFICATIVA_DE_TESTE), "n\u00e3o leva justificativa")
  off_line = xml_para_lista(cte_montar(cte, contingencia = TRUE, tipo_contingencia = "off-line",
                                       justificativa = JUSTIFICATIVA_DE_TESTE))
  expect_identical(off_line$ide$tpEmis, "2")
  expect_identical(off_line$ide$xJust, JUSTIFICATIVA_DE_TESTE)
  expect_error(cte_montar(cte, contingencia = TRUE, tipo_contingencia = "off-line"), "informe a justificativa")
  # O CE autoriza na SVRS e usa a SVC-SP (8).
  do_ceara = lista_sem_a_chave("cte_ce_simples_toma4.xml")
  expect_identical(xml_para_lista(cte_montar(do_ceara, contingencia = TRUE))$ide$tpEmis, "8")
  # A GTV-e só tem a off-line; o MDF-e, a contingência 2, sem justificativa.
  gtve = lista_sem_a_chave("gtve_proc_sp.xml")
  expect_identical(xml_para_lista(cte_montar(gtve, contingencia = TRUE, justificativa = JUSTIFICATIVA_DE_TESTE))$ide$tpEmis, "2")
  expect_error(cte_montar(gtve, contingencia = TRUE, tipo_contingencia = "svc"), "\u00e9 \"off-line\"", fixed = TRUE)
  manifesto = lista_sem_a_chave("mdfe_ce_carga_propria.xml")
  em_contingencia = xml_para_lista(mdfe_montar(manifesto, contingencia = TRUE))
  expect_identical(em_contingencia$ide$tpEmis, "2")
  expect_identical(substr(em_contingencia$Id, 39, 39), "2")
})

test_that("a SVC de cada UF sai das tabelas: a da NF-e, a do CT-e pela regra do portal", {
  expect_identical(svc_da_uf("SP", "NF-e", "homologacao")$forma_de_emissao, "6")
  expect_identical(svc_da_uf("BA", "NF-e", "homologacao")$forma_de_emissao, "7")
  expect_null(svc_da_uf("CE", "NFC-e", "homologacao"))
  # No CT-e, quem autoriza na SVRS, em MG, no PR ou no RS usa a SVC-SP; quem autoriza na SVSP, no MT, no MS ou em SP, a
  # SVC-RS. Todas as UFs têm uma.
  for (uf in names(CODIGO_DA_UF)) {
    autorizador = servico_da_uf(uf, "CteConsultaV4", "homologacao", "CT-e")$autorizador
    esperada = if (autorizador %in% c("SVSP", "MT", "MS", "SP")) "SVC-RS" else "SVC-SP"
    expect_identical(svc_da_uf(uf, "CT-e", "homologacao")$autorizador, esperada, info = uf)
  }
  expect_identical(servico_da_uf("CE", "CTeRecepcaoSincV4", "homologacao", "CT-e", 8L)$endereco,
                   "https://homologacao.nfe.fazenda.sp.gov.br/CTeWS/WS/CTeRecepcaoSincV4.asmx")
  expect_null(servico_da_uf("CE", "CTeRecepcaoSincV4", "homologacao", "CT-e", 7L))
  expect_match(problema_da_svc("CE", 7L, "NF-e", "homologacao"), "a SVC de CE \u00e9 a SVC-AN \\(tpEmis 6\\)")
  expect_true(is.na(problema_da_svc("CE", 1L, "NF-e", "homologacao")))
})

test_that("a NF-e da SVC vai \u00e0 SVC da UF; a de outra SVC e a NFC-e da SVC n\u00e3o v\u00e3o", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  nota = lista_sem_a_chave("nfe_ce_simples_cpf.xml")
  assinada = xml_assinar(nfe_montar(nota, contingencia = TRUE, justificativa = JUSTIFICATIVA_DE_TESTE),
                         CERTIFICADO_DA_CONTINGENCIA, "teste")
  chave = sub(".*Id=\"NFe([0-9A-Z]{44})\".*", "\\1", assinada)
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    protocolo = paste0('<protNFe versao="4.00"><infProt><tpAmb>2</tpAmb><verAplic>SVC-AN</verAplic><chNFe>', chave,
                       "</chNFe><dhRecbto>2026-11-23T13:48:28-03:00</dhRecbto><nProt>323260000099999</nProt>",
                       "<cStat>100</cStat><xMotivo>Autorizado o uso da NF-e</xMotivo></infProt></protNFe>")
    texto = paste0('<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">',
                   '<soap:Body><nfeResultMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeAutorizacao4">',
                   '<retEnviNFe versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>2</tpAmb><verAplic>SVC-AN</verAplic>',
                   "<cStat>104</cStat><xMotivo>Lote processado</xMotivo><cUF>23</cUF>",
                   "<dhRecbto>2026-11-23T13:48:28-03:00</dhRecbto>", protocolo, "</retEnviNFe></nfeResultMsg></soap:Body>",
                   "</soap:Envelope>")
    httr2::response(status_code = 200, headers = "Content-Type: application/soap+xml; charset=utf-8", body = charToRaw(texto))
  })
  autorizada = sefaz_autorizar(assinada, CERTIFICADO_DA_CONTINGENCIA, "teste")
  expect_identical(autorizada$autorizador, "SVC-AN")
  expect_identical(autorizada$situacao, 100L)
  expect_identical(pedidos[[1]]$url, "https://hom.sefazvirtual.fazenda.gov.br/NFeAutorizacao4/NFeAutorizacao4.asmx")
  # O tpEmis 7 (a SVC-RS) numa nota do CE, cuja SVC é a SVC-AN: nem vai.
  nota$ide$tpEmis = "7"
  nota$ide$dhCont = "2026-11-23T13:00:00-03:00"
  nota$ide$xJust = JUSTIFICATIVA_DE_TESTE
  outra_svc = sefaz_autorizar(xml_assinar(nfe_montar(nota), CERTIFICADO_DA_CONTINGENCIA, "teste"), CERTIFICADO_DA_CONTINGENCIA,
                              "teste")
  expect_match(outra_svc$problema, "a SVC de CE \u00e9 a SVC-AN")
  expect_length(pedidos, 1)
  # A NFC-e com o tpEmis da SVC, montada à mão: nem vai.
  nfce = lista_sem_a_chave("nfce_ce_contingencia.xml")
  nfce$ide$tpEmis = "6"
  da_svc = xml_assinar(nfe_montar(nfce), CERTIFICADO_DA_CONTINGENCIA, "teste")
  expect_match(notas_para_autorizar(da_svc, "homologacao")$linhas$problema, "a NFC-e n\u00e3o tem SVC")
})

test_that("a consulta e os eventos da NF-e e do CT-e da SVC v\u00e3o \u00e0 SVC", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("openssl")
  local_mocked_bindings(usar_processo_separado = function() FALSE)
  chave_da_nfe = chave_com_a_forma("35261011222333000181550010000010011123456785", "6")
  expect_identical(comeco_da_situacao(chave_da_nfe, "homologacao")$linha$autorizador, "SVC-AN")
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    httr2::response(status_code = 500)
  })
  sefaz_cancelar(chave_da_nfe, "135260000012345", "PEDIDO CANCELADO PELO CLIENTE", CERTIFICADO_DA_CONTINGENCIA, "teste")
  expect_identical(pedidos[[1]]$url, "https://hom.sefazvirtual.fazenda.gov.br/NFeRecepcaoEvento4/NFeRecepcaoEvento4.asmx")
  cte = xml_para_lista(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
  chave_do_cte = chave_com_a_forma(sub("^CTe", "", cte$Id), "7")
  expect_identical(comeco_da_situacao(chave_do_cte, "homologacao")$linha$autorizador, "SVC-RS")
  sefaz_cte_desacordo(chave_do_cte, "FRETE COBRADO EM DUPLICIDADE NA MESMA VIAGEM", CERTIFICADO_DA_CONTINGENCIA, "teste")
  expect_identical(pedidos[[2]]$url,
                   "https://cte-homologacao.svrs.rs.gov.br/ws/CTeRecepcaoEventoV4/CTeRecepcaoEventoV4.asmx")
})
