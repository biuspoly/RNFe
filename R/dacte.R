# O DACTE e o DACTE OS em PDF (A4, retrato), pelo modelo do modal rodoviário do MOC do CT-e 4.00 (DACTE e DACTE OS,
# itens 2 e 4): o canhoto, o emitente, o quadro do DACTE, o código de barras e o QR-Code, o protocolo, a prestação, as
# pessoas, a carga, os componentes do valor, o imposto, os documentos originários, as observações e o quadro do modal.
# Os documentos que não cabem seguem em folhas adicionais, com o cabeçalho.

#' @include pdf_comum.R danfe.R
NULL

NOMES_DOS_MODAIS_DO_CTE = c("01" = "RODOVI\u00c1RIO", "02" = "A\u00c9REO", "03" = "AQUAVI\u00c1RIO", "04" = "FERROVI\u00c1RIO",
                            "05" = "DUTOVI\u00c1RIO", "06" = "MULTIMODAL")
TIPOS_DO_CTE = c("0" = "NORMAL", "1" = "COMPLEMENTO DE VALORES", "2" = "ANULA\u00c7\u00c3O", "3" = "SUBSTITUTO")
TIPOS_DO_SERVICO_DO_CTE = c("0" = "NORMAL", "1" = "SUBCONTRATA\u00c7\u00c3O", "2" = "REDESPACHO",
                            "3" = "REDESPACHO INTERMEDI\u00c1RIO", "4" = "SERVI\u00c7O VINCULADO A MULTIMODAL")
ENDERECO_DA_CONSULTA_DO_CTE = "http://www.cte.fazenda.gov.br/portal"
DOCUMENTOS_NA_PRIMEIRA_FOLHA_DO_DACTE = 6

#' DACTE e DACTE OS em PDF
#'
#' Desenha o DACTE (o documento auxiliar do CT-e) ou o DACTE OS em A4, pelo
#' modelo do Manual de Orientação do CT-e 4.00: o canhoto, o emitente, o
#' modal, o modelo, a série, o número, a emissão, o código de barras da chave
#' (CODE-128C, ou o híbrido com o A no CNPJ alfanumérico), a consulta, o
#' protocolo, o QR-Code (o `qrCodCTe` do XML), o tipo do CT-e e do serviço, o
#' CFOP e a natureza, o início e o término da prestação, o remetente, o
#' destinatário, o expedidor, o recebedor e o tomador, a carga, os
#' componentes do valor, o ICMS, os documentos originários, as observações e
#' o RNTRC. Os documentos que não cabem na primeira folha seguem nas
#' adicionais. O CT-e de homologação leva "EMITIDO EM AMBIENTE DE HOMOLOGAÇÃO -
#' SEM VALOR FISCAL".
#'
#' Precisa do pacote `qrcode`.
#'
#' @param xml O CT-e ou o CT-e OS: o caminho do arquivo ou o texto do XML (o
#'   `cteProc`, com o protocolo).
#' @param arquivo O PDF a gravar.
#' @return O caminho do PDF, invisível.
#' @seealso [cte_ler()], [sefaz_cte_desacordo()]
#' @source Manual de Orientação do Contribuinte do CT-e 4.00, on-line: DACTE e
#'   DACTE OS (itens 2, 3 e 4, e o modelo do modal rodoviário).
#' @examples
#' \donttest{
#' if (requireNamespace("qrcode", quietly = TRUE)) {
#'   cte = system.file("exemplos", "cte_proc_sp.xml", package = "RNFe")
#'   dacte_pdf(cte, file.path(tempdir(), "dacte.pdf"))
#' }
#' }
#' @export
dacte_pdf = function(xml, arquivo) {
  exigir_pacotes("qrcode")
  documento = ler_o_xml_para_assinar(xml)
  conhecimento = xml2::xml_find_first(documento, "//*[(local-name()='CTe' or local-name()='CTeOS')]")
  informacao = xml2::xml_find_first(conhecimento, "*[local-name()='infCte']")
  if (inherits(informacao, "xml_missing")) {
    stop("O XML n\u00e3o traz um CT-e ou CT-e OS (o elemento CTe com o infCte).", call. = FALSE)
  }
  cte = list(
    informacao = informacao, chave = sub("^CTe", "", xml2::xml_attr(informacao, "Id")),
    qrcode = texto_pelo_caminho(conhecimento, "infCTeSupl/qrCodCTe"),
    protocolo = xml2::xml_find_first(documento, "//*[local-name()='protCTe']/*[local-name()='infProt']"),
    documentos = documentos_originarios_do_dacte(informacao)
  )
  abrir_o_pdf(arquivo, LARGURA_DO_A4, ALTURA_DO_A4)
  on.exit(grDevices::dev.off(), add = TRUE)
  grid::grid.newpage()
  restantes = cte$documentos[-seq_len(min(nrow(cte$documentos), DOCUMENTOS_NA_PRIMEIRA_FOLHA_DO_DACTE)), , drop = FALSE]
  por_folha_adicional = 40
  total = 1 + ceiling(nrow(restantes) / por_folha_adicional)
  desenhar_cabecalho_do_dacte(cte, 1, total, com_canhoto = TRUE)
  desenhar_corpo_do_dacte(cte)
  for (folha in seq_len(total - 1)) {
    grid::grid.newpage()
    desenhar_cabecalho_do_dacte(cte, folha + 1, total, com_canhoto = FALSE)
    linhas = restantes[seq(((folha - 1) * por_folha_adicional) + 1, min(nrow(restantes), folha * por_folha_adicional)), , drop = FALSE]
    desenhar_documentos_do_dacte(linhas, 9.6, "DOCUMENTOS ORIGIN\u00c1RIOS (CONTINUA\u00c7\u00c3O)")
  }
  invisible(arquivo)
}

