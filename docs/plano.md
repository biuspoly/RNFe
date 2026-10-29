# Plano do RNfe

Situação em 29/10/2026: **etapa 1 em andamento**: a chave de acesso e a leitura do XML da NF-e/NFC-e
prontas e conferidas com notas reais; faltam as tabelas fiscais. Repositório público no GitHub; o pacote
ainda não foi ao CRAN.

Decisões do usuário (29/10/2026): o nome é RNfe; só em R, porque no Python já existe o PyNFe e o que falta lá
vai como contribuição para ele. O pacote é um dos quatro do plano "Portar para o R" (os outros: financeiro,
leitor de códigos e utilidades brasileiras); o `veiculosbr` saiu das utilidades.

Antes de começar, o CRAN não tinha nenhum pacote de nota fiscal (dos 25.608 pacotes, nenhum trata de NF-e,
SEFAZ, SPED ou CFOP), e o nome RNfe estava livre no CRAN, no PyPI e no r-universe.

## As etapas

Cada etapa já é útil sozinha.

| Etapa | O que o pacote passa a fazer | Precisa de certificado? | Situação |
|---|---|---|---|
| 1 | Chave de acesso: conferir e desmontar, com o CNPJ alfanumérico | Não | pronta |
| 1 | Ler a nota de produto: o XML vira tabelas (cabeçalho, itens, impostos, parcelas) | Não | pronta |
| 1 | Tabelas fiscais (CFOP, CST, CSOSN; depois NCM, CEST e as da Reforma), com a data em que cada linha valeu | Não | |
| 2 | Ler CT-e, MDF-e e a NFS-e nacional | Não | |
| 3 | Certificado digital, SEFAZ no ar, baixar as notas recebidas | Sim | |
| 4 | Calculadora da Reforma (CBS e IBS): conferir e simular | Não | |
| 5 | Ler o SPED; pré-conferência do que a SEFAZ rejeitaria | Não | |
| por último | Assinatura, emissão e eventos (manifestação, desacordo do CT-e) | Sim | |

A assinatura é a peça mais delicada: vai ser comparada com a que o PyNFe faz.

## Tabelas que se atualizam sozinhas

O CRAN só recebe versão nova de tempos em tempos, então as tabelas vivem em três camadas: uma cópia dentro do
pacote (funciona sem internet), um repositório de dados no GitHub que um robô semanal atualiza a partir das
fontes oficiais, e o pacote buscando a mais nova de lá. Cada linha guarda "vale desde" e "vale até", para a
nota antiga ser lida com a tabela da época.

| Tabela | Fonte oficial | Atualização automática |
|---|---|---|
| NCM | Siscomex | sim |
| Municípios | IBGE | sim |
| Reforma (classificação e CST da CBS e do IBS) | Portal da NF-e e Receita | quase: a planilha muda de formato |
| CFOP, CST do ICMS, CSOSN, CEST | Confaz e Sinief | em parte: o robô avisa e alguém confere |

## Como testar sem certificado

Respostas da SEFAZ gravadas uma vez e lidas pelos testes; um certificado falso para conferir a assinatura
contra a do PyNFe; de vez em quando, uma consulta real.

## Dependências previstas

`xml2` (ler a nota) obrigatória; `httr2` e `openssl` opcionais, só para SEFAZ e certificado. Testes que vão à
internet ficam fora da checagem do CRAN (`skip_on_cran()`).

## Etapa 1, chave de acesso: o que se decidiu

- A regra das letras vem da NT Conjunta 2025.001 v1.00 (homologação 06/04/2026, produção 06/07/2026): cada
  caractere vale o ASCII menos 48, e o módulo 11 continua o mesmo, na chave e no CNPJ. Os exemplos dos testes
  foram calculados com a tradução literal dos anexos I (JavaScript) e II (VB.NET) da NT.
- A NT diz que algumas letras (I, O, U, Q, F) talvez não sejam aceitas no CNPJ, mas que isso "precisa ser
  confirmado": o pacote ainda aceita todas.
- A chave só é válida quando o CNPJ (ou o CPF, com três zeros na frente) da chave também confere, como a
  SEFAZ faz.
