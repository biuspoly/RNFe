# Olha as notas técnicas dos portais da NF-e, do CT-e, do MDF-e e da NFS-e Nacional e escreve um aviso para cada
# publicação que ainda não está em ferramentas/notas_tecnicas_vistas.csv. Uso, na raiz do repositório:
#   Rscript ferramentas/vigiar_notas_tecnicas.R <pasta dos avisos>
#   Rscript ferramentas/vigiar_notas_tecnicas.R --registrar
# Uma nota técnica nova (ou uma versão nova dela) pode mudar as regras de validação, os campos e os serviços que o
# RNFe segue: conferir é trabalho de uma pessoa. No portal do MDF-e entram também os manuais (o MOC). No da NFS-e entram
# todos os documentos das páginas da documentação técnica (notas técnicas, manuais das APIs, anexos com o leiaute e as
# regras), porque lá a mudança de leiaute e de API sai neles. Os pacotes de schemas ficam com o vigiar_schemas.R.
# Uma publicação é conhecida pelo portal e pelo endereço: cada versão nova sai num arquivo novo, e o título às vezes se
# repete (a mesma nota técnica do CT-e e do BP-e, um manual da NFS-e de uma versão para a outra).
# O robô (.github/workflows/vigiar-schemas.yml) abre um aviso (issue) por publicação. "--registrar" grava tudo o que os
# portais listam hoje: rodar depois de conferir. Termina com erro quando algum portal não respondeu, depois de escrever
# os avisos dos outros.

source("ferramentas/schemas.R", encoding = "UTF-8")

NOTAS_TECNICAS_VISTAS = "ferramentas/notas_tecnicas_vistas.csv"
PAGINAS_DAS_NOTAS_TECNICAS = list(
  nfe = "https://www.nfe.fazenda.gov.br/portal/listaConteudo.aspx?tipoConteudo=04BIflQt1aY=",
  cte = "https://www.cte.fazenda.gov.br/portal/listaConteudo.aspx?tipoConteudo=Y0nErnoZpsg=",
  mdfe = "https://dfe-portal.svrs.rs.gov.br/Mdfe/Documentos",
  nfse = c("https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica/documentacao-atual",
           "https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica/producao-restrita",
           "https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica/rtc",
           "https://www.gov.br/nfse/pt-br/nfs-e-via/documentacao-tecnica/notas-tecnicas")
)
NOME_DO_PORTAL_DAS_NOTAS = c(nfe = "portal da NF-e", cte = "portal do CT-e", mdfe = "portal do MDF-e",
                             nfse = "portal da NFS-e Nacional")
# O começo do título do aviso: nos portais do MDF-e e da NFS-e entram também manuais e anexos.
COMECO_DO_AVISO = c(nfe = "Nota técnica nova", cte = "Nota técnica nova", mdfe = "Publicação nova", nfse = "Publicação nova")
# No portal do MDF-e, os tipos de arquivo que entram: 1, os manuais (o MOC), e 3, as notas técnicas.
TIPOS_DE_ARQUIVO_DO_MDFE = c("1", "3")
ENDERECO_DO_PORTAL_DO_MDFE = "https://dfe-portal.svrs.rs.gov.br/"
# O que conferir em cada documento, depois de ler a tabela de versões do começo da nota técnica.
O_QUE_CONFERIR = c(
  nfe = paste0("se ela muda alguma regra de `inst/extdata/regras_nfe.csv` (a pré-conferência) ou de ",
               "`inst/extdata/tabelas/regras_ibs_cbs.csv` (a Reforma: as regras de implementação futura estão lá, sem ",
               "data), se muda alguma data de `inst/extdata/tabelas/marcos_ibs_cbs.csv`, e se mexe nos serviços da SEFAZ ",
               "que o RNFe usa (`sefaz_*`)"),
  cte = paste0("se ela muda o que o `cte_ler()`, o `cte_simplificado_ler()` e o `dacte_pdf()` leem, os eventos do ",
               "desacordo (`sefaz_cte_desacordo()`) ou as datas e regras da Reforma (`marcos_ibs_cbs.csv`, ",
               "`regras_ibs_cbs.csv`). O portal do CT-e publica também as do BP-e (o RNFe não lê o BP-e) e algumas do ",
               "MDF-e (ver o aviso do portal do MDF-e)"),
  mdfe = paste0("se ela muda o que o `mdfe_ler()` e o `damdfe_pdf()` leem ou os eventos e consultas do MDF-e ",
                "(`sefaz_mdfe_*`)"),
  nfse = paste0("se ela muda o que o `nfse_ler()` e o `danfse_pdf()` leem, a API da Sefin Nacional e do ADN que o ",
                "`nfse_emitir()`, o `nfse_cancelar()`, o `nfse_situacao()` e o `nfse_distribuicao()` usam (endereços, ",
                "parâmetros e respostas), ou as tabelas da Reforma que vêm dela (o cIndOp, `local_operacao_ibs_cbs.csv`)")
)

