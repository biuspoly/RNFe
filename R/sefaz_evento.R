# Os eventos da NF-e e da NFC-e (RecepcaoEvento4): o cancelamento e a carta de correção, no autorizador da UF da nota;
# a manifestação do destinatário, o comprovante de entrega, o ator interessado e o EPEC, no Ambiente Nacional; o
# insucesso na entrega, na SVRS. O detalhe de cada evento (o detEvento) é montado pelo schema oficial dele, e a mensagem
# inteira, já assinada, é conferida no schema geral dos eventos antes de ir à SEFAZ (os dois em inst/schemas/nfe_eventos).
# Cada evento vai num lote só dele. Só o ambiente de homologação.

#' @include sefaz.R assinatura.R sefaz_autorizar.R montar.R
NULL

# O texto da condição de uso da carta de correção, fixo no schema (e110110_v1.00.xsd, que aceita este e o com acentos).
CONDICAO_DE_USO_DA_CARTA_DE_CORRECAO = paste(
  "A Carta de Correcao e disciplinada pelo paragrafo 1o-A do art. 7o do Convenio S/N, de 15 de dezembro de 1970 e pode",
  "ser utilizada para regularizacao de erro ocorrido na emissao de documento fiscal, desde que o erro nao esteja",
  "relacionado com: I - as variaveis que determinam o valor do imposto tais como: base de calculo, aliquota, diferenca de",
  "preco, quantidade, valor da operacao ou da prestacao; II - a correcao de dados cadastrais que implique mudanca do",
  "remetente ou do destinatario; III - a data de emissao ou de saida."
)
# Os tipos de manifestação do destinatário e o código do evento. Cada tipo conclusivo pode ser registrado duas vezes na
# nota (a segunda com a sequência 2), e vale a última manifestação: confirmar, desconhecer e confirmar de novo (NT
# 2020.001 v1.60, item E e regra H02). A ciência, uma vez só.
TIPOS_DE_MANIFESTACAO = utils::read.table(header = TRUE, sep = ";", strip.white = TRUE, stringsAsFactors = FALSE, text = "
tipo            ; codigo ; conclusiva
confirmacao     ; 210200 ; sim
ciencia         ; 210210 ; nao
desconhecimento ; 210220 ; sim
nao_realizada   ; 210240 ; sim
", colClasses = "character")
# As situações do evento registrado: 135 (registrado e vinculado à nota), 136 (registrado sem vínculo) e 155
# (cancelamento homologado fora de prazo).
SITUACOES_DO_EVENTO_REGISTRADO = c(135L, 136L, 155L)

# A pasta dos schemas dos eventos da NF-e em inst/schemas: a parte geral do pacote 010d v1.03 (a do CNPJ alfanumérico, NT
# 2026.004), os tipos básicos do 010g (os do 010d com dois tipos novos, que os eventos daqui não usam) e o detEvento de
# cada evento, do pacote dele. Os pacotes de cada evento são anteriores ao CNPJ alfanumérico e incluem o
# tiposBasico_v1.03.xsd pelo nome; com o novo, mudam só o TCnpj e o TProt, os tipos que a NT 2026.004 mudou.
PASTA_DOS_EVENTOS_DA_NFE = "nfe_eventos"
# Cada evento: o schema do detEvento, quem recebe (UF: o autorizador da UF da chave; AN: o Ambiente Nacional; SVRS), os
# modelos da chave que o aceitam e o nome para as mensagens. Fontes: MOC 7.0 (itens 5.8 a 5.12), NT 2020.001
# (manifestação), NT 2021.001 (comprovante de entrega), NT 2014.001 (EPEC), NT 2020.007 (ator interessado) e NT 2023.005
# (insucesso na entrega, só na SVRS).
EVENTOS_DA_NFE = utils::read.table(header = TRUE, sep = ";", strip.white = TRUE, stringsAsFactors = FALSE, text = "
codigo ; schema            ; recebe ; modelos ; nome
110110 ; e110110_v1.00.xsd ; UF     ; 55      ; carta de corre\u00e7\u00e3o
110111 ; e110111_v1.00.xsd ; UF     ; 55 65   ; cancelamento
110130 ; e110130_v1.00.xsd ; AN     ; 55      ; comprovante de entrega
110131 ; e110131_v1.00.xsd ; AN     ; 55      ; cancelamento do comprovante de entrega
110140 ; e110140_v1.00.xsd ; AN     ; 55      ; EPEC
110150 ; 110150_v1.00.xsd  ; AN     ; 55      ; evento do ator interessado
110192 ; e110192_v1.00.xsd ; SVRS   ; 55      ; insucesso na entrega
110193 ; e110193_v1.00.xsd ; SVRS   ; 55      ; cancelamento do insucesso na entrega
210200 ; e210200_v1.00.xsd ; AN     ; 55      ; manifesta\u00e7\u00e3o do destinat\u00e1rio
210210 ; e210210_v1.00.xsd ; AN     ; 55      ; manifesta\u00e7\u00e3o do destinat\u00e1rio
210220 ; e210220_v1.00.xsd ; AN     ; 55      ; manifesta\u00e7\u00e3o do destinat\u00e1rio
210240 ; e210240_v1.00.xsd ; AN     ; 55      ; manifesta\u00e7\u00e3o do destinat\u00e1rio
", colClasses = "character")
# O código de órgão (cOrgao) de quem recebe o evento fora da UF da nota: 91, o Ambiente Nacional; 92, a SVRS.
ORGAO_DE_QUEM_RECEBE = c(AN = "91", SVRS = "92")
# O verAplic dos eventos que pedem a versão do aplicativo do autor.
VERSAO_DO_APLICATIVO = "RNFe"
# Os motivos do insucesso na entrega (tpMotivo, NT 2023.005): o "outro" exige a justificativa.
MOTIVOS_DO_INSUCESSO = c(nao_encontrado = "1", recusa = "2", endereco_inexistente = "3", outro = "4")
# Quem registra o evento do ator interessado (tpAutor, NT 2020.007).
AUTORES_DO_ATOR_INTERESSADO = c(emitente = "1", destinatario = "2", transportador = "3")
# As UFs cujos contribuintes não podem usar o EPEC desde 05/10/2026 (Ajuste SINIEF 25/2026; regra 2P10-20 da NT
# 2014.001 v1.40): o PR (41) e a PB (25).
UFS_SEM_EPEC = c("41", "25")

#' Cancelar uma NF-e
#'
#' Registra na SEFAZ o cancelamento de uma NF-e ou NFC-e autorizada (o evento
#' 110111): a nota deixa de valer, e o evento fica ligado a ela. O prazo é o da
#' legislação da UF (em geral, 24 horas da autorização na NF-e e 30 minutos na
#' NFC-e); fora dele, a SEFAZ rejeita ou registra como fora de prazo (155).
#'
#' O autor do evento é o emitente da chave (o CNPJ ou, nas séries do emitente
#' pessoa física, o CPF), e o certificado pode ser o dele ou o de outro
#' estabelecimento da empresa (o mesmo CNPJ-base): a nota de uma filial pode
#' ser cancelada com o certificado da matriz. O detalhe do evento é montado e
#' conferido pelo schema oficial dele, e a mensagem inteira, já assinada, pelo
#' schema geral dos eventos, antes de ir à SEFAZ. Por enquanto só o ambiente de
#' **homologação**.
#'
#' @param chave A chave de acesso da nota (44 posições).
#' @param protocolo O número do protocolo de autorização da nota (15
#'   algarismos; 17 no protocolo do provedor de assinatura e autorização, o
#'   PAA da NT 2026.001).
#' @param justificativa O motivo do cancelamento, de 15 a 255 caracteres.
#' @inheritParams sefaz_status
#' @return Um `data.frame` com uma linha: `chave`, `evento` (o código),
#'   `sequencia`, `ambiente`, `situacao_lote`, `motivo_lote`, `situacao` (135
#'   ou 136 registrado; 155 cancelamento fora de prazo; as outras são
#'   rejeição), `motivo`, `protocolo` (o do evento), `registro` (data e hora),
#'   `xml_evento` (o `procEventoNFe`, só no evento registrado), `endereco` e
#'   `problema`.
#' @seealso [sefaz_autorizar()], [sefaz_carta_correcao()],
#'   [sefaz_manifestar()]; [eventos_ler()] lê o `xml_evento`.
#' @source Manual de Orientação do Contribuinte da NF-e (o serviço de eventos e
#'   o cancelamento); os schemas `envEvento_v1.00.xsd` (pacote 010d v1.03) e
#'   `e110111_v1.00.xsd`; o WSDL do NFeRecepcaoEvento4 (operação
#'   `nfeRecepcaoEvento`).
#' @examples
#' \dontrun{
#' sefaz_cancelar("35261011222333000181550010000010011123456785", "135260000012345",
#'                "PEDIDO CANCELADO PELO CLIENTE", "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_cancelar = function(chave, protocolo, justificativa, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_texto_do_evento(justificativa, "justificativa", 15, 255)
  conferir_protocolo(protocolo, "o protocolo de autoriza\u00e7\u00e3o da nota")
  registrar_evento(chave, "110111", 1L, list(nProt = protocolo, xJust = justificativa), certificado, senha, ambiente)
}

#' Registrar uma carta de correção
#'
#' Registra na SEFAZ a carta de correção de uma NF-e (o evento 110110): corrige
#' um dado da nota que não muda o imposto, o remetente, o destinatário nem a
#' data. Cada carta nova substitui a anterior e leva o número seguinte
#' (`sequencia`, de 1 a 20). Só a NF-e (modelo 55) tem carta de correção.
#'
#' Como no cancelamento, o autor é o emitente da chave e o certificado pode ser
#' o de outro estabelecimento da empresa (o mesmo CNPJ-base). Por enquanto só o
#' ambiente de **homologação**.
#'
#' @param correcao O texto da correção, de 15 a 1.000 caracteres. A carta
#'   nova tem de trazer todas as correções, também as das cartas anteriores.
#' @param sequencia O número desta carta para a nota: 1 na primeira.
#' @inheritParams sefaz_cancelar
#' @inherit sefaz_cancelar return
#' @source Manual de Orientação do Contribuinte da NF-e (o serviço de eventos);
#'   o schema da carta de correção (`e110110_v1.00.xsd`, com o texto fixo da
#'   condição de uso).
#' @examples
#' \dontrun{
#' sefaz_carta_correcao("35261011222333000181550010000010011123456785",
#'                      "ONDE SE LE RUA DO CLIENTE, 10, LEIA-SE RUA DO CLIENTE, 100", 1,
#'                      "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_carta_correcao = function(chave, correcao, sequencia, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_texto_do_evento(correcao, "correcao", 15, 1000)
  sequencia = conferir_sequencia_do_evento(sequencia, 20, "da carta de corre\u00e7\u00e3o")
  campos = list(descEvento = "Carta de Correcao", xCorrecao = correcao, xCondUso = CONDICAO_DE_USO_DA_CARTA_DE_CORRECAO)
  registrar_evento(chave, "110110", sequencia, campos, certificado, senha, ambiente)
}

