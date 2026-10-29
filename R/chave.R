# Chave de acesso dos documentos fiscais eletrônicos. A composição vem do Manual de
# Orientação do Contribuinte; as letras no CNPJ e o cálculo com elas, da Nota Técnica
# Conjunta 2025.001 (CNPJ alfanumérico, em produção desde 06/07/2026).

TAMANHO_DA_CHAVE = 44
# Letras só nas 12 primeiras posições do CNPJ (NT 2025.001, item 5).
FORMATO_DA_CHAVE = "^[0-9]{6}[A-Z0-9]{12}[0-9]{26}$"
FORMATO_SEM_DIGITO = "^[0-9]{6}[A-Z0-9]{12}[0-9]{25}$"
# Pesos de 2 a 9 a partir da última posição, recomeçando no 2.
PESOS_DA_CHAVE = rev(rep(2:9, length.out = 43))
PESOS_DO_CNPJ = c(6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2)
# Código do IBGE de cada UF.
UF_PELO_CODIGO = c(
  "11" = "RO", "12" = "AC", "13" = "AM", "14" = "RR", "15" = "PA", "16" = "AP", "17" = "TO",
  "21" = "MA", "22" = "PI", "23" = "CE", "24" = "RN", "25" = "PB", "26" = "PE", "27" = "AL",
  "28" = "SE", "29" = "BA", "31" = "MG", "32" = "ES", "33" = "RJ", "35" = "SP", "41" = "PR",
  "42" = "SC", "43" = "RS", "50" = "MS", "51" = "MT", "52" = "GO", "53" = "DF"
)
DOCUMENTO_PELO_MODELO = c("55" = "NF-e", "65" = "NFC-e", "57" = "CT-e", "67" = "CT-e OS", "58" = "MDF-e")

#' Chave de acesso de documento fiscal eletrônico
#'
#' A chave de 44 posições que identifica uma NF-e, NFC-e, CT-e ou MDF-e. Ela
#' junta, nesta ordem: o código da UF do emitente (2), o ano e o mês de emissão
#' (4), o CNPJ do emitente (14; em alguns documentos, um CPF com três zeros na
#' frente), o modelo (2), a série (3), o número (9), a forma de emissão (1), um
#' código numérico (8) e o dígito verificador (1).
#'
#' Na NF-e avulsa, emitida pelo Fisco (`procEmi` 1 no XML), as posições do CNPJ
#' trazem o CNPJ do órgão que a emitiu, que vem no grupo `avulsa` do XML, e não
#' o do emitente.
#'
#' Desde 06/07/2026 o CNPJ pode ter letras nas 12 primeiras posições (CNPJ
#' alfanumérico). No cálculo dos dígitos, cada caractere vale o seu código ASCII
#' menos 48: os números continuam valendo o mesmo e as letras valem A = 17,
#' B = 18 e assim por diante.
#'
#' - `chave_valida()`: `TRUE` quando a chave tem o formato certo, a UF existe, o
#'   mês vai de 1 a 12, o CNPJ (ou CPF) da chave confere e o dígito verificador
#'   também.
#' - `chave_decompor()`: as partes da chave, uma linha por chave, com o que está
#'   errado em `problema`.
#' - `chave_digito()`: o dígito verificador que a chave deveria ter, calculado
#'   das 43 primeiras posições. Aceita a chave com ou sem o dígito.
#'
#' Espaços, pontos e o prefixo do atributo `Id` do XML (`NFe`, `CTe`, `MDFe`)
#' são ignorados, e letras minúsculas viram maiúsculas.
#'
#' @param chave A chave de acesso (um vetor de texto). Em `chave_digito()`, com
#'   44 posições ou só as 43 primeiras.
#' @return `chave_valida()`: um vetor lógico. `chave_digito()`: um vetor de
#'   inteiros, `NA` quando o texto não tem o formato de chave.
#'   `chave_decompor()`: um `data.frame` com `chave`, `valida`, `problema`,
#'   `codigo_uf`, `uf`, `ano`, `mes`, `documento_emitente` (o CNPJ ou CPF da
#'   chave; na NF-e avulsa, o do órgão do Fisco), `tipo_documento` (`"CNPJ"` ou
#'   `"CPF"`), `modelo`, `documento` (`"NF-e"`, `"NFC-e"`, `"CT-e"`,
#'   `"CT-e OS"` ou `"MDF-e"`; `NA` para outro modelo), `serie`, `numero`,
#'   `forma_emissao`, `codigo_numerico` e `digito`.
#' @source Manual de Orientação do Contribuinte da NF-e (composição da chave) e
#'   Nota Técnica Conjunta 2025.001, versão 1.00 de 25/04/2025 (CNPJ
#'   alfanumérico na chave e no cálculo dos dígitos), do Portal Nacional da NF-e.
#' @examples
#' chave = "35261011444777000161550010000001231123456783"
#' chave_valida(chave)
#' chave_decompor(chave)
#' chave_digito(chave)
#'
#' # CNPJ alfanumérico (o exemplo da Receita Federal, 12.ABC.345/01DE-35)
#' chave_decompor("35261012ABC34501DE35550010000001231123456784")
#' @name chave
NULL