- Conferida em 29/10/2026 com 135.049 chaves reais (120.522 NF-e e 14.527 CT-e), que não entram no
  repositório: todas válidas, e número, série, ano, mês e modelo iguais aos do XML em todas. As 127 em que o
  CNPJ da chave não era o do emitente eram NF-e avulsas (`procEmi` 1): ali a chave traz o CNPJ do órgão do
  Fisco, o do grupo `avulsa`. Nenhuma tinha CNPJ com letras, então essa parte só foi conferida com o exemplo
  da Receita e os anexos da NT.
- O cálculo é feito em todas as chaves de uma vez: as 135 mil levam uns 2 s (a primeira versão, chave por
  chave, levava 2 min). A versão nova deu resultado idêntico ao da antiga nessas chaves e em 4 mil estragadas
  de propósito.
- `chave_digito()` aceita a chave inteira, não só as 43 primeiras posições: foi assim que o usuário a usou no
  primeiro teste, e o `NA` que voltava não explicava nada.

## Etapa 1, leitura do XML: o que se decidiu

- `nfe_ler()` segue o schema oficial do pacote de liberação PL_010g v1.03 (Portal da NF-e, 26/10/2026, NT
  2026.006 e NT 2026.008), que já traz o IBS, a CBS e o Imposto Seletivo. Devolve `notas`, `itens`,
  `impostos`, `parcelas`, `pagamentos` e `arquivos`, ligadas pela chave. Cada coluna aponta para um caminho do
  leiaute (as tabelas `CAMPOS_*` em `R/nfe_ler.R`, que também geram a ajuda).
- Os impostos principais vão em colunas de `itens`; `impostos` traz todos os campos de imposto de cada item,
  um por linha, para nada se perder (monofásico, diferimento, crédito presumido...).
- Arquivo que não dá para ler não para os outros: vai para `arquivos` com o motivo (não encontrado, XML
  quebrado, não é NF-e, só o resumo `resNFe`). Nunca vira nota vazia.
- As notas de exemplo (`inst/exemplos`) foram escritas à mão e passam no schema oficial
  (`ferramentas/validar_notas_de_teste.R`). Para ter certeza de que o validador confere de verdade, ele
  reprovou cinco versões estragadas de propósito (campo obrigatório faltando, CST inválido, vírgula no valor,
  campo fora de ordem, letra fora do CNPJ na chave). A segunda nota tem emitente com CNPJ alfanumérico.
- Conferida em 29/10/2026 com 10.000 notas reais sorteadas (que não entram no repositório), contra o que
  outro sistema já tinha tirado dos mesmos XMLs: número, série, emitente, destinatário, totais e, nos 46.018
  itens, código, descrição, NCM, CFOP, CEST, quantidades, valores, origem, CST/CSOSN, bases, alíquotas e
  valores de ICMS, ICMS ST, IPI, PIS e COFINS bateram em 100%. As diferenças foram todas do outro lado
  (campo vazio lá, preenchido aqui). Em 10 notas, a soma dos itens difere do total da nota em R$ 0,01: é o
  arredondamento de quem emitiu, e o pacote mostra o que está no XML.
- Velocidade: 13 ms por nota (eram 27). Medido antes de mexer: o `xml2` procurava os namespaces de novo a
  cada busca (o documento já está sem eles; agora cada busca passa `ns = SEM_NAMESPACE`) e montava um
  `data.frame` por arquivo (agora as colunas vão em listas e a tabela é montada uma vez, no fim). A versão
  nova deu resultado idêntico ao da anterior em 10 mil notas reais, nas seis tabelas. O que mais pesa agora:
  tirar os namespaces (2 ms) e a tabela de impostos (2 ms).
- O código segue o jeito do usuário (pedido de 29/10/2026: "sem variáveis genéricas, como se fosse eu
  criando as funções, algo fácil de entender"): nomes que dizem o que a coisa é, `for` em vez de função
  dentro de função, `if`/`else` por extenso.
- `documento` (NF-e, NFC-e, CT-e, CT-e OS, MDF-e) só para os modelos em que a composição da chave foi
  conferida; outro modelo é desmontado igual, com `documento` vazio. A forma de emissão sai como número: o
  significado de cada código muda de documento para documento e fica para quando for conferido no manual de
  cada um.
