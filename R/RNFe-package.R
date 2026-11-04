#' RNFe: documentos fiscais eletrônicos brasileiros
#'
#' Funções para os documentos fiscais eletrônicos do Brasil (NF-e, NFC-e, CT-e,
#' GTV-e, MDF-e, NFS-e Nacional). Nesta versão:
#' - a chave de acesso, já com o CNPJ alfanumérico: [chave_valida()] (está
#'   certa?), [chave_decompor()] (as partes e o que está errado) e
#'   [chave_digito()] (o dígito que ela deveria ter) e [chave_extrair()] (a
#'   chave achada num PDF ou numa foto, pelo texto, QR-Code ou OCR);
#' - a leitura do XML em tabelas: [nfe_ler()] (também o resumo que a
#'   Distribuição de DF-e entrega), [cte_ler()], [gtve_ler()], [mdfe_ler()],
#'   [nfse_ler()] e, para os eventos de todos eles (cancelamento, carta de
#'   correção, manifestação, encerramento...), [eventos_ler()];
#' - as tabelas fiscais, com a vigência de cada código, e os municípios do
#'   IBGE: [tabela_fiscal()];
#' - o certificado digital A1: [certificado_ler()] (titular, CNPJ ou CPF e
#'   validade);
#' - a conversa com a SEFAZ, por enquanto só no ambiente de homologação:
#'   [sefaz_status()] (o serviço da NF-e, da NFC-e, do CT-e ou do MDF-e está
#'   no ar?), [sefaz_situacao()] (a situação de cada documento, pela chave),
#'   [sefaz_mdfe_nao_encerrados()] (os MDF-e que um emitente ainda não
#'   encerrou), [sefaz_cadastro()] (o cadastro de contribuintes, pelo CNPJ,
#'   CPF ou IE) e [sefaz_distribuicao()] (as NF-e e os CT-e emitidos contra
#'   um CNPJ);
#' - a NFS-e Nacional, pelas APIs do Sistema Nacional NFS-e, por enquanto só
#'   na Produção Restrita: [nfse_situacao()] (a nota pela chave, com os
#'   eventos) e [nfse_distribuicao()] (as notas e os eventos de um CNPJ);
#' - a situação do CNPJ na Receita Federal, sem certificado:
#'   [cnpj_situacao()] (a BrasilAPI e, quando ela está fora do ar, as outras
#'   fontes públicas).
#'
#' @section De onde vêm as regras:
#' Das especificações públicas dos portais da NF-e, do CT-e, do MDF-e e da
#' NFS-e Nacional: os manuais, as notas técnicas e os schemas, citados com a
#' versão em cada função (`@source`). Só as funções `sefaz_` falam com a
#' SEFAZ, e as `nfse_situacao()` e `nfse_distribuicao()` com o Sistema
#' Nacional NFS-e, todas só no ambiente de homologação.
#'
#' @keywords internal
"_PACKAGE"