#' @rdname chave
#' @export
chave_valida = function(chave) {
  chave_decompor(chave)$valida
}

#' @rdname chave
#' @export
chave_digito = function(chave) {
  chave = limpar_chave(chave)
  inteira = !is.na(chave) & grepl(FORMATO_DA_CHAVE, chave)
  sem_digito = !is.na(chave) & grepl(FORMATO_SEM_DIGITO, chave)
  chave[inteira] = substr(chave[inteira], 1, 43)
  digitos = rep(NA_integer_, length(chave))
  digitos[inteira | sem_digito] = digitos_das_chaves(chave[inteira | sem_digito])
  digitos
}

#' @rdname chave
#' @export
chave_decompor = function(chave) {
  chave = limpar_chave(chave)
  no_formato = !is.na(chave) & grepl(FORMATO_DA_CHAVE, chave)
  pedaco = function(inicio, fim) {
    partes = rep(NA_character_, length(chave))
    partes[no_formato] = substr(chave[no_formato], inicio, fim)
    partes
  }
  codigo_uf = pedaco(1, 2)
  mes = as.integer(pedaco(5, 6))
  documento_emitente = pedaco(7, 20)
  modelo = pedaco(21, 22)
  digito = as.integer(pedaco(44, 44))
  tipo_documento = tipo_do_documento(documento_emitente)
  digito_certo = rep(NA_integer_, length(chave))
  digito_certo[no_formato] = digitos_das_chaves(substr(chave[no_formato], 1, 43))

  problema = rep(NA_character_, length(chave))
  problema[!no_formato] = vapply(chave[!no_formato], problema_de_formato, character(1), USE.NAMES = FALSE)
  problema = juntar_problema(
    problema, no_formato & !(codigo_uf %in% names(UF_PELO_CODIGO)),
    paste0("c\u00f3digo de UF desconhecido: ", codigo_uf)
  )
  problema = juntar_problema(
    problema, no_formato & (mes < 1 | mes > 12),
    paste0("m\u00eas de emiss\u00e3o inv\u00e1lido: ", mes)
  )
  problema = juntar_problema(
    problema, no_formato & is.na(tipo_documento),
    "o CNPJ (ou CPF) do emitente n\u00e3o confere"
  )
  problema = juntar_problema(
    problema, no_formato & digito != digito_certo,
    paste0("o d\u00edgito verificador n\u00e3o confere: \u00e9 ", digito, ", deveria ser ", digito_certo)
  )

  data.frame(
    chave = chave,
    valida = no_formato & is.na(problema),
    problema = problema,
    codigo_uf = codigo_uf,
    uf = unname(UF_PELO_CODIGO[codigo_uf]),
    ano = 2000L + as.integer(pedaco(3, 4)),
    mes = mes,
    documento_emitente = documento_emitente,
    tipo_documento = tipo_documento,
    modelo = modelo,
    documento = unname(DOCUMENTO_PELO_MODELO[modelo]),
    serie = as.integer(pedaco(23, 25)),
    numero = as.integer(pedaco(26, 34)),
    forma_emissao = as.integer(pedaco(35, 35)),
    codigo_numerico = pedaco(36, 43),
    digito = digito
  )
}