# Os documentos originários: as NF-e (pela chave), as NF em papel e os outros documentos, e os documentos dos CT-e
# anteriores; com o tipo, o emitente e a série e o número (ou a chave).
documentos_originarios_do_dacte = function(informacao) {
  linhas = data.frame(tipo = character(), emitente = character(), numero = character())
  for (nfe in xml2::xml_find_all(informacao, ".//*[local-name()='infDoc']/*[local-name()='infNFe']")) {
    chave = texto_pelo_caminho(nfe, "chave")
    linhas = rbind(linhas, data.frame(tipo = "NF-e", emitente = documento_formatado(substr(chave, 7, 20)), numero = chave))
  }
  for (nota in xml2::xml_find_all(informacao, ".//*[local-name()='infDoc']/*[local-name()='infNF']")) {
    linhas = rbind(linhas, data.frame(tipo = paste0("NF ", texto_pelo_caminho(nota, "mod")), emitente = "",
                                      numero = paste0(texto_pelo_caminho(nota, "serie"), "/", texto_pelo_caminho(nota, "nDoc"))))
  }
  for (outro in xml2::xml_find_all(informacao, ".//*[local-name()='infDoc']/*[local-name()='infOutros']")) {
    descricao = texto_pelo_caminho(outro, "descOutros")
    linhas = rbind(linhas, data.frame(tipo = if (is.na(descricao)) paste("OUTROS", texto_pelo_caminho(outro, "tpDoc")) else descricao,
                                      emitente = "", numero = ifelse(is.na(texto_pelo_caminho(outro, "nDoc")), "",
                                                                     texto_pelo_caminho(outro, "nDoc"))))
  }
  for (anterior in xml2::xml_find_all(informacao, ".//*[local-name()='docAnt']//*[local-name()='idDocAntEle']")) {
    chave = texto_pelo_caminho(anterior, "chCTe")
    linhas = rbind(linhas, data.frame(tipo = "CT-e ANTERIOR", emitente = documento_formatado(substr(chave, 7, 20)), numero = chave))
  }
  linhas
}

