# O DAMDFE em PDF (A4, retrato), pelo modelo do modal rodoviário do Manual de Especificações Técnicas do DAMDFE (MOC
# MDF-e 3.00b, Anexo II, item 2.8.1): o emitente, o QR-Code, a identificação, as quantidades, o código de barras da
# chave na área de 3 x 9 cm, o protocolo, os veículos, os condutores, o vale-pedágio e as observações. Nos outros
# modais, sai o mesmo cabeçalho, sem os quadros do rodoviário.

#' @include pdf_comum.R
NULL

ENDERECO_DA_CONSULTA_DO_MDFE = "http://dfe-portal.svrs.rs.gov.br/MDFe"
NOMES_DOS_MODAIS_DO_MDFE = c("1" = "Rodovi\u00e1rio", "2" = "A\u00e9reo", "3" = "Aquavi\u00e1rio", "4" = "Ferrovi\u00e1rio")

#' DAMDFE em PDF
#'
#' Desenha o DAMDFE (o documento auxiliar do MDF-e) em A4, pelo modelo do
#' Manual de Especificações Técnicas do DAMDFE: o emitente, o QR-Code (o
#' `qrCodMDFe` do XML; sem ele, o endereço da SVRS com a chave e o ambiente), o
#' modelo, a série, o número, a emissão e as UF de carregamento e de
#' descarregamento, as quantidades de CT-e e de NF-e e o peso, o código de
#' barras da chave, o protocolo (ou a emissão em contingência), os veículos e
#' o RNTRC, os condutores, o vale-pedágio e as observações. O MDF-e de
#' homologação leva "EMITIDO EM AMBIENTE DE HOMOLOGAÇÃO - SEM VALOR FISCAL".
#'
#' Precisa do pacote `qrcode`.
#'
#' O MDF-e emitido em contingência (`tpEmis` 2) leva "EMISSÃO EM CONTINGÊNCIA",
#' as chaves dos documentos que ele relaciona e o QR-Code com a assinatura da
#' chave (o parâmetro `sign`, que só sai com o certificado, quando o XML ainda
#' não traz o QR-Code). As observações que não cabem seguem em folhas
#' adicionais.
#'
#' @param xml O MDF-e: o caminho do arquivo ou o texto do XML (o `mdfeProc`,
#'   com o protocolo).
#' @param arquivo O PDF a gravar.
#' @param certificado,senha Só para o MDF-e em contingência sem o QR-Code no
#'   XML: o certificado que assinou o MDF-e e a senha, para assinar a chave.
#' @return O caminho do PDF, invisível.
#' @seealso [sefaz_mdfe_autorizar()], [mdfe_ler()]
#' @source Manual de Orientação do Contribuinte do MDF-e 3.00b, Anexo II:
#'   Manual de Especificações Técnicas do DAMDFE (agosto de 2022), itens 2.3 a
#'   2.8; e a Visão Geral, itens 9.2 (o QR-Code, também o da contingência), 10.1
#'   (o endereço da consulta) e 11.1 (o DAMDFE da contingência).
#' @examples
#' \donttest{
#' if (requireNamespace("qrcode", quietly = TRUE)) {
#'   mdfe = system.file("exemplos", "mdfe_proc_sp.xml", package = "RNFe")
#'   damdfe_pdf(mdfe, file.path(tempdir(), "damdfe.pdf"))
#' }
#' }
#' @export
damdfe_pdf = function(xml, arquivo, certificado = NULL, senha = NULL) {
  exigir_pacotes("qrcode")
  documento = ler_o_xml_para_assinar(xml)
  manifesto = xml2::xml_find_first(documento, "//*[local-name()='MDFe']")
  informacao = xml2::xml_find_first(manifesto, "*[local-name()='infMDFe']")
  if (inherits(informacao, "xml_missing")) {
    stop("O XML n\u00e3o traz um MDF-e (o elemento MDFe com o infMDFe).", call. = FALSE)
  }
  chave = sub("^MDFe", "", xml2::xml_attr(informacao, "Id"))
  ambiente = texto_pelo_caminho(informacao, "ide/tpAmb")
  em_contingencia = identical(texto_pelo_caminho(informacao, "ide/tpEmis"), "2")
  qrcode_do_xml = texto_pelo_caminho(manifesto, "infMDFeSupl/qrCodMDFe")
  if (is.na(qrcode_do_xml)) {
    qrcode_do_xml = paste0("https://dfe-portal.svrs.rs.gov.br/mdfe/qrCode?chMDFe=", chave, "&tpAmb=", ambiente)
    if (em_contingencia) {
      if (is.null(certificado) || is.null(senha)) {
        stop("O MDF-e em conting\u00eancia sem o QR-Code no XML precisa do certificado e da senha (para o sign).",
             call. = FALSE)
      }
      qrcode_do_xml = paste0(qrcode_do_xml, "&sign=", assinatura_da_chave_do_mdfe(chave, certificado, senha))
    }
  }
  protocolo = xml2::xml_find_first(documento, "//*[local-name()='protMDFe']/*[local-name()='infProt']")
  abrir_o_pdf(arquivo, LARGURA_DO_A4, ALTURA_DO_A4)
  on.exit(grDevices::dev.off(), add = TRUE)
  grid::grid.newpage()
  # O rodoviário vem antes do cabeçalho: a altura dele diz quantas linhas do fim (as chaves dos documentos, na
  # contingência, e as observações) cabem na primeira folha, e o cabeçalho mostra o total de folhas.
  y = 11.2
  if (identical(texto_pelo_caminho(informacao, "ide/modal"), "1")) {
    y = desenhar_rodoviario_do_damdfe(informacao, y)
  }
  linhas_do_fim = linhas_do_fim_do_damdfe(informacao, em_contingencia)
  # Duas linhas a menos em cada folha: os títulos são mais altos que as linhas.
  cabem_na_primeira = max(0, floor((ALTURA_DO_A4 - 1.0 - (y + 0.3)) / 0.36) - 2)
  cabem_nas_outras = floor((ALTURA_DO_A4 - 1.0 - 2.45) / 0.36) - 2
  sobra = max(0, length(linhas_do_fim) - cabem_na_primeira)
  total = 1 + ceiling(sobra / cabem_nas_outras)
  desenhar_cabecalho_do_damdfe(informacao, chave, qrcode_do_xml, total)
  desenhar_quantidades_e_protocolo_do_damdfe(informacao, chave, protocolo, ambiente)
  desenhar_linhas_do_fim_do_damdfe(utils::head(linhas_do_fim, cabem_na_primeira), y)
  restantes = linhas_do_fim[-seq_len(min(cabem_na_primeira, length(linhas_do_fim)))]
  folha = 1
  while (length(restantes) > 0) {
    folha = folha + 1
    grid::grid.newpage()
    desenhar_texto(paste0("DAMDFE - continua\u00e7\u00e3o (FL. ", folha, "/", total, ")"), 1.0, 1.0, tamanho = 9, negrito = TRUE)
    desenhar_texto(chave_em_blocos(chave), 1.0, 1.45, tamanho = 8)
    desenhar_linhas_do_fim_do_damdfe(utils::head(restantes, cabem_nas_outras), 2.15)
    restantes = restantes[-seq_len(min(cabem_nas_outras, length(restantes)))]
  }
  invisible(arquivo)
}

