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

#' Conferir chaves de acesso
#'
#' Diz se cada chave de acesso de 44 posições (NF-e, NFC-e, CT-e, CT-e OS ou
#' MDF-e) está certa: `TRUE` ou `FALSE`, uma resposta por chave. Confere, como a
#' SEFAZ, o formato, a UF, o mês, o CNPJ (ou CPF) do emitente que vai dentro da
#' chave e o dígito verificador. Para saber o que está errado, use
#' [chave_decompor()].
#'
#' Espaços, pontos e o prefixo do atributo `Id` do XML (`NFe`, `CTe`, `MDFe`)
#' são ignorados, e letras minúsculas viram maiúsculas. O CNPJ com letras (CNPJ
#' alfanumérico, desde 06/07/2026) é aceito. A chave de 50 posições da NFS-e
#' Nacional não é conferida: a regra do dígito dela não está escrita nas fontes
#' oficiais.
#'
#' @param chaves As chaves de acesso: um texto ou um vetor com várias (por
#'   exemplo, a coluna `chave` que vem de [nfe_ler()]).
#' @return Um vetor lógico, um valor por chave.
#' @seealso [chave_decompor()] para as partes da chave e o problema;
#'   [chave_digito()] para calcular o dígito.
#' @source Manual de Orientação do Contribuinte da NF-e (composição da chave) e
#'   Nota Técnica Conjunta 2025.001, versão 1.00 de 25/04/2025 (CNPJ
#'   alfanumérico), do Portal Nacional da NF-e.
#' @examples
#' chave_valida("35261011444777000161550010000001231123456783")   # TRUE
#' chave_valida("35261011444777000161550010000001231123456780")   # FALSE: o dígito não confere
#' chave_valida(c("35261012ABC34501DE35550010000001231123456784", "123"))
#' @export
chave_valida = function(chaves) {
  chave_decompor(chaves)$valida
}

#' Calcular o dígito verificador da chave de acesso
#'
#' Calcula o dígito verificador (a última posição, de 0 a 9) que cada chave de
#' acesso deveria ter, a partir das 43 primeiras posições. Aceita a chave
#' inteira (44 posições) ou sem o dígito (43) e devolve um número por chave, ou
#' `NA` quando o texto não tem o formato de chave. Serve para completar uma
#' chave montada à mão ou para achar o dígito certo de uma chave errada.
#'
#' O dígito é o módulo 11 com pesos de 2 a 9 a partir da direita (resto 0 ou 1
#' dá dígito 0). Cada caractere vale o seu código ASCII menos 48: os números
#' valem o mesmo, e as letras do CNPJ alfanumérico valem A = 17, B = 18 e assim
#' por diante.
#'
#' @param chaves As chaves de acesso, com 44 posições ou só as 43 primeiras: um
#'   texto ou um vetor com várias.
#' @return Um vetor de inteiros, um por chave.
#' @seealso [chave_valida()], [chave_decompor()]
#' @source Manual de Orientação do Contribuinte da NF-e e Nota Técnica Conjunta
#'   2025.001, versão 1.00 de 25/04/2025, do Portal Nacional da NF-e.
#' @examples
#' chave_digito("3526101144477700016155001000000123112345678")    # 3, sem o dígito
#' chave_digito("35261011444777000161550010000001231123456789")   # 3: a chave deveria terminar em 3
#' @export
chave_digito = function(chaves) {
  chaves_limpas = limpar_chaves(chaves)
  chave_inteira = !is.na(chaves_limpas) & grepl(FORMATO_DA_CHAVE, chaves_limpas)
  chave_sem_digito = !is.na(chaves_limpas) & grepl(FORMATO_SEM_DIGITO, chaves_limpas)
  chaves_limpas[chave_inteira] = substr(chaves_limpas[chave_inteira], 1, 43)
  digitos_calculados = rep(NA_integer_, length(chaves_limpas))
  da_para_calcular = chave_inteira | chave_sem_digito
  digitos_calculados[da_para_calcular] = digitos_das_chaves(chaves_limpas[da_para_calcular])
  digitos_calculados
}

