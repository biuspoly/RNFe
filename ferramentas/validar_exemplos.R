# Confere os documentos de exemplo (inst/exemplos, usados nos testes e na ajuda) contra os schemas
# oficiais que os leitores seguem (ferramentas/schemas_usados.csv). Uso, na raiz do repositório:
#   Rscript ferramentas/validar_exemplos.R
#   Rscript ferramentas/validar_exemplos.R nfe=<pasta> cte=<pasta> mdfe=<pasta> nfse=<pasta> nfe_eventos=<pasta> ...
# Sem argumentos, baixa os pacotes dos portais (ferramentas/baixar_schemas.R). Com eles, usa as pastas dadas, uma
# para cada linha de schemas_usados.csv: a pasta que tem o arquivo principal daquele pacote (na NFS-e, a do
# NFSe_v1.01.xsd; a pasta da versão 1.00 fica ao lado dela, no mesmo pacote).
# Todo documento nessa pasta tem de passar: documento com defeito de propósito vai como texto dentro do teste.

source("ferramentas/schemas.R", encoding = "UTF-8")

argumentos = commandArgs(trailingOnly = TRUE)
if (length(argumentos) == 0) {
  source("ferramentas/baixar_schemas.R", encoding = "UTF-8")
  pasta_de_cada_pacote = baixar_schemas_usados(file.path(tempdir(), "schemas"))
} else {
  pasta_de_cada_pacote = sub("^[^=]*=", "", argumentos)
  names(pasta_de_cada_pacote) = sub("=.*$", "", argumentos)
}
pacotes_usados = ler_csv(SCHEMAS_USADOS)
for (numero_do_pacote in seq_len(nrow(pacotes_usados))) {
  pacote_usado = pacotes_usados[numero_do_pacote, ]
  pasta_do_pacote = pasta_de_cada_pacote[pacote_usado$documento]
  if (is.na(pasta_do_pacote) || !file.exists(file.path(pasta_do_pacote, pacote_usado$arquivo_principal))) {
    stop("Informe ", pacote_usado$documento, "=<pasta com o ", pacote_usado$arquivo_principal, ">, ou nada para baixar",
         call. = FALSE)
  }
}

# Copia a pasta do schema e acrescenta nela um raizes.xsd com as linhas pedidas, para validar o arquivo
# pela raiz que ele tiver.
schema_com_as_raizes = function(pasta_do_schema, nome_da_copia, namespace, linhas_das_raizes, tirar_ancoras = FALSE) {
  copia_do_schema = file.path(tempdir(), nome_da_copia)
  dir.create(copia_do_schema, showWarnings = FALSE)
  invisible(file.copy(list.files(pasta_do_schema, full.names = TRUE), copia_do_schema, overwrite = TRUE))
  # O schema da NFS-e escreve um padrão como "^0{0,4}\d{1,5}$" (o da série da DPS). No padrão XML Schema o "^" e
  # o "$" são letras, não início e fim, e o libxml2 recusaria até a série "1". O padrão XML Schema já compara o
  # valor inteiro, então tirar os dois dá a regra que o portal quis escrever.
  if (tirar_ancoras) {
    for (arquivo_xsd in list.files(copia_do_schema, pattern = "\\.xsd$", full.names = TRUE)) {
      texto_do_xsd = readLines(arquivo_xsd, encoding = "UTF-8", warn = FALSE)
      texto_do_xsd = gsub('(<xs:pattern value=")\\^([^"]*)\\$("\\s*/>)', "\\1\\2\\3", texto_do_xsd)
      writeLines(texto_do_xsd, arquivo_xsd, useBytes = TRUE)
    }
  }
  writeLines(c(
    '<?xml version="1.0" encoding="UTF-8"?>',
    paste0('<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="', namespace, '"'),
    paste0('  targetNamespace="', namespace, '" elementFormDefault="qualified" attributeFormDefault="unqualified">'),
    linhas_das_raizes,
    '</xs:schema>'
  ), file.path(copia_do_schema, "raizes.xsd"))
  xml2::read_xml(file.path(copia_do_schema, "raizes.xsd"))
}

