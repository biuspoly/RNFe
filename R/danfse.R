# O DANFSe v2.0 em PDF (A4, retrato, uma página), pela Nota Técnica SE/CGNFS-e 008/2026: o cabeçalho, os dados da
# NFS-e com o QR-Code da consulta pública, o prestador, o tomador, o destinatário, o intermediário, o serviço, a
# tributação municipal, a federal e a do IBS e da CBS, os totais, as informações complementares e o canhoto, na
# disposição do Anexo I (as posições do item 2.4.5). O bloco que a nota não tem vira uma linha com a frase da NT, e o
# espaço que sobra vai para as informações complementares.

#' @include pdf_comum.R danfe.R nfse_ler.R
NULL

ENDERECO_DA_CONSULTA_DA_NFSE = "https://www.nfse.gov.br/ConsultaPublica/?tpc=1&chave="
COLUNAS_DO_DANFSE = c(0.30, 5.41, 10.51, 15.62)
LARGURA_DA_COLUNA_DO_DANFSE = 5.09
CINZA_DO_DANFSE = grDevices::gray(0.95)
TIPOS_DE_IMUNIDADE_DO_ISSQN = c(
  "0" = "Imunidade (tipo n\u00e3o informado na nota de origem)",
  "1" = "Patrim\u00f4nio, renda ou servi\u00e7os, uns dos outros",
  "2" = "Templos de qualquer culto",
  "3" = "Patrim\u00f4nio, renda ou servi\u00e7os dos partidos pol\u00edticos, entidades sindicais e institui\u00e7\u00f5es sem fins lucrativos",
  "4" = "Livros, jornais, peri\u00f3dicos e o papel destinado a sua impress\u00e3o",
  "5" = "Fonogramas e videofonogramas musicais produzidos no Brasil"
)
SUSPENSOES_DO_ISSQN = c("1" = "Exigibilidade Suspensa por Decis\u00e3o Judicial",
                        "2" = "Exigibilidade Suspensa por Processo Administrativo")
# As descrições do tipo de benefício municipal (o TBMISSQN do leiaute), sem os nomes dos campos que o leiaute cita.
BENEFICIOS_MUNICIPAIS = c("1" = "Isen\u00e7\u00e3o", "2" = "Redu\u00e7\u00e3o da BC em %",
                          "3" = "Redu\u00e7\u00e3o da BC em R$", "4" = "Al\u00edquota Diferenciada")

#' DANFSe em PDF
#'
#' Desenha o DANFSe v2.0 (o documento auxiliar da NFS-e Nacional) em A4, numa
#' página, pela Nota Técnica SE/CGNFS-e 008/2026: o cabeçalho (com "NFS-e SEM
#' VALIDADE JURÍDICA" na Produção Restrita), os dados da NFS-e, o QR-Code da
#' consulta pública, o prestador, o tomador, o destinatário e o intermediário
#' (ou a frase de que a nota não os identifica), o serviço, a tributação
#' municipal, a federal (o PIS e a COFINS próprios até a competência de 2026,
#' pela data em `tabela_fiscal("marcos_ibs_cbs")`) e
#' a do IBS e da CBS, os totais, as informações complementares (com os totais
#' aproximados dos tributos) e o canhoto. O campo sem informação leva um traço.
#' A logomarca da NFS-e não vai: no lugar dela, o texto "NFS-e".
#'
#' Precisa do pacote `qrcode`.
#'
#' @param xml A NFS-e Nacional: o caminho do arquivo ou o texto do XML.
#' @param arquivo O PDF a gravar.
#' @return O caminho do PDF, invisível.
#' @seealso [nfse_ler()], [nfse_emitir()]
#' @source Nota Técnica SE/CGNFS-e 008/2026 (o DANFSe v2.0, 05/05/2026), itens 2.1
#'   a 2.5 e o Anexo I.
#' @examples
#' \donttest{
#' if (requireNamespace("qrcode", quietly = TRUE)) {
#'   nfse = system.file("exemplos", "nfse_sp_v101.xml", package = "RNFe")
#'   danfse_pdf(nfse, file.path(tempdir(), "danfse.pdf"))
#' }
#' }
#' @export
danfse_pdf = function(xml, arquivo) {
  exigir_pacotes("qrcode")
  lida = nfse_ler(xml)
  if (nrow(lida$nfses) == 0) {
    stop("O XML n\u00e3o traz uma NFS-e Nacional: ", lida$arquivos$problema[1], call. = FALSE)
  }
  nota = lida$nfses[1, ]
  documento = ler_o_xml_para_assinar(xml)
  informacao = xml2::xml_find_first(documento, "//*[local-name()='infNFSe']")
  dps = xml2::xml_find_first(informacao, ".//*[local-name()='infDPS']")
  abrir_o_pdf(arquivo, LARGURA_DO_A4, ALTURA_DO_A4, familia = "Helvetica")
  on.exit(grDevices::dev.off(), add = TRUE)
  grid::grid.newpage()
  grid::grid.rect(x = grid::unit(0.30, "cm"), y = grid::unit(ALTURA_DO_A4 - 0.30, "cm"), width = grid::unit(20.40, "cm"),
                  height = grid::unit(ALTURA_DO_A4 - 0.60, "cm"), just = c("left", "top"), gp = grid::gpar(fill = NA, lwd = 1))
  desenhar_cabecalho_do_danfse(nota)
  y = desenhar_dados_da_nfse(nota)
  tomador = pessoa_do_danfse(dps, "toma")
  destinatario = pessoa_do_danfse(dps, "IBSCBS/dest")
  y = desenhar_pessoa_do_danfse("PRESTADOR / FORNECEDOR", pessoa_do_danfse(dps, "prest", nota, informacao), y,
                                "PRESTADOR / FORNECEDOR N\u00c3O IDENTIFICADO NA NFS-e", com_simples = TRUE, nota = nota)
  y = desenhar_pessoa_do_danfse("TOMADOR / ADQUIRENTE", tomador, y,
                                "TOMADOR/ADQUIRENTE DA OPERA\u00c7\u00c3O N\u00c3O IDENTIFICADO NA NFS-e")
  # A nota 3: o indDest 0 diz que o destinatário é o próprio tomador (o leiaute não repete os dados dele).
  if (identical(texto_pelo_caminho(dps, "IBSCBS/indDest"), "0")) {
    y = desenhar_linha_unica_do_danfse("O DESTINAT\u00c1RIO \u00c9 O PR\u00d3PRIO TOMADOR/ADQUIRENTE DA OPERA\u00c7\u00c3O", y)
  } else {
    y = desenhar_pessoa_do_danfse("DESTINAT\u00c1RIO DA OPERA\u00c7\u00c3O", destinatario, y,
                                  "DESTINAT\u00c1RIO DA OPERA\u00c7\u00c3O N\u00c3O IDENTIFICADO NA NFS-e", com_inscricao = FALSE)
  }
  y = desenhar_pessoa_do_danfse("INTERMEDI\u00c1RIO DA OPERA\u00c7\u00c3O", pessoa_do_danfse(dps, "interm"), y,
                                "INTERMEDI\u00c1RIO DA OPERA\u00c7\u00c3O N\u00c3O IDENTIFICADO NA NFS-e")
  y = desenhar_servico_do_danfse(nota, y)
  y = desenhar_tributacao_municipal_do_danfse(nota, dps, informacao, y)
  y = desenhar_tributacao_federal_do_danfse(nota, y)
  y = desenhar_ibs_cbs_do_danfse(nota, dps, informacao, y)
  y = desenhar_totais_do_danfse(nota, y)
  desenhar_informacoes_do_danfse(nota, dps, y)
  desenhar_canhoto_do_danfse(nota)
  invisible(arquivo)
}

