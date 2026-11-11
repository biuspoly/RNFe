# Põe os arquivos de um pacote de schemas novo no lugar dos que o pacote do RNFe tem (inst/schemas), para o robô deixar
# a troca pronta num ramo, conferida, antes de uma pessoa decidir. Uso, na raiz do repositório:
#   Rscript ferramentas/preparar_troca_de_schemas.R <documento> <pasta do pacote aberto> <página da publicação> <relatório.md>
# <documento> é o portal (nfe, cte, mdfe, nfse). Cada arquivo de inst/schemas/<pasta> do portal que o pacote traz com o
# mesmo nome, outro conteúdo e uma data mais nova (a data do arquivo dentro do zip, contra a de
# ferramentas/datas_dos_schemas.csv) é trocado; o que um arquivo trocado inclui e a pasta não tem é acrescentado. O
# arquivo mais antigo que o do RNFe não é trocado (o pacote velho que o portal lista de novo não rebaixa nada), e o
# arquivo numa versão nova (o NFSe_v1.02.xsd no lugar do NFSe_v1.01.xsd) também não: o código diz o nome do arquivo, e a
# troca de versão é trabalho de uma pessoa. O relatório diz tudo isso. Termina com 0 quando trocou algo, 2 quando não
# trocou nada e 3 quando a troca deixou um schema que não abre (o 1 é o do R que parou com erro).

# As pastas de inst/schemas de cada portal. A NFS-e tem duas: a da produção, que recebe o pacote da página da
# documentação atual, e a da Produção Restrita (a homologação), que recebe o da página da Produção Restrita.
PASTAS_DE_CADA_PORTAL = list(nfe = c("nfe", "nfe_eventos"), cte = "cte", mdfe = "mdfe",
                             nfse = c("nfse", "nfse_producao_restrita"))
PASTA_DE_CADA_PAGINA_DA_NFSE = c("documentacao-atual" = "nfse", "producao-restrita" = "nfse_producao_restrita")
# O arquivo principal de cada pasta. Um arquivo que os outros da pasta incluem (o tiposBasico, o xmldsig) só é trocado
# pelo de uma pasta do pacote que traz também o principal: o pacote de consulta de cadastro traz um tiposBasico_v1.03.xsd
# só dele, que não pode tomar o lugar do dos eventos. O de base mais novo num pacote sem o principal vai no relatório.
PRINCIPAL_DE_CADA_PASTA = c(nfe = "nfe_v4.00.xsd", nfe_eventos = "leiauteEvento_v1.00.xsd", cte = "cte_v4.00.xsd",
                            mdfe = "mdfe_v3.00.xsd", nfse = "NFSe_v1.01.xsd", nfse_producao_restrita = "DPS_v1.01.xsd")
SCHEMAS_DO_PACOTE = "inst/schemas"
# A data de cada arquivo de inst/schemas dentro do pacote oficial de onde ele veio, com o MD5 dele.
DATAS_DOS_SCHEMAS = "ferramentas/datas_dos_schemas.csv"
SITUACAO_TROCOU = 0
SITUACAO_NADA = 2
SITUACAO_QUEBROU = 3

# As pastas que o pacote novo pode atualizar. Na NFS-e, pela página da publicação; a da Reforma Tributária não tem pasta
# certa (a troca é de uma pessoa).
pastas_do_portal = function(documento, pagina) {
  pastas = PASTAS_DE_CADA_PORTAL[[documento]]
  if (is.null(pastas)) {
    stop("Portal desconhecido: ", documento, call. = FALSE)
  }
  if (documento != "nfse") {
    return(pastas)
  }
  for (trecho in names(PASTA_DE_CADA_PAGINA_DA_NFSE)) {
    if (grepl(trecho, pagina, fixed = TRUE)) {
      return(PASTA_DE_CADA_PAGINA_DA_NFSE[[trecho]])
    }
  }
  character()
}

