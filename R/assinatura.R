# A assinatura digital dos documentos fiscais (XMLDSig, como o Manual de Orientação do Contribuinte pede): o
# elemento inf* do documento (infNFe, infEvento, infMDFe, infCte, infDPS) é canonicalizado (C14N 1.0 inclusiva, sem
# comentários), o resumo SHA-1 dele vai no Reference e o SignedInfo, canonicalizado, é assinado com a chave do
# certificado A1 (RSA). A canonicalização é feita aqui, sobre o xml2, que não a oferece; foi conferida com as
# assinaturas de NF-e reais (o mesmo DigestValue e a assinatura verificada).

#' @include certificado.R
NULL

NAMESPACE_DA_ASSINATURA = "http://www.w3.org/2000/09/xmldsig#"
ALGORITMO_DA_CANONICALIZACAO = "http://www.w3.org/TR/2001/REC-xml-c14n-20010315"
ALGORITMO_DA_TRANSFORMACAO = "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
# Os documentos assinados e o elemento assinado de cada um (o que tem o atributo Id).
ELEMENTOS_ASSINADOS = c(NFe = "infNFe", evento = "infEvento", MDFe = "infMDFe", CTe = "infCte", CTeOS = "infCte",
                        GTVe = "infCte", DPS = "infDPS", inutNFe = "infInut", eventoCTe = "infEvento",
                        eventoMDFe = "infEvento", pedRegEvento = "infPedReg")
# O SHA-1 é o que os manuais da NF-e, do CT-e e do MDF-e pedem. Na NFS-e Nacional, a Sefin aceita os dois (no acervo,
# há DPS e pedidos de evento assinados com cada um): o RNFe usa o SHA-256.
DOCUMENTOS_COM_SHA256 = c("DPS", "pedRegEvento")
ALGORITMOS_DO_RESUMO = list(
  sha1 = list(assinatura = "http://www.w3.org/2000/09/xmldsig#rsa-sha1", resumo = "http://www.w3.org/2000/09/xmldsig#sha1"),
  sha256 = list(assinatura = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256",
                resumo = "http://www.w3.org/2001/04/xmlenc#sha256")
)

#' Assinar o XML de um documento fiscal
#'
#' Assina o XML de uma NF-e, NFC-e, CT-e, MDF-e, DPS da NFS-e Nacional ou de
#' um evento com o certificado digital A1, como a SEFAZ exige antes do envio:
#' a assinatura XMLDSig do elemento que tem o `Id` (`infNFe`, `infCte`,
#' `infMDFe`, `infDPS`, `infEvento`), com a canonicalização C14N, o resumo e a
#' assinatura RSA. Num lote, cada documento é assinado. A assinatura que já
#' existia é trocada.
#'
#' Antes de assinar, os espaços e as quebras de linha entre as tags saem: a
#' SEFAZ rejeita o XML formatado (com recuo), e o que é assinado tem de ser o
#' que vai. Por isso o XML devolvido vem numa linha só.
#'
#' A NF-e, o CT-e, o MDF-e e os eventos são assinados com o SHA-1, como os
#' manuais deles pedem; a DPS e o pedido de evento da NFS-e Nacional, com o
#' SHA-256.
#'
#' Não escreva a senha no script: guarde-a numa variável de ambiente e leia
#' com [Sys.getenv()].
#'
#' @param xml O XML: o caminho do arquivo ou o próprio texto (começando por
#'   `<`).
#' @param certificado O caminho do certificado A1 (`.pfx` ou `.p12`).
#' @param senha A senha do certificado.
#' @return O XML assinado, num texto.
#' @seealso [certificado_ler()] para conferir o certificado; [nfe_conferir()]
#'   para conferir a nota antes de enviar.
#' @source Manual de Orientação do Contribuinte da NF-e, seção da assinatura
#'   digital (XMLDSig com C14N, SHA-1 e RSA); W3C, "XML Signature Syntax and
#'   Processing" e "Canonical XML Version 1.0".
#' @examples
#' \dontrun{
#' assinada = xml_assinar("nota.xml", "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' writeLines(assinada, "nota_assinada.xml", useBytes = TRUE)
#' }
#' @export
xml_assinar = function(xml, certificado, senha) {
  exigir_pacotes("openssl")
  conteudo = tryCatch(openssl::read_p12(certificado, password = senha), error = function(erro) erro)
  if (inherits(conteudo, "error") || is.null(conteudo$cert) || is.null(conteudo$key)) {
    stop("A senha n\u00e3o abre o certificado, ou ele n\u00e3o \u00e9 um certificado A1 com a chave.", call. = FALSE)
  }
  documento = ler_o_xml_para_assinar(xml)
  documentos_assinaveis = documentos_para_assinar(documento)
  if (length(documentos_assinaveis) == 0) {
    stop("O XML n\u00e3o tem um documento que se assina (NFe, CTe, MDFe, DPS ou evento com o elemento do Id).",
         call. = FALSE)
  }
  for (documento_assinavel in documentos_assinaveis) {
    assinar_um_documento(documento_assinavel, conteudo$cert, conteudo$key)
  }
  # Sem a opção "format": o recuo criaria espaços que não estavam no que foi assinado.
  trimws(as.character(documento, options = character()))
}