desenhar_cabecalho_do_dacte = function(cte, folha, total, com_canhoto) {
  informacao = cte$informacao
  if (identical(texto_pelo_caminho(informacao, "ide/tpAmb"), "2")) {
    desenhar_marca_de_homologacao()
  }
  topo = 0.4
  if (com_canhoto) {
    desenhar_caixa(0.4, 0.4, 20.2, 2.0, titulo = paste("DECLARO QUE RECEBI OS VOLUMES DESTE CONHECIMENTO EM PERFEITO ESTADO PELO",
                                                        "QUE DOU POR CUMPRIDO O PRESENTE CONTRATO DE TRANSPORTE"))
    desenhar_caixa(0.4, 0.85, 6.0, 0.75, titulo = "NOME")
    desenhar_caixa(0.4, 1.6, 6.0, 0.8, titulo = "RG")
    desenhar_caixa(6.4, 0.85, 5.6, 1.55, titulo = "ASSINATURA/CARIMBO")
    desenhar_caixa(12.0, 0.85, 4.5, 0.75, titulo = "T\u00c9RMINO DA PRESTA\u00c7\u00c3O - DATA/HORA")
    desenhar_caixa(12.0, 1.6, 4.5, 0.8, titulo = "IN\u00cdCIO DA PRESTA\u00c7\u00c3O - DATA/HORA")
    desenhar_caixa(16.5, 0.85, 4.1, 1.55, titulo = if (identical(texto_pelo_caminho(informacao, "ide/mod"), "67")) "CT-E OS" else "CT-E",
                   conteudo = c(paste("N\u00ba DOCUMENTO", texto_pelo_caminho(informacao, "ide/nCT")),
                                paste("S\u00c9RIE", texto_pelo_caminho(informacao, "ide/serie"))), tamanho_do_conteudo = 9,
                   negrito = TRUE)
    desenhar_linha(0.4, 2.6, 20.6, 2.6, tracejada = TRUE)
    topo = 2.8
  }
  endereco = c(
    paste0(texto_pelo_caminho(informacao, "emit/enderEmit/xLgr"), ", ", texto_pelo_caminho(informacao, "emit/enderEmit/nro")),
    paste0(texto_pelo_caminho(informacao, "emit/enderEmit/xBairro"), " - ", texto_pelo_caminho(informacao, "emit/enderEmit/xMun"),
           " - ", texto_pelo_caminho(informacao, "emit/enderEmit/UF"), " - CEP ",
           cep_formatado(texto_pelo_caminho(informacao, "emit/enderEmit/CEP"))),
    paste0("CNPJ: ", documento_formatado(texto_pelo_caminho(informacao, "emit/CNPJ|emit/CPF")), "  IE: ",
           texto_pelo_caminho(informacao, "emit/IE"),
           ifelse(is.na(texto_pelo_caminho(informacao, "emit/enderEmit/fone")), "",
                  paste0("  FONE: ", texto_pelo_caminho(informacao, "emit/enderEmit/fone"))))
  )
  desenhar_caixa(0.4, topo, 7.6, 3.0, titulo = "IDENTIFICA\u00c7\u00c3O DO EMITENTE")
  desenhar_caixa(0.4, topo + 0.35, 7.6, 1.0, conteudo = quebrar_texto(toupper(texto_pelo_caminho(informacao, "emit/xNome")), 7.4, 10, TRUE),
                 tamanho_do_conteudo = 10, negrito = TRUE, alinhamento = "centre", borda = FALSE)
  desenhar_caixa(0.4, topo + 1.4, 7.6, 1.6, conteudo = endereco, tamanho_do_conteudo = 7, alinhamento = "centre", borda = FALSE)
  modelo = texto_pelo_caminho(informacao, "ide/mod")
  titulo = if (identical(modelo, "67")) "DACTE OS" else "DACTE"
  desenhar_caixa(8.0, topo, 9.2, 1.5)
  desenhar_texto(titulo, 9.6, topo + 0.1, tamanho = 12, negrito = TRUE, alinhamento = "centre")
  desenhar_texto("Documento Auxiliar do", 9.6, topo + 0.6, tamanho = 6, alinhamento = "centre")
  desenhar_texto("Conhecimento de Transporte", 9.6, topo + 0.83, tamanho = 6, alinhamento = "centre")
  desenhar_texto("Eletr\u00f4nico", 9.6, topo + 1.06, tamanho = 6, alinhamento = "centre")
  modal = texto_pelo_caminho(informacao, "ide/modal")
  nome_do_modal = if (!is.na(modal) && modal %in% names(NOMES_DOS_MODAIS_DO_CTE)) NOMES_DOS_MODAIS_DO_CTE[[modal]] else modal
  desenhar_caixa(11.2, topo, 3.0, 0.75, titulo = "MODAL", conteudo = nome_do_modal, tamanho_do_conteudo = 9, negrito = TRUE,
                 alinhamento = "centre")
  desenhar_caixa(14.2, topo, 3.0, 0.75, titulo = "FL", conteudo = sprintf("%d/%d", folha, total), tamanho_do_conteudo = 9,
                 negrito = TRUE, alinhamento = "centre")
  emissao = texto_pelo_caminho(informacao, "ide/dhEmi")
  identificacao = list(list(11.2, 1.0, "MODELO", modelo), list(12.2, 1.0, "S\u00c9RIE", texto_pelo_caminho(informacao, "ide/serie")),
                       list(13.2, 1.6, "N\u00daMERO", texto_pelo_caminho(informacao, "ide/nCT")),
                       list(14.8, 2.4, "EMISS\u00c3O", paste(data_do_xml(emissao), hora_do_xml(emissao))))
  for (caixa in identificacao) {
    desenhar_caixa(caixa[[1]], topo + 0.75, caixa[[2]], 0.75, titulo = caixa[[3]], conteudo = caixa[[4]], tamanho_do_conteudo = 7,
                   negrito = TRUE)
  }
  desenhar_caixa(8.0, topo + 1.5, 9.2, 1.5)
  desenhar_codigo_de_barras(cte$chave, 8.2, topo + 1.6, 8.8, 1.2)
  desenhar_caixa(8.0, topo + 3.0, 9.2, 0.75, titulo = "CHAVE DE ACESSO", conteudo = chave_em_blocos(cte$chave),
                 tamanho_do_conteudo = 8, negrito = TRUE, alinhamento = "centre")
  desenhar_caixa(8.0, topo + 3.75, 9.2, 0.55, conteudo = paste("Consulta em", ENDERECO_DA_CONSULTA_DO_CTE), tamanho_do_conteudo = 8,
                 negrito = TRUE, alinhamento = "centre")
  numero = texto_pelo_caminho(cte$protocolo, "nProt")
  recebimento = texto_pelo_caminho(cte$protocolo, "dhRecbto")
  protocolo = if (is.na(numero)) NA_character_ else paste(numero, data_do_xml(recebimento), hora_do_xml(recebimento))
  desenhar_caixa(8.0, topo + 4.3, 9.2, 0.75, titulo = "PROTOCOLO DE AUTORIZA\u00c7\u00c3O DE USO", conteudo = protocolo,
                 tamanho_do_conteudo = 8, negrito = TRUE, alinhamento = "centre")
  if (!is.na(cte$qrcode)) {
    desenhar_qrcode(cte$qrcode, 17.5, topo + 0.3, 3.0)
  }
  tipo = texto_pelo_caminho(informacao, "ide/tpCTe")
  servico = texto_pelo_caminho(informacao, "ide/tpServ")
  desenhar_caixa(0.4, topo + 3.0, 3.8, 0.75, titulo = "TIPO DO CT-E", tamanho_do_conteudo = 8, negrito = TRUE,
                 conteudo = if (!is.na(tipo) && tipo %in% names(TIPOS_DO_CTE)) TIPOS_DO_CTE[[tipo]] else tipo)
  desenhar_caixa(4.2, topo + 3.0, 3.8, 0.75, titulo = "TIPO DO SERVI\u00c7O", tamanho_do_conteudo = 8, negrito = TRUE,
                 conteudo = if (!is.na(servico) && servico %in% names(TIPOS_DO_SERVICO_DO_CTE)) TIPOS_DO_SERVICO_DO_CTE[[servico]] else servico)
  desenhar_caixa(0.4, topo + 3.75, 7.6, 1.3, titulo = "CFOP - NATUREZA DA OPERA\u00c7\u00c3O", tamanho_do_conteudo = 8,
                 conteudo = quebrar_texto(paste(texto_pelo_caminho(informacao, "ide/CFOP"), "-", texto_pelo_caminho(informacao, "ide/natOp")),
                                          7.4, 8))
  if (identical(texto_pelo_caminho(informacao, "ide/tpAmb"), "2")) {
    desenhar_texto("EMITIDO EM AMBIENTE DE HOMOLOGA\u00c7\u00c3O - SEM VALOR FISCAL", 10.5, topo + 5.15, tamanho = 9, negrito = TRUE,
                   alinhamento = "centre")
  }
}