#' Manifestar o destinatário sobre uma NF-e
#'
#' Registra no Ambiente Nacional a manifestação do destinatário sobre uma NF-e
#' emitida contra ele: a ciência da operação (`"ciencia"`, que libera o XML
#' completo na Distribuição de DF-e), a confirmação (`"confirmacao"`), o
#' desconhecimento (`"desconhecimento"`) ou a operação não realizada
#' (`"nao_realizada"`, que pede a justificativa).
#'
#' Cada manifestação conclusiva (confirmação, desconhecimento ou operação não
#' realizada) pode ser registrada até duas vezes na nota, e vale a última
#' registrada: confirmar, depois desconhecer e confirmar de novo (a segunda
#' confirmação com `sequencia = 2`). A sequência conta por tipo: a primeira de
#' cada um é a 1. A ciência vai uma vez só, antes da manifestação conclusiva.
#'
#' O autor do evento é o destinatário da nota, e o certificado tem de ter o
#' CNPJ-base (ou o CPF) dele. Sem `destinatario`, o autor é o CNPJ do
#' certificado; quando a nota foi emitida para uma filial e o certificado é o
#' da matriz, informe o CNPJ da filial. Por enquanto só o ambiente de
#' **homologação**.
#'
#' @param tipo `"ciencia"`, `"confirmacao"`, `"desconhecimento"` ou
#'   `"nao_realizada"`.
#' @param justificativa Só na operação não realizada: o motivo, de 15 a 255
#'   caracteres.
#' @param destinatario Opcional: o CNPJ (ou o CPF) do destinatário da nota,
#'   quando não é o do certificado (o mesmo CNPJ-base).
#' @param sequencia 1 na primeira manifestação do tipo; 2 na segunda do mesmo
#'   tipo (só na conclusiva).
#' @inheritParams sefaz_cancelar
#' @inherit sefaz_cancelar return
#' @seealso [sefaz_distribuicao()], que traz o XML completo depois da ciência.
#' @source NT 2020.001 v1.60 (a manifestação do destinatário, eventos 210200,
#'   210210, 210220 e 210240, no Ambiente Nacional, órgão 91; a retificação,
#'   regra H02); os schemas `e210200_v1.00.xsd` a `e210240_v1.00.xsd`.
#' @examples
#' \dontrun{
#' sefaz_manifestar("35261011222333000181550010000010011123456785", "ciencia",
#'                  certificado = "empresa.pfx", senha = Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_manifestar = function(chave, tipo, justificativa = NULL, certificado, senha, ambiente = "homologacao",
                            destinatario = NULL, sequencia = 1) {
  conferir_ambiente(ambiente)
  if (length(tipo) != 1 || !(tipo %in% TIPOS_DE_MANIFESTACAO$tipo)) {
    stop("Informe o tipo: ", paste0("\"", TIPOS_DE_MANIFESTACAO$tipo, "\"", collapse = ", "), ".", call. = FALSE)
  }
  manifestacao = TIPOS_DE_MANIFESTACAO[TIPOS_DE_MANIFESTACAO$tipo == tipo, ]
  sequencia = conferir_sequencia_do_evento(sequencia, 2, "da manifesta\u00e7\u00e3o")
  if (sequencia == 2L && manifestacao$conclusiva != "sim") {
    stop("A ci\u00eancia da opera\u00e7\u00e3o vai uma vez s\u00f3 (sequ\u00eancia 1); a sequ\u00eancia 2 \u00e9 a segunda manifesta\u00e7\u00e3o conclusiva do ",
         "mesmo tipo.", call. = FALSE)
  }
  campos = list()
  if (tipo == "nao_realizada") {
    conferir_texto_do_evento(justificativa, "justificativa", 15, 255)
    campos$xJust = justificativa
  } else if (!is.null(justificativa)) {
    stop("A justificativa vai s\u00f3 na opera\u00e7\u00e3o n\u00e3o realizada.", call. = FALSE)
  }
  registrar_evento(chave, manifestacao$codigo, sequencia, campos, certificado, senha, ambiente, autor = "destinatario",
                   documento_do_autor = destinatario)
}

