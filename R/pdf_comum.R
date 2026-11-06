# As peças que os documentos auxiliares em PDF (DANFE, DANFE Simplificado, DANFE NFC-e, DACTE, DAMDFE, DANFSe e a carta
# de correção) usam: o código de barras CODE-128 da chave, o QR-Code, as caixas com título e conteúdo, a quebra do texto pela largura e a
# formatação brasileira dos números, das datas e dos documentos. O desenho é do pacote grid, em centímetros, com o
# eixo no canto de cima, à esquerda, como os manuais medem.

#' @include sefaz.R
NULL

# CODE-128: as larguras dos módulos (barra, espaço, barra, espaço, barra, espaço) de cada valor, de 0 a 105, como no
# Anexo III.01 do Manual do DANFE (MOC 7.0, Anexo II), e o caractere de parada, com 7 larguras.
LARGURAS_DO_CODE_128 = c(
  "212222", "222122", "222221", "121223", "121322", "131222", "122213", "122312", "132212", "221213",
  "221312", "231212", "112232", "122132", "122231", "113222", "123122", "123221", "223211", "221132",
  "221231", "213212", "223112", "312131", "311222", "321122", "321221", "312212", "322112", "322211",
  "212123", "212321", "232121", "111323", "131123", "131321", "112313", "132113", "132311", "211313",
  "231113", "231311", "112133", "112331", "132131", "113123", "113321", "133121", "313121", "211331",
  "231131", "213113", "213311", "213131", "311123", "311321", "331121", "312113", "312311", "332111",
  "314111", "221411", "431111", "111224", "111422", "121124", "121421", "141122", "141221", "112214",
  "112412", "122114", "122411", "142112", "142211", "241211", "221114", "413111", "241112", "134111",
  "111242", "121142", "121241", "114212", "124112", "124211", "411212", "421112", "421211", "212141",
  "214121", "412121", "111143", "111341", "131141", "114113", "114311", "411113", "411311", "113141",
  "114131", "311141", "411131", "211412", "211214", "211232"
)
PARADA_DO_CODE_128 = "2331112"
INICIO_DO_CODE_128C = 105L
MUDA_PARA_O_CODE_128A = 101L
MUDA_PARA_O_CODE_128C = 99L
# A margem clara de cada lado, em módulos (o manual pede no mínimo 10).
MARGEM_CLARA_DO_CODE_128 = 10

# Os valores dos símbolos do código de barras da chave: o CODE-128C, que codifica os algarismos em pares, e, na chave
# com o CNPJ alfanumérico, o modelo híbrido da Nota Técnica Conjunta 2025.001 (item 6): começa no C; diante de uma
# letra (ou do algarismo que sobra sozinho antes dela), muda para o A (101); no A, volta ao C (99) quando vêm quatro
# algarismos ou mais (com quantidade ímpar, o primeiro fica no A). No A, o valor é o código ASCII menos 32.
valores_do_codigo_128 = function(texto) {
  if (length(texto) != 1 || is.na(texto) || !grepl("^[0-9A-Z]+$", texto)) {
    stop("O c\u00f3digo de barras da chave aceita algarismos e letras mai\u00fasculas.", call. = FALSE)
  }
  caracteres = strsplit(texto, "")[[1]]
  quantidade = length(caracteres)
  valores = INICIO_DO_CODE_128C
  conjunto = "C"
  posicao = 1
  while (posicao <= quantidade) {
    algarismos_seguidos = algarismos_a_partir_de(caracteres, posicao)
    if (conjunto == "C") {
      for (par in seq_len(algarismos_seguidos %/% 2)) {
        valores = c(valores, as.integer(paste0(caracteres[posicao], caracteres[posicao + 1])))
        posicao = posicao + 2
      }
      if (posicao <= quantidade) {
        valores = c(valores, MUDA_PARA_O_CODE_128A)
        conjunto = "A"
      }
    } else if (algarismos_seguidos >= 4) {
      if (algarismos_seguidos %% 2 == 1) {
        valores = c(valores, utf8ToInt(caracteres[posicao]) - 32L)
        posicao = posicao + 1
      }
      valores = c(valores, MUDA_PARA_O_CODE_128C)
      conjunto = "C"
    } else {
      valores = c(valores, utf8ToInt(caracteres[posicao]) - 32L)
      posicao = posicao + 1
    }
  }
  digito = (valores[1] + sum(valores[-1] * seq_along(valores[-1]))) %% 103
  c(valores, digito)
}

