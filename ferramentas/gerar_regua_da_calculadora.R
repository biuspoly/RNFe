# Grava tests/testthat/calculadora_oficial/teste_varios_itens.csv: o teste de regressão de 262 itens da calculadora
# oficial da Receita (github.com/ReceitaFederal/calculadora-rtc-regime-regular, licença MIT), em 2027, com a entrada
# de cada item e o que a calculadora respondeu. O teste do ibs_cbs_calcular() calcula os mesmos itens e compara.
#
# A base vai pronta (o vBC da calculadora: o RNFe não calcula o Imposto Seletivo, que entra nela), menos na redução da
# base (CST 222), em que o valor cobrado vai como o do produto, para o RNFe reduzir. O diferimento da calculadora é
# sempre 100% (510 e 515); o RNFe recebe o percentual. Uso, na raiz do repositório, com o repositório da calculadora
# clonado em outra pasta:
#   Rscript ferramentas/gerar_regua_da_calculadora.R <pasta do calculadora-rtc-regime-regular>

argumentos = commandArgs(trailingOnly = TRUE)
if (length(argumentos) != 1) {
  stop("Informe a pasta do repositório calculadora-rtc-regime-regular.")
}
PASTA_DA_CALCULADORA = argumentos[1]
RECURSOS = file.path(PASTA_DA_CALCULADORA, "src", "test", "resources")
ARQUIVO_DE_ENTRADA = file.path(RECURSOS, "entradas", "calculoscorretos", "varios_itens", "Teste_Varios_Itens.json")
ARQUIVO_DE_SAIDA = file.path(RECURSOS, "saidas", "Teste_Varios_Itens.json")
PASTA_DA_REGUA = file.path("tests", "testthat", "calculadora_oficial")

numero_ou_vazio = function(valor) {
  if (is.null(valor)) NA_real_ else as.numeric(valor)
}

texto_ou_vazio = function(valor) {
  if (is.null(valor)) NA_character_ else as.character(valor)
}

# Os campos de cada parte na resposta: o nó dela, a alíquota e o valor.
PARTES_NA_RESPOSTA = list(ibs_uf = c("gIBSUF", "pIBSUF", "vIBSUF"), ibs_municipio = c("gIBSMun", "pIBSMun", "vIBSMun"),
                          cbs = c("gCBS", "pCBS", "vCBS"))
REGULAR_NA_RESPOSTA = list(ibs_uf = c("pAliqEfetRegIBSUF", "vTribRegIBSUF"),
                           ibs_municipio = c("pAliqEfetRegIBSMun", "vTribRegIBSMun"),
                           cbs = c("pAliqEfetRegCBS", "vTribRegCBS"))

entrada = jsonlite::fromJSON(ARQUIVO_DE_ENTRADA, simplifyVector = FALSE)
saida = jsonlite::fromJSON(ARQUIVO_DE_SAIDA, simplifyVector = FALSE)

respostas = list()
for (objeto in saida$objetos) {
  grupo = objeto$tribCalc$IBSCBS
  geral = grupo$gIBSCBS
  resposta = list(item = as.integer(objeto$nObj), oficial_base = numero_ou_vazio(geral$vBC),
                  oficial_valor_ibs = numero_ou_vazio(geral$vIBS))
  for (parte in names(PARTES_NA_RESPOSTA)) {
    campos = PARTES_NA_RESPOSTA[[parte]]
    no_da_parte = geral[[campos[1]]]
    resposta[[paste0("oficial_aliquota_", parte)]] = numero_ou_vazio(no_da_parte[[campos[2]]])
    resposta[[paste0("oficial_reducao_", parte)]] = numero_ou_vazio(no_da_parte$gRed$pRedAliq)
    resposta[[paste0("oficial_aliquota_efetiva_", parte)]] = numero_ou_vazio(no_da_parte$gRed$pAliqEfet)
    resposta[[paste0("oficial_diferimento_", parte)]] = numero_ou_vazio(no_da_parte$gDif$pDif)
    resposta[[paste0("oficial_valor_diferido_", parte)]] = numero_ou_vazio(no_da_parte$gDif$vDif)
    resposta[[paste0("oficial_valor_", parte)]] = numero_ou_vazio(no_da_parte[[campos[3]]])
  }
  regular = geral$gTribRegular
  for (parte in names(REGULAR_NA_RESPOSTA)) {
    campos = REGULAR_NA_RESPOSTA[[parte]]
    resposta[[paste0("oficial_aliquota_regular_", parte)]] = numero_ou_vazio(regular[[campos[1]]])
    resposta[[paste0("oficial_valor_regular_", parte)]] = numero_ou_vazio(regular[[campos[2]]])
  }
  respostas[[length(respostas) + 1]] = as.data.frame(resposta)
}
respostas = do.call(rbind, respostas)