# O pacote da NF-e só declara o NFe como raiz. O nfeProc (a nota com o protocolo de autorização) é
# declarado aqui.
schema_da_nfe = schema_com_as_raizes(pasta_de_cada_pacote[["nfe"]], "schema_nfe", "http://www.portalfiscal.inf.br/nfe", c(
  '  <xs:include schemaLocation="leiauteNFe_v4.00.xsd"/>',
  '  <xs:element name="NFe" type="TNFe"/>',
  '  <xs:element name="nfeProc" type="TNfeProc"/>'
))

# Os eventos da NF-e têm pacotes à parte: o envelope (procEventoNFe) passa no leiaute genérico de 2026, que já
# aceita o CNPJ com letras, e o detEvento no schema do tipo dele (e110111 é o cancelamento, e110110 a carta de
# correção), que o declara como raiz. O resumo do evento (resEvento) é do pacote da Distribuição de DF-e.
schema_dos_eventos_da_nfe = xml2::read_xml(file.path(pasta_de_cada_pacote[["nfe_eventos"]], "procEventoNFe_v1.00.xsd"))
pastas_dos_tipos_de_evento_da_nfe = pasta_de_cada_pacote[c("nfe_cancelamento", "nfe_carta_correcao")]
# O resEvento importa o xmldsig-core-schema_v1.01.xsd, que o pacote da Distribuição não traz: vai junto o do pacote
# dos eventos.
copia_da_distribuicao = file.path(tempdir(), "schema_distribuicao")
dir.create(copia_da_distribuicao, showWarnings = FALSE)
invisible(file.copy(c(list.files(pasta_de_cada_pacote[["nfe_distribuicao"]], full.names = TRUE),
                      file.path(pasta_de_cada_pacote[["nfe_eventos"]], "xmldsig-core-schema_v1.01.xsd")),
                    copia_da_distribuicao, overwrite = TRUE))
schema_do_resumo_de_evento = xml2::read_xml(file.path(copia_da_distribuicao, "resEvento_v1.01.xsd"))

# O pacote do CT-e declara cada raiz num arquivo: o CTe e o CTeOS, o cteProc e o cteOSProc (com o
# protocolo) e o rodo e o rodoOS (o modal rodoviário). O infModal e o detEvento aceitam qualquer coisa sem
# conferir, então o modal e o grupo do evento são validados à parte.
schema_do_cte = schema_com_as_raizes(pasta_de_cada_pacote[["cte"]], "schema_cte", "http://www.portalfiscal.inf.br/cte", c(
  '  <xs:include schemaLocation="cte_v4.00.xsd"/>',
  '  <xs:include schemaLocation="procCTe_v4.00.xsd"/>',
  '  <xs:include schemaLocation="cteOS_v4.00.xsd"/>',
  '  <xs:include schemaLocation="procCTeOS_v4.00.xsd"/>',
  '  <xs:include schemaLocation="cteModalRodoviario_v4.00.xsd"/>',
  '  <xs:include schemaLocation="cteModalRodoviarioOS_v4.00.xsd"/>'
))

# O pacote do MDF-e declara o MDFe, o mdfeProc (com o protocolo) e o rodo.
schema_do_mdfe = schema_com_as_raizes(pasta_de_cada_pacote[["mdfe"]], "schema_mdfe", "http://www.portalfiscal.inf.br/mdfe", c(
  '  <xs:include schemaLocation="mdfe_v3.00.xsd"/>',
  '  <xs:include schemaLocation="procMDFe_v3.00.xsd"/>',
  '  <xs:include schemaLocation="mdfeModalRodoviario_v3.00.xsd"/>'
))

# O evento com o retorno (procEventoCTe, procEventoMDFe) tem schema próprio no mesmo pacote. Ele não entra no
# schema acima: no CT-e, os dois definem o mesmo tipo (TModTransp) e o libxml2 recusa a junção.
schema_dos_eventos_do_cte = xml2::read_xml(file.path(pasta_de_cada_pacote[["cte"]], "procEventoCTe_v4.00.xsd"))
schema_dos_eventos_do_mdfe = xml2::read_xml(file.path(pasta_de_cada_pacote[["mdfe"]], "procEventoMDFe_v3.00.xsd"))

