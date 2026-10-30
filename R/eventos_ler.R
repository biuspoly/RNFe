# Leitura do XML dos eventos (cancelamento, carta de correção, manifestação, encerramento...) da NF-e, da NFC-e,
# do CT-e, do MDF-e e da NFS-e Nacional numa tabela só. Os caminhos seguem os schemas oficiais: o leiaute
# genérico de eventos da NF-e (PL_Evento do pacote 010d, NT 2026.004), o resumo de evento da Distribuição de
# DF-e (v1.04) e os pacotes que os leitores do CT-e, do MDF-e e da NFS-e já seguem.

#' @include ler_xml.R
NULL

# O pedido de cada evento, pelo infEvento: o da NF-e (e da NFC-e), o do CT-e e o do MDF-e. A NFS-e também chama
# o seu de evento, mas por dentro é outro: tem o pedRegEvento no lugar da chave.
CAMINHO_DOS_PEDIDOS_DE_EVENTO = "//evento/infEvento[chNFe]|//eventoCTe/infEvento|//eventoMDFe/infEvento"
CAMINHO_DOS_RETORNOS_DE_EVENTO = "//retEvento/infEvento|//retEventoCTe/infEvento|//retEventoMDFe/infEvento"
CAMINHO_DOS_EVENTOS_DA_NFSE = "//evento/infEvento[pedRegEvento]"
CAMINHO_DOS_RESUMOS_DE_EVENTO = "//resEvento"
CAMINHO_DOS_EVENTOS = paste(CAMINHO_DOS_PEDIDOS_DE_EVENTO, CAMINHO_DOS_EVENTOS_DA_NFSE, CAMINHO_DOS_RESUMOS_DE_EVENTO, sep = "|")

