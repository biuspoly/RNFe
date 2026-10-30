# O certificado digital A1 (arquivo .pfx ou .p12) que identifica quem fala com a SEFAZ: de quem é e até quando vale.
# Onde fica cada dado segue o DOC-ICP-04 (Requisitos Mínimos para as Políticas de Certificado na ICP-Brasil),
# versão 8.3, do ITI.

#' @include chave.R
NULL

# Os campos otherName da extensão Subject Alternative Name, como vêm no certificado (DER): a etiqueta de OID (06),
# o tamanho (05) e o OID. No de pessoa jurídica, o 2.16.76.1.3.3 traz o CNPJ nas 14 posições; no de pessoa física,
# o 2.16.76.1.3.1 traz a data de nascimento (8 posições) e depois o CPF (11).
OID_DO_CNPJ = as.raw(c(0x06, 0x05, 0x60, 0x4c, 0x01, 0x03, 0x03))
OID_DA_PESSOA_FISICA = as.raw(c(0x06, 0x05, 0x60, 0x4c, 0x01, 0x03, 0x01))

#' Ler certificados digitais A1
#'
#' Abre cada certificado digital A1 (o arquivo `.pfx` ou `.p12`, com a senha)
#' e diz de quem é e até quando vale. Devolve um `data.frame` com uma linha por
#' arquivo: o `titular`, o `documento` dele (CNPJ ou CPF), a autoridade que
#' emitiu (`emissor`), o começo e o fim da validade e quantos dias faltam para
#' vencer. Não fala com a SEFAZ.
#'
#' O CNPJ vem do campo que a ICP-Brasil reserva para ele no certificado de
#' pessoa jurídica (OID 2.16.76.1.3.3), e o CPF, do campo do certificado de
#' pessoa física (OID 2.16.76.1.3.1, depois da data de nascimento). Sem esses
#' campos, vale o número que vem depois de `:` no fim do nome do titular, como
#' os certificados costumam trazer (`EMPRESA DE TESTE LTDA:11222333000181`).
#'
#' Não escreva a senha no script: guarde-a numa variável de ambiente (no
#' arquivo `.Renviron`, por exemplo) e leia com [Sys.getenv()]. O RNfe não
#' grava nem mostra a senha.
#'
#' Precisa do pacote `openssl`.
#'
#' @param arquivos O caminho de cada certificado: um texto ou um vetor.
#' @param senha A senha do certificado: uma para todos ou uma por arquivo.
#' @return Um `data.frame` com `arquivo`, `titular` (o nome, sem o número do
#'   fim), `documento` (o CNPJ ou o CPF), `tipo_documento` (`"CNPJ"` ou
#'   `"CPF"`), `emissor` (a autoridade certificadora), `valido_desde` e
#'   `valido_ate` (data e hora, no horário de Brasília), `dias_para_vencer`,
#'   `vencido` (`TRUE` ou `FALSE`) e `problema` (por que o arquivo não abriu;
#'   vazio quando abriu).
#' @seealso [sefaz_status()], que usa o certificado para falar com a SEFAZ.
#' @source DOC-ICP-04, Requisitos Mínimos para as Políticas de Certificado na
#'   ICP-Brasil, versão 8.3 (Instituto Nacional de Tecnologia da Informação):
#'   os campos 2.16.76.1.3.3 (CNPJ) e 2.16.76.1.3.1 (CPF) da extensão Subject
#'   Alternative Name.
#' @examples
#' \dontrun{
#' certificado_ler("empresa.pfx", Sys.getenv("SENHA_DO_CERTIFICADO"))
#' certificado_ler(list.files("certificados", pattern = "pfx$", full.names = TRUE),
#'                 Sys.getenv("SENHA_DO_CERTIFICADO"))
#' }
#' @export
certificado_ler = function(arquivos, senha) {
  exigir_pacotes("openssl")
  senhas = rep_len(as.character(senha), length(arquivos))
  certificados = list()
  for (posicao in seq_along(arquivos)) {
    certificados[[posicao]] = ler_um_certificado(arquivos[posicao], senhas[posicao])
  }
  if (length(certificados) == 0) {
    certificados_lidos = ler_um_certificado(character(), character())
  } else {
    certificados_lidos = do.call(rbind, certificados)
  }
  # Juntar as linhas tira o fuso das datas: volta o de Brasília.
  attr(certificados_lidos$valido_desde, "tzone") = "America/Sao_Paulo"
  attr(certificados_lidos$valido_ate, "tzone") = "America/Sao_Paulo"
  certificados_lidos
}