# A prestação, as pessoas, a carga, os componentes, o imposto, os documentos (os primeiros), as observações e o modal.
desenhar_corpo_do_dacte = function(cte) {
  informacao = cte$informacao
  y = 8.6
  desenhar_caixa(0.4, y, 10.1, 0.75, titulo = "IN\u00cdCIO DA PRESTA\u00c7\u00c3O", tamanho_do_conteudo = 8,
                 conteudo = paste(texto_pelo_caminho(informacao, "ide/xMunIni"), "-", texto_pelo_caminho(informacao, "ide/UFIni")))
  desenhar_caixa(10.5, y, 10.1, 0.75, titulo = "T\u00c9RMINO DA PRESTA\u00c7\u00c3O", tamanho_do_conteudo = 8,
                 conteudo = paste(texto_pelo_caminho(informacao, "ide/xMunFim"), "-", texto_pelo_caminho(informacao, "ide/UFFim")))
  y = y + 0.75
  pessoas = list(list("REMETENTE", "rem", "enderReme"), list("DESTINAT\u00c1RIO", "dest", "enderDest"),
                 list("EXPEDIDOR", "exped", "enderExped"), list("RECEBEDOR", "receb", "enderReceb"))
  presentes = list()
  for (pessoa in pessoas) {
    if (!is.na(texto_pelo_caminho(informacao, paste0(pessoa[[2]], "/xNome")))) {
      presentes[[length(presentes) + 1]] = pessoa
    }
  }
  for (posicao in seq_along(presentes)) {
    pessoa = presentes[[posicao]]
    esquerda = if (posicao %% 2 == 1) 0.4 else 10.5
    desenhar_pessoa_do_dacte(informacao, pessoa[[1]], pessoa[[2]], pessoa[[3]], esquerda, y)
    if (posicao %% 2 == 0 || posicao == length(presentes)) {
      y = y + 1.75
    }
  }
  tomador = pessoa_do_tomador(informacao)
  if (!is.null(tomador)) {
    desenhar_caixa(0.4, y, 20.2, 0.75, titulo = "TOMADOR DO SERVI\u00c7O", tamanho_do_conteudo = 7, conteudo = paste0(
      tomador$nome, "  -  CNPJ/CPF: ", documento_formatado(tomador$documento), "  -  ", tomador$municipio, " - ", tomador$uf))
    y = y + 0.75
  }
  desenhar_caixa(0.4, y, 8.0, 0.75, titulo = "PRODUTO PREDOMINANTE", conteudo = texto_pelo_caminho(informacao, "infCTeNorm/infCarga/proPred"),
                 tamanho_do_conteudo = 8)
  desenhar_caixa(8.4, y, 7.2, 0.75, titulo = "OUTRAS CARACTER\u00cdSTICAS DA CARGA",
                 conteudo = texto_pelo_caminho(informacao, "infCTeNorm/infCarga/xOutCat"), tamanho_do_conteudo = 8)
  desenhar_caixa(15.6, y, 5.0, 0.75, titulo = "VALOR TOTAL DA CARGA", alinhamento = "right", tamanho_do_conteudo = 8,
                 conteudo = numero_brasileiro(as.numeric(texto_pelo_caminho(informacao, "infCTeNorm/infCarga/vCarga"))))
  y = y + 0.75
  medidas = xml2::xml_find_all(informacao, ".//*[local-name()='infCarga']/*[local-name()='infQ']")
  if (length(medidas) > 0) {
    textos = character()
    for (medida in medidas) {
      textos = c(textos, paste0(texto_pelo_caminho(medida, "tpMed"), ": ",
                                numero_brasileiro(as.numeric(texto_pelo_caminho(medida, "qCarga")), 2, 4)))
    }
    desenhar_caixa(0.4, y, 20.2, 0.6, titulo = "QUANTIDADE DA CARGA", conteudo = paste(textos, collapse = "    "),
                   tamanho_do_conteudo = 7)
    y = y + 0.6
  }
  y = desenhar_componentes_do_dacte(informacao, y)
  y = desenhar_imposto_do_dacte(informacao, y)
  primeiros = cte$documentos[seq_len(min(nrow(cte$documentos), DOCUMENTOS_NA_PRIMEIRA_FOLHA_DO_DACTE)), , drop = FALSE]
  y = desenhar_documentos_do_dacte(primeiros, y, "DOCUMENTOS ORIGIN\u00c1RIOS")
  if (nrow(cte$documentos) > DOCUMENTOS_NA_PRIMEIRA_FOLHA_DO_DACTE) {
    desenhar_texto("(CONTINUA NA FOLHA SEGUINTE)", 0.5, y + 0.05, tamanho = 6, negrito = TRUE)
    y = y + 0.3
  }
  observacoes = texto_pelo_caminho(informacao, "compl/xObs")
  linhas_das_observacoes = quebrar_texto(observacoes, 20.0, 7)
  desenhar_caixa(0.4, y, 20.2, max(1.0, 0.45 + 0.3 * length(linhas_das_observacoes)), titulo = "OBSERVA\u00c7\u00d5ES GERAIS",
                 conteudo = linhas_das_observacoes, tamanho_do_conteudo = 7)
  y = y + max(1.0, 0.45 + 0.3 * length(linhas_das_observacoes))
  if (identical(texto_pelo_caminho(informacao, "ide/modal"), "01")) {
    desenhar_caixa(0.4, y, 20.2, 0.75, titulo = "INFORMA\u00c7\u00d5ES ESPEC\u00cdFICAS DO MODAL RODOVI\u00c1RIO - RNTRC DA EMPRESA",
                   conteudo = texto_pelo_caminho(informacao, "infCTeNorm/infModal/rodo/RNTRC"), tamanho_do_conteudo = 8)
    y = y + 0.75
  }
  desenhar_caixa(0.4, y, 13.0, min(2.0, ALTURA_DO_A4 - 0.4 - y), titulo = "USO EXCLUSIVO DO EMISSOR DO CT-E")
  desenhar_caixa(13.4, y, 7.2, min(2.0, ALTURA_DO_A4 - 0.4 - y), titulo = "RESERVADO AO FISCO")
}

