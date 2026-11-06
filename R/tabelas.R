# Tabelas fiscais: as cópias das fontes oficiais que vão dentro do pacote (inst/extdata/tabelas),
# geradas por ferramentas/gerar_tabelas.R.

NOMES_DAS_TABELAS = c(
  "cfop", "ncm", "origem", "cst_icms", "csosn", "cst_ipi", "cst_pis", "cst_cofins", "cest", "cst_ibs_cbs",
  "classificacao_ibs_cbs", "credito_presumido_ibs_cbs", "mudancas_ibs_cbs", "aliquotas_ibs_cbs",
  "local_operacao_ibs_cbs", "biocombustivel_ibs_cbs", "combustiveis_monofasicos", "meios_pagamento", "bandeiras_cartao",
  "municipios", "codigos_dos_campos", "leiaute_efd_icms_ipi", "fontes"
)
COLUNAS_DE_DATA = c("inicio", "fim", "data_da_versao", "baixada_em", "publicada_em", "em_producao_ate", "inicio_cbs",
                    "fim_cbs", "inicio_ibs", "fim_ibs")
COLUNAS_DE_INDICADOR = c(
  "comunicacao", "transporte", "devolucao", "retorno", "anulacao", "remessa", "combustivel", "exclusivo_ibs_cbs",
  # O CST do IBS e da CBS: 1 = o grupo é exigido, 0 = não é permitido.
  "grupo_ibs_cbs", "grupo_monofasico", "grupo_reducao", "grupo_diferimento", "grupo_transferencia_credito",
  "grupo_credito_presumido_zfm", "grupo_ajuste_competencia", "redutor_base_calculo",
  # A classificação do IBS e da CBS: os grupos, como no CST, e os documentos em que ela pode ser usada.
  "grupo_tributacao_regular", "grupo_credito_presumido", "grupo_monofasico_padrao", "grupo_monofasico_retencao",
  "grupo_monofasico_retido", "grupo_diferenca_biocombustivel", "grupo_estorno_credito",
  "permitido_na_nfe", "permitido_na_nfce", "permitido_na_nfe_abi", "permitido_no_cte", "permitido_no_cte_os",
  "permitido_no_bpe", "permitido_no_bpe_ta", "permitido_no_bpe_tm", "permitido_na_nf3e", "permitido_na_nfse",
  "permitido_na_nfse_via", "permitido_na_nfcom", "permitido_na_nfag", "permitido_na_nfgas", "permitido_na_dere",
  "permitido_na_dir", "permitido_na_duimp",
  # O crédito presumido: como se apropria, se deduz do tributo do item, os grupos que exige ou não permite.
  "apropria_no_documento", "apropria_por_evento", "deduz_do_tributo", "grupo_credito_cbs", "grupo_credito_ibs",
  "declaracao_pagamento",
  # O combustível do ICMS monofásico que pede o pBio.
  "exige_pbio"
)
COLUNAS_DE_NUMERO = c("reducao_ibs", "reducao_cbs", "aliquota_ibs_uf", "aliquota_ibs_municipio", "aliquota_cbs",
                      "mistura_obrigatoria", "aliquota_ad_rem_icms", "nivel")
# Cada tabela é lida do disco uma vez por sessão.
tabelas_ja_lidas = new.env(parent = emptyenv())
# As tabelas que tabelas_atualizar() baixa: as fiscais e os endereços da SEFAZ. Vêm do ramo main do repositório, onde
# só entram depois de uma pessoa conferir o que o robô semanal achou nas fontes oficiais.
TABELAS_QUE_SE_ATUALIZAM = c(NOMES_DAS_TABELAS, "servicos_sefaz", "autorizadores_sefaz")
ENDERECO_DAS_TABELAS_NO_REPOSITORIO = "https://raw.githubusercontent.com/biuspoly/RNFe/main/inst/extdata/tabelas/"
# A lista de conferência: de cada tabela, as linhas e a soma de conferência (md5) do arquivo, e a versão do conjunto (a
# data e a hora, em UTC, em que alguma tabela mudou). Vai no pacote e no repositório; quem grava é
# ferramentas/gerar_conferencia_das_tabelas.R.
ARQUIVO_DA_CONFERENCIA = "conferencia.csv"
COLUNAS_DA_CONFERENCIA = c("tabela", "linhas", "md5", "versao_do_conjunto")