# Nos portais da NF-e e do CT-e, a página da lista traz os links de download (exibirArquivo.aspx).
notas_dos_portais_da_nfe_e_do_cte = function(pagina_da_lista, endereco_da_pagina) {
  links_da_pagina = links_dos_portais_da_nfe_e_do_cte(pagina_da_lista, endereco_da_pagina)
  data.frame(titulo = gsub("\\s+", " ", trimws(xml2::xml_text(links_da_pagina$links))),
             endereco = unname(links_da_pagina$enderecos))
}

# No portal do MDF-e o link é montado por JavaScript: download_arquivo_estatico('MDFE', 3, 'arquivo.pdf'), em que o
# primeiro é o sistema (MDFE, ou DFE nas notas técnicas conjuntas) e o segundo é o tipo do arquivo. O endereço é o que a
# função da página monta: /<sistema>/DownloadArquivoEstatico/?sistema=<sistema>&tipoArquivo=<tipo>&nomeArquivo=<nome>.
notas_do_portal_do_mdfe = function(pagina_da_lista) {
  links_de_download = xml2::xml_find_all(pagina_da_lista, "//a[contains(@onclick, 'download_arquivo_estatico')]")
  chamadas_do_javascript = xml2::xml_attr(links_de_download, "onclick")
  formato_da_chamada = "^.*download_arquivo_estatico\\('([A-Za-z]+)', *([0-9]+), *'([^']+)'.*$"
  sistemas = sub(formato_da_chamada, "\\1", chamadas_do_javascript)
  tipos_de_arquivo = sub(formato_da_chamada, "\\2", chamadas_do_javascript)
  nomes_dos_arquivos = sub(formato_da_chamada, "\\3", chamadas_do_javascript)
  links_que_entram = grepl(formato_da_chamada, chamadas_do_javascript) & tipos_de_arquivo %in% TIPOS_DE_ARQUIVO_DO_MDFE
  nomes_no_endereco = vapply(nomes_dos_arquivos[links_que_entram], utils::URLencode, character(1), reserved = TRUE)
  enderecos = paste0(ENDERECO_DO_PORTAL_DO_MDFE, sistemas[links_que_entram], "/DownloadArquivoEstatico/?sistema=",
                     sistemas[links_que_entram], "&tipoArquivo=", tipos_de_arquivo[links_que_entram], "&nomeArquivo=",
                     nomes_no_endereco)
  titulos = gsub("\\s+", " ", trimws(xml2::xml_text(links_de_download[links_que_entram])))
  titulos[titulos == ""] = nomes_dos_arquivos[links_que_entram][titulos == ""]
  data.frame(titulo = titulos, endereco = unname(enderecos))
}

# Nas páginas do gov.br entram, do conteúdo da página (fora o menu), os arquivos (PDF, planilha, documento) e as notas
# técnicas que são uma página (a 002). O link que termina em "/view" abre a página do arquivo, e sem o "/view" vem o
# arquivo. Os .zip são os pacotes de schemas, do vigiar_schemas.R. Um link sem texto leva o nome do arquivo.
notas_do_portal_da_nfse = function(pagina_da_lista, endereco_da_pagina) {
  conteudo_da_pagina = xml2::xml_find_first(pagina_da_lista, "//*[@id='content-core']")
  if (inherits(conteudo_da_pagina, "xml_missing")) {
    return(data.frame(titulo = character(), endereco = character()))
  }
  links_do_conteudo = xml2::xml_find_all(conteudo_da_pagina, ".//a[@href]")
  enderecos = sub("/view$", "", xml2::url_absolute(trimws(xml2::xml_attr(links_do_conteudo, "href")), endereco_da_pagina))
  titulos = gsub("\\s+", " ", trimws(xml2::xml_text(links_do_conteudo)))
  sao_arquivos = grepl("\\.(pdf|xlsx?|docx?|ods|odt|csv)$", enderecos, ignore.case = TRUE)
  sao_notas_tecnicas = grepl("^Nota T[eé]cnica", titulos, ignore.case = TRUE)
  links_que_entram = sao_arquivos | sao_notas_tecnicas
  titulos = titulos[links_que_entram]
  enderecos = enderecos[links_que_entram]
  titulos[titulos == ""] = basename(enderecos[titulos == ""])
  data.frame(titulo = titulos, endereco = enderecos)
}

