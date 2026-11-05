# As regras de validação da pré-conferência (nfe_conferir), grupo por grupo do Anexo I do MOC 7.0, cada uma pela
# redação da nota técnica mais nova que a mudou (a fonte de cada uma está em inst/extdata/regras_nfe.csv). Cada função
# devolve as linhas das regras do grupo (linhas_da_regra, de ibs_cbs_conferir.R); o modelo e as datas de cada regra
# são filtrados depois, em completar_com_as_regras_da_nfe.

#' @include ler_xml.R tabelas.R chave.R ibs_cbs_conferir.R ibs_cbs_regras_da_nota.R
NULL

SEM_ITEM = NA_integer_
# Os 5 minutos de diferença de relógio que a SEFAZ aceita (B09-10 e B09-40), em segundos.
TOLERANCIA_DO_RELOGIO = 300
SEGUNDOS_POR_DIA = 86400
# O total da nota aceita R$ 0,50 a mais ou a menos (nota (*3) do Anexo I).
TOLERANCIA_DO_TOTAL_DA_NOTA = 0.5
LIMITE_DA_NFCE_SEM_DESTINATARIO = 10000
# O valor máximo padrão da NFC-e e da NF-e com DANFE Simplificado Tipo 2 (W16-30); a UF pode definir outro.
LIMITE_DA_NFCE = 200000
# A origem da mercadoria importada (tabela de origem: 1, 2, 3 e 8), para a alíquota interestadual (NA09-10 e NA09-20).
ORIGENS_DE_IMPORTADO = c("1", "2", "3", "8")
LIMITE_DO_TROCO = 300000
LITERAL_DO_DESTINATARIO_EM_HOMOLOGACAO = "NF-E EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL"
LITERAL_DO_ITEM_EM_HOMOLOGACAO = "NOTA FISCAL EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL"
CODIGOS_NUMERICOS_PROIBIDOS = c("00000000", "11111111", "22222222", "33333333", "44444444", "55555555", "66666666",
                                "77777777", "88888888", "99999999", "12345678", "23456789", "34567890", "45678901",
                                "56789012", "67890123", "78901234", "89012345", "90123456", "01234567")
# Os CFOP que a NFC-e e a NF-e com DANFE Simplificado Tipo 2 aceitam (I08-150) e os de cada CST e CSOSN (N12-40,
# N12-44, N12a-40 e N12a-44).
CFOP_DA_NFCE = c("5101", "5102", "5103", "5104", "5115", "5405", "5656", "5667", "5910", "5933")
CFOP_DA_VENDA_NA_NFCE = c("5101", "5102", "5103", "5104", "5115", "5910")
CFOP_DO_ICMS_COBRADO_ANTES_NA_NFCE = c("5405", "5656", "5667", "5910")
CFOP_DE_SERVICO = c("1933", "2933", "5933", "6933")
CFOP_DE_CUPOM_FISCAL = c("5929", "6929")
# Os CFOP fora da exigência do indicador do intermediador (exceção 1 da B25c-10).
CFOP_SEM_INTERMEDIADOR = c("5205", "5206", "5207", "5251", "5252", "5253", "5254", "5255", "5256", "5257", "5258", "5301",
                           "5302", "5303", "5304", "5305", "5306", "5307")
# Os meios de pagamento que aceitam o grupo de cartões (YA04-20). Os códigos 23 e 24 entraram na tabela depois da
# redação da regra: com eles, o grupo fica sem conferir.
MEIOS_COM_CARTAO = c("03", "04", "10", "11", "12", "13", "15", "17", "18")
MEIOS_DEPOIS_DA_REGRA_DO_CARTAO = c("23", "24")
# As UF do destinatário que não permitem o contribuinte isento de IE (E16a-30).
UFS_SEM_ISENTO_DE_IE = c("AL", "AM", "BA", "CE", "DF", "ES", "GO", "MG", "MS", "MT", "PB", "PE", "RJ", "RN", "RS", "SE",
                         "SP")
CODIGO_DA_UF = names(UF_PELO_CODIGO)
names(CODIGO_DA_UF) = UF_PELO_CODIGO
MUNICIPIO_DO_EXTERIOR = "9999999"
PAIS_BRASIL = "1058"
OBSERVACAO_DO_SIMPLIFICADO = paste(
  "A NT 2026.002 n\u00e3o mudou esta regra, mas s\u00f3 exige o destinat\u00e1rio da NF-e com DANFE Simplificado Tipo 2",
  "na opera\u00e7\u00e3o n\u00e3o presencial (E01-20): confira com a SEFAZ."
)
OBSERVACAO_DA_TABELA_DE_HOJE = paste(
  "O c\u00f3digo n\u00e3o est\u00e1 na tabela de hoje, e a nota \u00e9 de antes dela: pode ter sido extinto depois da",
  "emiss\u00e3o."
)

# TRUE onde o campo veio no XML com algum conteúdo.
informado = function(textos) {
  !is.na(textos) & textos != ""
}

numero_ou_na = function(textos) {
  suppressWarnings(as.integer(textos))
}

# TRUE onde o número está entre o início e o fim (inclusive).
na_faixa = function(numeros, inicio, fim) {
  !is.na(numeros) & numeros >= inicio & numeros <= fim
}

municipio_existe = function(codigos) {
  codigos %in% tabela_fiscal("municipios")$codigo
}

codigo_da_uf = function(ufs) {
  unname(CODIGO_DA_UF[ufs])
}

# O dígito do GTIN (8, 12, 13 ou 14 posições): o módulo 10 com os pesos 3 e 1 a partir da direita, sem o dígito. Com
# zeros na frente até 14 posições, o cálculo é o mesmo para todos.
gtin_confere = function(codigos) {
  certo = rep(FALSE, length(codigos))
  formato = !is.na(codigos) & grepl("^([0-9]{8}|[0-9]{12,14})$", codigos)
  if (any(formato)) {
    com_14 = paste0(strrep("0", 14 - nchar(codigos[formato])), codigos[formato])
    digitos = valores_dos_caracteres(substr(com_14, 1, 13), 13)
    soma = as.vector(digitos %*% rep(c(3, 1), length.out = 13))
    certo[formato] = (10 - soma %% 10) %% 10 == as.integer(substr(com_14, 14, 14))
  }
  certo
}

# A soma de uma coluna dos itens por nota, na ordem das notas (a nota sem item soma 0).
somar_por_nota = function(valores, chaves_dos_itens, chaves_das_notas) {
  somas = as.vector(tapply(valor_ou_zero(valores), factor(chaves_dos_itens, levels = chaves_das_notas), sum))
  valor_ou_zero(somas)
}

# A soma de uma coluna dos itens por nota, na ordem das notas.
somar_dos_itens = function(valores, itens, notas) {
  somar_por_nota(valores, itens$chave, notas$chave)
}

# A posição de cada linha entre as da mesma nota (o 1º documento referenciado, a 2ª parcela...).
ordem_na_nota = function(chaves) {
  # Em ordem de chave (a ordenação radix mantém a ordem do XML entre as linhas da mesma chave), a posição de cada
  # linha menos a da primeira da chave dela.
  posicoes = order(chaves, method = "radix")
  chaves_em_ordem = chaves[posicoes]
  ordem = integer(length(chaves))
  ordem[posicoes] = seq_along(chaves_em_ordem) - match(chaves_em_ordem, chaves_em_ordem) + 1L
  ordem
}

texto_do_instante = function(instantes) {
  textos = format(instantes, "%d/%m/%Y %H:%M:%S", tz = "America/Sao_Paulo")
  textos[is.na(instantes)] = "(vazio)"
  textos
}

# A data da tabela fiscal do pacote (quando foi baixada): o código que não está nela pode ter existido antes.
data_da_tabela = function(nome_da_tabela) {
  fontes = tabela_fiscal("fontes")
  fontes$baixada_em[match(nome_da_tabela, fontes$tabela)]
}

# Uma regra de soma: o total da nota tem de ser a soma dos itens, até o centavo (o total que não veio vale zero).
linhas_da_soma = function(regra, notas, total, soma, campo, aplica = TRUE) {
  diferenca = round(valor_ou_zero(total) - soma, 2)
  linhas_da_regra(regra, notas, aplica = aplica, confere = abs(valor_ou_zero(total) - soma) < TOLERANCIA_DO_CENTAVO,
                  campo = campo, no_documento = texto_do_numero(total, 2), esperado = texto_do_numero(soma, 2),
                  diferenca = diferenca, itens_da_regra = SEM_ITEM)
}

# Uma regra de grupo que a NFC-e e a NF-e com DANFE Simplificado Tipo 2 não podem ter.
linhas_do_grupo_proibido = function(regra, tabela, presente, campo, itens_da_regra = SEM_ITEM) {
  linhas_da_regra(regra, tabela, aplica = tabela$simplificada, confere = !presente, campo = campo,
                  no_documento = texto_da_presenca(presente), esperado = "n\u00e3o informado",
                  itens_da_regra = itens_da_regra)
}

linhas_do_cnpj = function(regra, tabela, cnpjs, campo, itens_da_regra = SEM_ITEM) {
  linhas_da_regra(regra, tabela, aplica = informado(cnpjs), confere = cnpj_confere(cnpjs), campo = campo,
                  no_documento = cnpjs, esperado = "CNPJ com o d\u00edgito certo", itens_da_regra = itens_da_regra)
}

linhas_do_cpf = function(regra, tabela, cpfs, campo, itens_da_regra = SEM_ITEM) {
  linhas_da_regra(regra, tabela, aplica = informado(cpfs), confere = cpf_confere(cpfs), campo = campo,
                  no_documento = cpfs, esperado = "CPF com o d\u00edgito certo", itens_da_regra = itens_da_regra)
}

