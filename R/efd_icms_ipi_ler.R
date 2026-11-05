# A leitura da EFD ICMS/IPI (o SPED Fiscal; etapa 5): o arquivo de texto que o contribuinte gera, um registro por
# linha, vira uma tabela por registro, com os nomes de campo do leiaute (tabela_fiscal("leiaute_efd_icms_ipi")).

#' @include tabelas.R
NULL

#' Ler a EFD ICMS/IPI (o SPED Fiscal) em tabelas
#'
#' Lê o arquivo da Escrituração Fiscal Digital do ICMS e do IPI, o "SPED
#' Fiscal" que o contribuinte gera todo mês e transmite pelo programa da
#' Receita, e devolve uma tabela por registro (`0000`, `C100`, `C170`, `E110`...),
#' com os nomes de campo do leiaute oficial. O arquivo só é lido: nada é
#' enviado a lugar nenhum.
#'
#' O leiaute de cada arquivo é o do período dele (o `DT_INI` do registro
#' 0000): um arquivo de 2016 é lido sem os campos que entraram depois (eles
#' ficam vazios quando arquivos de anos diferentes são lidos juntos), e o E310
#' e o C177, que mudaram inteiros (em 2017 e em 2019), pela versão da época.
#' Veja `tabela_fiscal("leiaute_efd_icms_ipi")` para os registros, os campos,
#' a descrição e a vigência de cada um.
#'
#' Os campos numéricos com casas decimais (valores, alíquotas, quantidades)
#' viram número, e os de data (os `DT_`, no formato ddmmaaaa), `Date`. Os
#' outros ficam texto, com os zeros à esquerda: o CNPJ, o CFOP, o CST, a chave
#' de acesso, o número do documento e os indicadores. O campo vazio fica `NA`.
#' O leiaute dá o mesmo nome a dois campos do C170 (a alíquota do PIS e a da
#' COFINS, em percentual e em reais): cada um vem com o número do campo
#' (`ALIQ_PIS_27` e `ALIQ_PIS_29`, `ALIQ_COFINS_33` e `ALIQ_COFINS_35`).
#'
#' O arquivo vai em ISO 8859-1 (Latin-1), como pede o leiaute, ou em
#' Windows-1252, que dá o mesmo texto com alguns símbolos a mais; o arquivo
#' gravado em UTF-8 também é lido. A assinatura digital, que o programa da
#' Receita acrescenta depois do registro 9999, é ignorada.
#'
#' @section As tabelas:
#' Uma por registro que o arquivo tem, com o código dele como nome: as
#' colunas `arquivo`, `linha` (o número da linha no arquivo) e `linha_pai` (a
#' linha do registro de nível acima, que liga o C170 e o C190 ao C100 da nota,
#' e o C100 ao C001 do bloco), e depois os campos, na ordem do leiaute, a
#' começar pelo `REG`.
#' @section arquivos:
#' Uma linha por arquivo: `arquivo`, `inicio` e `fim` (o período, `DT_INI` e
#' `DT_FIN` do 0000), `versao` (o `COD_VER`, a versão do leiaute), `linhas`
#' (as lidas, até o 9999) e `problema` (por que o arquivo não pôde ser lido).
#' @section problemas:
#' Uma linha por linha do arquivo que não entrou numa tabela, ou por campo
#' que não pôde ser convertido: `arquivo`, `linha`, `registro`, `campo` e
#' `problema` (a linha fora do formato, o registro que o leiaute do período
#' não tem, o número de campos diferente do leiaute, o valor de número ou de
#' data fora do formato, que fica `NA` na tabela).
#'
#' @param arquivos O caminho de um arquivo, um vetor com vários ou o próprio
#'   texto do arquivo (que começa por `|0000|`).
#' @param registros Os registros que interessam (por exemplo,
#'   `c("C100", "C170")`); sem ele, todos. Num arquivo grande, ler só o que
#'   interessa poupa memória.
#' @return Uma lista com os `data.frame`s `arquivos` e `problemas` e uma
#'   tabela por registro lido.
#' @source Guia Prático da EFD ICMS/IPI, versão 3.2.2 (11/02/2026), e Nota
#'   Técnica 2025.001 v1.0 (leiaute versão 020), do portal do SPED (veja
#'   [tabela_fiscal()]).
#' @seealso [tabela_fiscal()] para o leiaute; [nfe_ler()] para as notas que o
#'   arquivo escritura.
#' @examples
#' arquivo = system.file("exemplos", "efd_icms_ipi_sp.txt", package = "RNFe")
#' efd = efd_icms_ipi_ler(arquivo)
#' efd$arquivos
#' efd$C100[, c("linha", "IND_OPER", "NUM_DOC", "CHV_NFE", "DT_DOC", "VL_DOC", "VL_ICMS")]
#' # Os itens de cada nota, pela linha do C100.
#' efd$C170[, c("linha_pai", "NUM_ITEM", "COD_ITEM", "CFOP", "VL_ITEM", "VL_ICMS")]
#' # Só as notas e os itens.
#' names(efd_icms_ipi_ler(arquivo, registros = c("C100", "C170")))
#' @export
efd_icms_ipi_ler = function(arquivos, registros = NULL) {
  arquivos = as.character(arquivos)
  if (!is.null(registros) && (!is.character(registros) || anyNA(registros))) {
    stop("Informe registros como um vetor de c\u00f3digos, por exemplo c(\"C100\", \"C170\").", call. = FALSE)
  }
  leiaute = tabela_fiscal("leiaute_efd_icms_ipi")
  if (!is.null(registros)) {
    desconhecidos = setdiff(registros, leiaute$registro)
    if (length(desconhecidos) > 0) {
      stop("Registro que o leiaute n\u00e3o tem: ", paste(desconhecidos, collapse = ", "), ".", call. = FALSE)
    }
  }
  resumos = vector("list", length(arquivos))
  problemas = vector("list", length(arquivos))
  tabelas_de_cada_arquivo = vector("list", length(arquivos))
  for (posicao in seq_along(arquivos)) {
    lido = ler_um_arquivo_da_efd(arquivos[posicao], posicao, leiaute, registros)
    resumos[[posicao]] = lido$resumo
    problemas[[posicao]] = lido$problemas
    tabelas_de_cada_arquivo[[posicao]] = lido$tabelas
  }
  resultado = list(
    arquivos = do.call(rbind, c(list(resumo_vazio_da_efd()), resumos)),
    problemas = do.call(rbind, c(list(problemas_vazios_da_efd()), problemas))
  )
  for (registro in registros_na_ordem_do_leiaute(tabelas_de_cada_arquivo, leiaute)) {
    pedacos = list()
    for (tabelas in tabelas_de_cada_arquivo) {
      if (!is.null(tabelas[[registro]])) {
        pedacos[[length(pedacos) + 1]] = tabelas[[registro]]
      }
    }
    resultado[[registro]] = juntar_com_as_colunas_de_todos(pedacos)
  }
  resultado
}