# O XML lido sem os espaços entre as tags (a opção NOBLANKS do libxml2): a assinatura vale para o que vai.
ler_o_xml_para_assinar = function(xml) {
  xml = as.character(xml)
  if (length(xml) != 1 || is.na(xml)) {
    stop("Informe um XML: o caminho de um arquivo ou o texto.", call. = FALSE)
  }
  if (!startsWith(trimws(xml), "<") && !file.exists(xml)) {
    stop("Arquivo n\u00e3o encontrado: ", xml, call. = FALSE)
  }
  tryCatch(xml2::read_xml(xml, options = "NOBLANKS"), error = function(erro) {
    stop("N\u00e3o \u00e9 um XML v\u00e1lido: ", conditionMessage(erro), call. = FALSE)
  })
}

# Cada documento do XML que tem o elemento assinado (pelo nome local, em qualquer namespace).
documentos_para_assinar = function(documento) {
  nomes = names(ELEMENTOS_ASSINADOS)
  caminho = paste0("//*[", paste0("(local-name()='", nomes, "' and *[local-name()='", ELEMENTOS_ASSINADOS, "'])",
                                  collapse = " or "), "]")
  xml2::xml_find_all(documento, caminho)
}

assinar_um_documento = function(documento_assinavel, certificado, chave) {
  nome_do_documento = xml2::xml_name(documento_assinavel)
  elemento_assinado = xml2::xml_find_first(documento_assinavel,
                                           paste0("*[local-name()='", ELEMENTOS_ASSINADOS[[nome_do_documento]], "']"))
  identificador = xml2::xml_attr(elemento_assinado, "Id")
  if (is.na(identificador) || identificador == "") {
    stop("O ", xml2::xml_name(elemento_assinado), " n\u00e3o tem o atributo Id, que a assinatura referencia.", call. = FALSE)
  }
  com_sha256 = nome_do_documento %in% DOCUMENTOS_COM_SHA256
  algoritmos = ALGORITMOS_DO_RESUMO[[if (com_sha256) "sha256" else "sha1"]]
  # A assinatura antiga sai antes de calcular o resumo.
  xml2::xml_remove(xml2::xml_find_all(documento_assinavel, "*[local-name()='Signature']"))
  resumo = resumo_em_base64(xml_canonico(elemento_assinado), com_sha256)
  # O SignedInfo já na forma canônica: é o texto que se assina, e o que a SEFAZ vai refazer do XML enviado.
  conteudo_da_informacao = paste0(
    "<CanonicalizationMethod Algorithm=\"", ALGORITMO_DA_CANONICALIZACAO, "\"></CanonicalizationMethod>",
    "<SignatureMethod Algorithm=\"", algoritmos$assinatura, "\"></SignatureMethod>",
    "<Reference URI=\"#", escapar_atributo_canonico(identificador), "\"><Transforms>",
    "<Transform Algorithm=\"", ALGORITMO_DA_TRANSFORMACAO, "\"></Transform>",
    "<Transform Algorithm=\"", ALGORITMO_DA_CANONICALIZACAO, "\"></Transform></Transforms>",
    "<DigestMethod Algorithm=\"", algoritmos$resumo, "\"></DigestMethod>",
    "<DigestValue>", resumo, "</DigestValue></Reference>"
  )
  informacao_canonica = paste0("<SignedInfo xmlns=\"", NAMESPACE_DA_ASSINATURA, "\">", conteudo_da_informacao, "</SignedInfo>")
  funcao_do_resumo = if (com_sha256) openssl::sha256 else openssl::sha1
  valor_da_assinatura = openssl::signature_create(charToRaw(enc2utf8(informacao_canonica)), hash = funcao_do_resumo,
                                                  key = chave)
  texto_da_assinatura = paste0(
    "<Signature xmlns=\"", NAMESPACE_DA_ASSINATURA, "\"><SignedInfo>", conteudo_da_informacao, "</SignedInfo>",
    "<SignatureValue>", openssl::base64_encode(valor_da_assinatura), "</SignatureValue>",
    "<KeyInfo><X509Data><X509Certificate>", openssl::base64_encode(openssl::write_der(certificado)),
    "</X509Certificate></X509Data></KeyInfo></Signature>"
  )
  xml2::xml_add_child(documento_assinavel, xml2::xml_root(xml2::read_xml(texto_da_assinatura)))
  # Conferência: o SignedInfo que ficou no documento tem de dar o mesmo texto que foi assinado.
  informacao_no_documento = xml2::xml_find_first(documento_assinavel,
                                                 "*[local-name()='Signature']/*[local-name()='SignedInfo']")
  if (!identical(xml_canonico(informacao_no_documento), informacao_canonica)) {
    stop("A forma can\u00f4nica do SignedInfo no documento n\u00e3o bate com a assinada.", call. = FALSE)
  }
  invisible(documento_assinavel)
}