# As linhas do fim do DAMDFE: na contingência, as chaves dos documentos que o MDF-e relaciona (o item 11.1 do MOC);
# depois, as observações (do Fisco e do contribuinte). Cada linha é um texto e se é título.
linhas_do_fim_do_damdfe = function(informacao, em_contingencia) {
  linhas = list()
  if (em_contingencia) {
    linhas[[1]] = list(texto = "Documentos do manifesto", titulo = TRUE)
    grupos = c(infCTe = "CT-e", infNFe = "NF-e", infMDFeTransp = "MDF-e")
    campos = c(infCTe = "chCTe", infNFe = "chNFe", infMDFeTransp = "chMDFe")
    for (grupo in names(grupos)) {
      caminho = paste0(".//*[local-name()='infMunDescarga']/*[local-name()='", grupo, "']/*[local-name()='", campos[[grupo]], "']")
      for (chave in xml2::xml_text(xml2::xml_find_all(informacao, caminho))) {
        linhas[[length(linhas) + 1]] = list(texto = paste0(grupos[[grupo]], ": ", chave_em_blocos(chave)), titulo = FALSE)
      }
    }
  }
  observacoes = c(texto_pelo_caminho(informacao, "infAdic/infAdFisco"), texto_pelo_caminho(informacao, "infAdic/infCpl"))
  linhas[[length(linhas) + 1]] = list(texto = "Observa\u00e7\u00f5es", titulo = TRUE)
  for (linha in quebrar_texto(paste(observacoes[!is.na(observacoes)], collapse = "; "), 19, 8)) {
    linhas[[length(linhas) + 1]] = list(texto = linha, titulo = FALSE)
  }
  linhas
}

