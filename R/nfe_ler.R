# Leitura do XML da NF-e e da NFC-e (leiaute 4.00) em tabelas. Os caminhos seguem o schema oficial
# do Portal da NF-e (pacote de liberação PL_010g v1.03, de 26/10/2026, que já traz a Reforma).

#' @include ler_xml.R
NULL

# O infNFe da nota fica sempre dentro do NFe. O CT-e e o MDF-e também têm infNFe, com a chave das notas que
# citam, e não são notas.
CAMINHO_DAS_NOTAS = "//NFe/infNFe"

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
natureza_operacao             ide/natOp                                   texto
tipo_operacao                 ide/tpNF                                    inteiro
destino_operacao              ide/idDest                                  inteiro
finalidade                    ide/finNFe                                  inteiro
consumidor_final              ide/indFinal                                inteiro
presenca                      ide/indPres                                 inteiro
forma_emissao                 ide/tpEmis                                  inteiro
ambiente                      ide/tpAmb                                   inteiro
processo_emissao              ide/procEmi                                 inteiro
formato_danfe                 ide/tpImp                                   inteiro
contingencia_entrada          ide/dhCont                                  data_hora
contingencia_justificativa    ide/xJust                                   texto
municipio_fato_gerador        ide/cMunFG                                  texto
emitente_documento            emit/CNPJ|emit/CPF                          texto
emitente_nome                 emit/xNome                                  texto
emitente_fantasia             emit/xFant                                  texto
emitente_ie                   emit/IE                                     texto
emitente_municipio            emit/enderEmit/xMun                         texto
emitente_codigo_municipio     emit/enderEmit/cMun                         texto
emitente_uf                   emit/enderEmit/UF                           texto
emitente_regime               emit/CRT                                    inteiro
avulsa_cnpj                   avulsa/CNPJ                                 texto
destinatario_documento        dest/CNPJ|dest/CPF|dest/idEstrangeiro       texto
destinatario_nome             dest/xNome                                  texto
destinatario_ie               dest/IE                                     texto
destinatario_indicador_ie     dest/indIEDest                              inteiro
destinatario_municipio        dest/enderDest/xMun                         texto
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
valor_is                      total/ISTot/vIS                             numero
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
cfop                      prod/CFOP                                  texto
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
informacoes_adicionais    infAdProd                                  texto
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
valor_is                  imposto/IS/vIS                             numero
percentual_devolvido      impostoDevol/pDevol                        numero
valor_ipi_devolvido       impostoDevol/IPI/vIPIDevol                 numero
")

