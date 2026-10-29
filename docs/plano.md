# Plano do RNfe

Situação em 29/10/2026: **etapa 1 concluída** (chave de acesso, leitura do XML da NF-e/NFC-e e tabelas
fiscais, conferidas com notas reais; o CEST foi adiado por decisão do usuário). **Etapa 2 começando.**
Repositório público no GitHub. **Nada vai ao CRAN até o usuário pedir** (decisão de 29/10/2026).

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
| 1 | Tabelas fiscais (CFOP, CST, CSOSN; depois NCM, CEST e as da Reforma), com a data em que cada linha valeu | Não | prontas, menos o CEST (adiado, veja abaixo) |
| 2 | Ler CT-e, MDF-e e a NFS-e nacional | Não | em andamento |
| 3 | Certificado digital, SEFAZ no ar, baixar as notas recebidas | Sim | |
| 4 | Calculadora da Reforma (CBS e IBS): conferir e simular | Não | |
| 5 | Ler o SPED; pré-conferência do que a SEFAZ rejeitaria | Não | |
| por último | Assinatura, emissão e eventos (manifestação, desacordo do CT-e) | Sim | |

A assinatura é a peça mais delicada: vai ser comparada com a que o PyNFe faz.

## Mais completo que o PyNFe (meta do usuário, 29/10/2026)

O RNfe tem de cobrir o que o PyNFe faz e também o que só existe nas bibliotecas que completam o PyNFe: o
brans-nfe (NFS-e Nacional) e o BrazilFiscalReport (os PDFs). Fontes: o README do PyNFe no GitHub, e as
páginas do brans-nfe 0.2.0 (10/06/2026) e do BrazilFiscalReport 1.3.1 (13/10/2026) no PyPI, lidas em
29/10/2026.

| O que | PyNFe | brans-nfe | BrazilFiscalReport | RNfe |
|---|---|---|---|---|
| Ler o XML em tabelas (NF-e, NFC-e) | não | não | não | pronto (etapa 1) |
| Ler CT-e, MDF-e e NFS-e Nacional em tabelas | não | não | não | etapa 2 |
| Tabelas fiscais com vigência (CFOP, NCM, CST, Reforma) | não | não | não | pronto (etapa 1) |
| Status da SEFAZ, consulta por chave e de protocolo | NF-e, MDF-e | NFS-e | não | etapa 3 |
| Distribuição (baixar o que foi emitido contra o CNPJ) | NF-e, CT-e | NFS-e | não | etapa 3 |
| Certificado A1, assinatura e conexão segura (mTLS) | sim | sim | não | etapa 3 e última |
| Emitir NF-e e NFC-e (normal e contingência) | sim | não | não | última |
| Cancelamento, carta de correção, inutilização | NF-e | NFS-e (cancelamento) | não | última |
| Manifestação do destinatário | sim | não | não | última |
| MDF-e: emitir, encerrar, incluir condutor e DF-e | sim | não | não | última (entrou agora no plano) |
| CT-e: consultar e registrar desacordo | não | não | não | etapa 3 e última |
| NFS-e Nacional: emitir, consultar, cancelar, eventos | não | sim | não | etapa 3 e última |
| NFS-e no padrão Abrasf (Ginfes, Betha) | sim | não | não | não previsto: o padrão nacional substitui |
| Baixar o DANFSe oficial | não | sim | não | etapa 3 |
| PDFs: DANFE, DANFCe, DACTE, DAMDFE, DANFSe, DACCe e etiqueta | não (usa o BrazilFiscalReport) | só o DANFSe não oficial | sim | última (entraram agora no plano) |
| Calculadora da Reforma: conferir e simular | não | não | não | etapa 4 |
| Ler o SPED e pré-conferência | não | não | não | etapa 5 |

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
- `documento` (NF-e, NFC-e, CT-e, CT-e OS, MDF-e) só para os modelos em que a composição da chave foi
  conferida; outro modelo é desmontado igual, com `documento` vazio. A forma de emissão sai como número: o
  significado de cada código muda de documento para documento e fica para quando for conferido no manual de
  cada um.

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

## Etapa 1, tabelas fiscais menores: o que se decidiu

- **Fontes:** as duas são oficiais e baixadas por `ferramentas/gerar_tabelas.R`.
  - O **CFOP** vem da Tabela de CFOP do Portal da NF-e (Informe Técnico 2023.002 v2.10, de 04/09/2026). Ela
    traz o título e a nota explicativa literais do Convênio SINIEF s/nº de 1970, o início de vigência e os
    indicadores.
  - Os **CSTs** vêm das tabelas externas do SPED Fiscal, pelo serviço público do próprio SPED
    (`WsConsulta.asmx` e `obterTabela.ashx`), o mesmo que o programa validador usa. Cada código vem com
    início e fim, e é procurado pelo tipo, não por um número fixo.
- **Correções sobre o SPED**, cada uma com prova:
  - A tabela A (origem) parou em 2012 e não tem a origem 8 (desde 01/08/2013).
  - A tabela B (CST de 2 dígitos) parou em 2009 e não tem os quatro de combustível monofásico (02, 15, 53, 61,
    desde 01/04/2023).
  - Os dois casos vêm da tabela de CST de três dígitos do SPED, que está em dia.
  - O CSOSN vai **sem datas**. Na EFD ele divide o campo com o CST, e o SPED "encerrou" o 300, o 400 e o 500
    em 2012 e o 102 e o 202 em 2023 só porque passaram a coincidir com CSTs novos. O schema da NF-e PL_010g
    ainda aceita todos.
