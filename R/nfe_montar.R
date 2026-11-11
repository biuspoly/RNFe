# A montagem da NF-e e da NFC-e pelo schema do leiaute (o pacote de liberação em inst/schemas/nfe), com o que o RNFe
# completa sozinho: o ambiente, o número de cada item, o código numérico, o dígito e o Id da chave de acesso.

#' @include montar.R nfe_conferir.R nfe_conferir_regras.R
NULL

#' Montar uma NF-e ou NFC-e
#'
#' Monta o XML da NF-e (modelo 55) ou da NFC-e (modelo 65) a partir de uma
#' lista do R com os grupos e os campos do `infNFe`, com os nomes do leiaute
#' (`ide`, `emit`, `dest`, `det`, `total`, `transp`, `pag`, `infAdic`...). A
#' ordem e o formato vêm do schema oficial que acompanha o pacote, lido na
#' hora: os campos podem vir em qualquer ordem; o número vai com as casas
#' decimais que o padrão do campo aceita (`50` vira `50.00` no valor e `10`
#' vira `10.0` na quantidade, que aceita de 1 a 4 casas); a data e hora do R
#' vai com o fuso; e o código que perdeu o zero à esquerda (`1` no lugar de
#' `"01"`) volta a tê-lo quando o leiaute só aceita a forma com zero. Campo que
#' o leiaute não tem é recusado, com o nome e o lugar dele. No fim, o XML é
#' conferido no schema oficial.
#'
#' O que mudaria o valor é recusado, nunca ajustado calado: o número com mais
#' casas do que o campo aceita (arredonde antes, com `round()`); o número com
#' casas num campo da chave (o `cNF`, o `nNF`, o CNPJ); o número grande demais
#' para o R guardar exato (uma chave de 44 algarismos); o número num campo que
#' aceita o zero à esquerda com e sem ele (a IE, o telefone, o GTIN), onde o
#' número não diz qual era (esses vão como texto; na quantidade, como o
#' `qVol`, o número vai sem o zero); e o texto que o tipo do campo recusa
#' (um NCM de 9 algarismos), com o nome do campo.
#'
#' O campo com `NULL` ou `NA` fica de fora. O texto vazio (`""`) fica de fora
#' no campo opcional e sai como tag vazia no obrigatório que o aceita (como o
#' `cEAN`); com `manter_vazios = TRUE`, ele sai como tag vazia também no
#' campo e no grupo opcionais (`<cBenef></cBenef>`), para quando a tag vazia
#' for preciso. Assim se escolhe campo por campo: `""` é a tag vazia, `NA` é
#' a falta dela. Com `manter_vazios = TRUE`, a nota lida por
#' [xml_para_lista()] volta exatamente como era, com os vazios dela.
#'
#' O RNFe completa sozinho o que não vier: o `tpAmb` do ambiente, o `nItem` de
#' cada item (na ordem), o código numérico `cNF` (sorteado pelo gerador do
#' sistema, fora dos que a SEFAZ recusa), o dígito `cDV`, o `Id` com a chave
#' de acesso (na NF-e avulsa, com o CNPJ do órgão do grupo `avulsa`), a versão
#' do leiaute e o campo obrigatório que só aceita um valor (como o `CST` do
#' `ICMS00`). Quando o `cDV` ou o `Id` vêm, eles têm de conferir com os
#' campos da nota; o `cNF` informado vai como veio (o [nfe_conferir()] confere
#' a regra B03-10, dos códigos que a SEFAZ recusa).
#'
#' Cada grupo é uma lista com os campos dele; o grupo que aparece mais de uma
#' vez (os itens, as duplicatas, as formas de pagamento) é uma lista de
#' listas; o campo que se repete é um vetor. É a mesma forma que
#' [xml_para_lista()] devolve, então uma nota que já existe pode servir de
#' ponto de partida.
#'
#' A montagem não confere as regras de negócio da SEFAZ (os totais, o CFOP do
#' destino, o texto do destinatário em homologação): para isso, passe o
#' resultado no [nfe_conferir()] antes de enviar.
#'
#' Por enquanto, como o resto da conversa com a SEFAZ, só para o ambiente de
#' **homologação**: a nota com o `tpAmb` 1 é recusada.
#'
#' @param nota Uma lista com o conteúdo do `infNFe`, com os nomes do leiaute.
#' @param manter_vazios `TRUE` para o texto vazio (`""`) sair como tag vazia
#'   também no campo e no grupo opcionais.
#' @param ambiente Por enquanto só `"homologacao"`.
#' @return O XML da NF-e (o elemento `NFe`, ainda sem a assinatura), num
#'   texto: pronto para [xml_assinar()].
#' @seealso [xml_para_lista()], [nfe_conferir()], [xml_assinar()],
#'   [sefaz_autorizar()], [nfce_qrcode()] para o QR-Code da NFC-e.
#' @source Os schemas da NF-e e da NFC-e, pacote de liberação 010g, versão
#'   1.03 (Portal Nacional da NF-e, `nfe_v4.00.xsd` e `leiauteNFe_v4.00.xsd`);
#'   a composição da chave de acesso e o código numérico pelo Manual de
#'   Orientação do Contribuinte 7.0 (Anexo I, regra B03-10, da NT 2019.001).
#' @examples
#' nota = xml_para_lista(system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe"))
#' nota$ide$nNF = 1002
#' nota$ide$cNF = NULL   # sorteado de novo
#' nota$ide$cDV = NULL
#' nota$Id = NULL        # a chave nova sai dos campos
#' nota$det[[1]]$prod$vProd = 50
#' if (requireNamespace("openssl", quietly = TRUE)) {
#'   montada = nfe_montar(nota)
#'   substr(montada, 1, 120)
#' }
#' @export
nfe_montar = function(nota, manter_vazios = FALSE, ambiente = "homologacao") {
  conferir_ambiente(ambiente)
  conferir_manter_vazios(manter_vazios)
  conferir_a_lista_do_documento(nota, "a nota", "do infNFe (ide, emit, dest, det, total, transp, pag...)", "infNFe")
  nota = com_o_ambiente(nota, ambiente, "A nota")
  nota = nfe_com_os_itens_numerados(nota)
  nota = completar_a_chave(nota, "NFe", "nNF", "cNF", cnpj_no_lugar = cnpj_da_chave_da_avulsa(nota))
  montar_o_documento("NF-e", nota, manter_vazios)
}

