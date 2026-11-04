# Sem rede: o httr2 devolve a resposta no lugar das fontes. respostas/cnpj/ tem respostas montadas à mão no formato
# que cada fonte devolveu em 04/11/2026 (os mesmos campos), com os CNPJs fictícios e nomes inventados: 11.222.333/0001-81
# ativo, 11.444.777/0001-61 baixado e o exemplo da Receita, 12.ABC.345/01DE-35, que as fontes não acham.
CNPJ_ATIVO = "11222333000181"
CNPJ_BAIXADO = "11444777000161"
CNPJ_QUE_NAO_EXISTE = "12ABC34501DE35"

resposta_da_fonte = function(fonte, cnpj, situacao_http) {
  texto = paste(readLines(test_path("respostas", "cnpj", paste0(fonte, "_", cnpj, ".json")), encoding = "UTF-8", warn = FALSE),
                collapse = "")
  httr2::response(status_code = situacao_http, headers = "Content-Type: application/json; charset=utf-8",
                  body = charToRaw(enc2utf8(texto)))
}

# O nome da fonte pelo endereço do pedido.
fonte_do_pedido = function(req) {
  enderecos = c(brasilapi = "https://brasilapi.com.br/", minhareceita = "https://minhareceita.org/",
                cnpja = "https://open.cnpja.com/", receitaws = "https://receitaws.com.br/", cnpjws = "https://publica.cnpj.ws/")
  names(enderecos)[startsWith(req$url, enderecos)]
}

test_that("fonte desconhecida \u00e9 recusada, e CNPJ com o d\u00edgito errado nem \u00e9 perguntado", {
  expect_error(cnpj_situacao(CNPJ_ATIVO, fontes = "receita"), "fontes")
  expect_error(cnpj_situacao(CNPJ_ATIVO, fontes = character()), "fontes")
  skip_if_not_installed("httr2")
  skip_if_not_installed("jsonlite")
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_fonte("brasilapi", CNPJ_ATIVO, 200)
  })
  situacoes = cnpj_situacao(c("11.222.333/0001-82", NA, "123"))
  expect_identical(situacoes$problema, rep("CNPJ inv\u00e1lido: o formato ou o d\u00edgito n\u00e3o confere", 3))
  expect_identical(situacoes$encontrado, rep(NA, 3))
  expect_length(pedidos, 0)
  vazio = cnpj_situacao(character())
  expect_identical(nrow(vazio), 0L)
  expect_identical(names(vazio), names(situacoes))
})

test_that("a BrasilAPI responde: o pedido que vai e a situa\u00e7\u00e3o em colunas", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("jsonlite")
  pedidos = list()
  httr2::local_mocked_responses(function(req) {
    pedidos[[length(pedidos) + 1]] <<- req
    resposta_da_fonte("brasilapi", CNPJ_ATIVO, 200)
  })
  situacao = cnpj_situacao("11.222.333/0001-81")
  expect_identical(situacao$cnpj, CNPJ_ATIVO)
  expect_true(situacao$encontrado)
  expect_identical(situacao$situacao, "ATIVA")
  expect_identical(situacao$data_situacao, as.Date("2005-11-03"))
  expect_identical(situacao$motivo_situacao, "SEM MOTIVO")
  expect_true(is.na(situacao$situacao_especial))
  expect_true(is.na(situacao$data_situacao_especial))
  expect_identical(situacao$razao_social, "EMPRESA FICTICIA DE TESTE LTDA")
  expect_identical(situacao$nome_fantasia, "MATRIZ FICTICIA")
  expect_true(is.na(situacao$atualizado_em))
  expect_identical(situacao$fonte, "brasilapi")
  expect_true(is.na(situacao$fontes_fora_do_ar))
  expect_true(is.na(situacao$problema))
  expect_length(pedidos, 1)
  expect_identical(pedidos[[1]]$url, paste0("https://brasilapi.com.br/api/cnpj/v1/", CNPJ_ATIVO))
  expect_identical(pedidos[[1]]$headers$Accept, "application/json")
  expect_match(pedidos[[1]]$options$useragent, "^RNFe ")
})

