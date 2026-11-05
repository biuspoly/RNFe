# O DANFE da NF-e em PDF: A4 em retrato, folhas soltas (o modelo do Anexo III.02 do Manual do DANFE, MOC 7.0, Anexo
# II), com as posições e os tamanhos do item 3.8.1, a fonte Times, o código de barras CODE-128C da chave e as folhas
# adicionais quando os itens ou as informações complementares não cabem.

#' @include pdf_comum.R
NULL

LARGURA_DO_A4 = 21
ALTURA_DO_A4 = 29.7
# As colunas do quadro dos produtos, na ordem do manual (as que não podem ser suprimidas e as do ICMS e do IPI), com a
# largura em centímetros (somam os 20,57 do quadro) e o alinhamento.
COLUNAS_DOS_PRODUTOS_DO_DANFE = utils::read.table(header = TRUE, sep = ";", strip.white = TRUE, stringsAsFactors = FALSE, text = "
coluna          ; titulo              ; largura ; alinhamento
codigo          ; C\u00d3DIGO              ; 1.60    ; left
descricao       ; DESCRI\u00c7\u00c3O DO PRODUTO/SERVI\u00c7O ; 5.27    ; left
ncm             ; NCM/SH              ; 1.20    ; centre
cst             ; O/CST               ; 0.75    ; centre
cfop            ; CFOP                ; 0.80    ; centre
unidade         ; UN                  ; 0.80    ; centre
quantidade      ; QUANT.              ; 1.30    ; right
valor_unitario  ; VALOR UNIT.         ; 1.50    ; right
valor_total     ; VALOR TOTAL         ; 1.50    ; right
base_icms       ; B.C\u00c1LC. ICMS        ; 1.40    ; right
valor_icms      ; VALOR ICMS          ; 1.30    ; right
valor_ipi       ; VALOR IPI           ; 1.15    ; right
aliquota_icms   ; AL\u00cdQ. ICMS          ; 1.00    ; right
aliquota_ipi    ; AL\u00cdQ. IPI           ; 1.00    ; right
")
TAMANHO_DOS_PRODUTOS = 6
ALTURA_DA_LINHA_DOS_PRODUTOS = 0.27

#' DANFE da NF-e em PDF
#'
#' Desenha o DANFE (o Documento Auxiliar da NF-e) de cada nota, em A4 retrato,
#' como o Manual de Especificações Técnicas do DANFE (MOC 7.0, Anexo II) pede:
#' o canhoto, o emitente, o quadro do DANFE com a entrada ou saída, o número, a
#' série e as folhas, o código de barras CODE-128C e a chave de acesso, o
#' protocolo de autorização, o destinatário, a fatura, o cálculo do imposto, o
#' transportador e os volumes, os produtos (com as informações adicionais de
#' cada um logo abaixo), o ISSQN e os dados adicionais. Os itens e as
#' informações complementares que não cabem seguem em folhas adicionais, com o
#' cabeçalho repetido. Os quadros da fatura e do ISSQN saem quando a nota não
#' os tem, e o espaço vai para os produtos. A nota de homologação leva "SEM
#' VALOR FISCAL" em marca d'água.
#'
#' O DANFE só traz o que está no XML. Para a NFC-e, use [danfce_pdf()].
#'
#' @param xml A NF-e: o caminho do arquivo ou o texto do XML (o `nfeProc`, com
#'   o protocolo; sem ele, o campo do protocolo fica vazio).
#' @param arquivo O PDF a gravar.
#' @return O caminho do PDF, invisível.
#' @seealso [danfce_pdf()], [dacce_pdf()], [nfe_ler()]
#' @source Manual de Orientação do Contribuinte 7.0, Anexo II: Manual de
#'   Especificações Técnicas do DANFE e Código de Barras (outubro de 2020),
#'   itens 2 (o CODE-128C), 3.1 a 3.10 e o Anexo III.02; e a Nota Técnica
#'   Conjunta 2025.001, item 6 (o código de barras da chave com o CNPJ
#'   alfanumérico, em CODE-128 C e A).
#' @examples
#' nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")
#' danfe_pdf(nota, file.path(tempdir(), "danfe.pdf"))
#' @export
danfe_pdf = function(xml, arquivo) {
  documento = ler_o_xml_para_assinar(xml)
  informacao = xml2::xml_find_first(documento, "//*[local-name()='NFe']/*[local-name()='infNFe']")
  if (inherits(informacao, "xml_missing")) {
    stop("O XML n\u00e3o traz uma NF-e (o elemento NFe com o infNFe).", call. = FALSE)
  }
  if (identical(texto_pelo_caminho(informacao, "ide/mod"), "65")) {
    stop("A NFC-e (modelo 65) tem o DANFE NFC-e: use danfce_pdf().", call. = FALSE)
  }
  nota = dados_do_danfe(documento, informacao)
  abrir_o_pdf(arquivo, LARGURA_DO_A4, ALTURA_DO_A4)
  on.exit(grDevices::dev.off(), add = TRUE)
  # A primeira folha abre antes de dividir os itens: a medida dos textos precisa da folha aberta.
  grid::grid.newpage()
  paginas = paginar_o_danfe(nota)
  for (numero in seq_along(paginas)) {
    if (numero > 1) {
      grid::grid.newpage()
    }
    desenhar_pagina_do_danfe(nota, paginas[[numero]], numero, length(paginas))
  }
  invisible(arquivo)
}

# O que o DANFE mostra, lido do XML: os campos de cada quadro, os itens e as linhas das informações complementares.
dados_do_danfe = function(documento, informacao) {
  campo = list()
  caminhos = c(
    chave = "@Id", numero = "ide/nNF", serie = "ide/serie", tipo_operacao = "ide/tpNF", natureza = "ide/natOp",
    emissao = "ide/dhEmi|ide/dEmi", saida = "ide/dhSaiEnt|ide/dSaiEnt", hora_saida = "ide/hSaiEnt", tipo_emissao = "ide/tpEmis",
    ambiente = "ide/tpAmb", emitente_nome = "emit/xNome", emitente_fantasia = "emit/xFant",
    emitente_documento = "emit/CNPJ|emit/CPF", emitente_ie = "emit/IE", emitente_iest = "emit/IEST", emitente_im = "emit/IM",
    emitente_logradouro = "emit/enderEmit/xLgr", emitente_numero = "emit/enderEmit/nro", emitente_complemento = "emit/enderEmit/xCpl",
    emitente_bairro = "emit/enderEmit/xBairro", emitente_municipio = "emit/enderEmit/xMun", emitente_uf = "emit/enderEmit/UF",
    emitente_cep = "emit/enderEmit/CEP", emitente_fone = "emit/enderEmit/fone",
    destinatario_nome = "dest/xNome", destinatario_documento = "dest/CNPJ|dest/CPF|dest/idEstrangeiro",
    destinatario_ie = "dest/IE", destinatario_logradouro = "dest/enderDest/xLgr", destinatario_numero = "dest/enderDest/nro",
    destinatario_complemento = "dest/enderDest/xCpl", destinatario_bairro = "dest/enderDest/xBairro",
    destinatario_municipio = "dest/enderDest/xMun", destinatario_uf = "dest/enderDest/UF", destinatario_cep = "dest/enderDest/CEP",
    destinatario_fone = "dest/enderDest/fone",
    base_icms = "total/ICMSTot/vBC", valor_icms = "total/ICMSTot/vICMS", base_st = "total/ICMSTot/vBCST",
    valor_st = "total/ICMSTot/vST", valor_produtos = "total/ICMSTot/vProd", valor_frete = "total/ICMSTot/vFrete",
    valor_seguro = "total/ICMSTot/vSeg", valor_desconto = "total/ICMSTot/vDesc", valor_outros = "total/ICMSTot/vOutro",
    valor_ipi = "total/ICMSTot/vIPI", valor_nota = "total/ICMSTot/vNF", valor_tributos = "total/ICMSTot/vTotTrib",
    servicos = "total/ISSQNtot/vServ", base_iss = "total/ISSQNtot/vBC", valor_iss = "total/ISSQNtot/vISS",
    modalidade_frete = "transp/modFrete", transportador_nome = "transp/transporta/xNome",
    transportador_documento = "transp/transporta/CNPJ|transp/transporta/CPF", transportador_ie = "transp/transporta/IE",
    transportador_endereco = "transp/transporta/xEnder", transportador_municipio = "transp/transporta/xMun",
    transportador_uf = "transp/transporta/UF", placa = "transp/veicTransp/placa", placa_uf = "transp/veicTransp/UF",
    antt = "transp/veicTransp/RNTC", volumes = "transp/vol/qVol", especie = "transp/vol/esp", marca = "transp/vol/marca",
    numeracao = "transp/vol/nVol", peso_liquido = "transp/vol/pesoL", peso_bruto = "transp/vol/pesoB",
    informacoes_fisco = "infAdic/infAdFisco", informacoes_complementares = "infAdic/infCpl"
  )
  for (nome in names(caminhos)) {
    if (caminhos[[nome]] == "@Id") {
      campo[[nome]] = sub("^NFe", "", xml2::xml_attr(informacao, "Id"))
    } else {
      campo[[nome]] = texto_pelo_caminho(informacao, caminhos[[nome]])
    }
  }
  protocolo = xml2::xml_find_first(documento, "//*[local-name()='protNFe']/*[local-name()='infProt']")
  campo$protocolo = texto_pelo_caminho(protocolo, "nProt")
  campo$autorizacao = texto_pelo_caminho(protocolo, "dhRecbto")
  campo$duplicatas = duplicatas_do_danfe(informacao)
  campo$fatura = texto_pelo_caminho(informacao, "cobr/fat/nFat")
  campo$itens = itens_do_danfe(informacao)
  campo
}

# As duplicatas, em texto curto (número, vencimento e valor), para o quadro da fatura.
duplicatas_do_danfe = function(informacao) {
  duplicatas = xml2::xml_find_all(informacao, "*[local-name()='cobr']/*[local-name()='dup']")
  textos = character()
  for (duplicata in duplicatas) {
    textos = c(textos, paste(texto_pelo_caminho(duplicata, "nDup"), data_do_xml(texto_pelo_caminho(duplicata, "dVenc")),
                             numero_brasileiro(as.numeric(texto_pelo_caminho(duplicata, "vDup")))))
  }
  textos
}

# Um item por linha: as colunas do quadro dos produtos e as informações adicionais do produto (com o FCP, que o manual
# manda imprimir ali).
itens_do_danfe = function(informacao) {
  detalhes = xml2::xml_find_all(informacao, "*[local-name()='det']")
  linhas = list()
  for (detalhe in detalhes) {
    cst = texto_pelo_caminho(detalhe, "imposto/ICMS/*/CST")
    csosn = texto_pelo_caminho(detalhe, "imposto/ICMS/*/CSOSN")
    origem = texto_pelo_caminho(detalhe, "imposto/ICMS/*/orig")
    adicionais = texto_pelo_caminho(detalhe, "infAdProd")
    fcp = texto_pelo_caminho(detalhe, "imposto/ICMS/*/vFCP")
    if (!is.na(fcp)) {
      adicionais = paste(c(adicionais[!is.na(adicionais)], paste0("vFCP: ", numero_brasileiro(as.numeric(fcp)))), collapse = " ")
    }
    linhas[[length(linhas) + 1]] = data.frame(
      codigo = texto_pelo_caminho(detalhe, "prod/cProd"), descricao = texto_pelo_caminho(detalhe, "prod/xProd"),
      ncm = texto_pelo_caminho(detalhe, "prod/NCM"),
      cst = paste0(ifelse(is.na(origem), "", origem), ifelse(is.na(cst), ifelse(is.na(csosn), "", csosn), cst)),
      cfop = texto_pelo_caminho(detalhe, "prod/CFOP"), unidade = texto_pelo_caminho(detalhe, "prod/uCom"),
      quantidade = numero_brasileiro(as.numeric(texto_pelo_caminho(detalhe, "prod/qCom")), 2, 4),
      valor_unitario = numero_brasileiro(as.numeric(texto_pelo_caminho(detalhe, "prod/vUnCom")), 2, 10),
      valor_total = numero_brasileiro(as.numeric(texto_pelo_caminho(detalhe, "prod/vProd"))),
      base_icms = numero_brasileiro(as.numeric(texto_pelo_caminho(detalhe, "imposto/ICMS/*/vBC"))),
      valor_icms = numero_brasileiro(as.numeric(texto_pelo_caminho(detalhe, "imposto/ICMS/*/vICMS"))),
      valor_ipi = numero_brasileiro(as.numeric(texto_pelo_caminho(detalhe, "imposto/IPI/IPITrib/vIPI"))),
      aliquota_icms = numero_brasileiro(as.numeric(texto_pelo_caminho(detalhe, "imposto/ICMS/*/pICMS"))),
      aliquota_ipi = numero_brasileiro(as.numeric(texto_pelo_caminho(detalhe, "imposto/IPI/IPITrib/pIPI"))),
      adicionais = if (length(adicionais) == 0) NA_character_ else adicionais
    )
  }
  if (length(linhas) == 0) {
    return(data.frame())
  }
  do.call(rbind, linhas)
}

# A altura do quadro dos produtos na primeira folha (o 3.8.1: 6,77 cm), com o espaço da fatura e do ISSQN quando a nota
# não os tem (o 3.3.2 e o 3.3.3), e o deslocamento dos quadros de baixo.
geometria_da_primeira_folha = function(nota) {
  sem_fatura = is.na(nota$fatura) && length(nota$duplicatas) == 0
  sem_issqn = is.na(nota$servicos)
  subida = if (sem_fatura) 1.27 else 0
  altura_dos_produtos = 6.77 + subida + if (sem_issqn) 1.27 else 0
  list(sem_fatura = sem_fatura, sem_issqn = sem_issqn, subida = subida, topo_dos_produtos = 17.87 - subida,
       altura_dos_produtos = altura_dos_produtos)
}

# As linhas do quadro dos produtos: a primeira de cada item (com as colunas), as que continuam a descrição e as das
# informações adicionais do produto. As informações complementares que não cabem no campo delas vêm depois, numa
# folha adicional.
linhas_dos_produtos_do_danfe = function(itens) {
  largura_da_descricao = COLUNAS_DOS_PRODUTOS_DO_DANFE$largura[COLUNAS_DOS_PRODUTOS_DO_DANFE$coluna == "descricao"] - 0.1
  linhas = list()
  for (posicao in seq_len(nrow(itens))) {
    descricao = quebrar_texto(itens$descricao[posicao], largura_da_descricao, TAMANHO_DOS_PRODUTOS)
    adicionais = quebrar_texto(itens$adicionais[posicao], largura_da_descricao, TAMANHO_DOS_PRODUTOS)
    textos = c(descricao, adicionais)
    if (length(textos) == 0) {
      textos = ""
    }
    linhas[[length(linhas) + 1]] = data.frame(item = posicao, primeira = c(TRUE, rep(FALSE, length(textos) - 1)),
                                              texto = textos)
  }
  if (length(linhas) == 0) {
    return(data.frame(item = integer(), primeira = logical(), texto = character()))
  }
  do.call(rbind, linhas)
}

# Divide as linhas dos produtos em folhas (sem partir um item entre duas, quando ele cabe numa folha) e põe as
# informações complementares que sobram na última. Cada folha diz as linhas dos produtos e as das informações.
paginar_o_danfe = function(nota) {
  geometria = geometria_da_primeira_folha(nota)
  linhas = linhas_dos_produtos_do_danfe(nota$itens)
  cabe_na_primeira = floor((geometria$altura_dos_produtos - 0.45) / ALTURA_DA_LINHA_DOS_PRODUTOS)
  cabe_nas_outras = floor((ALTURA_DO_A4 - 0.3 - 8.58 - 0.45) / ALTURA_DA_LINHA_DOS_PRODUTOS)
  informacoes = texto_das_informacoes_complementares(nota)
  linhas_das_informacoes = quebrar_texto(informacoes, 12.95 - 0.15, TAMANHO_DOS_PRODUTOS)
  cabe_nas_informacoes = floor((3.07 - 0.3) / ALTURA_DA_LINHA_DOS_PRODUTOS)
  sobra_das_informacoes = character()
  if (length(linhas_das_informacoes) > cabe_nas_informacoes) {
    sobra_das_informacoes = linhas_das_informacoes[-seq_len(cabe_nas_informacoes - 1)]
    linhas_das_informacoes = c(linhas_das_informacoes[seq_len(cabe_nas_informacoes - 1)], "(CONTINUA NA FOLHA SEGUINTE)")
  }
  paginas = list()
  inicio = 1
  capacidade = cabe_na_primeira
  while (inicio <= nrow(linhas) || length(paginas) == 0) {
    fim = min(nrow(linhas), inicio + capacidade - 1)
    # O item que não cabe inteiro vai para a folha seguinte, se começar no meio dela.
    if (fim < nrow(linhas) && !linhas$primeira[fim + 1]) {
      comeco_do_item = max(which(linhas$primeira[inicio:fim])) + inicio - 1
      if (comeco_do_item > inicio) {
        fim = comeco_do_item - 1
      }
    }
    paginas[[length(paginas) + 1]] = list(linhas = linhas[seq_len(max(0, fim - inicio + 1)) + inicio - 1, , drop = FALSE],
                                          informacoes = character(), continuacao = character())
    inicio = fim + 1
    capacidade = cabe_nas_outras
    if (nrow(linhas) == 0) {
      break
    }
  }
  paginas[[1]]$informacoes = linhas_das_informacoes
  if (length(sobra_das_informacoes) > 0) {
    ultima = paginas[[length(paginas)]]
    usadas = if (length(paginas) == 1) cabe_nas_outras else nrow(ultima$linhas) + 2
    if (length(paginas) == 1 || usadas + length(sobra_das_informacoes) > cabe_nas_outras) {
      paginas[[length(paginas) + 1]] = list(linhas = linhas[0, , drop = FALSE], informacoes = character(),
                                            continuacao = sobra_das_informacoes)
    } else {
      paginas[[length(paginas)]]$continuacao = sobra_das_informacoes
    }
  }
  paginas
}

# O conteúdo do campo das informações complementares: as de interesse do Fisco e as do contribuinte.
texto_das_informacoes_complementares = function(nota) {
  partes = c(nota$informacoes_fisco, nota$informacoes_complementares)
  paste(partes[!is.na(partes)], collapse = "; ")
}

desenhar_pagina_do_danfe = function(nota, pagina, numero, total) {
  if (identical(nota$ambiente, "2")) {
    desenhar_marca_de_homologacao()
  }
  if (numero == 1) {
    desenhar_canhoto_do_danfe(nota)
  }
  desenhar_cabecalho_do_danfe(nota, numero, total)
  if (numero == 1) {
    geometria = geometria_da_primeira_folha(nota)
    desenhar_destinatario_do_danfe(nota)
    desenhar_impostos_e_transporte_do_danfe(nota, geometria)
    desenhar_produtos_do_danfe(nota, pagina, geometria$topo_dos_produtos, geometria$altura_dos_produtos)
    desenhar_rodape_do_danfe(nota, pagina, geometria)
  } else {
    desenhar_produtos_do_danfe(nota, pagina, 8.58, ALTURA_DO_A4 - 0.3 - 8.58)
  }
}

desenhar_canhoto_do_danfe = function(nota) {
  desenhar_caixa(0.25, 0.42, 16.10, 0.85,
                 conteudo = paste0("RECEBEMOS DE ", toupper(nota$emitente_nome),
                                   " OS PRODUTOS E/OU SERVI\u00c7OS CONSTANTES DA NOTA FISCAL ELETR\u00d4NICA INDICADA AO LADO"),
                 tamanho_do_conteudo = 6)
  desenhar_caixa(16.35, 0.42, 4.50, 1.70, conteudo = c("NF-e", paste0("N\u00ba ", numero_da_nota_formatado(nota$numero)),
                                                       paste0("S\u00c9RIE ", sprintf("%03d", as.integer(nota$serie)))),
                 tamanho_do_conteudo = 10, negrito = TRUE, alinhamento = "centre")
  desenhar_caixa(0.25, 1.27, 4.10, 0.85, titulo = "DATA DE RECEBIMENTO")
  desenhar_caixa(4.35, 1.27, 12.00, 0.85, titulo = "IDENTIFICA\u00c7\u00c3O E ASSINATURA DO RECEBEDOR")
  desenhar_linha(0.25, 2.33, 20.82, 2.33, tracejada = TRUE)
}

# O número da nota com os pontos de milhar (000.000.001).
numero_da_nota_formatado = function(numero) {
  texto = sprintf("%09d", as.integer(numero))
  paste(substr(texto, 1, 3), substr(texto, 4, 6), substr(texto, 7, 9), sep = ".")
}

# O cabeçalho que se repete em toda folha: o emitente, o quadro do DANFE, o código de barras, a chave, a consulta e o
# protocolo, a natureza da operação e as inscrições.
desenhar_cabecalho_do_danfe = function(nota, numero, total) {
  endereco = paste0(nota$emitente_logradouro, ", ", nota$emitente_numero,
                    ifelse(is.na(nota$emitente_complemento), "", paste0(" - ", nota$emitente_complemento)))
  linhas_do_emitente = c(quebrar_texto(toupper(nota$emitente_nome), 9.8, 12, TRUE))
  desenhar_caixa(0.25, 2.54, 10.00, 3.92, titulo = "IDENTIFICA\u00c7\u00c3O DO EMITENTE")
  desenhar_caixa(0.25, 2.80, 10.00, 1.4, conteudo = linhas_do_emitente, tamanho_do_conteudo = 12, negrito = TRUE,
                 alinhamento = "centre", borda = FALSE)
  desenhar_caixa(0.25, 4.30, 10.00, 2.0, conteudo = c(
    quebrar_texto(endereco, 9.8, 8, TRUE),
    paste0(nota$emitente_bairro, " - ", cep_formatado(nota$emitente_cep)),
    paste0(nota$emitente_municipio, " - ", nota$emitente_uf, ifelse(is.na(nota$emitente_fone), "", paste0(" - FONE: ", nota$emitente_fone)))
  ), tamanho_do_conteudo = 8, negrito = TRUE, alinhamento = "centre", borda = FALSE)
  desenhar_caixa(10.25, 2.54, 2.54, 3.92)
  # O "DANFE" com 12 pontos; a identificação e a entrada ou saída com 8; o número, a série e a folha com 10, em negrito
  # (o item 3.7.4 do manual).
  desenhar_texto("DANFE", 11.52, 2.62, tamanho = 12, negrito = TRUE, alinhamento = "centre")
  linhas_da_identificacao = c("DOCUMENTO", "AUXILIAR DA", "NOTA FISCAL", "ELETR\u00d4NICA")
  for (posicao in seq_along(linhas_da_identificacao)) {
    desenhar_texto(linhas_da_identificacao[posicao], 11.52, 3.02 + (posicao - 1) * 0.30, tamanho = 8, alinhamento = "centre")
  }
  desenhar_texto("0 - ENTRADA", 10.35, 4.30, tamanho = 8)
  desenhar_texto("1 - SA\u00cdDA", 10.35, 4.62, tamanho = 8)
  desenhar_caixa(12.17, 4.30, 0.50, 0.55, conteudo = nota$tipo_operacao, tamanho_do_conteudo = 10, negrito = TRUE,
                 alinhamento = "centre")
  desenhar_texto(paste0("N\u00ba ", numero_da_nota_formatado(nota$numero)), 11.52, 5.02, tamanho = 10, negrito = TRUE,
                 alinhamento = "centre")
  desenhar_texto(paste0("S\u00c9RIE ", sprintf("%03d", as.integer(nota$serie))), 11.52, 5.42, tamanho = 10, negrito = TRUE,
                 alinhamento = "centre")
  desenhar_texto(sprintf("FOLHA %d/%d", numero, total), 11.52, 5.82, tamanho = 10, negrito = TRUE, alinhamento = "centre")
  desenhar_caixa(12.79, 2.54, 8.00, 1.48)
  desenhar_codigo_de_barras(nota$chave, 12.99, 2.78, 7.60, 1.00)
  desenhar_caixa(12.79, 4.02, 8.00, 0.85, titulo = "CHAVE DE ACESSO", conteudo = chave_em_blocos(nota$chave),
                 tamanho_do_conteudo = 8, negrito = TRUE, alinhamento = "centre")
  desenhar_caixa(12.79, 4.87, 8.00, 1.59, conteudo = c(
    "Consulta de autenticidade no portal nacional da NF-e", "www.nfe.fazenda.gov.br/portal ou no site da Sefaz Autorizadora"
  ), tamanho_do_conteudo = 8, alinhamento = "centre")
  desenhar_caixa(0.25, 6.46, 12.54, 0.85, titulo = "NATUREZA DA OPERA\u00c7\u00c3O", conteudo = nota$natureza,
                 tamanho_do_conteudo = 9)
  protocolo = if (is.na(nota$protocolo)) NA_character_ else
    paste(nota$protocolo, data_do_xml(nota$autorizacao), hora_do_xml(nota$autorizacao))
  desenhar_caixa(12.79, 6.46, 8.00, 0.85, titulo = "PROTOCOLO DE AUTORIZA\u00c7\u00c3O DE USO", conteudo = protocolo,
                 tamanho_do_conteudo = 9, negrito = TRUE, alinhamento = "centre")
  desenhar_caixa(0.25, 7.31, 6.86, 0.85, titulo = "INSCRI\u00c7\u00c3O ESTADUAL", conteudo = nota$emitente_ie, tamanho_do_conteudo = 9)
  desenhar_caixa(7.11, 7.31, 6.86, 0.85, titulo = "INSCRI\u00c7\u00c3O ESTADUAL DO SUBST. TRIBUT\u00c1RIO",
                 conteudo = nota$emitente_iest, tamanho_do_conteudo = 9)
  desenhar_caixa(13.97, 7.31, 6.86, 0.85, titulo = "CNPJ", conteudo = documento_formatado(nota$emitente_documento),
                 tamanho_do_conteudo = 9)
}

desenhar_destinatario_do_danfe = function(nota) {
  desenhar_texto("DESTINAT\u00c1RIO/REMETENTE", 0.25, 8.20, tamanho = 6, negrito = TRUE)
  endereco = paste0(nota$destinatario_logradouro, ifelse(is.na(nota$destinatario_numero), "", paste0(", ", nota$destinatario_numero)),
                    ifelse(is.na(nota$destinatario_complemento), "", paste0(" - ", nota$destinatario_complemento)))
  desenhar_caixa(0.25, 8.58, 12.32, 0.85, titulo = "NOME/RAZ\u00c3O SOCIAL", conteudo = nota$destinatario_nome, tamanho_do_conteudo = 9)
  desenhar_caixa(12.57, 8.58, 5.33, 0.85, titulo = "CNPJ/CPF", conteudo = documento_formatado(nota$destinatario_documento),
                 tamanho_do_conteudo = 9, negrito = TRUE)
  desenhar_caixa(17.90, 8.58, 2.92, 0.85, titulo = "DATA DA EMISS\u00c3O", conteudo = data_do_xml(nota$emissao), tamanho_do_conteudo = 9)
  desenhar_caixa(0.25, 9.43, 10.16, 0.85, titulo = "ENDERE\u00c7O", conteudo = if (is.na(nota$destinatario_logradouro)) NA else endereco,
                 tamanho_do_conteudo = 9)
  desenhar_caixa(10.41, 9.43, 4.83, 0.85, titulo = "BAIRRO/DISTRITO", conteudo = nota$destinatario_bairro, tamanho_do_conteudo = 9)
  desenhar_caixa(15.24, 9.43, 2.67, 0.85, titulo = "CEP", conteudo = cep_formatado(nota$destinatario_cep), tamanho_do_conteudo = 9)
  desenhar_caixa(17.91, 9.43, 2.91, 0.85, titulo = "DATA DA SA\u00cdDA/ENTRADA", conteudo = data_do_xml(nota$saida),
                 tamanho_do_conteudo = 9, negrito = TRUE)
  desenhar_caixa(0.25, 10.28, 7.11, 0.85, titulo = "MUNIC\u00cdPIO", conteudo = nota$destinatario_municipio, tamanho_do_conteudo = 9)
  desenhar_caixa(7.36, 10.28, 4.06, 0.85, titulo = "FONE/FAX", conteudo = nota$destinatario_fone, tamanho_do_conteudo = 9)
  desenhar_caixa(11.42, 10.28, 1.14, 0.85, titulo = "UF", conteudo = nota$destinatario_uf, tamanho_do_conteudo = 9)
  desenhar_caixa(12.56, 10.28, 5.33, 0.85, titulo = "INSCRI\u00c7\u00c3O ESTADUAL", conteudo = nota$destinatario_ie, tamanho_do_conteudo = 9)
  hora = if (!is.na(nota$hora_saida)) nota$hora_saida else hora_do_xml(nota$saida)
  desenhar_caixa(17.89, 10.28, 2.93, 0.85, titulo = "HORA DA SA\u00cdDA/ENTRADA", conteudo = hora, tamanho_do_conteudo = 9,
                 negrito = TRUE)
}

# A fatura, o cálculo do imposto, o transportador e os volumes; sem a fatura, os quadros sobem.
desenhar_impostos_e_transporte_do_danfe = function(nota, geometria) {
  if (!geometria$sem_fatura) {
    desenhar_texto("FATURA/DUPLICATAS", 0.25, 11.13, tamanho = 6, negrito = TRUE)
    fatura = c(if (is.na(nota$fatura)) NULL else paste("FATURA", nota$fatura), nota$duplicatas)
    desenhar_caixa(0.25, 11.51, 20.57, 0.85, conteudo = paste(fatura, collapse = "   |   "), tamanho_do_conteudo = 7)
  }
  topo = 12.36 - geometria$subida
  desenhar_texto("C\u00c1LCULO DO IMPOSTO", 0.25, topo + 0.04, tamanho = 6, negrito = TRUE)
  linha_1 = topo + 0.42
  linha_2 = linha_1 + 0.85
  valores = list(
    list(0.25, linha_1, 4.06, "BASE DE C\u00c1LCULO DO ICMS", nota$base_icms), list(4.31, linha_1, 4.06, "VALOR DO ICMS", nota$valor_icms),
    list(8.37, linha_1, 4.06, "BASE DE C\u00c1LCULO DO ICMS ST", nota$base_st), list(12.43, linha_1, 4.06, "VALOR DO ICMS ST", nota$valor_st),
    list(16.49, linha_1, 4.33, "VALOR TOTAL DOS PRODUTOS", nota$valor_produtos),
    list(0.25, linha_2, 3.30, "VALOR DO FRETE", nota$valor_frete), list(3.55, linha_2, 3.30, "VALOR DO SEGURO", nota$valor_seguro),
    list(6.85, linha_2, 3.30, "DESCONTO", nota$valor_desconto), list(10.15, linha_2, 3.30, "OUTRAS DESPESAS ACESS\u00d3RIAS", nota$valor_outros),
    list(13.45, linha_2, 3.30, "VALOR DO IPI", nota$valor_ipi), list(16.75, linha_2, 4.07, "VALOR TOTAL DA NOTA", nota$valor_nota)
  )
  for (valor in valores) {
    desenhar_caixa(valor[[1]], valor[[2]], valor[[3]], 0.85, titulo = valor[[4]],
                   conteudo = numero_brasileiro(as.numeric(valor[[5]])), tamanho_do_conteudo = 9, alinhamento = "right",
                   negrito = identical(valor[[4]], "VALOR TOTAL DA NOTA"))
  }
  topo = 14.48 - geometria$subida
  desenhar_texto("TRANSPORTADOR/VOLUMES TRANSPORTADOS", 0.25, topo + 0.04, tamanho = 6, negrito = TRUE)
  linha_1 = topo + 0.42
  linha_2 = linha_1 + 0.85
  linha_3 = linha_2 + 0.85
  desenhar_caixa(0.25, linha_1, 9.02, 0.85, titulo = "NOME/RAZ\u00c3O SOCIAL", conteudo = nota$transportador_nome, tamanho_do_conteudo = 9)
  desenhar_caixa(9.27, linha_1, 2.79, 0.85, titulo = "FRETE POR CONTA", conteudo = texto_da_modalidade_do_frete(nota$modalidade_frete),
                 tamanho_do_conteudo = 7)
  desenhar_caixa(12.06, linha_1, 1.78, 0.85, titulo = "C\u00d3DIGO ANTT", conteudo = nota$antt, tamanho_do_conteudo = 8)
  desenhar_caixa(13.84, linha_1, 2.29, 0.85, titulo = "PLACA DO VE\u00cdCULO", conteudo = nota$placa, tamanho_do_conteudo = 9)
  desenhar_caixa(16.13, linha_1, 0.76, 0.85, titulo = "UF", conteudo = nota$placa_uf, tamanho_do_conteudo = 9)
  desenhar_caixa(16.89, linha_1, 3.93, 0.85, titulo = "CNPJ/CPF", conteudo = documento_formatado(nota$transportador_documento),
                 tamanho_do_conteudo = 9)
  desenhar_caixa(0.25, linha_2, 9.02, 0.85, titulo = "ENDERE\u00c7O", conteudo = nota$transportador_endereco, tamanho_do_conteudo = 9)
  desenhar_caixa(9.27, linha_2, 6.86, 0.85, titulo = "MUNIC\u00cdPIO", conteudo = nota$transportador_municipio, tamanho_do_conteudo = 9)
  desenhar_caixa(16.13, linha_2, 0.76, 0.85, titulo = "UF", conteudo = nota$transportador_uf, tamanho_do_conteudo = 9)
  desenhar_caixa(16.89, linha_2, 3.93, 0.85, titulo = "INSCRI\u00c7\u00c3O ESTADUAL", conteudo = nota$transportador_ie, tamanho_do_conteudo = 9)
  desenhar_caixa(0.25, linha_3, 2.92, 0.85, titulo = "QUANTIDADE", conteudo = nota$volumes, tamanho_do_conteudo = 9)
  desenhar_caixa(3.17, linha_3, 3.05, 0.85, titulo = "ESP\u00c9CIE", conteudo = nota$especie, tamanho_do_conteudo = 9)
  desenhar_caixa(6.22, linha_3, 3.05, 0.85, titulo = "MARCA", conteudo = nota$marca, tamanho_do_conteudo = 9)
  desenhar_caixa(9.27, linha_3, 4.83, 0.85, titulo = "NUMERA\u00c7\u00c3O", conteudo = nota$numeracao, tamanho_do_conteudo = 9)
  desenhar_caixa(14.10, linha_3, 3.43, 0.85, titulo = "PESO BRUTO", conteudo = numero_brasileiro(as.numeric(nota$peso_bruto), 3),
                 tamanho_do_conteudo = 9, alinhamento = "right")
  desenhar_caixa(17.53, linha_3, 3.29, 0.85, titulo = "PESO L\u00cdQUIDO", conteudo = numero_brasileiro(as.numeric(nota$peso_liquido), 3),
                 tamanho_do_conteudo = 9, alinhamento = "right")
}

# A modalidade do frete (modFrete) por extenso, como os DANFE costumam mostrar.
texto_da_modalidade_do_frete = function(modalidade) {
  textos = c("0" = "0-POR CONTA DO REMET", "1" = "1-POR CONTA DO DEST", "2" = "2-POR CONTA DE TERCEIROS",
             "3" = "3-PR\u00d3PRIO POR CONTA DO REMET", "4" = "4-PR\u00d3PRIO POR CONTA DO DEST", "9" = "9-SEM FRETE")
  if (is.na(modalidade) || !(modalidade %in% names(textos))) {
    return(modalidade)
  }
  textos[[modalidade]]
}

# O quadro dos produtos: os títulos das colunas, as linhas de cada item (a primeira com as colunas, as outras só com o
# texto na descrição), o destaque tracejado entre os itens e, quando sobram, as informações complementares.
desenhar_produtos_do_danfe = function(nota, pagina, topo, altura) {
  desenhar_texto("DADOS DOS PRODUTOS/SERVI\u00c7OS", 0.25, topo - 0.38, tamanho = 6, negrito = TRUE)
  desenhar_caixa(0.25, topo, 20.57, altura)
  colunas = COLUNAS_DOS_PRODUTOS_DO_DANFE
  inicios = 0.25 + cumsum(c(0, colunas$largura))[seq_len(nrow(colunas))]
  # Com a continuação das informações complementares embaixo, as colunas param no último item.
  fim_das_colunas = topo + altura
  if (length(pagina$continuacao) > 0) {
    fim_das_colunas = topo + 0.5 + nrow(pagina$linhas) * ALTURA_DA_LINHA_DOS_PRODUTOS + 0.1
  }
  for (posicao in seq_len(nrow(colunas))) {
    desenhar_caixa(inicios[posicao], topo, colunas$largura[posicao], 0.45, conteudo = colunas$titulo[posicao],
                   tamanho_do_conteudo = 5, negrito = TRUE, alinhamento = "centre")
    if (posicao > 1) {
      desenhar_linha(inicios[posicao], topo, inicios[posicao], fim_das_colunas)
    }
  }
  linhas = pagina$linhas
  y = topo + 0.5
  for (posicao in seq_len(nrow(linhas))) {
    linha = linhas[posicao, ]
    if (linha$primeira) {
      if (posicao > 1) {
        desenhar_linha(0.25, y - 0.03, 20.82, y - 0.03, tracejada = TRUE)
      }
      item = nota$itens[linha$item, ]
      for (numero_da_coluna in seq_len(nrow(colunas))) {
        coluna = colunas$coluna[numero_da_coluna]
        texto = if (coluna == "descricao") linha$texto else item[[coluna]]
        desenhar_texto_na_coluna(texto, inicios[numero_da_coluna], colunas$largura[numero_da_coluna], y,
                                 colunas$alinhamento[numero_da_coluna])
      }
    } else {
      desenhar_texto_na_coluna(linha$texto, inicios[2], colunas$largura[2], y, "left")
    }
    y = y + ALTURA_DA_LINHA_DOS_PRODUTOS
  }
  if (length(pagina$continuacao) > 0) {
    y = y + 0.1
    desenhar_linha(0.25, y, 20.82, y)
    desenhar_texto("INFORMA\u00c7\u00d5ES COMPLEMENTARES (CONTINUA\u00c7\u00c3O)", 0.35, y + 0.05, tamanho = 6, negrito = TRUE)
    y = y + 0.35
    for (texto in pagina$continuacao) {
      desenhar_texto(texto, 0.35, y, tamanho = TAMANHO_DOS_PRODUTOS)
      y = y + ALTURA_DA_LINHA_DOS_PRODUTOS
    }
  }
}

desenhar_texto_na_coluna = function(texto, inicio, largura, y, alinhamento) {
  if (is.na(texto) || texto == "") {
    return(invisible(NULL))
  }
  x = switch(alinhamento, left = inicio + 0.05, right = inicio + largura - 0.05, centre = inicio + largura / 2)
  desenhar_texto(texto, x, y, tamanho = TAMANHO_DOS_PRODUTOS, alinhamento = alinhamento)
}

# O ISSQN (quando a nota tem) e os dados adicionais, no pé da primeira folha.
desenhar_rodape_do_danfe = function(nota, pagina, geometria) {
  if (!geometria$sem_issqn) {
    desenhar_texto("C\u00c1LCULO DO ISSQN", 0.25, 24.68, tamanho = 6, negrito = TRUE)
    desenhar_caixa(0.25, 25.06, 5.08, 0.85, titulo = "INSCRI\u00c7\u00c3O MUNICIPAL", conteudo = nota$emitente_im, tamanho_do_conteudo = 9)
    desenhar_caixa(5.33, 25.06, 5.08, 0.85, titulo = "VALOR TOTAL DOS SERVI\u00c7OS",
                   conteudo = numero_brasileiro(as.numeric(nota$servicos)), tamanho_do_conteudo = 9, alinhamento = "right")
    desenhar_caixa(10.41, 25.06, 5.08, 0.85, titulo = "BASE DE C\u00c1LCULO DO ISSQN",
                   conteudo = numero_brasileiro(as.numeric(nota$base_iss)), tamanho_do_conteudo = 9, alinhamento = "right")
    desenhar_caixa(15.49, 25.06, 5.33, 0.85, titulo = "VALOR DO ISSQN", conteudo = numero_brasileiro(as.numeric(nota$valor_iss)),
                   tamanho_do_conteudo = 9, alinhamento = "right")
  }
  desenhar_texto("DADOS ADICIONAIS", 0.25, 25.95, tamanho = 6, negrito = TRUE)
  desenhar_caixa(0.25, 26.33, 12.95, 3.07, titulo = "INFORMA\u00c7\u00d5ES COMPLEMENTARES", conteudo = pagina$informacoes,
                 tamanho_do_conteudo = TAMANHO_DOS_PRODUTOS)
  desenhar_caixa(13.20, 26.33, 7.62, 3.07, titulo = "RESERVADO AO FISCO")
}
