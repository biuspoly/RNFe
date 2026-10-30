# A conversa com os serviços web da SEFAZ (NF-e, modelo 55): o envelope SOAP 1.2, o certificado de cliente e o
# endereço de cada serviço, tirado da Relação de Serviços Web do Portal da NF-e (as tabelas servicos_sefaz e
# autorizadores_sefaz, geradas por ferramentas/gerar_tabelas.R). Por enquanto, só o ambiente de homologação.

#' @include chave.R certificado.R ler_xml.R
NULL

# O código de cada ambiente liberado (tpAmb). A produção fica de fora até o usuário liberar (decisão de 29/10/2026).
AMBIENTES_LIBERADOS = c(homologacao = 2L)
NAMESPACE_DA_NFE = "http://www.portalfiscal.inf.br/nfe"
TEMPO_LIMITE_DA_SEFAZ = 60

#' Status do serviço da NF-e na SEFAZ
#'
#' Pergunta à SEFAZ de cada UF se o serviço da NF-e (modelo 55) está no ar e
#' devolve um `data.frame` com uma linha por UF: o autorizador que atende a UF,
#' a `situacao` (107 quando está em operação), o `motivo` escrito pela SEFAZ, o
#' tempo médio de resposta e, quando a SEFAZ informa, a previsão de volta e uma
#' observação.
#'
#' Por enquanto o RNFe só fala com o ambiente de **homologação** (testes, sem
#' valor fiscal); o ambiente de produção é recusado.
#'
#' Cada UF é atendida pela própria SEFAZ ou por uma SEFAZ virtual (a SVRS ou a
#' SVAN), como diz a Relação de Serviços Web do Portal da NF-e. A conexão usa
#' o certificado digital A1 (veja [certificado_ler()]). Uma UF que não responde
#' não atrapalha as outras: o motivo fica em `problema`.
#'
#' Precisa dos pacotes `httr2`, `curl` e `openssl`.
#'
#' **No Windows não é preciso configurar nada.** Lá o curl do R usa o motor de
#' conexão segura do Windows (Schannel), que não conecta com BA, MG, MT, SP e a
#' SVAN (testado em 30/10/2026). Quando ele está ligado, o RNFe manda os
#' pedidos por um processo R separado, aberto com o motor OpenSSL, que conecta
#' com as 27 UFs; a sua sessão do R não muda. Isso custa uns 0,3 segundo a mais
#' por chamada, não por UF (medido em 30/10/2026). Quem já usa o OpenSSL (no
#' Linux, no Mac, ou com `CURL_SSL_BACKEND=openssl` no `.Renviron`) não paga
#' esse tempo.
#'
#' O certificado vai em PEM (o OpenSSL 3 não abre o `.pfx` com a cifra antiga
#' que os certificados costumam ter), num arquivo temporário apagado no fim,
#' com a chave cifrada pela própria senha; para o processo separado, a senha vai
#' numa variável de ambiente só dele, nunca num arquivo. O certificado do
#' servidor é sempre verificado, contra as raízes de sempre e a raiz v10 da
#' ICP-Brasil (a de SSL, que vem no pacote), que os servidores da SEFAZ usam.
#'
#' @param ufs As UFs pela sigla (`"SP"`, `"CE"`...): um texto ou um vetor.
#' @param certificado O caminho do certificado digital A1 (`.pfx` ou `.p12`).
#' @param senha A senha do certificado. Não escreva no script: leia de uma
#'   variável de ambiente com [Sys.getenv()].
#' @param ambiente `"homologacao"`, o único liberado por enquanto.
#' @return Um `data.frame` com `uf`, `autorizador` (a sigla da UF ou da SEFAZ
#'   virtual), `ambiente`, `situacao` (o código de status, `cStat`),
#'   `motivo`, `recebimento` (data e hora em que a SEFAZ recebeu a consulta, no
#'   horário de Brasília), `tempo_medio` (em segundos, dos últimos 5 minutos),
#'   `retorno_previsto` e `observacao` (quando o serviço está parado),
#'   `versao_aplicativo` (o sistema da SEFAZ que respondeu), `endereco` e
#'   `problema` (por que a consulta não deu certo; vazio quando deu).
#' @seealso [certificado_ler()]
#' @source Relação de Serviços Web do Portal da NF-e (endereços de
#'   homologação); o schema `leiauteConsStatServ_v4.00.xsd` do pacote de
#'   liberação 9q (pedido e resposta); o WSDL do serviço NFeStatusServico4
#'   (a mensagem em `nfeDadosMsg`, SOAP 1.2).
#' @examples
#' \dontrun{
#' sefaz_status(c("SP", "CE"), "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_status = function(ufs, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  exigir_pacotes(c("httr2", "curl", "openssl"))
  conferir_certificado(certificado, senha)
  # Os arquivos da conexão (o certificado em PEM, a lista de raízes, a tarefa do processo separado) ficam numa pasta
  # temporária, apagada no fim.
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  ufs = toupper(trimws(as.character(ufs)))
  # Primeiro a linha e o pedido de cada UF; depois os pedidos vão todos juntos (no Schannel, num processo só).
  linhas = list()
  pedidos = list()
  linha_de_cada_pedido = integer()
  for (posicao in seq_along(ufs)) {
    comeco = comeco_do_status(ufs[posicao], ambiente)
    linhas[[posicao]] = comeco$linha
    if (!is.null(comeco$pedido)) {
      pedidos[[length(pedidos) + 1]] = comeco$pedido
      linha_de_cada_pedido = c(linha_de_cada_pedido, posicao)
    }
  }
  respostas = enviar_pedidos(pedidos, conexao)
  for (numero_do_pedido in seq_along(respostas)) {
    posicao = linha_de_cada_pedido[numero_do_pedido]
    linhas[[posicao]] = completar_status(linhas[[posicao]], ler_resposta(respostas[[numero_do_pedido]]), ambiente)
  }
  if (length(linhas) == 0) {
    status = comeco_do_status(character(), ambiente)$linha
  } else {
    status = do.call(rbind, linhas)
  }
  # Juntar as linhas tira o fuso das datas: volta o de Brasília.
  attr(status$recebimento, "tzone") = "America/Sao_Paulo"
  attr(status$retorno_previsto, "tzone") = "America/Sao_Paulo"
  status
}

