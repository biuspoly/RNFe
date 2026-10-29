# Leitura do XML da NF-e e da NFC-e (leiaute 4.00) em tabelas. Os caminhos seguem o schema oficial
# do Portal da NF-e (pacote de liberação PL_010g v1.03, de 26/10/2026, que já traz a Reforma).

ler_campos = function(texto) {
  utils::read.table(text = texto, header = TRUE, stringsAsFactors = FALSE)
}

# Coluna, caminho a partir do infNFe e tipo. "a|b" pega o que existir (o leiaute deixa um ou outro).
CAMPOS_DA_NOTA = ler_campos("
coluna                        caminho                                     tipo
modelo                        ide/mod                                     texto
serie                         ide/serie                                   inteiro
numero                        ide/nNF                                     inteiro
emissao                       ide/dhEmi|ide/dEmi                          data_hora
data_emissao                  ide/dhEmi|ide/dEmi                          data
saida_entrada                 ide/dhSaiEnt                                data_hora
natureza_operacao             ide/natOp                                   texto
tipo_operacao                 ide/tpNF                                    inteiro
destino_operacao              ide/idDest                                  inteiro
finalidade                    ide/finNFe                                  inteiro
consumidor_final              ide/indFinal                                inteiro
presenca                      ide/indPres                                 inteiro
forma_emissao                 ide/tpEmis                                  inteiro
ambiente                      ide/tpAmb                                   inteiro
processo_emissao              ide/procEmi                                 inteiro
municipio_fato_gerador        ide/cMunFG                                  texto
emitente_documento            emit/CNPJ|emit/CPF                          texto
emitente_nome                 emit/xNome                                  texto
emitente_fantasia             emit/xFant                                  texto
emitente_ie                   emit/IE                                     texto
emitente_municipio            emit/enderEmit/xMun                         texto
emitente_codigo_municipio     emit/enderEmit/cMun                         texto
emitente_uf                   emit/enderEmit/UF                           texto
emitente_regime               emit/CRT                                    inteiro
avulsa_cnpj                   avulsa/CNPJ                                 texto
destinatario_documento        dest/CNPJ|dest/CPF|dest/idEstrangeiro       texto
destinatario_nome             dest/xNome                                  texto
destinatario_ie               dest/IE                                     texto
destinatario_indicador_ie     dest/indIEDest                              inteiro
destinatario_municipio        dest/enderDest/xMun                         texto
destinatario_codigo_municipio dest/enderDest/cMun                         texto
destinatario_uf               dest/enderDest/UF                           texto
base_icms                     total/ICMSTot/vBC                           numero
valor_icms                    total/ICMSTot/vICMS                         numero
valor_icms_desonerado         total/ICMSTot/vICMSDeson                    numero
valor_fcp                     total/ICMSTot/vFCP                          numero
base_icms_st                  total/ICMSTot/vBCST                         numero
valor_icms_st                 total/ICMSTot/vST                           numero
valor_fcp_st                  total/ICMSTot/vFCPST                        numero
valor_fcp_st_retido           total/ICMSTot/vFCPSTRet                     numero
valor_produtos                total/ICMSTot/vProd                         numero
valor_frete                   total/ICMSTot/vFrete                        numero
valor_seguro                  total/ICMSTot/vSeg                          numero
valor_desconto                total/ICMSTot/vDesc                         numero
valor_ii                      total/ICMSTot/vII                           numero
valor_ipi                     total/ICMSTot/vIPI                          numero
valor_ipi_devolvido           total/ICMSTot/vIPIDevol                     numero
valor_pis                     total/ICMSTot/vPIS                          numero
valor_cofins                  total/ICMSTot/vCOFINS                       numero
valor_outros                  total/ICMSTot/vOutro                        numero
valor_nota                    total/ICMSTot/vNF                           numero
valor_tributos_aproximado     total/ICMSTot/vTotTrib                      numero
base_ibs_cbs                  total/IBSCBSTot/vBCIBSCBS                   numero
valor_ibs                     total/IBSCBSTot/gIBS/vIBS                   numero
valor_cbs                     total/IBSCBSTot/gCBS/vCBS                   numero
valor_is                      total/ISTot/vIS                             numero
valor_nota_com_ibs_cbs_is     total/vNFTot                                numero
modalidade_frete              transp/modFrete                             inteiro
transportadora_documento      transp/transporta/CNPJ|transp/transporta/CPF texto
transportadora_nome           transp/transporta/xNome                     texto
fatura_numero                 cobr/fat/nFat                               texto
fatura_valor_original         cobr/fat/vOrig                              numero
fatura_desconto               cobr/fat/vDesc                              numero
fatura_valor_liquido          cobr/fat/vLiq                               numero
valor_troco                   pag/vTroco                                  numero
informacoes_complementares    infAdic/infCpl                              texto
informacoes_fisco             infAdic/infAdFisco                          texto
")

# A partir do infProt do protocolo de autorização (protNFe), que vem junto no nfeProc.
CAMPOS_DO_PROTOCOLO = ler_campos("
coluna      caminho   tipo
protocolo   nProt     texto
situacao    cStat     inteiro
motivo      xMotivo   texto
autorizacao dhRecbto  data_hora
")

# A partir do det. Os impostos principais em colunas; todos os campos estão na tabela impostos.
CAMPOS_DO_ITEM = ler_campos("
coluna                    caminho                                    tipo
codigo                    prod/cProd                                 texto
gtin                      prod/cEAN                                  texto
descricao                 prod/xProd                                 texto
ncm                       prod/NCM                                   texto
cest                      prod/CEST                                  texto
beneficio_fiscal          prod/cBenef                                texto
cfop                      prod/CFOP                                  texto
unidade                   prod/uCom                                  texto
quantidade                prod/qCom                                  numero
valor_unitario            prod/vUnCom                                numero
valor_produto             prod/vProd                                 numero
unidade_tributavel        prod/uTrib                                 texto
quantidade_tributavel     prod/qTrib                                 numero
valor_unitario_tributavel prod/vUnTrib                               numero
valor_frete               prod/vFrete                                numero
valor_seguro              prod/vSeg                                  numero
valor_desconto            prod/vDesc                                 numero
valor_outros              prod/vOutro                                numero
compoe_total              prod/indTot                                inteiro
pedido                    prod/xPed                                  texto
item_pedido               prod/nItemPed                              texto
informacoes_adicionais    infAdProd                                  texto
valor_tributos_aproximado imposto/vTotTrib                           numero
origem                    imposto/ICMS/*/orig                        texto
cst_icms                  imposto/ICMS/*/CST                         texto
csosn                     imposto/ICMS/*/CSOSN                       texto
base_icms                 imposto/ICMS/*/vBC                         numero
aliquota_icms             imposto/ICMS/*/pICMS                       numero
valor_icms                imposto/ICMS/*/vICMS                       numero
base_icms_st              imposto/ICMS/*/vBCST                       numero
aliquota_icms_st          imposto/ICMS/*/pICMSST                     numero
valor_icms_st             imposto/ICMS/*/vICMSST                     numero
base_icms_st_retido       imposto/ICMS/*/vBCSTRet                    numero
valor_icms_st_retido      imposto/ICMS/*/vICMSSTRet                  numero
valor_fcp                 imposto/ICMS/*/vFCP                        numero
valor_fcp_st              imposto/ICMS/*/vFCPST                      numero
valor_icms_desonerado     imposto/ICMS/*/vICMSDeson                  numero
cst_ipi                   imposto/IPI/*/CST                          texto
valor_ipi                 imposto/IPI/IPITrib/vIPI                   numero
cst_pis                   imposto/PIS/*/CST                          texto
valor_pis                 imposto/PIS/*/vPIS                         numero
cst_cofins                imposto/COFINS/*/CST                       texto
valor_cofins              imposto/COFINS/*/vCOFINS                   numero
valor_ii                  imposto/II/vII                             numero
cst_ibs_cbs               imposto/IBSCBS/CST                         texto
classificacao_ibs_cbs     imposto/IBSCBS/cClassTrib                  texto
base_ibs_cbs              imposto/IBSCBS/gIBSCBS/vBC                 numero
aliquota_ibs_uf           imposto/IBSCBS/gIBSCBS/gIBSUF/pIBSUF       numero
aliquota_ibs_municipio    imposto/IBSCBS/gIBSCBS/gIBSMun/pIBSMun     numero
valor_ibs                 imposto/IBSCBS/gIBSCBS/vIBS                numero
aliquota_cbs              imposto/IBSCBS/gIBSCBS/gCBS/pCBS           numero
valor_cbs                 imposto/IBSCBS/gIBSCBS/gCBS/vCBS           numero
valor_is                  imposto/IS/vIS                             numero
percentual_devolvido      impostoDevol/pDevol                        numero
valor_ipi_devolvido       impostoDevol/IPI/vIPIDevol                 numero
")

# A partir de cada dup (cobr/dup).
CAMPOS_DA_PARCELA = ler_campos("
coluna     caminho tipo
numero     nDup    texto
vencimento dVenc   data
valor      vDup    numero
")

# A partir de cada detPag (pag/detPag).
CAMPOS_DO_PAGAMENTO = ler_campos("
coluna           caminho    tipo
indicador        indPag     inteiro
forma            tPag       texto
descricao        xPag       texto
valor            vPag       numero
data             dPag       data
cnpj_instituicao card/CNPJ  texto
bandeira         card/tBand texto
autorizacao      card/cAut  texto
")

#' Ler o XML de NF-e e NFC-e
#'
#' Lê arquivos XML de NF-e e NFC-e (leiaute 4.00), com ou sem o protocolo de
#' autorização (`nfeProc` ou só `NFe`), e devolve tabelas ligadas pela `chave`.
#' Um arquivo que não dá para ler não interrompe os outros: fica em `arquivos`,
#' com o motivo.
#'
#' Cada coluna vem de um campo do leiaute (entre parênteses abaixo). Códigos
#' (CST, CFOP, forma de pagamento...) ficam como estão no XML; o significado de
#' cada um está no Manual de Orientação do Contribuinte. Campo que a nota não
#' tem fica `NA`.
#'
#' @section notas:
#' Uma linha por nota: `chave`, `versao`,
#' `r documentar_campos(CAMPOS_DA_NOTA)`;
#' do protocolo de autorização, quando vem junto:
#' `r documentar_campos(CAMPOS_DO_PROTOCOLO)`;
#' e `arquivo`. `emissao`, `saida_entrada` e `autorizacao` são data e hora
#' (mostradas no horário de Brasília); `data_emissao` é a data como está na
#' nota.
#'
#' @section itens:
#' Uma linha por item: `chave`, `item` (`nItem`),
#' `r documentar_campos(CAMPOS_DO_ITEM)`.
#' O `*` é o grupo do ICMS, do IPI, do PIS ou da COFINS que o item tiver (por
#' exemplo, `ICMS00` ou `ICMSSN102`).
#'
#' @section impostos:
#' Todos os campos dos impostos de cada item, um por linha: `chave`, `item`,
#' `tributo` (o grupo logo abaixo de `imposto`: `ICMS`, `IPI`, `PIS`,
#' `COFINS`, `IBSCBS`...), `grupo` (onde o campo está, por exemplo `ICMS00` ou
#' `gCBS`), `campo` (o nome no leiaute) e `valor` (o texto do XML). É o que
#' sobra para quem precisa de um campo que não está em `itens`.
#'
#' @section parcelas e pagamentos:
#' `parcelas`, uma linha por duplicata: `chave`,
#' `r documentar_campos(CAMPOS_DA_PARCELA)`.
#' `pagamentos`, uma linha por forma de pagamento: `chave`,
#' `r documentar_campos(CAMPOS_DO_PAGAMENTO)`.
#'
#' @section arquivos:
#' Uma linha por arquivo pedido: `arquivo`, `notas` (quantas notas tinha) e
#' `problema` (`NA` quando deu certo). Um texto de XML aparece como
#' `"(texto 1)"`, `"(texto 2)"`...
#'
#' @param arquivos Caminhos dos arquivos XML, ou o próprio texto do XML
#'   (começando por `<`).
#' @return Uma lista com os `data.frame`s `notas`, `itens`, `impostos`,
#'   `parcelas`, `pagamentos` e `arquivos`.
#' @source Schema oficial da NF-e, pacote de liberação PL_010g v1.03 (NT
#'   2026.006 e NT 2026.008), publicado no Portal Nacional da NF-e em
#'   26/10/2026.
#' @examples
#' nota = system.file("exemplos", "nfe_proc_sp.xml", package = "RNfe")
#' lida = nfe_ler(nota)
#' lida$notas[, c("chave", "emitente_nome", "valor_nota", "protocolo")]
#' lida$itens[, c("item", "descricao", "cfop", "cst_icms", "valor_icms", "valor_cbs")]
#' @export
nfe_ler = function(arquivos) {
  arquivos = as.character(arquivos)
  partes = lapply(seq_along(arquivos), function(posicao) ler_um_arquivo(arquivos[posicao], posicao))
  vazias = tabelas_do_documento(NULL, NA_character_)
  tabelas = lapply(names(vazias), function(nome) {
    empilhar(c(list(vazias[[nome]]), lapply(partes, function(parte) parte[[nome]])))
  })
  names(tabelas) = names(vazias)
  tabelas$notas = converter_datas(tabelas$notas, rbind(CAMPOS_DA_NOTA, CAMPOS_DO_PROTOCOLO))
  tabelas$parcelas = converter_datas(tabelas$parcelas, CAMPOS_DA_PARCELA)
  tabelas$pagamentos = converter_datas(tabelas$pagamentos, CAMPOS_DO_PAGAMENTO)
  tabelas$arquivos = data.frame(
    arquivo = vapply(partes, function(parte) parte$nome, character(1)),
    notas = vapply(partes, function(parte) nrow(parte$notas), integer(1)),
    problema = vapply(partes, function(parte) parte$problema, character(1))
  )
  tabelas
}

documentar_campos = function(campos) {
  paste0("`", campos$coluna, "` (`", campos$caminho, "`)", collapse = ", ")
}

ler_um_arquivo = function(arquivo, posicao) {
  texto_de_xml = !is.na(arquivo) && startsWith(trimws(arquivo), "<")
  nome = if (texto_de_xml) paste0("(texto ", posicao, ")") else arquivo
  documento = NULL
  problema = NA_character_
  if (is.na(arquivo) || !nzchar(trimws(arquivo))) {
    problema = "vazio"
  } else if (!texto_de_xml && !file.exists(arquivo)) {
    problema = "arquivo n\u00e3o encontrado"
  } else {
    documento = tryCatch(xml2::read_xml(arquivo), error = function(erro) {
      problema <<- paste0("n\u00e3o \u00e9 um XML v\u00e1lido: ", conditionMessage(erro))
      NULL
    })
  }
  if (!is.null(documento)) {
    xml2::xml_ns_strip(documento)
    if (length(xml2::xml_find_all(documento, "//infNFe")) == 0) {
      problema = problema_sem_nota(documento)
      documento = NULL
    }
  }
  partes = tabelas_do_documento(documento, nome)
  partes$nome = nome
  partes$problema = problema
  partes
}

problema_sem_nota = function(documento) {
  raiz = xml2::xml_name(xml2::xml_root(documento))
  if (raiz == "resNFe") {
    return("\u00e9 o resumo da NF-e (resNFe), sem os itens")
  }
  paste0("n\u00e3o \u00e9 uma NF-e (o XML come\u00e7a por <", raiz, ">)")
}

# Com documento NULL, devolve as tabelas vazias, já com as colunas e os tipos certos.
tabelas_do_documento = function(documento, nome) {
  if (is.null(documento)) {
    documento = xml2::read_xml("<vazio/>")
  }
  notas = xml2::xml_find_all(documento, "//infNFe")
  protocolos = xml2::xml_find_all(documento, "//protNFe/infProt")
  chaves = chave_do_no(notas)
  protocolo_da_nota = match(chaves, xml2::xml_text(xml2::xml_find_first(protocolos, "chNFe")))
  itens = xml2::xml_find_all(notas, "det")
  folhas_dos_impostos = xml2::xml_find_all(itens, "imposto//*[not(*)]")
  duplicatas = xml2::xml_find_all(notas, "cobr/dup")
  formas_de_pagamento = xml2::xml_find_all(notas, "pag/detPag")

  list(
    notas = data.frame(
      chave = chaves,
      versao = xml2::xml_attr(notas, "versao"),
      extrair(notas, CAMPOS_DA_NOTA),
      extrair(protocolos, CAMPOS_DO_PROTOCOLO, protocolo_da_nota),
      arquivo = rep(nome, length(notas))
    ),
    itens = data.frame(
      chave = chave_do_no(itens),
      item = as.integer(xml2::xml_attr(itens, "nItem")),
      extrair(itens, CAMPOS_DO_ITEM)
    ),
    impostos = data.frame(
      chave = chave_do_no(folhas_dos_impostos),
      item = as.integer(xml2::xml_attr(xml2::xml_find_first(folhas_dos_impostos, "ancestor::det"), "nItem")),
      tributo = xml2::xml_name(xml2::xml_find_first(folhas_dos_impostos, "ancestor-or-self::*[parent::imposto]")),
      # xml_parent() devolve cada pai uma vez só; parent::* devolve um por campo.
      grupo = xml2::xml_name(xml2::xml_find_first(folhas_dos_impostos, "parent::*")),
      campo = xml2::xml_name(folhas_dos_impostos),
      valor = xml2::xml_text(folhas_dos_impostos)
    ),
    parcelas = data.frame(chave = chave_do_no(duplicatas), extrair(duplicatas, CAMPOS_DA_PARCELA)),
    pagamentos = data.frame(chave = chave_do_no(formas_de_pagamento), extrair(formas_de_pagamento, CAMPOS_DO_PAGAMENTO))
  )
}

chave_do_no = function(nos) {
  nota = xml2::xml_find_first(nos, "ancestor-or-self::infNFe")
  sub("^NFe", "", xml2::xml_attr(nota, "Id"))
}

# Uma coluna por campo, já no tipo certo; datas ficam como texto até converter_datas().
# `posicoes` escolhe e repete os nós (no protocolo, NA é a nota que veio sem ele).
extrair = function(nos, campos, posicoes = seq_along(nos)) {
  colunas = lapply(seq_len(nrow(campos)), function(linha) {
    valores = xml2::xml_text(xml2::xml_find_first(nos, campos$caminho[linha]))[posicoes]
    tipo = campos$tipo[linha]
    if (tipo == "inteiro") {
      valores = as.integer(valores)
    } else if (tipo == "numero") {
      valores = as.numeric(valores)
    }
    valores
  })
  names(colunas) = campos$coluna
  data.frame(colunas)
}

empilhar = function(tabelas) {
  colunas = names(tabelas[[1]])
  juntas = lapply(colunas, function(coluna) do.call(c, lapply(tabelas, function(tabela) tabela[[coluna]])))
  names(juntas) = colunas
  data.frame(juntas)
}

converter_datas = function(tabela, campos) {
  for (linha in seq_len(nrow(campos))) {
    coluna = campos$coluna[linha]
    if (campos$tipo[linha] == "data") {
      tabela[[coluna]] = as.Date(substr(tabela[[coluna]], 1, 10))
    } else if (campos$tipo[linha] == "data_hora") {
      tabela[[coluna]] = data_hora(tabela[[coluna]])
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