# O conteúdo do campo: o texto, ou um traço quando a nota não tem (a nota 12 da NT); corta com reticências no limite.
conteudo_do_danfse = function(texto, limite = NA) {
  if (length(texto) == 0 || is.na(texto) || texto == "") {
    return("-")
  }
  texto = as.character(texto)
  if (!is.na(limite) && nchar(texto) > limite) {
    texto = paste0(substr(texto, 1, limite - 3), "...")
  }
  texto
}

reais_do_danfse = function(valor) {
  if (is.na(valor)) "-" else paste("R$", numero_brasileiro(as.numeric(valor)))
}

percentual_do_danfse = function(valor) {
  if (is.na(valor)) "-" else paste0(numero_brasileiro(as.numeric(valor)), "%")
}

# Um campo do DANFSe: o título (6 pontos, em negrito) e o conteúdo (7 pontos) embaixo, numa linha só.
campo_do_danfse = function(esquerda, superior, largura, altura, titulo, conteudo, sombreado = FALSE, tamanho_do_titulo = 6) {
  if (sombreado) {
    grid::grid.rect(x = grid::unit(esquerda, "cm"), y = grid::unit(ALTURA_DO_A4 - superior, "cm"), width = grid::unit(largura, "cm"),
                    height = grid::unit(altura, "cm"), just = c("left", "top"), gp = grid::gpar(fill = CINZA_DO_DANFSE, col = NA))
  }
  desenhar_texto(titulo, esquerda + 0.1, superior + 0.06, tamanho = tamanho_do_titulo, negrito = TRUE)
  if (!is.null(conteudo)) {
    texto = conteudo
    while (nchar(texto) > 4 && largura_do_texto(texto, 7) > largura - 0.15) {
      texto = paste0(substr(texto, 1, nchar(texto) - 4), "...")
    }
    desenhar_texto(texto, esquerda + 0.1, superior + 0.33, tamanho = 7)
  }
}

# O título de um bloco (7 pontos, caixa alta, sombreado) na primeira coluna da primeira linha, e a linha de cima.
titulo_do_bloco_do_danfse = function(titulo, superior, altura = 0.63) {
  desenhar_linha(0.30, superior, 20.70, superior)
  grid::grid.rect(x = grid::unit(0.30, "cm"), y = grid::unit(ALTURA_DO_A4 - superior, "cm"), width = grid::unit(5.09, "cm"),
                  height = grid::unit(altura, "cm"), just = c("left", "top"), gp = grid::gpar(fill = CINZA_DO_DANFSE, col = NA))
  desenhar_texto(titulo, 0.40, superior + 0.12, tamanho = 7, negrito = TRUE)
}