# A linha da UF (o autorizador e o endereço, ou o problema) e o pedido de status, quando dá para pedir.
comeco_do_status = function(uf, ambiente) {
  linha = data.frame(
    uf = NA_character_, autorizador = NA_character_, ambiente = ambiente, situacao = NA_integer_, motivo = NA_character_,
    recebimento = as.POSIXct(NA), tempo_medio = NA_integer_, retorno_previsto = as.POSIXct(NA), observacao = NA_character_,
    versao_aplicativo = NA_character_, endereco = NA_character_, problema = NA_character_
  )
  # Sem UF, a tabela vazia com as mesmas colunas.
  if (length(uf) == 0) {
    return(list(linha = linha[0, ], pedido = NULL))
  }
  linha$uf = as.character(uf)
  codigo_da_uf = names(UF_PELO_CODIGO)[match(uf, UF_PELO_CODIGO)]
  if (is.na(codigo_da_uf)) {
    linha$problema = "UF desconhecida"
    return(list(linha = linha, pedido = NULL))
  }
  servico = servico_da_uf(uf, "NfeStatusServico", ambiente)
  if (is.null(servico)) {
    linha$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz este servi\u00e7o para a UF"
    return(list(linha = linha, pedido = NULL))
  }
  linha$autorizador = servico$autorizador
  linha$endereco = servico$endereco
  mensagem = paste0(
    '<consStatServ xmlns="', NAMESPACE_DA_NFE, '" versao="4.00">',
    "<tpAmb>", AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb><cUF>", codigo_da_uf, "</cUF><xServ>STATUS</xServ>",
    "</consStatServ>"
  )
  list(linha = linha, pedido = montar_pedido(servico$endereco, "NFeStatusServico4", "nfeStatusServicoNF", mensagem))
}

