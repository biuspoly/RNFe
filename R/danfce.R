# O DANFE NFC-e em PDF, numa bobina de 80 mm (o Manual de Padrões Técnicos do DANFE NFC-e e QR Code, versão 6.0): as
# divisões I a IX, com o QR-Code centralizado (a figura 5). A altura da bobina sai do conteúdo: o desenho é montado
# como uma lista de linhas, medida num PDF sem arquivo e desenhada depois no de verdade.

#' @include pdf_comum.R danfe.R
NULL

LARGURA_DA_BOBINA = 8
MARGEM_DA_BOBINA = 0.3
LADO_DO_QRCODE_DA_NFCE = 3

#' DANFE NFC-e em PDF
#'
#' Desenha o DANFE NFC-e (o documento auxiliar da NFC-e) numa bobina de 80 mm,
#' como o Manual de Padrões Técnicos do DANFE NFC-e pede: o emitente, os itens,
#' os totais e as formas de pagamento com o troco, a consulta pela chave (o
#' endereço da `urlChave` e a chave em blocos), o consumidor, o QR-Code (o
#' `qrCode` do XML, de 3 cm), o número, a série, a emissão e o protocolo, a
#' mensagem de homologação ou de contingência, as informações do Fisco e as
#' do contribuinte (com os tributos da Lei 12.741/2012, quando a nota traz).
#'
#' Precisa do pacote `qrcode`.
#'
#' @param xml A NFC-e: o caminho do arquivo ou o texto do XML, com o
#'   `infNFeSupl` (veja [nfce_qrcode()]).
#' @param arquivo O PDF a gravar.
#' @return O caminho do PDF, invisível.
#' @seealso [danfe_pdf()], [nfce_qrcode()]
#' @source Manual de Padrões Técnicos do DANFE NFC-e e QR Code, versão 6.0
#'   (março de 2025), item 3 (as divisões, o papel, as margens e o tamanho do
#'   QR-Code).
#' @examples
#' \donttest{
#' if (requireNamespace("qrcode", quietly = TRUE)) {
#'   nfce = system.file("exemplos", "nfce_ce_contingencia.xml", package = "RNFe")
#'   danfce_pdf(nfce, file.path(tempdir(), "danfce.pdf"))
#' }
#' }
#' @export
danfce_pdf = function(xml, arquivo) {
  exigir_pacotes("qrcode")
  documento = ler_o_xml_para_assinar(xml)
  informacao = xml2::xml_find_first(documento, "//*[local-name()='NFe']/*[local-name()='infNFe']")
  if (inherits(informacao, "xml_missing") || !identical(texto_pelo_caminho(informacao, "ide/mod"), "65")) {
    stop("O XML n\u00e3o traz uma NFC-e (modelo 65); para a NF-e, use danfe_pdf().", call. = FALSE)
  }
  nota = dados_do_danfe(documento, informacao)
  nota$qrcode = texto_pelo_caminho(xml2::xml_find_first(documento, "//*[local-name()='NFe']"), "infNFeSupl/qrCode")
  nota$url_chave = texto_pelo_caminho(xml2::xml_find_first(documento, "//*[local-name()='NFe']"), "infNFeSupl/urlChave")
  if (is.na(nota$qrcode)) {
    stop("A NFC-e n\u00e3o tem o QR-Code (o infNFeSupl): veja nfce_qrcode().", call. = FALSE)
  }
  nota$pagamentos = pagamentos_da_nfce(informacao)
  nota$troco = texto_pelo_caminho(informacao, "pag/vTroco")
  # A medida dos textos precisa de um PDF aberto: um sem arquivo, só para montar as linhas e saber a altura.
  grDevices::pdf(NULL, width = LARGURA_DA_BOBINA / 2.54, height = 10, family = "Times", encoding = "WinAnsi.enc")
  grid::grid.newpage()
  linhas = tryCatch(linhas_do_danfce(nota), finally = grDevices::dev.off())
  altura = sum(vapply(linhas, altura_da_linha_do_danfce, numeric(1))) + 2 * MARGEM_DA_BOBINA
  abrir_o_pdf(arquivo, LARGURA_DA_BOBINA, altura)
  on.exit(grDevices::dev.off(), add = TRUE)
  grid::grid.newpage()
  y = MARGEM_DA_BOBINA
  for (linha in linhas) {
    desenhar_linha_do_danfce(linha, y)
    y = y + altura_da_linha_do_danfce(linha)
  }
  invisible(arquivo)
}

