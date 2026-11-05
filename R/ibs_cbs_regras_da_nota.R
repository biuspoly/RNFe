# As regras da NT 2025.002 fora do IBS e da CBS do item: a identificação da nota (grupo B), a compra governamental (BB),
# o emitente e o destinatário (C e E), o produto e o ICMS, o PIS e a COFINS de cada item (I, N, NA, Q e S), o documento
# referenciado no item (VC) e os totais que não são do IBS e da CBS (W07 e W31). Valem, como as outras, só no documento
# com o IBS e a CBS preenchidos. Não dá para conferir aqui as que a SEFAZ confere no documento referenciado guardado
# na base dela (BB05-170, BB05-190, BB05-200 e VC02-50).

#' @include ler_xml.R tabelas.R
NULL

# Os CFOP que a redação antiga da VC02-14 deixa de fora.
CFOP_FORA_DA_DEVOLUCAO_ANTIGA = c("1201", "1202", "1410", "1411", "5921", "6921")

# Os produtos da ANP de combustível derivado de petróleo que a exceção 6 da NA01-20 ainda alcança (a lista da NT).
PRODUTOS_ANP_DA_PARTILHA = c("820101001", "820101010", "810102001", "810102004", "810102002", "810102003", "810101002",
                             "810101001", "810101003", "220101003", "220101004", "220101002", "220101001", "220101005",
                             "220101006", "560101001")
UFS_DA_SUFRAMA = c("AC", "AM", "RO", "RR")
MUNICIPIOS_DO_AMAPA_NA_SUFRAMA = c("1600303", "1600600")
# Desde 16/11/2026, as mudanças da devolução da NT v1.53 (a B25-40 e a VC02-14). A v1.53 foi publicada em 30/10/2026,
# e a VC02-14 nova entra "até 16/11/2026" (a B25-40, em 16/11/2026).
INICIO_DA_DEVOLUCAO_NOVA = as.Date("2026-11-16")
PUBLICACAO_DA_DEVOLUCAO_NOVA = as.Date("2026-10-30")
# Os documentos que a redação antiga da VC02-14 aceita no cabeçalho da devolução (NF-e, NFC-e, NF modelo 1, NF de
# produtor e ECF).
REFERENCIAS_DA_DEVOLUCAO_ANTIGA = c("refNFe", "refNFeSig", "refNF", "refNFP", "refECF")

# Os documentos referenciados no cabeçalho (NFref), um por linha: o tipo (refNFe, refNFeSig, refNF, refNFP, refCTe,
# refECF), a chave (quando é chave) e, da chave ou dos campos, a UF, o CNPJ ou CPF do emitente, o modelo, o ano e a série.
referencias_das_notas = function(elementos_das_notas) {
  elementos = buscar_todos(elementos_das_notas, "ide/NFref/*")
  tipo = xml2::xml_name(elementos)
  # O refNFeSig é a chave de uma NF-e com o código numérico zerado: a UF, o ano, o emitente e a série estão nela.
  e_chave = tipo %in% c("refNFe", "refNFeSig", "refCTe")
  texto_da_chave = ifelse(e_chave, xml2::xml_text(elementos), NA_character_)
  cnpj = texto_de_cada(elementos, "CNPJ")
  cpf = texto_de_cada(elementos, "CPF")
  data.frame(
    chave = chave_de_cada(elementos, "infNFe"),
    tipo = tipo,
    chave_referenciada = texto_da_chave,
    uf = ifelse(e_chave, substr(texto_da_chave, 1, 2), texto_de_cada(elementos, "cUF")),
    documento = ifelse(e_chave, substr(texto_da_chave, 7, 20), ifelse(is.na(cnpj), cpf, cnpj)),
    modelo = ifelse(e_chave, substr(texto_da_chave, 21, 22), texto_de_cada(elementos, "mod")),
    ano = ifelse(e_chave, substr(texto_da_chave, 3, 4), substr(texto_de_cada(elementos, "AAMM"), 1, 2)),
    serie = ifelse(e_chave, substr(texto_da_chave, 23, 25), texto_de_cada(elementos, "serie"))
  )
}

# As chaves dos documentos anteriores da compra governamental (gCompraGov/refDFeAnt), uma por linha.
chaves_da_compra_governamental = function(elementos_das_notas) {
  elementos = buscar_todos(elementos_das_notas, "ide/gCompraGov/refDFeAnt")
  data.frame(chave = chave_de_cada(elementos, "infNFe"), chave_referenciada = xml2::xml_text(elementos))
}

# O CNPJ ou o CPF com 14 posições, como vai na chave (o CPF com três zeros na frente).
documento_com_14_posicoes = function(documentos) {
  documentos = as.character(documentos)
  documentos[!is.na(documentos) & nchar(documentos) == 11] = paste0("000", documentos[!is.na(documentos) & nchar(documentos) == 11])
  documentos
}

# O CNPJ base (as 8 primeiras posições) ou o CPF inteiro, de um documento de 14 posições.
cnpj_base_ou_cpf = function(documentos) {
  documentos = as.character(documentos)
  base = substr(documentos, 1, 8)
  de_cpf = tipo_do_documento(documentos) %in% "CPF"
  base[de_cpf] = documentos[de_cpf]
  base
}

# A série da NF-e avulsa (890 a 899): a chave traz o CNPJ do Fisco, não o do emitente.
serie_avulsa = function(series) {
  numeros = suppressWarnings(as.integer(series))
  !is.na(numeros) & numeros >= 890 & numeros <= 899
}

# A mesma data três meses depois; quando o mês de chegada não tem o dia (31 de novembro), o último dia dele.
tres_meses_depois = function(datas) {
  depois = as.Date(rep(NA_character_, length(datas)))
  com_data = !is.na(datas)
  partes = as.POSIXlt(datas[com_data])
  meses_desde_o_ano_zero = (partes$year + 1900) * 12 + partes$mon + 3
  ano = meses_desde_o_ano_zero %/% 12
  mes = meses_desde_o_ano_zero %% 12 + 1
  primeiro_do_mes_seguinte = as.Date(sprintf("%04d-%02d-01", ano + (mes == 12), mes %% 12 + 1))
  ultimo_dia = as.integer(format(primeiro_do_mes_seguinte - 1, "%d"))
  depois[com_data] = as.Date(sprintf("%04d-%02d-%02d", ano, mes, pmin(partes$mday, ultimo_dia)))
  depois
}

