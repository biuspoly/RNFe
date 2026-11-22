# RNFe

Documentos fiscais eletrônicos brasileiros (NF-e, NFC-e, CT-e, GTV-e, MDF-e, NFS-e) no **R**: montar o XML pelo
schema oficial, assinar, falar com a SEFAZ, ler o XML em tabelas e desenhar os PDFs.

> **Em desenvolvimento.** O que fala com a SEFAZ funciona, por enquanto, só no ambiente de homologação (na NFS-e
> Nacional, na Produção Restrita). Ainda não está no CRAN.

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
| [Ler os documentos](https://github.com/biuspoly/RNFe/blob/main/guia/ler.md) | A chave de acesso e o XML da NF-e, da NFC-e, do CT-e, do CT-e OS, do CT-e simplificado, da GTV-e, do MDF-e, da NFS-e Nacional, da NFS-e de prefeitura e dos eventos, em tabelas |
| [Montar os documentos](https://github.com/biuspoly/RNFe/blob/main/guia/montar.md) | A NF-e, a NFC-e, o CT-e (o OS, a GTV-e e o simplificado), o MDF-e e a DPS da NFS-e Nacional a partir de uma lista com os campos do leiaute, na ordem e no formato do schema oficial, e qualquer documento passado de volta para essa lista |
| [Certificado digital e SEFAZ](https://github.com/biuspoly/RNFe/blob/main/guia/sefaz.md) | O certificado A1, o status do serviço, a consulta pela chave, os MDF-e não encerrados, o cadastro de contribuintes, a Distribuição de DF-e e a NFS-e Nacional |
| [Assinar, enviar e registrar eventos](https://github.com/biuspoly/RNFe/blob/main/guia/emitir.md) | A assinatura, a autorização da NF-e, da NFC-e (com o QR-Code) e do CT-e (o OS, a GTV-e e o simplificado), o cancelamento, a carta de correção, a manifestação, o comprovante e o insucesso de entrega, o ator interessado, o EPEC, o cancelamento e o desacordo do CT-e, o MDF-e e a NFS-e Nacional (também a consulta pela DPS) |
| [Os documentos auxiliares em PDF](https://github.com/biuspoly/RNFe/blob/main/guia/pdf.md) | O DANFE, o DANFE Simplificado e a Etiqueta, o DANFE NFC-e, o DACTE, o DAMDFE, o DANFSe e a carta de correção |

## O que vem por aí

Cada parte futura tem um aviso no GitHub, com a etiqueta
[planejado](https://github.com/biuspoly/RNFe/issues?q=is%3Aissue+is%3Aopen+label%3Aplanejado):

- [a emissão em produção](https://github.com/biuspoly/RNFe/issues/21) (hoje, só homologação);
- [o CT-e autorizado de ponta a ponta](https://github.com/biuspoly/RNFe/issues/22) na homologação;
- [os códigos novos da NFS-e Nacional](https://github.com/biuspoly/RNFe/issues/23), quando o schema da NT 009 sair;
- [o MDF-e e o CT-e simplificado conferidos com documentos reais](https://github.com/biuspoly/RNFe/issues/24): quem
  tiver um acervo pode ajudar;
- [o envio ao CRAN](https://github.com/biuspoly/RNFe/issues/25).

## De onde vêm as regras

Das especificações públicas do [Portal Nacional da NF-e](https://www.nfe.fazenda.gov.br/portal/): o Manual de
Orientação do Contribuinte (a composição da chave) e a Nota Técnica Conjunta 2025.001, versão 1.00 (o CNPJ
alfanumérico na chave e no cálculo dos dígitos: cada caractere vale o código ASCII menos 48). A leitura dos
XMLs segue os schemas oficiais do Portal da NF-e, do
[Portal Nacional do CT-e](https://www.cte.fazenda.gov.br/portal/), do
[Portal do MDF-e](https://dfe-portal.svrs.rs.gov.br/Mdfe) e do
[portal da NFS-e Nacional](https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica), e não consulta a
SEFAZ. Cada página diz as fontes da parte dela.

A montagem usa os schemas oficiais que vão no pacote em `inst/schemas`, e todo XML montado é conferido com eles: o
pacote de liberação 010h (versão 1.03) da NF-e; os eventos da NF-e (a parte geral do 010d v1.03, a do CNPJ
alfanumérico, os tipos básicos do 010g e o pacote de cada evento); o CT-e da NT 2026.005; o MDF-e da NT 2025.001; e a
NFS-e Nacional de produção (1.01) e da Produção Restrita (a da NT 009, que a montagem da DPS segue).

Nos exemplos e nos testes, só CNPJs e CPFs fictícios; o 12.ABC.345/01DE-35 é o exemplo da Receita Federal.

## Agradecimentos

O RNFe se apoia no trabalho de muita gente.

- O **[PyNFe](https://github.com/TadaSoftware/PyNFe)** (TadaSoftware, LGPL-3.0), a biblioteca de NF-e do Python,
  é a principal referência deste pacote. O plano do RNFe parte do que ele faz (consulta à SEFAZ, distribuição
  de documentos, emissão, eventos), e a assinatura digital do RNFe foi conferida com a dele: o mesmo XML sai
  assinado igual, byte a byte (o PyNFe tira os acentos antes de assinar; o RNFe não). Obrigado a quem mantém o PyNFe e a todos que contribuíram com ele.
- O **[nfelib](https://github.com/akretion/nfelib)** (Akretion, MIT), que gera as classes da NF-e, do CT-e, do MDF-e
  e da NFS-e a partir dos schemas oficiais, é a outra régua do RNFe, ao lado do PyNFe: dele veio a ideia de deixar o
  schema decidir a montagem dos documentos (o RNFe lê o schema na hora, em vez de gerar código).
- O **[brans-nfe](https://github.com/badbrans/brans-nfe)** (MIT), cliente Python da NFS-e Nacional, e o
  **[BrazilFiscalReport](https://github.com/Engenere/BrazilFiscalReport)** (Engenere, LGPL-3.0), que gera o
  DANFE, o DACTE, o DAMDFE, a DACCe e o DANFSe, mostraram o que mais o RNFe precisa cobrir.
- Os portais que publicam abertamente os schemas e os manuais: o Portal Nacional da NF-e, o do CT-e, o do MDF-e e o
  da NFS-e Nacional; e o IBGE, de onde vêm os municípios.
- Os pacotes do R em que o RNFe se apoia: o xml2, que lê os XMLs; o httr2, na conversa com a SEFAZ e na
  ferramenta que baixa os schemas, com o jsonlite; o testthat e o roxygen2, nos testes
  e na ajuda.

O código do RNFe foi escrito do zero, a partir das especificações oficiais: nenhuma linha foi copiada desses
projetos.

## Licença

MIT.
