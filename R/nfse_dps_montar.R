# A montagem da DPS (a Declaração de Prestação de Serviço, que a Sefin Nacional transforma em NFS-e) pelo schema do
# leiaute. Na homologação, a Produção Restrita usa o leiaute que vem (o da NT 009, em inst/schemas/nfse_producao_restrita),
# e é ele que a montagem segue; a produção, quando for liberada, segue o de inst/schemas/nfse.

#' @include montar.R nfse_emitir.R
NULL

# O grupo do emitente da DPS, pelo tpEmit (1, o prestador; 2, o tomador; 3, o intermediário).
GRUPO_DO_EMITENTE_DA_DPS = c("1" = "prest", "2" = "toma", "3" = "interm")

#' Montar uma DPS da NFS-e Nacional
#'
#' Monta o XML da DPS (a Declaração de Prestação de Serviço, que a Sefin
#' Nacional transforma em NFS-e) a partir de uma lista com os grupos e os
#' campos do `infDPS`, com os nomes do leiaute (`tpAmb`, `dhEmi`, `serie`,
#' `nDPS`, `dCompet`, `tpEmit`, `cLocEmi`, `prest`, `toma`, `serv`,
#' `valores`, `IBSCBS`...), como o [nfe_montar()] faz com a NF-e: a ordem, o
#' formato dos números e das datas e o que é atributo vêm do schema oficial
#' que acompanha o pacote, e o resultado é conferido nele.
#'
#' Na homologação (a Produção Restrita da NFS-e Nacional), a montagem segue o
#' schema que a Produção Restrita usa, o da NT SE/CGNFS-e 009 (de 20/10/2026).
#'
#' O RNFe completa sozinho o que não vier: o `tpAmb` do ambiente, a versão do
#' leiaute, o campo obrigatório que só aceita um valor e o `Id`: "DPS", o
#' município de emissão (`cLocEmi`), o tipo e o número da inscrição federal do
#' emitente da DPS (o prestador, o tomador ou o intermediário, pelo `tpEmit`;
#' o CPF com zeros à esquerda), a série (5 posições) e o número (15).
#'
#' @param dps Uma lista com o conteúdo do `infDPS`, com os nomes do leiaute.
#' @inheritParams nfe_montar
#' @return O XML da DPS (o elemento `DPS`, ainda sem a assinatura), num texto:
#'   pronto para o [nfse_emitir()], que assina e envia.
#' @seealso [xml_para_lista()], [nfse_emitir()], [nfse_ler()]
#' @source Os schemas da NFS-e Nacional da Produção Restrita (NT SE/CGNFS-e
#'   009, pacote de 20/10/2026, `DPS_v1.01.xsd`) e o Anexo I do leiaute da DPS
#'   (a formação do identificador da DPS e a regra E0004).
#' @examples
#' # A DPS de uma NFS-e da versão 1.01 de produção, passada para o leiaute da
#' # NT 009: a finalidade sai do IBSCBS para o infDPS, e o CST e a
#' # classificação saem do gIBSCBS.
#' dps = xml_para_lista(system.file("exemplos", "nfse_sp_v101.xml", package = "RNFe"))
#' dps$nDPS = 2
#' dps$Id = NULL   # sai dos campos
#' dps$finNFSe = dps$IBSCBS$finNFSe
#' dps$IBSCBS$finNFSe = NULL
#' dps$IBSCBS$valores$trib = dps$IBSCBS$valores$trib$gIBSCBS
#' montada = nfse_dps_montar(dps)
#' substr(montada, 1, 120)
#' @export
nfse_dps_montar = function(dps, manter_vazios = FALSE, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_manter_vazios(manter_vazios)
  conferir_a_lista_do_documento(dps, "a DPS", "do infDPS (tpAmb, dhEmi, serie, nDPS, prest, toma, serv, valores...)", "infDPS")
  dps = com_o_ambiente_da_dps(dps, ambiente)
  dps = dps_com_o_identificador(dps)
  montar_o_documento("DPS", dps, manter_vazios, list(versao = versao_do_schema_da_dps()))
}

# A versão do leiaute da DPS (o atributo versao do elemento DPS, fora do infDPS) é a do arquivo do schema que o pacote
# traz (DPS_v1.01.xsd): o tipo dela aceita 1.00 e 1.01, e a montagem segue o schema que tem.
versao_do_schema_da_dps = function() {
  sub("^.*_v([0-9]+\\.[0-9]+)\\.xsd$", "\\1", DOCUMENTOS_PARA_MONTAR[["DPS"]]$arquivos[1])
}

