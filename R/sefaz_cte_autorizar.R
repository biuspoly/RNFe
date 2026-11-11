# A autorização do CT-e, do CT-e OS, da GTV-e e do CT-e simplificado. Pelo MOC do CT-e 4.00: a recepção é síncrona,
# sem lote, com o documento compactado em gzip dentro do base64 e sem o cabeçalho SOAP (que a 4.00 tirou); cada
# documento tem o seu serviço, e o retorno traz o protocolo. O QR-Code (infCTeSupl) entra quando falta. Só o ambiente
# de homologação.

#' @include sefaz.R assinatura.R nfse_emitir.R sefaz_mdfe.R sefaz_evento_cte.R
NULL

# O serviço de recepção de cada documento: o nome na Relação de Serviços Web, a operação do WSDL (conferida nos WSDLs
# da SVRS de homologação em 11/11/2026), o retorno e o elemento do documento autorizado (os schemas proc*_v4.00.xsd).
RECEPCAO_DE_CADA_DOCUMENTO_DO_CTE = utils::read.table(header = TRUE, sep = ";", strip.white = TRUE, stringsAsFactors = FALSE,
                                                      colClasses = "character", text = "
raiz    ; modelo ; documento         ; servico           ; operacao        ; retorno    ; processado
CTe     ; 57     ; CT-e              ; CTeRecepcaoSincV4 ; cteRecepcao     ; retCTe     ; cteProc
CTeOS   ; 67     ; CT-e OS           ; CTeRecepcaoOSV4   ; cteRecepcaoOS   ; retCTeOS   ; cteOSProc
GTVe    ; 64     ; GTV-e             ; CTeRecepcaoGTVeV4 ; cteRecepcaoGTVe ; retGTVe    ; GTVeProc
CTeSimp ; 57     ; CT-e simplificado ; CTeRecepcaoSimpV4 ; cteRecepcaoSimp ; retCTeSimp ; cteSimpProc
")
# A situação do CT-e autorizado (o CT-e 4.00 acabou com a denegação).
SITUACOES_DO_CTE_AUTORIZADO = c(100L)
# As formas de emissão cujo QR-Code leva o parâmetro sign (a chave assinada): a contingência off-line (2) e o EPEC (4),
# pelas regras G215 e G217 (CT-e e CT-e simplificado) e H131 e H133 (CT-e OS) da NT 2026.004 v1.01 do CT-e. A NT não
# fala da GTV-e: nela, fora da emissão normal, o QR-Code tem de vir pronto.
FORMAS_DE_EMISSAO_COM_A_CHAVE_ASSINADA_NO_QRCODE = c("2", "4")
DOCUMENTOS_COM_A_REGRA_DO_SIGN = c("CTe", "CTeOS", "CTeSimp")
# A autorização pela SVC (tpEmis 7, SVC-RS; 8, SVC-SP) vai a outro autorizador, que o RNFe ainda não usa.
FORMAS_DE_EMISSAO_PELA_SVC_DO_CTE = c("7", "8")

#' Autorizar um CT-e, CT-e OS, GTV-e ou CT-e simplificado
#'
#' Manda o documento assinado ao autorizador da UF dele, que o autoriza na
#' hora (a recepção do CT-e 4.00 é síncrona, sem lote). Ele vai compactado,
#' como o manual pede, pelo serviço de cada documento (o do CT-e, o do CT-e OS,
#' o da GTV-e ou o do CT-e simplificado). O autorizado volta no `cteProc`
#' (`cteOSProc`, `GTVeProc`, `cteSimpProc`): o documento e o protocolo, que o
#' [cte_ler()] lê (a GTV-e, o [gtve_ler()]; o CT-e simplificado, o
#' [cte_simplificado_ler()]).
#'
#' O QR-Code (`infCTeSupl`) entra sozinho quando falta: o endereço de consulta
#' do autorizador da UF (da Relação de Serviços Web do CT-e), a chave e o
#' ambiente; na contingência off-line e no EPEC do CT-e, do CT-e OS e do CT-e
#' simplificado, também a chave assinada com o certificado (o parâmetro
#' `sign`). Na GTV-e fora da emissão normal, cuja regra a NT não traz, o
#' QR-Code tem de vir pronto. Ele fica fora do que a assinatura cobre. O
#' documento autorizado pela SVC (`tpEmis` 7 ou 8) não é enviado: a SVC fica
#' para depois.
#'
#' Assine antes com [xml_assinar()]. Por enquanto só o ambiente de
#' **homologação**: o documento com o `tpAmb` 1 nem é enviado.
#'
#' @param xml O CT-e assinado: o caminho do arquivo ou o texto do XML.
#' @inheritParams sefaz_status
#' @return Um `data.frame` com uma linha: `chave`, `documento`, `ambiente`,
#'   `situacao_envio` e `motivo_envio` (o retorno do envio), `situacao` (100
#'   autorizado; as outras são rejeição), `motivo`, `protocolo`, `autorizacao`
#'   (data e hora), `xml_autorizado`, `endereco` e `problema`.
#' @seealso [cte_montar()], [xml_assinar()], [sefaz_situacao()],
#'   [sefaz_cte_desacordo()]
#' @source Manual de Orientação do Contribuinte do CT-e 4.00 (itens 4.2 a 4.5,
#'   a recepção síncrona, e 9.2, o QR-Code), a NT 2026.004 v1.01 do CT-e (a
#'   contingência off-line e as regras G215 e G217 do parâmetro sign), os
#'   WSDLs da recepção e os schemas `retCTe_v4.00.xsd`, `procCTe_v4.00.xsd` e
#'   os do CT-e OS, da GTV-e e do CT-e simplificado.
#' @examples
#' \dontrun{
#' assinado = xml_assinar(cte_montar(cte), "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' autorizado = sefaz_cte_autorizar(assinado, "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' autorizado[, c("chave", "situacao", "motivo", "protocolo")]
#' }
#' @export
sefaz_cte_autorizar = function(xml, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  exigir_pacotes(c("httr2", "curl", "openssl"))
  conferir_certificado(certificado, senha)
  lido = ler_o_cte_para_autorizar(xml, ambiente, certificado, senha)
  recepcao = RECEPCAO_DE_CADA_DOCUMENTO_DO_CTE[RECEPCAO_DE_CADA_DOCUMENTO_DO_CTE$raiz == lido$raiz, ]
  linha = data.frame(
    chave = lido$chave, documento = recepcao$documento, ambiente = ambiente, situacao_envio = NA_integer_,
    motivo_envio = NA_character_, situacao = NA_integer_, motivo = NA_character_, protocolo = NA_character_,
    autorizacao = as.POSIXct(NA), xml_autorizado = NA_character_, endereco = NA_character_, problema = NA_character_
  )
  if (lido$forma_de_emissao %in% FORMAS_DE_EMISSAO_PELA_SVC_DO_CTE) {
    linha$problema = "o documento em conting\u00eancia SVC (tpEmis 7 ou 8) vai para a SVC, que o RNFe ainda n\u00e3o usa"
    return(linha)
  }
  servico = servico_da_uf(UF_PELO_CODIGO[[substr(lido$chave, 1, 2)]], recepcao$servico, ambiente, "CT-e")
  if (is.null(servico)) {
    linha$problema = paste0("a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz o ", recepcao$servico, " para a UF")
    return(linha)
  }
  linha$endereco = servico$endereco
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  pedido = montar_pedido(servico$endereco, recepcao$servico, recepcao$operacao, gzip_em_base64(lido$texto), familia = "cte")
  resposta = enviar_pedidos(list(pedido), conexao)[[1]]
  linha = completar_autorizacao_do_cte(linha, ler_resposta(resposta, recepcao$retorno), lido$texto, recepcao, ambiente)
  attr(linha$autorizacao, "tzone") = "America/Sao_Paulo"
  linha
}

# O documento do XML, conferido: um só, assinado, de homologação e com a chave do modelo dele. Sai o texto dele, sem a
# declaração, com o namespace, e com o QR-Code quando faltava.
ler_o_cte_para_autorizar = function(xml, ambiente, certificado, senha) {
  documento = ler_o_xml_para_assinar(xml)
  raizes = RECEPCAO_DE_CADA_DOCUMENTO_DO_CTE$raiz
  caminho = paste0("//*[(", paste0("local-name()='", raizes, "'", collapse = " or "), ") and *[local-name()='infCte']]")
  conhecimentos = xml2::xml_find_all(documento, caminho)
  if (length(conhecimentos) != 1) {
    stop("O XML tem de trazer um documento do CT-e (um CTe, CTeOS, GTVe ou CTeSimp com o infCte).", call. = FALSE)
  }
  conhecimento = conhecimentos[[1]]
  raiz = xml2::xml_name(conhecimento)
  if (length(xml2::xml_find_all(conhecimento, "*[local-name()='Signature']")) == 0) {
    stop("O ", raiz, " n\u00e3o est\u00e1 assinado (veja xml_assinar()).", call. = FALSE)
  }
  informacao = xml2::xml_find_first(conhecimento, "*[local-name()='infCte']")
  if (!identical(texto_pelo_caminho(informacao, "ide/tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    stop("O ", raiz, " tem de ser do ambiente de homologa\u00e7\u00e3o (tpAmb 2).", call. = FALSE)
  }
  chave = sub("^CTe", "", xml2::xml_attr(informacao, "Id"))
  partes = chave_decompor(chave)
  modelo = RECEPCAO_DE_CADA_DOCUMENTO_DO_CTE$modelo[raizes == raiz]
  if (!partes$valida || !identical(partes$modelo, modelo)) {
    stop("O Id do infCte n\u00e3o traz uma chave v\u00e1lida do modelo ", modelo, ".", call. = FALSE)
  }
  forma_de_emissao = texto_pelo_caminho(informacao, "ide/tpEmis")
  if (inherits(xml2::xml_find_first(conhecimento, "*[local-name()='infCTeSupl']"), "xml_missing")) {
    if (!(raiz %in% DOCUMENTOS_COM_A_REGRA_DO_SIGN) && !identical(forma_de_emissao, "1")) {
      stop("Na ", raiz, " fora da emiss\u00e3o normal, a regra do QR-Code (com ou sem a chave assinada) n\u00e3o foi conferida: ",
           "informe o infCTeSupl.", call. = FALSE)
    }
    uf = UF_PELO_CODIGO[[substr(chave, 1, 2)]]
    endereco = servico_da_uf(uf, "qrcode", ambiente, "CT-e")
    if (is.null(endereco)) {
      stop("A Rela\u00e7\u00e3o de Servi\u00e7os Web do CT-e n\u00e3o traz o endere\u00e7o do QR-Code para ", uf,
           ": informe o infCTeSupl.", call. = FALSE)
    }
    qrcode = paste0(endereco$endereco, "?chCTe=", chave, "&tpAmb=", AMBIENTES_LIBERADOS[[ambiente]])
    if (forma_de_emissao %in% FORMAS_DE_EMISSAO_COM_A_CHAVE_ASSINADA_NO_QRCODE) {
      # A chave assinada em RSA-SHA1 com o certificado do CT-e, em base64 (o item 9.2.2 do MOC), como no MDF-e.
      qrcode = paste0(qrcode, "&sign=", assinatura_da_chave_do_mdfe(chave, certificado, senha))
    }
    grupo = paste0('<infCTeSupl xmlns="', NAMESPACE_DO_CTE, '"><qrCodCTe>', escapar_texto_canonico(qrcode),
                   "</qrCodCTe></infCTeSupl>")
    xml2::xml_add_sibling(informacao, xml2::xml_root(xml2::read_xml(grupo)), .where = "after")
  }
  texto = trimws(as.character(xml2::xml_new_root(conhecimento), options = "no_declaration"))
  list(chave = chave, raiz = raiz, texto = texto, forma_de_emissao = forma_de_emissao)
}

# O retorno da recepção (retCTe, retCTeOS, retGTVe, retCTeSimp): a situação do envio e o protocolo; o autorizado ganha o
# documento processado (o documento e o protocolo).
completar_autorizacao_do_cte = function(linha, resposta_lida, texto_do_documento, recepcao, ambiente) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  retorno = resposta_lida$retorno
  if (!identical(texto_do_retorno(retorno, "tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a SEFAZ respondeu de outro ambiente"
    return(linha)
  }
  linha$situacao_envio = as.integer(texto_do_retorno(retorno, "cStat"))
  linha$motivo_envio = texto_do_retorno(retorno, "xMotivo")
  protocolo = xml2::xml_find_first(retorno, "./*[local-name()='protCTe']")
  if (inherits(protocolo, "xml_missing")) {
    return(linha)
  }
  informacao = xml2::xml_find_first(protocolo, "./*[local-name()='infProt']")
  if (!identical(texto_do_retorno(informacao, "chCTe"), linha$chave)) {
    linha$problema = "a SEFAZ respondeu sobre outra chave"
    return(linha)
  }
  linha$situacao = as.integer(texto_do_retorno(informacao, "cStat"))
  linha$motivo = texto_do_retorno(informacao, "xMotivo")
  linha$protocolo = texto_do_retorno(informacao, "nProt")
  linha$autorizacao = data_hora_da_consulta(texto_do_retorno(informacao, "dhRecbto"))
  if (linha$situacao %in% SITUACOES_DO_CTE_AUTORIZADO) {
    texto_do_protocolo = trimws(as.character(xml2::xml_new_root(protocolo), options = "no_declaration"))
    linha$xml_autorizado = paste0('<?xml version="1.0" encoding="UTF-8"?><', recepcao$processado, ' xmlns="',
                                  NAMESPACE_DO_CTE, '" versao="4.00">', texto_do_documento, texto_do_protocolo, "</",
                                  recepcao$processado, ">")
  }
  linha
}