# A partir do infEvento do pedido. No CT-e e no MDF-e o detalhe fica num grupo de cada evento (evCancCTe,
# evEncMDFe...); na NF-e, direto no detEvento: "a|b" pega o que existir.
CAMPOS_DO_PEDIDO_DE_EVENTO = ler_campos("
coluna               caminho                                       tipo
chave                chNFe|chCTe|chMDFe                            texto
tipo                 tpEvento                                      texto
descricao            detEvento/descEvento|detEvento/*/descEvento   texto
sequencia            nSeqEvento                                    inteiro
data_evento          dhEvento                                      data_hora
autor_documento      CNPJ|CPF                                      texto
orgao                cOrgao                                        texto
ambiente             tpAmb                                         inteiro
justificativa        detEvento/xJust|detEvento/*/xJust             texto
correcao             detEvento/xCorrecao                           texto
observacao           detEvento/xObs|detEvento/*/xObs               texto
protocolo_documento  detEvento/nProt|detEvento/*/nProt             texto
versao               parent::*/@versao                             texto
")

# A partir do infEvento do retorno da SEFAZ (retEvento, retEventoCTe, retEventoMDFe).
CAMPOS_DO_RETORNO_DE_EVENTO = ler_campos("
coluna     caminho      tipo
situacao   cStat        inteiro
motivo     xMotivo      texto
descricao  xEvento      texto
protocolo  nProt        texto
registro   dhRegEvento  data_hora
")

# A partir do infEvento da NFS-e, que traz o pedido (pedRegEvento) dentro dele. O tipo do evento é o nome do
# grupo que tem a descrição (e101101 é o cancelamento): nem sempre ele vem logo depois da chave, porque a NFS-e
# 1.00 de substituição traz o nPedRegEvento entre os dois.
CAMPOS_DO_EVENTO_DA_NFSE = ler_campos("
coluna           caminho                                                        tipo
chave            pedRegEvento/infPedReg/chNFSe                                  texto
tipo             pedRegEvento/infPedReg/*/xDesc/parent::*                       elemento
descricao        pedRegEvento/infPedReg/*/xDesc                                 texto
sequencia        nSeqEvento                                                     inteiro
data_evento      pedRegEvento/infPedReg/dhEvento                                data_hora
autor_documento  pedRegEvento/infPedReg/CNPJAutor|pedRegEvento/infPedReg/CPFAutor texto
ambiente         pedRegEvento/infPedReg/tpAmb                                   inteiro
justificativa    pedRegEvento/infPedReg/*/xMotivo                               texto
registro         dhProc                                                         data_hora
versao           parent::*/@versao                                              texto
")

# O resumo de evento que a Distribuição de DF-e entrega (resEvento): sem o detalhe nem o retorno.
CAMPOS_DO_RESUMO_DE_EVENTO = ler_campos("
coluna           caminho     tipo
chave            chNFe       texto
tipo             tpEvento    texto
descricao        xEvento     texto
sequencia        nSeqEvento  inteiro
data_evento      dhEvento    data_hora
autor_documento  CNPJ|CPF    texto
orgao            cOrgao      texto
protocolo        nProt       texto
registro         dhRecbto    data_hora
versao           @versao     texto
")

SIGNIFICADOS_DOS_EVENTOS = ler_campos("
coluna_do_codigo campo coluna_do_contexto
ambiente         tpAmb -
")

CAMPOS_DE_DATA_DOS_EVENTOS = ler_campos("
coluna       tipo
data_evento  data_hora
registro     data_hora
")

# As colunas da tabela eventos, na ordem, com o tipo de cada uma (as datas ainda como texto).
COLUNAS_DOS_EVENTOS = list(
  documento = character(), chave = character(), tipo = character(), descricao = character(), sequencia = integer(),
  data_evento = character(), autor_documento = character(), orgao = character(), ambiente = integer(),
  justificativa = character(), correcao = character(), observacao = character(), protocolo_documento = character(),
  situacao = integer(),
  motivo = character(), protocolo = character(), registro = character(), resumo = logical(), versao = character(),
  arquivo = character()
)

FAMILIA_PELA_CHAVE = c(chNFe = "NF-e", chCTe = "CT-e", chMDFe = "MDF-e")

#' Ler o XML de eventos
#'
#' Lê o XML dos eventos (cancelamento, carta de correção, manifestação do
#' destinatário, encerramento, os que o Fisco registra...) da NF-e, da NFC-e, do
#' CT-e, do MDF-e e da NFS-e Nacional e devolve uma lista de tabelas
#' (`data.frame`s): `eventos` (uma linha por evento: o documento e a `chave`
#' dele, o tipo do evento, a descrição, a data, o autor, a justificativa, a
#' correção e o retorno da SEFAZ), `campos` (todos os campos de cada evento, um
#' por linha) e `arquivos` (o que foi lido e o motivo do que não deu). Junte
#' com as tabelas dos documentos pela `chave` para saber, por exemplo, quais
#' notas foram canceladas (tipo `110111`).
#'
#' Lê o evento com o retorno da SEFAZ (`procEventoNFe`, `procEventoCTe`,
#' `procEventoMDFe`), o evento só assinado, o evento da NFS-e como o sistema
#' nacional o registra e o resumo de evento que a Distribuição de DF-e entrega
#' (`resEvento`), de um arquivo, de vários de uma vez ou do próprio texto do
#' XML. Um arquivo que não dá para ler não interrompe os outros: fica em
#' `arquivos`, com o motivo.
#'
#' Um documento cancelado continua com a situação de autorizado no protocolo
#' dele, porque o cancelamento é um evento à parte. Para saber quais foram
#' cancelados, junte esta leitura com a dos documentos pela chave (veja os
#' exemplos).
#'
#' @section eventos:
#' Uma linha por evento: `documento` (`"NF-e"`, `"NFC-e"`, `"CT-e"`,
#' `"CT-e OS"`, `"MDF-e"` ou `"NFS-e"`, pelo modelo da chave), `chave` (a do
#' documento do evento), `tipo` (o código do evento, como `110111`, o
#' cancelamento), `descricao`, `sequencia`, `data_evento`, `autor_documento`
#' (CNPJ ou CPF de quem registrou), `orgao`, `ambiente`, `justificativa`,
#' `correcao` (o texto da carta de correção da NF-e), `observacao` (como o
#' motivo da prestação em desacordo do CT-e), `protocolo_documento` (o
#' protocolo do documento citado no cancelamento e no encerramento),
#' `situacao`, `motivo`, `protocolo` e `registro` (do retorno), `resumo`
#' (`TRUE` no resumo de evento, que não traz o detalhe), `versao` e `arquivo`.
#'
#' De onde vem cada coluna:
#' - no evento da NF-e, do CT-e e do MDF-e, do pedido (a partir do `infEvento`):
#'   `r documentar_campos(CAMPOS_DO_PEDIDO_DE_EVENTO)`; e do retorno da SEFAZ,
#'   quando vem junto: `r documentar_campos(CAMPOS_DO_RETORNO_DE_EVENTO)`. A
#'   descrição é a do pedido e, sem ela, a do retorno. O retorno é o que está no
#'   mesmo envelope que o pedido;
#' - no evento da NFS-e (a partir do `infEvento`):
#'   `r documentar_campos(CAMPOS_DO_EVENTO_DA_NFSE)`. O tipo é o nome do grupo
#'   do evento sem o `e` (`e101101` dá `101101`), e a justificativa é o motivo
#'   que o autor escreveu;
#' - no resumo de evento: `r documentar_campos(CAMPOS_DO_RESUMO_DE_EVENTO)`.
#'
#' `data_evento` e `registro` são data e hora (mostradas no horário de
#' Brasília). Códigos e textos ficam como estão no XML (as descrições da SEFAZ
#' vêm sem acento). O nome do tipo do evento é a `descricao` que o próprio
#' evento traz, e o `ambiente` vem com o significado ao lado
#' (`ambiente_descricao`).
#'
#' @section campos:
#' Com `todos_os_campos = TRUE`, o padrão. Todos os campos de cada evento,
#' menos os da assinatura digital, um por linha: `chave`, `tipo` e `sequencia`
#' (que identificam o evento), `caminho` (onde o campo está, a partir do
#' evento, do retorno ou do resumo, por exemplo
#' `evento/infEvento/detEvento/xCorrecao` ou `retEvento/infEvento/cStat`),
#' `grupo` (o grupo logo acima do campo), `campo` (o nome no leiaute) e `valor`
#' (o texto do XML). É onde ficam os campos próprios de cada tipo de evento: as
#' correções do CT-e, o município do encerramento do MDF-e, o código do motivo
#' do cancelamento da NFS-e...
#'
#' @section arquivos:
#' Uma linha por arquivo pedido: `arquivo`, `eventos` (quantos eventos tinha)
#' e `problema` (`NA` quando deu certo). Um texto de XML aparece como
#' `"(texto 1)"`, `"(texto 2)"`...
#'
#' @param arquivos Os XMLs a ler: o caminho de um arquivo, um vetor com vários
#'   (por exemplo, `list.files("pasta", pattern = "xml$", full.names = TRUE)`)
#'   ou o próprio texto do XML (começando por `<`).
#' @param todos_os_campos `FALSE` deixa de fora a tabela `campos`. O padrão é
#'   `TRUE` porque cada tipo de evento tem campos próprios, e um evento tem
#'   poucos campos.
#' @return Uma lista com os `data.frame`s `eventos`, `campos` (só com
#'   `todos_os_campos = TRUE`) e `arquivos`.
#' @source Schemas oficiais: o leiaute genérico de eventos da NF-e (PL_Evento
#'   do pacote 010d v1.01, NT 2026.004, Portal da NF-e, 08/06/2026), o do
#'   cancelamento (atualizado em 21/12/2018) e o da carta de correção (v1.01,
#'   30/05/2014), o resumo de evento da Distribuição de DF-e v1.04
#'   (03/07/2026), os eventos do CT-e (PL_CTe_400 NT 2026.004), do MDF-e
#'   (PL_MDFe_300b da NT 2025.001 v1.04) e da NFS-e Nacional
#'   (NFSe-ESQUEMAS_XSD-v1.01-20260209).
#' @examples
#' exemplos = system.file("exemplos", package = "RNfe")
#' arquivos = file.path(exemplos, c("evento_nfe_cancelamento.xml", "evento_nfse_cancelamento.xml"))
#' lido = eventos_ler(arquivos)
#' lido$eventos[, c("documento", "tipo", "descricao", "justificativa", "situacao")]
#'
#' # O cancelamento é um evento à parte: a nota continua autorizada no protocolo dela.
#' notas = nfe_ler(file.path(exemplos, "nfe_proc_sp.xml"))$notas
#' canceladas = lido$eventos$chave[lido$eventos$tipo == "110111"]
#' notas$cancelada = notas$chave %in% canceladas
#' notas[, c("chave", "situacao", "cancelada")]
#' @export
eventos_ler = function(arquivos, todos_os_campos = TRUE) {
  arquivos_lidos = ler_arquivos_xml(arquivos, CAMINHO_DOS_EVENTOS, "um evento", colunas_dos_eventos, todos_os_campos)
  colunas_vazias = colunas_dos_eventos(NULL, NA_character_, todos_os_campos)

  tabelas_dos_eventos = list(eventos = juntar_tabela(arquivos_lidos, "eventos", colunas_vazias$eventos))
  if (todos_os_campos) {
    tabelas_dos_eventos$campos = juntar_tabela(arquivos_lidos, "campos", colunas_vazias$campos)
  }
  tabelas_dos_eventos$arquivos = resumo_dos_arquivos(arquivos_lidos, "eventos", "eventos")
  tabelas_dos_eventos$eventos = converter_datas(tabelas_dos_eventos$eventos, CAMPOS_DE_DATA_DOS_EVENTOS)
  tabelas_dos_eventos$eventos = acrescentar_significados(tabelas_dos_eventos$eventos, "evento", SIGNIFICADOS_DOS_EVENTOS)
  tabelas_dos_eventos
}

# As colunas das tabelas de um arquivo de eventos, cada uma num vetor. Com xml_lido NULL, vêm vazias, já com os
# nomes e os tipos certos.
colunas_dos_eventos = function(xml_lido, nome_do_arquivo, todos_os_campos) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  pedidos = buscar_todos(xml_lido, CAMINHO_DOS_PEDIDOS_DE_EVENTO)
  retornos = buscar_todos(xml_lido, CAMINHO_DOS_RETORNOS_DE_EVENTO)
  eventos_da_nfse = buscar_todos(xml_lido, CAMINHO_DOS_EVENTOS_DA_NFSE)
  resumos = buscar_todos(xml_lido, CAMINHO_DOS_RESUMOS_DE_EVENTO)

  # O retorno é casado com o pedido pelo envelope em que os dois estão (procEventoNFe, procEventoCTe...). O
  # evento que veio sem envelope (só assinado) fica sem retorno.
  retorno_de_cada_pedido = match(caminho_do_envelope(pedidos), caminho_do_envelope(retornos), incomparables = NA)
  do_pedido = valores_dos_campos(pedidos, CAMPOS_DO_PEDIDO_DE_EVENTO)
  do_retorno = valores_dos_campos(retornos, CAMPOS_DO_RETORNO_DE_EVENTO, retorno_de_cada_pedido)
  familia_de_cada_pedido = unname(FAMILIA_PELA_CHAVE[xml2::xml_name(xml2::xml_find_first(pedidos, "chNFe|chCTe|chMDFe", ns = SEM_NAMESPACE))])

  grupo_dos_pedidos = do_pedido
  grupo_dos_pedidos$documento = documento_de_cada_evento(do_pedido$chave, familia_de_cada_pedido)
  grupo_dos_pedidos$descricao = ifelse(is.na(do_pedido$descricao), do_retorno$descricao, do_pedido$descricao)
  grupo_dos_pedidos$situacao = do_retorno$situacao
  grupo_dos_pedidos$motivo = do_retorno$motivo
  grupo_dos_pedidos$protocolo = do_retorno$protocolo
  grupo_dos_pedidos$registro = do_retorno$registro
  grupo_dos_pedidos$resumo = rep(FALSE, length(pedidos))

  grupo_da_nfse = valores_dos_campos(eventos_da_nfse, CAMPOS_DO_EVENTO_DA_NFSE)
  grupo_da_nfse$tipo = sub("^e", "", grupo_da_nfse$tipo)
  grupo_da_nfse$documento = rep("NFS-e", length(eventos_da_nfse))
  grupo_da_nfse$resumo = rep(FALSE, length(eventos_da_nfse))

  grupo_dos_resumos = valores_dos_campos(resumos, CAMPOS_DO_RESUMO_DE_EVENTO)
  grupo_dos_resumos$documento = documento_de_cada_evento(grupo_dos_resumos$chave, rep("NF-e", length(resumos)))
  grupo_dos_resumos$resumo = rep(TRUE, length(resumos))

  eventos = juntar_grupos_de_eventos(list(grupo_dos_pedidos, grupo_da_nfse, grupo_dos_resumos), COLUNAS_DOS_EVENTOS)
  eventos$arquivo = rep(nome_do_arquivo, length(eventos$chave))
  colunas_das_tabelas = list(eventos = eventos)

  if (todos_os_campos) {
    # De cada evento, na ordem da tabela eventos: o evento e o retorno dele, o evento da NFS-e ou o resumo.
    elemento_de_cada_pedido = xml2::xml_find_first(pedidos, "parent::*", ns = SEM_NAMESPACE)
    elemento_de_cada_retorno = xml2::xml_find_first(retornos, "parent::*", ns = SEM_NAMESPACE)
    elemento_de_cada_evento_da_nfse = xml2::xml_find_first(eventos_da_nfse, "parent::*", ns = SEM_NAMESPACE)
    partes_de_cada_evento = list()
    for (posicao in seq_along(pedidos)) {
      partes_do_evento = list(elemento_de_cada_pedido[[posicao]])
      if (!is.na(retorno_de_cada_pedido[posicao])) {
        partes_do_evento[[2]] = elemento_de_cada_retorno[[retorno_de_cada_pedido[posicao]]]
      }
      partes_de_cada_evento[[length(partes_de_cada_evento) + 1]] = partes_do_evento
    }
    for (posicao in seq_along(eventos_da_nfse)) {
      partes_de_cada_evento[[length(partes_de_cada_evento) + 1]] = list(elemento_de_cada_evento_da_nfse[[posicao]])
    }
    for (posicao in seq_along(resumos)) {
      partes_de_cada_evento[[length(partes_de_cada_evento) + 1]] = list(resumos[[posicao]])
    }
    colunas_das_tabelas$campos = colunas_dos_campos_dos_eventos(partes_de_cada_evento, eventos$chave, eventos$tipo, eventos$sequencia)
  }
  colunas_das_tabelas
}

# O caminho do envelope de cada infEvento (procEventoNFe, procEventoCTe...): NA quando o evento está sozinho.
caminho_do_envelope = function(informacoes_do_evento) {
  xml2::xml_path(xml2::xml_find_first(informacoes_do_evento, "parent::*/parent::*", ns = SEM_NAMESPACE))
}

# O documento de cada evento pelo modelo da chave (55 é NF-e, 65 NFC-e, 67 CT-e OS...) e, sem ele, pela família
# do evento.
documento_de_cada_evento = function(chaves, familia_de_cada) {
  documento_pelo_modelo = unname(DOCUMENTO_PELO_MODELO[substr(chaves, 21, 22)])
  ifelse(nchar(chaves) == 44 & !is.na(documento_pelo_modelo), documento_pelo_modelo, familia_de_cada)
}

# Junta os grupos de eventos (pedidos, eventos da NFS-e e resumos) nas colunas da tabela, na ordem de
# `colunas_vazias`. A coluna que um grupo não tem fica NA nas linhas dele.
juntar_grupos_de_eventos = function(grupos, colunas_vazias) {
  colunas_juntas = list()
  for (nome_da_coluna in names(colunas_vazias)) {
    pedacos_da_coluna = list(colunas_vazias[[nome_da_coluna]])
    for (grupo in grupos) {
      valores_do_grupo = grupo[[nome_da_coluna]]
      if (is.null(valores_do_grupo)) {
        valores_do_grupo = rep(NA, length(grupo$chave))
      }
      pedacos_da_coluna[[length(pedacos_da_coluna) + 1]] = valores_do_grupo
    }
    colunas_juntas[[nome_da_coluna]] = do.call(c, pedacos_da_coluna)
  }
  colunas_juntas
}

# Todos os campos de cada evento, um por linha, com o caminho a partir da parte de onde vêm (o evento, o retorno
# ou o resumo). `partes_de_cada_evento` traz, para cada linha da tabela eventos, as partes dele.
colunas_dos_campos_dos_eventos = function(partes_de_cada_evento, chaves, tipos, sequencias) {
  campos_de_cada_parte = list()
  for (posicao in seq_along(partes_de_cada_evento)) {
    for (parte_do_evento in partes_de_cada_evento[[posicao]]) {
      campos_da_parte = buscar_todos(parte_do_evento, ".//*[not(*)][not(ancestor::Signature)]")
      quantidade_de_campos = length(campos_da_parte)
      # O caminho de cada campo começa no nome da parte; o pedaço de antes (o procEventoNFe...) muda de arquivo
      # para arquivo.
      inicio_do_caminho = nchar(xml2::xml_path(parte_do_evento)) + 2
      grupo_de_cada_campo = xml2::xml_find_first(campos_da_parte, "parent::*", ns = SEM_NAMESPACE)
      campos_de_cada_parte[[length(campos_de_cada_parte) + 1]] = list(
        chave = rep(chaves[posicao], quantidade_de_campos),
        tipo = rep(tipos[posicao], quantidade_de_campos),
        sequencia = rep(sequencias[posicao], quantidade_de_campos),
        caminho = paste0(xml2::xml_name(parte_do_evento), "/", substring(xml2::xml_path(campos_da_parte), inicio_do_caminho),
                         recycle0 = TRUE),
        grupo = xml2::xml_name(grupo_de_cada_campo),
        campo = xml2::xml_name(campos_da_parte),
        valor = xml2::xml_text(campos_da_parte)
      )
    }
  }
  colunas_dos_campos = list(chave = character(), tipo = character(), sequencia = integer(), caminho = character(),
                            grupo = character(), campo = character(), valor = character())
  for (nome_da_coluna in names(colunas_dos_campos)) {
    pedacos_da_coluna = vector("list", length(campos_de_cada_parte) + 1)
    pedacos_da_coluna[[1]] = colunas_dos_campos[[nome_da_coluna]]
    for (posicao in seq_along(campos_de_cada_parte)) {
      pedacos_da_coluna[[posicao + 1]] = campos_de_cada_parte[[posicao]][[nome_da_coluna]]
    }
    colunas_dos_campos[[nome_da_coluna]] = do.call(c, pedacos_da_coluna)
  }
  colunas_dos_campos
}
