# RNFe

Documentos fiscais eletrônicos brasileiros (NF-e, NFC-e, CT-e, GTV-e, MDF-e, NFS-e) no **R**: ler o XML em
tabelas, conferir a nota antes de enviar, conferir e calcular o IBS e a CBS da Reforma Tributária, falar com a
SEFAZ, emitir e desenhar os PDFs.

> **Em desenvolvimento.** O que fala com a SEFAZ funciona, por enquanto, só no ambiente de homologação (na NFS-e
> Nacional, na Produção Restrita). Ainda não está no CRAN. O plano e a situação de cada parte estão em
> [docs/plano.md](https://github.com/biuspoly/RNFe/blob/main/docs/plano.md).

## Instalar

```r
remotes::install_github("biuspoly/RNFe")
```

## Um exemplo

```r
library(RNFe)

chave_valida("35261011444777000161550010000001231123456783")    # TRUE

lida = nfe_ler(c("nota1.xml", "nota2.xml"))   # ou o próprio texto do XML
lida$notas        # uma linha por nota: emitente, destinatário, totais (com IBS e CBS), protocolo
lida$itens        # uma linha por item: produto, CFOP, NCM e os impostos principais em colunas
```

## O que tem em cada página

| Página | O que tem |
|---|---|
| [Ler os documentos](guia/ler.md) | A chave de acesso (também achada num PDF ou numa foto) e o XML da NF-e, da NFC-e, do CT-e, do CT-e OS, do CT-e simplificado, da GTV-e, do MDF-e, da NFS-e Nacional, da NFS-e de prefeitura e dos eventos, em tabelas |
| [Certificado digital e SEFAZ](guia/sefaz.md) | O certificado A1, o status do serviço, a consulta pela chave, os MDF-e não encerrados, o cadastro de contribuintes, a Distribuição de DF-e, a NFS-e Nacional e a situação do CNPJ na Receita |
| [Assinar, enviar e registrar eventos](guia/emitir.md) | A assinatura, a autorização da NF-e e da NFC-e (com o QR-Code), o cancelamento, a carta de correção, a manifestação, o desacordo do CT-e, o MDF-e e a NFS-e Nacional |
| [Os documentos auxiliares em PDF](guia/pdf.md) | O DANFE, o DANFE Simplificado e a Etiqueta, o DANFE NFC-e, o DACTE, o DAMDFE, o DANFSe e a carta de correção |
| [A pré-conferência da NF-e](guia/conferir.md) | O schema e as regras de validação do Manual de Orientação do Contribuinte, antes de enviar |
| [IBS e CBS](guia/reforma.md) | A conferência pelas regras da NT 2025.002, como a SEFAZ as aplicava no dia da emissão, e o cálculo de cada item, também para simular outro ano |
| [SPED Fiscal](guia/sped.md) | A EFD ICMS/IPI em tabelas, uma por registro, e o cruzamento com os XML das NF-e |
| [Tabelas fiscais](guia/tabelas.md) | CFOP, NCM, CEST, os CST, as tabelas da Reforma, os municípios e o significado dos códigos, com a vigência, e como atualizá-las |

## De onde vêm as regras

Das especificações públicas do [Portal Nacional da NF-e](https://www.nfe.fazenda.gov.br/portal/): o Manual de
Orientação do Contribuinte (a composição da chave) e a Nota Técnica Conjunta 2025.001, versão 1.00 (o CNPJ
alfanumérico na chave e no cálculo dos dígitos: cada caractere vale o código ASCII menos 48). A leitura dos
XMLs segue os schemas oficiais do Portal da NF-e, do
[Portal Nacional do CT-e](https://www.cte.fazenda.gov.br/portal/), do
[Portal do MDF-e](https://dfe-portal.svrs.rs.gov.br/Mdfe) e do
[portal da NFS-e Nacional](https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica), e não consulta a
SEFAZ. Cada página diz as fontes da parte dela.

A pré-conferência usa os schemas do pacote de liberação 010g (versão 1.03) do Portal da NF-e, que vão no pacote em
`inst/schemas/nfe`, e as regras de validação do Anexo I do MOC 7.0 com as notas técnicas que as mudaram depois; a
regra, o código, a mensagem e a fonte de cada uma estão em `inst/extdata/regras_nfe.csv`.

Nos exemplos e nos testes, só CNPJs e CPFs fictícios; o 12.ABC.345/01DE-35 é o exemplo da Receita Federal.

## Agradecimentos

O RNFe se apoia no trabalho de muita gente.

- O **[PyNFe](https://github.com/TadaSoftware/PyNFe)** (TadaSoftware, LGPL-3.0), a biblioteca de NF-e do Python,
  é a principal referência deste pacote. O plano do RNFe parte do que ele faz (consulta à SEFAZ, distribuição
  de documentos, emissão, eventos), e a assinatura digital do RNFe foi conferida com a dele: o mesmo XML sai
  assinado igual, byte a byte. Obrigado a quem mantém o PyNFe e a todos que contribuíram com ele.
- O **[brans-nfe](https://github.com/badbrans/brans-nfe)** (MIT), cliente Python da NFS-e Nacional, e o
  **[BrazilFiscalReport](https://github.com/Engenere/BrazilFiscalReport)** (Engenere, LGPL-3.0), que gera o
  DANFE, o DACTE, o DAMDFE, a DACCe e o DANFSe, mostraram o que mais o RNFe precisa cobrir.
- Os portais que publicam abertamente os schemas, os manuais e as tabelas: o Portal Nacional da NF-e, o do
  CT-e, o do MDF-e, o da NFS-e Nacional, o SPED da Receita Federal, o Portal Único Siscomex e o IBGE.
- Os pacotes do R em que o RNFe se apoia: o xml2, que lê os XMLs; o httr2, na conversa com a SEFAZ e nas
  ferramentas que baixam as tabelas e os schemas, com o jsonlite e o readxl; o testthat e o roxygen2, nos testes
  e na ajuda.

O código do RNFe foi escrito do zero, a partir das especificações oficiais: nenhuma linha foi copiada desses
projetos.

## Licença

MIT.