# O arquivo do pacote que fica no lugar de um arquivo da pasta: o de mesmo nome; quando o pacote tem mais de um com esse
# nome e com conteúdos diferentes (o 010d traz um tiposBasico_v1.03.xsd na pasta do evento e outro na da consulta de
# cadastro), o da pasta do pacote que tem mais arquivos com os nomes da pasta. NA quando não dá para escolher.
arquivo_do_pacote_para = function(nome_do_arquivo, arquivos_do_pacote, nomes_da_pasta) {
  candidatos = arquivos_do_pacote[basename(arquivos_do_pacote) == nome_do_arquivo]
  if (length(candidatos) == 0) {
    return(NA_character_)
  }
  conteudos = tools::md5sum(candidatos)
  if (length(unique(conteudos)) == 1) {
    return(candidatos[1])
  }
  parecidos = integer(length(candidatos))
  for (posicao in seq_along(candidatos)) {
    vizinhos = basename(arquivos_do_pacote[dirname(arquivos_do_pacote) == dirname(candidatos[posicao])])
    parecidos[posicao] = sum(vizinhos %in% nomes_da_pasta)
  }
  melhores = candidatos[parecidos == max(parecidos)]
  if (length(unique(tools::md5sum(melhores))) > 1) {
    return(NA_character_)
  }
  melhores[1]
}

# Os arquivos que um schema inclui ou importa (pelo schemaLocation). O arquivo que não abre não inclui nada: a conferência
# do fim o põe na lista dos que não abrem.
arquivos_incluidos = function(caminho_do_xsd) {
  documento = tryCatch(xml2::read_xml(caminho_do_xsd), error = function(erro) NULL)
  if (is.null(documento)) {
    return(character())
  }
  locais = xml2::xml_attr(xml2::xml_find_all(documento, "//*[local-name()='include' or local-name()='import']"),
                          "schemaLocation")
  unique(basename(locais[!is.na(locais)]))
}

# O nome sem a versão (NFSe_v1.01.xsd vira NFSe) e a versão (1.01), para achar a versão nova de um arquivo.
nome_sem_a_versao = function(nomes) {
  sub("_v[0-9.]+\\.xsd$", "", nomes, ignore.case = TRUE)
}
versao_do_nome = function(nomes) {
  versoes = sub("^.*_v([0-9.]+)\\.xsd$", "\\1", nomes, ignore.case = TRUE)
  versoes[versoes == nomes] = NA_character_
  versoes
}

# A data de um arquivo do pacote aberto: a do zip, que o baixar_pacote() põe no arquivo (setTimes).
data_do_arquivo = function(caminho) {
  format(file.mtime(caminho), "%Y-%m-%d %H:%M")
}

ler_datas_dos_schemas = function() {
  utils::read.csv(DATAS_DOS_SCHEMAS, colClasses = "character", encoding = "UTF-8")
}

gravar_datas_dos_schemas = function(datas) {
  datas = datas[order(datas$pasta, tolower(datas$arquivo)), ]
  conexao = file(DATAS_DOS_SCHEMAS, "wb")
  utils::write.csv(datas, conexao, row.names = FALSE, fileEncoding = "UTF-8", eol = "\n")
  close(conexao)
}

# As versões mais novas de um arquivo da pasta que o pacote traz e o código ainda não usa. O que o pacote do RNFe já tem
# com esse nome noutra versão é outro arquivo, não a versão nova (o tiposBasico_v4.00.xsd da NF-e e o
# tiposBasico_v1.03.xsd dos eventos).
versoes_mais_novas = function(nome, arquivos_do_pacote, nomes_do_portal) {
  versao_atual = versao_do_nome(nome)
  if (is.na(versao_atual)) {
    return(character())
  }
  do_mesmo_nome = basename(arquivos_do_pacote[nome_sem_a_versao(basename(arquivos_do_pacote)) == nome_sem_a_versao(nome)])
  versoes = versao_do_nome(do_mesmo_nome)
  do_mesmo_nome = do_mesmo_nome[!is.na(versoes)]
  versoes = versoes[!is.na(versoes)]
  if (length(versoes) == 0) {
    return(character())
  }
  unique(do_mesmo_nome[numeric_version(versoes) > numeric_version(versao_atual) & !(do_mesmo_nome %in% nomes_do_portal)])
}

