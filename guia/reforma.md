# IBS e CBS: a Reforma Tributária

[Voltar ao início](../README.md)

## IBS e CBS: a conferência da Reforma

```r
conferida = ibs_cbs_conferir("nota.xml")    # um arquivo, vários ou o texto do XML
conferida$notas                             # por nota: itens com IBS e CBS, regras conferidas, erradas e sem conferir
conferida$conferencias                      # o que não confere: regra, campo, no documento, esperado, diferença,
                                            # o código e a mensagem da rejeição da SEFAZ e a observação
ibs_cbs_conferir("nota.xml", todas_as_regras = TRUE)   # também as que conferem
```

Confere o IBS e a CBS da NF-e e da NFC-e pelas regras de validação da NT 2025.002-RTC (v1.53): os códigos (o CST
e a classificação existem, combinam e valem no modelo), os grupos que cada CST e cada classificação exigem ou não
permitem, as alíquotas do ano, as contas de cada item (redução, alíquota efetiva, diferimento, devolução, valor do
IBS da UF, do município e da CBS, tributação regular, compra governamental), a nota de débito e de crédito (a
classificação combina com o tipo da nota, a transferência de crédito, o ajuste de competência e o estorno com valor,
o crédito presumido da ZFM), o crédito presumido da operação pela tabela `cCredPres` (o código, os grupos que ele
exige, o desconto no IBS do item, o crédito em condição suspensiva), a CBS zero na ZFM e nas ALC e os totais. Confere
também a tributação monofásica de combustíveis no leiaute novo da NT (v1.50, em produção desde 16/11/2026): os
grupos de cada ano, os subgrupos que a classificação pede, a quantidade vezes a alíquota ad rem, a quantidade de
biocombustível pela mistura obrigatória da data e os totais. E o resto da nota que a mesma NT valida: a previsão de
entrega, os documentos referenciados, o tipo da nota de débito e de crédito, o local da operação (`cIndOp`), a
compra governamental e as chaves dos documentos anteriores, a inscrição na Suframa (com o dígito), os tributos de
cada item na nota de débito e de crédito, o CFOP da devolução, o ICMS monofásico, o item de outro documento citado
no item e o total dos produtos. Como na NT, só a nota com IBS, CBS ou Imposto Seletivo é conferida. Cada
conferência traz a
regra (`UB35-10`), o código e a mensagem que a SEFAZ daria (`1041`, "Valor do IBS da UF difere do calculado") e, nas
contas, a diferença. O valor calculado vai a 2 casas antes da tolerância de 0,01, porque a SEFAZ autoriza assim.

Cada regra vale como a SEFAZ a aplicava no dia da emissão: a regra que ainda não estava em produção não é conferida
(pelo cronograma da NT), e o que não confere hoje mas pode ter conferido na época vem sem conferir (`confere` vazio),
com o motivo: a regra mudou depois da emissão, ou a linha da tabela de classificação que ela consulta mudou numa
versão que talvez ainda não estivesse em produção. Por exemplo, a classificação 550002 deixou de valer na NF-e na
versão 1.60 da tabela (publicada em 23/06/2026, em produção até 06/07/2026): numa nota de 1º de julho ela vem sem
conferir, numa de agosto, errada. As versões que o Informe Técnico não dá prazo (da 1.21 à 1.40) ficam sem prazo
conhecido: a SEFAZ autorizou NF-e com a 200001, que a 1.40 tirou da NF-e, um mês depois do prazo da versão seguinte.
Essas mudanças estão em `tabela_fiscal("mudancas_ibs_cbs")`, montada pelo robô das tabelas comparando as versões
publicadas desde 03/10/2025.

Ficam de fora as regras que a NT deixa para implementação futura (as do Imposto Seletivo entre elas; as 31 da v1.53
estão em `tabela_fiscal("regras_ibs_cbs")`, sem a data de produção) e as quatro
que a SEFAZ confere no documento guardado na base dela (BB05-170, BB05-190, BB05-200 e VC02-50). Duas contas do
monofásico ficam sempre sem conferir, com o motivo: o valor ad valorem que não bate com a alíquota lida como
percentual (a NT não diz a unidade) e o valor da diferença do biocombustível (a tabela que ele usa ainda não foi
publicada).

## IBS e CBS: o cálculo e a simulação

```r
calculada = ibs_cbs_calcular("nota.xml")            # na data da nota: o que cada item deveria trazer
calculada$itens                                     # base, alíquotas, redução, diferimento, valores, tributação regular
calculada$notas                                     # os totais de cada nota
ibs_cbs_calcular("nota.xml", data = "2027-03-10", aliquotas = c(cbs = 8.7))   # a mesma nota em 2027
ibs_cbs_calcular(nfe_ler("nota.xml"))                # ou o que o nfe_ler() leu (a lista inteira)
ibs_cbs_calcular(itens, data = "2026-11-04")         # ou itens soltos, num data.frame que você monta
```

Calcula o IBS da UF, o do município e a CBS de cada item, pelas mesmas fórmulas que a conferência confere. A base é
a soma da regra UB16-10 da NT (produto, frete, seguro, outras despesas, II e Imposto Seletivo, menos o desconto e os
tributos que não entram), e cada componente só entra no ano, na natureza e no modelo em que a calculadora oficial o
aceita: o PIS e a COFINS só em 2026, o ICMS e o ISSQN até 2032, o Imposto Seletivo a partir de 2027, o II e o ICMS
só no bem, o ISSQN só no serviço, o II, o ICMS da UF de destino e o FCP dele só na NF-e. A alíquota é a do ano, com a redução da
classificação; o diferimento e a tributação regular (a suspensão) entram com o que a nota informa. Para simular
outro ano, passe a data e, enquanto a alíquota do ano não for publicada (a CBS de 2027 em diante, o IBS de 2029 em
diante), a estimativa dela em `aliquotas`. Só `nfe_ler()$itens` não serve: a data, a finalidade e a compra
governamental estão nas notas, e a função pede a lista inteira.

Conferido com a calculadora oficial da Receita (o piloto da Reforma) em 51 itens inventados, de 11 classificações
(uma de cada caso que o cálculo cobre), em 2026, 2027 e 2030: a base, as alíquotas, a redução, o diferimento, a
tributação regular e o valor de cada parte saíram iguais, até o meio centavo, que vai para o par como lá. Em dois
pontos o RNFe segue a NT, que é o que a SEFAZ confere: o IBS do item é a soma do da UF e do município (a calculadora
arredonda o total à parte) e a classificação do CST 200 com tributação regular traz o grupo de redução. No acervo de
notas reais, com a base da própria nota, o IBS e a CBS calculados bateram (até 0,01) com os da nota em todos os
15.816 itens calculados com o grupo e as alíquotas de 2026, menos um (a CBS de uma nota que a conferência também
acusa).

Fica sem calcular, com o motivo: a nota que não é normal (a devolução, a complementar, a de ajuste e as de crédito e
de débito, que dependem da operação original), o monofásico (CST 620), a transferência de crédito e os ajustes (CST
800 a 820), a exclusão da base (CST 830, que a calculadora oficial também não trata), as alíquotas fixas e uniformes,
a compra governamental, o item com crédito presumido ou com valor de devolução de tributos, a base negativa e o Imposto
Seletivo.

---

[Voltar ao início](../README.md)