# A chave de acesso, o código numérico, as datas, o modelo do DANFE, a finalidade, a presença, o intermediador, o
# processo de emissão e a contingência (grupos A e B).
conferir_a_chave_e_a_identificacao = function(notas, itens, referencias) {
  numero_da_serie = numero_ou_na(notas$serie)
  documento_da_chave = documento_com_14_posicoes(notas$documento_emitente)
  # Na NF-e avulsa (série 890 a 899), a chave traz o CNPJ do órgão do Fisco, que vem no grupo avulsa.
  da_avulsa = na_faixa(numero_da_serie, 890, 899)
  documento_da_chave[da_avulsa] = notas$cnpj_avulsa[da_avulsa]
  tem_todas_as_partes = !is.na(notas$uf_codigo) & !is.na(notas$emissao_texto) & !is.na(documento_da_chave) &
    !is.na(notas$modelo) & !is.na(numero_da_serie) & !is.na(numero_ou_na(notas$numero)) & !is.na(notas$tipo_emissao) &
    !is.na(notas$codigo_numerico) & !is.na(notas$digito)
  chave_sem_digito = paste0(notas$uf_codigo, substr(notas$emissao_texto, 3, 4), substr(notas$emissao_texto, 6, 7),
                            documento_da_chave, notas$modelo, formatC(numero_da_serie, width = 3, flag = "0"),
                            formatC(numero_ou_na(notas$numero), width = 9, flag = "0"), notas$tipo_emissao,
                            notas$codigo_numerico)
  chave_montada = paste0(chave_sem_digito, notas$digito)
  digito_calculado = chave_digito(chave_sem_digito)
  id_sem_prefixo = sub("^NFe", "", notas$id)

  atraso_em_dias = as.numeric(difftime(notas$recebimento, notas$emissao, units = "days"))
  em_contingencia = notas$tipo_emissao %in% c("2", "4", "5", "9")
  emissao_ate = notas$recebimento + TOLERANCIA_DO_RELOGIO
  observacao_do_recebimento = ifelse(notas$tem_protocolo, "Comparada com a hora do protocolo de autoriza\u00e7\u00e3o.",
                                     "Comparada com o momento do envio (agora).")
  observacao_do_atraso = ifelse(atraso_em_dias > 7 & atraso_em_dias <= 30, paste0(
    "Atraso de ", floor(atraso_em_dias), " dias: a SEFAZ autoriza fora de prazo (cStat 150)."
  ), NA_character_)
  saida_antes_do_prazo = notas$saida < notas$recebimento - 30 * SEGUNDOS_POR_DIA
  # A B10-40 compara as datas, sem a hora (a redação é do dSaiEnt, só a data): há NF-e autorizada com a saída minutos
  # antes da emissão, no mesmo dia.
  data_da_saida = as.Date(substr(notas$saida_texto, 1, 10))
  confere_a_saida_antiga = ifelse(saida_antes_do_prazo & em_contingencia, NA, !saida_antes_do_prazo)

  chaves_com_cfop_da_devolucao_antiga = itens$chave[itens$cfop %in% CFOP_FORA_DA_DEVOLUCAO_ANTIGA]
  chaves_com_documento_da_devolucao = referencias$chave[referencias$tipo %in% REFERENCIAS_DA_DEVOLUCAO_ANTIGA]
  chaves_com_nfe_ou_nf = referencias$chave[referencias$tipo %in% c("refNFe", "refNF")]
  chaves_com_cfop_sem_intermediador = itens$chave[itens$cfop %in% CFOP_SEM_INTERMEDIADOR]
  processo = notas$processo_emissao
  em_santa_catarina = notas$uf_codigo %in% "42"

  juntar_linhas(list(
    linhas_da_regra("A03-10", notas, aplica = !is.na(notas$id) & tem_todas_as_partes,
                    confere = chave_montada == id_sem_prefixo, campo = "infNFe/@Id", no_documento = id_sem_prefixo,
                    esperado = chave_montada, itens_da_regra = SEM_ITEM),
    linhas_da_regra("B23-10", notas, aplica = tem_todas_as_partes,
                    confere = (digito_calculado == numero_ou_na(notas$digito)) %in% TRUE,
                    campo = "ide/cDV", no_documento = notas$digito, esperado = as.character(digito_calculado),
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B03-10", notas, aplica = !is.na(notas$codigo_numerico),
                    confere = !(notas$codigo_numerico %in% CODIGOS_NUMERICOS_PROIBIDOS) &
                      !((notas$codigo_numerico == notas$numero) %in% TRUE),
                    campo = "ide/cNF", no_documento = notas$codigo_numerico,
                    esperado = "c\u00f3digo que n\u00e3o seja sequ\u00eancia nem o n\u00famero da nota",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B07-10", notas, aplica = na_faixa(numero_da_serie, 970, 989), confere = FALSE, campo = "ide/serie",
                    no_documento = notas$serie, esperado = "s\u00e9rie fora da faixa do PAA (970 a 989)",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B09-10", notas, aplica = !is.na(notas$emissao), confere = notas$emissao <= emissao_ate,
                    campo = "ide/dhEmi", no_documento = texto_do_instante(notas$emissao),
                    esperado = paste("at\u00e9", texto_do_instante(emissao_ate)), observacao = observacao_do_recebimento,
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B09-20", notas, aplica = !is.na(notas$emissao),
                    confere = ifelse(atraso_em_dias > 30 & !em_contingencia, NA, TRUE),
                    campo = "ide/dhEmi", no_documento = paste(texto_do_numero(atraso_em_dias, 1), "dias de atraso"),
                    esperado = "at\u00e9 30 dias (fora da conting\u00eancia)", observacao = observacao_do_atraso,
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B09-40", notas, aplica = notas$simplificada & notas$tipo_emissao %in% c("1", "6", "7") &
                      !is.na(notas$emissao),
                    confere = notas$emissao >= notas$recebimento - TOLERANCIA_DO_RELOGIO, campo = "ide/dhEmi",
                    no_documento = texto_do_instante(notas$emissao),
                    esperado = paste("a partir de", texto_do_instante(notas$recebimento - TOLERANCIA_DO_RELOGIO)),
                    observacao = observacao_do_recebimento, itens_da_regra = SEM_ITEM),
    linhas_da_regra("B10-10", notas, aplica = notas$simplificada, confere = is.na(notas$saida_texto), campo = "ide/dhSaiEnt",
                    no_documento = texto_da_presenca(!is.na(notas$saida_texto)), esperado = "n\u00e3o informado",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B10-20", notas, aplica = !is.na(notas$saida),
                    confere = notas$saida <= notas$recebimento + 30 * SEGUNDOS_POR_DIA, campo = "ide/dhSaiEnt",
                    no_documento = texto_do_instante(notas$saida),
                    esperado = paste("at\u00e9", texto_do_instante(notas$recebimento + 30 * SEGUNDOS_POR_DIA)),
                    observacao = observacao_do_recebimento, itens_da_regra = SEM_ITEM),
    linhas_da_regra("B10-30", notas, aplica = !is.na(notas$saida), confere = confere_a_saida_antiga, campo = "ide/dhSaiEnt",
                    no_documento = texto_do_instante(notas$saida),
                    esperado = paste("a partir de", texto_do_instante(notas$recebimento - 30 * SEGUNDOS_POR_DIA)),
                    observacao = ifelse(is.na(confere_a_saida_antiga), paste(
                      "Na SEFAZ que aceita a NF-e em conting\u00eancia com mais de 30 dias, a regra vale s\u00f3 para o",
                      "tpEmis 1, 3, 6 e 7."
                    ), observacao_do_recebimento), itens_da_regra = SEM_ITEM),
    linhas_da_regra("B10-40", notas, aplica = notas$tipo_operacao %in% "1" & !is.na(data_da_saida) & !is.na(notas$data_emissao),
                    confere = data_da_saida >= notas$data_emissao, campo = "ide/dhSaiEnt",
                    no_documento = format(data_da_saida, "%d/%m/%Y"),
                    esperado = paste("a partir de", format(notas$data_emissao, "%d/%m/%Y")), itens_da_regra = SEM_ITEM),
    linhas_da_regra("B11-10", notas, aplica = notas$simplificada, confere = !(notas$tipo_operacao %in% "0"),
                    campo = "ide/tpNF", no_documento = texto_ou_vazio(notas$tipo_operacao), esperado = "1 (sa\u00edda)",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B11a-10", notas, aplica = notas$simplificada, confere = notas$destino_operacao %in% "1",
                    campo = "ide/idDest", no_documento = texto_ou_vazio(notas$destino_operacao),
                    esperado = "1 (opera\u00e7\u00e3o interna)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B12-10", notas, aplica = !is.na(notas$municipio_fato_gerador),
                    confere = municipio_existe(notas$municipio_fato_gerador), campo = "ide/cMunFG",
                    no_documento = notas$municipio_fato_gerador, esperado = "munic\u00edpio da tabela do IBGE",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B12-20", notas, aplica = !is.na(notas$municipio_fato_gerador),
                    confere = (substr(notas$municipio_fato_gerador, 1, 2) == notas$uf_codigo) %in% TRUE,
                    campo = "ide/cMunFG", no_documento = notas$municipio_fato_gerador,
                    esperado = paste("come\u00e7ando por", texto_ou_vazio(notas$uf_codigo)), itens_da_regra = SEM_ITEM),
    linhas_da_regra("B21-10", notas, aplica = TRUE, confere = notas$tipo_impressao %in% c("4", "5"), campo = "ide/tpImp",
                    no_documento = texto_ou_vazio(notas$tipo_impressao), esperado = "4 ou 5", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B21-20", notas, aplica = TRUE, confere = !(notas$tipo_impressao %in% c("4", "5")), campo = "ide/tpImp",
                    no_documento = texto_ou_vazio(notas$tipo_impressao), esperado = "diferente de 4 e 5",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B22-10", notas, aplica = notas$tipo_emissao %in% "9", confere = notas$tipo_impressao %in% "6",
                    campo = "ide/tpImp", no_documento = texto_ou_vazio(notas$tipo_impressao),
                    esperado = "6 (DANFE Simplificado Tipo 2)", itens_da_regra = SEM_ITEM),
    # A NFC-e não usa o FS-DA (2) nem o FS-IA (5); a EPEC (4) a UF pode aceitar.
    linhas_da_regra("B22-34", notas, aplica = !is.na(notas$tipo_emissao),
                    confere = ifelse(notas$tipo_emissao %in% c("2", "5"), FALSE, ifelse(notas$tipo_emissao %in% "4", NA, TRUE)),
                    campo = "ide/tpEmis", no_documento = notas$tipo_emissao, esperado = "diferente de 2, 4 e 5",
                    observacao = ifelse(notas$tipo_emissao %in% "4", "A conting\u00eancia EPEC (tpEmis 4) pode ser aceita, a crit\u00e9rio da UF.", NA),
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B25-20", notas, aplica = notas$simplificada, confere = notas$finalidade %in% "1", campo = "ide/finNFe",
                    no_documento = texto_ou_vazio(notas$finalidade), esperado = "1 (normal)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B25-70", notas, aplica = notas$finalidade %in% "4" & !notas$tem_reforma &
                      !(notas$chave %in% chaves_com_cfop_da_devolucao_antiga),
                    confere = notas$chave %in% chaves_com_documento_da_devolucao, campo = "ide/NFref",
                    no_documento = texto_da_presenca(notas$chave %in% chaves_com_documento_da_devolucao),
                    esperado = "documento referenciado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B25a-10", notas, aplica = notas$simplificada, confere = !(notas$consumidor_final %in% "0"),
                    campo = "ide/indFinal", no_documento = texto_ou_vazio(notas$consumidor_final),
                    esperado = "1 (consumidor final)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B25b-10", notas, aplica = !(notas$tipo_impressao %in% "6"), confere = !(notas$presenca %in% "4"),
                    campo = "ide/indPres", no_documento = texto_ou_vazio(notas$presenca), esperado = "diferente de 4",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B25b-20", notas, aplica = notas$simplificada, confere = notas$presenca %in% c("1", "4", "5"),
                    campo = "ide/indPres", no_documento = texto_ou_vazio(notas$presenca), esperado = "1, 4 ou 5",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B25b-40", notas, aplica = !(notas$tipo_impressao %in% "6") & notas$presenca %in% "5",
                    confere = notas$chave %in% chaves_com_nfe_ou_nf, campo = "ide/NFref",
                    no_documento = texto_da_presenca(notas$chave %in% chaves_com_nfe_ou_nf),
                    esperado = "refNFe ou refNF informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B25c-10", notas, aplica = notas$presenca %in% c("2", "3", "4", "9") & notas$tipo_operacao %in% "1" &
                      notas$finalidade %in% "1" & !(notas$chave %in% chaves_com_cfop_sem_intermediador),
                    confere = !is.na(notas$intermediador), campo = "ide/indIntermed",
                    no_documento = texto_ou_vazio(notas$intermediador), esperado = "informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B25c-20", notas, aplica = !is.na(notas$presenca) & !(notas$presenca %in% c("1", "2", "3", "4", "9")),
                    confere = !(notas$intermediador %in% "1"), campo = "ide/indIntermed",
                    no_documento = texto_ou_vazio(notas$intermediador), esperado = "diferente de 1",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B26-10", notas, aplica = processo %in% c("0", "3"),
                    confere = na_faixa(numero_da_serie, 0, 889) | na_faixa(numero_da_serie, 920, 969), campo = "ide/serie",
                    no_documento = notas$serie, esperado = "0 a 889 ou 920 a 969", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B26-20", notas, aplica = processo %in% c("1", "2"), confere = na_faixa(numero_da_serie, 890, 919),
                    campo = "ide/serie", no_documento = notas$serie, esperado = "890 a 919", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B26-24", notas, aplica = processo %in% "4", confere = na_faixa(numero_da_serie, 970, 989),
                    campo = "ide/serie", no_documento = notas$serie, esperado = "970 a 989", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B26-26", notas, aplica = processo %in% "4", confere = notas$tem_paa, campo = "infPAA",
                    no_documento = texto_da_presenca(notas$tem_paa), esperado = "informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B26-28", notas, aplica = !is.na(processo) & !(processo %in% "4"), confere = !notas$tem_paa,
                    campo = "infPAA", no_documento = texto_da_presenca(notas$tem_paa), esperado = "n\u00e3o informado",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("B26-30", notas, aplica = processo %in% c("1", "2"),
                    confere = notas$tipo_emissao %in% c("1", "6", "7") | (em_santa_catarina & notas$tipo_emissao %in% "9"),
                    campo = "ide/tpEmis", no_documento = texto_ou_vazio(notas$tipo_emissao),
                    esperado = "1, 6 ou 7 (em SC, tamb\u00e9m 9)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B26-50", notas, aplica = !(notas$tipo_emissao %in% "3") &
                      !(em_santa_catarina & processo %in% c("1", "2")),
                    confere = processo %in% "0", campo = "ide/procEmi", no_documento = texto_ou_vazio(processo),
                    esperado = "0 (aplicativo do contribuinte)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B28-10", notas, aplica = notas$tipo_emissao %in% "1",
                    confere = is.na(notas$contingencia_texto) & is.na(notas$justificativa), campo = "ide/dhCont e ide/xJust",
                    no_documento = texto_da_presenca(!is.na(notas$contingencia_texto) | !is.na(notas$justificativa)),
                    esperado = "n\u00e3o informados", itens_da_regra = SEM_ITEM),
    linhas_da_regra("B28-20", notas, aplica = em_contingencia,
                    confere = informado(notas$contingencia_texto) & informado(notas$justificativa),
                    campo = "ide/dhCont e ide/xJust",
                    no_documento = texto_da_presenca(informado(notas$contingencia_texto) & informado(notas$justificativa)),
                    esperado = "informados", itens_da_regra = SEM_ITEM)
  ))
}

# Os documentos referenciados (grupo BA): a chave de cada NF-e e CT-e referenciado e os documentos que não podem mais
# ser referenciados.
conferir_os_documentos_referenciados = function(notas, referencias) {
  da_nota = match(referencias$chave, notas$chave)
  chave_referenciada = referencias$chave_referenciada
  e_nfe = referencias$tipo %in% "refNFe"
  e_cte = referencias$tipo %in% "refCTe"
  formato_certo = !is.na(chave_referenciada) & grepl(FORMATO_DA_CHAVE, chave_referenciada)
  digito_calculado = chave_digito(chave_referenciada)
  ano = numero_ou_na(substr(chave_referenciada, 3, 4))
  ano_corrente = as.integer(format(notas$recebimento[da_nota], "%y", tz = "America/Sao_Paulo"))
  mes = numero_ou_na(substr(chave_referenciada, 5, 6))
  documento = substr(chave_referenciada, 7, 20)
  modelo = substr(chave_referenciada, 21, 22)
  serie = numero_ou_na(substr(chave_referenciada, 23, 25))
  numero = substr(chave_referenciada, 26, 34)
  forma_emissao = substr(chave_referenciada, 35, 35)
  # BA02-30: a série diz se a chave traz um CNPJ ou um CPF; na NFF (tpEmis 3), o 5º dígito do número (1, CNPJ; 2, CPF).
  quinto_digito_do_numero = substr(chave_referenciada, 30, 30)
  traz_cnpj = ifelse(forma_emissao %in% "3", quinto_digito_do_numero %in% "1",
                     na_faixa(serie, 0, 909) | na_faixa(serie, 980, 989))
  sabe_o_tipo = !(forma_emissao %in% "3") | quinto_digito_do_numero %in% c("1", "2")
  documento_certo = ifelse(traz_cnpj, cnpj_confere(documento),
                           startsWith(documento, "000") & cpf_confere(substr(documento, 4, 14)))
  repetida = duplicated(paste(referencias$chave, referencias$tipo, chave_referenciada))
  ordem = ordem_na_nota(referencias$chave)
  campo = paste0("NFref[", ordem, "]/", referencias$tipo)
  saida_que_nao_complementa = notas$tipo_operacao[da_nota] %in% "1" & !(notas$finalidade[da_nota] %in% c("2", "4"))
  texto_do_documento = ifelse(is.na(chave_referenciada), "informado", chave_referenciada)

  juntar_linhas(list(
    linhas_da_regra("BA01-10", notas, aplica = notas$simplificada, confere = !notas$tem_referencia, campo = "ide/NFref",
                    no_documento = texto_da_presenca(notas$tem_referencia), esperado = "n\u00e3o informado",
                    itens_da_regra = SEM_ITEM),
    linhas_da_chave_referenciada("BA02-10", referencias, e_nfe & formato_certo,
                                 (digito_calculado == numero_ou_na(substr(chave_referenciada, 44, 44))) %in% TRUE, campo,
                                 paste("d\u00edgito", digito_calculado)),
    linhas_da_chave_referenciada("BA02-14", referencias, e_nfe & formato_certo,
                                 substr(chave_referenciada, 1, 2) %in% names(UF_PELO_CODIGO), campo, "c\u00f3digo de UF do IBGE"),
    linhas_da_chave_referenciada("BA02-20", referencias, e_nfe & formato_certo, na_faixa(ano, 6, ano_corrente), campo,
                                 "ano de 06 at\u00e9 o ano corrente"),
    linhas_da_chave_referenciada("BA02-24", referencias, e_nfe & formato_certo, na_faixa(mes, 1, 12), campo, "m\u00eas de 01 a 12"),
    linhas_da_chave_referenciada("BA02-30", referencias, e_nfe & formato_certo & modelo %in% c("55", "65") & sabe_o_tipo,
                                 documento_certo, campo,
                                 ifelse(traz_cnpj, "CNPJ com o d\u00edgito certo", "CPF com o d\u00edgito certo")),
    linhas_da_chave_referenciada("BA02-34", referencias, e_nfe & formato_certo, modelo %in% c("55", "65", "59"), campo,
                                 "modelo 55, 65 ou 59"),
    linhas_da_chave_referenciada("BA02-35", referencias, e_nfe & formato_certo & saida_que_nao_complementa,
                                 !(modelo %in% c("65", "59")), campo, "modelo diferente de 65 e 59"),
    linhas_da_chave_referenciada("BA02-40", referencias, e_nfe & formato_certo & modelo %in% c("55", "65"),
                                 numero != "000000000", campo,
                                 "n\u00famero diferente de zero"),
    linhas_da_chave_referenciada("BA02-44", referencias, e_nfe, !repetida, campo, "chave sem repetir"),
    linhas_da_chave_referenciada("BA02-50", referencias, e_nfe, !((chave_referenciada == referencias$chave) %in% TRUE),
                                 campo, "chave de outra nota"),
    linhas_da_regra("BA03-10", referencias, aplica = referencias$tipo %in% "refNF", confere = FALSE, campo = campo,
                    no_documento = texto_do_documento, esperado = "n\u00e3o informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("BA10-10", referencias, aplica = referencias$tipo %in% "refNFP", confere = FALSE, campo = campo,
                    no_documento = texto_do_documento, esperado = "n\u00e3o informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("BA20-30", referencias, aplica = referencias$tipo %in% "refECF", confere = FALSE, campo = campo,
                    no_documento = texto_do_documento, esperado = "n\u00e3o informado", itens_da_regra = SEM_ITEM),
    linhas_da_chave_referenciada("BA19-10", referencias, e_cte & formato_certo,
                                 (digito_calculado == numero_ou_na(substr(chave_referenciada, 44, 44))) %in% TRUE, campo,
                                 paste("d\u00edgito", digito_calculado)),
    linhas_da_chave_referenciada("BA19-14", referencias, e_cte & formato_certo,
                                 substr(chave_referenciada, 1, 2) %in% names(UF_PELO_CODIGO), campo, "c\u00f3digo de UF do IBGE"),
    linhas_da_chave_referenciada("BA19-20", referencias, e_cte & formato_certo, na_faixa(ano, 6, ano_corrente), campo,
                                 "ano de 06 at\u00e9 o ano corrente"),
    linhas_da_chave_referenciada("BA19-24", referencias, e_cte & formato_certo, na_faixa(mes, 1, 12), campo, "m\u00eas de 01 a 12"),
    linhas_da_chave_referenciada("BA19-30", referencias, e_cte & formato_certo, cnpj_confere(documento), campo,
                                 "CNPJ com o d\u00edgito certo"),
    linhas_da_chave_referenciada("BA19-34", referencias, e_cte & formato_certo, modelo %in% "57", campo, "modelo 57"),
    linhas_da_chave_referenciada("BA19-40", referencias, e_cte & formato_certo, numero != "000000000", campo,
                                 "n\u00famero diferente de zero"),
    linhas_da_chave_referenciada("BA19-44", referencias, e_cte, !repetida, campo, "chave sem repetir")
  ))
}

linhas_da_chave_referenciada = function(regra, referencias, aplica, confere, campo, esperado) {
  linhas_da_regra(regra, referencias, aplica = aplica, confere = confere, campo = campo,
                  no_documento = referencias$chave_referenciada, esperado = esperado, itens_da_regra = SEM_ITEM)
}

# O emitente (grupo C) e a NF-e avulsa (grupo D).
conferir_o_emitente = function(notas) {
  numero_da_serie = numero_ou_na(notas$serie)
  ie = notas$ie_emitente
  iest = notas$iest_emitente
  iest_igual_a_outra_ie = (iest == ie) %in% TRUE | (iest == notas$ie_destinatario) %in% TRUE
  confere_iest_na_operacao = ifelse(notas$destino_operacao %in% "1", NA, FALSE)
  processo_do_fisco = notas$processo_emissao %in% c("1", "2")

  juntar_linhas(list(
    linhas_do_cnpj("C02-10", notas, notas$cnpj_emitente, "emit/CNPJ"),
    linhas_da_regra("C02-30", notas, aplica = !is.na(notas$cnpj_emitente),
                    confere = na_faixa(numero_da_serie, 0, 909) | na_faixa(numero_da_serie, 980, 989), campo = "ide/serie",
                    no_documento = notas$serie, esperado = "0 a 909 ou 980 a 989", itens_da_regra = SEM_ITEM),
    linhas_da_regra("C02a-10", notas, aplica = !is.na(notas$cpf_emitente) & !(notas$tipo_emissao %in% "3"),
                    confere = na_faixa(numero_da_serie, 890, 899) | na_faixa(numero_da_serie, 910, 979), campo = "ide/serie",
                    no_documento = notas$serie, esperado = "890 a 899 ou 910 a 979", itens_da_regra = SEM_ITEM),
    linhas_do_cpf("C02a-20", notas, notas$cpf_emitente, "emit/CPF"),
    linhas_da_regra("C10-10", notas, aplica = !is.na(notas$municipio_emitente),
                    confere = municipio_existe(notas$municipio_emitente), campo = "emit/enderEmit/cMun",
                    no_documento = notas$municipio_emitente, esperado = "munic\u00edpio da tabela do IBGE",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("C10-20", notas, aplica = !is.na(notas$municipio_emitente),
                    confere = (substr(notas$municipio_emitente, 1, 2) == codigo_da_uf(notas$uf_emitente)) %in% TRUE,
                    campo = "emit/enderEmit/cMun", no_documento = notas$municipio_emitente,
                    esperado = paste("come\u00e7ando por", texto_ou_vazio(codigo_da_uf(notas$uf_emitente))),
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("C17-10", notas, aplica = TRUE, confere = informado(ie) & !grepl("^0+$", ie), campo = "emit/IE",
                    no_documento = texto_ou_vazio(ie), esperado = "informada, sem ser s\u00f3 zeros", itens_da_regra = SEM_ITEM),
    linhas_da_regra("C17-30", notas, aplica = ie %in% "ISENTO",
                    confere = notas$modelo %in% "55" & na_faixa(numero_da_serie, 890, 919), campo = "emit/IE",
                    no_documento = ie, esperado = "ISENTO s\u00f3 na NF-e avulsa (s\u00e9rie 890 a 919)",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("C17-42", notas, aplica = TRUE, confere = informado(ie), campo = "emit/IE",
                    no_documento = texto_ou_vazio(ie), esperado = "informada", itens_da_regra = SEM_ITEM),
    linhas_da_regra("C17-43", notas, aplica = !informado(ie), confere = !is.na(notas$cnpj_emitente), campo = "emit/CNPJ",
                    no_documento = texto_da_presenca(!is.na(notas$cnpj_emitente)), esperado = "informado",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("C18-10", notas, aplica = notas$simplificada, confere = is.na(iest), campo = "emit/IEST",
                    no_documento = texto_ou_vazio(iest), esperado = "n\u00e3o informada", itens_da_regra = SEM_ITEM),
    linhas_da_regra("C18-14", notas, aplica = !is.na(iest) & notas$destino_operacao %in% c("1", "3"),
                    confere = confere_iest_na_operacao, campo = "emit/IEST", no_documento = iest,
                    esperado = "s\u00f3 na opera\u00e7\u00e3o interestadual",
                    observacao = ifelse(is.na(confere_iest_na_operacao),
                                        "A crit\u00e9rio da UF, a IE do substituto pode ser aceita na opera\u00e7\u00e3o interna.",
                                        NA), itens_da_regra = SEM_ITEM),
    linhas_da_regra("C18-40", notas, aplica = !is.na(iest), confere = !iest_igual_a_outra_ie, campo = "emit/IEST",
                    no_documento = iest, esperado = "diferente da IE do emitente e da do destinat\u00e1rio",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("C18-50", notas, aplica = !informado(ie), confere = is.na(iest), campo = "emit/IEST",
                    no_documento = texto_ou_vazio(iest), esperado = "n\u00e3o informada", itens_da_regra = SEM_ITEM),
    linhas_da_regra("D01-10", notas, aplica = notas$tem_avulsa, confere = processo_do_fisco, campo = "avulsa",
                    no_documento = paste("procEmi", texto_ou_vazio(notas$processo_emissao)), esperado = "procEmi 1 ou 2",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("D01-20", notas, aplica = processo_do_fisco, confere = notas$tem_avulsa, campo = "avulsa",
                    no_documento = texto_da_presenca(notas$tem_avulsa), esperado = "informado", itens_da_regra = SEM_ITEM)
  ))
}

# O destinatário (grupo E). As exceções que dependem dos itens (o combustível consumido no exterior, os CFOP de
# exportação, a UF de consumo, o ICMS-ST) são da nota inteira: valem quando algum item as tem.
conferir_o_destinatario = function(notas, itens) {
  chaves_com_combustivel_no_exterior = itens$chave[itens$uf_consumo %in% "EX" & itens$cfop %in% "7667"]
  combustivel_no_exterior = notas$chave %in% chaves_com_combustivel_no_exterior
  com_cfop_7552_ou_7501 = notas$chave %in% itens$chave[itens$cfop %in% c("7552", "7501")]
  excecao_do_exterior = combustivel_no_exterior | com_cfop_7552_ou_7501
  uf_de_consumo_diferente = notas$chave %in% itens$chave[!is.na(itens$uf_consumo) & itens$uf_consumo != itens$uf_emitente]
  uf_de_consumo_igual = notas$chave %in% itens$chave[(itens$uf_consumo == itens$uf_emitente) %in% TRUE]
  com_st = notas$chave %in% itens$chave[(itens$valor_st > 0) %in% TRUE]
  com_st_retido = notas$chave %in% itens$chave[!is.na(itens$icms_st_retido)]
  isenta_ou_nao_tributada = notas$chave %in% itens$chave[itens$cst %in% c("40", "41") |
                                                           itens$csosn %in% c("103", "300", "400")]

  uf_destino = notas$uf_destinatario
  uf_emitente = notas$uf_emitente
  uf_entrega = notas$uf_entrega
  uf_retirada = notas$uf_retirada
  com_entrega = !is.na(uf_entrega)
  com_retirada = !is.na(uf_retirada)
  documentos_diferentes = (notas$documento_emitente != notas$documento_destinatario) %in% TRUE
  mesma_uf = (uf_destino == uf_emitente) %in% TRUE
  # As exceções das regras E12-30 a E12-60 (NT 2015.003): a retirada e a entrega mudam a UF da operação.
  excecao_da_saida_interestadual = uf_de_consumo_diferente | (com_entrega & !com_retirada & (uf_entrega != uf_emitente) %in% TRUE) |
    (com_retirada & !com_entrega & (uf_retirada != uf_destino) %in% TRUE) | (com_entrega & com_retirada & uf_entrega != uf_retirada)
  excecao_da_saida_interna = uf_de_consumo_igual | (com_entrega & !com_retirada & (uf_entrega == uf_emitente) %in% TRUE) |
    (com_retirada & !com_entrega & (uf_retirada == uf_destino) %in% TRUE) | (com_entrega & com_retirada & uf_entrega == uf_retirada)
  excecao_da_entrada_interestadual = uf_de_consumo_diferente | (com_entrega & !com_retirada & (uf_entrega != uf_destino) %in% TRUE) |
    (com_retirada & !com_entrega & (uf_retirada != uf_emitente) %in% TRUE) | (com_entrega & com_retirada & uf_entrega != uf_retirada)
  excecao_da_entrada_interna = uf_de_consumo_igual | (com_entrega & !com_retirada & (uf_entrega == uf_destino) %in% TRUE) |
    (com_retirada & !com_entrega & (uf_retirada == uf_emitente) %in% TRUE) | (com_entrega & com_retirada & uf_entrega == uf_retirada)
  nao_consumidor_final = !(notas$consumidor_final %in% "1")
  com_endereco_no_brasil = notas$tem_endereco_destinatario & !(uf_destino %in% "EX")
  indicador_ie = notas$indicador_ie_destinatario

  # E01-10, E04-10 e E05-10 na NF-e com DANFE Simplificado Tipo 2: a regra, como está escrita, vale; mas a NT 2026.002
  # trata essa NF-e como a NFC-e, que pode não ter o destinatário. O que não confere ali fica sem conferir.
  do_simplificado = notas$tipo_impressao %in% "6"
  confere_o_destinatario = ifelse(!notas$tem_destinatario & do_simplificado, NA, notas$tem_destinatario)
  confere_o_nome = ifelse(!informado(notas$nome_destinatario) & do_simplificado, NA, informado(notas$nome_destinatario))
  confere_o_endereco = ifelse(!notas$tem_endereco_destinatario & do_simplificado, NA, notas$tem_endereco_destinatario)

  juntar_linhas(list(
    linhas_da_regra("E01-10", notas, aplica = TRUE, confere = confere_o_destinatario, campo = "dest",
                    no_documento = texto_da_presenca(notas$tem_destinatario), esperado = "informado",
                    observacao = ifelse(is.na(confere_o_destinatario), OBSERVACAO_DO_SIMPLIFICADO, NA),
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E01-20", notas, aplica = notas$simplificada & notas$presenca %in% "4", confere = notas$tem_destinatario,
                    campo = "dest", no_documento = texto_da_presenca(notas$tem_destinatario), esperado = "informado",
                    itens_da_regra = SEM_ITEM),
    linhas_do_cnpj("E02-10", notas, notas$cnpj_destinatario, "dest/CNPJ"),
    linhas_da_regra("E02-20", notas, aplica = !is.na(notas$cnpj_destinatario),
                    confere = !((notas$cnpj_destinatario == notas$cnpj_emitente) %in% TRUE), campo = "dest/CNPJ",
                    no_documento = notas$cnpj_destinatario, esperado = "diferente do CNPJ do emitente",
                    itens_da_regra = SEM_ITEM),
    linhas_do_cpf("E03-10", notas, notas$cpf_destinatario, "dest/CPF"),
    linhas_da_regra("E03a-10", notas, aplica = notas$destino_operacao %in% "3" & !com_cfop_7552_ou_7501 &
                      !(!is.na(notas$cnpj_destinatario) & notas$pais_destinatario %in% PAIS_BRASIL & combustivel_no_exterior),
                    confere = notas$tem_estrangeiro, campo = "dest/idEstrangeiro",
                    no_documento = texto_da_presenca(notas$tem_estrangeiro), esperado = "informado",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E03a-20", notas, aplica = !(notas$destino_operacao %in% "3") & notas$tem_estrangeiro,
                    confere = !nao_consumidor_final, campo = "ide/indFinal",
                    no_documento = texto_ou_vazio(notas$consumidor_final), esperado = "1 (consumidor final)",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E03a-30", notas, aplica = notas$tem_estrangeiro, confere = is.na(notas$ie_destinatario),
                    campo = "dest/IE", no_documento = texto_ou_vazio(notas$ie_destinatario), esperado = "n\u00e3o informada",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E03a-60", notas, aplica = informado(notas$estrangeiro),
                    confere = grepl("^[\\p{L}0-9:.+ /()-]*$", notas$estrangeiro, perl = TRUE), campo = "dest/idEstrangeiro",
                    no_documento = notas$estrangeiro, esperado = "s\u00f3 letras, algarismos e :.+-/() ou espa\u00e7o",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E04-10", notas, aplica = notas$tem_destinatario, confere = confere_o_nome, campo = "dest/xNome",
                    no_documento = texto_da_presenca(informado(notas$nome_destinatario)), esperado = "informado",
                    observacao = ifelse(is.na(confere_o_nome), OBSERVACAO_DO_SIMPLIFICADO, NA), itens_da_regra = SEM_ITEM),
    # Na NFC-e o xNome é opcional: sem ele, não há o que comparar.
    linhas_da_regra("E04-20", notas, aplica = notas$ambiente %in% "2" & !(notas$tipo_emissao %in% "3") &
                      notas$tem_destinatario & (notas$modelo %in% "55" | informado(notas$nome_destinatario)),
                    confere = notas$nome_destinatario %in% LITERAL_DO_DESTINATARIO_EM_HOMOLOGACAO, campo = "dest/xNome",
                    no_documento = texto_ou_vazio(notas$nome_destinatario),
                    esperado = LITERAL_DO_DESTINATARIO_EM_HOMOLOGACAO, itens_da_regra = SEM_ITEM),
    linhas_da_regra("E05-10", notas, aplica = notas$tem_destinatario, confere = confere_o_endereco, campo = "dest/enderDest",
                    no_documento = texto_da_presenca(notas$tem_endereco_destinatario), esperado = "informado",
                    observacao = ifelse(is.na(confere_o_endereco), OBSERVACAO_DO_SIMPLIFICADO, NA),
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E05-20", notas, aplica = notas$presenca %in% "4", confere = notas$tem_endereco_destinatario,
                    campo = "dest/enderDest", no_documento = texto_da_presenca(notas$tem_endereco_destinatario),
                    esperado = "informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("E10-10", notas, aplica = com_endereco_no_brasil, confere = municipio_existe(notas$municipio_destinatario),
                    campo = "dest/enderDest/cMun", no_documento = texto_ou_vazio(notas$municipio_destinatario),
                    esperado = "munic\u00edpio da tabela do IBGE", itens_da_regra = SEM_ITEM),
    linhas_da_regra("E10-20", notas, aplica = com_endereco_no_brasil,
                    confere = (substr(notas$municipio_destinatario, 1, 2) == codigo_da_uf(uf_destino)) %in% TRUE,
                    campo = "dest/enderDest/cMun", no_documento = texto_ou_vazio(notas$municipio_destinatario),
                    esperado = paste("come\u00e7ando por", texto_ou_vazio(codigo_da_uf(uf_destino))), itens_da_regra = SEM_ITEM),
    linhas_da_regra("E10-30", notas, aplica = uf_destino %in% "EX",
                    confere = notas$municipio_destinatario %in% MUNICIPIO_DO_EXTERIOR, campo = "dest/enderDest/cMun",
                    no_documento = texto_ou_vazio(notas$municipio_destinatario), esperado = MUNICIPIO_DO_EXTERIOR,
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E12-10", notas, aplica = notas$destino_operacao %in% "3" & !excecao_do_exterior,
                    confere = uf_destino %in% "EX", campo = "dest/enderDest/UF", no_documento = texto_ou_vazio(uf_destino),
                    esperado = "EX", itens_da_regra = SEM_ITEM),
    linhas_da_regra("E12-30", notas, aplica = notas$tipo_operacao %in% "1" & notas$destino_operacao %in% "2" &
                      notas$tem_endereco_destinatario,
                    confere = !(mesma_uf & documentos_diferentes) | excecao_da_saida_interestadual,
                    campo = "dest/enderDest/UF", no_documento = texto_ou_vazio(uf_destino),
                    esperado = paste("diferente de", texto_ou_vazio(uf_emitente)), itens_da_regra = SEM_ITEM),
    linhas_da_regra("E12-40", notas, aplica = notas$tipo_operacao %in% "1" & notas$destino_operacao %in% "1" &
                      nao_consumidor_final & notas$tem_endereco_destinatario,
                    confere = mesma_uf | excecao_da_saida_interna, campo = "dest/enderDest/UF",
                    no_documento = texto_ou_vazio(uf_destino), esperado = texto_ou_vazio(uf_emitente),
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E12-50", notas, aplica = notas$tipo_operacao %in% "0" & notas$destino_operacao %in% "2" &
                      notas$tem_endereco_destinatario,
                    confere = !(mesma_uf & documentos_diferentes) | excecao_da_entrada_interestadual,
                    campo = "dest/enderDest/UF", no_documento = texto_ou_vazio(uf_destino),
                    esperado = paste("diferente de", texto_ou_vazio(uf_emitente)), itens_da_regra = SEM_ITEM),
    linhas_da_regra("E12-60", notas, aplica = notas$tipo_operacao %in% "0" & notas$destino_operacao %in% "1" &
                      nao_consumidor_final & notas$tem_endereco_destinatario,
                    confere = mesma_uf | excecao_da_entrada_interna, campo = "dest/enderDest/UF",
                    no_documento = texto_ou_vazio(uf_destino), esperado = texto_ou_vazio(uf_emitente),
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E14-10", notas, aplica = notas$destino_operacao %in% "3" & !excecao_do_exterior,
                    confere = informado(notas$pais_destinatario) & !(notas$pais_destinatario %in% PAIS_BRASIL),
                    campo = "dest/enderDest/cPais", no_documento = texto_ou_vazio(notas$pais_destinatario),
                    esperado = "pa\u00eds diferente de 1058 (Brasil)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("E14-20", notas, aplica = !(notas$destino_operacao %in% "3") & informado(notas$pais_destinatario) &
                      !informado(notas$estrangeiro),
                    confere = notas$pais_destinatario %in% PAIS_BRASIL, campo = "dest/enderDest/cPais",
                    no_documento = notas$pais_destinatario, esperado = "1058 (Brasil)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("E14-30", notas, aplica = uf_destino %in% "EX", confere = !(notas$pais_destinatario %in% PAIS_BRASIL),
                    campo = "dest/enderDest/cPais", no_documento = texto_ou_vazio(notas$pais_destinatario),
                    esperado = "pa\u00eds diferente de 1058 (Brasil)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("E16a-10", notas, aplica = notas$tem_destinatario, confere = indicador_ie %in% "9",
                    campo = "dest/indIEDest", no_documento = texto_ou_vazio(indicador_ie),
                    esperado = "9 (n\u00e3o contribuinte)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("E16a-20", notas, aplica = notas$destino_operacao %in% "3" & !excecao_do_exterior & notas$tem_destinatario,
                    confere = indicador_ie %in% "9", campo = "dest/indIEDest", no_documento = texto_ou_vazio(indicador_ie),
                    esperado = "9 (n\u00e3o contribuinte)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("E16a-30", notas, aplica = indicador_ie %in% "2" & notas$destino_operacao %in% c("1", "2") &
                      uf_destino %in% UFS_SEM_ISENTO_DE_IE,
                    confere = ifelse(com_st | com_st_retido | isenta_ou_nao_tributada, TRUE,
                                     ifelse(notas$destino_operacao %in% "1", NA, FALSE)),
                    campo = "dest/indIEDest",
                    no_documento = paste0(indicador_ie, " (destinat\u00e1rio em ", uf_destino, ")"),
                    esperado = "1 ou 9, ou um item com ICMS-ST ou isento, imune ou n\u00e3o tributado",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E16a-40", notas, aplica = notas$tipo_operacao %in% "1" & !(notas$destino_operacao %in% "3") &
                      indicador_ie %in% "9",
                    confere = !nao_consumidor_final, campo = "ide/indFinal", no_documento = texto_ou_vazio(notas$consumidor_final),
                    esperado = "1 (consumidor final)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("E17-10", notas, aplica = notas$destino_operacao %in% "3", confere = is.na(notas$ie_destinatario),
                    campo = "dest/IE", no_documento = texto_ou_vazio(notas$ie_destinatario), esperado = "n\u00e3o informada",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E17-20", notas, aplica = indicador_ie %in% "1", confere = informado(notas$ie_destinatario),
                    campo = "dest/IE", no_documento = texto_ou_vazio(notas$ie_destinatario), esperado = "informada",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E17-30", notas, aplica = indicador_ie %in% "2", confere = is.na(notas$ie_destinatario),
                    campo = "dest/IE", no_documento = texto_ou_vazio(notas$ie_destinatario), esperado = "n\u00e3o informada",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E17-40", notas, aplica = informado(notas$ie_destinatario), confere = !(uf_destino %in% "EX"),
                    campo = "dest/IE", no_documento = notas$ie_destinatario, esperado = "s\u00f3 com o destinat\u00e1rio no Brasil",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("E18-10", notas, aplica = notas$tem_destinatario, confere = is.na(notas$suframa_destinatario),
                    campo = "dest/ISUF", no_documento = texto_ou_vazio(notas$suframa_destinatario),
                    esperado = "n\u00e3o informada", itens_da_regra = SEM_ITEM),
    linhas_da_regra("E18-20", notas, aplica = informado(notas$suframa_destinatario),
                    confere = inscricao_suframa_confere(notas$suframa_destinatario), campo = "dest/ISUF",
                    no_documento = notas$suframa_destinatario, esperado = "inscri\u00e7\u00e3o com o d\u00edgito certo",
                    itens_da_regra = SEM_ITEM)
  ))
}

# O local de retirada (grupo F) e o de entrega (grupo G).
conferir_a_retirada_e_a_entrega = function(notas) {
  juntar_linhas(list(
    linhas_da_regra("F01-10", notas, aplica = notas$simplificada, confere = !notas$tem_retirada, campo = "retirada",
                    no_documento = texto_da_presenca(notas$tem_retirada), esperado = "n\u00e3o informado",
                    itens_da_regra = SEM_ITEM),
    linhas_do_cnpj("F02-10", notas, notas$cnpj_retirada, "retirada/CNPJ"),
    linhas_do_cpf("F02a-10", notas, notas$cpf_retirada, "retirada/CPF"),
    linhas_do_municipio_do_local(c("F07-10", "F07-20", "F07-30"), notas, notas$tem_retirada, notas$uf_retirada,
                                 notas$municipio_retirada, "retirada/cMun"),
    linhas_do_cnpj("G02-10", notas, notas$cnpj_entrega, "entrega/CNPJ"),
    linhas_do_cpf("G02a-10", notas, notas$cpf_entrega, "entrega/CPF"),
    linhas_do_municipio_do_local(c("G07-10", "G07-20", "G07-30"), notas, notas$tem_entrega, notas$uf_entrega,
                                 notas$municipio_entrega, "entrega/cMun")
  ))
}

# As três regras do município de um local: 9999999 no exterior, município da tabela e a UF dele.
linhas_do_municipio_do_local = function(regras, notas, tem_o_local, ufs, municipios, campo) {
  no_exterior = tem_o_local & ufs %in% "EX"
  no_brasil = tem_o_local & !is.na(ufs) & !(ufs %in% "EX")
  juntar_linhas(list(
    linhas_da_regra(regras[1], notas, aplica = no_exterior, confere = municipios %in% MUNICIPIO_DO_EXTERIOR, campo = campo,
                    no_documento = texto_ou_vazio(municipios), esperado = MUNICIPIO_DO_EXTERIOR, itens_da_regra = SEM_ITEM),
    linhas_da_regra(regras[2], notas, aplica = no_brasil, confere = municipio_existe(municipios), campo = campo,
                    no_documento = texto_ou_vazio(municipios), esperado = "munic\u00edpio da tabela do IBGE",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra(regras[3], notas, aplica = no_brasil, confere = (substr(municipios, 1, 2) == codigo_da_uf(ufs)) %in% TRUE,
                    campo = campo, no_documento = texto_ou_vazio(municipios),
                    esperado = paste("come\u00e7ando por", texto_ou_vazio(codigo_da_uf(ufs))), itens_da_regra = SEM_ITEM)
  ))
}

# Os autorizados a baixar o XML (grupo GA).
conferir_os_autorizados = function(notas, autorizados) {
  da_nota = match(autorizados$chave, notas$chave)
  campo = paste0("autXML[", ordem_na_nota(autorizados$chave), "]")
  juntar_linhas(list(
    linhas_do_cnpj("GA02-10", autorizados, autorizados$cnpj, paste0(campo, "/CNPJ")),
    linhas_da_regra("GA02-20", autorizados, aplica = !is.na(autorizados$cnpj),
                    confere = !((autorizados$cnpj == notas$cnpj_destinatario[da_nota]) %in% TRUE),
                    campo = paste0(campo, "/CNPJ"), no_documento = autorizados$cnpj,
                    esperado = "diferente do CNPJ do destinat\u00e1rio", itens_da_regra = SEM_ITEM),
    linhas_do_cpf("GA03-10", autorizados, autorizados$cpf, paste0(campo, "/CPF")),
    linhas_da_regra("GA03-20", autorizados, aplica = !is.na(autorizados$cpf),
                    confere = !((autorizados$cpf == notas$cpf_destinatario[da_nota]) %in% TRUE),
                    campo = paste0(campo, "/CPF"), no_documento = autorizados$cpf,
                    esperado = "diferente do CPF do destinat\u00e1rio", itens_da_regra = SEM_ITEM)
  ))
}

# Se os números dos itens de uma nota são 1, 2, 3... nessa ordem.
itens_em_sequencia = function(numeros) {
  identical(as.integer(numeros), seq_along(numeros))
}

# Os números dos itens de uma nota, os 10 primeiros.
primeiros_numeros = function(numeros) {
  texto = paste(utils::head(numeros, 10), collapse = ", ")
  if (length(numeros) > 10) {
    texto = paste0(texto, "...")
  }
  texto
}

# O produto de cada item (grupo I e o H02-10): GTIN, NCM, CFOP, as contas do valor e o desconto.
conferir_os_produtos = function(notas, itens, referencias, exportacoes) {
  numeros_de_cada_nota = split(itens$item, factor(itens$chave, levels = notas$chave))
  em_sequencia = vapply(numeros_de_cada_nota, itens_em_sequencia, logical(1), USE.NAMES = FALSE)
  texto_dos_numeros = vapply(numeros_de_cada_nota, primeiros_numeros, character(1), USE.NAMES = FALSE)
  tem_itens = lengths(numeros_de_cada_nota) > 0

  ean = itens$codigo_ean
  ean_tributavel = itens$ean_tributavel
  ean_especifico = informado(ean) & ean != "SEM GTIN"
  ean_tributavel_especifico = informado(ean_tributavel) & ean_tributavel != "SEM GTIN"
  fora_do_mei = !(itens$regime_tributario %in% "4")
  primeiro_item = !duplicated(itens$chave)
  cfop = itens$cfop
  primeiro_digito_do_cfop = substr(cfop, 1, 1)

  # I05-20: o NCM tem de existir na data; o que não está na tabela de hoje, numa nota de antes dela, fica sem conferir,
  # e na NF-e de exportação vale também o código especial do Registro de Exportação, que a tabela não tem.
  ncm_de_oito = grepl("^[0-9]{8}$", itens$ncm) & !(itens$ncm %in% "00000000")
  tabela_do_ncm = tabela_fiscal("ncm")
  ncm_existe_hoje = itens$ncm %in% tabela_do_ncm$codigo
  ncm_existe_na_data = !is.na(descricao_na_data("ncm", itens$ncm, itens$data_emissao))
  nota_de_antes_da_tabela_do_ncm = (itens$data_emissao < data_da_tabela("ncm")) %in% TRUE
  # A tabela começa na versão da nomenclatura de 01/04/2022: a nota de antes dela fica sem conferir.
  nota_de_antes_do_comeco_da_tabela = (itens$data_emissao < min(tabela_do_ncm$inicio, na.rm = TRUE)) %in% TRUE
  ncm_sem_conferir = !ncm_existe_na_data & ((!ncm_existe_hoje & nota_de_antes_da_tabela_do_ncm) |
                                              nota_de_antes_do_comeco_da_tabela |
                                              (itens$modelo %in% "55" & primeiro_digito_do_cfop %in% "7"))
  confere_o_ncm = ifelse(ncm_sem_conferir, NA, ncm_existe_na_data)
  observacao_do_ncm = ifelse(ncm_sem_conferir & nota_de_antes_do_comeco_da_tabela, paste(
    "A tabela de NCM do pacote come\u00e7a em", format(min(tabela_do_ncm$inicio, na.rm = TRUE), "%d/%m/%Y"),
    "e a nota \u00e9 de antes."
  ), ifelse(ncm_sem_conferir & !ncm_existe_hoje & nota_de_antes_da_tabela_do_ncm, OBSERVACAO_DA_TABELA_DE_HOJE, NA))

  # I08-04: o CFOP tem de estar na tabela da NF-e, permitido na NF-e, na data.
  tabela_do_cfop = tabela_fiscal("cfop")
  linha_do_cfop = match(cfop, tabela_do_cfop$codigo)
  cfop_valia = (is.na(tabela_do_cfop$inicio[linha_do_cfop]) | (tabela_do_cfop$inicio[linha_do_cfop] <= itens$data_emissao) %in% TRUE) &
    (is.na(tabela_do_cfop$fim[linha_do_cfop]) | (tabela_do_cfop$fim[linha_do_cfop] >= itens$data_emissao) %in% TRUE)
  cfop_permitido = !is.na(linha_do_cfop) & tabela_do_cfop$permitido_na_nfe[linha_do_cfop] %in% 1 & cfop_valia
  cfop_sem_conferir = is.na(linha_do_cfop) & (itens$data_emissao < data_da_tabela("cfop")) %in% TRUE
  confere_o_cfop = ifelse(cfop_sem_conferir, NA, cfop_permitido)

  # I08-150: o CFOP 5.949 que a UF pode aceitar na NFC-e (RS e ES com CSOSN 900 ou CST 90; SP e AM com CSOSN 900 ou CST 40).
  cfop_da_uf_na_nfce = cfop %in% "5949" &
    ((itens$uf_emitente %in% c("RS", "ES") & (itens$csosn %in% "900" | itens$cst %in% "90")) |
       (itens$uf_emitente %in% c("SP", "AM") & (itens$csosn %in% "900" | itens$cst %in% "40")))
  confere_o_cfop_da_nfce = ifelse(cfop %in% CFOP_DA_NFCE, TRUE, ifelse(cfop_da_uf_na_nfce, NA, FALSE))

  chaves_com_nfce_referenciada = referencias$chave[referencias$tipo %in% "refNFe" &
                                                     substr(referencias$chave_referenciada, 21, 22) %in% "65"]
  tabela_dos_cfop_exclusivos = tabela_do_cfop$codigo[tabela_do_cfop$exclusivo_ibs_cbs %in% 1]
  produto_comercial = arredondar_no_centavo(itens$quantidade * itens$valor_unitario)
  produto_tributavel = arredondar_no_centavo(itens$quantidade_tributavel * itens$valor_unitario_tributavel)
  normal = itens$finalidade %in% "1"

  exportacao_formato_certo = !is.na(exportacoes$chave_exportacao) & grepl(FORMATO_DA_CHAVE, exportacoes$chave_exportacao)
  digito_da_exportacao = chave_digito(exportacoes$chave_exportacao)

  juntar_linhas(list(
    linhas_da_regra("H02-10", notas, aplica = tem_itens, confere = em_sequencia, campo = "det/@nItem",
                    no_documento = texto_dos_numeros, esperado = "1, 2, 3... em ordem", itens_da_regra = SEM_ITEM),
    linhas_da_regra("I03-10", itens, aplica = ean_especifico, confere = gtin_confere(ean), campo = "prod/cEAN",
                    no_documento = ean, esperado = "GTIN com o d\u00edgito certo"),
    linhas_da_regra("I03-30", itens, aplica = fora_do_mei, confere = informado(ean), campo = "prod/cEAN",
                    no_documento = texto_ou_vazio(ean), esperado = "GTIN ou SEM GTIN"),
    linhas_da_regra("I04-10", itens, aplica = itens$simplificada & itens$ambiente %in% "2" & primeiro_item,
                    confere = itens$descricao %in% LITERAL_DO_ITEM_EM_HOMOLOGACAO, campo = "prod/xProd",
                    no_documento = texto_ou_vazio(itens$descricao), esperado = LITERAL_DO_ITEM_EM_HOMOLOGACAO),
    linhas_da_regra("I05-10", itens, aplica = TRUE, confere = grepl("^[0-9]{8}$", itens$ncm) | itens$ncm %in% "00",
                    campo = "prod/NCM", no_documento = texto_ou_vazio(itens$ncm), esperado = "8 posi\u00e7\u00f5es (ou 00)"),
    linhas_da_regra("I05-20", itens, aplica = ncm_de_oito, confere = confere_o_ncm, campo = "prod/NCM",
                    no_documento = itens$ncm, esperado = "NCM da tabela na data da nota", observacao = observacao_do_ncm),
    linhas_da_regra("I08-04", itens, aplica = !is.na(cfop), confere = confere_o_cfop, campo = "prod/CFOP",
                    no_documento = cfop, esperado = "CFOP da tabela, permitido na NF-e",
                    observacao = ifelse(cfop_sem_conferir, OBSERVACAO_DA_TABELA_DE_HOJE, NA)),
    linhas_da_regra("I08-10", itens, aplica = itens$tipo_operacao %in% "1" & !is.na(cfop),
                    confere = !(primeiro_digito_do_cfop %in% c("1", "2", "3")), campo = "prod/CFOP", no_documento = cfop,
                    esperado = "CFOP de sa\u00edda (5, 6 ou 7)"),
    linhas_da_regra("I08-20", itens, aplica = itens$tipo_operacao %in% "0" & !is.na(cfop),
                    confere = !(primeiro_digito_do_cfop %in% c("5", "6", "7")), campo = "prod/CFOP", no_documento = cfop,
                    esperado = "CFOP de entrada (1, 2 ou 3)"),
    linhas_da_regra("I08-30", itens, aplica = primeiro_digito_do_cfop %in% c("3", "7"),
                    confere = itens$destino_operacao %in% "3" | (itens$uf_consumo %in% "EX" & primeiro_digito_do_cfop %in% "7"),
                    campo = "ide/idDest", no_documento = texto_ou_vazio(itens$destino_operacao),
                    esperado = "3 (opera\u00e7\u00e3o com o exterior)"),
    linhas_da_regra("I08-40", itens, aplica = primeiro_digito_do_cfop %in% c("2", "6"),
                    confere = itens$destino_operacao %in% "2", campo = "ide/idDest",
                    no_documento = texto_ou_vazio(itens$destino_operacao), esperado = "2 (interestadual)"),
    linhas_da_regra("I08-50", itens, aplica = primeiro_digito_do_cfop %in% c("1", "5"),
                    confere = itens$destino_operacao %in% "1", campo = "ide/idDest",
                    no_documento = texto_ou_vazio(itens$destino_operacao), esperado = "1 (interna)"),
    linhas_da_regra("I08-60", itens, aplica = primeiro_digito_do_cfop %in% c("3", "7") & !is.na(itens$uf_destinatario),
                    confere = itens$uf_destinatario %in% "EX" | itens$uf_consumo %in% "EX", campo = "dest/enderDest/UF",
                    no_documento = itens$uf_destinatario, esperado = "EX"),
    linhas_da_regra("I08-150", itens, aplica = itens$simplificada, confere = confere_o_cfop_da_nfce, campo = "prod/CFOP",
                    no_documento = texto_ou_vazio(cfop), esperado = paste(CFOP_DA_NFCE, collapse = ", ")),
    linhas_da_regra("I08-160", itens, aplica = cfop %in% CFOP_DE_SERVICO, confere = itens$tem_issqn, campo = "imposto/ISSQN",
                    no_documento = texto_da_presenca(itens$tem_issqn), esperado = "informado"),
    linhas_da_regra("I08-170", itens, aplica = itens$tem_issqn, confere = cfop %in% CFOP_DE_SERVICO, campo = "prod/CFOP",
                    no_documento = texto_ou_vazio(cfop), esperado = paste(CFOP_DE_SERVICO, collapse = ", ")),
    linhas_da_regra("I08-180", itens, aplica = cfop %in% CFOP_DE_CUPOM_FISCAL,
                    confere = !(itens$chave %in% chaves_com_nfce_referenciada), campo = "ide/NFref",
                    no_documento = texto_da_presenca(itens$chave %in% chaves_com_nfce_referenciada),
                    esperado = "sem NFC-e referenciada"),
    linhas_da_regra("I08-191", itens, aplica = !informado(itens$ie_emitente) & !(itens$finalidade %in% "4") &
                      !(itens$tipo_nota_credito %in% "03"),
                    confere = cfop %in% tabela_dos_cfop_exclusivos, campo = "prod/CFOP", no_documento = texto_ou_vazio(cfop),
                    esperado = "CFOP permitido ao contribuinte s\u00f3 do IBS e da CBS"),
    linhas_da_regra("I11-10", itens, aplica = normal & !is.na(produto_comercial) & !is.na(itens$valor_produto),
                    confere = igual_com_tolerancia(itens$valor_produto, produto_comercial, TOLERANCIA_DOS_VALORES),
                    campo = "prod/vProd", no_documento = texto_do_numero(itens$valor_produto, 2),
                    esperado = texto_do_numero(produto_comercial, 2), diferenca = round(itens$valor_produto - produto_comercial, 2)),
    linhas_da_regra("I11-20", itens, aplica = normal & !is.na(produto_tributavel) & !is.na(itens$valor_produto),
                    confere = igual_com_tolerancia(itens$valor_produto, produto_tributavel, TOLERANCIA_DOS_VALORES),
                    campo = "prod/vProd", no_documento = texto_do_numero(itens$valor_produto, 2),
                    esperado = texto_do_numero(produto_tributavel, 2), diferenca = round(itens$valor_produto - produto_tributavel, 2)),
    linhas_da_regra("I12-10", itens, aplica = ean_tributavel_especifico, confere = gtin_confere(ean_tributavel),
                    campo = "prod/cEANTrib", no_documento = ean_tributavel, esperado = "GTIN com o d\u00edgito certo"),
    linhas_da_regra("I12-30", itens, aplica = ean_especifico, confere = ean_tributavel_especifico, campo = "prod/cEANTrib",
                    no_documento = texto_ou_vazio(ean_tributavel), esperado = "GTIN da unidade tribut\u00e1vel"),
    linhas_da_regra("I12-40", itens, aplica = ean_tributavel_especifico, confere = ean_especifico, campo = "prod/cEAN",
                    no_documento = texto_ou_vazio(ean), esperado = "GTIN do produto"),
    linhas_da_regra("I12-60", itens, aplica = fora_do_mei, confere = informado(ean_tributavel), campo = "prod/cEANTrib",
                    no_documento = texto_ou_vazio(ean_tributavel), esperado = "GTIN ou SEM GTIN"),
    linhas_da_regra("I17-10", itens, aplica = !is.na(itens$desconto), confere = (itens$desconto <= itens$valor_produto) %in% TRUE,
                    campo = "prod/vDesc", no_documento = texto_do_numero(itens$desconto, 2),
                    esperado = paste("at\u00e9", texto_do_numero(itens$valor_produto, 2))),
    linhas_da_regra("I17b-10", itens, aplica = itens$simplificada, confere = !(itens$entra_no_total %in% "0"),
                    campo = "prod/indTot", no_documento = texto_ou_vazio(itens$entra_no_total), esperado = "1"),
    linhas_da_regra("I50-10", itens, aplica = itens$tem_exportacao, confere = itens$destino_operacao %in% "3",
                    campo = "prod/detExport", no_documento = paste("idDest", texto_ou_vazio(itens$destino_operacao)),
                    esperado = "s\u00f3 na opera\u00e7\u00e3o com o exterior (idDest 3)"),
    linhas_da_regra("I54-10", exportacoes, aplica = exportacao_formato_certo,
                    confere = (digito_da_exportacao == numero_ou_na(substr(exportacoes$chave_exportacao, 44, 44))) %in% TRUE,
                    campo = "prod/detExport/exportInd/chNFe", no_documento = exportacoes$chave_exportacao,
                    esperado = paste("d\u00edgito", digito_da_exportacao)),
    linhas_da_regra("I54-20", exportacoes, aplica = exportacao_formato_certo,
                    confere = substr(exportacoes$chave_exportacao, 21, 22) %in% "55",
                    campo = "prod/detExport/exportInd/chNFe", no_documento = exportacoes$chave_exportacao,
                    esperado = "modelo 55")
  ))
}

# O ICMS de cada item (grupo N): o CST e o CSOSN pelo regime, os da NFC-e e os CFOP de cada um, a conta do valor e a
# desoneração.
conferir_o_icms_dos_itens = function(itens) {
  cst = itens$cst
  csosn = itens$csosn
  cfop = itens$cfop
  regime_simples = itens$regime_tributario %in% c("1", "4")
  simplificada = itens$simplificada
  uf = itens$uf_emitente
  # N12-40 e N12a-40: os CFOP que a UF pode aceitar com cada CST ou CSOSN na NFC-e.
  cfop_da_uf_com_cst = (cst %in% "90" & cfop %in% "5949" & uf %in% c("RS", "ES")) |
    (cst %in% "90" & cfop %in% c("5403", "5405") & uf %in% "CE") |
    (cst %in% "40" & cfop %in% "5949" & uf %in% c("SP", "AM"))
  cfop_da_uf_com_csosn = (csosn %in% "900" & cfop %in% "5949" & uf %in% c("RS", "ES", "SP", "AM")) |
    (csosn %in% "900" & cfop %in% c("5403", "5405") & uf %in% "CE")
  confere_o_cfop_do_cst = ifelse(cfop %in% CFOP_DA_VENDA_NA_NFCE, TRUE, ifelse(cfop_da_uf_com_cst, NA, FALSE))
  confere_o_cfop_do_csosn = ifelse(cfop %in% CFOP_DA_VENDA_NA_NFCE, TRUE, ifelse(cfop_da_uf_com_csosn, NA, FALSE))
  confere_o_cst_da_nfce = ifelse(cst %in% c("00", "20", "40", "41", "60", "61"), TRUE, ifelse(cst %in% "90", NA, FALSE))
  confere_o_csosn_da_nfce = ifelse(csosn %in% c("102", "103", "300", "400", "500"), TRUE, ifelse(csosn %in% "900", NA, FALSE))
  icms_calculado = arredondar_no_centavo(itens$base_icms * itens$aliquota_icms / 100)
  # O MEI fora da exportação, na NFC-e e na NF-e com DANFE Simplificado Tipo 2 (N12a-81 e N12a-91).
  mei_na_nfce = itens$regime_tributario %in% "4" & !(itens$destino_operacao %in% "3") & simplificada
  texto_da_origem_e_da_aliquota = paste0("pICMSInter ", texto_do_numero(itens$aliquota_interestadual, 2), ", orig ",
                                         texto_ou_vazio(itens$origem))
  sem_ie = !informado(itens$ie_emitente) & !(itens$finalidade %in% "4") & !(itens$tipo_nota_credito %in% "03")

  juntar_linhas(list(
    linhas_da_regra("N01-10", itens, aplica = sem_ie, confere = !itens$tem_icms & !itens$tem_icms_uf_destino,
                    campo = "imposto/ICMS", no_documento = texto_da_presenca(itens$tem_icms | itens$tem_icms_uf_destino),
                    esperado = "n\u00e3o informado"),
    linhas_da_regra("N12-20", itens, aplica = regime_simples & !is.na(cst), confere = cst %in% c("02", "15", "53", "61"),
                    campo = "imposto/ICMS/CST", no_documento = cst, esperado = "CSOSN (ou CST monof\u00e1sico 02, 15, 53 ou 61)"),
    linhas_da_regra("N12a-10", itens, aplica = !is.na(csosn), confere = regime_simples, campo = "imposto/ICMS/CSOSN",
                    no_documento = paste("CRT", texto_ou_vazio(itens$regime_tributario)), esperado = "CRT 1 ou 4"),
    linhas_da_regra("N12-30", itens, aplica = simplificada & !is.na(cst), confere = confere_o_cst_da_nfce,
                    campo = "imposto/ICMS/CST", no_documento = cst, esperado = "00, 20, 40, 41, 60 ou 61",
                    observacao = ifelse(is.na(confere_o_cst_da_nfce), "A crit\u00e9rio da UF, o CST 90 pode ser aceito.", NA)),
    linhas_da_regra("N12-34", itens, aplica = simplificada & cst %in% "90", confere = is.na(itens$modalidade_base_st),
                    campo = "imposto/ICMS/ICMS90/modBCST", no_documento = texto_da_presenca(!is.na(itens$modalidade_base_st)),
                    esperado = "n\u00e3o informado"),
    linhas_da_regra("N12-40", itens, aplica = simplificada & cst %in% c("00", "20", "40", "41", "90"),
                    confere = confere_o_cfop_do_cst, campo = "prod/CFOP", no_documento = texto_ou_vazio(cfop),
                    esperado = paste(CFOP_DA_VENDA_NA_NFCE, collapse = ", ")),
    linhas_da_regra("N12-44", itens, aplica = simplificada & cst %in% "60", confere = cfop %in% CFOP_DO_ICMS_COBRADO_ANTES_NA_NFCE,
                    campo = "prod/CFOP", no_documento = texto_ou_vazio(cfop),
                    esperado = paste(CFOP_DO_ICMS_COBRADO_ANTES_NA_NFCE, collapse = ", ")),
    linhas_da_regra("N12-50", itens, aplica = simplificada, confere = !itens$tem_icms_partilha, campo = "imposto/ICMS/ICMSPart",
                    no_documento = texto_da_presenca(itens$tem_icms_partilha), esperado = "n\u00e3o informado"),
    linhas_da_regra("N12-60", itens, aplica = simplificada, confere = !itens$tem_icms_repasse, campo = "imposto/ICMS/ICMSST",
                    no_documento = texto_da_presenca(itens$tem_icms_repasse), esperado = "n\u00e3o informado"),
    linhas_da_regra("N12a-20", itens, aplica = simplificada & !is.na(csosn), confere = confere_o_csosn_da_nfce,
                    campo = "imposto/ICMS/CSOSN", no_documento = csosn, esperado = "102, 103, 300, 400 ou 500",
                    observacao = ifelse(is.na(confere_o_csosn_da_nfce), "A crit\u00e9rio da UF, o CSOSN 900 pode ser aceito.", NA)),
    linhas_da_regra("N12a-34", itens, aplica = simplificada & csosn %in% "900", confere = is.na(itens$modalidade_base_st),
                    campo = "imposto/ICMS/ICMSSN900/modBCST", no_documento = texto_da_presenca(!is.na(itens$modalidade_base_st)),
                    esperado = "n\u00e3o informado"),
    linhas_da_regra("N12a-40", itens, aplica = simplificada & csosn %in% c("102", "103", "300", "400", "900"),
                    confere = confere_o_cfop_do_csosn, campo = "prod/CFOP", no_documento = texto_ou_vazio(cfop),
                    esperado = paste(CFOP_DA_VENDA_NA_NFCE, collapse = ", ")),
    linhas_da_regra("N12a-44", itens, aplica = simplificada & csosn %in% "500",
                    confere = cfop %in% CFOP_DO_ICMS_COBRADO_ANTES_NA_NFCE, campo = "prod/CFOP",
                    no_documento = texto_ou_vazio(cfop), esperado = paste(CFOP_DO_ICMS_COBRADO_ANTES_NA_NFCE, collapse = ", ")),
    linhas_da_regra("N17-20", itens, aplica = cst %in% c("00", "10", "20", "70") & itens$finalidade %in% "1" &
                      !is.na(icms_calculado) & !is.na(itens$valor_icms),
                    confere = igual_com_tolerancia(itens$valor_icms, icms_calculado, TOLERANCIA_DOS_VALORES),
                    campo = "imposto/ICMS/vICMS", no_documento = texto_do_numero(itens$valor_icms, 2),
                    esperado = texto_do_numero(icms_calculado, 2), diferenca = round(itens$valor_icms - icms_calculado, 2)),
    linhas_da_regra("N28-30", itens, aplica = !is.na(itens$motivo_desoneracao), confere = (itens$icms_desonerado > 0) %in% TRUE,
                    campo = "imposto/ICMS/vICMSDeson", no_documento = texto_do_numero(itens$icms_desonerado, 2),
                    esperado = "maior que zero"),
    linhas_da_regra("N12-10", itens, aplica = substr(cfop, 1, 1) %in% "7" & !(itens$finalidade %in% "4"),
                    confere = cst %in% "41" | csosn %in% "300", campo = "imposto/ICMS",
                    no_documento = ifelse(is.na(cst), paste("CSOSN", texto_ou_vazio(csosn)), paste("CST", cst)),
                    esperado = "CST 41 ou CSOSN 300"),
    linhas_da_regra("N12a-81", itens, aplica = mei_na_nfce, confere = csosn %in% c("102", "300"),
                    campo = "imposto/ICMS/CSOSN", no_documento = texto_ou_vazio(csosn), esperado = "102 ou 300"),
    linhas_da_regra("N12a-91", itens, aplica = mei_na_nfce, confere = cfop %in% "5102", campo = "prod/CFOP",
                    no_documento = texto_ou_vazio(cfop), esperado = "5102"),
    linhas_da_regra("N28-12", itens, aplica = itens$motivo_desoneracao %in% "7", confere = itens$deduz_desonerado %in% "1",
                    campo = "imposto/ICMS/indDeduzDeson", no_documento = texto_ou_vazio(itens$deduz_desonerado),
                    esperado = "1"),
    linhas_da_regra("NA09-10", itens, aplica = (itens$aliquota_interestadual == 4) %in% TRUE,
                    confere = itens$origem %in% ORIGENS_DE_IMPORTADO, campo = "imposto/ICMSUFDest/pICMSInter",
                    no_documento = texto_da_origem_e_da_aliquota, esperado = "origem de importado (1, 2, 3 ou 8)"),
    linhas_da_regra("NA09-20", itens, aplica = (itens$aliquota_interestadual %in% c(7, 12)),
                    confere = !(itens$origem %in% ORIGENS_DE_IMPORTADO), campo = "imposto/ICMSUFDest/pICMSInter",
                    no_documento = texto_da_origem_e_da_aliquota, esperado = "origem diferente de 1, 2, 3 e 8")
  ))
}

# Os grupos que a NFC-e e a NF-e com DANFE Simplificado Tipo 2 não podem ter, no item e na nota.
conferir_os_grupos_da_nfce = function(notas, itens) {
  juntar_linhas(list(
    linhas_do_grupo_proibido("J01-10", itens, itens$tem_veiculo, "prod/veicProd", itens$item),
    linhas_do_grupo_proibido("L01-10", itens, itens$tem_arma, "prod/arma", itens$item),
    linhas_do_grupo_proibido("LB01-10", itens, itens$tem_recopi, "prod/nRECOPI", itens$item),
    linhas_do_grupo_proibido("NA01-10", itens, itens$tem_icms_uf_destino, "imposto/ICMSUFDest", itens$item),
    linhas_do_grupo_proibido("O01-10", itens, itens$tem_ipi, "imposto/IPI", itens$item),
    linhas_do_grupo_proibido("P01-10", itens, itens$tem_ii, "imposto/II", itens$item),
    linhas_do_grupo_proibido("R01-10", itens, itens$tem_pis_st, "imposto/PISST", itens$item),
    linhas_do_grupo_proibido("T01-10", itens, itens$tem_cofins_st, "imposto/COFINSST", itens$item),
    linhas_do_grupo_proibido("UA01-20", itens, itens$tem_devolucao_tributos, "impostoDevol", itens$item),
    linhas_do_grupo_proibido("X11-10", notas, notas$tem_retencao_transporte, "transp/retTransp"),
    linhas_do_grupo_proibido("X18-10", notas, notas$tem_veiculo_transporte, "transp/veicTransp"),
    linhas_do_grupo_proibido("X22-10", notas, notas$tem_reboque, "transp/reboque"),
    linhas_do_grupo_proibido("X25a-10", notas, notas$tem_vagao, "transp/vagao"),
    linhas_do_grupo_proibido("X25b-10", notas, notas$tem_balsa, "transp/balsa"),
    linhas_do_grupo_proibido("Y01-10", notas, notas$tem_cobranca, "cobr"),
    linhas_do_grupo_proibido("ZB01-10", notas, notas$tem_compra, "compra"),
    linhas_do_grupo_proibido("ZC01-10", notas, notas$tem_cana, "cana")
  ))
}

# Os totais da nota (grupo W): cada um é a soma dos itens, e o valor da nota é a conta dos outros totais.
conferir_os_totais_da_nota = function(notas, itens) {
  chaves = notas$chave
  com_issqn = notas$tem_total_issqn | chaves %in% itens$chave[itens$tem_issqn]
  pis_st_que_soma = somar_dos_itens(ifelse(itens$soma_pis_st %in% "1", itens$valor_pis_st, 0), itens, notas)
  cofins_st_que_soma = somar_dos_itens(ifelse(itens$soma_cofins_st %in% "1", itens$valor_cofins_st, 0), itens, notas)
  desonerado_que_deduz = somar_dos_itens(ifelse(itens$deduz_desonerado %in% "1", itens$icms_desonerado, 0), itens, notas)
  faturamento_direto = chaves %in% itens$chave[itens$tipo_operacao_veiculo %in% "2"]
  importacao = chaves %in% itens$chave[substr(itens$cfop, 1, 1) %in% "3"]

  # W16-10: o valor da nota pela redação da NT 2023.004. O ICMS desonerado dos itens sem o indDeduzDeson 1 pode ficar
  # fora da conta (exceção 4). No faturamento direto de veículos, a NT tirou da conta o ICMS monofásico com retenção sem
  # dizer desde quando: a conta antiga, com ele, também passa (a regra é facultativa).
  parte_comum = valor_ou_zero(notas$total_produtos) - valor_ou_zero(notas$total_desconto) +
    valor_ou_zero(notas$total_frete) + valor_ou_zero(notas$total_seguro) + valor_ou_zero(notas$total_outros) +
    valor_ou_zero(notas$total_ii) + valor_ou_zero(notas$total_ipi) + valor_ou_zero(notas$total_servicos) +
    pis_st_que_soma + cofins_st_que_soma
  parte_da_venda = valor_ou_zero(notas$total_st) + valor_ou_zero(notas$total_fcp_st) +
    valor_ou_zero(notas$total_monofasico_retencao) + valor_ou_zero(notas$total_ipi_devolvido)
  monofasico_do_faturamento_direto = ifelse(faturamento_direto, valor_ou_zero(notas$total_monofasico_retencao), 0)
  sem_desonerado = ifelse(faturamento_direto, parte_comum, parte_comum + parte_da_venda)
  pelo_total_desonerado = sem_desonerado - valor_ou_zero(notas$total_icms_desonerado)
  pelo_desonerado_que_deduz = sem_desonerado - desonerado_que_deduz
  valor_da_nota = valor_ou_zero(notas$total_nota)
  confere_o_valor_da_nota = abs(valor_da_nota - pelo_total_desonerado) <= TOLERANCIA_DO_TOTAL_DA_NOTA + FOLGA_DE_PONTO_FLUTUANTE |
    abs(valor_da_nota - pelo_desonerado_que_deduz) <= TOLERANCIA_DO_TOTAL_DA_NOTA + FOLGA_DE_PONTO_FLUTUANTE |
    abs(valor_da_nota - pelo_total_desonerado - monofasico_do_faturamento_direto) <= TOLERANCIA_DO_TOTAL_DA_NOTA + FOLGA_DE_PONTO_FLUTUANTE |
    abs(valor_da_nota - pelo_desonerado_que_deduz - monofasico_do_faturamento_direto) <= TOLERANCIA_DO_TOTAL_DA_NOTA + FOLGA_DE_PONTO_FLUTUANTE
  acima_do_limite = (notas$total_nota > LIMITE_DA_NFCE_SEM_DESTINATARIO) %in% TRUE
  com_codigo_do_destinatario = !is.na(notas$cnpj_destinatario) | !is.na(notas$cpf_destinatario) | notas$tem_estrangeiro

  juntar_linhas(list(
    linhas_da_soma("W03-10", notas, notas$total_base_icms, somar_dos_itens(itens$base_icms, itens, notas), "total/ICMSTot/vBC"),
    linhas_da_soma("W04-10", notas, notas$total_icms, somar_dos_itens(itens$valor_icms, itens, notas), "total/ICMSTot/vICMS"),
    linhas_da_soma("W04a-10", notas, notas$total_icms_desonerado, somar_dos_itens(itens$icms_desonerado, itens, notas), "total/ICMSTot/vICMSDeson"),
    linhas_da_soma("W04b-10", notas, notas$total_fcp, somar_dos_itens(itens$fcp, itens, notas), "total/ICMSTot/vFCP"),
    linhas_da_soma("W04c-10", notas, notas$total_fcp_uf_destino, somar_dos_itens(itens$fcp_uf_destino, itens, notas), "total/ICMSTot/vFCPUFDest"),
    linhas_da_soma("W04e-10", notas, notas$total_icms_uf_destino, somar_dos_itens(itens$icms_uf_destino, itens, notas), "total/ICMSTot/vICMSUFDest"),
    linhas_da_soma("W04g-10", notas, notas$total_icms_uf_remetente, somar_dos_itens(itens$icms_uf_remetente, itens, notas), "total/ICMSTot/vICMSUFRemet"),
    linhas_da_soma("W05-10", notas, notas$total_base_st, somar_dos_itens(itens$base_st, itens, notas), "total/ICMSTot/vBCST"),
    linhas_da_soma("W06-10", notas, notas$total_st, somar_dos_itens(itens$valor_st, itens, notas), "total/ICMSTot/vST"),
    linhas_da_soma("W06a-10", notas, notas$total_fcp_st, somar_dos_itens(itens$fcp_st, itens, notas), "total/ICMSTot/vFCPST"),
    linhas_da_soma("W06b-10", notas, notas$total_fcp_st_retido, somar_dos_itens(itens$fcp_st_retido, itens, notas), "total/ICMSTot/vFCPSTRet"),
    linhas_da_soma("W08-10", notas, notas$total_frete, somar_dos_itens(itens$frete, itens, notas), "total/ICMSTot/vFrete"),
    linhas_da_soma("W09-10", notas, notas$total_seguro, somar_dos_itens(itens$seguro, itens, notas), "total/ICMSTot/vSeg"),
    linhas_da_soma("W10-10", notas, notas$total_desconto, somar_dos_itens(itens$desconto, itens, notas), "total/ICMSTot/vDesc"),
    linhas_da_soma("W11-10", notas, notas$total_ii, somar_dos_itens(itens$valor_ii, itens, notas), "total/ICMSTot/vII"),
    linhas_da_soma("W12-10", notas, notas$total_ipi, somar_dos_itens(itens$valor_ipi, itens, notas), "total/ICMSTot/vIPI"),
    linhas_da_soma("W12a-10", notas, notas$total_ipi_devolvido, somar_dos_itens(itens$ipi_devolvido, itens, notas), "total/ICMSTot/vIPIDevol"),
    linhas_da_soma("W13-10", notas, notas$total_pis, somar_dos_itens(ifelse(itens$tem_icms, itens$valor_pis, 0), itens, notas), "total/ICMSTot/vPIS"),
    linhas_da_soma("W14-10", notas, notas$total_cofins, somar_dos_itens(ifelse(itens$tem_icms, itens$valor_cofins, 0), itens, notas),
                   "total/ICMSTot/vCOFINS"),
    linhas_da_soma("W15-10", notas, notas$total_outros, somar_dos_itens(itens$outros, itens, notas), "total/ICMSTot/vOutro"),
    linhas_da_regra("W16-10", notas, aplica = !importacao & !is.na(notas$total_nota), confere = confere_o_valor_da_nota,
                    campo = "total/ICMSTot/vNF", no_documento = texto_do_numero(notas$total_nota, 2),
                    esperado = texto_do_numero(pelo_total_desonerado, 2),
                    diferenca = round(valor_da_nota - pelo_total_desonerado, 2), itens_da_regra = SEM_ITEM),
    linhas_da_regra("W16-30", notas, aplica = notas$simplificada & !is.na(notas$total_nota),
                    confere = notas$total_nota <= LIMITE_DA_NFCE, campo = "total/ICMSTot/vNF",
                    no_documento = texto_do_numero(notas$total_nota, 2), esperado = "at\u00e9 200000.00",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("W16-40", notas, aplica = acima_do_limite, confere = com_codigo_do_destinatario,
                    campo = "dest/CNPJ, dest/CPF ou dest/idEstrangeiro", no_documento = texto_da_presenca(com_codigo_do_destinatario),
                    esperado = "informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("W16-50", notas, aplica = acima_do_limite, confere = informado(notas$nome_destinatario),
                    campo = "dest/xNome", no_documento = texto_da_presenca(informado(notas$nome_destinatario)),
                    esperado = "informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("W16-60", notas, aplica = acima_do_limite, confere = notas$tem_endereco_destinatario,
                    campo = "dest/enderDest", no_documento = texto_da_presenca(notas$tem_endereco_destinatario),
                    esperado = "informado", itens_da_regra = SEM_ITEM),
    linhas_da_soma("W18-10", notas, notas$total_servicos, somar_dos_itens(ifelse(itens$tem_issqn, itens$valor_produto, 0), itens, notas),
                   "total/ISSQNtot/vServ", aplica = com_issqn),
    linhas_da_soma("W19-10", notas, notas$total_base_iss, somar_dos_itens(itens$base_iss, itens, notas), "total/ISSQNtot/vBC", aplica = com_issqn),
    linhas_da_soma("W20-10", notas, notas$total_iss, somar_dos_itens(itens$valor_iss, itens, notas), "total/ISSQNtot/vISS", aplica = com_issqn),
    linhas_da_soma("W21-10", notas, notas$total_pis_servicos, somar_dos_itens(ifelse(itens$tem_issqn, itens$valor_pis, 0), itens, notas),
                   "total/ISSQNtot/vPIS", aplica = com_issqn),
    linhas_da_soma("W22-10", notas, notas$total_cofins_servicos, somar_dos_itens(ifelse(itens$tem_issqn, itens$valor_cofins, 0), itens, notas),
                   "total/ISSQNtot/vCOFINS", aplica = com_issqn)
  ))
}

# O transporte (grupo X): o frete na NFC-e e o transportador.
conferir_o_transporte = function(notas) {
  juntar_linhas(list(
    linhas_da_regra("X02-10", notas, aplica = notas$simplificada,
                    confere = notas$modalidade_frete %in% "9" | notas$presenca %in% "4", campo = "transp/modFrete",
                    no_documento = texto_ou_vazio(notas$modalidade_frete), esperado = "9 (sem frete), fora da entrega a domic\u00edlio",
                    itens_da_regra = SEM_ITEM),
    linhas_do_cnpj("X04-20", notas, notas$cnpj_transportador, "transp/transporta/CNPJ"),
    linhas_do_cpf("X05-10", notas, notas$cpf_transportador, "transp/transporta/CPF"),
    # A IE ISENTO não é inscrição: há NF-e autorizada com ela e sem a UF do transportador.
    linhas_da_regra("X07-10", notas, aplica = informado(notas$ie_transportador) & !(notas$ie_transportador %in% "ISENTO"),
                    confere = informado(notas$uf_transportador),
                    campo = "transp/transporta/UF", no_documento = texto_ou_vazio(notas$uf_transportador),
                    esperado = "informada", itens_da_regra = SEM_ITEM)
  ))
}

texto_da_data = function(datas) {
  textos = format(datas, "%d/%m/%Y")
  textos[is.na(datas)] = "(vazio)"
  textos
}

# A data dez anos depois de cada uma (o 29 de fevereiro vira 1º de março, quando o ano não tem o dia).
dez_anos_depois = function(datas) {
  partes = as.POSIXlt(datas)
  partes$year = partes$year + 10
  as.Date(partes)
}

# A cobrança (grupo Y): a fatura e as parcelas.
conferir_a_cobranca = function(notas, parcelas) {
  da_nota = match(parcelas$chave, notas$chave)
  ordem = ordem_na_nota(parcelas$chave)
  campo = paste0("cobr/dup[", ordem, "]")
  quantas_parcelas = as.integer(table(factor(parcelas$chave, levels = notas$chave)))
  vencimento_da_unica = parcelas$vencimento[match(notas$chave, parcelas$chave)]
  soma_das_parcelas = somar_por_nota(parcelas$valor, parcelas$chave, notas$chave)
  desconto = valor_ou_zero(notas$desconto_fatura)
  liquido_calculado = round(valor_ou_zero(notas$valor_original_fatura) - desconto, 2)
  # O vencimento da parcela anterior da mesma nota (a ordem do XML); a primeira não tem.
  vencimento_anterior = rep(as.Date(NA), length(parcelas$vencimento))
  if (length(parcelas$vencimento) > 1) {
    vencimento_anterior[-1] = parcelas$vencimento[-length(parcelas$vencimento)]
  }
  vencimento_anterior[ordem == 1] = NA
  limite_do_vencimento = dez_anos_depois(as.Date(format(notas$recebimento[da_nota], "%Y-%m-%d", tz = "America/Sao_Paulo")))

  juntar_linhas(list(
    linhas_da_regra("Y01-20", notas, aplica = notas$tem_cobranca,
                    confere = informado(notas$numero_fatura) & !is.na(notas$valor_original_fatura) &
                      !is.na(notas$valor_liquido_fatura),
                    campo = "cobr/fat", no_documento = texto_da_presenca(informado(notas$numero_fatura) &
                                                                           !is.na(notas$valor_original_fatura) &
                                                                           !is.na(notas$valor_liquido_fatura)),
                    esperado = "nFat, vOrig e vLiq informados", itens_da_regra = SEM_ITEM),
    linhas_da_regra("Y05-10", notas, aplica = !is.na(notas$valor_original_fatura) | !is.na(notas$desconto_fatura),
                    confere = desconto <= valor_ou_zero(notas$valor_original_fatura) + FOLGA_DE_PONTO_FLUTUANTE,
                    campo = "cobr/fat/vDesc", no_documento = texto_do_numero(notas$desconto_fatura, 2),
                    esperado = paste("at\u00e9", texto_do_numero(notas$valor_original_fatura, 2)), itens_da_regra = SEM_ITEM),
    linhas_da_regra("Y06-10", notas, aplica = !is.na(notas$valor_liquido_fatura) & !is.na(notas$valor_original_fatura),
                    confere = abs(notas$valor_liquido_fatura - liquido_calculado) < TOLERANCIA_DO_CENTAVO,
                    campo = "cobr/fat/vLiq", no_documento = texto_do_numero(notas$valor_liquido_fatura, 2),
                    esperado = texto_do_numero(liquido_calculado, 2),
                    diferenca = round(notas$valor_liquido_fatura - liquido_calculado, 2), itens_da_regra = SEM_ITEM),
    linhas_da_regra("Y08-10", parcelas, aplica = TRUE, confere = (parcelas$numero == sprintf("%03d", ordem)) %in% TRUE,
                    campo = paste0(campo, "/nDup"), no_documento = texto_ou_vazio(parcelas$numero),
                    esperado = sprintf("%03d", ordem), itens_da_regra = SEM_ITEM),
    linhas_da_regra("Y09-20", parcelas, aplica = TRUE,
                    confere = (parcelas$vencimento >= notas$data_emissao[da_nota]) %in% TRUE,
                    campo = paste0(campo, "/dVenc"), no_documento = texto_da_data(parcelas$vencimento),
                    esperado = paste("a partir de", texto_da_data(notas$data_emissao[da_nota])), itens_da_regra = SEM_ITEM),
    linhas_da_regra("Y09-30", parcelas, aplica = ordem > 1,
                    confere = (parcelas$vencimento >= vencimento_anterior) %in% TRUE, campo = paste0(campo, "/dVenc"),
                    no_documento = texto_da_data(parcelas$vencimento),
                    esperado = paste("a partir de", texto_da_data(vencimento_anterior)), itens_da_regra = SEM_ITEM),
    linhas_da_regra("Y09-40", notas, aplica = quantas_parcelas == 1 & !is.na(vencimento_da_unica) & !is.na(notas$data_emissao),
                    confere = vencimento_da_unica != notas$data_emissao, campo = "cobr/dup/dVenc",
                    no_documento = format(vencimento_da_unica, "%d/%m/%Y"), esperado = "vencimento depois da emiss\u00e3o",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("Y09-50", parcelas, aplica = !is.na(parcelas$vencimento),
                    confere = (parcelas$vencimento <= limite_do_vencimento) %in% TRUE, campo = paste0(campo, "/dVenc"),
                    no_documento = format(parcelas$vencimento, "%d/%m/%Y"),
                    esperado = paste("at\u00e9", format(limite_do_vencimento, "%d/%m/%Y")), itens_da_regra = SEM_ITEM),
    linhas_da_regra("Y10-10", notas, aplica = quantas_parcelas > 0 & !is.na(notas$valor_liquido_fatura),
                    confere = abs(soma_das_parcelas - notas$valor_liquido_fatura) < TOLERANCIA_DO_CENTAVO,
                    campo = "cobr/dup/vDup", no_documento = texto_do_numero(soma_das_parcelas, 2),
                    esperado = texto_do_numero(notas$valor_liquido_fatura, 2),
                    diferenca = round(soma_das_parcelas - notas$valor_liquido_fatura, 2), itens_da_regra = SEM_ITEM)
  ))
}

# Os pagamentos (grupo YA) e o intermediador (grupo YB).
conferir_os_pagamentos = function(notas, pagamentos) {
  da_nota = match(pagamentos$chave, notas$chave)
  campo = paste0("pag/detPag[", ordem_na_nota(pagamentos$chave), "]")
  meio = pagamentos$meio
  # O início de cada linha das tabelas é o da descrição de hoje (o 05 e o 17 já existiam antes de 2024, com outro
  # nome): basta o código estar na tabela.
  meio_existe = meio %in% tabela_fiscal("meios_pagamento")$codigo
  bandeira_existe = pagamentos$bandeira %in% tabela_fiscal("bandeiras_cartao")$codigo
  soma_dos_pagamentos = somar_por_nota(pagamentos$valor, pagamentos$chave, notas$chave)
  sem_pagamento_ou_posterior = notas$chave %in% pagamentos$chave[meio %in% c("90", "91")]
  valor_da_nota = valor_ou_zero(notas$total_nota)
  troco_calculado = round(soma_dos_pagamentos - valor_da_nota, 2)
  confere_o_cartao = ifelse(meio %in% MEIOS_COM_CARTAO, TRUE, ifelse(meio %in% MEIOS_DEPOIS_DA_REGRA_DO_CARTAO, NA, FALSE))
  # A data do pagamento contra a do recebimento pela SEFAZ, no horário de Brasília (YA03a-10).
  data_do_pagamento = as.Date(pagamentos$data_pagamento)
  data_do_recebimento = as.Date(format(notas$recebimento[da_nota], "%Y-%m-%d", tz = "America/Sao_Paulo"))

  juntar_linhas(list(
    linhas_da_regra("YA02-04", pagamentos, aplica = notas$finalidade[da_nota] %in% c("3", "4"), confere = meio %in% "90",
                    campo = paste0(campo, "/tPag"), no_documento = texto_ou_vazio(meio), esperado = "90 (sem pagamento)",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA02-40", pagamentos, aplica = TRUE, confere = !(meio %in% "90"), campo = paste0(campo, "/tPag"),
                    no_documento = texto_ou_vazio(meio), esperado = "diferente de 90", itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA02-60", pagamentos, aplica = !is.na(meio), confere = meio_existe, campo = paste0(campo, "/tPag"),
                    no_documento = meio, esperado = "meio de pagamento da tabela", itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA02a-10", pagamentos, aplica = meio %in% "99", confere = informado(pagamentos$descricao),
                    campo = paste0(campo, "/xPag"), no_documento = texto_ou_vazio(pagamentos$descricao),
                    esperado = "informada", itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA02a-20", pagamentos, aplica = !is.na(meio) & !(meio %in% "99"), confere = !informado(pagamentos$descricao),
                    campo = paste0(campo, "/xPag"), no_documento = texto_ou_vazio(pagamentos$descricao),
                    esperado = "n\u00e3o informada", itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA03-10", notas, aplica = !(notas$finalidade %in% c("3", "4")) & !sem_pagamento_ou_posterior &
                      !is.na(notas$total_nota),
                    confere = soma_dos_pagamentos >= valor_da_nota - TOLERANCIA_DO_CENTAVO, campo = "pag/detPag/vPag",
                    no_documento = texto_do_numero(soma_dos_pagamentos, 2),
                    esperado = paste("pelo menos", texto_do_numero(notas$total_nota, 2)),
                    diferenca = round(soma_dos_pagamentos - valor_da_nota, 2), itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA03-20", notas, aplica = notas$chave %in% pagamentos$chave & !is.na(notas$total_nota),
                    confere = !(soma_dos_pagamentos > valor_da_nota + TOLERANCIA_DO_CENTAVO & is.na(notas$troco)),
                    campo = "pag/vTroco", no_documento = texto_do_numero(notas$troco, 2),
                    esperado = "informado quando os pagamentos passam do total da nota", itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA03-30", pagamentos, aplica = meio %in% c("90", "91"), confere = (pagamentos$valor == 0) %in% TRUE,
                    campo = paste0(campo, "/vPag"), no_documento = texto_do_numero(pagamentos$valor, 2), esperado = "0.00",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA03a-10", pagamentos, aplica = !is.na(data_do_pagamento),
                    confere = (data_do_pagamento <= data_do_recebimento) %in% TRUE, campo = paste0(campo, "/dPag"),
                    no_documento = format(data_do_pagamento, "%d/%m/%Y"),
                    esperado = paste("at\u00e9", format(data_do_recebimento, "%d/%m/%Y")), itens_da_regra = SEM_ITEM),
    linhas_do_cnpj("YA03c-10", pagamentos, pagamentos$cnpj_pagamento, paste0(campo, "/CNPJPag")),
    linhas_da_regra("YA04-10", pagamentos, aplica = meio %in% c("03", "04", "17"), confere = pagamentos$tem_cartao,
                    campo = paste0(campo, "/card"), no_documento = texto_da_presenca(pagamentos$tem_cartao),
                    esperado = "informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA04-20", pagamentos, aplica = pagamentos$tem_cartao, confere = confere_o_cartao,
                    campo = paste0(campo, "/card"), no_documento = paste("tPag", texto_ou_vazio(meio)),
                    esperado = paste("tPag", paste(MEIOS_COM_CARTAO, collapse = ", ")),
                    observacao = ifelse(is.na(confere_o_cartao), paste(
                      "O meio de pagamento entrou na tabela depois da reda\u00e7\u00e3o da regra, que n\u00e3o diz se ele aceita",
                      "o grupo de cart\u00f5es."
                    ), NA), itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA05-10", pagamentos, aplica = pagamentos$tem_cartao & pagamentos$tipo_integracao %in% "1",
                    confere = informado(pagamentos$cnpj_credenciadora) & informado(pagamentos$autorizacao_cartao),
                    campo = paste0(campo, "/card/CNPJ e card/cAut"),
                    no_documento = paste0("CNPJ ", texto_da_presenca(informado(pagamentos$cnpj_credenciadora)), ", cAut ",
                                          texto_da_presenca(informado(pagamentos$autorizacao_cartao))),
                    esperado = "os dois informados (tpIntegra 1)", itens_da_regra = SEM_ITEM),
    linhas_do_cnpj("YA05-20", pagamentos, pagamentos$cnpj_credenciadora, paste0(campo, "/card/CNPJ")),
    linhas_da_regra("YA06-10", pagamentos, aplica = !is.na(pagamentos$bandeira), confere = bandeira_existe,
                    campo = paste0(campo, "/card/tBand"), no_documento = pagamentos$bandeira,
                    esperado = "bandeira da tabela", itens_da_regra = SEM_ITEM),
    linhas_do_cnpj("YA07a", pagamentos, pagamentos$cnpj_recebedor, paste0(campo, "/card/CNPJReceb")),
    # Com os pagamentos abaixo do valor da nota (a YA03-10), o troco calculado é negativo, e o zero é o único possível.
    linhas_da_regra("YA09-10", notas, aplica = !is.na(notas$troco) & !(notas$troco == 0 & troco_calculado < 0),
                    confere = abs(valor_ou_zero(notas$troco) - troco_calculado) < TOLERANCIA_DO_CENTAVO, campo = "pag/vTroco",
                    no_documento = texto_do_numero(notas$troco, 2), esperado = texto_do_numero(troco_calculado, 2),
                    diferenca = round(valor_ou_zero(notas$troco) - troco_calculado, 2), itens_da_regra = SEM_ITEM),
    linhas_da_regra("YA09-20", notas, aplica = !is.na(notas$troco), confere = notas$troco <= LIMITE_DO_TROCO,
                    campo = "pag/vTroco", no_documento = texto_do_numero(notas$troco, 2), esperado = "at\u00e9 300000.00",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("YB01-10", notas, aplica = notas$intermediador %in% "1", confere = notas$tem_intermediador,
                    campo = "infIntermed", no_documento = texto_da_presenca(notas$tem_intermediador), esperado = "informado",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("YB01-20", notas, aplica = !is.na(notas$intermediador) & !(notas$intermediador %in% "1"),
                    confere = !notas$tem_intermediador, campo = "infIntermed",
                    no_documento = texto_da_presenca(notas$tem_intermediador), esperado = "n\u00e3o informado",
                    itens_da_regra = SEM_ITEM),
    linhas_do_cnpj("YB02-10", notas, notas$cnpj_intermediador, "infIntermed/CNPJ")
  ))
}

# A exportação (grupo ZA), o responsável técnico (ZD) e o QR-Code (ZX).
conferir_as_informacoes_finais = function(notas) {
  exportacao = notas$tipo_operacao %in% "1" & notas$destino_operacao %in% "3"
  chave_do_qrcode = parametro_do_qrcode(notas$qrcode, 1)
  versao_do_qrcode = parametro_do_qrcode(notas$qrcode, 2)
  juntar_linhas(list(
    linhas_da_regra("ZA01-10", notas, aplica = exportacao, confere = notas$tem_exporta, campo = "exporta",
                    no_documento = texto_da_presenca(notas$tem_exporta), esperado = "informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("ZA01-20", notas, aplica = notas$tem_exporta, confere = exportacao, campo = "exporta",
                    no_documento = paste0("tpNF ", texto_ou_vazio(notas$tipo_operacao), ", idDest ",
                                          texto_ou_vazio(notas$destino_operacao)),
                    esperado = "s\u00f3 na sa\u00edda para o exterior (tpNF 1, idDest 3)", itens_da_regra = SEM_ITEM),
    linhas_da_regra("ZA01-30", notas, aplica = TRUE, confere = !notas$tem_exporta, campo = "exporta",
                    no_documento = texto_da_presenca(notas$tem_exporta), esperado = "n\u00e3o informado", itens_da_regra = SEM_ITEM),
    linhas_do_cnpj("ZD02-10", notas, notas$cnpj_responsavel_tecnico, "infRespTec/CNPJ"),
    linhas_da_regra("ZX01-10", notas, aplica = !(notas$tipo_impressao %in% "6"), confere = !notas$tem_suplementar,
                    campo = "infNFeSupl", no_documento = texto_da_presenca(notas$tem_suplementar),
                    esperado = "n\u00e3o informado", itens_da_regra = SEM_ITEM),
    linhas_da_regra("ZX02-10", notas, aplica = notas$simplificada & !(notas$tipo_emissao %in% "3"),
                    confere = informado(notas$qrcode), campo = "infNFeSupl/qrCode",
                    no_documento = texto_da_presenca(informado(notas$qrcode)), esperado = "informado",
                    itens_da_regra = SEM_ITEM),
    linhas_da_regra("ZX02-220", notas, aplica = informado(notas$qrcode), confere = versao_do_qrcode %in% "3",
                    campo = "infNFeSupl/qrCode", no_documento = paste("vers\u00e3o", texto_ou_vazio(versao_do_qrcode)),
                    esperado = "vers\u00e3o 3", itens_da_regra = SEM_ITEM),
    linhas_da_regra("ZX02-228", notas, aplica = versao_do_qrcode %in% c("2", "3"),
                    confere = (toupper(chave_do_qrcode) == toupper(notas$chave)) %in% TRUE, campo = "infNFeSupl/qrCode",
                    no_documento = texto_ou_vazio(chave_do_qrcode), esperado = notas$chave, itens_da_regra = SEM_ITEM)
  ))
}

# Um parâmetro do QR-Code (o 1º é a chave, o 2º a versão), depois do "p=" do endereço; NA sem ele.
parametro_do_qrcode = function(qrcodes, posicao) {
  com_parametros = !is.na(qrcodes) & grepl("[?&]p=", qrcodes)
  partes = strsplit(sub("^.*[?&]p=", "", qrcodes), "|", fixed = TRUE)
  valores = vapply(partes, "[", character(1), posicao)
  valores[!com_parametros] = NA_character_
  valores
}

# A importação por conta e ordem ou por encomenda (tpIntermedio 2 ou 3) com o adquirente ou o encomendante (grupo I,
# DI).
conferir_as_importacoes = function(importacoes) {
  por_terceiro = importacoes$intermedio %in% c("2", "3")
  campo = "prod/DI"
  juntar_linhas(list(
    linhas_da_regra("I23d-10", importacoes, aplica = por_terceiro,
                    confere = informado(importacoes$cnpj) | informado(importacoes$cpf), campo = paste0(campo, "/CNPJ ou CPF"),
                    no_documento = texto_da_presenca(informado(importacoes$cnpj) | informado(importacoes$cpf)),
                    esperado = "informado", itens_da_regra = importacoes$item),
    linhas_do_cnpj("I23d-20", importacoes, importacoes$cnpj, paste0(campo, "/CNPJ"), importacoes$item),
    linhas_do_cpf("I23d1-10", importacoes, importacoes$cpf, paste0(campo, "/CPF"), importacoes$item),
    linhas_da_regra("I23e-10", importacoes, aplica = por_terceiro, confere = informado(importacoes$uf_terceiro),
                    campo = paste0(campo, "/UFTerceiro"), no_documento = texto_ou_vazio(importacoes$uf_terceiro),
                    esperado = "informada", itens_da_regra = importacoes$item)
  ))
}
