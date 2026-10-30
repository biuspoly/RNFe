# Baixa dos portais oficiais os pacotes de schemas que os leitores do RNfe seguem (os de
# ferramentas/schemas_usados.csv) e diz em que pasta ficou cada um. Uso, na raiz do repositório:
#   Rscript ferramentas/baixar_schemas.R [pasta]
# Sem a pasta, baixa numa pasta temporária. Precisa de internet e dos pacotes httr2 e xml2.

source("ferramentas/schemas.R", encoding = "UTF-8")

# Devolve a pasta de cada documento (nfe, cte, mdfe), a que tem o arquivo principal do pacote.
baixar_schemas_usados = function(pasta_dos_schemas) {
  dir.create(pasta_dos_schemas, showWarnings = FALSE, recursive = TRUE)
  pacotes_usados = ler_csv(SCHEMAS_USADOS)
  pasta_de_cada_documento = character()
  for (numero_do_pacote in seq_len(nrow(pacotes_usados))) {
    pacote_usado = pacotes_usados[numero_do_pacote, ]
    pasta_do_pacote = baixar_pacote(pacote_usado$documento, pacote_usado$endereco, pasta_dos_schemas)
    pasta_do_schema = pasta_do_arquivo(pasta_do_pacote, pacote_usado$arquivo_principal)
    if (is.na(pasta_do_schema)) {
      stop("O pacote de ", pacote_usado$documento, " baixado de ", pacote_usado$endereco, " não tem o ",
           pacote_usado$arquivo_principal, call. = FALSE)
    }
    pasta_de_cada_documento[[pacote_usado$documento]] = pasta_do_schema
  }
  pasta_de_cada_documento
}

# Este bloco só roda quando o script é chamado pelo Rscript; quando outro script o carrega com source(), só
# a função acima fica disponível.
if (sys.nframe() == 0) {
  argumentos = commandArgs(trailingOnly = TRUE)
  if (length(argumentos) >= 1) {
    pasta_dos_schemas = argumentos[1]
  } else {
    pasta_dos_schemas = file.path(tempdir(), "schemas")
  }
  pasta_de_cada_documento = baixar_schemas_usados(pasta_dos_schemas)
  for (documento in names(pasta_de_cada_documento)) {
    cat(documento, pasta_de_cada_documento[[documento]], "\n")
  }
}
