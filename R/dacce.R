# A carta de correção em PDF (A4, retrato): o documento corrigido (a chave, com o código de barras), o evento e o
# registro na SEFAZ, a correção e as condições de uso. Não há modelo oficial de documento auxiliar da CC-e (nem no MOC
# da NF-e, nem no do CT-e): o desenho é o do pacote, com os quadros e as fontes do DANFE.

#' @include pdf_comum.R danfe.R
NULL

TIPO_DA_CARTA_DE_CORRECAO = "110110"

#' Carta de correção em PDF
#'
#' Desenha a carta de correção eletrônica (o evento 110110 da NF-e ou do
#' CT-e) em A4: o documento corrigido (a chave, com o código de barras, e o
#' emitente), o evento (a sequência e a data), o registro na SEFAZ (o
#' protocolo, a data e a situação), a correção e as condições de uso. Na
#' carta de correção do CT-e, a correção sai em tabela (o grupo, o campo, o
#' valor e o item alterados). A de homologação leva "SEM VALOR FISCAL".
#'
#' Não há modelo oficial do documento auxiliar da carta de correção: o
#' desenho é o do pacote.
#'
#' @param xml A carta de correção: o caminho do arquivo ou o texto do XML (o
#'   `procEventoNFe` ou o `procEventoCTe`, com o retorno da SEFAZ; sem o
#'   retorno, o quadro do registro sai com traços).
#' @param arquivo O PDF a gravar.
#' @return O caminho do PDF, invisível.
#' @seealso [sefaz_carta_correcao()], [eventos_ler()]
#' @source Os schemas da carta de correção: `e110110_v1.00.xsd` da NF-e (o
#'   `xCorrecao` e a condição de uso) e o `evCCeCTe` do CT-e (as
#'   `infCorrecao`).
#' @examples
#' carta = system.file("exemplos", "evento_nfe_carta_correcao.xml", package = "RNFe")
#' dacce_pdf(carta, file.path(tempdir(), "carta_de_correcao.pdf"))
#' @export
dacce_pdf = function(xml, arquivo) {
  documento = ler_o_xml_para_assinar(xml)
  pedido = xml2::xml_find_first(documento, "//*[local-name()='evento' or local-name()='eventoCTe']/*[local-name()='infEvento']")
  if (inherits(pedido, "xml_missing") || !identical(texto_pelo_caminho(pedido, "tpEvento"), TIPO_DA_CARTA_DE_CORRECAO)) {
    stop("O XML n\u00e3o traz uma carta de corre\u00e7\u00e3o (o evento 110110 da NF-e ou do CT-e).", call. = FALSE)
  }
  retorno = xml2::xml_find_first(documento, "//*[local-name()='retEvento' or local-name()='retEventoCTe']/*[local-name()='infEvento']")
  chave = texto_pelo_caminho(pedido, "chNFe|chCTe")
  abrir_o_pdf(arquivo, LARGURA_DO_A4, ALTURA_DO_A4)
  on.exit(grDevices::dev.off(), add = TRUE)
  grid::grid.newpage()
  if (identical(texto_pelo_caminho(pedido, "tpAmb"), "2")) {
    desenhar_marca_de_homologacao()
  }
  desenhar_cabecalho_da_carta(pedido, chave)
  desenhar_registro_da_carta(pedido, retorno)
  y = desenhar_correcao_da_carta(pedido)
  desenhar_condicoes_de_uso_da_carta(pedido, y)
  invisible(arquivo)
}

desenhar_cabecalho_da_carta = function(pedido, chave) {
  modelo = substr(chave, 21, 22)
  documento = if (modelo %in% c("57", "67")) "CT-e" else "NF-e"
  desenhar_caixa(1.0, 1.0, 19.0, 1.4, NULL, NULL)
  desenhar_texto("CARTA DE CORRE\u00c7\u00c3O ELETR\u00d4NICA", 10.5, 1.2, tamanho = 14, negrito = TRUE, alinhamento = "centre")
  artigo = if (documento == "CT-e") "do" else "da"
  desenhar_texto(paste("Corre\u00e7\u00e3o", artigo, documento, "pelo evento 110110"), 10.5, 1.85, tamanho = 8, alinhamento = "centre")
  desenhar_caixa(1.0, 2.6, 19.0, 2.4, NULL, NULL)
  desenhar_codigo_de_barras(chave, 2.0, 2.8, 17.0, 1.2)
  desenhar_texto("CHAVE DE ACESSO", 10.5, 4.15, tamanho = 6, negrito = TRUE, alinhamento = "centre")
  desenhar_texto(chave_em_blocos(chave), 10.5, 4.45, tamanho = 10, negrito = TRUE, alinhamento = "centre")
  desenhar_caixa(1.0, 5.2, 4.0, 0.8, "DOCUMENTO", documento)
  desenhar_caixa(5.0, 5.2, 3.0, 0.8, "S\u00c9RIE", sub("^0+(?=.)", "", substr(chave, 23, 25), perl = TRUE))
  desenhar_caixa(8.0, 5.2, 4.0, 0.8, "N\u00daMERO", numero_da_nota_formatado(substr(chave, 26, 34)))
  desenhar_caixa(12.0, 5.2, 8.0, 0.8, "CNPJ / CPF DO EMITENTE", documento_formatado(texto_pelo_caminho(pedido, "CNPJ|CPF")))
}

