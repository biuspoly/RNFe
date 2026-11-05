# RNFe

Documentos fiscais eletrônicos brasileiros (NF-e, NFC-e, CT-e, GTV-e, MDF-e, NFS-e Nacional) no **R**.

> **Em construção.** Esta versão traz a chave de acesso, a leitura do XML da NF-e (e do resumo que a
> Distribuição de DF-e entrega), da NFC-e, do CT-e, do CT-e OS, do CT-e simplificado, da GTV-e, do MDF-e, da
> NFS-e Nacional e dos eventos de todos eles, e as tabelas fiscais (CFOP, NCM, CSTs, as da Reforma, os
> municípios do IBGE, os meios de pagamento e o significado dos códigos de cada leiaute). Da
> SEFAZ, por enquanto, a leitura do certificado digital, o status do serviço e a consulta pela chave (NF-e, NFC-e,
> CT-e e MDF-e), os MDF-e não encerrados, a consulta de cadastro e a Distribuição de DF-e (NF-e e CT-e), em homologação;
> da NFS-e Nacional, a consulta pela chave e a distribuição, na Produção Restrita; e a situação do CNPJ na Receita
> Federal, pelas fontes públicas. Da Reforma Tributária, a conferência do IBS e da CBS da NF-e e da NFC-e pelas regras
> de validação da SEFAZ, como valiam no dia da emissão, e o cálculo de cada item, também para simular outro ano. O
> plano está em [docs/plano.md](https://github.com/biuspoly/RNFe/blob/main/docs/plano.md).

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
cte_simplificado_ler(ctes$documentos$xml)   # os CT-e simplificados (vêm para o tomador e os autorizados)
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

```r
# a situação do CNPJ na Receita Federal (sem certificado)
cnpj_situacao(c("11.222.333/0001-81", "11.444.777/0001-61"))
# cnpj, encontrado, situacao (ATIVA, BAIXADA...), data_situacao, motivo_situacao, razao_social, nome_fantasia,
# atualizado_em, fonte (a que respondeu), fontes_fora_do_ar e problema
```

A situação vem da BrasilAPI e, quando ela está fora do ar, do Minha Receita, da CNPJá, da ReceitaWS e da CNPJ.ws,
uma depois da outra: todas públicas, republicando o cadastro da Receita. Fora do ar é sem resposta, limite de
consultas (429), erro do servidor ou resposta fora do formato. O CNPJ que uma fonte não tem também é procurado na
próxima (o aberto há pouco pode não estar ainda nos dados abertos que a BrasilAPI usa). Só conta como "não achou"
a resposta no formato de cada fonte para o CNPJ que não existe; outra (o 404 de um proxy, um erro de consulta)
conta como fora do ar. A BrasilAPI e o Minha Receita são a mesma base: quando uma responde, a outra não é
perguntada. `encontrado` fica `FALSE` quando as que responderam não acharam e todas as seguintes responderam; se
alguma ficou fora do ar depois de um "não achou", ele fica `NA`, com o motivo em `problema`, porque ela poderia ter
achado. A ReceitaWS e a CNPJ.ws aceitam poucas consultas por minuto (3, em 04/11/2026), e por isso vêm por último;
dá para escolher as fontes e a ordem com `fontes`.

Por enquanto o RNFe só fala com o ambiente de **homologação** da SEFAZ: a produção é recusada antes de qualquer
conexão. O CNPJ do certificado vem do campo que a ICP-Brasil reserva para ele (DOC-ICP-04). O endereço de cada
serviço e o autorizador de cada UF (a própria SEFAZ ou uma SEFAZ virtual) vêm das Relações de Serviços Web dos
portais de cada documento (e da página da SEFAZ-MG, na NFC-e), que o robô das tabelas confere toda semana.

Não é preciso configurar nada, nem no Windows. Testado em 30/10/2026: as 27 UFs responderam numa sessão comum do R
no Windows. Lá o curl do R usa o motor de conexão segura do próprio Windows (Schannel), que não conecta com BA, MA,
MG, MT e SP; quando é ele que está ligado, o RNFe manda os pedidos por um processo R separado, aberto com o motor
OpenSSL, e a sua sessão não muda. Isso custa uns 0,3 segundo por chamada (não por UF).

O certificado vai em PEM, num arquivo temporário apagado no fim, com a chave cifrada por uma senha sorteada na hora,
não a do certificado; para o processo separado, essa senha vai numa variável de ambiente só dele, nunca num arquivo.
O certificado do servidor é sempre
verificado: contra as raízes de sempre e a raiz v10 da ICP-Brasil, que vem no pacote (conferida com a do repositório
do ITI). O PyNFe conecta sem isso porque desliga a verificação (`verify=False`).

## Assinar, enviar e registrar eventos (homologação)

```r
assinada = xml_assinar("nota.xml", "empresa.pfx", senha)   # a NF-e, NFC-e, CT-e, MDF-e, DPS ou evento assinado
nfe_conferir(assinada)                                      # confira antes de enviar
resposta = sefaz_autorizar(assinada, "empresa.pfx", senha)  # a situação (100), o protocolo e o nfeProc
writeLines(resposta$xml_autorizado, "nota_autorizada.xml", useBytes = TRUE)

sefaz_carta_correcao(resposta$chave, "ONDE SE LE RUA 10, LEIA-SE RUA 100", 1, "empresa.pfx", senha)
sefaz_cancelar(resposta$chave, resposta$protocolo, "PEDIDO CANCELADO PELO CLIENTE", "empresa.pfx", senha)
sefaz_manifestar(chave_recebida, "ciencia", certificado = "empresa.pfx", senha = senha)   # o destinatário
sefaz_cte_desacordo(chave_do_cte, "FRETE COBRADO EM DUPLICIDADE", "empresa.pfx", senha)   # o tomador do CT-e

mdfe = sefaz_mdfe_autorizar(xml_assinar("mdfe.xml", "empresa.pfx", senha), "empresa.pfx", senha)   # o MDF-e
sefaz_mdfe_incluir_condutor(mdfe$chave, "NOME DO MOTORISTA", cpf_do_motorista, certificado = "empresa.pfx", senha = senha)
sefaz_mdfe_encerrar(mdfe$chave, mdfe$protocolo, "PE", "2611606", Sys.Date(), "empresa.pfx", senha)

nfse = nfse_emitir("dps.xml", "empresa.pfx", senha)          # a NFS-e Nacional gerada a partir da DPS
nfse_cancelar(nfse$chave, "erro_na_emissao", "VALOR DO SERVICO INFORMADO ERRADO", "empresa.pfx", senha)

nfce = nfce_qrcode("nfce.xml", endereco_qrcode_da_uf, endereco_consulta_da_uf)   # o QR-Code da NFC-e (versão 3)
nfce = nfce_qrcode("nfce.xml", endereco_qrcode_da_uf, endereco_consulta_da_uf, "empresa.pfx", senha)  # off-line
```

A assinatura segue o Manual de Orientação: o elemento que tem o `Id` (`infNFe`, `infCte`, `infMDFe`, `infDPS`,
`infEvento`) é canonicalizado (C14N), o resumo SHA-1 dele vai na assinatura e o `SignedInfo` é assinado com a chave
do certificado (RSA); a DPS da NFS-e Nacional usa o SHA-256. A canonicalização é feita pelo RNFe e foi conferida com
1.000 NF-e reais autorizadas (o mesmo resumo e a assinatura verificada em todas) e com o PyNFe, que assina o mesmo XML
igual, byte a byte (ele tira os acentos antes; o RNFe não). O XML assinado vem sem os espaços entre as tags, que a
SEFAZ rejeita.

A autorização manda cada nota num lote só dela, no modo síncrono (a NT 2023.002 acaba com o assíncrono em 2027); se a
SEFAZ responde que vai processar depois (103), o RNFe consulta o recibo até a resposta chegar. A nota autorizada vem
com o `nfeProc` (a nota e o protocolo), que o `nfe_ler()` lê. Os eventos (cancelamento, carta de correção e
manifestação do destinatário, esta no Ambiente Nacional) são montados, assinados e enviados pelo RNFe, e voltam com o
`procEventoNFe`, que o `eventos_ler()` lê. O tomador do CT-e registra a prestação do serviço em desacordo (e cancela
o registro feito por engano) no autorizador do CT-e, com o `procEventoCTe` de volta.

O MDF-e vai compactado e é autorizado na hora pela SVRS, que atende todas as UF; o QR-Code dele entra sozinho
quando falta. Depois vêm a inclusão de condutor e o encerramento, com o `procEventoMDFe` de volta. A NFS-e Nacional é
gerada pela Sefin a partir da DPS que você monta pelo leiaute; o RNFe assina, compacta, envia e devolve a NFS-e (que o
`nfse_ler()` lê). O cancelamento também é montado e assinado aqui.

O QR-Code da NFC-e sai na versão 3 (NT 2025.001), que não usa mais o CSC: na emissão normal, a chave, a versão e o
ambiente; na contingência off-line, também o dia da emissão, o valor, o destinatário e a assinatura desses dados com o
mesmo certificado que assina a nota. Os endereços da consulta são os da UF do emitente, publicados no Portal da NFC-e,
e vão como argumento. O grupo sai no lugar certo para o schema, e a assinatura da nota não o cobre (pode ser antes ou
depois de `xml_assinar()`).

Testado na SVRS de homologação em 05/11/2026 com o certificado de uma empresa: uma NF-e montada a partir de uma nota
real, com o tpAmb 2, foi assinada pelo RNFe e autorizada (100); a carta de correção e o cancelamento foram registrados
(135) e a ciência da operação, no Ambiente Nacional (136). As rejeições que vieram antes foram de regras que a
pré-conferência acusa: o indicador do intermediador (434) e o CPF do transportador zerado (543) ela já acusava; o
vencimento da parcela antes da emissão (900, a Y09-20) entrou nela depois desse teste. O desacordo de um CT-e
inventado voltou "CT-e não consta na base de dados" (217): o evento passou pelo schema, pela assinatura e pelo órgão
de recepção. Um MDF-e de carga própria foi autorizado (100), ganhou um condutor e foi encerrado (135 nos dois). Na
Produção Restrita da NFS-e Nacional, uma NFS-e foi gerada (201) a partir de uma DPS montada sobre uma nota real e
cancelada (201). A Produção Restrita já usa o leiaute da NT 009 (o XSD de 20/10/2026, com o `finNFSe` e outra ordem
no `cServ`), que o pacote de schemas que o `nfse_ler()` segue ainda não traz; a série da DPS enviada por sistema
próprio é outra que a do Emissor Nacional (a 70000 voltou E0010, a 1 passou). Só a homologação: a nota com o tpAmb 1 nem é enviada.

## Os documentos auxiliares em PDF

```r
danfe_pdf("nota_autorizada.xml", "danfe.pdf")        # A4, com quantas folhas os itens pedirem
danfe_simplificado_pdf("nota_autorizada.xml", "simplificado.pdf")                 # o DANFE Simplificado
danfe_simplificado_pdf("nota_autorizada.xml", "etiqueta.pdf", etiqueta = TRUE)    # a Etiqueta, sem os itens
danfce_pdf("nfce_autorizada.xml", "danfce.pdf")      # a bobina de 80 mm, com o QR-Code
dacte_pdf("cte_autorizado.xml", "dacte.pdf")         # o CT-e e o CT-e OS
damdfe_pdf("mdfe_autorizado.xml", "damdfe.pdf")      # o MDF-e (o modal rodoviário completo)
danfse_pdf("nfse.xml", "danfse.pdf")                 # o DANFSe v2.0 da NFS-e Nacional
dacce_pdf("carta_de_correcao.xml", "carta.pdf")      # a carta de correção da NF-e ou do CT-e
```

Cada um segue o manual do documento: o DANFE, o Anexo II do Manual de Orientação da NF-e (as posições dos quadros e
o código de barras da chave em CODE-128C, conferido com o exemplo do manual, 09758364 com o dígito 48); com o CNPJ
alfanumérico, a chave vai em CODE-128 C e A, como manda a Nota Técnica Conjunta 2025.001. O DANFE Simplificado e a
Etiqueta seguem os campos mínimos dos itens 3.11 e 3.12 do mesmo anexo, que não traz leiaute: o desenho é o do RNFe,
em papel de 10 cm, para a chave com o CNPJ alfanumérico caber com o módulo mínimo do código de barras (0,02 cm). O
DANFE Simplificado Tipo 2 da NT 2026.002 não entrou: a nota técnica não traz o leiaute dele. O DANFE NFC-e segue o
Manual de Padrões Técnicos do DANFE NFC-e e QR Code (as divisões da bobina, a contingência e o consumidor); o DACTE, o
do CT-e 4.00 (também o DACTE OS); o DAMDFE, o Anexo II do Manual do MDF-e; e o DANFSe, a Nota Técnica SE/CGNFS-e
008/2026 (a versão 2.0, com os blocos do IBS e da CBS e as linhas únicas de quando a nota não tem tomador,
destinatário, intermediário ou ISSQN). A logomarca da NFS-e não vai: no lugar dela, o texto "NFS-e". A carta de
correção não tem modelo oficial: o desenho é o do RNFe, com a chave em código de barras, o registro na SEFAZ, a
correção e as condições de uso. Os documentos de homologação saem com a marca de sem valor fiscal (no DANFSe, "NFS-e
SEM VALIDADE JURÍDICA"). Os códigos de barras e os QR-Code dos exemplos foram lidos de volta por um leitor (o zxing),
com a chave e o endereço certos. Tudo é desenhado com o `grid` do próprio R; o QR-Code precisa do pacote `qrcode`.

## Antes de enviar: a pré-conferência da NF-e

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

Ficam de fora as regras que a NT deixa para implementação futura (as do Imposto Seletivo entre elas) e as quatro
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

## SPED Fiscal: a EFD ICMS/IPI em tabelas

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

## Tabelas fiscais

```r
tabela_fiscal("cfop")                    # título, nota explicativa e indicadores de cada CFOP
tabela_fiscal("ncm")                     # a NCM vigente, com a descrição completa de cada código
tabela_fiscal("classificacao_ibs_cbs")   # a cClassTrib da Reforma, e "cst_ibs_cbs", com os indicadores de cada um
tabela_fiscal("credito_presumido_ibs_cbs")  # o cCredPres: os grupos que cada código exige e se desconta do IBS
tabela_fiscal("mudancas_ibs_cbs")        # o que mudou nessas três de uma versão para a outra, com o prazo de produção
tabela_fiscal("aliquotas_ibs_cbs")       # as alíquotas do IBS e da CBS de cada ano, com a base legal
tabela_fiscal("local_operacao_ibs_cbs")  # o cIndOp (local da operação), do Anexo VII da NFS-e Nacional
tabela_fiscal("biocombustivel_ibs_cbs")  # o etanol anidro obrigatório em cada gasolina C, com a vigência
tabela_fiscal("combustiveis_monofasicos") # os combustíveis do ICMS monofásico e a alíquota ad rem de cada período
tabela_fiscal("cst_icms")                # e "origem", "csosn", "cst_ipi", "cst_pis", "cst_cofins"
tabela_fiscal("municipios")              # os municípios do IBGE: código de 7 dígitos, nome e UF
tabela_fiscal("meios_pagamento")         # o tPag da NF-e e da NFC-e (PIX, boleto...), e "bandeiras_cartao"
tabela_fiscal("codigos_dos_campos")      # o significado dos códigos do leiaute (tpEmis, modFrete, toma...)
tabela_fiscal("leiaute_efd_icms_ipi")    # os registros e os campos do SPED Fiscal, com a vigência
tabela_fiscal("fontes")                  # de onde veio cada tabela, com a versão e a data
```

A maioria tem o `inicio` e o `fim` da vigência (vazios no CSOSN, no CST do IBS e da CBS e nos municípios, que a
fonte não data; a ajuda de `tabela_fiscal()` diz as colunas de cada uma). As
fontes são oficiais: o Portal da NF-e (CFOP, Reforma, combustíveis, meios de pagamento e bandeiras), o Portal da
NFS-e Nacional (o local da operação da Reforma), o Portal Único
Siscomex (NCM), as tabelas do SPED Fiscal, da Receita (CSTs), e a API de localidades do IBGE (municípios).
O CST e a classificação do IBS e da CBS trazem os indicadores da planilha oficial (os grupos que cada um exige ou
não permite no documento e os documentos em que a classificação vale), que as regras de validação da NT 2025.002
consultam. As alíquotas do IBS e da CBS vêm da LC 214/2025: 0,1% de IBS da UF e 0,9% de CBS em 2026, e 0,05% de IBS
da UF e do município em 2027 e 2028; a CBS de 2027 e 2028 é a alíquota de referência que o Senado fixa menos 0,1
ponto percentual, e fica vazia até ser publicada. A tabela vai até 2028.
`ferramentas/gerar_tabelas.R` baixa tudo e refaz as cópias; um robô faz isso toda semana e abre um aviso
quando alguma tabela muda. Os municípios ficam de fora do robô, porque o IBGE não aceita conexão dos
servidores do GitHub.

```r
tabelas_atualizar()                           # as tabelas mais novas do repositório, sem esperar versão nova
tabelas_atualizar(usar_as_do_pacote = TRUE)   # volta às que vieram no pacote
```

O que o robô acha entra no repositório depois de uma pessoa conferir. `tabelas_atualizar()` baixa de lá as tabelas
fiscais e os endereços da SEFAZ para a pasta de cache do R e passa a usá-las, também nas próximas sessões. Nada é
baixado sem ela ser chamada. Primeiro vem a lista de conferência do repositório (`conferencia.csv`: as linhas e a
soma de conferência de cada tabela, e a versão do conjunto). Cada tabela baixada tem de conferir com ela, abrir sem
erro e ter as colunas da do pacote (se o formato mudou, o resultado pede para atualizar o pacote), e as tabelas são
trocadas todas juntas ou nenhuma. As baixadas valem enquanto o conjunto delas for mais novo que o do pacote
instalado: quem instala um pacote com tabelas mais novas volta a ter as dele. Depois de mexer numa tabela à mão,
rode `ferramentas/gerar_conferencia_das_tabelas.R` (o teste reclama se a lista ficar para trás).

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

A pré-conferência usa os schemas do pacote de liberação 010g (versão 1.03) do Portal da NF-e, que vão no pacote em
`inst/schemas/nfe`, e as regras de validação do Anexo I do MOC 7.0 com as notas técnicas que as mudaram depois; a
regra, o código, a mensagem e a fonte de cada uma estão em `inst/extdata/regras_nfe.csv`.

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