# O bloco que a nota não tem: uma linha de 0,32 cm com a frase da NT (as notas 2, 3 e 4).
desenhar_linha_unica_do_danfse = function(frase, y) {
  desenhar_linha(0.30, y, 20.70, y)
  grid::grid.rect(x = grid::unit(0.30, "cm"), y = grid::unit(ALTURA_DO_A4 - y, "cm"), width = grid::unit(20.40, "cm"),
                  height = grid::unit(0.32, "cm"), just = c("left", "top"), gp = grid::gpar(fill = CINZA_DO_DANFSE, col = NA))
  desenhar_texto(frase, 0.40, y + 0.06, tamanho = 7, negrito = TRUE)
  y + 0.32
}

desenhar_cabecalho_do_danfse = function(nota) {
  grid::grid.rect(x = grid::unit(0.30, "cm"), y = grid::unit(ALTURA_DO_A4 - 0.30, "cm"), width = grid::unit(20.40, "cm"),
                  height = grid::unit(1.16, "cm"), just = c("left", "top"), gp = grid::gpar(fill = CINZA_DO_DANFSE, lwd = 0.5))
  desenhar_texto("NFS-e", 0.49, 0.50, tamanho = 16, negrito = TRUE)
  desenhar_texto("DANFSe v2.0", 10.50, 0.40, tamanho = 9, negrito = TRUE, alinhamento = "centre")
  desenhar_texto("Documento Auxiliar da NFS-e", 10.50, 0.75, tamanho = 9, negrito = TRUE, alinhamento = "centre")
  if (identical(as.character(nota$ambiente), "2")) {
    grid::grid.text(texto_para_o_pdf("NFS-e SEM VALIDADE JUR\u00cdDICA"), x = grid::unit(10.50, "cm"), y = grid::unit(ALTURA_DO_A4 - 1.10, "cm"),
                    just = c("centre", "top"), gp = grid::gpar(fontsize = 9, fontface = "bold", col = "red"))
  }
  if (!identical(substr(nota$codigo_tributacao_nacional, 1, 2), "99")) {
    desenhar_texto(paste0("Munic\u00edpio: ", conteudo_do_danfse(nota$local_emissao_municipio), " / ",
                          conteudo_do_danfse(nota$emitente_uf)), 15.72, 0.40, tamanho = 8)
  }
  desenhar_texto(paste("Ambiente Gerador:", conteudo_do_danfse(nota$ambiente_gerador_descricao)), 15.72, 0.97, tamanho = 6)
  desenhar_texto(paste("Tipo de Ambiente:", conteudo_do_danfse(nota$ambiente_descricao)), 15.72, 1.22, tamanho = 6)
}

desenhar_dados_da_nfse = function(nota) {
  campo_do_danfse(0.30, 1.48, 15.30, 0.77, "CHAVE DE ACESSO DA NFS-E", nota$chave, tamanho_do_titulo = 7)
  campo_do_danfse(0.30, 2.27, 5.09, 0.67, "N\u00daMERO DA NFS-E", conteudo_do_danfse(nota$numero), tamanho_do_titulo = 7)
  campo_do_danfse(5.41, 2.27, 5.09, 0.67, "COMPET\u00caNCIA DA NFS-E", conteudo_do_danfse(format(nota$competencia, "%d/%m/%Y")),
                  tamanho_do_titulo = 7)
  campo_do_danfse(10.51, 2.27, 5.09, 0.67, "DATA E HORA DA EMISS\u00c3O DA NFS-E",
                  conteudo_do_danfse(format(nota$processamento, "%d/%m/%Y %H:%M:%S", tz = "America/Sao_Paulo")), tamanho_do_titulo = 7)
  campo_do_danfse(0.30, 2.96, 5.09, 0.67, "N\u00daMERO DA DPS", conteudo_do_danfse(nota$numero_dps), tamanho_do_titulo = 7)
  campo_do_danfse(5.41, 2.96, 5.09, 0.67, "S\u00c9RIE DA DPS", conteudo_do_danfse(nota$serie_dps), tamanho_do_titulo = 7)
  campo_do_danfse(10.51, 2.96, 5.09, 0.67, "DATA E HORA DA EMISS\u00c3O DA DPS",
                  conteudo_do_danfse(format(nota$emissao, "%d/%m/%Y %H:%M:%S", tz = "America/Sao_Paulo")), tamanho_do_titulo = 7)
  campo_do_danfse(0.30, 3.65, 5.09, 0.67, "EMITENTE DA NFS-E", conteudo_do_danfse(nota$tipo_emitente_descricao), sombreado = TRUE,
                  tamanho_do_titulo = 7)
  campo_do_danfse(5.41, 3.65, 5.09, 0.67, "SITUA\u00c7\u00c3O DA NFS-E", conteudo_do_danfse(nota$situacao_descricao, 40), tamanho_do_titulo = 7)
  campo_do_danfse(10.51, 3.65, 5.09, 0.67, "FINALIDADE", conteudo_do_danfse(nota$finalidade_descricao, 40), tamanho_do_titulo = 7)
  desenhar_qrcode(paste0(ENDERECO_DA_CONSULTA_DA_NFSE, nota$chave), 17.48, 1.67, 1.52)
  complemento = c("A autenticidade desta NFS-e pode ser verificada", "pela leitura deste c\u00f3digo QR ou pela consulta da",
                  "chave de acesso no portal nacional da NFS-e")
  for (posicao in seq_along(complemento)) {
    desenhar_texto(complemento[posicao], 15.80, 3.36 + (posicao - 1) * 0.22, tamanho = 6)
  }
  4.34
}

