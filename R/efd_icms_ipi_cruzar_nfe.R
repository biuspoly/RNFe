# O cruzamento da EFD ICMS/IPI com as NF-e e NFC-e (etapa 5, passo 2): cada nota do C100 com o XML dela, pela chave,
# e as notas do contribuinte que estão nos XML e não na escrituração.

#' @include efd_icms_ipi_ler.R nfe_ler.R
NULL

# O que o C100 e o XML devem trazer igual: o campo da EFD, a coluna do nfe_ler() e se o campo vale também na nota de
# terceiros. Na entrada, os impostos da EFD são os do crédito do declarante (o Guia Prático manda informar só o que dá
# direito a crédito): não se comparam com os do XML.
CAMPOS_DO_CRUZAMENTO = ler_campos("
campo_efd      coluna_xml       tipo   nas_entradas_de_terceiros
COD_MOD        modelo           texto  sim
SER            serie            serie  sim
NUM_DOC        numero           inteiro sim
DT_DOC         data_emissao     data   sim
VL_DOC         valor_nota       valor  sim
VL_DESC        valor_desconto   valor  sim
VL_MERC        valor_produtos   valor  sim
VL_FRT         valor_frete      valor  sim
VL_SEG         valor_seguro     valor  sim
VL_OUT_DA      valor_outros     valor  sim
VL_BC_ICMS     base_icms        valor  nao
VL_ICMS        valor_icms       valor  nao
VL_BC_ICMS_ST  base_icms_st     valor  nao
VL_ICMS_ST     valor_icms_st    valor  nao
VL_IPI         valor_ipi        valor  nao
VL_PIS         valor_pis        valor  nao
VL_COFINS      valor_cofins     valor  nao
")

# A situação do documento (COD_SIT, tabela 4.1.2 do Ato COTEPE/ICMS 44/2018): a escriturada sem valores (a cancelada, a
# denegada e a inutilizada só trazem a identificação).
SITUACOES_SEM_VALORES = c("02", "03", "04", "05")
SITUACOES_CANCELADAS = c("02", "03")

#' Cruzar a EFD ICMS/IPI com as NF-e e NFC-e
#'
#' Confere cada nota escriturada no C100 (modelos 55 e 65) com o XML dela,
#' pela chave de acesso, e lista as notas do contribuinte que estão nos XML e
#' não na escrituração: a que falta, o valor diferente, a data, o número, o
#' participante e a situação (a nota cancelada escriturada como regular, ou o
#' contrário). Nada é enviado: os dois lados são lidos dos arquivos.
#'
#' O que se compara:
#' - em toda nota: o modelo, a série, o número, a data de emissão, o valor do
#'   documento, o desconto, o valor das mercadorias, o frete, o seguro e as
#'   outras despesas, e o participante (o CNPJ ou CPF do 0150 do `COD_PART`
#'   contra o do outro lado da nota);
#' - na emissão própria, também a base e o valor do ICMS e do ICMS-ST e o IPI,
#'   o PIS e a COFINS. Na nota de terceiros, a EFD traz nesses campos só o
#'   crédito do declarante (o Guia Prático manda informar só o que dá direito a
#'   crédito), e eles não se comparam com o XML;
#' - o indicador do emitente (`IND_EMIT`) contra o emitente do XML, e o da
#'   operação (`IND_OPER`) contra o tipo da nota, na emissão própria;
#' - a situação (`COD_SIT`): a nota com o cancelamento em `eventos` (o evento
#'   110111) tem de estar escriturada como cancelada (02 ou 03), e a que não
#'   tem, como não cancelada. Sem `eventos`, a situação não é conferida.
#'
#' A nota cancelada, denegada ou inutilizada na EFD só traz a identificação: os
#' valores dela não se comparam. Os valores se comparam no centavo.
#'
#' As notas que faltam na EFD são as do XML em que o contribuinte do arquivo (o
#' CNPJ ou o CPF do 0000) é o emitente ou o destinatário, emitidas no período
#' do arquivo. A emissão própria tem de estar lá (a cancelada também, como
#' cancelada); a nota de terceiros pode ter entrado em outro período (a data
#' da entrada é a do recebimento) e vem com essa observação. A nota de
#' terceiros cancelada não é escriturada e não aparece.
#'
#' @section notas:
#' Uma linha por nota: `chave`, `onde` (`"nas duas"`, `"só na EFD"` ou
#' `"só nos XML"`), `arquivo_efd` e `linha_efd` (a linha do C100),
#' `emissao_propria`, `numero`, `data_emissao`, `valor_documento`,
#' `diferencas` (quantos campos não conferem) e `observacao`.
#' @section diferencas:
#' Uma linha por campo que não confere: `chave`, `arquivo_efd`, `linha_efd`,
#' `campo_efd`, `coluna_xml`, `na_efd`, `no_xml` (em texto) e `diferenca` (nos
#' valores, a EFD menos o XML).
#'
#' @param efd A EFD: o resultado de [efd_icms_ipi_ler()] ou os arquivos dela.
#' @param notas As notas: o resultado de [nfe_ler()] ou os XML (o caminho de
#'   um arquivo, vários ou o texto).
#' @param eventos Opcional: o resultado de [eventos_ler()] ou os XML dos
#'   eventos, para conferir a situação das notas canceladas.
#' @return Uma lista com os `data.frame`s `notas` e `diferencas`.
#' @seealso [efd_icms_ipi_ler()], [nfe_ler()], [eventos_ler()].
#' @examples
#' efd = system.file("exemplos", "efd_icms_ipi_sp.txt", package = "RNFe")
#' nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")
#' cruzamento = efd_icms_ipi_cruzar_nfe(efd, nota)
#' cruzamento$notas[, c("chave", "onde", "diferencas", "observacao")]
#' cruzamento$diferencas
#' @export
efd_icms_ipi_cruzar_nfe = function(efd, notas, eventos = NULL) {
  if (!is.list(efd) || !all(c("arquivos", "problemas") %in% names(efd))) {
    efd = efd_icms_ipi_ler(efd, registros = c("0000", "0150", "C100"))
  }
  if (!is.list(notas) || !all(c("notas", "itens") %in% names(notas))) {
    notas = nfe_ler(notas)
  }
  if (!is.null(eventos) && (!is.list(eventos) || !("eventos" %in% names(eventos)))) {
    eventos = eventos_ler(eventos)
  }
  if (is.null(efd$`0000`)) {
    stop("A EFD precisa do registro 0000 (e do 0150 e do C100): leia sem o argumento registros, ou com eles.",
         call. = FALSE)
  }
  do_xml = notas$notas[!duplicated(notas$notas$chave) & !is.na(notas$notas$chave), ]
  escrituradas = notas_escrituradas(efd)
  canceladas = chaves_canceladas(eventos)
  linhas_das_notas = list()
  linhas_das_diferencas = list()
  for (posicao in seq_len(nrow(escrituradas))) {
    escriturada = escrituradas[posicao, ]
    xml = do_xml[match(escriturada$CHV_NFE, do_xml$chave), ]
    if (is.na(escriturada$CHV_NFE) || is.na(xml$chave)) {
      linhas_das_notas[[length(linhas_das_notas) + 1]] = linha_da_nota(
        escriturada$CHV_NFE, "s\u00f3 na EFD", escriturada, escriturada$IND_EMIT == "0", escriturada$NUM_DOC,
        escriturada$DT_DOC, escriturada$VL_DOC, 0L,
        if (is.na(escriturada$CHV_NFE)) "O C100 n\u00e3o traz a chave." else "O XML da nota n\u00e3o est\u00e1 entre as notas."
      )
      next
    }
    diferencas = diferencas_da_nota(escriturada, xml, canceladas, !is.null(eventos))
    linhas_das_diferencas[[length(linhas_das_diferencas) + 1]] = diferencas
    linhas_das_notas[[length(linhas_das_notas) + 1]] = linha_da_nota(
      xml$chave, "nas duas", escriturada, escriturada$IND_EMIT == "0", escriturada$NUM_DOC, xml$data_emissao,
      xml$valor_nota, nrow(diferencas), NA_character_
    )
  }
  linhas_das_notas[[length(linhas_das_notas) + 1]] = notas_que_faltam_na_efd(efd, do_xml, escrituradas, canceladas)
  list(notas = do.call(rbind, c(list(notas_vazias_do_cruzamento()), linhas_das_notas)),
       diferencas = do.call(rbind, c(list(diferencas_vazias_do_cruzamento()), linhas_das_diferencas)))
}

notas_vazias_do_cruzamento = function() {
  data.frame(chave = character(), onde = character(), arquivo_efd = character(), linha_efd = integer(),
             emissao_propria = logical(), numero = character(), data_emissao = as.Date(character()),
             valor_documento = numeric(), diferencas = integer(), observacao = character())
}

diferencas_vazias_do_cruzamento = function() {
  data.frame(chave = character(), arquivo_efd = character(), linha_efd = integer(), campo_efd = character(),
             coluna_xml = character(), na_efd = character(), no_xml = character(), diferenca = numeric())
}

linha_da_nota = function(chave, onde, escriturada, emissao_propria, numero, data_emissao, valor_documento,
                         quantidade_de_diferencas, observacao) {
  data.frame(chave = chave, onde = onde,
             arquivo_efd = if (is.null(escriturada)) NA_character_ else escriturada$arquivo,
             linha_efd = if (is.null(escriturada)) NA_integer_ else escriturada$linha,
             emissao_propria = emissao_propria, numero = as.character(numero), data_emissao = as.Date(data_emissao),
             valor_documento = as.numeric(valor_documento), diferencas = as.integer(quantidade_de_diferencas),
             observacao = observacao)
}

# As notas do C100 (modelos 55 e 65), com o documento do participante (o CNPJ ou o CPF do 0150) e o do contribuinte
# do arquivo (o do 0000).
notas_escrituradas = function(efd) {
  c100 = efd$C100
  if (is.null(c100) || nrow(c100) == 0) {
    return(data.frame(arquivo = character(), linha = integer(), CHV_NFE = character(), IND_EMIT = character()))
  }
  c100 = c100[c100$COD_MOD %in% c("55", "65"), ]
  participantes = efd$`0150`
  if (is.null(participantes)) {
    c100$documento_do_participante = rep(NA_character_, nrow(c100))
  } else {
    documento = ifelse(is.na(participantes$CNPJ), participantes$CPF, participantes$CNPJ)
    c100$documento_do_participante = documento[match(paste(c100$arquivo, c100$COD_PART),
                                                     paste(participantes$arquivo, participantes$COD_PART))]
  }
  contribuintes = efd$`0000`
  documento_do_contribuinte = ifelse(is.na(contribuintes$CNPJ), contribuintes$CPF, contribuintes$CNPJ)
  c100$documento_do_contribuinte = documento_do_contribuinte[match(c100$arquivo, contribuintes$arquivo)]
  c100
}

# As chaves com o cancelamento (o evento 110111) aceito, ou sem o retorno (o evento lido sem o protocolo da SEFAZ).
chaves_canceladas = function(eventos) {
  if (is.null(eventos) || is.null(eventos$eventos) || nrow(eventos$eventos) == 0) {
    return(character())
  }
  cancelamentos = eventos$eventos[eventos$eventos$tipo %in% "110111", ]
  if ("situacao" %in% names(cancelamentos)) {
    cancelamentos = cancelamentos[is.na(cancelamentos$situacao) | cancelamentos$situacao %in% c(135, 136, 155), ]
  }
  unique(cancelamentos$chave)
}

# Os campos de uma nota que não conferem entre o C100 e o XML.
diferencas_da_nota = function(escriturada, xml, canceladas, com_eventos) {
  emissao_propria = escriturada$IND_EMIT %in% "0"
  sem_valores = escriturada$COD_SIT %in% SITUACOES_SEM_VALORES
  campos = CAMPOS_DO_CRUZAMENTO
  if (sem_valores) {
    campos = campos[campos$campo_efd %in% c("COD_MOD", "SER", "NUM_DOC"), ]
  } else if (!emissao_propria) {
    campos = campos[campos$nas_entradas_de_terceiros == "sim", ]
  }
  linhas = list()
  for (posicao in seq_len(nrow(campos))) {
    campo = campos[posicao, ]
    na_efd = escriturada[[campo$campo_efd]]
    no_xml = xml[[campo$coluna_xml]]
    if (is.na(na_efd) && is.na(no_xml)) {
      next
    }
    comparacao = comparar_campo(na_efd, no_xml, campo$tipo)
    if (!comparacao$confere) {
      linhas[[length(linhas) + 1]] = linha_da_diferenca(escriturada, xml$chave, campo$campo_efd, campo$coluna_xml,
                                                        comparacao$na_efd, comparacao$no_xml, comparacao$diferenca)
    }
  }
  # O emitente: a emissão própria é a nota emitida pelo contribuinte do arquivo.
  emitida_pelo_contribuinte = xml$emitente_documento %in% escriturada$documento_do_contribuinte
  if (emissao_propria != emitida_pelo_contribuinte) {
    linhas[[length(linhas) + 1]] = linha_da_diferenca(
      escriturada, xml$chave, "IND_EMIT", "emitente_documento", escriturada$IND_EMIT, xml$emitente_documento, NA_real_)
  }
  # A operação, na emissão própria: entrada (0) ou saída (1), como o tpNF.
  if (emissao_propria && !sem_valores && !is.na(xml$tipo_operacao) &&
      !(escriturada$IND_OPER %in% as.character(xml$tipo_operacao))) {
    linhas[[length(linhas) + 1]] = linha_da_diferenca(
      escriturada, xml$chave, "IND_OPER", "tipo_operacao", escriturada$IND_OPER, as.character(xml$tipo_operacao), NA_real_)
  }
  # O participante: o outro lado da nota (o destinatário na emissão própria, o emitente na de terceiros).
  documento_do_outro_lado = if (emitida_pelo_contribuinte) xml$destinatario_documento else xml$emitente_documento
  if (!sem_valores && !is.na(escriturada$documento_do_participante) &&
      !(escriturada$documento_do_participante %in% documento_do_outro_lado)) {
    coluna_do_outro_lado = if (emitida_pelo_contribuinte) "destinatario_documento" else "emitente_documento"
    linhas[[length(linhas) + 1]] = linha_da_diferenca(
      escriturada, xml$chave, "COD_PART (0150)", coluna_do_outro_lado, escriturada$documento_do_participante,
      documento_do_outro_lado, NA_real_)
  }
  # A situação, quando os eventos vieram: cancelada no XML e na EFD, ou em nenhum dos dois.
  if (com_eventos) {
    cancelada_no_xml = xml$chave %in% canceladas
    cancelada_na_efd = escriturada$COD_SIT %in% SITUACOES_CANCELADAS
    if (cancelada_no_xml != cancelada_na_efd) {
      linhas[[length(linhas) + 1]] = linha_da_diferenca(
        escriturada, xml$chave, "COD_SIT", "eventos (110111)", escriturada$COD_SIT,
        if (cancelada_no_xml) "cancelada" else "sem cancelamento", NA_real_)
    }
  }
  do.call(rbind, c(list(diferencas_vazias_do_cruzamento()), linhas))
}

comparar_campo = function(na_efd, no_xml, tipo) {
  if (tipo == "valor") {
    valor_da_efd = ifelse(is.na(na_efd), 0, na_efd)
    valor_do_xml = ifelse(is.na(no_xml), 0, no_xml)
    diferenca = round(valor_da_efd - valor_do_xml, 2)
    return(list(confere = abs(diferenca) < 0.005, na_efd = format_valor(na_efd), no_xml = format_valor(no_xml),
                diferenca = diferenca))
  }
  if (tipo %in% c("serie", "inteiro")) {
    numero_da_efd = suppressWarnings(as.numeric(na_efd))
    numero_do_xml = suppressWarnings(as.numeric(no_xml))
    return(list(confere = identical(numero_da_efd, numero_do_xml), na_efd = as.character(na_efd),
                no_xml = as.character(no_xml), diferenca = NA_real_))
  }
  if (tipo == "data") {
    return(list(confere = identical(as.Date(na_efd), as.Date(no_xml)), na_efd = format(as.Date(na_efd)),
                no_xml = format(as.Date(no_xml)), diferenca = NA_real_))
  }
  list(confere = identical(as.character(na_efd), as.character(no_xml)), na_efd = as.character(na_efd),
       no_xml = as.character(no_xml), diferenca = NA_real_)
}

format_valor = function(valor) {
  if (is.na(valor)) NA_character_ else formatC(valor, format = "f", digits = 2)
}

linha_da_diferenca = function(escriturada, chave, campo_efd, coluna_xml, na_efd, no_xml, diferenca) {
  data.frame(chave = chave, arquivo_efd = escriturada$arquivo, linha_efd = escriturada$linha, campo_efd = campo_efd,
             coluna_xml = coluna_xml, na_efd = as.character(na_efd), no_xml = as.character(no_xml),
             diferenca = as.numeric(diferenca))
}

# As notas do XML em que o contribuinte de algum arquivo da EFD é o emitente ou o destinatário, emitidas no período
# dele, e que não estão no C100 daquele arquivo. A de terceiros cancelada não é escriturada.
notas_que_faltam_na_efd = function(efd, do_xml, escrituradas, canceladas) {
  contribuintes = efd$`0000`
  if (is.null(contribuintes) || nrow(contribuintes) == 0 || nrow(do_xml) == 0) {
    return(notas_vazias_do_cruzamento())
  }
  linhas = list()
  for (posicao in seq_len(nrow(contribuintes))) {
    contribuinte = contribuintes[posicao, ]
    documento = if (is.na(contribuinte$CNPJ)) contribuinte$CPF else contribuinte$CNPJ
    no_periodo = !is.na(do_xml$data_emissao) & do_xml$data_emissao >= contribuinte$DT_INI &
      do_xml$data_emissao <= contribuinte$DT_FIN
    emitidas = do_xml$emitente_documento %in% documento
    recebidas = do_xml$destinatario_documento %in% documento & !emitidas
    escrituradas_no_arquivo = escrituradas$CHV_NFE[escrituradas$arquivo == contribuinte$arquivo]
    faltam = no_periodo & (emitidas | (recebidas & !(do_xml$chave %in% canceladas))) &
      !(do_xml$chave %in% escrituradas_no_arquivo)
    if (!any(faltam)) {
      next
    }
    observacao = ifelse(emitidas[faltam],
                        "Emiss\u00e3o pr\u00f3pria do per\u00edodo sem o C100 (a cancelada tamb\u00e9m \u00e9 escriturada, como cancelada).",
                        "Nota de terceiros do per\u00edodo sem o C100: a entrada pode ter sido escriturada em outro per\u00edodo.")
    linhas[[length(linhas) + 1]] = data.frame(
      chave = do_xml$chave[faltam], onde = "s\u00f3 nos XML", arquivo_efd = contribuinte$arquivo, linha_efd = NA_integer_,
      emissao_propria = emitidas[faltam], numero = as.character(do_xml$numero[faltam]),
      data_emissao = as.Date(do_xml$data_emissao[faltam]), valor_documento = as.numeric(do_xml$valor_nota[faltam]),
      diferencas = 0L, observacao = observacao
    )
  }
  do.call(rbind, c(list(notas_vazias_do_cruzamento()), linhas))
}