# O dígito da inscrição na Suframa (MOC 7.0, seção 8.4): 8 ou 9 dígitos, o setor (os dois primeiros) não pode ser 00, e
# o último é o módulo 11 dos outros com os pesos de 9 a 2 (0 quando o resto é 0 ou 1). A de 8 dígitos é a de 9 sem o
# zero da frente.
inscricao_suframa_confere = function(inscricoes) {
  certa = rep(FALSE, length(inscricoes))
  formato = !is.na(inscricoes) & grepl("^[0-9]{8,9}$", inscricoes)
  if (any(formato)) {
    com_nove = ifelse(nchar(inscricoes[formato]) == 8, paste0("0", inscricoes[formato]), inscricoes[formato])
    digitos = valores_dos_caracteres(substr(com_nove, 1, 8), 8)
    digito = digito_modulo_11(as.vector(digitos %*% (9:2)))
    certa[formato] = substr(com_nove, 1, 2) != "00" & digito == as.integer(substr(com_nove, 9, 9))
  }
  certa
}

# O grupo B: a previsão de entrega, os documentos referenciados, as notas de débito e de crédito, a NFC-e e o local da
# operação.
conferir_a_identificacao_da_nota = function(notas, referencias) {
  sem_item = rep(NA_integer_, nrow(notas))
  data_de_saida = as.Date(substr(ifelse(is.na(notas$data_saida), format(notas$data_emissao), notas$data_saida), 1, 10))
  previsao = as.Date(notas$previsao_entrega)
  com_previsao = !is.na(notas$previsao_entrega)
  ano = as.integer(format(notas$data_emissao, "%Y"))
  credito = notas$tipo_nota_credito
  debito = notas$tipo_nota_debito
  quantas_referencias = as.integer(table(factor(referencias$chave, levels = notas$chave)))
  # Na devolução, uma referência só a partir de 16/11/2026 (NT v1.53).
  devolucao_com_uma_referencia = notas$finalidade %in% "4" & !is.na(notas$data_emissao) &
    notas$data_emissao >= INICIO_DA_DEVOLUCAO_NOVA
  # B25-50 e B25-60: a NF referenciada. A chave da NF-e avulsa (série 890 a 899) traz o CNPJ do Fisco, não o do
  # emitente: na B25-50 ela fica sem conferir; na B25-60 vale (a UF da chave é a verdadeira).
  referencias_da_nota = referencias[referencias$tipo %in% c("refNFe", "refNFeSig", "refNF", "refNFP"), ]
  de_avulsa = referencias_da_nota$tipo %in% c("refNFe", "refNFeSig") & serie_avulsa(referencias_da_nota$serie)
  da_nota = match(referencias_da_nota$chave, notas$chave)
  documento_do_emitente = documento_com_14_posicoes(ifelse(is.na(notas$cnpj_emitente), notas$cpf_emitente,
                                                           notas$cnpj_emitente))
  outro_emitente = referencias_da_nota$chave[!de_avulsa & documento_com_14_posicoes(referencias_da_nota$documento) !=
                                               documento_do_emitente[da_nota]]
  com_avulsa = referencias_da_nota$chave[de_avulsa]
  emitente_sem_saber = notas$chave %in% com_avulsa & !(notas$chave %in% outro_emitente)
  outra_uf = referencias_da_nota$chave[referencias_da_nota$uf != notas$uf_codigo[da_nota]]
  nfe_referenciadas = referencias[referencias$tipo == "refNFe", ]
  do_credito_de_retorno = notas$tipo_nota_credito[match(nfe_referenciadas$chave, notas$chave)] %in% "03"
  modelo_errado = nfe_referenciadas$chave[!(nfe_referenciadas$modelo == "55" |
                                             (do_credito_de_retorno & nfe_referenciadas$modelo == "65"))]
  complementar_ou_credito = notas$finalidade %in% "2" | credito %in% c("03", "04")
  com_local = !is.na(notas$local_operacao)
  tabela_do_local = tabela_fiscal("local_operacao_ibs_cbs")
  do_local = match(notas$local_operacao, tabela_do_local$codigo)
  local_fora_da_tabela = com_local & is.na(do_local)
  texto_da_finalidade = paste0("finNFe ", texto_ou_vazio(notas$finalidade), ", tpNFDebito ", texto_ou_vazio(debito),
                               ", tpNFCredito ", texto_ou_vazio(credito))
  linhas = list(
    linhas_da_regra("B10a-10", notas, aplica = TRUE, confere = !com_previsao, campo = "ide/dPrevEntrega",
                    no_documento = texto_da_presenca(com_previsao), esperado = "n\u00e3o informado", itens_da_regra = sem_item),
    linhas_da_regra("B10a-20", notas, aplica = com_previsao, confere = previsao <= tres_meses_depois(data_de_saida),
                    campo = "ide/dPrevEntrega", no_documento = notas$previsao_entrega,
                    esperado = paste0("at\u00e9 ", format(tres_meses_depois(data_de_saida))), itens_da_regra = sem_item),
    linhas_da_regra("B10a-30", notas, aplica = com_previsao, confere = previsao >= data_de_saida, campo = "ide/dPrevEntrega",
                    no_documento = notas$previsao_entrega, esperado = paste0("a partir de ", format(data_de_saida)),
                    itens_da_regra = sem_item),
    linhas_da_regra("B10a-40", notas, aplica = com_previsao, confere = notas$finalidade %in% c("1", "4"),
                    campo = "ide/finNFe", no_documento = texto_ou_vazio(notas$finalidade), esperado = "1 ou 4",
                    itens_da_regra = sem_item),
    linhas_da_regra("B10a-50", notas, aplica = notas$modalidade_frete %in% c("1", "4", "9"), confere = !com_previsao,
                    campo = "ide/dPrevEntrega", no_documento = paste0("modFrete ", notas$modalidade_frete, ", dPrevEntrega ",
                                                                      texto_da_presenca(com_previsao)),
                    esperado = "sem a previs\u00e3o de entrega", itens_da_regra = sem_item),
    linhas_da_regra("B25-30", notas, aplica = notas$finalidade %in% "2" | credito %in% c("01", "03", "04"),
                    confere = quantas_referencias > 0, campo = "ide/NFref", no_documento = texto_da_finalidade,
                    esperado = "uma nota referenciada", itens_da_regra = sem_item),
    linhas_da_regra("B25-40", notas,
                    aplica = notas$finalidade %in% "2" | credito %in% c("01", "03", "04") | devolucao_com_uma_referencia,
                    confere = quantas_referencias <= 1, campo = "ide/NFref",
                    no_documento = paste0(quantas_referencias, " referenciadas"), esperado = "no m\u00e1ximo uma",
                    itens_da_regra = sem_item),
    linhas_da_regra("B25-50", notas, aplica = complementar_ou_credito & notas$chave %in% referencias_da_nota$chave,
                    confere = ifelse(emitente_sem_saber, NA, !(notas$chave %in% outro_emitente)), campo = "ide/NFref",
                    no_documento = ifelse(notas$chave %in% outro_emitente, "emitente diferente",
                                          ifelse(emitente_sem_saber, "NF-e avulsa", "o mesmo emitente")),
                    esperado = "o mesmo CNPJ ou CPF do emitente desta nota", itens_da_regra = sem_item,
                    observacao = ifelse(emitente_sem_saber, paste(
                      "A chave da NF-e avulsa (s\u00e9rie 890 a 899) traz o CNPJ do Fisco: s\u00f3 a base da SEFAZ diz o emitente."
                    ), NA)),
    linhas_da_regra("B25-60", notas, aplica = complementar_ou_credito & notas$chave %in% referencias_da_nota$chave,
                    confere = !(notas$chave %in% outra_uf), campo = "ide/NFref",
                    no_documento = ifelse(notas$chave %in% outra_uf, "outra UF", "a mesma UF"),
                    esperado = paste0("a UF ", notas$uf_codigo), itens_da_regra = sem_item),
    linhas_da_regra("B25-65", notas, aplica = credito %in% "02", confere = quantas_referencias == 0, campo = "ide/NFref",
                    no_documento = paste0(quantas_referencias, " referenciadas"), esperado = "nenhuma",
                    itens_da_regra = sem_item),
    linhas_da_regra("B25-100", notas, aplica = notas$finalidade %in% "5" & notas$chave %in% nfe_referenciadas$chave,
                    confere = !(notas$chave %in% modelo_errado), campo = "ide/NFref/refNFe",
                    no_documento = ifelse(notas$chave %in% modelo_errado, "outro modelo", "modelo 55"),
                    esperado = "NF-e modelo 55 (ou 65 no cr\u00e9dito de retorno)", itens_da_regra = sem_item),
    linhas_da_regra("B25-110", notas, aplica = notas$finalidade %in% "5", confere = notas$tipo_operacao %in% "0",
                    campo = "ide/tpNF", no_documento = texto_ou_vazio(notas$tipo_operacao), esperado = "0 (entrada)",
                    itens_da_regra = sem_item),
    linhas_da_regra("B25-120", notas, aplica = notas$finalidade %in% "6", confere = notas$tipo_operacao %in% "1",
                    campo = "ide/tpNF", no_documento = texto_ou_vazio(notas$tipo_operacao), esperado = "1 (sa\u00edda)",
                    itens_da_regra = sem_item),
    linhas_da_regra("B25.1-10", notas, aplica = !is.na(debito), confere = notas$finalidade %in% "6", campo = "ide/finNFe",
                    no_documento = texto_da_finalidade, esperado = "finNFe 6 (nota de d\u00e9bito)", itens_da_regra = sem_item),
    linhas_da_regra("B25.1-20", notas, aplica = notas$finalidade %in% "6", confere = !is.na(debito), campo = "ide/tpNFDebito",
                    no_documento = texto_ou_vazio(debito), esperado = "informado", itens_da_regra = sem_item),
    linhas_da_regra("B25.2-10", notas, aplica = !is.na(credito), confere = notas$finalidade %in% "5", campo = "ide/finNFe",
                    no_documento = texto_da_finalidade, esperado = "finNFe 5 (nota de cr\u00e9dito)", itens_da_regra = sem_item),
    linhas_da_regra("B25.2-20", notas, aplica = notas$finalidade %in% "5", confere = !is.na(credito),
                    campo = "ide/tpNFCredito", no_documento = texto_ou_vazio(credito), esperado = "informado",
                    itens_da_regra = sem_item),
    linhas_da_regra("B25.2-30", notas, aplica = credito %in% "02", confere = !is.na(ano) & ano >= 2029, campo = "ide/dhEmi",
                    no_documento = paste0("emitida em ", ano), esperado = "a partir de 2029", itens_da_regra = sem_item),
    linhas_da_regra("B25.2-40", notas, aplica = credito %in% "03", confere = notas$tipo_operacao %in% "0", campo = "ide/tpNF",
                    no_documento = texto_ou_vazio(notas$tipo_operacao), esperado = "0 (entrada)", itens_da_regra = sem_item),
    linhas_da_regra("B25b-20", notas, aplica = TRUE, confere = notas$presenca %in% c("1", "4", "5"), campo = "ide/indPres",
                    no_documento = texto_ou_vazio(notas$presenca), esperado = "1, 4 ou 5 (presencial)",
                    itens_da_regra = sem_item),
    linhas_da_regra("B25b-60", notas, aplica = !is.na(notas$municipio_fato_gerador_ibs), confere = notas$presenca %in% "5",
                    campo = "ide/indPres", no_documento = texto_ou_vazio(notas$presenca),
                    esperado = "5 (presencial fora do estabelecimento)", itens_da_regra = sem_item),
    linhas_da_regra("B25b-70", notas, aplica = notas$presenca %in% "5", confere = !is.na(notas$municipio_fato_gerador_ibs),
                    campo = "ide/cMunFGIBS", no_documento = texto_ou_vazio(notas$municipio_fato_gerador_ibs),
                    esperado = "informado", itens_da_regra = sem_item),
    linhas_da_regra("B25d-10", notas, aplica = TRUE, confere = !com_local, campo = "ide/cIndOp",
                    no_documento = texto_ou_vazio(notas$local_operacao), esperado = "n\u00e3o informado",
                    itens_da_regra = sem_item),
    linhas_da_regra("B25d-20", notas, aplica = com_local,
                    confere = ifelse(local_fora_da_tabela, NA, tabela_do_local$permitido_na_nfe[do_local] %in% 1),
                    campo = "ide/cIndOp", no_documento = texto_ou_vazio(notas$local_operacao),
                    esperado = "um c\u00f3digo que vale na NF-e (010104 ou 010105)",
                    observacao = ifelse(local_fora_da_tabela, "O c\u00f3digo n\u00e3o est\u00e1 na tabela do cIndOp (Anexo VII da NFS-e).",
                                        NA), itens_da_regra = sem_item),
    linhas_da_regra("B25d-30", notas, aplica = notas$local_operacao %in% c("010104", "010105"), confere = notas$tem_retirada,
                    campo = "retirada", no_documento = texto_da_presenca(notas$tem_retirada), esperado = "informado",
                    itens_da_regra = sem_item)
  )
  juntar_linhas(linhas)
}