#' Registrar o comprovante de entrega de uma NF-e
#'
#' Registra no Ambiente Nacional o comprovante de entrega da mercadoria de uma
#' NF-e autorizada (o evento 110130), quando a entrega não tem CT-e: quando e
#' quem recebeu, e o hash da imagem do comprovante (a assinatura do recebedor,
#' uma foto). O RNFe calcula o hash como a NT pede (o SHA-1, em Base64, da
#' chave de acesso seguida da imagem em Base64); a imagem não vai à SEFAZ.
#' Para registrar um comprovante novo, o anterior tem de ser cancelado antes
#' ([sefaz_cancelar_comprovante_entrega()]), e a nota com comprovante não pode
#' ser cancelada.
#'
#' O autor é o emitente da chave, e o certificado pode ser o de outro
#' estabelecimento da empresa (o mesmo CNPJ-base). Por enquanto só o ambiente de
#' **homologação**.
#'
#' @param entrega A data e a hora do fim da entrega (`POSIXct`, ou o texto no
#'   formato do leiaute, `AAAA-MM-DDThh:mm:ss-03:00`).
#' @param documento O número do documento de quem recebeu (2 a 20
#'   caracteres).
#' @param nome O nome de quem recebeu (2 a 60 caracteres).
#' @param comprovante A imagem do comprovante (o caminho do arquivo ou o
#'   conteúdo, `raw`), ou o hash já calculado (os 28 caracteres em Base64).
#' @param latitude,longitude Opcionais: o ponto da entrega, em graus (até 6
#'   casas decimais).
#' @param momento_do_comprovante Opcional: a data e a hora em que o hash foi
#'   gerado. Quando o RNFe calcula o hash da imagem e ela não vem, vai a hora do
#'   cálculo.
#' @param sequencia O número deste comprovante para a nota (1 a 99): 1 no
#'   primeiro, 2 no que vem depois do cancelamento dele. No cancelamento, o
#'   número do comprovante cancelado: a SEFAZ o procura pela chave e por esse
#'   número (a regra 4P15-10).
#' @inheritParams sefaz_cancelar
#' @inherit sefaz_cancelar return
#' @source NT 2021.001 v1.01 (o evento Comprovante de Entrega da NF-e, no
#'   Ambiente Nacional); o schema `e110130_v1.00.xsd`.
#' @examples
#' \dontrun{
#' sefaz_comprovante_entrega("35261011222333000181550010000010011123456785", Sys.time(), "123456789",
#'                           "MARIA DA SILVA", "assinatura.png", "empresa.pfx",
#'                           Sys.getenv("SENHA_DO_CERTIFICADO"),
#'                           latitude = -23.55052, longitude = -46.633308)
#' }
#' @export
sefaz_comprovante_entrega = function(chave, entrega, documento, nome, comprovante, certificado, senha, latitude = NULL,
                                     longitude = NULL, momento_do_comprovante = NULL, sequencia = 1,
                                     ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_texto_do_evento(nome, "nome", 2, 60)
  conferir_texto_do_evento(documento, "documento", 2, 20)
  sequencia = conferir_sequencia_do_evento(sequencia, 99, "do comprovante")
  partes = partes_da_chave_do_evento(chave)
  hash = hash_do_comprovante(partes$chave, comprovante)
  if (is.null(momento_do_comprovante) && hash$calculado) {
    momento_do_comprovante = Sys.time()
  }
  campos = list(cOrgaoAutor = partes$codigo_uf, verAplic = VERSAO_DO_APLICATIVO, dhEntrega = entrega, nDoc = documento,
                xNome = nome, latGPS = latitude, longGPS = longitude, hashComprovante = hash$hash,
                dhHashComprovante = momento_do_comprovante)
  registrar_evento(partes$chave, "110130", sequencia, campos, certificado, senha, ambiente)
}

#' @rdname sefaz_comprovante_entrega
#' @param protocolo_do_comprovante O protocolo do evento do comprovante de
#'   entrega que vai ser cancelado.
#' @export
sefaz_cancelar_comprovante_entrega = function(chave, protocolo_do_comprovante, certificado, senha, sequencia = 1,
                                              ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_protocolo(protocolo_do_comprovante, "o protocolo do comprovante de entrega")
  sequencia = conferir_sequencia_do_evento(sequencia, 99, "do cancelamento")
  partes = partes_da_chave_do_evento(chave)
  campos = list(cOrgaoAutor = partes$codigo_uf, verAplic = VERSAO_DO_APLICATIVO, nProtEvento = protocolo_do_comprovante)
  registrar_evento(partes$chave, "110131", sequencia, campos, certificado, senha, ambiente)
}