resumo_vazio_da_efd = function() {
  data.frame(arquivo = character(), inicio = as.Date(character()), fim = as.Date(character()), versao = character(),
             linhas = integer(), problema = character())
}

problemas_vazios_da_efd = function() {
  data.frame(arquivo = character(), linha = integer(), registro = character(), campo = character(),
             problema = character())
}

problemas_da_efd = function(nome_do_arquivo, linhas, registros, campos, motivos) {
  quantidade = length(linhas)
  data.frame(arquivo = rep(nome_do_arquivo, quantidade), linha = as.integer(linhas),
             registro = rep_len(as.character(registros), quantidade), campo = rep_len(as.character(campos), quantidade),
             problema = rep_len(as.character(motivos), quantidade))
}

ler_um_arquivo_da_efd = function(arquivo, posicao, leiaute, registros_pedidos) {
  e_texto = !is.na(arquivo) && startsWith(trimws(arquivo), "|0000|")
  nome_do_arquivo = if (e_texto) paste0("(texto ", posicao, ")") else arquivo
  resumo = data.frame(arquivo = nome_do_arquivo, inicio = as.Date(NA), fim = as.Date(NA), versao = NA_character_,
                      linhas = 0L, problema = NA_character_)
  sem_tabelas = list(resumo = resumo, problemas = problemas_vazios_da_efd(), tabelas = list())
  if (is.na(arquivo) || trimws(arquivo) == "") {
    sem_tabelas$resumo$problema = "vazio"
    return(sem_tabelas)
  }
  if (!e_texto && !file.exists(arquivo)) {
    sem_tabelas$resumo$problema = "arquivo n\u00e3o encontrado"
    return(sem_tabelas)
  }
  linhas = linhas_da_efd(arquivo, e_texto)
  resumo$linhas = length(linhas)
  campos_do_0000 = strsplit(substring(linhas[1], 2), "|", fixed = TRUE)[[1]]
  if (length(linhas) == 0 || !startsWith(linhas[1], "|0000|") || length(campos_do_0000) < 5) {
    sem_tabelas$resumo$linhas = length(linhas)
    sem_tabelas$resumo$problema = "n\u00e3o \u00e9 uma EFD ICMS/IPI: a primeira linha n\u00e3o \u00e9 o registro 0000"
    return(sem_tabelas)
  }
  resumo$versao = campos_do_0000[2]
  resumo$inicio = data_da_efd(campos_do_0000[4])
  resumo$fim = data_da_efd(campos_do_0000[5])
  if (is.na(resumo$inicio)) {
    resumo$problema = "a data inicial do registro 0000 (DT_INI) est\u00e1 fora do formato ddmmaaaa"
    return(list(resumo = resumo, problemas = problemas_vazios_da_efd(), tabelas = list()))
  }
  leiaute_do_periodo = leiaute[(is.na(leiaute$inicio) | leiaute$inicio <= resumo$inicio) &
                                 (is.na(leiaute$fim) | leiaute$fim >= resumo$inicio), ]
  leiaute_do_periodo = leiaute_do_periodo[order(leiaute_do_periodo$registro, leiaute_do_periodo$numero), ]
  registro_de_cada_linha = substr(linhas, 2, 5)
  linha_no_formato = startsWith(linhas, "|") & substr(linhas, 6, 6) == "|"
  registro_conhecido = registro_de_cada_linha %in% leiaute_do_periodo$registro
  nivel_de_cada_linha = leiaute_do_periodo$nivel[match(registro_de_cada_linha, leiaute_do_periodo$registro)]
  nivel_de_cada_linha[!linha_no_formato] = NA
  linha_pai = linha_pai_de_cada(nivel_de_cada_linha)
  problemas = list(problemas_da_efd(
    nome_do_arquivo, which(!linha_no_formato), NA, NA,
    "a linha n\u00e3o est\u00e1 no formato |REG|...| (registro de 4 caracteres entre barras)"
  ))
  fora_do_leiaute = which(linha_no_formato & !registro_conhecido)
  problemas[[2]] = problemas_da_efd(
    nome_do_arquivo, fora_do_leiaute, registro_de_cada_linha[fora_do_leiaute], NA,
    paste0("o leiaute do per\u00edodo do arquivo (", format(resumo$inicio, "%d/%m/%Y"), ") n\u00e3o tem o registro")
  )
  registros_a_ler = unique(registro_de_cada_linha[linha_no_formato & registro_conhecido])
  if (!is.null(registros_pedidos)) {
    registros_a_ler = intersect(registros_a_ler, registros_pedidos)
  }
  tabelas = list()
  for (registro in registros_a_ler) {
    campos_do_registro = leiaute_do_periodo[leiaute_do_periodo$registro == registro, ]
    posicoes = which(registro_de_cada_linha == registro & linha_no_formato)
    lida = tabela_do_registro(linhas[posicoes], posicoes, linha_pai[posicoes], campos_do_registro, nome_do_arquivo)
    tabelas[[registro]] = lida$tabela
    problemas[[length(problemas) + 1]] = lida$problemas
  }
  list(resumo = resumo, problemas = do.call(rbind, problemas), tabelas = tabelas)
}

