# Pré-conferência da NF-e e da NFC-e antes do envio: o schema do leiaute (o pacote de liberação PL_010g, em
# inst/schemas/nfe) e as regras de validação do Anexo I do MOC 7.0 que dá para conferir só com o XML e as tabelas do
# pacote, cada uma pela redação da nota técnica mais nova que a mudou. O código, a mensagem e a fonte de cada regra
# estão em inst/extdata/regras_nfe.csv; as regras, em nfe_conferir_regras.R. As da Reforma vêm de ibs_cbs_conferir().

#' @include ler_xml.R tabelas.R chave.R ibs_cbs_conferir.R ibs_cbs_regras_da_nota.R
NULL

NAMESPACE_DA_NFE = "http://www.portalfiscal.inf.br/nfe"
# A falta da assinatura no fim do NFe: a nota que ainda vai ser assinada não é um erro de schema.
ERRO_DE_SCHEMA_SEM_ASSINATURA = "^Element '\\{http://www.portalfiscal.inf.br/nfe\\}NFe': Missing child element\\(s\\)\\. Expected is .*xmldsig#\\}Signature"

# A partir do infNFe.
CAMPOS_DA_PRECONFERENCIA = ler_campos("
coluna                        caminho                                     tipo
id                            @Id                                         texto
uf_codigo                     ide/cUF                                     texto
codigo_numerico               ide/cNF                                     texto
modelo                        ide/mod                                     texto
serie                         ide/serie                                   texto
numero                        ide/nNF                                     texto
emissao_texto                 ide/dhEmi                                   texto
saida_texto                   ide/dhSaiEnt                                texto
tipo_operacao                 ide/tpNF                                    texto
destino_operacao              ide/idDest                                  texto
municipio_fato_gerador        ide/cMunFG                                  texto
tipo_impressao                ide/tpImp                                   texto
tipo_emissao                  ide/tpEmis                                  texto
digito                        ide/cDV                                     texto
ambiente                      ide/tpAmb                                   texto
finalidade                    ide/finNFe                                  texto
consumidor_final              ide/indFinal                                texto
presenca                      ide/indPres                                 texto
intermediador                 ide/indIntermed                             texto
processo_emissao              ide/procEmi                                 texto
contingencia_texto            ide/dhCont                                  texto
justificativa                 ide/xJust                                   texto
tipo_nota_credito             ide/tpNFCredito                             texto
cnpj_emitente                 emit/CNPJ                                   texto
cpf_emitente                  emit/CPF                                    texto
ie_emitente                   emit/IE                                     texto
iest_emitente                 emit/IEST                                   texto
regime_tributario             emit/CRT                                    texto
municipio_emitente            emit/enderEmit/cMun                         texto
uf_emitente                   emit/enderEmit/UF                           texto
cnpj_avulsa                   avulsa/CNPJ                                 texto
cnpj_destinatario             dest/CNPJ                                   texto
cpf_destinatario              dest/CPF                                    texto
estrangeiro                   dest/idEstrangeiro                          texto
nome_destinatario             dest/xNome                                  texto
municipio_destinatario        dest/enderDest/cMun                         texto
uf_destinatario               dest/enderDest/UF                           texto
pais_destinatario             dest/enderDest/cPais                        texto
indicador_ie_destinatario     dest/indIEDest                              texto
ie_destinatario               dest/IE                                     texto
suframa_destinatario          dest/ISUF                                   texto
cnpj_retirada                 retirada/CNPJ                               texto
cpf_retirada                  retirada/CPF                                texto
municipio_retirada            retirada/cMun                               texto
uf_retirada                   retirada/UF                                 texto
cnpj_entrega                  entrega/CNPJ                                texto
cpf_entrega                   entrega/CPF                                 texto
municipio_entrega             entrega/cMun                                texto
uf_entrega                    entrega/UF                                  texto
total_base_icms               total/ICMSTot/vBC                           numero
total_icms                    total/ICMSTot/vICMS                         numero
total_icms_desonerado         total/ICMSTot/vICMSDeson                    numero
total_fcp_uf_destino          total/ICMSTot/vFCPUFDest                    numero
total_icms_uf_destino         total/ICMSTot/vICMSUFDest                   numero
total_icms_uf_remetente       total/ICMSTot/vICMSUFRemet                  numero
total_fcp                     total/ICMSTot/vFCP                          numero
total_base_st                 total/ICMSTot/vBCST                         numero
total_st                      total/ICMSTot/vST                           numero
total_fcp_st                  total/ICMSTot/vFCPST                        numero
total_fcp_st_retido           total/ICMSTot/vFCPSTRet                     numero
total_monofasico_retencao     total/ICMSTot/vICMSMonoReten                numero
total_produtos                total/ICMSTot/vProd                         numero
total_frete                   total/ICMSTot/vFrete                        numero
total_seguro                  total/ICMSTot/vSeg                          numero
total_desconto                total/ICMSTot/vDesc                         numero
total_ii                      total/ICMSTot/vII                           numero
total_ipi                     total/ICMSTot/vIPI                          numero
total_ipi_devolvido           total/ICMSTot/vIPIDevol                     numero
total_pis                     total/ICMSTot/vPIS                          numero
total_cofins                  total/ICMSTot/vCOFINS                       numero
total_outros                  total/ICMSTot/vOutro                        numero
total_nota                    total/ICMSTot/vNF                           numero
total_servicos                total/ISSQNtot/vServ                        numero
total_base_iss                total/ISSQNtot/vBC                          numero
total_iss                     total/ISSQNtot/vISS                         numero
total_pis_servicos            total/ISSQNtot/vPIS                         numero
total_cofins_servicos         total/ISSQNtot/vCOFINS                      numero
modalidade_frete              transp/modFrete                             texto
cnpj_transportador            transp/transporta/CNPJ                      texto
cpf_transportador             transp/transporta/CPF                       texto
ie_transportador              transp/transporta/IE                        texto
uf_transportador              transp/transporta/UF                        texto
numero_fatura                 cobr/fat/nFat                               texto
valor_original_fatura         cobr/fat/vOrig                              numero
desconto_fatura               cobr/fat/vDesc                              numero
valor_liquido_fatura          cobr/fat/vLiq                               numero
troco                         pag/vTroco                                  numero
cnpj_intermediador            infIntermed/CNPJ                            texto
cnpj_responsavel_tecnico      infRespTec/CNPJ                             texto
qrcode                        parent::NFe/infNFeSupl/qrCode               texto
autorizacao_texto             parent::NFe/parent::nfeProc/protNFe/infProt/dhRecbto texto
")

GRUPOS_DA_PRECONFERENCIA = ler_campos("
coluna                        caminho
tem_referencia                ide/NFref
tem_avulsa                    avulsa
tem_destinatario              dest
tem_endereco_destinatario     dest/enderDest
tem_estrangeiro               dest/idEstrangeiro
tem_retirada                  retirada
tem_entrega                   entrega
tem_transportador             transp/transporta
tem_retencao_transporte       transp/retTransp
tem_veiculo_transporte        transp/veicTransp
tem_reboque                   transp/reboque
tem_vagao                     transp/vagao
tem_balsa                     transp/balsa
tem_cobranca                  cobr
tem_intermediador             infIntermed
tem_exporta                   exporta
tem_compra                    compra
tem_cana                      cana
tem_paa                       infPAA
tem_total_issqn               total/ISSQNtot
tem_total_ibs_cbs             total/IBSCBSTot
tem_total_is                  total/ISTot
tem_suplementar               parent::NFe/infNFeSupl
")

# A partir de cada det. O ICMS tem um grupo só por item (ICMS00, ICMSSN102...): o asterisco acha o dele.
CAMPOS_DO_ITEM_DA_PRECONFERENCIA = ler_campos("
coluna                        caminho                                     tipo
item                          @nItem                                      inteiro
codigo_ean                    prod/cEAN                                   texto
descricao                     prod/xProd                                  texto
ncm                           prod/NCM                                    texto
cfop                          prod/CFOP                                   texto
quantidade                    prod/qCom                                   numero
valor_unitario                prod/vUnCom                                 numero
valor_produto                 prod/vProd                                  numero
ean_tributavel                prod/cEANTrib                               texto
quantidade_tributavel         prod/qTrib                                  numero
valor_unitario_tributavel     prod/vUnTrib                                numero
frete                         prod/vFrete                                 numero
seguro                        prod/vSeg                                   numero
desconto                      prod/vDesc                                  numero
outros                        prod/vOutro                                 numero
entra_no_total                prod/indTot                                 texto
uf_consumo                    prod/comb/UFCons                            texto
tipo_operacao_veiculo         prod/veicProd/tpOp                          texto
cst                           imposto/ICMS/*/CST                          texto
csosn                         imposto/ICMS/*/CSOSN                        texto
base_icms                     imposto/ICMS/*/vBC                          numero
aliquota_icms                 imposto/ICMS/*/pICMS                        numero
valor_icms                    imposto/ICMS/*/vICMS                        numero
icms_desonerado               imposto/ICMS/*/vICMSDeson                   numero
motivo_desoneracao            imposto/ICMS/*/motDesICMS                   texto
deduz_desonerado              imposto/ICMS/*/indDeduzDeson                texto
fcp                           imposto/ICMS/*/vFCP                         numero
modalidade_base_st            imposto/ICMS/*/modBCST                      texto
base_st                       imposto/ICMS/*/vBCST                        numero
valor_st                      imposto/ICMS/*/vICMSST                      numero
fcp_st                        imposto/ICMS/*/vFCPST                       numero
fcp_st_retido                 imposto/ICMS/*/vFCPSTRet                    numero
icms_st_retido                imposto/ICMS/*/vICMSSTRet                   numero
fcp_uf_destino                imposto/ICMSUFDest/vFCPUFDest               numero
icms_uf_destino               imposto/ICMSUFDest/vICMSUFDest              numero
icms_uf_remetente             imposto/ICMSUFDest/vICMSUFRemet             numero
valor_ipi                     imposto/IPI/IPITrib/vIPI                    numero
valor_ii                      imposto/II/vII                              numero
valor_pis                     imposto/PIS/*/vPIS                          numero
valor_cofins                  imposto/COFINS/*/vCOFINS                    numero
valor_pis_st                  imposto/PISST/vPIS                          numero
soma_pis_st                   imposto/PISST/indSomaPISST                  texto
valor_cofins_st               imposto/COFINSST/vCOFINS                    numero
soma_cofins_st                imposto/COFINSST/indSomaCOFINSST            texto
base_iss                      imposto/ISSQN/vBC                           numero
valor_iss                     imposto/ISSQN/vISSQN                        numero
ipi_devolvido                 impostoDevol/IPI/vIPIDevol                  numero
")

GRUPOS_DO_ITEM_DA_PRECONFERENCIA = ler_campos("
coluna                        caminho
tem_icms                      imposto/ICMS
tem_icms_partilha             imposto/ICMS/ICMSPart
tem_icms_repasse              imposto/ICMS/ICMSST
tem_icms_uf_destino           imposto/ICMSUFDest
tem_ipi                       imposto/IPI
tem_ii                        imposto/II
tem_pis_st                    imposto/PISST
tem_cofins_st                 imposto/COFINSST
tem_issqn                     imposto/ISSQN
tem_devolucao_tributos        impostoDevol
tem_veiculo                   prod/veicProd
tem_arma                      prod/arma
tem_recopi                    prod/nRECOPI
tem_exportacao                prod/detExport
tem_ibs_cbs                   imposto/IBSCBS
tem_is                        imposto/IS
")

# A partir de cada detPag.
CAMPOS_DO_PAGAMENTO_DA_PRECONFERENCIA = ler_campos("
coluna                        caminho                                     tipo
meio                          tPag                                        texto
descricao                     xPag                                        texto
valor                         vPag                                        numero
cnpj_pagamento                CNPJPag                                     texto
cnpj_credenciadora            card/CNPJ                                   texto
bandeira                      card/tBand                                  texto
cnpj_recebedor                card/CNPJReceb                              texto
")

#' Conferir a NF-e antes de enviar
#'
#' Confere cada NF-e e NFC-e como a SEFAZ conferiria ao receber: o XML contra
#' o schema do leiaute e as regras de validação que dá para conferir só com o
#' XML e as tabelas do pacote. É a pré-conferência: o que não passar aqui seria
#' rejeitado (ou autorizado com outra situação), e é melhor saber antes de
#' enviar. Serve também para a nota já autorizada: aí a conferência usa a hora
#' do protocolo.
#'
#' O schema é o do pacote de liberação mais novo do Portal da NF-e (PL_010g,
#' versão 1.03, que vai junto com o pacote). A nota ainda sem a assinatura
#' digital é conferida assim mesmo: a falta da assinatura não conta como erro, e
#' a coluna `assinada` de `notas` diz que ela falta.
#'
#' As regras são as do Anexo I do Manual de Orientação do Contribuinte (MOC 7.0,
#' de 2020), cada uma pela redação da nota técnica mais nova que a mudou (a NT
#' 2026.002, do DANFE Simplificado Tipo 2; a 2026.001, do PAA; a 2026.007, do
#' contribuinte só do IBS e da CBS; e as outras de 2019 em diante, veja
#' `fonte` em cada linha): a identificação e a chave de acesso, os documentos
#' referenciados, o emitente, o destinatário, a retirada e a entrega, os
#' autorizados a baixar o XML, o produto (GTIN, NCM, CFOP e as contas do valor),
#' o ICMS do item, os grupos que a NFC-e não pode ter, os totais, o transporte, a
#' cobrança, os pagamentos, o intermediador, a exportação e o QR-Code. As regras
#' da Reforma (o IBS, a CBS e o Imposto Seletivo) vêm de [ibs_cbs_conferir()],
#' na mesma tabela, para a nota que tem esses tributos.
#'
#' Cada regra vale como a SEFAZ a aplicava no dia da emissão: a regra que
#' entrou depois (ou saiu antes) da emissão não é conferida, e a que ficou mais
#' rígida depois dela, quando não confere, fica sem conferir, com o motivo. O
#' código que não está na tabela de hoje (NCM, CFOP), numa nota emitida antes
#' da tabela, também fica sem conferir: pode ter sido extinto depois.
#'
#' Fica de fora o que a SEFAZ confere na base dela ou que depende dela: o
#' cadastro do emitente e do destinatário, a duplicidade, as notas
#' referenciadas que ela guarda, a inscrição estadual (o cálculo muda de UF para
#' UF), as tabelas de benefício fiscal e de GTIN de cada UF, o país do Banco
#' Central e os parâmetros que cada UF escolhe. A regra que vale "a critério da
#' UF" é conferida e diz isso na observação.
#'
#' @section notas:
#' Uma linha por nota: `chave`, `numero`, `modelo`, `data_emissao`,
#' `assinada` (se o XML tem a assinatura digital), `schema_valido`,
#' `erros_de_schema`, `regras_conferidas`, `regras_erradas` e
#' `regras_sem_conferir`.
#'
#' @section conferencias:
#' Uma linha por regra que se aplica a cada nota, item, documento referenciado,
#' parcela ou pagamento: `chave`, `item` (o `nItem`; vazio nas regras da
#' nota), `regra`, `campo` (o campo ou o grupo conferido), `no_documento` (o que
#' está no XML), `esperado`, `diferenca` (nas contas: o do documento menos o
#' calculado), `confere` (`TRUE`, `FALSE` ou vazio quando não deu para
#' conferir), `aplicacao` (`"obrigatória"` ou `"facultativa"`: a facultativa a
#' SEFAZ pode não aplicar), `codigo_sefaz` e `mensagem` (a rejeição) e
#' `observacao`. Só as que não conferem ou não deu para conferir, a menos que
#' `todas_as_regras = TRUE`.
#'
#' @section schema:
#' Uma linha por erro do schema: `chave` e `mensagem`, a do validador
#' (libxml2), em inglês, com o nome do campo e o que ele esperava.
#'
#' @param arquivos Os XMLs da NF-e ou da NFC-e (a nota sozinha, o `nfeProc` ou
#'   um lote): o caminho de um arquivo, um vetor com vários ou o próprio texto
#'   do XML (começando por `<`).
#' @param agora O momento do envio à SEFAZ, para as regras de prazo (a emissão
#'   atrasada ou adiantada, a data de saída, o vencimento das parcelas). Na nota
#'   com o protocolo de autorização, vale a hora do protocolo.
#' @param todas_as_regras `TRUE` traz em `conferencias` também as regras que
#'   conferem.
#' @return Uma lista com os `data.frame`s `notas`, `conferencias`, `schema` e
#'   `arquivos` (o que foi lido e o motivo do que não deu, como em
#'   [nfe_ler()]).
#' @source Schemas XML da NF-e, pacote de liberação 010g, versão 1.03 (Portal
#'   Nacional da NF-e, publicado em 26/10/2026); Manual de Orientação do
#'   Contribuinte 7.0, Anexo I (leiaute e regras de validação da NF-e e da
#'   NFC-e); as notas técnicas 2018.001, 2019.001, 2020.002, 2020.006, 2021.002,
#'   2021.003, 2022.002, 2022.003, 2023.002, 2023.003, 2023.004, 2024.001,
#'   2025.001, 2026.001, 2026.002 e 2026.007 (a versão mais nova de cada uma);
#'   e as tabelas de [tabela_fiscal()] (municípios, NCM, CFOP, meios de
#'   pagamento e bandeiras de cartão).
#' @seealso [ibs_cbs_conferir()] para só as regras da Reforma; [nfe_ler()]
#'   para ler as notas.
#' @examples
#' nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")
#' conferida = nfe_conferir(nota)
#' conferida$notas
#' conferida$conferencias[, c("regra", "campo", "no_documento", "esperado", "confere")]
#' @export
nfe_conferir = function(arquivos, agora = Sys.time(), todas_as_regras = FALSE) {
  if (!isTRUE(todas_as_regras) && !isFALSE(todas_as_regras)) {
    stop("Informe todas_as_regras = TRUE ou FALSE.", call. = FALSE)
  }
  if (!inherits(agora, "POSIXct") || length(agora) != 1 || is.na(agora)) {
    stop("Informe agora como um momento (POSIXct), por exemplo Sys.time().", call. = FALSE)
  }
  arquivos = as.character(arquivos)
  arquivos_lidos = ler_arquivos_xml(arquivos, CAMINHO_DAS_NOTAS_PARA_CONFERIR, "uma NF-e", colunas_da_preconferencia, FALSE)
  colunas_vazias = colunas_da_preconferencia(NULL, NA_character_, FALSE)
  notas = juntar_tabela(arquivos_lidos, "notas", colunas_vazias$notas)
  itens = juntar_tabela(arquivos_lidos, "itens", colunas_vazias$itens)
  referencias = juntar_tabela(arquivos_lidos, "referencias", colunas_vazias$referencias)
  autorizados = juntar_tabela(arquivos_lidos, "autorizados", colunas_vazias$autorizados)
  parcelas = juntar_tabela(arquivos_lidos, "parcelas", colunas_vazias$parcelas)
  pagamentos = juntar_tabela(arquivos_lidos, "pagamentos", colunas_vazias$pagamentos)
  exportacoes = juntar_tabela(arquivos_lidos, "exportacoes", colunas_vazias$exportacoes)

  notas = preparar_as_notas_da_preconferencia(notas, itens, agora)
  itens = preparar_os_itens_da_preconferencia(itens, notas)
  conferencias = juntar_linhas(list(
    conferir_a_chave_e_a_identificacao(notas, itens, referencias),
    conferir_os_documentos_referenciados(notas, referencias),
    conferir_o_emitente(notas),
    conferir_o_destinatario(notas, itens),
    conferir_a_retirada_e_a_entrega(notas),
    conferir_os_autorizados(notas, autorizados),
    conferir_os_produtos(notas, itens, referencias, exportacoes),
    conferir_o_icms_dos_itens(itens),
    conferir_os_grupos_da_nfce(notas, itens),
    conferir_os_totais_da_nota(notas, itens),
    conferir_o_transporte(notas),
    conferir_a_cobranca(notas, parcelas),
    conferir_os_pagamentos(notas, pagamentos),
    conferir_as_informacoes_finais(notas)
  ))
  conferencias = completar_com_as_regras_da_nfe(data.frame(conferencias), notas)
  conferencias = juntar_com_as_regras_da_reforma(conferencias, arquivos, notas)
  schema = conferir_os_schemas(arquivos)
  resumo = resumo_da_preconferencia(notas, conferencias, schema)
  if (!todas_as_regras) {
    conferencias = conferencias[!(conferencias$confere %in% TRUE), ]
    rownames(conferencias) = NULL
  }
  erros_de_schema = schema[!is.na(schema$mensagem), c("chave", "mensagem")]
  rownames(erros_de_schema) = NULL
  list(notas = resumo, conferencias = conferencias, schema = erros_de_schema,
       arquivos = resumo_dos_arquivos(arquivos_lidos, "notas", "notas"))
}

# As colunas das tabelas de um arquivo. Com xml_lido NULL, vêm vazias, com os nomes e os tipos certos.
colunas_da_preconferencia = function(xml_lido, nome_do_arquivo, todos_os_campos) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  elementos_das_notas = buscar_todos(xml_lido, CAMINHO_DAS_NOTAS_PARA_CONFERIR)
  # A mesma nota repetida no arquivo é conferida uma vez.
  elementos_das_notas = elementos_das_notas[!duplicated(chave_de_cada(elementos_das_notas, "infNFe"))]
  elementos_dos_itens = buscar_todos(elementos_das_notas, "det")
  notas = c(list(chave = chave_de_cada(elementos_das_notas, "infNFe")),
            valores_dos_campos(elementos_das_notas, CAMPOS_DA_PRECONFERENCIA),
            presenca_dos_grupos(elementos_das_notas, GRUPOS_DA_PRECONFERENCIA))
  notas$tem_assinatura = !is.na(xml2::xml_name(xml2::xml_find_first(elementos_das_notas, "parent::NFe/Signature",
                                                                      ns = SEM_NAMESPACE)))
  itens = c(list(chave = chave_de_cada(elementos_dos_itens, "infNFe")),
            valores_dos_campos(elementos_dos_itens, CAMPOS_DO_ITEM_DA_PRECONFERENCIA),
            presenca_dos_grupos(elementos_dos_itens, GRUPOS_DO_ITEM_DA_PRECONFERENCIA))

  elementos_dos_autorizados = buscar_todos(elementos_das_notas, "autXML")
  autorizados = list(chave = chave_de_cada(elementos_dos_autorizados, "infNFe"),
                     cnpj = texto_de_cada(elementos_dos_autorizados, "CNPJ"),
                     cpf = texto_de_cada(elementos_dos_autorizados, "CPF"))
  elementos_das_parcelas = buscar_todos(elementos_das_notas, "cobr/dup")
  parcelas = list(chave = chave_de_cada(elementos_das_parcelas, "infNFe"),
                  numero = texto_de_cada(elementos_das_parcelas, "nDup"),
                  vencimento = as.Date(texto_de_cada(elementos_das_parcelas, "dVenc")),
                  valor = as.numeric(texto_de_cada(elementos_das_parcelas, "vDup")))
  elementos_dos_pagamentos = buscar_todos(elementos_das_notas, "pag/detPag")
  pagamentos = c(list(chave = chave_de_cada(elementos_dos_pagamentos, "infNFe")),
                 valores_dos_campos(elementos_dos_pagamentos, CAMPOS_DO_PAGAMENTO_DA_PRECONFERENCIA),
                 list(tem_cartao = !is.na(xml2::xml_name(xml2::xml_find_first(elementos_dos_pagamentos, "card",
                                                                              ns = SEM_NAMESPACE)))))
  elementos_das_exportacoes = buscar_todos(elementos_dos_itens, "prod/detExport/exportInd/chNFe")
  item_de_cada_exportacao = xml2::xml_find_first(elementos_das_exportacoes, "ancestor::det", ns = SEM_NAMESPACE)
  exportacoes = list(chave = chave_de_cada(elementos_das_exportacoes, "infNFe"),
                     item = as.integer(xml2::xml_attr(item_de_cada_exportacao, "nItem")),
                     chave_exportacao = xml2::xml_text(elementos_das_exportacoes))
  list(notas = notas, itens = itens, referencias = as.list(referencias_das_notas(elementos_das_notas)),
       autorizados = autorizados, parcelas = parcelas, pagamentos = pagamentos, exportacoes = exportacoes)
}

# As colunas que as regras usam e o XML não traz pronto: as datas, a hora do recebimento (a do protocolo ou a do
# envio), se a nota é NFC-e ou NF-e com DANFE Simplificado Tipo 2 (as duas têm as mesmas regras) e se tem a Reforma.
preparar_as_notas_da_preconferencia = function(notas, itens, agora) {
  notas$data_emissao = as.Date(substr(notas$emissao_texto, 1, 10))
  notas$emissao = data_hora(notas$emissao_texto)
  notas$saida = data_hora(notas$saida_texto)
  recebimento = data_hora(notas$autorizacao_texto)
  notas$tem_protocolo = !is.na(recebimento)
  recebimento[!notas$tem_protocolo] = agora
  notas$recebimento = recebimento
  notas$simplificada = notas$modelo %in% "65" | notas$tipo_impressao %in% "6"
  com_tributo_novo = unique(itens$chave[itens$tem_ibs_cbs | itens$tem_is])
  notas$tem_reforma = notas$chave %in% com_tributo_novo | notas$tem_total_ibs_cbs | notas$tem_total_is
  notas$documento_emitente = ifelse(is.na(notas$cnpj_emitente), notas$cpf_emitente, notas$cnpj_emitente)
  notas$documento_destinatario = ifelse(is.na(notas$cnpj_destinatario), notas$cpf_destinatario, notas$cnpj_destinatario)
  notas
}

# Ao lado de cada item, os campos da nota dele que as regras do item usam.
preparar_os_itens_da_preconferencia = function(itens, notas) {
  da_nota = match(itens$chave, notas$chave)
  for (coluna in c("modelo", "simplificada", "tipo_operacao", "destino_operacao", "finalidade", "regime_tributario",
                   "uf_emitente", "uf_destinatario", "data_emissao", "ambiente", "ie_emitente", "tipo_nota_credito")) {
    itens[[coluna]] = notas[[coluna]][da_nota]
  }
  itens
}

# O schema de cada nota: cada NFe do arquivo vira um documento só dela (com o namespace) e é validado contra o
# nfe_v4.00.xsd. Os arquivos que não dão para ler ficam de fora: a tabela arquivos diz o motivo.
conferir_os_schemas = function(arquivos) {
  schema_da_nfe = schema_da_nfe_do_pacote()
  chaves = list()
  mensagens = list()
  for (posicao in seq_along(arquivos)) {
    arquivo = arquivos[posicao]
    if (is.na(arquivo) || trimws(arquivo) == "" || (!startsWith(trimws(arquivo), "<") && !file.exists(arquivo))) {
      next
    }
    documento = tryCatch(xml2::read_xml(arquivo), error = function(erro) NULL)
    if (is.null(documento)) {
      next
    }
    elementos_nfe = xml2::xml_find_all(documento, "//*[local-name()='NFe' and *[local-name()='infNFe']]")
    chaves_do_arquivo = sub("^NFe", "", xml2::xml_attr(xml2::xml_find_first(elementos_nfe, "*[local-name()='infNFe']"), "Id"))
    elementos_nfe = elementos_nfe[!duplicated(chaves_do_arquivo)]
    chaves_do_arquivo = chaves_do_arquivo[!duplicated(chaves_do_arquivo)]
    for (numero in seq_along(elementos_nfe)) {
      erros = erros_do_schema(elementos_nfe[[numero]], schema_da_nfe)
      # A nota sem erro fica com uma linha de mensagem vazia, para se saber que o schema dela foi conferido.
      if (length(erros) == 0) {
        erros = NA_character_
      }
      chaves[[length(chaves) + 1]] = rep(chaves_do_arquivo[numero], length(erros))
      mensagens[[length(mensagens) + 1]] = erros
    }
  }
  data.frame(chave = as.character(unlist(chaves)), mensagem = as.character(unlist(mensagens)))
}

# Os erros do schema de uma NFe. Sem a assinatura, o erro de que ela falta não conta.
erros_do_schema = function(elemento_nfe, schema_da_nfe) {
  documento_da_nota = xml2::xml_new_root(elemento_nfe)
  assinada = length(xml2::xml_find_all(documento_da_nota, "/*/*[local-name()='Signature']")) > 0
  resultado = xml2::xml_validate(documento_da_nota, schema_da_nfe)
  mensagens = trimws(attr(resultado, "errors"))
  if (!assinada) {
    mensagens = mensagens[!grepl(ERRO_DE_SCHEMA_SEM_ASSINATURA, mensagens)]
  }
  mensagens
}

# O nfe_v4.00.xsd do pacote, lido uma vez (ele inclui os outros arquivos da mesma pasta).
schema_da_nfe_do_pacote = function() {
  if (is.null(tabelas_ja_lidas[["schema_da_nfe"]])) {
    tabelas_ja_lidas[["schema_da_nfe"]] = xml2::read_xml(system.file("schemas", "nfe", "nfe_v4.00.xsd", package = "RNFe"))
  }
  tabelas_ja_lidas[["schema_da_nfe"]]
}

# As regras da pré-conferência, com o modelo, a aplicação, o código, a mensagem, a fonte e as datas (lidas uma vez).
regras_da_nfe = function() {
  if (is.null(tabelas_ja_lidas[["regras_nfe"]])) {
    regras = utils::read.csv(system.file("extdata", "regras_nfe.csv", package = "RNFe"), colClasses = "character",
                             fileEncoding = "UTF-8", na.strings = "")
    for (coluna in c("em_producao_desde", "em_producao_ate", "mudou_em_producao_em")) {
      regras[[coluna]] = as.Date(regras[[coluna]])
    }
    tabelas_ja_lidas[["regras_nfe"]] = regras
  }
  tabelas_ja_lidas[["regras_nfe"]]
}

# O modelo e as datas de cada regra, o código, a mensagem e a aplicação, e o que não confere hoje mas pode ter
# conferido na emissão.
completar_com_as_regras_da_nfe = function(conferencias, notas) {
  regras = regras_da_nfe()
  # Toda regra conferida tem de ter a linha dela na tabela (sem ela, o filtro do modelo a tiraria sem aviso).
  sem_linha = setdiff(conferencias$regra, regras$regra)
  if (length(sem_linha) > 0) {
    stop("Regra sem linha em regras_nfe.csv: ", paste(sem_linha, collapse = ", "), call. = FALSE)
  }
  da_regra = match(conferencias$regra, regras$regra)
  da_nota = match(conferencias$chave, notas$chave)
  modelo_da_nota = notas$modelo[da_nota]
  emissao = notas$data_emissao[da_nota]
  modelos_da_regra = regras$modelos[da_regra]
  do_modelo = modelos_da_regra %in% "55/65" | (!is.na(modelo_da_nota) & modelos_da_regra == modelo_da_nota)
  ja_valia = is.na(emissao) | is.na(regras$em_producao_desde[da_regra]) | emissao >= regras$em_producao_desde[da_regra]
  ainda_valia = is.na(emissao) | is.na(regras$em_producao_ate[da_regra]) | emissao <= regras$em_producao_ate[da_regra]
  conferencias = conferencias[do_modelo & ja_valia & ainda_valia, ]
  da_regra = match(conferencias$regra, regras$regra)
  emissao = notas$data_emissao[match(conferencias$chave, notas$chave)]
  mudou_em = regras$mudou_em_producao_em[da_regra]
  mudou_depois = conferencias$confere %in% FALSE & !is.na(emissao) & !is.na(mudou_em) & emissao < mudou_em
  conferencias$confere[mudou_depois] = NA
  conferencias$observacao[mudou_depois] = paste0(
    "Pela reda\u00e7\u00e3o de hoje n\u00e3o confere, mas a regra mudou na ", regras$fonte[da_regra][mudou_depois],
    " (em produ\u00e7\u00e3o desde ", format(mudou_em[mudou_depois], "%d/%m/%Y"), "), depois da emiss\u00e3o."
  )
  sem_observacao = is.na(conferencias$observacao)
  conferencias$observacao[sem_observacao] = regras$observacao[da_regra][sem_observacao]
  conferencias$aplicacao = regras$aplicacao[da_regra]
  conferencias$codigo_sefaz = regras$codigo_sefaz[da_regra]
  conferencias$mensagem = regras$mensagem[da_regra]
  conferencias = conferencias[, COLUNAS_DA_PRECONFERENCIA]
  rownames(conferencias) = NULL
  conferencias
}

COLUNAS_DA_PRECONFERENCIA = c("chave", "item", "regra", "campo", "no_documento", "esperado", "diferenca", "confere",
                              "aplicacao", "codigo_sefaz", "mensagem", "observacao")

# As regras da Reforma, de ibs_cbs_conferir(), na mesma tabela, depois das da nota. A regra que as duas conferem (a
# B25b-20) fica com a redação da NT 2026.002, que vale também para a NF-e com DANFE Simplificado Tipo 2.
juntar_com_as_regras_da_reforma = function(conferencias, arquivos, notas) {
  da_reforma = ibs_cbs_conferir(arquivos, todas_as_regras = TRUE)$conferencias
  da_reforma = da_reforma[!(da_reforma$regra %in% regras_da_nfe()$regra), ]
  da_reforma$aplicacao = rep(NA_character_, nrow(da_reforma))
  juntas = rbind(conferencias, da_reforma[, COLUNAS_DA_PRECONFERENCIA])
  juntas = juntas[order(match(juntas$chave, notas$chave), method = "radix"), ]
  rownames(juntas) = NULL
  juntas
}

# Uma linha por nota: o que a identifica, a assinatura, o schema e as contagens das regras (de todas, antes de tirar
# as que conferem).
resumo_da_preconferencia = function(notas, conferencias, schema) {
  erros_de_schema = as.integer(table(factor(schema$chave[!is.na(schema$mensagem)], levels = notas$chave)))
  com_schema = notas$chave %in% schema$chave
  data.frame(
    chave = notas$chave,
    numero = as.integer(notas$numero),
    modelo = notas$modelo,
    data_emissao = notas$data_emissao,
    assinada = notas$tem_assinatura,
    schema_valido = ifelse(com_schema, erros_de_schema == 0, NA),
    erros_de_schema = ifelse(com_schema, erros_de_schema, NA_integer_),
    regras_conferidas = as.integer(table(factor(conferencias$chave[!is.na(conferencias$confere)], levels = notas$chave))),
    regras_erradas = as.integer(table(factor(conferencias$chave[conferencias$confere %in% FALSE], levels = notas$chave))),
    regras_sem_conferir = as.integer(table(factor(conferencias$chave[is.na(conferencias$confere)], levels = notas$chave)))
  )
}
