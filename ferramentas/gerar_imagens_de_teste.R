# Gera as imagens dos testes da chave_extrair() (tests/testthat/documentos), com chaves inventadas (o CNPJ de exemplo
# 11222333000181): o QR-Code de uma NFC-e de PE, um cupom com a chave impressa em blocos de 4 e um com a chave
# impressa errada (um dígito trocado). Precisa do pacote qrcode, que não é do RNFe: só serve para gerar as imagens.
# Uso, na raiz do repositório:
#   Rscript ferramentas/gerar_imagens_de_teste.R

pasta = "tests/testthat/documentos"
dir.create(pasta, showWarnings = FALSE)
CHAVE_DO_CUPOM = "26261011222333000181650010000010011123456789"
URL_DO_QRCODE = paste0("https://nfce.sefaz.pe.gov.br/nfce/consulta?p=", CHAVE_DO_CUPOM,
                       "|2|2|1|ABCDEF0123456789ABCDEF0123456789ABCDEF01")

grDevices::png(file.path(pasta, "qrcode_nfce.png"), width = 400, height = 400)
plot(qrcode::qr_code(URL_DO_QRCODE))
grDevices::dev.off()

# A chave em blocos de 4, em duas linhas, como no cupom; o resto é texto de cupom inventado.
cupom_impresso = function(arquivo, chave) {
  blocos = substring(chave, seq(1, 41, 4), seq(4, 44, 4))
  grDevices::png(arquivo, width = 900, height = 520, bg = "white")
  graphics::par(mar = c(0, 0, 0, 0))
  graphics::plot.new()
  linhas = c("EMPRESA DE TESTE LTDA", "CNPJ 11.222.333/0001-81", "Valor total R$ 115,00",
             "Consulte pela chave de acesso", paste(blocos[1:6], collapse = " "), paste(blocos[7:11], collapse = " "),
             "CONSUMIDOR NAO IDENTIFICADO")
  graphics::text(0.5, seq(0.9, 0.1, length.out = length(linhas)), linhas, cex = 2.2, family = "mono")
  grDevices::dev.off()
}
cupom_impresso(file.path(pasta, "cupom_com_a_chave.png"), CHAVE_DO_CUPOM)
# O último dígito trocado: a chave não confere.
cupom_impresso(file.path(pasta, "cupom_com_a_chave_errada.png"), paste0(substr(CHAVE_DO_CUPOM, 1, 43), "0"))
cat("imagens gravadas em", pasta, "\n")