desenhar_pessoa_do_dacte = function(informacao, titulo, grupo, endereco, esquerda, y) {
  base = paste0(grupo, "/", endereco, "/")
  linhas = c(
    paste0(titulo, ": ", texto_pelo_caminho(informacao, paste0(grupo, "/xNome"))),
    paste0("ENDERE\u00c7O: ", texto_pelo_caminho(informacao, paste0(base, "xLgr")), ", ", texto_pelo_caminho(informacao, paste0(base, "nro")),
           " - ", texto_pelo_caminho(informacao, paste0(base, "xBairro"))),
    paste0("MUNIC\u00cdPIO: ", texto_pelo_caminho(informacao, paste0(base, "xMun")), " - ", texto_pelo_caminho(informacao, paste0(base, "UF")),
           "   CEP: ", cep_formatado(texto_pelo_caminho(informacao, paste0(base, "CEP")))),
    paste0("CNPJ/CPF: ", documento_formatado(texto_pelo_caminho(informacao, paste0(grupo, "/CNPJ|", grupo, "/CPF"))), "   IE: ",
           ifelse(is.na(texto_pelo_caminho(informacao, paste0(grupo, "/IE"))), "", texto_pelo_caminho(informacao, paste0(grupo, "/IE"))))
  )
  # Cada linha quebrada na largura do quadro; cabem cinco.
  quebradas = character()
  for (linha in linhas) {
    quebradas = c(quebradas, quebrar_texto(linha, 9.9, 7))
  }
  desenhar_caixa(esquerda, y, 10.1, 1.75, conteudo = utils::head(quebradas, 5), tamanho_do_conteudo = 7)
}

