# A chave de acesso achada num PDF (DANFE, DACTE, cupom da NFC-e...) ou numa imagem (foto, digitalização): pelo texto
# do PDF, pelo QR-Code ou por OCR. Só a chave: os outros números do documento não têm dígito verificador, e lidos de
# uma imagem podem vir errados sem aviso; os dados da nota vêm do XML.

#' @include chave.R
NULL

EXTENSOES_DE_IMAGEM = c("png", "jpg", "jpeg", "tif", "tiff", "bmp", "webp")
# A chave impressa no DANFE vem em 11 blocos de 4, separados por espaço; no QR-Code e no texto do XML, emendada.
SEQUENCIA_DE_BLOCOS = "\\b([0-9A-Z]{4} )+[0-9A-Z]{4}\\b"
CHAVE_EMENDADA = "[0-9]{6}[0-9A-Z]{12}[0-9]{26}"
RESOLUCAO_DA_PAGINA = 300

#' Achar a chave de acesso num PDF ou numa imagem
#'
#' Procura a chave de acesso de 44 posições em PDFs (o DANFE, o DACTE, o
#' cupom da NFC-e...) e em imagens (foto ou digitalização em PNG, JPG ou
#' TIFF) e devolve as chaves que conferem ([chave_valida()]). Procura nesta
#' ordem e para no primeiro jeito que acha: no texto do PDF, no QR-Code e, por
#' último, por OCR (reconhecimento do texto da imagem).
#'
#' Só a chave: o dígito verificador e o CNPJ que vão dentro dela pegam quase
#' toda leitura errada, então uma chave que confere é a do documento. Os outros
#' números (valores, quantidades) não têm essa conferência e, lidos de uma
#' imagem, podem vir errados sem aviso; os dados da nota vêm do XML, com
#' [nfe_ler()], e a situação dela, com [sefaz_situacao()]. Um número com cara
#' de chave que não confere (uma leitura errada, em geral) não é devolvido: ele
#' aparece em `problema`.
#'
#' Cada jeito precisa de um pacote, que só é usado se estiver instalado:
#' `pdftools` (o texto do PDF e a página do PDF como imagem), `opencv` (o
#' QR-Code) e `tesseract` (o OCR). Sem o pacote, o jeito é pulado. As páginas
#' de um TIFF depois da primeira precisam do pacote `magick`.
#'
#' Os limites: o PDF que tem texto é lido só pelo texto (uma página que é só
#' imagem, no mesmo PDF, fica de fora); e de cada imagem, ou página, sai um
#' QR-Code só (duas notas lado a lado na mesma página dão uma chave).
#'
#' @param arquivos Os PDFs e as imagens: o caminho de um arquivo ou um vetor
#'   com vários.
#' @param ocr `FALSE` deixa o OCR de fora (é o jeito mais lento: uns 1 a 2
#'   segundos por página).
#' @return Um `data.frame` com uma linha por chave achada (um PDF com várias
#'   notas, no texto ou uma por página, dá várias linhas) e uma linha para o
#'   arquivo em que nenhuma chave conferiu ou que não abriu: `arquivo`, `chave`, `origem` (`"texto do PDF"`, `"QR-Code"` ou
#'   `"OCR"`), `qrcode` (o texto do QR-Code, quando a chave veio dele: na NFC-e,
#'   a URL de consulta) e `problema` (vazio quando a chave foi achada).
#' @seealso [chave_valida()], [sefaz_situacao()]
#' @examples
#' \dontrun{
#' chave_extrair(c("danfe.pdf", "cupom.jpg"))
#' sefaz_situacao(chave_extrair("cupom.jpg")$chave, "empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
chave_extrair = function(arquivos, ocr = TRUE) {
  if (!isTRUE(ocr) && !isFALSE(ocr)) {
    stop("Informe ocr = TRUE ou ocr = FALSE.", call. = FALSE)
  }
  linhas = list()
  for (arquivo in as.character(arquivos)) {
    # Um arquivo que não abre (um PDF estragado, uma imagem corrompida) vira uma linha com o motivo; os outros seguem.
    linhas[[length(linhas) + 1]] = tryCatch(
      chaves_do_arquivo(arquivo, ocr),
      error = function(erro) linha_da_extracao(arquivo, NA_character_, NA_character_,
                                               paste("o arquivo n\u00e3o abriu:", conditionMessage(erro)))
    )
  }
  if (length(linhas) == 0) {
    return(data.frame(arquivo = character(), chave = character(), origem = character(), qrcode = character(),
                      problema = character()))
  }
  do.call(rbind, linhas)
}

