# Leitura do XML do MDF-e (modelo 58, leiaute 3.00) em tabelas. Os caminhos seguem o schema oficial do
# Portal do MDF-e (pacote PL_MDFe_300b da NT 2025.001 v1.04, de 25/04/2026).

#' @include ler_xml.R
NULL

CAMINHO_DOS_MDFES = "//MDFe/infMDFe"

# Coluna, caminho a partir do infMDFe e tipo. "a|b" pega o que existir (o leiaute deixa um ou outro).
CAMPOS_DO_MDFE = ler_campos("
coluna                       caminho                            tipo
modelo                       ide/mod                            texto
serie                        ide/serie                          inteiro
numero                       ide/nMDF                           inteiro
emissao                      ide/dhEmi                          data_hora
data_emissao                 ide/dhEmi                          data
tipo_emitente                ide/tpEmit                         inteiro
tipo_transportador           ide/tpTransp                       inteiro
modal                        ide/modal                          texto
forma_emissao                ide/tpEmis                         inteiro
ambiente                     ide/tpAmb                          inteiro
processo_emissao             ide/procEmi                        inteiro
inicio_uf                    ide/UFIni                          texto
fim_uf                       ide/UFFim                          texto
inicio_viagem                ide/dhIniViagem                    data_hora
canal_verde                  ide/indCanalVerde                  inteiro
carregamento_posterior       ide/indCarregaPosterior            inteiro
emitente_documento           emit/CNPJ|emit/CPF                 texto
emitente_nome                emit/xNome                         texto
emitente_fantasia            emit/xFant                         texto
emitente_ie                  emit/IE                            texto
emitente_municipio           emit/enderEmit/xMun                texto
emitente_codigo_municipio    emit/enderEmit/cMun                texto
emitente_uf                  emit/enderEmit/UF                  texto
versao_modal                 infModal/@versaoModal              texto
rntrc                        infModal/rodo/infANTT/RNTRC        texto
placa                        infModal/rodo/veicTracao/placa     texto
quantidade_cte               tot/qCTe                           inteiro
quantidade_nfe               tot/qNFe                           inteiro
quantidade_mdfe              tot/qMDFe                          inteiro
valor_carga                  tot/vCarga                         numero
unidade_peso                 tot/cUnid                          texto
peso_bruto                   tot/qCarga                         numero
tipo_carga                   prodPred/tpCarga                   texto
produto_predominante         prodPred/xProd                     texto
produto_gtin                 prodPred/cEAN                      texto
produto_ncm                  prodPred/NCM                       texto
informacoes_fisco            infAdic/infAdFisco                 texto
informacoes_complementares   infAdic/infCpl                     texto
")

# O nome do NCM do produto predominante, como a tabela registrava na data de emissão do MDF-e.
DESCRICOES_DO_MDFE = ler_campos("
coluna_do_codigo coluna_nova            tabela texto
produto_ncm      produto_ncm_descricao  ncm    descricao_completa
")

# O que quer dizer cada código, ao lado dele: a coluna, o campo do leiaute e a coluna de que o significado depende
# ("-" quando não depende). Os textos estão em tabela_fiscal("codigos_dos_campos").
SIGNIFICADOS_DO_MDFE = ler_campos("
coluna_do_codigo        campo               coluna_do_contexto
modelo                  mod                 -
tipo_emitente           tpEmit              -
tipo_transportador      tpTransp            -
modal                   modal               -
forma_emissao           tpEmis              -
ambiente                tpAmb               -
processo_emissao        procEmi             -
canal_verde             indCanalVerde       -
carregamento_posterior  indCarregaPosterior -
unidade_peso            cUnid               -
tipo_carga              tpCarga             -
")

SIGNIFICADOS_DO_DOCUMENTO_DO_MDFE = ler_campos("
coluna_do_codigo   campo               coluna_do_contexto
reentrega          indReentrega        -
prestacao_parcial  indPrestacaoParcial -
")

SIGNIFICADOS_DO_VEICULO = ler_campos("
coluna_do_codigo   campo  coluna_do_contexto
tipo_rodado        tpRod  -
tipo_carroceria    tpCar  -
proprietario_tipo  tpProp -
")

SIGNIFICADOS_DO_SEGURO = ler_campos("
coluna_do_codigo campo   coluna_do_contexto
responsavel      respSeg -
")

# Os municípios de carregamento, as UFs do percurso e os municípios de descarregamento, nessa ordem.
CAMINHO_DOS_LOCAIS = "ide/infMunCarrega|ide/infPercurso|infDoc/infMunDescarga"

CAMPOS_DO_LOCAL = ler_campos("
coluna            caminho                    tipo
tipo              self::*                    elemento
codigo_municipio  cMunCarrega|cMunDescarga   texto
municipio         xMunCarrega|xMunDescarga   texto
uf                UFPer                      texto
")

# Os documentos de cada município de descarregamento: CT-e, NF-e e, no aquaviário, outros MDF-e.
CAMINHO_DOS_DOCUMENTOS_DO_MDFE = "infDoc/infMunDescarga/infCTe|infDoc/infMunDescarga/infNFe|infDoc/infMunDescarga/infMDFeTransp"

CAMPOS_DO_DOCUMENTO_DO_MDFE = ler_campos("
coluna                     caminho                               tipo
tipo                       self::*                               elemento
documento_chave            chCTe|chNFe|chMDFe                    texto
descarga_codigo_municipio  parent::infMunDescarga/cMunDescarga   texto
descarga_municipio         parent::infMunDescarga/xMunDescarga   texto
reentrega                  indReentrega                          inteiro
segundo_codigo_barras      SegCodBarra                           texto
prestacao_parcial          indPrestacaoParcial                   inteiro
")

# O veículo com a tração e os reboques, do modal rodoviário.
CAMINHO_DOS_VEICULOS = "infModal/rodo/veicTracao|infModal/rodo/veicReboque"

CAMPOS_DO_VEICULO = ler_campos("
coluna                  caminho              tipo
tipo                    self::*              elemento
codigo_interno          cInt                 texto
placa                   placa                texto
renavam                 RENAVAM              texto
tara                    tara                 inteiro
capacidade_kg           capKG                inteiro
capacidade_m3           capM3                inteiro
tipo_rodado             tpRod                texto
tipo_carroceria         tpCar                texto
uf                      UF                   texto
proprietario_documento  prop/CPF|prop/CNPJ   texto
proprietario_nome       prop/xNome           texto
proprietario_rntrc      prop/RNTRC           texto
proprietario_ie         prop/IE              texto
proprietario_uf         prop/UF              texto
proprietario_tipo       prop/tpProp          inteiro
")

CAMPOS_DO_CONDUTOR = ler_campos("
coluna caminho tipo
nome   xNome   texto
cpf    CPF     texto
")

# Uma linha por averbação; o seguro sem averbação também tem a sua linha. Os outros campos vêm do seguro
# (seg) de onde a averbação é.
CAMINHO_DOS_SEGUROS = "seg/nAver|seg[not(nAver)]"

CAMPOS_DO_SEGURO = ler_campos("
coluna                 caminho                                                                tipo
responsavel            ancestor-or-self::seg/infResp/respSeg                                  inteiro
responsavel_documento  ancestor-or-self::seg/infResp/CNPJ|ancestor-or-self::seg/infResp/CPF   texto
seguradora_nome        ancestor-or-self::seg/infSeg/xSeg                                      texto
seguradora_cnpj        ancestor-or-self::seg/infSeg/CNPJ                                      texto
apolice                ancestor-or-self::seg/nApol                                            texto
averbacao              self::nAver                                                            texto
")

#' Ler o XML de MDF-e
#'
#' Lê o XML de MDF-e e devolve uma lista de tabelas (`data.frame`s) ligadas
#' pela `chave`: `mdfes` (uma linha por MDF-e: emitente, modal, UFs de início e
#' fim, placa, totais da carga e protocolo), `locais` (municípios de
#' carregamento, UFs do percurso e municípios de descarregamento), `documentos`
#' (os CT-e e as NF-e de cada descarregamento), `veiculos`, `condutores`,
#' `seguros`, `campos` (todos os campos, um por linha: CIOT, vale-pedágio,
#' pagamento do frete...) e `arquivos` (o que foi lido e o motivo do que não
#' deu).
#'
#' Lê o modelo 58, leiaute 3.00, com ou sem o protocolo de autorização
#' (`mdfeProc` ou só `MDFe`), de um arquivo, de vários de uma vez ou do próprio
#' texto do XML. Um arquivo que não dá para ler não interrompe os outros: fica
#' em `arquivos`, com o motivo. Para saber se o MDF-e foi encerrado ou
#' cancelado, leia os eventos dele com [eventos_ler()].
#'
#' Cada coluna vem de um campo do leiaute (entre parênteses abaixo). Os
#' códigos (modal, tipo de emitente, tipo de carga, rodado, carroceria...)
#' ficam como estão no XML, e ao lado de cada um vem o que ele quer dizer, numa
#' coluna `*_descricao`, pela documentação do schema oficial (veja
#' `tabela_fiscal("codigos_dos_campos")`). Campo que o MDF-e não tem fica `NA`. Nenhum campo se perde: o que
#' não tem coluna própria está na tabela `campos`.
#'
#' @section mdfes:
#' Uma linha por MDF-e: `chave`, `versao`,
#' `r documentar_campos(CAMPOS_DO_MDFE)`;
#' do protocolo de autorização, quando vem junto:
#' `r documentar_campos(CAMPOS_DO_PROTOCOLO)`;
#' e `arquivo`. `emissao`, `inicio_viagem` e `autorizacao` são data e hora
#' (mostradas no horário de Brasília); `data_emissao` é a data como está no
#' MDF-e. Ao lado do NCM do produto predominante vem a descrição dele, como a
#' tabela registrava na data de emissão (`produto_ncm_descricao`, veja
#' [tabela_fiscal()]).
#'
#' @section locais:
#' Os lugares da viagem, na ordem do XML: `chave`,
#' `r documentar_campos(CAMPOS_DO_LOCAL)`. `tipo` é o grupo de onde o lugar
#' veio: `infMunCarrega` (município de carregamento), `infPercurso` (UF por
#' onde o veículo passa, só a UF) e `infMunDescarga` (município de
#' descarregamento).
#'
#' @section documentos:
#' Os documentos que o MDF-e acoberta, um por linha, com o município onde são
#' descarregados: `chave`, `r documentar_campos(CAMPOS_DO_DOCUMENTO_DO_MDFE)`.
#' `tipo` é `infCTe`, `infNFe` ou `infMDFeTransp` (MDF-e transportado, só no
#' modal aquaviário).
#'
#' @section veiculos e condutores:
#' `veiculos`, do modal rodoviário, um por linha: `chave`,
#' `r documentar_campos(CAMPOS_DO_VEICULO)`. `tipo` é `veicTracao` (o veículo
#' com a tração) ou `veicReboque`; o proprietário só vem quando o veículo não é
#' do emitente.
#' `condutores`, um por linha: `chave`, `r documentar_campos(CAMPOS_DO_CONDUTOR)`.
#'
#' @section seguros:
#' Uma linha por averbação, e uma para o seguro que não tem averbação: `chave`,
#' `r documentar_campos(CAMPOS_DO_SEGURO)`. Os caminhos partem da averbação
#' (`nAver`) ou do seguro (`seg`).
#'
#' @section campos:
#' Com `todos_os_campos = TRUE`, o padrão. Todos os campos do MDF-e, um por
#' linha: `chave`, `caminho` (onde o campo
#' está, a partir do `infMDFe`, com a posição quando o grupo se repete, por
#' exemplo `infModal/rodo/veicTracao/condutor[2]/CPF`), `grupo` (o grupo logo
#' acima do campo), `campo` (o nome no leiaute) e `valor` (o texto do XML). É
#' onde ficam o que não tem coluna própria, como o CIOT, o vale-pedágio, os
#' contratantes, o pagamento do frete, os lacres e os modais aéreo,
#' aquaviário e ferroviário.
#'
#' @section arquivos:
#' Uma linha por arquivo pedido: `arquivo`, `mdfes` (quantos MDF-e tinha) e
#' `problema` (`NA` quando deu certo). Um texto de XML aparece como
#' `"(texto 1)"`, `"(texto 2)"`...
#'
#' @param arquivos Os XMLs a ler: o caminho de um arquivo, um vetor com vários
#'   (por exemplo, `list.files("pasta", pattern = "xml$", full.names = TRUE)`)
#'   ou o próprio texto do XML (começando por `<`).
#' @param todos_os_campos `FALSE` deixa de fora a tabela `campos`. O padrão é
#'   `TRUE` porque boa parte do MDF-e não tem coluna própria, e um MDF-e tem
#'   poucos campos.
#' @return Uma lista com os `data.frame`s `mdfes`, `locais`, `documentos`,
#'   `veiculos`, `condutores`, `seguros`, `campos` (só com
#'   `todos_os_campos = TRUE`) e `arquivos`.
#' @source Schema oficial do MDF-e, pacote PL_MDFe_300b da NT 2025.001 v1.04,
#'   publicado no Portal Nacional do MDF-e em 25/04/2026.
#' @examples
#' mdfe = system.file("exemplos", "mdfe_proc_sp.xml", package = "RNFe")
#' lido = mdfe_ler(mdfe)
#' lido$mdfes[, c("chave", "emitente_nome", "placa", "valor_carga", "protocolo")]
#' lido$documentos[, c("tipo", "documento_chave", "descarga_municipio")]
#' @export
mdfe_ler = function(arquivos, todos_os_campos = TRUE) {
  arquivos_lidos = ler_arquivos_xml(arquivos, CAMINHO_DOS_MDFES, "um MDF-e", colunas_do_mdfe, todos_os_campos)
  colunas_vazias = colunas_do_mdfe(NULL, NA_character_, todos_os_campos)

  tabelas_do_mdfe = list(
    mdfes = juntar_tabela(arquivos_lidos, "mdfes", colunas_vazias$mdfes),
    locais = juntar_tabela(arquivos_lidos, "locais", colunas_vazias$locais),
    documentos = juntar_tabela(arquivos_lidos, "documentos", colunas_vazias$documentos),
    veiculos = juntar_tabela(arquivos_lidos, "veiculos", colunas_vazias$veiculos),
    condutores = juntar_tabela(arquivos_lidos, "condutores", colunas_vazias$condutores),
    seguros = juntar_tabela(arquivos_lidos, "seguros", colunas_vazias$seguros)
  )
  if (todos_os_campos) {
    tabelas_do_mdfe$campos = juntar_tabela(arquivos_lidos, "campos", colunas_vazias$campos)
  }
  tabelas_do_mdfe$arquivos = resumo_dos_arquivos(arquivos_lidos, "mdfes", "mdfes")
  tabelas_do_mdfe$mdfes = converter_datas(tabelas_do_mdfe$mdfes, rbind(CAMPOS_DO_MDFE, CAMPOS_DO_PROTOCOLO))
  tabelas_do_mdfe$mdfes = acrescentar_descricoes(tabelas_do_mdfe$mdfes, tabelas_do_mdfe$mdfes$data_emissao, DESCRICOES_DO_MDFE)
  tabelas_do_mdfe$mdfes = acrescentar_significados(tabelas_do_mdfe$mdfes, "MDF-e", SIGNIFICADOS_DO_MDFE)
  tabelas_do_mdfe$documentos = acrescentar_significados(tabelas_do_mdfe$documentos, "MDF-e", SIGNIFICADOS_DO_DOCUMENTO_DO_MDFE)
  tabelas_do_mdfe$veiculos = acrescentar_significados(tabelas_do_mdfe$veiculos, "MDF-e", SIGNIFICADOS_DO_VEICULO)
  tabelas_do_mdfe$seguros = acrescentar_significados(tabelas_do_mdfe$seguros, "MDF-e", SIGNIFICADOS_DO_SEGURO)
  tabelas_do_mdfe
}

# As colunas das tabelas de um arquivo de MDF-e, cada uma num vetor. Com xml_lido NULL, vêm vazias, já com
# os nomes e os tipos certos.
colunas_do_mdfe = function(xml_lido, nome_do_arquivo, todos_os_campos) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  mdfes = buscar_todos(xml_lido, CAMINHO_DOS_MDFES)
  protocolos = buscar_todos(xml_lido, "//protMDFe/infProt")
  locais = buscar_todos(mdfes, CAMINHO_DOS_LOCAIS)
  documentos = buscar_todos(mdfes, CAMINHO_DOS_DOCUMENTOS_DO_MDFE)
  veiculos = buscar_todos(mdfes, CAMINHO_DOS_VEICULOS)
  condutores = buscar_todos(mdfes, "infModal/rodo/veicTracao/condutor")
  seguros = buscar_todos(mdfes, CAMINHO_DOS_SEGUROS)

  chaves = chave_de_cada(mdfes, "infMDFe")
  # O protocolo é casado com o MDF-e pela chave; MDF-e que veio sem protocolo fica com NA.
  protocolo_de_cada_mdfe = match(chaves, texto_de_cada(protocolos, "chMDFe"))

  colunas_das_tabelas = list(
    mdfes = c(
      list(chave = chaves, versao = xml2::xml_attr(mdfes, "versao")),
      valores_dos_campos(mdfes, CAMPOS_DO_MDFE),
      valores_dos_campos(protocolos, CAMPOS_DO_PROTOCOLO, protocolo_de_cada_mdfe),
      list(arquivo = rep(nome_do_arquivo, length(mdfes)))
    ),
    locais = c(list(chave = chave_de_cada(locais, "infMDFe")), valores_dos_campos(locais, CAMPOS_DO_LOCAL)),
    documentos = c(list(chave = chave_de_cada(documentos, "infMDFe")), valores_dos_campos(documentos, CAMPOS_DO_DOCUMENTO_DO_MDFE)),
    veiculos = c(list(chave = chave_de_cada(veiculos, "infMDFe")), valores_dos_campos(veiculos, CAMPOS_DO_VEICULO)),
    condutores = c(list(chave = chave_de_cada(condutores, "infMDFe")), valores_dos_campos(condutores, CAMPOS_DO_CONDUTOR)),
    seguros = c(list(chave = chave_de_cada(seguros, "infMDFe")), valores_dos_campos(seguros, CAMPOS_DO_SEGURO))
  )
  if (todos_os_campos) {
    colunas_das_tabelas$campos = colunas_de_todos_os_campos(buscar_todos_os_campos(mdfes), "infMDFe")
  }
  colunas_das_tabelas
}
