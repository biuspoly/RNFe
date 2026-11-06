# Os eventos da NF-e e da NFC-e que o emitente e o destinatário registram (RecepcaoEvento4): o cancelamento e a carta
# de correção, no autorizador da UF da nota, e a manifestação do destinatário, no Ambiente Nacional. Cada evento é
# montado, assinado com o certificado de quem o registra e enviado num lote só dele. Só o ambiente de homologação.

#' @include sefaz.R assinatura.R sefaz_autorizar.R
NULL

# O texto da condição de uso da carta de correção, fixo no schema (e110110_v1.00.xsd).
CONDICAO_DE_USO_DA_CARTA_DE_CORRECAO = paste(
  "A Carta de Correcao e disciplinada pelo paragrafo 1o-A do art. 7o do Convenio S/N, de 15 de dezembro de 1970 e pode",
  "ser utilizada para regularizacao de erro ocorrido na emissao de documento fiscal, desde que o erro nao esteja",
  "relacionado com: I - as variaveis que determinam o valor do imposto tais como: base de calculo, aliquota, diferenca de",
  "preco, quantidade, valor da operacao ou da prestacao; II - a correcao de dados cadastrais que implique mudanca do",
  "remetente ou do destinatario; III - a data de emissao ou de saida."
)
# Os tipos de manifestação do destinatário, com o código do evento e a descrição que o schema pede.
TIPOS_DE_MANIFESTACAO = utils::read.table(header = TRUE, sep = ";", strip.white = TRUE, stringsAsFactors = FALSE, text = "
tipo            ; codigo ; descricao
confirmacao     ; 210200 ; Confirmacao da Operacao
ciencia         ; 210210 ; Ciencia da Operacao
desconhecimento ; 210220 ; Desconhecimento da Operacao
nao_realizada   ; 210240 ; Operacao nao Realizada
", colClasses = "character")
# As situações do evento registrado: 135 (registrado e vinculado à nota), 136 (registrado sem vínculo) e 155
# (cancelamento homologado fora de prazo).
SITUACOES_DO_EVENTO_REGISTRADO = c(135L, 136L, 155L)

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
#' ser cancelada com o certificado da matriz. Por enquanto só o ambiente de
#' **homologação**.
#'
#' @param chave A chave de acesso da nota (44 posições).
#' @param protocolo O número do protocolo de autorização da nota.
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
#'   o cancelamento); os schemas `envEvento`, `retEnvEvento` e `procEventoNFe`
#'   do evento de cancelamento (`e110111_v1.00.xsd`); o WSDL do
#'   NFeRecepcaoEvento4 (operação `nfeRecepcaoEvento`).
#' @examples
#' \dontrun{
#' sefaz_cancelar("35261011222333000181550010000010011123456785", "135260000012345",
#'                "PEDIDO CANCELADO PELO CLIENTE", "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_cancelar = function(chave, protocolo, justificativa, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_texto_do_evento(justificativa, "justificativa", 15, 255)
  if (length(protocolo) != 1 || is.na(protocolo) || !grepl("^[0-9]{15}$", protocolo)) {
    stop("Informe o protocolo de autoriza\u00e7\u00e3o da nota (15 algarismos).", call. = FALSE)
  }
  detalhe = paste0("<descEvento>Cancelamento</descEvento><nProt>", protocolo, "</nProt><xJust>",
                   escapar_texto_canonico(justificativa), "</xJust>")
  registrar_evento(chave, "110111", 1L, detalhe, certificado, senha, ambiente, no_ambiente_nacional = FALSE)
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
  sequencia = suppressWarnings(as.integer(sequencia))
  if (length(sequencia) != 1 || is.na(sequencia) || sequencia < 1 || sequencia > 20) {
    stop("Informe a sequ\u00eancia da carta de corre\u00e7\u00e3o: de 1 a 20.", call. = FALSE)
  }
  if (!identical(chave_decompor(chave)$modelo, "55")) {
    stop("S\u00f3 a NF-e (modelo 55) tem carta de corre\u00e7\u00e3o.", call. = FALSE)
  }
  detalhe = paste0("<descEvento>Carta de Correcao</descEvento><xCorrecao>", escapar_texto_canonico(correcao),
                   "</xCorrecao><xCondUso>", CONDICAO_DE_USO_DA_CARTA_DE_CORRECAO, "</xCondUso>")
  registrar_evento(chave, "110110", sequencia, detalhe, certificado, senha, ambiente, no_ambiente_nacional = FALSE)
}