# O tomador: o toma4 (outro) ou a pessoa que o toma3 indica (0 remetente, 1 expedidor, 2 recebedor, 3 destinatário).
pessoa_do_tomador = function(informacao) {
  outro = xml2::xml_find_first(informacao, ".//*[local-name()='toma4']")
  if (!inherits(outro, "xml_missing")) {
    return(list(nome = texto_pelo_caminho(outro, "xNome"), documento = texto_pelo_caminho(outro, "CNPJ|CPF"),
                municipio = texto_pelo_caminho(outro, "enderToma/xMun"), uf = texto_pelo_caminho(outro, "enderToma/UF")))
  }
  indicado = texto_pelo_caminho(informacao, "ide/toma3/toma")
  grupos = c("0" = "rem/enderReme", "1" = "exped/enderExped", "2" = "receb/enderReceb", "3" = "dest/enderDest")
  if (is.na(indicado) || !(indicado %in% names(grupos))) {
    return(NULL)
  }
  grupo = sub("/.*$", "", grupos[[indicado]])
  list(nome = texto_pelo_caminho(informacao, paste0(grupo, "/xNome")),
       documento = texto_pelo_caminho(informacao, paste0(grupo, "/CNPJ|", grupo, "/CPF")),
       municipio = texto_pelo_caminho(informacao, paste0(grupos[[indicado]], "/xMun")),
       uf = texto_pelo_caminho(informacao, paste0(grupos[[indicado]], "/UF")))
}