# A compra governamental: o grupo não vale na NFC-e (BB01-10) e as chaves dos documentos anteriores, pelo tipo da
# operação (BB05-10 a BB05-50) e pela própria chave (BB05-60 a BB05-180, menos o que só a base da SEFAZ diz).
conferir_a_compra_governamental = function(notas, chaves_anteriores) {
  sem_item = rep(NA_integer_, nrow(notas))
  quantas = as.integer(table(factor(chaves_anteriores$chave, levels = notas$chave)))
  operacao = notas$operacao_governamental
  texto_de_quantas = paste0(quantas, " chaves anteriores")
  linhas = list(
    linhas_da_regra("BB01-10", notas, aplica = TRUE, confere = !notas$tem_compra_governamental, campo = "ide/gCompraGov",
                    no_documento = texto_da_presenca(notas$tem_compra_governamental), esperado = "n\u00e3o informado",
                    itens_da_regra = sem_item),
    linhas_da_regra("BB05-10", notas, aplica = operacao %in% "1", confere = quantas == 0, campo = "ide/gCompraGov/refDFeAnt",
                    no_documento = texto_de_quantas, esperado = "nenhuma", itens_da_regra = sem_item),
    linhas_da_regra("BB05-20", notas, aplica = operacao %in% "2", confere = quantas > 0, campo = "ide/gCompraGov/refDFeAnt",
                    no_documento = texto_de_quantas, esperado = "uma", itens_da_regra = sem_item),
    linhas_da_regra("BB05-30", notas, aplica = operacao %in% "2", confere = quantas <= 1, campo = "ide/gCompraGov/refDFeAnt",
                    no_documento = texto_de_quantas, esperado = "no m\u00e1ximo uma", itens_da_regra = sem_item),
    linhas_da_regra("BB05-40", notas, aplica = operacao %in% "3", confere = quantas > 0, campo = "ide/gCompraGov/refDFeAnt",
                    no_documento = texto_de_quantas, esperado = "ao menos uma", itens_da_regra = sem_item),
    linhas_da_regra("BB05-50", notas, aplica = operacao %in% "4", confere = quantas == 0, campo = "ide/gCompraGov/refDFeAnt",
                    no_documento = texto_de_quantas, esperado = "nenhuma", itens_da_regra = sem_item)
  )
  chave = chaves_anteriores$chave_referenciada
  da_nota = match(chaves_anteriores$chave, notas$chave)
  com_44 = !is.na(chave) & nchar(chave) == 44
  ano = suppressWarnings(as.integer(substr(chave, 3, 4)))
  mes = suppressWarnings(as.integer(substr(chave, 5, 6)))
  serie = suppressWarnings(as.integer(substr(chave, 23, 25)))
  forma_de_emissao = substr(chave, 35, 35)
  documento = substr(chave, 7, 20)
  # Na NF-e de emissão própria pelo Fisco (forma 3), o 5º dígito do número diz se a chave tem CNPJ (1) ou CPF (2).
  quinto_digito_do_numero = substr(chave, 30, 30)
  com_cnpj = ifelse(forma_de_emissao == "3", quinto_digito_do_numero == "1", !is.na(serie) & serie <= 909)
  com_cpf = ifelse(forma_de_emissao == "3", quinto_digito_do_numero == "2", !is.na(serie) & serie >= 910 & serie <= 969)
  documento_certo = ifelse(com_cnpj, documento != strrep("0", 14) & cnpj_confere(documento),
                           ifelse(com_cpf, cpf_confere(substr(documento, 4, 14)), TRUE))
  ano_da_emissao = as.integer(format(notas$data_emissao[da_nota], "%Y")) %% 100
  documento_do_emitente = documento_com_14_posicoes(ifelse(is.na(notas$cnpj_emitente[da_nota]), notas$cpf_emitente[da_nota],
                                                           notas$cnpj_emitente[da_nota]))
  avulsa = serie_avulsa(substr(chave, 23, 25))
  digito = chave_digito(chave)
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior("BB05-60", chaves_anteriores, TRUE, com_44, "44 posi\u00e7\u00f5es")
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior(
    "BB05-70", chaves_anteriores, com_44, (digito == suppressWarnings(as.integer(substr(chave, 44, 44)))) %in% TRUE,
    "o d\u00edgito verificador certo"
  )
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior("BB05-80", chaves_anteriores, com_44,
                                                          substr(chave, 1, 2) %in% names(UF_PELO_CODIGO), "o c\u00f3digo de uma UF")
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior("BB05-90", chaves_anteriores, com_44,
                                                          !is.na(ano) & ano >= 6 & ano <= ano_da_emissao,
                                                          "ano de 06 at\u00e9 o da emiss\u00e3o")
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior("BB05-100", chaves_anteriores, com_44,
                                                          !is.na(mes) & mes >= 1 & mes <= 12, "m\u00eas de 01 a 12")
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior("BB05-110", chaves_anteriores, com_44, documento_certo,
                                                          "CNPJ ou CPF v\u00e1lido para a s\u00e9rie")
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior("BB05-120", chaves_anteriores, com_44,
                                                          substr(chave, 21, 22) == "55", "modelo 55")
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior("BB05-130", chaves_anteriores, com_44,
                                                          substr(chave, 26, 34) != strrep("0", 9),
                                                          "n\u00famero diferente de zero")
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior("BB05-140", chaves_anteriores, TRUE,
                                                          !duplicated(paste(chaves_anteriores$chave, chave)),
                                                          "sem repetir a chave")
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior("BB05-150", chaves_anteriores, TRUE,
                                                          chave != chaves_anteriores$chave, "outra chave, n\u00e3o a desta nota")
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior("BB05-160", chaves_anteriores,
                                                          com_44 & !is.na(ano) & !is.na(mes) & (ano * 100 + mes) > 1104,
                                                          forma_de_emissao %in% c("1", "2", "3", "4", "5", "6", "7", "9"),
                                                          "forma de emiss\u00e3o 1 a 7 ou 9")
  linhas[[length(linhas) + 1]] = linhas_da_chave_anterior(
    "BB05-180", chaves_anteriores, com_44,
    ifelse(avulsa, NA, cnpj_base_ou_cpf(documento) == cnpj_base_ou_cpf(documento_do_emitente)),
    "o mesmo CNPJ base ou CPF do emitente desta nota",
    observacao = ifelse(avulsa, "Chave de NF-e avulsa: o CNPJ dela \u00e9 o do Fisco, e o do emitente s\u00f3 a SEFAZ tem.", NA)
  )
  juntar_linhas(linhas)
}