#' Manifestar o destinatário sobre uma NF-e
#'
#' Registra no Ambiente Nacional a manifestação do destinatário sobre uma NF-e
#' emitida contra ele: a ciência da operação (`"ciencia"`, que libera o XML
#' completo na Distribuição de DF-e), a confirmação (`"confirmacao"`), o
#' desconhecimento (`"desconhecimento"`) ou a operação não realizada
#' (`"nao_realizada"`, que pede a justificativa).
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
#' @inheritParams sefaz_cancelar
#' @inherit sefaz_cancelar return
#' @seealso [sefaz_distribuicao()], que traz o XML completo depois da ciência.
#' @source Manual de Orientação do Contribuinte da NF-e e a NT 2012.002
#'   (a manifestação do destinatário, eventos 210200, 210210, 210220 e 210240,
#'   no Ambiente Nacional, órgão 91).
#' @examples
#' \dontrun{
#' sefaz_manifestar("35261011222333000181550010000010011123456785", "ciencia",
#'                  certificado = "empresa.pfx", senha = Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_manifestar = function(chave, tipo, justificativa = NULL, certificado, senha, ambiente = "homologacao",
                            destinatario = NULL) {
  conferir_ambiente(ambiente)
  if (length(tipo) != 1 || !(tipo %in% TIPOS_DE_MANIFESTACAO$tipo)) {
    stop("Informe o tipo: ", paste0("\"", TIPOS_DE_MANIFESTACAO$tipo, "\"", collapse = ", "), ".", call. = FALSE)
  }
  manifestacao = TIPOS_DE_MANIFESTACAO[TIPOS_DE_MANIFESTACAO$tipo == tipo, ]
  detalhe = paste0("<descEvento>", manifestacao$descricao, "</descEvento>")
  if (tipo == "nao_realizada") {
    conferir_texto_do_evento(justificativa, "justificativa", 15, 255)
    detalhe = paste0(detalhe, "<xJust>", escapar_texto_canonico(justificativa), "</xJust>")
  }
  registrar_evento(chave, manifestacao$codigo, 1L, detalhe, certificado, senha, ambiente, no_ambiente_nacional = TRUE,
                   destinatario = destinatario)
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

# O autor informado (o destinatário da NF-e ou o tomador do CT-e, quando é uma filial e o certificado é o da matriz) ou,
# sem ele, o do certificado.
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
  if (length(texto) != 1 || is.na(texto) || nchar(trimws(texto)) < minimo || nchar(texto) > maximo ||
      texto != trimws(texto)) {
    stop("Informe ", nome, " com ", minimo, " a ", maximo, " caracteres, sem espa\u00e7o no come\u00e7o nem no fim.",
         call. = FALSE)
  }
}

# Monta o evento, assina, manda e lê a resposta. O autor é o emitente da chave ou, na manifestação, o destinatário (o
# informado ou o do certificado); o órgão é a UF da chave ou, na manifestação, o Ambiente Nacional (91).
registrar_evento = function(chave, codigo_do_evento, sequencia, detalhe, certificado, senha, ambiente,
                            no_ambiente_nacional, destinatario = NULL) {
  exigir_pacotes(c("httr2", "curl", "openssl"))
  montado = montar_o_evento(chave, codigo_do_evento, sequencia, detalhe, certificado, senha, ambiente,
                            no_ambiente_nacional, destinatario)
  if (is.null(montado$pedido)) {
    return(montado$linha)
  }
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  resposta = enviar_pedidos(list(montado$pedido), conexao)[[1]]
  linha = completar_evento(montado$linha, ler_resposta(resposta, "retEnvEvento"), montado$evento_assinado, ambiente)
  attr(linha$registro, "tzone") = "America/Sao_Paulo"
  linha
}

