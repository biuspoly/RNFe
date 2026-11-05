# A autorização da NF-e e da NFC-e (NFeAutorizacao4): o lote com uma nota só, no modo síncrono (a NT 2023.002 v1.02
# acaba com o assíncrono em 05/04/2027), e, quando a SEFAZ responde "lote recebido" (103) mesmo assim, a consulta do
# recibo (NFeRetAutorizacao4). Só o ambiente de homologação, como o resto da conversa com a SEFAZ.

#' @include sefaz.R assinatura.R
NULL

# Quantas vezes o recibo é consultado, e o intervalo entre uma e outra, quando a SEFAZ processa o lote depois.
TENTATIVAS_DO_RECIBO = 5
ESPERA_ENTRE_AS_TENTATIVAS = 3
# As situações do protocolo que autorizam o uso: 100 (autorizado), 150 (fora de prazo) e 120 (com alerta, NT 2026.002).
SITUACOES_AUTORIZADAS = c(100L, 120L, 150L)

#' Enviar a NF-e para autorização
#'
#' Manda cada NF-e ou NFC-e assinada para a SEFAZ autorizar e devolve, de cada
#' uma, a resposta: a situação (100 é autorizada), o motivo, o protocolo e o
#' XML autorizado (o `nfeProc`, a nota com o protocolo), pronto para guardar.
#' Cada nota vai num lote só dela, no modo síncrono, como a SEFAZ passa a
#' exigir; quando ela responde que recebeu o lote para processar depois (103),
#' o RNFe consulta o recibo até a resposta chegar.
#'
#' Por enquanto o RNFe só fala com o ambiente de **homologação**: a nota tem
#' de vir com `tpAmb` 2, e a de produção é recusada antes de qualquer conexão.
#' A conexão é a mesma do [sefaz_status()].
#'
#' Antes de enviar, confira a nota com [nfe_conferir()]: a rejeição da SEFAZ
#' gasta a numeração do lote e, em excesso, vira consumo indevido.
#'
#' @param xml As notas assinadas (veja [xml_assinar()]): o caminho de cada
#'   arquivo ou o próprio texto do XML, um por nota.
#' @inheritParams sefaz_status
#' @return Um `data.frame` com uma linha por nota: `chave`, `modelo`, `uf`,
#'   `autorizador`, `ambiente`, `situacao_lote` e `motivo_lote` (o que a SEFAZ
#'   disse do lote: 104 é processado), `recibo` (quando ela processou depois),
#'   `situacao` e `motivo` (o protocolo da nota: 100 autorizada, 150 autorizada
#'   fora de prazo, 120 autorizada com alerta, as outras são rejeição ou
#'   denegação), `protocolo`, `autorizacao` (data e hora), `xml_autorizado` (o
#'   `nfeProc`, só na nota autorizada), `endereco` e `problema` (por que não
#'   deu para enviar ou entender a resposta).
#' @seealso [xml_assinar()], [nfe_conferir()], [sefaz_situacao()] para
#'   consultar depois.
#' @source Manual de Orientação do Contribuinte da NF-e (o serviço de
#'   autorização, o lote e o protocolo); os schemas `enviNFe_v4.00.xsd`,
#'   `retEnviNFe_v4.00.xsd`, `consReciNFe_v4.00.xsd` e `procNFe_v4.00.xsd`; o
#'   WSDL do NFeAutorizacao4 (operação `nfeAutorizacaoLote`) e do
#'   NFeRetAutorizacao4 (`nfeRetAutorizacaoLote`); a NT 2023.002 v1.02 (o fim da
#'   autorização assíncrona).
#' @examples
#' \dontrun{
#' assinada = xml_assinar("nota.xml", "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' resposta = sefaz_autorizar(assinada, "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' resposta[, c("chave", "situacao", "motivo", "protocolo")]
#' writeLines(resposta$xml_autorizado, "nota_autorizada.xml", useBytes = TRUE)
#' }
#' @export
sefaz_autorizar = function(xml, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  exigir_pacotes(c("httr2", "curl", "openssl"))
  notas = notas_para_autorizar(xml, ambiente)
  conferir_certificado(certificado, senha)
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)

  linhas = notas$linhas
  enviaveis = which(is.na(linhas$problema))
  pedidos = list()
  for (posicao in enviaveis) {
    pedidos[[length(pedidos) + 1]] = pedido_da_autorizacao(linhas[posicao, ], notas$textos[posicao], ambiente)
  }
  respostas = enviar_pedidos(pedidos, conexao)
  for (numero in seq_along(enviaveis)) {
    posicao = enviaveis[numero]
    linhas[posicao, ] = completar_autorizacao(linhas[posicao, ], ler_resposta(respostas[[numero]], "retEnviNFe"),
                                              notas$textos[posicao], ambiente)
  }
  linhas = consultar_os_recibos(linhas, notas$textos, conexao, ambiente)
  attr(linhas$autorizacao, "tzone") = "America/Sao_Paulo"
  rownames(linhas) = NULL
  linhas
}