# Uma linha por chave anterior da compra governamental.
linhas_da_chave_anterior = function(regra, chaves_anteriores, aplica, confere, esperado, observacao = NA_character_) {
  linhas_da_regra(regra, chaves_anteriores, aplica = aplica, confere = confere, campo = "ide/gCompraGov/refDFeAnt",
                  no_documento = chaves_anteriores$chave_referenciada, esperado = esperado, observacao = observacao,
                  itens_da_regra = rep(NA_integer_, nrow(chaves_anteriores)))
}

# O emitente e o destinatário na Suframa: o município do emitente com a inscrição (C22-10), o dígito da inscrição
# (C22-20) e a UF do destinatário com a inscrição (E18-30).
conferir_o_emitente_e_o_destinatario = function(notas) {
  sem_item = rep(NA_integer_, nrow(notas))
  com_inscricao = !is.na(notas$inscricao_suframa_emitente)
  destinatario_com_inscricao = !is.na(notas$inscricao_suframa_destinatario)
  destino_na_suframa = notas$uf_destinatario %in% UFS_DA_SUFRAMA |
    (notas$uf_destinatario %in% "AP" & notas$municipio_destinatario %in% MUNICIPIOS_DO_AMAPA_NA_SUFRAMA)
  juntar_linhas(list(
    linhas_da_regra("C22-10", notas, aplica = com_inscricao, confere = notas$municipio_emitente %in% AREAS_INCENTIVADAS$municipio,
                    campo = "emit/enderEmit/cMun", no_documento = texto_ou_vazio(notas$municipio_emitente),
                    esperado = "um munic\u00edpio da ZFM ou de uma ALC", itens_da_regra = sem_item),
    linhas_da_regra("C22-20", notas, aplica = com_inscricao, confere = inscricao_suframa_confere(notas$inscricao_suframa_emitente),
                    campo = "emit/ISUFEmit", no_documento = texto_ou_vazio(notas$inscricao_suframa_emitente),
                    esperado = "o d\u00edgito verificador certo (MOC 7.0, 8.4)", itens_da_regra = sem_item),
    linhas_da_regra("E18-30", notas, aplica = destinatario_com_inscricao, confere = destino_na_suframa, campo = "dest/enderDest/UF",
                    no_documento = paste0(texto_ou_vazio(notas$uf_destinatario), " ", texto_ou_vazio(notas$municipio_destinatario)),
                    esperado = "AC, AM, RO, RR ou Macap\u00e1 e Santana (AP)", itens_da_regra = sem_item)
  ))
}

