# A situação cadastral do CNPJ na Receita Federal, pelas fontes públicas que republicam o cadastro: a BrasilAPI
# primeiro e, quando ela está fora do ar, as outras, uma depois da outra.

#' @include chave.R nfse_nacional.R
NULL

# As fontes, na ordem em que são tentadas. A BrasilAPI busca no Minha Receita; a CNPJá, a ReceitaWS e a CNPJ.ws são
# independentes dele. Todas são públicas, sem cadastro nem chave (conferido em 04/11/2026). A ReceitaWS e a CNPJ.ws
# disseram, nos cabeçalhos, que aceitam 3 consultas por minuto; por isso vão por último.
FONTES_DO_CNPJ = utils::read.table(header = TRUE, sep = ";", strip.white = TRUE, stringsAsFactors = FALSE, text = "
fonte        ; endereco
brasilapi    ; https://brasilapi.com.br/api/cnpj/v1/
minhareceita ; https://minhareceita.org/
cnpja        ; https://open.cnpja.com/office/
receitaws    ; https://receitaws.com.br/v1/cnpj/
cnpjws       ; https://publica.cnpj.ws/cnpj/
", colClasses = "character")
TEMPO_LIMITE_DAS_FONTES_DO_CNPJ = 15

#' Situação do CNPJ na Receita Federal
#'
#' Diz a situação cadastral de cada CNPJ (ATIVA, BAIXADA, INAPTA, SUSPENSA ou
#' NULA), com a data e o motivo, a razão social e o nome fantasia. Pergunta
#' primeiro à BrasilAPI e, quando ela está fora do ar, às outras fontes, uma
#' depois da outra: o Minha Receita, a CNPJá, a ReceitaWS e a CNPJ.ws. Todas
#' são públicas e republicam o cadastro da Receita; não precisa de certificado.
#'
#' Fora do ar quer dizer sem resposta, a resposta de limite de consultas (429),
#' erro do servidor (5xx) ou uma resposta que não é a de sempre. Um CNPJ que a
#' fonte não acha é resposta, não falha: ele não é procurado na próxima, e
#' `encontrado` fica `FALSE`. CNPJ com o dígito errado nem é perguntado.
#'
#' Os dados de cada fonte têm a sua data: a BrasilAPI e o Minha Receita usam os
#' dados abertos da Receita e não dizem a data no registro; a CNPJá, a
#' ReceitaWS e a CNPJ.ws dizem (`atualizado_em`). O texto do motivo é o que a
#' fonte escreve (com ou sem acento, em maiúsculas ou não); a CNPJ.ws não manda
#' o motivo. A ReceitaWS e a CNPJ.ws aceitam poucas consultas por minuto (3,
#' pelo que disseram em 04/11/2026): para muitos CNPJs, a BrasilAPI é a que dá
#' conta.
#'
#' Precisa dos pacotes `httr2` e `jsonlite`.
#'
#' @param cnpjs Os CNPJs: um texto ou um vetor. Pontos, barras e traços são
#'   ignorados; o CNPJ com letras (alfanumérico) é aceito.
#' @param fontes As fontes, na ordem em que são tentadas: todas, se nada for
#'   dito. Dá para tirar alguma ou trocar a ordem.
#' @return Um `data.frame` com uma linha por CNPJ: `cnpj`, `encontrado`
#'   (`TRUE`, `FALSE` quando a fonte não tem o CNPJ, `NA` quando nenhuma
#'   respondeu), `situacao`, `data_situacao`, `motivo_situacao`,
#'   `situacao_especial` e `data_situacao_especial`, `razao_social`,
#'   `nome_fantasia`, `atualizado_em` (quando a fonte diz de quando são os
#'   dados, no horário de Brasília), `fonte` (a que respondeu), `mensagem` (o
#'   que a fonte disse quando não achou), `fontes_fora_do_ar` (as que foram
#'   tentadas antes e não responderam, com o motivo) e `problema` (vazio quando
#'   alguma fonte respondeu).
#' @seealso [sefaz_cadastro()] para a inscrição estadual, na SEFAZ.
#' @source As respostas de cada fonte, conferidas em 04/11/2026 com um CNPJ
#'   ativo, um baixado e um que não existe: a BrasilAPI
#'   (`/api/cnpj/v1/<cnpj>`, que busca no Minha Receita, pelo código dela no
#'   GitHub), o Minha Receita (documentação em docs.minhareceita.org), a CNPJá
#'   (`open.cnpja.com/office/<cnpj>`), a ReceitaWS (`/v1/cnpj/<cnpj>`) e a
#'   CNPJ.ws (`publica.cnpj.ws/cnpj/<cnpj>`).
#' @examples
#' \dontrun{
#' cnpj_situacao(c("11.222.333/0001-81", "11.444.777/0001-61"))
#' # Só as fontes que não limitam tanto as consultas
#' cnpj_situacao("11222333000181", fontes = c("brasilapi", "minhareceita", "cnpja"))
#' }
#' @export
cnpj_situacao = function(cnpjs, fontes = c("brasilapi", "minhareceita", "cnpja", "receitaws", "cnpjws")) {
  fontes = as.character(fontes)
  if (length(fontes) == 0 || anyNA(fontes) || !all(fontes %in% FONTES_DO_CNPJ$fonte)) {
    stop("Informe as fontes entre ", paste0('"', FONTES_DO_CNPJ$fonte, '"', collapse = ", "), ".", call. = FALSE)
  }
  exigir_pacotes(c("httr2", "jsonlite"))
  cnpjs_limpos = toupper(gsub("[^0-9A-Za-z]", "", as.character(cnpjs)))
  linhas = list()
  for (posicao in seq_along(cnpjs_limpos)) {
    linhas[[posicao]] = situacao_de_um_cnpj(cnpjs_limpos[posicao], fontes)
  }
  if (length(linhas) == 0) {
    return(linha_do_cnpj(NA_character_)[0, ])
  }
  situacoes = do.call(rbind, linhas)
  # Juntar as linhas tira o fuso das datas: volta o de Brasília.
  attr(situacoes$atualizado_em, "tzone") = "America/Sao_Paulo"
  situacoes
}

linha_do_cnpj = function(cnpj) {
  data.frame(
    cnpj = cnpj, encontrado = NA, situacao = NA_character_, data_situacao = as.Date(NA), motivo_situacao = NA_character_,
    situacao_especial = NA_character_, data_situacao_especial = as.Date(NA), razao_social = NA_character_,
    nome_fantasia = NA_character_, atualizado_em = as.POSIXct(NA), fonte = NA_character_, mensagem = NA_character_,
    fontes_fora_do_ar = NA_character_, problema = NA_character_
  )
}

# Uma fonte depois da outra, até uma responder (achando ou não o CNPJ).
situacao_de_um_cnpj = function(cnpj, fontes) {
  linha = linha_do_cnpj(cnpj)
  if (is.na(cnpj) || !cnpj_confere(cnpj)) {
    linha$problema = "CNPJ inv\u00e1lido: o formato ou o d\u00edgito n\u00e3o confere"
    return(linha)
  }
  fora_do_ar = character()
  for (fonte in fontes) {
    resposta = perguntar_a_fonte(fonte, cnpj)
    if (resposta$resultado == "fora do ar") {
      fora_do_ar = c(fora_do_ar, paste0(fonte, " (", resposta$motivo, ")"))
      next
    }
    linha$fonte = fonte
    if (resposta$resultado == "n\u00e3o achou") {
      linha$encontrado = FALSE
      linha$mensagem = resposta$mensagem
    } else {
      linha = preencher_com_a_fonte(linha, fonte, resposta$json)
    }
    break
  }
  if (length(fora_do_ar) > 0) {
    linha$fontes_fora_do_ar = paste(fora_do_ar, collapse = "; ")
  }
  if (is.na(linha$fonte)) {
    linha$problema = "nenhuma fonte respondeu"
  }
  linha
}

# A resposta de uma fonte: "achou" (200, com o JSON), "não achou" (404 com a mensagem da fonte, ou o status ERROR da
# ReceitaWS, que responde 200) ou "fora do ar" (sem resposta, 429, 5xx, ou o que não é a resposta de sempre).
perguntar_a_fonte = function(fonte, cnpj) {
  pedido = httr2::request(paste0(FONTES_DO_CNPJ$endereco[FONTES_DO_CNPJ$fonte == fonte], cnpj))
  pedido = httr2::req_headers(pedido, Accept = "application/json")
  pedido = httr2::req_user_agent(pedido, "RNFe (https://github.com/biuspoly/RNFe)")
  pedido = httr2::req_timeout(pedido, TEMPO_LIMITE_DAS_FONTES_DO_CNPJ)
  pedido = httr2::req_error(pedido, is_error = function(resposta) FALSE)
  resposta = tryCatch(httr2::req_perform(pedido), error = function(erro) erro)
  if (inherits(resposta, "error")) {
    return(list(resultado = "fora do ar", motivo = paste("sem resposta:", gsub("\\s+", " ", conditionMessage(resposta)))))
  }
  situacao_http = httr2::resp_status(resposta)
  json = NULL
  if (httr2::resp_has_body(resposta)) {
    texto = rawToChar(httr2::resp_body_raw(resposta))
    Encoding(texto) = "UTF-8"
    json = tryCatch(jsonlite::fromJSON(texto, simplifyVector = FALSE), error = function(erro) NULL)
  }
  if (situacao_http == 404 && is.list(json)) {
    # A BrasilAPI, o Minha Receita e a CNPJá dizem em "message"; a CNPJ.ws, em "detalhes".
    mensagem = texto_da_fonte(valor_no_json(json, "message"))
    if (is.na(mensagem)) {
      mensagem = texto_da_fonte(valor_no_json(json, "detalhes"))
    }
    if (!is.na(mensagem)) {
      return(list(resultado = "n\u00e3o achou", mensagem = mensagem))
    }
  }
  if (situacao_http != 200 || !is.list(json)) {
    return(list(resultado = "fora do ar", motivo = paste("HTTP", situacao_http)))
  }
  if (fonte == "receitaws" && identical(texto_da_fonte(valor_no_json(json, "status")), "ERROR")) {
    return(list(resultado = "n\u00e3o achou", mensagem = texto_da_fonte(valor_no_json(json, "message"))))
  }
  # O 200 tem de trazer a situação no lugar de sempre da fonte; sem ela ({}, ou um aviso de manutenção em JSON), a fonte
  # conta como fora do ar.
  if (is.na(texto_da_fonte(campos_da_fonte(fonte, json)$situacao))) {
    return(list(resultado = "fora do ar", motivo = "resposta fora do formato"))
  }
  list(resultado = "achou", json = json)
}

# Os campos da resposta de cada fonte, cada uma no seu formato (conferido em 04/11/2026). O que não está lá vem NULL.
campos_da_fonte = function(fonte, json) {
  if (fonte %in% c("brasilapi", "minhareceita")) {
    return(list(situacao = valor_no_json(json, "descricao_situacao_cadastral"),
                data_situacao = valor_no_json(json, "data_situacao_cadastral"),
                motivo_situacao = valor_no_json(json, "descricao_motivo_situacao_cadastral"),
                situacao_especial = valor_no_json(json, "situacao_especial"),
                data_situacao_especial = valor_no_json(json, "data_situacao_especial"),
                razao_social = valor_no_json(json, "razao_social"), nome_fantasia = valor_no_json(json, "nome_fantasia"),
                atualizado_em = NULL))
  }
  if (fonte == "cnpja") {
    return(list(situacao = valor_no_json(json, "status", "text"), data_situacao = valor_no_json(json, "statusDate"),
                motivo_situacao = valor_no_json(json, "reason", "text"), situacao_especial = NULL,
                data_situacao_especial = NULL, razao_social = valor_no_json(json, "company", "name"),
                nome_fantasia = valor_no_json(json, "alias"), atualizado_em = valor_no_json(json, "updated")))
  }
  if (fonte == "receitaws") {
    return(list(situacao = valor_no_json(json, "situacao"), data_situacao = valor_no_json(json, "data_situacao"),
                motivo_situacao = valor_no_json(json, "motivo_situacao"),
                situacao_especial = valor_no_json(json, "situacao_especial"),
                data_situacao_especial = valor_no_json(json, "data_situacao_especial"),
                razao_social = valor_no_json(json, "nome"), nome_fantasia = valor_no_json(json, "fantasia"),
                atualizado_em = valor_no_json(json, "ultima_atualizacao")))
  }
  # A CNPJ.ws: a situação fica no estabelecimento, e o motivo não vem (veio vazio também no CNPJ baixado).
  list(situacao = valor_no_json(json, "estabelecimento", "situacao_cadastral"),
       data_situacao = valor_no_json(json, "estabelecimento", "data_situacao_cadastral"), motivo_situacao = NULL,
       situacao_especial = valor_no_json(json, "estabelecimento", "situacao_especial"),
       data_situacao_especial = valor_no_json(json, "estabelecimento", "data_situacao_especial"),
       razao_social = valor_no_json(json, "razao_social"),
       nome_fantasia = valor_no_json(json, "estabelecimento", "nome_fantasia"),
       atualizado_em = valor_no_json(json, "estabelecimento", "atualizado_em"))
}

# Os campos da fonte na linha do CNPJ.
preencher_com_a_fonte = function(linha, fonte, json) {
  campos = campos_da_fonte(fonte, json)
  linha$encontrado = TRUE
  linha$situacao = toupper(texto_da_fonte(campos$situacao))
  linha$data_situacao = data_da_fonte(texto_da_fonte(campos$data_situacao))
  linha$motivo_situacao = texto_da_fonte(campos$motivo_situacao)
  linha$situacao_especial = texto_da_fonte(campos$situacao_especial)
  linha$data_situacao_especial = data_da_fonte(texto_da_fonte(campos$data_situacao_especial))
  linha$razao_social = texto_da_fonte(campos$razao_social)
  linha$nome_fantasia = texto_da_fonte(campos$nome_fantasia)
  linha$atualizado_em = data_hora_da_consulta(texto_da_fonte(campos$atualizado_em))
  linha
}

# Um campo da fonte como texto: o que não veio, veio vazio ou não é um valor simples vira NA.
texto_da_fonte = function(valor) {
  if (is.null(valor) || is.list(valor) || length(valor) != 1) {
    return(NA_character_)
  }
  texto = trimws(as.character(valor))
  if (is.na(texto) || texto == "") {
    return(NA_character_)
  }
  texto
}

# A data como a fonte escreve: AAAA-MM-DD, ou DD/MM/AAAA na ReceitaWS.
data_da_fonte = function(texto) {
  if (is.na(texto)) {
    return(as.Date(NA))
  }
  if (grepl("^[0-9]{2}/[0-9]{2}/[0-9]{4}$", texto)) {
    return(as.Date(texto, format = "%d/%m/%Y"))
  }
  as.Date(substr(texto, 1, 10), format = "%Y-%m-%d")
}
