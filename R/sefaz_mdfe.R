# A emissão do MDF-e e os eventos do emitente: o encerramento (110112), a inclusão de condutor (110114) e a de DF-e
# (110115). Pelo MOC do MDF-e 3.00b: a recepção é síncrona, sem lote, com o MDF-e compactado em gzip dentro do
# base64; os eventos vão em XML sem compactação; o cabeçalho SOAP (mdfeCabecMsg) foi descontinuado e não vai. O MDF-e
# é todo da SVRS. Só o ambiente de homologação.

#' @include sefaz.R assinatura.R sefaz_evento.R nfse_emitir.R
NULL

NAMESPACE_DO_MDFE = "http://www.portalfiscal.inf.br/mdfe"
# As situações do MDF-e autorizado (o protocolo do retMDFe).
SITUACOES_DO_MDFE_AUTORIZADO = c(100L)

#' Autorizar um MDF-e
#'
#' Manda o MDF-e assinado à SVRS, que o autoriza na hora (a recepção do MDF-e é
#' síncrona, sem lote). O MDF-e vai compactado, como o manual pede. O
#' autorizado volta no `mdfeProc` (o MDF-e e o protocolo), que o [mdfe_ler()]
#' lê. Depois de chegar ao destino, o MDF-e tem de ser encerrado
#' ([sefaz_mdfe_encerrar()]).
#'
#' Assine antes com [xml_assinar()]. Por enquanto só o ambiente de
#' **homologação**: o MDF-e com o `tpAmb` 1 nem é enviado.
#'
#' @param xml O MDF-e assinado: o caminho do arquivo ou o texto do XML.
#' @inheritParams sefaz_status
#' @return Um `data.frame` com uma linha: `chave`, `ambiente`, `situacao_envio`
#'   e `motivo_envio` (o retorno do envio), `situacao` (100 autorizado; as
#'   outras são rejeição), `motivo`, `protocolo`, `autorizacao` (data e hora),
#'   `xml_autorizado` (o `mdfeProc`), `endereco` e `problema`.
#' @seealso [xml_assinar()], [sefaz_mdfe_encerrar()],
#'   [sefaz_mdfe_incluir_condutor()], [sefaz_situacao()]
#' @source Manual de Orientação do Contribuinte do MDF-e, versão 3.00b (Anexo
#'   XII, a recepção síncrona MDFeRecepcaoSinc e os eventos), e os schemas do
#'   pacote PL_MDFe_300b (`mdfe_v3.00.xsd`, `retMDFe_v3.00.xsd`).
#' @examples
#' \dontrun{
#' assinado = xml_assinar("mdfe.xml", "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' autorizado = sefaz_mdfe_autorizar(assinado, "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' autorizado[, c("chave", "situacao", "motivo", "protocolo")]
#' }
#' @export
sefaz_mdfe_autorizar = function(xml, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  exigir_pacotes(c("httr2", "curl", "openssl"))
  conferir_certificado(certificado, senha)
  lido = ler_o_mdfe_para_autorizar(xml, ambiente, certificado, senha)
  linha = data.frame(
    chave = lido$chave, ambiente = ambiente, situacao_envio = NA_integer_, motivo_envio = NA_character_,
    situacao = NA_integer_, motivo = NA_character_, protocolo = NA_character_, autorizacao = as.POSIXct(NA),
    xml_autorizado = NA_character_, endereco = NA_character_, problema = NA_character_
  )
  servico = servico_da_uf(UF_PELO_CODIGO[[substr(lido$chave, 1, 2)]], "MDFeRecepcaoSinc", ambiente, "MDF-e")
  if (is.null(servico)) {
    linha$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz a recep\u00e7\u00e3o do MDF-e para a UF"
    return(linha)
  }
  linha$endereco = servico$endereco
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  pedido = montar_pedido(servico$endereco, "MDFeRecepcaoSinc", "mdfeRecepcao", gzip_em_base64(lido$texto), familia = "mdfe")
  resposta = enviar_pedidos(list(pedido), conexao)[[1]]
  linha = completar_autorizacao_do_mdfe(linha, ler_resposta(resposta, "retMDFe"), lido$texto, ambiente)
  attr(linha$autorizacao, "tzone") = "America/Sao_Paulo"
  linha
}

