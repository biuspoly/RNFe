# Conferência do IBS e da CBS de uma NF-e ou NFC-e pelas regras de validação da NT 2025.002-RTC v1.53: o que a SEFAZ
# rejeitaria. O código e a mensagem de cada regra estão em inst/extdata/regras_ibs_cbs.csv, tirados do texto da NT; os
# indicadores de cada CST e de cada classificação, nas tabelas cst_ibs_cbs e classificacao_ibs_cbs; as alíquotas de
# cada ano, na aliquotas_ibs_cbs. As regras fora do grupo UB estão em ibs_cbs_regras_da_nota.R e as do monofásico, em
# ibs_cbs_monofasico.R.

#' @include ler_xml.R tabelas.R
NULL

CAMINHO_DAS_NOTAS_PARA_CONFERIR = "//NFe/infNFe"
# As regras de conta do item aceitam 0,01 a mais ou a menos; a soma da compra governamental, 0,04. As somas dos totais
# não dizem tolerância: têm de bater até o centavo. A alíquota efetiva vai em 4 casas, arredondada na última.
TOLERANCIA_DOS_VALORES = 0.01
TOLERANCIA_DA_COMPRA_GOVERNAMENTAL = 0.04
TOLERANCIA_DO_CENTAVO = 0.005
TOLERANCIA_DA_ALIQUOTA_EFETIVA = 0.00005
TOLERANCIA_DO_PERCENTUAL = 0.000001
FOLGA_DE_PONTO_FLUTUANTE = 1e-9