- **Codificação:** os arquivos do SPED são **Windows-1252**, não Latin-1. Lidos como Latin-1, o travessão
  (byte 0x96) do CST 51 do PIS virava um caractere invisível.
- **Antes de 2009**, quando o SPED Fiscal começou, a descrição fica vazia: o pacote não chuta a da época.
- **CFOP revogado:** a tabela de CFOP da NF-e só tem os códigos vigentes, então um CFOP revogado fica sem
  título. O SPED tem o histórico (649 linhas, de 2022) e pode entrar depois, se fizer falta.
- **Conferência com notas reais:** nas 10 mil notas reais (46.593 itens, de 2021 a 2026), todos os códigos
  acharam o nome. Pôr os nomes custa menos de 1 s para 46 mil itens.

## Etapa 1, NCM e tabelas da Reforma: o que se decidiu

- **NCM:** a nomenclatura vigente do Portal Único Siscomex (arquivo público
  `classif/api/publico/nomenclatura/download/json`), em todos os níveis, com o código sem os pontos.
  - A descrição completa junta a da posição (4 dígitos) com a de cada nível abaixo dela, porque o subitem
    sozinho costuma dizer só "-- Outros". Ela é montada ao ler a tabela, não gravada.
  - O arquivo só traz o que vale hoje, desde a versão atual da NCM (01/04/2022). Uma nota anterior fica sem a
    descrição.
  - Um NCM extinto depois de 2022 também fica sem descrição, mesmo em nota da época em que valia. Em 10 mil
    notas reais foram 76 itens, entre eles códigos que não são NCM ("00", "00000000").
- **Reforma:** a Tabela de Classificação Tributária do IBS e CBS do Portal da NF-e (Informe Técnico 2025.002
  v1.70, de 01/10/2026), com a aba de CST (18 códigos) e a de cClassTrib (173 classificações, todas desde
  01/01/2026).
  - O Excel guardava alguns CST como número (400 em vez de "400"); voltam com três dígitos.
  - Nota anterior a 2026 com o grupo IBSCBS (fase de testes) fica sem o nome da classificação. Em 10 mil notas
    reais foram 5 itens.

## O robô das tabelas

- `.github/workflows/atualizar-tabelas.yml` roda toda segunda às 9h UTC (6h em Brasília), e também à mão. Ele
  roda `ferramentas/gerar_tabelas.R` e compara o resultado com as tabelas do pacote; a data de download, em
  `fontes.csv`, não conta.
- Quando algo mudou, grava as tabelas num ramo `tabelas-AAAA-MM-DD` e abre um aviso (issue) com o resumo de
  `ferramentas/resumir_mudancas.R`: códigos novos, que saíram e linhas alteradas, tabela por tabela, mais o
  link para comparar. Quem junta ao pacote é uma pessoa, depois de conferir.
- É um aviso e não um pull request porque o repositório não deixa o Actions abrir pull request
  (`can_approve_pull_request_reviews: false`). Mudar isso é uma configuração de segurança do usuário.
- **Testado em 29/10/2026:** os sites do Portal da NF-e, do SPED e do Siscomex respondem aos servidores do
  GitHub, e uma execução leva uns 50 s.
- **Aviso falso no primeiro teste:** uma célula da tabela da Reforma tem quebra de linha dentro do texto, que
  o Windows gravava como `\r\r\n` e o Linux como `\r\n`. Desde então o gerador troca quebra dentro da célula
  por espaço e grava sempre com `\n`, e o `.gitattributes` guarda os CSV com LF. Na execução seguinte o robô
  não achou mudança, e o aviso falso foi fechado com a explicação.
- **Falta a terceira camada:** o pacote buscar sozinho, no computador de quem usa, a tabela mais nova do
  repositório.

## CEST: adiado (decisão do usuário, 29/10/2026)

Nenhuma fonte oficial dá a descrição atual do CEST sem ambiguidade, e o Portal da NF-e não publica tabela de
CEST (conferidas 495 publicações em cinco seções).

| Fonte | O que dá com certeza | O problema |
|---|---|---|
| SPED, tabela externa 996 (v18) | os 1.049 códigos e as descrições, com datas, até 31/08/2023 | desde 01/09/2023 as 1.038 linhas vigentes dizem só "Verificar, para o CEST, a descrição vigente para cada período no Convênio ICMS 142/18" |
| Convênio ICMS 142/18, página do Confaz | a redação atual (linhas de classe `A7-*`; as anteriores são `A9-*`) e o NCM de cada CEST | as seções de RETIFICAÇÃO e as tabelas repetidas da cláusula vigésima segunda deixam 36 códigos com mais de um texto "atual"; 3 códigos vigentes só no SPED e 15 só no Confaz; as notas de alteração têm 99 modelos de "nova redação" e 58 de "redação anterior" (com "sem efeitos", intervalos e erros de digitação) |

Opções quando voltar: só o SPED (descrições até 31/08/2023), ou o Confaz revisado caso a caso com o usuário.