# Os campos do retConsStatServ na linha da UF.
completar_status = function(linha, resposta_lida, ambiente) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  retorno = resposta_lida$retorno
  if (nome_local(retorno) != "retConsStatServ") {
    linha$problema = paste("a SEFAZ respondeu", nome_local(retorno), "no lugar de retConsStatServ")
    return(linha)
  }
  linha$situacao = as.integer(texto_do_retorno(retorno, "cStat"))
  linha$motivo = texto_do_retorno(retorno, "xMotivo")
  linha$recebimento = data_hora(texto_do_retorno(retorno, "dhRecbto"))
  linha$tempo_medio = as.integer(texto_do_retorno(retorno, "tMed"))
  linha$retorno_previsto = data_hora(texto_do_retorno(retorno, "dhRetorno"))
  linha$observacao = texto_do_retorno(retorno, "xObs")
  linha$versao_aplicativo = texto_do_retorno(retorno, "verAplic")
  if (!identical(texto_do_retorno(retorno, "tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a SEFAZ respondeu de outro ambiente"
  }
  linha
}

conferir_ambiente = function(ambiente) {
  if (length(ambiente) != 1 || is.na(ambiente) || !(ambiente %in% names(AMBIENTES_LIBERADOS))) {
    stop("Por enquanto o RNFe s\u00f3 fala com o ambiente de homologa\u00e7\u00e3o da SEFAZ: use ambiente = \"homologacao\".",
         call. = FALSE)
  }
}

# O certificado é conferido antes de qualquer conexão, para o erro vir claro uma vez só (e não em cada UF).
conferir_certificado = function(certificado, senha) {
  if (length(certificado) != 1 || length(senha) != 1) {
    stop("Informe um certificado e uma senha.", call. = FALSE)
  }
  certificado_lido = certificado_ler(certificado, senha)
  if (!is.na(certificado_lido$problema)) {
    stop("O certificado n\u00e3o abriu: ", certificado_lido$problema, ".", call. = FALSE)
  }
  if (certificado_lido$vencido) {
    stop("O certificado venceu em ", format(certificado_lido$valido_ate, "%d/%m/%Y"), ".", call. = FALSE)
  }
}

# O autorizador da UF e o endereço do serviço. A UF com SEFAZ própria usa a dela em tudo; as outras, a SEFAZ virtual
# da lista "demais serviços" (a consulta de cadastro tem lista própria).
servico_da_uf = function(uf, servico, ambiente) {
  autorizadores = tabela_interna("autorizadores_sefaz")
  usos = c("todos os servi\u00e7os", "demais servi\u00e7os")
  if (servico == "NfeConsultaCadastro") {
    usos = c("todos os servi\u00e7os", "consulta de cadastro")
  }
  da_uf = autorizadores[autorizadores$documento == "NF-e" & autorizadores$ambiente == ambiente &
                          autorizadores$uf == uf & autorizadores$uso %in% usos, ]
  if (nrow(da_uf) == 0) {
    return(NULL)
  }
  servicos = tabela_interna("servicos_sefaz")
  do_autorizador = servicos[servicos$documento == "NF-e" & servicos$ambiente == ambiente &
                              servicos$autorizador == da_uf$autorizador[1] & servicos$servico == servico, ]
  if (nrow(do_autorizador) == 0) {
    return(NULL)
  }
  list(autorizador = da_uf$autorizador[1], endereco = do_autorizador$endereco[1])
}

# As tabelas do pacote que não são tabelas fiscais (os endereços da SEFAZ), lidas uma vez por sessão.
tabela_interna = function(nome_da_tabela) {
  if (is.null(tabelas_ja_lidas[[nome_da_tabela]])) {
    tabelas_ja_lidas[[nome_da_tabela]] = ler_tabela_do_pacote(nome_da_tabela)
  }
  tabelas_ja_lidas[[nome_da_tabela]]
}

# O motor de conexão segura que o curl está usando ("Schannel", "OpenSSL"...). O curl_version() mostra entre
# parênteses os motores que estão disponíveis, mas desligados: "(OpenSSL/3.5.8) Schannel" é o Schannel.
motor_de_tls = function(motores_do_curl = curl::curl_version()$ssl_version) {
  motores = trimws(gsub("\\([^)]*\\)", "", motores_do_curl))
  sub("/.*$", "", strsplit(motores, " ")[[1]][1])
}

# No Schannel (o padrão do curl no Windows), BA, MG, MT, SP e a SVAN não conectam: os pedidos vão por um processo
# separado, com o OpenSSL.
usar_processo_separado = function() {
  identical(motor_de_tls(), "Schannel")
}

# As opções de conexão do certificado de cliente: o certificado em PEM com a cadeia que vier no .pfx e a chave
# cifrada com a senha (o OpenSSL 3 não abre o .pfx com a cifra antiga), e as raízes de sempre com a da ICP-Brasil.
preparar_conexao = function(certificado, senha, pasta_temporaria) {
  conteudo = openssl::read_p12(certificado, password = senha)
  arquivo_do_certificado = file.path(pasta_temporaria, "certificado.pem")
  arquivo_da_chave = file.path(pasta_temporaria, "chave.pem")
  writeLines(c(openssl::write_pem(conteudo$cert), vapply(conteudo$ca, openssl::write_pem, character(1))), arquivo_do_certificado)
  writeLines(openssl::write_pem(conteudo$key, password = senha), arquivo_da_chave)
  opcoes = list(sslcert = arquivo_do_certificado, sslcerttype = "PEM", sslkey = arquivo_da_chave, keypasswd = senha)
  arquivo_das_raizes = juntar_raizes(pasta_temporaria)
  if (!is.na(arquivo_das_raizes)) {
    opcoes$cainfo = arquivo_das_raizes
  }
  list(processo_separado = usar_processo_separado(), pasta_temporaria = pasta_temporaria, opcoes = opcoes)
}

# Os servidores da SEFAZ usam a raiz v10 da ICP-Brasil (a maioria) e raízes comerciais (GlobalSign na SVAN e no
# Ambiente Nacional, Let's Encrypt em GO). O cainfo troca a lista de raízes inteira, então vai num arquivo só a lista
# padrão e a raiz v10. Sem lista padrão, fica a que o curl já usa (NA), e as UFs da ICP-Brasil podem falhar.
juntar_raizes = function(pasta_temporaria, lista_padrao = lista_de_raizes_padrao()) {
  if (is.na(lista_padrao)) {
    return(NA_character_)
  }
  raiz_da_icp_brasil = system.file("certificados", "icp_brasil_raiz_v10.pem", package = "RNFe")
  arquivo_das_raizes = file.path(pasta_temporaria, "raizes.pem")
  writeLines(c(readLines(lista_padrao, warn = FALSE), readLines(raiz_da_icp_brasil, warn = FALSE)), arquivo_das_raizes)
  arquivo_das_raizes
}

# A lista de raízes que o curl usa sem cainfo: a do R no Windows (CURL_CA_BUNDLE) ou a do sistema.
lista_de_raizes_padrao = function() {
  lugares = c(Sys.getenv("CURL_CA_BUNDLE"), Sys.getenv("SSL_CERT_FILE"), "/etc/ssl/certs/ca-certificates.crt",
              "/etc/pki/tls/certs/ca-bundle.crt", "/etc/ssl/cert.pem")
  lugares = lugares[nzchar(lugares) & file.exists(lugares)]
  if (length(lugares) == 0) {
    return(NA_character_)
  }
  lugares[1]
}

# A mensagem no envelope SOAP 1.2: o elemento nfeDadosMsg, no namespace do serviço, e a action do WSDL.
montar_pedido = function(endereco, servico_do_wsdl, operacao, mensagem) {
  namespace_do_servico = paste0("http://www.portalfiscal.inf.br/nfe/wsdl/", servico_do_wsdl)
  envelope = paste0(
    '<?xml version="1.0" encoding="utf-8"?>',
    '<soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Body>',
    '<nfeDadosMsg xmlns="', namespace_do_servico, '">', mensagem, "</nfeDadosMsg>",
    "</soap12:Body></soap12:Envelope>"
  )
  list(
    endereco = endereco,
    corpo = charToRaw(enc2utf8(envelope)),
    tipo_do_conteudo = paste0('application/soap+xml; charset=utf-8; action="', namespace_do_servico, "/", operacao, '"')
  )
}

enviar_pedidos = function(pedidos, conexao) {
  if (length(pedidos) == 0) {
    return(list())
  }
  if (conexao$processo_separado) {
    return(enviar_num_processo_separado(pedidos, conexao)$respostas)
  }
  enviar_os_pedidos(pedidos, conexao$opcoes, TEMPO_LIMITE_DA_SEFAZ)
}

# Manda cada pedido e devolve, de cada um, a situação HTTP e o corpo da resposta, ou o erro da conexão. Só usa o
# httr2 e o R base: a mesma função roda no processo separado (vai para lá dentro da tarefa).
enviar_os_pedidos = function(pedidos, opcoes, tempo_limite) {
  respostas = list()
  for (posicao in seq_along(pedidos)) {
    pedido = httr2::request(pedidos[[posicao]]$endereco)
    pedido = httr2::req_body_raw(pedido, pedidos[[posicao]]$corpo, type = pedidos[[posicao]]$tipo_do_conteudo)
    pedido = do.call(httr2::req_options, c(list(pedido), opcoes))
    pedido = httr2::req_timeout(pedido, tempo_limite)
    pedido = httr2::req_error(pedido, is_error = function(resposta) FALSE)
    resposta = tryCatch(httr2::req_perform(pedido), error = function(erro) erro)
    if (inherits(resposta, "error")) {
      respostas[[posicao]] = list(situacao_http = NA_integer_, corpo = NULL, erro = conditionMessage(resposta))
    } else {
      respostas[[posicao]] = list(situacao_http = httr2::resp_status(resposta), corpo = httr2::resp_body_raw(resposta),
                                  erro = NA_character_)
    }
  }
  respostas
}

# No Schannel, os pedidos vão por um processo R à parte, aberto com CURL_SSL_BACKEND=openssl: o motor é escolhido
# quando o curl carrega, então não dá para trocar nesta sessão. A tarefa vai num arquivo (os pedidos, as opções e a
# função que envia); a senha, numa variável de ambiente que o processo herda. As variáveis desta sessão voltam como
# eram, e a pasta temporária (com a tarefa e o resultado) é apagada por quem a criou.
enviar_num_processo_separado = function(pedidos, conexao) {
  funcao_que_envia = enviar_os_pedidos
  environment(funcao_que_envia) = globalenv()
  opcoes_sem_a_senha = conexao$opcoes
  opcoes_sem_a_senha$keypasswd = NULL
  arquivo_da_tarefa = file.path(conexao$pasta_temporaria, "tarefa.rds")
  arquivo_do_resultado = file.path(conexao$pasta_temporaria, "resultado.rds")
  saveRDS(list(enviar = funcao_que_envia, pedidos = pedidos, opcoes = opcoes_sem_a_senha,
               tempo_limite = TEMPO_LIMITE_DA_SEFAZ, bibliotecas = .libPaths()), arquivo_da_tarefa)
  variaveis_de_antes = Sys.getenv(c("CURL_SSL_BACKEND", "RNFE_SENHA_DO_CERTIFICADO"), unset = NA)
  on.exit(restaurar_variaveis(variaveis_de_antes), add = TRUE)
  Sys.setenv(CURL_SSL_BACKEND = "openssl", RNFE_SENHA_DO_CERTIFICADO = conexao$opcoes$keypasswd)
  roteiro = system.file("sefaz", "processo_separado.R", package = "RNFe")
  saida = suppressWarnings(system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(roteiro), shQuote(arquivo_da_tarefa), shQuote(arquivo_do_resultado)),
    stdout = TRUE, stderr = TRUE
  ))
  if (!file.exists(arquivo_do_resultado)) {
    erro = paste("o processo separado n\u00e3o rodou:", paste(utils::tail(saida, 3), collapse = " "))
    respostas = list()
    for (posicao in seq_along(pedidos)) {
      respostas[[posicao]] = list(situacao_http = NA_integer_, corpo = NULL, erro = erro)
    }
    return(list(motor = NA_character_, respostas = respostas))
  }
  readRDS(arquivo_do_resultado)
}