# O pacote da NFS-e traz um schema por versão do leiaute (1.00 e 1.01), cada um na sua pasta, com a NFS-e e o
# evento. O documento é validado pelo da versão que ele declara no atributo versao.
schema_de_cada_versao_da_nfse = list()
arquivos_nfse_do_pacote = list.files(dirname(pasta_de_cada_pacote[["nfse"]]), pattern = "^NFSe_v[0-9.]+\\.xsd$",
                                     recursive = TRUE, full.names = TRUE)
for (arquivo_nfse in arquivos_nfse_do_pacote) {
  versao_do_leiaute = sub("^NFSe_v([0-9.]+)\\.xsd$", "\\1", basename(arquivo_nfse))
  linhas_das_raizes = paste0('  <xs:include schemaLocation="', basename(arquivo_nfse), '"/>')
  arquivo_do_evento = paste0("evento_v", versao_do_leiaute, ".xsd")
  if (file.exists(file.path(dirname(arquivo_nfse), arquivo_do_evento))) {
    linhas_das_raizes = c(linhas_das_raizes, paste0('  <xs:include schemaLocation="', arquivo_do_evento, '"/>'))
  }
  schema_de_cada_versao_da_nfse[[versao_do_leiaute]] = schema_com_as_raizes(
    dirname(arquivo_nfse), paste0("schema_nfse_", versao_do_leiaute), "http://www.sped.fazenda.gov.br/nfse",
    linhas_das_raizes, tirar_ancoras = TRUE
  )
}

mostrar_resultado = function(nome_do_que_foi_validado, resultado_da_validacao) {
  if (resultado_da_validacao) {
    cat("ok      ", nome_do_que_foi_validado, "\n")
  } else {
    cat("FALHOU  ", nome_do_que_foi_validado, "\n")
    cat(paste0("        ", attr(resultado_da_validacao, "errors"), collapse = "\n"), "\n")
  }
  resultado_da_validacao
}

# O documento inteiro e, depois, cada modal e cada grupo de evento sozinho. O modal passa no mesmo schema; o grupo
# do evento, no arquivo que tem o nome dele (o evCancCTe está no evCancCTe_v4.00.xsd), porque juntar os grupos todos
# num schema só dá conflito de tipos repetidos.
validar_com_as_partes = function(arquivo_de_exemplo, documento_lido, schema, pasta_do_schema, final_do_nome_do_arquivo) {
  passou = mostrar_resultado(basename(arquivo_de_exemplo), xml2::xml_validate(documento_lido, schema))
  namespaces = xml2::xml_ns(documento_lido)
  for (modal in xml2::xml_find_all(documento_lido, "//d1:infModal/*", namespaces)) {
    nome_do_modal = paste0(basename(arquivo_de_exemplo), " (modal ", xml2::xml_name(modal), ")")
    passou = mostrar_resultado(nome_do_modal, xml2::xml_validate(xml2::xml_new_root(modal), schema)) && passou
  }
  for (grupo_do_evento in xml2::xml_find_all(documento_lido, "//d1:detEvento/*", namespaces)) {
    nome_do_grupo = paste0(basename(arquivo_de_exemplo), " (", xml2::xml_name(grupo_do_evento), ")")
    arquivo_do_grupo = file.path(pasta_do_schema, paste0(xml2::xml_name(grupo_do_evento), final_do_nome_do_arquivo))
    if (!file.exists(arquivo_do_grupo)) {
      cat("FALHOU  ", nome_do_grupo, "\n         o pacote não tem o schema desse grupo\n")
      passou = FALSE
    } else {
      schema_do_grupo = xml2::read_xml(arquivo_do_grupo)
      passou = mostrar_resultado(nome_do_grupo, xml2::xml_validate(xml2::xml_new_root(grupo_do_evento), schema_do_grupo)) && passou
    }
  }
  passou
}