# Quantos algarismos seguidos há a partir da posição.
algarismos_a_partir_de = function(caracteres, posicao) {
  quantidade = 0
  while (posicao + quantidade <= length(caracteres) && grepl("[0-9]", caracteres[posicao + quantidade])) {
    quantidade = quantidade + 1
  }
  quantidade
}

# As larguras dos módulos de cada símbolo (com a parada), começando por uma barra.
larguras_do_codigo_128 = function(texto) {
  simbolos = c(LARGURAS_DO_CODE_128[valores_do_codigo_128(texto) + 1], PARADA_DO_CODE_128)
  as.integer(strsplit(paste(simbolos, collapse = ""), "")[[1]])
}

# Desenha o código de barras da chave numa caixa (em centímetros, do canto de cima, à esquerda), com a margem clara.
desenhar_codigo_de_barras = function(texto, esquerda, superior, largura, altura) {
  larguras = larguras_do_codigo_128(texto)
  modulo = largura / (sum(larguras) + 2 * MARGEM_CLARA_DO_CODE_128)
  posicoes = cumsum(c(0, larguras))[seq_along(larguras)]
  barras = seq(1, length(larguras), by = 2)
  inicio_das_barras = esquerda + (MARGEM_CLARA_DO_CODE_128 + posicoes[barras]) * modulo
  grid::grid.rect(x = grid::unit(inicio_das_barras, "cm"), y = grid::unit(altura_da_folha() - superior, "cm"),
                  width = grid::unit(larguras[barras] * modulo, "cm"), height = grid::unit(altura, "cm"),
                  just = c("left", "top"), gp = grid::gpar(fill = "black", col = NA))
}

# Desenha o QR-Code de um texto num quadrado (em centímetros), pelo pacote qrcode (nível de correção M).
desenhar_qrcode = function(texto, esquerda, superior, lado) {
  exigir_pacotes("qrcode")
  matriz = as.matrix(qrcode::qr_code(texto, ecl = "M"))
  # A matriz do qrcode já vem com uma borda em branco; ela sai, e o `lado` é o do símbolo: a margem segura fica por
  # conta de quem desenha (o espaço em branco em volta).
  linhas_com_preto = which(rowSums(matriz) > 0)
  colunas_com_preto = which(colSums(matriz) > 0)
  matriz = matriz[min(linhas_com_preto):max(linhas_com_preto), min(colunas_com_preto):max(colunas_com_preto)]
  modulos = nrow(matriz)
  tamanho_do_modulo = lado / modulos
  pretos = which(matriz, arr.ind = TRUE)
  grid::grid.rect(x = grid::unit(esquerda + (pretos[, "col"] - 1) * tamanho_do_modulo, "cm"),
                  y = grid::unit(altura_da_folha() - superior - (pretos[, "row"] - 1) * tamanho_do_modulo, "cm"),
                  width = grid::unit(tamanho_do_modulo, "cm"), height = grid::unit(tamanho_do_modulo, "cm"),
                  just = c("left", "top"), gp = grid::gpar(fill = "black", col = NA))
}

# A altura da folha aberta, em centímetros: o grid mede de baixo para cima; os manuais, de cima para baixo.
altura_da_folha = function() {
  as.numeric(grid::convertHeight(grid::unit(1, "npc"), "cm"))
}