#' Desmontar chaves de acesso
#'
#' Separa cada chave de acesso de 44 posições nas partes dela e diz o que está
#' errado. Devolve um `data.frame` com uma linha por chave: `valida` (`TRUE` ou
#' `FALSE`), `problema` (o que não confere), a `uf`, o `ano` e o `mes` de
#' emissão, o CNPJ ou CPF do emitente (`documento_emitente`), o `modelo` e o
#' nome do `documento` (NF-e, NFC-e, CT-e, CT-e OS ou MDF-e), a `serie`, o
#' `numero`, a `forma_emissao`, o `codigo_numerico` e o `digito`.
#'
#' A chave junta, nesta ordem: o código da UF do emitente (2 posições), o ano e
#' o mês de emissão (4), o CNPJ do emitente (14; em alguns documentos, um CPF
#' com três zeros na frente), o modelo (2), a série (3), o número (9), a forma
#' de emissão (1), um código numérico (8) e o dígito verificador (1).
#'
#' Na NF-e avulsa, emitida pelo Fisco (`procEmi` 1 no XML), as posições do CNPJ
#' trazem o CNPJ do órgão que a emitiu, que vem no grupo `avulsa` do XML, e não
#' o do emitente.
#'
#' Desde 06/07/2026 o CNPJ pode ter letras nas 12 primeiras posições (CNPJ
#' alfanumérico). Espaços, pontos e o prefixo do atributo `Id` do XML (`NFe`,
#' `CTe`, `MDFe`) são ignorados, e letras minúsculas viram maiúsculas.
#'
#' @param chaves As chaves de acesso: um texto ou um vetor com várias.
#' @return Um `data.frame` com `chave`, `valida`, `problema`, `codigo_uf`,
#'   `uf`, `ano`, `mes`, `documento_emitente` (o CNPJ ou CPF da chave; na NF-e
#'   avulsa, o do órgão do Fisco), `tipo_documento` (`"CNPJ"` ou `"CPF"`),
#'   `modelo`, `documento` (`"NF-e"`, `"NFC-e"`, `"CT-e"`, `"CT-e OS"` ou
#'   `"MDF-e"`; `NA` para outro modelo), `serie`, `numero`, `forma_emissao`,
#'   `codigo_numerico` e `digito`. Chave com o formato errado fica com as partes
#'   vazias (`NA`) e o motivo em `problema`.
#' @seealso [chave_valida()], [chave_digito()]
#' @source Manual de Orientação do Contribuinte da NF-e (composição da chave) e
#'   Nota Técnica Conjunta 2025.001, versão 1.00 de 25/04/2025 (CNPJ
#'   alfanumérico na chave e no cálculo dos dígitos), do Portal Nacional da NF-e.
#' @examples
#' chave_decompor("35261011444777000161550010000001231123456783")
#'
#' # CNPJ alfanumérico (o exemplo da Receita Federal, 12.ABC.345/01DE-35)
#' chave_decompor("35261012ABC34501DE35550010000001231123456784")
#'
#' # O que está errado em cada uma
#' chave_decompor(c("35261011444777000161550010000001231123456780", "3526"))$problema
#' @export
chave_decompor = function(chaves) {
  chaves_limpas = limpar_chaves(chaves)
  formato_certo = !is.na(chaves_limpas) & grepl(FORMATO_DA_CHAVE, chaves_limpas)
  codigo_uf = parte_das_chaves(chaves_limpas, formato_certo, 1, 2)
  mes = as.integer(parte_das_chaves(chaves_limpas, formato_certo, 5, 6))
  documento_emitente = parte_das_chaves(chaves_limpas, formato_certo, 7, 20)
  modelo = parte_das_chaves(chaves_limpas, formato_certo, 21, 22)
  digito = as.integer(parte_das_chaves(chaves_limpas, formato_certo, 44, 44))
  tipo_documento = tipo_do_documento(documento_emitente)
  digito_certo = rep(NA_integer_, length(chaves_limpas))
  digito_certo[formato_certo] = digitos_das_chaves(substr(chaves_limpas[formato_certo], 1, 43))

  problemas = rep(NA_character_, length(chaves_limpas))
  problemas[!formato_certo] = vapply(chaves_limpas[!formato_certo], problema_de_formato, character(1), USE.NAMES = FALSE)
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
    chave = chaves_limpas,
    valida = formato_certo & is.na(problemas),
    problema = problemas,
    codigo_uf = codigo_uf,
    uf = unname(UF_PELO_CODIGO[codigo_uf]),
    ano = 2000L + as.integer(parte_das_chaves(chaves_limpas, formato_certo, 3, 4)),
    mes = mes,
    documento_emitente = documento_emitente,
    tipo_documento = tipo_documento,
    modelo = modelo,
    documento = unname(DOCUMENTO_PELO_MODELO[modelo]),
    serie = as.integer(parte_das_chaves(chaves_limpas, formato_certo, 23, 25)),
    numero = as.integer(parte_das_chaves(chaves_limpas, formato_certo, 26, 34)),
    forma_emissao = as.integer(parte_das_chaves(chaves_limpas, formato_certo, 35, 35)),
    codigo_numerico = parte_das_chaves(chaves_limpas, formato_certo, 36, 43),
    digito = digito
  )
}

# As posições de início a fim de cada chave; NA na chave fora do formato.
parte_das_chaves = function(chaves_limpas, formato_certo, inicio, fim) {
  partes_das_chaves = rep(NA_character_, length(chaves_limpas))
  partes_das_chaves[formato_certo] = substr(chaves_limpas[formato_certo], inicio, fim)
  partes_das_chaves
}

limpar_chaves = function(chaves) {
  chaves_em_maiusculas = toupper(as.character(chaves))
  so_letras_e_numeros = gsub("[^A-Z0-9]", "", chaves_em_maiusculas)
  # A chave sempre começa por 6 números; letras antes disso são o prefixo do Id do XML.
  sub("^[A-Z]+", "", so_letras_e_numeros)
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
tipo_do_documento = function(documento_emitente) {
  tipo_de_cada = rep(NA_character_, length(documento_emitente))
  cpf_certo = !is.na(documento_emitente) & startsWith(documento_emitente, "000") & cpf_confere(substr(documento_emitente, 4, 14))
  tipo_de_cada[cpf_certo] = "CPF"
  tipo_de_cada[cnpj_confere(documento_emitente)] = "CNPJ"
  tipo_de_cada
}