test_that("cada fonte, no seu formato, d\u00e1 a mesma situa\u00e7\u00e3o do CNPJ baixado", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("jsonlite")
  httr2::local_mocked_responses(function(req) resposta_da_fonte(fonte_do_pedido(req), CNPJ_BAIXADO, 200))
  motivos = c(brasilapi = "EXTINCAO POR ENCERRAMENTO LIQUIDACAO VOLUNTARIA",
              minhareceita = "EXTINCAO POR ENCERRAMENTO LIQUIDACAO VOLUNTARIA",
              cnpja = "Extin\u00e7\u00e3o por encerramento liquida\u00e7\u00e3o volunt\u00e1ria",
              receitaws = "EXTIN\u00c7\u00c3O POR ENCERRAMENTO LIQUIDA\u00c7\u00c3O VOLUNT\u00c1RIA",
              cnpjws = NA)
  # As três dizem a data em UTC (o Z do fim).
  atualizacoes = c(brasilapi = NA, minhareceita = NA, cnpja = "2026-10-10 23:59:59", receitaws = "2026-10-13 23:59:59",
                   cnpjws = "2026-10-10 03:00:00")
  for (fonte in names(motivos)) {
    situacao = cnpj_situacao(CNPJ_BAIXADO, fontes = fonte)
    expect_identical(situacao$fonte, fonte)
    expect_true(situacao$encontrado)
    expect_identical(situacao$situacao, "BAIXADA")
    expect_identical(situacao$data_situacao, as.Date("2020-07-29"))
    expect_identical(situacao$motivo_situacao, unname(motivos[fonte]))
    expect_identical(situacao$razao_social, "OUTRA EMPRESA FICTICIA SA")
    expect_identical(toupper(situacao$nome_fantasia), "LOJA FICTICIA (CE)")
    expect_true(is.na(situacao$situacao_especial))
    if (is.na(atualizacoes[fonte])) {
      expect_true(is.na(situacao$atualizado_em))
    } else {
      expect_equal(as.numeric(situacao$atualizado_em), as.numeric(as.POSIXct(atualizacoes[[fonte]], tz = "UTC")))
    }
  }
})

test_that("o CNPJ que uma fonte n\u00e3o tem \u00e9 procurado na pr\u00f3xima; o Minha Receita s\u00f3 sem a BrasilAPI", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("jsonlite")
  pedidos = character()
  httr2::local_mocked_responses(function(req) {
    fonte = fonte_do_pedido(req)
    pedidos <<- c(pedidos, fonte)
    # A ReceitaWS diz que não achou com 200 e o status ERROR.
    if (fonte == "receitaws") {
      return(resposta_da_fonte(fonte, CNPJ_QUE_NAO_EXISTE, 200))
    }
    resposta_da_fonte(fonte, CNPJ_QUE_NAO_EXISTE, 404)
  })
  # Nenhuma acha: todas são perguntadas, menos o Minha Receita, porque a BrasilAPI respondeu.
  situacao = cnpj_situacao(CNPJ_QUE_NAO_EXISTE)
  expect_identical(pedidos, c("brasilapi", "cnpja", "receitaws", "cnpjws"))
  expect_false(situacao$encontrado)
  expect_true(is.na(situacao$fonte))
  expect_identical(situacao$mensagem, paste0(
    "brasilapi: CNPJ 12.ABC.345/01DE-35 n\u00e3o encontrado.; cnpja: tax id not registered at revenue service; ",
    "receitaws: CNPJ rejeitado pela Receita Federal; cnpjws: Recurso n\u00e3o encontrado"
  ))
  expect_true(is.na(situacao$situacao))
  expect_true(is.na(situacao$problema))
  # A BrasilAPI não acha e a CNPJá acha (o CNPJ aberto depois dos dados abertos que a BrasilAPI usa).
  pedidos = character()
  httr2::local_mocked_responses(function(req) {
    fonte = fonte_do_pedido(req)
    pedidos <<- c(pedidos, fonte)
    if (fonte == "brasilapi") {
      return(resposta_da_fonte(fonte, CNPJ_QUE_NAO_EXISTE, 404))
    }
    resposta_da_fonte(fonte, CNPJ_BAIXADO, 200)
  })
  situacao = cnpj_situacao(CNPJ_BAIXADO)
  expect_identical(pedidos, c("brasilapi", "cnpja"))
  expect_true(situacao$encontrado)
  expect_identical(situacao$fonte, "cnpja")
  expect_identical(situacao$situacao, "BAIXADA")
  expect_identical(situacao$mensagem, "brasilapi: CNPJ 12.ABC.345/01DE-35 n\u00e3o encontrado.")
  # A BrasilAPI fora do ar: aí o Minha Receita é perguntado.
  pedidos = character()
  httr2::local_mocked_responses(function(req) {
    fonte = fonte_do_pedido(req)
    pedidos <<- c(pedidos, fonte)
    if (fonte == "brasilapi") {
      return(httr2::response(status_code = 503))
    }
    resposta_da_fonte(fonte, CNPJ_BAIXADO, 200)
  })
  situacao = cnpj_situacao(CNPJ_BAIXADO)
  expect_identical(pedidos, c("brasilapi", "minhareceita"))
  expect_identical(situacao$fonte, "minhareceita")
  expect_true(is.na(situacao$mensagem))
})