desenhar_registro_da_carta = function(pedido, retorno) {
  sem_retorno = inherits(retorno, "xml_missing")
  protocolo = if (sem_retorno) NA else texto_pelo_caminho(retorno, "nProt")
  registro = if (sem_retorno) NA else texto_pelo_caminho(retorno, "dhRegEvento")
  situacao = if (sem_retorno) NA else paste(texto_pelo_caminho(retorno, "cStat"), "-", texto_pelo_caminho(retorno, "xMotivo"))
  destinatario = if (sem_retorno) NA else texto_pelo_caminho(retorno, "CNPJDest|CPFDest")
  evento = texto_pelo_caminho(pedido, "dhEvento")
  ambiente = if (identical(texto_pelo_caminho(pedido, "tpAmb"), "1")) "Produ\u00e7\u00e3o" else "Homologa\u00e7\u00e3o"
  desenhar_texto("EVENTO E REGISTRO NA SEFAZ", 1.0, 6.25, tamanho = 7, negrito = TRUE)
  desenhar_caixa(1.0, 6.6, 3.0, 0.8, "SEQU\u00caNCIA", texto_pelo_caminho(pedido, "nSeqEvento"))
  desenhar_caixa(4.0, 6.6, 5.0, 0.8, "DATA E HORA DO EVENTO", paste(data_do_xml(evento), hora_do_xml(evento)))
  desenhar_caixa(9.0, 6.6, 4.0, 0.8, "AMBIENTE", ambiente)
  desenhar_caixa(13.0, 6.6, 7.0, 0.8, "CNPJ / CPF DO DESTINAT\u00c1RIO", if (is.na(destinatario)) "-" else documento_formatado(destinatario))
  desenhar_caixa(1.0, 7.4, 5.0, 0.8, "PROTOCOLO", if (is.na(protocolo)) "-" else protocolo)
  desenhar_caixa(6.0, 7.4, 5.0, 0.8, "DATA E HORA DO REGISTRO", if (is.na(registro)) "-" else paste(data_do_xml(registro), hora_do_xml(registro)))
  desenhar_caixa(11.0, 7.4, 9.0, 0.8, "SITUA\u00c7\u00c3O", if (is.na(situacao)) "Sem o retorno da SEFAZ" else situacao)
}

# A correção: o texto da NF-e (xCorrecao) ou a tabela do CT-e (infCorrecao). Devolve onde o quadro termina.
desenhar_correcao_da_carta = function(pedido) {
  desenhar_texto("CORRE\u00c7\u00c3O", 1.0, 8.45, tamanho = 7, negrito = TRUE)
  texto = texto_pelo_caminho(pedido, "detEvento/*/xCorrecao|detEvento/xCorrecao")
  if (!is.na(texto)) {
    linhas = quebrar_texto(texto, 18.6, 9, separadores = "\r?\n")
    altura = 0.3 + length(linhas) * 0.42
    desenhar_caixa(1.0, 8.8, 19.0, altura, NULL, NULL)
    for (posicao in seq_along(linhas)) {
      desenhar_texto(linhas[posicao], 1.2, 9.0 + (posicao - 1) * 0.42, tamanho = 9)
    }
    return(8.8 + altura)
  }
  correcoes = xml2::xml_find_all(pedido, ".//*[local-name()='infCorrecao']")
  colunas = c(1.0, 5.5, 10.0, 17.0)
  larguras = c(4.5, 4.5, 7.0, 3.0)
  titulos = c("GRUPO ALTERADO", "CAMPO ALTERADO", "VALOR ALTERADO", "ITEM")
  y = 8.8
  for (posicao in seq_along(colunas)) {
    desenhar_caixa(colunas[posicao], y, larguras[posicao], 0.5, NULL, titulos[posicao], tamanho_do_conteudo = 6, negrito = TRUE)
  }
  y = y + 0.5
  for (correcao in correcoes) {
    valores = c(texto_pelo_caminho(correcao, "grupoAlterado"), texto_pelo_caminho(correcao, "campoAlterado"),
                texto_pelo_caminho(correcao, "valorAlterado"), texto_pelo_caminho(correcao, "nroItemAlterado"))
    linhas_do_valor = quebrar_texto(valores[3], larguras[3] - 0.2, 8, separadores = "\r?\n")
    altura = max(0.5, 0.25 + length(linhas_do_valor) * 0.36)
    for (posicao in seq_along(colunas)) {
      desenhar_caixa(colunas[posicao], y, larguras[posicao], altura, NULL, NULL)
    }
    desenhar_texto(valores[1], 1.1, y + 0.12, tamanho = 8)
    desenhar_texto(valores[2], 5.6, y + 0.12, tamanho = 8)
    for (linha in seq_along(linhas_do_valor)) {
      desenhar_texto(linhas_do_valor[linha], 10.1, y + 0.12 + (linha - 1) * 0.36, tamanho = 8)
    }
    desenhar_texto(valores[4], 17.1, y + 0.12, tamanho = 8)
    y = y + altura
  }
  y
}

desenhar_condicoes_de_uso_da_carta = function(pedido, y) {
  texto = texto_pelo_caminho(pedido, "detEvento/*/xCondUso|detEvento/xCondUso")
  desenhar_texto("CONDI\u00c7\u00d5ES DE USO", 1.0, y + 0.35, tamanho = 7, negrito = TRUE)
  linhas = quebrar_texto(if (is.na(texto)) "-" else texto, 18.6, 7, separadores = "\r?\n")
  altura = 0.3 + length(linhas) * 0.32
  desenhar_caixa(1.0, y + 0.7, 19.0, altura, NULL, NULL)
  for (posicao in seq_along(linhas)) {
    desenhar_texto(linhas[posicao], 1.2, y + 0.85 + (posicao - 1) * 0.32, tamanho = 7)
  }
}