#' Tabelas fiscais: CFOP, NCM, CSTs, IBS e CBS, pagamentos, municípios e o significado de cada código
#'
#' Devolve uma tabela de códigos dos documentos fiscais, copiada da fonte
#' oficial. Escolha pelo nome: `"cfop"`, `"ncm"`, `"origem"`, `"cst_icms"`,
#' `"csosn"`, `"cst_ipi"`, `"cst_pis"`, `"cst_cofins"`, `"cest"`, `"cst_ibs_cbs"`,
#' `"classificacao_ibs_cbs"`, `"credito_presumido_ibs_cbs"`, `"mudancas_ibs_cbs"`, `"aliquotas_ibs_cbs"`,
#' `"local_operacao_ibs_cbs"`, `"biocombustivel_ibs_cbs"`, `"combustiveis_monofasicos"`,
#' `"meios_pagamento"`, `"bandeiras_cartao"`,
#' `"municipios"`, `"codigos_dos_campos"` (o que quer dizer cada código dos
#' campos dos documentos) ou `"fontes"` (de onde veio cada uma, com a data).
#' A maioria das tabelas de códigos traz o `codigo`, a descrição e a vigência:
#' `inicio` (desde quando vale) e `fim` (até quando valeu, vazio quando ainda
#' vale). Um código que mudou de descrição tem uma linha por período. As que
#' fogem disso estão na descrição de cada uma, abaixo: o CSOSN, o CST do IBS e
#' da CBS e os municípios têm as colunas vazias (a fonte não data), o crédito
#' presumido tem a vigência na CBS e no IBS, as mudanças têm a versão e o
#' prazo, as alíquotas não têm código e o local da operação não tem datas.
#'
#' O que cada tabela tem:
#' - `"cfop"`: os CFOP aceitos hoje na NF-e, com o `titulo` e a
#'   `nota_explicativa` literais do Anexo II do Convênio SINIEF s/nº de 1970 e
#'   os indicadores da tabela da NF-e (1 = sim): `permitido_na_nfe`,
#'   `comunicacao`, `transporte`, `devolucao`, `retorno`, `anulacao`,
#'   `remessa`, `combustivel` (0, 1 ou 2, como na tabela oficial) e
#'   `exclusivo_ibs_cbs`. A tabela oficial só traz os códigos vigentes: um CFOP
#'   revogado não está nela.
#' - `"ncm"`: a nomenclatura vigente, em todos os níveis (capítulo, posição,
#'   subposição, item e subitem), com o código sem os pontos, como na NF-e, e o
#'   ato que criou cada linha (`ato_inicio`). Ao ler, ganha a
#'   `descricao_completa`, que junta a descrição da posição com a de cada nível
#'   abaixo dela (sozinho, o subitem costuma dizer só "-- Outros"). Só traz os
#'   códigos vigentes, desde a versão atual da NCM (01/04/2022).
#' - `"origem"`: a origem da mercadoria (o primeiro dígito do CST do ICMS). Os
#'   códigos 0 a 2 mudaram de descrição em 2013, quando vieram os de 3 a 8.
#' - `"cst_icms"`: o CST do ICMS, de dois dígitos, como vai na NF-e.
#' - `"csosn"`: o código do Simples Nacional, sem datas (veja abaixo).
#' - `"cst_ipi"`, `"cst_pis"` e `"cst_cofins"`: o CST de cada um.
#' - `"cest"`: o Código Especificador da Substituição Tributária, da
#'   tabela externa 996 do SPED, com a vigência de cada código. As descrições
#'   vão até 31/08/2023; desde 01/09/2023 o SPED só diz para conferir a
#'   descrição vigente no Convênio ICMS 142/18, e essa é a descrição que a
#'   tabela traz para esse período (o texto do Convênio no Confaz tem códigos
#'   com mais de uma redação atual, e não entrou).
#' - `"cst_ibs_cbs"`: o CST do IBS e da CBS (Reforma Tributária), com os
#'   indicadores dos grupos que cada CST exige (1) ou não permite (0) no
#'   documento, com o nome oficial entre parênteses: `grupo_ibs_cbs`
#'   (`ind_gIBSCBS`), `grupo_monofasico` (`ind_gIBSCBSMono`), `grupo_reducao`
#'   (`ind_gRed`), `grupo_diferimento` (`ind_gDif`),
#'   `grupo_transferencia_credito` (`ind_gTransfCred`),
#'   `grupo_credito_presumido_zfm` (`ind_gCredPresIBSZFM`),
#'   `grupo_ajuste_competencia` (`ind_gAjusteCompet`) e `redutor_base_calculo`
#'   (`ind_RedutorBC`). São os indicadores que as regras de validação da NT
#'   2025.002 consultam. O `inicio` e o `fim` ficam vazios: a planilha não
#'   data o CST (o que mudou de uma versão para outra está nas mudanças).
#' - `"classificacao_ibs_cbs"`: a classificação tributária do IBS e da CBS
#'   (`cClassTrib`), com o `cst` dela, o `nome`, a `descricao`, o artigo da LC
#'   214/2025 (`artigo_lc_214`), o `tipo_aliquota`, os percentuais de redução
#'   (`reducao_ibs` e `reducao_cbs`); os indicadores dos grupos, como no CST:
#'   `grupo_tributacao_regular` (`ind_gTribRegular`), `grupo_credito_presumido`
#'   (`ind_gCredPresOper`), `grupo_monofasico_padrao` (`ind_gMonoPadrao`),
#'   `grupo_monofasico_retencao` (`ind_gMonoReten`), `grupo_monofasico_retido`
#'   (`ind_gMonoRet`), `grupo_diferenca_biocombustivel` (`ind_gpBioDiferenca`) e
#'   `grupo_estorno_credito` (`ind_gEstornoCred`); os documentos em que ela pode
#'   ser usada (1 = pode): `permitido_na_nfe`, `permitido_na_nfce`,
#'   `permitido_na_nfe_abi`, `permitido_no_cte`, `permitido_no_cte_os`,
#'   `permitido_no_bpe`, `permitido_no_bpe_ta`, `permitido_no_bpe_tm`,
#'   `permitido_na_nf3e`, `permitido_na_nfse`, `permitido_na_nfse_via`,
#'   `permitido_na_nfcom`, `permitido_na_nfag`, `permitido_na_nfgas`,
#'   `permitido_na_dere`, `permitido_na_dir` e `permitido_na_duimp` (da coluna
#'   `ind` de cada um na planilha); o tipo de receita bruta do Simples Nacional
#'   (`tipo_receita_simples`, o `tpRBSN`) e o uso do indicador de doação
#'   (`doacao`, o `tpDoacao`), cada um com a `_descricao` das abas da planilha.
#' - `"credito_presumido_ibs_cbs"`: o código de classificação do crédito
#'   presumido do IBS e da CBS (`cCredPres`, com dois dígitos, como no XML), a
#'   `descricao`, o `texto_da_lc_214`; como ele se apropria
#'   (`apropria_no_documento` e `apropria_por_evento`), se o crédito é
#'   descontado do IBS do item (`deduz_do_tributo`, o `indDeduzCredPres`) e os
#'   grupos que exige (1) ou não permite (0) no documento: `grupo_credito_cbs`
#'   (`ind_gCBSCredPres`) e `grupo_credito_ibs` (`ind_gIBSCredPres`); a
#'   `declaracao_pagamento` (`indDecPag`) e os documentos em que vale
#'   (`permitido_na_nfe`, `permitido_na_nfce`, `permitido_no_cte` e
#'   `permitido_na_nfse`); as orientações da planilha, em texto
#'   (`orientacao_aliquota_cbs`, `orientacao_aliquota_ibs`,
#'   `orientacao_percentual_cbs`, `orientacao_percentual_ibs`,
#'   `orientacao_reducao_transicao_ibs` e
#'   `orientacao_classificacao_referenciada`); e a vigência na CBS e no IBS
#'   (`inicio_cbs`, `fim_cbs`, `inicio_ibs` e `fim_ibs`).
#' - `"mudancas_ibs_cbs"`: o que mudou nas tabelas acima de uma versão
#'   publicada para a seguinte, desde a 1.20 (a que estava publicada quando as
#'   regras de validação entraram em produção, em 10/11/2025): a `tabela`
#'   (`"cst_ibs_cbs"`, `"classificacao_ibs_cbs"` ou
#'   `"credito_presumido_ibs_cbs"`), o `codigo`, a `coluna` (o
#'   nome da coluna na tabela, ou `"existe"` para o código que entrou ou saiu),
#'   o valor de `antes` e o de `depois`, a `versao` do Informe Técnico
#'   2025.002, a data em que foi `publicada_em` e o prazo em que ficou
#'   `em_producao_ate` (o do controle de versões do IT). Da 1.21 à 1.40 o IT
#'   não dá prazo: vale o da versão mais nova que ainda traz o mesmo valor
#'   (hoje, a 1.71: 30/10/2026), porque o da primeira com prazo não serviu (a
#'   SEFAZ autorizou NF-e com a classificação 200001, que a 1.40 tirou da
#'   NF-e, depois do prazo da 1.50); quando sai uma versão nova com prazo que
#'   ainda traz o valor, o prazo passa a ser o dela. A mudança que outra
#'   versão desfez vale até o prazo de quem a desfez. É o que o
#'   [ibs_cbs_conferir()] consulta para uma nota emitida antes de uma mudança,
#'   que a SEFAZ conferiu pela versão da época.
#' - `"aliquotas_ibs_cbs"`: as alíquotas do IBS (da UF e do município) e da
#'   CBS de cada período, em percentual, com a `base_legal` e a `observacao`:
#'   0,1% de IBS da UF e 0,9% de CBS em 2026 (LC 214/2025, arts. 343 e 346; a
#'   NT 2025.002 aceita as mesmas em 2025), 0,05% de IBS da UF e 0,05% do
#'   município em 2027 e 2028 (art. 344). A CBS de 2027 e 2028 é a alíquota
#'   de referência fixada pelo Senado (art. 349) menos 0,1 ponto percentual
#'   (art. 347) e fica vazia enquanto não for publicada. A tabela vai até 2028:
#'   as alíquotas de 2029 em diante ainda serão publicadas. Sem `codigo`: uma
#'   linha por período (`inicio` e `fim`).
#' - `"local_operacao_ibs_cbs"`: o código indicador do local da operação
#'   (`cIndOp`, art. 11 da LC 214/2025), do Anexo VII da documentação da NFS-e
#'   Nacional: o `codigo`, o `tipo_operacao`, a `caracteristica` do
#'   fornecimento, o `local` que o documento identifica, o
#'   `dispositivo_lc_214`, a `observacao`, os documentos em que vale
#'   (`permitido_na_nfe`, `permitido_na_nfse`, `permitido_na_nfse_via`) e o
#'   `local_incidencia_nfse`. Sem datas: o anexo só traz a versão de hoje.
#' - `"biocombustivel_ibs_cbs"`: o percentual obrigatório de etanol anidro
#'   em cada gasolina C (`mistura_obrigatoria`, em fração: 0,32 = 32%), pelo
#'   código do produto da ANP (`codigo`, o `cProdANP`), com a vigência (a
#'   Tabela de Código de Índice de Biocombustível, Informe Técnico 2025.004).
#' - `"combustiveis_monofasicos"`: os combustíveis sujeitos à tributação
#'   monofásica do ICMS, pelo código do produto da ANP, com a
#'   `aliquota_ad_rem_icms` de cada período, se pedem o pBio (`exige_pbio`), a
#'   `origem_combustivel` e a `unidade_tributavel`.
#' - `"meios_pagamento"`: os meios de pagamento da tabela do Portal da NF-e
#'   (dinheiro, cartão, boleto, PIX...), com a `observacao` de quando usar
#'   cada um. É o código do `tPag` da NF-e e do meio de pagamento vinculado da
#'   Reforma (`tpMeioPgto`).
#' - `"bandeiras_cartao"`: as bandeiras de cartão de crédito e débito da
#'   tabela do Portal da NF-e (o `tBand`).
#' - `"codigos_dos_campos"`: o que quer dizer cada código dos campos dos
#'   documentos que não têm tabela própria (forma de emissão, finalidade,
#'   modal, tipo de carga, regime do Simples Nacional...): `documento`
#'   (`"NF-e"`, `"CT-e"`, `"GTV-e"`, `"MDF-e"`, `"NFS-e"` ou `"evento"`; o CT-e
#'   OS e o CT-e simplificado usam os do `"CT-e"`), `campo` (o nome no leiaute,
#'   como `tpEmis`), `contexto` (quando o significado depende de outra coisa: o
#'   modelo do CT-e, o tipo do CT-e ou o grupo do documento), `codigo` e
#'   `descricao`. Os textos vêm da documentação dos schemas oficiais; os
#'   leitores os põem ao lado de cada coluna de código (`*_descricao`).
#' - `"municipios"`: os municípios vigentes do IBGE, com o `codigo` de 7
#'   dígitos que vai nos documentos (`cMun`, `cMunFG`, `cLocIncid`...), o `nome`,
#'   a `uf` e o `codigo_uf` (o que abre a chave de acesso). Sem datas: o IBGE só
#'   publica a lista de hoje. O código 9999999, que a NF-e usa para o exterior,
#'   não é do IBGE e não está nela.
#' - `"leiaute_efd_icms_ipi"`: os registros e os campos da EFD ICMS/IPI (o
#'   SPED Fiscal), que o [efd_icms_ipi_ler()] usa: o `registro`, a vigência
#'   (`inicio` e `fim`: o campo que entrou depois tem o `inicio`; o E310 e o
#'   C177 antigos, que mudaram inteiros, têm o `fim`), o `nivel` na hierarquia
#'   do arquivo, o `numero` do campo, o `campo` (o nome do leiaute), a `coluna`
#'   (o nome na leitura: o mesmo, com o número do campo quando o nome se repete
#'   no registro), o `tipo` (`"C"` texto, `"N"` número), o `tamanho` (com `*`
#'   quando é exato) e as `decimais`, e a `descricao`. Do Guia Prático e da
#'   Nota Técnica do leiaute, conferidos um contra o outro; quando os dois
#'   discordam, vale o Guia, o mais novo. Sem `codigo`: uma linha por campo.
#' - `"fontes"`: de onde veio cada tabela, com a versão e o dia em que foi
#'   baixada.
#'
#' As tabelas vêm dentro do pacote. Para usar as mais novas sem esperar uma
#' versão nova, chame [tabelas_atualizar()]: a partir daí, elas vêm da cópia
#' baixada do repositório do RNFe.
#'
#' As tabelas do SPED começam em 2009, quando o SPED Fiscal começou: uma nota
#' mais antiga fica sem a descrição, em vez de receber uma que talvez não fosse
#' a da época. O CSOSN não tem datas porque as do SPED não servem para a NF-e:
#' lá o CSOSN e o CST dividem o mesmo campo, e o SPED encerrou o 300, o 400 e o
#' 500 em 2012 e o 102 e o 202 em 2023 só porque passaram a coincidir com CSTs
#' novos; na NF-e eles continuam aceitos.
#'
#' @param nome_da_tabela Qual tabela: `"cfop"` (CFOP), `"ncm"` (NCM),
#'   `"origem"` (origem da mercadoria), `"cst_icms"` (CST do ICMS), `"csosn"`
#'   (CSOSN, do Simples Nacional), `"cst_ipi"`, `"cst_pis"`, `"cst_cofins"`,
#'   `"cest"` (CEST),
#'   `"cst_ibs_cbs"` (CST do IBS e da CBS), `"classificacao_ibs_cbs"`
#'   (cClassTrib da Reforma), `"credito_presumido_ibs_cbs"` (cCredPres),
#'   `"mudancas_ibs_cbs"` (o que mudou nessas três de uma versão para a
#'   outra), `"aliquotas_ibs_cbs"` (as alíquotas de cada
#'   ano), `"local_operacao_ibs_cbs"` (cIndOp), `"biocombustivel_ibs_cbs"` (o
#'   etanol anidro obrigatório na gasolina C), `"combustiveis_monofasicos"` (os
#'   do ICMS monofásico), `"meios_pagamento"` (dinheiro, cartão, PIX...),
#'   `"bandeiras_cartao"`, `"municipios"` (código IBGE, nome e UF),
#'   `"codigos_dos_campos"` (o significado dos códigos dos documentos),
#'   `"leiaute_efd_icms_ipi"` (os registros e os campos do SPED Fiscal) ou
#'   `"fontes"` (de onde veio cada tabela).
#' @return Um `data.frame`. Na maioria, com `codigo`, a descrição (`titulo` e
#'   `nota_explicativa` no CFOP, `nome` nos municípios, `descricao` nas
#'   outras), `inicio` e `fim`; as colunas de cada uma estão acima.
#' @source CFOP: a Tabela de CFOP do Portal Nacional da NF-e (Informe Técnico
#'   2023.002, publicada em 04/09/2026). IBS e CBS: a Tabela de Classificação
#'   Tributária do Portal da NF-e (Informe Técnico 2025.002, publicada em
#'   30/10/2026) e a de Crédito Presumido (publicada em 01/10/2026), e as
#'   versões delas publicadas desde 03/10/2025 para as mudanças, com os prazos
#'   de produção do IT 2025.002 v1.71; o cIndOp, do Anexo VII da NFS-e Nacional
#'   (Portal da NFS-e, v1.03.00); o etanol anidro obrigatório, da Tabela de
#'   Índice de Biocombustível (IT 2025.004, publicada em 25/08/2026); os
#'   combustíveis do ICMS monofásico, da tabela do Portal da NF-e (publicada em
#'   05/12/2025); as alíquotas, da LC 214/2025 (texto do Planalto) e da NT
#'   2025.002-RTC v1.53 (Portal da NF-e, 30/10/2026). NCM: a nomenclatura vigente do Portal Único Siscomex
#'   (30/10/2026). Municípios: a API de localidades do IBGE
#'   (servicodados.ibge.gov.br, 30/10/2026). Meios de pagamento e bandeiras de
#'   cartão: as tabelas do Portal da NF-e (publicadas em 06/03/2026 e
#'   16/03/2021). Códigos dos campos: a documentação dos schemas oficiais que os
#'   leitores seguem, conferida por `ferramentas/conferir_codigos_dos_campos.R`;
#'   o tipo de transportador do MDF-e, pela Lei 11.442/2007 (art. 2º), e a
#'   tributação do ISSQN da NFS-e (`tribISSQN`), pelo Anexo I do leiaute da
#'   NFS-e Nacional, que corrige a ordem errada da documentação do schema 1.00.
#'   Origem, CSTs do ICMS, do IPI, do PIS e da COFINS e o CEST: as tabelas
#'   externas do SPED Fiscal (Receita Federal), cada uma na versão que o SPED
#'   publica (a do CEST é a 18, de 03/10/2024), com a origem 8 e os CST de
#'   combustível monofásico (de 2023) tirados da tabela de CST de três dígitos,
#'   porque as tabelas A e B do SPED não foram atualizadas. A versão e a data de
#'   cada uma estão em `tabela_fiscal("fontes")`.
#' @examples
#' tabela_fiscal("cst_icms")
#' cfop = tabela_fiscal("cfop")
#' cfop[cfop$codigo == "5102", c("codigo", "titulo")]
#' tabela_fiscal("fontes")
#' @export
tabela_fiscal = function(nome_da_tabela) {
  if (length(nome_da_tabela) != 1 || !(nome_da_tabela %in% NOMES_DAS_TABELAS)) {
    stop(
      "Tabela desconhecida: ", paste(nome_da_tabela, collapse = ", "), ". As tabelas s\u00e3o: ",
      paste(NOMES_DAS_TABELAS, collapse = ", "),
      call. = FALSE
    )
  }
  if (is.null(tabelas_ja_lidas[[nome_da_tabela]])) {
    tabelas_ja_lidas[[nome_da_tabela]] = ler_tabela_do_pacote(nome_da_tabela)
  }
  tabelas_ja_lidas[[nome_da_tabela]]
}

