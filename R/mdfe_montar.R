# A montagem do MDF-e pelo schema do leiaute (o pacote PL_MDFe_300b em inst/schemas/mdfe), com o modal (rodo, aereo,
# aquav, ferrov) pelo schema dele, e o que o RNFe completa sozinho: o ambiente, o modelo, o código numérico, o dígito e
# o Id da chave.

#' @include montar.R
NULL

#' Montar um MDF-e
#'
#' Monta o XML do MDF-e a partir de uma lista com os grupos e os campos do
#' `infMDFe`, com os nomes do leiaute (`ide`, `emit`, `infModal`, `infDoc`,
#' `seg`, `prodPred`, `tot`, `lacres`, `autXML`, `infAdic`...), como o
#' [nfe_montar()] faz com a NF-e: a ordem, o formato dos números e das datas e
#' o que é atributo vêm do schema oficial que acompanha o pacote, e o
#' resultado é conferido nele. O modal vai dentro do `infModal`, pelo nome
#' (`infModal = list(versaoModal = "3.00", rodo = list(...))`), e é conferido
#' pelo schema do modal.
#'
#' O RNFe completa sozinho o que não vier: o `tpAmb` do ambiente, o modelo
#' (58), o código numérico `cMDF` (sorteado, com o mesmo cuidado da NF-e), o
#' dígito `cDV`, o `Id` com a chave de acesso (o CNPJ do emitente, ou o CPF
#' com zeros à esquerda) e o campo obrigatório que só aceita um valor. O
#' QR-Code (`infMDFeSupl`) entra no [sefaz_mdfe_autorizar()].
#'
#' @param manifesto Uma lista com o conteúdo do `infMDFe`, com os nomes do
#'   leiaute.
#' @inheritParams nfe_montar
#' @return O XML do MDF-e (o elemento `MDFe`, ainda sem a assinatura), num
#'   texto: pronto para [xml_assinar()].
#' @seealso [xml_para_lista()], [sefaz_mdfe_autorizar()], [mdfe_ler()]
#' @source Os schemas do MDF-e, pacote PL_MDFe_300b com a NT 2025.001 v1.04
#'   (`mdfe_v3.00.xsd` e os dos modais), e a composição da chave de acesso
#'   pelo Manual de Orientação do Contribuinte do MDF-e 3.00b (itens 2.1.3 e
#'   2.1.5).
#' @examples
#' manifesto = xml_para_lista(system.file("exemplos", "mdfe_ce_carga_propria.xml", package = "RNFe"))
#' manifesto$ide$nMDF = 322
#' manifesto$ide$cMDF = NULL
#' manifesto$ide$cDV = NULL
#' manifesto$Id = NULL
#' if (requireNamespace("openssl", quietly = TRUE)) {
#'   montado = mdfe_montar(manifesto)
#'   substr(montado, 1, 120)
#' }
#' @export
mdfe_montar = function(manifesto, manter_vazios = FALSE, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_manter_vazios(manter_vazios)
  conferir_a_lista_do_documento(manifesto, "o MDF-e", "do infMDFe (ide, emit, infModal, infDoc, tot...)", "infMDFe")
  manifesto = com_o_ambiente(manifesto, ambiente, "O MDF-e")
  manifesto = completar_a_chave(manifesto, "MDFe", "nMDF", "cMDF", modelo_que_falta = "58")
  montar_o_documento("MDF-e", manifesto, manter_vazios)
}
