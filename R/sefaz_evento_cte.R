# Os eventos do tomador do CT-e (CTeRecepcaoEventoV4): a prestação do serviço em desacordo (610110) e o cancelamento
# dela (610111). Pelo MOC do CT-e 4.00, o evento vai sozinho (sem lote e sem compactação) ao autorizador do CT-e, e o
# retorno é o retEventoCTe. Só o ambiente de homologação.

#' @include sefaz.R assinatura.R sefaz_evento.R
NULL

NAMESPACE_DO_CTE = "http://www.portalfiscal.inf.br/cte"

#' Registrar a prestação do serviço em desacordo (CT-e)
#'
#' O tomador do serviço informa ao Fisco que o CT-e (ou o CT-e OS) que o cita
#' está em desacordo com o serviço prestado (o evento 610110). O prazo é de 45
#' dias da autorização do CT-e. `sefaz_cte_cancelar_desacordo()` cancela o
#' evento registrado por engano (o 610111).
#'
#' O evento é assinado com o certificado, que tem de ser o do tomador do
#' serviço do CT-e. Por enquanto só o ambiente de **homologação**.
#'
#' @param chave A chave de acesso do CT-e (modelo 57) ou do CT-e OS (67).
#' @param observacao O motivo do desacordo, de 15 a 255 caracteres.
#' @param sequencia O número do evento para o CT-e: 1 no primeiro (até 20).
#' @inheritParams sefaz_cancelar
#' @return Um `data.frame` com uma linha, como o de [sefaz_cancelar()]: a
#'   situação 135 é o evento registrado, e `xml_evento` traz o
#'   `procEventoCTe`, que o [eventos_ler()] lê.
#' @seealso [sefaz_situacao()] para ver os eventos do CT-e.
#' @source Manual de Orientação do Contribuinte do CT-e 4.00, on-line (Recepção
#'   de Evento: Parte Geral e Eventos Específicos, item 5); os schemas
#'   `eventoCTe_v4.00.xsd`, `evPrestDesacordo_v4.00.xsd` e
#'   `evCancPrestDesacordo_v4.00.xsd` (pacote PL_CTe_400).
#' @examples
#' \dontrun{
#' sefaz_cte_desacordo("35261012ABC34501DE35570010000005551876543210",
#'                     "FRETE COBRADO EM DUPLICIDADE NA MESMA VIAGEM", "empresa.pfx",
#'                     Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_cte_desacordo = function(chave, observacao, certificado, senha, sequencia = 1, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_texto_do_evento(observacao, "observacao", 15, 255)
  detalhe = paste0("<evPrestDesacordo><descEvento>Prestacao do Servico em Desacordo</descEvento>",
                   "<indDesacordoOper>1</indDesacordoOper><xObs>", escapar_texto_canonico(observacao),
                   "</xObs></evPrestDesacordo>")
  registrar_evento_do_cte(chave, "610110", sequencia, detalhe, certificado, senha, ambiente)
}

#' @rdname sefaz_cte_desacordo
#' @param protocolo_do_desacordo O protocolo do evento de desacordo que vai ser
#'   cancelado (15 algarismos).
#' @export
sefaz_cte_cancelar_desacordo = function(chave, protocolo_do_desacordo, certificado, senha, sequencia = 1,
                                        ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  if (length(protocolo_do_desacordo) != 1 || is.na(protocolo_do_desacordo) ||
      !grepl("^[0-9]{15}$", protocolo_do_desacordo)) {
    stop("Informe o protocolo do evento de desacordo (15 algarismos).", call. = FALSE)
  }
  detalhe = paste0("<evCancPrestDesacordo><descEvento>Cancelamento Prestacao do Servico em Desacordo</descEvento>",
                   "<nProtEvPrestDes>", protocolo_do_desacordo, "</nProtEvPrestDes></evCancPrestDesacordo>")
  registrar_evento_do_cte(chave, "610111", sequencia, detalhe, certificado, senha, ambiente)
}

registrar_evento_do_cte = function(chave, codigo_do_evento, sequencia, detalhe, certificado, senha, ambiente) {
  exigir_pacotes(c("httr2", "curl", "openssl"))
  sequencia = suppressWarnings(as.integer(sequencia))
  if (length(sequencia) != 1 || is.na(sequencia) || sequencia < 1 || sequencia > 20) {
    stop("Informe a sequ\u00eancia do evento: de 1 a 20.", call. = FALSE)
  }
  montado = montar_o_evento_do_cte(chave, codigo_do_evento, sequencia, detalhe, certificado, senha, ambiente)
  if (is.null(montado$pedido)) {
    return(montado$linha)
  }
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  resposta = enviar_pedidos(list(montado$pedido), conexao)[[1]]
  linha = completar_evento_do_cte(montado$linha, ler_resposta(resposta, "retEventoCTe"), montado$evento_assinado, ambiente)
  attr(linha$registro, "tzone") = "America/Sao_Paulo"
  linha
}