limpar_chave = function(chave) {
  chave = toupper(as.character(chave))
  chave = gsub("[^A-Z0-9]", "", chave)
  # A chave sempre começa por 6 números; letras antes disso são o prefixo do Id do XML.
  sub("^[A-Z]+", "", chave)
}

problema_de_formato = function(chave) {
  if (is.na(chave) || nchar(chave) == 0) {
    return("chave vazia")
  }
  if (nchar(chave) != TAMANHO_DA_CHAVE) {
    return(paste0("a chave tem ", nchar(chave), " posi\u00e7\u00f5es; deveria ter ", TAMANHO_DA_CHAVE))
  }
  "letra fora do CNPJ: s\u00f3 as posi\u00e7\u00f5es 7 a 18 podem ter letras"
}

# Acrescenta o texto ao problema de cada chave marcada em `onde`, separado por "; ".
juntar_problema = function(problema, onde, texto) {
  onde = onde %in% TRUE
  texto = rep_len(texto, length(problema))
  ja_tem = onde & !is.na(problema)
  so_este = onde & is.na(problema)
  problema[ja_tem] = paste0(problema[ja_tem], "; ", texto[ja_tem])
  problema[so_este] = texto[so_este]
  problema
}

# Uma linha por texto, uma coluna por caractere (todos os textos com a mesma largura). Cada
# caractere vale o código ASCII menos 48 (NT 2025.001): "0" a "9" valem 0 a 9, "A" vale 17.
valores_dos_caracteres = function(textos, largura) {
  matrix(utf8ToInt(paste(textos, collapse = "")) - 48L, ncol = largura, byrow = TRUE)
}

# Resto 0 ou 1 dá dígito 0.
digito_modulo_11 = function(soma) {
  resto = soma %% 11
  digito = as.integer(11 - resto)
  digito[resto < 2] = 0L
  digito
}

digitos_das_chaves = function(primeiras_43) {
  valores = valores_dos_caracteres(primeiras_43, 43)
  digito_modulo_11(as.vector(valores %*% PESOS_DA_CHAVE))
}

cnpj_confere = function(cnpj) {
  confere = rep(FALSE, length(cnpj))
  no_formato = !is.na(cnpj) & grepl("^[A-Z0-9]{12}[0-9]{2}$", cnpj) & cnpj != strrep("0", 14)
  if (any(no_formato)) {
    valores = valores_dos_caracteres(substr(cnpj[no_formato], 1, 12), 12)
    primeiro = digito_modulo_11(as.vector(valores %*% PESOS_DO_CNPJ[2:13]))
    segundo = digito_modulo_11(as.vector(cbind(valores, primeiro) %*% PESOS_DO_CNPJ))
    confere[no_formato] = substr(cnpj[no_formato], 13, 14) == paste0(primeiro, segundo)
  }
  confere
}

cpf_confere = function(cpf) {
  confere = rep(FALSE, length(cpf))
  # Números com os 11 dígitos iguais passam no cálculo, mas não são CPF.
  no_formato = !is.na(cpf) & grepl("^[0-9]{11}$", cpf) & !grepl("^(.)\\1{10}$", cpf, perl = TRUE)
  if (any(no_formato)) {
    valores = valores_dos_caracteres(substr(cpf[no_formato], 1, 9), 9)
    primeiro = digito_modulo_11(as.vector(valores %*% (10:2)))
    segundo = digito_modulo_11(as.vector(cbind(valores, primeiro) %*% (11:2)))
    confere[no_formato] = substr(cpf[no_formato], 10, 11) == paste0(primeiro, segundo)
  }
  confere
}

# Na chave, o CPF ocupa as 14 posições do CNPJ com três zeros na frente. Se o número servir
# como CNPJ, fica CNPJ.
tipo_do_documento = function(documento) {
  tipo = rep(NA_character_, length(documento))
  e_cpf = !is.na(documento) & startsWith(documento, "000") & cpf_confere(substr(documento, 4, 14))
  tipo[e_cpf] = "CPF"
  tipo[cnpj_confere(documento)] = "CNPJ"
  tipo
}