# Volta cada variável de ambiente ao que era (NA: não existia).
restaurar_variaveis = function(variaveis_de_antes) {
  for (nome in names(variaveis_de_antes)) {
    if (is.na(variaveis_de_antes[[nome]])) {
      Sys.unsetenv(nome)
    } else {
      valor = list(variaveis_de_antes[[nome]])
      names(valor) = nome
      do.call(Sys.setenv, valor)
    }
  }
}

# O retorno de dentro do nfeResultMsg; sem ele, o motivo vai em `problema`.
ler_resposta = function(resposta) {
  if (!is.na(resposta$erro)) {
    return(list(retorno = NULL, problema = paste("sem resposta da SEFAZ:", gsub("\\s+", " ", resposta$erro))))
  }
  xml_da_resposta = tryCatch(xml2::read_xml(resposta$corpo), error = function(erro) NULL)
  if (is.null(xml_da_resposta)) {
    return(list(retorno = NULL, problema = paste0("HTTP ", resposta$situacao_http, ": a SEFAZ n\u00e3o respondeu em XML")))
  }
  # As buscas são pelo nome local: cada SEFAZ põe o prefixo de namespace que quer (soap:, ns2:...) ou nenhum.
  retorno = xml2::xml_find_first(xml_da_resposta, "//*[local-name()='nfeResultMsg']/*[1]")
  if (inherits(retorno, "xml_missing")) {
    falha = xml2::xml_text(xml2::xml_find_first(
      xml_da_resposta, "//*[local-name()='Fault']//*[local-name()='Text' or local-name()='faultstring']"
    ))
    return(list(retorno = NULL, problema = paste0("HTTP ", resposta$situacao_http, ": ", trimws(falha))))
  }
  list(retorno = retorno, problema = NA_character_)
}

nome_local = function(elemento) {
  sub("^.*:", "", xml2::xml_name(elemento))
}

texto_do_retorno = function(retorno, campo) {
  elemento = xml2::xml_find_first(retorno, paste0("./*[local-name()='", campo, "']"))
  if (inherits(elemento, "xml_missing")) {
    return(NA_character_)
  }
  xml2::xml_text(elemento)
}