# Uma pessoa da DPS (prest, toma, interm ou IBSCBS/dest): o documento, a inscrição municipal, o telefone, o nome, o
# município e a UF, o código IBGE e o CEP, o endereço e o e-mail. NULL quando a nota não a traz. Do prestador que é o
# emitente sem os dados repetidos na DPS, vêm os do emitente.
pessoa_do_danfse = function(dps, grupo, nota = NULL, informacao = NULL) {
  no = xml2::xml_find_first(dps, paste0("./", paste0("*[local-name()='", strsplit(grupo, "/")[[1]], "']", collapse = "/")))
  if (inherits(no, "xml_missing")) {
    return(NULL)
  }
  if (grupo == "prest" && is.na(texto_pelo_caminho(no, "xNome")) && !is.null(informacao)) {
    emitente = xml2::xml_find_first(informacao, "*[local-name()='emit']")
    if (identical(texto_pelo_caminho(emitente, "CNPJ|CPF"), texto_pelo_caminho(no, "CNPJ|CPF"))) {
      no = emitente
    }
  }
  codigo = texto_pelo_caminho(no, "end/endNac/cMun|enderNac/cMun")
  nome_do_municipio = if (is.na(codigo)) texto_pelo_caminho(no, "end/endExt/xCidade") else municipio_com_a_uf(codigo)
  cep = texto_pelo_caminho(no, "end/endNac/CEP|enderNac/CEP")
  codigo_postal_do_exterior = texto_pelo_caminho(no, "end/endExt/cEndPost")
  partes_do_endereco = c(texto_pelo_caminho(no, "end/xLgr|enderNac/xLgr"), texto_pelo_caminho(no, "end/nro|enderNac/nro"),
                         texto_pelo_caminho(no, "end/xCpl|enderNac/xCpl"), texto_pelo_caminho(no, "end/xBairro|enderNac/xBairro"))
  list(documento = texto_pelo_caminho(no, "CNPJ|CPF|NIF"), inscricao = texto_pelo_caminho(no, "IM"),
       telefone = texto_pelo_caminho(no, "fone"), nome = texto_pelo_caminho(no, "xNome"), municipio = nome_do_municipio,
       codigo_e_cep = if (is.na(codigo)) codigo_postal_do_exterior else paste(codigo, "/", cep_do_danfse(cep)),
       endereco = if (all(is.na(partes_do_endereco))) NA_character_ else paste(partes_do_endereco[!is.na(partes_do_endereco)], collapse = ", "),
       email = texto_pelo_caminho(no, "email"))
}

# O CEP na máscara da NT 008 (nn.nnn-nnn).
cep_do_danfse = function(cep) {
  if (is.na(cep)) NA_character_ else sub("^([0-9]{2})([0-9]{3})([0-9]{3})$", "\\1.\\2-\\3", cep)
}

# O município pelo código do IBGE, com a UF ("Fortaleza / CE"); NA quando o código não está na tabela.
municipio_com_a_uf = function(codigo) {
  if (is.na(codigo)) {
    return(NA_character_)
  }
  municipios = tabela_fiscal("municipios")
  posicao = match(codigo, municipios$codigo)
  if (is.na(posicao)) NA_character_ else paste(municipios$nome[posicao], "/", municipios$uf[posicao])
}

desenhar_pessoa_do_danfse = function(titulo, pessoa, y, frase_sem_pessoa, com_inscricao = TRUE, com_simples = FALSE, nota = NULL) {
  if (is.null(pessoa)) {
    return(desenhar_linha_unica_do_danfse(frase_sem_pessoa, y))
  }
  titulo_do_bloco_do_danfse(titulo, y)
  campo_do_danfse(5.41, y, 5.09, 0.63, "CNPJ / CPF / NIF", conteudo_do_danfse(documento_formatado(pessoa$documento)))
  if (com_inscricao) {
    campo_do_danfse(10.51, y, 5.09, 0.63, "Indicador Municipal (Inscri\u00e7\u00e3o)", conteudo_do_danfse(pessoa$inscricao))
  }
  campo_do_danfse(15.62, y, 5.09, 0.63, "Telefone", conteudo_do_danfse(pessoa$telefone))
  campo_do_danfse(0.30, y + 0.64, 10.19, 0.63, "Nome / Nome Empresarial", conteudo_do_danfse(pessoa$nome, 80))
  campo_do_danfse(10.51, y + 0.64, 5.09, 0.63, "Munic\u00edpio / Sigla UF", conteudo_do_danfse(pessoa$municipio, 37))
  campo_do_danfse(15.62, y + 0.64, 5.09, 0.63, "C\u00f3digo IBGE / CEP", conteudo_do_danfse(pessoa$codigo_e_cep))
  campo_do_danfse(0.30, y + 1.30, 10.19, 0.63, "Endere\u00e7o", conteudo_do_danfse(pessoa$endereco, 80))
  campo_do_danfse(10.51, y + 1.30, 10.19, 0.63, "E-mail", conteudo_do_danfse(pessoa$email, 80))
  if (com_simples) {
    campo_do_danfse(0.30, y + 1.94, 5.09, 0.63, "Simples Nacional na Data de Compet\u00eancia",
                    conteudo_do_danfse(nota$prestador_simples_nacional_descricao, 40))
    campo_do_danfse(5.41, y + 1.94, 15.29, 0.63, "Regime de Apura\u00e7\u00e3o Tribut\u00e1ria pelo SN",
                    conteudo_do_danfse(nota$prestador_regime_apuracao_simples_descricao, 80))
    return(y + 2.58)
  }
  y + 1.94
}

