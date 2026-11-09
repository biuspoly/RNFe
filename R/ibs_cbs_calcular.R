# O cálculo do IBS e da CBS de cada item da NF-e e da NFC-e (etapa 4, passo 3): a base pelos componentes do item, as
# alíquotas do ano, a redução da classificação, o diferimento e a tributação regular, pelas mesmas fórmulas que a
# conferência usa. A calculadora oficial da Receita serviu de gabarito (veja docs/plano.md).

#' @include ler_xml.R tabelas.R ibs_cbs_conferir.R
NULL

# Os componentes da base (UB16-10 da NT 2025.002, que confere com o art. 12 da LC 214/2025): o sinal, os marcos em que
# entram e saem (tabela_fiscal("marcos_ibs_cbs"): entra no dia do primeiro e sai no dia do segundo), se valem no bem,
# no serviço ou nos dois, e em que modelo. Os períodos, a natureza e o modelo são os da calculadora oficial, que ignora
# o componente fora deles: o PIS e a COFINS só em 2026 (em 2025 vale a regra de 2026); o ICMS, o FCP e o ISSQN até
# 2032 (art. 12, § 2º, V); o II e o ICMS só no bem; o ISSQN só no serviço; o Imposto Seletivo de 2027 a 2033; o II, o
# ICMS da UF de destino e o FCP dele só na NF-e (modelo 55).
COMPONENTES_DA_BASE = ler_campos("
coluna                caminho                         sinal entra_no_marco                 sai_no_marco                   natureza modelos
valor_produto         prod/vProd                      1     inicio_do_calculo              fim_do_calculo                 ambas    55/65
valor_frete           prod/vFrete                     1     inicio_do_calculo              fim_do_calculo                 ambas    55/65
valor_seguro          prod/vSeg                       1     inicio_do_calculo              fim_do_calculo                 ambas    55/65
valor_outros          prod/vOutro                     1     inicio_do_calculo              fim_do_calculo                 ambas    55/65
valor_ii              imposto/II/vII                  1     inicio_do_calculo              fim_do_calculo                 bem      55
valor_is              imposto/IS/vIS                  1     imposto_seletivo_na_base_desde fim_do_calculo                 ambas    55/65
valor_desconto        prod/vDesc                      -1    inicio_do_calculo              fim_do_calculo                 ambas    55/65
valor_pis             imposto/PIS/*/vPIS              -1    inicio_do_calculo              fim_do_pis_e_da_cofins_na_base ambas    55/65
valor_cofins          imposto/COFINS/*/vCOFINS        -1    inicio_do_calculo              fim_do_pis_e_da_cofins_na_base ambas    55/65
valor_icms            imposto/ICMS/*/vICMS            -1    inicio_do_calculo              fim_do_icms_e_do_issqn_na_base bem      55/65
valor_icms_uf_destino imposto/ICMSUFDest/vICMSUFDest  -1    inicio_do_calculo              fim_do_icms_e_do_issqn_na_base bem      55
valor_fcp             imposto/ICMS/*/vFCP             -1    inicio_do_calculo              fim_do_icms_e_do_issqn_na_base bem      55/65
valor_fcp_uf_destino  imposto/ICMSUFDest/vFCPUFDest   -1    inicio_do_calculo              fim_do_icms_e_do_issqn_na_base bem      55
valor_icms_monofasico imposto/ICMS/*/vICMSMono        -1    inicio_do_calculo              fim_do_icms_e_do_issqn_na_base bem      55/65
valor_issqn           imposto/ISSQN/vISSQN            -1    inicio_do_calculo              fim_do_icms_e_do_issqn_na_base servico  55/65
")

# Os CSTs que o cálculo cobre: com o grupo do IBS e da CBS, a tributação integral (000), a redução (200), o diferimento
# (510 e 515) e a suspensão com a tributação regular (550); sem o grupo, a isenção (400) e a imunidade (410).
CST_CALCULADOS = c("000", "200", "510", "515", "550")
CST_SEM_O_GRUPO = c("400", "410")

# O resto do item, a partir do det, e o da nota, a partir do infNFe. Os nomes são os de nfe_ler()$itens.
CAMPOS_DO_ITEM_PARA_CALCULAR = ler_campos("
coluna                         caminho                                                tipo
item                           @nItem                                                 inteiro
cst_ibs_cbs                    imposto/IBSCBS/CST                                     texto
classificacao_ibs_cbs          imposto/IBSCBS/cClassTrib                              texto
diferimento_ibs_uf             imposto/IBSCBS/gIBSCBS/gIBSUF/gDif/pDif                numero
diferimento_ibs_municipio      imposto/IBSCBS/gIBSCBS/gIBSMun/gDif/pDif               numero
diferimento_cbs                imposto/IBSCBS/gIBSCBS/gCBS/gDif/pDif                  numero
valor_devolvido_ibs_uf         imposto/IBSCBS/gIBSCBS/gIBSUF/gDevTrib/vDevTrib        numero
valor_devolvido_ibs_municipio  imposto/IBSCBS/gIBSCBS/gIBSMun/gDevTrib/vDevTrib       numero
valor_devolvido_cbs            imposto/IBSCBS/gIBSCBS/gCBS/gDevTrib/vDevTrib          numero
cst_regular                    imposto/IBSCBS/gIBSCBS/gTribRegular/CSTReg             texto
classificacao_regular          imposto/IBSCBS/gIBSCBS/gTribRegular/cClassTribReg      texto
credito_presumido_codigo       imposto/IBSCBS/gCredPresOper/cCredPres                 texto
")
CAMPOS_DA_NOTA_PARA_CALCULAR = ler_campos("
coluna        caminho     tipo
modelo        ide/mod     texto
data_emissao  ide/dhEmi   texto
finalidade    ide/finNFe  texto
")

# As colunas de número que os itens podem trazer num data.frame.
COLUNAS_DE_NUMERO_DO_CALCULO = c(COMPONENTES_DA_BASE$coluna, "base", "diferimento_ibs_uf", "diferimento_ibs_municipio",
                                 "diferimento_cbs", "valor_devolvido_ibs_uf", "valor_devolvido_ibs_municipio",
                                 "valor_devolvido_cbs")
COLUNAS_DE_TEXTO_DO_CALCULO = c("chave", "modelo", "finalidade", "cst_regular", "classificacao_regular",
                                "credito_presumido_codigo")
PARTES_DO_CALCULO = c("ibs_uf", "ibs_municipio", "cbs")

#' Calcular o IBS e a CBS de uma NF-e, de uma NFC-e ou de itens
#'
#' Calcula o IBS (da UF e do município) e a CBS de cada item, na data da nota
#' ou na que você escolher: a base pelos componentes do item, as alíquotas do
#' ano, a redução da classificação tributária, o diferimento e a tributação
#' regular. Serve para saber o que uma nota deveria trazer e para simular como
#' ela seria em outro ano (por exemplo, 2027, quando o PIS e a COFINS saem da
#' base e a CBS passa à alíquota de referência).
#'
#' A conta é a mesma que a [ibs_cbs_conferir()] confere:
#' - a base (`vBC`) é a soma da UB16-10 da NT 2025.002: o produto, o frete, o
#'   seguro, as outras despesas, o II e o Imposto Seletivo, menos o desconto, o
#'   PIS, a COFINS, o ICMS, o ICMS da UF de destino, o FCP, o ICMS monofásico e
#'   o ISSQN. Cada componente só entra no ano, na natureza e no modelo em que a
#'   calculadora oficial da Receita o aceita: o PIS e a COFINS só em 2026 (o
#'   art. 12, § 2º, V da LC 214/2025 os tira da base de 2026 a 2032, e a
#'   calculadora não os aceita depois de 2026); o ICMS, o FCP e o ISSQN até
#'   2032; o II e o ICMS só no bem; o ISSQN só no serviço (o item com ISSQN); o
#'   Imposto Seletivo a partir de 2027; o II, o ICMS da UF de destino e o FCP
#'   dele só na NF-e. Em 2025 vale a regra de 2026 (a NT aceita em 2025 as
#'   alíquotas de 2026; a calculadora não calcula 2025). Essas datas vêm de
#'   `tabela_fiscal("marcos_ibs_cbs")`, não do código. O PIS e a COFINS por
#'   substituição tributária não entram (a calculadora não tem esses campos, e
#'   a UB16-10 ainda é implementação futura). A base pode vir pronta, na coluna
#'   `base`;
#' - a alíquota é a do ano (veja `tabela_fiscal("aliquotas_ibs_cbs")`), ou a que
#'   você passar em `aliquotas`; a da classificação com tributação regular é
#'   zero;
#' - com a redução (CST 200 e 515), a alíquota efetiva é a alíquota menos o
#'   percentual da classificação, em 4 casas;
#' - com o diferimento (CST 510 e 515), o valor diferido é a base vezes a
#'   alíquota vezes o percentual, que vem da nota ou de você (a tabela da
#'   classificação não traz o percentual);
#' - o valor é a base vezes a alíquota, menos o diferido, em 2 casas, com o
#'   meio centavo indo para o par (0,125 vai a 0,12), como a calculadora
#'   oficial (a NT não diz e aceita 0,01 de diferença); o IBS do item é o da UF
#'   mais o do município (UB54a-10);
#' - na tributação regular (a suspensão, CST 550, e as classificações que a
#'   pedem), o grupo `gTribRegular` com a alíquota e o valor da classificação
#'   regular informada.
#'
#' Conferido com a calculadora oficial da Receita em 51 itens inventados, de 11
#' classificações (uma de cada caso acima), em 2026, 2027 e 2030: tudo igual,
#' menos em dois pontos em que o RNFe segue a NT, que é o que a SEFAZ confere: o
#' IBS do item é a soma da UF e do município (a calculadora arredonda o total à
#' parte, e em 3 itens ele saiu 0,01 diferente da soma), e a classificação com
#' tributação regular no CST 200 traz a redução (a UB26-20 exige o grupo; a
#' calculadora não o traz).
#'
#' Fica sem calcular, com o motivo em `observacao`: a nota que não é normal
#' (a complementar, a de ajuste, a devolução e as notas de crédito e de débito,
#' que dependem da operação original: na devolução, a base é a dela, pelo art.
#' 12, § 7º); o monofásico (CST 620), a transferência de crédito, os ajustes e a
#' tributação em documento específico (CST 800 a 820), a exclusão da base (CST
#' 830, que a calculadora oficial também ainda não trata), as alíquotas fixas e
#' uniformes (CST 010, 011, 220, 221 e 222); o item com crédito presumido da
#' operação ou com valor de devolução de tributos (o grupo com zero não muda a
#' conta e é calculado); a compra governamental (o redutor de
#' cada ente e ano não está nas tabelas); a base negativa (a calculadora a
#' recusa); e o item sem a data, ou fora de 2025 a 2033. O Imposto Seletivo não
#' é calculado (o valor dele só entra na base). As alíquotas da tabela vão até
#' 2028 e a CBS de 2027 em diante não foi publicada: sem elas, o valor fica
#' vazio, a menos que você as passe em `aliquotas`.
#'
#' @section itens:
#' Uma linha por item: `chave`, `item`, `data_calculo` (a data usada),
#' `cst_ibs_cbs`, `classificacao_ibs_cbs`, `servico` (o item com ISSQN é
#' serviço), `base`, e para `ibs_uf`, `ibs_municipio` e `cbs`: `aliquota_*`,
#' `reducao_*`, `aliquota_efetiva_*`, `diferimento_*` (percentual),
#' `valor_diferido_*` e `valor_*`; `valor_ibs` (o da UF mais o do município);
#' `cst_regular`, `classificacao_regular`, `aliquota_regular_*` e
#' `valor_regular_*` (a tributação regular); `tem_grupo_ibs_cbs` (o item leva o
#' grupo `gIBSCBS`); `calculado` (`TRUE` quando tudo foi calculado) e
#' `observacao`. Os percentuais são como no XML (0,9 é 0,9%). A mesma nota em
#' mais de um arquivo é calculada uma vez.
#'
#' @section notas:
#' Uma linha por nota (pela `chave`; os itens sem chave juntos, numa linha sem
#' chave): `chave`, `itens`, `itens_calculados`, `base`, `valor_ibs_uf`,
#' `valor_ibs_municipio`, `valor_ibs` e `valor_cbs`, somados nos itens
#' calculados.
#'
#' @param entrada O que calcular:
#'   - os XMLs da NF-e ou da NFC-e: o caminho de um arquivo, um vetor com
#'     vários ou o próprio texto do XML;
#'   - o resultado inteiro de [nfe_ler()] (a lista): a data, o modelo, a
#'     finalidade e a compra governamental vêm de `notas`, e o resto de
#'     `itens`. Só `nfe_ler()$itens` não serve, porque não traz o que está na
#'     nota (a função recusa, com a explicação);
#'   - um `data.frame` de itens que você monta: `cst_ibs_cbs`,
#'     `classificacao_ibs_cbs` e os componentes da base (`valor_produto`,
#'     `valor_frete`, `valor_seguro`, `valor_outros`, `valor_desconto`,
#'     `valor_ii`, `valor_is`, `valor_pis`, `valor_cofins`, `valor_icms`,
#'     `valor_icms_uf_destino`, `valor_fcp`, `valor_fcp_uf_destino`,
#'     `valor_icms_monofasico`, `valor_issqn`; o que faltar conta como zero) ou
#'     a `base` pronta, em número. Opcionais: `chave`, `item`, `data_emissao`,
#'     `modelo` (`"55"` sem ela), `finalidade` (`"1"`, a nota normal, sem ela),
#'     `compra_governamental` (`TRUE` ou `FALSE`), `servico` (sem ela, o item
#'     com `valor_issqn` acima de zero é serviço), `diferimento_ibs_uf`,
#'     `diferimento_ibs_municipio`, `diferimento_cbs`, `cst_regular`,
#'     `classificacao_regular`, `credito_presumido_codigo`,
#'     `valor_devolvido_ibs_uf`, `valor_devolvido_ibs_municipio` e
#'     `valor_devolvido_cbs`.
#' @param data A data do cálculo (`Date`, data e hora, que vale no horário de
#'   Brasília, ou `"AAAA-MM-DD"`). Sem ela, a data de emissão de cada nota (ou a
#'   coluna `data_emissao`).
#' @param aliquotas As alíquotas, em percentual, no lugar das da tabela: um
#'   vetor com nomes entre `ibs_uf`, `ibs_municipio` e `cbs` (por exemplo,
#'   `c(cbs = 8.7)` para simular 2027 com uma estimativa da CBS).
#' @return Uma lista com os `data.frame`s `itens` e `notas` e, com XML,
#'   `arquivos` (o que foi lido e o motivo do que não deu, como em
#'   [nfe_ler()]).
#' @source Nota Técnica 2025.002-RTC, versão 1.53 (Portal Nacional da NF-e):
#'   a base (UB16-10) e as contas do grupo UB; LC 214/2025, art. 12 (a base) e
#'   as alíquotas de cada ano (veja [tabela_fiscal()]); a calculadora oficial da
#'   Receita Federal (piloto, versão 1.6.2, base de regras V0066), para a
#'   vigência de cada componente e como gabarito.
#' @seealso [ibs_cbs_conferir()] para conferir o que a nota trouxe;
#'   [nfe_ler()] para ler as notas.
#' @examples
#' nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")
#' ibs_cbs_calcular(nota)$itens[, c("item", "base", "valor_ibs_uf", "valor_cbs")]
#' # A mesma nota em 2027, com uma estimativa da CBS de referência.
#' em_2027 = ibs_cbs_calcular(nota, data = "2027-03-10", aliquotas = c(cbs = 8.7))
#' em_2027$notas
#' # Pelo que o nfe_ler() leu (a lista inteira).
#' ibs_cbs_calcular(nfe_ler(nota))$notas
#' # Itens soltos, sem nota.
#' itens = data.frame(cst_ibs_cbs = c("000", "200"), classificacao_ibs_cbs = c("000001", "200047"),
#'                    valor_produto = c(100, 50), valor_icms = c(18, 9))
#' ibs_cbs_calcular(itens, data = "2026-11-04")$itens
#' @export
ibs_cbs_calcular = function(entrada, data = NULL, aliquotas = NULL) {
  data_do_calculo = data_pedida_no_calculo(data)
  aliquotas_pedidas = aliquotas_pedidas_no_calculo(aliquotas)
  arquivos = NULL
  if (is.data.frame(entrada)) {
    if ("classificacao_ibs_cbs_nome" %in% names(entrada) && !("finalidade" %in% names(entrada))) {
      stop("Isto parece nfe_ler()$itens: passe o resultado inteiro do nfe_ler() (a lista), porque a data, a finalidade ",
           "e a compra governamental est\u00e3o nas notas.", call. = FALSE)
    }
    itens = itens_da_tabela_para_calcular(entrada)
  } else if (is.list(entrada) && all(c("notas", "itens") %in% names(entrada))) {
    itens = itens_da_tabela_para_calcular(itens_com_os_campos_da_nota(entrada$itens, entrada$notas))
  } else {
    arquivos_lidos = ler_arquivos_xml(entrada, CAMINHO_DAS_NOTAS_PARA_CONFERIR, "uma NF-e", colunas_para_calcular, FALSE)
    itens = juntar_tabela(arquivos_lidos, "itens", colunas_para_calcular(NULL, NA_character_, FALSE)$itens)
    arquivos = resumo_dos_arquivos(arquivos_lidos, "notas", "notas")
  }
  # A mesma nota em mais de um arquivo conta uma vez.
  repetido = !is.na(itens$chave) & duplicated(paste(itens$chave, itens$item))
  itens = itens[!repetido, , drop = FALSE]
  if (!is.na(data_do_calculo)) {
    itens$data_emissao = rep(data_do_calculo, nrow(itens))
  }
  calculados = calcular_os_itens(itens, aliquotas_pedidas)
  resultado = list(itens = calculados, notas = somar_as_notas(calculados))
  if (!is.null(arquivos)) {
    resultado$arquivos = arquivos
  }
  resultado
}

# Uma data só, como Date (a data e hora vale no horário de Brasília). NA quando não pedida.
data_pedida_no_calculo = function(data) {
  if (is.null(data)) {
    return(as.Date(NA))
  }
  if (length(data) != 1) {
    stop("Informe uma data s\u00f3, como Date ou \"AAAA-MM-DD\".", call. = FALSE)
  }
  data_convertida = datas_do_calculo(data, "data")
  if (is.na(data_convertida)) {
    stop("Informe uma data s\u00f3, como Date ou \"AAAA-MM-DD\".", call. = FALSE)
  }
  data_convertida
}

# As datas de uma coluna ou do argumento, como Date: a data e hora vale no horário de Brasília; o texto, só no formato
# AAAA-MM-DD (com a hora depois, como no dhEmi, ou sem).
datas_do_calculo = function(valores, nome) {
  if (inherits(valores, "Date")) {
    return(valores)
  }
  if (inherits(valores, c("POSIXct", "POSIXlt"))) {
    return(as.Date(format(valores, "%Y-%m-%d", tz = "America/Sao_Paulo")))
  }
  if (is.logical(valores) && all(is.na(valores))) {
    return(as.Date(rep(NA_character_, length(valores))))
  }
  if (!is.character(valores) || any(!is.na(valores) & !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}", valores))) {
    stop("A ", nome, " tem de ser Date, data e hora ou texto no formato \"AAAA-MM-DD\".", call. = FALSE)
  }
  datas = as.Date(substr(valores, 1, 10), optional = TRUE)
  if (any(!is.na(valores) & is.na(datas))) {
    stop("A ", nome, " tem um dia que n\u00e3o existe.", call. = FALSE)
  }
  datas
}

aliquotas_pedidas_no_calculo = function(aliquotas) {
  pedidas = c(ibs_uf = NA_real_, ibs_municipio = NA_real_, cbs = NA_real_)
  if (is.null(aliquotas)) {
    return(pedidas)
  }
  if (!is.numeric(aliquotas) || is.null(names(aliquotas)) || !all(names(aliquotas) %in% PARTES_DO_CALCULO) ||
      anyDuplicated(names(aliquotas)) > 0 || any(!is.finite(aliquotas)) || any(aliquotas < 0)) {
    stop("Informe aliquotas como um vetor de n\u00fameros com nomes entre ibs_uf, ibs_municipio e cbs, em percentual ",
         "(por exemplo, c(cbs = 8.7)).", call. = FALSE)
  }
  pedidas[names(aliquotas)] = aliquotas
  pedidas
}

# As colunas de um arquivo: os itens de cada nota, com a data, o modelo, a finalidade e a compra governamental da nota.
# Com xml_lido NULL, vêm vazias.
colunas_para_calcular = function(xml_lido, nome_do_arquivo, todos_os_campos) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  elementos_das_notas = buscar_todos(xml_lido, CAMINHO_DAS_NOTAS_PARA_CONFERIR)
  elementos_das_notas = elementos_das_notas[!duplicated(chave_de_cada(elementos_das_notas, "infNFe"))]
  elementos_dos_itens = buscar_todos(elementos_das_notas, "det")
  notas = data.frame(c(
    list(chave = chave_de_cada(elementos_das_notas, "infNFe")),
    valores_dos_campos(elementos_das_notas, CAMPOS_DA_NOTA_PARA_CALCULAR),
    list(compra_governamental = !is.na(xml2::xml_name(xml2::xml_find_first(elementos_das_notas, "ide/gCompraGov",
                                                                           ns = SEM_NAMESPACE))))
  ))
  itens = data.frame(c(
    list(chave = chave_de_cada(elementos_dos_itens, "infNFe")),
    valores_dos_campos(elementos_dos_itens, CAMPOS_DO_ITEM_PARA_CALCULAR),
    valores_dos_campos(elementos_dos_itens, campos_dos_componentes()),
    list(servico = !is.na(xml2::xml_name(xml2::xml_find_first(elementos_dos_itens, "imposto/ISSQN", ns = SEM_NAMESPACE))))
  ))
  da_nota = match(itens$chave, notas$chave)
  itens$data_emissao = as.Date(substr(notas$data_emissao[da_nota], 1, 10))
  itens$modelo = notas$modelo[da_nota]
  itens$finalidade = notas$finalidade[da_nota]
  itens$compra_governamental = notas$compra_governamental[da_nota]
  itens$base = rep(NA_real_, nrow(itens))
  list(notas = as.list(notas), itens = as.list(itens))
}

# Os componentes da base como lista de campos do XML (coluna, caminho e tipo).
campos_dos_componentes = function() {
  data.frame(coluna = COMPONENTES_DA_BASE$coluna, caminho = COMPONENTES_DA_BASE$caminho, tipo = "numero")
}

# Os itens do nfe_ler() com o que vem da nota deles: a data, o modelo, a finalidade e a compra governamental.
itens_com_os_campos_da_nota = function(itens, notas) {
  if (!is.data.frame(itens) || !is.data.frame(notas) || !all(c("chave", "item") %in% names(itens))) {
    stop("A lista precisa ser o resultado do nfe_ler(), com notas e itens.", call. = FALSE)
  }
  da_nota = match(itens$chave, notas$chave)
  itens$data_emissao = notas$data_emissao[da_nota]
  itens$modelo = as.character(notas$modelo[da_nota])
  itens$finalidade = as.character(notas$finalidade[da_nota])
  itens$compra_governamental = !is.na(notas$compra_governamental_ente[da_nota])
  # No nfe_ler(), o valor_issqn só vem com o grupo ISSQN, que é o que faz do item um serviço (como no XML).
  itens$servico = !is.na(itens$valor_issqn)
  itens
}

# Uma coluna de número de um data.frame: o texto só vale com ponto decimal; fator e outros tipos são recusados.
numeros_da_coluna = function(valores, nome) {
  if (is.numeric(valores)) {
    return(as.numeric(valores))
  }
  if (is.logical(valores) && all(is.na(valores))) {
    return(as.numeric(valores))
  }
  if (is.character(valores)) {
    numeros = suppressWarnings(as.numeric(valores))
    if (any(!is.na(valores) & is.na(numeros))) {
      stop("A coluna ", nome, " tem texto que n\u00e3o \u00e9 n\u00famero (o separador decimal \u00e9 o ponto).", call. = FALSE)
    }
    return(numeros)
  }
  stop("A coluna ", nome, " tem de ser de n\u00fameros (veio ", class(valores)[1], ").", call. = FALSE)
}

# Os itens de um data.frame, com as colunas que faltam vazias e cada uma no tipo certo.
itens_da_tabela_para_calcular = function(tabela) {
  quantidade = nrow(tabela)
  if (!all(c("cst_ibs_cbs", "classificacao_ibs_cbs") %in% names(tabela))) {
    stop("Os itens precisam das colunas cst_ibs_cbs e classificacao_ibs_cbs (como em nfe_ler()$itens).", call. = FALSE)
  }
  if (!any(c("base", "valor_produto") %in% names(tabela))) {
    stop("Os itens precisam da base pronta (coluna base) ou dos componentes dela (pelo menos valor_produto).",
         call. = FALSE)
  }
  itens = data.frame(
    item = if ("item" %in% names(tabela)) as.integer(as.character(tabela$item)) else seq_len(quantidade),
    cst_ibs_cbs = as.character(tabela$cst_ibs_cbs),
    classificacao_ibs_cbs = as.character(tabela$classificacao_ibs_cbs)
  )
  for (coluna in COLUNAS_DE_TEXTO_DO_CALCULO) {
    itens[[coluna]] = if (coluna %in% names(tabela)) as.character(tabela[[coluna]]) else rep(NA_character_, quantidade)
  }
  for (coluna in COLUNAS_DE_NUMERO_DO_CALCULO) {
    itens[[coluna]] = if (coluna %in% names(tabela)) numeros_da_coluna(tabela[[coluna]], coluna) else rep(NA_real_, quantidade)
  }
  itens$modelo[is.na(itens$modelo)] = "55"
  itens$finalidade[is.na(itens$finalidade)] = "1"
  if ("servico" %in% names(tabela)) {
    itens$servico = as.logical(tabela$servico) %in% TRUE
  } else {
    itens$servico = (itens$valor_issqn > 0) %in% TRUE
  }
  itens$compra_governamental = if ("compra_governamental" %in% names(tabela)) {
    as.logical(tabela$compra_governamental) %in% TRUE
  } else {
    rep(FALSE, quantidade)
  }
  itens$data_emissao = if ("data_emissao" %in% names(tabela)) {
    datas_do_calculo(tabela$data_emissao, "coluna data_emissao")
  } else {
    as.Date(rep(NA_character_, quantidade))
  }
  itens
}

# A base de cada item: a soma dos componentes que valem na data, na natureza e no modelo dele.
base_pelos_componentes = function(itens, datas) {
  base = rep(0, nrow(itens))
  for (numero_do_componente in seq_len(nrow(COMPONENTES_DA_BASE))) {
    componente = COMPONENTES_DA_BASE[numero_do_componente, ]
    natureza_certa = componente$natureza == "ambas" | (componente$natureza == "servico") == itens$servico
    modelo_certo = itens$modelo %in% strsplit(componente$modelos, "/")[[1]]
    entra = !is.na(datas) & datas >= marco_da_reforma(componente$entra_no_marco) &
      datas < marco_da_reforma(componente$sai_no_marco) & natureza_certa & modelo_certo
    valores = valor_ou_zero(itens[[componente$coluna]])
    base = base + ifelse(entra, componente$sinal * valores, 0)
  }
  arredondar_no_centavo(base)
}

# As alíquotas do ano de cada data (NA quando a tabela não tem o período), com as pedidas por cima.
aliquotas_nas_datas = function(datas, aliquotas_pedidas) {
  tabela = tabela_fiscal("aliquotas_ibs_cbs")
  linha_do_periodo = rep(NA_integer_, length(datas))
  for (numero_da_linha in seq_len(nrow(tabela))) {
    no_periodo = !is.na(datas) & datas >= tabela$inicio[numero_da_linha] & datas <= tabela$fim[numero_da_linha]
    linha_do_periodo[no_periodo] = numero_da_linha
  }
  aliquotas = data.frame(ibs_uf = tabela$aliquota_ibs_uf[linha_do_periodo],
                         ibs_municipio = tabela$aliquota_ibs_municipio[linha_do_periodo],
                         cbs = tabela$aliquota_cbs[linha_do_periodo])
  for (parte in names(aliquotas_pedidas)) {
    if (!is.na(aliquotas_pedidas[[parte]])) {
      aliquotas[[parte]] = rep(aliquotas_pedidas[[parte]], length(datas))
    }
  }
  aliquotas
}

# A base (em reais) vezes a alíquota (em %) vezes o percentual (em %), no centavo, com o meio centavo indo para o par,
# como a calculadora oficial (0,125 vai a 0,12; a NT não diz e aceita 0,01 de diferença). A base vai em centavos e os
# percentuais em décimos de milésimo, todos inteiros, e o produto é feito em pedaços de 6 dígitos: a conta fica exata
# enquanto a base do item não passa de 1 bilhão de reais (o double guarda inteiros exatos só até uns 9e15).
valor_no_centavo_ao_par = function(base, aliquota, percentual = 100) {
  centavos_da_base = round(abs(base) * 100)
  aliquota_inteira = round(aliquota * 10000)
  percentual_inteiro = round(percentual * 10000)
  # A base vezes a alíquota, em dois pedaços: alto * 1e6 + baixo.
  produto_do_pedaco_baixo = (centavos_da_base %% 1e6) * aliquota_inteira
  baixo = produto_do_pedaco_baixo %% 1e6
  alto = (centavos_da_base %/% 1e6) * aliquota_inteira + produto_do_pedaco_baixo %/% 1e6
  # Vezes o percentual e dividido por 1e12 (o que sobra das casas da base e dos dois percentuais): os centavos.
  produto_do_alto = (alto %% 1e6) * percentual_inteiro
  centavos = (alto %/% 1e6) * percentual_inteiro + produto_do_alto %/% 1e6
  resto = (produto_do_alto %% 1e6) * 1e6 + baixo * percentual_inteiro
  centavos = centavos + resto %/% 1e12
  resto = resto %% 1e12
  sobe = resto > 5e11 | (resto == 5e11 & centavos %% 2 == 1)
  sign(base) * (centavos + sobe) / 100
}

arredondar_em_quatro_casas = function(valores) {
  sign(valores) * floor(abs(valores) * 10000 + 0.5 + FOLGA_DE_PONTO_FLUTUANTE) / 10000
}

# O motivo de cada item que não dá para calcular (NA quando dá). Quando há mais de um, fica o último daqui.
motivo_para_nao_calcular = function(itens, datas, base, cst_da_tabela, classificacao_da_tabela) {
  motivo = rep(NA_character_, nrow(itens))
  sem_o_grupo = itens$cst_ibs_cbs %in% CST_SEM_O_GRUPO
  cst_fora = !(itens$cst_ibs_cbs %in% c(CST_CALCULADOS, CST_SEM_O_GRUPO))
  motivo[cst_fora] = paste0("O CST ", itens$cst_ibs_cbs[cst_fora], " (", cst_da_tabela$descricao[cst_fora],
                            ") n\u00e3o entra no c\u00e1lculo.")
  classificacao_desconhecida = is.na(classificacao_da_tabela$codigo)
  classificacao_de_outro_cst = (!classificacao_desconhecida & classificacao_da_tabela$cst != itens$cst_ibs_cbs) %in% TRUE
  motivo[classificacao_de_outro_cst] = "A classifica\u00e7\u00e3o n\u00e3o \u00e9 do CST informado."
  motivo[classificacao_desconhecida] = "A classifica\u00e7\u00e3o n\u00e3o est\u00e1 na tabela."
  motivo[is.na(cst_da_tabela$codigo)] = "O CST n\u00e3o est\u00e1 na tabela."
  motivo[!sem_o_grupo & !is.na(itens$credito_presumido_codigo)] = paste(
    "Cr\u00e9dito presumido da opera\u00e7\u00e3o (cCredPres): o c\u00e1lculo n\u00e3o trata."
  )
  # O valor devolvido sai do valor do item (UB35-10, UB54-10 e UB67-10): com zero, a conta é a mesma.
  com_devolucao_de_tributos = valor_ou_zero(itens$valor_devolvido_ibs_uf) != 0 |
    valor_ou_zero(itens$valor_devolvido_ibs_municipio) != 0 | valor_ou_zero(itens$valor_devolvido_cbs) != 0
  motivo[!sem_o_grupo & com_devolucao_de_tributos] = "Devolu\u00e7\u00e3o de tributos (gDevTrib): o c\u00e1lculo n\u00e3o trata."
  motivo[!sem_o_grupo & itens$compra_governamental] = paste(
    "Compra governamental: o redutor de cada ente e de cada ano n\u00e3o est\u00e1 nas tabelas do RNFe."
  )
  nao_normal = !(itens$finalidade %in% "1")
  motivo[nao_normal] = paste0(
    "A nota n\u00e3o \u00e9 normal (finNFe ", itens$finalidade[nao_normal], "): a complementar, a de ajuste, a devolu\u00e7\u00e3o ",
    "e as notas de cr\u00e9dito e de d\u00e9bito dependem da opera\u00e7\u00e3o original."
  )
  motivo[!sem_o_grupo & (base < 0) %in% TRUE] = paste(
    "A base ficou negativa (o que se subtrai passa do que se soma): a calculadora oficial recusa."
  )
  motivo[is.na(itens$base) & is.na(itens$valor_produto)] = "Sem a base nem o valor do produto."
  fora_do_calculo = (datas < marco_da_reforma("inicio_do_calculo") | datas >= marco_da_reforma("fim_do_calculo")) %in% TRUE
  motivo[fora_do_calculo] = paste0(
    "O c\u00e1lculo cobre as notas ", texto_entre_os_marcos("inicio_do_calculo", "fim_do_calculo"),
    " (a vig\u00eancia dos componentes da base)."
  )
  motivo[is.na(datas)] = "Sem a data do c\u00e1lculo (informe em data, ou a data de emiss\u00e3o)."
  motivo[is.na(itens$cst_ibs_cbs) | is.na(itens$classificacao_ibs_cbs)] = "Sem o CST ou a classifica\u00e7\u00e3o do IBS e da CBS."
  motivo
}

calcular_os_itens = function(itens, aliquotas_pedidas) {
  quantidade = nrow(itens)
  tabela_do_cst = tabela_fiscal("cst_ibs_cbs")
  tabela_da_classificacao = tabela_fiscal("classificacao_ibs_cbs")
  cst_da_tabela = tabela_do_cst[match(itens$cst_ibs_cbs, tabela_do_cst$codigo), ]
  classificacao_da_tabela = tabela_da_classificacao[match(itens$classificacao_ibs_cbs, tabela_da_classificacao$codigo), ]
  regular_da_tabela = tabela_da_classificacao[match(itens$classificacao_regular, tabela_da_classificacao$codigo), ]
  cst_regular_da_tabela = tabela_do_cst[match(itens$cst_regular, tabela_do_cst$codigo), ]
  base = ifelse(!is.na(itens$base), arredondar_no_centavo(itens$base), base_pelos_componentes(itens, itens$data_emissao))
  motivo = motivo_para_nao_calcular(itens, itens$data_emissao, base, cst_da_tabela, classificacao_da_tabela)
  da_para_calcular = is.na(motivo)
  com_o_grupo = da_para_calcular & !(itens$cst_ibs_cbs %in% CST_SEM_O_GRUPO)
  tributacao_regular = classificacao_da_tabela$grupo_tributacao_regular %in% 1
  com_reducao = cst_da_tabela$grupo_reducao %in% 1
  com_diferimento = cst_da_tabela$grupo_diferimento %in% 1
  aliquotas_do_ano = aliquotas_nas_datas(itens$data_emissao, aliquotas_pedidas)
  calculados = data.frame(chave = itens$chave, item = itens$item, data_calculo = itens$data_emissao,
                          cst_ibs_cbs = itens$cst_ibs_cbs, classificacao_ibs_cbs = itens$classificacao_ibs_cbs,
                          servico = itens$servico, base = ifelse(com_o_grupo, base, NA_real_))
  observacoes = list(motivo)
  valor_ibs = rep(0, quantidade)
  for (parte in PARTES_DO_CALCULO) {
    reducao_da_classificacao = if (parte == "cbs") classificacao_da_tabela$reducao_cbs else classificacao_da_tabela$reducao_ibs
    aliquota = ifelse(tributacao_regular, 0, aliquotas_do_ano[[parte]])
    reducao = ifelse(com_reducao, reducao_da_classificacao, NA_real_)
    aliquota_efetiva = arredondar_em_quatro_casas(aliquota * (1 - reducao / 100))
    aliquota_usada = ifelse(is.na(reducao), aliquota, aliquota_efetiva)
    diferimento = ifelse(com_diferimento, itens[[paste0("diferimento_", parte)]], NA_real_)
    valor_diferido = valor_no_centavo_ao_par(base, aliquota_usada, diferimento)
    valor = valor_no_centavo_ao_par(base, aliquota_usada) - valor_ou_zero(valor_diferido)
    valor[com_diferimento & is.na(diferimento)] = NA_real_
    calculados[[paste0("aliquota_", parte)]] = ifelse(com_o_grupo, aliquota, NA_real_)
    calculados[[paste0("reducao_", parte)]] = ifelse(com_o_grupo, reducao, NA_real_)
    calculados[[paste0("aliquota_efetiva_", parte)]] = ifelse(com_o_grupo, aliquota_efetiva, NA_real_)
    calculados[[paste0("diferimento_", parte)]] = ifelse(com_o_grupo, diferimento, NA_real_)
    calculados[[paste0("valor_diferido_", parte)]] = ifelse(com_o_grupo, valor_diferido, NA_real_)
    calculados[[paste0("valor_", parte)]] = ifelse(com_o_grupo, valor, NA_real_)
    nome_da_parte = switch(parte, ibs_uf = "do IBS da UF", ibs_municipio = "do IBS do munic\u00edpio", cbs = "da CBS")
    observacoes[[length(observacoes) + 1]] = ifelse(
      com_o_grupo & is.na(aliquota), paste0("Sem a al\u00edquota ", nome_da_parte, " do ano (informe em aliquotas)."), NA)
    observacoes[[length(observacoes) + 1]] = ifelse(
      com_o_grupo & com_diferimento & is.na(diferimento),
      paste0("Sem o percentual do diferimento ", nome_da_parte, " (a tabela da classifica\u00e7\u00e3o n\u00e3o o traz)."), NA)
    if (parte != "cbs") {
      valor_ibs = valor_ibs + calculados[[paste0("valor_", parte)]]
    }
  }
  calculados$valor_ibs = valor_ibs
  # A tributação regular: a base vezes a alíquota do ano com a redução da classificação regular.
  pede_regular = com_o_grupo & tributacao_regular
  calculados$cst_regular = ifelse(pede_regular, itens$cst_regular, NA_character_)
  calculados$classificacao_regular = ifelse(pede_regular, itens$classificacao_regular, NA_character_)
  regular_conhecida = !is.na(regular_da_tabela$codigo) & !is.na(cst_regular_da_tabela$codigo)
  for (parte in PARTES_DO_CALCULO) {
    reducao_regular = if (parte == "cbs") regular_da_tabela$reducao_cbs else regular_da_tabela$reducao_ibs
    reducao_regular = ifelse(cst_regular_da_tabela$grupo_reducao %in% 1, reducao_regular, 0)
    aliquota_regular = arredondar_em_quatro_casas(aliquotas_do_ano[[parte]] * (1 - reducao_regular / 100))
    calculados[[paste0("aliquota_regular_", parte)]] = ifelse(pede_regular & regular_conhecida, aliquota_regular, NA_real_)
    calculados[[paste0("valor_regular_", parte)]] = ifelse(pede_regular & regular_conhecida,
                                                           valor_no_centavo_ao_par(base, aliquota_regular), NA_real_)
  }
  observacoes[[length(observacoes) + 1]] = ifelse(
    pede_regular & !regular_conhecida,
    "Sem o CST e a classifica\u00e7\u00e3o da tributa\u00e7\u00e3o regular (cst_regular e classificacao_regular).", NA)
  sem_aliquota_regular = pede_regular & regular_conhecida &
    (is.na(calculados$aliquota_regular_ibs_uf) | is.na(calculados$aliquota_regular_ibs_municipio) |
       is.na(calculados$aliquota_regular_cbs))
  observacoes[[length(observacoes) + 1]] = ifelse(
    sem_aliquota_regular, "Sem a al\u00edquota do ano para a tributa\u00e7\u00e3o regular (informe em aliquotas).", NA)
  calculados$tem_grupo_ibs_cbs = com_o_grupo
  calculados$observacao = juntar_as_observacoes(observacoes)
  calculados$calculado = da_para_calcular & is.na(calculados$observacao)
  calculados[, c(setdiff(names(calculados), c("calculado", "observacao")), "calculado", "observacao")]
}

# As observações de cada item numa só, separadas por espaço (NA quando não há nenhuma).
juntar_as_observacoes = function(observacoes) {
  juntas = rep(NA_character_, length(observacoes[[1]]))
  for (observacao in observacoes) {
    com_texto = !is.na(observacao)
    juntas[com_texto] = ifelse(is.na(juntas[com_texto]), observacao[com_texto], paste(juntas[com_texto], observacao[com_texto]))
  }
  juntas
}

# Os totais de cada nota, somados nos itens calculados.
somar_as_notas = function(calculados) {
  chave_para_somar = ifelse(is.na(calculados$chave), "", calculados$chave)
  chaves = unique(chave_para_somar)
  contados = calculados$calculado
  notas = data.frame(chave = ifelse(chaves == "", NA_character_, chaves),
                     itens = as.integer(table(factor(chave_para_somar, levels = chaves))),
                     itens_calculados = as.integer(table(factor(chave_para_somar[contados], levels = chaves))))
  for (coluna in c("base", "valor_ibs_uf", "valor_ibs_municipio", "valor_ibs", "valor_cbs")) {
    valores = ifelse(contados, valor_ou_zero(calculados[[coluna]]), 0)
    notas[[coluna]] = arredondar_no_centavo(as.numeric(tapply(valores, factor(chave_para_somar, levels = chaves), sum)))
  }
  notas
}