#' Registrar o insucesso na entrega de uma NF-e
#'
#' Registra na SVRS a tentativa de entrega que não deu certo, quando a entrega
#' não tem CT-e (o evento 110192, que substitui a anotação no verso do DANFE):
#' quando foi, o motivo e o hash de uma imagem da tentativa (uma foto, a
#' assinatura de quem recusou), calculado pelo RNFe como no
#' [sefaz_comprovante_entrega()]. Para registrar outro insucesso, o anterior
#' tem de ser cancelado antes ([sefaz_cancelar_insucesso_entrega()]).
#'
#' O autor é o emitente da chave, e o certificado pode ser o de outro
#' estabelecimento da empresa (o mesmo CNPJ-base). Por enquanto só o ambiente de
#' **homologação**.
#'
#' @param tentativa A data e a hora da tentativa de entrega (`POSIXct`, ou o
#'   texto no formato do leiaute).
#' @param motivo `"nao_encontrado"` (o recebedor não foi encontrado),
#'   `"recusa"` (o recebedor recusou), `"endereco_inexistente"` ou `"outro"`
#'   (que pede a justificativa).
#' @param comprovante A imagem da tentativa (o caminho do arquivo ou o
#'   conteúdo, `raw`), ou o hash já calculado (os 28 caracteres em Base64).
#' @param justificativa Só no motivo `"outro"`: o motivo, de 25 a 250
#'   caracteres.
#' @param numero_da_tentativa Opcional: o número da tentativa (até 3
#'   algarismos).
#' @param sequencia O número deste insucesso para a nota (1 a 99): 1 no
#'   primeiro, 2 no que vem depois do cancelamento dele. No cancelamento, o
#'   número do insucesso cancelado: a SEFAZ o procura pela chave e por esse
#'   número (a regra 4P15-10).
#' @inheritParams sefaz_comprovante_entrega
#' @inherit sefaz_cancelar return
#' @source NT 2023.005 v1.02 (o evento Insucesso na Entrega da NF-e, na SVRS,
#'   órgão 92); o schema `e110192_v1.00.xsd`.
#' @examples
#' \dontrun{
#' sefaz_insucesso_entrega("35261011222333000181550010000010011123456785", Sys.time(), "recusa",
#'                         "foto_da_porta.jpg", "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_insucesso_entrega = function(chave, tentativa, motivo, comprovante, certificado, senha, justificativa = NULL,
                                   numero_da_tentativa = NULL, latitude = NULL, longitude = NULL,
                                   momento_do_comprovante = NULL, sequencia = 1, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  if (length(motivo) != 1 || !(motivo %in% names(MOTIVOS_DO_INSUCESSO))) {
    stop("Informe o motivo: ", paste0("\"", names(MOTIVOS_DO_INSUCESSO), "\"", collapse = ", "), ".", call. = FALSE)
  }
  if (motivo == "outro") {
    conferir_texto_do_evento(justificativa, "justificativa", 25, 250)
  } else if (!is.null(justificativa)) {
    stop("A justificativa vai s\u00f3 no motivo \"outro\".", call. = FALSE)
  }
  sequencia = conferir_sequencia_do_evento(sequencia, 99, "do insucesso")
  if (!is.null(numero_da_tentativa)) {
    numero_da_tentativa = as.character(conferir_sequencia_do_evento(numero_da_tentativa, 999, "da tentativa"))
  }
  partes = partes_da_chave_do_evento(chave)
  hash = hash_do_comprovante(partes$chave, comprovante)
  if (is.null(momento_do_comprovante) && hash$calculado) {
    momento_do_comprovante = Sys.time()
  }
  campos = list(cOrgaoAutor = partes$codigo_uf, verAplic = VERSAO_DO_APLICATIVO, dhTentativaEntrega = tentativa,
                nTentativa = numero_da_tentativa, tpMotivo = MOTIVOS_DO_INSUCESSO[[motivo]], xJustMotivo = justificativa,
                latGPS = latitude, longGPS = longitude, hashTentativaEntrega = hash$hash,
                dhHashTentativaEntrega = momento_do_comprovante)
  registrar_evento(partes$chave, "110192", sequencia, campos, certificado, senha, ambiente)
}

#' @rdname sefaz_insucesso_entrega
#' @param protocolo_do_insucesso O protocolo do evento de insucesso na entrega
#'   que vai ser cancelado.
#' @export
sefaz_cancelar_insucesso_entrega = function(chave, protocolo_do_insucesso, certificado, senha, sequencia = 1,
                                            ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_protocolo(protocolo_do_insucesso, "o protocolo do insucesso na entrega")
  sequencia = conferir_sequencia_do_evento(sequencia, 99, "do cancelamento")
  partes = partes_da_chave_do_evento(chave)
  campos = list(cOrgaoAutor = partes$codigo_uf, verAplic = VERSAO_DO_APLICATIVO, nProtEvento = protocolo_do_insucesso)
  registrar_evento(partes$chave, "110193", sequencia, campos, certificado, senha, ambiente)
}

#' Autorizar um transportador a baixar o XML de uma NF-e
#'
#' Registra no Ambiente Nacional o evento do ator interessado (110150): o
#' transportador (o CNPJ ou o CPF de `autorizado`) passa a poder baixar o XML
#' da nota pela Distribuição de DF-e, como quem está no `autXML` dela. Serve
#' quando o transportador não era conhecido na emissão. Pode ser registrado
#' pelo emitente, pelo destinatário (quando o frete é por conta dele) ou pelo
#' transportador contratado (que autoriza um subcontratado ou um redespacho,
#' quando o emitente ou o destinatário permitiu, com `permite_repassar =
#' TRUE`). O prazo é de 6 meses da autorização da nota.
#'
#' O autor emitente é o da chave, e o certificado pode ser o de outro
#' estabelecimento da empresa (o mesmo CNPJ-base); o destinatário e o
#' transportador são o CNPJ do certificado, ou o `documento_do_autor`. Por
#' enquanto só o ambiente de **homologação**.
#'
#' @param autorizado O CNPJ ou o CPF de quem passa a poder baixar o XML.
#' @param autor Quem registra: `"emitente"`, `"destinatario"` ou
#'   `"transportador"` (o transportador contratado).
#' @param permite_repassar Só quando o autor é o emitente ou o destinatário:
#'   `TRUE` deixa o transportador autorizado autorizar outros transportadores
#'   (o subcontratado, o redespacho).
#' @param uf_do_autor A UF de quem registra (a sigla ou o código), quando o
#'   autor é o destinatário ou o transportador; no emitente, é a da chave.
#' @param documento_do_autor Opcional: o CNPJ (ou o CPF) do destinatário ou do
#'   transportador, quando não é o do certificado (o mesmo CNPJ-base).
#' @param sequencia O número deste evento para a nota (1 a 20): 1 no primeiro.
#' @inheritParams sefaz_cancelar
#' @inherit sefaz_cancelar return
#' @source NT 2020.007 v1.40 (o evento Ator Interessado na NF-e -
#'   Transportador, no Ambiente Nacional) e NT 2026.004 (o CNPJ alfanumérico); o
#'   schema `110150_v1.00.xsd`.
#' @examples
#' \dontrun{
#' sefaz_ator_interessado("35261011222333000181550010000010011123456785", "11444777000161",
#'                        "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_ator_interessado = function(chave, autorizado, certificado, senha, autor = "emitente", permite_repassar = FALSE,
                                  uf_do_autor = NULL, documento_do_autor = NULL, sequencia = 1,
                                  ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  if (length(autor) != 1 || !(autor %in% names(AUTORES_DO_ATOR_INTERESSADO))) {
    stop("Informe o autor: ", paste0("\"", names(AUTORES_DO_ATOR_INTERESSADO), "\"", collapse = ", "), ".", call. = FALSE)
  }
  if (!isTRUE(permite_repassar) && !isFALSE(permite_repassar)) {
    stop("permite_repassar tem de ser TRUE ou FALSE.", call. = FALSE)
  }
  sequencia = conferir_sequencia_do_evento(sequencia, 20, "do evento")
  partes = partes_da_chave_do_evento(chave)
  documento_autorizado = toupper(gsub("[^0-9A-Za-z]", "", autorizado))
  if (length(documento_autorizado) != 1 || !(cnpj_confere(documento_autorizado) || cpf_confere(documento_autorizado))) {
    stop("Informe o CNPJ ou o CPF do autorizado com os d\u00edgitos certos.", call. = FALSE)
  }
  if (nchar(documento_autorizado) == 11) {
    pessoa_autorizada = list(CPF = documento_autorizado)
  } else {
    pessoa_autorizada = list(CNPJ = documento_autorizado)
  }
  if (autor == "emitente") {
    if (!is.null(uf_do_autor) && !identical(codigo_da_uf_informada(uf_do_autor), partes$codigo_uf)) {
      stop("No evento do emitente, a UF do autor \u00e9 a da chave (", partes$uf, ").", call. = FALSE)
    }
    orgao_do_autor = partes$codigo_uf
  } else {
    if (is.null(uf_do_autor)) {
      stop("Informe a UF do ", autor, " (uf_do_autor).", call. = FALSE)
    }
    orgao_do_autor = codigo_da_uf_informada(uf_do_autor)
  }
  campos = list(cOrgaoAutor = orgao_do_autor, tpAutor = AUTORES_DO_ATOR_INTERESSADO[[autor]],
                verAplic = VERSAO_DO_APLICATIVO, autXML = pessoa_autorizada)
  # O tipo de autorização vai quando o autor é o emitente ou o destinatário (regras P26-10 e P26-20); a condição de
  # uso, só com a autorização para repassar (P27-10 e P27-20), no texto único que o schema aceita.
  if (autor == "transportador") {
    if (isTRUE(permite_repassar)) {
      stop("O transportador contratado n\u00e3o autoriza a repassar: permite_repassar vale s\u00f3 para o emitente e o destinat\u00e1rio.",
           call. = FALSE)
    }
  } else if (isTRUE(permite_repassar)) {
    campos$tpAutorizacao = "1"
    campos$xCondUso = valor_unico_do_campo_do_evento("110150", "xCondUso")
  } else {
    campos$tpAutorizacao = "0"
  }
  autor_do_evento = autor
  if (autor == "transportador") {
    autor_do_evento = "outro"
  }
  registrar_evento(partes$chave, "110150", sequencia, campos, certificado, senha, ambiente, autor = autor_do_evento,
                   documento_do_autor = documento_do_autor)
}