desenhar_servico_do_danfse = function(nota, y) {
  titulo_do_bloco_do_danfse("SERVI\u00c7O PRESTADO", y)
  nacional = if (is.na(nota$codigo_tributacao_nacional)) NA_character_ else
    sub("^([0-9]{2})([0-9]{2})([0-9]{2})$", "\\1.\\2.\\3", nota$codigo_tributacao_nacional)
  codigos = c(nacional, nota$codigo_tributacao_municipal)
  campo_do_danfse(5.41, y, 5.09, 0.63, "C\u00f3digo de Tributa\u00e7\u00e3o Nacional / Municipal",
                  conteudo_do_danfse(if (all(is.na(codigos))) NA else paste(codigos[!is.na(codigos)], collapse = " / ")))
  nbs = if (is.na(nota$nbs)) NA_character_ else sub("^([0-9])([0-9]{4})([0-9]{2})([0-9]{2})$", "\\1.\\2.\\3.\\4", nota$nbs)
  campo_do_danfse(10.51, y, 5.09, 0.63, "C\u00f3digo da NBS", conteudo_do_danfse(nbs))
  # O município e a UF (pelo código do IBGE) e, na prestação no exterior, o país (o código ISO de 2 letras).
  local = municipio_com_a_uf(nota$prestacao_codigo_municipio)
  if (is.na(local)) {
    local = nota$prestacao_local
  }
  if (!is.na(nota$prestacao_pais)) {
    local = paste(c(local[!is.na(local)], nota$prestacao_pais), collapse = " / ")
  }
  campo_do_danfse(15.62, y, 5.09, 0.63, "Local da Presta\u00e7\u00e3o / Sigla UF / Pa\u00eds", conteudo_do_danfse(local, 42))
  descricao_do_codigo = if (!is.na(nota$tributacao_municipal)) nota$tributacao_municipal else nota$tributacao_nacional
  desenhar_texto(conteudo_do_danfse(descricao_do_codigo, 170), 0.40, y + 0.70, tamanho = 6)
  linhas = quebrar_texto(conteudo_do_danfse(nota$descricao_servico, 1300), 20.2, 7)
  desenhar_texto("Descri\u00e7\u00e3o do Servi\u00e7o", 0.40, y + 1.05, tamanho = 6, negrito = TRUE)
  for (posicao in seq_along(utils::head(linhas, 12))) {
    desenhar_texto(linhas[posicao], 0.40, y + 1.30 + (posicao - 1) * 0.29, tamanho = 7)
  }
  y + 1.35 + max(1, min(12, length(linhas))) * 0.29 + 0.1
}

