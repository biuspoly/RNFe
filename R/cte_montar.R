# A montagem do CT-e, do CT-e OS, da GTV-e e do CT-e simplificado pelo schema do leiaute (o pacote do CT-e 4.00 em
# inst/schemas/cte), com o modal pelo schema dele, e o que o RNFe completa sozinho: o ambiente, o modelo, o código
# numérico, o dígito e o Id da chave.

#' @include montar.R
NULL

# O modelo de cada documento do leiaute do CT-e (o TModCT, o TModCTOS e o TModGTVe do schema).
MODELO_DE_CADA_DOCUMENTO_DO_CTE = c("CT-e" = "57", "CT-e simplificado" = "57", "CT-e OS" = "67", "GTV-e" = "64")
# O tpCTe do CT-e simplificado (o TFinCTeSimp do schema: 5, o simplificado; 6, a substituição dele).
TIPOS_DO_CTE_SIMPLIFICADO = c("5", "6")

#' Montar um CT-e, CT-e OS, GTV-e ou CT-e simplificado
#'
#' Monta o XML do documento do leiaute do CT-e a partir de uma lista com os
#' grupos e os campos do `infCte`, com os nomes do leiaute (`ide`, `compl`,
#' `emit`, `rem`, `dest`, `vPrest`, `imp`, `infCTeNorm`...), como o
#' [nfe_montar()] faz com a NF-e: a ordem, o formato dos números e das datas e
#' o que é atributo vêm do schema oficial que acompanha o pacote, e o
#' resultado é conferido nele. O modal vai dentro do `infModal`, pelo nome
#' (`infModal = list(versaoModal = "4.00", rodo = list(RNTRC = ...))`), e é
#' conferido pelo schema do modal.
#'
#' O documento sai do `mod` (57 é o CT-e, 67 o CT-e OS e 64 a GTV-e) e, no
#' modelo 57, do `tpCTe` (5 e 6 são o CT-e simplificado); ou diga qual em
#' `documento`.
#'
#' O RNFe completa sozinho o que não vier: o `tpAmb` do ambiente, o modelo, o
#' código numérico `cCT` (sorteado, com o mesmo cuidado da NF-e), o dígito
#' `cDV`, o `Id` com a chave de acesso e o campo obrigatório que só aceita um
#' valor. O QR-Code (`infCTeSupl`) entra no [sefaz_cte_autorizar()].
#'
#' @param cte Uma lista com o conteúdo do `infCte`, com os nomes do leiaute.
#' @param documento `"CT-e"`, `"CT-e OS"`, `"GTV-e"` ou `"CT-e simplificado"`;
#'   sem ele, sai do `mod` e do `tpCTe`.
#' @inheritParams nfe_montar
#' @return O XML do documento (o elemento `CTe`, `CTeOS`, `GTVe` ou `CTeSimp`,
#'   ainda sem a assinatura), num texto: pronto para [xml_assinar()].
#' @seealso [xml_para_lista()], [sefaz_cte_autorizar()], [cte_ler()]
#' @source Os schemas do CT-e 4.00, pacote da NT 2026.005 (`cte_v4.00.xsd`,
#'   `cteOS_v4.00.xsd`, `GTVe_v4.00.xsd`, `cteSimp_v4.00.xsd` e os dos modais),
#'   e a composição da chave de acesso pelo Manual de Orientação do
#'   Contribuinte do CT-e 4.00 (item 2.1.4).
#' @examples
#' cte = xml_para_lista(system.file("exemplos", "cte_proc_sp.xml", package = "RNFe"))
#' cte$ide$nCT = 4568
#' cte$ide$cCT = NULL
#' cte$ide$cDV = NULL
#' cte$Id = NULL
#' if (requireNamespace("openssl", quietly = TRUE)) {
#'   montado = cte_montar(cte)
#'   substr(montado, 1, 120)
#' }
#' @export
cte_montar = function(cte, documento = NULL, manter_vazios = FALSE, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_manter_vazios(manter_vazios)
  conferir_a_lista_do_documento(cte, "o CT-e", "do infCte (ide, emit, rem, dest, vPrest, imp, infCTeNorm...)", "infCte")
  documento = documento_do_cte(cte, documento)
  cte = com_o_ambiente(cte, ambiente, paste0("O ", documento))
  cte = completar_a_chave(cte, "CTe", "nCT", "cCT", modelo_que_falta = MODELO_DE_CADA_DOCUMENTO_DO_CTE[[documento]])
  montar_o_documento(documento, cte, manter_vazios)
}

# O documento: o informado, ou o que o mod e o tpCTe dizem.
documento_do_cte = function(cte, documento) {
  if (!is.null(documento)) {
    if (length(documento) != 1 || is.na(documento) || !(documento %in% names(MODELO_DE_CADA_DOCUMENTO_DO_CTE))) {
      stop("Informe o documento: ", paste0("\"", names(MODELO_DE_CADA_DOCUMENTO_DO_CTE), "\"", collapse = ", "), ".",
           call. = FALSE)
    }
    return(documento)
  }
  modelo = texto_do_campo(cte[["ide"]][["mod"]], "ide/mod")
  tipo = texto_do_campo(cte[["ide"]][["tpCTe"]], "ide/tpCTe")
  if (identical(modelo, "67")) {
    return("CT-e OS")
  }
  if (identical(modelo, "64")) {
    return("GTV-e")
  }
  if (identical(modelo, "57")) {
    if (!is.na(tipo) && tipo %in% TIPOS_DO_CTE_SIMPLIFICADO) {
      return("CT-e simplificado")
    }
    return("CT-e")
  }
  stop("Informe o modelo no ide$mod (57, 67 ou 64) ou o documento: ",
       paste0("\"", names(MODELO_DE_CADA_DOCUMENTO_DO_CTE), "\"", collapse = ", "), ".", call. = FALSE)
}
