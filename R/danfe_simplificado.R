# O DANFE Simplificado e o DANFE Simplificado - Etiqueta em PDF, pelos itens 3.11 e 3.12 do Manual do DANFE (MOC 7.0,
# Anexo II). O manual não traz leiaute: diz o papel (largura mínima de 55 mm), onde vai a chave (no alto, à direita, em
# qualquer sentido), as fontes (no mínimo 6 pontos, os títulos em negrito e caixa alta) e os campos mínimos. O desenho é
# o do pacote: 10 cm de largura (a do papel de etiqueta mais comum), para o código de barras da chave com o CNPJ
# alfanumérico caber com o módulo mínimo de 0,02 cm, e a altura que o conteúdo pedir.

#' @include pdf_comum.R danfe.R
NULL

LARGURA_DO_DANFE_SIMPLIFICADO = 10
MARGEM_DO_DANFE_SIMPLIFICADO = 0.3
ALTURA_DO_CODIGO_DO_SIMPLIFICADO = 1.0

#' DANFE Simplificado e DANFE Simplificado - Etiqueta em PDF
#'
#' Desenha o DANFE Simplificado da NF-e (com os itens) ou, com
#' `etiqueta = TRUE`, o DANFE Simplificado - Etiqueta (sem os itens, para a
#' venda a varejo pela internet ou por telefone), com os campos mínimos do
#' Manual do DANFE: a chave e o código de barras no alto, o protocolo de
#' autorização (ou, na etiqueta emitida em contingência EPEC, o protocolo do
#' evento EPEC), o emitente (nome, UF, CNPJ e inscrição estadual), o tipo de
#' operação, a série, o número e a emissão, o destinatário (nome, UF, CNPJ ou
#' CPF e a inscrição estadual, quando há), os itens (descrição, unidade,
#' quantidade, valor unitário e total) e o valor total da nota. A de
#' homologação leva "SEM VALOR FISCAL".
#'
#' O manual não traz um leiaute: o desenho é o do pacote, em papel de 10 cm de
#' largura, com a altura que o conteúdo pedir.
#'
#' @param xml A NF-e: o caminho do arquivo ou o texto do XML (o `nfeProc`, com
#'   o protocolo).
#' @param arquivo O PDF a gravar.
#' @param etiqueta `TRUE` para o DANFE Simplificado - Etiqueta (sem os itens).
#' @param protocolo_epec Na etiqueta da nota emitida em contingência EPEC, o
#'   protocolo do evento EPEC (o `nProt` do retorno do evento).
#' @return O caminho do PDF, invisível.
#' @seealso [danfe_pdf()], [danfce_pdf()]
#' @source Manual de Orientação do Contribuinte 7.0, Anexo II: Manual de
#'   Especificações Técnicas do DANFE e Código de Barras, itens 2 (o
#'   código de barras e o módulo mínimo), 3.11 (o DANFE Simplificado) e 3.12 (o
#'   DANFE Simplificado - Etiqueta, da NT 2020.004).
#' @examples
#' nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")
#' danfe_simplificado_pdf(nota, file.path(tempdir(), "danfe_simplificado.pdf"))
#' danfe_simplificado_pdf(nota, file.path(tempdir(), "etiqueta.pdf"), etiqueta = TRUE)
#' @export
danfe_simplificado_pdf = function(xml, arquivo, etiqueta = FALSE, protocolo_epec = NULL) {
  documento = ler_o_xml_para_assinar(xml)
  informacao = xml2::xml_find_first(documento, "//*[local-name()='NFe']/*[local-name()='infNFe']")
  if (inherits(informacao, "xml_missing")) {
    stop("O XML n\u00e3o traz uma NF-e (o elemento NFe com o infNFe).", call. = FALSE)
  }
  if (identical(texto_pelo_caminho(informacao, "ide/mod"), "65")) {
    stop("A NFC-e (modelo 65) tem o DANFE NFC-e: use danfce_pdf().", call. = FALSE)
  }
  if (!isTRUE(etiqueta) && !isFALSE(etiqueta)) {
    stop("O etiqueta \u00e9 TRUE ou FALSE.", call. = FALSE)
  }
  # O item 3.11 não admite o EPEC no DANFE Simplificado; só a Etiqueta (3.12, f) traz o protocolo dele.
  if (!is.null(protocolo_epec) && !etiqueta) {
    stop("O protocolo do EPEC s\u00f3 vai no DANFE Simplificado - Etiqueta (etiqueta = TRUE).", call. = FALSE)
  }
  nota = dados_do_danfe(documento, informacao)
  # A medida dos textos precisa de um PDF aberto: um sem arquivo, só para montar as linhas e saber a altura.
  grDevices::pdf(NULL, width = LARGURA_DO_DANFE_SIMPLIFICADO / 2.54, height = 10, family = "Times", encoding = "WinAnsi.enc")
  grid::grid.newpage()
  linhas = tryCatch(linhas_do_danfe_simplificado(nota, etiqueta, protocolo_epec), finally = grDevices::dev.off())
  inicio_das_linhas = MARGEM_DO_DANFE_SIMPLIFICADO + ALTURA_DO_CODIGO_DO_SIMPLIFICADO + 0.15
  altura = inicio_das_linhas + sum(vapply(linhas, altura_da_linha_do_simplificado, numeric(1))) + MARGEM_DO_DANFE_SIMPLIFICADO
  abrir_o_pdf(arquivo, LARGURA_DO_DANFE_SIMPLIFICADO, altura)
  on.exit(grDevices::dev.off(), add = TRUE)
  grid::grid.newpage()
  desenhar_codigo_de_barras(nota$chave, MARGEM_DO_DANFE_SIMPLIFICADO, MARGEM_DO_DANFE_SIMPLIFICADO,
                            LARGURA_DO_DANFE_SIMPLIFICADO - 2 * MARGEM_DO_DANFE_SIMPLIFICADO, ALTURA_DO_CODIGO_DO_SIMPLIFICADO)
  y = inicio_das_linhas
  for (linha in linhas) {
    desenhar_linha_do_simplificado(linha, y)
    y = y + altura_da_linha_do_simplificado(linha)
  }
  invisible(arquivo)
}