desenhar_tributacao_municipal_do_danfse = function(nota, dps, informacao, y) {
  # A nota 4: a operação sem incidência do ISSQN (sem o grupo, ou tribISSQN 4, de não incidência) vira uma linha.
  if (is.na(nota$tributacao_issqn) || nota$tributacao_issqn == 4) {
    return(desenhar_linha_unica_do_danfse("TRIBUTA\u00c7\u00c3O MUNICIPAL (ISSQN) - OPERA\u00c7\u00c3O N\u00c3O SUJEITA AO ISSQN", y))
  }
  titulo_do_bloco_do_danfse("TRIBUTA\u00c7\u00c3O MUNICIPAL (ISSQN)", y)
  campo_do_danfse(5.41, y, 5.09, 0.63, "Tipo de Tributa\u00e7\u00e3o do ISSQN", conteudo_do_danfse(nota$tributacao_issqn_descricao))
  incidencia = municipio_com_a_uf(nota$incidencia_codigo_municipio)
  if (is.na(incidencia)) {
    incidencia = nota$incidencia_municipio
  }
  pais_do_resultado = texto_pelo_caminho(dps, "valores/trib/tribMun/cPaisResult")
  if (!is.na(pais_do_resultado)) {
    incidencia = paste(c(incidencia[!is.na(incidencia)], pais_do_resultado), collapse = " / ")
  }
  campo_do_danfse(10.51, y, 10.19, 0.63, "Munic\u00edpio / Sigla UF / Pa\u00eds de Incid\u00eancia do ISSQN", conteudo_do_danfse(incidencia, 42))
  y = y + 0.64
  imunidade = texto_pelo_caminho(dps, "valores/trib/tribMun/tpImunidade")
  suspensao = texto_pelo_caminho(dps, "valores/trib/tribMun/exigSusp/tpSusp")
  processo = texto_pelo_caminho(dps, "valores/trib/tribMun/exigSusp/nProcesso")
  if (!all(is.na(c(nota$prestador_regime_especial_descricao, imunidade, suspensao, processo)))) {
    campo_do_danfse(0.30, y, 5.09, 0.63, "Regime Especial de Tributa\u00e7\u00e3o do ISSQN",
                    conteudo_do_danfse(nota$prestador_regime_especial_descricao, 27))
    campo_do_danfse(5.41, y, 5.09, 0.63, "Tipo de Imunidade do ISSQN",
                    conteudo_do_danfse(if (is.na(imunidade)) NA else TIPOS_DE_IMUNIDADE_DO_ISSQN[[imunidade]], 40))
    campo_do_danfse(10.51, y, 5.09, 0.63, "Suspens\u00e3o da Exigibilidade do ISSQN",
                    conteudo_do_danfse(if (is.na(suspensao)) NA else SUSPENSOES_DO_ISSQN[[suspensao]], 40))
    campo_do_danfse(15.62, y, 5.09, 0.63, "N\u00famero Processo Suspens\u00e3o", conteudo_do_danfse(processo))
    y = y + 0.64
  }
  beneficio = texto_pelo_caminho(informacao, "valores/tpBM")
  calculo_do_beneficio = c(nota$beneficio_municipal_calculado,
                           as.numeric(texto_pelo_caminho(dps, "valores/trib/tribMun/BM/vRedBCBM")))
  calculo_do_beneficio = calculo_do_beneficio[!is.na(calculo_do_beneficio)][1]
  deducoes = c(as.numeric(texto_pelo_caminho(dps, "valores/vDedRed/vDR")), nota$deducao_calculada,
               as.numeric(texto_pelo_caminho(informacao, "valores/vCalcAjusteBCISSQN")))
  reembolso = as.numeric(texto_pelo_caminho(informacao, "IBSCBS/valores/vCalcReeRepRes"))
  deducoes = c(deducoes[!is.na(deducoes)][1], reembolso)
  total_das_deducoes = if (all(is.na(deducoes))) NA else sum(deducoes, na.rm = TRUE)
  if (!all(is.na(c(beneficio, calculo_do_beneficio, total_das_deducoes, nota$desconto_incondicionado)))) {
    campo_do_danfse(0.30, y, 5.09, 0.63, "Benef\u00edcio Municipal", conteudo_do_danfse(if (is.na(beneficio)) NA else BENEFICIOS_MUNICIPAIS[[beneficio]]))
    campo_do_danfse(5.41, y, 5.09, 0.63, "C\u00e1lculo do BM", reais_do_danfse(calculo_do_beneficio))
    campo_do_danfse(10.51, y, 5.09, 0.63, "Total Dedu\u00e7\u00f5es/Redu\u00e7\u00f5es", reais_do_danfse(total_das_deducoes))
    campo_do_danfse(15.62, y, 5.09, 0.63, "Desconto Incondicionado", reais_do_danfse(nota$desconto_incondicionado))
    y = y + 0.64
  }
  campo_do_danfse(0.30, y, 5.09, 0.63, "BC ISSQN", reais_do_danfse(nota$base_issqn))
  campo_do_danfse(5.41, y, 5.09, 0.63, "Al\u00edquota Aplicada", percentual_do_danfse(nota$aliquota_issqn))
  campo_do_danfse(10.51, y, 5.09, 0.63, "Reten\u00e7\u00e3o do ISSQN", conteudo_do_danfse(nota$retencao_issqn_descricao))
  campo_do_danfse(15.62, y, 5.09, 0.63, "ISSQN Apurado", reais_do_danfse(nota$valor_issqn))
  y + 0.64
}

desenhar_tributacao_federal_do_danfse = function(nota, y) {
  titulo_do_bloco_do_danfse("TRIBUTA\u00c7\u00c3O FEDERAL (EXCETO CBS)", y)
  campo_do_danfse(5.41, y, 5.09, 0.63, "IRRF", reais_do_danfse(nota$valor_retido_irrf))
  campo_do_danfse(10.51, y, 5.09, 0.63, "Contribui\u00e7\u00e3o Previdenci\u00e1ria - Retida", reais_do_danfse(nota$valor_retido_cp))
  campo_do_danfse(15.62, y, 5.09, 0.63, "Contribui\u00e7\u00f5es Sociais - Retidas", reais_do_danfse(nota$valor_retido_csll))
  y = y + 0.64
  # A nota 6: o PIS e a COFINS próprios só até a competência de 2026 (a data vem da tabela dos marcos).
  if (!is.na(nota$competencia) && nota$competencia < marco_da_reforma("danfse_sem_pis_e_cofins_proprios_desde")) {
    campo_do_danfse(0.30, y, 5.09, 0.63, "PIS - D\u00e9bito Apura\u00e7\u00e3o Pr\u00f3pria", reais_do_danfse(nota$valor_pis))
    campo_do_danfse(5.41, y, 5.09, 0.63, "COFINS - D\u00e9bito Apura\u00e7\u00e3o Pr\u00f3pria", reais_do_danfse(nota$valor_cofins))
    campo_do_danfse(10.51, y, 10.19, 0.63, "Descri\u00e7\u00e3o Contrib. Sociais - Retidas",
                    conteudo_do_danfse(nota$retencao_pis_cofins_descricao, 35))
    y = y + 0.64
  }
  y
}

