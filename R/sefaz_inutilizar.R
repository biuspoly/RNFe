# A inutilização de numeração da NF-e e da NFC-e (NFeInutilizacao4): o pedido assinado vai sozinho ao autorizador da
# UF do emitente, e o retorno é o retInutNFe. Só o ambiente de homologação.

#' @include sefaz.R assinatura.R sefaz_evento.R
NULL

#' Inutilizar uma faixa de numeração (NF-e e NFC-e)
#'
#' Pede ao autorizador da UF do emitente que inutilize os números de uma série
#' que não foram nem vão ser usados (uma nota pulada, uma rejeitada que não vai
#' ser reenviada). A situação 102 é a inutilização homologada; o número
#' inutilizado não pode mais ser usado.
#'
#' O certificado tem de ser do emitente: o mesmo CNPJ-base (o da matriz serve
#' para a filial). O `Id` do pedido, pelo schema oficial em vigor, só aceita
#' números: o CNPJ alfanumérico ainda não tem como inutilizar. Por enquanto só
#' o ambiente de **homologação**.
#'
#' @param cnpj O CNPJ do emitente.
#' @param uf A UF do emitente, pela sigla.
#' @param serie A série das notas (de 0 a 999).
#' @param numero_inicial,numero_final A faixa a inutilizar (de 1 a 999999999;
#'   o mesmo número nos dois para um só).
#' @param justificativa O motivo, de 15 a 255 caracteres.
#' @param modelo `"55"` (NF-e) ou `"65"` (NFC-e).
#' @param ano O ano da inutilização (padrão: o ano de hoje), com 4 ou 2
#'   algarismos.
#' @inheritParams sefaz_cancelar
#' @return Um `data.frame` com uma linha: `situacao` e `motivo` (a 102 é a
#'   inutilização homologada), `protocolo`, `registro` (a data e hora em que a
#'   SEFAZ recebeu), `xml_inutilizacao` (o `procInutNFe`: o pedido assinado e o
#'   retorno, que se guarda como prova), `endereco` e `problema` (o que impediu
#'   a resposta).
#' @seealso [sefaz_autorizar()], [sefaz_cancelar()]
#' @source Manual de Orientação do Contribuinte da NF-e (o serviço de
#'   inutilização de numeração) e os schemas `inutNFe_v4.00.xsd` e
#'   `leiauteInutNFe_v4.00.xsd`.
#' @examples
#' \dontrun{
#' sefaz_inutilizar("11222333000181", "CE", serie = 1, numero_inicial = 120, numero_final = 122,
#'                  justificativa = "NUMERACAO PULADA NA EMISSAO", certificado = "empresa.pfx",
#'                  senha = Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_inutilizar = function(cnpj, uf, serie, numero_inicial, numero_final, justificativa, certificado, senha,
                            modelo = "55", ano = format(Sys.Date(), "%Y"), ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  exigir_pacotes(c("httr2", "curl", "openssl"))
  cnpj_limpo = toupper(gsub("[^0-9A-Za-z]", "", as.character(cnpj)))
  if (length(cnpj_limpo) != 1 || !cnpj_confere(cnpj_limpo)) {
    stop("Informe o CNPJ do emitente com os d\u00edgitos certos.", call. = FALSE)
  }
  if (length(uf) != 1 || is.na(uf) || !(uf %in% names(CODIGO_DA_UF))) {
    stop("Informe a UF do emitente pela sigla.", call. = FALSE)
  }
  modelo = as.character(modelo)
  if (length(modelo) != 1 || !(modelo %in% c("55", "65"))) {
    stop("Informe o modelo: \"55\" (NF-e) ou \"65\" (NFC-e).", call. = FALSE)
  }
  serie = numero_inteiro_na_faixa(serie, 0, 999, "a s\u00e9rie")
  numero_inicial = numero_inteiro_na_faixa(numero_inicial, 1, 999999999, "o n\u00famero inicial")
  numero_final = numero_inteiro_na_faixa(numero_final, 1, 999999999, "o n\u00famero final")
  if (numero_final < numero_inicial) {
    stop("O n\u00famero final \u00e9 menor que o inicial.", call. = FALSE)
  }
  ano_texto = as.character(ano)
  if (length(ano_texto) != 1 || !grepl("^([0-9]{2}|[0-9]{4})$", ano_texto)) {
    stop("Informe o ano com 4 ou 2 algarismos.", call. = FALSE)
  }
  ano_curto = substr(ano_texto, nchar(ano_texto) - 1, nchar(ano_texto))
  conferir_texto_do_evento(justificativa, "a justificativa", 15, 255)
  conferir_certificado(certificado, senha)
  conferir_o_certificado_do_autor(list(tipo_documento = "CNPJ", documento = cnpj_limpo), certificado, senha,
                                  "o emitente")
  documento = if (modelo == "65") "NFC-e" else "NF-e"
  linha = data.frame(
    cnpj = cnpj_limpo, uf = uf, modelo = modelo, serie = serie, numero_inicial = numero_inicial,
    numero_final = numero_final, ambiente = ambiente, situacao = NA_integer_, motivo = NA_character_,
    protocolo = NA_character_, registro = as.POSIXct(NA), xml_inutilizacao = NA_character_, endereco = NA_character_,
    problema = NA_character_
  )
  servico = servico_da_uf(uf, "NfeInutilizacao", ambiente, documento)
  if (is.null(servico)) {
    linha$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz o servi\u00e7o de inutiliza\u00e7\u00e3o para a UF"
    return(linha)
  }
  linha$endereco = servico$endereco
  codigo_da_uf = CODIGO_DA_UF[[uf]]
  identificador = paste0("ID", codigo_da_uf, ano_curto, cnpj_limpo, modelo, sprintf("%03d", serie),
                         sprintf("%09d", numero_inicial), sprintf("%09d", numero_final))
  pedido_montado = paste0(
    '<inutNFe xmlns="', NAMESPACE_DA_NFE, '" versao="4.00"><infInut Id="', identificador, '"><tpAmb>',
    AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb><xServ>INUTILIZAR</xServ><cUF>", codigo_da_uf, "</cUF><ano>", ano_curto,
    "</ano><CNPJ>", cnpj_limpo, "</CNPJ><mod>", modelo, "</mod><serie>", serie, "</serie><nNFIni>", numero_inicial,
    "</nNFIni><nNFFin>", numero_final, "</nNFFin><xJust>", escapar_texto_canonico(justificativa),
    "</xJust></infInut></inutNFe>"
  )
  pedido_assinado = sub("^<\\?xml[^>]*\\?>\\s*", "", xml_assinar(pedido_montado, certificado, senha))
  arquivo_do_schema = system.file("schemas", "nfe", "inutNFe_v4.00.xsd", package = "RNFe")
  erros = erros_no_arquivo_do_schema(xml2::read_xml(pedido_assinado), arquivo_do_schema)
  parar_se_o_schema_recusar(gsub("\\{https?://[^}]*\\}", "", erros))
  pedido = montar_pedido(servico$endereco, "NFeInutilizacao4", "nfeInutilizacaoNF", pedido_assinado)
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  resposta = enviar_pedidos(list(pedido), conexao)[[1]]
  linha = completar_inutilizacao(linha, ler_resposta(resposta, "retInutNFe"), pedido_assinado, ambiente)
  attr(linha$registro, "tzone") = "America/Sao_Paulo"
  linha
}

