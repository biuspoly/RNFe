# RNfe

Documentos fiscais eletrônicos brasileiros (NF-e, NFC-e, CT-e, MDF-e, NFS-e Nacional) no **R**.

> **Em construção.** Esta versão traz a chave de acesso, a leitura do XML da NF-e, da NFC-e, do CT-e, do
> CT-e OS, do MDF-e, da NFS-e Nacional e dos eventos de todos eles, e as tabelas fiscais (CFOP, NCM, CSTs, as
> da Reforma e os municípios do IBGE). O certificado digital e a SEFAZ vêm a seguir; o plano está em
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
A chave de 50 posições da NFS-e Nacional fica de fora: a regra do dígito dela não está escrita nas fontes
oficiais.

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
lida$pagamentos_vinculados   # o pagamento vinculado da Reforma (split payment)
lida$arquivos     # o que foi lido, e o motivo de cada arquivo que não deu

nfe_ler("nota1.xml", todos_os_campos = TRUE)$campos   # todos os campos da nota, um por linha, com o caminho
```

Segue o schema oficial mais recente (pacote de liberação PL_010g, de 26/10/2026), já com os campos da Reforma
Tributária. Ao lado de cada código do item vem o nome dele (`cfop_titulo`, `cst_icms_descricao`...), como a
tabela oficial registrava na data da nota. Conferido com 10 mil notas reais (que não estão no repositório):
os campos comparados bateram em todas, e todos os códigos dos 46 mil itens acharam o nome.

Na NFC-e (modelo 65) vêm também o QR-Code e a URL de consulta (`qrcode` e `url_consulta`, do grupo que fica
fora do `infNFe`) e, na emissão em contingência, a entrada e a justificativa. A NFC-e foi conferida pelo
schema oficial e por um exemplo em contingência offline; as notas reais usadas na conferência eram todas NF-e.

## Ler o XML do CT-e e do CT-e OS

```r
lido = cte_ler(c("cte1.xml", "cte2.xml"))   # ou o próprio texto do XML
lido$ctes          # uma linha por CT-e: pessoas, tomador, prestação, ICMS, IBS e CBS, carga, protocolo
lido$componentes   # os componentes do valor da prestação (frete peso, pedágio...)
lido$documentos    # o que o CT-e cita: NF-e transportadas, transporte anterior, CT-e complementado...
lido$cargas        # as quantidades da carga (peso, caixas...)
lido$impostos      # todos os campos de imposto, um por linha
lido$parcelas      # as duplicatas
lido$pagamentos_vinculados   # o pagamento vinculado da Reforma (split payment)
lido$observacoes   # os campos de uso livre (ObsCont e ObsFisco)
lido$arquivos      # o que foi lido, e o motivo de cada arquivo que não deu

cte_ler("cte1.xml", todos_os_campos = TRUE)$campos   # todos os campos do CT-e (o modal, o percurso...)
```

Lê o CT-e (modelo 57) e o CT-e OS (modelo 67), nos leiautes 3.00 e 4.00, pelo schema oficial mais recente
(PL_CTe_400 NT 2026.004, republicado em 16/10/2026). O tomador vem pronto: quando o XML só diz o papel dele
(remetente, expedidor, recebedor ou destinatário), os dados dessa pessoa são copiados para as colunas
`tomador_`. Conferido com 14 mil CT-e reais (que não estão no repositório), contra outro sistema e contra um
segundo leitor do XML: os campos e as contagens comparados bateram em todos.

## Ler o XML do MDF-e

```r
lido = mdfe_ler(c("mdfe1.xml", "mdfe2.xml"))   # ou o próprio texto do XML
lido$mdfes        # uma linha por MDF-e: emitente, modal, UFs, placa, totais da carga, protocolo
lido$locais       # municípios de carregamento, UFs do percurso e municípios de descarregamento
lido$documentos   # os CT-e e as NF-e de cada descarregamento
lido$veiculos     # o veículo com a tração e os reboques, com o proprietário
lido$condutores   # os motoristas
lido$seguros      # uma linha por averbação
lido$campos       # todos os campos, um por linha, com o caminho (CIOT, vale-pedágio, pagamento do frete...)
lido$arquivos     # o que foi lido, e o motivo de cada arquivo que não deu
```

Lê o MDF-e (modelo 58, leiaute 3.00) pelo schema oficial mais recente (PL_MDFe_300b da NT 2025.001,
publicado em 25/04/2026). Os exemplos passam no schema oficial; ainda não foi conferido com MDF-e reais.

## Ler o XML da NFS-e Nacional

```r
lida = nfse_ler(c("nfse1.xml", "nfse2.xml"))   # ou o próprio texto do XML
lida$nfses      # uma linha por NFS-e: prestador, tomador, serviço, ISSQN, retenções, IBS e CBS, valor líquido
lida$campos     # todos os campos, um por linha, com o caminho (deduções, obra, comércio exterior...)
lida$arquivos   # o que foi lido, e o motivo de cada arquivo que não deu
```

Lê a NFS-e do padrão nacional (leiautes 1.00 e 1.01) pelo schema oficial mais recente
(NFSe-ESQUEMAS_XSD-v1.01, de 09/02/2026), com a chave de acesso de 50 posições. Junta o que quem emitiu
declarou (a DPS) e o que o sistema nacional calculou (ISSQN, valor líquido, IBS e CBS). A NFS-e de prefeitura,
no padrão próprio de cada município, não é lida. Conferido com 11 mil NFS-e reais (que não estão no
repositório), contra outro sistema e contra um segundo leitor do XML: os campos comparados bateram em todas.

No MDF-e e na NFS-e a tabela `campos` vem por padrão (`todos_os_campos = FALSE` a deixa de fora); na NF-e e
no CT-e, que já têm tabelas para quase tudo, só com `todos_os_campos = TRUE`.

## Ler o XML dos eventos

```r
lido = eventos_ler(c("cancelamento.xml", "carta_de_correcao.xml"))   # ou o próprio texto do XML
lido$eventos    # uma linha por evento: documento, chave, tipo, descrição, justificativa, correção, retorno
lido$campos     # todos os campos de cada evento, um por linha (o detalhe próprio de cada tipo)
lido$arquivos   # o que foi lido, e o motivo de cada arquivo que não deu