# A linha do evento, o evento assinado e o pedido, sem mandar nada. O autor é o CNPJ (ou CPF) do certificado; o órgão,
# a UF da chave, cujo autorizador recebe o evento.
montar_o_evento_do_cte = function(chave, codigo_do_evento, sequencia, detalhe, certificado, senha, ambiente) {
  chave_limpa = limpar_chaves(chave)
  partes = chave_decompor(chave_limpa)
  if (length(chave_limpa) != 1 || !partes$valida || !(partes$modelo %in% c("57", "67"))) {
    stop("Informe a chave de um CT-e ou CT-e OS (44 posi\u00e7\u00f5es, com o d\u00edgito certo).", call. = FALSE)
  }
  conferir_certificado(certificado, senha)
  autor = certificado_ler(certificado, senha)
  linha = data.frame(
    chave = chave_limpa, evento = codigo_do_evento, sequencia = sequencia, ambiente = ambiente,
    situacao_lote = NA_integer_, motivo_lote = NA_character_, situacao = NA_integer_, motivo = NA_character_,
    protocolo = NA_character_, registro = as.POSIXct(NA), xml_evento = NA_character_, endereco = NA_character_,
    problema = NA_character_
  )
  servico = servico_da_uf(partes$uf, "CteRecepcaoEventoV4", ambiente, "CT-e")
  if (is.null(servico)) {
    linha$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz o servi\u00e7o de eventos do CT-e para a UF"
    return(list(linha = linha, pedido = NULL))
  }
  linha$endereco = servico$endereco
  campo_do_autor = if (autor$tipo_documento %in% "CPF") "CPF" else "CNPJ"
  identificador = paste0("ID", codigo_do_evento, chave_limpa, sprintf("%03d", sequencia))
  evento = paste0(
    '<eventoCTe xmlns="', NAMESPACE_DO_CTE, '" versao="4.00"><infEvento Id="', identificador, '"><cOrgao>',
    partes$codigo_uf, "</cOrgao><tpAmb>", AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb><", campo_do_autor, ">",
    autor$documento, "</", campo_do_autor, "><chCTe>", chave_limpa, "</chCTe><dhEvento>", data_hora_do_evento(Sys.time()),
    "</dhEvento><tpEvento>", codigo_do_evento, "</tpEvento><nSeqEvento>", sequencia,
    '</nSeqEvento><detEvento versaoEvento="4.00">', detalhe, "</detEvento></infEvento></eventoCTe>"
  )
  evento_assinado = sub("^<\\?xml[^>]*\\?>\\s*", "", xml_assinar(evento, certificado, senha))
  list(linha = linha, evento_assinado = evento_assinado,
       pedido = montar_pedido(servico$endereco, "CTeRecepcaoEventoV4", "cteRecepcaoEvento", evento_assinado,
                              familia = "cte"))
}

# O retorno do evento (sem lote: a situação vem só no infEvento); o evento registrado ganha o procEventoCTe.
completar_evento_do_cte = function(linha, resposta_lida, evento_assinado, ambiente) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  retorno = resposta_lida$retorno
  informacao = xml2::xml_find_first(retorno, "./*[local-name()='infEvento']")
  if (!identical(texto_do_retorno(informacao, "tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a SEFAZ respondeu de outro ambiente"
    return(linha)
  }
  chave_do_retorno = texto_do_retorno(informacao, "chCTe")
  if (!is.na(chave_do_retorno) && !identical(chave_do_retorno, linha$chave)) {
    linha$problema = "a SEFAZ respondeu sobre outra chave"
    return(linha)
  }
  linha$situacao = as.integer(texto_do_retorno(informacao, "cStat"))
  linha$motivo = texto_do_retorno(informacao, "xMotivo")
  linha$protocolo = texto_do_retorno(informacao, "nProt")
  linha$registro = data_hora_da_consulta(texto_do_retorno(informacao, "dhRegEvento"))
  if (linha$situacao %in% SITUACOES_DO_EVENTO_REGISTRADO) {
    texto_do_retorno_do_evento = trimws(as.character(xml2::xml_new_root(retorno), options = "no_declaration"))
    linha$xml_evento = paste0('<?xml version="1.0" encoding="UTF-8"?><procEventoCTe xmlns="', NAMESPACE_DO_CTE,
                              '" versao="4.00">', evento_assinado, texto_do_retorno_do_evento, "</procEventoCTe>")
  }
  linha
}
