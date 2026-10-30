#' RNfe: documentos fiscais eletrônicos brasileiros
#'
#' Funções para os documentos fiscais eletrônicos do Brasil (NF-e, NFC-e, CT-e,
#' MDF-e, NFS-e Nacional). Nesta versão:
#' - a chave de acesso: conferir, desmontar e calcular o dígito, já com o CNPJ
#'   alfanumérico (veja [chave]);
#' - a leitura do XML em tabelas: [nfe_ler()], [cte_ler()], [mdfe_ler()] e
#'   [nfse_ler()];
#' - as tabelas fiscais, com a vigência de cada código: [tabela_fiscal()].
#'
#' @section De onde vêm as regras:
#' Das especificações públicas dos portais da NF-e, do CT-e, do MDF-e e da
#' NFS-e Nacional: os manuais, as notas técnicas e os schemas, citados com a
#' versão em cada função (`@source`). Nada aqui consulta a SEFAZ.
#'
#' @keywords internal
"_PACKAGE"