# A partir do infNFe.
CAMPOS_DA_NOTA_PARA_CONFERIR = ler_campos("
coluna                        caminho                                         tipo
numero                        ide/nNF                                         inteiro
modelo                        ide/mod                                         texto
tipo_impressao                ide/tpImp                                       texto
data_emissao                  ide/dhEmi                                       texto
autorizacao                   parent::NFe/parent::nfeProc/protNFe/infProt/dhRecbto texto
finalidade                    ide/finNFe                                      texto
tipo_nota_debito              ide/tpNFDebito                                  texto
tipo_nota_credito             ide/tpNFCredito                                 texto
redutor_compra_governamental  ide/gCompraGov/pRedutor                         numero
municipio_emitente            emit/enderEmit/cMun                             texto
municipio_destinatario        dest/enderDest/cMun                             texto
inscricao_suframa_emitente    emit/ISUFEmit                                   texto
uf_codigo                     ide/cUF                                         texto
ambiente                      ide/tpAmb                                       texto
tipo_operacao                 ide/tpNF                                        texto
destino_operacao              ide/idDest                                      texto
consumidor_final              ide/indFinal                                    texto
presenca                      ide/indPres                                     texto
data_saida                    ide/dhSaiEnt                                    texto
previsao_entrega              ide/dPrevEntrega                                texto
municipio_fato_gerador_ibs    ide/cMunFGIBS                                   texto
local_operacao                ide/cIndOp                                      texto
ente_governamental            ide/gCompraGov/tpEnteGov                        texto
operacao_governamental        ide/gCompraGov/tpOperGov                        texto
cnpj_emitente                 emit/CNPJ                                       texto
cpf_emitente                  emit/CPF                                        texto
uf_emitente                   emit/enderEmit/UF                               texto
regime_tributario             emit/CRT                                        texto
inscricao_suframa_destinatario dest/ISUF                                      texto
uf_destinatario               dest/enderDest/UF                               texto
indicador_ie_destinatario     dest/indIEDest                                  texto
uf_entrega                    entrega/UF                                      texto
modalidade_frete              transp/modFrete                                 texto
total_produtos                total/ICMSTot/vProd                             numero
total_ibs_monofasico          total/IBSCBSTot/gMono/vIBSMono                  numero
total_cbs_monofasica          total/IBSCBSTot/gMono/vCBSMono                  numero
total_ibs_monofasico_retencao total/IBSCBSTot/gMono/vIBSMonoReten             numero
total_cbs_monofasica_retencao total/IBSCBSTot/gMono/vCBSMonoReten             numero
total_ibs_monofasico_retido   total/IBSCBSTot/gMono/vIBSMonoRet               numero
total_cbs_monofasica_retida   total/IBSCBSTot/gMono/vCBSMonoRet               numero
total_base                    total/IBSCBSTot/vBCIBSCBS                       numero
total_diferimento_ibs_uf      total/IBSCBSTot/gIBS/gIBSUF/vDif                numero
total_devolvido_ibs_uf        total/IBSCBSTot/gIBS/gIBSUF/vDevTrib            numero
total_ibs_uf                  total/IBSCBSTot/gIBS/gIBSUF/vIBSUF              numero
total_diferimento_ibs_mun     total/IBSCBSTot/gIBS/gIBSMun/vDif               numero
total_devolvido_ibs_mun       total/IBSCBSTot/gIBS/gIBSMun/vDevTrib           numero
total_ibs_mun                 total/IBSCBSTot/gIBS/gIBSMun/vIBSMun            numero
total_ibs                     total/IBSCBSTot/gIBS/vIBS                       numero
total_credito_presumido_ibs   total/IBSCBSTot/gIBS/vCredPres                  numero
total_diferimento_cbs         total/IBSCBSTot/gCBS/vDif                       numero
total_devolvido_cbs           total/IBSCBSTot/gCBS/vDevTrib                   numero
total_cbs                     total/IBSCBSTot/gCBS/vCBS                       numero
total_credito_presumido_cbs   total/IBSCBSTot/gCBS/vCredPres                  numero
total_estorno_ibs             total/IBSCBSTot/gEstornoCred/vIBSEstCred        numero
total_estorno_cbs             total/IBSCBSTot/gEstornoCred/vCBSEstCred        numero
")

GRUPOS_DA_NOTA_PARA_CONFERIR = ler_campos("
coluna                    caminho
tem_total_ibs_cbs         total/IBSCBSTot
tem_compra_governamental  ide/gCompraGov
tem_total_is              total/ISTot
tem_retirada              retirada
tem_referencia            ide/NFref
")

# A partir de cada det. Os grupos da UF, do município e da CBS têm os mesmos campos, cada um com o seu final no nome.
CAMPOS_DO_ITEM_PARA_CONFERIR = ler_campos("
coluna                          caminho                                                       tipo
item                            @nItem                                                        inteiro
ncm                             prod/NCM                                                      texto
bem_movel_usado                 prod/indBemMovelUsado                                         texto
cst                             imposto/IBSCBS/CST                                            texto
classificacao                   imposto/IBSCBS/cClassTrib                                     texto
base                            imposto/IBSCBS/gIBSCBS/vBC                                    numero
aliquota_ibs_uf                 imposto/IBSCBS/gIBSCBS/gIBSUF/pIBSUF                          numero
diferimento_ibs_uf              imposto/IBSCBS/gIBSCBS/gIBSUF/gDif/pDif                       numero
valor_diferimento_ibs_uf        imposto/IBSCBS/gIBSCBS/gIBSUF/gDif/vDif                       numero
valor_devolvido_ibs_uf          imposto/IBSCBS/gIBSCBS/gIBSUF/gDevTrib/vDevTrib               numero
reducao_ibs_uf                  imposto/IBSCBS/gIBSCBS/gIBSUF/gRed/pRedAliq                   numero
aliquota_efetiva_ibs_uf         imposto/IBSCBS/gIBSCBS/gIBSUF/gRed/pAliqEfet                  numero
valor_ibs_uf                    imposto/IBSCBS/gIBSCBS/gIBSUF/vIBSUF                          numero
aliquota_ibs_mun                imposto/IBSCBS/gIBSCBS/gIBSMun/pIBSMun                        numero
diferimento_ibs_mun             imposto/IBSCBS/gIBSCBS/gIBSMun/gDif/pDif                      numero
valor_diferimento_ibs_mun       imposto/IBSCBS/gIBSCBS/gIBSMun/gDif/vDif                      numero
valor_devolvido_ibs_mun         imposto/IBSCBS/gIBSCBS/gIBSMun/gDevTrib/vDevTrib              numero
reducao_ibs_mun                 imposto/IBSCBS/gIBSCBS/gIBSMun/gRed/pRedAliq                  numero
aliquota_efetiva_ibs_mun        imposto/IBSCBS/gIBSCBS/gIBSMun/gRed/pAliqEfet                 numero
valor_ibs_mun                   imposto/IBSCBS/gIBSCBS/gIBSMun/vIBSMun                        numero
valor_ibs                       imposto/IBSCBS/gIBSCBS/vIBS                                   numero
aliquota_cbs                    imposto/IBSCBS/gIBSCBS/gCBS/pCBS                              numero
diferimento_cbs                 imposto/IBSCBS/gIBSCBS/gCBS/gDif/pDif                         numero
valor_diferimento_cbs           imposto/IBSCBS/gIBSCBS/gCBS/gDif/vDif                         numero
percentual_devolvido_cbs        imposto/IBSCBS/gIBSCBS/gCBS/gDevTrib/pDevTrib                 numero
valor_devolvido_cbs             imposto/IBSCBS/gIBSCBS/gCBS/gDevTrib/vDevTrib                 numero
reducao_cbs                     imposto/IBSCBS/gIBSCBS/gCBS/gRed/pRedAliq                     numero
aliquota_efetiva_cbs            imposto/IBSCBS/gIBSCBS/gCBS/gRed/pAliqEfet                    numero
valor_cbs                       imposto/IBSCBS/gIBSCBS/gCBS/vCBS                              numero
cst_regular                     imposto/IBSCBS/gIBSCBS/gTribRegular/CSTReg                    texto
classificacao_regular           imposto/IBSCBS/gIBSCBS/gTribRegular/cClassTribReg             texto
aliquota_regular_ibs_uf         imposto/IBSCBS/gIBSCBS/gTribRegular/pAliqEfetRegIBSUF         numero
valor_regular_ibs_uf            imposto/IBSCBS/gIBSCBS/gTribRegular/vTribRegIBSUF             numero
aliquota_regular_ibs_mun        imposto/IBSCBS/gIBSCBS/gTribRegular/pAliqEfetRegIBSMun        numero
valor_regular_ibs_mun           imposto/IBSCBS/gIBSCBS/gTribRegular/vTribRegIBSMun            numero
aliquota_regular_cbs            imposto/IBSCBS/gIBSCBS/gTribRegular/pAliqEfetRegCBS           numero
valor_regular_cbs               imposto/IBSCBS/gIBSCBS/gTribRegular/vTribRegCBS               numero
compra_governamental_ibs_uf     imposto/IBSCBS/gIBSCBS/gTribCompraGov/vTribIBSUF              numero
compra_governamental_ibs_mun    imposto/IBSCBS/gIBSCBS/gTribCompraGov/vTribIBSMun             numero
compra_governamental_cbs        imposto/IBSCBS/gIBSCBS/gTribCompraGov/vTribCBS                numero
credito_presumido_ibs           imposto/IBSCBS/gCredPresOper/gIBSCredPres/vCredPres           numero
credito_presumido_cbs           imposto/IBSCBS/gCredPresOper/gCBSCredPres/vCredPres           numero
credito_presumido_codigo        imposto/IBSCBS/gCredPresOper/cCredPres                        texto
credito_suspenso_ibs            imposto/IBSCBS/gCredPresOper/gIBSCredPres/vCredPresCondSus    numero
credito_suspenso_cbs            imposto/IBSCBS/gCredPresOper/gCBSCredPres/vCredPresCondSus    numero
valor_produto                   prod/vProd                                                    numero
cfop                            prod/CFOP                                                     texto
entra_no_total                  prod/indTot                                                   texto
quantidade_tributavel           prod/qTrib                                                    numero
tipo_credito_zfm_produto        prod/tpCredPresIBSZFM                                         texto
produto_anp                     prod/comb/cProdANP                                            texto
percentual_biocombustivel       prod/comb/pBio                                                numero
cst_icms                        imposto/ICMS/*/CST                                            texto
csosn                           imposto/ICMS/*/CSOSN                                          texto
referenciado_chave              DFeReferenciado/chaveAcesso                                   texto
referenciado_item               DFeReferenciado/nItem                                         texto
monofasico_ibs                  imposto/IBSCBS/gIBSCBSMono//vIBSMono                          numero
monofasico_cbs                  imposto/IBSCBS/gIBSCBSMono//vCBSMono                          numero
monofasico_ibs_retencao         imposto/IBSCBS/gIBSCBSMono//vIBSMonoReten                     numero
monofasico_cbs_retencao         imposto/IBSCBS/gIBSCBSMono//vCBSMonoReten                     numero
monofasico_ibs_retido           imposto/IBSCBS/gIBSCBSMono//vIBSMonoRet                       numero
monofasico_cbs_retido           imposto/IBSCBS/gIBSCBSMono//vCBSMonoRet                       numero
estorno_ibs                     imposto/IBSCBS/gEstornoCred/vIBSEstCred                       numero
estorno_cbs                     imposto/IBSCBS/gEstornoCred/vCBSEstCred                       numero
tipo_area_incentivada_cbs       imposto/IBSCBS/gIBSCBS/gCBS/gALCZFMCBS/tpALCZFMCBS            texto
processo_suframa                imposto/IBSCBS/gIBSCBS/gCBS/gALCZFMCBS/nProcSuframa           texto
aliquota_sem_area_incentivada   imposto/IBSCBS/gIBSCBS/gCBS/gALCZFMCBS/pAliqEfetRegCBS        numero
valor_sem_area_incentivada      imposto/IBSCBS/gIBSCBS/gCBS/gALCZFMCBS/vTribRegCBS            numero
transferencia_ibs               imposto/IBSCBS/gTransfCred/vIBS                               numero
transferencia_cbs               imposto/IBSCBS/gTransfCred/vCBS                               numero
ajuste_competencia_ibs          imposto/IBSCBS/gAjusteCompet/vIBS                             numero
ajuste_competencia_cbs          imposto/IBSCBS/gAjusteCompet/vCBS                             numero
competencia_credito_zfm         imposto/IBSCBS/gCredPresIBSZFM/competApur                     texto
tipo_credito_zfm                imposto/IBSCBS/gCredPresIBSZFM/tpCredPresIBSZFM               texto
")

GRUPOS_DO_ITEM_PARA_CONFERIR = ler_campos("
coluna                          caminho
tem_ibs_cbs                     imposto/IBSCBS
tem_grupo_ibs_cbs               imposto/IBSCBS/gIBSCBS
tem_monofasico                  imposto/IBSCBS/gIBSCBSMono
tem_transferencia_credito       imposto/IBSCBS/gTransfCred
tem_ajuste_competencia          imposto/IBSCBS/gAjusteCompet
tem_estorno_credito             imposto/IBSCBS/gEstornoCred
tem_credito_presumido           imposto/IBSCBS/gCredPresOper
tem_credito_presumido_ibs       imposto/IBSCBS/gCredPresOper/gIBSCredPres
tem_credito_presumido_cbs       imposto/IBSCBS/gCredPresOper/gCBSCredPres
tem_credito_presumido_zfm       imposto/IBSCBS/gCredPresIBSZFM
tem_diferimento_ibs_uf          imposto/IBSCBS/gIBSCBS/gIBSUF/gDif
tem_devolucao_ibs_uf            imposto/IBSCBS/gIBSCBS/gIBSUF/gDevTrib
tem_reducao_ibs_uf              imposto/IBSCBS/gIBSCBS/gIBSUF/gRed
tem_diferimento_ibs_mun         imposto/IBSCBS/gIBSCBS/gIBSMun/gDif
tem_devolucao_ibs_mun           imposto/IBSCBS/gIBSCBS/gIBSMun/gDevTrib
tem_reducao_ibs_mun             imposto/IBSCBS/gIBSCBS/gIBSMun/gRed
tem_diferimento_cbs             imposto/IBSCBS/gIBSCBS/gCBS/gDif
tem_devolucao_cbs               imposto/IBSCBS/gIBSCBS/gCBS/gDevTrib
tem_reducao_cbs                 imposto/IBSCBS/gIBSCBS/gCBS/gRed
tem_area_incentivada_cbs        imposto/IBSCBS/gIBSCBS/gCBS/gALCZFMCBS
tem_tributacao_regular          imposto/IBSCBS/gIBSCBS/gTribRegular
tem_compra_governamental_item   imposto/IBSCBS/gIBSCBS/gTribCompraGov
tem_combustivel                 prod/comb
tem_icms                        imposto/ICMS
tem_origem_icms                 imposto/ICMS/*/orig
tem_icms_partilha               imposto/ICMS/ICMSPart
tem_issqn                       imposto/ISSQN
tem_ipi                         imposto/IPI
tem_ii                          imposto/II
tem_pis                         imposto/PIS
tem_pis_st                      imposto/PISST
tem_cofins                      imposto/COFINS
tem_cofins_st                   imposto/COFINSST
tem_icms_uf_destino             imposto/ICMSUFDest
tem_imposto_devolvido           impostoDevol
tem_is                          imposto/IS
tem_dfe_referenciado            DFeReferenciado
")

# Os municípios das áreas incentivadas da regra UB56-10 (exceção 3): a CBS pode ser zero quando o emitente e o
# destinatário estão na mesma área (os três municípios da ZFM entre si, e cada ALC com os seus).
AREAS_INCENTIVADAS = ler_campos("
municipio area
1301902   ZFM
1302603   ZFM
1303569   ZFM
1304062   ALC1
1100106   ALC2
1400100   ALC3
1400159   ALC3
1600303   ALC4
1600600   ALC4
1200104   ALC5
1200252   ALC5
1200203   ALC5
")
AREAS_INCENTIVADAS$municipio = as.character(AREAS_INCENTIVADAS$municipio)

# O que cada regra consulta nas tabelas do IBS e da CBS: a tabela, a coluna (ou "existe", para o código) e o campo do
# item com o código; os modelos em que a consulta vale. É por aqui que a conferência acha, para uma nota antiga, a
# mudança da tabela que a SEFAZ talvez não usou (tabela_fiscal("mudancas_ibs_cbs")).
CONSULTAS_DAS_REGRAS = ler_campos("
regra     tabela                 coluna                       campo_do_codigo        modelos
UB13-10   cst_ibs_cbs            existe                       cst                    55/65
UB13-20   cst_ibs_cbs            grupo_ibs_cbs                cst                    55/65
UB13-30   cst_ibs_cbs            grupo_ibs_cbs                cst                    55/65
UB13-39   cst_ibs_cbs            grupo_monofasico             cst                    55/65
UB13-44   cst_ibs_cbs            grupo_transferencia_credito  cst                    55/65
UB13-45   cst_ibs_cbs            grupo_transferencia_credito  cst                    55/65
UB112-10  cst_ibs_cbs            grupo_ajuste_competencia     cst                    55/65
UB112-20  cst_ibs_cbs            grupo_ajuste_competencia     cst                    55/65
UB131-20  cst_ibs_cbs            grupo_credito_presumido_zfm  cst                    55/65
UB131-30  cst_ibs_cbs            grupo_credito_presumido_zfm  cst                    55/65
UB22-10   cst_ibs_cbs            grupo_diferimento            cst                    55/65
UB22-20   cst_ibs_cbs            grupo_diferimento            cst                    55/65
UB40-10   cst_ibs_cbs            grupo_diferimento            cst                    55/65
UB40-20   cst_ibs_cbs            grupo_diferimento            cst                    55/65
UB59-10   cst_ibs_cbs            grupo_diferimento            cst                    55/65
UB59-20   cst_ibs_cbs            grupo_diferimento            cst                    55/65
UB26-10   cst_ibs_cbs            grupo_reducao                cst                    55/65
UB26-20   cst_ibs_cbs            grupo_reducao                cst                    55/65
UB45-10   cst_ibs_cbs            grupo_reducao                cst                    55/65
UB45-20   cst_ibs_cbs            grupo_reducao                cst                    55/65
UB64-10   cst_ibs_cbs            grupo_reducao                cst                    55/65
UB64-20   cst_ibs_cbs            grupo_reducao                cst                    55/65
UB27-10   cst_ibs_cbs            grupo_reducao                cst                    55/65
UB46-10   cst_ibs_cbs            grupo_reducao                cst                    55/65
UB65-10   cst_ibs_cbs            grupo_reducao                cst                    55/65
UB27-10   classificacao_ibs_cbs  reducao_ibs                  classificacao          55/65
UB46-10   classificacao_ibs_cbs  reducao_ibs                  classificacao          55/65
UB65-10   classificacao_ibs_cbs  reducao_cbs                  classificacao          55/65
UB82a-10  cst_ibs_cbs            grupo_ibs_cbs                cst                    55/65
UB69-10   cst_ibs_cbs            existe                       cst_regular            55/65
UB14-10   classificacao_ibs_cbs  existe                       classificacao          55/65
UB14-25   classificacao_ibs_cbs  permitido_na_nfe             classificacao          55
UB14-25   classificacao_ibs_cbs  permitido_na_nfce            classificacao          65
UB68-10   classificacao_ibs_cbs  grupo_tributacao_regular     classificacao          55/65
UB68-11   classificacao_ibs_cbs  grupo_tributacao_regular     classificacao          55/65
UB116-10  classificacao_ibs_cbs  grupo_estorno_credito        classificacao          55/65
UB116-20  classificacao_ibs_cbs  grupo_estorno_credito        classificacao          55/65
UB120-20  classificacao_ibs_cbs  grupo_credito_presumido      classificacao          55/65
UB18-10   classificacao_ibs_cbs  grupo_tributacao_regular     classificacao          55/65
UB37-10   classificacao_ibs_cbs  grupo_tributacao_regular     classificacao          55/65
UB56-10   classificacao_ibs_cbs  grupo_tributacao_regular     classificacao          55/65
UB56-20   classificacao_ibs_cbs  grupo_tributacao_regular     classificacao          55/65
UB70-10   classificacao_ibs_cbs  existe                       classificacao_regular  55/65
UB122-10  credito_presumido_ibs_cbs  existe                   credito_presumido_codigo  55/65
UB123-10  credito_presumido_ibs_cbs  grupo_credito_ibs        credito_presumido_codigo  55/65
UB123-20  credito_presumido_ibs_cbs  grupo_credito_ibs        credito_presumido_codigo  55/65
UB127-10  credito_presumido_ibs_cbs  grupo_credito_cbs        credito_presumido_codigo  55/65
UB127-20  credito_presumido_ibs_cbs  grupo_credito_cbs        credito_presumido_codigo  55/65
UB54a-10  credito_presumido_ibs_cbs  deduz_do_tributo         credito_presumido_codigo  55/65
UB86-10   classificacao_ibs_cbs  grupo_monofasico_padrao      classificacao          55/65
UB86-20   classificacao_ibs_cbs  grupo_monofasico_padrao      classificacao          55/65
UB91-10   classificacao_ibs_cbs  grupo_monofasico_padrao      classificacao          55/65
UB91-20   classificacao_ibs_cbs  grupo_monofasico_padrao      classificacao          55/65
UB96-10   classificacao_ibs_cbs  grupo_monofasico_padrao      classificacao          55/65
UB96-20   classificacao_ibs_cbs  grupo_monofasico_padrao      classificacao          55/65
UB101-10  classificacao_ibs_cbs  grupo_monofasico_padrao      classificacao          55/65
UB101-20  classificacao_ibs_cbs  grupo_monofasico_padrao      classificacao          55/65
UB87-10   classificacao_ibs_cbs  grupo_monofasico_retencao    classificacao          55/65
UB87-20   classificacao_ibs_cbs  grupo_monofasico_retencao    classificacao          55/65
UB92-10   classificacao_ibs_cbs  grupo_monofasico_retencao    classificacao          55/65
UB92-20   classificacao_ibs_cbs  grupo_monofasico_retencao    classificacao          55/65
UB97-10   classificacao_ibs_cbs  grupo_monofasico_retencao    classificacao          55/65
UB97-20   classificacao_ibs_cbs  grupo_monofasico_retencao    classificacao          55/65
UB102-10  classificacao_ibs_cbs  grupo_monofasico_retencao    classificacao          55/65
UB102-20  classificacao_ibs_cbs  grupo_monofasico_retencao    classificacao          55/65
UB88-10   classificacao_ibs_cbs  grupo_monofasico_retido      classificacao          55/65
UB88-20   classificacao_ibs_cbs  grupo_monofasico_retido      classificacao          55/65
UB93-10   classificacao_ibs_cbs  grupo_monofasico_retido      classificacao          55/65
UB93-20   classificacao_ibs_cbs  grupo_monofasico_retido      classificacao          55/65
UB98-10   classificacao_ibs_cbs  grupo_monofasico_retido      classificacao          55/65
UB98-20   classificacao_ibs_cbs  grupo_monofasico_retido      classificacao          55/65
UB103-10  classificacao_ibs_cbs  grupo_monofasico_retido      classificacao          55/65
UB103-20  classificacao_ibs_cbs  grupo_monofasico_retido      classificacao          55/65
UB89-10   classificacao_ibs_cbs  grupo_diferenca_biocombustivel classificacao        55/65
UB89-20   classificacao_ibs_cbs  grupo_diferenca_biocombustivel classificacao        55/65
UB94-10   classificacao_ibs_cbs  grupo_diferenca_biocombustivel classificacao        55/65
UB94-20   classificacao_ibs_cbs  grupo_diferenca_biocombustivel classificacao        55/65
UB99-10   classificacao_ibs_cbs  grupo_diferenca_biocombustivel classificacao        55/65
UB99-20   classificacao_ibs_cbs  grupo_diferenca_biocombustivel classificacao        55/65
UB104-10  classificacao_ibs_cbs  grupo_diferenca_biocombustivel classificacao        55/65
UB104-20  classificacao_ibs_cbs  grupo_diferenca_biocombustivel classificacao        55/65
")

# As somas dos totais (regras W): a regra, o campo do total, a coluna do total na nota e a coluna do item que soma.
TOTAIS_PARA_CONFERIR = ler_campos("
regra    campo                       coluna_do_total               coluna_do_item
W35-10   vBCIBSCBS                   total_base                    base
W38-10   gIBSUF/vDif                 total_diferimento_ibs_uf      valor_diferimento_ibs_uf
W39-10   gIBSUF/vDevTrib             total_devolvido_ibs_uf        valor_devolvido_ibs_uf
W41-10   gIBSUF/vIBSUF               total_ibs_uf                  valor_ibs_uf
W43-10   gIBSMun/vDif                total_diferimento_ibs_mun     valor_diferimento_ibs_mun
W44-10   gIBSMun/vDevTrib            total_devolvido_ibs_mun       valor_devolvido_ibs_mun
W46-10   gIBSMun/vIBSMun             total_ibs_mun                 valor_ibs_mun
W47-10   gIBS/vIBS                   total_ibs                     valor_ibs
W48-10   gIBS/vCredPres              total_credito_presumido_ibs   credito_presumido_ibs
W53-10   gCBS/vDif                   total_diferimento_cbs         valor_diferimento_cbs
W54-10   gCBS/vDevTrib               total_devolvido_cbs           valor_devolvido_cbs
W56-10   gCBS/vCBS                   total_cbs                     valor_cbs
W56a-10  gCBS/vCredPres              total_credito_presumido_cbs   credito_presumido_cbs
W59f-10  gEstornoCred/vIBSEstCred    total_estorno_ibs             estorno_ibs
W59g-10  gEstornoCred/vCBSEstCred    total_estorno_cbs             estorno_cbs
W58-10   gMono/vIBSMono              total_ibs_monofasico          monofasico_ibs
W59-10   gMono/vCBSMono              total_cbs_monofasica          monofasico_cbs
W59a-10  gMono/vIBSMonoReten         total_ibs_monofasico_retencao monofasico_ibs_retencao
W59b-10  gMono/vCBSMonoReten         total_cbs_monofasica_retencao monofasico_cbs_retencao
W59c-10  gMono/vIBSMonoRet           total_ibs_monofasico_retido   monofasico_ibs_retido
W59d-10  gMono/vCBSMonoRet           total_cbs_monofasica_retida   monofasico_cbs_retido
")

#' Conferir o IBS e a CBS de uma NF-e ou NFC-e
#'
#' Confere o IBS e a CBS de cada item e os totais da NF-e e da NFC-e pelas
#' regras de validação da Nota Técnica 2025.002-RTC: o que a SEFAZ rejeitaria
#' ao autorizar a nota. Cada conferência diz a regra (por exemplo, `UB35-10`),
#' o código e a mensagem da rejeição, o que está no documento, o que a regra
#' espera e, nas contas, a diferença. Lê o XML como [nfe_ler()]: um arquivo,
#' vários ou o próprio texto.
#'
#' O que é conferido:
#' - os códigos: o CST e a classificação tributária (`cClassTrib`) existem, a
#'   classificação é do CST e vale no modelo do documento;
#' - os grupos: o que cada CST e cada classificação exige ou não permite no
#'   item (diferimento, redução, devolução, tributação regular, transferência
#'   de crédito, ajuste de competência, estorno de crédito, crédito presumido,
#'   compra governamental), pelos indicadores da planilha oficial (veja
#'   `tabela_fiscal("cst_ibs_cbs")` e `tabela_fiscal("classificacao_ibs_cbs")`);
#' - a nota de débito e de crédito: a classificação combina com o tipo da
#'   nota; a transferência de crédito, o ajuste de competência e o estorno com
#'   valor; o crédito presumido da ZFM só na nota de crédito do tipo 02;
#' - o crédito presumido da operação, pela tabela de crédito presumido (veja
#'   `tabela_fiscal("credito_presumido_ibs_cbs")`): o código existe, os grupos
#'   do IBS e da CBS que ele exige ou não permite, o limite do código 04 e o
#'   crédito em condição suspensiva;
#' - a CBS zero na área incentivada (ZFM e ALC): a inscrição na Suframa, o NCM,
#'   a mesma área do emitente e do destinatário e o valor sem a redução;
#' - as alíquotas do ano (veja `tabela_fiscal("aliquotas_ibs_cbs")`), com as
#'   exceções da NT: a tributação regular, a devolução, as notas de crédito e,
#'   na CBS, as áreas incentivadas (ZFM e ALC);
#' - as contas: o percentual de redução da classificação, a alíquota efetiva
#'   (em 4 casas), o diferimento, a devolução da CBS, os valores do IBS da UF,
#'   do município e da CBS, o IBS do item, a tributação regular e a soma da
#'   compra governamental, com a tolerância que cada regra dá (0,01 nas contas
#'   do item, 0,04 na compra governamental), depois de arredondar o valor
#'   calculado em 2 casas, como o campo;
#' - os totais (`IBSCBSTot`): a soma de cada campo nos itens, até o centavo;
#' - a tributação monofásica de combustíveis, no leiaute da versão 1.50 da NT:
#'   os grupos de cada ano (ad rem e ad valorem, do IBS e da CBS), os
#'   subgrupos que a classificação exige ou não permite, as contas (a
#'   quantidade vezes a alíquota ad rem; a ad valorem só confere quando bate
#'   com a alíquota lida como percentual, porque a NT não diz a unidade, e
#'   senão fica sem conferir), a quantidade de biocombustível pela mistura
#'   obrigatória na data da nota (veja
#'   `tabela_fiscal("biocombustivel_ibs_cbs")`; o `pBio` do XML é percentual,
#'   a tabela traz fração) e os totais do grupo `gMono`;
#' - o resto da nota que a mesma NT valida: a identificação (a previsão de
#'   entrega, os documentos referenciados, a nota de débito e de crédito, a
#'   NFC-e, o município do fato gerador do IBS e o local da operação, veja
#'   `tabela_fiscal("local_operacao_ibs_cbs")`), a compra governamental (o
#'   tipo da operação, as alíquotas nos anos de transição e as chaves dos
#'   documentos anteriores), a inscrição na Suframa do emitente e do
#'   destinatário (com o dígito), os tributos de cada item na nota de débito e
#'   de crédito, o CFOP da devolução, o ICMS monofásico (veja
#'   `tabela_fiscal("combustiveis_monofasicos")`), o documento referenciado no
#'   item, o total dos produtos (até o centavo) e o grupo do Imposto Seletivo
#'   nos totais.
#'
#' Como na NT, as regras só valem para o documento com o IBS, a CBS ou o
#' Imposto Seletivo preenchidos: a nota sem eles não é conferida.
#'
#' Cada regra vale como a SEFAZ a aplicava no dia da emissão (`dhEmi`):
#' - a regra só é conferida na nota emitida depois de ela entrar em produção
#'   (pelo cronograma da NT: 10/11/2025 para a maioria, 02/02/2026 e
#'   03/08/2026 para as que entraram depois, e 16/11/2026 para o monofásico
#'   da versão 1.50 e as mudanças da devolução da versão 1.53);
#' - quando a regra mudou depois da emissão, ou quando a linha do CST ou da
#'   classificação que ela consulta mudou numa versão da tabela que talvez
#'   ainda não estivesse em produção (veja
#'   `tabela_fiscal("mudancas_ibs_cbs")`), o que não confere pela regra e pela
#'   tabela de hoje vem com `confere` vazio e o motivo, em vez de errado.
#'   A versão da tabela sem prazo de produção no Informe Técnico (da 1.21 à
#'   1.40) fica sem prazo conhecido;
#' - a mudança que só afrouxou a regra (uma exceção nova) vale também para a
#'   nota de antes: o que confere hoje é dado como certo;
#' - quando a SEFAZ autorizou notas reais contra o texto da regra num caso que
#'   a NT não deixa claro (o `tpCredPresIBSZFM` 0 fora da ZFM, a classificação
#'   620 sem o grupo de combustível antes de 16/11/2026, um centavo de
#'   diferença no total dos produtos), esse caso fica sem conferir, com o
#'   motivo. A redação antiga da VC02-14 (a referência na devolução) vale até
#'   15/11/2026, e a da versão 1.53 desde 16/11/2026.
#'
#' Fica de fora: as regras que a NT deixa para implementação futura (as do
#' Imposto Seletivo, a da base de cálculo, UB16-10, e a exigência do grupo
#' monofásico pelo CST, UB13-40, entre outras); as que a SEFAZ confere no
#' documento guardado na base dela (BB05-170, BB05-190, BB05-200 e VC02-50); e
#' o CT-e e os outros documentos, que têm as notas técnicas deles. Uma regra
#' que se aplica mas não dá para conferir (a CBS de 2027 em diante, sem a
#' alíquota de referência publicada; o valor da diferença do biocombustível,
#' UB89b-10 e UB99b-10, sem a tabela que a NT diz que será publicada) vem com
#' `confere` vazio e o motivo.
#'
#' @section notas:
#' Uma linha por nota (a mesma nota repetida num arquivo é conferida uma vez):
#' `chave`, `numero`, `modelo`, `data_emissao`,
#' `itens_com_ibs_cbs` (quantos itens têm o grupo `IBSCBS`),
#' `regras_conferidas`, `regras_erradas` e `regras_sem_conferir` (que se
#' aplicavam mas não deu para conferir).
#'
#' @section conferencias:
#' Uma linha por regra que se aplica a cada item, ou à nota nas regras da nota
#' (e, na BB05, a cada chave anterior da compra governamental):
#' `chave`, `item` (o `nItem`; vazio nas regras da nota), `regra`, `campo` (o campo ou
#' o grupo conferido), `no_documento` (o que está no XML), `esperado` (o que a
#' regra espera), `diferenca` (nas contas: o do documento menos o calculado),
#' `confere` (`TRUE`, `FALSE` ou vazio quando não deu para conferir),
#' `codigo_sefaz` e `mensagem` (a rejeição que a SEFAZ daria, como na NT) e
#' `observacao`. Só as que não conferem ou não deu para conferir, a menos que
#' `todas_as_regras = TRUE`.
#'
#' @param arquivos Os XMLs da NF-e ou da NFC-e: o caminho de um arquivo, um
#'   vetor com vários ou o próprio texto do XML (começando por `<`).
#' @param todas_as_regras `TRUE` traz em `conferencias` também as regras que
#'   conferem.
#' @return Uma lista com os `data.frame`s `notas`, `conferencias` e `arquivos`
#'   (o que foi lido e o motivo do que não deu, como em [nfe_ler()]).
#' @source Nota Técnica 2025.002-RTC, versão 1.53 (Portal Nacional da NF-e,
#'   publicada em 30/10/2026), seção 7, regras de validação dos grupos UB
#'   (IBS e CBS do item), W (totais) e dos outros grupos que dependem da
#'   Reforma (B, BB, C, E, I, LA, N, NA, Q, S e VC); a Tabela de Classificação
#'   Tributária do IBS e CBS (Informe Técnico 2025.002, v1.71) e a de Crédito
#'   Presumido; a LC 214/2025 (as alíquotas de cada ano); o Anexo VII da
#'   documentação da NFS-e Nacional (o local da operação); a Tabela de Índice
#'   de Biocombustível (Informe Técnico 2025.004); e a tabela de combustíveis
#'   do ICMS monofásico do Portal da NF-e. Veja [tabela_fiscal()]. Na VC02-04,
#'   também a Nota Técnica 2026.002, versão 1.11 (a NF-e com DANFE Simplificado
#'   Tipo 2).
#' @seealso [nfe_ler()] para ler as notas; [tabela_fiscal()] para as tabelas
#'   que a conferência consulta.
#' @examples
#' nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")
#' conferida = ibs_cbs_conferir(nota)
#' conferida$notas
#' todas = ibs_cbs_conferir(nota, todas_as_regras = TRUE)$conferencias
#' todas[todas$item %in% 1, c("regra", "campo", "no_documento", "esperado", "confere")]
#' @export
ibs_cbs_conferir = function(arquivos, todas_as_regras = FALSE) {
  if (!isTRUE(todas_as_regras) && !isFALSE(todas_as_regras)) {
    stop("Informe todas_as_regras = TRUE ou FALSE.", call. = FALSE)
  }
  arquivos_lidos = ler_arquivos_xml(arquivos, CAMINHO_DAS_NOTAS_PARA_CONFERIR, "uma NF-e", colunas_da_conferencia, FALSE)
  colunas_vazias = colunas_da_conferencia(NULL, NA_character_, FALSE)
  notas = juntar_tabela(arquivos_lidos, "notas", colunas_vazias$notas)
  conferencias = juntar_tabela(arquivos_lidos, "conferencias", colunas_vazias$conferencias)
  if (!todas_as_regras) {
    conferencias = conferencias[!(conferencias$confere %in% TRUE), ]
    rownames(conferencias) = NULL
  }
  list(notas = notas, conferencias = conferencias, arquivos = resumo_dos_arquivos(arquivos_lidos, "notas", "notas"))
}

# As colunas das tabelas de um arquivo: a conferência de cada nota e o resumo delas. Com xml_lido NULL, vêm vazias, com
# os nomes e os tipos certos. Com `agora` (o nfe_conferir), a nota sem o protocolo é conferida como recebida pela SEFAZ
# nesse momento.
colunas_da_conferencia = function(xml_lido, nome_do_arquivo, todos_os_campos, agora = NULL) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  elementos_das_notas = buscar_todos(xml_lido, CAMINHO_DAS_NOTAS_PARA_CONFERIR)
  # A mesma nota repetida no arquivo é conferida uma vez (as contagens por chave contariam os itens dela duas vezes).
  elementos_das_notas = elementos_das_notas[!duplicated(chave_de_cada(elementos_das_notas, "infNFe"))]
  elementos_dos_itens = buscar_todos(elementos_das_notas, "det")
  notas = data.frame(
    c(list(chave = chave_de_cada(elementos_das_notas, "infNFe")),
      valores_dos_campos(elementos_das_notas, CAMPOS_DA_NOTA_PARA_CONFERIR),
      presenca_dos_grupos(elementos_das_notas, GRUPOS_DA_NOTA_PARA_CONFERIR))
  )
  notas$data_emissao = as.Date(substr(notas$data_emissao, 1, 10))
  notas$recebimento_pelo_envio = rep(FALSE, nrow(notas))
  if (!is.null(agora)) {
    notas$recebimento_pelo_envio = is.na(notas$autorizacao)
    notas$autorizacao[notas$recebimento_pelo_envio] = format(agora, "%Y-%m-%dT%H:%M:%S", tz = "America/Sao_Paulo")
  }
  itens_lidos = data.frame(
    c(list(chave = chave_de_cada(elementos_dos_itens, "infNFe")),
      valores_dos_campos(elementos_dos_itens, CAMPOS_DO_ITEM_PARA_CONFERIR),
      valores_dos_campos(elementos_dos_itens, CAMPOS_DO_MONOFASICO),
      presenca_dos_grupos(elementos_dos_itens, GRUPOS_DO_ITEM_PARA_CONFERIR),
      presenca_dos_grupos(elementos_dos_itens, GRUPOS_DO_MONOFASICO_NO_ITEM))
  )
  # As regras da NT só valem no documento com o IBS, a CBS ou o Imposto Seletivo preenchidos (nota ** do cronograma).
  itens_com_tributo_novo = itens_lidos$chave[itens_lidos$tem_ibs_cbs | itens_lidos$tem_is]
  notas_conferidas = notas[notas$chave %in% itens_com_tributo_novo | notas$tem_total_ibs_cbs | notas$tem_total_is, ]
  itens_da_nota = preparar_os_itens(itens_lidos[itens_lidos$chave %in% notas_conferidas$chave, ], notas_conferidas)
  itens = itens_da_nota[itens_da_nota$tem_ibs_cbs, ]
  referencias = referencias_das_notas(elementos_das_notas)
  chaves_anteriores = chaves_da_compra_governamental(elementos_das_notas)
  conferencias = juntar_linhas(list(
    conferir_os_codigos(itens),
    conferir_os_grupos(itens),
    conferir_as_notas_de_debito_e_credito(itens),
    conferir_a_area_incentivada_da_cbs(itens),
    conferir_o_credito_presumido(itens),
    conferir_as_aliquotas(itens),
    conferir_as_contas(itens),
    conferir_o_monofasico(itens),
    conferir_a_identificacao_da_nota(notas_conferidas, referencias),
    conferir_a_compra_governamental(notas_conferidas, chaves_anteriores),
    conferir_o_emitente_e_o_destinatario(notas_conferidas),
    conferir_os_itens_da_nota(itens_da_nota, referencias),
    conferir_os_totais(itens_da_nota, notas_conferidas),
    conferir_os_outros_totais(itens_da_nota, notas_conferidas)
  ))
  conferencias = completar_com_as_regras(data.frame(conferencias), notas, itens_da_nota)

  resumo = data.frame(
    chave = notas$chave, numero = notas$numero, modelo = notas$modelo, data_emissao = notas$data_emissao,
    itens_com_ibs_cbs = as.integer(table(factor(itens$chave, levels = notas$chave))),
    regras_conferidas = as.integer(table(factor(conferencias$chave[!is.na(conferencias$confere)], levels = notas$chave))),
    regras_erradas = as.integer(table(factor(conferencias$chave[conferencias$confere %in% FALSE], levels = notas$chave))),
    regras_sem_conferir = as.integer(table(factor(conferencias$chave[is.na(conferencias$confere)], levels = notas$chave)))
  )
  list(notas = as.list(resumo), conferencias = as.list(conferencias))
}

# TRUE onde o grupo existe em cada elemento.
presenca_dos_grupos = function(elementos, grupos) {
  colunas = list()
  for (numero_do_grupo in seq_len(nrow(grupos))) {
    achados = xml2::xml_find_first(elementos, grupos$caminho[numero_do_grupo], ns = SEM_NAMESPACE)
    colunas[[grupos$coluna[numero_do_grupo]]] = !is.na(xml2::xml_name(achados))
  }
  colunas
}

# Ao lado de cada item: os campos da nota dele, os indicadores do CST e da classificação, as alíquotas do ano e a
# alíquota que entra na conta (a efetiva, quando há redução).
preparar_os_itens = function(itens, notas) {
  da_nota = match(itens$chave, notas$chave)
  for (coluna in c("modelo", "tipo_impressao", "data_emissao", "autorizacao", "recebimento_pelo_envio", "finalidade", "tipo_nota_debito",
                   "tipo_nota_credito",
                   "redutor_compra_governamental", "municipio_emitente", "municipio_destinatario",
                   "inscricao_suframa_emitente", "tem_compra_governamental", "ambiente", "tipo_operacao",
                   "destino_operacao", "consumidor_final", "indicador_ie_destinatario", "uf_emitente", "uf_entrega",
                   "regime_tributario", "operacao_governamental", "ente_governamental", "tem_referencia")) {
    itens[[coluna]] = notas[[coluna]][da_nota]
  }
  tabela_de_cst = tabela_fiscal("cst_ibs_cbs")
  tabela_de_classificacao = tabela_fiscal("classificacao_ibs_cbs")
  do_cst = match(itens$cst, tabela_de_cst$codigo)
  da_classificacao = match(itens$classificacao, tabela_de_classificacao$codigo)
  itens$cst_existe = !is.na(do_cst)
  itens$classificacao_existe = !is.na(da_classificacao)
  itens$cst_da_classificacao = tabela_de_classificacao$cst[da_classificacao]
  itens$permitido_no_modelo = ifelse(itens$modelo == "65", tabela_de_classificacao$permitido_na_nfce[da_classificacao],
                                     tabela_de_classificacao$permitido_na_nfe[da_classificacao])
  # Os indicadores do CST e da classificação: 1 = o grupo é exigido, 0 = não é permitido; NA quando o código não existe.
  for (indicador in c("grupo_ibs_cbs", "grupo_monofasico", "grupo_reducao", "grupo_diferimento",
                      "grupo_transferencia_credito", "grupo_credito_presumido_zfm", "grupo_ajuste_competencia")) {
    itens[[indicador]] = tabela_de_cst[[indicador]][do_cst]
  }
  for (indicador in c("grupo_tributacao_regular", "grupo_estorno_credito", "grupo_credito_presumido",
                      "reducao_ibs", "reducao_cbs", "grupo_monofasico_padrao", "grupo_monofasico_retencao",
                      "grupo_monofasico_retido", "grupo_diferenca_biocombustivel")) {
    itens[[paste0(indicador, "_da_classificacao")]] = tabela_de_classificacao[[indicador]][da_classificacao]
  }
  tabela_do_credito = tabela_fiscal("credito_presumido_ibs_cbs")
  do_credito = match(itens$credito_presumido_codigo, tabela_do_credito$codigo)
  itens$credito_presumido_existe = !is.na(do_credito)
  for (indicador in c("grupo_credito_ibs", "grupo_credito_cbs", "deduz_do_tributo")) {
    itens[[indicador]] = tabela_do_credito[[indicador]][do_credito]
  }
  aliquotas = tabela_fiscal("aliquotas_ibs_cbs")
  linha_do_ano = rep(NA_integer_, nrow(itens))
  for (numero_da_linha in seq_len(nrow(aliquotas))) {
    no_periodo = !is.na(itens$data_emissao) & itens$data_emissao >= aliquotas$inicio[numero_da_linha] &
      itens$data_emissao <= aliquotas$fim[numero_da_linha]
    linha_do_ano[no_periodo] = numero_da_linha
  }
  itens$tem_aliquota_do_ano = !is.na(linha_do_ano)
  itens$aliquota_do_ano_ibs_uf = aliquotas$aliquota_ibs_uf[linha_do_ano]
  itens$aliquota_do_ano_ibs_mun = aliquotas$aliquota_ibs_municipio[linha_do_ano]
  itens$aliquota_do_ano_cbs = aliquotas$aliquota_cbs[linha_do_ano]
  itens$aliquota_usada_ibs_uf = ifelse(itens$tem_reducao_ibs_uf, itens$aliquota_efetiva_ibs_uf, itens$aliquota_ibs_uf)
  itens$aliquota_usada_ibs_mun = ifelse(itens$tem_reducao_ibs_mun, itens$aliquota_efetiva_ibs_mun, itens$aliquota_ibs_mun)
  itens$aliquota_usada_cbs = ifelse(itens$tem_reducao_cbs, itens$aliquota_efetiva_cbs, itens$aliquota_cbs)
  area_do_emitente = AREAS_INCENTIVADAS$area[match(itens$municipio_emitente, AREAS_INCENTIVADAS$municipio)]
  area_do_destinatario = AREAS_INCENTIVADAS$area[match(itens$municipio_destinatario, AREAS_INCENTIVADAS$municipio)]
  itens$mesma_area_incentivada = !is.na(area_do_emitente) & area_do_emitente %in% area_do_destinatario
  itens$ncm_fora_da_area_incentivada = ncm_sem_cbs_zero_na_area_incentivada(itens$ncm)
  itens
}

# Os NCM que a exceção 3 da regra UB56-10 deixa de fora: armas e munições (93), fumo (24), bebidas alcoólicas (2203 a
# 2208), automóveis de passageiros (8703) e perfumaria e toucador (33, menos 3303 a 3307).
ncm_sem_cbs_zero_na_area_incentivada = function(ncms) {
  posicao = substr(ncms, 1, 4)
  capitulo = substr(ncms, 1, 2)
  capitulo %in% c("93", "24") | posicao %in% c("2203", "2204", "2205", "2206", "2207", "2208", "8703") |
    (capitulo == "33" & !(posicao %in% c("3303", "3304", "3305", "3306", "3307")))
}

conferir_os_codigos = function(itens) {
  linhas = list()
  linhas[[1]] = linhas_da_regra("UB13-10", itens, aplica = !is.na(itens$cst), confere = itens$cst_existe, campo = "CST",
                                no_documento = itens$cst, esperado = "um CST da tabela do IBS e da CBS")
  linhas[[2]] = linhas_da_regra("UB14-10", itens, aplica = !is.na(itens$classificacao), confere = itens$classificacao_existe,
                                campo = "cClassTrib", no_documento = itens$classificacao,
                                esperado = "uma classifica\u00e7\u00e3o da tabela do IBS e da CBS")
  linhas[[3]] = linhas_da_regra("UB14-20", itens, aplica = itens$classificacao_existe & !is.na(itens$cst),
                                confere = itens$cst_da_classificacao == itens$cst, campo = "cClassTrib",
                                no_documento = paste0("CST ", itens$cst, ", cClassTrib ", itens$classificacao),
                                esperado = paste0("CST ", itens$cst_da_classificacao))
  linhas[[4]] = linhas_da_regra("UB14-25", itens, aplica = itens$classificacao_existe,
                                confere = itens$permitido_no_modelo %in% 1, campo = "cClassTrib",
                                no_documento = paste0("cClassTrib ", itens$classificacao, " no modelo ", itens$modelo),
                                esperado = "classifica\u00e7\u00e3o permitida no modelo")
  linhas[[5]] = linhas_da_regra("UB69-10", itens, aplica = itens$tem_tributacao_regular,
                                confere = itens$cst_regular %in% tabela_fiscal("cst_ibs_cbs")$codigo,
                                campo = "gTribRegular/CSTReg", no_documento = itens$cst_regular,
                                esperado = "um CST da tabela do IBS e da CBS")
  linhas[[6]] = linhas_da_regra("UB70-10", itens, aplica = itens$tem_tributacao_regular,
                                confere = itens$classificacao_regular %in% tabela_fiscal("classificacao_ibs_cbs")$codigo,
                                campo = "gTribRegular/cClassTribReg", no_documento = itens$classificacao_regular,
                                esperado = "uma classifica\u00e7\u00e3o da tabela do IBS e da CBS")
  juntar_linhas(linhas)
}

conferir_os_grupos = function(itens) {
  com_grupo = itens$tem_grupo_ibs_cbs
  nota_de_perda = itens$tipo_nota_debito %in% "07"
  linhas = list(
    regra_de_grupo("UB13-20", itens, itens$grupo_ibs_cbs, 0, itens$tem_grupo_ibs_cbs, "gIBSCBS"),
    regra_de_grupo("UB13-30", itens, itens$grupo_ibs_cbs, 1, itens$tem_grupo_ibs_cbs, "gIBSCBS", !nota_de_perda),
    regra_de_grupo("UB13-39", itens, itens$grupo_monofasico, 0, itens$tem_monofasico, "gIBSCBSMono"),
    regra_de_grupo("UB13-44", itens, itens$grupo_transferencia_credito, 0, itens$tem_transferencia_credito, "gTransfCred"),
    regra_de_grupo("UB13-45", itens, itens$grupo_transferencia_credito, 1, itens$tem_transferencia_credito, "gTransfCred"),
    regra_de_grupo("UB112-10", itens, itens$grupo_ajuste_competencia, 0, itens$tem_ajuste_competencia, "gAjusteCompet"),
    regra_de_grupo("UB112-20", itens, itens$grupo_ajuste_competencia, 1, itens$tem_ajuste_competencia, "gAjusteCompet"),
    regra_de_grupo("UB131-20", itens, itens$grupo_credito_presumido_zfm, 0, itens$tem_credito_presumido_zfm,
                   "gCredPresIBSZFM"),
    regra_de_grupo("UB131-30", itens, itens$grupo_credito_presumido_zfm, 1, itens$tem_credito_presumido_zfm,
                   "gCredPresIBSZFM"),
    regra_de_grupo("UB22-10", itens, itens$grupo_diferimento, 0, itens$tem_diferimento_ibs_uf, "gIBSUF/gDif", com_grupo),
    regra_de_grupo("UB22-20", itens, itens$grupo_diferimento, 1, itens$tem_diferimento_ibs_uf, "gIBSUF/gDif", com_grupo),
    regra_de_grupo("UB40-10", itens, itens$grupo_diferimento, 1, itens$tem_diferimento_ibs_mun, "gIBSMun/gDif", com_grupo),
    regra_de_grupo("UB40-20", itens, itens$grupo_diferimento, 0, itens$tem_diferimento_ibs_mun, "gIBSMun/gDif", com_grupo),
    regra_de_grupo("UB59-10", itens, itens$grupo_diferimento, 1, itens$tem_diferimento_cbs, "gCBS/gDif", com_grupo),
    regra_de_grupo("UB59-20", itens, itens$grupo_diferimento, 0, itens$tem_diferimento_cbs, "gCBS/gDif", com_grupo),
    regra_de_grupo("UB68-10", itens, itens$grupo_tributacao_regular_da_classificacao, 1, itens$tem_tributacao_regular,
                   "gTribRegular"),
    regra_de_grupo("UB68-11", itens, itens$grupo_tributacao_regular_da_classificacao, 0, itens$tem_tributacao_regular,
                   "gTribRegular"),
    regra_de_grupo("UB116-10", itens, itens$grupo_estorno_credito_da_classificacao, 0, itens$tem_estorno_credito,
                   "gEstornoCred", !nota_de_perda),
    regra_de_grupo("UB120-20", itens, itens$grupo_credito_presumido_da_classificacao, 0, itens$tem_credito_presumido,
                   "gCredPresOper", !(itens$bem_movel_usado %in% "1"))
  )
  # O estorno de crédito também é exigido na nota de débito de perda em estoque (tpNFDebito 07).
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB116-20", itens, aplica = itens$grupo_estorno_credito_da_classificacao %in% 1 | nota_de_perda,
    confere = itens$tem_estorno_credito, campo = "gEstornoCred", no_documento = texto_da_presenca(itens$tem_estorno_credito),
    esperado = "informado"
  )
  # Na NFC-e não há crédito presumido (as regras são só do modelo 65; o filtro pelo modelo vem depois).
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB120-10", itens, aplica = TRUE, confere = !itens$tem_credito_presumido, campo = "gCredPresOper",
    no_documento = texto_da_presenca(itens$tem_credito_presumido), esperado = "n\u00e3o informado"
  )
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB131-10", itens, aplica = TRUE, confere = !itens$tem_credito_presumido_zfm, campo = "gCredPresIBSZFM",
    no_documento = texto_da_presenca(itens$tem_credito_presumido_zfm), esperado = "n\u00e3o informado"
  )
  # A redução: o CST que não permite aceita o grupo só na compra governamental, com o percentual zero (exceção das
  # regras UB26-10, UB45-10 e UB64-10); o grupo é exigido pelo CST ou pela compra governamental.
  for (parte in c("ibs_uf", "ibs_mun", "cbs")) {
    regras = switch(parte, ibs_uf = c("UB26-10", "UB26-20"), ibs_mun = c("UB45-10", "UB45-20"), cbs = c("UB64-10", "UB64-20"))
    grupo = switch(parte, ibs_uf = "gIBSUF/gRed", ibs_mun = "gIBSMun/gRed", cbs = "gCBS/gRed")
    tem_reducao = itens[[paste0("tem_reducao_", parte)]]
    percentual_de_reducao = itens[[paste0("reducao_", parte)]]
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      regras[1], itens, aplica = com_grupo & itens$grupo_reducao %in% 0,
      confere = !tem_reducao | (itens$tem_compra_governamental & percentual_de_reducao %in% 0), campo = grupo,
      no_documento = texto_da_presenca(tem_reducao), esperado = "n\u00e3o informado (ou zero na compra governamental)"
    )
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      regras[2], itens, aplica = com_grupo & (itens$grupo_reducao %in% 1 | itens$tem_compra_governamental),
      confere = tem_reducao, campo = grupo, no_documento = texto_da_presenca(tem_reducao), esperado = "informado"
    )
  }
  # A devolução de tributos (cashback) não é permitida no IBS; na CBS, não na NFC-e, e na NF-e com o percentual.
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB24-10", itens, aplica = com_grupo, confere = !itens$tem_devolucao_ibs_uf, campo = "gIBSUF/gDevTrib",
    no_documento = texto_da_presenca(itens$tem_devolucao_ibs_uf), esperado = "n\u00e3o informado"
  )
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB43-10", itens, aplica = com_grupo, confere = !itens$tem_devolucao_ibs_mun, campo = "gIBSMun/gDevTrib",
    no_documento = texto_da_presenca(itens$tem_devolucao_ibs_mun), esperado = "n\u00e3o informado"
  )
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB62-10", itens, aplica = com_grupo, confere = !itens$tem_devolucao_cbs, campo = "gCBS/gDevTrib",
    no_documento = texto_da_presenca(itens$tem_devolucao_cbs), esperado = "n\u00e3o informado"
  )
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB62a-10", itens, aplica = itens$tem_devolucao_cbs, confere = !is.na(itens$percentual_devolvido_cbs),
    campo = "gCBS/gDevTrib/pDevTrib", no_documento = texto_do_numero(itens$percentual_devolvido_cbs, 4),
    esperado = "informado"
  )
  # A compra governamental: com o gCompraGov na nota, o item traz a composição (gTribCompraGov), menos no CST que não
  # permite o grupo do IBS e da CBS; sem ele, não traz.
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB82a-10", itens, aplica = itens$tem_compra_governamental & !(itens$grupo_ibs_cbs %in% 0),
    confere = itens$tem_compra_governamental_item, campo = "gTribCompraGov",
    no_documento = texto_da_presenca(itens$tem_compra_governamental_item), esperado = "informado"
  )
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB82a-30", itens, aplica = !itens$tem_compra_governamental, confere = !itens$tem_compra_governamental_item,
    campo = "gTribCompraGov", no_documento = texto_da_presenca(itens$tem_compra_governamental_item),
    esperado = "n\u00e3o informado"
  )
  juntar_linhas(linhas)
}

# A classificação que só vale num tipo de nota de débito ou de crédito (regras UB14-60, UB14-70 e UB14-80). Os tipos que
# a NT deixa sem limite (multa e juros, pagamento antecipado, as recusas na entrega, a redução de valores) não estão aqui.
CLASSIFICACAO_DE_CADA_TIPO_DE_NOTA = data.frame(
  classificacao = c("410030", "800001", "800001", "800002", "810001", "811001", "811002", "811003"),
  nota = c("debito", "debito", "credito", "debito", "credito", "debito", "debito", "debito"),
  tipo = c("07", "05", "05", "01", "02", "02", "03", "08")
)

# As regras da nota de débito e de crédito (só da NF-e): a classificação e o tipo da nota combinam; a transferência de
# crédito, o ajuste de competência e o estorno de crédito com valor; o crédito presumido da ZFM só na nota de crédito
# do tipo 02, com a competência até o mês da emissão e sem repetir o tipo na nota.
conferir_as_notas_de_debito_e_credito = function(itens) {
  tabela = CLASSIFICACAO_DE_CADA_TIPO_DE_NOTA
  pares_da_tabela = paste(tabela$classificacao, tabela$nota, tabela$tipo)
  combina_com_o_debito = paste(itens$classificacao, "debito", itens$tipo_nota_debito) %in% pares_da_tabela
  combina_com_o_credito = paste(itens$classificacao, "credito", itens$tipo_nota_credito) %in% pares_da_tabela
  do_debito = tabela[tabela$nota == "debito", ]
  classificacao_do_debito = do_debito$classificacao[match(itens$tipo_nota_debito, do_debito$tipo)]
  do_credito = tabela[tabela$nota == "credito", ]
  classificacao_do_credito = do_credito$classificacao[match(itens$tipo_nota_credito, do_credito$tipo)]
  # A UB132-10: o mês "atual" da SEFAZ é o da autorização (o dhRecbto do protocolo). Sem o protocolo no arquivo, só se
  # sabe que ela não veio antes da emissão: até o mês da emissão confere, depois dele fica sem conferir.
  com_autorizacao = !is.na(itens$autorizacao)
  mes_atual = ifelse(com_autorizacao, substr(itens$autorizacao, 1, 7), format(itens$data_emissao, "%Y-%m"))
  competencia_sem_saber = !com_autorizacao & (itens$competencia_credito_zfm > mes_atual) %in% TRUE
  texto_da_nota = paste0("cClassTrib ", itens$classificacao, ", tpNFDebito ", texto_ou_vazio(itens$tipo_nota_debito),
                         ", tpNFCredito ", texto_ou_vazio(itens$tipo_nota_credito))
  linhas = list(
    linhas_da_regra("UB14-60", itens, aplica = itens$classificacao %in% tabela$classificacao,
                    confere = combina_com_o_debito | combina_com_o_credito, campo = "cClassTrib", no_documento = texto_da_nota,
                    esperado = tipos_de_nota_da_classificacao(itens$classificacao)),
    linhas_da_regra("UB14-70", itens, aplica = !is.na(classificacao_do_debito),
                    confere = !is.na(itens$classificacao) & itens$classificacao == classificacao_do_debito,
                    campo = "cClassTrib", no_documento = texto_da_nota,
                    esperado = paste0("cClassTrib ", classificacao_do_debito)),
    linhas_da_regra("UB14-80", itens, aplica = !is.na(classificacao_do_credito),
                    confere = !is.na(itens$classificacao) & itens$classificacao == classificacao_do_credito,
                    campo = "cClassTrib", no_documento = texto_da_nota,
                    esperado = paste0("cClassTrib ", classificacao_do_credito)),
    linhas_da_regra("UB106-30", itens, aplica = itens$tem_transferencia_credito, confere = itens$finalidade %in% "6",
                    campo = "ide/finNFe", no_documento = texto_ou_vazio(itens$finalidade),
                    esperado = "6 (nota de d\u00e9bito)"),
    linhas_da_regra("UB106-31", itens, aplica = itens$tem_transferencia_credito,
                    confere = itens$tipo_nota_debito %in% c("01", "05"), campo = "ide/tpNFDebito",
                    no_documento = texto_ou_vazio(itens$tipo_nota_debito), esperado = "01 ou 05"),
    linhas_da_regra("UB106-40", itens, aplica = itens$tem_transferencia_credito,
                    confere = valor_ou_zero(itens$transferencia_ibs) > 0 | valor_ou_zero(itens$transferencia_cbs) > 0,
                    campo = "gTransfCred", no_documento = texto_dos_dois_valores(itens$transferencia_ibs, itens$transferencia_cbs),
                    esperado = "vIBS ou vCBS maior que zero"),
    linhas_da_regra("UB112-30", itens, aplica = itens$tem_ajuste_competencia,
                    confere = valor_ou_zero(itens$ajuste_competencia_ibs) > 0 | valor_ou_zero(itens$ajuste_competencia_cbs) > 0,
                    campo = "gAjusteCompet",
                    no_documento = texto_dos_dois_valores(itens$ajuste_competencia_ibs, itens$ajuste_competencia_cbs),
                    esperado = "vIBS ou vCBS maior que zero"),
    # Na nota de débito de perda em estoque (tpNFDebito 07), o estorno pode vir zerado.
    linhas_da_regra("UB116-30", itens, aplica = itens$tem_estorno_credito & !(itens$tipo_nota_debito %in% "07"),
                    confere = valor_ou_zero(itens$estorno_ibs) > 0 | valor_ou_zero(itens$estorno_cbs) > 0,
                    campo = "gEstornoCred", no_documento = texto_dos_dois_valores(itens$estorno_ibs, itens$estorno_cbs),
                    esperado = "vIBSEstCred ou vCBSEstCred maior que zero"),
    linhas_da_regra("UB131-40", itens, aplica = itens$tem_credito_presumido_zfm, confere = itens$tipo_nota_credito %in% "02",
                    campo = "ide/tpNFCredito", no_documento = texto_ou_vazio(itens$tipo_nota_credito), esperado = "02"),
    linhas_da_regra("UB131-50", itens, aplica = !itens$tem_credito_presumido_zfm,
                    confere = !(itens$tipo_nota_credito %in% "02"), campo = "gCredPresIBSZFM",
                    no_documento = paste0("tpNFCredito ", texto_ou_vazio(itens$tipo_nota_credito), ", grupo n\u00e3o informado"),
                    esperado = "o grupo, porque a nota de cr\u00e9dito \u00e9 do tipo 02"),
    linhas_da_regra("UB132-10", itens, aplica = !is.na(itens$competencia_credito_zfm),
                    confere = ifelse(competencia_sem_saber, NA, itens$competencia_credito_zfm <= mes_atual),
                    campo = "gCredPresIBSZFM/competApur", no_documento = itens$competencia_credito_zfm,
                    esperado = paste0("at\u00e9 ", mes_atual, ifelse(com_autorizacao, ifelse(
                      itens$recebimento_pelo_envio, " (o m\u00eas do envio)", " (o m\u00eas da autoriza\u00e7\u00e3o)"),
                      " (o m\u00eas da emiss\u00e3o)")),
                    observacao = ifelse(competencia_sem_saber, paste0(
                      "Sem o protocolo de autoriza\u00e7\u00e3o no arquivo, n\u00e3o d\u00e1 para saber o m\u00eas em que a SEFAZ ",
                      "recebeu a nota."), NA)),
    linhas_da_regra("UB133-10", itens, aplica = itens$tem_credito_presumido_zfm & !is.na(itens$tipo_credito_zfm),
                    confere = !duplicated(paste(itens$chave, itens$tipo_credito_zfm)),
                    campo = "gCredPresIBSZFM/tpCredPresIBSZFM", no_documento = itens$tipo_credito_zfm,
                    esperado = "um tipo que nenhum item anterior da nota usou")
  )
  juntar_linhas(linhas)
}

# "tpNFDebito 05 ou tpNFCredito 05", o que a regra UB14-60 aceita para cada classificação da tabela.
tipos_de_nota_da_classificacao = function(classificacoes) {
  tabela = CLASSIFICACAO_DE_CADA_TIPO_DE_NOTA
  textos = paste0(ifelse(tabela$nota == "debito", "tpNFDebito ", "tpNFCredito "), tabela$tipo)
  juntos = tapply(textos, tabela$classificacao, paste, collapse = " ou ")
  unname(juntos[classificacoes])
}

# A CBS zero na área incentivada (gALCZFMCBS): o emitente com inscrição na Suframa, o NCM fora das exceções e os dois na
# mesma área (os mesmos da UB56-10), o processo na Suframa no tipo 2 e o valor que a CBS teria fora da área. A UB66e-10
# não diz tolerância: tem de bater até o centavo, depois de arredondar o calculado.
conferir_a_area_incentivada_da_cbs = function(itens) {
  com_o_grupo = itens$tem_area_incentivada_cbs
  valor_calculado = arredondar_no_centavo(itens$base * itens$aliquota_sem_area_incentivada / 100)
  linhas = list(
    linhas_da_regra("UB66a-10", itens, aplica = com_o_grupo,
                    confere = !is.na(itens$inscricao_suframa_emitente) & nzchar(itens$inscricao_suframa_emitente),
                    campo = "emit/ISUFEmit", no_documento = texto_ou_vazio(itens$inscricao_suframa_emitente),
                    esperado = "informada"),
    linhas_da_regra("UB66a-20", itens, aplica = com_o_grupo,
                    confere = itens$mesma_area_incentivada & !itens$ncm_fora_da_area_incentivada, campo = "gCBS/gALCZFMCBS",
                    no_documento = paste0("NCM ", texto_ou_vazio(itens$ncm), ", munic\u00edpios ",
                                          texto_ou_vazio(itens$municipio_emitente), " e ",
                                          texto_ou_vazio(itens$municipio_destinatario)),
                    esperado = "NCM fora das exce\u00e7\u00f5es e emitente e destinat\u00e1rio na mesma \u00e1rea (ZFM ou a mesma ALC)"),
    linhas_da_regra("UB66c-10", itens, aplica = com_o_grupo & itens$tipo_area_incentivada_cbs %in% "2",
                    confere = !is.na(itens$processo_suframa) & grepl("[1-9]", itens$processo_suframa),
                    campo = "gCBS/gALCZFMCBS/nProcSuframa", no_documento = texto_ou_vazio(itens$processo_suframa),
                    esperado = "informado, sem ser s\u00f3 zeros"),
    linhas_da_regra("UB66e-10", itens, aplica = com_o_grupo,
                    confere = igual_com_tolerancia(itens$valor_sem_area_incentivada, valor_calculado, TOLERANCIA_DO_CENTAVO),
                    campo = "gCBS/gALCZFMCBS/vTribRegCBS", no_documento = texto_do_numero(itens$valor_sem_area_incentivada, 2),
                    esperado = texto_do_numero(valor_calculado, 2), diferenca = itens$valor_sem_area_incentivada - valor_calculado)
  )
  juntar_linhas(linhas)
}

# O crédito presumido da operação (gCredPresOper), pela tabela de crédito presumido: o código existe; os grupos do IBS e
# da CBS que ele exige ou não permite; no código 04 (bem móvel comprado de pessoa física para revenda), o crédito até o
# valor do produto; e o crédito em condição suspensiva, que só vale no código 04, no IBS a partir de 2033 e na CBS a
# partir de 2027.
conferir_o_credito_presumido = function(itens) {
  com_o_codigo = itens$tem_credito_presumido & !is.na(itens$credito_presumido_codigo)
  do_bem_movel = itens$credito_presumido_codigo %in% "04"
  ano_da_emissao = as.integer(format(itens$data_emissao, "%Y"))
  texto_do_suspenso = paste0("cCredPres ", texto_ou_vazio(itens$credito_presumido_codigo), ", emitida em ",
                             texto_ou_vazio(as.character(ano_da_emissao)))
  linhas = list(
    linhas_da_regra("UB122-10", itens, aplica = com_o_codigo, confere = itens$credito_presumido_existe,
                    campo = "gCredPresOper/cCredPres", no_documento = itens$credito_presumido_codigo,
                    esperado = "um c\u00f3digo da tabela de cr\u00e9dito presumido"),
    regra_de_grupo("UB123-10", itens, itens$grupo_credito_ibs, 0, itens$tem_credito_presumido_ibs,
                   "gCredPresOper/gIBSCredPres", com_o_codigo),
    regra_de_grupo("UB123-20", itens, itens$grupo_credito_ibs, 1, itens$tem_credito_presumido_ibs,
                   "gCredPresOper/gIBSCredPres", com_o_codigo),
    regra_de_grupo("UB127-10", itens, itens$grupo_credito_cbs, 0, itens$tem_credito_presumido_cbs,
                   "gCredPresOper/gCBSCredPres", com_o_codigo),
    regra_de_grupo("UB127-20", itens, itens$grupo_credito_cbs, 1, itens$tem_credito_presumido_cbs,
                   "gCredPresOper/gCBSCredPres", com_o_codigo),
    linhas_da_regra("UB125-10", itens, aplica = do_bem_movel & !is.na(itens$credito_presumido_ibs),
                    confere = itens$credito_presumido_ibs <= valor_ou_zero(itens$valor_produto) + FOLGA_DE_PONTO_FLUTUANTE,
                    campo = "gIBSCredPres/vCredPres", no_documento = texto_do_numero(itens$credito_presumido_ibs, 2),
                    esperado = paste0("at\u00e9 ", texto_do_numero(itens$valor_produto, 2), " (vProd)")),
    linhas_da_regra("UB129-10", itens, aplica = do_bem_movel & !is.na(itens$credito_presumido_cbs),
                    confere = itens$credito_presumido_cbs <= valor_ou_zero(itens$valor_produto) + FOLGA_DE_PONTO_FLUTUANTE,
                    campo = "gCBSCredPres/vCredPres", no_documento = texto_do_numero(itens$credito_presumido_cbs, 2),
                    esperado = paste0("at\u00e9 ", texto_do_numero(itens$valor_produto, 2), " (vProd)")),
    linhas_da_regra("UB126-10", itens, aplica = !is.na(itens$credito_suspenso_ibs),
                    confere = do_bem_movel & ano_da_emissao >= 2033, campo = "gIBSCredPres/vCredPresCondSus",
                    no_documento = texto_do_suspenso, esperado = "cCredPres 04, a partir de 2033"),
    linhas_da_regra("UB130-10", itens, aplica = !is.na(itens$credito_suspenso_cbs),
                    confere = do_bem_movel & ano_da_emissao >= 2027, campo = "gCBSCredPres/vCredPresCondSus",
                    no_documento = texto_do_suspenso, esperado = "cCredPres 04, a partir de 2027")
  )
  juntar_linhas(linhas)
}

# A alíquota do ano: 0 na classificação com tributação regular; a regra não vale na devolução e em algumas notas de
# crédito. Na CBS, a exceção 3 da UB56-10 aceita zero quando o emitente e o destinatário estão na mesma área incentivada
# e o NCM não é um dos de fora; de 2027 em diante (UB56-20), a CBS é zero com o grupo da área incentivada.
conferir_as_aliquotas = function(itens) {
  tributacao_regular = itens$grupo_tributacao_regular_da_classificacao %in% 1
  sem_regra_do_ibs = itens$finalidade %in% "4" | itens$tipo_nota_credito %in% c("03", "04", "06")
  linhas = list()
  # De 2029 em diante a alíquota do IBS é "a ser publicada" (UB18-10 e UB37-10): só dá para conferir o zero da
  # tributação regular; o resto fica sem conferir, com o motivo.
  for (parte in c("ibs_uf", "ibs_mun")) {
    regra = switch(parte, ibs_uf = "UB18-10", ibs_mun = "UB37-10")
    campo = switch(parte, ibs_uf = "gIBSUF/pIBSUF", ibs_mun = "gIBSMun/pIBSMun")
    aliquota = itens[[paste0("aliquota_", parte)]]
    esperada = ifelse(tributacao_regular, 0, itens[[paste0("aliquota_do_ano_", parte)]])
    sem_aliquota_publicada = is.na(esperada)
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      regra, itens, aplica = itens$tem_grupo_ibs_cbs & !is.na(itens$data_emissao) & !sem_regra_do_ibs,
      confere = ifelse(sem_aliquota_publicada, NA, igual_com_tolerancia(aliquota, esperada, TOLERANCIA_DO_PERCENTUAL)),
      campo = campo, no_documento = texto_da_aliquota(aliquota),
      esperado = ifelse(sem_aliquota_publicada, "a al\u00edquota do ano, a ser publicada", texto_da_aliquota(esperada)),
      observacao = ifelse(sem_aliquota_publicada, "A al\u00edquota do IBS deste ano ainda n\u00e3o foi publicada.", NA)
    )
  }
  # A CBS pelo ano da emissão: a UB56-10 é a de 2025 e 2026; a UB56-20, a de 2027 em diante, com outras exceções.
  ano = as.integer(format(itens$data_emissao, "%Y"))
  ate_2026 = ano %in% c(2025, 2026)
  de_2027_em_diante = (ano >= 2027) %in% TRUE
  esperada_cbs = ifelse(tributacao_regular, 0, itens$aliquota_do_ano_cbs)
  zero_na_area_incentivada = !tributacao_regular & itens$aliquota_cbs %in% 0 & itens$mesma_area_incentivada &
    !itens$ncm_fora_da_area_incentivada
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB56-10", itens,
    aplica = itens$tem_grupo_ibs_cbs & ate_2026 & !is.na(itens$aliquota_do_ano_cbs) & !(itens$tipo_nota_credito %in% "04"),
    confere = igual_com_tolerancia(itens$aliquota_cbs, esperada_cbs, TOLERANCIA_DO_PERCENTUAL) | zero_na_area_incentivada,
    campo = "gCBS/pCBS", no_documento = texto_da_aliquota(itens$aliquota_cbs),
    esperado = ifelse(tributacao_regular, "0 (classifica\u00e7\u00e3o com tributa\u00e7\u00e3o regular)",
                      paste0(texto_da_aliquota(esperada_cbs), " (ou 0 na mesma \u00e1rea incentivada, ZFM ou ALC)"))
  )
  # De 2027 em diante, enquanto a alíquota da CBS do ano não for publicada (a de referência, menos 0,1 ponto em 2027 e
  # 2028, pelo art. 347), só dá para conferir o zero obrigatório.
  cbs_zero = tributacao_regular | itens$tem_area_incentivada_cbs
  aliquota_publicada = !is.na(itens$aliquota_do_ano_cbs)
  esperada_cbs_depois = ifelse(cbs_zero, 0, itens$aliquota_do_ano_cbs)
  da_para_conferir = cbs_zero | aliquota_publicada
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB56-20", itens, aplica = itens$tem_grupo_ibs_cbs & de_2027_em_diante & !sem_regra_do_ibs,
    confere = ifelse(da_para_conferir, igual_com_tolerancia(itens$aliquota_cbs, esperada_cbs_depois, TOLERANCIA_DO_PERCENTUAL),
                     NA),
    campo = "gCBS/pCBS", no_documento = texto_da_aliquota(itens$aliquota_cbs),
    esperado = ifelse(da_para_conferir, texto_da_aliquota(esperada_cbs_depois), "a al\u00edquota do ano, a ser publicada"),
    observacao = ifelse(da_para_conferir, NA, "A al\u00edquota da CBS deste ano ainda n\u00e3o foi publicada.")
  )
  juntar_linhas(linhas)
}

conferir_as_contas = function(itens) {
  linhas = list()
  fator_da_compra_governamental = ifelse(itens$tem_compra_governamental,
                                         1 - valor_ou_zero(itens$redutor_compra_governamental) / 100, 1)
  for (parte in c("ibs_uf", "ibs_mun", "cbs")) {
    regras = switch(parte,
                    ibs_uf = c("UB27-10", "UB28-10", "UB23-10", "UB35-10"),
                    ibs_mun = c("UB46-10", "UB47-10", "UB42-10", "UB54-10"),
                    cbs = c("UB65-10", "UB66-10", "UB61-10", "UB67-10"))
    grupo = switch(parte, ibs_uf = "gIBSUF", ibs_mun = "gIBSMun", cbs = "gCBS")
    campo_do_valor = switch(parte, ibs_uf = "vIBSUF", ibs_mun = "vIBSMun", cbs = "vCBS")
    tem_reducao = itens[[paste0("tem_reducao_", parte)]]
    percentual_de_reducao = itens[[paste0("reducao_", parte)]]
    reducao_da_classificacao = if (parte == "cbs") itens$reducao_cbs_da_classificacao else itens$reducao_ibs_da_classificacao
    aliquota = itens[[paste0("aliquota_", parte)]]
    aliquota_efetiva = itens[[paste0("aliquota_efetiva_", parte)]]
    aliquota_usada = itens[[paste0("aliquota_usada_", parte)]]
    valor_do_diferimento = itens[[paste0("valor_diferimento_", parte)]]
    valor_devolvido = itens[[paste0("valor_devolvido_", parte)]]
    valor = itens[[paste0("valor_", parte)]]

    # O percentual de redução é o da classificação; com o CST que não permite redução, só o zero da compra governamental.
    exige_reducao = itens$grupo_reducao %in% 1
    reducao_esperada = ifelse(exige_reducao, reducao_da_classificacao, 0)
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      regras[1], itens,
      aplica = tem_reducao & !is.na(itens$grupo_reducao) & (!exige_reducao | !is.na(reducao_da_classificacao)),
      confere = ifelse(exige_reducao, igual_com_tolerancia(percentual_de_reducao, reducao_esperada, TOLERANCIA_DO_PERCENTUAL),
                       itens$tem_compra_governamental & percentual_de_reducao %in% 0),
      campo = paste0(grupo, "/gRed/pRedAliq"), no_documento = texto_da_aliquota(percentual_de_reducao),
      esperado = ifelse(exige_reducao, texto_da_aliquota(reducao_esperada), "0 (s\u00f3 na compra governamental)")
    )
    efetiva_calculada = aliquota * (1 - percentual_de_reducao / 100) * fator_da_compra_governamental
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      regras[2], itens, aplica = tem_reducao & !is.na(aliquota) & !is.na(percentual_de_reducao),
      confere = igual_com_tolerancia(aliquota_efetiva, efetiva_calculada, TOLERANCIA_DA_ALIQUOTA_EFETIVA),
      campo = paste0(grupo, "/gRed/pAliqEfet"), no_documento = texto_do_numero(aliquota_efetiva, 4),
      esperado = texto_do_numero(efetiva_calculada, 4), diferenca = aliquota_efetiva - efetiva_calculada
    )
    tem_diferimento = itens[[paste0("tem_diferimento_", parte)]]
    diferimento_calculado = arredondar_no_centavo(itens$base * aliquota_usada / 100 * itens[[paste0("diferimento_", parte)]] / 100)
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      regras[3], itens, aplica = tem_diferimento,
      confere = igual_com_tolerancia(valor_do_diferimento, diferimento_calculado, TOLERANCIA_DOS_VALORES),
      campo = paste0(grupo, "/gDif/vDif"), no_documento = texto_do_numero(valor_do_diferimento, 2),
      esperado = texto_do_numero(diferimento_calculado, 2), diferenca = valor_do_diferimento - diferimento_calculado
    )
    valor_calculado = arredondar_no_centavo(itens$base * aliquota_usada / 100) - valor_ou_zero(valor_do_diferimento) -
      valor_ou_zero(valor_devolvido)
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      regras[4], itens, aplica = itens$tem_grupo_ibs_cbs,
      confere = igual_com_tolerancia(valor, valor_calculado, TOLERANCIA_DOS_VALORES),
      campo = paste0(grupo, "/", campo_do_valor), no_documento = texto_do_numero(valor, 2),
      esperado = texto_do_numero(valor_calculado, 2), diferenca = valor - valor_calculado
    )
  }
  # A devolução da CBS (cashback): a base vezes a alíquota vezes o percentual devolvido.
  devolucao_calculada = arredondar_no_centavo(itens$base * itens$aliquota_usada_cbs / 100 * itens$percentual_devolvido_cbs / 100)
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB63-10", itens, aplica = itens$tem_devolucao_cbs & !is.na(itens$percentual_devolvido_cbs),
    confere = igual_com_tolerancia(itens$valor_devolvido_cbs, devolucao_calculada, TOLERANCIA_DOS_VALORES),
    campo = "gCBS/gDevTrib/vDevTrib", no_documento = texto_do_numero(itens$valor_devolvido_cbs, 2),
    esperado = texto_do_numero(devolucao_calculada, 2), diferenca = itens$valor_devolvido_cbs - devolucao_calculada
  )
  # O IBS do item é o da UF mais o do município, menos o crédito presumido do IBS quando o código dele manda descontar
  # (indDeduzCredPres = 1). Com o código fora da tabela, não dá para saber se desconta.
  desconta_o_credito = itens$tem_credito_presumido_ibs & itens$deduz_do_tributo %in% 1
  codigo_fora_da_tabela = itens$tem_credito_presumido_ibs & !itens$credito_presumido_existe
  ibs_calculado = valor_ou_zero(itens$valor_ibs_uf) + valor_ou_zero(itens$valor_ibs_mun) -
    ifelse(desconta_o_credito, valor_ou_zero(itens$credito_presumido_ibs), 0)
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB54a-10", itens, aplica = itens$tem_grupo_ibs_cbs,
    confere = ifelse(codigo_fora_da_tabela, NA, igual_com_tolerancia(itens$valor_ibs, ibs_calculado, TOLERANCIA_DO_CENTAVO)),
    campo = "gIBSCBS/vIBS", no_documento = texto_do_numero(itens$valor_ibs, 2),
    esperado = texto_do_numero(ibs_calculado, 2), diferenca = itens$valor_ibs - ibs_calculado,
    observacao = ifelse(codigo_fora_da_tabela, paste(
      "O c\u00f3digo do cr\u00e9dito presumido n\u00e3o est\u00e1 na tabela: n\u00e3o d\u00e1 para saber se o vCredPres \u00e9",
      "descontado do IBS do item."
    ), NA)
  )
  # A tributação regular: a base vezes a alíquota efetiva regular de cada um.
  for (parte in c("ibs_uf", "ibs_mun", "cbs")) {
    regra = switch(parte, ibs_uf = "UB72-10", ibs_mun = "UB72b-10", cbs = "UB72d-10")
    campo = switch(parte, ibs_uf = "gTribRegular/vTribRegIBSUF", ibs_mun = "gTribRegular/vTribRegIBSMun",
                   cbs = "gTribRegular/vTribRegCBS")
    valor_regular = itens[[paste0("valor_regular_", parte)]]
    regular_calculado = arredondar_no_centavo(itens$base * itens[[paste0("aliquota_regular_", parte)]] / 100)
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      regra, itens, aplica = itens$tem_tributacao_regular,
      confere = igual_com_tolerancia(valor_regular, regular_calculado, TOLERANCIA_DOS_VALORES), campo = campo,
      no_documento = texto_do_numero(valor_regular, 2), esperado = texto_do_numero(regular_calculado, 2),
      diferenca = valor_regular - regular_calculado
    )
  }
  # A compra governamental: a soma da composição bate com a soma do IBS e da CBS do item.
  soma_da_compra = valor_ou_zero(itens$compra_governamental_ibs_uf) + valor_ou_zero(itens$compra_governamental_ibs_mun) +
    valor_ou_zero(itens$compra_governamental_cbs)
  soma_do_item = valor_ou_zero(itens$valor_ibs_uf) + valor_ou_zero(itens$valor_ibs_mun) + valor_ou_zero(itens$valor_cbs)
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB82a-20", itens, aplica = itens$tem_compra_governamental_item,
    confere = igual_com_tolerancia(soma_da_compra, soma_do_item, TOLERANCIA_DA_COMPRA_GOVERNAMENTAL),
    campo = "gTribCompraGov", no_documento = texto_do_numero(soma_da_compra, 2), esperado = texto_do_numero(soma_do_item, 2),
    diferenca = soma_da_compra - soma_do_item
  )
  juntar_linhas(linhas)
}

# Os totais da nota (IBSCBSTot): o grupo existe quando algum item tem o IBS e a CBS, e cada campo é a soma dos itens.
conferir_os_totais = function(itens, notas) {
  notas_com_ibs_cbs = notas$chave %in% itens$chave[itens$tem_ibs_cbs]
  sem_item = rep(NA_integer_, nrow(notas))
  linhas = list(
    linhas_da_regra("W34-10", notas, aplica = notas$tem_total_ibs_cbs, confere = notas_com_ibs_cbs, campo = "IBSCBSTot",
                    no_documento = "informado", esperado = "s\u00f3 com algum item com IBSCBS", itens_da_regra = sem_item),
    linhas_da_regra("W34-20", notas, aplica = !notas$tem_total_ibs_cbs, confere = !notas_com_ibs_cbs, campo = "IBSCBSTot",
                    no_documento = "n\u00e3o informado", esperado = "informado, porque algum item tem IBSCBS",
                    itens_da_regra = sem_item)
  )
  for (numero_do_total in seq_len(nrow(TOTAIS_PARA_CONFERIR))) {
    total = TOTAIS_PARA_CONFERIR[numero_do_total, ]
    soma_dos_itens = rep(0, nrow(notas))
    if (nrow(itens) > 0) {
      somas = rowsum(valor_ou_zero(itens[[total$coluna_do_item]]), itens$chave)
      soma_dos_itens = valor_ou_zero(somas[match(notas$chave, rownames(somas)), 1])
    }
    valor_do_total = valor_ou_zero(notas[[total$coluna_do_total]])
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      total$regra, notas, aplica = notas$tem_total_ibs_cbs,
      confere = igual_com_tolerancia(valor_do_total, soma_dos_itens, TOLERANCIA_DO_CENTAVO),
      campo = paste0("IBSCBSTot/", total$campo), no_documento = texto_do_numero(valor_do_total, 2),
      esperado = texto_do_numero(soma_dos_itens, 2), diferenca = valor_do_total - soma_dos_itens, itens_da_regra = sem_item
    )
  }
  juntar_linhas(linhas)
}

# Uma regra de grupo: onde o indicador é `valor_do_indicador` (1 = o grupo é exigido, 0 = não é permitido), o grupo
# tem de estar no item, ou não estar. `aplica_tambem` são as outras condições da regra.
regra_de_grupo = function(regra, itens, indicador, valor_do_indicador, presente, grupo, aplica_tambem = TRUE) {
  if (valor_do_indicador == 1) {
    confere = presente
    esperado = "informado"
  } else {
    confere = !presente
    esperado = "n\u00e3o informado"
  }
  linhas_da_regra(regra, itens, aplica = indicador %in% valor_do_indicador & aplica_tambem, confere = confere,
                  campo = grupo, no_documento = texto_da_presenca(presente), esperado = esperado)
}

# As linhas de uma regra: uma por item (ou por nota, nos totais) em que ela se aplica. Vêm como uma lista de colunas,
# não um data.frame: montar um data.frame por regra e juntar com rbind custava 2/3 do tempo da conferência.
linhas_da_regra = function(regra, itens, aplica, confere, campo, no_documento, esperado, diferenca = NA_real_,
                           observacao = NA_character_, itens_da_regra = itens$item) {
  quantidade = length(itens$chave)
  # Cada valor vem um só ou um por linha: um vetor de nota numa regra de item seria repetido sem aviso.
  for (valor in list(aplica, confere, campo, no_documento, esperado, diferenca, observacao, itens_da_regra)) {
    if (!(length(valor) %in% c(1L, quantidade))) {
      stop("Regra ", regra, ": ", length(valor), " valores para ", quantidade, " linhas.", call. = FALSE)
    }
  }
  aplica = rep_len(aplica, quantidade)
  onde_aplica = which(!is.na(aplica) & aplica)
  list(
    chave = as.character(itens$chave)[onde_aplica],
    item = as.integer(rep_len(itens_da_regra, quantidade))[onde_aplica],
    regra = rep_len(regra, quantidade)[onde_aplica],
    campo = rep_len(as.character(campo), quantidade)[onde_aplica],
    no_documento = rep_len(as.character(no_documento), quantidade)[onde_aplica],
    esperado = rep_len(as.character(esperado), quantidade)[onde_aplica],
    diferenca = rep_len(as.numeric(diferenca), quantidade)[onde_aplica],
    confere = rep_len(as.logical(confere), quantidade)[onde_aplica],
    observacao = rep_len(as.character(observacao), quantidade)[onde_aplica]
  )
}

# As colunas das linhas de cada regra, vazias e com o tipo certo.
LINHAS_VAZIAS = list(chave = character(), item = integer(), regra = character(), campo = character(),
                     no_documento = character(), esperado = character(), diferenca = numeric(), confere = logical(),
                     observacao = character())

# Junta as linhas de várias regras (cada uma, uma lista de colunas) numa lista só, coluna por coluna.
juntar_linhas = function(lista_de_linhas) {
  juntas = list()
  for (coluna in names(LINHAS_VAZIAS)) {
    valores = vector("list", length(lista_de_linhas))
    for (posicao in seq_along(lista_de_linhas)) {
      valores[[posicao]] = lista_de_linhas[[posicao]][[coluna]]
    }
    juntas[[coluna]] = c(LINHAS_VAZIAS[[coluna]], unlist(valores, use.names = FALSE))
  }
  juntas
}

# O código e a mensagem de cada regra, o filtro pelo modelo (algumas regras são só da NF-e ou só da NFC-e) e pela data
# (a regra só vale para a nota emitida depois de entrar em produção; sem a data de emissão, todas valem), o que não
# confere hoje mas pode ter conferido na emissão e a observação da regra quando a linha não tem uma própria.
completar_com_as_regras = function(conferencias, notas, itens) {
  regras = regras_do_ibs_cbs()
  da_regra = match(conferencias$regra, regras$regra)
  da_nota = match(conferencias$chave, notas$chave)
  modelo_da_nota = notas$modelo[da_nota]
  emissao = notas$data_emissao[da_nota]
  modelos_da_regra = regras$modelos[da_regra]
  do_modelo = modelos_da_regra %in% "55/65" | (!is.na(modelo_da_nota) & modelos_da_regra == modelo_da_nota)
  em_producao_desde = regras$em_producao_desde[da_regra]
  em_producao = is.na(emissao) | (!is.na(em_producao_desde) & emissao >= em_producao_desde)
  conferencias$codigo_sefaz = regras$codigo_sefaz[da_regra]
  conferencias$mensagem = regras$mensagem[da_regra]
  conferencias = conferencias[do_modelo & em_producao, ]
  conferencias = sem_conferir_pela_mudanca_da_regra(conferencias, notas)
  conferencias = sem_conferir_pela_mudanca_das_tabelas(conferencias, notas, itens)
  sem_observacao = is.na(conferencias$observacao)
  conferencias$observacao[sem_observacao] = regras$observacao[match(conferencias$regra, regras$regra)][sem_observacao]
  conferencias = conferencias[, c("chave", "item", "regra", "campo", "no_documento", "esperado", "diferenca", "confere",
                                  "codigo_sefaz", "mensagem", "observacao")]
  rownames(conferencias) = NULL
  conferencias
}

# A regra que mudou depois da emissão de um jeito que pode ter aceitado antes o que hoje não aceita: o que não confere
# pela redação de hoje fica sem conferir, com o motivo.
sem_conferir_pela_mudanca_da_regra = function(conferencias, notas) {
  regras = regras_do_ibs_cbs()
  da_regra = match(conferencias$regra, regras$regra)
  emissao = notas$data_emissao[match(conferencias$chave, notas$chave)]
  mudou_em = regras$mudou_em_producao_em[da_regra]
  incerta = conferencias$confere %in% FALSE & !is.na(emissao) & !is.na(mudou_em) & emissao < mudou_em
  conferencias$confere[incerta] = NA
  conferencias$observacao[incerta] = paste0(
    "Pela reda\u00e7\u00e3o de hoje n\u00e3o confere, mas a regra mudou na NT 2025.002 v", regras$mudou_na_versao[da_regra][incerta],
    " (em produ\u00e7\u00e3o desde ", format(mudou_em[incerta], "%d/%m/%Y"), "), depois da emiss\u00e3o: a SEFAZ conferiu a nota ",
    "pela reda\u00e7\u00e3o anterior."
  )
  conferencias
}

# A linha do CST ou da classificação que a regra consulta e que mudou numa versão da tabela que podia não estar em
# produção na emissão (veja tabela_fiscal("mudancas_ibs_cbs")): o que não confere pela tabela de hoje fica sem conferir,
# com o motivo.
sem_conferir_pela_mudanca_das_tabelas = function(conferencias, notas, itens) {
  erradas = which(conferencias$confere %in% FALSE & !is.na(conferencias$item))
  if (length(erradas) == 0) {
    return(conferencias)
  }
  da_nota = match(conferencias$chave[erradas], notas$chave)
  linhas = data.frame(
    posicao = erradas,
    regra = conferencias$regra[erradas],
    emissao = notas$data_emissao[da_nota],
    modelo = notas$modelo[da_nota],
    do_item = match(paste(conferencias$chave[erradas], conferencias$item[erradas]), paste(itens$chave, itens$item))
  )
  linhas = merge(linhas, CONSULTAS_DAS_REGRAS, by = "regra")
  linhas = linhas[linhas$modelos == "55/65" | (!is.na(linhas$modelo) & linhas$modelos == linhas$modelo), ]
  # A regra errada que não consulta tabela nenhuma (uma conta, por exemplo) não tem o que procurar aqui.
  if (nrow(linhas) == 0) {
    return(conferencias)
  }
  linhas$codigo = NA_character_
  for (campo in unique(linhas$campo_do_codigo)) {
    deste_campo = linhas$campo_do_codigo == campo
    linhas$codigo[deste_campo] = itens[[campo]][linhas$do_item[deste_campo]]
  }
  linhas = merge(linhas, tabela_fiscal("mudancas_ibs_cbs"), by = c("tabela", "codigo", "coluna"))
  # A mudança que podia não estar em produção na emissão: sem prazo conhecido ou com o prazo depois dela.
  linhas = linhas[!is.na(linhas$emissao) & (is.na(linhas$em_producao_ate) | linhas$emissao < linhas$em_producao_ate), ]
  if (nrow(linhas) == 0) {
    return(conferencias)
  }
  # De cada conferência, a mudança mais recente.
  linhas = linhas[order(linhas$posicao, linhas$publicada_em, decreasing = c(FALSE, TRUE), method = "radix"), ]
  linhas = linhas[!duplicated(linhas$posicao), ]
  conferencias$confere[linhas$posicao] = NA
  conferencias$observacao[linhas$posicao] = texto_da_mudanca_da_tabela(linhas)
  conferencias
}

texto_da_mudanca_da_tabela = function(linhas) {
  nomes_das_tabelas = c(cst_ibs_cbs = "CST", classificacao_ibs_cbs = "classifica\u00e7\u00e3o tribut\u00e1ria",
                        credito_presumido_ibs_cbs = "cr\u00e9dito presumido")
  nome_da_tabela = unname(nomes_das_tabelas[linhas$tabela])
  o_que_mudou = ifelse(
    linhas$coluna == "existe",
    paste0("o c\u00f3digo ", linhas$codigo, ifelse(linhas$depois %in% "1", " entrou na tabela", " saiu da tabela")),
    paste0(linhas$coluna, " do c\u00f3digo ", linhas$codigo, " mudou de ", texto_do_valor_da_tabela(linhas$antes), " para ",
           texto_do_valor_da_tabela(linhas$depois))
  )
  versao = ifelse(is.na(linhas$versao), "", paste0(" ", linhas$versao))
  prazo = ifelse(is.na(linhas$em_producao_ate), "sem prazo de produ\u00e7\u00e3o conhecido",
                 paste0("em produ\u00e7\u00e3o at\u00e9 ", format(linhas$em_producao_ate, "%d/%m/%Y")))
  como_a_sefaz_conferiu = ifelse(linhas$emissao < linhas$publicada_em, "a SEFAZ conferiu a nota pela vers\u00e3o anterior",
                                 "a SEFAZ pode ter conferido a nota pela vers\u00e3o anterior")
  paste0("Pela tabela de hoje n\u00e3o confere, mas na vers\u00e3o", versao, " da tabela de ", nome_da_tabela, " (publicada em ",
         format(linhas$publicada_em, "%d/%m/%Y"), ", ", prazo, ") ", o_que_mudou, ": ", como_a_sefaz_conferiu, ".")
}

texto_do_valor_da_tabela = function(valores) {
  valores[is.na(valores)] = "(vazio)"
  valores
}

# As regras da NT 2025.002 que a conferência usa, com o modelo, o código e a mensagem da rejeição (lidas uma vez).
regras_do_ibs_cbs = function() {
  if (is.null(tabelas_ja_lidas[["regras_ibs_cbs"]])) {
    tabelas_ja_lidas[["regras_ibs_cbs"]] = utils::read.csv(
      system.file("extdata", "regras_ibs_cbs.csv", package = "RNFe"), colClasses = "character", fileEncoding = "UTF-8",
      na.strings = ""
    )
    for (coluna in c("em_producao_desde", "mudou_em_producao_em")) {
      tabelas_ja_lidas[["regras_ibs_cbs"]][[coluna]] = as.Date(tabelas_ja_lidas[["regras_ibs_cbs"]][[coluna]])
    }
  }
  tabelas_ja_lidas[["regras_ibs_cbs"]]
}

# O valor calculado vai a 2 casas, como o campo, antes da tolerância (meio centavo para cima): a SEFAZ autorizou nota
# com 0,01005 de diferença para a conta sem arredondar.
arredondar_no_centavo = function(valores) {
  sign(valores) * floor(abs(valores) * 100 + 0.5 + FOLGA_DE_PONTO_FLUTUANTE) / 100
}

igual_com_tolerancia = function(valor, calculado, tolerancia) {
  !is.na(valor) & !is.na(calculado) & abs(valor - calculado) <= tolerancia + FOLGA_DE_PONTO_FLUTUANTE
}

valor_ou_zero = function(numeros) {
  numeros[is.na(numeros)] = 0
  numeros
}

texto_ou_vazio = function(textos) {
  textos[is.na(textos)] = "(vazio)"
  textos
}

texto_dos_dois_valores = function(valor_do_ibs, valor_da_cbs) {
  paste0("IBS ", texto_do_numero(valor_do_ibs, 2), ", CBS ", texto_do_numero(valor_da_cbs, 2))
}

texto_da_presenca = function(presente) {
  ifelse(presente, "informado", "n\u00e3o informado")
}

# O número com as casas pedidas, como no XML (ponto decimal); "(vazio)" quando não veio.
texto_do_numero = function(numeros, casas) {
  textos = formatC(numeros, format = "f", digits = casas)
  textos[is.na(numeros)] = "(vazio)"
  textos
}

# A alíquota sem os zeros que sobram no fim (0.9, 0.05, 60).
texto_da_aliquota = function(numeros) {
  textos = sub("\\.?0+$", "", formatC(numeros, format = "f", digits = 4))
  textos[is.na(numeros)] = "(vazio)"
  textos
}
