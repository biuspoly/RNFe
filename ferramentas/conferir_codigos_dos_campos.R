# Confere a tabela dos códigos dos campos (inst/extdata/tabelas/codigos_dos_campos.csv), escrita à mão a partir da
# documentação dos schemas, contra os schemas oficiais: todo código da tabela tem de ser aceito pelo schema, e todo
# valor que o schema aceita, nos campos que a tabela cobre, tem de ter o significado. Uso, na raiz do repositório:
#   Rscript ferramentas/conferir_codigos_dos_campos.R
#   Rscript ferramentas/conferir_codigos_dos_campos.R nfe=<pasta> cte=<pasta> mdfe=<pasta> nfse=<pasta> nfe_eventos=<pasta>
# Sem argumentos, baixa os pacotes de ferramentas/schemas_usados.csv. Termina com erro quando algo não confere.

source("ferramentas/schemas.R", encoding = "UTF-8")

argumentos = commandArgs(trailingOnly = TRUE)
if (length(argumentos) == 0) {
  source("ferramentas/baixar_schemas.R", encoding = "UTF-8")
  pasta_de_cada_pacote = baixar_schemas_usados(file.path(tempdir(), "schemas"))
} else {
  pasta_de_cada_pacote = sub("^[^=]*=", "", argumentos)
  names(pasta_de_cada_pacote) = sub("=.*$", "", argumentos)
}

