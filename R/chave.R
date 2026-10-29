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
  chave_inteira = !is.na(chave) & grepl(FORMATO_DA_CHAVE, chave)
  chave_sem_digito = !is.na(chave) & grepl(FORMATO_SEM_DIGITO, chave)
  chave[chave_inteira] = substr(chave[chave_inteira], 1, 43)
  digitos_calculados = rep(NA_integer_, length(chave))
  da_para_calcular = chave_inteira | chave_sem_digito
  digitos_calculados[da_para_calcular] = digitos_das_chaves(chave[da_para_calcular])
  digitos_calculados
}

#' @rdname chave
#' @export
chave_decompor = function(chave) {
  chave = limpar_chave(chave)
  formato_certo = !is.na(chave) & grepl(FORMATO_DA_CHAVE, chave)
  # As posi\u00e7\u00f5es de in\u00edcio a fim de cada chave; NA na chave fora do formato.
  parte_da_chave = function(inicio, fim) {
    partes_das_chaves = rep(NA_character_, length(chave))
    partes_das_chaves[formato_certo] = substr(chave[formato_certo], inicio, fim)
    partes_das_chaves
  }
  codigo_uf = parte_da_chave(1, 2)
  mes = as.integer(parte_da_chave(5, 6))
  documento_emitente = parte_da_chave(7, 20)
  modelo = parte_da_chave(21, 22)
  digito = as.integer(parte_da_chave(44, 44))
  tipo_documento = tipo_do_documento(documento_emitente)
  digito_certo = rep(NA_integer_, length(chave))
  digito_certo[formato_certo] = digitos_das_chaves(substr(chave[formato_certo], 1, 43))

  problemas = rep(NA_character_, length(chave))
  problemas[!formato_certo] = vapply(chave[!formato_certo], problema_de_formato, character(1), USE.NAMES = FALSE)
  problemas = juntar_problema(
    problemas, formato_certo & !(codigo_uf %in% names(UF_PELO_CODIGO)),
    paste0("c\u00f3digo de UF desconhecido: ", codigo_uf)
  )
  problemas = juntar_problema(
    problemas, formato_certo & (mes < 1 | mes > 12),
    paste0("m\u00eas de emiss\u00e3o inv\u00e1lido: ", mes)
  )
  problemas = juntar_problema(
    problemas, formato_certo & is.na(tipo_documento),
    "o CNPJ (ou CPF) do emitente n\u00e3o confere"
  )
  problemas = juntar_problema(
    problemas, formato_certo & digito != digito_certo,
    paste0("o d\u00edgito verificador n\u00e3o confere: \u00e9 ", digito, ", deveria ser ", digito_certo)
  )

  data.frame(
    chave = chave,
    valida = formato_certo & is.na(problemas),
    problema = problemas,
    codigo_uf = codigo_uf,
    uf = unname(UF_PELO_CODIGO[codigo_uf]),
    ano = 2000L + as.integer(parte_da_chave(3, 4)),
    mes = mes,
    documento_emitente = documento_emitente,
    tipo_documento = tipo_documento,
    modelo = modelo,
    documento = unname(DOCUMENTO_PELO_MODELO[modelo]),
    serie = as.integer(parte_da_chave(23, 25)),
    numero = as.integer(parte_da_chave(26, 34)),
    forma_emissao = as.integer(parte_da_chave(35, 35)),
    codigo_numerico = parte_da_chave(36, 43),
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

# Acrescenta a descrição ao problema de cada chave que tem o problema, separada por "; ".
juntar_problema = function(problemas, chaves_com_o_problema, descricao_do_problema) {
  chaves_com_o_problema = chaves_com_o_problema %in% TRUE
  descricao_do_problema = rep_len(descricao_do_problema, length(problemas))
  ja_tinha_problema = chaves_com_o_problema & !is.na(problemas)
  primeiro_problema = chaves_com_o_problema & is.na(problemas)
  problemas[ja_tinha_problema] = paste0(problemas[ja_tinha_problema], "; ", descricao_do_problema[ja_tinha_problema])
  problemas[primeiro_problema] = descricao_do_problema[primeiro_problema]
  problemas
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
  valor_de_cada_caractere = valores_dos_caracteres(primeiras_43, 43)
  digito_modulo_11(as.vector(valor_de_cada_caractere %*% PESOS_DA_CHAVE))
}

cnpj_confere = function(cnpj) {
  cnpj_certo = rep(FALSE, length(cnpj))
  formato_de_cnpj = !is.na(cnpj) & grepl("^[A-Z0-9]{12}[0-9]{2}$", cnpj) & cnpj != strrep("0", 14)
  if (any(formato_de_cnpj)) {
    valor_de_cada_caractere = valores_dos_caracteres(substr(cnpj[formato_de_cnpj], 1, 12), 12)
    primeiro_digito = digito_modulo_11(as.vector(valor_de_cada_caractere %*% PESOS_DO_CNPJ[2:13]))
    segundo_digito = digito_modulo_11(as.vector(cbind(valor_de_cada_caractere, primeiro_digito) %*% PESOS_DO_CNPJ))
    cnpj_certo[formato_de_cnpj] = substr(cnpj[formato_de_cnpj], 13, 14) == paste0(primeiro_digito, segundo_digito)
  }
  cnpj_certo
}

cpf_confere = function(cpf) {
  cpf_certo = rep(FALSE, length(cpf))
  # Números com os 11 dígitos iguais passam no cálculo, mas não são CPF.
  formato_de_cpf = !is.na(cpf) & grepl("^[0-9]{11}$", cpf) & !grepl("^(.)\\1{10}$", cpf, perl = TRUE)
  if (any(formato_de_cpf)) {
    valor_de_cada_caractere = valores_dos_caracteres(substr(cpf[formato_de_cpf], 1, 9), 9)
    primeiro_digito = digito_modulo_11(as.vector(valor_de_cada_caractere %*% (10:2)))
    segundo_digito = digito_modulo_11(as.vector(cbind(valor_de_cada_caractere, primeiro_digito) %*% (11:2)))
    cpf_certo[formato_de_cpf] = substr(cpf[formato_de_cpf], 10, 11) == paste0(primeiro_digito, segundo_digito)
  }
  cpf_certo
}

# Na chave, o CPF ocupa as 14 posições do CNPJ com três zeros na frente. Se o número servir
# como CNPJ, fica CNPJ.
tipo_do_documento = function(documento) {
  tipos = rep(NA_character_, length(documento))
  cpf_certo = !is.na(documento) & startsWith(documento, "000") & cpf_confere(substr(documento, 4, 14))
  tipos[cpf_certo] = "CPF"
  tipos[cnpj_confere(documento)] = "CNPJ"
  tipos
}
