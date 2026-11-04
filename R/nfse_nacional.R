# A NFS-e Nacional pelas APIs do Sistema Nacional NFS-e: a nota pela chave (Sefin Nacional) e os documentos de um CNPJ
# (ADN, o Ambiente de Dados Nacional). São APIs REST, com o mesmo certificado de cliente da SEFAZ e mensagens em JSON;
# os documentos vêm em gzip dentro do base64. Por enquanto, só a Produção Restrita, que é a homologação da NFS-e
# Nacional.

#' @include sefaz.R
NULL

# Os endereços de cada ambiente: a Sefin Nacional (gera e consulta a NFS-e) e o ADN dos contribuintes (guarda e
# distribui as NFS-e e os eventos). Da página "APIs - Prod. Restrita e Produção" do gov.br/nfse e das especificações
# OpenAPI de cada uma (lidas em 04/11/2026).
ENDERECOS_DA_NFSE_NACIONAL = utils::read.table(header = TRUE, sep = ";", strip.white = TRUE, stringsAsFactors = FALSE, text = "
ambiente    ; sefin                                                    ; adn
homologacao ; https://sefin.producaorestrita.nfse.gov.br/SefinNacional ; https://adn.producaorestrita.nfse.gov.br/contribuintes
", colClasses = "character")

# A Sefin diz o ambiente pelo número (o tpAmb, 2 na homologação); o ADN, pelo nome.
AMBIENTE_NA_RESPOSTA_DO_ADN = c(homologacao = "HOMOLOGACAO")

#' Situação de NFS-e Nacional, pela chave
#'
#' Pergunta ao Sistema Nacional NFS-e cada nota pela chave de acesso (50
#' números) e devolve uma lista com `situacoes` (uma linha por chave: se a nota
#' foi achada, e o XML dela) e `eventos` (os eventos de cada nota, como o
#' cancelamento, lidos por [eventos_ler()]). A nota vem da Sefin Nacional
#' (`GET /nfse/<chave>`) e os eventos, do ADN, o Ambiente de Dados Nacional
#' (`GET /NFSe/<chave>/Eventos`). Leia as notas com [nfse_ler()]:
#' `nfse_ler(consulta$situacoes$xml)`.
#'
#' A NFS-e não tem um código de situação como o da NF-e: o que acontece com a
#' nota depois de gerada (cancelamento, substituição, manifestação) é
#' registrado em eventos, ligados a ela. Para saber se foi cancelada, veja os
#' eventos (o cancelamento é o 101101).
#'
#' Só quem aparece na nota (prestador, tomador ou intermediário) consegue
#' consultá-la; para os outros, a Sefin responde 403. Chave que não tem 50
#' números nem é enviada: o motivo fica em `problema`.
#'
#' Por enquanto só a **Produção Restrita**, que é a homologação da NFS-e
#' Nacional (`ambiente = "homologacao"`); a produção é recusada. A conexão é a
#' mesma do [sefaz_status()] (o certificado A1 e, no Windows, o processo
#' separado). As respostas vêm em JSON: precisa também do pacote `jsonlite`.
#'
#' @param chaves As chaves de acesso de 50 números: um texto ou um vetor (por
#'   exemplo, a coluna `chave` de [nfse_ler()]). Espaços, pontos e o prefixo
#'   `NFS` do `Id` do XML são ignorados.
#' @inheritParams sefaz_status
#' @return Uma lista com dois `data.frame`s:
#'   - `situacoes`, uma linha por chave: `chave`, `ambiente`, `encontrada`
#'     (`TRUE` quando a nota veio), `situacao_http` (200 quando veio, 404
#'     quando não existe, 403 quando quem pergunta não está na nota), `codigo` e
#'     `motivo` (o erro da Sefin: o `E2401`, por exemplo, é "Chave de acesso não
#'     encontrada."), `processamento` (data e hora da resposta, no horário de
#'     Brasília), `versao_aplicativo`, `xml` (o XML da NFS-e, quando veio),
#'     `endereco` e `problema` (por que a consulta não deu certo; vazio quando
#'     deu, inclusive quando a nota não existe);
#'   - `eventos`: a tabela `eventos` de [eventos_ler()] com os eventos que o
#'     ADN tem de cada nota, ligados pela `chave`, sem a coluna `arquivo`.
#' @seealso [nfse_ler()], [eventos_ler()], [nfse_distribuicao()]
#' @source As especificações OpenAPI da Sefin Nacional (v1) e do ADN
#'   Contribuintes (v1) na Produção Restrita; a página "APIs - Prod. Restrita e
#'   Produção" do gov.br/nfse; os manuais de contribuintes "Guia para utilização
#'   das APIs do Emissor Público Nacional" (v1.0, 17/03/2025) e "Guia para
#'   utilização das APIs do ADN" (v1.0, 12/02/2026). Lidos em 04/11/2026.
#' @examples
#' \dontrun{
#' consulta = nfse_situacao(nfse_ler("nota.xml")$nfses$chave, "empresa.pfx",
#'                          Sys.getenv("SENHA_DO_CERTIFICADO"))
#' consulta$situacoes[, c("chave", "encontrada", "codigo", "motivo")]
#' consulta$eventos[, c("chave", "tipo", "descricao", "data_evento")]
#' nfse_ler(consulta$situacoes$xml)
#' }
#' @export
nfse_situacao = function(chaves, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  exigir_pacotes(c("httr2", "curl", "openssl", "jsonlite"))
  conferir_certificado(certificado, senha)
  enderecos = ENDERECOS_DA_NFSE_NACIONAL[ENDERECOS_DA_NFSE_NACIONAL$ambiente == ambiente, ]
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  chaves_limpas = limpar_chaves(chaves)
  linhas = list()
  pedidos = list()
  linha_de_cada_chave_pedida = integer()
  for (posicao in seq_along(chaves_limpas)) {
    linhas[[posicao]] = comeco_da_situacao_da_nfse(chaves_limpas[posicao], ambiente, enderecos$sefin)
    if (is.na(linhas[[posicao]]$problema)) {
      # Dois pedidos por chave: a nota, na Sefin, e os eventos dela, no ADN.
      pedidos[[length(pedidos) + 1]] = pedido_da_nfse_nacional(linhas[[posicao]]$endereco)
      pedidos[[length(pedidos) + 1]] = pedido_da_nfse_nacional(paste0(enderecos$adn, "/NFSe/", chaves_limpas[posicao], "/Eventos"))
      linha_de_cada_chave_pedida = c(linha_de_cada_chave_pedida, posicao)
    }
  }
  respostas = enviar_pedidos(pedidos, conexao)
  xml_dos_eventos = character()
  for (numero_da_chave in seq_along(linha_de_cada_chave_pedida)) {
    posicao = linha_de_cada_chave_pedida[numero_da_chave]
    resposta_da_nota = ler_resposta_em_json(respostas[[2 * numero_da_chave - 1]])
    linhas[[posicao]] = completar_situacao_da_nfse(linhas[[posicao]], resposta_da_nota, ambiente)
    resposta_dos_eventos = ler_resposta_do_adn(ler_resposta_em_json(respostas[[2 * numero_da_chave]]), ambiente)
    xml_dos_eventos = c(xml_dos_eventos, resposta_dos_eventos$documentos$xml)
    if (!is.na(resposta_dos_eventos$problema)) {
      problemas = c(linhas[[posicao]]$problema, paste("nos eventos:", resposta_dos_eventos$problema))
      linhas[[posicao]]$problema = paste(problemas[!is.na(problemas)], collapse = "; ")
    }
  }
  if (length(linhas) == 0) {
    situacoes = comeco_da_situacao_da_nfse(NA_character_, ambiente, enderecos$sefin)[0, ]
  } else {
    situacoes = do.call(rbind, linhas)
  }
  # Juntar as linhas tira o fuso das datas: volta o de Brasília.
  attr(situacoes$processamento, "tzone") = "America/Sao_Paulo"
  eventos = eventos_ler(xml_dos_eventos[!is.na(xml_dos_eventos)], todos_os_campos = FALSE)$eventos
  eventos$arquivo = NULL
  list(situacoes = situacoes, eventos = eventos)
}

# A linha da chave, com o endereço da consulta na Sefin, ou com o problema quando a chave não tem 50 números.
comeco_da_situacao_da_nfse = function(chave, ambiente, endereco_da_sefin) {
  linha = data.frame(
    chave = chave, ambiente = ambiente, encontrada = FALSE, situacao_http = NA_integer_, codigo = NA_character_,
    motivo = NA_character_, processamento = as.POSIXct(NA), versao_aplicativo = NA_character_, xml = NA_character_,
    endereco = NA_character_, problema = NA_character_
  )
  # O schema da NFS-e (TSChaveNFSe) só aceita 50 números.
  if (is.na(chave) || !grepl("^[0-9]{50}$", chave)) {
    linha$problema = "chave inv\u00e1lida: a da NFS-e Nacional tem 50 n\u00fameros"
    return(linha)
  }
  linha$endereco = paste0(endereco_da_sefin, "/nfse/", chave)
  linha
}

# A resposta da Sefin na linha da chave: o erro (codigo e descrição) ou a nota, descompactada. Nota que não existe (404)
# ou que quem pergunta não pode ver (403) é resposta, não problema.
completar_situacao_da_nfse = function(linha, resposta_lida, ambiente) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  json = resposta_lida$json
  linha$situacao_http = resposta_lida$situacao_http
  linha$processamento = data_hora_da_consulta(texto_do_json(json$dataHoraProcessamento))
  linha$versao_aplicativo = texto_do_json(json$versaoAplicativo)
  linha$codigo = texto_do_json(json$erro$codigo)
  linha$motivo = texto_do_json(json$erro$descricao)
  complemento = texto_do_json(json$erro$complemento)
  if (!is.na(complemento) && nzchar(complemento)) {
    linha$motivo = paste0(linha$motivo, " (", complemento, ")")
  }
  if (!identical(texto_do_json(json$tipoAmbiente), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a NFS-e Nacional respondeu de outro ambiente"
    return(linha)
  }
  if (!identical(linha$situacao_http, 200L)) {
    return(linha)
  }
  if (!identical(texto_do_json(json$chaveAcesso), linha$chave)) {
    linha$problema = "a Sefin respondeu com outra chave"
    return(linha)
  }
  xml = tryCatch(texto_do_gzip_em_base64(texto_do_json(json$nfseXmlGZipB64)), error = function(erro) NA_character_)
  if (is.na(xml)) {
    linha$problema = "a nota veio, mas o XML dela n\u00e3o abriu"
    return(linha)
  }
  linha$xml = xml
  linha$encontrada = TRUE
  linha
}

#' Distribuição de NFS-e Nacional: as notas e os eventos de um CNPJ
#'
#' Pede ao ADN (o Ambiente de Dados Nacional da NFS-e) os documentos em que um
#' CNPJ ou CPF aparece como emitente, tomador ou intermediário: as NFS-e e os
#' eventos delas. Devolve uma lista com `consulta` (a resposta, numa linha) e
#' `documentos` (um por linha, com o XML já descompactado). Leia as notas com
#' [nfse_ler()] e os eventos com [eventos_ler()]:
#' `nfse_ler(distribuicao$documentos$xml)`.
#'
#' Cada chamada faz um pedido, que traz um lote dos documentos com NSU maior
#' que `ultimo_nsu`. Para seguir, chame de novo com `ultimo_nsu` igual ao
#' `ultimo_nsu` da resposta (o maior NSU que veio), até a resposta dizer
#' `"NENHUM_DOCUMENTO_LOCALIZADO"`. A documentação do ADN não fala de espera
#' nem de bloqueio, como as da NF-e e do CT-e; mesmo assim, não pergunte em
#' laço sem pausa.
#'
#' Com um certificado de empresa, dá para pedir os documentos de qualquer CNPJ
#' com a mesma raiz (os 8 primeiros dígitos); de outra raiz, ou de outro CPF,
#' só com procuração cadastrada na Receita Federal (sem ela, o ADN rejeita com
#' E2245). O CNPJ ou CPF vai sempre no pedido: sem ele, a Produção Restrita
#' rejeitou o pedido sem dizer o motivo (testado em 04/11/2026).
#'
#' Por enquanto só a **Produção Restrita**, que é a homologação da NFS-e
#' Nacional (`ambiente = "homologacao"`); a produção é recusada. A conexão é a
#' mesma do [sefaz_status()], e as respostas vêm em JSON: precisa também do
#' pacote `jsonlite`.
#'
#' @param documento O CNPJ ou CPF cujos documentos se quer (em geral o do
#'   certificado). Pontos, barras e traços são ignorados.
#' @param ultimo_nsu O último NSU já recebido: 0 na primeira vez e, depois, o
#'   `ultimo_nsu` da resposta anterior.
#' @inheritParams sefaz_status
#' @return Uma lista com dois `data.frame`s:
#'   - `consulta`, numa linha: `documento`, `ambiente`, `situacao`
#'     (`"DOCUMENTOS_LOCALIZADOS"`, `"NENHUM_DOCUMENTO_LOCALIZADO"` ou
#'     `"REJEICAO"`), `situacao_http`, `tipo_consulta` (como o ADN autorizou o
#'     pedido: `"InscricaoCertificado"`, `"CnpjBase"` ou `"Procuracao"`),
#'     `codigo` e `motivo` (os erros, como o `E2220` de nenhum documento,
#'     separados por `"; "`), `alertas`, `processamento` (data e hora da
#'     resposta, no horário de Brasília), `ultimo_nsu` (o maior NSU que veio,
#'     de onde seguir; o do pedido, quando não veio nada), `documentos`
#'     (quantos vieram), `versao_aplicativo`, `endereco` e `problema` (por que o
#'     pedido não deu certo; vazio quando deu, inclusive quando não há
#'     documentos);
#'   - `documentos`, um por linha: `nsu`, `chave` (da NFS-e), `tipo_documento`
#'     (`"NFSE"` ou `"EVENTO"`, como o ADN diz), `tipo_evento` (no evento, o
#'     nome que o ADN dá, como `"CANCELAMENTO"`), `gerado_em` (data e hora em
#'     que o documento foi gerado, no horário de Brasília) e `xml` (o
#'     documento, descompactado).
#' @seealso [nfse_ler()], [eventos_ler()], [nfse_situacao()],
#'   [sefaz_distribuicao()]
#' @source A especificação OpenAPI do ADN Contribuintes (v1) na Produção
#'   Restrita (`GET /DFe/<NSU>`, os parâmetros `cnpjConsulta` e `cpfConsulta`
#'   e as mensagens de erro); o manual de contribuintes "Guia para utilização
#'   das APIs do ADN" (v1.0, 12/02/2026); a página "APIs - Prod. Restrita e
#'   Produção" do gov.br/nfse. Lidos em 04/11/2026.
#' @examples
#' \dontrun{
#' senha = Sys.getenv("SENHA_DO_CERTIFICADO")
#' distribuicao = nfse_distribuicao("11222333000181", "empresa.pfx", senha)
#' distribuicao$consulta[, c("situacao", "codigo", "motivo", "ultimo_nsu")]
#' nfse_ler(distribuicao$documentos$xml)$nfses
#' eventos_ler(distribuicao$documentos$xml)$eventos
#' # O próximo pedido segue do último NSU recebido.
#' seguinte = nfse_distribuicao("11222333000181", "empresa.pfx", senha,
#'                              ultimo_nsu = distribuicao$consulta$ultimo_nsu)
#' }
#' @export
nfse_distribuicao = function(documento, certificado, senha, ultimo_nsu = 0, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  documento = toupper(gsub("[^0-9A-Za-z]", "", as.character(documento)))
  if (length(documento) != 1 || is.na(documento) || !grepl("^([0-9A-Z]{12}[0-9]{2}|[0-9]{11})$", documento)) {
    stop("Informe um CNPJ (14 posi\u00e7\u00f5es) ou um CPF (11 d\u00edgitos) em `documento`.", call. = FALSE)
  }
  ultimo_nsu = nsu_do_adn(ultimo_nsu)
  exigir_pacotes(c("httr2", "curl", "openssl", "jsonlite"))
  conferir_certificado(certificado, senha)
  enderecos = ENDERECOS_DA_NFSE_NACIONAL[ENDERECOS_DA_NFSE_NACIONAL$ambiente == ambiente, ]
  if (nchar(documento) == 14) {
    parametro_do_documento = "cnpjConsulta"
  } else {
    parametro_do_documento = "cpfConsulta"
  }
  endereco = paste0(enderecos$adn, "/DFe/", ultimo_nsu, "?", parametro_do_documento, "=", documento)
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  resposta = enviar_pedidos(list(pedido_da_nfse_nacional(endereco)), conexao)[[1]]
  resposta_lida = ler_resposta_do_adn(ler_resposta_em_json(resposta), ambiente)
  documentos = resposta_lida$documentos
  consulta = data.frame(
    documento = documento, ambiente = ambiente, situacao = resposta_lida$situacao,
    situacao_http = resposta_lida$situacao_http, tipo_consulta = resposta_lida$tipo_consulta, codigo = resposta_lida$codigo,
    motivo = resposta_lida$motivo, alertas = resposta_lida$alertas, processamento = resposta_lida$processamento,
    ultimo_nsu = ultimo_nsu, documentos = nrow(documentos), versao_aplicativo = resposta_lida$versao_aplicativo,
    endereco = endereco, problema = resposta_lida$problema
  )
  if (is.na(resposta_lida$situacao)) {
    consulta$documentos = NA_integer_
  }
  if (nrow(documentos) > 0) {
    consulta$ultimo_nsu = documentos$nsu[which.max(as.numeric(documentos$nsu))]
  }
  list(consulta = consulta, documentos = documentos)
}

# O NSU no caminho do pedido: só dígitos, sem os zeros da frente (o ADN o trata como número inteiro de 64 bits).
nsu_do_adn = function(nsu) {
  if (is.numeric(nsu)) {
    nsu = format(nsu, scientific = FALSE, trim = TRUE)
  }
  nsu = as.character(nsu)
  if (length(nsu) != 1 || is.na(nsu) || !grepl("^[0-9]{1,19}$", nsu)) {
    stop("O NSU tem de ter de 1 a 19 d\u00edgitos.", call. = FALSE)
  }
  sub("^0+([0-9])", "\\1", nsu)
}

# Um pedido às APIs da NFS-e Nacional: um GET, sem corpo, que pede a resposta em JSON.
pedido_da_nfse_nacional = function(endereco) {
  list(endereco = endereco, aceita = "application/json")
}

# A resposta de uma API da NFS-e Nacional, lida do JSON. Sem resposta, ou sem JSON, o motivo vai em `problema`. As
# APIs respondem em JSON também nos erros (400, 403, 404), e esses ficam como resposta.
ler_resposta_em_json = function(resposta) {
  if (!is.na(resposta$erro)) {
    return(list(json = NULL, situacao_http = NA_integer_,
                problema = paste("sem resposta da NFS-e Nacional:", gsub("\\s+", " ", resposta$erro))))
  }
  texto = rawToChar(resposta$corpo)
  Encoding(texto) = "UTF-8"
  json = tryCatch(jsonlite::fromJSON(texto, simplifyVector = FALSE), error = function(erro) NULL)
  if (is.null(json)) {
    return(list(json = NULL, situacao_http = as.integer(resposta$situacao_http),
                problema = paste0("HTTP ", resposta$situacao_http, ": a resposta n\u00e3o veio em JSON")))
  }
  list(json = json, situacao_http = as.integer(resposta$situacao_http), problema = NA_character_)
}

# A resposta do ADN (a distribuição, ou os eventos de uma nota): a situação, os erros e alertas, e os documentos, com o
# XML descompactado. "Nenhum documento localizado" não é problema; a rejeição, a resposta de outro ambiente e o
# documento que não abre são.
ler_resposta_do_adn = function(resposta_lida, ambiente) {
  documentos = data.frame(nsu = character(), chave = character(), tipo_documento = character(), tipo_evento = character(),
                          gerado_em = as.POSIXct(character(), tz = "America/Sao_Paulo"), xml = character())
  lida = list(situacao = NA_character_, situacao_http = resposta_lida$situacao_http, tipo_consulta = NA_character_,
              codigo = NA_character_, motivo = NA_character_, alertas = NA_character_, processamento = as.POSIXct(NA),
              versao_aplicativo = NA_character_, documentos = documentos, problema = resposta_lida$problema)
  if (!is.na(resposta_lida$problema)) {
    return(lida)
  }
  json = resposta_lida$json
  lida$situacao = texto_do_json(json$StatusProcessamento)
  lida$tipo_consulta = texto_do_json(json$TipoConsulta)
  lida$codigo = juntar_mensagens_do_adn(json$Erros, "Codigo")
  lida$motivo = juntar_mensagens_do_adn(json$Erros, "Descricao")
  alertas_com_codigo = character()
  for (alerta in json$Alertas) {
    alertas_com_codigo = c(alertas_com_codigo, paste(texto_do_json(alerta$Codigo), texto_do_json(alerta$Descricao)))
  }
  if (length(alertas_com_codigo) > 0) {
    lida$alertas = paste(alertas_com_codigo, collapse = "; ")
  }
  lida$processamento = data_hora_da_consulta(texto_do_json(json$DataHoraProcessamento))
  lida$versao_aplicativo = texto_do_json(json$VersaoAplicativo)
  if (!identical(texto_do_json(json$TipoAmbiente), AMBIENTE_NA_RESPOSTA_DO_ADN[[ambiente]])) {
    lida$problema = "o ADN respondeu de outro ambiente"
    return(lida)
  }
  if (identical(lida$situacao, "REJEICAO")) {
    if (is.na(lida$codigo)) {
      lida$problema = "o ADN rejeitou o pedido sem dizer o motivo"
    } else {
      lida$problema = paste0("o ADN rejeitou o pedido: ", lida$codigo, " ", lida$motivo)
    }
    return(lida)
  }
  linhas = list()
  que_nao_abriram = character()
  for (documento in json$LoteDFe) {
    nsu = texto_do_json(documento$NSU)
    xml = tryCatch(texto_do_gzip_em_base64(texto_do_json(documento$ArquivoXml)), error = function(erro) NA_character_)
    if (is.na(xml)) {
      que_nao_abriram = c(que_nao_abriram, nsu)
    }
    linhas[[length(linhas) + 1]] = data.frame(
      nsu = nsu, chave = texto_do_json(documento$ChaveAcesso), tipo_documento = texto_do_json(documento$TipoDocumento),
      tipo_evento = texto_do_json(documento$TipoEvento), gerado_em = data_hora_da_consulta(texto_do_json(documento$DataHoraGeracao)),
      xml = xml
    )
  }
  if (length(linhas) > 0) {
    lida$documentos = do.call(rbind, linhas)
    attr(lida$documentos$gerado_em, "tzone") = "America/Sao_Paulo"
  }
  if (length(que_nao_abriram) > 0) {
    lida$problema = paste("o XML destes NSU n\u00e3o abriu:", paste(que_nao_abriram, collapse = ", "))
  }
  lida
}

# Um campo (o Codigo ou a Descricao) de cada mensagem do ADN, separados por "; ", ou NA quando não há nenhuma.
juntar_mensagens_do_adn = function(mensagens, campo) {
  textos = character()
  for (mensagem in mensagens) {
    textos = c(textos, texto_do_json(mensagem[[campo]]))
  }
  if (length(textos) == 0) {
    return(NA_character_)
  }
  paste(textos, collapse = "; ")
}

# Um valor do JSON como texto; o que não veio (NULL), como NA. O número grande (NSU) sai sem notação científica.
texto_do_json = function(valor) {
  if (is.null(valor) || length(valor) == 0) {
    return(NA_character_)
  }
  if (is.numeric(valor)) {
    return(format(valor, scientific = FALSE, trim = TRUE))
  }
  as.character(valor)
}