# As linhas do DANFE Simplificado, de cima para baixo: cada uma, um texto (com o tamanho, o negrito e o alinhamento), um
# par (texto à esquerda e à direita) ou um traço.
linhas_do_danfe_simplificado = function(nota, etiqueta, protocolo_epec) {
  linhas = c(textos_do_simplificado("CHAVE DE ACESSO", 6, TRUE, "centre"),
             textos_do_simplificado(chave_em_blocos(nota$chave), 8, TRUE, "centre"),
             textos_do_simplificado(if (etiqueta) "DANFE SIMPLIFICADO - ETIQUETA" else "DANFE SIMPLIFICADO", 9, TRUE, "centre"))
  if (!is.na(nota$protocolo)) {
    linhas = c(linhas, textos_do_simplificado("PROTOCOLO DE AUTORIZA\u00c7\u00c3O DE USO", 6, TRUE, "centre"),
               textos_do_simplificado(paste(nota$protocolo, "-", data_do_xml(nota$autorizacao), hora_do_xml(nota$autorizacao)),
                                      8, FALSE, "centre"))
  } else if (!is.null(protocolo_epec)) {
    linhas = c(linhas, textos_do_simplificado("PROTOCOLO DO EVENTO EPEC", 6, TRUE, "centre"),
               textos_do_simplificado(protocolo_epec, 8, FALSE, "centre"))
  } else {
    linhas = c(linhas, textos_do_simplificado("SEM O PROTOCOLO DE AUTORIZA\u00c7\u00c3O DE USO", 7, TRUE, "centre"))
  }
  linhas = c(linhas, list(list(tipo = "traco")), textos_do_simplificado("EMITENTE", 6, TRUE, "left"),
             textos_do_simplificado(toupper(nota$emitente_nome), 8, TRUE, "left"),
             textos_do_simplificado(paste0("CNPJ/CPF: ", documento_formatado(nota$emitente_documento), "   IE: ",
                                           ifelse(is.na(nota$emitente_ie), "", nota$emitente_ie), "   UF: ", nota$emitente_uf),
                                    7, FALSE, "left"))
  operacao = if (identical(nota$tipo_operacao, "0")) "0 - ENTRADA" else "1 - SA\u00cdDA"
  linhas = c(linhas, list(list(tipo = "traco")),
             list(par_do_simplificado("TIPO DE OPERA\u00c7\u00c3O", "S\u00c9RIE / N\u00daMERO / EMISS\u00c3O", TRUE)),
             list(par_do_simplificado(operacao, paste(nota$serie, "/", numero_da_nota_formatado(nota$numero), "/",
                                                       data_do_xml(nota$emissao)), FALSE)))
  linhas = c(linhas, list(list(tipo = "traco")), textos_do_simplificado("DESTINAT\u00c1RIO / REMETENTE", 6, TRUE, "left"),
             textos_do_simplificado(if (is.na(nota$destinatario_nome)) "-" else toupper(nota$destinatario_nome), 8, TRUE, "left"))
  documento = paste0("CNPJ/CPF: ", if (is.na(nota$destinatario_documento)) "-" else documento_formatado(nota$destinatario_documento),
                     if (is.na(nota$destinatario_ie)) "" else paste0("   IE: ", nota$destinatario_ie),
                     "   UF: ", if (is.na(nota$destinatario_uf)) "-" else nota$destinatario_uf)
  linhas = c(linhas, textos_do_simplificado(documento, 7, FALSE, "left"))
  if (!etiqueta) {
    linhas = c(linhas, list(list(tipo = "traco")),
               list(par_do_simplificado("DESCRI\u00c7\u00c3O", "QTDE UN x VL UNIT = VL TOTAL", TRUE)))
    for (posicao in seq_len(nrow(nota$itens))) {
      item = nota$itens[posicao, ]
      linhas = c(linhas, textos_do_simplificado(item$descricao, 7, FALSE, "left"),
                 list(par_do_simplificado("", paste0(item$quantidade, " ", item$unidade, " x ", item$valor_unitario, " = ",
                                                     item$valor_total), FALSE)))
    }
  }
  linhas = c(linhas, list(list(tipo = "traco")),
             list(par_do_simplificado("VALOR TOTAL DA NOTA R$", numero_brasileiro(as.numeric(nota$valor_nota)), TRUE)))
  if (identical(nota$ambiente, "2")) {
    linhas = c(linhas, list(list(tipo = "traco")),
               textos_do_simplificado("EMITIDA EM AMBIENTE DE HOMOLOGA\u00c7\u00c3O - SEM VALOR FISCAL", 7, TRUE, "centre"))
  }
  linhas
}

