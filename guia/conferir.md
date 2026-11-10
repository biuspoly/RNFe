# Antes de enviar: a pré-conferência da NF-e

[Voltar ao início](../README.md)

```r
conferida = nfe_conferir("nota.xml")     # um arquivo, vários ou o texto do XML, assinado ou não
conferida$notas                           # por nota: se está assinada, se o schema valida, regras erradas e sem conferir
conferida$schema                          # cada erro do schema, com o campo e o que ele esperava
conferida$conferencias                    # cada regra que não confere: o campo, o que veio, o esperado, o código e a
                                          # mensagem da rejeição, se a regra é obrigatória ou facultativa e a observação
nfe_conferir("nota.xml", agora = Sys.time() + 600)   # o momento do envio, para as regras de prazo
```

Confere a NF-e e a NFC-e como a SEFAZ confere ao receber, para saber antes de enviar o que seria rejeitado. Primeiro o
schema: o XML contra o pacote de liberação mais novo do Portal da NF-e (o PL_010g, versão 1.03, que vai junto com o
RNFe), com a mensagem do validador para cada campo errado. A nota ainda sem a assinatura é conferida assim mesmo (a
falta dela não conta como erro). Depois, as regras de validação do Anexo I do Manual de Orientação do Contribuinte,
cada uma pela redação da nota técnica mais nova que a mudou: a chave de acesso e o código numérico, os prazos da
emissão e da saída, o modelo do DANFE, a finalidade, a presença e o intermediador, a série de cada processo de emissão
(o PAA da NT 2026.001 entre eles), a contingência, os documentos referenciados (o dígito, a UF, o modelo e a repetição
de cada chave; a NF modelo 1, a de produtor e o cupom fiscal, que a NT 2026.002 proibiu), o emitente e o destinatário
(o CNPJ e o CPF com o dígito, o município, a UF de cada tipo de operação, o estrangeiro, a inscrição estadual e a da
Suframa), a retirada e a entrega, quem pode baixar o XML, o produto (o GTIN com o dígito, o NCM e o CFOP nas tabelas
do pacote, o CFOP de cada operação e as contas do valor), o ICMS do item, os grupos que a NFC-e não pode ter, os totais,
o transporte, a cobrança (o vencimento de cada parcela), os pagamentos (o cartão, a integração, a data do pagamento,
o troco) e o QR-Code (a versão e a chave). A NF-e com o DANFE Simplificado Tipo 2 (NT 2026.002) segue as regras da
NFC-e, o MEI entre elas. As regras da Reforma vêm de `ibs_cbs_conferir()`, na mesma tabela, para a nota que tem o IBS e
a CBS. A mesma nota em mais de um arquivo (o XML assinado e o `nfeProc`, por exemplo) é conferida uma vez, a do arquivo
com o protocolo.

Cada regra vale como a SEFAZ a aplicava no dia da emissão: a C17-10 (a IE do emitente) sai em 16/11/2026, quando a NT
2026.007 deixa o contribuinte só do IBS e da CBS emitir sem ela, e a C17-42 entra; a BA02-35 (a NFC-e referenciada na
NF-e de saída) só entra em 14/12/2026. O código que não está na tabela de hoje numa nota de antes dela fica sem
conferir. A regra que vale "a critério da UF" fica sem conferir quando não confere, com o motivo, e a facultativa vem
marcada assim, porque a SEFAZ pode não aplicá-la. Fica de fora o que depende da base da SEFAZ (o cadastro, a
duplicidade, a nota referenciada que ela guarda), a inscrição estadual (o cálculo muda de UF para UF) e as tabelas de
cada UF.

Conferido em quatro amostras de NF-e reais autorizadas (de 4.200 a 5.548 notas cada uma, de todas as UF, de 2021 a
2026; a última depois da revisão da etapa): as regras que acusam erro em nota autorizada são as facultativas (contas
que a SEFAZ não confere ao centavo) e as que nem toda SEFAZ aplica, que dizem isso na observação (o indicador do
intermediador em SP, o CPF zerado do transportador no RN). O schema acusa as notas
do monofásico de combustíveis da Reforma emitidas no leiaute anterior ao pacote 010g.

---

[Voltar ao início](../README.md)