desenhar_ibs_cbs_do_danfse = function(nota, dps, informacao, y) {
  titulo_do_bloco_do_danfse("TRIBUTA\u00c7\u00c3O IBS / CBS", y)
  cst = if (is.na(nota$cst_ibs_cbs)) NA else paste(nota$cst_ibs_cbs, "/", conteudo_do_danfse(nota$classificacao_ibs_cbs))
  campo_do_danfse(5.41, y, 5.09, 0.63, "CST / cClassTrib", conteudo_do_danfse(cst))
  uf_da_incidencia = municipio_com_a_uf(nota$incidencia_ibs_cbs_codigo_municipio)
  uf_da_incidencia = if (is.na(uf_da_incidencia)) NA_character_ else sub("^.* / ", "", uf_da_incidencia)
  partes = c(nota$indicador_operacao, nota$incidencia_ibs_cbs_codigo_municipio, nota$incidencia_ibs_cbs_municipio, uf_da_incidencia)
  campo_do_danfse(10.51, y, 10.19, 0.63,
                  "Indicador de Opera\u00e7\u00e3o / C\u00f3digo IBGE Incid\u00eancia / Munic\u00edpio Incid\u00eancia / Sigla UF",
                  conteudo_do_danfse(if (all(is.na(partes))) NA else paste(partes[!is.na(partes)], collapse = " / "), 56))
  y = y + 0.64
  # O reembolso, repasse ou ressarcimento (vCalcReeRepRes, do leiaute 1.01) virou, no leiaute da NT 009, os dois ajustes
  # da base (vCalcAjusteBCLocImoveis e vCalcAjusteBCIBSCBS); entra o que a nota tiver.
  ajustes = c(texto_pelo_caminho(informacao, "IBSCBS/valores/vCalcReeRepRes"),
              texto_pelo_caminho(informacao, "IBSCBS/valores/vCalcAjusteBCLocImoveis"),
              texto_pelo_caminho(informacao, "IBSCBS/valores/vCalcAjusteBCIBSCBS"))
  exclusoes = c(nota$desconto_incondicionado, as.numeric(ajustes), nota$valor_issqn, nota$valor_pis, nota$valor_cofins)
  reducoes = c(texto_pelo_caminho(informacao, "IBSCBS/valores/uf/pRedAliqUF"), texto_pelo_caminho(informacao, "IBSCBS/valores/mun/pRedAliqMun"),
               texto_pelo_caminho(informacao, "IBSCBS/valores/fed/pRedAliqCBS"))
  campo_do_danfse(0.30, y, 5.09, 0.63, "Exclus\u00f5es e Redu\u00e7\u00f5es da Base de C\u00e1lculo",
                  if (all(is.na(exclusoes))) "-" else reais_do_danfse(sum(as.numeric(exclusoes), na.rm = TRUE)))
  campo_do_danfse(5.41, y, 5.09, 0.63, "Base de C\u00e1lculo Ap\u00f3s Exclus\u00f5es e Redu\u00e7\u00f5es", reais_do_danfse(nota$base_ibs_cbs))
  campo_do_danfse(10.51, y, 5.09, 0.63, "Red. Al\u00edquota IBS / Red. Al\u00edquota CBS",
                  if (all(is.na(reducoes))) "-" else paste(vapply(reducoes, percentual_do_danfse, character(1)), collapse = " / "))
  campo_do_danfse(15.62, y, 5.09, 0.63, "Al\u00edquota - IBS UF / IBS Mun",
                  if (is.na(nota$aliquota_ibs_uf)) "-" else paste(percentual_do_danfse(nota$aliquota_ibs_uf), "/",
                                                                  percentual_do_danfse(nota$aliquota_ibs_municipio)))
  y = y + 0.64
  campo_do_danfse(0.30, y, 5.09, 0.63, "Al\u00edq. Efetiva Municipal - IBS", percentual_do_danfse(nota$aliquota_efetiva_ibs_municipio))
  campo_do_danfse(5.41, y, 5.09, 0.63, "Valor Apurado Municipal - IBS", reais_do_danfse(nota$valor_ibs_municipio))
  campo_do_danfse(10.51, y, 5.09, 0.63, "Al\u00edq. Efetiva Estadual - IBS", percentual_do_danfse(nota$aliquota_efetiva_ibs_uf))
  campo_do_danfse(15.62, y, 5.09, 0.63, "Valor Apurado Estadual - IBS", reais_do_danfse(nota$valor_ibs_uf))
  y = y + 0.64
  campo_do_danfse(0.30, y, 5.09, 0.63, "Valor Total Apurado - IBS", reais_do_danfse(nota$valor_ibs))
  campo_do_danfse(5.41, y, 5.09, 0.63, "Al\u00edquota - CBS", percentual_do_danfse(nota$aliquota_cbs))
  campo_do_danfse(10.51, y, 5.09, 0.63, "Al\u00edquota Efetiva - CBS", percentual_do_danfse(nota$aliquota_efetiva_cbs))
  campo_do_danfse(15.62, y, 5.09, 0.63, "Valor Total Apurado - CBS", reais_do_danfse(nota$valor_cbs))
  y + 0.64
}

