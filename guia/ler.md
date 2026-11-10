# Ler os documentos

[Voltar ao início](../README.md)

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
instalados (as páginas de um TIFF depois da primeira, com o `magick`). Um arquivo que não abre vira uma linha com o
motivo, sem atrapalhar os outros. Só devolve a chave que confere. O dígito verificador e o CNPJ dentro dela pegam quase toda leitura errada;
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
Tributária: na nota, o IBS, a CBS e o monofásico dos totais, a previsão de entrega, o tipo da nota de débito e de
crédito, o local da operação, o município do fato gerador do IBS, a compra governamental e as inscrições na
Suframa; no item, o IBS e a CBS, o monofásico, o crédito presumido da ZFM, o bem móvel usado, o valor do item e o
item de outro documento que ele cita. Ao lado de cada código do item vem o nome dele (`cfop_titulo`, `cst_icms_descricao`...), como a
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
(PL_CTe_400 NT 2026.005 RTC SN, de 04/11/2026, com o IBS e a CBS do Simples Nacional e o CT-e de que se cobra
multa e juros). O tomador vem pronto: quando o XML só diz o papel dele
(remetente, expedidor, recebedor ou destinatário), os dados dessa pessoa são copiados para as colunas
`tomador_`. Conferido com 14 mil CT-e reais (que não estão no repositório), contra outro sistema e contra um
segundo leitor do XML: os campos e as contagens comparados bateram em todos.

## Ler o XML do CT-e simplificado

```r
lido = cte_simplificado_ler(c("simp1.xml", "simp2.xml"))   # ou o próprio texto do XML
lido$ctes          # uma linha por CT-e: tomador, emitente, totais, ICMS, IBS e CBS, carga, protocolo
lido$entregas      # uma linha por entrega: municípios de início e de fim, valor, IBS e CBS
lido$componentes   # os componentes do valor de cada entrega (frete peso, pedágio...)
lido$documentos    # as NF-e de cada entrega, o CT-e anterior e o CT-e substituído
lido$cargas        # as quantidades da carga, com o tipo da medida em código (peso bruto da NF-e, caixas...)
lido$impostos      # todos os campos de imposto, um por linha, com a entrega
lido$arquivos      # o que foi lido, e o motivo de cada arquivo que não deu
```

O CT-e simplificado (modelo 57, tipo 5, e o de substituição, tipo 6) tem a chave, o protocolo e os eventos do
CT-e, mas no lugar do remetente, do destinatário e dos documentos de uma prestação só traz o tomador e até 990
entregas, cada uma com o seu valor, o IBS e a CBS e os seus documentos. Por isso tem leitor próprio. Segue o
schema oficial (tipo `TCTeSimp`); nenhum CT-e simplificado real passou por ele ainda, só o exemplo do pacote,
validado contra o schema.

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
declarou (a DPS) e o que o sistema nacional calculou (ISSQN, valor líquido, IBS e CBS). Conferido com 11 mil NFS-e
reais (que não estão no repositório), contra outro sistema e contra um segundo leitor do XML: os campos comparados
bateram em todas.

Lê também a nota no leiaute da Nota Técnica SE/CGNFS-e 009, que a Produção Restrita já usa: onde ela mudou um campo
de lugar (a finalidade, o destinatário, o CST e a classificação do IBS e da CBS, as deduções do ISSQN), a coluna vem
de onde o campo estiver. Os significados dos códigos novos dela (a NFS-e de crédito e de débito, o optante pendente
do Simples) entram quando o schema oficial da NT 009 sair no portal.

No MDF-e e na NFS-e a tabela `campos` vem por padrão (`todos_os_campos = FALSE` a deixa de fora); na NF-e e
no CT-e, que já têm tabelas para quase tudo, só com `todos_os_campos = TRUE`.

## Ler o XML da NFS-e de prefeitura

```r
lida = nfse_prefeitura_ler(list.files("nfse", pattern = "xml$", full.names = TRUE))
lida$nfses      # uma linha por NFS-e, com as mesmas colunas nos três leiautes
lida$campos     # todos os campos, um por linha
lida$arquivos   # o que foi lido, e o motivo de cada arquivo que não deu
```

Lê a NFS-e dos padrões municipais, anteriores à NFS-e Nacional: o leiaute da Prefeitura de São Paulo (também o da
Reforma, com a chave da nota no ambiente nacional) e o padrão ABRASF, nas versões 1.00 (também a do Ginfes, com
prefixo no namespace) e 2.0x. As regras vêm dos schemas e dos manuais oficiais (o da Prefeitura de São Paulo, 3.3.4, e
os da ABRASF, 1.00, 2.02, 2.03 e 2.04), com o significado de cada código ao lado dele. A alíquota vem como está no XML, e a escala
muda: São Paulo manda a fração (0,05), a ABRASF 2 o percentual (5), e a ABRASF 1.00 não diz (no acervo, há
municípios dos dois jeitos); `aliquota_percentual` traz o percentual onde o manual diz a escala. O código do serviço
de São Paulo é o da tabela do município e fica em `codigo_tributacao_municipio`, como o da ABRASF; o item da lista da
LC 116, que só a ABRASF traz, fica em `item_lista_servico`. Os municípios com
leiaute próprio, fora desses três, ficam em `arquivos` com o motivo. Conferido com as 1.921 NFS-e de prefeitura do
acervo (que não estão no repositório) contra outro sistema: o número, o prestador, o tomador, o valor dos serviços, o
valor líquido e o cancelamento bateram em todas as que os dois leram (num prestador, o outro sistema ficou vazio).

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

---

[Voltar ao início](../README.md)