#' Registrar o EPEC de uma NF-e
#'
#' Registra no Ambiente Nacional o Evento Prévio de Emissão em Contingência
#' (EPEC, 110140) de uma NF-e emitida com `tpEmis` 4, quando a SEFAZ da UF não
#' responde: com o EPEC registrado, o DANFE pode ser impresso em papel comum
#' (com o protocolo do EPEC: veja o `protocolo_epec` de [danfe_pdf()]), e a nota
#' tem de ser autorizada depois, com a mesma chave e os mesmos dados
#' ([sefaz_autorizar()]), no prazo da legislação; com EPEC pendente há mais de
#' 7 dias, o emitente fica sem EPEC até autorizar as notas.
#'
#' Os dados do EPEC saem da própria nota, para baterem com ela (a regra
#' 2AB08-30): a chave, a data de emissão, o tipo (entrada ou saída), a IE do
#' emitente, a UF, o documento e a IE do destinatário, e os totais da nota, do
#' ICMS e do ICMS-ST. Os contribuintes do PR e da PB não podem usar o EPEC
#' desde 05/10/2026 (Ajuste SINIEF 25/2026). Por enquanto só o ambiente de
#' **homologação**.
#'
#' @param nota O XML da NF-e com `tpEmis` 4 (o caminho do arquivo ou o próprio
#'   texto), como o [nfe_montar()] devolve, assinada ou não.
#' @inheritParams sefaz_cancelar
#' @return O `data.frame` de [sefaz_cancelar()] (o EPEC registrado tem a
#'   situação 136) e a coluna `chaves_pendentes`: as chaves dos EPEC
#'   pendentes do emitente, separadas por espaço, que a SEFAZ devolve quando o
#'   EPEC está bloqueado para ele (situação 142); `NA` quando não vêm.
#' @source NT 2014.001 v1.41 (o EPEC da NF-e, no Ambiente Nacional, órgão 91) e
#'   NT 2026.004 (o CNPJ alfanumérico); o MOC 7.0, Anexo III (Manual de
#'   Contingência); o schema `e110140_v1.00.xsd`.
#' @examples
#' \dontrun{
#' sefaz_epec("nota_em_contingencia.xml", "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_epec = function(nota, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  documento = ler_o_xml_para_assinar(nota)
  todas_as_notas = xml2::xml_find_all(documento, "//*[local-name()='infNFe']")
  if (length(todas_as_notas) == 0) {
    stop("Informe o XML de uma NF-e (com o grupo infNFe).", call. = FALSE)
  }
  if (length(todas_as_notas) > 1) {
    stop("O XML traz ", length(todas_as_notas), " notas: o EPEC \u00e9 de uma nota por vez.", call. = FALSE)
  }
  informacoes = todas_as_notas[[1]]
  chave = sub("^NFe", "", xml2::xml_attr(informacoes, "Id"))
  partes = partes_da_chave_do_evento(chave)
  if (!identical(texto_na_nota(informacoes, "ide/mod"), "55")) {
    stop("O EPEC \u00e9 s\u00f3 da NF-e (modelo 55).", call. = FALSE)
  }
  # O EPEC tem de bater com a nota que vai ser autorizada depois: a do mesmo ambiente e a da UF da chave.
  if (!identical(texto_na_nota(informacoes, "ide/tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    stop("A nota tem o tpAmb ", texto_na_nota(informacoes, "ide/tpAmb"), ", e o EPEC vai ao ambiente de tpAmb ",
         AMBIENTES_LIBERADOS[[ambiente]], " (", ambiente, "): o da nota tem de ser o mesmo.", call. = FALSE)
  }
  if (!identical(texto_na_nota(informacoes, "ide/cUF"), partes$codigo_uf)) {
    stop("O cUF da nota (", texto_na_nota(informacoes, "ide/cUF"), ") n\u00e3o \u00e9 o da chave (", partes$codigo_uf, ").",
         call. = FALSE)
  }
  if (!identical(texto_na_nota(informacoes, "ide/tpEmis"), "4") || !identical(partes$forma_emissao, 4L)) {
    stop("O EPEC \u00e9 da nota emitida em conting\u00eancia EPEC (tpEmis 4, tamb\u00e9m na posi\u00e7\u00e3o 35 da chave).", call. = FALSE)
  }
  if (partes$codigo_uf %in% UFS_SEM_EPEC) {
    stop("A SEFAZ da UF da nota (", partes$uf, ") n\u00e3o permite o EPEC desde 05/10/2026 (Ajuste SINIEF 25/2026).",
         call. = FALSE)
  }
  destinatario = xml2::xml_find_first(informacoes, "./*[local-name()='dest']")
  if (inherits(destinatario, "xml_missing")) {
    stop("A nota n\u00e3o tem o destinat\u00e1rio (dest), que o EPEC pede.", call. = FALSE)
  }
  do_destinatario = list(UF = texto_na_nota(destinatario, "enderDest/UF"))
  for (nome_do_documento in c("CNPJ", "CPF", "idEstrangeiro")) {
    valor = texto_na_nota(destinatario, nome_do_documento)
    if (!is.na(valor)) {
      do_destinatario[[nome_do_documento]] = valor
    }
  }
  do_destinatario$IE = texto_na_nota(destinatario, "IE")
  do_destinatario$vNF = texto_na_nota(informacoes, "total/ICMSTot/vNF")
  do_destinatario$vICMS = texto_na_nota(informacoes, "total/ICMSTot/vICMS")
  do_destinatario$vST = texto_na_nota(informacoes, "total/ICMSTot/vST")
  campos = list(cOrgaoAutor = partes$codigo_uf, verAplic = VERSAO_DO_APLICATIVO,
                dhEmi = texto_na_nota(informacoes, "ide/dhEmi"), tpNF = texto_na_nota(informacoes, "ide/tpNF"),
                IE = texto_na_nota(informacoes, "emit/IE"), dest = do_destinatario)
  registrar_evento(partes$chave, "110140", 1L, campos, certificado, senha, ambiente, com_pendentes = TRUE)
}