# Uma linha por publicação do portal: documento, título e endereço. O mesmo arquivo pode estar em mais de uma página (ou
# duas vezes na mesma, uma delas sem texto): fica uma linha, com o título que tiver texto.
listar_notas_do_portal = function(documento, pasta_temporaria) {
  notas = data.frame(titulo = character(), endereco = character())
  for (endereco_da_pagina in PAGINAS_DAS_NOTAS_TECNICAS[[documento]]) {
    pagina_da_lista = abrir_pagina(paste0(documento, "_notas_tecnicas"), endereco_da_pagina, pasta_temporaria)
    if (documento == "mdfe") {
      notas_da_pagina = notas_do_portal_do_mdfe(pagina_da_lista)
    } else if (documento == "nfse") {
      notas_da_pagina = notas_do_portal_da_nfse(pagina_da_lista, endereco_da_pagina)
    } else {
      notas_da_pagina = notas_dos_portais_da_nfe_e_do_cte(pagina_da_lista, endereco_da_pagina)
    }
    if (nrow(notas_da_pagina) == 0) {
      stop("A página não tem mais os links das notas técnicas: ", endereco_da_pagina, call. = FALSE)
    }
    notas = rbind(notas, notas_da_pagina)
  }
  titulo_veio_do_nome_do_arquivo = notas$titulo == basename(notas$endereco)
  notas = notas[order(titulo_veio_do_nome_do_arquivo), ]
  notas = notas[!duplicated(notas$endereco), ]
  data.frame(documento = rep(documento, nrow(notas)), titulo = notas$titulo, endereco = notas$endereco)
}

listar_todas_as_notas = function(pasta_temporaria) {
  notas = data.frame(documento = character(), titulo = character(), endereco = character())
  portais_com_erro = character()
  for (documento in names(PAGINAS_DAS_NOTAS_TECNICAS)) {
    notas_do_portal = tryCatch(listar_notas_do_portal(documento, pasta_temporaria), error = function(erro) erro)
    if (inherits(notas_do_portal, "error")) {
      portais_com_erro = c(portais_com_erro, paste0(NOME_DO_PORTAL_DAS_NOTAS[[documento]], ": ", conditionMessage(notas_do_portal)))
    } else {
      notas = rbind(notas, notas_do_portal)
    }
  }
  list(notas = notas, portais_com_erro = portais_com_erro)
}

# O nome do arquivo no endereço (no portal do MDF-e ele vem no parâmetro nomeArquivo).
nome_do_arquivo_no_endereco = function(endereco) {
  if (grepl("nomeArquivo=", endereco, fixed = TRUE)) {
    return(utils::URLdecode(sub("^.*nomeArquivo=", "", endereco)))
  }
  basename(endereco)
}