# Uma caixa com a borda, o título pequeno em cima, à esquerda, e o conteúdo embaixo (ou as linhas dele, uma em cima da
# outra). Tamanhos em pontos; posições em centímetros.
desenhar_caixa = function(esquerda, superior, largura, altura, titulo = NULL, conteudo = NULL, tamanho_do_titulo = 5,
                          tamanho_do_conteudo = 8, negrito = FALSE, alinhamento = "left", borda = TRUE) {
  topo = altura_da_folha() - superior
  if (borda) {
    grid::grid.rect(x = grid::unit(esquerda, "cm"), y = grid::unit(topo, "cm"), width = grid::unit(largura, "cm"),
                    height = grid::unit(altura, "cm"), just = c("left", "top"), gp = grid::gpar(fill = NA, lwd = 0.6))
  }
  if (!is.null(titulo) && !is.na(titulo)) {
    grid::grid.text(texto_para_o_pdf(titulo), x = grid::unit(esquerda + 0.05, "cm"), y = grid::unit(topo - 0.05, "cm"), just = c("left", "top"),
                    gp = grid::gpar(fontsize = tamanho_do_titulo, fontface = "bold"))
  }
  if (is.null(conteudo) || all(is.na(conteudo))) {
    return(invisible(NULL))
  }
  conteudo = ifelse(is.na(conteudo), "", conteudo)
  posicao_horizontal = switch(alinhamento, left = esquerda + 0.08, right = esquerda + largura - 0.08,
                              centre = esquerda + largura / 2)
  altura_da_linha = tamanho_do_conteudo * 0.0353 * 1.15
  primeira = if (is.null(titulo)) topo - 0.08 else topo - 0.05 - tamanho_do_titulo * 0.0353 * 1.2
  for (numero in seq_along(conteudo)) {
    grid::grid.text(texto_para_o_pdf(conteudo[numero]), x = grid::unit(posicao_horizontal, "cm"),
                    y = grid::unit(primeira - (numero - 1) * altura_da_linha, "cm"), just = c(alinhamento, "top"),
                    gp = grid::gpar(fontsize = tamanho_do_conteudo, fontface = if (negrito) "bold" else "plain"))
  }
  invisible(NULL)
}

# O texto como vai ao PDF: o dispositivo pdf() do R desenha o hífen (-) como sinal de menos; o hífen de verdade é o
# hífen opcional (U+00AD), que a codificação do Windows desenha como hífen.
texto_para_o_pdf = function(textos) {
  gsub("-", "\u00ad", textos, fixed = TRUE)
}

# Um texto solto (posições em centímetros, do canto de cima).
desenhar_texto = function(texto, esquerda, superior, tamanho = 8, negrito = FALSE, alinhamento = "left") {
  if (length(texto) == 0 || is.na(texto)) {
    return(invisible(NULL))
  }
  grid::grid.text(texto_para_o_pdf(texto), x = grid::unit(esquerda, "cm"), y = grid::unit(altura_da_folha() - superior, "cm"),
                  just = c(alinhamento, "top"), gp = grid::gpar(fontsize = tamanho, fontface = if (negrito) "bold" else "plain"))
}

# Uma linha (posições em centímetros, do canto de cima).
desenhar_linha = function(x_inicial, y_inicial, x_final, y_final, tracejada = FALSE) {
  altura = altura_da_folha()
  grid::grid.lines(x = grid::unit(c(x_inicial, x_final), "cm"), y = grid::unit(altura - c(y_inicial, y_final), "cm"),
                   gp = grid::gpar(lwd = 0.5, lty = if (tracejada) "dashed" else "solid"))
}

# A largura de um texto, em centímetros, na fonte aberta e no tamanho pedido.
largura_do_texto = function(textos, tamanho, negrito = FALSE) {
  as.numeric(grid::convertWidth(grid::grobWidth(grid::textGrob(texto_para_o_pdf(textos), gp = grid::gpar(
    fontsize = tamanho, fontface = if (negrito) "bold" else "plain"))), "cm"))
}

# O texto quebrado em linhas que cabem na largura (em centímetros), pela medida de cada palavra na fonte aberta. A
# palavra maior que a linha é cortada. A linha nova começa também em cada quebra de linha do texto (nenhum manual manda
# quebrar no ";", que fica no texto).
quebrar_texto = function(texto, largura, tamanho, negrito = FALSE) {
  if (is.na(texto) || texto == "") {
    return(character())
  }
  linhas = character()
  for (paragrafo in strsplit(texto, "\r?\n")[[1]]) {
    palavras = strsplit(trimws(paragrafo), "\\s+")[[1]]
    atual = ""
    for (palavra in palavras) {
      candidata = if (atual == "") palavra else paste(atual, palavra)
      if (largura_do_texto(candidata, tamanho, negrito) <= largura) {
        atual = candidata
        next
      }
      if (atual != "") {
        linhas = c(linhas, atual)
      }
      atual = palavra
      while (largura_do_texto(atual, tamanho, negrito) > largura && nchar(atual) > 1) {
        cabe = nchar(atual) - 1
        while (cabe > 1 && largura_do_texto(substr(atual, 1, cabe), tamanho, negrito) > largura) {
          cabe = cabe - 1
        }
        linhas = c(linhas, substr(atual, 1, cabe))
        atual = substr(atual, cabe + 1, nchar(atual))
      }
    }
    if (atual != "") {
      linhas = c(linhas, atual)
    }
  }
  linhas
}