# O texto de um campo da nota pelo caminho (ide/tpEmis), sem olhar o prefixo do namespace; NA quando não tem. O campo
# vazio (o idEstrangeiro do estrangeiro sem documento) volta como texto vazio.
texto_na_nota = function(elemento, caminho) {
  passos = strsplit(caminho, "/", fixed = TRUE)[[1]]
  expressao = paste0("./", paste0("*[local-name()='", passos, "']", collapse = "/"))
  achado = xml2::xml_find_first(elemento, expressao)
  if (inherits(achado, "xml_missing")) {
    return(NA_character_)
  }
  xml2::xml_text(achado)
}

# As séries em que a chave traz o CPF do emitente (precedido de zeros), e não o CNPJ: na NF-e, fora de 0 a 909 (a nota
# da regra P12-44 do MOC 7.0); no MDF-e, de 920 a 969 (a regra J09 do MOC do MDF-e 3.00b).
SERIES_DO_CPF_NA_NFE = 910:999
SERIES_DO_CPF_NO_MDFE = 920:969

# O autor de um evento do emitente: o CNPJ (ou o CPF) que está na chave. O MOC da NF-e (P12-44) e o do MDF-e (J09)
# rejeitam o autor diferente do emitente da chave; o certificado pode ser o da matriz ou o de uma filial (o mesmo
# CNPJ-base, item 5.9 do MOC da NF-e).
autor_do_emitente = function(partes, series_do_cpf, certificado, senha) {
  if (partes$serie %in% series_do_cpf) {
    autor = list(tipo_documento = "CPF", documento = substr(partes$documento_emitente, 4, 14))
  } else {
    autor = list(tipo_documento = "CNPJ", documento = partes$documento_emitente)
  }
  conferir_o_certificado_do_autor(autor, certificado, senha, "o emitente da chave")
  autor
}

# O autor informado (o destinatário da NF-e, o transportador ou o tomador do CT-e, quando é uma filial e o certificado
# é o da matriz) ou, sem ele, o do certificado.
autor_informado_ou_do_certificado = function(documento, certificado, senha, quem) {
  if (is.null(documento)) {
    do_certificado = certificado_ler(certificado, senha)
    if (is.na(do_certificado$documento)) {
      stop("O certificado n\u00e3o traz o CNPJ nem o CPF do titular: informe o ", quem, ".", call. = FALSE)
    }
    return(list(tipo_documento = do_certificado$tipo_documento, documento = do_certificado$documento))
  }
  documento_limpo = toupper(gsub("[^0-9A-Za-z]", "", documento))
  if (length(documento_limpo) != 1 || !(cnpj_confere(documento_limpo) || cpf_confere(documento_limpo))) {
    stop("Informe o CNPJ ou o CPF do ", quem, " com os d\u00edgitos certos.", call. = FALSE)
  }
  autor = list(tipo_documento = if (nchar(documento_limpo) == 11) "CPF" else "CNPJ", documento = documento_limpo)
  conferir_o_certificado_do_autor(autor, certificado, senha, paste("o", quem))
  autor
}

# O certificado tem de ser do autor: o mesmo CNPJ-base (as 8 primeiras posições) ou o mesmo CPF.
conferir_o_certificado_do_autor = function(autor, certificado, senha, quem) {
  do_certificado = certificado_ler(certificado, senha)
  if (is.na(do_certificado$documento)) {
    stop("O certificado n\u00e3o traz o CNPJ nem o CPF do titular.", call. = FALSE)
  }
  if (autor$tipo_documento == "CPF") {
    do_mesmo_titular = identical(do_certificado$documento, autor$documento)
  } else {
    do_mesmo_titular = identical(do_certificado$tipo_documento, "CNPJ") &&
      identical(substr(do_certificado$documento, 1, 8), substr(autor$documento, 1, 8))
  }
  if (!do_mesmo_titular) {
    stop("O certificado (", do_certificado$documento, ") n\u00e3o \u00e9 de ", quem, " (", autor$documento,
         "): tem de ter o mesmo CNPJ-base (ou o mesmo CPF).", call. = FALSE)
  }
}

conferir_texto_do_evento = function(texto, nome, minimo, maximo) {
  if (length(texto) != 1 || is.na(texto) || !is.character(texto) || nchar(trimws(texto)) < minimo ||
      nchar(texto) > maximo || texto != trimws(texto)) {
    stop("Informe ", nome, " com ", minimo, " a ", maximo, " caracteres, sem espa\u00e7o no come\u00e7o nem no fim.",
         call. = FALSE)
  }
  # O TString dos schemas (NF-e, CT-e, MDF-e e NFS-e) só aceita do espaço (U+0020) ao U+00FF.
  if (grepl("[^\\x{20}-\\x{FF}]", enc2utf8(as.character(texto)), perl = TRUE)) {
    stop("Informe ", nome, " sem quebra de linha, tabula\u00e7\u00e3o nem caractere fora do Latin-1 (como o travess\u00e3o).",
         call. = FALSE)
  }
}

# O número do evento (nSeqEvento), inteiro, de 1 até o máximo do evento (99 nos genéricos; 20 na carta de correção e no
# ator interessado; 2 na manifestação).
conferir_sequencia_do_evento = function(sequencia, maximo = 99, de_que = "do evento") {
  numero = suppressWarnings(as.numeric(sequencia))
  if (length(numero) != 1 || is.na(numero) || numero != round(numero) || numero < 1 || numero > maximo) {
    stop("Informe a sequ\u00eancia ", de_que, ": de 1 a ", maximo, ".", call. = FALSE)
  }
  as.integer(numero)
}

# O protocolo de autorização (da nota ou de um evento): 15 algarismos, ou 17 no do PAA (o TProt do tiposBasico_v1.03
# dos pacotes 010d v1.03 e 010g).
conferir_protocolo = function(protocolo, qual) {
  if (length(protocolo) != 1 || is.na(protocolo) || !grepl("^([0-9]{15}|[0-9]{17})$", protocolo)) {
    stop("Informe ", qual, " (15 algarismos, ou 17 no do PAA).", call. = FALSE)
  }
}

# A chave do evento, limpa e conferida, com as partes dela (a UF, o modelo, a forma de emissão).
partes_da_chave_do_evento = function(chave) {
  chave_limpa = limpar_chaves(chave)
  partes = chave_decompor(chave_limpa)
  if (length(chave_limpa) != 1 || !partes$valida || !(partes$modelo %in% c("55", "65"))) {
    stop("Informe a chave de uma NF-e ou NFC-e (44 posi\u00e7\u00f5es, com o d\u00edgito certo).", call. = FALSE)
  }
  partes$chave = chave_limpa
  partes
}

# O código IBGE da UF informada pela sigla ("SP") ou pelo código ("35").
codigo_da_uf_informada = function(uf) {
  texto = toupper(trimws(as.character(uf)))
  if (length(texto) != 1 || is.na(texto)) {
    stop("Informe uma UF s\u00f3 (a sigla ou o c\u00f3digo).", call. = FALSE)
  }
  if (texto %in% UF_PELO_CODIGO) {
    return(names(UF_PELO_CODIGO)[UF_PELO_CODIGO == texto])
  }
  if (texto %in% names(UF_PELO_CODIGO)) {
    return(texto)
  }
  stop("A UF ", texto, " n\u00e3o existe (informe a sigla ou o c\u00f3digo do IBGE).", call. = FALSE)
}

