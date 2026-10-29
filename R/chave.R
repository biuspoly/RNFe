# Chave de acesso dos documentos fiscais eletrônicos. A composição vem do Manual de
# Orientação do Contribuinte; as letras no CNPJ e o cálculo com elas, da Nota Técnica
# Conjunta 2025.001 (CNPJ alfanumérico, em produção desde 06/07/2026).

TAMANHO_DA_CHAVE = 44
# Letras só nas 12 primeiras posições do CNPJ (NT 2025.001, item 5).
FORMATO_DA_CHAVE = "^[0-9]{6}[A-Z0-9]{12}[0-9]{26}$"
FORMATO_SEM_DIGITO = "^[0-9]{6}[A-Z0-9]{12}[0-9]{25}$"
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
#' Desde 06/07/2026 o CNPJ pode ter letras nas 12 primeiras posições (CNPJ
#' alfanumérico). No cálculo dos dígitos, cada caractere vale o seu código ASCII
#' menos 48: os números continuam valendo o mesmo e as letras valem A = 17,
#' B = 18 e assim por diante.
#'
#' - `chave_valida()`: `TRUE` quando a chave tem o formato certo, a UF existe, o
#'   mês vai de 1 a 12, o CNPJ (ou CPF) do emitente confere e o dígito
#'   verificador também.
#' - `chave_decompor()`: as partes da chave, uma linha por chave, com o que está
#'   errado em `problema`.
#' - `chave_digito()`: o dígito verificador das 43 primeiras posições.
#'
#' Espaços, pontos e o prefixo do atributo `Id` do XML (`NFe`, `CTe`, `MDFe`)
#' são ignorados, e letras minúsculas viram maiúsculas.
#'
#' @param chave A chave de acesso (um vetor de texto).
#' @param primeiras_43 As 43 primeiras posições da chave, sem o dígito.
#' @return `chave_valida()`: um vetor lógico. `chave_digito()`: um vetor de
#'   inteiros, `NA` quando o texto não tem o formato das 43 posições.
#'   `chave_decompor()`: um `data.frame` com `chave`, `valida`, `problema`,
#'   `codigo_uf`, `uf`, `ano`, `mes`, `documento_emitente`, `tipo_documento`
#'   (`"CNPJ"` ou `"CPF"`), `modelo`, `documento` (`"NF-e"`, `"NFC-e"`,
#'   `"CT-e"`, `"CT-e OS"` ou `"MDF-e"`; `NA` para outro modelo), `serie`,
#'   `numero`, `forma_emissao`, `codigo_numerico` e `digito`.
#' @source Manual de Orientação do Contribuinte da NF-e (composição da chave) e
#'   Nota Técnica Conjunta 2025.001, versão 1.00 de 25/04/2025 (CNPJ
#'   alfanumérico na chave e no cálculo dos dígitos), do Portal Nacional da NF-e.
#' @examples
#' chave = "35261011444777000161550010000001231123456783"
#' chave_valida(chave)
#' chave_decompor(chave)
#' chave_digito(substr(chave, 1, 43))
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
chave_digito = function(primeiras_43) {
  primeiras_43 = toupper(as.character(primeiras_43))
  digitos = vapply(primeiras_43, function(texto) {
    if (is.na(texto) || !grepl(FORMATO_SEM_DIGITO, texto)) {
      return(NA_integer_)
    }
    digito_da_chave(texto)
  }, integer(1), USE.NAMES = FALSE)
  digitos
}

#' @rdname chave
#' @export
chave_decompor = function(chave) {
  linhas = lapply(limpar_chave(chave), decompor_uma_chave)
  do.call(rbind, c(list(linha_de_chave(NA_character_)[0, ]), linhas))
}

limpar_chave = function(chave) {
  chave = toupper(as.character(chave))
  chave = gsub("[^A-Z0-9]", "", chave)
  # A chave sempre começa por 6 números; letras antes disso são o prefixo do Id do XML.
  sub("^[A-Z]+", "", chave)
}

