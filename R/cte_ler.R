# Leitura do XML do CT-e (modelo 57) e do CT-e OS (modelo 67), leiautes 3.00 e 4.00, em tabelas. Os
# caminhos seguem o schema oficial do Portal do CT-e (pacote de liberação PL_CTe_400 NT 2026.004 RTC 1.00,
# que já traz a Reforma).

#' @include ler_xml.R
NULL

# O CT-e (raiz CTe) e o CT-e OS (raiz CTeOS) têm o mesmo infCte. A GTV-e e o CT-e simplificado também
# usam infCte, com outro conteúdo, e por isso ficam de fora.
CAMINHO_DOS_CTES = "//CTe/infCte|//CTeOS/infCte"

# Coluna, caminho a partir do infCte e tipo. "a|b" pega o que existir (o leiaute deixa um ou outro):
# o tomador vem do toma4 no CT-e e do toma no CT-e OS.
CAMPOS_DO_CTE = ler_campos("
coluna                          caminho                                           tipo
modelo                          ide/mod                                           texto
serie                           ide/serie                                         inteiro
numero                          ide/nCT                                           inteiro
emissao                         ide/dhEmi                                         data_hora
data_emissao                    ide/dhEmi                                         data
cfop                            ide/CFOP                                          texto
natureza_operacao               ide/natOp                                         texto
tipo_cte                        ide/tpCTe                                         inteiro
tipo_servico                    ide/tpServ                                        inteiro
modal                           ide/modal                                         texto
forma_emissao                   ide/tpEmis                                        inteiro
ambiente                        ide/tpAmb                                         inteiro
processo_emissao                ide/procEmi                                       inteiro
globalizado                     ide/indGlobalizado                                inteiro
envio_codigo_municipio          ide/cMunEnv                                       texto
envio_municipio                 ide/xMunEnv                                       texto
envio_uf                        ide/UFEnv                                         texto
inicio_codigo_municipio         ide/cMunIni                                       texto
inicio_municipio                ide/xMunIni                                       texto
inicio_uf                       ide/UFIni                                         texto
fim_codigo_municipio            ide/cMunFim                                       texto
fim_municipio                   ide/xMunFim                                       texto
fim_uf                          ide/UFFim                                         texto
retira                          ide/retira                                        inteiro
tomador_papel                   ide/toma3/toma|ide/toma4/toma                     inteiro
tomador_indicador_ie            ide/indIEToma                                     inteiro
tomador_documento               ide/toma4/CNPJ|ide/toma4/CPF|toma/CNPJ|toma/CPF   texto
tomador_nome                    ide/toma4/xNome|toma/xNome                        texto
tomador_ie                      ide/toma4/IE|toma/IE                              texto
tomador_municipio               ide/toma4/enderToma/xMun|toma/enderToma/xMun      texto
tomador_codigo_municipio        ide/toma4/enderToma/cMun|toma/enderToma/cMun      texto
tomador_uf                      ide/toma4/enderToma/UF|toma/enderToma/UF          texto
emitente_documento              emit/CNPJ|emit/CPF                                texto
emitente_nome                   emit/xNome                                        texto
emitente_fantasia               emit/xFant                                        texto
emitente_ie                     emit/IE                                           texto
emitente_municipio              emit/enderEmit/xMun                               texto
emitente_codigo_municipio       emit/enderEmit/cMun                               texto
emitente_uf                     emit/enderEmit/UF                                 texto
emitente_regime                 emit/CRT                                          inteiro
remetente_documento             rem/CNPJ|rem/CPF                                  texto
remetente_nome                  rem/xNome                                         texto
remetente_ie                    rem/IE                                            texto
remetente_municipio             rem/enderReme/xMun                                texto
remetente_codigo_municipio      rem/enderReme/cMun                                texto
remetente_uf                    rem/enderReme/UF                                  texto
expedidor_documento             exped/CNPJ|exped/CPF                              texto
expedidor_nome                  exped/xNome                                       texto
expedidor_ie                    exped/IE                                          texto
expedidor_municipio             exped/enderExped/xMun                             texto
expedidor_codigo_municipio      exped/enderExped/cMun                             texto
expedidor_uf                    exped/enderExped/UF                               texto
recebedor_documento             receb/CNPJ|receb/CPF                              texto
recebedor_nome                  receb/xNome                                       texto
recebedor_ie                    receb/IE                                          texto
recebedor_municipio             receb/enderReceb/xMun                             texto
recebedor_codigo_municipio      receb/enderReceb/cMun                             texto
recebedor_uf                    receb/enderReceb/UF                               texto
destinatario_documento          dest/CNPJ|dest/CPF                                texto
destinatario_nome               dest/xNome                                        texto
destinatario_ie                 dest/IE                                           texto
destinatario_municipio          dest/enderDest/xMun                               texto
destinatario_codigo_municipio   dest/enderDest/cMun                               texto
destinatario_uf                 dest/enderDest/UF                                 texto
valor_prestacao                 vPrest/vTPrest                                    numero
valor_prestacao_sem_tributos    vPrest/vTPrestLiq                                 numero
valor_receber                   vPrest/vRec                                       numero
grupo_icms                      imp/ICMS/*                                        elemento
cst_icms                        imp/ICMS/*/CST                                    texto
reducao_base_icms               imp/ICMS/*/pRedBC|imp/ICMS/*/pRedBCOutraUF        numero
base_icms                       imp/ICMS/*/vBC|imp/ICMS/*/vBCOutraUF              numero
aliquota_icms                   imp/ICMS/*/pICMS|imp/ICMS/*/pICMSOutraUF          numero
valor_icms                      imp/ICMS/*/vICMS|imp/ICMS/*/vICMSOutraUF          numero
base_icms_st_retido             imp/ICMS/*/vBCSTRet                               numero
aliquota_icms_st_retido         imp/ICMS/*/pICMSSTRet                             numero
valor_icms_st_retido            imp/ICMS/*/vICMSSTRet                             numero
valor_credito_icms              imp/ICMS/*/vCred                                  numero
valor_icms_desonerado           imp/ICMS/*/vICMSDeson                             numero
beneficio_fiscal                imp/ICMS/*/cBenef                                 texto
simples_nacional                imp/ICMS/*/indSN                                  inteiro
valor_tributos_aproximado       imp/vTotTrib                                      numero
informacoes_fisco               imp/infAdFisco                                    texto
base_icms_uf_fim                imp/ICMSUFFim/vBCUFFim                            numero
valor_fcp_uf_fim                imp/ICMSUFFim/vFCPUFFim                           numero
valor_icms_uf_fim               imp/ICMSUFFim/vICMSUFFim                          numero
valor_icms_uf_inicio            imp/ICMSUFFim/vICMSUFIni                          numero
valor_pis                       imp/infTribFed/vPIS                               numero
valor_cofins                    imp/infTribFed/vCOFINS                            numero
valor_ir                        imp/infTribFed/vIR                                numero
valor_inss                      imp/infTribFed/vINSS                              numero
valor_csll                      imp/infTribFed/vCSLL                              numero
cst_ibs_cbs                     imp/IBSCBS/CST                                    texto
classificacao_ibs_cbs           imp/IBSCBS/cClassTrib                             texto
base_ibs_cbs                    imp/IBSCBS/gIBSCBS/vBC                            numero
aliquota_ibs_uf                 imp/IBSCBS/gIBSCBS/gIBSUF/pIBSUF                  numero
valor_ibs_uf                    imp/IBSCBS/gIBSCBS/gIBSUF/vIBSUF                  numero
aliquota_ibs_municipio          imp/IBSCBS/gIBSCBS/gIBSMun/pIBSMun                numero
valor_ibs_municipio             imp/IBSCBS/gIBSCBS/gIBSMun/vIBSMun                numero
valor_ibs                       imp/IBSCBS/gIBSCBS/vIBS                           numero
aliquota_cbs                    imp/IBSCBS/gIBSCBS/gCBS/pCBS                      numero
valor_cbs                       imp/IBSCBS/gIBSCBS/gCBS/vCBS                      numero
valor_total_documento           imp/vTotDFe                                       numero
valor_carga                     infCTeNorm/infCarga/vCarga                        numero
produto_predominante            infCTeNorm/infCarga/proPred                       texto
outras_caracteristicas_carga    infCTeNorm/infCarga/xOutCat                       texto
valor_carga_averbacao           infCTeNorm/infCarga/vCargaAverb                   numero
servico_descricao               infCTeNorm/infServico/xDescServ                   texto
servico_quantidade              infCTeNorm/infServico/infQ/qCarga                 numero
rntrc                           infCTeNorm/infModal/rodo/RNTRC                    texto
fatura_numero                   infCTeNorm/cobr/fat/nFat                          texto
fatura_valor_original           infCTeNorm/cobr/fat/vOrig                         numero
fatura_desconto                 infCTeNorm/cobr/fat/vDesc                         numero
fatura_valor_liquido            infCTeNorm/cobr/fat/vLiq                          numero
caracteristica_transporte       compl/xCaracAd                                    texto
caracteristica_servico          compl/xCaracSer                                   texto
observacoes_gerais              compl/xObs                                        texto
")

# No toma3, o tomador é uma das outras pessoas do CT-e: papel 0 a 3, nesta ordem.
PESSOA_DE_CADA_PAPEL = c("remetente", "expedidor", "recebedor", "destinatario")
DADOS_DO_TOMADOR = c("documento", "nome", "ie", "municipio", "codigo_municipio", "uf")

# O nome de cada código, ao lado dele, como a tabela fiscal registrava na data de emissão do CT-e. O CST
# do ICMS fica sem: a tabela do pacote é a da NF-e, que não tem o CST 45 do CT-e.
DESCRICOES_DO_CTE = ler_campos("
coluna_do_codigo      coluna_nova                tabela                texto
cfop                  cfop_titulo                cfop                  titulo
cst_ibs_cbs           cst_ibs_cbs_descricao      cst_ibs_cbs           descricao
classificacao_ibs_cbs classificacao_ibs_cbs_nome classificacao_ibs_cbs nome
")

# A partir de cada Comp (vPrest/Comp).
CAMPOS_DO_COMPONENTE = ler_campos("
coluna caminho tipo
nome   xNome   texto
valor  vComp   numero
")

# Os documentos que o CT-e cita, a partir do infCte, nesta ordem: os transportados (infNFe, infNF,
# infOutros, infDCe), os de transporte anterior (idDocAntEle, idDocAntPap), o CT-e complementado, o
# substituído, o CT-e multimodal do serviço vinculado e, no CT-e OS, os documentos referenciados e as GTV-e.
CAMINHO_DOS_DOCUMENTOS = paste(
  "infCTeNorm/infDoc/*",
  "infCTeNorm/docAnt/emiDocAnt/idDocAnt/*",
  "infCteComp",
  "infCTeNorm/infCteSub",
  "infCTeNorm/infServVinc/infCTeMultimodal",
  "infCTeNorm/infDocRef",
  "infCTeNorm/infGTVe",
  sep = "|"
)

# A partir de cada documento. Cada grupo tem só alguns destes campos; o resto fica NA.
CAMPOS_DO_DOCUMENTO = ler_campos("
coluna              caminho                                            tipo
tipo                self::*                                            elemento
documento_chave     chave|chCTe|chCte|chBPe|chCTeMultimodal            texto
modelo              mod                                                texto
tipo_documento      tpDoc                                              texto
descricao           descOutros                                         texto
serie               serie                                              texto
subserie            subser|subserie                                    texto
numero              nDoc                                               texto
emissao             dEmi                                               data
valor               vNF|vDocFisc|vDoc                                  numero
base_icms           vBC                                                numero
valor_icms          vICMS                                              numero
base_icms_st        vBCST                                              numero
valor_icms_st       vST                                                numero
valor_produtos      vProd                                              numero
cfop                nCFOP                                              texto
peso                nPeso                                              numero
previsao_entrega    dPrev                                              data
romaneio            nRoma                                              texto
pedido              nPed                                               texto
emitente_documento  ancestor::emiDocAnt/CNPJ|ancestor::emiDocAnt/CPF   texto
emitente_nome       ancestor::emiDocAnt/xNome                          texto
emitente_uf         ancestor::emiDocAnt/UF                             texto
")

# A partir de cada infQ (infCTeNorm/infCarga/infQ).
CAMPOS_DA_CARGA = ler_campos("
coluna       caminho tipo
unidade      cUnid   texto
tipo_medida  tpMed   texto
quantidade   qCarga  numero
")

# A partir de cada ObsCont e ObsFisco (compl).
CAMPOS_DA_OBSERVACAO = ler_campos("
coluna caminho  tipo
tipo   self::*  elemento
campo  @xCampo  texto
texto  xTexto   texto
")

#' Ler o XML de CT-e e CT-e OS
#'
#' Lê arquivos XML de CT-e (modelo 57) e de CT-e OS (modelo 67), leiautes 3.00
#' e 4.00, com ou sem o protocolo de autorização (`cteProc`, `cteOSProc` ou só
#' o documento), e devolve tabelas ligadas pela `chave`. Um arquivo que não dá
#' para ler não interrompe os outros: fica em `arquivos`, com o motivo. O CT-e
#' simplificado e a GTV-e, que têm outro conteúdo, não são lidos.
#'
#' Cada coluna vem de um campo do leiaute (entre parênteses abaixo). Códigos
#' (CST, CFOP, modal...) ficam como estão no XML; o significado de cada um está
#' no Manual de Orientação do Contribuinte do CT-e. Campo que o CT-e não tem
#' fica `NA`.
#'
#' @section ctes:
#' Uma linha por CT-e: `chave`, `versao`,
#' `r documentar_campos(CAMPOS_DO_CTE)`;
#' do protocolo de autorização, quando vem junto:
#' `r documentar_campos(CAMPOS_DO_PROTOCOLO)`;
#' e `arquivo`. `emissao` e `autorizacao` são data e hora (mostradas no horário
#' de Brasília); `data_emissao` é a data como está no CT-e.
#'
#' O `*` é o grupo do ICMS que o CT-e tiver, e `grupo_icms` diz qual (por
#' exemplo, `ICMS00`, `ICMS45`, `ICMSOutraUF` ou `ICMSSN`). No `ICMSOutraUF`, o
#' ICMS devido à UF de origem da prestação quando ela é diferente da UF do
#' emitente, a redução, a base, a alíquota e o valor vêm dos campos com
#' `OutraUF` no nome.
#'
#' As colunas `tomador_` trazem o tomador do serviço. No CT-e com `toma3`
#' (`tomador_papel` de 0 a 3), ele é o remetente, o expedidor, o recebedor ou o
#' destinatário, nessa ordem, e os dados são os dessa pessoa; com `toma4`
#' (`tomador_papel` 4) e no CT-e OS (grupo `toma`, sem papel), os dados vêm do
#' próprio grupo.
#'
#' Ao lado do CFOP, do CST e da classificação tributária do IBS e da CBS vem o
#' nome de cada um, como a tabela fiscal registrava na data de emissão (veja
#' [tabela_fiscal()]): `cfop_titulo`, `cst_ibs_cbs_descricao` e
#' `classificacao_ibs_cbs_nome`. O CST do ICMS fica sem nome: a tabela do
#' pacote é a da NF-e, que não tem o CST 45 do CT-e.
#'
#' @section componentes:
#' Os componentes do valor da prestação (frete peso, pedágio...), um por linha:
#' `chave`, `r documentar_campos(CAMPOS_DO_COMPONENTE)`.
#'
#' @section documentos:
#' Os documentos que o CT-e cita, um por linha: `chave`,
#' `r documentar_campos(CAMPOS_DO_DOCUMENTO)`.
#' Cada grupo tem só alguns desses campos. `tipo` é o grupo de onde o documento
#' veio:
#' * `infNFe`, `infNF`, `infOutros` e `infDCe`: os documentos transportados
#'   (NF-e, nota fiscal em papel, outros documentos e DC-e);
#' * `idDocAntEle` e `idDocAntPap`: os documentos de transporte anterior
#'   (eletrônico e em papel), com o emitente;
#' * `infCteComp`: o CT-e que este complementa;
#' * `infCteSub`: o CT-e que este substitui;
#' * `infCTeMultimodal`: o CT-e multimodal do serviço vinculado;
#' * `infDocRef` e `infGTVe`: no CT-e OS, os documentos referenciados (ou o
#'   BP-e) e as GTV-e.
#'
#' @section cargas:
#' As quantidades da carga, uma por linha (o mesmo CT-e pode trazer o peso e o
#' número de caixas, por exemplo): `chave`,
#' `r documentar_campos(CAMPOS_DA_CARGA)`.
#'
#' @section impostos:
#' Todos os campos dos impostos do CT-e, um por linha: `chave`, `tributo` (o
#' grupo logo abaixo de `imp`: `ICMS`, `ICMSUFFim`, `infTribFed`, `IBSCBS`...),
#' `grupo` (onde o campo está, por exemplo `ICMS00` ou `gCBS`), `campo` (o nome
#' no leiaute) e `valor` (o texto do XML). É o que sobra para quem precisa de um
#' campo que não está em `ctes`.
#'
#' @section parcelas e observações:
#' `parcelas`, uma linha por duplicata: `chave`,
#' `r documentar_campos(CAMPOS_DA_PARCELA)`.
#' `observacoes`, uma linha por campo de uso livre (`ObsCont` e `ObsFisco`):
#' `chave`, `r documentar_campos(CAMPOS_DA_OBSERVACAO)`.
#'
#' @section arquivos:
#' Uma linha por arquivo pedido: `arquivo`, `ctes` (quantos CT-e tinha) e
#' `problema` (`NA` quando deu certo). Um texto de XML aparece como
#' `"(texto 1)"`, `"(texto 2)"`...
#'
#' @param arquivos Caminhos dos arquivos XML, ou o próprio texto do XML
#'   (começando por `<`).
#' @return Uma lista com os `data.frame`s `ctes`, `componentes`, `documentos`,
#'   `cargas`, `impostos`, `parcelas`, `observacoes` e `arquivos`.
#' @source Schema oficial do CT-e, pacote de liberação PL_CTe_400 NT 2026.004
#'   RTC 1.00, publicado no Portal Nacional do CT-e (republicado em
#'   16/10/2026).
#' @examples
#' cte = system.file("exemplos", "cte_proc_sp.xml", package = "RNfe")
#' lido = cte_ler(cte)
#' lido$ctes[, c("chave", "emitente_nome", "tomador_nome", "valor_prestacao", "valor_icms")]
#' lido$documentos[, c("tipo", "documento_chave")]
#' @export
cte_ler = function(arquivos) {
  arquivos_lidos = ler_arquivos_xml(arquivos, CAMINHO_DOS_CTES, "um CT-e", colunas_do_cte)
  colunas_vazias = colunas_do_cte(NULL, NA_character_)

  resultado = list(
    ctes = juntar_tabela(arquivos_lidos, "ctes", colunas_vazias$ctes),
    componentes = juntar_tabela(arquivos_lidos, "componentes", colunas_vazias$componentes),
    documentos = juntar_tabela(arquivos_lidos, "documentos", colunas_vazias$documentos),
    cargas = juntar_tabela(arquivos_lidos, "cargas", colunas_vazias$cargas),
    impostos = juntar_tabela(arquivos_lidos, "impostos", colunas_vazias$impostos),
    parcelas = juntar_tabela(arquivos_lidos, "parcelas", colunas_vazias$parcelas),
    observacoes = juntar_tabela(arquivos_lidos, "observacoes", colunas_vazias$observacoes),
    arquivos = resumo_dos_arquivos(arquivos_lidos, "ctes", "ctes")
  )
  resultado$ctes = converter_datas(resultado$ctes, rbind(CAMPOS_DO_CTE, CAMPOS_DO_PROTOCOLO))
  resultado$ctes = preencher_tomador(resultado$ctes)
  resultado$ctes = acrescentar_descricoes(resultado$ctes, resultado$ctes$data_emissao, DESCRICOES_DO_CTE)
  resultado$documentos = converter_datas(resultado$documentos, CAMPOS_DO_DOCUMENTO)
  resultado$parcelas = converter_datas(resultado$parcelas, CAMPOS_DA_PARCELA)
  resultado
}

# As colunas das tabelas de um arquivo de CT-e, cada uma num vetor. Com documento NULL, vêm vazias, já
# com os nomes e os tipos certos.
colunas_do_cte = function(documento, nome_do_arquivo) {
  if (is.null(documento)) {
    documento = xml2::read_xml("<vazio/>")
  }
  ctes = buscar_todos(documento, CAMINHO_DOS_CTES)
  protocolos = buscar_todos(documento, "//protCTe/infProt")
  componentes = buscar_todos(ctes, "vPrest/Comp")
  documentos = buscar_todos(ctes, CAMINHO_DOS_DOCUMENTOS)
  cargas = buscar_todos(ctes, "infCTeNorm/infCarga/infQ")
  campos_dos_impostos = buscar_todos(ctes, "imp//*[not(*)]")
  duplicatas = buscar_todos(ctes, "infCTeNorm/cobr/dup")
  observacoes = buscar_todos(ctes, "compl/ObsCont|compl/ObsFisco")

  chaves = chave_de_cada(ctes, "infCte")
  # O protocolo é casado com o CT-e pela chave; CT-e que veio sem protocolo fica com NA.
  protocolo_de_cada_cte = match(chaves, texto_de_cada(protocolos, "chCTe"))

  list(
    ctes = c(
      list(chave = chaves, versao = xml2::xml_attr(ctes, "versao")),
      valores_dos_campos(ctes, CAMPOS_DO_CTE),
      valores_dos_campos(protocolos, CAMPOS_DO_PROTOCOLO, protocolo_de_cada_cte),
      list(arquivo = rep(nome_do_arquivo, length(ctes)))
    ),
    componentes = c(list(chave = chave_de_cada(componentes, "infCte")), valores_dos_campos(componentes, CAMPOS_DO_COMPONENTE)),
    documentos = c(list(chave = chave_de_cada(documentos, "infCte")), valores_dos_campos(documentos, CAMPOS_DO_DOCUMENTO)),
    cargas = c(list(chave = chave_de_cada(cargas, "infCte")), valores_dos_campos(cargas, CAMPOS_DA_CARGA)),
    impostos = colunas_dos_impostos_do_cte(campos_dos_impostos),
    parcelas = c(list(chave = chave_de_cada(duplicatas, "infCte")), valores_dos_campos(duplicatas, CAMPOS_DA_PARCELA)),
    observacoes = c(list(chave = chave_de_cada(observacoes, "infCte")), valores_dos_campos(observacoes, CAMPOS_DA_OBSERVACAO))
  )
}

# Um campo de imposto por linha. O tributo é o grupo logo abaixo de <imp> (ICMS, IBSCBS...) e o grupo é
# onde o campo está (ICMS00, gCBS...).
colunas_dos_impostos_do_cte = function(campos_dos_impostos) {
  tributo_de_cada_campo = xml2::xml_find_first(campos_dos_impostos, "ancestor-or-self::*[parent::imp]", ns = SEM_NAMESPACE)
  # xml_parent() devolveria cada grupo uma vez só; parent::* devolve um por campo.
  grupo_de_cada_campo = xml2::xml_find_first(campos_dos_impostos, "parent::*", ns = SEM_NAMESPACE)
  list(
    chave = chave_de_cada(campos_dos_impostos, "infCte"),
    tributo = xml2::xml_name(tributo_de_cada_campo),
    grupo = xml2::xml_name(grupo_de_cada_campo),
    campo = xml2::xml_name(campos_dos_impostos),
    valor = xml2::xml_text(campos_dos_impostos)
  )
}

# No toma3 o XML só diz o papel do tomador; os dados dele são os da pessoa desse papel.
preencher_tomador = function(ctes) {
  for (papel in 0:3) {
    linhas_do_papel = which(ctes$tomador_papel == papel)
    pessoa = PESSOA_DE_CADA_PAPEL[papel + 1]
    for (dado in DADOS_DO_TOMADOR) {
      ctes[[paste0("tomador_", dado)]][linhas_do_papel] = ctes[[paste0(pessoa, "_", dado)]][linhas_do_papel]
    }
  }
  ctes
}
