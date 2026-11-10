# Certificado digital e SEFAZ (homologação)

[Voltar ao início](../README.md)

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
serviço: a SVAN não o tem e a SVRS não atende o MA, e o cadastro de lá só se consulta no site do Sintegra do MA. A
linha vem com esse motivo. A SEFAZ pode recusar quem pergunta (257, "Solicitante não habilitado para emissão da
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
desativada em 03/08/2026, e pela NT 008/2026 cada sistema gera o seu. A distribuição foi conferida na Produção
Restrita em 10/11/2026 com documentos de verdade (a NFS-e gerada e cancelada no teste da emissão): os dois vieram,
com o XML descompactado lido pelo `nfse_ler()` e pelo `eventos_ler()`, a chave certa e a data de geração a menos de
um minuto da nota e do evento.

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

---

[Voltar ao início](../README.md)