# Cada forma de pagamento com o nome do meio (da tabela dos meios de pagamento) e o valor pago.
pagamentos_da_nfce = function(informacao) {
  meios = tabela_fiscal("meios_pagamento")
  pagamentos = xml2::xml_find_all(informacao, "*[local-name()='pag']/*[local-name()='detPag']")
  linhas = data.frame(meio = character(), valor = character())
  for (pagamento in pagamentos) {
    codigo = texto_pelo_caminho(pagamento, "tPag")
    descricao = meios$descricao[match(codigo, meios$codigo)]
    if (identical(codigo, "99") && !is.na(texto_pelo_caminho(pagamento, "xPag"))) {
      descricao = texto_pelo_caminho(pagamento, "xPag")
    }
    linhas = rbind(linhas, data.frame(meio = if (is.na(descricao)) codigo else descricao,
                                      valor = numero_brasileiro(as.numeric(texto_pelo_caminho(pagamento, "vPag")))))
  }
  linhas
}

# As linhas do DANFE NFC-e, de cima para baixo: cada uma, um texto (com o tamanho, o negrito e o alinhamento), um par
# (texto à esquerda e à direita), um traço ou o QR-Code.
linhas_do_danfce = function(nota) {
  largura = LARGURA_DA_BOBINA - 2 * MARGEM_DA_BOBINA
  linhas = list()
  # Divisão I: o emitente.
  linhas = c(linhas, textos_da_bobina(paste("CNPJ:", documento_formatado(nota$emitente_documento)), 7, TRUE, "centre"))
  linhas = c(linhas, textos_da_bobina(toupper(nota$emitente_nome), 8, TRUE, "centre"))
  endereco = paste0(nota$emitente_logradouro, ", ", nota$emitente_numero,
                    ifelse(is.na(nota$emitente_complemento), "", paste0(" - ", nota$emitente_complemento)), ", ",
                    nota$emitente_bairro, ", ", nota$emitente_municipio, " - ", nota$emitente_uf)
  linhas = c(linhas, textos_da_bobina(endereco, 7, FALSE, "centre"))
  linhas = c(linhas, textos_da_bobina("Documento Auxiliar da Nota Fiscal de Consumidor Eletr\u00f4nica", 7, FALSE, "centre"))
  contingencia = identical(nota$tipo_emissao, "9") && is.na(nota$protocolo)
  if (contingencia) {
    linhas = c(linhas, list(list(tipo = "traco")), textos_da_bobina("EMITIDA EM CONTING\u00caNCIA", 8, TRUE, "centre"),
               textos_da_bobina("Pendente de autoriza\u00e7\u00e3o", 8, TRUE, "centre"))
  }
  # Divisão II: os itens.
  linhas = c(linhas, list(list(tipo = "traco")),
             list(list(tipo = "par", esquerda = "C\u00d3DIGO  DESCRI\u00c7\u00c3O", direita = "QTDE UN x VL UNIT = VL TOTAL",
                       tamanho = 6, negrito = TRUE)))
  for (posicao in seq_len(nrow(nota$itens))) {
    item = nota$itens[posicao, ]
    linhas = c(linhas, textos_da_bobina(paste(item$codigo, item$descricao), 7, FALSE, "left"))
    linhas = c(linhas, list(list(tipo = "par", esquerda = "",
                                 direita = paste0(item$quantidade, " ", item$unidade, " x ", item$valor_unitario, " = ",
                                                  item$valor_total), tamanho = 7, negrito = FALSE)))
  }
  # Divisão III: os totais e os pagamentos.
  acrescimos = sum(as.numeric(c(nota$valor_frete, nota$valor_seguro, nota$valor_outros)), na.rm = TRUE)
  desconto = as.numeric(nota$valor_desconto)
  linhas = c(linhas, list(list(tipo = "traco")),
             list(par_da_bobina("Qtde. total de itens", as.character(nrow(nota$itens)))),
             list(par_da_bobina("Valor total R$", numero_brasileiro(as.numeric(nota$valor_produtos)))))
  if (acrescimos > 0) {
    linhas = c(linhas, list(par_da_bobina("Acr\u00e9scimos (frete, seguro e outras despesas) R$", numero_brasileiro(acrescimos))))
  }
  if (!is.na(desconto) && desconto > 0) {
    linhas = c(linhas, list(par_da_bobina("Desconto R$", numero_brasileiro(desconto))))
  }
  if (acrescimos > 0 || (!is.na(desconto) && desconto > 0)) {
    linhas = c(linhas, list(par_da_bobina("Valor a pagar R$", numero_brasileiro(as.numeric(nota$valor_nota)), negrito = TRUE)))
  }
  linhas = c(linhas, list(par_da_bobina("FORMA DE PAGAMENTO", "VALOR PAGO R$", negrito = TRUE)))
  for (posicao in seq_len(nrow(nota$pagamentos))) {
    linhas = c(linhas, list(par_da_bobina(nota$pagamentos$meio[posicao], nota$pagamentos$valor[posicao])))
  }
  if (!is.na(nota$troco)) {
    linhas = c(linhas, list(par_da_bobina("Troco R$", numero_brasileiro(as.numeric(nota$troco)))))
  }
  # Divisão IV: a consulta pela chave.
  linhas = c(linhas, list(list(tipo = "traco")), textos_da_bobina("Consulte pela Chave de Acesso em", 7, TRUE, "centre"),
             textos_da_bobina(nota$url_chave, 7, FALSE, "centre"), textos_da_bobina(chave_em_blocos(nota$chave), 7, FALSE, "centre"))
  # Divisões V, VI e VII: o consumidor, o QR-Code centralizado, a identificação e o protocolo.
  linhas = c(linhas, list(list(tipo = "traco")), textos_da_bobina(texto_do_consumidor(nota), 7, TRUE, "centre"))
  if (!is.na(nota$destinatario_nome)) {
    linhas = c(linhas, textos_da_bobina(nota$destinatario_nome, 7, FALSE, "centre"))
  }
  linhas = c(linhas, list(list(tipo = "qrcode", texto = nota$qrcode)))
  identificacao = paste0("NFC-e n\u00ba ", nota$numero, " S\u00e9rie ", nota$serie, " ", data_do_xml(nota$emissao), " ",
                         hora_do_xml(nota$emissao))
  linhas = c(linhas, textos_da_bobina(identificacao, 7, TRUE, "centre"))
  if (contingencia) {
    linhas = c(linhas, textos_da_bobina("EMITIDA EM CONTING\u00caNCIA", 8, TRUE, "centre"),
               textos_da_bobina("Pendente de autoriza\u00e7\u00e3o", 8, TRUE, "centre"))
  } else if (!is.na(nota$protocolo)) {
    linhas = c(linhas, textos_da_bobina(paste("Protocolo de autoriza\u00e7\u00e3o:", nota$protocolo), 7, FALSE, "centre"),
               textos_da_bobina(paste("Data de autoriza\u00e7\u00e3o:", data_do_xml(nota$autorizacao), hora_do_xml(nota$autorizacao)),
                                7, FALSE, "centre"))
  }
  # Divisão VIII: a mensagem fiscal; divisão IX: a do contribuinte.
  if (identical(nota$ambiente, "2")) {
    linhas = c(linhas, list(list(tipo = "traco")),
               textos_da_bobina("EMITIDA EM AMBIENTE DE HOMOLOGA\u00c7\u00c3O - SEM VALOR FISCAL", 7, TRUE, "centre"))
  }
  if (!is.na(nota$informacoes_fisco)) {
    linhas = c(linhas, textos_da_bobina(nota$informacoes_fisco, 7, FALSE, "centre"))
  }
  if (!is.na(nota$informacoes_complementares) || !is.na(nota$valor_tributos)) {
    linhas = c(linhas, list(list(tipo = "traco")))
  }
  if (!is.na(nota$valor_tributos)) {
    linhas = c(linhas, textos_da_bobina(paste0("Tributos totais incidentes (Lei Federal 12.741/2012): R$ ",
                                               numero_brasileiro(as.numeric(nota$valor_tributos))), 7, FALSE, "centre"))
  }
  if (!is.na(nota$informacoes_complementares)) {
    linhas = c(linhas, textos_da_bobina(nota$informacoes_complementares, 7, FALSE, "centre"))
  }
  linhas
}

