# RNFe

Documentos fiscais eletrônicos brasileiros (NF-e, NFC-e, CT-e, GTV-e, MDF-e, NFS-e Nacional) no **R**.

> **Em construção.** Esta versão traz a chave de acesso, a leitura do XML da NF-e (e do resumo que a
> Distribuição de DF-e entrega), da NFC-e, do CT-e, do CT-e OS, da GTV-e, do MDF-e, da NFS-e Nacional e dos
> eventos de todos eles, e as tabelas fiscais (CFOP, NCM, CSTs, as
> da Reforma, os municípios do IBGE, os meios de pagamento e o significado dos códigos de cada leiaute). Da
> SEFAZ, por enquanto, a leitura do certificado digital, o status do serviço e a consulta pela chave (NF-e, NFC-e,
> CT-e e MDF-e), os MDF-e não encerrados, a consulta de cadastro e a Distribuição de DF-e (NF-e e CT-e), em homologação;
> da NFS-e Nacional, a consulta pela chave e a distribuição, na Produção Restrita; o plano está em
> [docs/plano.md](https://github.com/biuspoly/RNFe/blob/main/docs/plano.md).

## Instalar

```r
remotes::install_github("biuspoly/RNFe")
```

## Chave de acesso

A chave de 44 posições que identifica cada documento: conferir, desmontar e calcular o dígito, já com o
**CNPJ alfanumérico** (CNPJ com letras), em produção desde 06/07/2026.

```r
library(RNFe)

chave_valida("35261011444777000161550010000001231123456783")    # TRUE
chave_decompor("35261012ABC34501DE35550010000001231123456784")  # UF, ano, mês, CNPJ, modelo, série, número...
chave_digito("35261011444777000161550010000001231123456789")     # 3: o dígito que a chave deveria ter
```

`chave_decompor()` devolve uma linha por chave e, quando algo não confere, diz o quê na coluna `problema`
(o dígito, o CNPJ do emitente, a UF, o mês ou o formato). A forma de emissão vem com o significado dela no
leiaute daquele documento (a 2 é "Contingência FS" na NF-e e "Contingência offline" no CT-e). Espaços e o prefixo do `Id` do XML (`NFe...`) são
ignorados. Na NF-e avulsa, emitida pelo Fisco, o CNPJ da chave é o do órgão que a emitiu, não o do emitente.
A chave de 50 posições da NFS-e Nacional fica de fora: a regra do dígito dela não está escrita nas fontes
oficiais.

```r
chave_extrair(c("danfe.pdf", "cupom.jpg"))   # a chave achada no PDF ou na foto
```

`chave_extrair()` acha a chave em PDFs (DANFE, DACTE, cupom da NFC-e) e em imagens (foto, digitalização): pelo texto
do PDF, pelo QR-Code ou por OCR, nessa ordem, com os pacotes `pdftools`, `opencv` e `tesseract`, se estiverem
instalados. Só devolve a chave que confere. O dígito verificador e o CNPJ dentro dela pegam quase toda leitura errada;
um número com cara de chave que não confere aparece em `problema`. Os outros números do documento (valores,
quantidades) não têm essa conferência e, lidos de uma imagem, podem vir errados sem aviso: por isso a função só
procura a chave, e os dados da nota vêm do XML.

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
lida$resumos      # o resumo da NF-e (resNFe) que a Distribuição de DF-e entrega ao destinatário
lida$arquivos     # o que foi lido, e o motivo de cada arquivo que não deu

nfe_ler("nota1.xml", todos_os_campos = TRUE)$campos   # todos os campos da nota, um por linha, com o caminho
```

O resumo (`resNFe`) é o que a Distribuição de DF-e entrega ao destinatário enquanto ele não se manifestou
sobre a nota: emitente, emissão, valor, protocolo e a situação da nota (autorizada, denegada ou cancelada).
Vem em `resumos`, uma linha por resumo, ligado à nota completa e aos eventos pela chave. Conferido com 2 mil
resumos reais (versões 1.00 e 1.01): todos lidos, e nos 251 que tinham a nota completa ao lado, os campos
bateram com ela.

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

## Ler o XML da GTV-e

```r
lida = gtve_ler(c("gtve1.xml", "gtve2.xml"))   # ou o próprio texto do XML
lida$gtves         # uma linha por GTV-e: pessoas, tomador, origem e destino, saída e chegada, malotes, protocolo
lida$especies      # o valor levado de cada espécie (cédula, cheque, moeda...), nacional ou estrangeira
lida$veiculos      # a placa, a UF e o RNTRC de cada veículo
lida$observacoes   # os campos de uso livre (ObsCont e ObsFisco)
lida$arquivos      # o que foi lido, e o motivo de cada arquivo que não deu
```

A GTV-e (Guia de Transporte de Valores Eletrônica, modelo 64) é um CT-e do tipo 4: tem a chave, o protocolo
e os eventos do CT-e, mas no lugar do valor da prestação e dos impostos traz os valores levados. Por isso tem
leitor próprio. Conferido com 285 GTV-e reais: todas lidas, e as espécies, a quantidade de malotes, a emissão,
o protocolo e as partes da chave bateram com o XML em todas.

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

## Certificado digital e SEFAZ (homologação)

```r
senha = Sys.getenv("SENHA_DO_CERTIFICADO")   # nunca escrita no script
certificado_ler("empresa.pfx", senha)          # titular, CNPJ ou CPF, emissor e validade
sefaz_status(c("SP", "CE"), "empresa.pfx", senha)   # o serviço da NF-e está no ar em cada UF?
sefaz_status(c("SP", "CE"), "empresa.pfx", senha, documento = "CT-e")   # ou "NFC-e" ou "MDF-e"

consulta = sefaz_situacao(chaves, "empresa.pfx", senha)   # a situação de cada documento, pela chave
consulta$situacoes   # uma linha por chave: a resposta da SEFAZ e o protocolo de autorização
consulta$eventos     # os eventos que a SEFAZ manda junto (o cancelamento, por exemplo)
```

A consulta pela chave vale para a NF-e, a NFC-e, o CT-e, o CT-e OS, a GTV-e e o MDF-e (o modelo vem da chave) e vai
ao autorizador da UF que está na chave; chave que não confere nem é enviada. Os eventos que vêm na resposta são lidos
pelo `eventos_ler()`. A NFC-e tem endereços próprios: os do Portal da NFC-e (AM, GO, MS, MT, PR, RS, SP e a SVRS para
outras 19 UFs) e os da página da SEFAZ-MG, que o Portal não lista. O CT-e segue o Portal do CT-e (MG, MS, MT, PR, RS
e SP têm autorizador próprio; AP, PE e RR vão à SVSP; as outras 18 UFs, à SVRS); o MDF-e vai sempre à SVRS. Testado
em 03/11/2026 com chaves inventadas: o status nas 27 UFs para NF-e, NFC-e, CT-e e MDF-e (107, em operação) e a
consulta nas 27 UFs para NF-e, NFC-e e CT-e, e em algumas para CT-e OS, GTV-e e MDF-e (217, o documento não consta,
como esperado numa chave que não existe).

```r
abertos = sefaz_mdfe_nao_encerrados("11222333000181", "empresa.pfx", senha)   # MDF-e ainda não encerrados
abertos$mdfes   # a chave e o protocolo de cada um (nenhuma linha e situação 112 quando não há)
```

```r
cadastro = sefaz_cadastro("11.222.333/0001-81", "SP", "empresa.pfx", senha)   # ou tipo = "CPF" ou "IE"
cadastro$consultas   # uma linha por documento consultado: a resposta da SEFAZ
cadastro$cadastros   # uma linha por inscrição: situação, credenciamento na NF-e e no CT-e, nome, CNAE, endereço
```

A consulta de cadastro vai à SEFAZ própria da UF ou, nas 16 UFs da SVRS, à SVRS. A página do Portal lista só 5
delas para o cadastro, mas a SVRS atende todas (testado em 03/11/2026). Só o MA, que usa a SVAN, fica sem o
serviço: a linha vem com o motivo. A SEFAZ pode recusar quem pergunta (257, "Solicitante não habilitado para emissão da
NF-e", sobre o CNPJ do certificado), e uma resposta que fala de outro documento não entra (na homologação, GO e AM
respondem sobre o CNPJ do certificado). O MT pede o envelope de outro jeito, e o RNFe já manda assim.

```r
distribuicao = sefaz_distribuicao("11222333000181", "empresa.pfx", senha)   # o que foi emitido contra o CNPJ
distribuicao$consulta     # a resposta: 137 (nenhum documento) ou 138, o último NSU e o maior
nfe_ler(distribuicao$documentos$xml)       # as notas e os resumos que vieram
eventos_ler(distribuicao$documentos$xml)   # os eventos
# o próximo pedido segue do último NSU recebido
sefaz_distribuicao("11222333000181", "empresa.pfx", senha, ultimo_nsu = distribuicao$consulta$ultimo_nsu)

# os CT-e, CT-e OS e GTV-e em que o CNPJ aparece (remetente, destinatário, tomador...); a UF de quem pede é obrigatória
ctes = sefaz_distribuicao("11222333000181", "empresa.pfx", senha, distribuicao = "CT-e", uf = "SP")
cte_ler(ctes$documentos$xml)       # os CT-e e CT-e OS que vieram
gtve_ler(ctes$documentos$xml)      # as GTV-e
eventos_ler(ctes$documentos$xml)   # os eventos
```

A Distribuição de DF-e (NT 2014.002 na NF-e, NT 2015.002 no CT-e) traz até 50 documentos por pedido, já
descompactados. Depois de uma resposta "não há mais documentos", quem pede de novo pelo último NSU antes de passar
uma hora recebe 656 ("Consumo Indevido"), e na NF-e o CNPJ fica bloqueado por uma hora; o RNFe recusa esse pedido
nesta sessão do R, antes de ir à SEFAZ. A NF-e e o CT-e têm cada um a sua sequência de NSU e a sua espera. Também dá
para pedir um NSU que faltou (`nsu`) ou, só na NF-e, uma nota pela chave (`chave`). O emitente não recebe os próprios
CT-e, e o schema da distribuição do CT-e (1.00) ainda não aceita o CNPJ com letras.

```r
# NFS-e Nacional: a nota pela chave (Sefin Nacional) e os eventos dela (ADN)
consulta = nfse_situacao("35503082211222333000181000000000012326101234567898", "empresa.pfx", senha)
consulta$situacoes   # encontrada?, o erro da Sefin (E2401: não existe) e o XML da nota
consulta$eventos     # o cancelamento (101101) e os outros eventos
nfse_ler(consulta$situacoes$xml)

# as NFS-e e os eventos em que o CNPJ aparece (emitente, tomador ou intermediário), por NSU
distribuicao = nfse_distribuicao("11222333000181", "empresa.pfx", senha)
nfse_ler(distribuicao$documentos$xml)
nfse_distribuicao("11222333000181", "empresa.pfx", senha, ultimo_nsu = distribuicao$consulta$ultimo_nsu)
```

A NFS-e Nacional não passa pela SEFAZ: são as APIs do Sistema Nacional NFS-e (a Sefin Nacional, que gera e consulta
a nota, e o ADN, o Ambiente de Dados Nacional, que guarda e distribui), com o mesmo certificado e respostas em JSON
(precisa do pacote `jsonlite`). O ambiente de teste lá se chama **Produção Restrita**, e é ele que o RNFe usa com
`ambiente = "homologacao"`. A NFS-e não tem código de situação: o cancelamento e os outros fatos vêm em eventos. Só
quem aparece na nota consegue consultá-la. O DANFSe oficial não é mais baixado do sistema nacional: a API dele foi
desativada em 03/08/2026, e pela NT 008/2026 cada sistema gera o seu.

Por enquanto o RNFe só fala com o ambiente de **homologação** da SEFAZ: a produção é recusada antes de qualquer
conexão. O CNPJ do certificado vem do campo que a ICP-Brasil reserva para ele (DOC-ICP-04). O endereço de cada
serviço e o autorizador de cada UF (a própria SEFAZ ou uma SEFAZ virtual) vêm das Relações de Serviços Web dos
portais de cada documento (e da página da SEFAZ-MG, na NFC-e), que o robô das tabelas confere toda semana.

Não é preciso configurar nada, nem no Windows. Testado em 30/10/2026: as 27 UFs responderam numa sessão comum do R
no Windows. Lá o curl do R usa o motor de conexão segura do próprio Windows (Schannel), que não conecta com BA, MA,
MG, MT e SP; quando é ele que está ligado, o RNFe manda os pedidos por um processo R separado, aberto com o motor
OpenSSL, e a sua sessão não muda. Isso custa uns 0,3 segundo por chamada (não por UF).

O certificado vai em PEM, num arquivo temporário apagado no fim, com a chave cifrada pela senha; para o processo
separado, a senha vai numa variável de ambiente só dele, nunca num arquivo. O certificado do servidor é sempre
verificado: contra as raízes de sempre e a raiz v10 da ICP-Brasil, que vem no pacote (conferida com a do repositório
do ITI). O PyNFe conecta sem isso porque desliga a verificação (`verify=False`).

## Tabelas fiscais

```r
tabela_fiscal("cfop")                    # título, nota explicativa e indicadores de cada CFOP
tabela_fiscal("ncm")                     # a NCM vigente, com a descrição completa de cada código
tabela_fiscal("classificacao_ibs_cbs")   # a cClassTrib da Reforma, e "cst_ibs_cbs"
tabela_fiscal("cst_icms")                # e "origem", "csosn", "cst_ipi", "cst_pis", "cst_cofins"
tabela_fiscal("municipios")              # os municípios do IBGE: código de 7 dígitos, nome e UF
tabela_fiscal("meios_pagamento")         # o tPag da NF-e e da NFC-e (PIX, boleto...), e "bandeiras_cartao"
tabela_fiscal("codigos_dos_campos")      # o significado dos códigos do leiaute (tpEmis, modFrete, toma...)
tabela_fiscal("fontes")                  # de onde veio cada tabela, com a versão e a data
```

Cada linha tem o `inicio` e o `fim` da vigência (vazios no CSOSN e nos municípios, que a fonte não data). As
fontes são oficiais: o Portal da NF-e (CFOP, Reforma, meios de pagamento e bandeiras), o Portal Único
Siscomex (NCM), as tabelas do SPED Fiscal, da Receita (CSTs), e a API de localidades do IBGE (municípios).
`ferramentas/gerar_tabelas.R` baixa tudo e refaz as cópias; um robô faz isso toda semana e abre um aviso
quando alguma tabela muda. Os municípios ficam de fora do robô, porque o IBGE não aceita conexão dos
servidores do GitHub.

Os leitores usam essas tabelas: ao lado de cada código vem o significado dele, numa coluna com o mesmo nome e
`_descricao` no fim (`forma_emissao` 9 vem com "Contingência off-line da NFC-e e da NF-e com DANFE
Simplificado Tipo 2"; `modal` "01", com "Rodoviário"). Os significados dos códigos do leiaute vêm da
documentação dos schemas oficiais, escritos à mão (os schemas trazem o texto, não uma tabela), e
`ferramentas/conferir_codigos_dos_campos.R` confere que cada código está no schema e que nenhum valor do schema
ficou sem significado. Onde a documentação do schema tinha erro, vale a fonte que o corrige: o `tribISSQN` da
NFS-e 1.00 segue o Anexo I do leiaute (2 é imunidade, 3 exportação, 4 não incidência), não a ordem do schema
1.00. O tipo de transportador do MDF-e (ETC, TAC, CTC) vem com o nome da Lei 11.442/2007, art. 2º. No órgão dos
eventos da NF-e, os schemas se contradizem sobre o Ambiente Nacional (90 ou 91): vale o 91, que é o que a SEFAZ
devolve; o código que nenhuma fonte explica fica com o significado vazio.

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

O RNFe se apoia no trabalho de muita gente.

- O **[PyNFe](https://github.com/TadaSoftware/PyNFe)** (TadaSoftware, LGPL-3.0), a biblioteca de NF-e do Python,
  é a principal referência deste pacote. O plano do RNFe parte do que ele faz (consulta à SEFAZ, distribuição
  de documentos, emissão, eventos), e a assinatura digital, quando chegar aqui, vai ser conferida contra a dele.
  Obrigado a quem mantém o PyNFe e a todos que contribuíram com ele.
- O **[brans-nfe](https://github.com/badbrans/brans-nfe)** (MIT), cliente Python da NFS-e Nacional, e o
  **[BrazilFiscalReport](https://github.com/Engenere/BrazilFiscalReport)** (Engenere, LGPL-3.0), que gera o
  DANFE, o DACTE, o DAMDFE, a DACCe e o DANFSe, mostraram o que mais o RNFe precisa cobrir.
- Os portais que publicam abertamente os schemas, os manuais e as tabelas: o Portal Nacional da NF-e, o do
  CT-e, o do MDF-e, o da NFS-e Nacional, o SPED da Receita Federal, o Portal Único Siscomex e o IBGE.
- Os pacotes do R em que o RNFe se apoia: o xml2, que lê os XMLs; o httr2, o jsonlite e o readxl, nas
  ferramentas que baixam as tabelas e os schemas; o testthat e o roxygen2, nos testes e na ajuda.

O código do RNFe foi escrito do zero, a partir das especificações oficiais: nenhuma linha foi copiada desses
projetos.

## Licença

MIT.