desenhar_componentes_do_dacte = function(informacao, y) {
  componentes = xml2::xml_find_all(informacao, "*[local-name()='vPrest']/*[local-name()='Comp']")
  desenhar_texto("COMPONENTES DO VALOR DA PRESTA\u00c7\u00c3O DE SERVI\u00c7O", 10.5, y + 0.05, tamanho = 6, negrito = TRUE,
                 alinhamento = "centre")
  altura = max(1.2, 0.35 + 0.3 * ceiling(length(componentes) / 3))
  desenhar_caixa(0.4, y + 0.3, 14.6, altura)
  for (posicao in seq_along(componentes)) {
    coluna = (posicao - 1) %% 3
    linha = (posicao - 1) %/% 3
    esquerda = 0.5 + coluna * 4.85
    desenhar_texto(texto_pelo_caminho(componentes[[posicao]], "xNome"), esquerda, y + 0.4 + linha * 0.3, tamanho = 7)
    desenhar_texto(numero_brasileiro(as.numeric(texto_pelo_caminho(componentes[[posicao]], "vComp"))), esquerda + 4.6,
                   y + 0.4 + linha * 0.3, tamanho = 7, alinhamento = "right")
  }
  desenhar_caixa(15.0, y + 0.3, 5.6, altura / 2, titulo = "VALOR TOTAL DA PRESTA\u00c7\u00c3O", alinhamento = "right",
                 conteudo = numero_brasileiro(as.numeric(texto_pelo_caminho(informacao, "vPrest/vTPrest"))), tamanho_do_conteudo = 8,
                 negrito = TRUE)
  desenhar_caixa(15.0, y + 0.3 + altura / 2, 5.6, altura / 2, titulo = "VALOR A RECEBER", alinhamento = "right",
                 conteudo = numero_brasileiro(as.numeric(texto_pelo_caminho(informacao, "vPrest/vRec"))), tamanho_do_conteudo = 8,
                 negrito = TRUE)
  y + 0.3 + altura
}