# Uma linha por nota, com o que dá para saber antes de enviar (a chave, o modelo, a UF e o endereço do serviço) ou o
# motivo de não enviar, e o texto da NFe de cada uma (sem a declaração do XML, que não vai dentro do lote).
notas_para_autorizar = function(xml, ambiente) {
  xml = as.character(xml)
  linhas = data.frame(
    chave = rep(NA_character_, length(xml)), modelo = NA_character_, uf = NA_character_, autorizador = NA_character_,
    ambiente = ambiente, situacao_lote = NA_integer_, motivo_lote = NA_character_, recibo = NA_character_,
    situacao = NA_integer_, motivo = NA_character_, protocolo = NA_character_, autorizacao = as.POSIXct(NA),
    xml_autorizado = NA_character_, endereco = NA_character_, problema = NA_character_
  )
  textos = rep(NA_character_, length(xml))
  for (posicao in seq_along(xml)) {
    lida = ler_a_nota_para_autorizar(xml[posicao], ambiente)
    if (!is.na(lida$problema)) {
      linhas$problema[posicao] = lida$problema
      next
    }
    linhas$chave[posicao] = lida$chave
    linhas$modelo[posicao] = lida$modelo
    linhas$uf[posicao] = UF_PELO_CODIGO[[substr(lida$chave, 1, 2)]]
    documento = if (lida$modelo == "65") "NFC-e" else "NF-e"
    servico = servico_da_uf(linhas$uf[posicao], "NFeAutorizacao", ambiente, documento)
    if (is.null(servico)) {
      linhas$problema[posicao] = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz a autoriza\u00e7\u00e3o para a UF"
      next
    }
    linhas$autorizador[posicao] = servico$autorizador
    linhas$endereco[posicao] = servico$endereco
    textos[posicao] = lida$texto
  }
  list(linhas = linhas, textos = textos)
}

