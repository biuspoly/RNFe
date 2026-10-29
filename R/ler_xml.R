# O que a leitura de NF-e e de CT-e faz igual: abrir os arquivos, buscar os campos e montar as tabelas.

# O documento é lido sem namespace (xml_ns_strip). Passar isto em cada busca evita que o xml2 procure
# os namespaces de novo a cada vez, o que deixava a leitura duas vezes mais lenta.
SEM_NAMESPACE = character()

ler_campos = function(texto) {
  utils::read.table(text = texto, header = TRUE, stringsAsFactors = FALSE)
}

documentar_campos = function(campos) {
  paste0("`", campos$coluna, "` (`", campos$caminho, "`)", collapse = ", ")
}

# A partir do infProt do protocolo de autorização (protNFe, protCTe), que vem junto no nfeProc e no cteProc.
CAMPOS_DO_PROTOCOLO = ler_campos("
coluna      caminho   tipo
protocolo   nProt     texto
situacao    cStat     inteiro
motivo      xMotivo   texto
autorizacao dhRecbto  data_hora
")

# A partir de cada dup (cobr/dup), igual na NF-e e no CT-e.
CAMPOS_DA_PARCELA = ler_campos("
coluna     caminho tipo
numero     nDup    texto
vencimento dVenc   data
valor      vDup    numero
")

# Lê cada arquivo e devolve, de cada um, as colunas das tabelas (o que `colunas_do_documento` monta), o
# nome e o problema. `caminho_dos_documentos` acha cada documento no XML ("//infNFe") e
# `nome_do_documento` vai na mensagem do arquivo que não é desse tipo ("uma NF-e", "um CT-e").
ler_arquivos_xml = function(arquivos, caminho_dos_documentos, nome_do_documento, colunas_do_documento) {
  arquivos = as.character(arquivos)
  arquivos_lidos = list()
  for (posicao in seq_along(arquivos)) {
    arquivos_lidos[[posicao]] = ler_um_arquivo(arquivos[posicao], posicao, caminho_dos_documentos, nome_do_documento, colunas_do_documento)
  }
  arquivos_lidos
}

ler_um_arquivo = function(arquivo, posicao, caminho_dos_documentos, nome_do_documento, colunas_do_documento) {
  e_texto_do_xml = !is.na(arquivo) && startsWith(trimws(arquivo), "<")
  if (e_texto_do_xml) {
    nome_do_arquivo = paste0("(texto ", posicao, ")")
  } else {
    nome_do_arquivo = arquivo
  }

  documento = NULL
  problema = NA_character_
  if (is.na(arquivo) || trimws(arquivo) == "") {
    problema = "vazio"
  } else if (!e_texto_do_xml && !file.exists(arquivo)) {
    problema = "arquivo n\u00e3o encontrado"
  } else {
    documento = tryCatch(xml2::read_xml(arquivo), error = function(erro) erro)
    if (inherits(documento, "error")) {
      problema = paste0("n\u00e3o \u00e9 um XML v\u00e1lido: ", conditionMessage(documento))
      documento = NULL
    }
  }

  if (!is.null(documento)) {
    xml2::xml_ns_strip(documento)
    if (length(buscar_todos(documento, caminho_dos_documentos)) == 0) {
      problema = problema_sem_documento(documento, nome_do_documento)
      documento = NULL
    }
  }

  arquivo_lido = colunas_do_documento(documento, nome_do_arquivo)
  arquivo_lido$nome_do_arquivo = nome_do_arquivo
  arquivo_lido$problema = problema
  arquivo_lido
}

problema_sem_documento = function(documento, nome_do_documento) {
  raiz = xml2::xml_name(xml2::xml_root(documento))
  if (raiz == "resNFe") {
    return("\u00e9 o resumo da NF-e (resNFe), sem os itens")
  }
  if (raiz %in% c("CTeSimp", "cteSimpProc")) {
    return("\u00e9 um CT-e simplificado, que ainda n\u00e3o \u00e9 lido")
  }
  paste0("n\u00e3o \u00e9 ", nome_do_documento, " (o XML come\u00e7a por <", raiz, ">)")
}

# Junta a mesma tabela de todos os arquivos numa só. Cada arquivo traz as colunas numa lista, e o
# data.frame é montado uma vez, aqui: montar um por arquivo custava uns 3 ms por nota. `colunas_vazias`
# dá os nomes e os tipos quando não há arquivo nenhum.
juntar_tabela = function(arquivos_lidos, nome_da_tabela, colunas_vazias) {
  colunas = colunas_vazias
  for (nome_da_coluna in names(colunas)) {
    valores_de_cada_arquivo = lapply(arquivos_lidos, function(arquivo_lido) arquivo_lido[[nome_da_tabela]][[nome_da_coluna]])
    colunas[[nome_da_coluna]] = do.call(c, c(list(colunas[[nome_da_coluna]]), valores_de_cada_arquivo))
  }
  list2DF(colunas)
}

# Uma linha por arquivo pedido: o nome, quantos documentos tinha e o problema. `nome_da_contagem` é o nome
# da coluna do meio ("notas", "ctes") e `tabela_principal` a tabela em que os documentos são contados.
resumo_dos_arquivos = function(arquivos_lidos, tabela_principal, nome_da_contagem) {
  quantidade_de_arquivos = length(arquivos_lidos)
  nome_de_cada = character(quantidade_de_arquivos)
  documentos_de_cada = integer(quantidade_de_arquivos)
  problema_de_cada = character(quantidade_de_arquivos)
  for (posicao in seq_len(quantidade_de_arquivos)) {
    nome_de_cada[posicao] = arquivos_lidos[[posicao]]$nome_do_arquivo
    documentos_de_cada[posicao] = length(arquivos_lidos[[posicao]][[tabela_principal]]$chave)
    problema_de_cada[posicao] = arquivos_lidos[[posicao]]$problema
  }
  resumo = data.frame(arquivo = nome_de_cada, quantidade = documentos_de_cada, problema = problema_de_cada)
  names(resumo)[2] = nome_da_contagem
  resumo
}

buscar_todos = function(dentro_de, caminho) {
  xml2::xml_find_all(dentro_de, caminho, ns = SEM_NAMESPACE)
}

texto_de_cada = function(elementos, caminho) {
  xml2::xml_text(xml2::xml_find_first(elementos, caminho, ns = SEM_NAMESPACE))
}

# A chave vem do Id do elemento principal, sem o prefixo de letras (NFe, CTe).
chave_de_cada = function(elementos, elemento_principal) {
  documento_de_cada = xml2::xml_find_first(elementos, paste0("ancestor-or-self::", elemento_principal), ns = SEM_NAMESPACE)
  sub("^[A-Za-z]+", "", xml2::xml_attr(documento_de_cada, "Id"))
}

# Uma coluna por campo, já no tipo certo; as datas ficam como texto até converter_datas(). O tipo
# "elemento" guarda o nome do elemento achado (ICMS00, infNFe...), não o texto dele.
# `posicoes` diz de qual elemento vem cada linha (no protocolo, NA é o documento que veio sem ele).
valores_dos_campos = function(elementos, campos, posicoes = seq_along(elementos)) {
  colunas = list()
  for (numero_do_campo in seq_len(nrow(campos))) {
    caminho = campos$caminho[numero_do_campo]
    nome_da_coluna = campos$coluna[numero_do_campo]
    tipo = campos$tipo[numero_do_campo]
    if (tipo == "elemento") {
      elemento_de_cada = xml2::xml_find_first(elementos, caminho, ns = SEM_NAMESPACE)
      colunas[[nome_da_coluna]] = xml2::xml_name(elemento_de_cada)[posicoes]
      next
    }
    textos = texto_de_cada(elementos, caminho)[posicoes]
    if (tipo == "inteiro") {
      colunas[[nome_da_coluna]] = as.integer(textos)
    } else if (tipo == "numero") {
      colunas[[nome_da_coluna]] = as.numeric(textos)
    } else {
      colunas[[nome_da_coluna]] = textos
    }
  }
  colunas
}

converter_datas = function(tabela, campos) {
  for (numero_do_campo in seq_len(nrow(campos))) {
    nome_da_coluna = campos$coluna[numero_do_campo]
    if (campos$tipo[numero_do_campo] == "data") {
      tabela[[nome_da_coluna]] = as.Date(substr(tabela[[nome_da_coluna]], 1, 10))
    } else if (campos$tipo[numero_do_campo] == "data_hora") {
      tabela[[nome_da_coluna]] = data_hora(tabela[[nome_da_coluna]])
    }
  }
  tabela
}

# "2026-10-15T10:30:00-03:00": o instante exato, mostrado no horário de Brasília. Só a data
# (leiaute antigo, dEmi) não tem hora e fica NA.
data_hora = function(texto) {
  sem_dois_pontos = sub("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2", texto)
  instante = as.POSIXct(sem_dois_pontos, format = "%Y-%m-%dT%H:%M:%S%z", tz = "UTC")
  attr(instante, "tzone") = "America/Sao_Paulo"
  instante
}

# Ao lado de cada código, o nome dele como a tabela fiscal registrava na data do documento. `descricoes`
# diz qual coluna de código, qual coluna nova, qual tabela e qual texto dela.
acrescentar_descricoes = function(tabela, datas, descricoes) {
  for (numero_da_linha in seq_len(nrow(descricoes))) {
    descricao = descricoes[numero_da_linha, ]
    textos = descricao_na_data(descricao$tabela, tabela[[descricao$coluna_do_codigo]], datas, descricao$texto)
    tabela = inserir_coluna_depois(tabela, descricao$coluna_nova, textos, descricao$coluna_do_codigo)
  }
  tabela
}

inserir_coluna_depois = function(tabela, nome_da_coluna, valores, depois_de) {
  tabela[[nome_da_coluna]] = valores
  outras_colunas = setdiff(names(tabela), nome_da_coluna)
  ordem = append(outras_colunas, nome_da_coluna, after = match(depois_de, outras_colunas))
  tabela[, ordem]
}