ler_tabela_do_pacote = function(nome_da_tabela) {
  ler_tabela_csv(arquivo_da_tabela(nome_da_tabela), nome_da_tabela)
}

ler_tabela_csv = function(arquivo_csv, nome_da_tabela) {
  tabela_lida = utils::read.csv(arquivo_csv, colClasses = "character", fileEncoding = "UTF-8", na.strings = "")
  for (nome_da_coluna in names(tabela_lida)) {
    if (nome_da_coluna %in% COLUNAS_DE_DATA) {
      tabela_lida[[nome_da_coluna]] = as.Date(tabela_lida[[nome_da_coluna]])
    } else if (nome_da_coluna %in% COLUNAS_DE_INDICADOR) {
      tabela_lida[[nome_da_coluna]] = as.integer(tabela_lida[[nome_da_coluna]])
    } else if (nome_da_coluna %in% COLUNAS_DE_NUMERO) {
      tabela_lida[[nome_da_coluna]] = as.numeric(tabela_lida[[nome_da_coluna]])
    }
  }
  if (nome_da_tabela == "ncm") {
    tabela_lida$descricao_completa = descricao_completa_do_ncm(tabela_lida)
  }
  tabela_lida
}

# O arquivo da tabela: o que tabelas_atualizar() baixou, quando o conjunto baixado é mais novo que o do pacote e a
# tabela tem as mesmas colunas que a do pacote; senão, o do pacote. Quem instala um pacote com tabelas mais novas que
# as baixadas volta a ter as dele.
arquivo_da_tabela = function(nome_da_tabela) {
  do_pacote = system.file("extdata", "tabelas", paste0(nome_da_tabela, ".csv"), package = "RNFe")
  if (usar_as_tabelas_baixadas()) {
    baixado = file.path(pasta_das_tabelas_baixadas(), paste0(nome_da_tabela, ".csv"))
    if (file.exists(baixado) && identical(primeira_linha(baixado), primeira_linha(do_pacote))) {
      return(baixado)
    }
  }
  do_pacote
}

