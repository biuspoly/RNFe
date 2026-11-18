# A logomarca da NFS-e que o DANFSe leva no canto esquerdo do cabeçalho (NT SE/CGNFS-e 008/2026, item 2.4.3), baixada do
# endereço que a NT dá e gravada em inst/extdata/logo_nfse.rds como uma imagem do R (raster): o pacote a desenha sem
# precisar de outro pacote para ler o PNG. O quadro da NT (4,00 cm por 0,85 cm) é o tamanho mínimo: a imagem vai na
# altura dele, a 300 pontos por polegada, e a largura que a proporção der (a logomarca é mais larga que o quadro).
# Uso, na raiz do repositório (precisa do pacote magick):
#   Rscript ferramentas/gerar_logo_do_danfse.R

ENDERECO_DA_LOGOMARCA = paste0("https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica/logos-da-nfs-e/",
                               "Logo%20-%20NFS-e%20-%20Horizontal.png")
ARQUIVO_DA_LOGOMARCA = "inst/extdata/logo_nfse.rds"
PONTOS_POR_CENTIMETRO = 300 / 2.54
LARGURA_DO_QUADRO = 4.00
ALTURA_DO_QUADRO = 0.85

arquivo_baixado = tempfile(fileext = ".png")
utils::download.file(ENDERECO_DA_LOGOMARCA, arquivo_baixado, mode = "wb", quiet = TRUE)
imagem = magick::image_read(arquivo_baixado)
informacao_do_original = magick::image_info(imagem)
altura_em_pontos = round(ALTURA_DO_QUADRO * PONTOS_POR_CENTIMETRO)
# A altura do quadro, ou a que dá a largura do quadro, o que for maior (o "geometry" do magick mantém a proporção).
altura_pela_largura = ceiling(LARGURA_DO_QUADRO * PONTOS_POR_CENTIMETRO * informacao_do_original$height /
                                informacao_do_original$width)
reduzida = magick::image_scale(imagem, paste0("x", max(altura_em_pontos, altura_pela_largura)))
imagem_do_r = grDevices::as.raster(reduzida)
saveRDS(imagem_do_r, ARQUIVO_DA_LOGOMARCA, compress = "xz")
informacao = magick::image_info(reduzida)
cat("logomarca:", informacao$width, "x", informacao$height, "pontos,", file.size(ARQUIVO_DA_LOGOMARCA), "bytes\n")