# As linhas do arquivo até o registro 9999, como texto em UTF-8. O leiaute pede Latin-1; o Windows-1252 dá o mesmo
# texto (e os símbolos que o Latin-1 não tem); o arquivo em UTF-8 é reconhecido. A assinatura digital que o programa
# da Receita grava depois do 9999 tem bytes nulos: o corte vem antes de virar texto.
linhas_da_efd = function(arquivo, e_texto) {
  if (e_texto) {
    bytes = charToRaw(enc2utf8(arquivo))
  } else {
    bytes = readBin(arquivo, "raw", n = file.size(arquivo))
  }
  # A linha que começa pelo 9999 (o "|9999|" também aparece no meio do 9900 que o conta).
  inicio_do_9999 = grepRaw("\n|9999|", bytes, fixed = TRUE)
  if (length(inicio_do_9999) > 0) {
    fim_da_linha = grepRaw("\n", bytes, offset = inicio_do_9999 + 1, fixed = TRUE)
    if (length(fim_da_linha) > 0) {
      bytes = bytes[seq_len(fim_da_linha)]
    }
  }
  bytes = bytes[bytes != as.raw(0)]
  texto = rawToChar(bytes)
  if (!validUTF8(texto)) {
    texto = iconv(texto, from = "CP1252", to = "UTF-8", sub = "?")
  }
  Encoding(texto) = "UTF-8"
  # O arquivo em UTF-8 salvo com a marca de ordem dos bytes (BOM) no começo.
  texto = sub("^\ufeff", "", texto)
  linhas = strsplit(texto, "\r?\n")[[1]]
  linhas = sub("\r$", "", linhas)
  # As linhas em branco no fim não contam.
  while (length(linhas) > 0 && trimws(linhas[length(linhas)]) == "") {
    linhas = linhas[-length(linhas)]
  }
  linhas
}