# A escolha vale para a sessão inteira (até a próxima chamada de tabelas_atualizar()): é feita uma vez, pela versão do
# conjunto gravada na lista de conferência de cada lado, e não pela data dos arquivos, que muda a cada instalação.
usar_as_tabelas_baixadas = function() {
  if (is.null(tabelas_ja_lidas[["usar_as_baixadas"]])) {
    versao_baixada = versao_da_conferencia(file.path(pasta_das_tabelas_baixadas(), ARQUIVO_DA_CONFERENCIA))
    versao_do_pacote = versao_da_conferencia(arquivo_da_conferencia_do_pacote())
    tabelas_ja_lidas[["usar_as_baixadas"]] = !is.na(versao_baixada) && !is.na(versao_do_pacote) &&
      versao_baixada > versao_do_pacote
  }
  tabelas_ja_lidas[["usar_as_baixadas"]]
}

arquivo_da_conferencia_do_pacote = function() {
  system.file("extdata", "tabelas", ARQUIVO_DA_CONFERENCIA, package = "RNFe")
}

pasta_das_tabelas_baixadas = function() {
  file.path(tools::R_user_dir("RNFe", which = "cache"), "tabelas")
}

primeira_linha = function(arquivo) {
  readLines(arquivo, n = 1, warn = FALSE, encoding = "UTF-8")
}