# As linhas de um arquivo: as chaves achadas pelo primeiro jeito que acha, ou uma linha com o problema.
chaves_do_arquivo = function(arquivo, ocr) {
  if (is.na(arquivo) || !file.exists(arquivo) || dir.exists(arquivo)) {
    return(linha_da_extracao(arquivo, NA_character_, NA_character_, "arquivo n\u00e3o encontrado"))
  }
  extensao = tolower(tools::file_ext(arquivo))
  if (!(extensao %in% c("pdf", EXTENSOES_DE_IMAGEM))) {
    return(linha_da_extracao(arquivo, NA_character_, NA_character_, "n\u00e3o \u00e9 PDF nem imagem"))
  }
  que_nao_conferem = character()
  pulados = character()
  imagens = arquivo
  if (extensao == "pdf") {
    if (!requireNamespace("pdftools", quietly = TRUE)) {
      return(linha_da_extracao(arquivo, NA_character_, NA_character_, "para ler PDF, instale o pacote pdftools"))
    }
    achadas = chaves_no_texto(paste(pdftools::pdf_text(arquivo), collapse = "\n"))
    if (length(achadas$validas) > 0) {
      return(linha_da_extracao(arquivo, achadas$validas, "texto do PDF", NA_character_))
    }
    que_nao_conferem = c(que_nao_conferem, achadas$que_nao_conferem)
    # Sem texto (um PDF de foto ou de digitalização), as páginas viram imagens.
    imagens = file.path(tempdir(), paste0("rnfe_pagina_", seq_len(pdftools::pdf_info(arquivo)$pages), "_", basename(tempfile()), ".png"))
    pdftools::pdf_convert(arquivo, format = "png", dpi = RESOLUCAO_DA_PAGINA, filenames = imagens, verbose = FALSE)
    on.exit(unlink(imagens), add = TRUE)
  }
  # O opencv e o tesseract leem só a primeira página de um TIFF: com o magick, cada página vira uma imagem.
  if (extensao %in% c("tif", "tiff")) {
    if (requireNamespace("magick", quietly = TRUE)) {
      paginas_do_tiff = magick::image_read(arquivo)
      if (length(paginas_do_tiff) > 1) {
        imagens = file.path(tempdir(), paste0("rnfe_pagina_", seq_along(paginas_do_tiff), "_", basename(tempfile()), ".png"))
        for (numero_da_pagina in seq_along(paginas_do_tiff)) {
          magick::image_write(paginas_do_tiff[numero_da_pagina], imagens[numero_da_pagina], format = "png")
        }
        on.exit(unlink(imagens), add = TRUE)
      }
    } else {
      pulados = c(pulados, "as p\u00e1ginas do TIFF depois da primeira (instale o pacote magick)")
    }
  }
  if (requireNamespace("opencv", quietly = TRUE)) {
    chaves_do_qrcode = character()
    textos_do_qrcode = character()
    for (imagem in imagens) {
      textos = as.character(opencv::ocv_qr_detect(opencv::ocv_read(imagem), decoder = "wechat"))
      for (texto in textos) {
        achadas = chaves_no_texto(texto)
        chaves_do_qrcode = c(chaves_do_qrcode, achadas$validas)
        textos_do_qrcode = c(textos_do_qrcode, rep(texto, length(achadas$validas)))
        que_nao_conferem = c(que_nao_conferem, achadas$que_nao_conferem)
      }
    }
    if (length(chaves_do_qrcode) > 0) {
      sem_repetir = !duplicated(chaves_do_qrcode)
      return(linha_da_extracao(arquivo, chaves_do_qrcode[sem_repetir], "QR-Code", NA_character_, textos_do_qrcode[sem_repetir]))
    }
  } else {
    pulados = c(pulados, "o QR-Code (instale o pacote opencv)")
  }
  if (ocr && requireNamespace("tesseract", quietly = TRUE)) {
    motor = tesseract::tesseract("eng")
    chaves_do_ocr = character()
    for (imagem in imagens) {
      achadas = chaves_no_texto(tesseract::ocr(imagem, engine = motor))
      chaves_do_ocr = c(chaves_do_ocr, achadas$validas)
      que_nao_conferem = c(que_nao_conferem, achadas$que_nao_conferem)
    }
    if (length(chaves_do_ocr) > 0) {
      return(linha_da_extracao(arquivo, unique(chaves_do_ocr), "OCR", NA_character_))
    }
  } else if (ocr) {
    pulados = c(pulados, "o OCR (instale o pacote tesseract)")
  }
  problema = "nenhuma chave que confere"
  if (length(que_nao_conferem) > 0) {
    problema = paste0(problema, "; com cara de chave, mas n\u00e3o confere (leitura errada?): ",
                      paste(unique(que_nao_conferem), collapse = ", "))
  }
  if (length(pulados) > 0) {
    problema = paste0(problema, "; ficou de fora ", paste(pulados, collapse = " e "))
  }
  linha_da_extracao(arquivo, NA_character_, NA_character_, problema)
}

# Os números com cara de chave num texto, separados entre os que conferem e os que não. Numa sequência emendada, cada
# janela de 44 posições é uma candidata (um número colado antes da chave não a esconde); numa sequência de blocos de 4,
# cada janela de 11 blocos (um telefone logo antes da chave não a esconde).
chaves_no_texto = function(texto) {
  texto = toupper(gsub("\\s+", " ", paste(texto, collapse = " ")))
  candidatas = character()
  for (sequencia in regmatches(texto, gregexpr("[0-9A-Z]{44,}", texto, perl = TRUE))[[1]]) {
    for (inicio in seq_len(nchar(sequencia) - 43)) {
      candidatas = c(candidatas, substr(sequencia, inicio, inicio + 43))
    }
  }
  for (sequencia in regmatches(texto, gregexpr(SEQUENCIA_DE_BLOCOS, texto, perl = TRUE))[[1]]) {
    blocos = strsplit(sequencia, " ", fixed = TRUE)[[1]]
    for (inicio in seq_len(max(0, length(blocos) - 10))) {
      candidatas = c(candidatas, paste(blocos[inicio:(inicio + 10)], collapse = ""))
    }
  }
  candidatas = unique(candidatas)
  # Os blocos também casam com letras e números quaisquer: só fica o que tem o formato de chave.
  candidatas = candidatas[grepl(paste0("^", CHAVE_EMENDADA, "$"), candidatas)]
  conferem = chave_valida(candidatas)
  list(validas = candidatas[conferem], que_nao_conferem = candidatas[!conferem])
}

linha_da_extracao = function(arquivo, chaves, origem, problema, qrcode = NA_character_) {
  data.frame(arquivo = rep(arquivo, max(1, length(chaves))), chave = chaves, origem = origem, qrcode = qrcode,
             problema = problema)
}
