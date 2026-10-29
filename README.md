# RNfe

Documentos fiscais eletrônicos brasileiros (NF-e, NFC-e, CT-e, MDF-e) no **R**.

> **Em construção.** Esta versão traz a chave de acesso. A leitura do XML da nota e as tabelas fiscais
> (CFOP, CST, NCM...) vêm a seguir; o plano está em
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
chave_digito("3526101144477700016155001000000123112345678")      # 3
```

`chave_decompor()` devolve uma linha por chave e, quando algo não confere, diz o quê na coluna `problema`
(o dígito, o CNPJ do emitente, a UF, o mês ou o formato). Espaços e o prefixo do `Id` do XML (`NFe...`) são
ignorados.

## De onde vêm as regras

Das especificações públicas do [Portal Nacional da NF-e](https://www.nfe.fazenda.gov.br/portal/): o Manual de
Orientação do Contribuinte (a composição da chave) e a Nota Técnica Conjunta 2025.001, versão 1.00 (o CNPJ
alfanumérico na chave e no cálculo dos dígitos: cada caractere vale o código ASCII menos 48). Nada aqui
consulta a SEFAZ.

Nos exemplos e nos testes, só CNPJs e CPFs fictícios; o 12.ABC.345/01DE-35 é o exemplo da Receita Federal.

## Licença

MIT.