desenhar_linhas_do_fim_do_damdfe = function(linhas, y) {
  posicao_vertical = y + 0.3
  for (linha in linhas) {
    if (linha$titulo) {
      desenhar_texto(linha$texto, 1.0, posicao_vertical + 0.1, tamanho = 8, negrito = TRUE)
      desenhar_linha(1.0, posicao_vertical + 0.5, 20.0, posicao_vertical + 0.5)
      posicao_vertical = posicao_vertical + 0.6
    } else {
      desenhar_texto(linha$texto, 1.0, posicao_vertical, tamanho = 8)
      posicao_vertical = posicao_vertical + 0.36
    }
  }
}

desenhar_cabecalho_do_damdfe = function(informacao, chave, qrcode, total_de_folhas = 1) {
  nome = texto_pelo_caminho(informacao, "emit/xNome")
  endereco = paste0(texto_pelo_caminho(informacao, "emit/enderEmit/xLgr"), ", ", texto_pelo_caminho(informacao, "emit/enderEmit/nro"))
  cep = texto_pelo_caminho(informacao, "emit/enderEmit/CEP")
  cidade = paste0(texto_pelo_caminho(informacao, "emit/enderEmit/xMun"), " - ", texto_pelo_caminho(informacao, "emit/enderEmit/UF"),
                  ifelse(is.na(cep), "", paste0("   CEP ", cep_formatado(cep))))
  rntrc = texto_pelo_caminho(informacao, "infModal/rodo/infANTT/RNTRC")
  documentos = paste0("CNPJ/CPF: ", documento_formatado(texto_pelo_caminho(informacao, "emit/CNPJ|emit/CPF")),
                      "   IE: ", ifelse(is.na(texto_pelo_caminho(informacao, "emit/IE")), "", texto_pelo_caminho(informacao, "emit/IE")),
                      ifelse(is.na(rntrc), "", paste0("   RNTRC: ", rntrc)))
  desenhar_texto(toupper(nome), 1.0, 1.0, tamanho = 10, negrito = TRUE)
  desenhar_texto(endereco, 1.0, 1.45, tamanho = 8)
  desenhar_texto(cidade, 1.0, 1.80, tamanho = 8)
  desenhar_texto(documentos, 1.0, 2.15, tamanho = 8, negrito = TRUE)
  desenhar_qrcode(qrcode, 16.9, 0.9, 3.1)
  desenhar_texto("DAMDFE - Documento Auxiliar de Manifesto Eletr\u00f4nico de Documentos Fiscais", 1.0, 2.75, tamanho = 9,
                 negrito = TRUE)
  emissao = texto_pelo_caminho(informacao, "ide/dhEmi")
  caixas = list(
    list(1.0, 1.4, "Modelo", texto_pelo_caminho(informacao, "ide/mod")),
    list(2.4, 1.4, "S\u00e9rie", texto_pelo_caminho(informacao, "ide/serie")),
    list(3.8, 2.0, "N\u00famero", texto_pelo_caminho(informacao, "ide/nMDF")),
    list(5.8, 1.0, "FL.", paste0("1/", total_de_folhas)),
    list(6.8, 3.6, "Data e hora de emiss\u00e3o", paste(data_do_xml(emissao), hora_do_xml(emissao))),
    list(10.4, 2.2, "UF carreg.", texto_pelo_caminho(informacao, "ide/UFIni")),
    list(12.6, 2.2, "UF descarreg.", texto_pelo_caminho(informacao, "ide/UFFim"))
  )
  for (caixa in caixas) {
    desenhar_caixa(caixa[[1]], 3.25, caixa[[2]], 0.9, titulo = caixa[[3]], conteudo = caixa[[4]], tamanho_do_titulo = 6,
                   tamanho_do_conteudo = 9, negrito = TRUE)
  }
}