# O hash do comprovante (o SHA-1, em Base64, da chave seguida da imagem em Base64, como pedem a NT 2021.001 e a NT
# 2023.005), calculado da imagem (o arquivo ou o conteúdo), ou o hash já calculado.
hash_do_comprovante = function(chave, comprovante) {
  exigir_pacotes("openssl")
  if (is.raw(comprovante)) {
    imagem = comprovante
  } else if (is.character(comprovante) && length(comprovante) == 1 && !is.na(comprovante) && file.exists(comprovante)) {
    imagem = readBin(comprovante, "raw", file.size(comprovante))
  } else if (is.character(comprovante) && length(comprovante) == 1 && !is.na(comprovante) &&
             grepl("^[A-Za-z0-9+/]{27}=$", comprovante)) {
    return(list(hash = comprovante, calculado = FALSE))
  } else {
    stop("Informe o comprovante: o caminho da imagem, o conte\u00fado dela (raw) ou o hash j\u00e1 calculado (28 caracteres ",
         "em Base64).", call. = FALSE)
  }
  if (length(imagem) == 0) {
    stop("A imagem do comprovante est\u00e1 vazia.", call. = FALSE)
  }
  imagem_em_base64 = openssl::base64_encode(imagem, linebreaks = FALSE)
  resumo = openssl::sha1(charToRaw(paste0(chave, imagem_em_base64)))
  list(hash = openssl::base64_encode(as.raw(resumo), linebreaks = FALSE), calculado = TRUE)
}

# O valor único que o schema do evento aceita num campo do detEvento (a condição de uso do ator interessado).
valor_unico_do_campo_do_evento = function(codigo_do_evento, nome_do_campo) {
  evento = EVENTOS_DA_NFE[EVENTOS_DA_NFE$codigo == codigo_do_evento, ]
  schema = schema_para_montar(PASTA_DOS_EVENTOS_DA_NFE, evento$schema)
  tipo = tipo_do_elemento(elemento_do_topo("detEvento", schema), schema)
  elementos_do_tipo(tipo, schema)$elementos[[nome_do_campo]]$unico
}

# O detEvento montado pelo schema do evento: os campos informados, a versão e, quando o schema só aceita uma, a
# descrição. Sai sem a declaração do namespace, que o infEvento em volta já tem.
detalhe_do_evento = function(codigo_do_evento, campos) {
  evento = EVENTOS_DA_NFE[EVENTOS_DA_NFE$codigo == codigo_do_evento, ]
  schema = schema_para_montar(PASTA_DOS_EVENTOS_DA_NFE, evento$schema)
  if (is.null(campos[["descEvento"]])) {
    tipo = tipo_do_elemento(elemento_do_topo("detEvento", schema), schema)
    campos = c(list(descEvento = elementos_do_tipo(tipo, schema)$elementos$descEvento$unico), campos)
  }
  montado = montar_pelo_schema(schema, "detEvento", campos)
  parar_se_o_schema_recusar(erros_do_documento_montado(montado, schema, "detEvento"))
  versao = xml2::xml_attr(xml2::read_xml(montado), "versao")
  list(xml = sub('^<detEvento xmlns="[^"]*"', "<detEvento", montado), versao = versao)
}

# A mensagem do lote (envEvento), já com o evento assinado, conferida no schema geral dos eventos.
conferir_a_mensagem_do_evento = function(mensagem) {
  arquivo_do_schema = system.file("schemas", PASTA_DOS_EVENTOS_DA_NFE, "envEvento_v1.00.xsd", package = "RNFe")
  erros = erros_no_arquivo_do_schema(xml2::read_xml(mensagem), arquivo_do_schema)
  parar_se_o_schema_recusar(gsub("\\{https?://[^}]*\\}", "", erros))
}

# O evento assinado do CT-e ou do MDF-e conferido nos schemas oficiais da pasta (inst/schemas/cte, mdfe): o do evento e o
# do detalhe, que entra no detEvento por um xs:any e é conferido à parte.
conferir_o_evento_no_schema = function(evento_assinado, pasta, arquivo_do_evento, arquivo_do_detalhe) {
  documento = xml2::read_xml(evento_assinado)
  erros = erros_no_arquivo_do_schema(documento, system.file("schemas", pasta, arquivo_do_evento, package = "RNFe"))
  detalhe = xml2::xml_find_first(documento, "//*[local-name()='detEvento']/*")
  if (inherits(detalhe, "xml_missing")) {
    erros = c(erros, "o detEvento veio vazio")
  } else {
    erros = c(erros, erros_no_arquivo_do_schema(xml2::xml_new_root(detalhe),
                                                system.file("schemas", pasta, arquivo_do_detalhe, package = "RNFe")))
  }
  parar_se_o_schema_recusar(gsub("\\{https?://[^}]*\\}", "", erros))
}

# Monta o evento, assina, manda e lê a resposta. `autor` diz quem registra: o emitente da chave, o destinatário (o
# informado ou o do certificado) ou outro (o transportador do ator interessado, também o informado ou o do
# certificado). No EPEC, a resposta traz as chaves pendentes quando o EPEC está bloqueado para o emitente.
registrar_evento = function(chave, codigo_do_evento, sequencia, campos, certificado, senha, ambiente, autor = "emitente",
                            documento_do_autor = NULL, com_pendentes = FALSE) {
  exigir_pacotes(c("httr2", "curl", "openssl"))
  montado = montar_o_evento(chave, codigo_do_evento, sequencia, campos, certificado, senha, ambiente, autor,
                            documento_do_autor)
  if (com_pendentes) {
    montado$linha$chaves_pendentes = NA_character_
  }
  if (is.null(montado$pedido)) {
    return(montado$linha)
  }
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  resposta = enviar_pedidos(list(montado$pedido), conexao)[[1]]
  linha = completar_evento(montado$linha, ler_resposta(resposta, "retEnvEvento"), montado$evento_assinado, ambiente,
                           com_pendentes)
  attr(linha$registro, "tzone") = "America/Sao_Paulo"
  linha
}

