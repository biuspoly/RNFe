# Leitura do XML da NFS-e Nacional (padrão nacional, leiautes 1.00 e 1.01) em tabelas. Os caminhos seguem o
# schema oficial do portal da NFS-e (NFSe-ESQUEMAS_XSD-v1.01-20260209, que traz as duas versões).

#' @include ler_xml.R
NULL

CAMINHO_DAS_NFSES = "//NFSe/infNFSe"

# Coluna, caminho a partir do infNFSe e tipo. "a|b" pega o que existir. O que está fora do DPS foi gerado pelo
# sistema que autorizou a NFS-e (número, situação, valores calculados, IBS e CBS calculados); o que está no DPS
# foi declarado por quem emitiu. O xOutInf mudou de lugar da versão 1.00 para a 1.01.
CAMPOS_DA_NFSE = ler_campos("
coluna                              caminho                                                                                     tipo
numero                              nNFSe                                                                                       texto
numero_dfse                         nDFSe                                                                                       texto
situacao                            cStat                                                                                       inteiro
processamento                       dhProc                                                                                      data_hora
ambiente_gerador                    ambGer                                                                                      inteiro
tipo_emissao                        tpEmis                                                                                      inteiro
processo_emissao                    procEmi                                                                                     inteiro
emissao                             DPS/infDPS/dhEmi                                                                            data_hora
data_emissao                        DPS/infDPS/dhEmi                                                                            data
competencia                         DPS/infDPS/dCompet                                                                          data
ambiente                            DPS/infDPS/tpAmb                                                                            inteiro
serie_dps                           DPS/infDPS/serie                                                                            texto
numero_dps                          DPS/infDPS/nDPS                                                                             texto
tipo_emitente                       DPS/infDPS/tpEmit                                                                           inteiro
local_emissao_codigo_municipio      DPS/infDPS/cLocEmi                                                                          texto
local_emissao_municipio             xLocEmi                                                                                     texto
prestacao_codigo_municipio          DPS/infDPS/serv/locPrest/cLocPrestacao                                                      texto
prestacao_pais                      DPS/infDPS/serv/locPrest/cPaisPrestacao                                                     texto
prestacao_local                     xLocPrestacao                                                                               texto
incidencia_codigo_municipio         cLocIncid                                                                                   texto
incidencia_municipio                xLocIncid                                                                                   texto
substituida_chave                   DPS/infDPS/subst/chSubstda                                                                  texto
substituicao_motivo                 DPS/infDPS/subst/cMotivo                                                                    texto
emitente_documento                  emit/CNPJ|emit/CPF                                                                          texto
emitente_nome                       emit/xNome                                                                                  texto
emitente_fantasia                   emit/xFant                                                                                  texto
emitente_im                         emit/IM                                                                                     texto
emitente_codigo_municipio           emit/enderNac/cMun                                                                          texto
emitente_uf                         emit/enderNac/UF                                                                            texto
prestador_documento                 DPS/infDPS/prest/CNPJ|DPS/infDPS/prest/CPF|DPS/infDPS/prest/NIF                             texto
prestador_nome                      DPS/infDPS/prest/xNome                                                                      texto
prestador_im                        DPS/infDPS/prest/IM                                                                         texto
prestador_codigo_municipio          DPS/infDPS/prest/end/endNac/cMun                                                            texto
prestador_simples_nacional          DPS/infDPS/prest/regTrib/opSimpNac                                                          inteiro
prestador_regime_apuracao_simples   DPS/infDPS/prest/regTrib/regApTribSN                                                        inteiro
prestador_regime_especial           DPS/infDPS/prest/regTrib/regEspTrib                                                         inteiro
tomador_documento                   DPS/infDPS/toma/CNPJ|DPS/infDPS/toma/CPF|DPS/infDPS/toma/NIF                                texto
tomador_nome                        DPS/infDPS/toma/xNome                                                                       texto
tomador_im                          DPS/infDPS/toma/IM                                                                          texto
tomador_codigo_municipio            DPS/infDPS/toma/end/endNac/cMun                                                             texto
intermediario_documento             DPS/infDPS/interm/CNPJ|DPS/infDPS/interm/CPF|DPS/infDPS/interm/NIF                          texto
intermediario_nome                  DPS/infDPS/interm/xNome                                                                     texto
codigo_tributacao_nacional          DPS/infDPS/serv/cServ/cTribNac                                                              texto
tributacao_nacional                 xTribNac                                                                                    texto
codigo_tributacao_municipal         DPS/infDPS/serv/cServ/cTribMun                                                              texto
tributacao_municipal                xTribMun                                                                                    texto
nbs                                 DPS/infDPS/serv/cServ/cNBS                                                                  texto
nbs_descricao                       xNBS                                                                                        texto
descricao_servico                   DPS/infDPS/serv/cServ/xDescServ                                                             texto
codigo_interno_servico              DPS/infDPS/serv/cServ/cIntContrib                                                           texto
valor_servico                       DPS/infDPS/valores/vServPrest/vServ                                                         numero
valor_recebido_intermediario        DPS/infDPS/valores/vServPrest/vReceb                                                        numero
desconto_incondicionado             DPS/infDPS/valores/vDescCondIncond/vDescIncond                                              numero
desconto_condicionado               DPS/infDPS/valores/vDescCondIncond/vDescCond                                                numero
deducao_percentual                  DPS/infDPS/valores/vDedRed/pDR                                                              numero
deducao_valor                       DPS/infDPS/valores/vDedRed/vDR                                                              numero
tributacao_issqn                    DPS/infDPS/valores/trib/tribMun/tribISSQN                                                   inteiro
retencao_issqn                      DPS/infDPS/valores/trib/tribMun/tpRetISSQN                                                  inteiro
aliquota_issqn_informada            DPS/infDPS/valores/trib/tribMun/pAliq                                                       numero
deducao_calculada                   valores/vCalcDR                                                                             numero
beneficio_municipal_calculado       valores/vCalcBM                                                                             numero
base_issqn                          valores/vBC                                                                                 numero
aliquota_issqn                      valores/pAliqAplic                                                                          numero
valor_issqn                         valores/vISSQN                                                                              numero
valor_total_retido                  valores/vTotalRet                                                                           numero
valor_liquido                       valores/vLiq                                                                                numero
cst_pis_cofins                      DPS/infDPS/valores/trib/tribFed/piscofins/CST                                               texto
base_pis_cofins                     DPS/infDPS/valores/trib/tribFed/piscofins/vBCPisCofins                                      numero
aliquota_pis                        DPS/infDPS/valores/trib/tribFed/piscofins/pAliqPis                                          numero
aliquota_cofins                     DPS/infDPS/valores/trib/tribFed/piscofins/pAliqCofins                                       numero
valor_pis                           DPS/infDPS/valores/trib/tribFed/piscofins/vPis                                              numero
valor_cofins                        DPS/infDPS/valores/trib/tribFed/piscofins/vCofins                                           numero
retencao_pis_cofins                 DPS/infDPS/valores/trib/tribFed/piscofins/tpRetPisCofins                                    inteiro
valor_retido_cp                     DPS/infDPS/valores/trib/tribFed/vRetCP                                                      numero
valor_retido_irrf                   DPS/infDPS/valores/trib/tribFed/vRetIRRF                                                    numero
valor_retido_csll                   DPS/infDPS/valores/trib/tribFed/vRetCSLL                                                    numero
finalidade                          DPS/infDPS/IBSCBS/finNFSe                                                                   inteiro
consumo_final                       DPS/infDPS/IBSCBS/indFinal                                                                  inteiro
indicador_operacao                  DPS/infDPS/IBSCBS/cIndOp                                                                    texto
destinatario_indicador              DPS/infDPS/IBSCBS/indDest                                                                   inteiro
destinatario_documento              DPS/infDPS/IBSCBS/dest/CNPJ|DPS/infDPS/IBSCBS/dest/CPF|DPS/infDPS/IBSCBS/dest/NIF           texto
destinatario_nome                   DPS/infDPS/IBSCBS/dest/xNome                                                                texto
cst_ibs_cbs                         DPS/infDPS/IBSCBS/valores/trib/gIBSCBS/CST                                                  texto
classificacao_ibs_cbs               DPS/infDPS/IBSCBS/valores/trib/gIBSCBS/cClassTrib                                           texto
incidencia_ibs_cbs_codigo_municipio IBSCBS/cLocalidadeIncid                                                                     texto
incidencia_ibs_cbs_municipio        IBSCBS/xLocalidadeIncid                                                                     texto
base_ibs_cbs                        IBSCBS/valores/vBC                                                                          numero
aliquota_ibs_uf                     IBSCBS/valores/uf/pIBSUF                                                                    numero
aliquota_efetiva_ibs_uf             IBSCBS/valores/uf/pAliqEfetUF                                                               numero
aliquota_ibs_municipio              IBSCBS/valores/mun/pIBSMun                                                                  numero
aliquota_efetiva_ibs_municipio      IBSCBS/valores/mun/pAliqEfetMun                                                             numero
aliquota_cbs                        IBSCBS/valores/fed/pCBS                                                                     numero
aliquota_efetiva_cbs                IBSCBS/valores/fed/pAliqEfetCBS                                                             numero
valor_ibs_uf                        IBSCBS/totCIBS/gIBS/gIBSUFTot/vIBSUF                                                        numero
valor_ibs_municipio                 IBSCBS/totCIBS/gIBS/gIBSMunTot/vIBSMun                                                      numero
valor_ibs                           IBSCBS/totCIBS/gIBS/vIBSTot                                                                 numero
valor_cbs                           IBSCBS/totCIBS/gCBS/vCBS                                                                    numero
valor_total_com_ibs_cbs             IBSCBS/totCIBS/vTotNF                                                                       numero
pedido                              DPS/infDPS/serv/infoCompl/xPed                                                              texto
informacoes_complementares          DPS/infDPS/serv/infoCompl/xInfComp                                                          texto
outras_informacoes                  xOutInf|valores/xOutInf                                                                     texto
")

# O nome do CST e da classificação tributária do IBS e da CBS, como a tabela registrava na data de emissão.
DESCRICOES_DA_NFSE = ler_campos("
coluna_do_codigo      coluna_nova                tabela                texto
cst_ibs_cbs           cst_ibs_cbs_descricao      cst_ibs_cbs           descricao
classificacao_ibs_cbs classificacao_ibs_cbs_nome classificacao_ibs_cbs nome
")

# O que quer dizer cada código, ao lado dele: a coluna, o campo do leiaute e a coluna de que o significado depende
# ("-" quando não depende). Os textos estão em tabela_fiscal("codigos_dos_campos").
SIGNIFICADOS_DA_NFSE = ler_campos("
coluna_do_codigo                   campo          coluna_do_contexto
situacao                           cStat          -
ambiente_gerador                   ambGer         -
tipo_emissao                       tpEmis         -
processo_emissao                   procEmi        -
ambiente                           tpAmb          -
tipo_emitente                      tpEmit         -
substituicao_motivo                cMotivo        -
prestador_simples_nacional         opSimpNac      -
prestador_regime_apuracao_simples  regApTribSN    -
prestador_regime_especial          regEspTrib     -
tributacao_issqn                   tribISSQN      -
retencao_issqn                     tpRetISSQN     -
cst_pis_cofins                     CST            -
retencao_pis_cofins                tpRetPisCofins -
finalidade                         finNFSe        -
consumo_final                      indFinal       -
destinatario_indicador             indDest        -
")

#' Ler o XML da NFS-e Nacional
#'
#' Lê o XML da NFS-e do padrão nacional e devolve uma lista de tabelas
#' (`data.frame`s) ligadas pela `chave` (a chave de acesso de 50 posições):
#' `nfses` (uma linha por NFS-e: prestador, tomador, serviço, valor, ISSQN,
#' retenções, valor líquido, IBS e CBS), `campos` (todos os campos, um por
#' linha: deduções, obra, comércio exterior...) e `arquivos` (o que foi lido e
#' o motivo do que não deu).
#'
#' Lê os leiautes 1.00 e 1.01 (raiz `NFSe`), de um arquivo, de vários de uma
#' vez ou do próprio texto do XML. A NFS-e de prefeitura, no padrão próprio de
#' cada município, não é lida. Um arquivo que não dá para ler não interrompe os
#' outros: fica em `arquivos`, com o motivo. Para saber se a NFS-e foi
#' cancelada ou substituída, leia os eventos dela com [eventos_ler()].
#'
#' A NFS-e traz duas partes: a DPS, que quem emitiu declarou (prestador,
#' tomador, serviço, valores, tributos), e o que o sistema que a autorizou gerou
#' (número, situação, base e valor do ISSQN, valor líquido e o IBS e a CBS
#' calculados). Os códigos ficam como estão no XML, e ao lado de cada um vem o
#' que ele quer dizer, numa coluna `*_descricao`: a situação, o regime do
#' Simples Nacional, a tributação e a retenção do ISSQN, o CST do PIS e da
#' COFINS... pela documentação do schema oficial (veja
#' `tabela_fiscal("codigos_dos_campos")`), e o nome do CST e da classificação
#' do IBS e da CBS pela tabela fiscal na data. Campo que a NFS-e não tem fica
#' `NA`. Nenhum campo se perde: o que não tem coluna própria está na tabela
#' `campos`.
#'
#' O RNfe não confere o dígito da chave da NFS-e: a regra do cálculo não está
#' no schema nem no leiaute oficial.
#'
#' @section nfses:
#' Uma linha por NFS-e: `chave`, `versao` (do leiaute),
#' `r documentar_campos(CAMPOS_DA_NFSE)`;
#' e `arquivo`. `processamento` e `emissao` são data e hora (mostradas no
#' horário de Brasília); `data_emissao` e `competencia` são datas. Ao lado do
#' CST e da classificação tributária do IBS e da CBS vem o nome de cada um,
#' como a tabela registrava na data de emissão (`cst_ibs_cbs_descricao` e
#' `classificacao_ibs_cbs_nome`, veja [tabela_fiscal()]).
#'
#' @section campos:
#' Com `todos_os_campos = TRUE`, o padrão. Todos os campos da NFS-e, menos os
#' da assinatura digital, um por linha:
#' `chave`, `caminho` (onde o campo está, a partir do `infNFSe`, com a posição
#' quando o grupo se repete), `grupo` (o grupo logo acima do campo), `campo`
#' (o nome no leiaute) e `valor` (o texto do XML). É onde ficam as deduções e
#' seus documentos, a obra, o evento, o comércio exterior, os documentos de
#' reembolso, as NFS-e referenciadas e o que mais não tiver coluna própria.
#'
#' @section arquivos:
#' Uma linha por arquivo pedido: `arquivo`, `nfses` (quantas NFS-e tinha) e
#' `problema` (`NA` quando deu certo). Um texto de XML aparece como
#' `"(texto 1)"`, `"(texto 2)"`...
#'
#' @param arquivos Os XMLs a ler: o caminho de um arquivo, um vetor com vários
#'   (por exemplo, `list.files("pasta", pattern = "xml$", full.names = TRUE)`)
#'   ou o próprio texto do XML (começando por `<`).
#' @param todos_os_campos `FALSE` deixa de fora a tabela `campos`. O padrão é
#'   `TRUE` porque boa parte da NFS-e não tem coluna própria, e uma NFS-e tem
#'   poucos campos.
#' @return Uma lista com os `data.frame`s `nfses`, `campos` (só com
#'   `todos_os_campos = TRUE`) e `arquivos`.
#' @source Schema oficial da NFS-e Nacional, pacote NFSe-ESQUEMAS_XSD-v1.01-20260209,
#'   publicado na documentação técnica do portal da NFS-e (gov.br/nfse).
#' @examples
#' nfse = system.file("exemplos", "nfse_sp_v101.xml", package = "RNfe")
#' lida = nfse_ler(nfse)
#' lida$nfses[, c("chave", "numero", "prestador_documento", "valor_servico",
#'                "valor_issqn", "valor_cbs")]
#' @export
nfse_ler = function(arquivos, todos_os_campos = TRUE) {
  arquivos_lidos = ler_arquivos_xml(arquivos, CAMINHO_DAS_NFSES, "uma NFS-e Nacional", colunas_da_nfse, todos_os_campos)
  colunas_vazias = colunas_da_nfse(NULL, NA_character_, todos_os_campos)

  tabelas_da_nfse = list(nfses = juntar_tabela(arquivos_lidos, "nfses", colunas_vazias$nfses))
  if (todos_os_campos) {
    tabelas_da_nfse$campos = juntar_tabela(arquivos_lidos, "campos", colunas_vazias$campos)
  }
  tabelas_da_nfse$arquivos = resumo_dos_arquivos(arquivos_lidos, "nfses", "nfses")
  tabelas_da_nfse$nfses = converter_datas(tabelas_da_nfse$nfses, CAMPOS_DA_NFSE)
  tabelas_da_nfse$nfses = acrescentar_descricoes(tabelas_da_nfse$nfses, tabelas_da_nfse$nfses$data_emissao, DESCRICOES_DA_NFSE)
  tabelas_da_nfse$nfses = acrescentar_significados(tabelas_da_nfse$nfses, "NFS-e", SIGNIFICADOS_DA_NFSE)
  tabelas_da_nfse
}

# As colunas das tabelas de um arquivo de NFS-e, cada uma num vetor. Com xml_lido NULL, vêm vazias, já com os
# nomes e os tipos certos.
colunas_da_nfse = function(xml_lido, nome_do_arquivo, todos_os_campos) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  nfses = buscar_todos(xml_lido, CAMINHO_DAS_NFSES)
  # A versão do leiaute fica no NFSe, em volta do infNFSe.
  versao_de_cada = texto_de_cada(nfses, "parent::NFSe/@versao")

  colunas_das_tabelas = list(
    nfses = c(
      list(chave = chave_de_cada(nfses, "infNFSe"), versao = versao_de_cada),
      valores_dos_campos(nfses, CAMPOS_DA_NFSE),
      list(arquivo = rep(nome_do_arquivo, length(nfses)))
    )
  )
  if (todos_os_campos) {
    colunas_das_tabelas$campos = colunas_de_todos_os_campos(buscar_todos_os_campos(nfses), "infNFSe")
  }
  colunas_das_tabelas
}