# O nome de cada código do item, ao lado dele, como a tabela fiscal registrava na data de emissão da nota.
DESCRICOES_DOS_ITENS = ler_campos("
coluna_do_codigo      coluna_nova                tabela                texto
ncm                   ncm_descricao              ncm                   descricao_completa
cfop                  cfop_titulo                cfop                  titulo
origem                origem_descricao           origem                descricao
cst_icms              cst_icms_descricao         cst_icms              descricao
csosn                 csosn_descricao            csosn                 descricao
cst_ipi               cst_ipi_descricao          cst_ipi               descricao
cst_pis               cst_pis_descricao          cst_pis               descricao
cst_cofins            cst_cofins_descricao       cst_cofins            descricao
cst_ibs_cbs           cst_ibs_cbs_descricao      cst_ibs_cbs           descricao
classificacao_ibs_cbs classificacao_ibs_cbs_nome classificacao_ibs_cbs nome
")

# O que quer dizer cada código, ao lado dele: a coluna, o campo do leiaute e a coluna de que o significado depende
# ("-" quando não depende). Os textos estão em tabela_fiscal("codigos_dos_campos").
SIGNIFICADOS_DA_NOTA = ler_campos("
coluna_do_codigo          campo     coluna_do_contexto
tipo_operacao             tpNF      -
destino_operacao          idDest    -
finalidade                finNFe    -
consumidor_final          indFinal  -
presenca                  indPres   -
forma_emissao             tpEmis    -
ambiente                  tpAmb     -
processo_emissao          procEmi   -
formato_danfe             tpImp     -
emitente_regime           CRT       -
destinatario_indicador_ie indIEDest -
modalidade_frete          modFrete  -
")

SIGNIFICADOS_DO_ITEM = ler_campos("
coluna_do_codigo campo  coluna_do_contexto
compoe_total     indTot -
")

SIGNIFICADOS_DO_PAGAMENTO = ler_campos("
coluna_do_codigo campo  coluna_do_contexto
indicador        indPag -
")

# O nome da forma de pagamento e da bandeira do cartão, como as tabelas do Portal da NF-e registravam na data da
# nota.
DESCRICOES_DO_PAGAMENTO = ler_campos("
coluna_do_codigo coluna_nova        tabela           texto
forma            forma_descricao    meios_pagamento  descricao
bandeira         bandeira_descricao bandeiras_cartao descricao
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
#' item: produto, NCM, CFOP e os impostos em colunas, com o nome de cada
#' código), `impostos` (todos os campos de imposto, um por linha), `parcelas`,
#' `pagamentos`, `pagamentos_vinculados`, `campos` (todos os campos, só com
#' `todos_os_campos = TRUE`) e `arquivos` (o que foi lido e o motivo do que não
#' deu).
#'
#' Lê o leiaute 4.00, com ou sem o protocolo de autorização (`nfeProc` ou só
#' `NFe`), de um arquivo, de vários de uma vez ou do próprio texto do XML. Um
#' arquivo que não dá para ler não interrompe os outros: fica em `arquivos`,
#' com o motivo. Para saber se a nota foi cancelada, leia os eventos dela com
#' [eventos_ler()].
#'
#' Cada coluna vem de um campo do leiaute (entre parênteses abaixo). Os
#' códigos ficam como estão no XML, e ao lado de cada um vem o que ele quer
#' dizer: o nome do CFOP, do CST, da forma de pagamento e da bandeira, pela
#' tabela fiscal na data da nota, e o significado dos outros códigos (forma de
#' emissão, finalidade, presença, modalidade do frete...) numa coluna
#' `*_descricao`, pela documentação do schema oficial (veja
#' `tabela_fiscal("codigos_dos_campos")`). Campo que a nota não tem fica `NA`. O que não tem coluna própria vem na tabela `campos`, quando
#' pedida (`todos_os_campos = TRUE`).
#'
#' @section notas:
#' Uma linha por nota: `chave`, `versao`,
#' `r documentar_campos(CAMPOS_DA_NOTA)`;
#' do protocolo de autorização, quando vem junto:
#' `r documentar_campos(CAMPOS_DO_PROTOCOLO)`;
#' e `arquivo`. `emissao`, `saida_entrada`, `contingencia_entrada` e
#' `autorizacao` são data e hora (mostradas no horário de Brasília);
#' `data_emissao` é a data como está na nota. Na NFC-e (`modelo` 65), `qrcode`
#' e `url_consulta` vêm do grupo `infNFeSupl`, que fica fora do `infNFe`; o
#' texto do QR-Code fica como está, sem desmontar.
#'
#' @section itens:
#' Uma linha por item: `chave`, `item` (`nItem`),
#' `r documentar_campos(CAMPOS_DO_ITEM)`.
#' O `*` é o grupo do ICMS, do IPI, do PIS ou da COFINS que o item tiver (por
#' exemplo, `ICMS00` ou `ICMSSN102`). Ao lado de cada código vem o nome dele,
#' como a tabela fiscal registrava na data de emissão da nota (veja
#' [tabela_fiscal()]): `ncm_descricao` (a descrição completa, da posição até o
#' código), `cfop_titulo`, `origem_descricao`, `cst_icms_descricao`,
#' `csosn_descricao`, `cst_ipi_descricao`, `cst_pis_descricao`,
#' `cst_cofins_descricao`, `cst_ibs_cbs_descricao` e
#' `classificacao_ibs_cbs_nome`.
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
#' @section campos:
#' Só com `todos_os_campos = TRUE`. Todos os campos da nota, um por linha:
#' `chave`, `caminho` (onde o campo está, a partir do `infNFe`, com a posição
#' quando o grupo se repete, por exemplo `det[2]/prod/cProd`), `grupo` (o grupo
#' logo acima do campo), `campo` (o nome no leiaute) e `valor` (o texto do
#' XML). É onde ficam as notas referenciadas, os volumes do transporte, a
#' rastreabilidade do produto e o que mais não tiver coluna própria. Uma nota
#' tem, em média, uns 220 campos, e a tabela custa de 5 a 7 ms a mais por nota
#' e uns 10 KB de memória (medido em 10 mil notas reais): por isso ela só vem
#' quando pedida.
#'
#' @section arquivos:
#' Uma linha por arquivo pedido: `arquivo`, `notas` (quantas notas tinha) e
#' `problema` (`NA` quando deu certo). Um texto de XML aparece como
#' `"(texto 1)"`, `"(texto 2)"`...
#'
#' @param arquivos Os XMLs a ler: o caminho de um arquivo, um vetor com vários
#'   (por exemplo, `list.files("pasta", pattern = "xml$", full.names = TRUE)`)
#'   ou o próprio texto do XML (começando por `<`).
#' @param todos_os_campos `TRUE` devolve também a tabela `campos`, com todos os
#'   campos de cada nota.
#' @return Uma lista com os `data.frame`s `notas`, `itens`, `impostos`,
#'   `parcelas`, `pagamentos`, `pagamentos_vinculados`, `campos` (só com
#'   `todos_os_campos = TRUE`) e `arquivos`.
#' @source Schema oficial da NF-e, pacote de liberação PL_010g v1.03 (NT
#'   2026.006 e NT 2026.008), publicado no Portal Nacional da NF-e em
#'   26/10/2026.
#' @examples
#' nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNfe")
#' lida = nfe_ler(nota)
#' lida$notas[, c("chave", "emitente_nome", "valor_nota", "protocolo")]
#' lida$itens[, c("item", "descricao", "cfop", "cst_icms", "valor_icms", "valor_cbs")]
#' @export
nfe_ler = function(arquivos, todos_os_campos = FALSE) {
  arquivos_lidos = ler_arquivos_xml(arquivos, CAMINHO_DAS_NOTAS, "uma NF-e", colunas_da_nfe, todos_os_campos)
  colunas_vazias = colunas_da_nfe(NULL, NA_character_, todos_os_campos)

  tabelas_da_nfe = list(
    notas = juntar_tabela(arquivos_lidos, "notas", colunas_vazias$notas),
    itens = juntar_tabela(arquivos_lidos, "itens", colunas_vazias$itens),
    impostos = juntar_tabela(arquivos_lidos, "impostos", colunas_vazias$impostos),
    parcelas = juntar_tabela(arquivos_lidos, "parcelas", colunas_vazias$parcelas),
    pagamentos = juntar_tabela(arquivos_lidos, "pagamentos", colunas_vazias$pagamentos),
    pagamentos_vinculados = juntar_tabela(arquivos_lidos, "pagamentos_vinculados", colunas_vazias$pagamentos_vinculados)
  )
  if (todos_os_campos) {
    tabelas_da_nfe$campos = juntar_tabela(arquivos_lidos, "campos", colunas_vazias$campos)
  }
  tabelas_da_nfe$arquivos = resumo_dos_arquivos(arquivos_lidos, "notas", "notas")
  tabelas_da_nfe$notas = converter_datas(tabelas_da_nfe$notas, rbind(CAMPOS_DA_NOTA, CAMPOS_DO_PROTOCOLO))
  tabelas_da_nfe$parcelas = converter_datas(tabelas_da_nfe$parcelas, CAMPOS_DA_PARCELA)
  tabelas_da_nfe$pagamentos = converter_datas(tabelas_da_nfe$pagamentos, CAMPOS_DO_PAGAMENTO)
  data_de_cada_item = tabelas_da_nfe$notas$data_emissao[match(tabelas_da_nfe$itens$chave, tabelas_da_nfe$notas$chave)]
  tabelas_da_nfe$itens = acrescentar_descricoes(tabelas_da_nfe$itens, data_de_cada_item, DESCRICOES_DOS_ITENS)
  tabelas_da_nfe$notas = acrescentar_significados(tabelas_da_nfe$notas, "NF-e", SIGNIFICADOS_DA_NOTA)
  tabelas_da_nfe$itens = acrescentar_significados(tabelas_da_nfe$itens, "NF-e", SIGNIFICADOS_DO_ITEM)
  data_de_cada_pagamento = tabelas_da_nfe$notas$data_emissao[match(tabelas_da_nfe$pagamentos$chave, tabelas_da_nfe$notas$chave)]
  tabelas_da_nfe$pagamentos = acrescentar_significados(tabelas_da_nfe$pagamentos, "NF-e", SIGNIFICADOS_DO_PAGAMENTO)
  tabelas_da_nfe$pagamentos = acrescentar_descricoes(tabelas_da_nfe$pagamentos, data_de_cada_pagamento, DESCRICOES_DO_PAGAMENTO)
  data_de_cada_vinculado = tabelas_da_nfe$notas$data_emissao[match(tabelas_da_nfe$pagamentos_vinculados$chave, tabelas_da_nfe$notas$chave)]
  tabelas_da_nfe$pagamentos_vinculados = acrescentar_descricoes(tabelas_da_nfe$pagamentos_vinculados, data_de_cada_vinculado,
                                                                DESCRICOES_DO_PAGAMENTO_VINCULADO)
  tabelas_da_nfe
}

# As colunas das tabelas de um arquivo de NF-e, cada uma num vetor. Com xml_lido NULL, vêm vazias, já com
# os nomes e os tipos certos.
colunas_da_nfe = function(xml_lido, nome_do_arquivo, todos_os_campos) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  notas = buscar_todos(xml_lido, CAMINHO_DAS_NOTAS)
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
