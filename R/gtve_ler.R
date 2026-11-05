# Leitura do XML da GTV-e (Guia de Transporte de Valores Eletrônica, modelo 64), leiaute 4.00, em tabelas. A GTV-e é
# um CT-e do tipo 4 (tpCTe): tem o infCte, a chave e o protocolo do CT-e, mas no lugar do valor da prestação e dos
# impostos traz os valores levados (as espécies), os malotes e os veículos. Os caminhos seguem o tipo TGTVe do schema
# oficial do Portal do CT-e (pacote de liberação PL_CTe_400 NT 2026.005 RTC SN 1.00, de 04/11/2026; o TGTVe é igual
# ao do pacote anterior).

#' @include ler_xml.R cte_ler.R
NULL

CAMINHO_DAS_GTVES = "//GTVe/infCte"

# Coluna, caminho a partir do infCte e tipo. O tomador é o remetente ou o destinatário (grupo toma, só com o papel) ou
# outra pessoa, com os dados no próprio grupo (tomaTerceiro). O QR-Code fica fora do infCte, no infCTeSupl, ao lado
# dele.
CAMPOS_DA_GTVE = ler_campos("
coluna                        caminho                                     tipo
modelo                        ide/mod                                     texto
serie                         ide/serie                                   inteiro
numero                        ide/nCT                                     inteiro
emissao                       ide/dhEmi                                   data_hora
data_emissao                  ide/dhEmi                                   data
cfop                          ide/CFOP                                    texto
natureza_operacao             ide/natOp                                   texto
tipo_cte                      ide/tpCTe                                   inteiro
tipo_servico                  ide/tpServ                                  inteiro
modal                         ide/modal                                   texto
formato_dacte                 ide/tpImp                                   inteiro
forma_emissao                 ide/tpEmis                                  inteiro
ambiente                      ide/tpAmb                                   inteiro
envio_codigo_municipio        ide/cMunEnv                                 texto
envio_municipio               ide/xMunEnv                                 texto
envio_uf                      ide/UFEnv                                   texto
saida_origem                  ide/dhSaidaOrig                             data_hora
chegada_destino               ide/dhChegadaDest                           data_hora
contingencia_entrada          ide/dhCont                                  data_hora
contingencia_justificativa    ide/xJust                                   texto
tomador_papel                 ide/toma/toma|ide/tomaTerceiro/toma         inteiro
tomador_indicador_ie          ide/indIEToma                               inteiro
tomador_documento             ide/tomaTerceiro/CNPJ|ide/tomaTerceiro/CPF  texto
tomador_nome                  ide/tomaTerceiro/xNome                      texto
tomador_ie                    ide/tomaTerceiro/IE                         texto
tomador_municipio             ide/tomaTerceiro/enderToma/xMun             texto
tomador_codigo_municipio      ide/tomaTerceiro/enderToma/cMun             texto
tomador_uf                    ide/tomaTerceiro/enderToma/UF               texto
emitente_documento            emit/CNPJ                                   texto
emitente_nome                 emit/xNome                                  texto
emitente_fantasia             emit/xFant                                  texto
emitente_ie                   emit/IE                                     texto
emitente_municipio            emit/enderEmit/xMun                         texto
emitente_codigo_municipio     emit/enderEmit/cMun                         texto
emitente_uf                   emit/enderEmit/UF                           texto
remetente_documento           rem/CNPJ|rem/CPF                            texto
remetente_nome                rem/xNome                                   texto
remetente_ie                  rem/IE                                      texto
remetente_municipio           rem/enderReme/xMun                          texto
remetente_codigo_municipio    rem/enderReme/cMun                          texto
remetente_uf                  rem/enderReme/UF                            texto
destinatario_documento        dest/CNPJ|dest/CPF                          texto
destinatario_nome             dest/xNome                                  texto
destinatario_ie               dest/IE                                     texto
destinatario_municipio        dest/enderDest/xMun                         texto
destinatario_codigo_municipio dest/enderDest/cMun                         texto
destinatario_uf               dest/enderDest/UF                           texto
origem_municipio              origem/xMun                                 texto
origem_codigo_municipio       origem/cMun                                 texto
origem_uf                     origem/UF                                   texto
destino_municipio             destino/xMun                                texto
destino_codigo_municipio      destino/cMun                                texto
destino_uf                    destino/UF                                  texto
quantidade_volumes            detGTV/qCarga                               numero
caracteristica_transporte     compl/xCaracAd                              texto
caracteristica_servico        compl/xCaracSer                             texto
observacoes_gerais            compl/xObs                                  texto
qrcode                        parent::GTVe/infCTeSupl/qrCodCTe            texto
")

# No toma da GTV-e o tomador é o remetente (papel 0) ou o destinatário (papel 1): o 1 não é o expedidor, como no CT-e.
PESSOA_DE_CADA_PAPEL_NA_GTVE = c("remetente", "destinatario")

# O nome do CFOP, ao lado dele, como a tabela fiscal registrava na data de emissão da GTV-e.
DESCRICOES_DA_GTVE = ler_campos("
coluna_do_codigo coluna_nova tabela texto
cfop             cfop_titulo cfop   titulo
")

# O que quer dizer cada código, ao lado dele, pela documentação do tipo TGTVe do schema (os textos estão em
# tabela_fiscal("codigos_dos_campos"), documento "GTV-e").
SIGNIFICADOS_DA_GTVE = ler_campos("
coluna_do_codigo     campo     coluna_do_contexto
modelo               mod       -
tipo_cte             tpCTe     -
tipo_servico         tpServ    -
modal                modal     -
formato_dacte        tpImp     -
forma_emissao        tpEmis    -
ambiente             tpAmb     -
tomador_papel        toma      -
tomador_indicador_ie indIEToma -
")

# A partir de cada infEspecie (detGTV/infEspecie): o valor levado de cada espécie.
CAMPOS_DA_ESPECIE = ler_campos("
coluna            caminho      tipo
tipo              tpEspecie    inteiro
valor             vEspecie     numero
numerario         tpNumerario  inteiro
moeda_estrangeira xMoedaEstr   texto
")

SIGNIFICADOS_DA_ESPECIE = ler_campos("
coluna_do_codigo campo       coluna_do_contexto
tipo             tpEspecie   -
numerario        tpNumerario -
")

# A partir de cada infVeiculo (detGTV/infVeiculo).
CAMPOS_DO_VEICULO_DA_GTVE = ler_campos("
coluna caminho tipo
placa  placa   texto
uf     UF      texto
rntrc  RNTRC   texto
")

#' Ler o XML da GTV-e
#'
#' Lê o XML da GTV-e (Guia de Transporte de Valores Eletrônica, modelo 64) e
#' devolve uma lista de tabelas (`data.frame`s) ligadas pela `chave`: `gtves`
#' (uma linha por GTV-e: as pessoas, o tomador já resolvido, a origem e o
#' destino, os horários de saída e de chegada, a quantidade de malotes e o
#' protocolo), `especies` (o valor levado de cada espécie: cédula, cheque,
#' moeda...), `veiculos`, `observacoes`, `campos` (todos os campos, só com
#' `todos_os_campos = TRUE`) e `arquivos` (o que foi lido e o motivo do que não
#' deu).
#'
#' A GTV-e é um CT-e do tipo 4: tem a chave e o protocolo do CT-e, e os
#' eventos dela (o cancelamento, por exemplo) são os do CT-e, lidos por
#' [eventos_ler()]. Mas não tem valor da prestação nem impostos: no lugar deles
#' traz os valores levados. Por isso tem leitor próprio, e não entra em
#' [cte_ler()]. Lê o leiaute 4.00, com ou sem o protocolo de autorização
#' (`GTVeProc` ou só `GTVe`), de um arquivo, de vários de uma vez ou do próprio
#' texto do XML. Um arquivo que não dá para ler não interrompe os outros: fica
#' em `arquivos`, com o motivo.
#'
#' Cada coluna vem de um campo do leiaute (entre parênteses abaixo). Os
#' códigos ficam como estão no XML, e ao lado de cada um vem o que ele quer
#' dizer: o nome do CFOP, pela tabela fiscal na data da GTV-e, e o significado
#' dos outros códigos (tipo, modal, forma de emissão, papel do tomador, espécie,
#' numerário...) numa coluna `*_descricao`, pela documentação do schema oficial
#' (veja `tabela_fiscal("codigos_dos_campos")`, documento `"GTV-e"`). Campo que
#' a GTV-e não tem fica `NA`.
#'
#' @section gtves:
#' Uma linha por GTV-e: `chave`, `versao`,
#' `r documentar_campos(CAMPOS_DA_GTVE)`;
#' do protocolo de autorização, quando vem junto:
#' `r documentar_campos(CAMPOS_DO_PROTOCOLO)`;
#' e `arquivo`. `emissao`, `saida_origem`, `chegada_destino`,
#' `contingencia_entrada` e `autorizacao` são data e hora (mostradas no horário
#' de Brasília); `data_emissao` é a data como está na GTV-e.
#'
#' As colunas `tomador_` trazem o tomador do serviço. Com o grupo `toma`
#' (`tomador_papel` 0 ou 1), ele é o remetente ou o destinatário, e os dados
#' são os dessa pessoa; com `tomaTerceiro` (`tomador_papel` 4), os dados vêm
#' do próprio grupo.
#'
#' @section especies:
#' O valor levado de cada espécie, um por linha: `chave`,
#' `r documentar_campos(CAMPOS_DA_ESPECIE)`. O significado do `tipo` (cédula,
#' cheque, moeda ou outros) e do `numerario` (nacional ou estrangeiro) vem ao
#' lado, em `*_descricao`; `moeda_estrangeira` é o nome da moeda do numerário
#' estrangeiro. A GTV-e não tem um valor total: some o `valor` das espécies
#' de cada `chave`.
#'
#' @section veiculos e observacoes:
#' `veiculos`, um por linha: `chave`,
#' `r documentar_campos(CAMPOS_DO_VEICULO_DA_GTVE)`.
#' `observacoes`, uma linha por campo de uso livre (`ObsCont` e `ObsFisco`):
#' `chave`, `r documentar_campos(CAMPOS_DA_OBSERVACAO)`.
#'
#' @section campos:
#' Só com `todos_os_campos = TRUE`. Todos os campos da GTV-e, um por linha:
#' `chave`, `caminho` (onde o campo está, a partir do `infCte`, com a posição
#' quando o grupo se repete, por exemplo `detGTV/infEspecie[2]/vEspecie`),
#' `grupo` (o grupo logo acima do campo), `campo` (o nome no leiaute) e `valor`
#' (o texto do XML). É onde ficam os endereços completos, os autorizados a
#' baixar o XML e o responsável técnico.
#'
#' @section arquivos:
#' Uma linha por arquivo pedido: `arquivo`, `gtves` (quantas GTV-e tinha) e
#' `problema` (`NA` quando deu certo). Um texto de XML aparece como
#' `"(texto 1)"`, `"(texto 2)"`...
#'
#' @param arquivos Os XMLs a ler: o caminho de um arquivo, um vetor com vários
#'   (por exemplo, `list.files("pasta", pattern = "xml$", full.names = TRUE)`)
#'   ou o próprio texto do XML (começando por `<`).
#' @param todos_os_campos `TRUE` devolve também a tabela `campos`, com todos os
#'   campos de cada GTV-e.
#' @return Uma lista com os `data.frame`s `gtves`, `especies`, `veiculos`,
#'   `observacoes`, `campos` (só com `todos_os_campos = TRUE`) e `arquivos`.
#' @source Schema oficial do CT-e, pacote de liberação PL_CTe_400 NT 2026.005
#'   RTC SN 1.00 (tipo `TGTVe`, `GTVe_v4.00.xsd` e `procGTVe_v4.00.xsd`),
#'   publicado no Portal Nacional do CT-e em 04/11/2026, e o Manual de
#'   Orientação do Contribuinte do CT-e, versão 4.00 (fevereiro/2023), item
#'   2.1.2.
#' @examples
#' gtve = system.file("exemplos", "gtve_proc_sp.xml", package = "RNFe")
#' lida = gtve_ler(gtve)
#' lida$gtves[, c("chave", "remetente_nome", "destinatario_nome", "quantidade_volumes")]
#' lida$especies[, c("tipo_descricao", "valor", "numerario_descricao", "moeda_estrangeira")]
#' @export
gtve_ler = function(arquivos, todos_os_campos = FALSE) {
  arquivos_lidos = ler_arquivos_xml(arquivos, CAMINHO_DAS_GTVES, "uma GTV-e", colunas_da_gtve, todos_os_campos)
  colunas_vazias = colunas_da_gtve(NULL, NA_character_, todos_os_campos)

  tabelas_da_gtve = list(
    gtves = juntar_tabela(arquivos_lidos, "gtves", colunas_vazias$gtves),
    especies = juntar_tabela(arquivos_lidos, "especies", colunas_vazias$especies),
    veiculos = juntar_tabela(arquivos_lidos, "veiculos", colunas_vazias$veiculos),
    observacoes = juntar_tabela(arquivos_lidos, "observacoes", colunas_vazias$observacoes)
  )
  if (todos_os_campos) {
    tabelas_da_gtve$campos = juntar_tabela(arquivos_lidos, "campos", colunas_vazias$campos)
  }
  tabelas_da_gtve$arquivos = resumo_dos_arquivos(arquivos_lidos, "gtves", "gtves")
  tabelas_da_gtve$gtves = converter_datas(tabelas_da_gtve$gtves, rbind(CAMPOS_DA_GTVE, CAMPOS_DO_PROTOCOLO))
  tabelas_da_gtve$gtves = preencher_tomador(tabelas_da_gtve$gtves, PESSOA_DE_CADA_PAPEL_NA_GTVE)
  tabelas_da_gtve$gtves = acrescentar_descricoes(tabelas_da_gtve$gtves, tabelas_da_gtve$gtves$data_emissao, DESCRICOES_DA_GTVE)
  tabelas_da_gtve$gtves = acrescentar_significados(tabelas_da_gtve$gtves, "GTV-e", SIGNIFICADOS_DA_GTVE)
  tabelas_da_gtve$especies = acrescentar_significados(tabelas_da_gtve$especies, "GTV-e", SIGNIFICADOS_DA_ESPECIE)
  tabelas_da_gtve
}

# As colunas das tabelas de um arquivo de GTV-e, cada uma num vetor. Com xml_lido NULL, vêm vazias, já com os nomes e
# os tipos certos.
colunas_da_gtve = function(xml_lido, nome_do_arquivo, todos_os_campos) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  gtves = buscar_todos(xml_lido, CAMINHO_DAS_GTVES)
  protocolos = buscar_todos(xml_lido, "//protCTe/infProt")
  especies = buscar_todos(gtves, "detGTV/infEspecie")
  veiculos = buscar_todos(gtves, "detGTV/infVeiculo")
  observacoes = buscar_todos(gtves, "compl/ObsCont|compl/ObsFisco")

  chaves = chave_de_cada(gtves, "infCte")
  # O protocolo é casado com a GTV-e pela chave; GTV-e que veio sem protocolo fica com NA.
  protocolo_de_cada_gtve = match(chaves, texto_de_cada(protocolos, "chCTe"))

  colunas_das_tabelas = list(
    gtves = c(
      list(chave = chaves, versao = xml2::xml_attr(gtves, "versao")),
      valores_dos_campos(gtves, CAMPOS_DA_GTVE),
      valores_dos_campos(protocolos, CAMPOS_DO_PROTOCOLO, protocolo_de_cada_gtve),
      list(arquivo = rep(nome_do_arquivo, length(gtves)))
    ),
    especies = c(list(chave = chave_de_cada(especies, "infCte")), valores_dos_campos(especies, CAMPOS_DA_ESPECIE)),
    veiculos = c(list(chave = chave_de_cada(veiculos, "infCte")), valores_dos_campos(veiculos, CAMPOS_DO_VEICULO_DA_GTVE)),
    observacoes = c(list(chave = chave_de_cada(observacoes, "infCte")), valores_dos_campos(observacoes, CAMPOS_DA_OBSERVACAO))
  )
  if (todos_os_campos) {
    colunas_das_tabelas$campos = colunas_de_todos_os_campos(buscar_todos_os_campos(gtves), "infCte")
  }
  colunas_das_tabelas
}
