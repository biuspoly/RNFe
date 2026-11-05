# O QR-Code da NFC-e na versão 3 (NT 2025.001 e o Manual de Padrões Técnicos do DANFE NFC-e e QR-Code, versão 6.0): sem
# o CSC. Na emissão normal, a chave, a versão e o ambiente; na contingência off-line (tpEmis 9), também o dia da
# emissão, o valor da nota e o destinatário, com a assinatura RSA-SHA1 desses parâmetros pelo certificado que assina a
# nota.

#' @include assinatura.R
NULL

#' Pôr o QR-Code na NFC-e
#'
#' Monta o grupo `infNFeSupl` da NFC-e (o QR-Code e o endereço da consulta pela
#' chave), na versão 3 do QR-Code, a que dispensa o CSC: na emissão normal, o
#' QR-Code leva a chave, a versão e o ambiente; na contingência off-line
#' (`tpEmis` 9), também o dia da emissão, o valor da nota e o destinatário, e a
#' assinatura desses parâmetros com o certificado (o mesmo que assina a nota).
#' O grupo que já existia é trocado. Pode ser chamado antes ou depois de
#' [xml_assinar()]: a assinatura da nota não cobre este grupo.
#'
#' O endereço da consulta pelo QR-Code e o da consulta pela chave são os da UF
#' do emitente, publicados no Portal Nacional da NFC-e
#' (<https://nfce.encat.org/desenvolvedor/qrcode/>), um para a produção e outro
#' para a homologação.
#'
#' @param xml A NFC-e: o caminho do arquivo ou o próprio texto do XML.
#' @param endereco_qrcode O endereço da consulta pelo QR-Code da UF (o
#'   `?p=` e os parâmetros são acrescentados aqui).
#' @param endereco_consulta O endereço da consulta pela chave de acesso da UF
#'   (vai na `urlChave`).
#' @param certificado,senha O certificado A1 e a senha: só na contingência
#'   off-line, para assinar os parâmetros do QR-Code.
#' @return O XML da NFC-e com o `infNFeSupl`, num texto.
#' @seealso [xml_assinar()], [sefaz_autorizar()]
#' @source Nota Técnica 2025.001 v1.03 (o leiaute do QR-Code versão 3) e o
#'   Manual de Padrões Técnicos do DANFE NFC-e e QR-Code, versão 6.0 (março de
#'   2025), seção 4.4, do Portal da NF-e; o schema `leiauteNFe_v4.00.xsd` do
#'   pacote 010g (o padrão do `qrCode`).
#' @examples
#' \dontrun{
#' nfce = nfce_qrcode("nfce.xml", "http://nfceh.sefaz.ce.gov.br/pages/ShowNFCe.html?",
#'                    "http://nfceh.sefaz.ce.gov.br/pages/consultaChaveAcesso.jsf")
#' assinada = xml_assinar(nfce, "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
nfce_qrcode = function(xml, endereco_qrcode, endereco_consulta, certificado = NULL, senha = NULL) {
  for (endereco in list(endereco_qrcode, endereco_consulta)) {
    if (length(endereco) != 1 || is.na(endereco) || !grepl("^https?://", endereco, ignore.case = TRUE)) {
      stop("Informe os dois endere\u00e7os da UF, come\u00e7ando por http:// ou https://.", call. = FALSE)
    }
  }
  documento = ler_o_xml_para_assinar(xml)
  notas = xml2::xml_find_all(documento, "//*[local-name()='NFe' and *[local-name()='infNFe']]")
  if (length(notas) != 1) {
    stop("O XML tem de trazer uma NFC-e (uma NFe com o infNFe).", call. = FALSE)
  }
  nota = notas[[1]]
  informacao = xml2::xml_find_first(nota, "*[local-name()='infNFe']")
  chave = sub("^NFe", "", xml2::xml_attr(informacao, "Id"))
  if (!identical(chave_decompor(chave)$modelo, "65")) {
    stop("O QR-Code \u00e9 da NFC-e (modelo 65).", call. = FALSE)
  }
  parametros = paste(chave, "3", texto_pelo_caminho(informacao, "ide/tpAmb"), sep = "|")
  if (identical(texto_pelo_caminho(informacao, "ide/tpEmis"), "9")) {
    parametros = parametros_da_contingencia(parametros, informacao, certificado, senha)
  }
  separador = if (endsWith(endereco_qrcode, "?")) "p=" else "?p="
  grupo = paste0('<infNFeSupl xmlns="', NAMESPACE_DA_NFE, '"><qrCode>', escapar_texto_canonico(paste0(endereco_qrcode, separador, parametros)),
                 "</qrCode><urlChave>", escapar_texto_canonico(endereco_consulta), "</urlChave></infNFeSupl>")
  xml2::xml_remove(xml2::xml_find_all(nota, "*[local-name()='infNFeSupl']"))
  xml2::xml_add_sibling(informacao, xml2::xml_root(xml2::read_xml(grupo)), .where = "after")
  trimws(as.character(documento, options = character()))
}

# Os parâmetros da contingência off-line: o dia da emissão (dois dígitos), o valor da nota, o tipo e o número do
# destinatário (vazios quando ele não é identificado; o número vazio também para o estrangeiro) e a assinatura deles,
# em base64, com a chave do certificado.
parametros_da_contingencia = function(parametros, informacao, certificado, senha) {
  if (is.null(certificado) || is.null(senha)) {
    stop("Na conting\u00eancia off-line o QR-Code leva a assinatura: informe o certificado e a senha.", call. = FALSE)
  }
  exigir_pacotes("openssl")
  conteudo = tryCatch(openssl::read_p12(certificado, password = senha), error = function(erro) erro)
  if (inherits(conteudo, "error") || is.null(conteudo$key)) {
    stop("A senha n\u00e3o abre o certificado, ou ele n\u00e3o \u00e9 um certificado A1 com a chave.", call. = FALSE)
  }
  emissao = texto_pelo_caminho(informacao, "ide/dhEmi")
  valor_da_nota = texto_pelo_caminho(informacao, "total/ICMSTot/vNF")
  cnpj = texto_pelo_caminho(informacao, "dest/CNPJ")
  cpf = texto_pelo_caminho(informacao, "dest/CPF")
  estrangeiro = !is.na(texto_pelo_caminho(informacao, "dest/idEstrangeiro"))
  tipo_do_destinatario = ""
  destinatario = ""
  if (!is.na(cnpj)) {
    tipo_do_destinatario = "1"
    destinatario = cnpj
  } else if (!is.na(cpf)) {
    tipo_do_destinatario = "2"
    destinatario = cpf
  } else if (estrangeiro) {
    tipo_do_destinatario = "3"
  }
  assinados = paste(parametros, substr(emissao, 9, 10), valor_da_nota, tipo_do_destinatario, destinatario, sep = "|")
  assinatura = openssl::signature_create(charToRaw(enc2utf8(assinados)), hash = openssl::sha1, key = conteudo$key)
  paste0(assinados, "|", openssl::base64_encode(assinatura))
}