# Se o produto da ANP estava na tabela de combustíveis do ICMS monofásico na data de emissão.
combustivel_monofasico_na_data = function(produtos, datas) {
  tabela = tabela_fiscal("combustiveis_monofasicos")
  esta = rep(FALSE, length(produtos))
  for (numero_da_linha in seq_len(nrow(tabela))) {
    esta = esta | (!is.na(produtos) & produtos == tabela$codigo[numero_da_linha] & !is.na(datas) &
                     datas >= tabela$inicio[numero_da_linha] &
                     (is.na(tabela$fim[numero_da_linha]) | datas <= tabela$fim[numero_da_linha]))
  }
  esta
}

# As regras de cada item da nota (não só os que têm o IBS e a CBS): os tributos da nota de débito e de crédito, o ICMS
# ou o ISSQN, a compra governamental nos anos de transição, a classificação para a subapuração na ZFM, o CFOP da
# devolução, a origem e o ICMS monofásico, o ICMS da UF de destino, o PIS e a COFINS e o documento referenciado.
conferir_os_itens_da_nota = function(itens, referencias) {
  finalidade = itens$finalidade
  credito = itens$tipo_nota_credito
  debito = itens$tipo_nota_debito
  ano = as.integer(format(itens$data_emissao, "%Y"))
  debito_ou_credito = finalidade %in% c("5", "6") | itens$operacao_governamental %in% "2"
  # B25-80: na nota de débito e de crédito só vão o IBS e a CBS; o pagamento antecipado (débito 06) aceita o PIS e a
  # COFINS na nota de 2026 e o IPI sempre.
  pagamento_antecipado = debito %in% "06"
  com_pis_e_cofins_aceitos = pagamento_antecipado & ano %in% 2026
  tributos_a_mais = cbind(
    ICMS = itens$tem_icms, ISSQN = itens$tem_issqn, IPI = itens$tem_ipi & !pagamento_antecipado, II = itens$tem_ii,
    PIS = itens$tem_pis & !com_pis_e_cofins_aceitos, PISST = itens$tem_pis_st & !com_pis_e_cofins_aceitos,
    COFINS = itens$tem_cofins & !com_pis_e_cofins_aceitos, COFINSST = itens$tem_cofins_st & !com_pis_e_cofins_aceitos,
    ICMSUFDest = itens$tem_icms_uf_destino, impostoDevol = itens$tem_imposto_devolvido
  )
  nomes_a_mais = character(nrow(itens))
  for (nome_do_tributo in colnames(tributos_a_mais)) {
    com_o_tributo = tributos_a_mais[, nome_do_tributo] %in% TRUE
    nomes_a_mais[com_o_tributo] = ifelse(nomes_a_mais[com_o_tributo] == "", nome_do_tributo,
                                         paste0(nomes_a_mais[com_o_tributo], ", ", nome_do_tributo))
  }
  # O CFOP de devolução pela tabela de CFOP (indDevol), e os de retorno e de remessa (exceções da NA01-20).
  tabela_de_cfop = tabela_fiscal("cfop")
  do_cfop = match(itens$cfop, tabela_de_cfop$codigo)
  cfop_de_devolucao = tabela_de_cfop$devolucao[do_cfop] %in% 1
  devolucao_ou_retorno = finalidade %in% "4" | credito %in% c("03", "06")
  cfop_aceito_na_devolucao = cfop_de_devolucao | itens$cfop %in% c("1949", "2949") |
    (itens$cfop %in% c("5949", "6949") & itens$ncm %in% "27112100")
  # NA01-20: o ICMS da UF de destino na venda interestadual a consumidor final não contribuinte, com as exceções.
  # A exceção 3 fala da NF "com chave de acesso" anterior a 2016: a do cabeçalho ou a do próprio item (DFeReferenciado).
  referencias_antigas = referencias$chave[referencias$tipo %in% c("refNFe", "refNFeSig") &
                                            (suppressWarnings(as.integer(referencias$ano)) < 16) %in% TRUE]
  item_referencia_chave_antiga = (suppressWarnings(as.integer(substr(itens$referenciado_chave, 3, 4))) < 16) %in% TRUE
  combustivel_fora_da_partilha = itens$tem_combustivel & !(itens$produto_anp %in% PRODUTOS_ANP_DA_PARTILHA)
  icms_sem_partilha = itens$cst_icms %in% c("40", "41") | itens$csosn %in% c("103", "300", "400")
  pede_icms_do_destino = itens$destino_operacao %in% "2" & itens$consumidor_final %in% "1" &
    itens$indicador_ie_destinatario %in% "9" & !itens$tem_issqn & !itens$tem_icms_partilha &
    !(finalidade %in% "4" & (itens$chave %in% referencias_antigas | item_referencia_chave_antiga)) &
    !(tabela_de_cfop$retorno[do_cfop] %in% 1) &
    !(itens$tipo_operacao %in% "0") & !combustivel_fora_da_partilha &
    !(!is.na(itens$uf_entrega) & itens$uf_entrega == itens$uf_emitente) & !(tabela_de_cfop$remessa[do_cfop] %in% 1) &
    !(itens$cfop %in% c("6552", "6922", "6929")) & !icms_sem_partilha & !(finalidade %in% c("2", "3", "5", "6")) &
    !(itens$operacao_governamental %in% "2") & !(itens$regime_tributario %in% c("1", "4"))
  # O documento referenciado no item.
  com_dfe = itens$tem_dfe_referenciado
  nfe_no_cabecalho = itens$chave %in% referencias$chave[referencias$tipo == "refNFe"]
  chaves_por_nota = unique(data.frame(chave = itens$chave[com_dfe], referenciada = itens$referenciado_chave[com_dfe]))
  documentos_diferentes = as.integer(table(factor(chaves_por_nota$chave, levels = unique(itens$chave)))[itens$chave])
  documento_referenciado = substr(itens$referenciado_chave, 7, 20)
  referenciadas_proprias = com_dfe & !serie_avulsa(substr(itens$referenciado_chave, 23, 25))
  emitentes_por_nota = unique(data.frame(chave = itens$chave[referenciadas_proprias],
                                         emitente = cnpj_base_ou_cpf(documento_referenciado[referenciadas_proprias])))
  emitentes_diferentes = as.integer(table(factor(emitentes_por_nota$chave, levels = unique(itens$chave)))[itens$chave])
  # I05k-20: o 0 do tpCredPresIBSZFM fora da ZFM fica sem conferir (há NF-e autorizada assim).
  emitente_na_suframa = itens$uf_emitente %in% UFS_DA_SUFRAMA |
    (itens$uf_emitente %in% "AP" & itens$municipio_emitente %in% MUNICIPIOS_DO_AMAPA_NA_SUFRAMA)
  zero_fora_da_suframa = itens$tipo_credito_zfm_produto %in% "0" & !emitente_na_suframa
  # VC02-14: a redação antiga (NT 2013/005): a devolução referencia um documento no cabeçalho (NFref) ou no item, menos
  # nos CFOP da exceção. A da v1.53: sem o refNFe no cabeçalho, o item referencia. O cronograma da v1.53 (publicada em
  # 30/10/2026) põe a nova em produção "até 16/11/2026": entre as duas datas, quando as redações discordam, fica sem
  # conferir.
  devolucao_nova = (itens$data_emissao >= INICIO_DA_DEVOLUCAO_NOVA) %in% TRUE
  devolucao_na_janela = !devolucao_nova & (itens$data_emissao >= PUBLICACAO_DA_DEVOLUCAO_NOVA) %in% TRUE
  com_referencia_antiga = itens$chave %in% referencias$chave[referencias$tipo %in% REFERENCIAS_DA_DEVOLUCAO_ANTIGA]
  aplica_a_antiga = finalidade %in% "4" & !(itens$cfop %in% CFOP_FORA_DA_DEVOLUCAO_ANTIGA)
  aplica_a_nova = finalidade %in% "4" & !nfe_no_cabecalho & !(itens$cfop %in% c("5921", "6921"))
  errada_pela_antiga = aplica_a_antiga & !(com_dfe | com_referencia_antiga)
  errada_pela_nova = aplica_a_nova & !com_dfe
  aplica_a_devolucao = ifelse(devolucao_nova, aplica_a_nova,
                              ifelse(devolucao_na_janela, aplica_a_antiga | aplica_a_nova, aplica_a_antiga))
  confere_a_devolucao = ifelse(devolucao_nova, !errada_pela_nova,
                               ifelse(devolucao_na_janela, ifelse(errada_pela_antiga == errada_pela_nova, !errada_pela_nova, NA),
                                      !errada_pela_antiga))
  linhas = list(
    linhas_da_regra("B25-80", itens, aplica = debito_ou_credito & !(credito %in% c("03", "04", "06")) & !(debito %in% "07"),
                    confere = nomes_a_mais == "", campo = "imposto", no_documento = ifelse(nomes_a_mais == "", "s\u00f3 o IBS e a CBS",
                                                                                           nomes_a_mais),
                    esperado = "s\u00f3 o IBS e a CBS"),
    linhas_da_regra("B25-90", itens, aplica = !debito_ou_credito, confere = itens$tem_icms | itens$tem_issqn,
                    campo = "imposto/ICMS ou imposto/ISSQN", no_documento = ifelse(itens$tem_icms | itens$tem_issqn, "informado",
                                                                                   "nenhum dos dois"),
                    esperado = "o ICMS ou o ISSQN"),
    linhas_da_regra("I05k-10", itens, aplica = TRUE, confere = is.na(itens$tipo_credito_zfm_produto),
                    campo = "prod/tpCredPresIBSZFM", no_documento = texto_ou_vazio(itens$tipo_credito_zfm_produto),
                    esperado = "n\u00e3o informado"),
    linhas_da_regra("I05k-20", itens, aplica = !is.na(itens$tipo_credito_zfm_produto),
                    confere = ifelse(zero_fora_da_suframa, NA, emitente_na_suframa),
                    campo = "emit/enderEmit/UF", no_documento = paste0(texto_ou_vazio(itens$uf_emitente), ", tpCredPresIBSZFM ",
                                                                       texto_ou_vazio(itens$tipo_credito_zfm_produto)),
                    esperado = "AC, AM, RO, RR ou Macap\u00e1 e Santana (AP)",
                    observacao = ifelse(zero_fora_da_suframa, paste0(
                      "O 0 \u00e9 \"sem cr\u00e9dito presumido\": a NT n\u00e3o diz se ele conta como informado, e h\u00e1 NF-e ",
                      "autorizada com o 0 fora da ZFM."), NA)),
    linhas_da_regra("I08-140", itens, aplica = devolucao_ou_retorno, confere = cfop_aceito_na_devolucao, campo = "prod/CFOP",
                    no_documento = texto_ou_vazio(itens$cfop), esperado = "um CFOP de devolu\u00e7\u00e3o (indDevol 1), 1949 ou 2949"),
    linhas_da_regra("I08-141", itens,
                    aplica = itens$regime_tributario %in% "4" & !(itens$destino_operacao %in% "3") & devolucao_ou_retorno,
                    confere = itens$cfop %in% c("1202", "1553", "2202", "2553", "5202", "6202"), campo = "prod/CFOP",
                    no_documento = texto_ou_vazio(itens$cfop), esperado = "1202, 1553, 2202, 2553, 5202 ou 6202"),
    linhas_da_regra("I08-144", itens,
                    aplica = !(finalidade %in% c("2", "4")) & !(finalidade %in% "5" & credito %in% c("03", "04", "06")),
                    confere = !cfop_de_devolucao, campo = "prod/CFOP", no_documento = texto_ou_vazio(itens$cfop),
                    esperado = "um CFOP que n\u00e3o \u00e9 de devolu\u00e7\u00e3o"),
    linhas_da_regra("N11-10", itens, aplica = itens$tem_icms & !(itens$regime_tributario %in% "4") & !(finalidade %in% c("5", "6")),
                    confere = itens$tem_origem_icms, campo = "imposto/ICMS/orig",
                    no_documento = texto_da_presenca(itens$tem_origem_icms), esperado = "informado"),
    linhas_da_regra("N12-110", itens,
                    aplica = combustivel_monofasico_na_data(itens$produto_anp, itens$data_emissao) & !(finalidade %in% c("5", "6")),
                    confere = itens$cst_icms %in% c("02", "15", "53", "61", "40", "41", "50", "90"), campo = "imposto/ICMS/CST",
                    no_documento = paste0("CST ", texto_ou_vazio(itens$cst_icms), ", cProdANP ", texto_ou_vazio(itens$produto_anp)),
                    esperado = "CST 02, 15, 53 ou 61 (ou 40, 41, 50 ou 90)"),
    linhas_da_regra("NA01-20", itens, aplica = pede_icms_do_destino, confere = itens$tem_icms_uf_destino,
                    campo = "imposto/ICMSUFDest", no_documento = texto_da_presenca(itens$tem_icms_uf_destino),
                    esperado = "informado"),
    linhas_da_regra("Q01-20", itens, aplica = !debito_ou_credito, confere = itens$tem_pis, campo = "imposto/PIS",
                    no_documento = texto_da_presenca(itens$tem_pis), esperado = "informado"),
    linhas_da_regra("S01-20", itens, aplica = !debito_ou_credito, confere = itens$tem_cofins, campo = "imposto/COFINS",
                    no_documento = texto_da_presenca(itens$tem_cofins), esperado = "informado"),
    linhas_da_regra("VC02-04", itens, aplica = TRUE, confere = !com_dfe, campo = "DFeReferenciado",
                    no_documento = texto_da_presenca(com_dfe), esperado = "n\u00e3o informado"),
    linhas_da_regra("VC02-05", itens, aplica = com_dfe, confere = !itens$tem_referencia, campo = "ide/NFref",
                    no_documento = texto_da_presenca(itens$tem_referencia), esperado = "sem refer\u00eancia no cabe\u00e7alho"),
    linhas_da_regra("VC02-07", itens, aplica = finalidade %in% "5" & !(credito %in% "06"), confere = !com_dfe,
                    campo = "DFeReferenciado", no_documento = texto_da_presenca(com_dfe), esperado = "n\u00e3o informado"),
    linhas_da_regra("VC02-10", itens, aplica = debito %in% c("03", "04") | credito %in% "06", confere = com_dfe,
                    campo = "DFeReferenciado", no_documento = texto_da_presenca(com_dfe), esperado = "informado"),
    linhas_da_regra("VC02-14", itens, aplica = aplica_a_devolucao, confere = confere_a_devolucao, campo = "DFeReferenciado",
                    no_documento = ifelse(com_referencia_antiga, "NFref no cabe\u00e7alho", texto_da_presenca(com_dfe)),
                    esperado = ifelse(devolucao_nova, "informado (sem refNFe no cabe\u00e7alho)",
                                      "informado, ou um documento no NFref do cabe\u00e7alho"),
                    observacao = ifelse(devolucao_na_janela & is.na(confere_a_devolucao), paste(
                      "Entre 30/10 e 15/11/2026 a SEFAZ podia aplicar a reda\u00e7\u00e3o antiga ou a da NT v1.53 (em produ\u00e7\u00e3o",
                      "\"at\u00e9 16/11/2026\"), e elas discordam aqui."), NA)),
    linhas_da_regra("VC02-30", itens, aplica = com_dfe & !(debito %in% c("03", "07")) & !(finalidade %in% "4"),
                    confere = documentos_diferentes <= 1, campo = "DFeReferenciado/chaveAcesso",
                    no_documento = paste0(documentos_diferentes, " documentos na nota"), esperado = "um documento s\u00f3"),
    linhas_da_regra("VC02-40", itens, aplica = referenciadas_proprias & finalidade %in% "4",
                    confere = emitentes_diferentes <= 1, campo = "DFeReferenciado/chaveAcesso",
                    no_documento = paste0(emitentes_diferentes, " emitentes na nota"), esperado = "o mesmo emitente em todos"),
    linhas_da_regra("VC03-10", itens, aplica = debito %in% "03" & com_dfe, confere = is.na(itens$referenciado_item),
                    campo = "DFeReferenciado/nItem", no_documento = texto_ou_vazio(itens$referenciado_item),
                    esperado = "n\u00e3o informado")
  )
  # BB02-10: nos anos de transição, a compra de um ente não leva a alíquota dos outros (a tabela da regra).
  linhas[[length(linhas) + 1]] = conferir_as_aliquotas_da_compra_governamental(itens[itens$tem_ibs_cbs, ])
  juntar_linhas(linhas)
}

