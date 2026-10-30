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
#' Por enquanto o RNfe só fala com o ambiente de **homologação** (testes, sem
#' valor fiscal); o ambiente de produção é recusado.
#'
#' Cada UF é atendida pela própria SEFAZ ou por uma SEFAZ virtual (a SVRS ou a
#' SVAN), como diz a Relação de Serviços Web do Portal da NF-e. A conexão usa
#' o certificado digital A1 (veja [certificado_ler()]). Uma UF que não responde
#' não atrapalha as outras: o motivo fica em `problema`.
#'
#' Precisa dos pacotes `httr2` e `openssl`. A conexão foi testada no Windows,
#' que confia na cadeia de certificados da ICP-Brasil usada pelos servidores da
#' SEFAZ; em outro sistema, a cadeia pode precisar ser instalada.
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
  exigir_pacotes(c("httr2", "openssl"))
  conferir_certificado(certificado, senha)
  ufs = toupper(trimws(as.character(ufs)))
  linhas = list()
  for (posicao in seq_along(ufs)) {
    linhas[[posicao]] = status_de_uma_uf(ufs[posicao], certificado, senha, ambiente)
  }
  if (length(linhas) == 0) {
    status = status_de_uma_uf(character(), certificado, senha, ambiente)
  } else {
    status = do.call(rbind, linhas)
  }
  # Juntar as linhas tira o fuso das datas: volta o de Brasília.
  attr(status$recebimento, "tzone") = "America/Sao_Paulo"
  attr(status$retorno_previsto, "tzone") = "America/Sao_Paulo"
  status
}

status_de_uma_uf = function(uf, certificado, senha, ambiente) {
  linha = data.frame(
    uf = NA_character_, autorizador = NA_character_, ambiente = ambiente, situacao = NA_integer_, motivo = NA_character_,
    recebimento = as.POSIXct(NA), tempo_medio = NA_integer_, retorno_previsto = as.POSIXct(NA), observacao = NA_character_,
    versao_aplicativo = NA_character_, endereco = NA_character_, problema = NA_character_
  )
  # Sem UF, a tabela vazia com as mesmas colunas.
  if (length(uf) == 0) {
    return(linha[0, ])
  }
  linha$uf = as.character(uf)
  codigo_da_uf = names(UF_PELO_CODIGO)[match(uf, UF_PELO_CODIGO)]
  if (is.na(codigo_da_uf)) {
    linha$problema = "UF desconhecida"
    return(linha)
  }
  servico = servico_da_uf(uf, "NfeStatusServico", ambiente)
  if (is.null(servico)) {
    linha$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz este servi\u00e7o para a UF"
    return(linha)
  }
  linha$autorizador = servico$autorizador
  linha$endereco = servico$endereco
  mensagem = paste0(
    '<consStatServ xmlns="', NAMESPACE_DA_NFE, '" versao="4.00">',
    "<tpAmb>", AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb><cUF>", codigo_da_uf, "</cUF><xServ>STATUS</xServ>",
    "</consStatServ>"
  )
  resposta = pedir_a_sefaz(servico$endereco, "NFeStatusServico4", "nfeStatusServicoNF", mensagem, certificado, senha)
  if (!is.na(resposta$problema)) {
    linha$problema = resposta$problema
    return(linha)
  }
  retorno = resposta$retorno
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
    stop("Por enquanto o RNfe s\u00f3 fala com o ambiente de homologa\u00e7\u00e3o da SEFAZ: use ambiente = \"homologacao\".",
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

# Manda a mensagem no envelope SOAP 1.2 (o elemento nfeDadosMsg, no namespace do serviço), com o certificado de
# cliente, e devolve o retorno de dentro do nfeResultMsg. Sem retorno, o motivo vai em `problema`.
pedir_a_sefaz = function(endereco, servico_do_wsdl, operacao, mensagem, certificado, senha) {
  namespace_do_servico = paste0("http://www.portalfiscal.inf.br/nfe/wsdl/", servico_do_wsdl)
  envelope = paste0(
    '<?xml version="1.0" encoding="utf-8"?>',
    '<soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Body>',
    '<nfeDadosMsg xmlns="', namespace_do_servico, '">', mensagem, "</nfeDadosMsg>",
    "</soap12:Body></soap12:Envelope>"
  )
  tipo_do_conteudo = paste0('application/soap+xml; charset=utf-8; action="', namespace_do_servico, "/", operacao, '"')
  pedido = httr2::request(endereco)
  pedido = httr2::req_body_raw(pedido, charToRaw(enc2utf8(envelope)), type = tipo_do_conteudo)
  pedido = httr2::req_options(pedido, sslcert = certificado, sslcerttype = "P12", keypasswd = senha)
  pedido = httr2::req_timeout(pedido, TEMPO_LIMITE_DA_SEFAZ)
  pedido = httr2::req_error(pedido, is_error = function(resposta) FALSE)
  resposta = tryCatch(httr2::req_perform(pedido), error = function(erro) erro)
  if (inherits(resposta, "error")) {
    return(list(retorno = NULL, problema = paste("sem resposta da SEFAZ:", gsub("\\s+", " ", conditionMessage(resposta)))))
  }
  situacao_http = httr2::resp_status(resposta)
  xml_da_resposta = tryCatch(xml2::read_xml(httr2::resp_body_raw(resposta)), error = function(erro) NULL)
  if (is.null(xml_da_resposta)) {
    return(list(retorno = NULL, problema = paste0("HTTP ", situacao_http, ": a SEFAZ n\u00e3o respondeu em XML")))
  }
  # As buscas são pelo nome local: cada SEFAZ põe o prefixo de namespace que quer (soap:, ns2:...) ou nenhum.
  retorno = xml2::xml_find_first(xml_da_resposta, "//*[local-name()='nfeResultMsg']/*[1]")
  if (inherits(retorno, "xml_missing")) {
    falha = xml2::xml_text(xml2::xml_find_first(
      xml_da_resposta, "//*[local-name()='Fault']//*[local-name()='Text' or local-name()='faultstring']"
    ))
    return(list(retorno = NULL, problema = paste0("HTTP ", situacao_http, ": ", trimws(falha))))
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