# A versão do conjunto de uma lista de conferência; NA quando ela não existe ou não está no formato.
versao_da_conferencia = function(arquivo) {
  conferencia = ler_conferencia(arquivo)
  if (is.null(conferencia)) {
    return(NA_character_)
  }
  conferencia$versao_do_conjunto[1]
}

# A lista de conferência lida, ou NULL quando o arquivo não existe, não abre (um aviso da leitura conta como erro) ou
# não tem as colunas, uma versão só e a versão no formato "AAAA-MM-DD HH:MM:SS".
ler_conferencia = function(arquivo) {
  if (!nzchar(arquivo) || !file.exists(arquivo)) {
    return(NULL)
  }
  conferencia = tryCatch(
    withCallingHandlers(
      utils::read.csv(arquivo, colClasses = "character", fileEncoding = "UTF-8", na.strings = ""),
      warning = function(aviso) stop(conditionMessage(aviso), call. = FALSE)
    ),
    error = function(erro) NULL
  )
  formato_certo = !is.null(conferencia) && identical(names(conferencia), COLUNAS_DA_CONFERENCIA) &&
    nrow(conferencia) > 0 && !anyNA(conferencia) && length(unique(conferencia$versao_do_conjunto)) == 1 &&
    grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$", conferencia$versao_do_conjunto[1])
  if (!formato_certo) {
    return(NULL)
  }
  conferencia
}