desenhar_quantidades_e_protocolo_do_damdfe = function(informacao, chave, protocolo, ambiente) {
  modal = texto_pelo_caminho(informacao, "ide/modal")
  nome_do_modal = if (!is.na(modal) && modal %in% names(NOMES_DOS_MODAIS_DO_MDFE)) NOMES_DOS_MODAIS_DO_MDFE[[modal]] else modal
  desenhar_texto(paste("Modelo", nome_do_modal, "de Carga"), 1.0, 4.55, tamanho = 10, negrito = TRUE)
  unidade = if (identical(texto_pelo_caminho(informacao, "tot/cUnid"), "02")) "(Ton)" else "(Kg)"
  quantidades = list(
    list(1.0, 2.6, "Qtd. CT-e", texto_pelo_caminho(informacao, "tot/qCTe")),
    list(3.6, 2.6, "Qtd. NF-e", texto_pelo_caminho(informacao, "tot/qNFe")),
    list(6.2, 3.4, paste("Peso total", unidade), numero_brasileiro(as.numeric(texto_pelo_caminho(informacao, "tot/qCarga")), 2, 4))
  )
  for (caixa in quantidades) {
    conteudo = if (is.na(caixa[[4]])) "0" else caixa[[4]]
    desenhar_caixa(caixa[[1]], 5.2, caixa[[2]], 0.9, titulo = caixa[[3]], conteudo = conteudo, tamanho_do_titulo = 6,
                   tamanho_do_conteudo = 9, negrito = TRUE)
  }
  desenhar_texto("CONTROLE DO FISCO", 11.0, 4.55, tamanho = 6)
  # A área de 3 x 9 cm, com a barra entre 1,5 e 2,5 cm de altura.
  desenhar_codigo_de_barras(chave, 11.0, 4.95, 9.0, 1.7)
  desenhar_texto("Protocolo de autoriza\u00e7\u00e3o", 1.0, 7.2, tamanho = 8, negrito = TRUE)
  numero = texto_pelo_caminho(protocolo, "nProt")
  if (identical(texto_pelo_caminho(informacao, "ide/tpEmis"), "2") && is.na(numero)) {
    desenhar_texto("EMISS\u00c3O EM CONTING\u00caNCIA", 1.0, 7.6, tamanho = 9, negrito = TRUE)
  } else if (!is.na(numero)) {
    recebimento = texto_pelo_caminho(protocolo, "dhRecbto")
    desenhar_texto(paste0(numero, " - ", data_do_xml(recebimento), " \u00e0s ", hora_do_xml(recebimento)), 1.0, 7.6, tamanho = 9)
  }
  if (identical(ambiente, "2")) {
    desenhar_texto("EMITIDO EM AMBIENTE DE HOMOLOGA\u00c7\u00c3O - SEM VALOR FISCAL", 10.5, 8.35, tamanho = 9, negrito = TRUE,
                   alinhamento = "centre")
  }
  desenhar_texto("Chave de acesso", 11.0, 7.2, tamanho = 8, negrito = TRUE)
  desenhar_texto(chave_em_blocos(chave), 11.0, 7.6, tamanho = 8)
  desenhar_texto(paste("Consulte em", ENDERECO_DA_CONSULTA_DO_MDFE), 11.0, 7.95, tamanho = 7, negrito = TRUE)
}

