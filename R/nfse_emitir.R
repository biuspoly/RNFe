# A emissão e o cancelamento da NFS-e Nacional pela Sefin Nacional (API REST, com o certificado de cliente): a DPS
# assinada vai em gzip dentro do base64 num JSON (POST /nfse), e a NFS-e gerada volta do mesmo jeito; o pedido de
# registro do evento de cancelamento vai em POST /nfse/<chave>/eventos. Só a Produção Restrita, a homologação.

#' @include sefaz.R assinatura.R nfse_nacional.R
NULL

NAMESPACE_DA_NFSE = "http://www.sped.fazenda.gov.br/nfse"

# Os motivos do cancelamento (TSCodJustCanc do tiposSimples_v1.01.xsd).
MOTIVOS_DO_CANCELAMENTO_DA_NFSE = c(erro_na_emissao = "1", servico_nao_prestado = "2", outros = "9")

#' Emitir uma NFS-e Nacional
#'
#' Manda a DPS (a Declaração de Prestação de Serviço) à Sefin Nacional, que
#' gera a NFS-e na hora e a devolve. A DPS é assinada aqui com o certificado
#' do prestador (com o SHA-256; a assinatura que já existia é trocada) e vai
#' compactada, como a API pede. Monte a DPS pelo leiaute da NFS-e Nacional
#' (`DPS_v1.01.xsd`), com o `tpAmb` 2.
#'
#' Por enquanto só a **Produção Restrita**, que é a homologação da NFS-e
#' Nacional: a DPS com o `tpAmb` 1 nem é enviada.
#'
#' @param dps A DPS: o caminho do arquivo ou o texto do XML.
#' @inheritParams sefaz_status
#' @return Um `data.frame` com uma linha: `id_dps`, `chave` (a da NFS-e
#'   gerada), `ambiente`, `situacao_http` (201 quando a nota foi gerada),
#'   `codigo` e `motivo` (os erros da Sefin, separados por `;`), `alertas`,
#'   `processamento` (no horário de Brasília), `xml` (a NFS-e, que o
#'   [nfse_ler()] lê), `endereco` e `problema`.
#' @seealso [nfse_cancelar()], [nfse_situacao()], [nfse_ler()]
#' @source A especificação OpenAPI da Sefin Nacional na Produção Restrita
#'   (`POST /nfse`, `NFSePostRequest` e as respostas); os schemas da NFS-e
#'   Nacional, versão 1.01 (`DPS_v1.01.xsd`).
#' @examples
#' \dontrun{
#' emitida = nfse_emitir("dps.xml", "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' emitida[, c("chave", "situacao_http", "codigo", "motivo")]
#' nfse_ler(emitida$xml)
#' }
#' @export
nfse_emitir = function(dps, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  exigir_pacotes(c("httr2", "curl", "openssl", "jsonlite"))
  conferir_certificado(certificado, senha)
  documento = ler_o_xml_para_assinar(dps)
  informacao = xml2::xml_find_first(documento, "/*[local-name()='DPS']/*[local-name()='infDPS']")
  if (inherits(informacao, "xml_missing")) {
    stop("O XML tem de ser uma DPS (o elemento DPS com o infDPS).", call. = FALSE)
  }
  if (!identical(texto_pelo_caminho(informacao, "tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    stop("A DPS tem de ser do ambiente de homologa\u00e7\u00e3o (tpAmb 2).", call. = FALSE)
  }
  # Com a declaração: sem ela, a Sefin rejeita (E1229, "Xml não está utilizando codificação UTF-8").
  assinada = xml_com_a_declaracao(xml_assinar(dps, certificado, senha))
  enderecos = ENDERECOS_DA_NFSE_NACIONAL[ENDERECOS_DA_NFSE_NACIONAL$ambiente == ambiente, ]
  linha = data.frame(
    id_dps = xml2::xml_attr(informacao, "Id"), chave = NA_character_, ambiente = ambiente, situacao_http = NA_integer_,
    codigo = NA_character_, motivo = NA_character_, alertas = NA_character_, processamento = as.POSIXct(NA),
    xml = NA_character_, endereco = paste0(enderecos$sefin, "/nfse"), problema = NA_character_
  )
  corpo = jsonlite::toJSON(list(dpsXmlGZipB64 = gzip_em_base64(assinada)), auto_unbox = TRUE)
  resposta = enviar_para_a_nfse_nacional(linha$endereco, corpo, certificado, senha)
  linha = completar_emissao_da_nfse(linha, ler_resposta_em_json(resposta), ambiente)
  attr(linha$processamento, "tzone") = "America/Sao_Paulo"
  linha
}

#' Cancelar uma NFS-e Nacional
#'
#' Registra na Sefin Nacional o cancelamento de uma NFS-e (o evento 101101),
#' com o motivo e a justificativa. O pedido é montado e assinado aqui com o
#' certificado de quem cancela (o prestador), com o SHA-256.
#'
#' Por enquanto só a **Produção Restrita**, que é a homologação da NFS-e
#' Nacional.
#'
#' @param chave A chave de acesso da NFS-e (50 posições).
#' @param motivo `"erro_na_emissao"`, `"servico_nao_prestado"` ou `"outros"`.
#' @param justificativa O motivo por extenso, de 15 a 255 caracteres.
#' @inheritParams sefaz_status
#' @return Um `data.frame` com uma linha: `chave`, `ambiente`, `situacao_http`
#'   (201 quando o evento foi registrado), `codigo` e `motivo` (o erro da
#'   Sefin), `processamento`, `xml_evento` (o evento, que o [eventos_ler()]
#'   lê), `endereco` e `problema`.
#' @seealso [nfse_emitir()], [nfse_situacao()]
#' @source A especificação OpenAPI da Sefin Nacional na Produção Restrita
#'   (`POST /nfse/{chaveAcesso}/eventos`); o schema do pedido de registro de
#'   evento da NFS-e Nacional, versão 1.01 (`pedRegEvento_v1.01.xsd` e o
#'   `TE101101` de `tiposEventos_v1.01.xsd`).
#' @examples
#' \dontrun{
#' nfse_cancelar("35503082211222333000181000000000012326101234567898", "erro_na_emissao",
#'               "VALOR DO SERVICO INFORMADO ERRADO", "empresa.pfx",
#'               Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
nfse_cancelar = function(chave, motivo, justificativa, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  if (length(motivo) != 1 || !(motivo %in% names(MOTIVOS_DO_CANCELAMENTO_DA_NFSE))) {
    stop("Informe o motivo: ", paste0("\"", names(MOTIVOS_DO_CANCELAMENTO_DA_NFSE), "\"", collapse = ", "), ".",
         call. = FALSE)
  }
  conferir_texto_do_evento(justificativa, "justificativa", 15, 255)
  chave_limpa = limpar_chaves(chave)
  if (length(chave_limpa) != 1 || is.na(chave_limpa) || !grepl(FORMATO_DA_CHAVE_DA_NFSE, chave_limpa)) {
    stop("Informe a chave de acesso da NFS-e (50 posi\u00e7\u00f5es).", call. = FALSE)
  }
  exigir_pacotes(c("httr2", "curl", "openssl", "jsonlite"))
  conferir_certificado(certificado, senha)
  autor = autor_informado_ou_do_certificado(NULL, certificado, senha, "autor")
  campo_do_autor = if (autor$tipo_documento == "CPF") "CPFAutor" else "CNPJAutor"
  pedido = paste0(
    '<pedRegEvento xmlns="', NAMESPACE_DA_NFSE, '" versao="1.01"><infPedReg Id="PRE', chave_limpa, '101101"><tpAmb>',
    AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb><verAplic>RNFe</verAplic><dhEvento>", data_hora_do_evento(Sys.time()),
    "</dhEvento><", campo_do_autor, ">", autor$documento, "</", campo_do_autor, "><chNFSe>", chave_limpa,
    "</chNFSe><e101101><xDesc>Cancelamento de NFS-e</xDesc><cMotivo>", MOTIVOS_DO_CANCELAMENTO_DA_NFSE[[motivo]],
    "</cMotivo><xMotivo>", escapar_texto_canonico(justificativa), "</xMotivo></e101101></infPedReg></pedRegEvento>"
  )
  assinado = xml_com_a_declaracao(xml_assinar(pedido, certificado, senha))
  enderecos = ENDERECOS_DA_NFSE_NACIONAL[ENDERECOS_DA_NFSE_NACIONAL$ambiente == ambiente, ]
  linha = data.frame(
    chave = chave_limpa, ambiente = ambiente, situacao_http = NA_integer_, codigo = NA_character_, motivo = NA_character_,
    processamento = as.POSIXct(NA), xml_evento = NA_character_, endereco = paste0(enderecos$sefin, "/nfse/", chave_limpa,
                                                                                  "/eventos"),
    problema = NA_character_
  )
  corpo = jsonlite::toJSON(list(pedidoRegistroEventoXmlGZipB64 = gzip_em_base64(assinado)), auto_unbox = TRUE)
  resposta = enviar_para_a_nfse_nacional(linha$endereco, corpo, certificado, senha)
  linha = completar_evento_da_nfse(linha, ler_resposta_em_json(resposta), ambiente)
  attr(linha$processamento, "tzone") = "America/Sao_Paulo"
  linha
}

# O XML com a declaração do UTF-8 no começo, uma vez só.
xml_com_a_declaracao = function(xml) {
  paste0('<?xml version="1.0" encoding="UTF-8"?>', sub("^<\\?xml[^>]*\\?>\\s*", "", xml))
}

# O texto em gzip (o formato com o cabeçalho, que a API pede) e em base64. O memCompress() faz o formato zlib, sem o
# cabeçalho do gzip: o gzip vem do gzfile, num arquivo temporário.
gzip_em_base64 = function(texto) {
  arquivo = tempfile(fileext = ".gz")
  on.exit(unlink(arquivo), add = TRUE)
  conexao = gzfile(arquivo, "wb")
  writeBin(charToRaw(enc2utf8(texto)), conexao)
  close(conexao)
  openssl::base64_encode(readBin(arquivo, "raw", n = file.size(arquivo)))
}

# Um POST com o JSON à API da NFS-e Nacional, pela conexão de sempre (o certificado e, no Windows, o processo separado).
enviar_para_a_nfse_nacional = function(endereco, corpo_em_json, certificado, senha) {
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  pedido = list(endereco = endereco, corpo = charToRaw(enc2utf8(as.character(corpo_em_json))),
                tipo_do_conteudo = "application/json")
  enviar_pedidos(list(pedido), conexao)[[1]]
}

# A resposta do POST /nfse: a NFS-e gerada (201) ou os erros (a lista "erros").
completar_emissao_da_nfse = function(linha, resposta_lida, ambiente) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  json = resposta_lida$json
  linha$situacao_http = resposta_lida$situacao_http
  if (is.null(valor_no_json(json, "tipoAmbiente"))) {
    linha$problema = resposta_fora_do_formato(resposta_lida, "da Sefin Nacional")
    return(linha)
  }
  linha$processamento = data_hora_da_consulta(texto_do_json(valor_no_json(json, "dataHoraProcessamento")))
  linha$codigo = juntar_ou_na(textos_das_mensagens_da_sefin(valor_no_json(json, "erros"), "codigo"))
  linha$motivo = juntar_ou_na(textos_das_mensagens_da_sefin(valor_no_json(json, "erros"), "descricao"))
  alertas = textos_das_mensagens_da_sefin(valor_no_json(json, "alertas"), "descricao")
  linha$alertas = juntar_ou_na(alertas)
  if (!identical(texto_do_json(valor_no_json(json, "tipoAmbiente")), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a NFS-e Nacional respondeu de outro ambiente"
    return(linha)
  }
  if (!identical(linha$situacao_http, 201L)) {
    return(linha)
  }
  linha$chave = texto_do_json(valor_no_json(json, "chaveAcesso"))
  xml = tryCatch(texto_do_gzip_em_base64(texto_do_json(valor_no_json(json, "nfseXmlGZipB64"))), error = function(erro) NA_character_)
  if (is.na(xml)) {
    linha$problema = "a nota foi gerada, mas o XML dela n\u00e3o abriu"
    return(linha)
  }
  linha$xml = xml
  linha
}

# A resposta do POST dos eventos: o evento registrado (201) ou o erro (um só, no "erro").
completar_evento_da_nfse = function(linha, resposta_lida, ambiente) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  json = resposta_lida$json
  linha$situacao_http = resposta_lida$situacao_http
  if (is.null(valor_no_json(json, "tipoAmbiente"))) {
    linha$problema = resposta_fora_do_formato(resposta_lida, "da Sefin Nacional")
    return(linha)
  }
  linha$processamento = data_hora_da_consulta(texto_do_json(valor_no_json(json, "dataHoraProcessamento")))
  erro = valor_no_json(json, "erro")
  linha$codigo = campo_da_mensagem_da_sefin(erro, "codigo")
  linha$motivo = campo_da_mensagem_da_sefin(erro, "descricao")
  complemento = campo_da_mensagem_da_sefin(erro, "complemento")
  if (!is.na(complemento) && nzchar(complemento)) {
    linha$motivo = paste0(linha$motivo, " (", complemento, ")")
  }
  if (!identical(texto_do_json(valor_no_json(json, "tipoAmbiente")), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a NFS-e Nacional respondeu de outro ambiente"
    return(linha)
  }
  if (!identical(linha$situacao_http, 201L)) {
    return(linha)
  }
  xml = tryCatch(texto_do_gzip_em_base64(texto_do_json(valor_no_json(json, "eventoXmlGZipB64"))), error = function(erro) NA_character_)
  if (is.na(xml)) {
    linha$problema = "o evento foi registrado, mas o XML dele n\u00e3o abriu"
    return(linha)
  }
  linha$xml_evento = xml
  linha
}

# Um campo (codigo, descricao) de cada mensagem da Sefin; a mensagem que vem como texto solto entra inteira.
textos_das_mensagens_da_sefin = function(mensagens, campo) {
  textos = character()
  if (!is.list(mensagens)) {
    return(textos)
  }
  for (mensagem in mensagens) {
    texto = if (is.list(mensagem)) campo_da_mensagem_da_sefin(mensagem, campo) else texto_do_json(mensagem)
    if (!is.na(texto)) {
      textos = c(textos, texto)
    }
  }
  textos
}

# O campo de uma mensagem da Sefin pelo nome da especificação ("codigo") ou com a inicial maiúscula ("Codigo"), como a
# Produção Restrita respondeu em 05/11/2026.
campo_da_mensagem_da_sefin = function(mensagem, campo) {
  texto = texto_do_json(valor_no_json(mensagem, campo))
  if (is.na(texto)) {
    texto = texto_do_json(valor_no_json(mensagem, paste0(toupper(substr(campo, 1, 1)), substring(campo, 2))))
  }
  texto
}
