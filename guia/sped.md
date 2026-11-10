# SPED Fiscal: a EFD ICMS/IPI em tabelas

[Voltar ao início](../README.md)

```r
efd = efd_icms_ipi_ler("efd.txt")    # um arquivo, vários ou o próprio texto
efd$arquivos                         # o período, a versão do leiaute e o que não deu para ler
efd$C100                             # as notas, com os nomes de campo do leiaute (NUM_DOC, CHV_NFE, VL_DOC...)
efd$C170                             # os itens; linha_pai é a linha do C100 de cada um
efd$problemas                        # cada linha que não entrou numa tabela, com o motivo
efd_icms_ipi_ler("efd.txt", registros = c("C100", "C170"))   # só o que interessa
cruzamento = efd_icms_ipi_cruzar_nfe("efd.txt", "notas/", eventos = "eventos/")  # a EFD contra os XML das notas
cruzamento$notas                     # cada nota: nas duas, só na EFD ou só nos XML
cruzamento$diferencas                # cada campo que não confere, com os dois valores
```

Lê o arquivo da Escrituração Fiscal Digital do ICMS e do IPI, o que a empresa gera todo mês e transmite pelo programa
da Receita (o RNFe só lê o arquivo; não transmite nada). Cada registro vira uma tabela, com os nomes de campo do
leiaute oficial, e `linha_pai` liga cada registro ao de nível acima (o item à nota). O leiaute é o do período do
arquivo: um arquivo de 2016 é lido sem os campos que entraram depois e com o E310 e o C177 da época. Os valores com
casas decimais viram número, as datas viram `Date` e o resto fica texto, com os zeros à esquerda (CNPJ, CFOP, CST,
chave). O arquivo pode estar em Latin-1, como pede o leiaute, ou em UTF-8, e a assinatura depois do 9999 é ignorada.

O cruzamento confere cada nota do C100 (NF-e e NFC-e) com o XML dela, pela chave, como o Guia Prático manda
escriturar: o número, a data, os valores, o participante e, com os eventos, a situação (a cancelada, inclusive por
substituição, tem de estar escriturada como cancelada). O ICMS do C100 inclui o FCP. Na entrada, os impostos da EFD são
os do crédito de quem escritura e não se comparam com os do XML; na NFC-e, o C100 não traz o ICMS-ST, o IPI, o PIS e a
COFINS; o PIS e a COFINS vazios (de quem entrega a EFD-Contribuições) e os valores da complementar e da nota de regime
especial, que são facultativos, só se comparam quando vêm. A partir de 2027, o valor do documento pode ser o da nota
com o IBS, a CBS e o IS. As notas do contribuinte que estão nos XML e não na EFD também aparecem: a emissão própria
autorizada do período tem de estar lá (a denegada não precisa); a de terceiros pode ter entrado em outro mês; a NFC-e
recebida não se escritura. Vinte mil notas se cruzam em um segundo.

O leiaute está em `tabela_fiscal("leiaute_efd_icms_ipi")`: os 270 registros e os 2.225 campos, com a descrição e a
vigência de cada um. Ele sai do Guia Prático da EFD ICMS/IPI (versão 3.2.2) e da Nota Técnica do leiaute 020, do
portal do SPED, lidos e conferidos um contra o outro por `ferramentas/gerar_leiaute_efd.py`. As poucas divergências
entre os dois documentos estão em `ferramentas/leiaute_efd_decisoes.csv`, com o motivo; quando eles discordam, vale o
Guia, que é o mais novo.

---

[Voltar ao início](../README.md)
