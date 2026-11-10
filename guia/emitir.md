# Assinar, enviar e registrar eventos (homologação)

[Voltar ao início](../README.md)

```r
assinada = xml_assinar("nota.xml", "empresa.pfx", senha)   # a NF-e, NFC-e, CT-e, MDF-e, DPS ou evento assinado
nfe_conferir(assinada)                                      # confira antes de enviar
resposta = sefaz_autorizar(assinada, "empresa.pfx", senha)  # a situação (100), o protocolo e o nfeProc
writeLines(resposta$xml_autorizado, "nota_autorizada.xml", useBytes = TRUE)

sefaz_carta_correcao(resposta$chave, "ONDE SE LE RUA 10, LEIA-SE RUA 100", 1, "empresa.pfx", senha)
sefaz_cancelar(resposta$chave, resposta$protocolo, "PEDIDO CANCELADO PELO CLIENTE", "empresa.pfx", senha)
sefaz_manifestar(chave_recebida, "ciencia", certificado = "empresa.pfx", senha = senha)   # o destinatário
sefaz_cte_desacordo(chave_do_cte, "FRETE COBRADO EM DUPLICIDADE", "empresa.pfx", senha)   # o tomador do CT-e

mdfe = sefaz_mdfe_autorizar(xml_assinar("mdfe.xml", "empresa.pfx", senha), "empresa.pfx", senha)   # o MDF-e
sefaz_mdfe_incluir_condutor(mdfe$chave, "NOME DO MOTORISTA", cpf_do_motorista, certificado = "empresa.pfx", senha = senha)
sefaz_mdfe_incluir_dfe(mdfe$chave, mdfe$protocolo, "2611606", "Recife", chaves_das_nfe, "2611606", "Recife",
                       certificado = "empresa.pfx", senha = senha)   # as NF-e do MDF-e com carregamento posterior
sefaz_mdfe_encerrar(mdfe$chave, mdfe$protocolo, "PE", "2611606", Sys.Date(), "empresa.pfx", senha)

nfse = nfse_emitir("dps.xml", "empresa.pfx", senha)          # a NFS-e Nacional gerada a partir da DPS
nfse_cancelar(nfse$chave, "erro_na_emissao", "VALOR DO SERVICO INFORMADO ERRADO", "empresa.pfx", senha)

nfce = nfce_qrcode("nfce.xml", endereco_qrcode_da_uf, endereco_consulta_da_uf)   # o QR-Code da NFC-e (versão 3)
nfce = nfce_qrcode("nfce.xml", endereco_qrcode_da_uf, endereco_consulta_da_uf, "empresa.pfx", senha)  # off-line
```

A assinatura segue o Manual de Orientação: o elemento que tem o `Id` (`infNFe`, `infCte`, `infMDFe`, `infDPS`,
`infEvento`) é canonicalizado (C14N), o resumo SHA-1 dele vai na assinatura e o `SignedInfo` é assinado com a chave
do certificado (RSA); a DPS da NFS-e Nacional usa o SHA-256. A canonicalização é feita pelo RNFe e foi conferida com
1.000 NF-e reais autorizadas (o mesmo resumo e a assinatura verificada em todas) e com o PyNFe, que assina o mesmo XML
igual, byte a byte (ele tira os acentos antes; o RNFe não). O XML assinado vem sem os espaços entre as tags, que a
SEFAZ rejeita.