# Um aviso para as publicações novas de um portal com o mesmo título (a nota técnica do CT-e e a do BP-e saem com o
# mesmo nome). O robô não abre dois avisos com o mesmo título, nem depois de fechado o primeiro: nos portais do MDF-e e
# da NFS-e, onde o título de um manual se repete de uma versão para a outra, o nome do arquivo (que traz a versão) entra
# no título.
escrever_aviso_da_nota_tecnica = function(publicacoes, pasta_dos_avisos, numero_do_aviso) {
  documento = publicacoes$documento[1]
  titulo_da_publicacao = publicacoes$titulo[1]
  nome_do_portal = NOME_DO_PORTAL_DAS_NOTAS[[documento]]
  titulo_do_aviso = paste0(COMECO_DO_AVISO[[documento]], " no ", nome_do_portal, ": ", titulo_da_publicacao)
  if (documento %in% c("mdfe", "nfse")) {
    nomes_dos_arquivos = vapply(publicacoes$endereco, nome_do_arquivo_no_endereco, character(1), USE.NAMES = FALSE)
    titulo_do_aviso = paste0(titulo_do_aviso, " (", paste(unique(nomes_dos_arquivos), collapse = ", "), ")")
  }
  titulo_do_aviso = substr(titulo_do_aviso, 1, 250)
  if (nrow(publicacoes) == 1) {
    linhas_dos_enderecos = paste0("Endereço: ", publicacoes$endereco)
  } else {
    linhas_dos_enderecos = c("Endereços (o mesmo título, arquivos diferentes):", paste0("- ", publicacoes$endereco))
  }
  linhas_do_aviso = c(
    titulo_do_aviso,
    paste0("O ", nome_do_portal, " publicou: **", titulo_da_publicacao, "**"),
    "",
    linhas_dos_enderecos,
    "",
    paste0("O que fazer: ler a tabela de versões do começo do documento, quando tiver (o que foi alterado, criado e ",
           "excluído, e a data de produção de cada versão), e conferir ", O_QUE_CONFERIR[[documento]], ". O texto que sai vem ",
           "riscado: confira na página do PDF, não no texto copiado. Mexeu numa tabela, rodar ",
           "`Rscript ferramentas/gerar_conferencia_das_tabelas.R`. Depois, rodar ",
           "`Rscript ferramentas/vigiar_notas_tecnicas.R --registrar`.")
  )
  arquivo_do_aviso = file.path(pasta_dos_avisos, sprintf("nt_%03d.md", numero_do_aviso))
  conexao_com_o_arquivo = file(arquivo_do_aviso, "w", encoding = "UTF-8")
  writeLines(linhas_do_aviso, conexao_com_o_arquivo)
  close(conexao_com_o_arquivo)
  titulo_do_aviso
}

argumentos = commandArgs(trailingOnly = TRUE)
if (length(argumentos) != 1) {
  stop("Uso: Rscript ferramentas/vigiar_notas_tecnicas.R <pasta dos avisos> | --registrar", call. = FALSE)
}
pasta_temporaria = tempfile("vigia_das_notas_tecnicas_")
dir.create(pasta_temporaria)
listagem_dos_portais = listar_todas_as_notas(pasta_temporaria)
if (argumentos[1] == "--registrar") {
  if (length(listagem_dos_portais$portais_com_erro) > 0) {
    stop("Algum portal não respondeu, nada foi gravado: ", paste(listagem_dos_portais$portais_com_erro, collapse = "; "),
         call. = FALSE)
  }
  gravar_csv(listagem_dos_portais$notas, NOTAS_TECNICAS_VISTAS)
  cat("Registradas", nrow(listagem_dos_portais$notas), "publicações em", NOTAS_TECNICAS_VISTAS, "\n")
} else {
  pasta_dos_avisos = argumentos[1]
  dir.create(pasta_dos_avisos, showWarnings = FALSE, recursive = TRUE)
  ja_vistas = ler_csv(NOTAS_TECNICAS_VISTAS)
  notas_de_hoje = listagem_dos_portais$notas
  identificacao_das_vistas = paste(ja_vistas$documento, ja_vistas$endereco)
  identificacao_de_hoje = paste(notas_de_hoje$documento, notas_de_hoje$endereco)
  novas = notas_de_hoje[!(identificacao_de_hoje %in% identificacao_das_vistas), ]
  titulos_das_novas = paste(novas$documento, novas$titulo)
  titulos_dos_avisos = unique(titulos_das_novas)
  for (numero in seq_along(titulos_dos_avisos)) {
    publicacoes_do_aviso = novas[titulos_das_novas == titulos_dos_avisos[numero], ]
    cat("Aviso:", escrever_aviso_da_nota_tecnica(publicacoes_do_aviso, pasta_dos_avisos, numero), "\n")
  }
  cat("Publicações nos portais:", nrow(notas_de_hoje), "; novas:", nrow(novas), "; avisos:", length(titulos_dos_avisos), "\n")
  if (length(listagem_dos_portais$portais_com_erro) > 0) {
    cat("Portais que não responderam:\n", paste0("  ", listagem_dos_portais$portais_com_erro, "\n"), sep = "")
    quit(status = 1)
  }
}