# O texto quebrado na largura da bobina, uma linha da lista para cada linha do texto.
textos_da_bobina = function(texto, tamanho, negrito, alinhamento) {
  linhas = list()
  for (pedaco in quebrar_texto(texto, LARGURA_DA_BOBINA - 2 * MARGEM_DA_BOBINA, tamanho, negrito)) {
    linhas[[length(linhas) + 1]] = list(tipo = "texto", texto = pedaco, tamanho = tamanho, negrito = negrito,
                                        alinhamento = alinhamento)
  }
  linhas
}

par_da_bobina = function(esquerda, direita, negrito = FALSE) {
  list(tipo = "par", esquerda = esquerda, direita = direita, tamanho = 7, negrito = negrito)
}

# "CONSUMIDOR CNPJ:", "CPF:" ou "Id. Estrangeiro:" com o documento, ou "CONSUMIDOR NÃO IDENTIFICADO".
texto_do_consumidor = function(nota) {
  documento = nota$destinatario_documento
  if (is.na(documento)) {
    return("CONSUMIDOR N\u00c3O IDENTIFICADO")
  }
  if (grepl("^[0-9A-Z]{12}[0-9]{2}$", documento)) {
    return(paste("CONSUMIDOR CNPJ:", documento_formatado(documento)))
  }
  if (grepl("^[0-9]{11}$", documento)) {
    return(paste("CONSUMIDOR CPF:", documento_formatado(documento)))
  }
  paste("CONSUMIDOR Id. Estrangeiro:", documento)
}