itens = list()
for (item in entrada$itens) {
  nominais = item$aliquotasNominais
  cst = as.character(item$cst)
  itens[[length(itens) + 1]] = data.frame(
    item = as.integer(item$numero), cst_ibs_cbs = cst, classificacao_ibs_cbs = as.character(item$cClassTrib),
    cst_regular = texto_ou_vazio(item$tributacaoRegular$cst),
    classificacao_regular = texto_ou_vazio(item$tributacaoRegular$cClassTrib),
    valor_cobrado = numero_ou_vazio(item$baseCalculo), aliquota_nominal_ibs_uf = numero_ou_vazio(nominais$ibsEstadual),
    aliquota_nominal_ibs_municipio = numero_ou_vazio(nominais$ibsMunicipal),
    aliquota_nominal_cbs = numero_ou_vazio(nominais$cbs),
    diferimento = if (cst %in% c("510", "515")) 100 else NA_real_)
}
itens = do.call(rbind, itens)

regua = merge(itens, respostas, by = "item", all.x = TRUE, sort = TRUE)
# A base pronta é a da calculadora; na redução da base, o valor cobrado vai como o do produto.
pela_parte_da_base = regua$cst_ibs_cbs == "222"
regua$base = ifelse(pela_parte_da_base, NA_real_, ifelse(is.na(regua$oficial_base), regua$valor_cobrado,
                                                          regua$oficial_base))
regua$valor_produto = ifelse(pela_parte_da_base, regua$valor_cobrado, NA_real_)
regua$valor_cobrado = NULL
colunas_da_entrada = c("item", "cst_ibs_cbs", "classificacao_ibs_cbs", "cst_regular", "classificacao_regular", "base",
                       "valor_produto", "diferimento", "aliquota_nominal_ibs_uf", "aliquota_nominal_ibs_municipio",
                       "aliquota_nominal_cbs")
regua = regua[, c(colunas_da_entrada, setdiff(names(regua), colunas_da_entrada))]

dir.create(PASTA_DA_REGUA, showWarnings = FALSE, recursive = TRUE)
utils::write.csv(regua, file.path(PASTA_DA_REGUA, "teste_varios_itens.csv"), row.names = FALSE, na = "",
                 fileEncoding = "UTF-8")
file.copy(file.path(PASTA_DA_CALCULADORA, "LICENSE"), file.path(PASTA_DA_REGUA, "LICENSE"), overwrite = TRUE)
commit_da_calculadora = system2("git", c("-C", shQuote(PASTA_DA_CALCULADORA), "log", "-1", "--format=%H%x20(%cs)"),
                                stdout = TRUE)
writeLines(c(
  "O teste de regressão de 262 itens da calculadora oficial da Receita (Teste_Varios_Itens.json, a entrada e a saída),",
  "do repositório github.com/ReceitaFederal/calculadora-rtc-regime-regular, sob a licença MIT do arquivo LICENSE.",
  paste("Commit da calculadora:", commit_da_calculadora),
  "Gerado por ferramentas/gerar_regua_da_calculadora.R."
), file.path(PASTA_DA_REGUA, "ORIGEM.txt"), useBytes = FALSE)
cat("régua:", nrow(regua), "itens, de", length(unique(regua$classificacao_ibs_cbs)), "classificações\n")
