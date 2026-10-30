# O que a leitura de NF-e, de CT-e e de MDF-e faz igual: abrir os arquivos, buscar os campos e montar as
# tabelas.

# O documento é lido sem namespace (xml_ns_strip). Passar isto em cada busca evita que o xml2 procure
# os namespaces de novo a cada vez, o que deixava a leitura duas vezes mais lenta.
SEM_NAMESPACE = character()

# A lista de campos de uma tabela, escrita como texto em colunas (coluna, caminho, tipo).
ler_campos = function(lista_em_texto) {
  utils::read.table(text = lista_em_texto, header = TRUE, stringsAsFactors = FALSE)
}

# A lista de campos como aparece na ajuda: `coluna` (`caminho`), separados por vírgula.
documentar_campos = function(lista_de_campos) {
  paste0("`", lista_de_campos$coluna, "` (`", lista_de_campos$caminho, "`)", collapse = ", ")
}

# A partir do infProt do protocolo de autorização (protNFe, protCTe, protMDFe), que vem junto no nfeProc, no
# cteProc e no mdfeProc.
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

# A partir de cada pagamento vinculado da Reforma (gPgtoVinc/gPgto na NF-e, pgtoVinc/pgto no CT-e), que liga o
# documento à transação de pagamento usada no split payment. O código do meio de pagamento é o do Informe
# Técnico 2026.001.
CAMPOS_DO_PAGAMENTO_VINCULADO = ler_campos("
coluna                 caminho        tipo
numero                 @nPag          inteiro
transacao              @idTransacao   texto
meio_pagamento         tpMeioPgto     texto
cnpj_recebedor         CNPJReceb      texto
cnpj_base_instituicao  CNPJBasePSP    texto
")

# O nome do meio de pagamento, como a tabela de meios de pagamento do Portal da NF-e registrava na data do documento
# (o Informe Técnico 2026.001 manda usar a mesma tabela do tPag).
DESCRICOES_DO_PAGAMENTO_VINCULADO = ler_campos("
coluna_do_codigo coluna_nova              tabela          texto
meio_pagamento   meio_pagamento_descricao meios_pagamento descricao
")

# Lê cada arquivo e devolve, de cada um, as colunas das tabelas (o que `colunas_do_documento` monta), o
# nome e o problema. `caminho_dos_documentos` acha cada documento no XML ("//NFe/infNFe") e
# `nome_do_documento` vai na mensagem do arquivo que não é desse tipo ("uma NF-e", "um CT-e").
# `todos_os_campos` diz se `colunas_do_documento` monta também a tabela campos.
ler_arquivos_xml = function(arquivos, caminho_dos_documentos, nome_do_documento, colunas_do_documento, todos_os_campos) {
  arquivos = as.character(arquivos)
  arquivos_lidos = list()
  for (posicao in seq_along(arquivos)) {
    arquivos_lidos[[posicao]] = ler_um_arquivo(arquivos[posicao], posicao, caminho_dos_documentos, nome_do_documento,
                                               colunas_do_documento, todos_os_campos)
  }
  arquivos_lidos
}

ler_um_arquivo = function(arquivo, posicao, caminho_dos_documentos, nome_do_documento, colunas_do_documento, todos_os_campos) {
  e_texto_do_xml = !is.na(arquivo) && startsWith(trimws(arquivo), "<")
  if (e_texto_do_xml) {
    nome_do_arquivo = paste0("(texto ", posicao, ")")
  } else {
    nome_do_arquivo = arquivo
  }

  xml_lido = NULL
  problema = NA_character_
  if (is.na(arquivo) || trimws(arquivo) == "") {
    problema = "vazio"
  } else if (!e_texto_do_xml && !file.exists(arquivo)) {
    problema = "arquivo n\u00e3o encontrado"
  } else {
    xml_lido = tryCatch(xml2::read_xml(arquivo), error = function(erro) erro)
    if (inherits(xml_lido, "error")) {
      problema = paste0("n\u00e3o \u00e9 um XML v\u00e1lido: ", conditionMessage(xml_lido))
      xml_lido = NULL
    }
  }

  if (!is.null(xml_lido)) {
    xml2::xml_ns_strip(xml_lido)
    if (length(buscar_todos(xml_lido, caminho_dos_documentos)) == 0) {
      problema = problema_sem_documento(xml_lido, nome_do_documento)
      xml_lido = NULL
    }
  }

  arquivo_lido = colunas_do_documento(xml_lido, nome_do_arquivo, todos_os_campos)
  arquivo_lido$nome_do_arquivo = nome_do_arquivo
  arquivo_lido$problema = problema
  arquivo_lido
}

problema_sem_documento = function(xml_lido, nome_do_documento) {
  raiz_do_xml = xml2::xml_name(xml2::xml_root(xml_lido))
  if (raiz_do_xml == "resNFe") {
    return("\u00e9 o resumo da NF-e (resNFe), sem os itens")
  }
  if (raiz_do_xml %in% c("CTeSimp", "cteSimpProc")) {
    return("\u00e9 um CT-e simplificado, que ainda n\u00e3o \u00e9 lido")
  }
  paste0("n\u00e3o \u00e9 ", nome_do_documento, " (o XML come\u00e7a por <", raiz_do_xml, ">)")
}

# Junta a mesma tabela de todos os arquivos numa só. Cada arquivo traz as colunas numa lista, e o
# data.frame é montado uma vez, aqui: montar um por arquivo custava uns 3 ms por nota. `colunas_vazias`
# dá os nomes e os tipos quando não há arquivo nenhum.
juntar_tabela = function(arquivos_lidos, nome_da_tabela, colunas_vazias) {
  colunas_juntas = colunas_vazias
  for (nome_da_coluna in names(colunas_vazias)) {
    # O pedaço vazio vem primeiro e dá o tipo da coluna; depois, o pedaço de cada arquivo.
    pedacos_da_coluna = vector("list", length(arquivos_lidos) + 1)
    pedacos_da_coluna[[1]] = colunas_vazias[[nome_da_coluna]]
    for (posicao in seq_along(arquivos_lidos)) {
      pedacos_da_coluna[[posicao + 1]] = arquivos_lidos[[posicao]][[nome_da_tabela]][[nome_da_coluna]]
    }
    colunas_juntas[[nome_da_coluna]] = do.call(c, pedacos_da_coluna)
  }
  list2DF(colunas_juntas)
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

buscar_todos = function(dentro_de, caminho_no_xml) {
  xml2::xml_find_all(dentro_de, caminho_no_xml, ns = SEM_NAMESPACE)
}

texto_de_cada = function(elementos, caminho_no_xml) {
  xml2::xml_text(xml2::xml_find_first(elementos, caminho_no_xml, ns = SEM_NAMESPACE))
}

# Todos os campos (os elementos sem filhos) de cada documento, menos os da assinatura digital: na NFS-e a
# assinatura da DPS fica dentro do infNFSe.
buscar_todos_os_campos = function(documentos) {
  buscar_todos(documentos, ".//*[not(*)][not(ancestor::Signature)]")
}

# Um campo por linha, com o caminho a partir do elemento principal (infMDFe, infNFSe...). O xml2 põe a posição
# no caminho só quando o grupo se repete (condutor[2]), o que basta para separar uma ocorrência da outra.
colunas_de_todos_os_campos = function(campos_do_xml, elemento_principal) {
  grupo_de_cada_campo = xml2::xml_find_first(campos_do_xml, "parent::*", ns = SEM_NAMESPACE)
  list(
    chave = chave_de_cada(campos_do_xml, elemento_principal),
    caminho = sub(paste0("^.*/", elemento_principal, "/"), "", xml2::xml_path(campos_do_xml)),
    grupo = xml2::xml_name(grupo_de_cada_campo),
    campo = xml2::xml_name(campos_do_xml),
    valor = xml2::xml_text(campos_do_xml)
  )
}

# A chave vem do Id do elemento principal, sem o prefixo de letras (NFe, CTe, MDFe, NFS).
chave_de_cada = function(elementos, elemento_principal) {
  documento_de_cada = xml2::xml_find_first(elementos, paste0("ancestor-or-self::", elemento_principal), ns = SEM_NAMESPACE)
  sub("^[A-Za-z]+", "", xml2::xml_attr(documento_de_cada, "Id"))
}

# Uma coluna por campo, já no tipo certo; as datas ficam como texto até converter_datas(). O tipo
# "elemento" guarda o nome do elemento achado (ICMS00, infNFe...), não o texto dele.
# `posicoes` diz de qual elemento vem cada linha (no protocolo, NA é o documento que veio sem ele).
valores_dos_campos = function(elementos, lista_de_campos, posicoes = seq_along(elementos)) {
  colunas_dos_campos = list()
  for (numero_do_campo in seq_len(nrow(lista_de_campos))) {
    caminho_do_campo = lista_de_campos$caminho[numero_do_campo]
    nome_da_coluna = lista_de_campos$coluna[numero_do_campo]
    tipo_do_campo = lista_de_campos$tipo[numero_do_campo]
    if (tipo_do_campo == "elemento") {
      elemento_de_cada = xml2::xml_find_first(elementos, caminho_do_campo, ns = SEM_NAMESPACE)
      colunas_dos_campos[[nome_da_coluna]] = xml2::xml_name(elemento_de_cada)[posicoes]
      next
    }
    textos_do_xml = texto_de_cada(elementos, caminho_do_campo)[posicoes]
    if (tipo_do_campo == "inteiro") {
      colunas_dos_campos[[nome_da_coluna]] = as.integer(textos_do_xml)
    } else if (tipo_do_campo == "numero") {
      colunas_dos_campos[[nome_da_coluna]] = as.numeric(textos_do_xml)
    } else {
      colunas_dos_campos[[nome_da_coluna]] = textos_do_xml
    }
  }
  colunas_dos_campos
}

converter_datas = function(tabela_lida, lista_de_campos) {
  for (numero_do_campo in seq_len(nrow(lista_de_campos))) {
    nome_da_coluna = lista_de_campos$coluna[numero_do_campo]
    if (lista_de_campos$tipo[numero_do_campo] == "data") {
      tabela_lida[[nome_da_coluna]] = as.Date(substr(tabela_lida[[nome_da_coluna]], 1, 10))
    } else if (lista_de_campos$tipo[numero_do_campo] == "data_hora") {
      tabela_lida[[nome_da_coluna]] = data_hora(tabela_lida[[nome_da_coluna]])
    }
  }
  tabela_lida
}

# "2026-10-15T10:30:00-03:00": o instante exato, mostrado no horário de Brasília. Só a data
# (leiaute antigo, dEmi) não tem hora e fica NA.
data_hora = function(data_hora_do_xml) {
  fuso_sem_dois_pontos = sub("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2", data_hora_do_xml)
  instante = as.POSIXct(fuso_sem_dois_pontos, format = "%Y-%m-%dT%H:%M:%S%z", tz = "UTC")
  attr(instante, "tzone") = "America/Sao_Paulo"
  instante
}

# Ao lado de cada código, o nome dele como a tabela fiscal registrava na data do documento. `descricoes`
# diz qual coluna de código, qual coluna nova, qual tabela e qual texto dela.
acrescentar_descricoes = function(tabela_lida, datas, descricoes) {
  for (numero_da_descricao in seq_len(nrow(descricoes))) {
    descricao_pedida = descricoes[numero_da_descricao, ]
    codigos = tabela_lida[[descricao_pedida$coluna_do_codigo]]
    nomes_na_data = descricao_na_data(descricao_pedida$tabela, codigos, datas, descricao_pedida$texto)
    tabela_lida = inserir_coluna_depois(tabela_lida, descricao_pedida$coluna_nova, nomes_na_data, descricao_pedida$coluna_do_codigo)
  }
  tabela_lida
}

# Ao lado de cada coluna de código, o que o código quer dizer, numa coluna `<coluna>_descricao`, pela tabela
# tabela_fiscal("codigos_dos_campos") (textos da documentação dos schemas). `significados` diz a coluna, o campo do
# leiaute que ela lê e, quando o significado depende de outra coluna (o modelo do CT-e, o grupo do documento), qual
# é ela; "-" quando não depende. Código que a tabela não tem fica NA.
acrescentar_significados = function(tabela_lida, documento, significados) {
  codigos_dos_campos = tabela_fiscal("codigos_dos_campos")
  codigos_do_documento = codigos_dos_campos[codigos_dos_campos$documento == documento, ]
  for (numero_do_significado in seq_len(nrow(significados))) {
    significado_pedido = significados[numero_do_significado, ]
    codigos_do_campo = codigos_do_documento[codigos_do_documento$campo == significado_pedido$campo, ]
    codigos_na_tabela = as.character(tabela_lida[[significado_pedido$coluna_do_codigo]])
    if (significado_pedido$coluna_do_contexto == "-") {
      contexto_de_cada = rep(NA_character_, length(codigos_na_tabela))
    } else {
      contexto_de_cada = as.character(tabela_lida[[significado_pedido$coluna_do_contexto]])
    }
    # Primeiro o significado do contexto da linha; sem ele, o que vale em qualquer contexto.
    linha_com_contexto = match(paste(contexto_de_cada, codigos_na_tabela),
                               paste(codigos_do_campo$contexto, codigos_do_campo$codigo)[!is.na(codigos_do_campo$contexto)])
    linhas_com_contexto = which(!is.na(codigos_do_campo$contexto))
    linhas_sem_contexto = which(is.na(codigos_do_campo$contexto))
    linha_de_cada = linhas_com_contexto[linha_com_contexto]
    sem_o_contexto = is.na(linha_de_cada)
    linha_de_cada[sem_o_contexto] = linhas_sem_contexto[match(codigos_na_tabela[sem_o_contexto], codigos_do_campo$codigo[linhas_sem_contexto])]
    tabela_lida = inserir_coluna_depois(tabela_lida, paste0(significado_pedido$coluna_do_codigo, "_descricao"),
                                        codigos_do_campo$descricao[linha_de_cada], significado_pedido$coluna_do_codigo)
  }
  tabela_lida
}

inserir_coluna_depois = function(tabela_lida, nome_da_coluna, valores_da_coluna, depois_de) {
  tabela_lida[[nome_da_coluna]] = valores_da_coluna
  outras_colunas = setdiff(names(tabela_lida), nome_da_coluna)
  ordem_das_colunas = append(outras_colunas, nome_da_coluna, after = match(depois_de, outras_colunas))
  tabela_lida[, ordem_das_colunas]
}