# A linha do evento, o evento assinado e o pedido (o lote com ele), sem mandar nada.
montar_o_evento = function(chave, codigo_do_evento, sequencia, detalhe, certificado, senha, ambiente,
                           no_ambiente_nacional, destinatario = NULL) {
  chave_limpa = limpar_chaves(chave)
  partes = chave_decompor(chave_limpa)
  if (length(chave_limpa) != 1 || !partes$valida || !(partes$modelo %in% c("55", "65"))) {
    stop("Informe a chave de uma NF-e ou NFC-e (44 posi\u00e7\u00f5es, com o d\u00edgito certo).", call. = FALSE)
  }
  conferir_certificado(certificado, senha)
  if (no_ambiente_nacional) {
    autor = autor_informado_ou_do_certificado(destinatario, certificado, senha, "destinat\u00e1rio")
  } else {
    autor = autor_do_emitente(partes, SERIES_DO_CPF_NA_NFE, certificado, senha)
  }
  linha = data.frame(
    chave = chave_limpa, evento = codigo_do_evento, sequencia = sequencia, ambiente = ambiente,
    situacao_lote = NA_integer_, motivo_lote = NA_character_, situacao = NA_integer_, motivo = NA_character_,
    protocolo = NA_character_, registro = as.POSIXct(NA), xml_evento = NA_character_, endereco = NA_character_,
    problema = NA_character_
  )
  documento = if (partes$modelo == "65") "NFC-e" else "NF-e"
  if (no_ambiente_nacional) {
    orgao = "91"
    servico = servico_do_ambiente_nacional("RecepcaoEvento", ambiente)
  } else {
    orgao = partes$codigo_uf
    servico = servico_da_uf(partes$uf, "RecepcaoEvento", ambiente, documento)
  }
  if (is.null(servico)) {
    linha$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz o servi\u00e7o de eventos para a UF"
    return(list(linha = linha, pedido = NULL))
  }
  linha$endereco = servico$endereco
  campo_do_autor = if (autor$tipo_documento == "CPF") "CPF" else "CNPJ"
  identificador = paste0("ID", codigo_do_evento, chave_limpa, sprintf("%02d", sequencia))
  evento = paste0(
    '<evento xmlns="', NAMESPACE_DA_NFE, '" versao="1.00"><infEvento Id="', identificador, '"><cOrgao>', orgao,
    "</cOrgao><tpAmb>", AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb><", campo_do_autor, ">", autor$documento, "</",
    campo_do_autor, "><chNFe>", chave_limpa, "</chNFe><dhEvento>", data_hora_do_evento(Sys.time()),
    "</dhEvento><tpEvento>", codigo_do_evento, "</tpEvento><nSeqEvento>", sequencia,
    '</nSeqEvento><verEvento>1.00</verEvento><detEvento versao="1.00">', detalhe, "</detEvento></infEvento></evento>"
  )
  evento_assinado = sub("^<\\?xml[^>]*\\?>\\s*", "", xml_assinar(evento, certificado, senha))
  numero_do_lote = substr(format(floor(as.numeric(Sys.time()) * 1000), scientific = FALSE), 1, 15)
  mensagem = paste0('<envEvento xmlns="', NAMESPACE_DA_NFE, '" versao="1.00"><idLote>', numero_do_lote, "</idLote>",
                    evento_assinado, "</envEvento>")
  list(linha = linha, evento_assinado = evento_assinado,
       pedido = montar_pedido(servico$endereco, "NFeRecepcaoEvento4", "nfeRecepcaoEvento", mensagem))
}

# O endereço de um serviço do Ambiente Nacional (a manifestação do destinatário), que não depende da UF.
servico_do_ambiente_nacional = function(servico, ambiente) {
  servicos = tabela_interna("servicos_sefaz")
  do_ambiente_nacional = servicos[servicos$documento == "NF-e" & servicos$ambiente == ambiente &
                                    servicos$autorizador == "AN" & servicos$servico == servico, ]
  if (nrow(do_ambiente_nacional) == 0) {
    return(NULL)
  }
  list(autorizador = "AN", endereco = do_ambiente_nacional$endereco[1])
}

# O instante no formato do leiaute (AAAA-MM-DDThh:mm:ssTZD), no horário de Brasília.
data_hora_do_evento = function(instante) {
  paste0(format(instante, "%Y-%m-%dT%H:%M:%S", tz = "America/Sao_Paulo"), "-03:00")
}

# O retorno do lote de eventos: a situação do lote e a do evento; o evento registrado ganha o procEventoNFe (o evento
# como foi enviado e o retorno da SEFAZ).
completar_evento = function(linha, resposta_lida, evento_assinado, ambiente) {
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
  linha$situacao = as.integer(texto_do_retorno(informacao, "cStat"))
  linha$motivo = texto_do_retorno(informacao, "xMotivo")
  linha$protocolo = texto_do_retorno(informacao, "nProt")
  linha$registro = data_hora_da_consulta(texto_do_retorno(informacao, "dhRegEvento"))
  if (linha$situacao %in% SITUACOES_DO_EVENTO_REGISTRADO) {
    texto_do_retorno_do_evento = trimws(as.character(xml2::xml_new_root(retorno_do_evento), options = "no_declaration"))
    linha$xml_evento = paste0('<?xml version="1.0" encoding="UTF-8"?><procEventoNFe xmlns="', NAMESPACE_DA_NFE,
                              '" versao="1.00">', evento_assinado, texto_do_retorno_do_evento, "</procEventoNFe>")
  }
  linha
}
