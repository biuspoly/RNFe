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

# A chave da NFS-e: o município (7), o ambiente gerador (1), o tipo de inscrição (1), a inscrição (14), o número (13), o
# ano e mês (4), o código (9) e o dígito (1). Com o CNPJ alfanumérico (tipo 2), a inscrição tem letras: assim nos
# identificadores do evento e do pedido de registro (TSIdEvento, TSIdPedRegEvt) da Produção Restrita. O TSChaveNFSe de
# lá põe as letras nas posições 7 a 20, fora da regra de formação: vale a regra.
FORMATO_DA_CHAVE_DA_NFSE = "^[0-9]{8}(1[0-9]{14}|2[0-9A-Z]{14})[0-9]{27}$"

# Os erros do ADN que querem dizer só "não há documento" (a tabela de mensagens da especificação do ADN Contribuintes).
# Outro erro com a mesma situação, como o E2241 (a nota não cita quem pergunta), é problema: os eventos não foram vistos.
CODIGOS_DE_NENHUM_DOCUMENTO = c("E2220", "E2230", "E2240")

#' Situação de NFS-e Nacional, pela chave
#'
#' Pergunta ao Sistema Nacional NFS-e cada nota pela chave de acesso (50
#' posições) e devolve uma lista com `situacoes` (uma linha por chave: se a nota
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
#' consultá-la; para os outros, a Sefin responde 403. Chave que não tem o
#' formato (50 posições: números e, com o CNPJ alfanumérico, letras no lugar
#' do CNPJ) nem é enviada: o motivo fica em `problema`.
#'
#' Por enquanto só a **Produção Restrita**, que é a homologação da NFS-e
#' Nacional (`ambiente = "homologacao"`); a produção é recusada. A conexão é a
#' mesma do [sefaz_status()] (o certificado A1 e, no Windows, o processo
#' separado). As respostas vêm em JSON: precisa também do pacote `jsonlite`.
#'
#' @param chaves As chaves de acesso de 50 posições: um texto ou um vetor (por
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
  # A chave repetida vai uma vez só; no fim, ela recebe a linha da primeira.
  primeira_posicao_da_chave = match(chaves_limpas, chaves_limpas)
  linhas = list()
  pedidos = list()
  linha_de_cada_chave_pedida = integer()
  for (posicao in seq_along(chaves_limpas)) {
    if (primeira_posicao_da_chave[posicao] != posicao) {
      next
    }
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
  for (posicao in seq_along(chaves_limpas)) {
    if (primeira_posicao_da_chave[posicao] != posicao) {
      linhas[[posicao]] = linhas[[primeira_posicao_da_chave[posicao]]]
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

#' Situação de NFS-e Nacional, pela DPS
#'
#' Pergunta à Sefin Nacional se a DPS (pelo identificador dela, o `Id` do
#' `infDPS`) já gerou uma NFS-e e, quando gerou, traz a chave e o XML da nota.
#' Serve quando a emissão ficou sem resposta ([nfse_emitir()] com `problema`,
#' a conexão que caiu): antes de mandar a mesma DPS de novo, veja se ela já
#' virou nota. A consulta é a `GET /dps/<Id>` da Sefin, e a nota vem pela
#' `GET /nfse/<chave>`, como no [nfse_situacao()].
#'
#' Por enquanto só a **Produção Restrita**, que é a homologação da NFS-e
#' Nacional (`ambiente = "homologacao"`); a produção é recusada. A conexão é a
#' mesma do [sefaz_status()]; precisa também do pacote `jsonlite`.
#'
#' @param dps O identificador de cada DPS (`"DPS"` seguido de 42 posições: o
#'   município, o tipo e a inscrição do emitente, a série e o número), um
#'   vetor deles, ou o XML da DPS (o caminho do arquivo ou o texto), como o
#'   [nfse_dps_montar()] devolve. Espaços são ignorados.
#' @inheritParams sefaz_status
#' @return Um `data.frame` com uma linha por DPS: `dps` (o identificador),
#'   `ambiente`, `encontrada` (`TRUE` quando a DPS gerou uma NFS-e),
#'   `situacao_http` (200 quando gerou, 404 quando não), `codigo` e `motivo` (o
#'   erro da Sefin), `processamento` (data e hora da resposta, no horário de
#'   Brasília), `versao_aplicativo`, `chave` (a da NFS-e gerada), `xml` (o XML
#'   da NFS-e), `endereco` e `problema` (por que a consulta não deu certo,
#'   como o erro da Sefin que não diz se a DPS gerou nota: o limite de
#'   consultas, a Sefin fora do ar; vazio quando deu, inclusive quando a DPS
#'   não gerou nota, o 404). Com `problema`, não mande a DPS de novo antes de
#'   consultar outra vez.
#' @seealso [nfse_emitir()], [nfse_situacao()], [nfse_dps_montar()]
#' @source A especificação OpenAPI da Sefin Nacional (v1) na Produção Restrita
#'   (`GET /dps/{id}`: o `DpsGetResponse`, com o `idDps` e a `chaveAcesso`, e o
#'   `ResponseErro`; o 404 quando a DPS não gerou nota), lida em 04/11/2026; o
#'   tipo `TSIdDPS` do schema da DPS (v1.01).
#' @examples
#' \dontrun{
#' nfse_situacao_da_dps("DPS355030821122233300018100001000000000000123", "empresa.pfx",
#'                      Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
nfse_situacao_da_dps = function(dps, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  exigir_pacotes(c("httr2", "curl", "openssl", "jsonlite"))
  identificadores = identificadores_das_dps(dps)
  conferir_certificado(certificado, senha)
  enderecos = ENDERECOS_DA_NFSE_NACIONAL[ENDERECOS_DA_NFSE_NACIONAL$ambiente == ambiente, ]
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  primeira_posicao = match(identificadores, identificadores)
  linhas = list()
  pedidos = list()
  posicoes_pedidas = integer()
  for (posicao in seq_along(identificadores)) {
    if (primeira_posicao[posicao] != posicao) {
      next
    }
    linhas[[posicao]] = comeco_da_situacao_da_dps(identificadores[posicao], ambiente, enderecos$sefin)
    if (is.na(linhas[[posicao]]$problema)) {
      pedidos[[length(pedidos) + 1]] = pedido_da_nfse_nacional(linhas[[posicao]]$endereco)
      posicoes_pedidas = c(posicoes_pedidas, posicao)
    }
  }
  respostas = enviar_pedidos(pedidos, conexao)
  # As DPS que geraram nota: a nota de cada uma, num segundo pedido à Sefin.
  pedidos_das_notas = list()
  posicoes_das_notas = integer()
  for (numero in seq_along(posicoes_pedidas)) {
    posicao = posicoes_pedidas[numero]
    linhas[[posicao]] = completar_situacao_da_dps(linhas[[posicao]], ler_resposta_em_json(respostas[[numero]]), ambiente)
    if (linhas[[posicao]]$encontrada) {
      pedidos_das_notas[[length(pedidos_das_notas) + 1]] = pedido_da_nfse_nacional(paste0(enderecos$sefin, "/nfse/",
                                                                                          linhas[[posicao]]$chave))
      posicoes_das_notas = c(posicoes_das_notas, posicao)
    }
  }
  respostas_das_notas = enviar_pedidos(pedidos_das_notas, conexao)
  for (numero in seq_along(posicoes_das_notas)) {
    posicao = posicoes_das_notas[numero]
    da_nota = comeco_da_situacao_da_nfse(linhas[[posicao]]$chave, ambiente, enderecos$sefin)
    da_nota = completar_situacao_da_nfse(da_nota, ler_resposta_em_json(respostas_das_notas[[numero]]), ambiente)
    linhas[[posicao]]$xml = da_nota$xml
    if (!da_nota$encontrada) {
      motivo = da_nota$problema
      if (is.na(motivo)) {
        motivo = paste0("HTTP ", da_nota$situacao_http, " ", da_nota$codigo, " ", da_nota$motivo)
      }
      linhas[[posicao]]$problema = paste("a DPS gerou a nota, mas a nota n\u00e3o veio:", trimws(motivo))
    }
  }
  for (posicao in seq_along(identificadores)) {
    if (primeira_posicao[posicao] != posicao) {
      linhas[[posicao]] = linhas[[primeira_posicao[posicao]]]
    }
  }
  situacoes = do.call(rbind, linhas)
  attr(situacoes$processamento, "tzone") = "America/Sao_Paulo"
  situacoes
}

# O identificador de cada DPS informada: o texto ("DPS" e as 42 posições, também sem o "DPS") ou o Id do infDPS do XML.
identificadores_das_dps = function(dps) {
  if (!is.character(dps) || length(dps) == 0) {
    stop("Informe o identificador de cada DPS (o Id do infDPS) ou o XML da DPS.", call. = FALSE)
  }
  if (length(dps) == 1 && !is.na(dps) && (grepl("^\\s*<", dps) || (grepl("\\.xml$", dps, ignore.case = TRUE) &&
                                                                       file.exists(dps)))) {
    documento = ler_o_xml_para_assinar(dps)
    informacoes = xml2::xml_find_all(documento, "//*[local-name()='infDPS']")
    if (length(informacoes) == 0) {
      stop("O XML n\u00e3o tem a DPS (o grupo infDPS).", call. = FALSE)
    }
    return(xml2::xml_attr(informacoes, "Id"))
  }
  identificadores = toupper(gsub("\\s", "", dps))
  sem_prefixo = !is.na(identificadores) & !startsWith(identificadores, "DPS")
  identificadores[sem_prefixo] = paste0("DPS", identificadores[sem_prefixo])
  identificadores
}

# A linha da DPS, com o endereço da consulta na Sefin, ou com o problema quando o identificador não tem o formato do
# TSIdDPS.
comeco_da_situacao_da_dps = function(identificador, ambiente, endereco_da_sefin) {
  linha = data.frame(
    dps = identificador, ambiente = ambiente, encontrada = FALSE, situacao_http = NA_integer_, codigo = NA_character_,
    motivo = NA_character_, processamento = as.POSIXct(NA), versao_aplicativo = NA_character_, chave = NA_character_,
    xml = NA_character_, endereco = NA_character_, problema = NA_character_
  )
  if (is.na(identificador) || !grepl("^DPS[0-9]{7}(1[0-9]{14}|2[0-9A-Z]{14})[0-9]{20}$", identificador)) {
    linha$problema = paste("identificador inv\u00e1lido: o da DPS \u00e9 \"DPS\", o munic\u00edpio (7), o tipo e a inscri\u00e7\u00e3o",
                           "do emitente (1 e 14), a s\u00e9rie (5) e o n\u00famero (15)")
    return(linha)
  }
  linha$endereco = paste0(endereco_da_sefin, "/dps/", identificador)
  linha
}

# A resposta da Sefin à consulta da DPS: a chave da nota gerada, ou o erro. Só a DPS que não gerou nota (404) é
# resposta; os outros erros (o pedido recusado, o limite de consultas, a Sefin fora do ar) não dizem se ela gerou, e
# vão para o problema.
completar_situacao_da_dps = function(linha, resposta_lida, ambiente) {
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
  linha$versao_aplicativo = texto_do_json(valor_no_json(json, "versaoAplicativo"))
  linha$codigo = texto_do_json(valor_no_json(json, "erro", "codigo"))
  linha$motivo = texto_do_json(valor_no_json(json, "erro", "descricao"))
  complemento = texto_do_json(valor_no_json(json, "erro", "complemento"))
  if (!is.na(complemento) && nzchar(complemento)) {
    linha$motivo = paste0(linha$motivo, " (", complemento, ")")
  }
  if (!identical(texto_do_json(valor_no_json(json, "tipoAmbiente")), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a NFS-e Nacional respondeu de outro ambiente"
    return(linha)
  }
  if (identical(linha$situacao_http, 404L)) {
    return(linha)
  }
  if (!identical(linha$situacao_http, 200L)) {
    linha$problema = paste0("a Sefin respondeu com erro (HTTP ", linha$situacao_http, "): a consulta n\u00e3o diz se a DPS ",
                            "gerou a nota")
    return(linha)
  }
  if (!identical(texto_do_json(valor_no_json(json, "idDps")), linha$dps)) {
    linha$problema = "a Sefin respondeu sobre outra DPS"
    return(linha)
  }
  chave = texto_do_json(valor_no_json(json, "chaveAcesso"))
  if (is.na(chave) || !grepl(FORMATO_DA_CHAVE_DA_NFSE, chave)) {
    linha$problema = "a Sefin respondeu sem a chave da nota (50 posi\u00e7\u00f5es)"
    return(linha)
  }
  linha$chave = chave
  linha$encontrada = TRUE
  linha
}

# A linha da chave, com o endereço da consulta na Sefin, ou com o problema quando a chave não tem o formato.
comeco_da_situacao_da_nfse = function(chave, ambiente, endereco_da_sefin) {
  linha = data.frame(
    chave = chave, ambiente = ambiente, encontrada = FALSE, situacao_http = NA_integer_, codigo = NA_character_,
    motivo = NA_character_, processamento = as.POSIXct(NA), versao_aplicativo = NA_character_, xml = NA_character_,
    endereco = NA_character_, problema = NA_character_
  )
  if (is.na(chave) || !grepl(FORMATO_DA_CHAVE_DA_NFSE, chave)) {
    linha$problema = "chave inv\u00e1lida: a da NFS-e Nacional tem 50 posi\u00e7\u00f5es"
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
  # Sem o tipoAmbiente, a resposta não é a da Sefin (um erro do servidor no formato dele, por exemplo).
  if (is.null(valor_no_json(json, "tipoAmbiente"))) {
    linha$problema = resposta_fora_do_formato(resposta_lida, "da Sefin Nacional")
    return(linha)
  }
  linha$processamento = data_hora_da_consulta(texto_do_json(valor_no_json(json, "dataHoraProcessamento")))
  linha$versao_aplicativo = texto_do_json(valor_no_json(json, "versaoAplicativo"))
  linha$codigo = texto_do_json(valor_no_json(json, "erro", "codigo"))
  linha$motivo = texto_do_json(valor_no_json(json, "erro", "descricao"))
  complemento = texto_do_json(valor_no_json(json, "erro", "complemento"))
  if (!is.na(complemento) && nzchar(complemento)) {
    linha$motivo = paste0(linha$motivo, " (", complemento, ")")
  }
  if (!identical(texto_do_json(valor_no_json(json, "tipoAmbiente")), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a NFS-e Nacional respondeu de outro ambiente"
    return(linha)
  }
  if (!identical(linha$situacao_http, 200L)) {
    return(linha)
  }
  if (!identical(texto_do_json(valor_no_json(json, "chaveAcesso")), linha$chave)) {
    linha$problema = "a Sefin respondeu com outra chave"
    return(linha)
  }
  xml = tryCatch(texto_do_gzip_em_base64(texto_do_json(valor_no_json(json, "nfseXmlGZipB64"))), error = function(erro) NA_character_)
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
#' `"NENHUM_DOCUMENTO_LOCALIZADO"`; com `problema` preenchido, pare e veja o
#' motivo. Um documento cujo XML não abriu fica na tabela, com o `xml` vazio
#' e o NSU dele em `problema`. A documentação do ADN não fala de espera nem de
#' bloqueio, como as da NF-e e do CT-e; mesmo assim, não pergunte em laço sem
#' pausa.
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
  # O maior NSU que veio, comparado como texto (pelo tamanho e depois pelos dígitos): acima de 2^53 o número do R perde
  # dígitos.
  nsus_que_vieram = documentos$nsu[!is.na(documentos$nsu)]
  if (length(nsus_que_vieram) > 0) {
    consulta$ultimo_nsu = nsus_que_vieram[order(nchar(nsus_que_vieram), nsus_que_vieram, decreasing = TRUE)][1]
  }
  list(consulta = consulta, documentos = documentos)
}

# O NSU no caminho do pedido: só dígitos, sem os zeros da frente (o ADN o trata como número inteiro de 64 bits).
nsu_do_adn = function(nsu) {
  if (is.numeric(nsu)) {
    if (length(nsu) == 1 && !is.na(nsu) && (nsu != floor(nsu) || nsu > 2^53)) {
      stop("O NSU \u00e9 um n\u00famero inteiro; acima de 2^53, passe como texto (o n\u00famero do R perde d\u00edgitos).", call. = FALSE)
    }
    nsu = format(nsu, scientific = FALSE, trim = TRUE)
  }
  nsu = as.character(nsu)
  if (length(nsu) != 1 || is.na(nsu) || !grepl("^[0-9]{1,19}$", nsu)) {
    stop("O NSU tem de ter de 1 a 19 d\u00edgitos.", call. = FALSE)
  }
  nsu = sub("^0+([0-9])", "\\1", nsu)
  if (nchar(nsu) == 19 && nsu > "9223372036854775807") {
    stop("O NSU passa do maior inteiro de 64 bits.", call. = FALSE)
  }
  nsu
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
  # O número grande (o NSU) vem como texto, para não perder dígitos.
  json = tryCatch(jsonlite::fromJSON(texto, simplifyVector = FALSE, bigint_as_char = TRUE), error = function(erro) NULL)
  if (is.null(json)) {
    return(list(json = NULL, situacao_http = as.integer(resposta$situacao_http),
                problema = paste0("HTTP ", resposta$situacao_http, ": a resposta n\u00e3o veio em JSON")))
  }
  if (!is.list(json)) {
    return(list(json = NULL, situacao_http = as.integer(resposta$situacao_http),
                problema = paste0("HTTP ", resposta$situacao_http, ": a resposta n\u00e3o \u00e9 a de sempre (", texto_do_json(json[1]), ")")))
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
  # Sem o TipoAmbiente, a resposta não é a do ADN (um erro do servidor no formato dele, por exemplo).
  if (is.null(valor_no_json(json, "TipoAmbiente"))) {
    lida$problema = resposta_fora_do_formato(resposta_lida, "do ADN")
    return(lida)
  }
  lida$situacao = texto_do_json(valor_no_json(json, "StatusProcessamento"))
  lida$tipo_consulta = texto_do_json(valor_no_json(json, "TipoConsulta"))
  codigos_dos_erros = textos_das_mensagens_do_adn(valor_no_json(json, "Erros"), "Codigo")
  lida$codigo = juntar_ou_na(codigos_dos_erros)
  lida$motivo = juntar_ou_na(textos_das_mensagens_do_adn(valor_no_json(json, "Erros"), "Descricao"))
  alertas = character()
  for (alerta in valor_no_json(json, "Alertas")) {
    partes_do_alerta = c(texto_do_json(valor_no_json(alerta, "Codigo")), texto_do_json(valor_no_json(alerta, "Descricao")))
    if (any(!is.na(partes_do_alerta))) {
      alertas = c(alertas, paste(partes_do_alerta[!is.na(partes_do_alerta)], collapse = " "))
    }
  }
  lida$alertas = juntar_ou_na(alertas)
  lida$processamento = data_hora_da_consulta(texto_do_json(valor_no_json(json, "DataHoraProcessamento")))
  lida$versao_aplicativo = texto_do_json(valor_no_json(json, "VersaoAplicativo"))
  if (!identical(texto_do_json(valor_no_json(json, "TipoAmbiente")), AMBIENTE_NA_RESPOSTA_DO_ADN[[ambiente]])) {
    lida$problema = "o ADN respondeu de outro ambiente"
    return(lida)
  }
  # O código e a descrição do erro, o que vier.
  erro_do_adn = c(lida$codigo, lida$motivo)
  erro_do_adn = paste(erro_do_adn[!is.na(erro_do_adn)], collapse = " ")
  if (identical(lida$situacao, "REJEICAO")) {
    if (erro_do_adn == "") {
      lida$problema = "o ADN rejeitou o pedido sem dizer o motivo"
    } else {
      lida$problema = paste0("o ADN rejeitou o pedido: ", erro_do_adn)
    }
    return(lida)
  }
  if (identical(lida$situacao, "NENHUM_DOCUMENTO_LOCALIZADO") && !all(codigos_dos_erros %in% CODIGOS_DE_NENHUM_DOCUMENTO)) {
    lida$problema = paste0("o ADN n\u00e3o entregou: ", erro_do_adn)
    return(lida)
  }
  linhas = list()
  que_nao_abriram = character()
  for (documento in valor_no_json(json, "LoteDFe")) {
    nsu = texto_do_json(valor_no_json(documento, "NSU"))
    xml = tryCatch(texto_do_gzip_em_base64(texto_do_json(valor_no_json(documento, "ArquivoXml"))), error = function(erro) NA_character_)
    if (is.na(xml)) {
      que_nao_abriram = c(que_nao_abriram, nsu)
    }
    linhas[[length(linhas) + 1]] = data.frame(
      nsu = nsu, chave = texto_do_json(valor_no_json(documento, "ChaveAcesso")),
      tipo_documento = texto_do_json(valor_no_json(documento, "TipoDocumento")),
      tipo_evento = texto_do_json(valor_no_json(documento, "TipoEvento")),
      gerado_em = data_hora_da_consulta(texto_do_json(valor_no_json(documento, "DataHoraGeracao"))),
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

# Um campo (o Codigo ou a Descricao) de cada mensagem do ADN; o que vem vazio (null) fica de fora.
textos_das_mensagens_do_adn = function(mensagens, campo) {
  textos = character()
  if (!is.list(mensagens)) {
    return(textos)
  }
  for (mensagem in mensagens) {
    texto = texto_do_json(valor_no_json(mensagem, campo))
    if (!is.na(texto)) {
      textos = c(textos, texto)
    }
  }
  textos
}

juntar_ou_na = function(textos) {
  if (length(textos) == 0) {
    return(NA_character_)
  }
  paste(textos, collapse = "; ")
}

# O problema de uma resposta que não tem os campos de sempre, com o título que o servidor pôs, quando pôs.
resposta_fora_do_formato = function(resposta_lida, quem_responde) {
  problema = paste0("HTTP ", resposta_lida$situacao_http, ": a resposta n\u00e3o \u00e9 a ", quem_responde)
  titulo = texto_do_json(valor_no_json(resposta_lida$json, "title"))
  if (!is.na(titulo)) {
    problema = paste0(problema, " (", titulo, ")")
  }
  problema
}

# Um valor dentro do JSON pelo caminho de nomes (valor_no_json(json, "erro", "codigo")): o que não existe, ou um passo
# que não é um objeto, vira NULL.
valor_no_json = function(json, ...) {
  valor = json
  for (nome in c(...)) {
    if (!is.list(valor) || is.null(valor[[nome]])) {
      return(NULL)
    }
    valor = valor[[nome]]
  }
  valor
}

# Um valor do JSON como texto; o que não veio (NULL) ou não é um valor simples, como NA. O número sai sem notação
# científica.
texto_do_json = function(valor) {
  if (is.null(valor) || is.list(valor) || length(valor) == 0) {
    return(NA_character_)
  }
  if (is.numeric(valor)) {
    return(format(valor, scientific = FALSE, trim = TRUE))
  }
  as.character(valor)
}