# O número no formato brasileiro (1.234,56), com as casas pedidas; com `casas_maximas`, as casas do valor até esse
# limite, sem os zeros que sobram (e no mínimo `casas`).
numero_brasileiro = function(valores, casas = 2, casas_maximas = casas) {
  textos = character(length(valores))
  for (posicao in seq_along(valores)) {
    valor = valores[posicao]
    if (is.na(valor)) {
      textos[posicao] = ""
      next
    }
    texto = formatC(valor, format = "f", digits = casas_maximas, big.mark = "")
    if (casas_maximas > casas) {
      decimais = sub("^[^.]*\\.?", "", texto)
      decimais = sub("0+$", "", decimais)
      if (nchar(decimais) < casas) {
        decimais = formatC(decimais, width = casas, flag = "-")
        decimais = gsub(" ", "0", decimais)
      }
      texto = paste0(sub("\\..*$", "", texto), if (nchar(decimais) > 0) paste0(".", decimais) else "")
    }
    inteiro = sub("\\..*$", "", texto)
    decimal = if (grepl("\\.", texto)) sub("^[^.]*\\.", "", texto) else ""
    negativo = startsWith(inteiro, "-")
    inteiro = sub("^-", "", inteiro)
    # O "f" sem casas, não o "d": o "d" passa por inteiro do R e vira NA acima de 2.147.483.647.
    inteiro = formatC(as.numeric(inteiro), format = "f", digits = 0, big.mark = ".", decimal.mark = ",")
    textos[posicao] = paste0(if (negativo) "-" else "", inteiro, if (nchar(decimal) > 0) paste0(",", decimal) else "")
  }
  textos
}

# O CNPJ (numérico ou alfanumérico) ou o CPF com a pontuação; o resto, como veio.
documento_formatado = function(documentos) {
  textos = ifelse(is.na(documentos), "", documentos)
  cnpj = grepl("^[0-9A-Z]{12}[0-9]{2}$", textos)
  cpf = grepl("^[0-9]{11}$", textos)
  textos[cnpj] = sub("^(.{2})(.{3})(.{3})(.{4})(.{2})$", "\\1.\\2.\\3/\\4-\\5", textos[cnpj])
  textos[cpf] = sub("^(.{3})(.{3})(.{3})(.{2})$", "\\1.\\2.\\3-\\4", textos[cpf])
  textos
}

# A chave de acesso em blocos de quatro.
chave_em_blocos = function(chave) {
  trimws(gsub("(.{4})", "\\1 ", chave))
}

# A data (dd/mm/aaaa) e a hora (hh:mm:ss) de um instante do XML (AAAA-MM-DDThh:mm:ss-03:00), como está nele.
data_do_xml = function(texto) {
  ifelse(is.na(texto), "", sub("^([0-9]{4})-([0-9]{2})-([0-9]{2}).*$", "\\3/\\2/\\1", texto))
}

hora_do_xml = function(texto) {
  ifelse(is.na(texto) | !grepl("T", texto), "", sub("^.*T([0-9]{2}:[0-9]{2}:[0-9]{2}).*$", "\\1", texto))
}

# O CEP com o traço.
cep_formatado = function(cep) {
  ifelse(is.na(cep), "", sub("^([0-9]{5})([0-9]{3})$", "\\1-\\2", cep))
}

# Abre o PDF (Times, ou a família pedida, na codificação do Windows: a do Latin-1 desenha o hífen como sinal de menos).
abrir_o_pdf = function(arquivo, largura_em_cm, altura_em_cm, familia = "Times") {
  if (length(arquivo) != 1 || is.na(arquivo) || !grepl("\\.pdf$", arquivo, ignore.case = TRUE)) {
    stop("Informe o arquivo do PDF (terminando por .pdf).", call. = FALSE)
  }
  grDevices::pdf(arquivo, width = largura_em_cm / 2.54, height = altura_em_cm / 2.54, family = familia,
                 encoding = "WinAnsi.enc", onefile = TRUE)
}

# A marca d'água da nota de homologação, na diagonal.
desenhar_marca_de_homologacao = function(texto = "SEM VALOR FISCAL") {
  grid::grid.text(texto, x = grid::unit(0.5, "npc"), y = grid::unit(0.5, "npc"), rot = 55,
                  gp = grid::gpar(fontsize = 60, fontface = "bold", col = grDevices::rgb(0.75, 0.75, 0.75, 0.6)))
}