# Uma nota cancelada continua autorizada no protocolo dela: o cancelamento é um evento à parte.
notas = nfe_ler("nota1.xml")$notas
notas$cancelada = notas$chave %in% lido$eventos$chave[lido$eventos$tipo == "110111"]
```

Lê os eventos da NF-e, da NFC-e, do CT-e, do MDF-e e da NFS-e Nacional numa tabela só: cancelamento, carta de
correção, manifestação do destinatário, encerramento, os que o Fisco registra (CT-e e MDF-e autorizados para a
nota, registro de passagem...). Lê o evento com o retorno da SEFAZ, o evento só assinado, o da NFS-e como o
sistema nacional registra e o resumo de evento que a Distribuição de DF-e entrega. Conferido com 181 mil
eventos reais (que não estão no repositório), contra outro sistema e contra um segundo leitor do XML: os campos
comparados bateram em todos. A data do evento sai como o instante exato, pelo fuso escrito no XML (que nem
sempre é o de Brasília).

## Tabelas fiscais

```r
tabela_fiscal("cfop")                    # título, nota explicativa e indicadores de cada CFOP
tabela_fiscal("ncm")                     # a NCM vigente, com a descrição completa de cada código
tabela_fiscal("classificacao_ibs_cbs")   # a cClassTrib da Reforma, e "cst_ibs_cbs"
tabela_fiscal("cst_icms")                # e "origem", "csosn", "cst_ipi", "cst_pis", "cst_cofins"
tabela_fiscal("municipios")              # os municípios do IBGE: código de 7 dígitos, nome e UF
tabela_fiscal("fontes")                  # de onde veio cada tabela, com a versão e a data
```

Cada linha tem o `inicio` e o `fim` da vigência (vazios no CSOSN e nos municípios, que a fonte não data). As
fontes são oficiais: o Portal da NF-e (CFOP e Reforma), o Portal Único Siscomex (NCM), as tabelas do SPED
Fiscal, da Receita (CSTs), e a API de localidades do IBGE (municípios). `ferramentas/gerar_tabelas.R` baixa
tudo e refaz as cópias; um robô faz isso toda semana e abre um aviso quando alguma tabela muda.

## De onde vêm as regras

Das especificações públicas do [Portal Nacional da NF-e](https://www.nfe.fazenda.gov.br/portal/): o Manual de
Orientação do Contribuinte (a composição da chave) e a Nota Técnica Conjunta 2025.001, versão 1.00 (o CNPJ
alfanumérico na chave e no cálculo dos dígitos: cada caractere vale o código ASCII menos 48). A leitura dos
XMLs segue os schemas oficiais do Portal da NF-e, do
[Portal Nacional do CT-e](https://www.cte.fazenda.gov.br/portal/), do
[Portal do MDF-e](https://dfe-portal.svrs.rs.gov.br/Mdfe) e do
[portal da NFS-e Nacional](https://www.gov.br/nfse/pt-br/biblioteca/documentacao-tecnica). Nada aqui consulta
a SEFAZ.

Nos exemplos e nos testes, só CNPJs e CPFs fictícios; o 12.ABC.345/01DE-35 é o exemplo da Receita Federal.

## Agradecimentos

O RNfe se apoia no trabalho de muita gente.

- O **[PyNFe](https://github.com/TadaSoftware/PyNFe)** (TadaSoftware, LGPL-3.0), a biblioteca de NF-e do Python,
  é a principal referência deste pacote. O plano do RNfe parte do que ele faz (consulta à SEFAZ, distribuição
  de documentos, emissão, eventos), e a assinatura digital, quando chegar aqui, vai ser conferida contra a dele.
  Obrigado a quem mantém o PyNFe e a todos que contribuíram com ele.
- O **[brans-nfe](https://github.com/badbrans/brans-nfe)** (MIT), cliente Python da NFS-e Nacional, e o
  **[BrazilFiscalReport](https://github.com/Engenere/BrazilFiscalReport)** (Engenere, LGPL-3.0), que gera o
  DANFE, o DACTE, o DAMDFE, a DACCe e o DANFSe, mostraram o que mais o RNfe precisa cobrir.
- Os portais que publicam abertamente os schemas, os manuais e as tabelas: o Portal Nacional da NF-e, o do
  CT-e, o do MDF-e, o da NFS-e Nacional, o SPED da Receita Federal, o Portal Único Siscomex e o IBGE.
- Os pacotes do R em que o RNfe se apoia: o xml2, que lê os XMLs; o httr2, o jsonlite e o readxl, nas
  ferramentas que baixam as tabelas e os schemas; o testthat e o roxygen2, nos testes e na ajuda.

O código do RNfe foi escrito do zero, a partir das especificações oficiais: nenhuma linha foi copiada desses
projetos.

## Licença

MIT.