desenhar_totais_do_danfse = function(nota, y) {
  titulo_do_bloco_do_danfse("VALOR TOTAL DA NFS-E", y, 0.67)
  campo_do_danfse(5.41, y, 5.09, 0.67, "VALOR DA OPERA\u00c7\u00c3O / SERVI\u00c7O", reais_do_danfse(nota$valor_servico), tamanho_do_titulo = 7)
  campo_do_danfse(10.51, y, 5.09, 0.67, "Desconto Incondicionado", reais_do_danfse(nota$desconto_incondicionado))
  campo_do_danfse(15.62, y, 5.09, 0.67, "Desconto Condicionado", reais_do_danfse(nota$desconto_condicionado))
  y = y + 0.69
  ibs_cbs = if (is.na(nota$valor_ibs) && is.na(nota$valor_cbs)) NA else sum(c(nota$valor_ibs, nota$valor_cbs), na.rm = TRUE)
  campo_do_danfse(0.30, y, 5.09, 0.67, "Total das Reten\u00e7\u00f5es (ISSQN / Federais)", reais_do_danfse(nota$valor_total_retido))
  campo_do_danfse(5.41, y, 5.09, 0.67, "VALOR L\u00cdQUIDO DA NFS-e", reais_do_danfse(nota$valor_liquido), tamanho_do_titulo = 7)
  campo_do_danfse(10.51, y, 5.09, 0.67, "Total do IBS/CBS", reais_do_danfse(ibs_cbs))
  campo_do_danfse(15.62, y, 5.09, 0.67, "VALOR L\u00cdQUIDO DA NFS-e + IBS/CBS", reais_do_danfse(nota$valor_total_com_ibs_cbs),
                  sombreado = TRUE, tamanho_do_titulo = 7)
  y + 0.69
}

# As informações complementares, na ordem da NT e separadas por "|", com a linha dos totais aproximados dos tributos.
desenhar_informacoes_do_danfse = function(nota, dps, y) {
  titulo_do_bloco_do_danfse("INFORMA\u00c7\u00d5ES COMPLEMENTARES", y, 0.39)
  partes = c(
    rotulo_do_danfse("Inf. Cont.:", texto_pelo_caminho(dps, "serv/infoCompl/xInfComp")),
    rotulo_do_danfse("NFS-e Subst.:", texto_pelo_caminho(dps, "subst/chSubstda")),
    rotulo_do_danfse("Doc. Ref.:", texto_pelo_caminho(dps, "serv/infoCompl/docRef")),
    rotulo_do_danfse("Cod. Obra:", texto_pelo_caminho(dps, "serv/obra/cObra")),
    rotulo_do_danfse("Insc. Imob.:", texto_pelo_caminho(dps, "serv/obra/inscImobFisc|IBSCBS/imovel/inscImobFisc")),
    rotulo_do_danfse("Cod. Evt.:", texto_pelo_caminho(dps, "serv/atvEvento/idAtvEvt")),
    rotulo_do_danfse("Doc. Tec.:", texto_pelo_caminho(dps, "serv/infoCompl/idDocTec")),
    rotulo_do_danfse("N\u00fam. Ped.:", texto_pelo_caminho(dps, "serv/infoCompl/xPed")),
    rotulo_do_danfse("Item Ped.:", texto_pelo_caminho(dps, "serv/infoCompl/gItemPed/xItemPed")),
    rotulo_do_danfse("Inf. A. T. Mun.:", nota$outras_informacoes)
  )
  texto = paste(partes[!is.na(partes)], collapse = " | ")
  linhas = quebrar_texto(texto, 20.2, 7)
  limite = floor((28.10 - 0.1 - (y + 0.45) - 0.35) / 0.29)
  for (posicao in seq_along(utils::head(linhas, max(0, limite)))) {
    desenhar_texto(linhas[posicao], 0.40, y + 0.45 + (posicao - 1) * 0.29, tamanho = 7)
  }
  desenhar_texto(texto_dos_tributos_aproximados(dps), 0.40, y + 0.45 + max(0, min(length(linhas), limite)) * 0.29, tamanho = 7)
}

rotulo_do_danfse = function(rotulo, valor) {
  if (is.na(valor)) NA_character_ else paste(rotulo, valor)
}

# A linha fixa dos totais aproximados dos tributos (a nota 10): em reais ou em percentual, como a DPS traz.
texto_dos_tributos_aproximados = function(dps) {
  esferas = c(Federais = "Fed", Estaduais = "Est", Municipais = "Mun")
  partes = character()
  for (esfera in names(esferas)) {
    valor = texto_pelo_caminho(dps, paste0("valores/trib/totTrib/vTotTrib/vTotTrib", esferas[[esfera]]))
    percentual = texto_pelo_caminho(dps, paste0("valores/trib/totTrib/pTotTrib/pTotTrib", esferas[[esfera]]))
    quantia = if (!is.na(valor)) paste("R$", numero_brasileiro(as.numeric(valor))) else
      if (!is.na(percentual)) paste0(numero_brasileiro(as.numeric(percentual)), "%") else "-"
    partes = c(partes, paste0(esfera, ": ", quantia))
  }
  paste0("Totais Aproximados dos Tributos cfe. Lei n\u00ba 12.741/2012: ", paste(partes, collapse = "; "))
}

desenhar_canhoto_do_danfse = function(nota) {
  desenhar_linha(0.30, 28.10, 20.70, 28.10)
  campo_do_danfse(0.30, 28.10, 5.09, 0.67, "DATA CIENTIFICA\u00c7\u00c3O:", NULL, tamanho_do_titulo = 7)
  campo_do_danfse(5.41, 28.10, 5.09, 0.67, "IDENTIFICA\u00c7\u00c3O E ASSINATURA", NULL, tamanho_do_titulo = 7)
  campo_do_danfse(10.51, 28.10, 10.19, 0.67, "N\u00ba NFS-e / CHAVE NFS-e", paste(nota$numero, "/", nota$chave), tamanho_do_titulo = 7)
}