data_da_efd = function(textos) {
  datas = as.Date(rep(NA_character_, length(textos)))
  no_formato = !is.na(textos) & grepl("^[0-9]{8}$", textos)
  datas[no_formato] = as.Date(textos[no_formato], format = "%d%m%Y")
  datas
}

# A linha do registro de nível acima de cada linha: a última, antes dela, com o nível um a menos (o C100 de cada C170;
# o C001 de cada C100). O nível vem do leiaute; a linha sem nível (fora do formato ou fora do leiaute) fica de fora.
linha_pai_de_cada = function(niveis) {
  pais = rep(NA_integer_, length(niveis))
  for (nivel in sort(unique(niveis[!is.na(niveis) & niveis >= 1]))) {
    deste_nivel = which(niveis %in% nivel)
    do_nivel_acima = which(niveis %in% (nivel - 1))
    if (length(do_nivel_acima) == 0) {
      next
    }
    indice_do_pai = findInterval(deste_nivel, do_nivel_acima)
    com_pai = indice_do_pai > 0
    pais[deste_nivel[com_pai]] = do_nivel_acima[indice_do_pai[com_pai]]
  }
  pais
}

# As linhas de um registro numa tabela: cada campo com o nome do leiaute e no tipo dele. A linha com o número de
# campos diferente do leiaute do período vai para os problemas.
tabela_do_registro = function(linhas_do_registro, posicoes, linhas_pai, campos_do_registro, nome_do_arquivo) {
  quantidade_esperada = nrow(campos_do_registro)
  pedacos = strsplit(substring(linhas_do_registro, 2), "|", fixed = TRUE)
  quantidade_lida = lengths(pedacos)
  certas = quantidade_lida == quantidade_esperada
  registro = campos_do_registro$registro[1]
  problemas = list(problemas_da_efd(
    nome_do_arquivo, posicoes[!certas], registro, NA,
    paste0("a linha tem ", quantidade_lida[!certas], " campos; o leiaute do per\u00edodo do arquivo tem ",
           quantidade_esperada)
  ))
  valores = matrix(as.character(unlist(pedacos[certas])), ncol = quantidade_esperada, byrow = TRUE)
  colunas = list(arquivo = rep(nome_do_arquivo, sum(certas)), linha = as.integer(posicoes[certas]),
                 linha_pai = as.integer(linhas_pai[certas]))
  for (numero_do_campo in seq_len(quantidade_esperada)) {
    campo = campos_do_registro[numero_do_campo, ]
    convertido = valores_do_campo(valores[, numero_do_campo], campo)
    colunas[[campo$coluna]] = convertido$valores
    if (length(convertido$fora_do_formato) > 0) {
      problemas[[length(problemas) + 1]] = problemas_da_efd(
        nome_do_arquivo, posicoes[certas][convertido$fora_do_formato], registro, campo$coluna,
        paste0("valor fora do formato (", convertido$formato, "): ", valores[convertido$fora_do_formato, numero_do_campo])
      )
    }
  }
  list(tabela = list2DF(colunas), problemas = do.call(rbind, problemas))
}

