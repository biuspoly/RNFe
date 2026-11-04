# As regras da tributação monofásica de combustíveis do IBS e da CBS (gIBSCBSMono), no leiaute que a NT 2025.002 v1.50
# separou em ad rem e ad valorem (produção em 16/11/2026): o grupo que cada ano exige, o que cada classificação exige ou
# não permite em cada grupo, as contas e o combustível com etanol anidro fora do percentual obrigatório. Também a
# exigência do grupo de combustível (LA01-30).

#' @include ler_xml.R tabelas.R
NULL

INICIO_DO_MONOFASICO_NOVO = as.Date("2026-11-16")

# A partir de cada det: os campos dos quatro grupos (IBS e CBS, ad rem e ad valorem).
CAMPOS_DO_MONOFASICO = ler_campos("
coluna                                    caminho                                                                          tipo
ibs_ad_rem_quantidade                     imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gMonoPadrao/qBCMono                     numero
ibs_ad_rem_aliquota                       imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gMonoPadrao/adRemIBS                    numero
ibs_ad_rem_valor                          imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gMonoPadrao/vIBSMono                    numero
ibs_ad_rem_quantidade_retencao            imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gMonoReten/qBCMonoReten                numero
ibs_ad_rem_aliquota_retencao              imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gMonoReten/adRemIBSReten               numero
ibs_ad_rem_valor_retencao                 imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gMonoReten/vIBSMonoReten               numero
ibs_ad_rem_quantidade_biocombustivel      imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gpBioDiferenca/qBCBioComb              numero
ibs_ad_valorem_base                       imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoPadrao/vBCMono                numero
ibs_ad_valorem_aliquota_uf                imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoPadrao/pAliqMonoUF            numero
ibs_ad_valorem_valor_uf                   imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoPadrao/vIBSMonoUF             numero
ibs_ad_valorem_aliquota_municipio         imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoPadrao/pAliqMonoMun           numero
ibs_ad_valorem_valor_municipio            imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoPadrao/vIBSMonoMun            numero
ibs_ad_valorem_valor                      imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoPadrao/vIBSMono               numero
ibs_ad_valorem_base_retencao              imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoReten/vBCMonoReten            numero
ibs_ad_valorem_aliquota_retencao          imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoReten/pAliqMonoReten          numero
ibs_ad_valorem_valor_retencao             imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoReten/vIBSMonoReten           numero
ibs_ad_valorem_quantidade_biocombustivel  imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gpBioDiferenca/qBCBioComb          numero
cbs_ad_rem_quantidade                     imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gMonoPadrao/qBCMono                     numero
cbs_ad_rem_aliquota                       imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gMonoPadrao/adRemCBS                    numero
cbs_ad_rem_valor                          imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gMonoPadrao/vCBSMono                    numero
cbs_ad_rem_quantidade_retencao            imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gMonoReten/qBCMonoReten                numero
cbs_ad_rem_aliquota_retencao              imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gMonoReten/adRemCBSReten               numero
cbs_ad_rem_valor_retencao                 imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gMonoReten/vCBSMonoReten               numero
cbs_ad_rem_quantidade_biocombustivel      imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gpBioDiferenca/qBCBioComb              numero
cbs_ad_valorem_base                       imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gMonoPadrao/vBCMono                numero
cbs_ad_valorem_aliquota                   imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gMonoPadrao/pAliqMonoCBS           numero
cbs_ad_valorem_valor                      imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gMonoPadrao/vCBSMono               numero
cbs_ad_valorem_base_retencao              imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gMonoReten/vBCMonoReten            numero
cbs_ad_valorem_aliquota_retencao          imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gMonoReten/pAliqMonoReten          numero
cbs_ad_valorem_valor_retencao             imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gMonoReten/vCBSMonoReten           numero
cbs_ad_valorem_quantidade_biocombustivel  imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gpBioDiferenca/qBCBioComb          numero
")

GRUPOS_DO_MONOFASICO_NO_ITEM = ler_campos("
coluna                              caminho
tem_ibs_ad_rem                      imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem
tem_ibs_ad_rem_padrao               imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gMonoPadrao
tem_ibs_ad_rem_retencao             imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gMonoReten
tem_ibs_ad_rem_retido               imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gMonoRet
tem_ibs_ad_rem_biocombustivel       imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdRem/gpBioDiferenca
tem_ibs_ad_valorem                  imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem
tem_ibs_ad_valorem_padrao           imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoPadrao
tem_ibs_ad_valorem_retencao         imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoReten
tem_ibs_ad_valorem_retido           imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gMonoRet
tem_ibs_ad_valorem_biocombustivel   imposto/IBSCBS/gIBSCBSMono/gIBSMonoAdValorem/gpBioDiferenca
tem_cbs_ad_rem                      imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem
tem_cbs_ad_rem_padrao               imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gMonoPadrao
tem_cbs_ad_rem_retencao             imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gMonoReten
tem_cbs_ad_rem_retido               imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gMonoRet
tem_cbs_ad_rem_biocombustivel       imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdRem/gpBioDiferenca
tem_cbs_ad_valorem                  imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem
tem_cbs_ad_valorem_padrao           imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gMonoPadrao
tem_cbs_ad_valorem_retencao         imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gMonoReten
tem_cbs_ad_valorem_retido           imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gMonoRet
tem_cbs_ad_valorem_biocombustivel   imposto/IBSCBS/gIBSCBSMono/gCBSMonoAdValorem/gpBioDiferenca
")

# De cada grupo, as regras de cada subgrupo: a que exige (indicador 1 na classificação) e a que não permite (0).
REGRAS_DOS_GRUPOS_DO_MONOFASICO = ler_campos("
parte           grupo               padrao_exigido  padrao_vedado  retencao_exigido  retencao_vedado  retido_exigido  retido_vedado  biocombustivel_exigido  biocombustivel_vedado
ibs_ad_rem      gIBSMonoAdRem       UB86-10         UB86-20        UB87-10           UB87-20          UB88-10         UB88-20        UB89-10                 UB89-20
ibs_ad_valorem  gIBSMonoAdValorem   UB91-10         UB91-20        UB92-10           UB92-20          UB93-10         UB93-20        UB94-10                 UB94-20
cbs_ad_rem      gCBSMonoAdRem       UB96-10         UB96-20        UB97-10           UB97-20          UB98-10         UB98-20        UB99-10                 UB99-20
cbs_ad_valorem  gCBSMonoAdValorem   UB101-10        UB101-20       UB102-10          UB102-20         UB103-10        UB103-20       UB104-10                UB104-20
")

# Cada subgrupo: o nome no XML e o indicador da classificação que diz se ele é exigido.
SUBGRUPOS_DO_MONOFASICO = ler_campos("
subgrupo        no_xml          indicador
padrao          gMonoPadrao     grupo_monofasico_padrao_da_classificacao
retencao        gMonoReten      grupo_monofasico_retencao_da_classificacao
retido          gMonoRet        grupo_monofasico_retido_da_classificacao
biocombustivel  gpBioDiferenca  grupo_diferenca_biocombustivel_da_classificacao
")

# As contas do monofásico: a regra, o subgrupo, os campos que entram e o campo conferido.
CONTAS_AD_REM_DO_MONOFASICO = ler_campos("
regra      tem_o_subgrupo                  quantidade                       aliquota                       valor                          campo
UB86c-10   tem_ibs_ad_rem_padrao           ibs_ad_rem_quantidade            ibs_ad_rem_aliquota            ibs_ad_rem_valor               gIBSMonoAdRem/gMonoPadrao/vIBSMono
UB87c-10   tem_ibs_ad_rem_retencao         ibs_ad_rem_quantidade_retencao   ibs_ad_rem_aliquota_retencao   ibs_ad_rem_valor_retencao      gIBSMonoAdRem/gMonoReten/vIBSMonoReten
UB96c-10   tem_cbs_ad_rem_padrao           cbs_ad_rem_quantidade            cbs_ad_rem_aliquota            cbs_ad_rem_valor               gCBSMonoAdRem/gMonoPadrao/vCBSMono
UB97c-10   tem_cbs_ad_rem_retencao         cbs_ad_rem_quantidade_retencao   cbs_ad_rem_aliquota_retencao   cbs_ad_rem_valor_retencao      gCBSMonoAdRem/gMonoReten/vCBSMonoReten
")

CONTAS_AD_VALOREM_DO_MONOFASICO = ler_campos("
regra      tem_o_subgrupo                base                           aliquota                           valor                            campo
UB91c-10   tem_ibs_ad_valorem_padrao     ibs_ad_valorem_base            ibs_ad_valorem_aliquota_uf         ibs_ad_valorem_valor_uf          gIBSMonoAdValorem/gMonoPadrao/vIBSMonoUF
UB91e-10   tem_ibs_ad_valorem_padrao     ibs_ad_valorem_base            ibs_ad_valorem_aliquota_municipio  ibs_ad_valorem_valor_municipio   gIBSMonoAdValorem/gMonoPadrao/vIBSMonoMun
UB92c-10   tem_ibs_ad_valorem_retencao   ibs_ad_valorem_base_retencao   ibs_ad_valorem_aliquota_retencao   ibs_ad_valorem_valor_retencao    gIBSMonoAdValorem/gMonoReten/vIBSMonoReten
UB101c-10  tem_cbs_ad_valorem_padrao     cbs_ad_valorem_base            cbs_ad_valorem_aliquota            cbs_ad_valorem_valor             gCBSMonoAdValorem/gMonoPadrao/vCBSMono
UB102c-10  tem_cbs_ad_valorem_retencao   cbs_ad_valorem_base_retencao   cbs_ad_valorem_aliquota_retencao   cbs_ad_valorem_valor_retencao    gCBSMonoAdValorem/gMonoReten/vCBSMonoReten
")

conferir_o_monofasico = function(itens) {
  juntar_linhas(list(
    conferir_os_grupos_do_ano(itens),
    conferir_os_subgrupos_do_monofasico(itens),
    conferir_as_contas_do_monofasico(itens),
    conferir_o_combustivel(itens)
  ))
}

# O grupo de cada ano (a tabela das regras UB85a, UB90, UB95a e UB100): o IBS é ad valorem até 2028 e ad rem depois; a
# CBS, ad valorem em 2026 e ad rem depois. O grupo do ano é exigido quando a classificação exige algum subgrupo. Em
# homologação, a CBS ad rem é aceita em 2026, e com ela a ad valorem deixa de ser exigida.
conferir_os_grupos_do_ano = function(itens) {
  ano = as.integer(format(itens$data_emissao, "%Y"))
  com_o_grupo = itens$tem_monofasico & !is.na(ano)
  exige_algum_subgrupo = itens$grupo_monofasico_padrao_da_classificacao %in% 1 |
    itens$grupo_monofasico_retencao_da_classificacao %in% 1 | itens$grupo_monofasico_retido_da_classificacao %in% 1 |
    itens$grupo_diferenca_biocombustivel_da_classificacao %in% 1
  em_homologacao = itens$ambiente %in% "2"
  linhas = list(
    linhas_da_regra("UB85a-10", itens, aplica = com_o_grupo & ano <= 2028, confere = !itens$tem_ibs_ad_rem,
                    campo = "gIBSCBSMono/gIBSMonoAdRem", no_documento = texto_da_presenca(itens$tem_ibs_ad_rem),
                    esperado = "n\u00e3o informado at\u00e9 2028"),
    linhas_da_regra("UB85a-20", itens, aplica = com_o_grupo & ano > 2028 & exige_algum_subgrupo,
                    confere = itens$tem_ibs_ad_rem, campo = "gIBSCBSMono/gIBSMonoAdRem",
                    no_documento = texto_da_presenca(itens$tem_ibs_ad_rem), esperado = "informado depois de 2028"),
    linhas_da_regra("UB90-10", itens, aplica = com_o_grupo & ano > 2028, confere = !itens$tem_ibs_ad_valorem,
                    campo = "gIBSCBSMono/gIBSMonoAdValorem", no_documento = texto_da_presenca(itens$tem_ibs_ad_valorem),
                    esperado = "n\u00e3o informado depois de 2028"),
    linhas_da_regra("UB90-20", itens, aplica = com_o_grupo & ano <= 2028 & exige_algum_subgrupo,
                    confere = itens$tem_ibs_ad_valorem, campo = "gIBSCBSMono/gIBSMonoAdValorem",
                    no_documento = texto_da_presenca(itens$tem_ibs_ad_valorem), esperado = "informado at\u00e9 2028"),
    linhas_da_regra("UB95a-10", itens, aplica = com_o_grupo & ano <= 2026 & !em_homologacao,
                    confere = !itens$tem_cbs_ad_rem, campo = "gIBSCBSMono/gCBSMonoAdRem",
                    no_documento = texto_da_presenca(itens$tem_cbs_ad_rem), esperado = "n\u00e3o informado em 2026"),
    linhas_da_regra("UB95a-20", itens, aplica = com_o_grupo & ano > 2026 & exige_algum_subgrupo,
                    confere = itens$tem_cbs_ad_rem, campo = "gIBSCBSMono/gCBSMonoAdRem",
                    no_documento = texto_da_presenca(itens$tem_cbs_ad_rem), esperado = "informado depois de 2026"),
    linhas_da_regra("UB100-10", itens, aplica = com_o_grupo & ano > 2026, confere = !itens$tem_cbs_ad_valorem,
                    campo = "gIBSCBSMono/gCBSMonoAdValorem", no_documento = texto_da_presenca(itens$tem_cbs_ad_valorem),
                    esperado = "n\u00e3o informado depois de 2026"),
    linhas_da_regra("UB100-20", itens,
                    aplica = com_o_grupo & ano <= 2026 & exige_algum_subgrupo & !(em_homologacao & itens$tem_cbs_ad_rem),
                    confere = itens$tem_cbs_ad_valorem, campo = "gIBSCBSMono/gCBSMonoAdValorem",
                    no_documento = texto_da_presenca(itens$tem_cbs_ad_valorem), esperado = "informado em 2026")
  )
  juntar_linhas(linhas)
}

# Os subgrupos de cada grupo informado: o que a classificação exige (indicador 1) tem de vir, o que ela não permite (0),
# não.
conferir_os_subgrupos_do_monofasico = function(itens) {
  linhas = list()
  for (numero_do_grupo in seq_len(nrow(REGRAS_DOS_GRUPOS_DO_MONOFASICO))) {
    grupo = REGRAS_DOS_GRUPOS_DO_MONOFASICO[numero_do_grupo, ]
    tem_o_grupo = itens[[paste0("tem_", grupo$parte)]]
    for (numero_do_subgrupo in seq_len(nrow(SUBGRUPOS_DO_MONOFASICO))) {
      subgrupo = SUBGRUPOS_DO_MONOFASICO[numero_do_subgrupo, ]
      indicador = itens[[subgrupo$indicador]]
      tem_o_subgrupo = itens[[paste0("tem_", grupo$parte, "_", subgrupo$subgrupo)]]
      caminho = paste0(grupo$grupo, "/", subgrupo$no_xml)
      linhas[[length(linhas) + 1]] = regra_de_grupo(grupo[[paste0(subgrupo$subgrupo, "_exigido")]], itens, indicador, 1,
                                                    tem_o_subgrupo, caminho, tem_o_grupo)
      linhas[[length(linhas) + 1]] = regra_de_grupo(grupo[[paste0(subgrupo$subgrupo, "_vedado")]], itens, indicador, 0,
                                                    tem_o_subgrupo, caminho, tem_o_grupo)
    }
  }
  juntar_linhas(linhas)
}

# As contas: no ad rem, a quantidade vezes a alíquota por unidade; no ad valorem, a base vezes a alíquota. A NT não diz
# se a alíquota ad valorem é percentual (as fórmulas dela não dividem por 100, as das outras alíquotas dividem): o
# valor que bate com a alíquota lida em percentual confere; o que não bate fica sem conferir, com o motivo.
conferir_as_contas_do_monofasico = function(itens) {
  linhas = list()
  for (numero_da_conta in seq_len(nrow(CONTAS_AD_REM_DO_MONOFASICO))) {
    conta = CONTAS_AD_REM_DO_MONOFASICO[numero_da_conta, ]
    valor = itens[[conta$valor]]
    calculado = arredondar_no_centavo(itens[[conta$quantidade]] * itens[[conta$aliquota]])
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      conta$regra, itens, aplica = itens[[conta$tem_o_subgrupo]],
      confere = igual_com_tolerancia(valor, calculado, TOLERANCIA_DOS_VALORES), campo = conta$campo,
      no_documento = texto_do_numero(valor, 2), esperado = texto_do_numero(calculado, 2), diferenca = valor - calculado
    )
  }
  for (numero_da_conta in seq_len(nrow(CONTAS_AD_VALOREM_DO_MONOFASICO))) {
    conta = CONTAS_AD_VALOREM_DO_MONOFASICO[numero_da_conta, ]
    valor = itens[[conta$valor]]
    calculado = arredondar_no_centavo(itens[[conta$base]] * itens[[conta$aliquota]] / 100)
    bate = igual_com_tolerancia(valor, calculado, TOLERANCIA_DOS_VALORES)
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      conta$regra, itens, aplica = itens[[conta$tem_o_subgrupo]], confere = ifelse(bate, TRUE, NA), campo = conta$campo,
      no_documento = texto_do_numero(valor, 2), esperado = texto_do_numero(calculado, 2), diferenca = valor - calculado,
      observacao = ifelse(bate, NA, paste(
        "N\u00e3o bate com a base vezes a al\u00edquota lida em percentual (dividida por 100); a NT n\u00e3o diz se a",
        "al\u00edquota ad valorem do monof\u00e1sico \u00e9 percentual, e a f\u00f3rmula dela n\u00e3o divide por 100."
      ))
    )
  }
  # O IBS ad valorem do item é o da UF mais o do município.
  soma = valor_ou_zero(itens$ibs_ad_valorem_valor_uf) + valor_ou_zero(itens$ibs_ad_valorem_valor_municipio)
  linhas[[length(linhas) + 1]] = linhas_da_regra(
    "UB91f-10", itens, aplica = itens$tem_ibs_ad_valorem_padrao,
    confere = igual_com_tolerancia(itens$ibs_ad_valorem_valor, soma, TOLERANCIA_DOS_VALORES),
    campo = "gIBSMonoAdValorem/gMonoPadrao/vIBSMono", no_documento = texto_do_numero(itens$ibs_ad_valorem_valor, 2),
    esperado = texto_do_numero(soma, 2), diferenca = itens$ibs_ad_valorem_valor - soma
  )
  # A quantidade de etanol anidro acima (620004) ou abaixo (620005) do percentual obrigatório.
  quantidade_calculada = quantidade_de_biocombustivel(itens)
  sem_calcular = is.na(quantidade_calculada)
  for (parte in c("ibs_ad_rem", "ibs_ad_valorem", "cbs_ad_rem", "cbs_ad_valorem")) {
    regra = switch(parte, ibs_ad_rem = "UB89a-10", ibs_ad_valorem = "UB94a-10", cbs_ad_rem = "UB99a-10",
                   cbs_ad_valorem = "UB104a-10")
    grupo = REGRAS_DOS_GRUPOS_DO_MONOFASICO$grupo[REGRAS_DOS_GRUPOS_DO_MONOFASICO$parte == parte]
    quantidade = itens[[paste0(parte, "_quantidade_biocombustivel")]]
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      regra, itens, aplica = itens[[paste0("tem_", parte, "_biocombustivel")]],
      confere = ifelse(sem_calcular, NA, igual_com_tolerancia(quantidade, quantidade_calculada, TOLERANCIA_DOS_VALORES)),
      campo = paste0(grupo, "/gpBioDiferenca/qBCBioComb"), no_documento = texto_do_numero(quantidade, 4),
      esperado = texto_do_numero(quantidade_calculada, 4), diferenca = quantidade - quantidade_calculada,
      observacao = ifelse(sem_calcular, paste(
        "Sem o percentual obrigat\u00f3rio de etanol anidro do cProdANP na data (tabela de biocombust\u00edvel), sem o pBio ou",
        "com a classifica\u00e7\u00e3o fora de 620004 e 620005: n\u00e3o d\u00e1 para calcular."
      ), NA)
    )
  }
  # O valor da diferença do biocombustível usa a alíquota ad rem do biocombustível de uma tabela que a NT diz que ainda
  # será publicada.
  for (parte in c("ibs_ad_rem", "cbs_ad_rem")) {
    regra = switch(parte, ibs_ad_rem = "UB89b-10", cbs_ad_rem = "UB99b-10")
    grupo = REGRAS_DOS_GRUPOS_DO_MONOFASICO$grupo[REGRAS_DOS_GRUPOS_DO_MONOFASICO$parte == parte]
    linhas[[length(linhas) + 1]] = linhas_da_regra(
      regra, itens, aplica = itens[[paste0("tem_", parte, "_biocombustivel")]], confere = NA,
      campo = paste0(grupo, "/gpBioDiferenca"), no_documento = "informado",
      esperado = "a quantidade vezes a al\u00edquota ad rem do biocombust\u00edvel",
      observacao = paste("A al\u00edquota ad rem do biocombust\u00edvel vem da Tabela de Combust\u00edveis Sujeitos \u00e0",
                         "Tributa\u00e7\u00e3o Monof\u00e1sica do IBS e CBS, que a NT diz que ainda ser\u00e1 publicada.")
    )
  }
  juntar_linhas(linhas)
}

# A quantidade de etanol anidro a recolher (620004) ou a ressarcir (620005), pela fórmula da NT. O pBio do XML é
# percentual (até 100) e o obrigatório da tabela é fração (0,32): o do XML vai dividido por 100.
quantidade_de_biocombustivel = function(itens) {
  obrigatoria = mistura_obrigatoria_na_data(itens$produto_anp, itens$data_emissao)
  informada = itens$percentual_biocombustivel / 100
  calculada = rep(NA_real_, nrow(itens))
  acima = itens$classificacao %in% "620004"
  abaixo = itens$classificacao %in% "620005"
  calculada[acima] = (itens$quantidade_tributavel * (informada - obrigatoria) / (1 - obrigatoria))[acima]
  calculada[abaixo] = (itens$quantidade_tributavel * (obrigatoria - informada) / (1 - obrigatoria))[abaixo]
  calculada
}

# O percentual obrigatório de etanol anidro do produto da ANP na data (a tabela de índice de biocombustível, em fração:
# 0,32 = 32%); NA para o produto fora da tabela.
mistura_obrigatoria_na_data = function(produtos, datas) {
  tabela = tabela_fiscal("biocombustivel_ibs_cbs")
  mistura = rep(NA_real_, length(produtos))
  for (numero_da_linha in seq_len(nrow(tabela))) {
    vale = !is.na(produtos) & produtos == tabela$codigo[numero_da_linha] & !is.na(datas) &
      datas >= tabela$inicio[numero_da_linha] & (is.na(tabela$fim[numero_da_linha]) | datas <= tabela$fim[numero_da_linha])
    mistura[vale] = tabela$mistura_obrigatoria[numero_da_linha]
  }
  mistura
}

# O combustível: a classificação de combustível pede o grupo comb (LA01-30); a gasolina com etanol anidro acima do
# obrigatório usa a 620004 e abaixo, a 620005 (UB14-30 e UB14-50).
conferir_o_combustivel = function(itens) {
  de_combustivel = itens$classificacao %in% "410013" | substr(itens$classificacao, 1, 3) %in% "620"
  obrigatoria = mistura_obrigatoria_na_data(itens$produto_anp, itens$data_emissao)
  informada = itens$percentual_biocombustivel / 100
  texto_da_mistura = paste0("pBio ", texto_ou_vazio(as.character(itens$percentual_biocombustivel)), "%, cProdANP ",
                            texto_ou_vazio(itens$produto_anp))
  sem_a_tabela = is.na(obrigatoria)
  observacao = ifelse(sem_a_tabela, "O cProdANP n\u00e3o est\u00e1 na tabela de biocombust\u00edvel na data de emiss\u00e3o.", NA)
  # A NT adiou as regras do monofásico (v1.35) e o reformulou na v1.50, em produção em 16/11/2026, e há NF-e autorizada
  # antes disso com a classificação 620 sem o grupo comb. Sem saber desde quando a SEFAZ aplica a LA01-30 ao
  # monofásico, a nota de antes fica sem conferir.
  monofasico_antes_do_leiaute_novo = substr(itens$classificacao, 1, 3) %in% "620" &
    (itens$data_emissao < INICIO_DO_MONOFASICO_NOVO) %in% TRUE
  combustivel_sem_saber = monofasico_antes_do_leiaute_novo & !itens$tem_combustivel
  juntar_linhas(list(
    linhas_da_regra("LA01-30", itens, aplica = de_combustivel, confere = ifelse(combustivel_sem_saber, NA, itens$tem_combustivel),
                    campo = "prod/comb", no_documento = texto_da_presenca(itens$tem_combustivel), esperado = "informado",
                    observacao = ifelse(combustivel_sem_saber, paste0(
                      "Antes de 16/11/2026 n\u00e3o d\u00e1 para saber se a SEFAZ aplicava esta regra ao monof\u00e1sico ",
                      "(cClassTrib 620): a NT adiou as regras do monof\u00e1sico (v1.35) e o reformulou na v1.50, e h\u00e1 NF-e ",
                      "autorizada sem o grupo comb."), NA)),
    linhas_da_regra("UB14-30", itens, aplica = itens$classificacao %in% "620004",
                    confere = ifelse(sem_a_tabela, NA, !is.na(informada) & informada > obrigatoria + FOLGA_DE_PONTO_FLUTUANTE),
                    campo = "prod/comb/pBio", no_documento = texto_da_mistura,
                    esperado = paste0("acima de ", texto_da_aliquota(obrigatoria * 100), "%"), observacao = observacao),
    linhas_da_regra("UB14-50", itens, aplica = itens$classificacao %in% "620005",
                    confere = ifelse(sem_a_tabela, NA, !is.na(informada) & informada < obrigatoria - FOLGA_DE_PONTO_FLUTUANTE),
                    campo = "prod/comb/pBio", no_documento = texto_da_mistura,
                    esperado = paste0("abaixo de ", texto_da_aliquota(obrigatoria * 100), "%"), observacao = observacao)
  ))
}