# Na DPS, o tpAmb fica direto no infDPS.
com_o_ambiente_da_dps = function(dps, ambiente) {
  tipo_de_ambiente = as.character(AMBIENTES_LIBERADOS[[ambiente]])
  informado = texto_do_campo(dps[["tpAmb"]], "tpAmb")
  if (is.na(informado)) {
    dps[["tpAmb"]] = tipo_de_ambiente
  } else if (informado != tipo_de_ambiente) {
    stop("A DPS tem de ser do ambiente de homologa\u00e7\u00e3o (tpAmb 2).", call. = FALSE)
  }
  dps
}

# O Id da DPS, pelo Anexo I: "DPS" + município de emissão (7) + tipo de inscrição (1 CPF, 2 CNPJ) + inscrição do
# emitente (14, o CPF com zeros à esquerda) + série (5) + número (15).
dps_com_o_identificador = function(dps) {
  faltam = character()
  for (nome_do_campo in c("cLocEmi", "tpEmit", "serie", "nDPS")) {
    if (is.na(texto_do_campo(dps[[nome_do_campo]], nome_do_campo))) {
      faltam = c(faltam, nome_do_campo)
    }
  }
  tipo_do_emitente = texto_do_campo(dps[["tpEmit"]], "tpEmit")
  grupo_do_emitente = NA_character_
  if (!is.na(tipo_do_emitente) && tipo_do_emitente %in% names(GRUPO_DO_EMITENTE_DA_DPS)) {
    grupo_do_emitente = GRUPO_DO_EMITENTE_DA_DPS[[tipo_do_emitente]]
  } else if (!is.na(tipo_do_emitente)) {
    stop("O tpEmit da DPS tem de ser 1 (prestador), 2 (tomador) ou 3 (intermedi\u00e1rio).", call. = FALSE)
  }
  inscricao = NA_character_
  if (!is.na(grupo_do_emitente)) {
    emitente = dps[[grupo_do_emitente]]
    if (!is.list(emitente)) {
      emitente = list()
    }
    caminho_do_cnpj = paste0(grupo_do_emitente, "/CNPJ")
    caminho_do_cpf = paste0(grupo_do_emitente, "/CPF")
    if (is.numeric(emitente[["CNPJ"]])) {
      emitente[["CNPJ"]] = com_zeros(emitente[["CNPJ"]], 14, caminho_do_cnpj)
    }
    if (is.numeric(emitente[["CPF"]])) {
      emitente[["CPF"]] = com_zeros(emitente[["CPF"]], 11, caminho_do_cpf)
    }
    cnpj = texto_do_campo(emitente[["CNPJ"]], caminho_do_cnpj)
    cpf = texto_do_campo(emitente[["CPF"]], caminho_do_cpf)
    if (!is.na(cnpj)) {
      inscricao = paste0("2", cnpj)
    } else if (!is.na(cpf)) {
      inscricao = paste0("1000", cpf)
    } else {
      faltam = c(faltam, paste0(grupo_do_emitente, "/CNPJ (ou ", grupo_do_emitente, "/CPF)"))
    }
    if (length(emitente) > 0) {
      dps[[grupo_do_emitente]] = emitente
    }
  }
  if (length(faltam) > 0) {
    stop("Para montar o Id da DPS faltam: ", paste(faltam, collapse = ", "), ".", call. = FALSE)
  }
  # O Id fora do padrão (uma série com letra, por exemplo) é recusado depois, pelo schema.
  identificador = paste0("DPS", texto_do_campo(dps[["cLocEmi"]], "cLocEmi"), inscricao, com_zeros(dps[["serie"]], 5, "serie"),
                         com_zeros(dps[["nDPS"]], 15, "nDPS"))
  identificador_informado = texto_do_campo(dps[["Id"]], "Id")
  if (!is.na(identificador_informado) && identificador_informado != identificador) {
    stop("O Id informado (", identificador_informado, ") n\u00e3o confere com os campos da DPS: o certo \u00e9 ", identificador, ".",
         call. = FALSE)
  }
  dps[["Id"]] = identificador
  dps
}
