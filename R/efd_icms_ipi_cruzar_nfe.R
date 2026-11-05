# O cruzamento da EFD ICMS/IPI com as NF-e e NFC-e (etapa 5, passo 2): cada nota do C100 com o XML dela, pela chave,
# e as notas do contribuinte que estão nos XML e não na escrituração.

#' @include efd_icms_ipi_ler.R nfe_ler.R
NULL

# O que o C100 e o XML devem trazer igual (Guia Prático 3.2.2, registro C100): o campo da EFD, a coluna do nfe_ler()
# (com "+", a soma das colunas), se o campo se compara na entrada e na NFC-e e se pode vir vazio. Na entrada, os
# impostos são os do crédito do declarante (o Guia manda informar só o que dá direito a crédito); o ICMS do C100 é a
# soma dos C190, que incluem o FCP; na NFC-e, o C100 não traz o ICMS-ST, o IPI, o PIS e a COFINS (exceção 9); e quem
# entrega a EFD-Contribuições deixa o PIS e a COFINS vazios.
CAMPOS_DO_CRUZAMENTO = ler_campos("
campo_efd      coluna_xml                 tipo    nas_entradas na_nfce pode_vir_vazio
COD_MOD        modelo                     texto   sim          sim     nao
SER            serie                      serie   sim          sim     nao
NUM_DOC        numero                     inteiro sim          sim     nao
DT_DOC         data_emissao               data    sim          sim     nao
VL_DOC         valor_nota                 valor   sim          sim     nao
VL_DESC        valor_desconto             valor   sim          sim     nao
VL_MERC        valor_produtos             valor   sim          sim     nao
VL_FRT         valor_frete                valor   sim          sim     nao
VL_SEG         valor_seguro               valor   sim          sim     nao
VL_OUT_DA      valor_outros               valor   sim          sim     nao
VL_BC_ICMS     base_icms                  valor   nao          sim     nao
VL_ICMS        valor_icms+valor_fcp       valor   nao          sim     nao
VL_BC_ICMS_ST  base_icms_st               valor   nao          nao     nao
VL_ICMS_ST     valor_icms_st+valor_fcp_st valor   nao          nao     nao
VL_IPI         valor_ipi                  valor   nao          nao     nao
VL_PIS         valor_pis                  valor   nao          nao     sim
VL_COFINS      valor_cofins               valor   nao          nao     sim
")

# A situação do documento (COD_SIT, tabela 4.1.2 do Ato COTEPE/ICMS 44/2018): a cancelada, a denegada e a inutilizada
# só trazem a identificação (exceção 1 do C100); na complementar (06 e 07) e na de regime especial (08), os valores são
# facultativos (exceções 3 e 4) e só se comparam quando vêm.
SITUACOES_SEM_VALORES = c("02", "03", "04", "05")
SITUACOES_COM_VALORES_FACULTATIVOS = c("06", "07", "08")
SITUACOES_CANCELADAS = c("02", "03")
CAMPOS_DA_IDENTIFICACAO = c("COD_MOD", "SER", "NUM_DOC")

# Os eventos que cancelam a nota (MOC 7.0): o cancelamento e o cancelamento por substituição, da NFC-e.
EVENTOS_DE_CANCELAMENTO = c("110111", "110112")

# A nota que se escritura: a autorizada (100) e a autorizada fora de prazo (150). A denegada deixou de ser obrigatória
# em 01/12/2021 (Ajustes SINIEF 34/2021 e 38/2021).
SITUACOES_QUE_SE_ESCRITURAM = c(100L, 150L)

# A partir de 2027, o valor total do documento inclui o IBS, a CBS e o IS (Guia, campo 12 do C100: em 2026 eles ficam
# fora).
INICIO_DO_VALOR_COM_IBS_CBS_IS = as.Date("2027-01-01")

#' Cruzar a EFD ICMS/IPI com as NF-e e NFC-e
#'
#' Confere cada nota escriturada no C100 (modelos 55 e 65) com o XML dela,
#' pela chave de acesso, e lista as notas do contribuinte que estão nos XML e
#' não na escrituração: a que falta, o valor diferente, a data, o número, o
#' participante e a situação (a nota cancelada escriturada como regular, ou o
#' contrário). Nada é enviado: os dois lados são lidos dos arquivos.
#'
#' O que se compara, pelo Guia Prático da EFD ICMS/IPI:
#' - em toda nota: o modelo, a série, o número, a data de emissão, o valor do
#'   documento, o desconto, o valor das mercadorias, o frete, o seguro e as
#'   outras despesas, e o participante (o CNPJ ou CPF do 0150 do `COD_PART`
#'   contra o do outro lado da nota). Na nota de 2027 em diante, o valor do
#'   documento confere com o valor da nota com ou sem o IBS, a CBS e o IS
#'   (`vNFTot` ou `vNF`);
#' - na saída, também a base e o valor do ICMS (com o FCP) e do ICMS-ST (com o
#'   FCP-ST), o IPI, o PIS e a COFINS. Na entrada, a EFD traz nesses campos só
#'   o crédito do declarante, e eles não se comparam. Na NFC-e, o C100 não traz
#'   o ICMS-ST, o IPI, o PIS e a COFINS; e o PIS e a COFINS vazios (de quem
#'   entrega a EFD-Contribuições) não se comparam;
#' - o indicador do emitente (`IND_EMIT`) contra o emitente do XML, e o da
#'   operação (`IND_OPER`) contra o tipo da nota, na emissão própria;
#' - a situação (`COD_SIT`): a nota com o cancelamento em `eventos` (o evento
#'   110111, ou o 110112, de cancelamento por substituição) tem de estar
#'   escriturada como cancelada (02 ou 03), e a que não tem, como não
#'   cancelada. Sem `eventos`, a situação não é conferida.
#'
#' A nota cancelada, denegada ou inutilizada na EFD só traz a identificação: os
#' valores dela não se comparam. Na complementar (`COD_SIT` 06 e 07) e na de
#' regime especial (08), os valores são facultativos e só se comparam quando
#' vêm. Os valores se comparam no centavo.
#'
#' As notas que faltam na EFD são as do XML em que o contribuinte do arquivo (o
#' CNPJ ou o CPF do 0000) é o emitente ou o destinatário, emitidas no período
#' do arquivo e autorizadas (a denegada não precisa ser escriturada). A emissão
#' própria tem de estar lá (a cancelada também, como cancelada); a nota de
#' terceiros pode ter entrado em outro período (a data da entrada é a do
#' recebimento) e vem com essa observação. A nota de terceiros cancelada e a
#' NFC-e recebida não são escrituradas e não aparecem.
#'
#' @section notas:
#' Uma linha por nota: `chave`, `onde` (`"nas duas"`, `"só na EFD"` ou
#' `"só nos XML"`), `arquivo_efd` e `linha_efd` (a linha do C100),
#' `emissao_propria`, `numero`, `data_emissao`, `valor_documento`,
#' `diferencas` (quantos campos não conferem) e `observacao`.
#' @section diferencas:
#' Uma linha por campo que não confere: `chave`, `arquivo_efd`, `linha_efd`,
#' `campo_efd`, `coluna_xml` (com `+`, a soma das colunas), `na_efd`, `no_xml`
#' (em texto) e `diferenca` (nos valores, a EFD menos o XML).
#'
#' @param efd A EFD: o resultado de [efd_icms_ipi_ler()] ou os arquivos dela.
#' @param notas As notas: o resultado de [nfe_ler()] ou os XML (o caminho de
#'   um arquivo, vários ou o texto).
#' @param eventos Opcional: o resultado de [eventos_ler()] ou os XML dos
#'   eventos, para conferir a situação das notas canceladas.
#' @return Uma lista com os `data.frame`s `notas` e `diferencas`.
#' @source Guia Prático da EFD ICMS/IPI, versão 3.2.2 (fevereiro de 2026),
#'   registros C100 e C190; Manual de Orientação do Contribuinte 7.0 da NF-e
#'   (os tipos de evento).
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
  if (nrow(escrituradas) == 0) {
    return(list(notas = notas_que_faltam_na_efd(efd, do_xml, escrituradas, canceladas),
                diferencas = diferencas_vazias_do_cruzamento()))
  }
  do_c100 = match(escrituradas$CHV_NFE, do_xml$chave)
  com_xml = !is.na(do_c100)
  pares = escrituradas[com_xml, ]
  xml_dos_pares = do_xml[do_c100[com_xml], ]
  diferencas = diferencas_das_notas(pares, xml_dos_pares, canceladas, !is.null(eventos))

  quantidade_de_diferencas = integer(nrow(escrituradas))
  quantidade_de_diferencas[com_xml] = tabulate(diferencas$par, nbins = nrow(pares))
  data_emissao = escrituradas$DT_DOC
  data_emissao[com_xml] = xml_dos_pares$data_emissao
  valor_documento = escrituradas$VL_DOC
  valor_documento[com_xml] = xml_dos_pares$valor_nota
  sem_xml = ifelse(is.na(escrituradas$CHV_NFE), "O C100 n\u00e3o traz a chave.",
                   "O XML da nota n\u00e3o est\u00e1 entre as notas.")
  notas_da_efd = data.frame(
    chave = escrituradas$CHV_NFE, onde = ifelse(com_xml, "nas duas", "s\u00f3 na EFD"), arquivo_efd = escrituradas$arquivo,
    linha_efd = escrituradas$linha, emissao_propria = escrituradas$IND_EMIT %in% "0",
    numero = as.character(escrituradas$NUM_DOC), data_emissao = as.Date(data_emissao),
    valor_documento = as.numeric(valor_documento), diferencas = quantidade_de_diferencas,
    observacao = ifelse(com_xml, NA_character_, sem_xml)
  )
  diferencas$par = NULL
  list(notas = rbind(notas_da_efd, notas_que_faltam_na_efd(efd, do_xml, escrituradas, canceladas)),
       diferencas = diferencas)
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

# As chaves com o cancelamento aceito, ou sem o retorno (o evento lido sem o protocolo da SEFAZ).
chaves_canceladas = function(eventos) {
  if (is.null(eventos) || is.null(eventos$eventos) || nrow(eventos$eventos) == 0) {
    return(character())
  }
  cancelamentos = eventos$eventos[eventos$eventos$tipo %in% EVENTOS_DE_CANCELAMENTO, ]
  if ("situacao" %in% names(cancelamentos)) {
    cancelamentos = cancelamentos[is.na(cancelamentos$situacao) | cancelamentos$situacao %in% c(135, 136, 155), ]
  }
  unique(cancelamentos$chave)
}

# Os campos que não conferem entre cada C100 e o XML dele (`pares` e `xml` com uma linha por nota, na mesma ordem),
# com a coluna `par`: a posição da nota em `pares`.
diferencas_das_notas = function(pares, xml, canceladas, com_eventos) {
  emissao_propria = pares$IND_EMIT %in% "0"
  entrada = pares$IND_OPER %in% "0"
  nfce = pares$COD_MOD %in% "65"
  sem_valores = pares$COD_SIT %in% SITUACOES_SEM_VALORES
  valores_facultativos = pares$COD_SIT %in% SITUACOES_COM_VALORES_FACULTATIVOS
  campos = CAMPOS_DO_CRUZAMENTO
  linhas = list(cbind(data.frame(par = integer(), ordem = integer()), diferencas_vazias_do_cruzamento()))
  for (posicao in seq_len(nrow(campos))) {
    campo = campos[posicao, ]
    na_efd = pares[[campo$campo_efd]]
    no_xml = valores_do_xml(xml, campo$coluna_xml)
    comparacao = comparar_campo(na_efd, no_xml, campo$tipo)
    if (campo$campo_efd == "VL_DOC") {
      com_ibs_cbs_is = (xml$data_emissao >= INICIO_DO_VALOR_COM_IBS_CBS_IS) %in% TRUE & !is.na(xml$valor_nota_com_ibs_cbs_is)
      pelo_total_com_ibs_cbs_is = abs(round(valor_ou_zero(na_efd) - xml$valor_nota_com_ibs_cbs_is, 2)) < 0.005
      comparacao$confere = comparacao$confere | (com_ibs_cbs_is & pelo_total_com_ibs_cbs_is %in% TRUE)
    }
    compara = !(is.na(na_efd) & is.na(no_xml))
    if (!(campo$campo_efd %in% CAMPOS_DA_IDENTIFICACAO)) {
      compara = compara & !sem_valores
    }
    if (campo$nas_entradas == "nao") {
      compara = compara & !entrada
    }
    if (campo$na_nfce == "nao") {
      compara = compara & !nfce
    }
    vazio_aceito = valores_facultativos | campo$pode_vir_vazio == "sim"
    compara = compara & !(is.na(na_efd) & vazio_aceito)
    linhas[[length(linhas) + 1]] = linhas_da_diferenca(pares, xml$chave, compara & !comparacao$confere, posicao,
                                                       campo$campo_efd, campo$coluna_xml, comparacao$na_efd,
                                                       comparacao$no_xml, comparacao$diferenca)
  }
  # O emitente: a emissão própria é a nota emitida pelo contribuinte do arquivo.
  emitida_pelo_contribuinte = (xml$emitente_documento == pares$documento_do_contribuinte) %in% TRUE
  linhas[[length(linhas) + 1]] = linhas_da_diferenca(pares, xml$chave, emissao_propria != emitida_pelo_contribuinte,
                                                     nrow(campos) + 1, "IND_EMIT", "emitente_documento", pares$IND_EMIT,
                                                     xml$emitente_documento, NA_real_)
  # A operação, na emissão própria: entrada (0) ou saída (1), como o tpNF.
  operacao_diferente = emissao_propria & !sem_valores & !is.na(xml$tipo_operacao) &
    !((pares$IND_OPER == as.character(xml$tipo_operacao)) %in% TRUE)
  linhas[[length(linhas) + 1]] = linhas_da_diferenca(pares, xml$chave, operacao_diferente, nrow(campos) + 2, "IND_OPER",
                                                     "tipo_operacao", pares$IND_OPER, as.character(xml$tipo_operacao),
                                                     NA_real_)
  # O participante: o outro lado da nota (o destinatário na emissão própria, o emitente na de terceiros).
  documento_do_outro_lado = ifelse(emitida_pelo_contribuinte, xml$destinatario_documento, xml$emitente_documento)
  participante_diferente = !sem_valores & !is.na(pares$documento_do_participante) &
    !((pares$documento_do_participante == documento_do_outro_lado) %in% TRUE)
  linhas[[length(linhas) + 1]] = linhas_da_diferenca(
    pares, xml$chave, participante_diferente, nrow(campos) + 3, "COD_PART (0150)",
    ifelse(emitida_pelo_contribuinte, "destinatario_documento", "emitente_documento"), pares$documento_do_participante,
    documento_do_outro_lado, NA_real_)
  # A situação, quando os eventos vieram: cancelada no XML e na EFD, ou em nenhum dos dois.
  if (com_eventos) {
    cancelada_no_xml = xml$chave %in% canceladas
    cancelada_na_efd = pares$COD_SIT %in% SITUACOES_CANCELADAS
    linhas[[length(linhas) + 1]] = linhas_da_diferenca(
      pares, xml$chave, cancelada_no_xml != cancelada_na_efd, nrow(campos) + 4, "COD_SIT", "eventos de cancelamento",
      pares$COD_SIT, ifelse(cancelada_no_xml, "cancelada", "sem cancelamento"), NA_real_)
  }
  juntas = do.call(rbind, linhas)
  juntas = juntas[order(juntas$par, juntas$ordem, method = "radix"), ]
  juntas$ordem = NULL
  rownames(juntas) = NULL
  juntas
}

# Os valores do XML para um campo: a coluna, ou a soma das colunas ligadas por "+" (vazia só se todas forem).
valores_do_xml = function(xml, coluna_xml) {
  colunas = strsplit(coluna_xml, "+", fixed = TRUE)[[1]]
  if (length(colunas) == 1) {
    return(xml[[colunas]])
  }
  soma = numeric(nrow(xml))
  alguma_informada = logical(nrow(xml))
  for (coluna in colunas) {
    soma = soma + valor_ou_zero(xml[[coluna]])
    alguma_informada = alguma_informada | !is.na(xml[[coluna]])
  }
  soma[!alguma_informada] = NA
  soma
}

# Compara os dois lados, nota a nota: confere, os textos de cada lado e a diferença (só nos valores).
comparar_campo = function(na_efd, no_xml, tipo) {
  if (tipo == "valor") {
    diferenca = round(valor_ou_zero(na_efd) - valor_ou_zero(no_xml), 2)
    return(list(confere = abs(diferenca) < 0.005, na_efd = texto_do_valor(na_efd), no_xml = texto_do_valor(no_xml),
                diferenca = diferenca))
  }
  if (tipo %in% c("serie", "inteiro")) {
    numero_da_efd = suppressWarnings(as.numeric(na_efd))
    numero_do_xml = suppressWarnings(as.numeric(no_xml))
    return(list(confere = iguais_ou_os_dois_vazios(numero_da_efd, numero_do_xml), na_efd = as.character(na_efd),
                no_xml = as.character(no_xml), diferenca = NA_real_))
  }
  if (tipo == "data") {
    return(list(confere = iguais_ou_os_dois_vazios(as.Date(na_efd), as.Date(no_xml)), na_efd = format(as.Date(na_efd)),
                no_xml = format(as.Date(no_xml)), diferenca = NA_real_))
  }
  list(confere = iguais_ou_os_dois_vazios(as.character(na_efd), as.character(no_xml)), na_efd = as.character(na_efd),
       no_xml = as.character(no_xml), diferenca = NA_real_)
}

iguais_ou_os_dois_vazios = function(de_um_lado, do_outro) {
  (de_um_lado == do_outro) %in% TRUE | (is.na(de_um_lado) & is.na(do_outro))
}

texto_do_valor = function(valores) {
  textos = formatC(valores, format = "f", digits = 2)
  textos[is.na(valores)] = NA_character_
  textos
}

# As linhas das notas em que um campo não confere (`errado`), com a posição da nota (`par`) e a do campo (`ordem`).
linhas_da_diferenca = function(pares, chaves, errado, ordem, campo_efd, coluna_xml, na_efd, no_xml, diferenca) {
  quantidade = nrow(pares)
  onde = which(errado)
  data.frame(par = onde, ordem = rep(as.integer(ordem), length(onde)), chave = chaves[onde],
             arquivo_efd = pares$arquivo[onde], linha_efd = pares$linha[onde],
             campo_efd = rep_len(campo_efd, quantidade)[onde], coluna_xml = rep_len(coluna_xml, quantidade)[onde],
             na_efd = rep_len(as.character(na_efd), quantidade)[onde],
             no_xml = rep_len(as.character(no_xml), quantidade)[onde],
             diferenca = rep_len(as.numeric(diferenca), quantidade)[onde])
}

# As notas do XML em que o contribuinte de algum arquivo da EFD é o emitente ou o destinatário, emitidas no período
# dele, e que não estão no C100 daquele arquivo. Só a nota autorizada se escritura (a denegada não precisa); a de
# terceiros cancelada e a NFC-e recebida (o Guia: "as NFC-e não devem ser escrituradas nas entradas") não entram.
notas_que_faltam_na_efd = function(efd, do_xml, escrituradas, canceladas) {
  contribuintes = efd$`0000`
  if (is.null(contribuintes) || nrow(contribuintes) == 0 || nrow(do_xml) == 0) {
    return(notas_vazias_do_cruzamento())
  }
  autorizada_ou_sem_protocolo = do_xml$situacao %in% SITUACOES_QUE_SE_ESCRITURAM | is.na(do_xml$situacao)
  linhas = list(notas_vazias_do_cruzamento())
  for (posicao in seq_len(nrow(contribuintes))) {
    contribuinte = contribuintes[posicao, ]
    documento = if (is.na(contribuinte$CNPJ)) contribuinte$CPF else contribuinte$CNPJ
    no_periodo = !is.na(do_xml$data_emissao) & do_xml$data_emissao >= contribuinte$DT_INI &
      do_xml$data_emissao <= contribuinte$DT_FIN
    emitidas = do_xml$emitente_documento %in% documento
    recebidas = do_xml$destinatario_documento %in% documento & !emitidas & !(do_xml$modelo %in% "65") &
      !(do_xml$chave %in% canceladas)
    escrituradas_no_arquivo = escrituradas$CHV_NFE[escrituradas$arquivo == contribuinte$arquivo]
    faltam = no_periodo & autorizada_ou_sem_protocolo & (emitidas | recebidas) &
      !(do_xml$chave %in% escrituradas_no_arquivo)
    if (!any(faltam)) {
      next
    }
    observacao = ifelse(emitidas[faltam],
                        "Emiss\u00e3o pr\u00f3pria do per\u00edodo sem o C100 (a cancelada tamb\u00e9m \u00e9 escriturada, como cancelada).",
                        "Nota de terceiros do per\u00edodo sem o C100: a entrada pode ter sido escriturada em outro per\u00edodo.")
    sem_protocolo = is.na(do_xml$situacao[faltam])
    observacao[sem_protocolo] = paste(observacao[sem_protocolo], "O XML n\u00e3o traz o protocolo de autoriza\u00e7\u00e3o.")
    linhas[[length(linhas) + 1]] = data.frame(
      chave = do_xml$chave[faltam], onde = "s\u00f3 nos XML", arquivo_efd = contribuinte$arquivo, linha_efd = NA_integer_,
      emissao_propria = emitidas[faltam], numero = as.character(do_xml$numero[faltam]),
      data_emissao = as.Date(do_xml$data_emissao[faltam]), valor_documento = as.numeric(do_xml$valor_nota[faltam]),
      diferencas = 0L, observacao = observacao
    )
  }
  do.call(rbind, linhas)
}