ler_um_certificado = function(arquivo, senha) {
  linha = data.frame(
    arquivo = NA_character_, titular = NA_character_, documento = NA_character_, tipo_documento = NA_character_,
    emissor = NA_character_, valido_desde = as.POSIXct(NA), valido_ate = as.POSIXct(NA), dias_para_vencer = NA_integer_,
    vencido = NA, problema = NA_character_
  )
  # Sem arquivo, a tabela vazia com as mesmas colunas.
  if (length(arquivo) == 0) {
    return(linha[0, ])
  }
  linha$arquivo = as.character(arquivo)
  if (!file.exists(arquivo)) {
    linha$problema = "arquivo n\u00e3o encontrado"
    return(linha)
  }
  conteudo = tryCatch(openssl::read_p12(arquivo, password = senha), error = function(erro) erro)
  if (inherits(conteudo, "error") || is.null(conteudo$cert) || is.null(conteudo$key)) {
    linha$problema = "a senha n\u00e3o abre o arquivo, ou ele n\u00e3o \u00e9 um certificado A1 com a chave"
    return(linha)
  }
  nome_do_titular = parte_do_nome(conteudo$cert$subject, "CN")
  documento = documento_do_certificado(openssl::write_der(conteudo$cert), nome_do_titular)
  linha$titular = sub(":[0-9]{11}$|:[0-9]{14}$", "", nome_do_titular)
  linha$documento = documento
  linha$tipo_documento = ifelse(nchar(documento) == 14, "CNPJ", ifelse(nchar(documento) == 11, "CPF", NA_character_))
  linha$emissor = parte_do_nome(conteudo$cert$issuer, "CN")
  linha$valido_desde = data_do_certificado(conteudo$cert$validity[1])
  linha$valido_ate = data_do_certificado(conteudo$cert$validity[2])
  linha$dias_para_vencer = as.integer(floor(difftime(linha$valido_ate, Sys.time(), units = "days")))
  linha$vencido = linha$valido_ate < Sys.time()
  linha
}

# O valor de um atributo do nome do certificado ("CN=EMPRESA LTDA:11222333000181,OU=...,O=ICP-Brasil,C=BR"). Uma
# vírgula dentro do valor vem escapada ("\,").
parte_do_nome = function(nome_distinto, atributo) {
  partes = strsplit(nome_distinto, "(?<!\\\\),", perl = TRUE)[[1]]
  prefixo = paste0(atributo, "=")
  parte = partes[startsWith(trimws(partes), prefixo)]
  if (length(parte) == 0) {
    return(NA_character_)
  }
  gsub("\\\\,", ",", substring(trimws(parte[1]), nchar(prefixo) + 1))
}

# O CNPJ do campo 2.16.76.1.3.3 ou o CPF do 2.16.76.1.3.1; sem eles, o número no fim do nome do titular.
documento_do_certificado = function(certificado_der, nome_do_titular) {
  cnpj = valor_do_outro_nome(certificado_der, OID_DO_CNPJ)
  if (!is.na(cnpj) && grepl("^[0-9]{14}$", cnpj)) {
    return(cnpj)
  }
  pessoa_fisica = valor_do_outro_nome(certificado_der, OID_DA_PESSOA_FISICA)
  if (!is.na(pessoa_fisica) && grepl("^[0-9]{19}", pessoa_fisica)) {
    return(substr(pessoa_fisica, 9, 19))
  }
  numero_no_nome = regmatches(nome_do_titular, regexpr("(?<=:)([0-9]{14}|[0-9]{11})$", nome_do_titular, perl = TRUE))
  if (length(numero_no_nome) == 1) {
    return(numero_no_nome)
  }
  NA_character_
}

# O texto de um otherName: depois do OID vêm o [0] que o envolve (A0, tamanho) e o texto (etiqueta, tamanho,
# conteúdo). Os tamanhos destes campos cabem num byte (forma curta do DER).
valor_do_outro_nome = function(certificado_der, oid) {
  tamanho_do_oid = length(oid)
  ultima_posicao = length(certificado_der) - tamanho_do_oid - 4
  for (posicao in seq_len(max(ultima_posicao, 0))) {
    if (!identical(certificado_der[posicao:(posicao + tamanho_do_oid - 1)], oid)) {
      next
    }
    depois_do_oid = posicao + tamanho_do_oid
    if (certificado_der[depois_do_oid] != as.raw(0xa0)) {
      next
    }
    tamanho_do_texto = as.integer(certificado_der[depois_do_oid + 3])
    inicio_do_texto = depois_do_oid + 4
    if (tamanho_do_texto == 0 || tamanho_do_texto >= 128 || inicio_do_texto + tamanho_do_texto - 1 > length(certificado_der)) {
      next
    }
    return(rawToChar(certificado_der[inicio_do_texto:(inicio_do_texto + tamanho_do_texto - 1)]))
  }
  NA_character_
}

# A validade vem como "Mar 20 14:10:00 2027 GMT": o mês em inglês, que month.abb tem em qualquer idioma do R.
data_do_certificado = function(texto_da_data) {
  partes = strsplit(trimws(gsub("\\s+", " ", texto_da_data)), " ")[[1]]
  instante = as.POSIXct(
    sprintf("%s-%02d-%02d %s", partes[4], match(partes[1], month.abb), as.integer(partes[2]), partes[3]),
    tz = "UTC"
  )
  attr(instante, "tzone") = "America/Sao_Paulo"
  instante
}

# Os pacotes que só a parte de certificado e SEFAZ usa (ficam em Suggests).
exigir_pacotes = function(pacotes) {
  faltando = pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
  if (length(faltando) > 0) {
    stop("Esta fun\u00e7\u00e3o precisa do(s) pacote(s) ", paste(faltando, collapse = ", "), ": install.packages(c(\"",
         paste(faltando, collapse = "\", \""), "\"))", call. = FALSE)
  }
}