# Onde ficam os schemas de cada documento da tabela. A NFS-e tem uma pasta por versão do leiaute (1.00 e 1.01), e
# vale o que qualquer uma aceita.
PASTAS_DE_CADA_DOCUMENTO = list(
  "NF-e" = pasta_de_cada_pacote[["nfe"]],
  "CT-e" = pasta_de_cada_pacote[["cte"]],
  "MDF-e" = pasta_de_cada_pacote[["mdfe"]],
  "NFS-e" = list.dirs(dirname(pasta_de_cada_pacote[["nfse"]]), recursive = FALSE),
  "evento" = pasta_de_cada_pacote[["nfe_eventos"]]
)
# Valores que o schema aceita em grupos que o RNfe não lê: ficam sem significado na tabela de propósito.
VALORES_FORA_DOS_LEITORES = utils::read.table(header = TRUE, stringsAsFactors = FALSE, colClasses = "character", text = "
documento campo codigo grupo
CT-e      tpCTe 4      GTV-e
CT-e      tpCTe 5      CT-e_simplificado
CT-e      tpCTe 6      CT-e_simplificado
CT-e      tpServ 9     GTV-e
")
# Valores de leiaute anterior que o RNfe ainda lê: o CT-e de anulação (tpCTe 2) é do leiaute 3.00. O texto vem da
# documentação do evento EPEC, no pacote do 4.00, que ainda lista o 2.
VALORES_DE_LEIAUTE_ANTERIOR = utils::read.table(header = TRUE, stringsAsFactors = FALSE, colClasses = "character", text = "
documento campo codigo
CT-e      tpCTe 2
")

# Os valores que o schema aceita no campo: em cada pasta, cada declaração do campo, seguindo o tipo nomeado e a base
# da restrição. Cada pasta é lida sozinha, porque as versões da NFS-e repetem os nomes dos tipos. Nos documentos, os
# arquivos de evento ficam de fora: lá o mesmo nome de campo tem outra lista (o cMotivo do cancelamento da NFS-e).
valores_aceitos = function(pastas_do_schema, nome_do_campo, documento) {
  valores = character()
  for (pasta_do_schema in pastas_do_schema) {
    valores = c(valores, valores_aceitos_na_pasta(pasta_do_schema, nome_do_campo, documento))
  }
  unique(valores)
}

valores_aceitos_na_pasta = function(pasta_do_schema, nome_do_campo, documento) {
  arquivos_xsd = list.files(pasta_do_schema, pattern = "\\.xsd$", full.names = TRUE)
  if (documento != "evento") {
    arquivos_xsd = arquivos_xsd[!grepl("^ev|[Ee]vento", basename(arquivos_xsd))]
  }
  tipos_simples = list()
  declaracoes = list()
  for (arquivo_xsd in arquivos_xsd) {
    schema_lido = xml2::read_xml(arquivo_xsd)
    for (tipo in xml2::xml_find_all(schema_lido, "/xs:schema/xs:simpleType[@name]", NAMESPACE_DO_XSD)) {
      tipos_simples[[xml2::xml_attr(tipo, "name")]] = tipo
    }
    declaracoes = c(declaracoes, as.list(xml2::xml_find_all(schema_lido, paste0("//xs:element[@name='", nome_do_campo, "']"), NAMESPACE_DO_XSD)))
  }
  valores = character()
  for (declaracao in declaracoes) {
    restricao = xml2::xml_find_first(declaracao, "xs:simpleType/xs:restriction", NAMESPACE_DO_XSD)
    nome_do_tipo = sem_prefixo(xml2::xml_attr(declaracao, "type"))
    for (passo in 1:10) {
      if (inherits(restricao, "xml_missing") && !is.na(nome_do_tipo) && !is.null(tipos_simples[[nome_do_tipo]])) {
        restricao = xml2::xml_find_first(tipos_simples[[nome_do_tipo]], "xs:restriction", NAMESPACE_DO_XSD)
      }
      if (inherits(restricao, "xml_missing")) {
        break
      }
      enumeracoes = xml2::xml_attr(xml2::xml_find_all(restricao, "xs:enumeration", NAMESPACE_DO_XSD), "value")
      if (length(enumeracoes) > 0) {
        valores = c(valores, enumeracoes)
        break
      }
      nome_do_tipo = sem_prefixo(xml2::xml_attr(restricao, "base"))
      restricao = xml2::xml_missing()
    }
  }
  unique(valores)
}

codigos_dos_campos = utils::read.csv("inst/extdata/tabelas/codigos_dos_campos.csv", colClasses = "character", na.strings = "",
                                     encoding = "UTF-8")
tudo_confere = TRUE
for (documento in names(PASTAS_DE_CADA_DOCUMENTO)) {
  do_documento = codigos_dos_campos[codigos_dos_campos$documento == documento, ]
  for (nome_do_campo in unique(do_documento$campo)) {
    codigos_na_tabela = unique(do_documento$codigo[do_documento$campo == nome_do_campo])
    aceitos_pelo_schema = valores_aceitos(PASTAS_DE_CADA_DOCUMENTO[[documento]], nome_do_campo, documento)
    fora_dos_leitores = VALORES_FORA_DOS_LEITORES$codigo[VALORES_FORA_DOS_LEITORES$documento == documento &
                                                           VALORES_FORA_DOS_LEITORES$campo == nome_do_campo]
    de_leiaute_anterior = VALORES_DE_LEIAUTE_ANTERIOR$codigo[VALORES_DE_LEIAUTE_ANTERIOR$documento == documento &
                                                               VALORES_DE_LEIAUTE_ANTERIOR$campo == nome_do_campo]
    nao_aceitos = setdiff(codigos_na_tabela, c(aceitos_pelo_schema, de_leiaute_anterior))
    sem_significado = setdiff(aceitos_pelo_schema, c(codigos_na_tabela, fora_dos_leitores))
    if (length(aceitos_pelo_schema) == 0) {
      cat(sprintf("%-7s %-20s o schema não tem lista de valores para o campo\n", documento, nome_do_campo))
      tudo_confere = FALSE
    } else if (length(nao_aceitos) > 0 || length(sem_significado) > 0) {
      cat(sprintf("%-7s %-20s na tabela e não no schema: %s | no schema e sem significado: %s\n", documento, nome_do_campo,
                  paste(nao_aceitos, collapse = " "), paste(sem_significado, collapse = " ")))
      tudo_confere = FALSE
    } else {
      cat(sprintf("%-7s %-20s ok (%d códigos)\n", documento, nome_do_campo, length(codigos_na_tabela)))
    }
  }
}
if (!tudo_confere) {
  quit(status = 1)
}