conferir_as_aliquotas_da_compra_governamental = function(itens) {
  ano = as.integer(format(itens$data_emissao, "%Y"))
  ente = itens$ente_governamental
  ibs_uf = valor_ou_zero(itens$aliquota_ibs_uf) > 0
  ibs_mun = valor_ou_zero(itens$aliquota_ibs_mun) > 0
  cbs = valor_ou_zero(itens$aliquota_cbs) > 0
  na_transicao = !is.na(ano) & ano >= 2027 & ano <= 2032
  depois = !is.na(ano) & ano >= 2033
  outra_aliquota = ifelse(na_transicao,
                          (ente %in% "1" & (ibs_uf | ibs_mun)) | (ente %in% c("2", "3") & ibs_mun) | (ente %in% "4" & ibs_uf),
                          (ente %in% "1" & (ibs_uf | ibs_mun)) | (ente %in% c("2", "3") & (cbs | ibs_mun)) |
                            (ente %in% "4" & (ibs_uf | cbs)))
  linhas_da_regra("BB02-10", itens, aplica = itens$tem_compra_governamental & ente %in% c("1", "2", "3", "4") &
                    (na_transicao | depois),
                  confere = !outra_aliquota, campo = "gIBSCBS",
                  no_documento = paste0("tpEnteGov ", texto_ou_vazio(ente), ", pIBSUF ", texto_da_aliquota(itens$aliquota_ibs_uf),
                                        ", pIBSMun ", texto_da_aliquota(itens$aliquota_ibs_mun), ", pCBS ",
                                        texto_da_aliquota(itens$aliquota_cbs)),
                  esperado = "zero nas al\u00edquotas dos outros entes")
}

