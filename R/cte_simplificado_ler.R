# Leitura do XML do CT-e simplificado (modelo 57, tpCTe 5 e 6), leiaute 4.00, em tabelas. Tem o infCte, a chave e o
# protocolo do CT-e, mas no lugar do remetente, do destinatário e dos documentos de uma prestação só traz o tomador
# (com os dados dele) e um grupo det por entrega, cada um com os municípios, o valor, os componentes, o IBS e a CBS e
# os documentos dela. Os caminhos seguem o tipo TCTeSimp do schema oficial do Portal do CT-e (pacote de liberação
# PL_CTe_400 NT 2026.004 RTC 1.00).

#' @include ler_xml.R cte_ler.R
NULL

CAMINHO_DOS_CTES_SIMPLIFICADOS = "//CTeSimp/infCte"

# Coluna, caminho a partir do infCte e tipo. Os valores e o IBS e a CBS são os totais do CT-e (grupo total); os de
# cada entrega ficam na tabela entregas. O ICMS é um só, do CT-e inteiro, e é lido como no cte_ler(). O QR-Code fica
# fora do infCte, no infCTeSupl, ao lado dele.
CAMPOS_DO_CTE_SIMPLIFICADO = ler_campos("
coluna                          caminho                                           tipo
modelo                          ide/mod                                           texto
serie                           ide/serie                                         inteiro
numero                          ide/nCT                                           inteiro
emissao                         ide/dhEmi                                         data_hora
data_emissao                    ide/dhEmi                                         data
cfop                            ide/CFOP                                          texto
natureza_operacao               ide/natOp                                         texto
tipo_cte                        ide/tpCTe                                         inteiro
tipo_servico                    ide/tpServ                                        inteiro
modal                           ide/modal                                         texto
forma_emissao                   ide/tpEmis                                        inteiro
ambiente                        ide/tpAmb                                         inteiro
processo_emissao                ide/procEmi                                       inteiro
envio_codigo_municipio          ide/cMunEnv                                       texto
envio_municipio                 ide/xMunEnv                                       texto
envio_uf                        ide/UFEnv                                         texto
inicio_uf                       ide/UFIni                                         texto
fim_uf                          ide/UFFim                                         texto
retira                          ide/retira                                        inteiro
retira_detalhes                 ide/xDetRetira                                    texto
contingencia_entrada            ide/dhCont                                        data_hora
contingencia_justificativa      ide/xJust                                         texto
tomador_papel                   toma/toma                                         inteiro
tomador_indicador_ie            toma/indIEToma                                    inteiro
tomador_documento               toma/CNPJ|toma/CPF                                texto
tomador_nome                    toma/xNome                                        texto
tomador_ie                      toma/IE                                           texto
tomador_municipio               toma/enderToma/xMun                               texto
tomador_codigo_municipio        toma/enderToma/cMun                               texto
tomador_uf                      toma/enderToma/UF                                 texto
emitente_documento              emit/CNPJ|emit/CPF                                texto
emitente_nome                   emit/xNome                                        texto
emitente_fantasia               emit/xFant                                        texto
emitente_ie                     emit/IE                                           texto
emitente_municipio              emit/enderEmit/xMun                               texto
emitente_codigo_municipio       emit/enderEmit/cMun                               texto
emitente_uf                     emit/enderEmit/UF                                 texto
emitente_regime                 emit/CRT                                          inteiro
valor_prestacao                 total/vTPrest                                     numero
valor_prestacao_sem_tributos    total/vTPrestLiq                                  numero
valor_receber                   total/vTRec                                       numero
grupo_icms                      imp/ICMS/*                                        elemento
cst_icms                        imp/ICMS/*/CST                                    texto
reducao_base_icms               imp/ICMS/*/pRedBC|imp/ICMS/*/pRedBCOutraUF        numero
base_icms                       imp/ICMS/*/vBC|imp/ICMS/*/vBCOutraUF              numero
aliquota_icms                   imp/ICMS/*/pICMS|imp/ICMS/*/pICMSOutraUF          numero
valor_icms                      imp/ICMS/*/vICMS|imp/ICMS/*/vICMSOutraUF          numero
base_icms_st_retido             imp/ICMS/*/vBCSTRet                               numero
aliquota_icms_st_retido         imp/ICMS/*/pICMSSTRet                             numero
valor_icms_st_retido            imp/ICMS/*/vICMSSTRet                             numero
valor_credito_icms              imp/ICMS/*/vCred                                  numero
valor_icms_desonerado           imp/ICMS/*/vICMSDeson                             numero
valor_icms_previsto             imp/ICMS/gICMSPrevistoPagtoAntecip/vICMSPrevisto  numero
beneficio_fiscal                imp/ICMS/*/cBenef                                 texto
simples_nacional                imp/ICMS/*/indSN                                  inteiro
valor_tributos_aproximado       imp/vTotTrib                                      numero
informacoes_fisco               imp/infAdFisco                                    texto
base_icms_uf_fim                imp/ICMSUFFim/vBCUFFim                            numero
valor_fcp_uf_fim                imp/ICMSUFFim/vFCPUFFim                           numero
valor_icms_uf_fim               imp/ICMSUFFim/vICMSUFFim                          numero
valor_icms_uf_inicio            imp/ICMSUFFim/vICMSUFIni                          numero
base_ibs_cbs                    total/IBSCBSTot/vBCIBSCBS                         numero
valor_ibs_uf                    total/IBSCBSTot/gIBS/gIBSUF/vIBSUF                numero
valor_ibs_municipio             total/IBSCBSTot/gIBS/gIBSMun/vIBSMun              numero
valor_ibs                       total/IBSCBSTot/gIBS/vIBS                         numero
valor_cbs                       total/IBSCBSTot/gCBS/vCBS                         numero
valor_total_documento           total/vTotDFe                                     numero
valor_carga                     infCarga/vCarga                                   numero
produto_predominante            infCarga/proPred                                  texto
outras_caracteristicas_carga    infCarga/xOutCat                                  texto
valor_carga_averbacao           infCarga/vCargaAverb                              numero
rntrc                           infModal/rodo/RNTRC                               texto
fatura_numero                   cobr/fat/nFat                                     texto
fatura_valor_original           cobr/fat/vOrig                                    numero
fatura_desconto                 cobr/fat/vDesc                                    numero
fatura_valor_liquido            cobr/fat/vLiq                                     numero
caracteristica_transporte       compl/xCaracAd                                    texto
caracteristica_servico          compl/xCaracSer                                   texto
observacoes_gerais              compl/xObs                                        texto
qrcode                          parent::CTeSimp/infCTeSupl/qrCodCTe               texto
")

# O nome do CFOP, ao lado dele, como a tabela fiscal registrava na data de emissão do CT-e.
DESCRICOES_DO_CTE_SIMPLIFICADO = ler_campos("
coluna_do_codigo coluna_nova tabela texto
cfop             cfop_titulo cfop   titulo
")

# Os códigos são os do documento CT-e da tabela_fiscal("codigos_dos_campos"). O toma 4 é "Terceiro" no CT-e
# simplificado (tipo 5 e 6) e "Outros" no CT-e, por isso o tipo do CT-e é o contexto dele.
SIGNIFICADOS_DO_CTE_SIMPLIFICADO = ler_campos("
coluna_do_codigo      campo          coluna_do_contexto
modelo                mod            -
tipo_cte              tpCTe          -
tipo_servico          tpServ         -
modal                 modal          -
forma_emissao         tpEmis         -
ambiente              tpAmb          -
processo_emissao      procEmi        modelo
retira                retira         -
tomador_papel         toma           tipo_cte
tomador_indicador_ie  indIEToma      -
emitente_regime       CRT            -
cst_icms              CST            grupo_icms
simples_nacional      indSN          -
")

# A partir de cada det: uma entrega, com o número dela no CT-e (nItem).
CAMPOS_DA_ENTREGA = ler_campos("
coluna                        caminho                          tipo
entrega                       @nItem                           inteiro
inicio_codigo_municipio       cMunIni                          texto
inicio_municipio              xMunIni                          texto
fim_codigo_municipio          cMunFim                          texto
fim_municipio                 xMunFim                          texto
valor_prestacao               vPrest                           numero
valor_prestacao_sem_tributos  vPrestLiq                        numero
valor_receber                 vRec                             numero
cst_ibs_cbs                   IBSCBS/CST                       texto
classificacao_ibs_cbs         IBSCBS/cClassTrib                texto
base_ibs_cbs                  IBSCBS/gIBSCBS/vBC               numero
aliquota_ibs_uf               IBSCBS/gIBSCBS/gIBSUF/pIBSUF     numero
valor_ibs_uf                  IBSCBS/gIBSCBS/gIBSUF/vIBSUF     numero
aliquota_ibs_municipio        IBSCBS/gIBSCBS/gIBSMun/pIBSMun   numero
valor_ibs_municipio           IBSCBS/gIBSCBS/gIBSMun/vIBSMun   numero
valor_ibs                     IBSCBS/gIBSCBS/vIBS              numero
aliquota_cbs                  IBSCBS/gIBSCBS/gCBS/pCBS         numero
valor_cbs                     IBSCBS/gIBSCBS/gCBS/vCBS         numero
")

# O nome do CST e da classificação tributária do IBS e da CBS de cada entrega, na data de emissão do CT-e.
DESCRICOES_DA_ENTREGA = ler_campos("
coluna_do_codigo      coluna_nova                tabela                texto
cst_ibs_cbs           cst_ibs_cbs_descricao      cst_ibs_cbs           descricao
classificacao_ibs_cbs classificacao_ibs_cbs_nome classificacao_ibs_cbs nome
")

# A partir de cada Comp (det/Comp): os componentes do valor de cada entrega.
CAMPOS_DO_COMPONENTE_DA_ENTREGA = ler_campos("
coluna  caminho               tipo
entrega ancestor::det/@nItem  inteiro
nome    xNome                 texto
valor   vComp                 numero
")

# Os documentos que o CT-e simplificado cita, na ordem do XML: os da Reforma no ide (o do pagamento antecipado e o
# anterior da compra governamental); em cada entrega, as NF-e (infNFe) ou o CT-e anterior (infDocAnt) com as NF-e
# informadas dentro dele (infNFeTranspParcial); e o CT-e que este substitui (infCteSub).
CAMINHO_DOS_DOCUMENTOS_DO_SIMPLIFICADO = paste(
  "ide/gPagAntecipado/chDFePagAnt",
  "ide/gCompraGov/refDFeAnt",
  "det/infNFe",
  "det/infDocAnt",
  "det/infDocAnt/infNFeTranspParcial",
  "infCteSub",
  sep = "|"
)

# A partir de cada documento. Cada grupo tem só alguns destes campos; o resto fica NA.
CAMPOS_DO_DOCUMENTO_DO_SIMPLIFICADO = ler_campos("
coluna              caminho                  tipo
entrega             ancestor::det/@nItem     inteiro
tipo                self::*                  elemento
documento_chave     chNFe|chCTe|chCte|self::chDFePagAnt|self::refDFeAnt  texto
pin                 PIN                      texto
previsao_entrega    dPrev                    data
tipo_prestacao      tpPrest                  inteiro
cte_anterior_chave  parent::infDocAnt/chCTe  texto
altera_tomador      indAlteraToma            inteiro
")

SIGNIFICADOS_DO_DOCUMENTO_DO_SIMPLIFICADO = ler_campos("
coluna_do_codigo campo         coluna_do_contexto
tipo_prestacao   tpPrest       -
altera_tomador   indAlteraToma -
")

# No CT-e simplificado o tipo da medida é um código; no CT-e é texto livre.
SIGNIFICADOS_DA_CARGA_DO_SIMPLIFICADO = ler_campos("
coluna_do_codigo campo coluna_do_contexto
unidade          cUnid -
tipo_medida      tpMed -
")

#' Ler o XML do CT-e simplificado
#'
#' Lê o XML do CT-e simplificado (modelo 57, tipo 5, e o de substituição,
#' tipo 6) e devolve uma lista de tabelas (`data.frame`s) ligadas pela
#' `chave`: `ctes` (uma linha por CT-e: o tomador, o emitente, os totais, o
#' ICMS, o IBS e a CBS, a carga e o protocolo), `entregas` (uma linha por
#' entrega: os municípios de início e de fim, o valor, o IBS e a CBS),
#' `componentes` (frete peso, pedágio... de cada entrega), `documentos` (as
#' NF-e de cada entrega, o CT-e anterior e o CT-e substituído), `cargas` (as
#' quantidades), `impostos` (todos os campos de imposto, um por linha),
#' `parcelas`, `pagamentos_vinculados`, `observacoes`, `campos` (todos os
#' campos, só com `todos_os_campos = TRUE`) e `arquivos` (o que foi lido e o
#' motivo do que não deu).
#'
#' O CT-e simplificado tem a chave e o protocolo do CT-e, e os eventos dele
#' (o cancelamento, por exemplo) são os do CT-e, lidos por [eventos_ler()].
#' Mas, no lugar do remetente, do destinatário e dos documentos de uma
#' prestação só, traz o tomador e um grupo por entrega (`det`, até 990), cada
#' um com o seu valor, o IBS e a CBS e os seus documentos. Por isso tem leitor
#' próprio, e não entra em [cte_ler()]. Lê o leiaute 4.00, com ou sem o
#' protocolo de autorização (`cteSimpProc` ou só `CTeSimp`), de um arquivo,
#' de vários de uma vez ou do próprio texto do XML. Um arquivo que não dá para
#' ler não interrompe os outros: fica em `arquivos`, com o motivo.
#'
#' Cada coluna vem de um campo do leiaute (entre parênteses abaixo). Os
#' códigos ficam como estão no XML, e ao lado de cada um vem o que ele quer
#' dizer: o nome do CFOP e do CST e da classificação tributária do IBS e da
#' CBS, pela tabela fiscal na data do CT-e, e o significado dos outros códigos
#' (tipo do CT-e, serviço, modal, papel do tomador, unidade e tipo da medida
#' da carga, prestação total ou parcial...) numa coluna `*_descricao`, pela
#' documentação do schema oficial (veja `tabela_fiscal("codigos_dos_campos")`,
#' documento `"CT-e"`). Campo que o CT-e não tem fica `NA`.
#'
#' @section ctes:
#' Uma linha por CT-e simplificado: `chave`, `versao`,
#' `r documentar_campos(CAMPOS_DO_CTE_SIMPLIFICADO)`;
#' do protocolo de autorização, quando vem junto:
#' `r documentar_campos(CAMPOS_DO_PROTOCOLO)`;
#' e `arquivo`. `emissao`, `contingencia_entrada` e `autorizacao` são data e
#' hora (mostradas no horário de Brasília); `data_emissao` é a data como está
#' no CT-e.
#'
#' As colunas `tomador_` trazem os dados do próprio grupo `toma`; o
#' `tomador_papel` diz quem o tomador é na prestação (remetente, expedidor,
#' recebedor, destinatário ou terceiro). Os valores, o IBS e a CBS são os
#' totais do CT-e (grupo `total`); os de cada entrega estão em `entregas`. O
#' ICMS é um só, do CT-e inteiro, lido como no [cte_ler()]: o `*` é o grupo do
#' ICMS que o CT-e tiver, e `grupo_icms` diz qual. Ao lado do CFOP vem o nome
#' dele (`cfop_titulo`); o significado do CST do ICMS (`cst_icms_descricao`)
#' segue o leiaute do CT-e, pelo grupo.
#'
#' @section entregas:
#' Uma linha por entrega (grupo `det`): `chave`,
#' `r documentar_campos(CAMPOS_DA_ENTREGA)`. `entrega` é o número dela no
#' CT-e e liga a ela as linhas de `componentes`, `documentos` e `impostos`. Ao
#' lado do CST e da classificação tributária do IBS e da CBS vêm
#' `cst_ibs_cbs_descricao` e `classificacao_ibs_cbs_nome`, como a tabela
#' fiscal registrava na data de emissão do CT-e.
#'
#' @section componentes:
#' Os componentes do valor de cada entrega (frete peso, pedágio...), um por
#' linha: `chave`, `r documentar_campos(CAMPOS_DO_COMPONENTE_DA_ENTREGA)`.
#'
#' @section documentos:
#' Os documentos que o CT-e simplificado cita, um por linha: `chave`,
#' `r documentar_campos(CAMPOS_DO_DOCUMENTO_DO_SIMPLIFICADO)`.
#' Cada grupo tem só alguns desses campos. `tipo` é o grupo de onde o documento
#' veio:
#' * `chDFePagAnt`: o documento do pagamento antecipado cujas parcelas este
#'   abate (grupo `gPagAntecipado`, da Reforma; sem `entrega`);
#' * `refDFeAnt`: o documento fiscal anterior da compra governamental (grupo
#'   `gCompraGov`, da Reforma; sem `entrega`);
#' * `infNFe`: as NF-e da entrega;
#' * `infDocAnt`: o CT-e anterior da entrega, com `tipo_prestacao`, que diz se
#'   a prestação é total ou parcial em relação às notas dele;
#' * `infNFeTranspParcial`: as NF-e informadas dentro do grupo do CT-e
#'   anterior, que vem em `cte_anterior_chave`;
#' * `infCteSub`: o CT-e que este substitui (sem `entrega`), e
#'   `altera_tomador` diz se a substituição é para trocar o tomador.
#'
#' @section cargas:
#' As quantidades da carga, uma por linha (o mesmo CT-e pode trazer o peso e o
#' número de caixas, por exemplo): `chave`,
#' `r documentar_campos(CAMPOS_DA_CARGA)`. Aqui o `tipo_medida` é um código
#' (peso bruto da NF-e, caixas, paletes...), com o significado ao lado; no
#' CT-e ele é texto livre.
#'
#' @section impostos:
#' Todos os campos dos impostos, um por linha: `chave`, `entrega` (o número
#' da entrega, no IBS e na CBS de cada uma; `NA` no que é do CT-e inteiro),
#' `tributo` (o grupo de cima: o grupo logo abaixo de `imp`, como `ICMS` e
#' `ICMSUFFim`; `IBSCBS` no de cada entrega; `IBSCBSTot` nos totais do IBS e
#' da CBS), `grupo` (onde o campo está, por exemplo `ICMS00` ou `gCBS`),
#' `campo` (o nome no leiaute) e `valor` (o texto do XML). É o que sobra para
#' quem precisa de um campo que não está em `ctes` nem em `entregas` (o
#' diferimento e a devolução de tributos, por exemplo).
#'
#' @section parcelas, pagamentos vinculados e observações:
#' `parcelas`, uma linha por duplicata: `chave`,
#' `r documentar_campos(CAMPOS_DA_PARCELA)`.
#' `pagamentos_vinculados`, uma linha por pagamento vinculado da Reforma (o
#' que liga o CT-e à transação de pagamento usada no split payment): `chave`,
#' `r documentar_campos(CAMPOS_DO_PAGAMENTO_VINCULADO)`. O código do meio de
#' pagamento é o da tabela do Informe Técnico 2026.001.
#' `observacoes`, uma linha por campo de uso livre (`ObsCont` e `ObsFisco`):
#' `chave`, `r documentar_campos(CAMPOS_DA_OBSERVACAO)`.
#'
#' @section campos:
#' Só com `todos_os_campos = TRUE`. Todos os campos do CT-e simplificado, um
#' por linha: `chave`, `caminho` (onde o campo está, a partir do `infCte`, com
#' a posição quando o grupo se repete, por exemplo `det[2]/Comp/vComp`; o
#' número entre colchetes é a posição no XML, e o número da entrega, que o
#' schema não obriga a seguir a ordem, está em `entregas`),
#' `grupo` (o grupo logo acima do campo), `campo` (o nome no leiaute) e
#' `valor` (o texto do XML). É onde ficam os endereços completos, as unidades
#' de carga e de transporte de cada NF-e, as compras governamentais, os
#' autorizados a baixar o XML e o responsável técnico.
#'
#' @section arquivos:
#' Uma linha por arquivo pedido: `arquivo`, `ctes` (quantos CT-e simplificados
#' tinha) e `problema` (`NA` quando deu certo). Um texto de XML aparece como
#' `"(texto 1)"`, `"(texto 2)"`...
#'
#' @param arquivos Os XMLs a ler: o caminho de um arquivo, um vetor com vários
#'   (por exemplo, `list.files("pasta", pattern = "xml$", full.names = TRUE)`)
#'   ou o próprio texto do XML (começando por `<`).
#' @param todos_os_campos `TRUE` devolve também a tabela `campos`, com todos os
#'   campos de cada CT-e.
#' @return Uma lista com os `data.frame`s `ctes`, `entregas`, `componentes`,
#'   `documentos`, `cargas`, `impostos`, `parcelas`, `pagamentos_vinculados`,
#'   `observacoes`, `campos` (só com `todos_os_campos = TRUE`) e `arquivos`.
#' @source Schema oficial do CT-e, pacote de liberação PL_CTe_400 NT 2026.004
#'   RTC 1.00 (tipo `TCTeSimp`, `cteSimp_v4.00.xsd` e
#'   `procCTeSimp_v4.00.xsd`), publicado no Portal Nacional do CT-e
#'   (republicado em 16/10/2026).
#' @examples
#' simplificado = system.file("exemplos", "cte_simp_proc_sp.xml", package = "RNFe")
#' lido = cte_simplificado_ler(simplificado)
#' lido$ctes[, c("chave", "tomador_nome", "valor_prestacao", "valor_icms", "valor_cbs")]
#' lido$entregas[, c("entrega", "fim_municipio", "valor_prestacao", "valor_cbs")]
#' lido$documentos[, c("entrega", "tipo", "documento_chave")]
#' @export
cte_simplificado_ler = function(arquivos, todos_os_campos = FALSE) {
  arquivos_lidos = ler_arquivos_xml(arquivos, CAMINHO_DOS_CTES_SIMPLIFICADOS, "um CT-e simplificado",
                                    colunas_do_cte_simplificado, todos_os_campos)
  colunas_vazias = colunas_do_cte_simplificado(NULL, NA_character_, todos_os_campos)

  tabelas_do_simplificado = list(
    ctes = juntar_tabela(arquivos_lidos, "ctes", colunas_vazias$ctes),
    entregas = juntar_tabela(arquivos_lidos, "entregas", colunas_vazias$entregas),
    componentes = juntar_tabela(arquivos_lidos, "componentes", colunas_vazias$componentes),
    documentos = juntar_tabela(arquivos_lidos, "documentos", colunas_vazias$documentos),
    cargas = juntar_tabela(arquivos_lidos, "cargas", colunas_vazias$cargas),
    impostos = juntar_tabela(arquivos_lidos, "impostos", colunas_vazias$impostos),
    parcelas = juntar_tabela(arquivos_lidos, "parcelas", colunas_vazias$parcelas),
    pagamentos_vinculados = juntar_tabela(arquivos_lidos, "pagamentos_vinculados", colunas_vazias$pagamentos_vinculados),
    observacoes = juntar_tabela(arquivos_lidos, "observacoes", colunas_vazias$observacoes)
  )
  if (todos_os_campos) {
    tabelas_do_simplificado$campos = juntar_tabela(arquivos_lidos, "campos", colunas_vazias$campos)
  }
  tabelas_do_simplificado$arquivos = resumo_dos_arquivos(arquivos_lidos, "ctes", "ctes")

  ctes = converter_datas(tabelas_do_simplificado$ctes, rbind(CAMPOS_DO_CTE_SIMPLIFICADO, CAMPOS_DO_PROTOCOLO))
  ctes = acrescentar_descricoes(ctes, ctes$data_emissao, DESCRICOES_DO_CTE_SIMPLIFICADO)
  tabelas_do_simplificado$ctes = acrescentar_significados(ctes, "CT-e", SIGNIFICADOS_DO_CTE_SIMPLIFICADO)

  # A entrega e o pagamento vinculado não têm data: vale a de emissão do CT-e deles.
  data_de_cada_entrega = ctes$data_emissao[match(tabelas_do_simplificado$entregas$chave, ctes$chave)]
  tabelas_do_simplificado$entregas = acrescentar_descricoes(tabelas_do_simplificado$entregas, data_de_cada_entrega,
                                                            DESCRICOES_DA_ENTREGA)
  data_de_cada_vinculado = ctes$data_emissao[match(tabelas_do_simplificado$pagamentos_vinculados$chave, ctes$chave)]
  tabelas_do_simplificado$pagamentos_vinculados = acrescentar_descricoes(tabelas_do_simplificado$pagamentos_vinculados,
                                                                         data_de_cada_vinculado,
                                                                         DESCRICOES_DO_PAGAMENTO_VINCULADO)

  documentos = converter_datas(tabelas_do_simplificado$documentos, CAMPOS_DO_DOCUMENTO_DO_SIMPLIFICADO)
  tabelas_do_simplificado$documentos = acrescentar_significados(documentos, "CT-e", SIGNIFICADOS_DO_DOCUMENTO_DO_SIMPLIFICADO)
  tabelas_do_simplificado$cargas = acrescentar_significados(tabelas_do_simplificado$cargas, "CT-e",
                                                            SIGNIFICADOS_DA_CARGA_DO_SIMPLIFICADO)
  tabelas_do_simplificado$parcelas = converter_datas(tabelas_do_simplificado$parcelas, CAMPOS_DA_PARCELA)
  tabelas_do_simplificado
}

# As colunas das tabelas de um arquivo de CT-e simplificado, cada uma num vetor. Com xml_lido NULL, vêm vazias, já com
# os nomes e os tipos certos.
colunas_do_cte_simplificado = function(xml_lido, nome_do_arquivo, todos_os_campos) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  ctes = buscar_todos(xml_lido, CAMINHO_DOS_CTES_SIMPLIFICADOS)
  protocolos = buscar_todos(xml_lido, "//protCTe/infProt")
  entregas = buscar_todos(ctes, "det")
  componentes = buscar_todos(ctes, "det/Comp")
  documentos = buscar_todos(ctes, CAMINHO_DOS_DOCUMENTOS_DO_SIMPLIFICADO)
  cargas = buscar_todos(ctes, "infCarga/infQ")
  campos_dos_impostos = buscar_todos(ctes, "imp//*[not(*)]|det/IBSCBS//*[not(*)]|total/IBSCBSTot//*[not(*)]")
  duplicatas = buscar_todos(ctes, "cobr/dup")
  observacoes = buscar_todos(ctes, "compl/ObsCont|compl/ObsFisco")
  pagamentos_vinculados = buscar_todos(ctes, "pgtoVinc/pgto")

  chaves = chave_de_cada(ctes, "infCte")
  # O protocolo é casado com o CT-e pela chave; CT-e que veio sem protocolo fica com NA.
  protocolo_de_cada_cte = match(chaves, texto_de_cada(protocolos, "chCTe"))

  colunas_das_tabelas = list(
    ctes = c(
      list(chave = chaves, versao = xml2::xml_attr(ctes, "versao")),
      valores_dos_campos(ctes, CAMPOS_DO_CTE_SIMPLIFICADO),
      valores_dos_campos(protocolos, CAMPOS_DO_PROTOCOLO, protocolo_de_cada_cte),
      list(arquivo = rep(nome_do_arquivo, length(ctes)))
    ),
    entregas = c(list(chave = chave_de_cada(entregas, "infCte")), valores_dos_campos(entregas, CAMPOS_DA_ENTREGA)),
    componentes = c(
      list(chave = chave_de_cada(componentes, "infCte")),
      valores_dos_campos(componentes, CAMPOS_DO_COMPONENTE_DA_ENTREGA)
    ),
    documentos = c(
      list(chave = chave_de_cada(documentos, "infCte")),
      valores_dos_campos(documentos, CAMPOS_DO_DOCUMENTO_DO_SIMPLIFICADO)
    ),
    cargas = c(list(chave = chave_de_cada(cargas, "infCte")), valores_dos_campos(cargas, CAMPOS_DA_CARGA)),
    impostos = colunas_dos_impostos_do_simplificado(campos_dos_impostos),
    parcelas = c(list(chave = chave_de_cada(duplicatas, "infCte")), valores_dos_campos(duplicatas, CAMPOS_DA_PARCELA)),
    pagamentos_vinculados = c(
      list(chave = chave_de_cada(pagamentos_vinculados, "infCte")),
      valores_dos_campos(pagamentos_vinculados, CAMPOS_DO_PAGAMENTO_VINCULADO)
    ),
    observacoes = c(list(chave = chave_de_cada(observacoes, "infCte")), valores_dos_campos(observacoes, CAMPOS_DA_OBSERVACAO))
  )
  if (todos_os_campos) {
    colunas_das_tabelas$campos = colunas_de_todos_os_campos(buscar_todos_os_campos(ctes), "infCte")
  }
  colunas_das_tabelas
}

# Um campo de imposto por linha, como no cte_ler(), com a entrega. O tributo é o grupo logo abaixo de <imp> (ICMS,
# ICMSUFFim...), o IBSCBS de cada entrega ou o IBSCBSTot dos totais; o grupo é onde o campo está (ICMS00, gCBS...).
colunas_dos_impostos_do_simplificado = function(campos_dos_impostos) {
  tributo_de_cada_campo = xml2::xml_find_first(campos_dos_impostos,
                                               "ancestor-or-self::*[parent::imp or parent::det or parent::total]",
                                               ns = SEM_NAMESPACE)
  # xml_parent() devolveria cada grupo uma vez só; parent::* devolve um por campo.
  grupo_de_cada_campo = xml2::xml_find_first(campos_dos_impostos, "parent::*", ns = SEM_NAMESPACE)
  list(
    chave = chave_de_cada(campos_dos_impostos, "infCte"),
    entrega = as.integer(texto_de_cada(campos_dos_impostos, "ancestor::det/@nItem")),
    tributo = xml2::xml_name(tributo_de_cada_campo),
    grupo = xml2::xml_name(grupo_de_cada_campo),
    campo = xml2::xml_name(campos_dos_impostos),
    valor = xml2::xml_text(campos_dos_impostos)
  )
}