# A linha do evento, o evento assinado e o pedido (o lote com ele), sem mandar nada. O órgão é a UF da chave ou o de
# quem recebe o evento fora dela (o Ambiente Nacional, a SVRS).
montar_o_evento = function(chave, codigo_do_evento, sequencia, campos, certificado, senha, ambiente, autor = "emitente",
                           documento_do_autor = NULL) {
  partes = partes_da_chave_do_evento(chave)
  evento = EVENTOS_DA_NFE[EVENTOS_DA_NFE$codigo == codigo_do_evento, ]
  modelos_do_evento = strsplit(evento$modelos, " ", fixed = TRUE)[[1]]
  if (!(partes$modelo %in% modelos_do_evento)) {
    stop("S\u00f3 a NF-e (modelo 55) tem ", evento$nome, ".", call. = FALSE)
  }
  conferir_certificado(certificado, senha)
  if (autor == "emitente") {
    autor_do_evento = autor_do_emitente(partes, SERIES_DO_CPF_NA_NFE, certificado, senha)
  } else if (autor == "destinatario") {
    autor_do_evento = autor_informado_ou_do_certificado(documento_do_autor, certificado, senha, "destinat\u00e1rio")
  } else {
    autor_do_evento = autor_informado_ou_do_certificado(documento_do_autor, certificado, senha, "transportador")
  }
  detalhe = detalhe_do_evento(codigo_do_evento, campos)
  linha = data.frame(
    chave = partes$chave, evento = codigo_do_evento, sequencia = sequencia, ambiente = ambiente,
    situacao_lote = NA_integer_, motivo_lote = NA_character_, situacao = NA_integer_, motivo = NA_character_,
    protocolo = NA_character_, registro = as.POSIXct(NA), xml_evento = NA_character_, endereco = NA_character_,
    problema = NA_character_
  )
  documento = if (partes$modelo == "65") "NFC-e" else "NF-e"
  if (evento$recebe == "UF") {
    orgao = partes$codigo_uf
    servico = servico_da_uf(partes$uf, "RecepcaoEvento", ambiente, documento)
  } else {
    orgao = ORGAO_DE_QUEM_RECEBE[[evento$recebe]]
    servico = servico_do_autorizador(evento$recebe, "RecepcaoEvento", ambiente)
  }
  if (is.null(servico)) {
    linha$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz o servi\u00e7o de eventos para a UF"
    return(list(linha = linha, pedido = NULL))
  }
  linha$endereco = servico$endereco
  campo_do_autor = if (autor_do_evento$tipo_documento == "CPF") "CPF" else "CNPJ"
  identificador = paste0("ID", codigo_do_evento, partes$chave, sprintf("%02d", sequencia))
  evento_montado = paste0(
    '<evento xmlns="', NAMESPACE_DA_NFE, '" versao="1.00"><infEvento Id="', identificador, '"><cOrgao>', orgao,
    "</cOrgao><tpAmb>", AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb><", campo_do_autor, ">", autor_do_evento$documento, "</",
    campo_do_autor, "><chNFe>", partes$chave, "</chNFe><dhEvento>", data_hora_do_evento(Sys.time()),
    "</dhEvento><tpEvento>", codigo_do_evento, "</tpEvento><nSeqEvento>", sequencia, "</nSeqEvento><verEvento>",
    detalhe$versao, "</verEvento>", detalhe$xml, "</infEvento></evento>"
  )
  evento_assinado = sub("^<\\?xml[^>]*\\?>\\s*", "", xml_assinar(evento_montado, certificado, senha))
  numero_do_lote = substr(format(floor(as.numeric(Sys.time()) * 1000), scientific = FALSE), 1, 15)
  mensagem = paste0('<envEvento xmlns="', NAMESPACE_DA_NFE, '" versao="1.00"><idLote>', numero_do_lote, "</idLote>",
                    evento_assinado, "</envEvento>")
  conferir_a_mensagem_do_evento(mensagem)
  list(linha = linha, evento_assinado = evento_assinado,
       pedido = montar_pedido(servico$endereco, "NFeRecepcaoEvento4", "nfeRecepcaoEvento", mensagem))
}

# O endereço de um serviço de um autorizador que não depende da UF (o Ambiente Nacional, a SVRS).
servico_do_autorizador = function(autorizador, servico, ambiente) {
  servicos = tabela_interna("servicos_sefaz")
  do_autorizador = servicos[servicos$documento == "NF-e" & servicos$ambiente == ambiente &
                              servicos$autorizador == autorizador & servicos$servico == servico, ]
  if (nrow(do_autorizador) == 0) {
    return(NULL)
  }
  list(autorizador = autorizador, endereco = do_autorizador$endereco[1])
}

# O instante no formato do leiaute (AAAA-MM-DDThh:mm:ssTZD), no horário de Brasília.
data_hora_do_evento = function(instante) {
  paste0(format(instante, "%Y-%m-%dT%H:%M:%S", tz = "America/Sao_Paulo"), "-03:00")
}

PROBLEMA_DO_RETORNO_DE_OUTRO_EVENTO = "a SEFAZ respondeu sobre outro evento (o tipo ou a sequ\u00eancia n\u00e3o s\u00e3o os enviados)"

# O retorno do evento (NF-e, CT-e, MDF-e) traz o tipo e a sequência quando registra (no rejeitado, podem faltar):
# diferentes dos da linha, a resposta é de outro evento.
retorno_de_outro_evento = function(informacao, linha) {
  tipo_do_retorno = texto_do_retorno(informacao, "tpEvento")
  sequencia_do_retorno = suppressWarnings(as.integer(texto_do_retorno(informacao, "nSeqEvento")))
  (!is.na(tipo_do_retorno) && !identical(tipo_do_retorno, as.character(linha$evento))) ||
    (!is.na(sequencia_do_retorno) && !identical(sequencia_do_retorno, as.integer(linha$sequencia)))
}

# O retorno do lote de eventos: a situação do lote e a do evento; o evento registrado ganha o procEventoNFe (o evento
# como foi enviado e o retorno da SEFAZ). No EPEC, as chaves pendentes que a SEFAZ devolve (chNFePend).
completar_evento = function(linha, resposta_lida, evento_assinado, ambiente, com_pendentes = FALSE) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  retorno = resposta_lida$retorno
  if (!identical(texto_do_retorno(retorno, "tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a SEFAZ respondeu de outro ambiente"
    return(linha)
  }
  linha$situacao_lote = as.integer(texto_do_retorno(retorno, "cStat"))
  linha$motivo_lote = texto_do_retorno(retorno, "xMotivo")
  retorno_do_evento = xml2::xml_find_first(retorno, "./*[local-name()='retEvento']")
  if (inherits(retorno_do_evento, "xml_missing")) {
    return(linha)
  }
  informacao = xml2::xml_find_first(retorno_do_evento, "./*[local-name()='infEvento']")
  chave_do_retorno = texto_do_retorno(informacao, "chNFe")
  if (!is.na(chave_do_retorno) && !identical(chave_do_retorno, linha$chave)) {
    linha$problema = "a SEFAZ respondeu sobre outra chave"
    return(linha)
  }
  if (retorno_de_outro_evento(informacao, linha)) {
    linha$problema = PROBLEMA_DO_RETORNO_DE_OUTRO_EVENTO
    return(linha)
  }
  linha$situacao = as.integer(texto_do_retorno(informacao, "cStat"))
  linha$motivo = texto_do_retorno(informacao, "xMotivo")
  linha$protocolo = texto_do_retorno(informacao, "nProt")
  linha$registro = data_hora_da_consulta(texto_do_retorno(informacao, "dhRegEvento"))
  if (com_pendentes) {
    pendentes = xml2::xml_text(xml2::xml_find_all(informacao, "./*[local-name()='chNFePend']"))
    if (length(pendentes) > 0) {
      linha$chaves_pendentes = paste(pendentes, collapse = " ")
    }
  }
  if (linha$situacao %in% SITUACOES_DO_EVENTO_REGISTRADO) {
    texto_do_retorno_do_evento = trimws(as.character(xml2::xml_new_root(retorno_do_evento), options = "no_declaration"))
    linha$xml_evento = paste0('<?xml version="1.0" encoding="UTF-8"?><procEventoNFe xmlns="', NAMESPACE_DA_NFE,
                              '" versao="1.00">', evento_assinado, texto_do_retorno_do_evento, "</procEventoNFe>")
  }
  linha
}