# Os veículos (tração e reboques, com o RNTRC do proprietário ou o da ANTT), os condutores e o vale-pedágio; devolve onde
# o próximo quadro começa.
desenhar_rodoviario_do_damdfe = function(informacao, y) {
  rodoviario = xml2::xml_find_first(informacao, "*[local-name()='infModal']/*[local-name()='rodo']")
  rntrc_da_antt = texto_pelo_caminho(rodoviario, "infANTT/RNTRC")
  veiculos = c(xml2::xml_find_all(rodoviario, "*[local-name()='veicTracao']"),
               xml2::xml_find_all(rodoviario, "*[local-name()='veicReboque']"))
  desenhar_texto("Ve\u00edculo", 1.0, y - 2.0, tamanho = 10, negrito = TRUE)
  desenhar_texto("Placa", 1.0, y - 1.5, tamanho = 7)
  desenhar_texto("RNTRC", 3.6, y - 1.5, tamanho = 7)
  desenhar_linha(1.0, y - 1.15, 9.5, y - 1.15)
  linha = y - 1.05
  for (veiculo in veiculos) {
    rntrc = texto_pelo_caminho(veiculo, "prop/RNTRC")
    desenhar_texto(texto_pelo_caminho(veiculo, "placa"), 1.0, linha, tamanho = 9, negrito = TRUE)
    desenhar_texto(if (is.na(rntrc)) ifelse(is.na(rntrc_da_antt), "", rntrc_da_antt) else rntrc, 3.6, linha, tamanho = 9,
                   negrito = TRUE)
    linha = linha + 0.42
  }
  condutores = xml2::xml_find_all(rodoviario, "*[local-name()='veicTracao']/*[local-name()='condutor']")
  desenhar_texto("Condutor", 11.0, y - 2.0, tamanho = 10, negrito = TRUE)
  desenhar_texto("CPF", 11.0, y - 1.5, tamanho = 7)
  desenhar_texto("Nome", 13.6, y - 1.5, tamanho = 7)
  desenhar_linha(11.0, y - 1.15, 20.0, y - 1.15)
  linha_dos_condutores = y - 1.05
  for (condutor in condutores) {
    desenhar_texto(documento_formatado(texto_pelo_caminho(condutor, "CPF")), 11.0, linha_dos_condutores, tamanho = 9, negrito = TRUE)
    desenhar_texto(texto_pelo_caminho(condutor, "xNome"), 13.6, linha_dos_condutores, tamanho = 9, negrito = TRUE)
    linha_dos_condutores = linha_dos_condutores + 0.42
  }
  linha = max(linha, linha_dos_condutores) + 0.3
  pedagios = xml2::xml_find_all(rodoviario, "*[local-name()='infANTT']/*[local-name()='valePed']/*[local-name()='disp']")
  if (length(pedagios) > 0) {
    desenhar_texto("Vale Ped\u00e1gio", 1.0, linha, tamanho = 10, negrito = TRUE)
    desenhar_texto("Respons\u00e1vel CNPJ", 1.0, linha + 0.5, tamanho = 7, negrito = TRUE)
    desenhar_texto("Fornecedor CNPJ", 4.2, linha + 0.5, tamanho = 7, negrito = TRUE)
    desenhar_texto("N\u00ba comprovante", 7.4, linha + 0.5, tamanho = 7, negrito = TRUE)
    linha = linha + 0.9
    for (pedagio in pedagios) {
      desenhar_texto(documento_formatado(texto_pelo_caminho(pedagio, "CNPJPg|CPFPg")), 1.0, linha, tamanho = 7)
      desenhar_texto(documento_formatado(texto_pelo_caminho(pedagio, "CNPJForn")), 4.2, linha, tamanho = 7)
      desenhar_texto(texto_pelo_caminho(pedagio, "nCompra"), 7.4, linha, tamanho = 7)
      linha = linha + 0.36
    }
  }
  linha + 0.2
}