A autorização manda cada nota num lote só dela, no modo síncrono (a NT 2023.002 acaba com o assíncrono em 2027); se a
SEFAZ responde que vai processar depois (103), o RNFe consulta o recibo enquanto ele estiver em processamento (105). A
nota denegada também volta com o `nfeProc` (a SEFAZ guarda a nota com o protocolo da denegação). O autor do
cancelamento, da carta de correção e dos eventos do MDF-e é o emitente da chave, e o certificado pode ser o de outro
estabelecimento da empresa (o mesmo CNPJ-base): a nota de uma filial pode ser cancelada com o certificado da matriz. Na
manifestação e no desacordo do CT-e, o autor é o destinatário ou o tomador; quando é uma filial e o certificado é o da
matriz, ele vai em `destinatario` ou em `tomador`. A nota autorizada vem
com o `nfeProc` (a nota e o protocolo), que o `nfe_ler()` lê. Os eventos (cancelamento, carta de correção e
manifestação do destinatário, esta no Ambiente Nacional) são montados, assinados e enviados pelo RNFe, e voltam com o
`procEventoNFe`, que o `eventos_ler()` lê. O tomador do CT-e registra a prestação do serviço em desacordo (e cancela
o registro feito por engano) no autorizador do CT-e, com o `procEventoCTe` de volta.

O MDF-e vai compactado e é autorizado na hora pela SVRS, que atende todas as UF; o QR-Code dele entra sozinho
quando falta (no MDF-e em contingência, com a chave assinada pelo certificado, o parâmetro `sign`). Depois vêm a inclusão de condutor e o encerramento, com o `procEventoMDFe` de volta.
No MDF-e emitido com carregamento posterior (`indCarregaPosterior` 1: carga própria dentro da UF, quando o emitente,
no início da viagem, não tem acesso aos documentos fiscais transportados), as NF-e entram depois, pela inclusão de DF-e, com o município de carregamento e o de
descarregamento de cada nota; ele só se encerra depois de uma inclusão. Testado na SVRS de homologação em 10/11/2026:
o MDF-e com carregamento posterior foi autorizado (100), duas inclusões foram registradas (135; a segunda com a
sequência 2, embora o MOC diga que só vale a 1) e ele foi encerrado (135). A NFS-e Nacional é
gerada pela Sefin a partir da DPS que você monta pelo leiaute; o RNFe assina, compacta, envia e devolve a NFS-e (que o
`nfse_ler()` lê). O cancelamento também é montado e assinado aqui.

O QR-Code da NFC-e sai na versão 3 (NT 2025.001), que não usa mais o CSC: na emissão normal, a chave, a versão e o
ambiente; na contingência off-line, também o dia da emissão, o valor, o destinatário e a assinatura desses dados com o
mesmo certificado que assina a nota. Os endereços da consulta são os da UF do emitente, publicados no Portal da NFC-e,
e vão como argumento. O grupo sai no lugar certo para o schema, e a assinatura da nota não o cobre (pode ser antes ou
depois de `xml_assinar()`).

Testado na SVRS de homologação em 05/11/2026 com o certificado de uma empresa: uma NF-e montada a partir de uma nota
real, com o tpAmb 2, foi assinada pelo RNFe e autorizada (100); a carta de correção e o cancelamento foram registrados
(135) e a ciência da operação, no Ambiente Nacional (136). As rejeições que vieram antes foram de regras que a
pré-conferência acusa: o indicador do intermediador (434) e o CPF do transportador zerado (543) ela já acusava; o
vencimento da parcela antes da emissão (900, a Y09-20) entrou nela depois desse teste. O desacordo de um CT-e
inventado voltou "CT-e não consta na base de dados" (217): o evento passou pelo schema, pela assinatura e pelo órgão
de recepção. Um MDF-e de carga própria foi autorizado (100), ganhou um condutor e foi encerrado (135 nos dois). Na
Produção Restrita da NFS-e Nacional, uma NFS-e foi gerada (201) a partir de uma DPS montada sobre uma nota real e
cancelada (201). A Produção Restrita já usa o leiaute da NT 009 (o XSD de 20/10/2026, com o `finNFSe` e outra ordem
no `cServ`), que o pacote de schemas que o `nfse_ler()` segue ainda não traz; a série da DPS enviada por sistema
próprio é outra que a do Emissor Nacional (a 70000 voltou E0010, a 1 passou). Só a homologação: a nota com o tpAmb 1 nem é enviada.

---

[Voltar ao início](../README.md)