# Os itens sem o nItem ganham o número da posição deles.
nfe_com_os_itens_numerados = function(nota) {
  if (is.null(nota[["det"]])) {
    return(nota)
  }
  itens = list()
  for (item in ocorrencias_do_grupo(nota[["det"]], "NFe/infNFe/det")) {
    if (is.list(item)) {
      itens[[length(itens) + 1]] = item
    }
  }
  for (posicao in seq_along(itens)) {
    if (is.na(texto_do_campo(itens[[posicao]][["nItem"]], "det/@nItem"))) {
      itens[[posicao]][["nItem"]] = posicao
    }
  }
  nota[["det"]] = itens
  nota
}

# Na NF-e avulsa emitida pelo Fisco (procEmi 1, com o grupo avulsa), a chave leva o CNPJ do órgão, o do grupo avulsa:
# assim nas 128 avulsas reais conferidas (veja o plano). Nos outros casos, NA (vale o do emitente).
cnpj_da_chave_da_avulsa = function(nota) {
  if (!is.list(nota[["avulsa"]])) {
    return(NA_character_)
  }
  # A avulsa emitida pelo contribuinte no site do Fisco (procEmi 2) também tem o grupo, mas nenhuma nota real assim foi
  # conferida: o CNPJ da chave dela não é certo, e a chave vem de quem a emitiu.
  processo_de_emissao = texto_do_campo(nota[["ide"]][["procEmi"]], "ide/procEmi")
  if (identical(processo_de_emissao, "2")) {
    stop("Na NF-e avulsa emitida no site do Fisco (procEmi 2), a chave \u00e9 a que o site gerou: a regra do CNPJ da chave ",
         "dela n\u00e3o foi conferida com notas de verdade, e a montagem n\u00e3o a calcula.", call. = FALSE)
  }
  if (!identical(processo_de_emissao, "1")) {
    return(NA_character_)
  }
  if (is.numeric(nota[["avulsa"]][["CNPJ"]])) {
    return(com_zeros(nota[["avulsa"]][["CNPJ"]], 14, "avulsa/CNPJ"))
  }
  texto_do_campo(nota[["avulsa"]][["CNPJ"]], "avulsa/CNPJ")
}