# O evento da NF-e pelo envelope e o detEvento pelo schema do tipo dele, achado nos pacotes dos eventos.
validar_evento_da_nfe = function(arquivo_de_exemplo, documento_lido, schema_do_envelope, pastas_dos_tipos) {
  passou = mostrar_resultado(basename(arquivo_de_exemplo), xml2::xml_validate(documento_lido, schema_do_envelope))
  namespaces = xml2::xml_ns(documento_lido)
  for (detalhe_do_evento in xml2::xml_find_all(documento_lido, "//d1:detEvento", namespaces)) {
    tipo_do_evento = xml2::xml_text(xml2::xml_find_first(detalhe_do_evento, "../d1:tpEvento", namespaces))
    nome_com_o_tipo = paste0(basename(arquivo_de_exemplo), " (detEvento ", tipo_do_evento, ")")
    arquivos_do_tipo = list.files(pastas_dos_tipos, pattern = paste0("^e", tipo_do_evento, "_v[0-9.]+\\.xsd$"), full.names = TRUE)
    if (length(arquivos_do_tipo) == 0) {
      cat("FALHOU  ", nome_com_o_tipo, "\n         nenhum pacote baixado tem o schema desse tipo de evento\n")
      passou = FALSE
    } else {
      so_o_detalhe = xml2::xml_new_root(detalhe_do_evento)
      passou = mostrar_resultado(nome_com_o_tipo, xml2::xml_validate(so_o_detalhe, xml2::read_xml(arquivos_do_tipo[1]))) && passou
    }
  }
  passou
}

arquivos_de_exemplo = list.files("inst/exemplos", pattern = "\\.xml$", full.names = TRUE)
todos_passaram = TRUE
for (arquivo_de_exemplo in arquivos_de_exemplo) {
  documento_lido = xml2::read_xml(arquivo_de_exemplo)
  namespace_do_documento = xml2::xml_ns(documento_lido)[["d1"]]
  raiz_do_documento = xml2::xml_name(xml2::xml_root(documento_lido))
  if (identical(namespace_do_documento, "http://www.portalfiscal.inf.br/nfe")) {
    if (raiz_do_documento == "procEventoNFe") {
      passou = validar_evento_da_nfe(arquivo_de_exemplo, documento_lido, schema_dos_eventos_da_nfe, pastas_dos_tipos_de_evento_da_nfe)
    } else if (raiz_do_documento == "resEvento") {
      passou = mostrar_resultado(basename(arquivo_de_exemplo), xml2::xml_validate(documento_lido, schema_do_resumo_de_evento))
    } else {
      passou = mostrar_resultado(basename(arquivo_de_exemplo), xml2::xml_validate(documento_lido, schema_da_nfe))
    }
  } else if (identical(namespace_do_documento, "http://www.portalfiscal.inf.br/cte")) {
    schema_do_documento = if (raiz_do_documento == "procEventoCTe") schema_dos_eventos_do_cte else schema_do_cte
    passou = validar_com_as_partes(arquivo_de_exemplo, documento_lido, schema_do_documento, pasta_de_cada_pacote[["cte"]], "_v4.00.xsd")
  } else if (identical(namespace_do_documento, "http://www.portalfiscal.inf.br/mdfe")) {
    schema_do_documento = if (raiz_do_documento == "procEventoMDFe") schema_dos_eventos_do_mdfe else schema_do_mdfe
    passou = validar_com_as_partes(arquivo_de_exemplo, documento_lido, schema_do_documento, pasta_de_cada_pacote[["mdfe"]], "_v3.00.xsd")
  } else if (identical(namespace_do_documento, "http://www.sped.fazenda.gov.br/nfse")) {
    versao_do_leiaute = xml2::xml_attr(xml2::xml_root(documento_lido), "versao")
    nome_com_a_versao = paste0(basename(arquivo_de_exemplo), " (leiaute ", versao_do_leiaute, ")")
    if (is.null(schema_de_cada_versao_da_nfse[[versao_do_leiaute]])) {
      cat("FALHOU  ", nome_com_a_versao, "\n         o pacote não tem o schema dessa versão\n")
      passou = FALSE
    } else {
      passou = mostrar_resultado(nome_com_a_versao, xml2::xml_validate(documento_lido, schema_de_cada_versao_da_nfse[[versao_do_leiaute]]))
    }
  } else {
    cat("FALHOU  ", basename(arquivo_de_exemplo), "\n         namespace desconhecido:", namespace_do_documento, "\n")
    passou = FALSE
  }
  todos_passaram = todos_passaram && passou
}
if (!todos_passaram) {
  quit(status = 1)
}
