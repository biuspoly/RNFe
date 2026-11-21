#' RNFe: documentos fiscais eletrônicos brasileiros
#'
#' Funções para os documentos fiscais eletrônicos do Brasil (NF-e, NFC-e, CT-e,
#' GTV-e, MDF-e, NFS-e Nacional). Nesta versão:
#' - a chave de acesso, já com o CNPJ alfanumérico: [chave_valida()] (está
#'   certa?), [chave_decompor()] (as partes e o que está errado) e
#'   [chave_digito()] (o dígito que ela deveria ter);
#' - a leitura do XML em tabelas: [nfe_ler()] (também o resumo que a
#'   Distribuição de DF-e entrega), [cte_ler()], [cte_simplificado_ler()],
#'   [gtve_ler()], [mdfe_ler()], [nfse_ler()], [nfse_prefeitura_ler()] (a
#'   NFS-e de São Paulo e a do padrão ABRASF) e, para os eventos de todos eles
#'   (cancelamento, carta de correção, manifestação, encerramento...),
#'   [eventos_ler()];
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
#' - a montagem do XML pelo schema oficial: [nfe_montar()], [cte_montar()],
#'   [mdfe_montar()] e [nfse_dps_montar()], e o caminho de volta,
#'   [xml_para_lista()];
#' - a emissão, por enquanto só em homologação: [xml_assinar()],
#'   [sefaz_autorizar()] (a NF-e e a NFC-e, com o QR-Code de [nfce_qrcode()]),
#'   [sefaz_cancelar()], [sefaz_carta_correcao()], [sefaz_manifestar()],
#'   [sefaz_cte_desacordo()] e [sefaz_cte_cancelar_desacordo()],
#'   [sefaz_mdfe_autorizar()], [sefaz_mdfe_incluir_condutor()] e
#'   [sefaz_mdfe_encerrar()], e a NFS-e Nacional na Produção Restrita:
#'   [nfse_emitir()] e [nfse_cancelar()];
#' - os documentos auxiliares em PDF: [danfe_pdf()],
#'   [danfe_simplificado_pdf()], [danfce_pdf()], [dacte_pdf()],
#'   [damdfe_pdf()], [danfse_pdf()] e [dacce_pdf()].
#'
#' @section De onde vêm as regras:
#' Das especificações públicas dos portais da NF-e, do CT-e, do MDF-e e da
#' NFS-e Nacional: os manuais, as notas técnicas e os schemas, citados com a
#' versão em cada função (`@source`). Só as funções `sefaz_` falam com a
#' SEFAZ, e as `nfse_situacao()`, `nfse_distribuicao()`, `nfse_emitir()` e
#' `nfse_cancelar()` com o Sistema Nacional NFS-e, todas só no ambiente de
#' homologação (a Produção Restrita, na NFS-e).
#'
#' @keywords internal
"_PACKAGE"