#' Atualizar as tabelas fiscais pelo repositório do RNFe
#'
#' Baixa as tabelas fiscais (as de [tabela_fiscal()]) e os endereços da SEFAZ
#' do repositório do RNFe no GitHub e passa a usá-las no lugar das que vieram
#' no pacote. Lá, um robô confere toda semana as fontes oficiais (o Portal da
#' NF-e, o SPED, o Siscomex, o IBGE), e uma pessoa junta ao repositório o que
#' mudou depois de conferir: assim as tabelas ficam em dia sem esperar uma
#' versão nova do pacote.
#'
#' Nada é baixado sem esta função ser chamada. Primeiro vem a lista de
#' conferência do repositório, com a soma de conferência (md5) e o número de
#' linhas de cada tabela e a versão do conjunto. Quando o pacote instalado já
#' tem esse conjunto (ou um mais novo), nada mais é baixado. Senão, cada tabela
#' baixada tem de conferir com a lista, abrir sem erro e ter as mesmas colunas
#' que a do pacote; se o formato mudou, o resultado diz que é preciso atualizar
#' o pacote. **As tabelas são trocadas todas juntas ou nenhuma:** se uma der
#' problema, ficam as que estavam em uso, para nunca misturar tabelas de
#' origens diferentes.
#'
#' As tabelas baixadas ficam na pasta de cache do R para o RNFe
#' ([tools::R_user_dir()]) e valem para as próximas sessões também, enquanto
#' forem mais novas que as do pacote instalado (pela versão do conjunto, não
#' pela data dos arquivos). Quem instala uma versão do pacote com tabelas mais
#' novas volta a ter as dele.
#'
#' Precisa do pacote `httr2`.
#'
#' @param usar_as_do_pacote `TRUE` apaga as tabelas baixadas e volta a usar as
#'   que vieram no pacote, sem baixar nada.
#' @return Um `data.frame` com uma linha por tabela: `tabela`,
#'   `linhas_antes` (as da tabela em uso antes de baixar), `linhas_agora` (as
#'   da tabela em uso depois), `mudou` (`TRUE` quando a tabela em uso agora é
#'   diferente da de antes) e `problema` (por que as tabelas não foram
#'   trocadas; vazio quando foram). Com `usar_as_do_pacote = TRUE`, nada
#'   (invisível); dá erro se não conseguir apagar a pasta (um arquivo aberto
#'   por outro programa, no Windows).
#' @seealso [tabela_fiscal()]
#' @examples
#' \dontrun{
#' atualizacao = tabelas_atualizar()
#' atualizacao[atualizacao$mudou, ]
#' tabela_fiscal("fontes")   # de onde veio e quando foi baixada cada tabela
#' tabelas_atualizar(usar_as_do_pacote = TRUE)   # volta às do pacote
#' }
#' @export
tabelas_atualizar = function(usar_as_do_pacote = FALSE) {
  if (!isTRUE(usar_as_do_pacote) && !isFALSE(usar_as_do_pacote)) {
    stop("Informe usar_as_do_pacote = TRUE ou FALSE.", call. = FALSE)
  }
  pasta = pasta_das_tabelas_baixadas()
  # Dê certo ou não, a próxima leitura de cada tabela, e a escolha entre as baixadas e as do pacote, voltam ao disco.
  on.exit(rm(list = ls(tabelas_ja_lidas), envir = tabelas_ja_lidas), add = TRUE)
  if (usar_as_do_pacote) {
    if (!apagar_pasta(pasta)) {
      stop("N\u00e3o deu para apagar as tabelas baixadas (algum arquivo aberto por outro programa?): ", pasta, call. = FALSE)
    }
    return(invisible(NULL))
  }
  exigir_pacotes("httr2")

  arquivos_em_uso = vapply(TABELAS_QUE_SE_ATUALIZAM, arquivo_da_tabela, character(1), USE.NAMES = FALSE)
  md5_em_uso = unname(tools::md5sum(arquivos_em_uso))
  linhas_em_uso = vapply(arquivos_em_uso, contar_linhas_da_tabela, integer(1), USE.NAMES = FALSE)
  resultado = data.frame(tabela = TABELAS_QUE_SE_ATUALIZAM, linhas_antes = linhas_em_uso, linhas_agora = linhas_em_uso,
                         mudou = FALSE, problema = NA_character_)

  # Tudo é baixado numa pasta ao lado, e só ela inteira entra no lugar da pasta em uso.
  preparada = paste0(pasta, "_preparando")
  if (!apagar_pasta(preparada)) {
    resultado$problema = paste("n\u00e3o deu para apagar a pasta de uma atualiza\u00e7\u00e3o anterior:", preparada)
    return(resultado)
  }
  dir.create(preparada, recursive = TRUE, showWarnings = FALSE)
  on.exit(apagar_pasta(preparada), add = TRUE)

  problema_da_conferencia = baixar_do_repositorio(ARQUIVO_DA_CONFERENCIA, preparada)
  conferencia = ler_conferencia(file.path(preparada, ARQUIVO_DA_CONFERENCIA))
  if (is.na(problema_da_conferencia) && is.null(conferencia)) {
    problema_da_conferencia = "veio fora do formato"
  }
  if (!is.na(problema_da_conferencia)) {
    resultado$problema = paste("a lista de confer\u00eancia do reposit\u00f3rio", problema_da_conferencia)
    return(resultado)
  }
  versao_do_pacote = versao_da_conferencia(arquivo_da_conferencia_do_pacote())
  if (!is.na(versao_do_pacote) && conferencia$versao_do_conjunto[1] <= versao_do_pacote) {
    # O pacote instalado já tem estas tabelas, ou mais novas: as baixadas antes, se houver, não servem mais.
    apagar_pasta(pasta)
    tabelas_ja_lidas[["usar_as_baixadas"]] = NULL
    arquivos_do_pacote = vapply(TABELAS_QUE_SE_ATUALIZAM, arquivo_da_tabela, character(1), USE.NAMES = FALSE)
    resultado$linhas_agora = vapply(arquivos_do_pacote, contar_linhas_da_tabela, integer(1), USE.NAMES = FALSE)
    resultado$mudou = unname(tools::md5sum(arquivos_do_pacote)) != md5_em_uso
    return(resultado)
  }

  for (posicao in seq_along(TABELAS_QUE_SE_ATUALIZAM)) {
    conferida = tryCatch(
      baixar_e_conferir_tabela(TABELAS_QUE_SE_ATUALIZAM[posicao], preparada, conferencia),
      error = function(erro) list(problema = paste("erro:", conditionMessage(erro)), linhas = NA_integer_)
    )
    resultado$problema[posicao] = conferida$problema
    resultado$linhas_agora[posicao] = conferida$linhas
  }
  if (any(!is.na(resultado$problema))) {
    resultado$problema[is.na(resultado$problema)] = paste(
      "n\u00e3o trocada: as tabelas s\u00f3 s\u00e3o trocadas todas juntas, e outra deu problema"
    )
    resultado$linhas_agora = resultado$linhas_antes
    return(resultado)
  }
  problema_da_troca = trocar_a_pasta(preparada, pasta)
  if (!is.na(problema_da_troca)) {
    resultado$problema = problema_da_troca
    resultado$linhas_agora = resultado$linhas_antes
    return(resultado)
  }
  md5_agora = unname(tools::md5sum(file.path(pasta, paste0(TABELAS_QUE_SE_ATUALIZAM, ".csv"))))
  resultado$mudou = md5_agora != md5_em_uso
  resultado
}

