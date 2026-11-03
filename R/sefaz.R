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
    linhas[[posicao]] = completar_status(linhas[[posicao]], ler_resposta(respostas[[numero_do_pedido]], "retConsStatServ"), ambiente)
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

#' Situação da NF-e na SEFAZ, pela chave
#'
#' Pergunta à SEFAZ a situação de cada NF-e (modelo 55) pela chave de acesso:
#' se está autorizada, cancelada, denegada ou se não consta. Devolve uma lista
#' com `situacoes` (uma linha por chave: a resposta da SEFAZ e o protocolo de
#' autorização, quando vem) e `eventos` (os eventos da nota que a SEFAZ manda
#' junto, como o cancelamento, lidos por [eventos_ler()]).
#'
#' Cada chave vai ao autorizador da UF que está nela (a própria SEFAZ ou a
#' SVRS ou a SVAN), como diz a Relação de Serviços Web do Portal da NF-e. Chave
#' que não confere (veja [chave_decompor()]) nem é enviada: o motivo fica em
#' `problema`. Por enquanto só a NF-e (modelo 55) e só o ambiente de
#' **homologação**; a produção é recusada. A conexão é a mesma do
#' [sefaz_status()], com as mesmas exigências e o mesmo processo separado no
#' Windows.
#'
#' @param chaves As chaves de acesso: um texto ou um vetor com várias (por
#'   exemplo, a coluna `chave` que vem de [nfe_ler()]).
#' @inheritParams sefaz_status
#' @return Uma lista com dois `data.frame`s:
#'   - `situacoes`: `chave`, `uf` (a da chave), `autorizador`, `ambiente`,
#'     `situacao` (o código de status da resposta, `cStat`), `motivo` (o que a
#'     SEFAZ escreveu; o 217, por exemplo, é a NF-e que não consta na base de
#'     dados), `recebimento` (data e hora em que a SEFAZ recebeu a consulta, no
#'     horário de Brasília), do protocolo de autorização (`protNFe`), quando
#'     vem: `protocolo`, `autorizacao` (data e hora) e `digest_value`; e
#'     `versao_aplicativo`, `endereco` e `problema` (por que a consulta não deu
#'     certo; vazio quando deu);
#'   - `eventos`: a tabela `eventos` de [eventos_ler()] com os eventos
#'     (`procEventoNFe`) que vieram nas respostas, ligados pela `chave`, sem a
#'     coluna `arquivo`.
#' @seealso [sefaz_status()], [eventos_ler()]
#' @source Relação de Serviços Web do Portal da NF-e (endereços de
#'   homologação); o schema `leiauteConsSitNFe_v4.00.xsd` do pacote de
#'   liberação 010d v1.01 (NT 2026.004, 08/06/2026); o WSDL do serviço
#'   NFeConsultaProtocolo4 (a mensagem em `nfeDadosMsg`, operação
#'   `nfeConsultaNF`, SOAP 1.2).
#' @examples
#' \dontrun{
#' consulta = sefaz_situacao(nfe_ler("nota.xml")$notas$chave, "empresa.pfx",
#'                           Sys.getenv("SENHA_DO_CERTIFICADO"))
#' consulta$situacoes[, c("chave", "situacao", "motivo", "protocolo")]
#' consulta$eventos[, c("chave", "tipo", "descricao", "data_evento")]
#' }
#' @export
sefaz_situacao = function(chaves, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  exigir_pacotes(c("httr2", "curl", "openssl"))
  conferir_certificado(certificado, senha)
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  chaves_limpas = limpar_chaves(chaves)
  linhas = list()
  pedidos = list()
  linha_de_cada_pedido = integer()
  for (posicao in seq_along(chaves_limpas)) {
    comeco = comeco_da_situacao(chaves_limpas[posicao], ambiente)
    linhas[[posicao]] = comeco$linha
    if (!is.null(comeco$pedido)) {
      pedidos[[length(pedidos) + 1]] = comeco$pedido
      linha_de_cada_pedido = c(linha_de_cada_pedido, posicao)
    }
  }
  respostas = enviar_pedidos(pedidos, conexao)
  # Os retornos que trazem eventos vão, como texto, para o eventos_ler().
  retornos_com_eventos = character()
  for (numero_do_pedido in seq_along(respostas)) {
    posicao = linha_de_cada_pedido[numero_do_pedido]
    resposta_lida = ler_resposta(respostas[[numero_do_pedido]], "retConsSitNFe")
    linhas[[posicao]] = completar_situacao(linhas[[posicao]], resposta_lida, ambiente)
    if (is.na(linhas[[posicao]]$problema) &&
        !inherits(xml2::xml_find_first(resposta_lida$retorno, "./*[local-name()='procEventoNFe']"), "xml_missing")) {
      retornos_com_eventos = c(retornos_com_eventos, as.character(resposta_lida$retorno))
    }
  }
  if (length(linhas) == 0) {
    situacoes = comeco_da_situacao(character(), ambiente)$linha
  } else {
    situacoes = do.call(rbind, linhas)
  }
  # Juntar as linhas tira o fuso das datas: volta o de Brasília.
  attr(situacoes$recebimento, "tzone") = "America/Sao_Paulo"
  attr(situacoes$autorizacao, "tzone") = "America/Sao_Paulo"
  eventos = eventos_ler(retornos_com_eventos, todos_os_campos = FALSE)$eventos
  eventos$arquivo = NULL
  list(situacoes = situacoes, eventos = eventos)
}