numero_inteiro_na_faixa = function(valor, minimo, maximo, nome) {
  numero = suppressWarnings(as.numeric(valor))
  if (length(numero) != 1 || is.na(numero) || numero != round(numero) || numero < minimo || numero > maximo) {
    stop("Informe ", nome, ": um n\u00famero inteiro de ", minimo, " a ", format(maximo, scientific = FALSE), ".",
         call. = FALSE)
  }
  as.integer(numero)
}

# O retorno da inutilização; a homologada (102) ganha o procInutNFe (o pedido como foi e o retorno da SEFAZ).
completar_inutilizacao = function(linha, resposta_lida, pedido_assinado, ambiente) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  retorno = resposta_lida$retorno
  informacao = xml2::xml_find_first(retorno, "./*[local-name()='infInut']")
  if (!identical(texto_do_retorno(informacao, "tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a SEFAZ respondeu de outro ambiente"
    return(linha)
  }
  linha$situacao = as.integer(texto_do_retorno(informacao, "cStat"))
  linha$motivo = texto_do_retorno(informacao, "xMotivo")
  linha$protocolo = texto_do_retorno(informacao, "nProt")
  linha$registro = data_hora_da_consulta(texto_do_retorno(informacao, "dhRecbto"))
  if (identical(linha$situacao, 102L)) {
    texto_do_retorno_da_sefaz = trimws(as.character(xml2::xml_new_root(retorno), options = "no_declaration"))
    linha$xml_inutilizacao = paste0('<?xml version="1.0" encoding="UTF-8"?><procInutNFe xmlns="', NAMESPACE_DA_NFE,
                                    '" versao="4.00">', pedido_assinado, texto_do_retorno_da_sefaz, "</procInutNFe>")
  }
  linha
}