contar_linhas_da_tabela = function(arquivo_csv) {
  nrow(utils::read.csv(arquivo_csv, colClasses = "character", fileEncoding = "UTF-8", na.strings = ""))
}

# Baixa um arquivo do repositório para a pasta. Devolve NA quando deu certo, ou o problema.
baixar_do_repositorio = function(nome_do_arquivo, pasta) {
  pedido = httr2::request(paste0(ENDERECO_DAS_TABELAS_NO_REPOSITORIO, nome_do_arquivo))
  pedido = httr2::req_user_agent(pedido, "RNFe (https://github.com/biuspoly/RNFe)")
  pedido = httr2::req_timeout(pedido, 120)
  pedido = httr2::req_error(pedido, is_error = function(resposta) FALSE)
  resposta = tryCatch(httr2::req_perform(pedido), error = function(erro) erro)
  if (inherits(resposta, "error")) {
    return(paste("n\u00e3o baixou:", gsub("\\s+", " ", conditionMessage(resposta))))
  }
  if (httr2::resp_status(resposta) != 200) {
    return(paste("n\u00e3o baixou: HTTP", httr2::resp_status(resposta)))
  }
  corpo = raw(0)
  if (httr2::resp_has_body(resposta)) {
    corpo = httr2::resp_body_raw(resposta)
  }
  if (length(corpo) == 0) {
    return("veio vazia")
  }
  primeiro_caractere = corpo[!(corpo %in% charToRaw(" \t\r\n"))][1]
  if (identical(primeiro_caractere, charToRaw("<"))) {
    return("veio como p\u00e1gina da web, n\u00e3o como tabela (algum proxy ou portal de rede no caminho?)")
  }
  writeBin(corpo, file.path(pasta, nome_do_arquivo))
  NA_character_
}