# A NFe de um XML, conferida: uma nota só, assinada, com o tpAmb do ambiente e um modelo que a autorização conhece.
ler_a_nota_para_autorizar = function(xml, ambiente) {
  resultado = list(problema = NA_character_)
  e_texto = !is.na(xml) && startsWith(trimws(xml), "<")
  if (is.na(xml) || (!e_texto && !file.exists(xml))) {
    resultado$problema = "arquivo n\u00e3o encontrado"
    return(resultado)
  }
  documento = tryCatch(xml2::read_xml(xml, options = "NOBLANKS"), error = function(erro) NULL)
  if (is.null(documento)) {
    resultado$problema = "n\u00e3o \u00e9 um XML v\u00e1lido"
    return(resultado)
  }
  notas = xml2::xml_find_all(documento, "//*[local-name()='NFe' and *[local-name()='infNFe']]")
  if (length(notas) != 1) {
    resultado$problema = paste0("o XML tem ", length(notas), " NF-e; mande uma por XML")
    return(resultado)
  }
  nota = notas[[1]]
  if (length(xml2::xml_find_all(nota, "*[local-name()='Signature']")) == 0) {
    resultado$problema = "a NF-e n\u00e3o est\u00e1 assinada (veja xml_assinar())"
    return(resultado)
  }
  ambiente_da_nota = xml2::xml_text(xml2::xml_find_first(nota, ".//*[local-name()='ide']/*[local-name()='tpAmb']"))
  if (!identical(ambiente_da_nota, as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    resultado$problema = paste0("a NF-e tem o tpAmb ", ambiente_da_nota, ": o RNFe s\u00f3 envia a de homologa\u00e7\u00e3o (tpAmb 2)")
    return(resultado)
  }
  identificador = xml2::xml_attr(xml2::xml_find_first(nota, "*[local-name()='infNFe']"), "Id")
  chave = sub("^NFe", "", identificador)
  partes = chave_decompor(chave)
  if (!partes$valida || !(partes$modelo %in% c("55", "65"))) {
    resultado$problema = "o Id do infNFe n\u00e3o traz uma chave de NF-e ou NFC-e v\u00e1lida"
    return(resultado)
  }
  # A contingência SVC (tpEmis 6 e 7) vai para outro autorizador, que o RNFe ainda não usa.
  if (partes$forma_emissao %in% c(6L, 7L)) {
    resultado$problema = "a nota em conting\u00eancia SVC (tpEmis 6 ou 7) vai para a SVC, que o RNFe ainda n\u00e3o usa"
    return(resultado)
  }
  # O texto da NFe sozinha, com o namespace dela: é o que vai dentro do enviNFe.
  documento_da_nota = xml2::xml_new_root(nota)
  texto = as.character(documento_da_nota, options = "no_declaration")
  list(problema = NA_character_, chave = chave, modelo = partes$modelo, texto = trimws(texto))
}

# O lote com uma nota, no modo síncrono (indSinc 1). O número do lote só precisa ser único para quem envia: vai o
# instante em milissegundos com dois dígitos sorteados (15 posições, o máximo do schema).
pedido_da_autorizacao = function(linha, texto_da_nota, ambiente) {
  numero_do_lote = paste0(format(floor(as.numeric(Sys.time()) * 1000), scientific = FALSE),
                          sprintf("%02d", sample.int(100, 1) - 1))
  numero_do_lote = substr(numero_do_lote, nchar(numero_do_lote) - 14, nchar(numero_do_lote))
  mensagem = paste0('<enviNFe xmlns="', NAMESPACE_DA_NFE, '" versao="4.00"><idLote>', numero_do_lote,
                    "</idLote><indSinc>1</indSinc>", texto_da_nota, "</enviNFe>")
  montar_pedido(linha$endereco, "NFeAutorizacao4", "nfeAutorizacaoLote", mensagem)
}

# O retorno do lote: a situação dele, o recibo (quando ele foi para processar depois) e, quando veio, o protocolo da
# nota. A nota autorizada ganha o nfeProc.
completar_autorizacao = function(linha, resposta_lida, texto_da_nota, ambiente) {
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
  recibo = xml2::xml_find_first(retorno, "./*[local-name()='infRec']/*[local-name()='nRec']")
  if (!inherits(recibo, "xml_missing")) {
    linha$recibo = xml2::xml_text(recibo)
  }
  protocolo = xml2::xml_find_first(retorno, "./*[local-name()='protNFe']")
  completar_com_o_protocolo(linha, protocolo, texto_da_nota)
}

# O protocolo da nota (protNFe): a situação, o motivo, o número e a hora; na nota autorizada, o nfeProc com a nota e o
# protocolo como a SEFAZ mandou.
completar_com_o_protocolo = function(linha, protocolo, texto_da_nota) {
  if (inherits(protocolo, "xml_missing")) {
    return(linha)
  }
  informacao = xml2::xml_find_first(protocolo, "./*[local-name()='infProt']")
  chave_do_protocolo = texto_do_retorno(informacao, "chNFe")
  if (!identical(chave_do_protocolo, linha$chave)) {
    linha$problema = "a SEFAZ respondeu sobre outra chave"
    return(linha)
  }
  linha$situacao = as.integer(texto_do_retorno(informacao, "cStat"))
  linha$motivo = texto_do_retorno(informacao, "xMotivo")
  linha$protocolo = texto_do_retorno(informacao, "nProt")
  linha$autorizacao = data_hora_da_consulta(texto_do_retorno(informacao, "dhRecbto"))
  if (linha$situacao %in% SITUACOES_AUTORIZADAS) {
    linha$xml_autorizado = montar_o_processo_da_nota(texto_da_nota, protocolo)
  }
  linha
}

# O nfeProc: a nota como foi enviada e o protocolo como a SEFAZ mandou, no namespace da NF-e.
montar_o_processo_da_nota = function(texto_da_nota, protocolo) {
  documento_do_protocolo = xml2::xml_new_root(protocolo)
  texto_do_protocolo = trimws(as.character(documento_do_protocolo, options = "no_declaration"))
  versao = xml2::xml_attr(protocolo, "versao")
  if (is.na(versao)) {
    versao = "4.00"
  }
  paste0('<?xml version="1.0" encoding="UTF-8"?><nfeProc xmlns="', NAMESPACE_DA_NFE, '" versao="', versao, '">',
         texto_da_nota, texto_do_protocolo, "</nfeProc>")
}

esperar_antes_do_recibo = function() {
  Sys.sleep(ESPERA_ENTRE_AS_TENTATIVAS)
}

# A nota cujo lote a SEFAZ recebeu para processar depois (103, com o recibo) é consultada pelo recibo, algumas vezes,
# com um intervalo entre elas; enquanto a SEFAZ responde "em processamento" (105), espera e pergunta de novo.
consultar_os_recibos = function(linhas, textos, conexao, ambiente) {
  for (tentativa in seq_len(TENTATIVAS_DO_RECIBO)) {
    pendentes = which(!is.na(linhas$recibo) & is.na(linhas$situacao) & is.na(linhas$problema))
    if (length(pendentes) == 0) {
      break
    }
    esperar_antes_do_recibo()
    pedidos = list()
    for (posicao in pendentes) {
      servico = servico_da_uf(linhas$uf[posicao], "NFeRetAutorizacao", ambiente,
                              if (linhas$modelo[posicao] == "65") "NFC-e" else "NF-e")
      mensagem = paste0('<consReciNFe xmlns="', NAMESPACE_DA_NFE, '" versao="4.00"><tpAmb>',
                        AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb><nRec>", linhas$recibo[posicao], "</nRec></consReciNFe>")
      pedidos[[length(pedidos) + 1]] = montar_pedido(servico$endereco, "NFeRetAutorizacao4", "nfeRetAutorizacaoLote",
                                                     mensagem)
    }
    respostas = enviar_pedidos(pedidos, conexao)
    for (numero in seq_along(pendentes)) {
      posicao = pendentes[numero]
      resposta_lida = ler_resposta(respostas[[numero]], "retConsReciNFe")
      if (!is.na(resposta_lida$problema)) {
        linhas$problema[posicao] = resposta_lida$problema
        next
      }
      situacao_do_recibo = as.integer(texto_do_retorno(resposta_lida$retorno, "cStat"))
      linhas$situacao_lote[posicao] = situacao_do_recibo
      linhas$motivo_lote[posicao] = texto_do_retorno(resposta_lida$retorno, "xMotivo")
      protocolo = xml2::xml_find_first(resposta_lida$retorno, "./*[local-name()='protNFe']")
      linhas[posicao, ] = completar_com_o_protocolo(linhas[posicao, ], protocolo, textos[posicao])
    }
  }
  ainda_pendentes = !is.na(linhas$recibo) & is.na(linhas$situacao) & is.na(linhas$problema)
  linhas$problema[ainda_pendentes] = paste("a SEFAZ ainda n\u00e3o processou o lote: consulte o recibo ou a chave depois",
                                           "(sefaz_situacao())")
  linhas
}
