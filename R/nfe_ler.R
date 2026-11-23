# Leitura do XML da NF-e e da NFC-e (leiaute 4.00) em tabelas. Os caminhos seguem o schema oficial
# do Portal da NF-e (pacote de liberação PL_010h v1.03, de 13/11/2026, que já traz a Reforma e o Simples Nacional nela).

#' @include ler_xml.R
NULL

# O infNFe da nota fica sempre dentro do NFe. O CT-e e o MDF-e também têm infNFe, com a chave das notas que
# citam, e não são notas.
CAMINHO_DAS_NOTAS = "//NFe/infNFe"

# O resumo da NF-e que a Distribuição de DF-e entrega ao destinatário enquanto ele não se manifestou sobre a nota (NT
# 2014.002): a nota numa linha, sem os itens.
CAMINHO_DOS_RESUMOS_DA_NFE = "//resNFe"

# Coluna, caminho a partir do infNFe e tipo. "a|b" pega o que existir (o leiaute deixa um ou outro). O QR-Code e a
# URL de consulta da NFC-e ficam fora do infNFe, no infNFeSupl, ao lado dele.
CAMPOS_DA_NOTA = ler_campos("
coluna                        caminho                                     tipo
modelo                        ide/mod                                     texto
serie                         ide/serie                                   inteiro
numero                        ide/nNF                                     inteiro
emissao                       ide/dhEmi|ide/dEmi                          data_hora
data_emissao                  ide/dhEmi|ide/dEmi                          data
saida_entrada                 ide/dhSaiEnt                                data_hora
previsao_entrega              ide/dPrevEntrega                            data
natureza_operacao             ide/natOp                                   texto
tipo_operacao                 ide/tpNF                                    inteiro
destino_operacao              ide/idDest                                  inteiro
finalidade                    ide/finNFe                                  inteiro
tipo_nota_debito              ide/tpNFDebito                              texto
tipo_nota_credito             ide/tpNFCredito                             texto
consumidor_final              ide/indFinal                                inteiro
presenca                      ide/indPres                                 inteiro
local_operacao                ide/cIndOp                                  texto
forma_emissao                 ide/tpEmis                                  inteiro
ambiente                      ide/tpAmb                                   inteiro
processo_emissao              ide/procEmi                                 inteiro
formato_danfe                 ide/tpImp                                   inteiro
contingencia_entrada          ide/dhCont                                  data_hora
contingencia_justificativa    ide/xJust                                   texto
municipio_fato_gerador        ide/cMunFG                                  texto
municipio_fato_gerador_ibs    ide/cMunFGIBS                               texto
compra_governamental_ente     ide/gCompraGov/tpEnteGov                    texto
compra_governamental_redutor  ide/gCompraGov/pRedutor                     numero
compra_governamental_operacao ide/gCompraGov/tpOperGov                    texto
emitente_documento            emit/CNPJ|emit/CPF                          texto
emitente_nome                 emit/xNome                                  texto
emitente_fantasia             emit/xFant                                  texto
emitente_ie                   emit/IE                                     texto
emitente_inscricao_suframa    emit/ISUFEmit                               texto
emitente_municipio            emit/enderEmit/xMun                         texto
emitente_codigo_municipio     emit/enderEmit/cMun                         texto
emitente_uf                   emit/enderEmit/UF                           texto
emitente_regime               emit/CRT                                    inteiro
emitente_regime_ibs_cbs       emit/tpRegimeIBSCBS                         inteiro
avulsa_cnpj                   avulsa/CNPJ                                 texto
destinatario_documento        dest/CNPJ|dest/CPF|dest/idEstrangeiro       texto
destinatario_nome             dest/xNome                                  texto
destinatario_ie               dest/IE                                     texto
destinatario_indicador_ie     dest/indIEDest                              inteiro
destinatario_inscricao_suframa dest/ISUF                                  texto
destinatario_municipio       dest/enderDest/xMun                         texto
destinatario_codigo_municipio dest/enderDest/cMun                         texto
destinatario_uf               dest/enderDest/UF                           texto
base_icms                     total/ICMSTot/vBC                           numero
valor_icms                    total/ICMSTot/vICMS                         numero
valor_icms_desonerado         total/ICMSTot/vICMSDeson                    numero
valor_fcp                     total/ICMSTot/vFCP                          numero
base_icms_st                  total/ICMSTot/vBCST                         numero
valor_icms_st                 total/ICMSTot/vST                           numero
valor_fcp_st                  total/ICMSTot/vFCPST                        numero
valor_fcp_st_retido           total/ICMSTot/vFCPSTRet                     numero
valor_produtos                total/ICMSTot/vProd                         numero
valor_produtos_liquido        total/vProdLiqTot                           numero
valor_frete                   total/ICMSTot/vFrete                        numero
valor_seguro                  total/ICMSTot/vSeg                          numero
valor_desconto                total/ICMSTot/vDesc                         numero
valor_ii                      total/ICMSTot/vII                           numero
valor_ipi                     total/ICMSTot/vIPI                          numero
valor_ipi_devolvido           total/ICMSTot/vIPIDevol                     numero
valor_pis                     total/ICMSTot/vPIS                          numero
valor_cofins                  total/ICMSTot/vCOFINS                       numero
valor_outros                  total/ICMSTot/vOutro                        numero
valor_nota                    total/ICMSTot/vNF                           numero
valor_tributos_aproximado     total/ICMSTot/vTotTrib                      numero
base_ibs_cbs                  total/IBSCBSTot/vBCIBSCBS                   numero
valor_ibs                     total/IBSCBSTot/gIBS/vIBS                   numero
valor_cbs                     total/IBSCBSTot/gCBS/vCBS                   numero
valor_ibs_monofasico          total/IBSCBSTot/gMono/vIBSMono              numero
valor_cbs_monofasica          total/IBSCBSTot/gMono/vCBSMono              numero
valor_ibs_simples_nacional    total/IBSCBSTot/gTribSN/vIBSSN              numero
valor_cbs_simples_nacional    total/IBSCBSTot/gTribSN/vCBSSN              numero
valor_is                    total/ISTot/vIS                             numero
valor_nota_com_ibs_cbs_is     total/vNFTot                                numero
modalidade_frete              transp/modFrete                             inteiro
transportadora_documento      transp/transporta/CNPJ|transp/transporta/CPF texto
transportadora_nome           transp/transporta/xNome                     texto
fatura_numero                 cobr/fat/nFat                               texto
fatura_valor_original         cobr/fat/vOrig                              numero
fatura_desconto               cobr/fat/vDesc                              numero
fatura_valor_liquido          cobr/fat/vLiq                               numero
valor_troco                   pag/vTroco                                  numero
informacoes_complementares    infAdic/infCpl                              texto
informacoes_fisco             infAdic/infAdFisco                          texto
qrcode                        parent::NFe/infNFeSupl/qrCode               texto
url_consulta                  parent::NFe/infNFeSupl/urlChave             texto
")

# A partir do det. Os impostos principais em colunas; todos os campos estão na tabela impostos.
CAMPOS_DO_ITEM = ler_campos("
coluna                    caminho                                    tipo
codigo                    prod/cProd                                 texto
gtin                      prod/cEAN                                  texto
descricao                 prod/xProd                                 texto
ncm                       prod/NCM                                   texto
cest                      prod/CEST                                  texto
beneficio_fiscal          prod/cBenef                                texto
credito_presumido_zfm_tipo prod/tpCredPresIBSZFM                     texto
cfop                     prod/CFOP                                  texto
unidade                   prod/uCom                                  texto
quantidade                prod/qCom                                  numero
valor_unitario            prod/vUnCom                                numero
valor_produto             prod/vProd                                 numero
valor_unitario_liquido    prod/vUnComLiq                             numero
valor_produto_liquido     prod/vProdLiq                              numero
unidade_tributavel        prod/uTrib                                 texto
quantidade_tributavel     prod/qTrib                                 numero
valor_unitario_tributavel prod/vUnTrib                               numero
valor_frete               prod/vFrete                                numero
valor_seguro              prod/vSeg                                  numero
valor_desconto            prod/vDesc                                 numero
valor_outros              prod/vOutro                                numero
compoe_total              prod/indTot                                inteiro
pedido                    prod/xPed                                  texto
item_pedido               prod/nItemPed                              texto
bem_movel_usado           prod/indBemMovelUsado                      texto
atividade_simples_nacional prod/cAtivSN                             texto
informacoes_adicionais   infAdProd                                  texto
valor_tributos_aproximado imposto/vTotTrib                           numero
origem                    imposto/ICMS/*/orig                        texto
cst_icms                  imposto/ICMS/*/CST                         texto
csosn                     imposto/ICMS/*/CSOSN                       texto
base_icms                 imposto/ICMS/*/vBC                         numero
aliquota_icms             imposto/ICMS/*/pICMS                       numero
valor_icms                imposto/ICMS/*/vICMS                       numero
base_icms_st              imposto/ICMS/*/vBCST                       numero
aliquota_icms_st          imposto/ICMS/*/pICMSST                     numero
valor_icms_st             imposto/ICMS/*/vICMSST                     numero
base_icms_st_retido       imposto/ICMS/*/vBCSTRet                    numero
valor_icms_st_retido      imposto/ICMS/*/vICMSSTRet                  numero
valor_fcp                 imposto/ICMS/*/vFCP                        numero
valor_fcp_st              imposto/ICMS/*/vFCPST                      numero
valor_icms_desonerado     imposto/ICMS/*/vICMSDeson                  numero
valor_icms_previsto       imposto/ICMS/ICMSPrevistoPagtoAntecip/vICMSPrevisto numero
valor_icms_monofasico     imposto/ICMS/*/vICMSMono                   numero
valor_icms_uf_destino     imposto/ICMSUFDest/vICMSUFDest             numero
valor_fcp_uf_destino      imposto/ICMSUFDest/vFCPUFDest              numero
valor_issqn               imposto/ISSQN/vISSQN                       numero
cst_ipi                   imposto/IPI/*/CST                          texto
valor_ipi                 imposto/IPI/IPITrib/vIPI                   numero
cst_pis                   imposto/PIS/*/CST                          texto
valor_pis                 imposto/PIS/*/vPIS                         numero
cst_cofins                imposto/COFINS/*/CST                       texto
valor_cofins              imposto/COFINS/*/vCOFINS                   numero
valor_ii                  imposto/II/vII                             numero
cst_ibs_cbs               imposto/IBSCBS/CST                         texto
classificacao_ibs_cbs     imposto/IBSCBS/cClassTrib                  texto
base_ibs_cbs              imposto/IBSCBS/gIBSCBS/vBC                 numero
aliquota_ibs_uf           imposto/IBSCBS/gIBSCBS/gIBSUF/pIBSUF       numero
aliquota_ibs_municipio    imposto/IBSCBS/gIBSCBS/gIBSMun/pIBSMun     numero
valor_ibs                 imposto/IBSCBS/gIBSCBS/vIBS                numero
aliquota_cbs              imposto/IBSCBS/gIBSCBS/gCBS/pCBS           numero
valor_cbs                 imposto/IBSCBS/gIBSCBS/gCBS/vCBS           numero
diferimento_ibs_uf        imposto/IBSCBS/gIBSCBS/gIBSUF/gDif/pDif    numero
diferimento_ibs_municipio imposto/IBSCBS/gIBSCBS/gIBSMun/gDif/pDif   numero
diferimento_cbs           imposto/IBSCBS/gIBSCBS/gCBS/gDif/pDif      numero
valor_devolvido_ibs_uf    imposto/IBSCBS/gIBSCBS/gIBSUF/gDevTrib/vDevTrib numero
valor_devolvido_ibs_municipio imposto/IBSCBS/gIBSCBS/gIBSMun/gDevTrib/vDevTrib numero
valor_devolvido_cbs       imposto/IBSCBS/gIBSCBS/gCBS/gDevTrib/vDevTrib numero
cst_regular               imposto/IBSCBS/gIBSCBS/gTribRegular/CSTReg texto
classificacao_regular     imposto/IBSCBS/gIBSCBS/gTribRegular/cClassTribReg texto
credito_presumido_codigo  imposto/IBSCBS/gCredPresOper/cCredPres     texto
valor_total_ibs_monofasico imposto/IBSCBS/gIBSCBSMono/vTotIBSMonoItem numero
valor_total_cbs_monofasica imposto/IBSCBS/gIBSCBSMono/vTotCBSMonoItem numero
aliquota_ibs_simples_nacional imposto/IBSCBS/gTribSN/gIBSSN/pIBSSN   numero
valor_ibs_simples_nacional imposto/IBSCBS/gTribSN/gIBSSN/vIBSSN      numero
aliquota_cbs_simples_nacional imposto/IBSCBS/gTribSN/gCBSSN/pCBSSN   numero
valor_cbs_simples_nacional imposto/IBSCBS/gTribSN/gCBSSN/vCBSSN      numero
valor_is                  imposto/IS/vIS                             numero
percentual_devolvido      impostoDevol/pDevol                        numero
valor_ipi_devolvido       impostoDevol/IPI/vIPIDevol                 numero
valor_item                vItem                                      numero
referenciado_chave        DFeReferenciado/chaveAcesso                texto
referenciado_item         DFeReferenciado/nItem                      inteiro
")

# A partir do resNFe (schema resNFe_v1.01 do pacote da Distribuição de DF-e v1.04). O digVal, diz o schema, serve
# para conferir a integridade da NF-e original.
CAMPOS_DO_RESUMO_DA_NFE = ler_campos("
coluna             caminho   tipo
chave              chNFe     texto
versao             @versao   texto
emitente_documento CNPJ|CPF  texto
emitente_nome      xNome     texto
emitente_ie        IE        texto
emissao            dhEmi     data_hora
data_emissao       dhEmi     data
tipo_operacao      tpNF      inteiro
valor_nota         vNF       numero
digest_value       digVal    texto
autorizacao        dhRecbto  data_hora
protocolo          nProt     texto
situacao_nfe       cSitNFe   inteiro
")

# A partir de cada detPag (pag/detPag).
CAMPOS_DO_PAGAMENTO = ler_campos("
coluna           caminho    tipo
indicador        indPag     inteiro
forma            tPag       texto
descricao        xPag       texto
valor            vPag       numero
data             dPag       data
cnpj_instituicao card/CNPJ  texto
bandeira         card/tBand texto
autorizacao      card/cAut  texto
")

#' Ler o XML de NF-e e NFC-e
#'
#' Lê o XML de NF-e e NFC-e e devolve uma lista de tabelas (`data.frame`s)
#' ligadas pela `chave`: `notas` (uma linha por nota: emitente, destinatário,
#' totais, IBS e CBS, protocolo e, na NFC-e, o QR-Code), `itens` (uma linha por
#' item: produto, NCM, CFOP e os impostos em colunas), `impostos` (todos os campos de imposto, um por linha), `parcelas`,
#' `pagamentos`, `pagamentos_vinculados`, `resumos` (o resumo da NF-e que a
#' Distribuição de DF-e entrega), `campos` (todos os campos, só com
#' `todos_os_campos = TRUE`) e `arquivos` (o que foi lido e o motivo do que não
#' deu).
#'
#' Lê o leiaute 4.00, com ou sem o protocolo de autorização (`nfeProc` ou só
#' `NFe`), e o resumo da NF-e (`resNFe`), de um arquivo, de vários de uma vez
#' ou do próprio texto do XML. Um arquivo que não dá para ler não interrompe os
#' outros: fica em `arquivos`, com o motivo. Para saber se a nota foi
#' cancelada, leia os eventos dela com [eventos_ler()].
#'
#' Cada coluna vem de um campo do leiaute (entre parênteses abaixo), e os
#' códigos ficam como estão no XML. Campo que a nota não tem fica `NA`. O que não tem coluna própria vem na tabela `campos`, quando
#' pedida (`todos_os_campos = TRUE`).
#'
#' @section notas:
#' Uma linha por nota: `chave`, `versao`,
#' `r documentar_campos(CAMPOS_DA_NOTA)`;
#' do protocolo de autorização, quando vem junto:
#' `r documentar_campos(CAMPOS_DO_PROTOCOLO)`;
#' e `arquivo`. `emissao`, `saida_entrada`, `contingencia_entrada` e
#' `autorizacao` são data e hora (mostradas no horário de Brasília);
#' `data_emissao` é a data como está na nota, e `previsao_entrega`, a data da
#' previsão de entrega. Os campos da Reforma na identificação da nota (o tipo
#' da nota de débito e da de crédito, o local da operação, o município do fato
#' gerador do IBS e a compra governamental) e as inscrições na Suframa vêm em
#' colunas próprias. Na NFC-e (`modelo` 65), `qrcode`
#' e `url_consulta` vêm do grupo `infNFeSupl`, que fica fora do `infNFe`; o
#' texto do QR-Code fica como está, sem desmontar.
#'
#' @section itens:
#' Uma linha por item: `chave`, `item` (`nItem`),
#' `r documentar_campos(CAMPOS_DO_ITEM)`.
#' O `*` é o grupo do ICMS, do IPI, do PIS ou da COFINS que o item tiver (por
#' exemplo, `ICMS00` ou `ICMSSN102`). `valor_total_ibs_monofasico` e
#' `valor_total_cbs_monofasica` são os totais do monofásico do item
#' (combustíveis: `vTotIBSMonoItem` e `vTotCBSMonoItem`; em `notas`,
#' `valor_ibs_monofasico` e `valor_cbs_monofasica` são outro campo, o do
#' grupo `gMono` dos totais, sem a retenção e o retido, que têm campos
#' próprios), `valor_item` é a participação do item no total da nota e
#' `referenciado_chave` e `referenciado_item`, o item de outro documento que
#' ele cita (nota de crédito ou de débito, devolução), todos da Reforma. Do
#' IBS e da CBS vêm também o percentual do diferimento, o tributo devolvido, a
#' tributação regular e o código do crédito presumido da operação.
#'
#' @section impostos:
#' Todos os campos dos impostos de cada item, um por linha: `chave`, `item`,
#' `tributo` (o grupo logo abaixo de `imposto`: `ICMS`, `IPI`, `PIS`,
#' `COFINS`, `IBSCBS`...), `grupo` (onde o campo está, por exemplo `ICMS00` ou
#' `gCBS`), `campo` (o nome no leiaute) e `valor` (o texto do XML). É o que
#' sobra para quem precisa de um campo que não está em `itens`.
#'
#' @section parcelas e pagamentos:
#' `parcelas`, uma linha por duplicata: `chave`,
#' `r documentar_campos(CAMPOS_DA_PARCELA)`.
#' `pagamentos`, uma linha por forma de pagamento: `chave`,
#' `r documentar_campos(CAMPOS_DO_PAGAMENTO)`.
#' `pagamentos_vinculados`, uma linha por pagamento vinculado da Reforma (o que
#' liga a nota à transação de pagamento usada no split payment): `chave`,
#' `r documentar_campos(CAMPOS_DO_PAGAMENTO_VINCULADO)`. O código do meio de
#' pagamento é o da tabela do Informe Técnico 2026.001.
#'
#' @section resumos:
#' Uma linha por resumo da NF-e (`resNFe`), o que a Distribuição de DF-e
#' entrega ao destinatário enquanto ele não se manifestou sobre a nota: a nota
#' numa linha, sem itens, impostos nem destinatário.
#' `r documentar_campos(CAMPOS_DO_RESUMO_DA_NFE)` e `arquivo`. `emissao` e
#' `autorizacao` são data e hora (mostradas no horário de Brasília);
#' `data_emissao` é a data como está no resumo. `situacao_nfe` é a situação da
#' nota no momento da consulta (1 autorizada, 2 denegada, 3 cancelada, pela NT
#' 2014.002). Com a chave, a nota completa e os eventos dela podem ser
#' juntados depois.
#'
#' @section campos:
#' Só com `todos_os_campos = TRUE`. Todos os campos da nota, um por linha:
#' `chave`, `caminho` (onde o campo está, a partir do `infNFe`, com a posição
#' quando o grupo se repete, por exemplo `det[2]/prod/cProd`), `grupo` (o grupo
#' logo acima do campo), `campo` (o nome no leiaute) e `valor` (o texto do
#' XML). É onde ficam as notas referenciadas, os volumes do transporte, a
#' rastreabilidade do produto e o que mais não tiver coluna própria. Uma nota
#' tem, em média, uns 220 campos, e a tabela custa de 5 a 7 ms a mais por nota
#' e uns 10 KB de memória (medido em 10 mil notas reais): por isso ela só vem
#' quando pedida. O resumo não entra nela: os campos dele já estão todos em
#' `resumos`.
#'
#' @section arquivos:
#' Uma linha por arquivo pedido: `arquivo`, `notas` (quantas notas tinha),
#' `resumos` (quantos resumos) e `problema` (`NA` quando deu certo). Um texto de
#' XML aparece como `"(texto 1)"`, `"(texto 2)"`...
#'
#' @param arquivos Os XMLs a ler: o caminho de um arquivo, um vetor com vários
#'   (por exemplo, `list.files("pasta", pattern = "xml$", full.names = TRUE)`)
#'   ou o próprio texto do XML (começando por `<`).
#' @param todos_os_campos `TRUE` devolve também a tabela `campos`, com todos os
#'   campos de cada nota.
#' @return Uma lista com os `data.frame`s `notas`, `itens`, `impostos`,
#'   `parcelas`, `pagamentos`, `pagamentos_vinculados`, `resumos`, `campos` (só
#'   com `todos_os_campos = TRUE`) e `arquivos`.
#' @source Schema oficial da NF-e, pacote de liberação PL_010h v1.03 (NT
#'   2026.006 e NT 2026.008), publicado no Portal Nacional da NF-e em
#'   26/10/2026; o resumo, pelo pacote da Distribuição de DF-e v1.04
#'   (`resNFe_v1.01.xsd`, publicado em 03/07/2026) e pela NT 2014.002 v1.02d.
#' @examples
#' nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")
#' lida = nfe_ler(nota)
#' lida$notas[, c("chave", "emitente_nome", "valor_nota", "protocolo")]
#' lida$itens[, c("item", "descricao", "cfop", "cst_icms", "valor_icms", "valor_cbs")]
#' @export
nfe_ler = function(arquivos, todos_os_campos = FALSE) {
  caminho_das_notas_e_dos_resumos = paste(CAMINHO_DAS_NOTAS, CAMINHO_DOS_RESUMOS_DA_NFE, sep = "|")
  arquivos_lidos = ler_arquivos_xml(arquivos, caminho_das_notas_e_dos_resumos, "uma NF-e", colunas_da_nfe, todos_os_campos)
  colunas_vazias = colunas_da_nfe(NULL, NA_character_, todos_os_campos)

  tabelas_da_nfe = list(
    notas = juntar_tabela(arquivos_lidos, "notas", colunas_vazias$notas),
    itens = juntar_tabela(arquivos_lidos, "itens", colunas_vazias$itens),
    impostos = juntar_tabela(arquivos_lidos, "impostos", colunas_vazias$impostos),
    parcelas = juntar_tabela(arquivos_lidos, "parcelas", colunas_vazias$parcelas),
    pagamentos = juntar_tabela(arquivos_lidos, "pagamentos", colunas_vazias$pagamentos),
    pagamentos_vinculados = juntar_tabela(arquivos_lidos, "pagamentos_vinculados", colunas_vazias$pagamentos_vinculados),
    resumos = juntar_tabela(arquivos_lidos, "resumos", colunas_vazias$resumos)
  )
  if (todos_os_campos) {
    tabelas_da_nfe$campos = juntar_tabela(arquivos_lidos, "campos", colunas_vazias$campos)
  }
  # O arquivo da Distribuição de DF-e traz o resumo sem a nota: os dois são contados, cada um na sua coluna.
  tabelas_da_nfe$arquivos = resumo_dos_arquivos(arquivos_lidos, "notas", "notas")
  resumos_de_cada_arquivo = resumo_dos_arquivos(arquivos_lidos, "resumos", "resumos")$resumos
  tabelas_da_nfe$arquivos = inserir_coluna_depois(tabelas_da_nfe$arquivos, "resumos", resumos_de_cada_arquivo, "notas")
  tabelas_da_nfe$notas = converter_datas(tabelas_da_nfe$notas, rbind(CAMPOS_DA_NOTA, CAMPOS_DO_PROTOCOLO))
  tabelas_da_nfe$resumos = converter_datas(tabelas_da_nfe$resumos, CAMPOS_DO_RESUMO_DA_NFE)
  tabelas_da_nfe$parcelas = converter_datas(tabelas_da_nfe$parcelas, CAMPOS_DA_PARCELA)
  tabelas_da_nfe$pagamentos = converter_datas(tabelas_da_nfe$pagamentos, CAMPOS_DO_PAGAMENTO)
  tabelas_da_nfe
}

# As colunas das tabelas de um arquivo de NF-e, cada uma num vetor. Com xml_lido NULL, vêm vazias, já com
# os nomes e os tipos certos.
colunas_da_nfe = function(xml_lido, nome_do_arquivo, todos_os_campos) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  notas = buscar_todos(xml_lido, CAMINHO_DAS_NOTAS)
  resumos_da_nfe = buscar_todos(xml_lido, CAMINHO_DOS_RESUMOS_DA_NFE)
  protocolos = buscar_todos(xml_lido, "//protNFe/infProt")
  itens = buscar_todos(notas, "det")
  campos_dos_impostos = buscar_todos(itens, "imposto//*[not(*)]")
  duplicatas = buscar_todos(notas, "cobr/dup")
  formas_de_pagamento = buscar_todos(notas, "pag/detPag")
  pagamentos_vinculados = buscar_todos(notas, "gPgtoVinc/gPgto")

  chaves = chave_de_cada(notas, "infNFe")
  # O protocolo é casado com a nota pela chave; nota que veio sem protocolo fica com NA.
  protocolo_de_cada_nota = match(chaves, texto_de_cada(protocolos, "chNFe"))

  colunas_das_tabelas = list(
    notas = c(
      list(chave = chaves, versao = xml2::xml_attr(notas, "versao")),
      valores_dos_campos(notas, CAMPOS_DA_NOTA),
      valores_dos_campos(protocolos, CAMPOS_DO_PROTOCOLO, protocolo_de_cada_nota),
      list(arquivo = rep(nome_do_arquivo, length(notas)))
    ),
    itens = c(
      list(chave = chave_de_cada(itens, "infNFe"), item = as.integer(xml2::xml_attr(itens, "nItem"))),
      valores_dos_campos(itens, CAMPOS_DO_ITEM)
    ),
    impostos = colunas_dos_impostos(campos_dos_impostos),
    parcelas = c(list(chave = chave_de_cada(duplicatas, "infNFe")), valores_dos_campos(duplicatas, CAMPOS_DA_PARCELA)),
    pagamentos = c(
      list(chave = chave_de_cada(formas_de_pagamento, "infNFe")),
      valores_dos_campos(formas_de_pagamento, CAMPOS_DO_PAGAMENTO)
    ),
    pagamentos_vinculados = c(
      list(chave = chave_de_cada(pagamentos_vinculados, "infNFe")),
      valores_dos_campos(pagamentos_vinculados, CAMPOS_DO_PAGAMENTO_VINCULADO)
    ),
    resumos = c(
      valores_dos_campos(resumos_da_nfe, CAMPOS_DO_RESUMO_DA_NFE),
      list(arquivo = rep(nome_do_arquivo, length(resumos_da_nfe)))
    )
  )
  if (todos_os_campos) {
    colunas_das_tabelas$campos = colunas_de_todos_os_campos(buscar_todos_os_campos(notas), "infNFe")
  }
  colunas_das_tabelas
}

# Um campo de imposto por linha. O tributo é o grupo logo abaixo de <imposto> (ICMS, PIS, IBSCBS...)
# e o grupo é onde o campo está (ICMS00, gCBS...).
colunas_dos_impostos = function(campos_dos_impostos) {
  item_de_cada_campo = xml2::xml_find_first(campos_dos_impostos, "ancestor::det", ns = SEM_NAMESPACE)
  tributo_de_cada_campo = xml2::xml_find_first(campos_dos_impostos, "ancestor-or-self::*[parent::imposto]", ns = SEM_NAMESPACE)
  # xml_parent() devolveria cada grupo uma vez só; parent::* devolve um por campo.
  grupo_de_cada_campo = xml2::xml_find_first(campos_dos_impostos, "parent::*", ns = SEM_NAMESPACE)
  list(
    chave = chave_de_cada(campos_dos_impostos, "infNFe"),
    item = as.integer(xml2::xml_attr(item_de_cada_campo, "nItem")),
    tributo = xml2::xml_name(tributo_de_cada_campo),
    grupo = xml2::xml_name(grupo_de_cada_campo),
    campo = xml2::xml_name(campos_dos_impostos),
    valor = xml2::xml_text(campos_dos_impostos)
  )
}