decompor_uma_chave = function(chave) {
  if (is.na(chave) || !grepl(FORMATO_DA_CHAVE, chave)) {
    return(linha_de_chave(chave, problema = problema_de_formato(chave)))
  }
  partes = list(
    codigo_uf = substr(chave, 1, 2),
    ano = 2000L + as.integer(substr(chave, 3, 4)),
    mes = as.integer(substr(chave, 5, 6)),
    documento_emitente = substr(chave, 7, 20),
    modelo = substr(chave, 21, 22),
    serie = as.integer(substr(chave, 23, 25)),
    numero = as.integer(substr(chave, 26, 34)),
    forma_emissao = as.integer(substr(chave, 35, 35)),
    codigo_numerico = substr(chave, 36, 43),
    digito = as.integer(substr(chave, 44, 44))
  )
  partes$tipo_documento = tipo_do_documento(partes$documento_emitente)

  problemas = character()
  if (!(partes$codigo_uf %in% names(UF_PELO_CODIGO))) {
    problemas = c(problemas, paste0("c\u00f3digo de UF desconhecido: ", partes$codigo_uf))
  }
  if (partes$mes < 1 || partes$mes > 12) {
    problemas = c(problemas, paste0("m\u00eas de emiss\u00e3o inv\u00e1lido: ", partes$mes))
  }
  if (is.na(partes$tipo_documento)) {
    problemas = c(problemas, "o CNPJ (ou CPF) do emitente n\u00e3o confere")
  }
  digito_certo = digito_da_chave(substr(chave, 1, 43))
  if (partes$digito != digito_certo) {
    problemas = c(problemas, paste0(
      "o d\u00edgito verificador n\u00e3o confere: \u00e9 ", partes$digito, ", deveria ser ", digito_certo
    ))
  }
  problema = if (length(problemas) == 0) NA_character_ else paste(problemas, collapse = "; ")
  linha_de_chave(chave, problema, partes)
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

linha_de_chave = function(chave, problema = NA_character_, partes = list()) {
  valor = function(nome, vazio) {
    if (is.null(partes[[nome]])) vazio else partes[[nome]]
  }
  codigo_uf = valor("codigo_uf", NA_character_)
  modelo = valor("modelo", NA_character_)
  data.frame(
    chave = chave,
    valida = length(partes) > 0 && is.na(problema),
    problema = problema,
    codigo_uf = codigo_uf,
    uf = unname(UF_PELO_CODIGO[codigo_uf]),
    ano = valor("ano", NA_integer_),
    mes = valor("mes", NA_integer_),
    documento_emitente = valor("documento_emitente", NA_character_),
    tipo_documento = valor("tipo_documento", NA_character_),
    modelo = modelo,
    documento = unname(DOCUMENTO_PELO_MODELO[modelo]),
    serie = valor("serie", NA_integer_),
    numero = valor("numero", NA_integer_),
    forma_emissao = valor("forma_emissao", NA_integer_),
    codigo_numerico = valor("codigo_numerico", NA_character_),
    digito = valor("digito", NA_integer_)
  )
}

# Cada caractere vale o código ASCII menos 48 (NT 2025.001): "0" a "9" valem 0 a 9, "A" vale 17.
valores_dos_caracteres = function(texto) {
  utf8ToInt(texto) - 48L
}

digito_modulo_11 = function(soma) {
  resto = soma %% 11
  if (resto < 2) {
    return(0L)
  }
  as.integer(11 - resto)
}

# Pesos de 2 a 9 a partir da última posição, recomeçando no 2; resto 0 ou 1 dá dígito 0.
digito_da_chave = function(primeiras_43) {
  valores = rev(valores_dos_caracteres(primeiras_43))
  pesos = rep(2:9, length.out = length(valores))
  digito_modulo_11(sum(valores * pesos))
}

digitos_do_cnpj = function(primeiros_12) {
  valores = valores_dos_caracteres(primeiros_12)
  primeiro = digito_modulo_11(sum(valores * PESOS_DO_CNPJ[2:13]))
  segundo = digito_modulo_11(sum(c(valores, primeiro) * PESOS_DO_CNPJ))
  paste0(primeiro, segundo)
}

digitos_do_cpf = function(primeiros_9) {
  valores = valores_dos_caracteres(primeiros_9)
  primeiro = digito_modulo_11(sum(valores * 10:2))
  segundo = digito_modulo_11(sum(c(valores, primeiro) * 11:2))
  paste0(primeiro, segundo)
}

cnpj_confere = function(cnpj) {
  if (!grepl("^[A-Z0-9]{12}[0-9]{2}$", cnpj) || cnpj == strrep("0", 14)) {
    return(FALSE)
  }
  substr(cnpj, 13, 14) == digitos_do_cnpj(substr(cnpj, 1, 12))
}

cpf_confere = function(cpf) {
  # Números com os 11 dígitos iguais passam no cálculo, mas não são CPF.
  if (!grepl("^[0-9]{11}$", cpf) || length(unique(strsplit(cpf, "")[[1]])) == 1) {
    return(FALSE)
  }
  substr(cpf, 10, 11) == digitos_do_cpf(substr(cpf, 1, 9))
}

# Na chave, o CPF ocupa as 14 posições do CNPJ com três zeros na frente.
tipo_do_documento = function(documento) {
  if (cnpj_confere(documento)) {
    return("CNPJ")
  }
  if (startsWith(documento, "000") && cpf_confere(substr(documento, 4, 14))) {
    return("CPF")
  }
  NA_character_
}