desenhar_imposto_do_dacte = function(informacao, y) {
  icms = xml2::xml_find_first(informacao, "*[local-name()='imp']/*[local-name()='ICMS']/*")
  desenhar_texto("INFORMA\u00c7\u00d5ES RELATIVAS AO IMPOSTO", 10.5, y + 0.05, tamanho = 6, negrito = TRUE, alinhamento = "centre")
  cst = texto_pelo_caminho(icms, "CST")
  if (is.na(cst) && !inherits(icms, "xml_missing")) {
    cst = xml2::xml_name(icms)
  }
  caixas = list(list(0.4, 7.0, "CLASSIFICA\u00c7\u00c3O TRIBUT\u00c1RIA DO SERVI\u00c7O", cst, "left"),
                list(7.4, 3.3, "BASE DE C\u00c1LCULO", numero_brasileiro(as.numeric(texto_pelo_caminho(icms, "vBC"))), "right"),
                list(10.7, 3.3, "AL\u00cdQ. DO ICMS", numero_brasileiro(as.numeric(texto_pelo_caminho(icms, "pICMS"))), "right"),
                list(14.0, 3.3, "VALOR DO ICMS", numero_brasileiro(as.numeric(texto_pelo_caminho(icms, "vICMS"))), "right"),
                list(17.3, 3.3, "% RED. BC CALC.", numero_brasileiro(as.numeric(texto_pelo_caminho(icms, "pRedBC"))), "right"))
  for (caixa in caixas) {
    desenhar_caixa(caixa[[1]], y + 0.3, caixa[[2]], 0.75, titulo = caixa[[3]], conteudo = caixa[[4]], tamanho_do_conteudo = 8,
                   alinhamento = caixa[[5]])
  }
  y + 1.05
}

# Os documentos originários em duas colunas (tipo, emitente, série e número ou chave); devolve onde o quadro acaba.
desenhar_documentos_do_dacte = function(documentos, y, titulo) {
  desenhar_texto(titulo, 10.5, y + 0.05, tamanho = 6, negrito = TRUE, alinhamento = "centre")
  linhas = max(1, ceiling(nrow(documentos) / 2))
  altura = 0.4 + 0.3 * linhas
  desenhar_caixa(0.4, y + 0.3, 10.1, altura)
  desenhar_caixa(10.5, y + 0.3, 10.1, altura)
  for (esquerda in c(0.4, 10.5)) {
    desenhar_texto("TP DOC", esquerda + 0.1, y + 0.35, tamanho = 5, negrito = TRUE)
    desenhar_texto("CNPJ/CPF EMITENTE", esquerda + 1.8, y + 0.35, tamanho = 5, negrito = TRUE)
    desenhar_texto("S\u00c9RIE/N\u00ba DOCUMENTO (OU CHAVE)", esquerda + 4.4, y + 0.35, tamanho = 5, negrito = TRUE)
  }
  for (posicao in seq_len(nrow(documentos))) {
    esquerda = if (posicao %% 2 == 1) 0.4 else 10.5
    linha = (posicao - 1) %/% 2
    altura_da_linha = y + 0.65 + linha * 0.3
    desenhar_texto(documentos$tipo[posicao], esquerda + 0.1, altura_da_linha, tamanho = 6)
    desenhar_texto(documentos$emitente[posicao], esquerda + 1.8, altura_da_linha, tamanho = 6)
    desenhar_texto(documentos$numero[posicao], esquerda + 4.4, altura_da_linha, tamanho = 5.5)
  }
  y + 0.3 + altura
}