# O texto quebrado na largura do papel, uma linha da lista para cada linha do texto.
textos_do_simplificado = function(texto, tamanho, negrito, alinhamento) {
  linhas = list()
  largura = LARGURA_DO_DANFE_SIMPLIFICADO - 2 * MARGEM_DO_DANFE_SIMPLIFICADO
  for (pedaco in quebrar_texto(texto, largura, tamanho, negrito)) {
    linhas[[length(linhas) + 1]] = list(tipo = "texto", texto = pedaco, tamanho = tamanho, negrito = negrito,
                                        alinhamento = alinhamento)
  }
  linhas
}

par_do_simplificado = function(esquerda, direita, negrito) {
  list(tipo = "par", esquerda = esquerda, direita = direita, tamanho = if (negrito) 6 else 7, negrito = negrito)
}

altura_da_linha_do_simplificado = function(linha) {
  if (linha$tipo == "traco") {
    return(0.2)
  }
  linha$tamanho * 0.0353 * 1.3
}

desenhar_linha_do_simplificado = function(linha, y) {
  esquerda = MARGEM_DO_DANFE_SIMPLIFICADO
  direita = LARGURA_DO_DANFE_SIMPLIFICADO - MARGEM_DO_DANFE_SIMPLIFICADO
  if (linha$tipo == "traco") {
    desenhar_linha(esquerda, y + 0.1, direita, y + 0.1, tracejada = TRUE)
  } else if (linha$tipo == "par") {
    desenhar_texto(linha$esquerda, esquerda, y, tamanho = linha$tamanho, negrito = linha$negrito)
    desenhar_texto(linha$direita, direita, y, tamanho = linha$tamanho, negrito = linha$negrito, alinhamento = "right")
  } else {
    x = switch(linha$alinhamento, left = esquerda, right = direita, centre = LARGURA_DO_DANFE_SIMPLIFICADO / 2)
    desenhar_texto(linha$texto, x, y, tamanho = linha$tamanho, negrito = linha$negrito, alinhamento = linha$alinhamento)
  }
}
