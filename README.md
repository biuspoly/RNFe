# RNfe

Documentos fiscais eletrônicos brasileiros (NF-e, NFC-e, CT-e, MDF-e) no **R**.

> **Em construção.** Esta versão traz a chave de acesso e a leitura do XML da NF-e e da NFC-e. As tabelas
> fiscais (CFOP, CST, NCM...) vêm a seguir; o plano está em
> [docs/plano.md](https://github.com/biuspoly/RNfe/blob/main/docs/plano.md).

## Instalar

```r
remotes::install_github("biuspoly/RNfe")
```

## Chave de acesso

A chave de 44 posições que identifica cada documento: conferir, desmontar e calcular o dígito, já com o
**CNPJ alfanumérico** (CNPJ com letras), em produção desde 06/07/2026.

```r
library(RNfe)

chave_valida("35261011444777000161550010000001231123456783")    # TRUE
chave_decompor("35261012ABC34501DE35550010000001231123456784")  # UF, ano, mês, CNPJ, modelo, série, número...
chave_digito("35261011444777000161550010000001231123456789")     # 3: o dígito que a chave deveria ter
```

`chave_decompor()` devolve uma linha por chave e, quando algo não confere, diz o quê na coluna `problema`
(o dígito, o CNPJ do emitente, a UF, o mês ou o formato). Espaços e o prefixo do `Id` do XML (`NFe...`) são
ignorados. Na NF-e avulsa, emitida pelo Fisco, o CNPJ da chave é o do órgão que a emitiu, não o do emitente.

Conferido com 135 mil chaves reais de NF-e e CT-e (que não estão no repositório): todas válidas, e as partes
iguais às do XML de cada nota. As 135 mil são desmontadas em uns 2 segundos.

## Ler o XML da NF-e e da NFC-e

```r
lida = nfe_ler(c("nota1.xml", "nota2.xml"))   # ou o próprio texto do XML
lida$notas        # uma linha por nota: emitente, destinatário, totais (com IBS e CBS), protocolo
lida$itens        # uma linha por item: produto, CFOP, NCM e os impostos principais em colunas
lida$impostos     # todos os campos de imposto de cada item, um por linha
lida$parcelas     # as duplicatas
lida$pagamentos   # as formas de pagamento
lida$arquivos     # o que foi lido, e o motivo de cada arquivo que não deu
```

Segue o schema oficial mais recente (pacote de liberação PL_010g, de 26/10/2026), já com os campos da Reforma
Tributária. Conferido com 10 mil notas reais (que não estão no repositório): os campos comparados bateram em
todas.

## De onde vêm as regras

Das especificações públicas do [Portal Nacional da NF-e](https://www.nfe.fazenda.gov.br/portal/): o Manual de
Orientação do Contribuinte (a composição da chave) e a Nota Técnica Conjunta 2025.001, versão 1.00 (o CNPJ
alfanumérico na chave e no cálculo dos dígitos: cada caractere vale o código ASCII menos 48). Nada aqui
consulta a SEFAZ.

Nos exemplos e nos testes, só CNPJs e CPFs fictícios; o 12.ABC.345/01DE-35 é o exemplo da Receita Federal.

## Licença

MIT.