resumo_em_base64 = function(texto_canonico, com_sha256) {
  bytes = charToRaw(enc2utf8(texto_canonico))
  if (com_sha256) {
    return(openssl::base64_encode(openssl::sha256(bytes)))
  }
  openssl::base64_encode(openssl::sha1(bytes))
}

# A forma canônica de um elemento (C14N 1.0 inclusiva, sem comentários): as tags de abertura e fechamento sempre (o
# elemento vazio vira <a></a>), os atributos em ordem, o namespace declarado onde ele muda (no elemento de partida,
# o que estiver em escopo) e os caracteres escapados como a norma manda. Os documentos fiscais só usam o namespace
# padrão (sem prefixo), que é o que esta forma trata.
xml_canonico = function(elemento, namespace_de_cima = "") {
  namespace = xml2::xml_find_chr(elemento, "string(namespace-uri())")
  nome = xml2::xml_name(elemento)
  abertura = paste0("<", nome)
  if (!identical(namespace, namespace_de_cima)) {
    abertura = paste0(abertura, " xmlns=\"", escapar_atributo_canonico(namespace), "\"")
  }
  atributos = xml2::xml_attrs(elemento)
  # O xml2 devolve a declaração de namespace feita no próprio elemento como um atributo: ela já foi tratada acima.
  atributos = atributos[!(names(atributos) == "xmlns" | startsWith(names(atributos), "xmlns:"))]
  if (length(atributos) > 0) {
    ordem = order(names(atributos), method = "radix")
    abertura = paste0(abertura, paste0(" ", names(atributos)[ordem], "=\"", escapar_atributo_canonico(atributos[ordem]),
                                       "\"", collapse = ""))
  }
  partes = character()
  for (filho in xml2::xml_contents(elemento)) {
    tipo = xml2::xml_type(filho)
    if (tipo == "element") {
      partes = c(partes, xml_canonico(filho, namespace))
    } else if (tipo %in% c("text", "cdata")) {
      partes = c(partes, escapar_texto_canonico(xml2::xml_text(filho)))
    }
  }
  paste0(abertura, ">", paste(partes, collapse = ""), "</", nome, ">")
}

escapar_texto_canonico = function(texto) {
  texto = gsub("&", "&amp;", texto, fixed = TRUE)
  texto = gsub("<", "&lt;", texto, fixed = TRUE)
  texto = gsub(">", "&gt;", texto, fixed = TRUE)
  gsub("\r", "&#xD;", texto, fixed = TRUE)
}

escapar_atributo_canonico = function(texto) {
  texto = gsub("&", "&amp;", texto, fixed = TRUE)
  texto = gsub("<", "&lt;", texto, fixed = TRUE)
  texto = gsub("\"", "&quot;", texto, fixed = TRUE)
  texto = gsub("\t", "&#x9;", texto, fixed = TRUE)
  texto = gsub("\n", "&#xA;", texto, fixed = TRUE)
  gsub("\r", "&#xD;", texto, fixed = TRUE)
}