test_that("fora do ar: sem resposta, limite, erro do servidor e resposta que n\u00e3o \u00e9 a de sempre passam para a pr\u00f3xima", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("jsonlite")
  pedidos = character()
  httr2::local_mocked_responses(function(req) {
    fonte = fonte_do_pedido(req)
    pedidos <<- c(pedidos, fonte)
    if (fonte == "brasilapi") {
      return(httr2::response(status_code = 503, headers = "Content-Type: application/json",
                             body = charToRaw('{"message":"Servi\\u00e7o indispon\\u00edvel","type":"service_error"}')))
    }
    if (fonte == "minhareceita") {
      stop("Timeout was reached")
    }
    if (fonte == "cnpja") {
      return(httr2::response(status_code = 429, body = charToRaw("Too Many Requests")))
    }
    if (fonte == "receitaws") {
      # Uma página 404 sem a mensagem da fonte não é "não achou".
      return(httr2::response(status_code = 404, headers = "Content-Type: text/html", body = charToRaw("<html>404</html>")))
    }
    resposta_da_fonte("cnpjws", CNPJ_BAIXADO, 200)
  })
  situacao = cnpj_situacao(CNPJ_BAIXADO)
  expect_identical(pedidos, c("brasilapi", "minhareceita", "cnpja", "receitaws", "cnpjws"))
  expect_identical(situacao$fonte, "cnpjws")
  expect_identical(situacao$situacao, "BAIXADA")
  expect_match(situacao$fontes_fora_do_ar,
               "^brasilapi \\(HTTP 503\\); minhareceita \\(sem resposta: .*Timeout was reached.*\\); cnpja \\(HTTP 429\\); receitaws \\(HTTP 404\\)$")
  expect_true(is.na(situacao$problema))
  # Nenhuma responde.
  httr2::local_mocked_responses(function(req) httr2::response(status_code = 502))
  situacao = cnpj_situacao(CNPJ_BAIXADO, fontes = c("brasilapi", "cnpja"))
  expect_true(is.na(situacao$encontrado))
  expect_true(is.na(situacao$fonte))
  expect_identical(situacao$fontes_fora_do_ar, "brasilapi (HTTP 502); cnpja (HTTP 502)")
  expect_identical(situacao$problema, "nenhuma fonte respondeu")
})

test_that("o 200 fora do formato conta como fora do ar, e o campo de outro tipo n\u00e3o derruba", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("jsonlite")
  httr2::local_mocked_responses(function(req) {
    fonte = fonte_do_pedido(req)
    if (fonte == "brasilapi") {
      return(httr2::response(status_code = 200, headers = "Content-Type: application/json", body = charToRaw("{}")))
    }
    if (fonte == "minhareceita") {
      return(httr2::response(status_code = 200, headers = "Content-Type: application/json",
                             body = charToRaw('{"message":"Servico em manutencao"}')))
    }
    if (fonte == "cnpja") {
      # O status como texto, e n\u00e3o o objeto de sempre.
      return(httr2::response(status_code = 200, headers = "Content-Type: application/json",
                             body = charToRaw('{"status":"Ativa","company":"x"}')))
    }
    resposta_da_fonte(fonte, CNPJ_BAIXADO, 200)
  })
  situacao = cnpj_situacao(CNPJ_BAIXADO, fontes = c("brasilapi", "minhareceita", "cnpja", "receitaws"))
  expect_identical(situacao$fonte, "receitaws")
  expect_identical(situacao$situacao, "BAIXADA")
  expect_identical(situacao$fontes_fora_do_ar, paste0("brasilapi (resposta fora do formato); minhareceita (resposta fora do ",
                                                      "formato); cnpja (resposta fora do formato)"))
})

test_that("cada CNPJ come\u00e7a de novo pela primeira fonte", {
  skip_if_not_installed("httr2")
  skip_if_not_installed("jsonlite")
  httr2::local_mocked_responses(function(req) {
    fonte = fonte_do_pedido(req)
    cnpj = sub("^.*/", "", req$url)
    if (fonte == "brasilapi" && cnpj == CNPJ_BAIXADO) {
      return(httr2::response(status_code = 500))
    }
    resposta_da_fonte(fonte, cnpj, 200)
  })
  situacoes = cnpj_situacao(c(CNPJ_BAIXADO, CNPJ_ATIVO), fontes = c("brasilapi", "cnpja"))
  expect_identical(situacoes$fonte, c("cnpja", "brasilapi"))
  expect_identical(situacoes$situacao, c("BAIXADA", "ATIVA"))
  expect_identical(attr(situacoes$atualizado_em, "tzone"), "America/Sao_Paulo")
})