preparar_troca = function(documento, pasta_do_pacote, pagina) {
  arquivos_do_pacote = list.files(pasta_do_pacote, pattern = "\\.xsd$", recursive = TRUE, full.names = TRUE,
                                  ignore.case = TRUE)
  relatorio = list(trocados = character(), acrescentados = character(), mais_antigos = character(),
                   versoes_novas = character(), base_sem_o_principal = character(), sem_data = character(),
                   sem_escolha = character(), quebrados = character(), observacoes = character())
  datas = ler_datas_dos_schemas()
  nomes_do_portal = character()
  for (pasta in PASTAS_DE_CADA_PORTAL[[documento]]) {
    nomes_do_portal = c(nomes_do_portal, list.files(file.path(SCHEMAS_DO_PACOTE, pasta), pattern = "\\.xsd$"))
  }
  pastas = pastas_do_portal(documento, pagina)
  if (length(pastas) == 0) {
    relatorio$observacoes = paste0("A publicação é de uma página (", pagina, ") que não tem pasta certa em inst/schemas: ",
                                   "a troca é de uma pessoa.")
  }
  for (pasta in pastas) {
    caminho_da_pasta = file.path(SCHEMAS_DO_PACOTE, pasta)
    nomes_da_pasta = list.files(caminho_da_pasta, pattern = "\\.xsd$")
    # Os arquivos de base (os que algum arquivo da pasta inclui) e as pastas do pacote que trazem o principal dela.
    de_base = character()
    for (nome in nomes_da_pasta) {
      de_base = c(de_base, arquivos_incluidos(file.path(caminho_da_pasta, nome)))
    }
    pastas_com_o_principal = dirname(arquivos_do_pacote[basename(arquivos_do_pacote) == PRINCIPAL_DE_CADA_PASTA[[pasta]]])
    for (nome in nomes_da_pasta) {
      mais_novas = versoes_mais_novas(nome, arquivos_do_pacote, nomes_do_portal)
      if (length(mais_novas) > 0) {
        relatorio$versoes_novas = c(relatorio$versoes_novas, paste0(file.path(pasta, nome), " -> ",
                                                                    paste(mais_novas, collapse = ", ")))
      }
      caminho_em_uso = file.path(caminho_da_pasta, nome)
      md5_em_uso = unname(tools::md5sum(caminho_em_uso))
      linha_da_data = which(datas$pasta == pasta & datas$arquivo == nome)
      arquivos_que_valem = arquivos_do_pacote
      if (nome %in% de_base) {
        arquivos_que_valem = arquivos_do_pacote[dirname(arquivos_do_pacote) %in% pastas_com_o_principal]
        # O de base noutra pasta do pacote, diferente e mais novo que o do RNFe: só no relatório.
        de_fora = arquivos_do_pacote[basename(arquivos_do_pacote) == nome & !(arquivos_do_pacote %in% arquivos_que_valem)]
        for (candidato in de_fora) {
          if (length(linha_da_data) == 1 && unname(tools::md5sum(candidato)) != md5_em_uso &&
              data_do_arquivo(candidato) > datas$data[linha_da_data]) {
            relatorio$base_sem_o_principal = c(relatorio$base_sem_o_principal, paste0(
              file.path(pasta, nome), " (o do pacote, de ", data_do_arquivo(candidato), ", está numa pasta sem o ",
              PRINCIPAL_DE_CADA_PASTA[[pasta]], ")"))
            break
          }
        }
      }
      novo = arquivo_do_pacote_para(nome, arquivos_que_valem, nomes_da_pasta)
      if (is.na(novo)) {
        if (sum(basename(arquivos_que_valem) == nome) > 1) {
          relatorio$sem_escolha = c(relatorio$sem_escolha, file.path(pasta, nome))
        }
        next
      }
      md5_novo = unname(tools::md5sum(novo))
      if (identical(md5_novo, md5_em_uso)) {
        next
      }
      # Sem a data do arquivo em uso (ele mudou sem passar por aqui), não dá para saber se o do pacote é mais novo.
      if (length(linha_da_data) != 1 || !identical(datas$md5[linha_da_data], md5_em_uso)) {
        relatorio$sem_data = c(relatorio$sem_data, file.path(pasta, nome))
        next
      }
      data_nova = data_do_arquivo(novo)
      if (data_nova <= datas$data[linha_da_data]) {
        relatorio$mais_antigos = c(relatorio$mais_antigos, paste0(file.path(pasta, nome), " (o do pacote é de ", data_nova,
                                                                  "; o do RNFe, de ", datas$data[linha_da_data], ")"))
        next
      }
      file.copy(novo, caminho_em_uso, overwrite = TRUE)
      datas$md5[linha_da_data] = md5_novo
      datas$data[linha_da_data] = data_nova
      relatorio$trocados = c(relatorio$trocados, paste0(file.path(pasta, nome), " (de ", data_nova, ")"))
    }
    # O que os arquivos da pasta incluem e ela não tem vem do pacote (da pasta do arquivo que inclui).
    repeat {
      faltam = character()
      for (nome in list.files(caminho_da_pasta, pattern = "\\.xsd$")) {
        incluidos = arquivos_incluidos(file.path(caminho_da_pasta, nome))
        faltam = c(faltam, incluidos[!file.exists(file.path(caminho_da_pasta, incluidos))])
      }
      faltam = unique(faltam)
      acrescentados_agora = character()
      for (nome in faltam) {
        novo = arquivo_do_pacote_para(nome, arquivos_do_pacote, list.files(caminho_da_pasta))
        if (!is.na(novo)) {
          file.copy(novo, file.path(caminho_da_pasta, nome))
          datas = rbind(datas, data.frame(pasta = pasta, arquivo = nome, md5 = unname(tools::md5sum(novo)),
                                          data = data_do_arquivo(novo)))
          acrescentados_agora = c(acrescentados_agora, file.path(pasta, nome))
        }
      }
      relatorio$acrescentados = c(relatorio$acrescentados, acrescentados_agora)
      if (length(acrescentados_agora) == 0) {
        break
      }
    }
    # Cada schema da pasta tem de abrir (com o que ele inclui) depois da troca.
    for (nome in list.files(caminho_da_pasta, pattern = "\\.xsd$")) {
      abriu = tryCatch({
        xml2::xml_validate(xml2::read_xml("<vazio/>"), xml2::read_xml(file.path(caminho_da_pasta, nome)))
        TRUE
      }, error = function(erro) FALSE)
      if (!abriu) {
        relatorio$quebrados = c(relatorio$quebrados, file.path(pasta, nome))
      }
    }
  }
  if (length(relatorio$trocados) > 0 || length(relatorio$acrescentados) > 0) {
    gravar_datas_dos_schemas(datas)
  }
  relatorio
}