# O MDFe de um XML, conferido: um só, assinado, de homologação e com a chave do modelo 58. Sai o texto dele, sem a
# declaração, com o namespace.
ler_o_mdfe_para_autorizar = function(xml, ambiente, certificado, senha) {
  documento = ler_o_xml_para_assinar(xml)
  manifestos = xml2::xml_find_all(documento, "//*[local-name()='MDFe' and *[local-name()='infMDFe']]")
  if (length(manifestos) != 1) {
    stop("O XML tem de trazer um MDF-e (um MDFe com o infMDFe).", call. = FALSE)
  }
  manifesto = manifestos[[1]]
  if (length(xml2::xml_find_all(manifesto, "*[local-name()='Signature']")) == 0) {
    stop("O MDF-e n\u00e3o est\u00e1 assinado (veja xml_assinar()).", call. = FALSE)
  }
  informacao = xml2::xml_find_first(manifesto, "*[local-name()='infMDFe']")
  if (!identical(texto_pelo_caminho(informacao, "ide/tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    stop("O MDF-e tem de ser do ambiente de homologa\u00e7\u00e3o (tpAmb 2).", call. = FALSE)
  }
  chave = sub("^MDFe", "", xml2::xml_attr(informacao, "Id"))
  partes = chave_decompor(chave)
  if (!partes$valida || !identical(partes$modelo, "58")) {
    stop("O Id do infMDFe n\u00e3o traz uma chave de MDF-e v\u00e1lida.", call. = FALSE)
  }
  # O QR-Code (infMDFeSupl), quando falta: o endereço da SVRS com a chave e o ambiente e, na contingência (tpEmis 2),
  # a assinatura da chave (o item 9.2.2 do MOC). Fica fora do que a assinatura cobre, entre o infMDFe e a assinatura.
  if (inherits(xml2::xml_find_first(manifesto, "*[local-name()='infMDFeSupl']"), "xml_missing")) {
    servicos = tabela_interna("servicos_sefaz")
    endereco_do_qrcode = servicos$endereco[servicos$documento == "MDF-e" & servicos$ambiente == ambiente &
                                             servicos$servico == "QR Code"][1]
    qrcode = paste0(endereco_do_qrcode, "?chMDFe=", chave, "&tpAmb=", AMBIENTES_LIBERADOS[[ambiente]])
    if (identical(texto_pelo_caminho(informacao, "ide/tpEmis"), "2")) {
      qrcode = paste0(qrcode, "&sign=", assinatura_da_chave_do_mdfe(chave, certificado, senha))
    }
    grupo = paste0('<infMDFeSupl xmlns="', NAMESPACE_DO_MDFE, '"><qrCodMDFe>', escapar_texto_canonico(qrcode),
                   "</qrCodMDFe></infMDFeSupl>")
    xml2::xml_add_sibling(informacao, xml2::xml_root(xml2::read_xml(grupo)), .where = "after")
  }
  texto = trimws(as.character(xml2::xml_new_root(manifesto), options = "no_declaration"))
  list(chave = chave, texto = texto)
}

# O parâmetro sign do QR-Code do MDF-e em contingência: a chave assinada em RSA-SHA1 com o certificado que assina o
# MDF-e, em base64 (o item 9.2.2 do MOC do MDF-e 3.00b).
assinatura_da_chave_do_mdfe = function(chave, certificado, senha) {
  conteudo = openssl::read_p12(certificado, password = senha)
  openssl::base64_encode(openssl::signature_create(charToRaw(chave), hash = openssl::sha1, key = conteudo$key))
}

# O retorno da recepção (retMDFe): a situação do envio e o protocolo; o autorizado ganha o mdfeProc.
completar_autorizacao_do_mdfe = function(linha, resposta_lida, texto_do_manifesto, ambiente) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  retorno = resposta_lida$retorno
  if (!identical(texto_do_retorno(retorno, "tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a SEFAZ respondeu de outro ambiente"
    return(linha)
  }
  linha$situacao_envio = as.integer(texto_do_retorno(retorno, "cStat"))
  linha$motivo_envio = texto_do_retorno(retorno, "xMotivo")
  protocolo = xml2::xml_find_first(retorno, "./*[local-name()='protMDFe']")
  if (inherits(protocolo, "xml_missing")) {
    return(linha)
  }
  informacao = xml2::xml_find_first(protocolo, "./*[local-name()='infProt']")
  if (!identical(texto_do_retorno(informacao, "chMDFe"), linha$chave)) {
    linha$problema = "a SEFAZ respondeu sobre outra chave"
    return(linha)
  }
  linha$situacao = as.integer(texto_do_retorno(informacao, "cStat"))
  linha$motivo = texto_do_retorno(informacao, "xMotivo")
  linha$protocolo = texto_do_retorno(informacao, "nProt")
  linha$autorizacao = data_hora_da_consulta(texto_do_retorno(informacao, "dhRecbto"))
  if (linha$situacao %in% SITUACOES_DO_MDFE_AUTORIZADO) {
    texto_do_protocolo = trimws(as.character(xml2::xml_new_root(protocolo), options = "no_declaration"))
    linha$xml_autorizado = paste0('<?xml version="1.0" encoding="UTF-8"?><mdfeProc xmlns="', NAMESPACE_DO_MDFE,
                                  '" versao="3.00">', texto_do_manifesto, texto_do_protocolo, "</mdfeProc>")
  }
  linha
}

#' Encerrar um MDF-e
#'
#' Registra o encerramento do MDF-e (o evento 110112): a viagem acabou, no
#' município e na data informados. Sem o encerramento, a SVRS não deixa emitir
#' outro MDF-e para o mesmo veículo e a mesma UF de carregamento.
#' `sefaz_mdfe_incluir_condutor()` acrescenta um condutor ao MDF-e rodoviário
#' (o evento 110114). `sefaz_mdfe_incluir_dfe()` inclui NF-e no MDF-e emitido
#' com carregamento posterior (`indCarregaPosterior` 1, o MDF-e de carga
#' própria em operação dentro da UF, quando o emitente, no início da viagem,
#' não tem acesso aos documentos fiscais transportados): o evento 110115, com o município onde as notas foram carregadas e o
#' de descarregamento de cada uma. O MDF-e sem carregamento posterior é
#' recusado pela SEFAZ (708), e o com carregamento posterior só se encerra
#' depois de uma inclusão (715).
#'
#' O autor do evento é o emitente da chave (o CNPJ ou, nas séries 920 a 969, o
#' CPF), e o certificado pode ser o dele ou o de outro estabelecimento da
#' empresa (o mesmo CNPJ-base). Por enquanto só o ambiente de **homologação**.
#'
#' @param chave A chave de acesso do MDF-e.
#' @param protocolo O número do protocolo de autorização do MDF-e.
#' @param uf A UF do encerramento, pela sigla (`"EX"` para o exterior).
#' @param municipio O código IBGE do município do encerramento (7 números;
#'   `"9999999"` no exterior).
#' @param data A data do encerramento.
#' @inheritParams sefaz_cancelar
#' @return Um `data.frame` com uma linha, como o de [sefaz_cancelar()]: a
#'   situação 135 é o evento registrado, e `xml_evento` traz o
#'   `procEventoMDFe`, que o [eventos_ler()] lê.
#' @seealso [sefaz_mdfe_autorizar()], [sefaz_mdfe_nao_encerrados()]
#' @source Manual de Orientação do Contribuinte do MDF-e, versão 3.00b, itens
#'   2.1.9 (o MDF-e com carregamento posterior), 5 e 6 (o serviço de eventos, o
#'   encerramento, a inclusão de condutor e a de DF-e), e os schemas
#'   `eventoMDFe_v3.00.xsd`, `evEncMDFe_v3.00.xsd`,
#'   `evIncCondutorMDFe_v3.00.xsd` e `evInclusaoDFeMDFe_v3.00.xsd`.
#' @examples
#' \dontrun{
#' sefaz_mdfe_encerrar("23261012ABC34501DE35580010000003211112233440", "923260000012345",
#'                     "CE", "2304400", Sys.Date(), "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
sefaz_mdfe_encerrar = function(chave, protocolo, uf, municipio, data = Sys.Date(), certificado, senha,
                               ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_protocolo_do_mdfe(protocolo)
  if (length(uf) != 1 || is.na(uf) || !(uf %in% c(names(CODIGO_DA_UF), "EX"))) {
    stop("Informe a UF do encerramento pela sigla (\"EX\" para o exterior).", call. = FALSE)
  }
  codigo_da_uf = if (uf == "EX") "99" else CODIGO_DA_UF[[uf]]
  conferir_municipio_do_evento(municipio, "do encerramento")
  data = as.Date(data)
  if (length(data) != 1 || is.na(data)) {
    stop("Informe a data do encerramento.", call. = FALSE)
  }
  detalhe = paste0("<evEncMDFe><descEvento>Encerramento</descEvento><nProt>", protocolo, "</nProt><dtEnc>", format(data),
                   "</dtEnc><cUF>", codigo_da_uf, "</cUF><cMun>", municipio, "</cMun></evEncMDFe>")
  registrar_evento_do_mdfe(chave, "110112", 1L, detalhe, certificado, senha, ambiente)
}

#' @rdname sefaz_mdfe_encerrar
#' @param nome,cpf O nome e o CPF do condutor incluído.
#' @param sequencia O número do evento para o MDF-e: 1 no primeiro condutor
#'   (ou na primeira inclusão de DF-e), 2 no segundo, até 99. Na inclusão de
#'   DF-e, o MOC diz que só vale a 1, mas a SVRS registrou a 2 em homologação
#'   (10/11/2026): cada nova inclusão no mesmo MDF-e leva a sequência seguinte.
#' @export
sefaz_mdfe_incluir_condutor = function(chave, nome, cpf, sequencia = 1, certificado, senha, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_texto_do_evento(nome, "nome", 2, 60)
  if (length(cpf) != 1 || is.na(cpf) || !cpf_confere(cpf)) {
    stop("Informe o CPF do condutor (11 n\u00fameros, com o d\u00edgito certo).", call. = FALSE)
  }
  sequencia = conferir_sequencia_do_evento(sequencia)
  detalhe = paste0("<evIncCondutorMDFe><descEvento>Inclusao Condutor</descEvento><condutor><xNome>",
                   escapar_texto_canonico(nome), "</xNome><CPF>", cpf, "</CPF></condutor></evIncCondutorMDFe>")
  registrar_evento_do_mdfe(chave, "110114", sequencia, detalhe, certificado, senha, ambiente)
}

#' @rdname sefaz_mdfe_encerrar
#' @param municipio_carregamento,nome_carregamento O código IBGE (7 números) e
#'   o nome do município onde as NF-e incluídas foram carregadas.
#' @param chaves_nfe As chaves das NF-e incluídas no MDF-e.
#' @param municipios_descarregamento,nomes_descarregamento O código IBGE e o
#'   nome do município de descarregamento de cada NF-e (um só vale para todas).
#' @export
sefaz_mdfe_incluir_dfe = function(chave, protocolo, municipio_carregamento, nome_carregamento, chaves_nfe,
                                  municipios_descarregamento, nomes_descarregamento, sequencia = 1, certificado, senha,
                                  ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_protocolo_do_mdfe(protocolo)
  conferir_municipio_do_evento(municipio_carregamento, "do carregamento")
  conferir_texto_do_evento(nome_carregamento, "o nome do munic\u00edpio do carregamento", 2, 60)
  chaves_limpas = limpar_chaves(chaves_nfe)
  partes_das_chaves = chave_decompor(chaves_limpas)
  if (length(chaves_limpas) == 0 || !all(partes_das_chaves$valida %in% TRUE) || !all(partes_das_chaves$modelo %in% "55")) {
    stop("Informe as chaves das NF-e (modelo 55, 44 posi\u00e7\u00f5es, com o d\u00edgito certo).", call. = FALSE)
  }
  if (anyDuplicated(chaves_limpas) > 0) {
    stop("A mesma NF-e aparece mais de uma vez.", call. = FALSE)
  }
  if (length(municipios_descarregamento) == 1) {
    municipios_descarregamento = rep(municipios_descarregamento, length(chaves_limpas))
  }
  if (length(nomes_descarregamento) == 1) {
    nomes_descarregamento = rep(nomes_descarregamento, length(chaves_limpas))
  }
  if (length(municipios_descarregamento) != length(chaves_limpas) || length(nomes_descarregamento) != length(chaves_limpas)) {
    stop("Informe um munic\u00edpio de descarregamento para todas as NF-e ou um para cada uma.", call. = FALSE)
  }
  documentos = character()
  for (posicao in seq_along(chaves_limpas)) {
    conferir_municipio_do_evento(municipios_descarregamento[posicao], "do descarregamento")
    conferir_texto_do_evento(nomes_descarregamento[posicao], "o nome do munic\u00edpio do descarregamento", 2, 60)
    documentos = c(documentos, paste0("<infDoc><cMunDescarga>", municipios_descarregamento[posicao], "</cMunDescarga>",
                                      "<xMunDescarga>", escapar_texto_canonico(nomes_descarregamento[posicao]),
                                      "</xMunDescarga><chNFe>", chaves_limpas[posicao], "</chNFe></infDoc>"))
  }
  sequencia = conferir_sequencia_do_evento(sequencia)
  detalhe = paste0("<evIncDFeMDFe><descEvento>Inclusao DF-e</descEvento><nProt>", protocolo, "</nProt><cMunCarrega>",
                   municipio_carregamento, "</cMunCarrega><xMunCarrega>", escapar_texto_canonico(nome_carregamento),
                   "</xMunCarrega>", paste(documentos, collapse = ""), "</evIncDFeMDFe>")
  registrar_evento_do_mdfe(chave, "110115", sequencia, detalhe, certificado, senha, ambiente)
}

conferir_protocolo_do_mdfe = function(protocolo) {
  if (length(protocolo) != 1 || is.na(protocolo) || !grepl("^[0-9]{15}$", protocolo)) {
    stop("Informe o protocolo de autoriza\u00e7\u00e3o do MDF-e (15 algarismos).", call. = FALSE)
  }
}

conferir_municipio_do_evento = function(municipio, de_que) {
  if (length(municipio) != 1 || is.na(municipio) || !grepl("^[0-9]{7}$", municipio)) {
    stop("Informe o c\u00f3digo IBGE do munic\u00edpio ", de_que, " (7 n\u00fameros).", call. = FALSE)
  }
}

# O schema do detalhe de cada evento do MDF-e (em inst/schemas/mdfe), que a mensagem assinada segue antes de ir à SEFAZ.
SCHEMA_DO_DETALHE_DO_EVENTO_DO_MDFE = c("110112" = "evEncMDFe_v3.00.xsd", "110114" = "evIncCondutorMDFe_v3.00.xsd",
                                         "110115" = "evInclusaoDFeMDFe_v3.00.xsd")

registrar_evento_do_mdfe = function(chave, codigo_do_evento, sequencia, detalhe, certificado, senha, ambiente) {
  exigir_pacotes(c("httr2", "curl", "openssl"))
  chave_limpa = limpar_chaves(chave)
  partes = chave_decompor(chave_limpa)
  if (length(chave_limpa) != 1 || !partes$valida || !identical(partes$modelo, "58")) {
    stop("Informe a chave de um MDF-e (44 posi\u00e7\u00f5es, com o d\u00edgito certo).", call. = FALSE)
  }
  conferir_certificado(certificado, senha)
  autor = autor_do_emitente(partes, SERIES_DO_CPF_NO_MDFE, certificado, senha)
  linha = data.frame(
    chave = chave_limpa, evento = codigo_do_evento, sequencia = sequencia, ambiente = ambiente,
    situacao_lote = NA_integer_, motivo_lote = NA_character_, situacao = NA_integer_, motivo = NA_character_,
    protocolo = NA_character_, registro = as.POSIXct(NA), xml_evento = NA_character_, endereco = NA_character_,
    problema = NA_character_
  )
  servico = servico_da_uf(partes$uf, "MDFeRecepcaoEvento", ambiente, "MDF-e")
  if (is.null(servico)) {
    linha$problema = "a Rela\u00e7\u00e3o de Servi\u00e7os Web n\u00e3o traz o servi\u00e7o de eventos do MDF-e para a UF"
    return(linha)
  }
  linha$endereco = servico$endereco
  campo_do_autor = if (autor$tipo_documento == "CPF") "CPF" else "CNPJ"
  identificador = paste0("ID", codigo_do_evento, chave_limpa, sprintf("%02d", sequencia))
  evento = paste0(
    '<eventoMDFe xmlns="', NAMESPACE_DO_MDFE, '" versao="3.00"><infEvento Id="', identificador, '"><cOrgao>',
    partes$codigo_uf, "</cOrgao><tpAmb>", AMBIENTES_LIBERADOS[[ambiente]], "</tpAmb><", campo_do_autor, ">",
    autor$documento, "</", campo_do_autor, "><chMDFe>", chave_limpa, "</chMDFe><dhEvento>", data_hora_do_evento(Sys.time()),
    "</dhEvento><tpEvento>", codigo_do_evento, "</tpEvento><nSeqEvento>", sequencia,
    '</nSeqEvento><detEvento versaoEvento="3.00">', detalhe, "</detEvento></infEvento></eventoMDFe>"
  )
  evento_assinado = sub("^<\\?xml[^>]*\\?>\\s*", "", xml_assinar(evento, certificado, senha))
  conferir_o_evento_no_schema(evento_assinado, "mdfe", "eventoMDFe_v3.00.xsd", SCHEMA_DO_DETALHE_DO_EVENTO_DO_MDFE[[codigo_do_evento]])
  pedido = montar_pedido(servico$endereco, "MDFeRecepcaoEvento", "mdfeRecepcaoEvento", evento_assinado, familia = "mdfe")
  pasta_temporaria = tempfile("rnfe_")
  dir.create(pasta_temporaria)
  on.exit(unlink(pasta_temporaria, recursive = TRUE), add = TRUE)
  conexao = preparar_conexao(certificado, senha, pasta_temporaria)
  resposta = enviar_pedidos(list(pedido), conexao)[[1]]
  linha = completar_evento_do_mdfe(linha, ler_resposta(resposta, "retEventoMDFe"), evento_assinado, ambiente)
  attr(linha$registro, "tzone") = "America/Sao_Paulo"
  linha
}

# O retorno do evento (retEventoMDFe, sem lote); o evento registrado ganha o procEventoMDFe.
completar_evento_do_mdfe = function(linha, resposta_lida, evento_assinado, ambiente) {
  if (!is.na(resposta_lida$problema)) {
    linha$problema = resposta_lida$problema
    return(linha)
  }
  retorno = resposta_lida$retorno
  informacao = xml2::xml_find_first(retorno, "./*[local-name()='infEvento']")
  if (!identical(texto_do_retorno(informacao, "tpAmb"), as.character(AMBIENTES_LIBERADOS[[ambiente]]))) {
    linha$problema = "a SEFAZ respondeu de outro ambiente"
    return(linha)
  }
  chave_do_retorno = texto_do_retorno(informacao, "chMDFe")
  if (!is.na(chave_do_retorno) && !identical(chave_do_retorno, linha$chave)) {
    linha$problema = "a SEFAZ respondeu sobre outra chave"
    return(linha)
  }
  if (retorno_de_outro_evento(informacao, linha)) {
    linha$problema = PROBLEMA_DO_RETORNO_DE_OUTRO_EVENTO
    return(linha)
  }
  linha$situacao = as.integer(texto_do_retorno(informacao, "cStat"))
  linha$motivo = texto_do_retorno(informacao, "xMotivo")
  linha$protocolo = texto_do_retorno(informacao, "nProt")
  linha$registro = data_hora_da_consulta(texto_do_retorno(informacao, "dhRegEvento"))
  if (linha$situacao %in% SITUACOES_DO_EVENTO_REGISTRADO) {
    texto_do_retorno_do_evento = trimws(as.character(xml2::xml_new_root(retorno), options = "no_declaration"))
    linha$xml_evento = paste0('<?xml version="1.0" encoding="UTF-8"?><procEventoMDFe xmlns="', NAMESPACE_DO_MDFE,
                              '" versao="3.00">', evento_assinado, texto_do_retorno_do_evento, "</procEventoMDFe>")
  }
  linha
}