# O campo no tipo do leiaute: o DT_ vira data (ddmmaaaa), o número com casas decimais vira número (com a vírgula
# decimal), o resto fica texto. O vazio fica NA; o que não está no formato também, e vai para os problemas.
valores_do_campo = function(textos, campo) {
  textos[textos == ""] = NA
  if (startsWith(campo$campo, "DT_")) {
    valores = data_da_efd(textos)
    return(list(valores = valores, fora_do_formato = which(!is.na(textos) & is.na(valores)), formato = "ddmmaaaa"))
  }
  if (campo$tipo == "N" && campo$decimais != "-") {
    no_formato = grepl("^-?[0-9]+(,[0-9]+)?$", textos)
    valores = rep(NA_real_, length(textos))
    valores[no_formato] = as.numeric(sub(",", ".", textos[no_formato], fixed = TRUE))
    return(list(valores = valores, fora_do_formato = which(!is.na(textos) & !no_formato),
                formato = "n\u00famero com v\u00edrgula decimal"))
  }
  list(valores = textos, fora_do_formato = integer(), formato = "")
}

# Os registros lidos, na ordem do leiaute (o bloco 0, depois B, C, D, E, G, H, K, 1 e 9).
registros_na_ordem_do_leiaute = function(tabelas_de_cada_arquivo, leiaute) {
  lidos = unique(as.character(unlist(lapply(tabelas_de_cada_arquivo, names))))
  if (length(lidos) == 0) {
    return(character())
  }
  ordem_dos_blocos = match(substr(lidos, 1, 1), strsplit("0BCDEGHK19", "")[[1]])
  lidos[order(ordem_dos_blocos, lidos)]
}

# Junta as tabelas do mesmo registro de vários arquivos. Um arquivo antigo não tem os campos que entraram depois (e o
# E310 e o C177 antigos têm outros): cada tabela ganha as colunas que faltam, vazias, na ordem em que aparecem.
juntar_com_as_colunas_de_todos = function(tabelas) {
  if (length(tabelas) == 1) {
    return(tabelas[[1]])
  }
  todas_as_colunas = unique(unlist(lapply(tabelas, names)))
  for (coluna in todas_as_colunas) {
    # A coluna que falta vem vazia, com o tipo que tem nas outras tabelas: com NA lógico, o rbind tiraria a classe da
    # data que viesse depois.
    coluna_de_exemplo = NULL
    for (tabela in tabelas) {
      if (coluna %in% names(tabela)) {
        coluna_de_exemplo = tabela[[coluna]]
        break
      }
    }
    for (posicao in seq_along(tabelas)) {
      if (!(coluna %in% names(tabelas[[posicao]]))) {
        tabelas[[posicao]][[coluna]] = coluna_de_exemplo[rep(NA_integer_, nrow(tabelas[[posicao]]))]
      }
    }
  }
  for (posicao in seq_along(tabelas)) {
    tabelas[[posicao]] = tabelas[[posicao]][todas_as_colunas]
  }
  do.call(rbind, tabelas)
}