# A linha da chave (a UF, o autorizador e o endereço, ou o problema) e o pedido de consulta, quando dá para pedir.
comeco_da_situacao = function(chave, ambiente) {
  linha = data.frame(
    chave = NA_character_, uf = NA_character_, autorizador = NA_character_, ambiente = ambiente, situacao = NA_integer_,
    motivo = NA_character_, recebimento = as.POSIXct(NA), protocolo = NA_character_, autorizacao = as.POSIXct(NA),
    digest_value = NA_character_, versao_aplicativo = NA_character_, endereco = NA_character_, problema = NA_character_
  )
  # Sem chave, a tabela vazia com as mesmas colunas.
  if (length(chave) == 0) {
    return(list(linha = linha[0, ], pedido = NULL))
  }
  linha$chave = chave
  partes_da_chave = chave_decompor(chave)
  if (!partes_da_chave$valida) {
    linha$problema = paste("chave inv\u00e1lida:", partes_da_chave$problema)
    return(list(linha = linha, pedido = NULL))
  }
  linha$uf = partes_da_chave$uf
  if (partes_da_chave$modelo != "55") {
    linha$problema = "por enquanto s\u00f3 a NF-e (modelo 55) \u00e9 consultada"
    return(list(linha = linha, pedido = NULL))
  }
  servico = servico_da_uf(partes_da_chave$uf, "NfeConsultaProtocolo", ambiente)
  if (is.null(servico)) {
    linha$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz este servi\u00e7o para a UF"
    return(list(linha = linha, pedido = NULL))
  }
  linha$autorizador = servico$autorizador
  linha$endereco = servico$endereco
  mensagem = paste0(
    '<consSitNFe xmlns="', NAMESPACE_DA_NFE, '" versao="4.00">',
    "<tpAmb>", AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb><xServ>CONSULTAR</xServ><chNFe>", chave, "</chNFe>",
    "</consSitNFe>"
  )
  list(linha = linha, pedido = montar_pedido(servico$endereco, "NFeConsultaProtocolo4", "nfeConsultaNF", mensagem))
}