altura_da_linha_do_danfce = function(linha) {
  if (linha$tipo == "traco") {
    return(0.2)
  }
  if (linha$tipo == "qrcode") {
    return(LADO_DO_QRCODE_DA_NFCE + 0.2)
  }
  linha$tamanho * 0.0353 * 1.3
}

desenhar_linha_do_danfce = function(linha, y) {
  esquerda = MARGEM_DA_BOBINA
  direita = LARGURA_DA_BOBINA - MARGEM_DA_BOBINA
  if (linha$tipo == "traco") {
    desenhar_linha(esquerda, y + 0.1, direita, y + 0.1, tracejada = TRUE)
  } else if (linha$tipo == "qrcode") {
    # O QR-Code de 3 cm, com a margem segura de 10% dentro dele (o manual pede no mínimo 25 mm, com 3 mm de margem).
    lado_do_conteudo = LADO_DO_QRCODE_DA_NFCE * 0.8
    desenhar_qrcode(linha$texto, (LARGURA_DA_BOBINA - lado_do_conteudo) / 2, y + 0.1 + LADO_DO_QRCODE_DA_NFCE * 0.1,
                    lado_do_conteudo)
  } else if (linha$tipo == "par") {
    desenhar_texto(linha$esquerda, esquerda, y, tamanho = linha$tamanho, negrito = linha$negrito)
    desenhar_texto(linha$direita, direita, y, tamanho = linha$tamanho, negrito = linha$negrito, alinhamento = "right")
  } else {
    x = switch(linha$alinhamento, left = esquerda, right = direita, centre = LARGURA_DA_BOBINA / 2)
    desenhar_texto(linha$texto, x, y, tamanho = linha$tamanho, negrito = linha$negrito, alinhamento = linha$alinhamento)
  }
}