# Os totais que não são do IBS e da CBS: o total dos produtos é a soma dos itens que entram no total (W07-10) e o grupo
# do Imposto Seletivo existe quando algum item tem (W31-10 e W31-20). A W07-10 não diz tolerância, mas há NF-e
# autorizada com 0,01 de diferença: até o centavo confere, um centavo fica sem conferir e mais que isso não confere.
conferir_os_outros_totais = function(itens, notas) {
  sem_item = rep(NA_integer_, nrow(notas))
  soma_dos_produtos = rep(0, nrow(notas))
  # Pela redação da v1.40 (a em produção desde 03/08/2026): os itens com indTot 1 sujeitos ao ICMS ou ao IBS, à CBS ou
  # ao IS (o serviço só com o ISSQN, na nota conjugada, fica fora).
  entram = itens$entra_no_total %in% "1" & (itens$tem_icms | itens$tem_ibs_cbs | itens$tem_is)
  if (any(entram)) {
    somas = rowsum(valor_ou_zero(itens$valor_produto[entram]), itens$chave[entram])
    soma_dos_produtos = valor_ou_zero(somas[match(notas$chave, rownames(somas)), 1])
  }
  total_dos_produtos = valor_ou_zero(notas$total_produtos)
  produtos_no_centavo = igual_com_tolerancia(total_dos_produtos, soma_dos_produtos, TOLERANCIA_DO_CENTAVO)
  produtos_com_um_centavo = !produtos_no_centavo &
    igual_com_tolerancia(total_dos_produtos, soma_dos_produtos, TOLERANCIA_DOS_VALORES)
  com_imposto_seletivo = notas$chave %in% itens$chave[itens$tem_is]
  juntar_linhas(list(
    linhas_da_regra("W07-10", notas, aplica = TRUE, confere = ifelse(produtos_com_um_centavo, NA, produtos_no_centavo),
                    campo = "ICMSTot/vProd", no_documento = texto_do_numero(notas$total_produtos, 2),
                    esperado = texto_do_numero(soma_dos_produtos, 2), diferenca = total_dos_produtos - soma_dos_produtos,
                    observacao = ifelse(produtos_com_um_centavo, paste0(
                      "A NT n\u00e3o d\u00e1 toler\u00e2ncia, mas h\u00e1 NF-e autorizada com 0,01 de diferen\u00e7a entre o ",
                      "total dos produtos e a soma dos itens."), NA),
                    itens_da_regra = sem_item),
    linhas_da_regra("W31-10", notas, aplica = notas$tem_total_is, confere = com_imposto_seletivo, campo = "ISTot",
                    no_documento = "informado", esperado = "s\u00f3 com algum item com o IS", itens_da_regra = sem_item),
    linhas_da_regra("W31-20", notas, aplica = !notas$tem_total_is, confere = !com_imposto_seletivo, campo = "ISTot",
                    no_documento = "n\u00e3o informado", esperado = "informado, porque algum item tem o IS", itens_da_regra = sem_item)
  ))
}