# Uma lista do relatório em Markdown, com o título e a quantidade; nada quando ela está vazia.
linhas_de_uma_lista = function(rotulo, itens) {
  if (length(itens) == 0) {
    return(character())
  }
  c(paste0("**", rotulo, " (", length(itens), "):**"), "", paste0("- `", itens, "`"), "")
}

linhas_do_relatorio = function(relatorio) {
  linhas = c(
    linhas_de_uma_lista("Arquivos trocados em inst/schemas", relatorio$trocados),
    linhas_de_uma_lista("Arquivos acrescentados (incluídos pelos trocados)", relatorio$acrescentados),
    linhas_de_uma_lista("Arquivos do pacote mais antigos que os do RNFe (não trocados)", relatorio$mais_antigos),
    linhas_de_uma_lista("Versões novas que o código ainda não usa (a troca delas é de uma pessoa)", relatorio$versoes_novas),
    linhas_de_uma_lista("Arquivos de base mais novos numa pasta do pacote sem o arquivo principal (não trocados: confira)",
                        relatorio$base_sem_o_principal),
    linhas_de_uma_lista(paste0("Arquivos em uso que não estão em ", DATAS_DOS_SCHEMAS, " com o conteúdo de hoje (não trocados)"),
                        relatorio$sem_data),
    linhas_de_uma_lista("Arquivos que o pacote traz mais de uma vez, com conteúdos diferentes (não trocados)",
                        relatorio$sem_escolha),
    linhas_de_uma_lista("Schemas que não abrem depois da troca", relatorio$quebrados)
  )
  if (length(relatorio$observacoes) > 0) {
    linhas = c(relatorio$observacoes, "", linhas)
  }
  linhas
}

if (sys.nframe() == 0) {
  argumentos = commandArgs(trailingOnly = TRUE)
  if (length(argumentos) != 4) {
    stop("Uso: Rscript ferramentas/preparar_troca_de_schemas.R <documento> <pasta do pacote> <página> <relatório.md>",
         call. = FALSE)
  }
  relatorio = preparar_troca(argumentos[1], argumentos[2], argumentos[3])
  conexao = file(argumentos[4], "w", encoding = "UTF-8")
  writeLines(linhas_do_relatorio(relatorio), conexao)
  close(conexao)
  cat(linhas_do_relatorio(relatorio), sep = "\n")
  if (length(relatorio$quebrados) > 0) {
    quit(status = SITUACAO_QUEBROU)
  }
  if (length(relatorio$trocados) == 0 && length(relatorio$acrescentados) == 0) {
    quit(status = SITUACAO_NADA)
  }
  quit(status = SITUACAO_TROCOU)
}
