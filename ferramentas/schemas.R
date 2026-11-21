# O que as ferramentas de schema fazem igual: baixar um pacote de schemas de um portal e achar nele a pasta do
# arquivo principal. Usado por baixar_schemas.R e validar_exemplos.R (com source()). Precisa dos pacotes httr2 e
# xml2.

# As páginas de cada portal que listam os pacotes de schemas. A NFS-e publica em três: a da documentação
# atual (produção), a da Produção Restrita (o leiaute que vem, como o da NT 009, sai primeiro nela) e a da
# Reforma Tributária (RTC).
PAGINA_DOS_SCHEMAS = list(
  nfe = "https://www.nfe.fazenda.gov.br/portal/listaConteudo.aspx?tipoConteudo=BMPFMBoln3w=",
  cte = "https://www.cte.fazenda.gov.br/portal/listaConteudo.aspx?tipoConteudo=0xlG1bdBass=",
  mdfe = "https://dfe-portal.svrs.rs.gov.br/Mdfe/Documentos",
  nfse = c("https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica/documentacao-atual",
           "https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica/producao-restrita",
           "https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica/rtc")
)
# O pacote de schemas que cada leitor do RNFe segue e o arquivo principal dele. As linhas que começam por nfe_ são os
# pacotes à parte dos eventos da NF-e e da Distribuição.
SCHEMAS_USADOS = "ferramentas/schemas_usados.csv"

ler_csv = function(caminho_do_csv) {
  utils::read.csv(caminho_do_csv, colClasses = "character", encoding = "UTF-8")
}

arquivo_de_cookies_do_portal = function(documento, pasta_temporaria) {
  file.path(pasta_temporaria, paste0("cookies_", documento, ".txt"))
}

# Abre a página da lista guardando o cookie de sessão: o Portal da NF-e e o do CT-e só entregam o arquivo
# para quem abriu a página antes.
abrir_pagina = function(documento, endereco_da_pagina, pasta_temporaria) {
  pedido_da_pagina = httr2::request(endereco_da_pagina)
  pedido_da_pagina = httr2::req_cookie_preserve(pedido_da_pagina, arquivo_de_cookies_do_portal(documento, pasta_temporaria))
  pedido_da_pagina = httr2::req_timeout(pedido_da_pagina, 120)
  resposta_da_pagina = httr2::req_perform(pedido_da_pagina)
  xml2::read_html(httr2::resp_body_string(resposta_da_pagina))
}

# Baixa o pacote e o abre numa pasta. Devolve a pasta, ou NA quando o arquivo não é um zip.
baixar_pacote = function(documento, endereco, pasta_temporaria) {
  abrir_pagina(documento, PAGINA_DOS_SCHEMAS[[documento]][1], pasta_temporaria)
  arquivo_zip = tempfile(tmpdir = pasta_temporaria, fileext = ".zip")
  pedido_do_arquivo = httr2::request(endereco)
  pedido_do_arquivo = httr2::req_cookie_preserve(pedido_do_arquivo, arquivo_de_cookies_do_portal(documento, pasta_temporaria))
  pedido_do_arquivo = httr2::req_timeout(pedido_do_arquivo, 300)
  httr2::req_perform(pedido_do_arquivo, path = arquivo_zip)
  pasta_do_pacote = sub("\\.zip$", "", arquivo_zip)
  arquivos_abertos = tryCatch(utils::unzip(arquivo_zip, exdir = pasta_do_pacote, setTimes = TRUE),
                              error = function(erro) character(), warning = function(aviso) character())
  if (length(arquivos_abertos) == 0) {
    return(NA_character_)
  }
  # Alguns pacotes guardam os schemas em zips dentro do zip (o 010d da NF-e traz o PL_Evento.zip): cada um é
  # aberto numa pasta com o nome dele.
  for (zip_de_dentro in arquivos_abertos[grepl("\\.zip$", arquivos_abertos, ignore.case = TRUE)]) {
    tryCatch(utils::unzip(zip_de_dentro, exdir = sub("\\.zip$", "", zip_de_dentro, ignore.case = TRUE), setTimes = TRUE),
             error = function(erro) character(), warning = function(aviso) character())
  }
  pasta_do_pacote
}

# A pasta, dentro do pacote aberto, que tem o arquivo principal (os pacotes guardam os schemas em
# subpastas com nomes que mudam). NA quando o pacote não tem esse arquivo.
pasta_do_arquivo = function(pasta_do_pacote, arquivo_principal) {
  if (is.na(pasta_do_pacote)) {
    return(NA_character_)
  }
  nome_exato = paste0("^", gsub(".", "\\.", arquivo_principal, fixed = TRUE), "$")
  arquivos_achados = list.files(pasta_do_pacote, pattern = nome_exato, recursive = TRUE, full.names = TRUE)
  if (length(arquivos_achados) == 0) {
    return(NA_character_)
  }
  dirname(arquivos_achados[1])
}