# Os campos do retConsSitNFe e do protocolo de autorização (protNFe/infProt) na linha da chave.
completar_situacao = function(linha, resposta_lida, ambiente) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  retorno = resposta_lida$retorno
  linha$situacao = as.integer(texto_do_retorno(retorno, "cStat"))
  linha$motivo = texto_do_retorno(retorno, "xMotivo")
  linha$recebimento = data_hora(texto_do_retorno(retorno, "dhRecbto"))
  linha$versao_aplicativo = texto_do_retorno(retorno, "verAplic")
  protocolo = xml2::xml_find_first(retorno, "./*[local-name()='protNFe']/*[local-name()='infProt']")
  if (!inherits(protocolo, "xml_missing")) {
    linha$protocolo = texto_do_retorno(protocolo, "nProt")
    linha$autorizacao = data_hora(texto_do_retorno(protocolo, "dhRecbto"))
    linha$digest_value = texto_do_retorno(protocolo, "digVal")
  }
  if (!identical(texto_do_retorno(retorno, "tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a SEFAZ respondeu de outro ambiente"
  } else if (!identical(texto_do_retorno(retorno, "chNFe"), linha$chave)) {
    linha$problema = "a SEFAZ respondeu sobre outra chave"
  }
  linha
}

# A consulta de cadastro do MT segue outro WSDL: o nfeDadosMsg vai dentro de consultaCadastro (WSDL de homologação do MT,
# baixado em 03/11/2026; o pedido igual ao das outras SEFAZ voltava 215, "Falha no schema XML").
ELEMENTO_EM_VOLTA_NO_CADASTRO = c(MT = "consultaCadastro")

# Cada contribuinte (infCad) da resposta da consulta de cadastro (leiauteConsultaCadastro_v2.00 do pacote 010d).
CAMPOS_DO_CADASTRO = ler_campos("
coluna                 caminho       tipo
ie                     IE            texto
contribuinte_documento CNPJ|CPF      texto
uf                     UF            texto
situacao_cadastral     cSit          inteiro
credenciado_nfe        indCredNFe    inteiro
credenciado_cte        indCredCTe    inteiro
nome                   xNome         texto
fantasia               xFant         texto
regime_apuracao        xRegApur      texto
cnae                   CNAE          texto
inicio_atividade       dIniAtiv      data
ultima_situacao        dUltSit       data
baixa                  dBaixa        data
ie_unica               IEUnica       texto
ie_atual               IEAtual       texto
logradouro             ender/xLgr    texto
numero                 ender/nro     texto
complemento            ender/xCpl    texto
bairro                 ender/xBairro texto
codigo_municipio       ender/cMun    texto
municipio              ender/xMun    texto
cep                    ender/CEP     texto
")

SIGNIFICADOS_DO_CADASTRO = ler_campos("
coluna_do_codigo   campo      coluna_do_contexto
situacao_cadastral cSit       -
credenciado_nfe    indCredNFe -
credenciado_cte    indCredCTe -
")

# O formato de cada tipo de documento consultado, como o schema da consulta aceita.
FORMATO_DO_DOCUMENTO_CONSULTADO = c(CNPJ = "^[0-9A-Z]{12}[0-9]{2}$", CPF = "^[0-9]{3,11}$", IE = "^[0-9]{2,14}$")

#' Cadastro de contribuintes na SEFAZ
#'
#' Pergunta à SEFAZ de uma UF o cadastro de contribuintes do ICMS pelo CNPJ,
#' pelo CPF ou pela inscrição estadual: a inscrição, a situação (habilitado ou
#' não), se é credenciado a emitir NF-e e CT-e, o nome, o regime de apuração, o
#' CNAE, as datas e o endereço. Devolve uma lista com `consultas` (uma linha
#' por documento consultado) e `cadastros` (uma linha por inscrição que a
#' SEFAZ devolveu: um CNPJ pode ter mais de uma).
#'
#' Cada documento vai à SEFAZ que atende a UF (veja a seção "Em cada UF").
#' Por enquanto só o ambiente de **homologação**; a produção é recusada. A
#' conexão é a mesma do [sefaz_status()].
#'
#' @section Em cada UF:
#' O que se sabe de cada UF, testado em homologação em 03/11/2026 com um CNPJ
#' inventado:
#' - **SEFAZ própria** (o pedido vai a ela): AM, BA, GO, MG, MS, MT, PE, PR, RS
#'   e SP. O MT quer a mensagem num envelope diferente, e o RNFe já manda
#'   assim.
#' - **SVRS:** AC, AL, AP, CE, DF, ES, PA, PB, PI, RJ, RN, RO, RR, SC, SE e TO.
#'   A Relação de Serviços Web do Portal da NF-e põe só AC, ES, PB, RN e SC na
#'   consulta de cadastro da SVRS, mas ela atende todas essas (e responde ao
#'   CE, ao AL e ao PI também em produção).
#' - **Sem o serviço:** o MA, que usa a SVAN para a NF-e. A SVAN não tem a
#'   consulta e a SVRS responde que não atende a UF; a linha vem com o motivo
#'   em `problema`, sem ir à SEFAZ.
#'
#' A SEFAZ pode recusar por causa de quem pergunta: a **257** ("Solicitante
#' não habilitado para emissão da NF-e") é sobre o CNPJ do certificado, não
#' sobre o documento consultado. Use o certificado de uma empresa que emite
#' NF-e; no teste, 11 das 15 UFs consultadas recusaram assim o certificado
#' usado. Já a **259** ("CNPJ da consulta não cadastrado como
#' contribuinte na UF") é sobre o documento consultado.
#'
#' A resposta é conferida: quando ela fala de outro documento, os cadastros
#' dela não entram e `problema` diz "a SEFAZ respondeu sobre outro documento".
#' Na homologação, **GO e AM** respondiam assim, sobre o CNPJ do certificado.
#'
#' @param documentos Os documentos a consultar, todos do mesmo `tipo`: um
#'   texto ou um vetor. Pontos, barras e traços são ignorados.
#' @param ufs A UF em que cada documento é consultado (a sigla): uma para cada
#'   documento, ou uma só para todos.
#' @param tipo `"CNPJ"` (o padrão), `"CPF"` ou `"IE"`.
#' @inheritParams sefaz_status
#' @return Uma lista com dois `data.frame`s:
#'   - `consultas`: `documento`, `tipo`, `uf`, `autorizador`, `ambiente`,
#'     `situacao` (o código de status da resposta, `cStat`), `motivo` (o que a
#'     SEFAZ escreveu), `consulta` (data e hora da consulta, no horário de
#'     Brasília; quando a SEFAZ manda sem o fuso, ele é lido como o de
#'     Brasília), `contribuintes` (quantas inscrições vieram),
#'     `versao_aplicativo`, `endereco` e `problema` (por que a consulta não deu
#'     certo; vazio quando deu);
#'   - `cadastros`: `documento` (o consultado, para ligar com `consultas`) e
#'     `r documentar_campos(CAMPOS_DO_CADASTRO)`. `situacao_cadastral`,
#'     `credenciado_nfe` e `credenciado_cte` vêm com o significado ao lado,
#'     em `*_descricao`, pela documentação do schema.
#' @seealso [sefaz_status()], [sefaz_situacao()]
#' @source Relação de Serviços Web do Portal da NF-e (endereços de
#'   homologação); o schema `leiauteConsultaCadastro_v2.00.xsd` do pacote de
#'   liberação 010d v1.01 (NT 2026.004, 08/06/2026); o WSDL do serviço
#'   CadConsultaCadastro4 (operação `consultaCadastro`, SOAP 1.2) e, no MT, o
#'   WSDL de homologação de lá.
#' @examples
#' \dontrun{
#' cadastro = sefaz_cadastro("11.222.333/0001-81", "SP", "empresa.pfx",
#'                           Sys.getenv("SENHA_DO_CERTIFICADO"))
#' cadastro$consultas[, c("documento", "uf", "situacao", "motivo")]
#' cadastro$cadastros[, c("ie", "nome", "situacao_cadastral_descricao", "municipio")]
#' }
#' @export
sefaz_cadastro = function(documentos, ufs, certificado, senha, tipo = "CNPJ", ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  if (length(tipo) != 1 || is.na(tipo) || !(tipo %in% names(FORMATO_DO_DOCUMENTO_CONSULTADO))) {
    stop('Informe tipo = "CNPJ", "CPF" ou "IE".', call. = FALSE)
  }
  documentos = toupper(gsub("[^0-9A-Za-z]", "", as.character(documentos)))
  ufs = toupper(trimws(as.character(ufs)))
  if (length(ufs) == 1) {
    ufs = rep(ufs, length(documentos))
  }
  if (length(ufs) != length(documentos)) {
    stop("Informe uma UF para cada documento, ou uma s\u00f3 para todos.", call. = FALSE)
  }
  exigir_pacotes(c("httr2", "curl", "openssl"))
  conferir_certificado(certificado, senha)
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  linhas = list()
  pedidos = list()
  linha_de_cada_pedido = integer()
  for (posicao in seq_along(documentos)) {
    comeco = comeco_do_cadastro(documentos[posicao], ufs[posicao], tipo, ambiente)
    linhas[[posicao]] = comeco$linha
    if (!is.null(comeco$pedido)) {
      pedidos[[length(pedidos) + 1]] = comeco$pedido
      linha_de_cada_pedido = c(linha_de_cada_pedido, posicao)
    }
  }
  respostas = enviar_pedidos(pedidos, conexao)
  cadastros_de_cada_resposta = list()
  for (numero_do_pedido in seq_along(respostas)) {
    posicao = linha_de_cada_pedido[numero_do_pedido]
    completado = completar_cadastro(linhas[[posicao]], ler_resposta(respostas[[numero_do_pedido]], "retConsCad"))
    linhas[[posicao]] = completado$linha
    cadastros_de_cada_resposta[[numero_do_pedido]] = completado$cadastros
  }
  if (length(linhas) == 0) {
    consultas = comeco_do_cadastro(character(), character(), tipo, ambiente)$linha
  } else {
    consultas = do.call(rbind, linhas)
  }
  # Juntar as linhas tira o fuso das datas: volta o de Brasília.
  attr(consultas$consulta, "tzone") = "America/Sao_Paulo"
  cadastros = do.call(rbind, c(list(colunas_do_cadastro(list(), character())), cadastros_de_cada_resposta))
  cadastros = acrescentar_significados(cadastros, "NF-e", SIGNIFICADOS_DO_CADASTRO)
  list(consultas = consultas, cadastros = cadastros)
}

# A linha do documento (a UF, o autorizador e o endereço, ou o problema) e o pedido de consulta, quando dá para pedir.
comeco_do_cadastro = function(documento, uf, tipo, ambiente) {
  linha = data.frame(
    documento = NA_character_, tipo = tipo, uf = NA_character_, autorizador = NA_character_, ambiente = ambiente,
    situacao = NA_integer_, motivo = NA_character_, consulta = as.POSIXct(NA), contribuintes = NA_integer_,
    versao_aplicativo = NA_character_, endereco = NA_character_, problema = NA_character_
  )
  # Sem documento, a tabela vazia com as mesmas colunas.
  if (length(documento) == 0) {
    return(list(linha = linha[0, ], pedido = NULL))
  }
  linha$documento = documento
  linha$uf = uf
  if (is.na(documento) || !grepl(FORMATO_DO_DOCUMENTO_CONSULTADO[[tipo]], documento)) {
    linha$problema = paste("n\u00e3o tem o formato de", tipo)
    return(list(linha = linha, pedido = NULL))
  }
  if (!(uf %in% UF_PELO_CODIGO)) {
    linha$problema = "UF desconhecida"
    return(list(linha = linha, pedido = NULL))
  }
  servico = servico_da_uf(uf, "NfeConsultaCadastro", ambiente)
  if (is.null(servico)) {
    linha$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz este servi\u00e7o para a UF"
    return(list(linha = linha, pedido = NULL))
  }
  linha$autorizador = servico$autorizador
  linha$endereco = servico$endereco
  mensagem = paste0(
    '<ConsCad xmlns="', NAMESPACE_DA_NFE, '" versao="2.00">',
    "<infCons><xServ>CONS-CAD</xServ><UF>", uf, "</UF><", tipo, ">", documento, "</", tipo, "></infCons>",
    "</ConsCad>"
  )
  elemento_em_volta = unname(ELEMENTO_EM_VOLTA_NO_CADASTRO[servico$autorizador])
  list(linha = linha, pedido = montar_pedido(servico$endereco, "CadConsultaCadastro4", "consultaCadastro", mensagem,
                                             elemento_em_volta))
}

# Os campos do infCons na linha do documento e os contribuintes (infCad) da resposta. A consulta não tem tpAmb: o
# ambiente é o do endereço.
completar_cadastro = function(linha, resposta_lida) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(list(linha = linha, cadastros = NULL))
  }
  informacoes = xml2::xml_find_first(resposta_lida$retorno, "./*[local-name()='infCons']")
  linha$situacao = as.integer(texto_do_retorno(informacoes, "cStat"))
  linha$motivo = texto_do_retorno(informacoes, "xMotivo")
  linha$consulta = data_hora_da_consulta(texto_do_retorno(informacoes, "dhCons"))
  linha$versao_aplicativo = texto_do_retorno(informacoes, "verAplic")
  cadastros_do_xml = xml2::xml_find_all(informacoes, "./*[local-name()='infCad']")
  linha$contribuintes = length(cadastros_do_xml)
  documento_da_resposta = texto_do_retorno(informacoes, linha$tipo)
  if (!is.na(documento_da_resposta) && documento_da_resposta != linha$documento) {
    linha$problema = "a SEFAZ respondeu sobre outro documento"
    return(list(linha = linha, cadastros = NULL))
  }
  list(linha = linha, cadastros = colunas_do_cadastro(cadastros_do_xml, rep(linha$documento, length(cadastros_do_xml))))
}

# Um contribuinte por linha, já no tipo certo. Os campos são buscados pelo nome local, porque o prefixo de namespace muda
# de SEFAZ para SEFAZ.
colunas_do_cadastro = function(cadastros_do_xml, documentos_consultados) {
  colunas = list(documento = documentos_consultados)
  for (numero_do_campo in seq_len(nrow(CAMPOS_DO_CADASTRO))) {
    campo = CAMPOS_DO_CADASTRO[numero_do_campo, ]
    textos = character(length(cadastros_do_xml))
    for (posicao in seq_along(cadastros_do_xml)) {
      textos[posicao] = texto_pelo_caminho(cadastros_do_xml[[posicao]], campo$caminho)
    }
    if (campo$tipo == "inteiro") {
      colunas[[campo$coluna]] = as.integer(textos)
    } else if (campo$tipo == "data") {
      colunas[[campo$coluna]] = as.Date(textos)
    } else {
      colunas[[campo$coluna]] = textos
    }
  }
  list2DF(colunas)
}

# O texto do campo pelo caminho, só com nomes locais ("ender/xLgr"); "CNPJ|CPF" pega o que existir.
texto_pelo_caminho = function(elemento, caminho) {
  for (caminho_possivel in strsplit(caminho, "|", fixed = TRUE)[[1]]) {
    passos = strsplit(caminho_possivel, "/", fixed = TRUE)[[1]]
    caminho_do_xml = paste0("./", paste0("*[local-name()='", passos, "']", collapse = "/"))
    achado = xml2::xml_find_first(elemento, caminho_do_xml)
    if (!inherits(achado, "xml_missing")) {
      return(xml2::xml_text(achado))
    }
  }
  NA_character_
}

# A data e hora da consulta. Algumas SEFAZ mandam sem o fuso (MG, em 03/11/2026, mandou a hora de Brasília: a mesma do
# AM, que manda com o fuso, consultado na mesma hora); sem ele, vale o de Brasília. O PR manda os milésimos, que saem.
data_hora_da_consulta = function(texto) {
  texto = sub("(T[0-9]{2}:[0-9]{2}:[0-9]{2})\\.[0-9]+", "\\1", texto)
  if (is.na(texto) || grepl("([+-][0-9]{2}:?[0-9]{2}|Z)$", texto)) {
    return(data_hora(sub("Z$", "+00:00", texto)))
  }
  as.POSIXct(texto, format = "%Y-%m-%dT%H:%M:%S", tz = "America/Sao_Paulo")
}

# Quando o Ambiente Nacional disse que não havia mais documentos para cada documento (CNPJ ou CPF) e ambiente, nesta
# sessão. A NT 2014.002 manda esperar uma hora antes de perguntar de novo; antes disso, a SEFAZ pode bloquear o CNPJ
# por uma hora (656, "Consumo Indevido").
quando_nao_havia_mais_documentos = new.env(parent = emptyenv())
ESPERA_DEPOIS_DE_NENHUM_DOCUMENTO = 3600

#' Distribuição de DF-e: os documentos de interesse de um CNPJ
#'
#' Pergunta ao Ambiente Nacional os documentos de interesse de um CNPJ ou CPF
#' (a Distribuição de DF-e da NT 2014.002): as NF-e em que ele é
#' destinatário, transportador ou autorizado, os resumos das que ele ainda não
#' manifestou e os eventos. Devolve uma lista com `consulta` (a resposta, numa
#' linha) e `documentos` (um por linha, com o XML já descompactado). Leia os
#' documentos com [nfe_ler()] (as notas e os resumos) e [eventos_ler()]:
#' `nfe_ler(distribuicao$documentos$xml)`.
#'
#' Cada chamada faz um pedido, que traz até 50 documentos. Para seguir, chame
#' de novo com `ultimo_nsu` igual ao `ultimo_nsu` da resposta, até ele ficar
#' igual ao `maior_nsu`. Também dá para pedir um NSU que faltou (`nsu`) ou uma
#' NF-e pela chave (`chave`).
#'
#' **A SEFAZ bloqueia quem pergunta demais.** Pela NT 2014.002, quando a
#' resposta diz que não há mais documentos (137, ou o `ultimo_nsu` igual ao
#' `maior_nsu`), é preciso esperar uma hora antes de pedir de novo a partir do
#' último NSU; antes disso, ela pode responder 656 ("Consumo Indevido") e
#' bloquear o CNPJ por uma hora. As consultas também têm de seguir o
#' `ultimo_nsu` que ela devolveu. Por isso, nesta sessão do R, o RNFe recusa
#' um novo pedido pelo último NSU do mesmo CNPJ antes de passar a hora (o
#' pedido de um `nsu` ou de uma `chave` não entra nessa regra).
#'
#' Por enquanto só o ambiente de **homologação**; a produção é recusada. A
#' conexão é a mesma do [sefaz_status()].
#'
#' @param documento O CNPJ ou CPF de quem pede (o interessado nos documentos),
#'   em geral o do certificado. Pontos, barras e traços são ignorados.
#' @param ultimo_nsu O último NSU já recebido: 0 na primeira vez (a SEFAZ
#'   devolve só o que chegou nos últimos 3 meses) e, depois, o `ultimo_nsu` da
#'   resposta anterior.
#' @param nsu Um NSU específico, para buscar um documento que faltou. Quando
#'   informado, `ultimo_nsu` não é usado.
#' @param chave A chave de acesso de uma NF-e, para buscá-la direto. Quando
#'   informada, `ultimo_nsu` e `nsu` não são usados.
#' @inheritParams sefaz_status
#' @return Uma lista com dois `data.frame`s:
#'   - `consulta`, numa linha: `documento`, `ambiente`, `situacao` (o código de
#'     status, `cStat`: 137 quando não há documentos, 138 quando há),
#'     `motivo`, `processamento` (data e hora, no horário de Brasília),
#'     `ultimo_nsu` (de onde seguir), `maior_nsu` (o maior NSU que o Ambiente
#'     Nacional tem para o documento), `documentos` (quantos vieram),
#'     `versao_aplicativo`, `endereco` e `problema` (por que a consulta não deu
#'     certo; vazio quando deu);
#'   - `documentos`, um por linha: `nsu`, `schema` (o schema que valida o
#'     documento, como `resNFe_v1.01.xsd` ou `procNFe_v4.00.xsd`), `tipo` (o
#'     nome do schema sem a versão: `resNFe`, `procNFe`, `resEvento`,
#'     `procEventoNFe`...) e `xml` (o documento, descompactado).
#' @seealso [nfe_ler()], [eventos_ler()], [sefaz_situacao()]
#' @source NT 2014.002 v1.02d (Web Service de Distribuição de DF-e, Portal da
#'   NF-e); os schemas `distDFeInt_v1.01.xsd` e `retDistDFeInt_v1.01.xsd` do
#'   pacote da Distribuição de DF-e v1.04 (03/07/2026); o WSDL do serviço
#'   NFeDistribuicaoDFe do Ambiente Nacional (operação `nfeDistDFeInteresse`,
#'   com o `nfeDadosMsg` dentro de `nfeDistDFeInteresse`).
#' @examples
#' \dontrun{
#' senha = Sys.getenv("SENHA_DO_CERTIFICADO")
#' distribuicao = sefaz_distribuicao("11222333000181", "empresa.pfx", senha)
#' distribuicao$consulta[, c("situacao", "motivo", "ultimo_nsu", "maior_nsu")]
#' nfe_ler(distribuicao$documentos$xml)$resumos
#' # O próximo pedido segue do último NSU recebido.
#' seguinte = sefaz_distribuicao("11222333000181", "empresa.pfx", senha,
#'                               ultimo_nsu = distribuicao$consulta$ultimo_nsu)
#' }
#' @export
sefaz_distribuicao = function(documento, certificado, senha, ultimo_nsu = 0, nsu = NA, chave = NA,
                              ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  documento = toupper(gsub("[^0-9A-Za-z]", "", as.character(documento)))
  if (length(documento) != 1 || is.na(documento) || !grepl("^([0-9A-Z]{12}[0-9]{2}|[0-9]{11})$", documento)) {
    stop("Informe um CNPJ (14 posi\u00e7\u00f5es) ou um CPF (11 d\u00edgitos) em `documento`.", call. = FALSE)
  }
  grupo_do_pedido = grupo_da_distribuicao(ultimo_nsu, nsu, chave)
  memoria = paste(documento, ambiente)
  if (grupo_do_pedido$pelo_ultimo_nsu && !is.null(quando_nao_havia_mais_documentos[[memoria]])) {
    liberado_em = quando_nao_havia_mais_documentos[[memoria]] + ESPERA_DEPOIS_DE_NENHUM_DOCUMENTO
    if (Sys.time() < liberado_em) {
      stop("O Ambiente Nacional disse \u00e0s ", format(quando_nao_havia_mais_documentos[[memoria]], "%H:%M"),
           " que n\u00e3o havia mais documentos para este CNPJ ou CPF. A NT 2014.002 manda esperar uma hora antes de pedir ",
           "de novo (sen\u00e3o a SEFAZ bloqueia o CNPJ por uma hora): tente depois das ", format(liberado_em, "%H:%M"), ".",
           call. = FALSE)
    }
  }
  exigir_pacotes(c("httr2", "curl", "openssl"))
  conferir_certificado(certificado, senha)
  servicos = tabela_interna("servicos_sefaz")
  do_ambiente_nacional = servicos[servicos$documento == "NF-e" & servicos$ambiente == ambiente &
                                    servicos$autorizador == "AN" & servicos$servico == "NFeDistribuicaoDFe", ]
  consulta = data.frame(
    documento = documento, ambiente = ambiente, situacao = NA_integer_, motivo = NA_character_,
    processamento = as.POSIXct(NA), ultimo_nsu = NA_character_, maior_nsu = NA_character_, documentos = NA_integer_,
    versao_aplicativo = NA_character_, endereco = do_ambiente_nacional$endereco[1], problema = NA_character_
  )
  documentos = data.frame(nsu = character(), schema = character(), tipo = character(), xml = character())
  if (nrow(do_ambiente_nacional) == 0) {
    consulta$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz a Distribui\u00e7\u00e3o de DF-e"
    return(list(consulta = consulta, documentos = documentos))
  }
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  if (nchar(documento) == 14) {
    tipo_do_documento = "CNPJ"
  } else {
    tipo_do_documento = "CPF"
  }
  mensagem = paste0(
    '<distDFeInt xmlns="', NAMESPACE_DA_NFE, '" versao="1.01"><tpAmb>', AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb>",
    "<", tipo_do_documento, ">", documento, "</", tipo_do_documento, ">", grupo_do_pedido$xml, "</distDFeInt>"
  )
  pedido = montar_pedido(consulta$endereco, "NFeDistribuicaoDFe", "nfeDistDFeInteresse", mensagem, "nfeDistDFeInteresse")
  resposta_lida = ler_resposta(enviar_pedidos(list(pedido), conexao)[[1]], "retDistDFeInt")
  if (!is.na(resposta_lida$problema)) {
    consulta$problema = resposta_lida$problema
    return(list(consulta = consulta, documentos = documentos))
  }
  retorno = resposta_lida$retorno
  consulta$situacao = as.integer(texto_do_retorno(retorno, "cStat"))
  consulta$motivo = texto_do_retorno(retorno, "xMotivo")
  consulta$processamento = data_hora(texto_do_retorno(retorno, "dhResp"))
  consulta$ultimo_nsu = texto_do_retorno(retorno, "ultNSU")
  consulta$maior_nsu = texto_do_retorno(retorno, "maxNSU")
  consulta$versao_aplicativo = texto_do_retorno(retorno, "verAplic")
  if (!identical(texto_do_retorno(retorno, "tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    consulta$problema = "a SEFAZ respondeu de outro ambiente"
    return(list(consulta = consulta, documentos = documentos))
  }
  documentos = documentos_da_distribuicao(xml2::xml_find_all(retorno, "./*[local-name()='loteDistDFeInt']/*[local-name()='docZip']"))
  consulta$documentos = nrow(documentos)
  # 137 (nenhum documento), o último NSU já igual ao maior ou o bloqueio (656): a próxima pergunta pelo último NSU só
  # depois de uma hora.
  sem_mais_documentos = consulta$situacao %in% c(137L, 656L) ||
    (!is.na(consulta$ultimo_nsu) && identical(consulta$ultimo_nsu, consulta$maior_nsu))
  if (grupo_do_pedido$pelo_ultimo_nsu && sem_mais_documentos) {
    quando_nao_havia_mais_documentos[[memoria]] = Sys.time()
  }
  list(consulta = consulta, documentos = documentos)
}

# O grupo do pedido: o último NSU (distNSU), um NSU (consNSU) ou uma chave (consChNFe). O NSU tem 15 dígitos.
grupo_da_distribuicao = function(ultimo_nsu, nsu, chave) {
  if (length(chave) == 1 && !is.na(chave)) {
    chave_limpa = limpar_chaves(chave)
    if (!chave_valida(chave_limpa)) {
      stop("A chave n\u00e3o confere: ", chave_decompor(chave_limpa)$problema, ".", call. = FALSE)
    }
    return(list(xml = paste0("<consChNFe><chNFe>", chave_limpa, "</chNFe></consChNFe>"), pelo_ultimo_nsu = FALSE))
  }
  if (length(nsu) == 1 && !is.na(nsu)) {
    return(list(xml = paste0("<consNSU><NSU>", nsu_com_15_digitos(nsu), "</NSU></consNSU>"), pelo_ultimo_nsu = FALSE))
  }
  list(xml = paste0("<distNSU><ultNSU>", nsu_com_15_digitos(ultimo_nsu), "</ultNSU></distNSU>"), pelo_ultimo_nsu = TRUE)
}

nsu_com_15_digitos = function(nsu) {
  if (is.numeric(nsu)) {
    nsu = format(nsu, scientific = FALSE, trim = TRUE)
  }
  nsu = as.character(nsu)
  if (length(nsu) != 1 || is.na(nsu) || !grepl("^[0-9]{1,15}$", nsu)) {
    stop("O NSU tem de ter de 1 a 15 d\u00edgitos.", call. = FALSE)
  }
  paste0(strrep("0", 15 - nchar(nsu)), nsu)
}

# Cada docZip: o NSU, o schema e o XML, que vem em gzip dentro do base64.
documentos_da_distribuicao = function(documentos_zipados) {
  nsus = xml2::xml_attr(documentos_zipados, "NSU")
  schemas = xml2::xml_attr(documentos_zipados, "schema")
  textos = character(length(documentos_zipados))
  for (posicao in seq_along(documentos_zipados)) {
    compactado = openssl::base64_decode(xml2::xml_text(documentos_zipados[[posicao]]))
    texto = rawToChar(memDecompress(compactado, type = "gzip"))
    Encoding(texto) = "UTF-8"
    textos[posicao] = texto
  }
  data.frame(nsu = as.character(nsus), schema = as.character(schemas), tipo = sub("_v?[0-9.]+\\.xsd$", "", as.character(schemas)),
             xml = textos)
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
# da lista "demais serviços". Na consulta de cadastro, a página só lista AC, ES, PB, RN e SC para a SVRS, mas a SVRS
# atende todas as UFs dela: em homologação (03/11/2026) AL, AP, CE, DF, PA, PI, RJ, RO, RR, SE e TO responderam como as
# da lista, e só o MA (da SVAN) voltou 410, "UF não é atendida"; em produção, o app Fiscal consulta CE, AL e PI por lá.
servico_da_uf = function(uf, servico, ambiente) {
  autorizadores = tabela_interna("autorizadores_sefaz")
  usos = c("todos os servi\u00e7os", "demais servi\u00e7os")
  if (servico == "NfeConsultaCadastro") {
    usos = c("todos os servi\u00e7os", "consulta de cadastro", "demais servi\u00e7os")
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

# A mensagem no envelope SOAP 1.2: o elemento nfeDadosMsg, no namespace do serviço, e a action do WSDL. Quando o WSDL
# de uma SEFAZ pede o nfeDadosMsg dentro de outro elemento (o consultaCadastro do MT), `elemento_em_volta` diz qual.
montar_pedido = function(endereco, servico_do_wsdl, operacao, mensagem, elemento_em_volta = NA) {
  namespace_do_servico = paste0("http://www.portalfiscal.inf.br/nfe/wsdl/", servico_do_wsdl)
  if (is.na(elemento_em_volta)) {
    corpo_do_envelope = paste0('<nfeDadosMsg xmlns="', namespace_do_servico, '">', mensagem, "</nfeDadosMsg>")
  } else {
    corpo_do_envelope = paste0('<', elemento_em_volta, ' xmlns="', namespace_do_servico, '"><nfeDadosMsg>', mensagem,
                               "</nfeDadosMsg></", elemento_em_volta, ">")
  }
  envelope = paste0(
    '<?xml version="1.0" encoding="utf-8"?>',
    '<soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Body>',
    corpo_do_envelope,
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

# O retorno pedido (`nome_do_retorno`: retConsStatServ, retConsSitNFe, retConsCad) onde estiver na resposta; sem ele, o
# motivo vai em `problema`. Ele costuma vir no nfeResultMsg, mas o envelope muda de SEFAZ para SEFAZ (na consulta de
# cadastro, o AM e MG usam consultaCadastro4Result e o MT põe um consultaCadastroResult no meio).
ler_resposta = function(resposta, nome_do_retorno) {
  if (!is.na(resposta$erro)) {
    return(list(retorno = NULL, problema = paste("sem resposta da SEFAZ:", gsub("\\s+", " ", resposta$erro))))
  }
  xml_da_resposta = tryCatch(xml2::read_xml(resposta$corpo), error = function(erro) NULL)
  if (is.null(xml_da_resposta)) {
    return(list(retorno = NULL, problema = paste0("HTTP ", resposta$situacao_http, ": a SEFAZ n\u00e3o respondeu em XML")))
  }
  # As buscas são pelo nome local: cada SEFAZ põe o prefixo de namespace que quer (soap:, ns2:...) ou nenhum.
  retorno = xml2::xml_find_first(xml_da_resposta, paste0("//*[local-name()='", nome_do_retorno, "']"))
  if (inherits(retorno, "xml_missing")) {
    falha = xml2::xml_find_first(
      xml_da_resposta, "//*[local-name()='Fault']//*[local-name()='Text' or local-name()='faultstring']"
    )
    if (inherits(falha, "xml_missing")) {
      return(list(retorno = NULL, problema = paste0("HTTP ", resposta$situacao_http, ": a resposta n\u00e3o traz o ", nome_do_retorno)))
    }
    return(list(retorno = NULL, problema = paste0("HTTP ", resposta$situacao_http, ": ", trimws(xml2::xml_text(falha)))))
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