# Baixa uma tabela e confere: a soma de conferência e o número de linhas da lista, as colunas da do pacote e a leitura
# sem erro nem aviso (como o pacote vai ler). Devolve o problema (NA quando deu certo) e as linhas.
baixar_e_conferir_tabela = function(nome_da_tabela, pasta, conferencia) {
  sem_linhas = NA_integer_
  da_conferencia = conferencia[conferencia$tabela == nome_da_tabela, ]
  if (nrow(da_conferencia) != 1) {
    return(list(problema = "a lista de confer\u00eancia do reposit\u00f3rio n\u00e3o traz esta tabela", linhas = sem_linhas))
  }
  nome_do_arquivo = paste0(nome_da_tabela, ".csv")
  problema = baixar_do_repositorio(nome_do_arquivo, pasta)
  if (!is.na(problema)) {
    return(list(problema = problema, linhas = sem_linhas))
  }
  baixado = file.path(pasta, nome_do_arquivo)
  if (!identical(unname(tools::md5sum(baixado)), da_conferencia$md5)) {
    return(list(problema = paste("n\u00e3o confere com a lista de confer\u00eancia do reposit\u00f3rio (veio pela metade",
                                 "ou diferente)"), linhas = sem_linhas))
  }
  do_pacote = system.file("extdata", "tabelas", nome_do_arquivo, package = "RNFe")
  if (!identical(primeira_linha(baixado), primeira_linha(do_pacote))) {
    return(list(problema = "a tabela mudou de formato: atualize o pacote RNFe para usar as tabelas novas",
                linhas = sem_linhas))
  }
  lida = tryCatch(
    withCallingHandlers(ler_tabela_csv(baixado, nome_da_tabela),
                        warning = function(aviso) stop(conditionMessage(aviso), call. = FALSE)),
    error = function(erro) erro
  )
  if (inherits(lida, "error")) {
    return(list(problema = paste("a tabela baixada n\u00e3o abre:", conditionMessage(lida)), linhas = sem_linhas))
  }
  if (nrow(lida) != as.integer(da_conferencia$linhas)) {
    return(list(problema = paste("a tabela baixada tem", nrow(lida), "linhas, e a lista de confer\u00eancia diz",
                                 da_conferencia$linhas), linhas = sem_linhas))
  }
  list(problema = NA_character_, linhas = nrow(lida))
}

# Põe a pasta preparada no lugar da pasta em uso, de uma vez: a em uso sai do caminho e só é apagada depois que a nova
# entrou. Se algo falha (no Windows, um arquivo aberto por outro programa), volta a que estava. Devolve NA quando deu
# certo, ou o problema.
trocar_a_pasta = function(preparada, pasta) {
  antiga = paste0(pasta, "_antiga")
  if (!apagar_pasta(antiga)) {
    return(paste("n\u00e3o deu para trocar as tabelas: n\u00e3o deu para apagar", antiga))
  }
  tinha_tabelas_baixadas = dir.exists(pasta)
  if (tinha_tabelas_baixadas && !renomear(pasta, antiga)) {
    return("n\u00e3o deu para trocar as tabelas: as baixadas antes est\u00e3o abertas por outro programa")
  }
  if (!renomear(preparada, pasta)) {
    if (tinha_tabelas_baixadas) {
      renomear(antiga, pasta)
    }
    return("n\u00e3o deu para trocar as tabelas: a pasta nova n\u00e3o p\u00f4de entrar no lugar")
  }
  apagar_pasta(antiga)
  NA_character_
}

renomear = function(de, para) {
  suppressWarnings(file.rename(de, para))
}

# Apaga a pasta e diz se ela sumiu mesmo: no Windows, um arquivo aberto por outro programa impede.
apagar_pasta = function(pasta) {
  unlink(pasta, recursive = TRUE)
  !dir.exists(pasta)
}

# No NCM, o subitem diz pouco sozinho ("-- Outros"). A descrição completa junta a da posição (4 dígitos)
# com a de cada nível abaixo dela, até o próprio código. O capítulo (2 dígitos) fica com a dele.
descricao_completa_do_ncm = function(ncm) {
  descricoes_completas = rep("", nrow(ncm))
  for (tamanho in 4:8) {
    descricao_do_nivel = ncm$descricao[match(substr(ncm$codigo, 1, tamanho), ncm$codigo)]
    tem_o_nivel = nchar(ncm$codigo) >= tamanho & !is.na(descricao_do_nivel)
    descricoes_completas[tem_o_nivel] = trimws(paste(descricoes_completas[tem_o_nivel], descricao_do_nivel[tem_o_nivel]))
  }
  sem_nivel_abaixo_do_capitulo = descricoes_completas == ""
  descricoes_completas[sem_nivel_abaixo_do_capitulo] = ncm$descricao[sem_nivel_abaixo_do_capitulo]
  descricoes_completas
}

# O texto de cada código como a tabela registrava na data de cada nota. Código que a tabela não tem, ou
# data fora do período em que ela registra o código (antes do início ou depois do fim), fica NA.
descricao_na_data = function(nome_da_tabela, codigos, datas, coluna_do_texto = "descricao") {
  tabela_completa = tabela_fiscal(nome_da_tabela)
  linhas_dos_codigos = tabela_completa[tabela_completa$codigo %in% codigos, ]
  descricoes = rep(NA_character_, length(codigos))
  for (numero_da_linha in seq_len(nrow(linhas_dos_codigos))) {
    do_codigo = !is.na(codigos) & codigos == linhas_dos_codigos$codigo[numero_da_linha]
    ja_valia = is.na(linhas_dos_codigos$inicio[numero_da_linha]) | (!is.na(datas) & datas >= linhas_dos_codigos$inicio[numero_da_linha])
    ainda_valia = is.na(linhas_dos_codigos$fim[numero_da_linha]) | (!is.na(datas) & datas <= linhas_dos_codigos$fim[numero_da_linha])
    descricoes[do_codigo & ja_valia & ainda_valia] = linhas_dos_codigos[[coluna_do_texto]][numero_da_linha]
  }
  descricoes
}
