# Baixa dos portais oficiais os pacotes de schemas que os leitores do RNfe seguem (os de
# ferramentas/schemas_usados.csv) e diz em que pasta ficou cada um. Uso, na raiz do repositório:
#   Rscript ferramentas/baixar_schemas.R [pasta]
# Sem a pasta, baixa numa pasta temporária. Precisa de internet e dos pacotes httr2 e xml2.

source("ferramentas/schemas.R", encoding = "UTF-8")

# Devolve a pasta de cada documento (nfe, cte, mdfe), a que tem o arquivo principal do pacote.
baixar_schemas_usados = function(pasta) {
  dir.create(pasta, showWarnings = FALSE, recursive = TRUE)
  usados = ler_csv(SCHEMAS_USADOS)
  pastas = character()
  for (numero_da_linha in seq_len(nrow(usados))) {
    usado = usados[numero_da_linha, ]
    pasta_do_pacote = baixar_pacote(usado$documento, usado$endereco, pasta)
    pasta_do_schema = pasta_do_arquivo(pasta_do_pacote, usado$arquivo_principal)
    if (is.na(pasta_do_schema)) {
      stop("O pacote de ", usado$documento, " baixado de ", usado$endereco, " não tem o ", usado$arquivo_principal, call. = FALSE)
    }
    pastas[[usado$documento]] = pasta_do_schema
  }
  pastas
}

if (sys.nframe() == 0) {
  argumentos = commandArgs(trailingOnly = TRUE)
  if (length(argumentos) >= 1) {
    pasta = argumentos[1]
  } else {
    pasta = file.path(tempdir(), "schemas")
  }
  pastas = baixar_schemas_usados(pasta)
  for (documento in names(pastas)) {
    cat(documento, pastas[[documento]], "\n")
  }
}
