# Plano do RNFe

Situação em 06/11/2026: **etapas 1 a 5 e a última feitas, e revisadas** (seção "Revisão das etapas 1 a 3", no fim
das da etapa 3). Etapa 1: chave de acesso, leitura do XML da NF-e/NFC-e e tabelas fiscais, conferidas com
notas reais; o CEST entrou em 06/11/2026, pela tabela do SPED (veja a seção dele). Etapa 2: a leitura do CT-e e do CT-e OS (14.370 CT-e
reais), da GTV-e, do CT-e simplificado e do MDF-e (os dois pelo schema oficial, sem documentos reais para
comparar), da NFS-e Nacional (11.207 reais) e dos eventos de todos; a NFS-e de prefeitura (São Paulo e ABRASF, 1.921
reais) entrou em 06/11/2026, depois da última etapa. Etapa 3:
certificado, SEFAZ (status, consulta pela chave, cadastro, MDF-e não encerrados, Distribuição da NF-e e do
CT-e) e a NFS-e Nacional, em homologação, e a situação do CNPJ na Receita. O que a revisão de 04/11/2026
deixou em aberto está no fim dela. Etapa 4 (a Reforma): as tabelas, a conferência e o cálculo prontos, e
revisados em 05/11/2026 (seção "Revisão da etapa 4", no fim da etapa 4). Etapa 5: a leitura da EFD ICMS/IPI, o
cruzamento com as NF-e e a pré-conferência da NF-e, prontos e revisados (05/11/2026). Última etapa: assinatura,
autorização da NF-e e da NFC-e, eventos, QR-Code da NFC-e, desacordo do CT-e, MDF-e e a emissão e o cancelamento da
NFS-e Nacional prontos, em homologação, e os PDFs (DANFE, DANFE Simplificado e Etiqueta, DANFE NFC-e, DACTE, DAMDFE,
DANFSe e a carta de correção) prontos (05/11/2026).
Repositório público no GitHub. **Nada vai ao CRAN até o usuário pedir** (decisão de 29/10/2026).

Decisões do usuário (29/10/2026): o nome é RNfe; só em R, porque no Python já existe o PyNFe e o que falta lá
vai como contribuição para ele. Em 30/10/2026 o nome passou a **RNFe**, com o F maiúsculo, como o PyNFe (pedido
do usuário: "é possível trocar a biblioteca pra RNFe? com o F maiúsculo, como o PyNFe"). O pacote é um dos quatro do plano "Portar para o R" (os outros: financeiro,
leitor de códigos e utilidades brasileiras); o `veiculosbr` saiu das utilidades.

Antes de começar, o CRAN não tinha nenhum pacote de nota fiscal (dos 25.608 pacotes, nenhum trata de NF-e,
SEFAZ, SPED ou CFOP), e o nome RNfe estava livre no CRAN, no PyPI e no r-universe. Na troca para RNFe
(30/10/2026), nenhum dos 25.577 pacotes do CRAN tinha esse nome, em nenhuma combinação de maiúsculas.

## As etapas

Cada etapa já é útil sozinha.

| Etapa | O que o pacote passa a fazer | Precisa de certificado? | Situação |
|---|---|---|---|
| 1 | Chave de acesso: conferir e desmontar, com o CNPJ alfanumérico | Não | pronta |
| 1 | Ler a nota de produto: o XML vira tabelas (cabeçalho, itens, impostos, parcelas) | Não | pronta |
| 1 | Tabelas fiscais (CFOP, CST, CSOSN; depois NCM, CEST, as da Reforma e os municípios), com a data em que cada linha valeu | Não | prontas (o CEST pelo SPED, em 06/11/2026: as descrições até 08/2023, veja abaixo) |
| 2 | Ler CT-e, MDF-e e a NFS-e nacional, e os eventos de todos | Não | prontos (CT-e, CT-e OS, CT-e simplificado, GTV-e, MDF-e, NFS-e Nacional, eventos e o resumo da NF-e); a NFS-e de prefeitura (São Paulo e ABRASF 1.00 e 2.0x) pronta em 06/11/2026 |
| 3 | Certificado digital, SEFAZ no ar, baixar as notas recebidas | Sim | pronta, em homologação: certificado, status do serviço e consulta pela chave nas 27 UFs (NF-e, NFC-e, CT-e, CT-e OS, GTV-e e MDF-e), MDF-e não encerrados, consulta de cadastro nas 26 que têm o serviço e a Distribuição de DF-e da NF-e e do CT-e, em homologação; da NFS-e Nacional, a consulta pela chave (com os eventos) e a distribuição, na Produção Restrita; a chave num PDF ou numa foto; a situação do CNPJ na Receita (sem certificado) |
| 4 | Calculadora da Reforma (CBS e IBS): conferir e simular | Não | pronta (04/11/2026) e revisada (05/11/2026): as tabelas, a conferência (`ibs_cbs_conferir`) e o cálculo (`ibs_cbs_calcular`, também para simular outro ano) |
| 5 | Ler o SPED; pré-conferência do que a SEFAZ rejeitaria | Não | pronta e revisada (05/11/2026): a EFD ICMS/IPI em tabelas, o cruzamento com as NF-e e a pré-conferência da NF-e e da NFC-e (`nfe_conferir`) |
| por último | Assinatura, emissão e eventos (manifestação, desacordo do CT-e) | Sim | em andamento, só em homologação: assinatura, autorização da NF-e e da NFC-e, cancelamento, carta de correção, manifestação, QR-Code da NFC-e, desacordo do CT-e, MDF-e (autorização, condutor e encerramento) e a NFS-e Nacional (emissão e cancelamento) prontos; os PDFs prontos (sem certificado) |

A assinatura é a peça mais delicada: vai ser comparada com a que o PyNFe faz.

## Mais completo que o PyNFe (meta do usuário, 29/10/2026)

O RNFe tem de cobrir o que o PyNFe faz e também o que só existe nas bibliotecas que completam o PyNFe: o
brans-nfe (NFS-e Nacional) e o BrazilFiscalReport (os PDFs). Fontes: o README do PyNFe no GitHub, e as
páginas do brans-nfe 0.2.0 (10/06/2026) e do BrazilFiscalReport 1.3.1 (13/10/2026) no PyPI, lidas em
29/10/2026.

| O que | PyNFe | brans-nfe | BrazilFiscalReport | RNFe |
|---|---|---|---|---|
| Ler o XML em tabelas (NF-e, NFC-e) | não | não | não | pronto (etapa 1) |
| Ler CT-e, CT-e OS, GTV-e e MDF-e em tabelas | não | não | não | pronto (etapa 2) |
| Ler NFS-e Nacional em tabelas | não | não | não | pronto (etapa 2) |
| Ler os eventos (cancelamento, carta de correção, manifestação, encerramento) em tabelas | não | não | não | pronto (etapa 2) |
| Tabelas fiscais com vigência (CFOP, NCM, CST, Reforma) e municípios | não | não | não | pronto (etapa 1) |
| Status da SEFAZ, consulta por chave e de protocolo | NF-e, MDF-e | NFS-e | não | status e consulta pela chave da NF-e, da NFC-e, do CT-e e do MDF-e, e os MDF-e não encerrados, prontos em homologação; a NFS-e Nacional pela chave, com os eventos, pronta na Produção Restrita |
| Distribuição (baixar o que foi emitido contra o CNPJ) | NF-e, CT-e | NFS-e | não | NF-e, CT-e e NFS-e Nacional prontos em homologação (a da NFS-e na Produção Restrita) |
| Certificado A1, assinatura e conexão segura (mTLS) | sim | sim | não | pronto: a assinatura conferida com 1.000 NF-e reais e com o PyNFe |
| Emitir NF-e e NFC-e (normal e contingência) | sim | não | não | pronto em homologação (o QR-Code da NFC-e na versão 3, também off-line) |
| Cancelamento, carta de correção, inutilização | NF-e | NFS-e (cancelamento) | não | cancelamento e carta de correção prontos em homologação; a inutilização não (o serviço acaba em 11/11/2026, NT 2023.002) |
| Manifestação do destinatário | sim | não | não | pronto em homologação |
| MDF-e: emitir, encerrar, incluir condutor e DF-e | sim | não | não | emitir, incluir condutor, incluir DF-e (desde 10/11/2026) e encerrar: prontos em homologação |
| CT-e: consultar e registrar desacordo | não | não | não | consultar: pronto em homologação (etapa 3); desacordo e o cancelamento dele: prontos em homologação |
| NFS-e Nacional: emitir, consultar, cancelar, eventos | não | sim | não | consultar e ler os eventos (etapa 3), emitir e cancelar: prontos na Produção Restrita |
| NFS-e no padrão Abrasf (Ginfes, Betha) | sim | não | não | ler: pronto (06/11/2026), a ABRASF 1.00 e 2.0x e o leiaute de São Paulo; emitir: não previsto, o padrão nacional substitui |
| Baixar o DANFSe oficial | não | sim | não | não existe mais: a API do DANFSe foi desativada em 03/08/2026 (NT 008/2026, veja a etapa 3); o DANFSe vai para os PDFs, no leiaute da NT 008 |
| PDFs: DANFE, DANFCe, DACTE, DAMDFE, DANFSe, DACCe e etiqueta | não (usa o BrazilFiscalReport) | só o DANFSe não oficial | sim | prontos (05/11/2026): DANFE, DANFE Simplificado e Etiqueta, DANFE NFC-e, DACTE e DACTE OS, DAMDFE, DANFSe v2.0 e a carta de correção (NF-e e CT-e) |
| Calculadora da Reforma: conferir e simular | não | não | não | etapa 4: conferir (NF-e e NFC-e, como a SEFAZ conferia no dia da emissão) e calcular ou simular outro ano, prontos |
| Ler o SPED e pré-conferência | não | não | não | etapa 5, pronta: a EFD ICMS/IPI, o cruzamento com as NF-e e a pré-conferência da NF-e e da NFC-e |

## Tabelas que se atualizam sozinhas

O CRAN só recebe versão nova de tempos em tempos, então as tabelas vivem em três camadas: uma cópia dentro do
pacote (funciona sem internet), um repositório de dados no GitHub que um robô semanal atualiza a partir das
fontes oficiais, e o pacote buscando a mais nova de lá. Cada linha guarda "vale desde" e "vale até", para a
nota antiga ser lida com a tabela da época. As três existem desde 04/11/2026: o repositório é o próprio do RNFe
(o robô avisa, uma pessoa confere e junta ao `main`), e a busca é a `tabelas_atualizar()`.

| Tabela | Fonte oficial | Atualização automática |
|---|---|---|
| NCM | Siscomex | sim |
| Municípios | IBGE | não pelo robô: o IBGE não aceita conexão dos servidores do GitHub; roda-se `ferramentas/gerar_tabelas.R` numa máquina no Brasil |
| Reforma (classificação e CST da CBS e do IBS) | Portal da NF-e e Receita | quase: a planilha muda de formato |
| CFOP, CST do ICMS, CSOSN, CEST | Confaz e Sinief | em parte: o robô avisa e alguém confere |
| Meios de pagamento e bandeiras de cartão | Portal da NF-e | sim |
| Significado dos códigos de cada campo | documentação dos schemas | não: escrita à mão; o vigia dos schemas avisa quando o schema muda, e `ferramentas/conferir_codigos_dos_campos.R` confere |

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
  conferida; outro modelo é desmontado igual, com `documento` vazio. A forma de emissão sai como número e,
  desde 30/10/2026, com `forma_emissao_descricao`: o significado muda de documento para documento (a 2 é
  "Contingência FS" na NF-e e "Contingência offline" no CT-e), então vem do leiaute de cada um em
  `codigos_dos_campos` (a NFC-e segue o da NF-e, e o CT-e OS o do CT-e).

## Etapa 1, leitura do XML: o que se decidiu

- `nfe_ler()` segue o schema oficial do pacote de liberação PL_010g v1.03 (Portal da NF-e, 26/10/2026, NT
  2026.006 e NT 2026.008), que já traz o IBS, a CBS e o Imposto Seletivo. Devolve `notas`, `itens`,
  `impostos`, `parcelas`, `pagamentos` e `arquivos`, ligadas pela chave. Cada coluna aponta para um caminho do
  leiaute (as tabelas `CAMPOS_*` em `R/nfe_ler.R`, que também geram a ajuda).
- Os impostos principais vão em colunas de `itens`; `impostos` traz todos os campos de imposto de cada item,
  um por linha, para nada se perder (monofásico, diferimento, crédito presumido...).
- Arquivo que não dá para ler não para os outros: vai para `arquivos` com o motivo (não encontrado, XML
  quebrado, não é NF-e). Nunca vira nota vazia.
- **O resumo da NF-e (`resNFe`)**, desde 03/11/2026, vai para a tabela `resumos` do `nfe_ler()` (antes era
  recusado como "só o resumo"). É o que a Distribuição de DF-e entrega ao destinatário enquanto ele não se
  manifestou (NT 2014.002): emitente, IE, emissão, tipo, valor, `digVal`, autorização, protocolo e
  `cSitNFe`. Segue o `resNFe_v1.01.xsd` do pacote da Distribuição v1.04. O schema lista o `cSitNFe` (1, 2 e
  3) sem dizer o que cada um é; o significado (uso autorizado, uso denegado, NF-e cancelada) é o da NT
  2014.002 v1.02d, baixada do Portal da NF-e. `arquivos` ganhou a coluna `resumos`, ao lado de `notas`.
  - Conferido em 03/11/2026 com os 2.000 resumos do acervo do Fiscal (fora do repositório): todos lidos, sem
    nenhum campo vazio, 1.917 na versão 1.01 e 83 na 1.00 (os mesmos campos); todo campo dos arquivos tem
    coluna; 920 autorizadas, 8 denegadas e 1.072 canceladas. Em 251 a nota completa da mesma chave estava no
    acervo: documento e IE do emitente, data, tipo, valor, protocolo, autorização e `digVal` (contra o do
    protocolo da nota) bateram em todos. As três diferenças são dos próprios documentos: dois nomes do
    emitente que só mudam maiúscula e minúscula, e uma emissão com o mesmo horário local, mas `-02:00` na nota
    e `-03:00` no resumo.
- Só o `infNFe` de dentro do `NFe` é nota: o CT-e e o MDF-e também têm `infNFe`, com a chave das notas que
  citam. Até 29/10/2026 um CT-e passado ao `nfe_ler()` virava duas notas vazias; achado ao escrever o
  `cte_ler()`, corrigido e conferido de novo com 10 mil NF-e reais (uma nota por arquivo, a chave certa).
- As notas de exemplo (`inst/exemplos`) foram escritas à mão e passam no schema oficial
  (`ferramentas/validar_exemplos.R`). Para ter certeza de que o validador confere de verdade, ele
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

## Etapa 1, a NFC-e: o que se decidiu (30/10/2026)

- **Lacuna achada na revisão das etapas:** o `nfe_ler()` dizia ler a NFC-e, mas nenhuma NFC-e tinha sido
  lida. Os exemplos eram os dois de modelo 55, e as 120.522 NF-e reais do app Fiscal também (nenhuma de
  modelo 65). O grupo do QR-Code (`infNFeSupl`) fica fora do `infNFe`, então não entrava nem na tabela
  `campos`.
- `notas` ganhou `qrcode` e `url_consulta` (do `infNFeSupl`), `formato_danfe` (`tpImp`: 4 é o DANFE NFC-e) e,
  para a emissão em contingência, `contingencia_entrada` (`dhCont`) e `contingencia_justificativa` (`xJust`).
  O texto do QR-Code fica como está, sem desmontar.
- **Exemplo:** uma NFC-e em contingência offline (forma de emissão 9) autorizada depois, com consumidor não
  identificado, troco e o QR-Code da versão 3 offline. Passa no schema PL_010g. O validador reprovou o QR-Code
  com dia 32, sem o `?p=` e a URL de consulta curta. Ele **não** reprova forma de emissão 1 com um QR-Code de
  contingência: o schema não cruza o `tpEmis` com a chave dentro do QR-Code. Essa conferência entre campos é
  da SEFAZ e fica para a pré-conferência (etapa 5).
- Os endereços do exemplo usam o domínio reservado `.invalid`, para não parecer endereço de SEFAZ.
- **Sem NFC-e reais para conferir:** a conferência é pelo schema e pelo exemplo.

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
  - O Portal publicou a tabela de novo em 30/10/2026: as classificações 410003 e 410026 passaram a citar as
    amostras grátis junto das doações (nome e descrição). O resto ficou igual.
- **Municípios (30/10/2026):** a API de localidades do IBGE, na visão nivelada
  (`localidades/municipios?view=nivelado`): 5.571 municípios, com o código de 7 dígitos, o nome, a UF e o
  código da UF. A visão completa traz a UF dentro da microrregião, e um município vinha sem microrregião (ficaria
  sem UF). O IBGE só publica a lista de hoje: a tabela vai sem datas, como o CSOSN. O código 9999999, que a NF-e
  usa para o exterior (está no schema), não é do IBGE e não entra.
  - **O IBGE não aceita conexão dos servidores do GitHub:** na primeira rodada do robô com os municípios
    (30/10/2026), a conexão esgotou o tempo (120 s) e o `gerar_tabelas.R` parou, sem atualizar nenhuma
    tabela. Agora, quando o IBGE não responde, fica a cópia de municípios que está no pacote, com a data dela
    em `fontes.csv`, as outras tabelas seguem e a rodada do robô mostra um aviso. Testado aqui com o endereço
    trocado por um que não existe: o arquivo dos municípios ficou igual e a data antiga ficou. A lista se
    atualiza rodando `ferramentas/gerar_tabelas.R` numa máquina no Brasil.

## Etapa 2, leitura do CT-e: o que se decidiu

- `cte_ler()` lê o CT-e (modelo 57) e o CT-e OS (modelo 67), leiautes 3.00 e 4.00, pelo schema oficial do
  pacote PL_CTe_400 NT 2026.004 RTC 1.00 (Portal do CT-e, republicado em 16/10/2026), que já traz o IBS e a
  CBS. **Desde 05/11/2026, o pacote PL_CTe_400 NT 2026.005 RTC SN 1.00** (publicado em 04/11/2026; o vigia avisou na
  revisão da etapa 4): ele traz tudo o da NT 2026.004 v1.01, publicada no mesmo dia (o grupo `gMultaJuros`, com o
  CT-e de que se cobra multa e juros, no CT-e, no CT-e OS e no simplificado), e mais o `gTribSN`, o IBS e a CBS do
  Simples Nacional (no `imp/IBSCBS` do CT-e e do CT-e OS, e no item e no total do simplificado), e dois eventos: a
  tributação do Simples Nacional (412140) e o cancelamento dela (412141). A GTV-e não mudou. O `chCTeRef` foi para
  `documentos`, como os outros documentos da Reforma; o `gTribSN`, para colunas `*_simples_nacional`; os eventos o
  `eventos_ler()` já lia (o detalhe de cada item vai para `campos`). Os 19 exemplos passam no schema novo. As duas
  publicações do BP-e, no mesmo dia, não mudam nada no RNFe. Devolve `ctes`, `componentes`, `documentos`, `cargas`, `impostos`, `parcelas`, `observacoes` e
  `arquivos`, ligadas pela chave, no mesmo molde do `nfe_ler()`. O que as duas leituras fazem igual está em
  `R/ler_xml.R`.
- **O CT-e OS entrou junto** porque usa o mesmo `infCte` e quase os mesmos grupos; muda o tomador (grupo
  `toma`), o serviço (`infServico`) e os tributos federais (`infTribFed`). A GTV-e e o CT-e simplificado
  também usam `infCte`, com outro conteúdo, e ficam de fora: têm leitor próprio, a GTV-e desde 03/11/2026 e o
  simplificado desde 04/11/2026 (veja as seções deles).
- **O tomador sai pronto.** No `toma3` o XML só diz o papel (0 remetente, 1 expedidor, 2 recebedor,
  3 destinatário, como está no schema) e o pacote copia os dados dessa pessoa; no `toma4` e no CT-e OS os
  dados vêm do próprio grupo.
- **`documentos` junta tudo o que o CT-e cita**, com o grupo de origem em `tipo`: os transportados (NF-e,
  nota em papel, outros, DC-e), os de transporte anterior (com o emitente), o CT-e complementado, o
  substituído, o multimodal e, no CT-e OS, os referenciados e as GTV-e.
- O `ICMSOutraUF` vai nas mesmas colunas de base, alíquota e valor do ICMS, e `grupo_icms` diz de qual grupo
  veio. O CST do ICMS ganhou o significado em 30/10/2026, pelo leiaute do CT-e e com o grupo como contexto
  (veja "O significado de cada código"). Antes, o motivo escrito aqui para deixá-lo sem nome ("a tabela da NF-e
  não tem o CST 45 do CT-e") estava errado: não existe CST 45; `ICMS45` é o nome do grupo, que leva o 40, o 41
  e o 51.
- **Exemplos:** três CT-e escritos à mão (com protocolo e IBS/CBS; subcontratação do Simples Nacional com
  tomador no `toma4` e documentos de transporte anterior; CT-e OS de fretamento) passam no schema oficial.
  `ferramentas/validar_exemplos.R` agora confere NF-e e CT-e. O `infModal` do CT-e aceita qualquer conteúdo
  sem conferir, então o modal (`rodo`, `rodoOS`) é validado à parte: um RNTRC de 4 dígitos passava no schema
  principal e foi reprovado no do modal. O validador também reprovou um CT-e sem `vRec` e um com `toma` 5.
- **Conferido em 29/10/2026 com os 14.370 CT-e reais** do app Fiscal (5.569 na versão 3.00, 8.801 na 4.00,
  29 deles CT-e OS), que não entram no repositório. Todos foram lidos, por dois lados:
  - contra o que o app Fiscal tirou dos mesmos XMLs: número, série, protocolo, situação, natureza, emitente,
    remetente, destinatário, tomador, valor da prestação e da carga, início, fim e as 16.877 ligações
    CT-e → NF-e bateram. As diferenças foram todas do lado do Fiscal, que só lê CNPJ: 1 emitente, 23
    remetentes, 429 destinatários e 8 tomadores com CPF, e os 29 tomadores do CT-e OS, que ele não lê;
  - contra um segundo leitor do XML (ElementTree, em Python, sem XPath): modelo, CFOP, papel e documento do
    tomador, emissão e autorização (o instante), valor a receber, grupo e valor do ICMS, CST e valor da CBS,
    e as contagens e somas de campos de imposto, componentes, cargas, documentos (por tipo), parcelas e
    observações bateram em todos.
  - CFOP e CST do IBS/CBS acharam o nome em todos. 72 CT-e de outubro a dezembro de 2025 com o grupo IBSCBS
    ficam sem o nome da classificação, que vale desde 01/01/2026; o CST do IBS/CBS tem nome porque a aba de
    CST da tabela oficial não tem datas de vigência.
- Velocidade: 6,9 ms por CT-e (99 s para os 14.370).

## Etapa 2, verificação de 03/11/2026: o que o acervo tinha e não era lido

- **Pedido do usuário:** "verifique se a fase 2 terminou de fato, antes" de seguir na etapa 3. Pelo elemento raiz
  de cada XML do acervo do Fiscal, tudo o que os leitores cobrem era lido. Ficavam de fora o resumo da NF-e
  (`resNFe`, 2.000 arquivos), a GTV-e (285) e as NFS-e de prefeitura (Ginfes e formatos sem namespace, com raiz
  `NFe`, `nfe`, `CompNfse` ou `CompNfe`).
- **Decisão do usuário:** o resumo e a GTV-e agora (seções abaixo e "Etapa 1, leitura do XML"); a NFS-e de
  prefeitura depois, começando pelos formatos que mais aparecem no acervo.

## Etapa 2, leitura da GTV-e: o que se decidiu (03/11/2026)

- `gtve_ler()` lê a GTV-e (Guia de Transporte de Valores Eletrônica, modelo 64), leiaute 4.00, pelo tipo `TGTVe`
  do mesmo pacote do CT-e (`GTVe_v4.00.xsd` e `procGTVe_v4.00.xsd`). Devolve `gtves`, `especies`, `veiculos`,
  `observacoes`, `campos` e `arquivos`.
- **Leitor próprio, não o `cte_ler()`:** a GTV-e é um CT-e do tipo 4 (o schema a chama de "CT-e do tipo GTV-e"),
  com a chave e o protocolo do CT-e, mas não tem valor da prestação nem impostos. No lugar deles traz os valores
  levados por espécie (cédula, cheque, moeda, outros; nacional ou estrangeiro), a quantidade de malotes, os
  veículos e os horários de saída e de chegada. No `ctes`, metade das colunas viria vazia.
- **O tomador sai pronto, com outra lista de papéis:** no grupo `toma` da GTV-e, o 0 é o remetente e o 1 o
  destinatário (no CT-e o 1 é o expedidor); no `tomaTerceiro` (papel 4) os dados vêm do grupo. O
  `preencher_tomador()` do CT-e passou a receber a pessoa de cada papel, e serve aos dois.
- **Significados:** todos da documentação do `TGTVe` (o significado fica na segunda `documentation` de cada
  campo), num documento próprio, `GTV-e`, em `codigos_dos_campos`: 23 linhas. A ferramenta de conferência
  passou a olhar, para a GTV-e, só as declarações de dentro do `TGTVe`: o pacote do CT-e tem outros `toma`.
- **A chave:** o modelo 64 virou "GTV-e" em `chave_decompor()` e nos eventos. A fonte é o MOC do CT-e 4.00
  (fevereiro/2023, baixado do Portal do CT-e): o item 2.1.2 põe a GTV-e no projeto do CT-e, o 2.1.4 dá a
  composição da chave, e as regras da consulta separam CT-e, CT-e OS e GTV-e pelo "modelo do documento indicado
  na chave de acesso". A forma de emissão segue a lista da GTV-e (só 1 e 2).
- **Eventos:** o serviço de eventos do CT-e recebe os de "CTe de Carga (57), Outros Serviços (67) ou GTVe (64)"
  (MOC, item 5), e o cancelamento (110111) vale para a GTV-e. O evento dela é lido pelo `eventos_ler()` com o
  documento "GTV-e", e o órgão 90 em diante tem o significado do CT-e (5 linhas). O acervo não tem nenhum evento
  de GTV-e; o teste usa o cancelamento do CT-e de exemplo com a chave da GTV-e.
- **Exemplo:** uma GTV-e escrita à mão (três espécies, uma em moeda estrangeira, observação, origem e destino,
  destinatário com CNPJ alfanumérico) passa no schema oficial. O validador pegou o `versao` que faltava no
  `GTVe`.
- **Conferido em 03/11/2026 com as 285 GTV-e reais** do acervo do Fiscal (todas `GTVeProc` 4.00, de produção),
  que não entram no repositório: todas lidas; as 285 chaves válidas e iguais, parte a parte (UF, mês, CNPJ,
  modelo, série, número, forma de emissão, código e dígito), aos campos do XML e à chave do protocolo; nenhuma
  coluna que todo arquivo tem ficou vazia; o tomador do papel 0 é o remetente nas 197 que o usam, e as 88 do
  `tomaTerceiro` trazem os dados do grupo. Contra uma leitura direta de cada arquivo, as 632 espécies (valor e
  ordem), a quantidade, a emissão, o protocolo e o número de campos bateram em todas. 25 GTV-e aparecem em dois
  arquivos cada (260 chaves distintas). Velocidade: 1,8 s para as 285, com a tabela `campos`.

## Etapa 2, leitura do CT-e simplificado: o que se decidiu (04/11/2026)

- **Pedido do usuário** ("faça todos", sobre as brechas da revisão de 04/11/2026). `cte_simplificado_ler()` lê o
  CT-e simplificado (modelo 57, `tpCTe` 5, e o de substituição, 6), leiaute 4.00, pelo tipo `TCTeSimp` do mesmo
  pacote do CT-e (`cteSimp_v4.00.xsd` e `procCTeSimp_v4.00.xsd`). Devolve `ctes`, `entregas`, `componentes`,
  `documentos`, `cargas`, `impostos`, `parcelas`, `pagamentos_vinculados`, `observacoes`, `campos` e `arquivos`.
- **Leitor próprio, não o `cte_ler()`:** tem a chave, o protocolo e os eventos do CT-e, mas não tem o remetente, o
  expedidor, o recebedor nem o destinatário. Traz o tomador, com os dados no próprio grupo `toma` (o papel só diz
  quem ele é), e um grupo `det` por entrega (até 990; o schema aceita o `nItem` de 1 a 990), cada um com os municípios de início e de fim, o valor, os
  componentes, o IBS e a CBS e os documentos. O valor e o IBS e a CBS do CT-e inteiro vêm do grupo `total`; o ICMS
  é um só, como no CT-e. No `ctes` do `cte_ler()`, as entregas não caberiam.
- **A entrega liga as tabelas:** `entregas` tem o número dela (`nItem`), e `componentes`, `documentos` e `impostos`
  trazem a coluna `entrega`. Em `documentos`, a NF-e da entrega (`infNFe`, com a previsão de entrega), o CT-e
  anterior (`infDocAnt`, com a prestação total ou parcial) e as NF-e dentro dele (`infNFeTranspParcial`, com a chave
  do CT-e anterior ao lado), e o CT-e substituído (`infCteSub`, sem entrega). Em `impostos`, o `tributo` é
  `IBSCBS` no de cada entrega e `IBSCBSTot` nos totais (o diferimento e a devolução de tributos ficam lá).
- **Significados no documento `CT-e`** de `codigos_dos_campos`, porque os códigos são os do CT-e: o `tpCTe` 5 e 6
  saíram da lista "fora de propósito"; o `tpMed`, que aqui é código (17 valores, de "Cubagem da NF-e" a "Outros"),
  e o `tpPrest` (total ou parcial). O `toma` 4 é "Terceiro" no simplificado e "Outros" no CT-e: entrou com o tipo do
  CT-e (5 e 6) como contexto, e o `cte_ler()` continua com "Outros". 23 linhas, todas da documentação do
  `TCTeSimp`; a ferramenta de conferência aprovou.
- **As outras mensagens:** o `cte_ler()`, o `nfe_ler()` e os outros leitores dizem "é um CT-e simplificado, lido por
  cte_simplificado_ler()"; a distribuição do CT-e manda lê-lo por ele. Junto, um defeito pequeno: o próprio leitor
  da GTV-e (e agora o do simplificado), com a raiz certa e sem o `infCte`, dizia que o arquivo era lido por ele
  mesmo; agora diz que falta o `infCte`.
- **Exemplo:** um CT-e simplificado escrito à mão (duas entregas, uma com NF-e e outra com o CT-e anterior parcial,
  tomador terceiro, carga com o tipo da medida em código, fatura com desconto, pagamento vinculado, IBS e CBS por
  entrega e nos totais) passa no schema oficial. O validador pegou o desconto 0.00 da fatura, que o schema não
  aceita.
- **Sem documento real:** o acervo do Fiscal não tem nenhum CT-e simplificado (a revisão de 04/11/2026 contou os
  tipos pela raiz), como no MDF-e. O MOC do CT-e 4.00 (fevereiro/2023) não fala dele; o que a ajuda diz vem do
  schema.

## Etapa 2, leitura do MDF-e: o que se decidiu

- `mdfe_ler()` lê o MDF-e (modelo 58, leiaute 3.00) pelo schema oficial do Portal do MDF-e: o pacote
  `PL_MDFe_300b_NT012025_1.04.zip`, da NT 2025.001 v1.04, de 25/04/2026, o mais recente da lista de schemas
  em 30/10/2026 (o zip se chama 1.04 e a pasta de dentro, 1.05). A NT 2026.001 (maio de 2026) só torna o CIOT
  obrigatório em alguns casos, sem mudar o leiaute.
- Devolve `mdfes`, `locais`, `documentos`, `veiculos`, `condutores`, `seguros`, `campos` e `arquivos`.
  - `locais` junta, na ordem do XML, os municípios de carregamento, as UFs do percurso e os municípios de
    descarregamento; `documentos` traz cada CT-e, NF-e ou MDF-e com o município onde é descarregado.
  - `seguros` tem uma linha por averbação, e uma para o seguro que não tem averbação.
  - **`campos` é nova:** todos os campos do MDF-e, um por linha, com o caminho a partir do `infMDFe` e a
    posição quando o grupo se repete (`condutor[2]`, `infPrazo[1]`). Assim nada se perde: o CIOT, o
    vale-pedágio, os contratantes, o pagamento do frete, os lacres e os modais aéreo, aquaviário e
    ferroviário ficam ali, sem tabela própria por enquanto.
- O NCM do produto predominante ganha a descrição da tabela NCM na data de emissão.
- **Achado no schema oficial:** no pacote de 25/04/2026, o `Id` do `infMDFe` ainda só aceita números
  (`MDFe[0-9]{44}`, em `mdfeTiposBasico_v3.00.xsd`), embora o CNPJ do emitente, a `chMDFe`, o QR-Code e os
  eventos já aceitem o CNPJ com letras. Um MDF-e de emitente com CNPJ alfanumérico não passa nesse schema. A
  leitura não depende disso, mas o exemplo de MDF-e usa um CNPJ só de números.
- A chave de MDF-e de emitente com CPF não foi usada nos exemplos: a composição dela não foi conferida no
  manual do MDF-e.
- **Exemplos:** dois MDF-e escritos à mão (transportadora com protocolo, levando o CT-e de exemplo; carga
  própria sem protocolo, com percurso, veículo de terceiro, reboque, dois condutores, pagamento a prazo e um
  seguro sem averbação) passam no schema oficial, e o modal rodoviário passa no schema dele.
  `ferramentas/validar_exemplos.R` agora recebe também a pasta do schema do MDF-e. Ele reprovou um modal 5,
  um MDF-e sem o peso da carga e um tipo de rodado 07; este último só na validação separada do modal.
- **Sem conferência com MDF-e reais:** o acervo do app Fiscal não tem nenhum MDF-e, e os exemplos públicos
  achados são poucos e soltos. Fica para quando houver MDF-e reais para comparar.
- Cada leitor recusa o documento dos outros: o MDF-e cita `infNFe` e `infCTe`, mas não vira nota nem CT-e.

## Etapa 2, leitura da NFS-e Nacional: o que se decidiu

- `nfse_ler()` lê a NFS-e do padrão nacional (raiz `NFSe`), leiautes 1.00 e 1.01, pelo pacote oficial
  `NFSe-ESQUEMAS_XSD-v1.01-20260209` (página de documentação atual do portal da NFS-e, gov.br/nfse), que traz
  um schema por versão, cada um na sua pasta. A NFS-e de prefeitura, no padrão próprio de cada município
  (Abrasf, Ginfes...), não é lida: avisa em `arquivos` com a raiz que o XML tem. Ler essas fica para depois
  (decisão do usuário, 03/11/2026), começando pelos formatos que mais aparecem no acervo do Fiscal.
- Devolve `nfses` (uma linha por NFS-e), `campos` e `arquivos`. A NFS-e não tem itens: é um serviço por
  documento. As colunas juntam as duas partes do XML: a DPS, que quem emitiu declarou (prestador, tomador,
  intermediário, serviço, valores, tributos e o IBS e a CBS informados), e o que o sistema nacional gerou
  (número, situação, base e valor do ISSQN, total retido, valor líquido e o IBS e a CBS calculados). Ao lado
  do CST e da classificação do IBS/CBS vem o nome na data de emissão.
- **Diferença entre as versões:** o `xOutInf` (informações do município) fica em `valores/xOutInf` na 1.00 e
  direto no `infNFSe` na 1.01; a coluna `outras_informacoes` lê os dois lugares.
- **A chave tem 50 posições:** "NFS" no `Id`, município (7), ambiente gerador (1), tipo de inscrição (1:
  CPF, 2: CNPJ), inscrição federal (14), número da NFS-e (13), ano e mês (4), código numérico (9) e dígito
  (1). A regra do dígito **não está escrita** em nenhuma fonte oficial lida (o schema, o Anexo I do leiaute e
  três manuais das APIs). As 11.207 chaves reais seguem o módulo 11 da NF-e, mas sem a regra escrita o pacote
  não confere o dígito da NFS-e, e as funções `chave_*` continuam só para a chave de 44 posições.
- **O schema oficial não bate com as NFS-e reais.** Validadas 300 NFS-e reais sorteadas: 198 passaram e 102
  não (100 da 1.00, 2 da 1.01). Os motivos são do schema e do próprio sistema nacional, não do RNFe:
  - a lista de situações (`cStat`) é {100, 101, 102, 103} na 1.00 e {100, 102, 103, 107} na 1.01, mas
    NFS-e 1.00 reais trazem 107 e uma 1.01 traz 101;
  - a assinatura real usa SHA-256 e a canonicalização exclusiva, e o schema da assinatura que vem no pacote
    fixa SHA-1;
  - NFS-e antigas, do leiaute anterior, trazem campos fora do lugar (`pAliq`, `cLocIncid` vazio).
  A leitura não depende do schema; o que importa é o caminho de cada campo.
- **Achado no schema:** a série da DPS tem o padrão `^0{0,4}\d{1,5}$`. Em XML Schema o `^` e o `$` são
  letras comuns, e o libxml2 recusaria até a série "1". O validador tira os dois na cópia que usa
  (`tirar_ancoras`), o que dá a regra que o portal quis escrever.
- **Exemplos:** duas NFS-e escritas à mão passam no schema oficial da sua versão: uma 1.01 com IBS e CBS,
  ISSQN, PIS e COFINS e o IRRF retido; uma 1.00 de MEI, com tomador pessoa física, desconto e o
  `xOutInf` no lugar antigo. `ferramentas/validar_exemplos.R` agora recebe também a pasta da NFS-e e valida cada uma pelo
  schema da versão que ela declara.
- **Conferido em 30/10/2026 com as 11.207 NFS-e nacionais reais** do app Fiscal (5.691 na 1.00, 5.516 na
  1.01), que não entram no repositório. Todas foram lidas, por dois lados:
  - contra o que o app Fiscal tirou dos mesmos XMLs: número, prestador, tomador, valor do serviço, valor
    líquido, município e data de emissão bateram em todas. O nome do emitente diferiu em 23, todas por
    espaços no começo ou no fim: o Fiscal tira os espaços e o RNFe deixa o nome como está no XML;
  - contra um segundo leitor do XML (ElementTree, em Python): chave, versão, situação, processamento,
    emissão, competência, prestador, tomador, intermediário, código e nome da tributação nacional, base,
    alíquota e valor do ISSQN, total retido, retenção do ISSQN, PIS, IRRF, CST e classificação do IBS/CBS,
    indicador da operação, IBS, CBS, total com IBS e CBS, outras informações e o número de campos de cada
    NFS-e bateram em todas.
  - CST e classificação do IBS/CBS acharam o nome em todas.
- Velocidade: 7 ms por NFS-e (78 s para as 11.207).

## Etapa 2, os eventos: o que se decidiu (30/10/2026)

- **Lacuna achada na revisão das etapas:** nenhum leitor lia eventos, e um documento cancelado saía do leitor
  como autorizado (a situação 100 do protocolo): o cancelamento é um evento à parte. O acervo do app Fiscal
  tem 181.621 eventos, entre eles 2.208 cancelamentos e 2.142 cartas de correção.
- `eventos_ler()` lê, numa tabela só: o evento com o retorno da SEFAZ (`procEventoNFe`, `procEventoCTe`,
  `procEventoMDFe`), o evento só assinado, o evento da NFS-e (raiz `evento`, com o `pedRegEvento` dentro) e o
  resumo de evento da Distribuição de DF-e (`resEvento`, 60% dos eventos do acervo). Devolve `eventos`,
  `campos` (ligada por padrão) e `arquivos`, e se junta aos documentos pela chave.
- O retorno é casado com o pedido pelo envelope em que os dois estão, não pela chave: num arquivo com vários
  envelopes, cada pedido fica com o seu (há teste). `documento` sai do modelo da chave (NF-e, NFC-e, CT-e,
  CT-e OS, MDF-e) e é "NFS-e" no evento da NFS-e.
- Na NF-e o detalhe fica direto no `detEvento`; no CT-e e no MDF-e, num grupo de cada evento (`evCancCTe`,
  `evEncMDFe`...). As colunas leem os dois lugares, e o que é próprio de cada tipo fica em `campos`, com o
  caminho a partir do evento, do retorno ou do resumo (os três aparecem no caminho, então o resumo e o completo
  do mesmo evento não se confundem).
- Textos em colunas: `justificativa` (`xJust`; na NFS-e, o `xMotivo` que o autor escreveu), `correcao`
  (`xCorrecao`, da carta de correção da NF-e) e `observacao` (`xObs`, como o motivo do desacordo do CT-e). A
  `observacao` entrou depois da conferência: o Fiscal mostrava o `xObs` de 4 eventos de desacordo que o RNFe só
  tinha em `campos`.
- **NFS-e:** o tipo é o nome do grupo do evento sem o `e` (`e101101` dá `101101`). **Achado nos eventos
  reais:** a NFS-e 1.00 de substituição traz o `nPedRegEvento` entre a chave e o grupo (e `nDFe` no lugar de
  `nDFSe`), o que não está no schema 1.00. Por isso o tipo sai do grupo que tem a descrição (`xDesc`), não da
  posição.
- **Schemas:** os eventos do CT-e, do MDF-e e da NFS-e vêm nos pacotes que os leitores já seguem. Os da NF-e
  têm pacotes à parte: o leiaute genérico de 2026 (PL_Evento do pacote 010d, que já aceita o CNPJ com letras),
  o do cancelamento (2018), o da carta de correção (2014) e o da Distribuição de DF-e v1.04 (o `resEvento`).
  O validador confere o envelope do evento da NF-e pelo genérico e o `detEvento` pelo schema do tipo dele
  (`e110111`, `e110110`); no CT-e e no MDF-e, o `procEvento*` pelo schema próprio e o grupo do evento pelo
  arquivo que tem o nome dele. Juntar o evento do CT-e ao schema do CT-e dá conflito (os dois definem o tipo
  `TModTransp`), e juntar todos os grupos também. O `resEvento` importa o schema da assinatura, que o pacote
  da Distribuição não traz: vai a cópia do pacote dos eventos.
- **Exemplos:** seis eventos escritos à mão passam no schema oficial: cancelamento da NF-e, carta de correção
  da NF-e de emitente com CNPJ alfanumérico, resumo da ciência da operação, cancelamento do CT-e,
  encerramento do MDF-e e cancelamento da NFS-e, todos citando os documentos de exemplo. Os textos (descrição,
  motivo do retorno) são os que a SEFAZ usa, conferidos no acervo. O validador reprovou oito versões
  estragadas de propósito: justificativa curta, descrição fora da lista, sequência 0, condição de uso da carta
  alterada, protocolo do resumo com 14 dígitos, cancelamento do CT-e sem protocolo, município do encerramento
  com 5 dígitos e código de motivo 3 na NFS-e.
- **Conferido em 30/10/2026 com os 181.621 eventos reais** do app Fiscal (180.417 de NF-e, 884 de CT-e e 320
  de NFS-e; 108.418 resumos), que não entram no repositório. Todos foram lidos, um evento por arquivo:
  - contra um segundo leitor do XML (ElementTree, em Python): chave, tipo, sequência, data do evento, autor,
    descrição, protocolo, data do registro, situação, justificativa, correção, protocolo do documento,
    versão, resumo e o número de campos de cada evento (2.530.117 no total) bateram em todos;
  - contra o que o app Fiscal tirou dos mesmos XMLs: documento, chave, tipo, sequência, autor, situação,
    protocolo e resumo bateram em todos; o texto (correção, justificativa ou observação), em todos menos um,
    em que o Fiscal tira os espaços das pontas.
  - A data difere na forma: o Fiscal guarda o relógio escrito no XML sem o fuso, e o RNFe guarda o instante.
    Em 148 eventos o fuso escrito não era o de Brasília (+00:00, -04:00, -02:00, -07:00, -00:00 e -08:00); em
    2, o Fiscal ficou sem a data.
  - 393 eventos aparecem em dois arquivos (o mesmo evento guardado duas vezes); o leitor devolve uma linha por
    arquivo lido.
- Sem eventos de MDF-e reais (o acervo não tem MDF-e): a conferência deles é pelo schema e pelo exemplo.
- Velocidade: uns 4 ms por evento (de 700 a 840 s para os 181 mil, com a tabela `campos`).

## Etapa 2, a tabela `campos` nos quatro leitores

- Cada leitor tem colunas para os campos mais usados, e o resto do documento vai para `campos`: um campo por
  linha, com o caminho a partir do grupo principal (`infNFe`, `infCte`, `infMDFe`, `infNFSe`) e a posição
  quando o grupo se repete (`det[2]/prod/cProd`). A assinatura digital fica de fora. Assim nada se perde:
  notas referenciadas, volumes, rastreabilidade, modais do CT-e, obra e dedução da NFS-e...
- **O argumento `todos_os_campos` decide se ela vem.** Na NF-e e no CT-e começa desligado; no MDF-e e na
  NFS-e, ligado. O motivo é o custo, medido nas 10 mil notas reais: uma NF-e tem em média 223 campos, e com a
  tabela a leitura passa de 13 a 14 ms para 19 a 21 ms por nota; a tabela das 10 mil ocupa uns 100 MB. O CT-e fica
  como a NF-e: já tem tabelas para quase tudo (componentes, documentos, cargas, impostos, observações). No
  MDF-e e na NFS-e boa parte do documento não tem coluna própria, e o documento tem poucos campos.
- Com o argumento desligado, as outras tabelas saem idênticas às de antes (conferido nas 10 mil NF-e reais
  e em 3 mil CT-e de exemplo, contra a versão do commit anterior), e a velocidade é a mesma: três rodadas de
  cada versão ficaram na mesma faixa (141 a 155 s antes, 146 a 152 s depois, nas 10 mil notas). Ligado, as
  outras tabelas também saem iguais.

## O significado de cada código: o que se decidiu (30/10/2026)

- **Pedido do usuário**, depois de ver a ajuda no RStudio ("mas o que eu posso escolher entre as opções?"):
  ao lado de cada coluna de código, uma coluna com o significado, como já acontecia com o CFOP e os CSTs.
  `forma_emissao` 1 vem com `forma_emissao_descricao` "Normal". Vale para os cinco leitores e para o
  `chave_decompor()`.
- **Meios de pagamento e bandeiras** vêm das planilhas do Portal da NF-e, baixadas por
  `ferramentas/gerar_tabelas.R` (o IT 2026.001 manda usar a tabela nacional de meios de pagamento). Servem ao
  `tPag` e ao `tBand` da NF-e e ao meio do pagamento vinculado da Reforma (NF-e e CT-e). A planilha guarda a
  data de vigência como número do Excel (dias desde 30/12/1899), e o significado sai pela data do documento:
  o PIX dinâmico (17) só existe desde 01/07/2024.
- **Os outros códigos** (`codigos_dos_campos.csv`, 271 linhas na primeira rodada e 332 com a segunda) foram escritos à mão a partir da
  documentação dos schemas, porque o schema traz o texto, não uma tabela. A escrita foi acertada sem mudar o
  sentido (maiúsculas, "à Prazo" virou "a prazo"). Onde a documentação do schema tinha erro, vale a fonte
  que corrige:
  - NF-e `indIEDest` 1: o schema diz "Contribuinte ICMSpagamento à vista"; ficou "Contribuinte ICMS".
  - MDF-e `respSeg`: a documentação diz "22"; o schema aceita 1 e 2.
  - NFS-e `tribISSQN`: o schema 1.00 documenta 2 exportação, 3 não incidência e 4 imunidade; o 1.01 e o
    Anexo I do leiaute trazem 2 imunidade, 3 exportação e 4 não incidência. Vale a segunda para as duas
    versões: as regras de recepção do Anexo I valem para toda DPS (a E0854 cita a 1.00 de propósito) e
    amarram o 2 à imunidade (E0592: o tipo de imunidade só com `tribISSQN` 2) e o 4 à não incidência
    (E0532). Em 2023 isso já tinha dado nota rejeitada e exportação no lugar de não incidência para quem
    seguia o schema 1.00; a Receita confirmou ao ACBr que vale o manual (fórum do ACBr, tópico 73979,
    set/2023 a fev/2024).
  - NFS-e CST 07 do PIS/COFINS: o schema 1.00 diz "Operação tributável da contribuição"; o 1.01 e a tabela
    oficial do CST dizem "Operação isenta da contribuição".
  - MDF-e `tpTransp`: o schema só traz a sigla (ETC, TAC, CTC); o nome vem da Lei 11.442/2007, art. 2º.
- **Contexto:** alguns códigos mudam de sentido dentro do mesmo documento. No CT-e, o `procEmi` 3 é o
  aplicativo do SEBRAE no modelo 57 e o do Fisco no CT-e OS (67); o `tpDoc` tem uma lista para outros
  documentos (`infOutros`) e outra para os de transporte anterior em papel (`idDocAntPap`). A tabela tem a
  coluna `contexto`, e o leitor procura primeiro o significado do contexto da linha. O `toma` 4 é "Outros" no CT-e
  e "Terceiro" no CT-e simplificado (contexto: o tipo do CT-e, 5 ou 6).
- **Fora de propósito:** no documento CT-e, o `tpCTe` 4 e o `tpServ` 9, que são da GTV-e: desde 03/11/2026 ela
  tem os códigos dela no documento `GTV-e`. O `tpCTe` 5 e 6 (CT-e simplificado) ficaram aqui até 04/11/2026, quando
  ganharam leitor e significado. O `tpCTe` 2 (anulação, do leiaute 3.00) fica, porque o leitor lê o 3.00. Os
  modelos das notas referenciadas da NF-e (`refNF`, `refNFP`, `refECF`: 01, 02, 04, 2B, 2C, 2D) também ficam
  sem significado: só vão para a tabela `campos`, e o 01 muda de sentido entre os grupos.
- **Segunda rodada (30/10/2026), achada cruzando cada coluna dos leitores com os valores que o schema aceita:**
  - **CST do ICMS no CT-e**, com o grupo como contexto: o 90 é "ICMS outros" no `ICMS90`, o ICMS devido a
    outra UF no `ICMSOutraUF` e o do Simples Nacional no `ICMSSN`. Os textos são os da documentação do schema
    do CT-e, iguais no CT-e e no CT-e OS.
  - **Modelo** do documento na NF-e (55, 65), no CT-e (57, 67, e o 01 e o 04 das notas em papel citadas), no
    MDF-e (58).
  - **Órgão dos eventos** (`cOrgao`): a UF pelo código do IBGE (as 27 linhas conferidas contra a tabela de
    municípios), e os órgãos especiais pelo documento do evento, como cada leiaute os lista: no CT-e, 90
    SUFRAMA, 91 RFB, 94 SVC-RS, 95 SVC-SP e 96 a sincronização das chaves do RS para a SVSP; no MDF-e, 90
    SUFRAMA, 91 RFB, 92 BackOffice BRId, 93 ONE e 94 SVBA; na NF-e, 91 Ambiente Nacional. **Na NF-e os
    schemas se contradizem:** o de eventos genérico diz "90 para identificar o Ambiente Nacional", o do
    cancelamento e o da Distribuição dizem 91, e o tipo diz "90 RFB". Ficou o 91, que é o que a SEFAZ devolve:
    numa amostra de 823 eventos reais do Fiscal (até 30 por tipo), todos os registrados no Ambiente Nacional
    (manifestação, EPEC e outros) vêm com 91. O 90 e o 92 da NF-e (o 92 aparece no evento 510630) e o 93 do
    CT-e ficam sem significado: nenhum documento diz o que são.
  - O que mais o cruzamento apontou não é código: siglas de UF, textos, versões, o `tpMed` (lista fechada só
    no CT-e simplificado, com significado desde 04/11/2026; no CT-e é texto livre) e a situação do retorno do
    evento, que vem com o `motivo` escrito pela SEFAZ.
- **Conferência:** `ferramentas/conferir_codigos_dos_campos.R` compara a tabela com os valores que o schema
  aceita, campo por campo (cada versão da NFS-e lida à parte). Reprovou uma tabela estragada de propósito
  (um código que o schema não aceita, outro que faltava). Em 30/10/2026, com os pacotes oficiais baixados na
  hora, os 63 campos conferem (66 depois da segunda rodada). Nos 16 exemplos, todo código preenchido achou o
  significado. Em 03/11/2026, com o `cSitNFe` do resumo e os 11 campos da GTV-e, a ferramenta aprova 79 campos.
- **Comparação da documentação da NFS-e 1.00 com a 1.01**, campo por campo: além do `tribISSQN` e do CST 07,
  só a lista de códigos mudou: no `cStat` o 101 (só na 1.00) e o 107 (só na 1.01), o regime especial 9 e os
  campos da Reforma, na 1.01. Como o código de uma versão não aparece na outra, uma lista só serve às duas.

## Etapa 3, primeiro passo: o certificado e o status do serviço (30/10/2026)

- **Pedido do usuário:** "a fase três vá com calma, primeiramente indo com as partes fáceis como consulta status".
  Só homologação (autorização de 29/10/2026): `AMBIENTES_LIBERADOS` só tem a homologação, a produção é
  recusada antes de qualquer conexão, e a resposta que vier de outro ambiente (`tpAmb`) fica marcada em
  `problema`.
- **`certificado_ler()`**, pelo DOC-ICP-04 v8.3 (ITI): o CNPJ vem do otherName 2.16.76.1.3.3 da extensão Subject
  Alternative Name; o CPF, do 2.16.76.1.3.1 (depois da data de nascimento). Sem eles, o número depois de ":" no
  fim do nome (o CN). Os perfis novos do DOC-ICP-04 tiram o número do CN (vai para o serialNumber), por isso o
  campo próprio vem primeiro. Nos 58 certificados reais do Fiscal (só contagens): o campo traz o CNPJ em todos,
  igual ao do fim do nome, com os dígitos certos; vem como PrintableString, e o certificado falso dos testes
  também. A validade vem com o mês em inglês ("Oct"): lida pelo `month.abb`, que não depende do idioma do R. O
  primeiro script de busca, com `%b`, contou 19 certificados válidos em vez de 23, porque no R em português "Oct"
  não é mês.
- **Endereços:** a Relação de Serviços Web de homologação do Portal da NF-e, baixada por `gerar_tabelas.R` (e
  conferida pelo robô toda semana): `servicos_sefaz` (96 serviços de 14 autorizadores) e `autorizadores_sefaz`
  (a UF com SEFAZ própria usa a dela; as outras, a SVRS ou a SVAN; a consulta de cadastro da SVRS tem lista
  própria, menor). Ficam fora de `tabela_fiscal()`. O resumo do robô compara pela linha inteira a tabela que
  não tem `codigo`.
- **A mensagem:** o pedido segue o `leiauteConsStatServ_v4.00.xsd`, que está no pacote completo 9q (os parciais
  010d e 010g, que o RNFe segue, não trazem os schemas dos serviços); o pedido montado passa nele, e um estragado
  é reprovado. O envelope é o do WSDL do serviço (SOAP 1.2, `nfeDadosMsg` no namespace do serviço e a action
  `.../NFeStatusServico4/nfeStatusServicoNF`); a SVRS só mostra o WSDL com certificado de cliente. As respostas
  são lidas pelo nome local de cada elemento, porque cada SEFAZ põe o prefixo de namespace que quer.
- **Teste real (30/10/2026), as 27 UFs em homologação, com um e-CNPJ da empresa:** 22 responderam 107 em 8 s
  (as 16 da SVRS e AM, GO, MS, PE, PR e RS). As 5 que falham são de TLS:
  - com o Schannel (o motor padrão do curl no Windows), MG e MT não têm algoritmo em comum com o servidor, e BA,
    SP e a SVAN (MA) fecham a conexão sem resposta. A primeira suspeita (o Schannel não mandar a cadeia do
    certificado de cliente) estava errada: pelo OpenSSL, os três respondem mesmo com só o certificado da empresa,
    sem a cadeia (testado em 30/10/2026). A causa no Schannel não foi provada;
  - com o OpenSSL (`CURL_SSL_BACKEND=openssl`), o `.pfx` não abre no curl (cifra antiga, que o OpenSSL 3 não lê);
    em PEM, extraído pelo pacote `openssl` com a cadeia, MG e a SVAN respondem, mas a SVRS, BA, SP e MT falham
    porque o OpenSSL não acha a raiz da ICP-Brasil (o Schannel busca a raiz no Windows Update; o OpenSSL, mesmo
    com o repositório do Windows, não);
  - os servidores usam a Raiz Brasileira v10 da ICP-Brasil (BA, MS, MT, PE, RS, SP, SVRS), a GlobalSign Root R46
    (Ambiente Nacional e SVAN) e a ISRG Root X1 (GO).
  - **Resolvido no mesmo dia (pedido: "siga com as UF que não respondem"):** com o motor OpenSSL, o certificado
    em PEM (com a cadeia que vem no .pfx; a chave cifrada com a senha, num arquivo temporário apagado no fim) e o
    `cainfo` com a lista padrão de raízes mais a raiz v10 da ICP-Brasil, as 27 UFs respondem 107 (6 s). A lista
    padrão é a do R no Windows (`CURL_CA_BUNDLE`, `R/etc/curl-ca-bundle.crt`) ou a do sistema; precisa ir junto,
    porque o `cainfo` troca a lista inteira (só com a v10, GO, a SVAN e MG falharam), e o `ssl_options` das raízes
    do Windows não soma com o `cainfo` neste curl (8.14).
  - **A raiz v10** (`inst/certificados/icp_brasil_raiz_v10.pem`), a que o ITI identifica como a raiz de SSL, vem
    do repositório do ITI (acraiz.icpbrasil.gov.br); o SHA-256 dela é igual ao da raiz que o servidor do MT manda
    na própria cadeia, e um teste confere esse SHA-256. Vale até 01/07/2032. As outras raízes (v5, v11 de
    assinatura de código, v12, v13) ficam de fora: nenhum servidor da SEFAZ as usa hoje.
  - **O motor da sessão não é trocado:** ele é escolhido quando o curl carrega, e mudar a variável de ambiente por
    conta própria afetaria tudo o que a sessão faz na internet. Primeiro a ajuda e o README pediam
    `CURL_SSL_BACKEND=openssl` no `.Renviron`; o usuário perguntou se cada pessoa teria de fazer isso e decidiu
    "então quero automático" (30/10/2026).
  - **Automático, como no PyNFe:** com o Schannel ligado (`usar_processo_separado()`), os pedidos vão todos juntos
    por um processo R separado (`Rscript --vanilla inst/sefaz/processo_separado.R`), aberto com
    `CURL_SSL_BACKEND=openssl`. A tarefa vai num arquivo da pasta temporária: os pedidos já montados, as opções da
    conexão sem a senha, as bibliotecas desta sessão e a própria função que envia (`enviar_os_pedidos()`, só httr2 e
    R base, com o ambiente trocado para o global, para não depender do RNFe instalado lá). A senha vai numa
    variável de ambiente que o processo herda; as variáveis desta sessão voltam como eram. A leitura das
    respostas fica nesta sessão. Com o OpenSSL já ligado, tudo roda aqui mesmo, com a mesma função.
  - **Medido em 30/10/2026:** numa sessão comum do Windows (Schannel), as 27 UFs responderam 107 em 8 s (7 s com o
    OpenSSL já ligado); uma UF só, 0,6 a 0,8 s contra 0,3 a 0,4 s: o processo separado custa uns 0,3 s por chamada.
    Um teste roda o processo separado de verdade, contra uma porta fechada do próprio computador: o motor lá dentro
    é o OpenSSL, o erro volta, a senha não está no arquivo da tarefa e as variáveis da sessão não mudam.
  - **Como o PyNFe faz** (o `master` do GitHub, lido em 30/10/2026, pergunta do usuário: "mas o pynfe consegue?"):
    o `requests` do Python roda sempre sobre o OpenSSL, também no Windows, então o problema do Schannel não existe
    para ele; o .pfx vira PEM em arquivos temporários (a chave sem cifra, `NoEncryption()`, só o certificado da
    empresa, sem a cadeia) apagados depois; e a chamada é `requests.post(..., verify=False)`, nas três funções de
    envio: **não verifica o certificado do servidor**, por isso não precisa das raízes da ICP-Brasil. Pelo nosso
    teste com o OpenSSL e só o certificado da empresa, BA, SP, a SVAN, MG e MT respondem; o PyNFe em si não foi
    rodado. O RNFe mantém a verificação ligada (sem ela, quem estiver no meio do caminho pode se passar pela
    SEFAZ) e grava a chave cifrada.
- **Testes sem rede:** certificados falsos (`ferramentas/gerar_certificados_de_teste.py`, com o pacote
  `cryptography`: pessoa jurídica com os quatro otherName dos reais, pessoa física, sem os campos e vencido), a
  resposta real da SVRS gravada (não tem dado de empresa) e o `httr2` devolvendo essa resposta no lugar da
  SEFAZ (esses testes forçam o envio nesta sessão, porque o processo separado não veria o httr2 simulado).
  `httr2`, `curl` e `openssl` ficam em Suggests.

## Etapa 3, segundo passo: a consulta pela chave (03/11/2026)

- `sefaz_situacao(chaves, certificado, senha)` pergunta a situação de cada NF-e (modelo 55) pelo serviço
  NFeConsultaProtocolo4, só em homologação. O pedido (`consSitNFe` 4.00: `tpAmb`, `xServ` CONSULTAR, `chNFe`) e a
  resposta (`retConsSitNFe`) seguem o `leiauteConsSitNFe_v4.00.xsd` do pacote 010d v1.01 (o mesmo dos eventos, com
  o CNPJ alfanumérico); o namespace e a operação (`nfeConsultaNF`) vêm do WSDL baixado da SVRS de homologação. A
  conexão, o envelope e o processo separado são os do `sefaz_status()`.
- **Cada chave vai ao autorizador da UF da chave.** Chave que não confere (`chave_decompor()`), de outro modelo
  (a NFC-e tem outra lista de endereços) ou sem o serviço na Relação de Serviços Web não é enviada: o motivo vai
  em `problema`. A resposta é conferida: ambiente diferente ou outra chave na resposta também vão em `problema`.
- **Devolve `situacoes` e `eventos`.** Em `situacoes`, a resposta (`cStat`, `xMotivo`, a hora do recebimento) e o
  protocolo de autorização (`protNFe`: número, data e `digVal`). Os eventos que a SEFAZ manda junto
  (`procEventoNFe`, como o cancelamento) passam pelo `eventos_ler()`, sem a coluna `arquivo`. O `retCancNFe`, do
  cancelamento de antes dos eventos, não tem coluna.
- **Teste real em homologação (03/11/2026):** uma chave inventada por UF (CNPJ de exemplo, nada da empresa), nas
  27: todas responderam `retConsSitNFe` com 217 ("NF-e não consta na base de dados"), ambiente 2 e a mesma chave,
  em 26 s pelo processo separado (um pedido depois do outro). A resposta da SVRS ficou gravada para os testes sem
  rede. A resposta da nota cancelada dos testes é montada com o protocolo de `nfe_proc_sp.xml` e o cancelamento
  de `evento_nfe_cancelamento.xml`, e passa no `retConsSitNFe_v4.00.xsd`.

## Etapa 3, a NFC-e na consulta pela chave (03/11/2026)

- **Pedido do usuário**, com um cupom de NFC-e de PE em mãos. A `sefaz_situacao()` passou a consultar a NFC-e
  (modelo 65), com a coluna `documento` (`NF-e` ou `NFC-e`, pelo modelo da chave). O pedido e o WSDL são os da
  NF-e (`consSitNFe` no NFeConsultaProtocolo4); mudam os endereços.
- **De onde vêm os endereços da NFC-e:** o Portal da NF-e só lista os da NF-e. Os da NFC-e estão no Portal da NFC-e,
  mantido pela SVRS (`dfe-portal.svrs.rs.gov.br/Nfce/Servicos`), uma tabela por autorizador e ambiente: AM, GO, MS,
  MT, PR, RS, SP e SVRS. O portal não diz que UFs usam a SVRS, e não lista MG, que tem NFC-e própria: os endereços de
  MG vêm da página da SEFAZ-MG (`portalsped.fazenda.mg.gov.br/spedmg/nfce/web-services/`). O `gerar_tabelas.R` lê as
  duas páginas (o robô semanal passa a vigiar os endereços da NFC-e também) e grava as linhas com `documento`
  `NFC-e` em `servicos_sefaz` e `autorizadores_sefaz`.
- **Conferido em homologação (03/11/2026)**, com chaves inventadas de NFC-e: a SVRS respondeu às 19 UFs sem
  autorizador próprio (entre elas o MA, que na NF-e usa a SVAN, e BA, PE, que têm SEFAZ própria na NF-e) e recusou
  com 410 as 8 de autorizador próprio, inclusive MG; cada uma das 8 respondeu no seu endereço. Pela função pública,
  7 UFs e a chave do cupom (PE) foram cada uma ao seu autorizador, em 3,7 s. O cupom volta 217 em homologação: é
  uma nota de produção.

## A chave num PDF ou numa foto: `chave_extrair()` (03/11/2026)

- **Pedido do usuário**, com a foto de um cupom de NFC-e em PDF: "ler QR-Code também e OCR pelo tesseract ... leitura
  de PDF também ... se não for bom, me diga porque melhor não". A resposta foi: bom para achar a chave, não para ler o
  resto. A chave tem dígito verificador e o CNPJ dentro, e pega quase toda leitura errada; valores, quantidades e
  descrições não têm conferência, e lidos de uma imagem viriam errados sem aviso. Os dados da nota vêm do XML.
- `chave_extrair(arquivos, ocr = TRUE)` procura em PDFs e imagens, nesta ordem, e para no primeiro jeito que acha:
  o texto do PDF (`pdftools`); o QR-Code (`opencv`, com o decodificador `wechat`), na página do PDF virada imagem a
  300 dpi ou na imagem; e o OCR (`tesseract`, com o inglês que vem no pacote: só os números importam). Os três ficam
  em Suggests, e o jeito sem o pacote é pulado (dito em `problema`). O `quadrangle`, outro leitor de QR-Code, não
  existe para o R 4.6.
- **Como a chave é achada no texto:** emendada (o QR-Code, o texto do XML) ou em blocos de 4 separados por espaço
  (o DANFE). Em cada sequência de blocos, cada janela de 11 blocos é uma candidata, para um número de 4 dígitos logo
  antes da chave (um telefone) não a esconder. Só fica a candidata com o formato de chave e que passa no
  `chave_valida()`; a que tem o formato e não confere vai para `problema`.
- **No cupom do usuário (uma foto, sem texto):** o PDF não tinha texto; o QR-Code estava cortado no pé da foto e não
  foi lido; o OCR achou a chave, que confere, em cerca de 1 s (5,6 s ao todo, com a tentativa do QR-Code). O cupom
  não entra no repositório. Os testes usam imagens geradas com uma chave inventada
  (`ferramentas/gerar_imagens_de_teste.R`, com o pacote `qrcode`): o QR-Code de uma NFC-e, um cupom com a chave em
  blocos (OCR) e o mesmo com um dígito trocado (vai para `problema`); o PDF com texto é gerado no próprio teste.

## Etapa 3, terceiro passo: a consulta de cadastro (03/11/2026)

- `sefaz_cadastro(documentos, ufs, certificado, senha, tipo = "CNPJ")` consulta o cadastro de contribuintes do
  ICMS pelo CNPJ, CPF ou IE (um tipo por chamada, para não confundir uma IE com um CPF), só em homologação. Pedido
  (`ConsCad` 2.00, com C maiúsculo, sem `tpAmb`: o ambiente é o do endereço) e resposta (`retConsCad`) pelo
  `leiauteConsultaCadastro_v2.00.xsd`, que vem no zip do pacote 010d; namespace e operação (`consultaCadastro`) pelo
  WSDL da SVRS de homologação. Devolve `consultas` (uma linha por documento) e `cadastros` (uma por inscrição; um
  CNPJ pode ter várias), com o significado da situação (`cSit`) e do credenciamento na NF-e e no CT-e
  (`indCredNFe`, `indCredCTe`) pela documentação do schema.
- **26 UFs têm o serviço:** as 10 com SEFAZ própria (AM, BA, GO, MG, MS, MT, PE, PR, RS, SP) e as 16 da SVRS. A
  Relação de Serviços Web (homologação e produção, conferidas em 03/11/2026) lista para a consulta de cadastro da
  SVRS só AC, ES, PB, RN e SC, e a primeira versão seguiu a lista: o CE ficava "sem o serviço" (achado pelo usuário,
  consultando o CE). Mas a SVRS atende todas as UFs dela: em homologação, AL, AP, CE, DF, PA, PI, RJ, RO, RR, SE e TO
  responderam como AC e SC (257, sobre quem pergunta), e só o MA voltou 410 ("UF informada no campo cUF não é
  atendida pelo Web Service"), o que mostra que a SVRS confere a UF antes de quem pergunta. Em produção, o app Fiscal
  consulta CE, AL e PI pela SVRS desde 30/10/2026. Agora a consulta de cadastro usa a SVRS para toda UF que a usa nos
  demais serviços. O MA (SVAN) fica sem: a linha vem com o motivo, sem pedido.
  - **As 27 UFs na SVRS** (pedido do usuário: "é bom ver para os outros estados também"): a SVRS de homologação
    aceita também AM, GO, MS, MT, PR e RS, que têm SEFAZ própria, e responde 410 a BA, MA, MG, PE e SP. O RNFe
    continua mandando cada UF com SEFAZ própria à SEFAZ dela, que é o caminho da Relação de Serviços Web; a SVRS fica
    anotada como alternativa para GO e AM, cuja SEFAZ responde sobre o CNPJ do certificado.
  - **A ajuda diz o que acontece em cada UF** (pedido do usuário): a seção "Em cada UF" do `sefaz_cadastro()` lista
    as UFs de SEFAZ própria, as da SVRS e o MA sem o serviço, e explica a 257 (sobre o certificado) e a 259 (sobre o
    documento consultado).
- **As SEFAZ não seguem o mesmo envelope** (WSDLs de homologação baixados em 03/11/2026):
  - o MT pede o `nfeDadosMsg` dentro de um `consultaCadastro` e responde com um `consultaCadastroResult` no meio;
    o pedido igual ao dos outros voltava 215, "Falha no schema XML". Fica em `ELEMENTO_EM_VOLTA_NO_CADASTRO`;
  - o AM e MG respondem num `consultaCadastro4Result`, sem o `nfeResultMsg` (o WSDL do AM chama a operação de
    `consultaCadastro4`, mas ele responde igual às duas);
  - por isso o `ler_resposta()` passou a achar o retorno pelo nome (`retConsStatServ`, `retConsSitNFe`,
    `retConsCad`), em qualquer envelope;
  - MG manda a hora sem fuso (é a de Brasília: a mesma do AM, que manda com fuso, na mesma consulta) e o PR manda
    milésimos; os dois são lidos.
- **Teste real em homologação (03/11/2026)**, com o CNPJ de exemplo inventado, nas 15 UFs: 11 responderam 257
  ("Solicitante não habilitado para emissão da NF-e"), que é sobre o CNPJ do certificado, não sobre o consultado;
  MT e PR responderam 259 ("CNPJ não cadastrado como contribuinte na UF"), sobre o CNPJ consultado; **GO e AM
  responderam sobre o CNPJ do certificado** (conferido comparando os dois, sem mostrá-los). Por isso a resposta é
  conferida: se ela traz outro documento, os cadastros dela não entram e a linha vai com "a SEFAZ respondeu sobre
  outro documento". Nenhuma UF devolveu um cadastro (o CNPJ é inventado): o caso com cadastro é testado com uma
  resposta montada com dados inventados, no envelope de MG, que passa no `retConsCad_v2.00.xsd` (as duas respostas
  reais gravadas para os testes, da SVRS e do PR, também passam).

## Etapa 3, quarto passo: a Distribuição de DF-e (03/11/2026)

- `sefaz_distribuicao(documento, certificado, senha, ultimo_nsu = 0, nsu, chave)` pede ao Ambiente Nacional os
  documentos de interesse de um CNPJ ou CPF (NT 2014.002 v1.02d), só em homologação. Pedido `distDFeInt` 1.01 e
  resposta `retDistDFeInt` pelo pacote da Distribuição v1.04; o WSDL do Ambiente Nacional (baixado em 03/11/2026)
  pede o `nfeDadosMsg` dentro de `nfeDistDFeInteresse`, o mesmo jeito do MT na consulta de cadastro. Devolve
  `consulta` (uma linha: `cStat`, último e maior NSU, quantos documentos) e `documentos` (NSU, schema, tipo e o XML
  descompactado do gzip em base64, com o `memDecompress` do R e o `openssl`). Os documentos vão direto para o
  `nfe_ler()` (notas e resumos) e o `eventos_ler()`.
- **Um pedido por chamada, e a trava de uma hora.** A NT manda esperar uma hora depois de um 137, ou de o último NSU
  chegar ao maior, antes de pedir de novo pelo último NSU, e seguir sempre o `ultNSU` devolvido; senão, 656
  ("Consumo Indevido") e o CNPJ bloqueado por uma hora. Por isso a função não segue sozinha até o fim e, nesta sessão
  do R, recusa antes de conectar um novo pedido pelo último NSU do mesmo CNPJ e ambiente dentro da hora (o 656
  também conta). O pedido de um NSU (`consNSU`) ou de uma chave (`consChNFe`) fica fora da trava, como na NT.
- **Teste real em homologação (03/11/2026)**, com o CNPJ do certificado de teste: um pedido pelo último NSU (0) voltou
  137, "Nenhum documento localizado", com último e maior NSU zerados (ninguém emitiu nota de teste contra esse
  CNPJ); um pela chave inventada voltou 217, "NF-e inexistente para a chave de acesso informada"; o segundo pedido
  pelo último NSU foi recusado pelo RNFe, sem ir à SEFAZ (só dois pedidos saíram). A resposta do 137 ficou gravada
  para os testes (não tem dado de empresa). A resposta com documentos dos testes é montada com o resumo e o
  cancelamento de exemplo compactados como a SEFAZ manda, e passa no `retDistDFeInt_v1.01.xsd` (a real também).

## Etapa 3, quinto passo: CT-e e MDF-e no status e na consulta pela chave (03/11/2026)

- **Pedido do usuário** ("e depois prossiga com o resto"). O `sefaz_status()` ganhou o argumento `documento` (`"NF-e"`,
  o padrão, `"NFC-e"`, `"CT-e"` ou `"MDF-e"`) e a coluna `documento`; a `sefaz_situacao()` consulta também o CT-e (57),
  o CT-e OS (67), a GTV-e (64) e o MDF-e (58), pelo modelo da chave. Cada documento é uma linha de uma tabela no topo
  do `R/sefaz.R` (`STATUS_DE_CADA_DOCUMENTO` e `CONSULTA_DE_CADA_DOCUMENTO`): a lista de endereços, o nome do serviço
  nela, o WSDL, a operação, a família (`nfe`, `cte`, `mdfe`, que dá o `<família>DadosMsg` e o namespace), o pedido, a
  versão, o retorno, o protocolo e o campo da chave. Como todo modelo que a chave conhece agora é consultado, saiu o
  aviso de "modelo que não é consultado".
- **Pedidos e respostas pelos schemas:** no CT-e, `consStatServCTe` e `consSitCTe` 4.00 do pacote PL_CTe_400 NT
  2026.004 RTC 1.00; no MDF-e, `consStatServMDFe` e `consSitMDFe` 3.00 do PL_MDFe_300b (NT 2025.001). O CT-e OS e a
  GTV-e vão ao serviço de consulta do CT-e, que separa os três pelo modelo da chave (MOC do CT-e 4.00). Pelos WSDLs de
  homologação (baixados em 03/11/2026), o MDF-e pede o cabeçalho `mdfeCabecMsg` com a UF e a versão; no status do
  MDF-e a UF vai só no cabeçalho, porque o `consStatServMDFe` não tem `cUF`. O CT-e 4.00 não tem cabeçalho.
- **O retorno do CT-e e do MDF-e é mais curto:** o `retConsSitCTe` e o `retConsSitMDFe` não repetem a chave nem
  trazem a hora do recebimento. `recebimento` fica vazio, e a chave conferida é a do `infProt` do protocolo, quando
  ele vem (há teste com a resposta de outra chave). Os eventos que vêm junto (`procEventoCTe`, `procEventoMDFe`)
  passam pelo `eventos_ler()`, como os da NF-e.
- **Os endereços:** o `gerar_tabelas.R` lê a Relação de Serviços Web de homologação do Portal do CT-e (no molde da
  da NF-e: MG, MS, MT, PR, RS e SP com autorizador próprio, e as UFs de cada SEFAZ virtual, SVSP para AP, PE e RR e
  SVRS para as outras 18) e a página de serviços do Portal do MDF-e (a SVRS, para todas as UFs). As linhas entram em
  `servicos_sefaz` e `autorizadores_sefaz` com `documento` `CT-e` e `MDF-e`, e o robô semanal vigia as duas páginas.
- **`sefaz_mdfe_nao_encerrados(documento, certificado, senha)`** pergunta à SVRS os MDF-e de um CNPJ ou CPF emitente
  que ainda não foram encerrados (`consMDFeNaoEnc` 3.00, `xServ` "CONSULTAR NÃO ENCERRADOS"). Devolve `consulta` (a
  resposta, numa linha) e `mdfes` (a chave e o protocolo de cada um). O WSDL deixa a UF do cabeçalho opcional, e a do
  emitente não é sabida: vai só a versão. Em homologação a SVRS respondeu igual com a UF, sem ela e sem cabeçalho.
- **Teste real em homologação (03/11/2026)**, com chaves inventadas (CNPJ de exemplo): o status nas 27 UFs para
  CT-e, MDF-e e NFC-e voltou 107 em todas; a consulta voltou 217 (o documento não consta) para o CT-e nas 27 UFs, o
  CT-e OS de SP e do RS, a GTV-e de SP e do CE e o MDF-e de SP, do CE e do MA. Os MDF-e não encerrados, com o CNPJ do
  certificado de teste e pela função pública, voltaram 112 ("não localizou MDF-e nessa situação") em 0,9 s. As
  respostas da SVRS e de SP ficaram gravadas para os testes (não têm dado de empresa); as do CT-e cancelado e do
  MDF-e encerrado são montadas com o protocolo e o evento dos exemplos do pacote.

## Etapa 3, sexto passo: a Distribuição do CT-e (04/11/2026)

- **Pedido do usuário** ("pode começar", depois de o que faltava ser listado). A `sefaz_distribuicao()` ganhou os
  argumentos `distribuicao` (`"NF-e"`, o padrão, ou `"CT-e"`) e `uf`, e a coluna `distribuicao` na consulta. Cada
  distribuição é uma linha de `DISTRIBUICAO_DE_CADA_DOCUMENTO`, no `R/sefaz.R`: o serviço, a operação, a família, a
  versão e a nota técnica. A do CT-e traz também o CT-e OS e a GTV-e, e os documentos vão para o `cte_ler()`, o
  `gtve_ler()` e o `eventos_ler()`.
- **Fontes:** a NT 2015.002 v1.05 (novembro de 2024) e o pacote PL_CTeDistDFe_100, ambos do Portal do CT-e, e o WSDL
  de homologação do CTeDistribuicaoDFe (baixado em 04/11/2026), que pede o `cteDadosMsg` dentro de
  `cteDistDFeInteresse`, como na NF-e. O endereço já estava em `servicos_sefaz`.
- **O que muda em relação à NF-e:**
  - o pedido exige o `cUFAutor` (a UF de quem pede), que na NF-e é opcional. A NT não tem regra sobre o valor. Na
    NF-e ele vai quando `uf` é informada;
  - não há busca pela chave: o pedido só tem o último NSU (`distNSU`) e o NSU (`consNSU`);
  - o CNPJ do schema 1.00 é só de números. O CNPJ com letras é recusado antes de conectar, com o motivo;
  - o emitente não recebe os próprios CT-e. Recebem o remetente, o destinatário, o expedidor, o recebedor, o tomador e
    quem está no `autXML`. Para quem só está no `autXML`, as chaves citadas no documento chegam trocadas por 44 noves.
    O CT-e simplificado também vem (para o tomador e os autorizados), lido por `cte_simplificado_ler()` desde
    04/11/2026;
  - **o `dhResp` vem sem o fuso** (o schema não tem). A resposta real disse 09:44:12 às 09:44 de Brasília, então ele é
    lido como hora de Brasília. Só o teste real mostrou isso.
- **A trava de uma hora é de cada distribuição:** a NT 2015.002 também manda esperar uma hora depois de "não há mais
  documentos" e responde 656 a quem não espera (sem dizer de bloqueio, que é da NT 2014.002). A memória da sessão
  agora é por distribuição, CNPJ e ambiente: a espera do CT-e não prende a NF-e.
- **Teste real em homologação (04/11/2026)**, com o CNPJ do certificado de teste: um pedido pelo último NSU (0) voltou
  137, "Nenhum documento localizado.", em 2,2 s, com último e maior NSU zerados; um pedido do NSU 1 pela função pública
  também voltou 137, e não o 589 ("NSU superior ao maior") que a regra H06 da NT prevê. A resposta do 137 ficou gravada para os
  testes (não tem dado de empresa). O pedido montado pelo RNFe (pelo último NSU, por um NSU e com CPF), a resposta real
  e a resposta montada dos testes (um CT-e, o cancelamento dele e uma GTV-e) passam nos schemas do pacote.

## Etapa 3, sétimo passo: a NFS-e Nacional (04/11/2026)

- **Pedido do usuário** ("pode começar"; a Produção Restrita, que é a homologação da NFS-e Nacional, foi liberada por
  ele). Duas funções novas, em `R/nfse_nacional.R`: `nfse_situacao(chaves, certificado, senha)`, a nota pela chave na
  Sefin Nacional (`GET /nfse/<chave>`) e os eventos dela no ADN (`GET /NFSe/<chave>/Eventos`); e
  `nfse_distribuicao(documento, certificado, senha, ultimo_nsu)`, as NFS-e e os eventos de um CNPJ ou CPF no ADN
  (`GET /DFe/<NSU>`). As notas vão para o `nfse_ler()` e os eventos para o `eventos_ler()`, que já liam os dois.
- **Fontes:** a página "APIs - Prod. Restrita e Produção" do gov.br/nfse (os endereços), as especificações OpenAPI da
  Sefin Nacional e do ADN Contribuintes, baixadas da Produção Restrita com o certificado (só a documentação), e os dois
  manuais de contribuintes (Emissor Público Nacional, v1.0 de 17/03/2025; APIs do ADN, v1.0 de 12/02/2026). A chave
  tem 50 números (o `TSChaveNFSe` do schema 1.01); a que não tem nem é enviada.
- **O jeito é outro:** APIs REST, GET sem corpo e respostas em JSON, também nos erros (a Sefin manda `erro` com
  `codigo` e `descricao`; o ADN, `Erros` e `Alertas`), com os documentos em gzip dentro do base64. O
  `enviar_os_pedidos()` passou a mandar GET quando o pedido não tem corpo, também no processo separado. O JSON é lido
  com o `jsonlite`, que entrou em Suggests.
- **A NFS-e não tem situação como a NF-e:** o cancelamento, a substituição e a manifestação são eventos. A
  `nfse_situacao()` devolve se a nota veio, o erro da Sefin (`E2401`, chave não encontrada; 403 para quem não está na
  nota) e o XML, e os eventos numa tabela à parte. Nota que não existe e nota sem eventos (`E2240`) são resposta, não
  problema.
- **O DANFSe oficial não existe mais.** A API do DANFSe do ADN foi desativada em 03/08/2026 (página "Atualizações e
  Implantações" do gov.br/nfse: "Desativação da API do DANFSe do ADN (versão 1.0)"). Pela NT SE/CGNFS-e 008/2026, cada
  sistema gera o seu DANFSe, num leiaute único. Na Produção Restrita a documentação do DANFSe responde 404, e o
  `GET /DANFSe` da Sefin responde 501 ("serviço movido"). Por isso a etapa 3 não baixa o DANFSe: ele entra com os PDFs,
  no leiaute da NT 008.
- **Teste real na Produção Restrita (04/11/2026)**, com o certificado de teste:
  - a chave inventada (50 números, CNPJ de exemplo) voltou 404, `E2401` "Chave de acesso não encontrada.", em 1,6 s,
    com os eventos dela;
  - os eventos voltaram 404, `E2240`;
  - a chave curta voltou 400, `E2406`, e no RNFe nem vai;
  - a distribuição com o CNPJ do certificado voltou 404, `E2220` "Nenhum documento localizado", autorizada como
    `CnpjBase`, em 0,8 s, pelo processo separado de uma sessão comum do Windows.
- **Achado do teste real:** sem o `cnpjConsulta`, que a documentação diz ser opcional, a distribuição voltou 400,
  "REJEICAO", sem erro nenhum na lista (NSU 0 e 1, com e sem `lote`). Com ele, respondeu normalmente. Por isso a
  `nfse_distribuicao()` sempre manda o CNPJ (ou o `cpfConsulta`), e a rejeição sem motivo tem mensagem própria.
- **Não há trava de uma hora** na distribuição da NFS-e: a documentação do ADN não fala de espera nem de bloqueio
  (diferente das NTs da NF-e e do CT-e), e o RNFe não inventa regra. A ajuda pede para não perguntar em laço sem pausa.
- As quatro respostas reais ficaram gravadas para os testes (não têm dado de empresa). As respostas com documentos são
  montadas com a NFS-e e o cancelamento de exemplo, no formato da especificação. O que não foi visto na resposta real,
  porque a Produção Restrita não tem nota desse CNPJ: o `ArquivoXml` do ADN em gzip e base64 (é o padrão que a
  especificação diz para as mensagens) e o formato do `DataHoraGeracao`.

## Etapa 3, oitavo passo: a situação do CNPJ na Receita Federal (04/11/2026)

- **Decisão do usuário:** "a situação do cnpj deve ser uma nova funcao que le do brasilapi e outras caso esteja fora do
  ar". A `cnpj_situacao(cnpjs, fontes)`, em `R/cnpj.R`, devolve uma linha por CNPJ: se foi encontrado, a situação
  cadastral (ATIVA, BAIXADA, INAPTA, SUSPENSA, NULA), a data e o motivo, a situação especial, a razão social, o nome
  fantasia, de quando são os dados (quando a fonte diz), a fonte que respondeu e as que estavam fora do ar. Não usa
  certificado. Precisa do `httr2` e do `jsonlite`.
- **As fontes, nesta ordem:** a BrasilAPI (`/api/cnpj/v1/<cnpj>`), o Minha Receita, a CNPJá (`open.cnpja.com`), a
  ReceitaWS e a CNPJ.ws (`publica.cnpj.ws`). Pelo código da BrasilAPI no GitHub, ela busca o CNPJ no Minha Receita e
  responde 503 quando ele não responde: o Minha Receita direto cobre só a queda da própria BrasilAPI, e as outras três
  são independentes. Todas são públicas, sem cadastro nem chave. A documentação do Minha Receita diz que nenhuma
  consulta é recusada por limite; a ReceitaWS e a CNPJ.ws mandaram, nos cabeçalhos, limite de 3 por minuto, por isso
  vão por último. O argumento `fontes` escolhe quais e em que ordem.
- **Fora do ar** (vai para a próxima): sem resposta (inclui o tempo limite de 15 s), 429, 5xx, ou uma resposta que não
  é a de sempre (sem JSON, ou um 404 sem a mensagem da fonte). **Não achou** é o 404 com a mensagem da fonte
  (`message` na BrasilAPI, no Minha Receita e na CNPJá; `detalhes` na CNPJ.ws), ou, na ReceitaWS, o 200 com `status`
  "ERROR" ("CNPJ rejeitado pela Receita Federal"). Na primeira versão, o "não achou" parava ali; desde 04/11/2026
  (o usuário, depois da revisão: "faça todos") ele também passa para a próxima, porque o CNPJ aberto há pouco pode
  ainda não estar nos dados abertos que a BrasilAPI usa. O Minha Receita só é perguntado quando a BrasilAPI está fora
  do ar: ela busca nele, e perguntar aos dois seria perguntar duas vezes à mesma base. `mensagem` traz o que cada
  fonte que não achou disse, com o nome dela.
- **Cada fonte no seu formato**, conferido em 04/11/2026 com a matriz do Banco do Brasil (ativa desde 03/11/2005), uma
  filial baixada em 29/07/2020 e um CNPJ com o dígito certo que não existe; as cinco deram a mesma situação e a mesma
  data:
  - a BrasilAPI e o Minha Receita: `descricao_situacao_cadastral`, `data_situacao_cadastral`,
    `descricao_motivo_situacao_cadastral` (sem acento, "SEM MOTIVO" na ativa); não dizem a data dos dados no
    registro;
  - a CNPJá: `status.text` ("Baixada"), `statusDate`, `reason.text` (com acento), `company.name`, `alias` e `updated`;
  - a ReceitaWS: `situacao`, `data_situacao` em DD/MM/AAAA, `motivo_situacao` (com acento, em maiúsculas),
    `ultima_atualizacao`;
  - a CNPJ.ws: a situação no `estabelecimento`, e o motivo veio vazio também na filial baixada: a função não lê motivo
    dela.
  A situação sai em maiúsculas; o motivo, como a fonte escreve; o vazio vira NA.
- **CNPJ que não confere** (o formato ou o dígito, também o alfanumérico, pelo `cnpj_confere()` da chave) nem é
  perguntado.
- **Teste real (04/11/2026)**, pela função pública: a BrasilAPI respondeu os quatro CNPJs (ativo, baixado, inexistente
  e um de dígito errado, que não foi perguntado) em 1 s; cada fonte sozinha achou a filial baixada em 0,6 a 0,9 s.
- **Os testes não usam esses CNPJs** (regra do repositório: só os fictícios): as respostas de `tests/testthat/respostas/cnpj`
  são montadas à mão, com os mesmos campos que cada fonte devolveu, para 11.222.333/0001-81 (ativo), 11.444.777/0001-61
  (baixado) e o exemplo da Receita, 12.ABC.345/01DE-35 (que as fontes não acham). A queda de cada fonte é simulada.

## Revisão das etapas 1 a 3 (04/11/2026)

- **Pedido do usuário:** "você tem que ver se terminou realmente as etapas anteriores antes de prosseguir pra
  quarta; corrigir possíveis erros e considerar brechas". Quatro frentes: o plano contra o pacote, os robôs do
  GitHub, o acervo do Fiscal inteiro e uma revisão independente do código da etapa 3 (dois revisores, com
  experimentos rodados: respostas simuladas, certificados falsos e um servidor local; nenhuma conexão com a SEFAZ).
- **Os robôs:** sem aviso aberto. Disparados à mão em 04/11/2026, os dois rodaram sem erro, já com o gerador de
  tabelas novo (os endereços do CT-e, do MDF-e e da NFC-e), que ainda não tinha rodado no GitHub.
- **O acervo do Fiscal** (341.402 XML), por tipo de documento, uma amostra de até 300 de cada tipo em todos os
  leitores (só contagens): os tipos que o RNFe lê saíram sem problema, sem aviso do R, e com todas as chaves
  conferindo. Os que nenhum leitor lê são NFS-e de prefeitura (cerca de 2.200: `CompNfse`, `Nfse`, `CompNfe` e
  `NFe`/`nfe` sem namespace, como a da prefeitura de São Paulo), que ficam para depois por decisão do usuário. A
  mensagem para eles dizia "não é uma NF-e (o XML começa por <NFe>)", o que confunde; agora diz que parece NFS-e de
  prefeitura, ou que o `<NFe>` não tem o infNFe da NF-e.
- **Erros achados na revisão do código e corrigidos** (cada um com teste):
  - uma resposta HTTP sem corpo (um 503 vazio) derrubava a chamada inteira, e no Windows, pelo processo separado,
    levava junto as respostas boas: o `enviar_os_pedidos()` passou a aceitar o corpo vazio (vira "não respondeu em
    XML" ou "não veio em JSON", só naquela linha);
  - a chave de um modelo que o RNFe não consulta (59, 62, 63, 66) derrubava a `sefaz_situacao()` inteira: o trecho
    que tratava disso tinha sido tirado em 03/11/2026 como "código morto", e não era (o `chave_decompor()` aceita
    qualquer modelo). Agora a linha vai com "o modelo 59 não é consultado pelo RNFe";
  - na NFS-e, o E2241 do ADN ("a nota não cita quem pergunta") vem, pela especificação, como 404 e
    `NENHUM_DOCUMENTO_LOCALIZADO`: ele passava por "nota sem eventos". Agora só E2220, E2230 e E2240 querem dizer
    nenhum documento; outro código vai para `problema`. O teste antigo montava o E2241 como 400 `REJEICAO`, caminho
    que a especificação não usa;
  - JSON fora do formato (o erro padrão do servidor, um texto solto) dava mensagem errada ou derrubava; NSU nulo
    derrubava a distribuição da NFS-e; erro do ADN sem código virava o texto "NA"; NSU acima de 2^53 perdia o
    último dígito (agora o JSON é lido com os inteiros grandes como texto, e o maior NSU é comparado como texto);
  - na `cnpj_situacao()`, um 200 fora do formato (`{}`, um aviso de manutenção) virava "achou" com tudo vazio; agora
    conta como fora do ar, e a fonte seguinte é tentada. Um campo de outro tipo (o `status` da CNPJá como texto)
    derrubava a lista inteira;
  - na `chave_extrair()`, um arquivo que não abre derrubava a lista inteira (agora é uma linha com o motivo); o TIFF
    de várias páginas só tinha a primeira lida (agora o `magick`, em Suggests, separa as páginas); a chave emendada
    com um número colado antes não era achada (agora cada janela de 44 posições é candidata); uma pasta com nome
    de PDF e `ocr = NA` davam erro. Ficam escritos na ajuda, sem mudar: um QR-Code por imagem ou página, e o PDF
    com texto é lido só pelo texto;
  - a chave repetida ia duas vezes à SEFAZ (a mesma consulta repetida pode virar consumo indevido) e duplicava os
    eventos: agora vai uma vez, na `sefaz_situacao()` e na `nfse_situacao()`;
  - a hora com milésimos, sem fuso ou com "Z" virava NA no status e na consulta pela chave (o cadastro e a
    distribuição já aceitavam): agora todos usam a mesma leitura; uma data fora do formato no cadastro derrubava a
    consulta inteira;
  - na consulta pela chave, a resposta sobre outra chave ou de outro ambiente deixava a situação e o protocolo
    dela na linha; agora a linha fica só com o `problema`, como no cadastro. Um evento que vem na resposta e não é
    lido vai para `problema` (antes sumia calado);
  - na distribuição, duas chaves, dois NSU ou duas UFs viravam, sem aviso, o pedido pelo último NSU (e ligavam a
    trava); a chave de outro modelo ia ao `consChNFe` (a NT 2014.002, regra H122, só aceita o 55); o NSU com casas
    decimais era arredondado. Agora são recusados antes de conectar;
  - no certificado: o CNPJ alfanumérico não era lido; a coluna `tipo_documento` saía lógica quando nenhum
    certificado tinha documento; só a vírgula escapada do nome era desfeita (agora as do RFC 4514); o certificado
    que ainda não vale passava na conferência; e, com senha vazia, a chave temporária ia sem cifra. **A chave
    temporária agora é cifrada por uma senha sorteada na hora**, não a do certificado: a senha de quem usa nem vai
    para o processo separado;
  - o processo separado não apagava um resultado antigo e, no erro, mostrava o fim do rastro em vez da mensagem.
- **Sem correção, porque não aconteceu de verdade:** os eventos com prefixo de namespace declarado no envelope
  (`ns2:`). Nenhuma das respostas reais (27 UFs) faz isso, e a SEFAZ proíbe prefixo nos documentos (rejeição 404).
  Se acontecer, agora vira `problema` em vez de sumir.
- **Brechas que ficaram em aberto**, e o que o usuário decidiu no mesmo dia ("faça todos"): o **CT-e simplificado**
  (tpCTe 5 e 6), que a distribuição do CT-e entrega ao tomador, ganhou leitor (veja a seção dele, na etapa 2); a
  terceira camada das tabelas virou o `tabelas_atualizar()` (veja "O robô das tabelas"); e a `cnpj_situacao()`
  passou a tentar a fonte seguinte também quando uma não acha o CNPJ (veja o oitavo passo da etapa 3). **Seguem em
  aberto:** a NFS-e de prefeitura (decisão do usuário: depois); o MDF-e e o CT-e simplificado sem documento real para
  conferir; o dígito da chave da NFS-e, sem regra publicada.

## Revisão do código novo (04/11/2026, antes da etapa 4)

- **Por quê:** o código das três brechas (o CT-e simplificado, o `tabelas_atualizar()` e a fonte seguinte no CNPJ)
  foi escrito depois da revisão das etapas 1 a 3. Dois revisores independentes, com o código e o schema e sem a
  conclusão de quem escreveu, com experimentos (variações validadas pelo schema, respostas simuladas, arquivo preso).
- **O leitor do CT-e simplificado:** com XML válido pelo schema, nenhum resultado errado (os grupos de ICMS, CPF,
  contingência, vários documentos anteriores, `nItem` 990, sem protocolo, dois documentos num arquivo). Corrigidos:
  - o documento com prefixo no namespace (`<cte:CTe>`) ganhava a mensagem "sem o infCte", que é falsa: agora diz que
    usa prefixo, que a SEFAZ não aceita e o RNFe não lê. No acervo (341.402 XML), nenhum usa prefixo no namespace
    fiscal; os 147 com prefixo são NFS-e de prefeitura (`ns4:Nfse`), que já tinham a mensagem certa;
  - os documentos que o CT-e e o CT-e simplificado citam pela chave nos grupos da Reforma (o do pagamento
    antecipado, `chDFePagAnt`, e o anterior da compra governamental, `refDFeAnt`) passaram a `documentos`, e o
    indicador de que a substituição troca o tomador (`indAlteraToma`), a coluna `altera_tomador`, nos dois leitores;
  - a ajuda dizia "até 999" entregas: o `nItem` só vai de 1 a 990. Na tabela `campos`, o `[k]` do `det` é a posição
    no XML, não o número da entrega (agora dito na ajuda);
  - o CT-e simplificado e a GTV-e dentro de outro grupo também são apontados aos leitores deles.
- **O `tabelas_atualizar()`:** refeito (veja "O robô das tabelas"). Achados: tabela cortada, com data fora do formato
  ou com coluna a mais entrava como certa e quebrava a leitura das notas, nesta sessão e nas próximas; falha no meio
  misturava tabelas; a escolha pela data do arquivo errava ao reinstalar e com `load_all()`; arquivo preso fazia a
  troca falhar com só um aviso; os testes liam a pasta de cache de quem roda.
- **A `cnpj_situacao()`:**
  - `encontrado` saía `FALSE` quando só a BrasilAPI respondeu "não achou" e as seguintes estavam fora do ar (o
    limite de 3 por minuto torna isso comum num lote): agora fica `NA`, com o motivo, porque elas poderiam ter
    achado;
  - qualquer 404 com mensagem contava como "não achou" (o de um proxy também): agora só o formato de cada fonte para
    o CNPJ que não existe, o que elas devolveram em 04/11/2026; o resto é fora do ar, com o que a fonte disse;
  - com o Minha Receita antes da BrasilAPI na lista, a mesma base era perguntada duas vezes; fonte repetida também.

## Etapa 4, a calculadora da Reforma: o que se decidiu (04/11/2026)

- **Pedido do usuário:** "vá fazendo" (depois da revisão do código novo). Três passos: as tabelas, conferir o IBS e a
  CBS de um documento como a SEFAZ confere, e simular o cálculo.
- **As fontes:**
  - a **NT 2025.002-RTC v1.53** (Portal da NF-e, 30/10/2026), com as regras de validação do grupo UB: as contas do
    IBS e da CBS (o valor é a base vezes a alíquota, ou a alíquota efetiva quando há redução, menos o diferimento e
    o tributo devolvido, com tolerância de 0,01; a alíquota efetiva em 4 casas), as alíquotas de cada ano e os grupos
    que cada CST e cada classificação exigem ou não permitem;
  - a **Tabela de Classificação Tributária do IBS e CBS** (Informe Técnico 2025.002, v1.71, de 30/10/2026): os
    indicadores que essas regras consultam;
  - a **LC 214/2025**, no texto do Planalto: 0,1% de IBS da UF e 0,9% de CBS em 2026 (arts. 343 e 346), 0,05% de IBS
    da UF e 0,05% do município em 2027 e 2028 (art. 344), e a CBS de 2027 em diante como a alíquota de referência do
    Senado (art. 349) menos 0,1 ponto percentual (art. 347), ainda não publicada.
- **Passo 1, as tabelas (pronto):**
  - o `cst_ibs_cbs` ganhou os 8 indicadores da aba de CST (1 = o grupo é exigido, 0 = não é permitido, pela legenda
    da planilha), em português, com o nome oficial na ajuda;
  - a `classificacao_ibs_cbs` ganhou os 7 indicadores de grupo da aba de cClassTrib, a permissão em cada documento
    (NF-e, NFC-e, CT-e, CT-e OS, NFS-e, BP-e, NF3e, NFCom e os outros, 17 ao todo) e o tipo de receita do Simples
    (`tpRBSN`) e o de doação (`tpDoacao`), com o significado tirado das abas da própria planilha;
  - a tabela nova `aliquotas_ibs_cbs`, escrita à mão da LC e da NT, uma linha por período. A CBS de 2027 em diante
    fica vazia, com a observação, até o Senado publicar.
  - O formato das duas tabelas da Reforma mudou: quem tem o pacote de antes e chama `tabelas_atualizar()` recebe "a
    tabela mudou de formato: atualize o pacote", e nenhuma tabela é trocada (tudo ou nada).
- **Passo 2, conferir (pronto, 04/11/2026):** `ibs_cbs_conferir()`, a NF-e e a NFC-e pelas regras UB e W da NT
  v1.53. O código e a mensagem de cada regra estão em `inst/extdata/regras_ibs_cbs.csv`, tirados do texto da NT.
  - **Testado no acervo do Fiscal** (2.638 NF-e sorteadas com IBS e CBS, 14.077 itens, só contagens na tela): a
    primeira rodada acusou 192 regras em notas autorizadas. Cada uma tinha um motivo, e nenhum era a nota:
    - UB24-10, UB43-10 e UB62a-10 (99): as notas eram de antes de 03/08/2026, quando essas regras entraram em
      produção (NT v1.40);
    - UB13-40 (90): a própria NT diz "implementação futura" para a produção e a homologação. Saiu da conferência;
    - UB67-10 (1): a diferença era de 0,01005 para a conta sem arredondar, e a SEFAZ autorizou. O calculado passou a
      ir a 2 casas antes da tolerância;
    - UB14-25 (2): a classificação 200001 na NF-e, permitida até a versão 1.30 da tabela e proibida desde a 1.40
      (publicada em 28/01/2026); as notas eram de março de 2026.
    Depois das correções: nenhuma errada, 2 sem conferir (as da 200001, com o motivo).
  - **As datas de cada regra:** `em_producao_desde` pelo cronograma da NT (10/11/2025 para a maioria, 02/02/2026 para
    a segunda lista da v1.30, 03/08/2026 para as incluídas na v1.40; a UB13-30 desde 04/12/2025, porque até a v1.31
    ela dizia "em produção para NFe com data de emissão maior ou igual a 05/01/2026" e a v1.32 tirou isso). O
    cronograma não lista toda mudança de texto: as 12 versões da NT (1.30 a 1.53) foram baixadas e o texto de cada
    regra comparado de uma para a outra. A maioria das diferenças é redação (a mensagem, a ordem). As que mudam o que
    a regra aceita, e que podem ter aceitado antes o que hoje não aceita, estão em `mudou_na_versao` e
    `mudou_em_producao_em`: a UB56-10 (v1.51, 05/10/2026: a ZFM deixou de ser os estados e passou a ser os três
    municípios), a UB26-20, a UB45-20 e a UB64-20 (v1.36, 03/08/2026: saiu o "se a alíquota for maior que zero"), a
    UB35-10, a UB54-10, a UB67-10 e a W47-10 (v1.31, 17/11/2025: saiu o crédito presumido da conta). A mudança que só
    afrouxou a regra (uma exceção nova) não entra: o que não confere hoje também não conferia antes.
  - **A tabela também muda:** as 8 versões da planilha publicadas desde 03/10/2025 (a 1.20, que estava publicada
    quando as regras entraram em produção) foram comparadas; as 100 mudanças estão em `mudancas_ibs_cbs`, com o prazo
    de produção do controle de versões do IT 2025.002 v1.71 (da 1.21 à 1.40 não há prazo lá; até o acervo inteiro,
    elas valiam até o prazo da 1.50, 04/05/2026, que já as traz, mas uma NF-e autorizada com a 200001 em 01/06/2026
    desmentiu isso; na revisão da etapa 4 passaram a valer até o prazo da versão mais nova que ainda traz o mesmo
    valor, hoje a 1.71, 30/10/2026, e a mudança que outra versão desfez, até o prazo de quem a desfez). A coluna
    DataAtualização da planilha não serve para isso: a 1.70 mexeu no texto das 170 linhas, e todas ficaram com
    01/10/2026. O robô refaz a comparação toda semana; a planilha nova que ainda não está em `PUBLICACOES_DA_REFORMA`
    (no `gerar_tabelas.R`) gera um aviso, e as mudanças dela ficam sem prazo até sair uma versão com prazo que ainda
    traga o valor (a conferência as trata como talvez não em produção). As 100 mudanças são da planilha de classificação (95 de classificação e 5 de CST); com as 3 da de
    crédito presumido, a tabela tem 103.
  - **Como fica:** o que não confere pela regra e pela tabela de hoje, numa nota emitida antes da mudança, vem com
    `confere` vazio e o motivo (para a tabela, "a SEFAZ conferiu" quando a nota é de antes da publicação e "pode ter
    conferido" entre a publicação e o prazo).
  - **Depois do primeiro commit (no mesmo dia), as que faltavam:**
    - a nota de débito e de crédito: UB14-60 a UB14-80 (a classificação e o tipo da nota, pela tabela que a NT dá
      dentro das regras), UB106-30/31/40 (transferência de crédito), UB112-30 e UB116-30 (ajuste e estorno com
      valor), UB131-40/50, UB132-10 e UB133-10 (o crédito presumido da ZFM); o mês "atual" da UB132-10 é o da
      autorização (o `dhRecbto` do protocolo; sem ele, o mês depois da emissão fica sem conferir: desde a revisão
      independente, que achou o caso da contingência);
    - a CBS zero na área incentivada: UB66a-10/20 (na v1.51 a ZFM entrou na lista da UB66a-20, o que só afrouxou a
      regra: sem marca de mudança, desde a revisão independente), UB66c-10 e UB66e-10 (que não diz tolerância: até o centavo, depois de arredondar o calculado);
    - o crédito presumido da operação: a tabela nova `credito_presumido_ibs_cbs` (a planilha de crédito presumido do
      IT, 13 códigos, publicada em 01/10/2026; as orientações de texto em colunas `orientacao_*`), com a história
      dela em `mudancas_ibs_cbs` (5 versões desde 03/10/2025; o link da de 07/10/2025 vem com espaço no lugar do
      "+" no portal), e as regras UB122-10, UB123-10/20, UB125-10, UB126-10, UB127-10/20, UB129-10 e UB130-10 (a
      UB123-10 e a UB127-10 perderam na v1.51 a exceção do bem móvel usado); a UB54a-10 passou a descontar o
      crédito presumido do IBS do item quando o código manda (`deduz_do_tributo`).
    Na amostra do acervo, nenhuma acusou nota autorizada (o acervo não tem crédito presumido nem CBS da ZFM: essas
    estão testadas com variações do XML de exemplo).
  - **O resto do passo 2, no mesmo dia** (pergunta do usuário: "tem certeza que não falta mais nada?"; depois, "então
    siga"). Eram duas faltas de regra (o monofásico e as regras da NT fora do grupo UB/W) e quatro de processo (o
    leitor sem as colunas da Reforma, o acervo inteiro, a revisão independente e o robô). As 239 regras estão em
    `inst/extdata/regras_ibs_cbs.csv` (eram 104).
    - **O monofásico de combustíveis**, no leiaute da v1.50 (produção em 16/11/2026; o 03/11 está riscado no
      cronograma): os grupos de cada ano (UB85a, UB90, UB95a e UB100: o IBS é ad valorem até 2028 e ad rem depois; a
      CBS, ad valorem em 2026 e ad rem depois; em homologação, as exceções da NT), os subgrupos que a classificação
      exige ou não permite (padrão, retenção, retido e diferença do biocombustível, pelos indicadores da planilha), as
      contas e os totais do `gMono` (W58-10 a W59d-10). Três leituras, cada uma com a fonte:
      - o `pBio` do XML é **percentual** (no acervo, 1.951 dos 1.980 valores passam de 1) e a mistura obrigatória da
        tabela nova `biocombustivel_ibs_cbs` (Tabela de Índice de Biocombustível, IT 2025.004) é **fração** (0,32): as
        contas usam pBio/100;
      - a NT não diz a unidade da alíquota ad valorem do monofásico: o valor que bate com a alíquota lida como
        percentual confere; o que não bate fica sem conferir, com o motivo;
      - a UB89b-10 e a UB99b-10 (o valor da diferença do biocombustível) usam uma tabela que a NT diz que ainda será
        publicada: ficam sempre sem conferir.
      Os 1.394 XML do acervo com monofásico são todos do leiaute antigo (de antes da v1.50): as regras novas não se
      aplicam a eles; estão testadas com variações do XML de exemplo.
    - **As regras da NT fora do UB e do W**, nos grupos B (previsão de entrega, documentos referenciados, nota de débito
      e de crédito, NFC-e, município do fato gerador do IBS e local da operação), BB (compra governamental: o tipo da
      operação, as alíquotas nos anos de transição e as chaves dos documentos anteriores), C e E (a inscrição na
      Suframa, com o dígito do MOC 7.0, seção 8.4), I, N, NA, Q e S (os tributos de cada item na nota de débito e de
      crédito, o CFOP da devolução, o ICMS e a origem, o ICMS da UF de destino, o PIS e a COFINS), LA (o grupo de
      combustível), VC (o documento referenciado no item) e W07/W31 (o total dos produtos e o do Imposto Seletivo).
      Tabelas novas: `local_operacao_ibs_cbs` (o cIndOp, do Anexo VII da documentação da NFS-e Nacional, a versão mais
      alta publicada; v1.03.00 hoje) e `combustiveis_monofasicos` (os do ICMS monofásico, Portal da NF-e). A tag do
      schema é `ISUFEmit` (a NT escreve ISUFemit; achado conferindo cada caminho contra o schema 010g). Ficam de fora as
      quatro que a SEFAZ confere no documento guardado na base dela (BB05-170, BB05-190, BB05-200 e VC02-50).
    - **Como na NT, só a nota com IBS, CBS ou IS é conferida** (nota ** do cronograma): as regras da nota toda (B, C,
      I, N...) também. A nota sem os tributos novos sai sem conferências.
    - **O `nfe_ler()` ganhou as colunas da Reforma que faltavam:** na nota, `previsao_entrega`, `tipo_nota_debito` e
      `tipo_nota_credito`, `local_operacao`, `municipio_fato_gerador_ibs`, `compra_governamental_ente`, `_redutor` e
      `_operacao`, `emitente_inscricao_suframa`, `destinatario_inscricao_suframa` e os totais do monofásico; no item,
      `credito_presumido_zfm_tipo`, `bem_movel_usado`, `valor_item`, `referenciado_chave`, `referenciado_item` e os
      totais do monofásico. O significado ao lado vem da documentação do schema (`tpNFDebito`, `tpNFCredito`,
      `tpEnteGov`, `tpOperGov` e `indBemMovelUsado`, 25 linhas novas em `codigos_dos_campos`; os 90 campos conferem
      contra os schemas). O `tpCredPresIBSZFM` fica sem significado: só a NT diz o que é cada valor, não o schema.
    - **Velocidade:** a primeira rodada no acervo levou 0,32 s por arquivo; dois terços eram montar um `data.frame` por
      regra e juntar com `rbind`. Agora cada regra devolve as colunas e a tabela é montada uma vez por arquivo
      (`juntar_linhas`): no acervo inteiro (12.561 arquivos, 5 itens por nota em média), 88 ms por arquivo na primeira
      rodada e 73 na segunda, e o resultado igual (os testes da conferência passaram sem mudança).
    - **O que a SEFAZ autorizou contra o texto da regra fica sem conferir, com o motivo** (amostra do acervo, 2.638
      NF-e autorizadas, 23 acusações, cada uma olhada só por códigos e contagens):
      - I05k-20 (19 itens, 9 notas): o `tpCredPresIBSZFM` 0 ("sem crédito presumido") em emitente fora da ZFM,
        autorizado de fevereiro a setembro de 2026. A regra (em produção desde 02/02/2026) diz "se informada", e a NT
        não diz se o 0 conta. O 0 fora da ZFM fica sem conferir; de 1 a 4, errado;
      - LA01-30 (1 nota de 02/02/2026): a classificação 620 sem o grupo `comb`. A NT adiou as regras do monofásico
        (v1.35), diz que as orientações dele virão em NT futura (pág. 7) e o reformulou na v1.50: antes de 16/11/2026,
        a 620 sem o grupo fica sem conferir; a 410013 sempre, e a 620 a partir de 16/11/2026, são conferidas;
      - W07-10 (2 notas de setembro de 2026): o total dos produtos 0,01 menor que a soma dos itens. A regra não dá
        tolerância e é obrigatória desde 03/08/2026 (v1.40): até o centavo confere, um centavo fica sem conferir e mais
        que isso não confere.
    - **O acervo inteiro** (só contagens na tela): dos 341.402 XML, 120.972 são NF-e e 12.561 têm IBS, CBS ou IS; 185
      deles são NFS-e de prefeitura que usam o nome `<NFe>` (ficam em `arquivos`, com o motivo). Nas 12.376 NF-e
      (todas modelo 55, de novembro de 2025 a outubro de 2026, 65.194 itens com IBS e CBS), 90 regras se aplicaram e
      deram 1.688.033 conferências: 5 erradas e 168 sem conferir, todas olhadas:
      - UB14-25 (4 itens de uma nota de 01/06/2026, a 200001 na NF-e): a 1.40 da tabela tirou a 200001 da NF-e e
        não tem prazo no IT; eu usava o prazo da 1.50 (04/05/2026). A nota autorizada desmente: as versões sem prazo
        no IT (1.21 a 1.40) ficam sem prazo conhecido, e a mudança delas, sem conferir. As duas notas de março do
        mesmo emitente já saíam sem conferir;
      - UB67-10 (1 item de uma nota de 16/03/2026): a CBS 0,02 acima do calculado. A NT dá tolerância de 0,01,
        escrita; continua errada pela NT (a SEFAZ que autorizou aceitou, ao menos nesse caso: 1 em 17.176 conferências
        da regra);
      - sem conferir, com o motivo: 151 I05k-20 (o 0), 9 LA01-30 (a 620 antes de 16/11/2026), 6 W07-10 (um centavo)
        e 2 UB14-25 (a 200001 em março).
      Depois da correção da 200001 e das da revisão independente (abaixo), a segunda rodada: 91 regras aplicadas (a
      VC02-14 entrou, e nenhuma devolução do acervo deixou de referenciar), 1.688.508 conferências, 1 errada (a UB67-10)
      e 172 sem conferir, todas com o motivo.
    - **Revisão independente** (um revisor com o código, a NT, o schema e o MOC, sem as minhas conclusões, com
      experimentos em XML variado): 8 achados dados como confirmados e 4 suspeitas. Cada um conferido na fonte antes
      de mexer:
      - **W34-10 e W34-20, erro meu da mesma tarde:** ao passar todos os itens da nota para as regras dos totais, a
        W34-10 deixou de acusar o `IBSCBSTot` sem item com IBSCBS, e a W34-20 acusava a nota só com o IS. Agora olham
        só os itens com IBSCBS (teste novo);
      - **VC02-14:** estava só desde 16/11/2026, mas a regra existe desde a v1.30 (é a da NT 2013/005, na lista que
        entrou em 10/11/2025); o que entra em 16/11/2026 é a redação da v1.53. Agora, até 15/11/2026, a devolução
        referencia um documento no cabeçalho (NF-e, NFC-e, NF modelo 1, de produtor ou ECF) ou no item, menos nos CFOP
        1201, 1202, 1410, 1411, 5921 e 6921; desde 16/11/2026, sem o `refNFe` no cabeçalho, cada item referencia, menos
        nos CFOP 5921 e 6921;
      - **a mesma nota duas vezes no arquivo derrubava a chamada** (`factor level duplicated`): agora é conferida uma
        vez;
      - **W07-10:** a redação da v1.40 soma só os itens com indTot 1 "sujeitos ao ICMS ou IBS/CBS/IS"; o serviço só com
        ISSQN, na nota conjugada, ficava na soma;
      - **UB66a-20:** a v1.51 só acrescentou a ZFM à lista (afrouxou): saiu a marca de mudança;
      - **UB13-20, falso:** o revisor leu na v1.30 o texto antigo, que lá está riscado (a v1.30 mostra o antigo
        riscado e o novo realçado; conferido na imagem da página 33). Desde 10/11/2025 vale o novo; nada a mudar;
      - **um `"\ufeff"` do `gerar_tabelas.R` virou o caractere invisível** quando desfiz os escapes do arquivo (as
        ferramentas guardam acento cru no código): voltou o escape;
      - **a ajuda:** o item vazio em todas as regras da nota, a linha por chave anterior na BB05 e o que acontece com
        a mudança que afrouxou a regra (vale para a nota de antes);
      - **suspeitas:** a UB56-10 valia pela alíquota da tabela, não pelo ano (quando o Senado publicar a CBS de 2027,
        as notas de 2027 cairiam na regra de 2026): agora a UB56-10 é de 2025 e 2026 e a UB56-20 de 2027 em diante,
        com a alíquota publicada ou só o zero obrigatório (teste com uma CBS de 2027 inventada); a UB132-10 passou ao
        mês da autorização; o `refNFeSig` (a chave com o código numérico zerado) passou a contar como chave onde a
        regra fala da NF referenciada (B25-50, B25-60 e a exceção 3 da NA01-20), e não onde a NT escreve `refNFe`
        (B25-100 e a VC02-14 nova). O Simples Nacional (CRT 1 e 4) segue as regras de alíquota ao pé da letra: a NT
        remete as orientações dele a uma NT futura e não dá exceção, e nenhuma nota autorizada do acervo foi acusada
        nelas.
    - **Fica de fora:** as regras que a NT deixa para implementação futura (as do Imposto Seletivo, a UB16-10, a
      UB13-40, a VC03-20 e outras) e as quatro que dependem da base da SEFAZ.
- **Passo 3, calcular e simular (pronto, 04/11/2026):** `ibs_cbs_calcular()`. Pedido do usuário: "siga se realmente
  tiver tudo ok"; a produção na SEFAZ continuou travada (não foi pedida com todas as letras). Decisão do usuário, entre
  o cálculo próprio, só a calculadora da Receita ou os dois: **cálculo próprio, conferido com a calculadora oficial**.
  - **As fontes:** as fórmulas da NT (as mesmas da conferência: alíquota efetiva em 4 casas, valor diferido, valor
    menos o diferido, tributação regular, IBS do item como soma); a base da UB16-10, que confere com o art. 12 da LC
    214/2025 (o texto do Planalto); e a calculadora oficial da Receita, o piloto da Reforma
    (`piloto-cbs.tributos.gov.br/servico/calculadora-consumo/api`, versão 1.6.2, base de regras V0066; a especificação
    OpenAPI está em `api-docs`). A Receita é que diz a vigência de cada componente da base
    (`/base-calculo/base-calculo-unificada` devolve o aviso de cada campo ignorado): o PIS e a COFINS só em 2026; o
    ICMS, o ICMS da UF de destino, o FCP e o ICMS monofásico de 2026 a 2032 e só no bem; o II só no bem; o ISSQN de
    2026 a 2032 e só no serviço; o Imposto Seletivo de 2027 a 2033. Por isso o cálculo cobre de 2025 (a NT aceita em
    2025 as regras de 2026) a 2033.
  - **O que a sondagem da calculadora mostrou** (itens inventados, um por pedido, com 4 s entre eles; o piloto barra
    rajadas): o diferimento da 510001 sai com 100% sem ser informado, mas a classificação oficial
    (`dados-abertos/classificacoes-tributarias`) não traz o percentual, nem a planilha do IT: no RNFe ele vem da nota
    ou de quem usa; a 830001 a calculadora "ainda não trata"; as classificações reduzidas de anexo recusam NCM fora do
    anexo (o RNFe não tem as listas dos anexos e não confere isso); em 2027 ela exige as alíquotas informadas
    (`aliquotasNominais`), como o RNFe, que tem o IBS de 2027 e 2028 mas não a CBS de referência.
  - **O gabarito:** 51 itens inventados (bases na beira do meio centavo e componentes sorteados com semente fixa), de
    000001, 200003, 200022, 200030, 200034, 200035, 200047, 410001, 510001, 515001 e 550001 (com NCMs que a própria
    Receita aceita em cada anexo, conferidos em `ncm-aplicavel`), em 2026, 2027 e 2030. A primeira comparação deu 30
    campos diferentes de 1.224:
    - o **arredondamento**: a calculadora manda o meio centavo para o par (0,125 vai a 0,12; 0,105 a 0,10), e o RNFe
      mandava para cima. A NT não diz e aceita 0,01; o cálculo passou a seguir a Receita, com a conta feita em
      inteiros, em pedaços de 6 dígitos (`valor_no_centavo_ao_par`), para o ponto flutuante não decidir o meio
      centavo. A conferência segue como estava (a tolerância cobre os dois);
    - **dois pontos em que o RNFe segue a NT**, que é o que a SEFAZ confere: a calculadora arredonda o IBS do item à
      parte, e em 3 itens ele saiu 0,01 diferente da soma da UF e do município (a UB54a-10 exige a soma); e na
      200022 (CST 200 com tributação regular) ela não traz o grupo de redução, que a UB26-20 exige quando o CST tem o
      indicador de redução.
    Depois disso, só esses dois pontos ficaram diferentes: a base, as alíquotas, a redução, o diferimento, a tributação
    regular e o valor de cada parte saíram iguais nos 51 itens.
  - **O acervo inteiro** (só contagens; 12.561 arquivos em 146 s, 12 ms por arquivo): nas 12.376 NF-e, 65.336 itens,
    62.678 calculados; os outros são do monofásico (2.516) ou não têm o grupo da Reforma (142).
    - A base pelos componentes bateu com o `vBC` da nota em 14.453 dos 17.176 itens com o grupo. Nos 2.723 diferentes,
      1.631 têm o `vBC` igual ao valor do produto menos o desconto, sem tirar os tributos: a UB16-10 ainda é
      "implementação futura, aguardando orientação normativa", e nem todo emitente a segue.
    - Com a base da própria nota, o IBS calculado bateu nos 17.176 itens e a CBS em 17.175 (a que não bate é a nota
      de 0,02 que a conferência acusa). No centavo exato, 16.860 com o meio centavo indo para o par e 16.901 com ele
      indo para cima, que é o que a maioria dos emissores faz; a diferença é de 0,01, dentro do que a SEFAZ aceita.
  - **Fica sem calcular, com o motivo:** o monofásico (CST 620), a transferência de crédito, os ajustes e a tributação
    em documento específico (CST 800 a 820), a exclusão da base (CST 830), as alíquotas fixas e uniformes (CST 010,
    011, 220, 221 e 222), a compra governamental (o redutor de cada ente e ano está na calculadora oficial, em
    `dados-abertos/redutores-compra-governamental`, mas não nas tabelas do RNFe), o crédito presumido, a devolução de
    tributos e o Imposto Seletivo.
  - **O `nfe_ler()` ganhou** os quatro componentes da base que faltavam no item (`valor_icms_monofasico`,
    `valor_icms_uf_destino`, `valor_fcp_uf_destino` e `valor_issqn`). Na revisão da etapa 4, o cálculo passou a
    pedir o resultado inteiro do `nfe_ler()` (a lista), não só os itens: a data, a finalidade e a compra
    governamental estão nas notas.

## Revisão da etapa 4 (05/11/2026)

- **Pedido do usuário:** "siga com isso", tudo na ordem, cada etapa revisada antes da seguinte. As mesmas quatro
  frentes da revisão das etapas 1 a 3: o plano contra o pacote, os robôs do GitHub, o acervo do Fiscal inteiro e uma
  revisão independente (dois revisores, um do cálculo e um das tabelas e da conferência, com o código, a NT, a LC
  214/2025 e as planilhas oficiais, sem as minhas conclusões, com experimentos rodados).
- **Os robôs:** o das tabelas rodou sem mudança. O vigia achou quatro publicações de 04/11/2026 no portal do CT-e: os
  schemas do CT-e da NT 2026.004 v1.01 e da NT 2026.005 (Simples Nacional) v1.00, e os do BP-e das mesmas duas notas.
  O BP-e o RNFe não lê. O pacote do CT-e da NT 2026.005 contém tudo o da 2026.004 v1.01 e traz: a referência ao CT-e
  da multa e dos juros (`gMultaJuros/chCTeRef`, no CT-e, no CT-e OS e no simplificado), o IBS e a CBS do Simples
  Nacional (`gTribSN`, no imposto do CT-e e do CT-e OS e na entrega e no total do simplificado) e os eventos 412140 e
  412141 (a tributação do Simples Nacional e o cancelamento dela). A GTV-e não mudou. Os leitores passaram ao pacote
  novo: as colunas `*_simples_nacional` e o `chCTeRef` nos documentos. No acervo, os 15.078 CT-e e as 285 GTV-e
  continuam lidos sem aviso; nenhum tem os grupos novos ainda.
- **O plano contra o pacote:** o texto de `tabela_fiscal()` e do README dizia que toda tabela tem `inicio` e `fim`
  (não valia para o local da operação, as mudanças, o crédito presumido e as alíquotas, e o CST do IBS e da CBS tem as
  duas vazias); e que a CBS de 2027 em diante é a de referência menos 0,1 ponto (o art. 347 só vale em 2027 e 2028).
  Corrigidos, com o que a tabela tem de fato. No plano, a contagem das mudanças (100 da classificação, 103 com o
  crédito presumido) e a UB66a-20 (a v1.51 só afrouxou a regra).
- **A revisão do cálculo achou, e foi corrigido** (cada um com teste):
  - o item com crédito presumido da operação (`gCredPresOper`) ou com devolução de tributos (`gDevTrib`) saía
    calculado, com o valor sem eles: agora fica sem calcular, com o motivo. A devolução só quando o valor não é zero
    (achado no acervo: os 167 itens com o grupo trazem todos 0,00, e o `vDevTrib` só é subtraído do valor, UB35-10,
    UB54-10 e UB67-10);
  - a nota que não é normal (a devolução, a complementar, a de ajuste e as de crédito e de débito) saía calculada como
    venda: na devolução a base é a da operação original (art. 12, § 7º); agora fica sem calcular;
  - pelo `nfe_ler()$itens`, o cálculo perdia a data, o modelo, a finalidade, a compra governamental e o diferimento:
    agora pede a lista inteira do `nfe_ler()` (e recusa só os itens, com a explicação), e o `nfe_ler()` passou a trazer
    o diferimento, a devolução de tributos, a tributação regular e o código do crédito presumido de cada item;
  - no `data.frame`, a coluna de número como fator ou como texto com vírgula virava outro número sem aviso; a data com
    hora em UTC mudava de dia; `data = 2027` passava; a alíquota infinita passava. Agora são recusados, e a data com
    hora vale no horário de Brasília;
  - a mesma nota em dois arquivos dobrava os totais; a base negativa saía com valor negativo (a calculadora oficial a
    recusa); a NFC-e somava o II e o ICMS da UF de destino (a calculadora só os aceita na NF-e); a isenção e a
    imunidade com compra governamental saíam sem calcular; o item sem data não dizia o motivo;
  - os nomes `ibs_mun` passaram a `ibs_municipio`, como no `nfe_ler()` e nas tabelas.
- **A revisão das tabelas e da conferência achou, e foi corrigido:**
  - as mudanças das versões sem prazo no IT (1.21 a 1.40) ficavam sem conferir para sempre (uma NF-e de 2027 com a
    200001 sairia "a SEFAZ pode ter conferido pela versão anterior"). O prazo da primeira versão com prazo, a 1.50, já
    tinha sido desmentido pela NF-e autorizada em 01/06/2026; passou a valer o da versão mais nova que ainda traz o
    mesmo valor (hoje a 1.71, 30/10/2026). E, achado meu ao conferir as tabelas refeitas, a mudança que outra versão
    desfez antes de alguma com prazo (o 000002 na NFGas entrou na 1.30 e saiu na 1.31) vale até o prazo de quem a
    desfez;
  - de 2029 em diante, a UB18-10, a UB37-10 e a UB56-20 sumiam sem linha nem motivo: agora vêm sem conferir, "a
    alíquota do ano, a ser publicada";
  - a NF-e avulsa referenciada (série 890 a 899) tirava a B25-50 e a B25-60 caladas: a chave dela traz o CNPJ do
    Fisco, então a B25-50 fica sem conferir com o motivo, e a B25-60 vale (a UF da chave é a verdadeira);
  - a exceção 3 da NA01-20 (devolução de NF-e anterior a 2016) só olhava o cabeçalho, e contava a NF modelo 1 e a
    de produtor; agora olha também a chave referenciada no item, e só a NF-e;
  - a VC02-14 entre a publicação da v1.53 (30/10/2026) e 15/11/2026: a SEFAZ podia aplicar a redação antiga ou a nova;
    onde elas discordam, fica sem conferir;
  - no gerador: os números da planilha de crédito presumido em notação científica (7.0000000000000007E-2 virou 0.07);
    o código da classificação lido como número; a planilha mais nova escolhida pela ordem da página (agora pela data
    "Publicada em"); o Anexo VII da Produção Restrita podendo entrar no lugar do de produção.
- **Achado meu na revisão:** no `data.frame` sem a coluna `servico`, todo item com `valor_issqn` preenchido virava
  serviço, também com zero (uma planilha com a coluna zerada perdia o II e o ICMS da base). Agora só o ISSQN acima de
  zero; pela lista do `nfe_ler()`, a presença do grupo ISSQN, como no XML.
- **O gabarito da calculadora oficial**, de novo com o cálculo refeito: os mesmos 51 itens, só as duas diferenças em
  que o RNFe segue a NT (o grupo de redução da 200022 e o IBS do item como soma).
- **O acervo inteiro, de novo** (só contagens): a conferência deu o mesmo de antes (1.688.508 conferências, 1 errada,
  a UB67-10 de 0,02, e 172 sem conferir, todas com o motivo; as 6 da 200001 continuam "pode ter conferido", agora com
  o prazo de 30/10/2026). No cálculo, a mesma nota em mais de um arquivo passou a contar uma vez: 63.150 itens (eram
  65.336 com as repetições), 55.668 calculados; ficam sem calcular 4.956 de nota que não é normal (4.947 de
  devolução), 2.384 do monofásico e 142 sem o grupo da Reforma. Pela lista do `nfe_ler()` e pelos arquivos, o mesmo
  resultado. Com a base da própria nota, nos 15.816 itens calculados com o grupo e as alíquotas de 2026, o IBS bateu
  (até 0,01) em todos e a CBS em todos menos um (a nota de 0,02).
- **A máquina local passou a barrar o R:** em 05/11/2026 o Controle Inteligente de Aplicativos do Windows (ligado,
  `VerifiedAndReputablePolicyState` 1) começou a barrar as DLLs sem assinatura de vários pacotes (curl, testthat,
  roxygen2, knitr, processx); o xml2 e o pkgload carregam. Desligar o antivírus não muda isso. Por isso as tabelas
  foram refeitas pelo robô num ramo temporário, e a ajuda, os testes e o R CMD check rodaram no GitHub, num ramo
  temporário com um robô só para ele (2.537 conferências, nenhuma falha; check sem NOTE, no Linux). O acervo e o
  gabarito rodaram aqui, pelo `load_all()`. Isso pesa na última etapa (a emissão em homologação precisa do curl
  local): é decisão do usuário.

## Etapa 5, primeiro passo: a leitura da EFD ICMS/IPI (05/11/2026)

- **O pedido:** a etapa 5 do plano ("ler o SPED; pré-conferência"). O usuário perguntou se o SPED "tem na SEFAZ": não;
  é o arquivo que a empresa gera todo mês e transmite pelo programa da Receita (a SEFAZ recebe uma cópia, mas não tem
  serviço para consultar ou baixar). Ler é só abrir o arquivo; nada é enviado ("se tiver algo como só homologação ou
  teste, tudo bem"). Decisões do usuário: as colunas com os **nomes do leiaute** (REG, COD_PART, VL_DOC...), não nomes
  descritivos; a conferência com arquivos reais **depois** (os SPED do Fiscal ficam no servidor; a pasta local está
  vazia): por enquanto, arquivos inventados.
- **As fontes:** o Guia Prático da EFD ICMS/IPI 3.2.2 (11/02/2026) e a Nota Técnica 2025.001 v1.0 (leiaute 020), do
  portal do SPED (`sped.rfb.gov.br`, "Manuais e Guias Práticos"). As duas trazem a tabela de campos de cada registro,
  em PDF. O programa validador da Receita (o PVA) não foi aberto por dentro: a licença dele limita o uso ao fim a que
  se destina (validar a escrituração).
- **Como o leiaute foi montado** (`ferramentas/gerar_leiaute_efd.py`): o PDF quebra as linhas das tabelas de jeitos
  diferentes, e o nome longo quebra na coluna estreita ("COD_MU" e "N"). Cada documento é lido duas vezes, pelo texto
  corrido e pelas linhas e colunas da tabela (a faixa entre duas linhas horizontais que cruzam a coluna Nº é um campo,
  porque o número fica centralizado na célula, às vezes abaixo do nome), e cada coluna de cada campo sai da votação
  das quatro leituras; o nome que o texto do Guia escreve por extenso ("Campo 06 (COD_MOT_REST_COMPL)", 1.645 campos)
  vale mais que o cortado. O que a votação não decide está em `ferramentas/leiaute_efd_decisoes.csv`, com o motivo, e
  a ferramenta não grava enquanto houver campo sem decisão. Achados no caminho:
  - a Nota Técnica não traz o campo 16 do C100 (VL_MERC) nem as tabelas do 1250, do 1255 e do D990, e se contradiz
    no nível do K275 (4 na tabela de registros, 5 na seção dele; o Guia diz 4 nos dois lugares);
  - os nomes oficiais têm acento e minúscula (CHV_DOCe, NÍVEL, DT_SAÍDA, VL_RETENÇAO_ST): ficam como estão;
  - divergências de verdade entre os dois documentos, decididas pelo Guia (o mais novo): o tipo do NUM_DOC do C350,
    do IND_PROC do E312 e da SER do D700; o tamanho do COD_ITEM do 1300 e do IND_MOV do H001; o nome do campo 03 do
    C120 (NUM_DOC_IMP no Guia, NUM_DOC__IMP na NT). O histórico do Guia chama o campo 27 do C176 de VL_UNIT_RES_FCP e
    as duas tabelas de VL_UNIT_RES_FCP_ST: vale o das tabelas;
  - o C170 tem dois campos com o mesmo nome (ALIQ_PIS, em percentual e em reais; o mesmo com a COFINS): na leitura,
    cada um leva o número do campo (`ALIQ_PIS_27`, `ALIQ_PIS_29`).
  Resultado: 270 registros e 2.225 campos, em `tabela_fiscal("leiaute_efd_icms_ipi")` (está nas tabelas fiscais, com
  a lista de conferência; o `tabelas_atualizar()` também o traz).
- **A vigência:** o título do registro diz as versões que mudaram inteiras (o E310 até 2016 e desde 2017, o C177 até
  2018 e desde 2019; o 0210 e o 1600 valeram até 2021), e o Capítulo II do Guia lista os registros e os campos
  incluídos em cada ano desde 2010 (114 registros e 71 campos; o de 2012 vem em prosa, e o título do período às vezes
  quebra a linha antes do ano). **Todo campo incluído ocupa o fim do registro** (a ferramenta confere): por isso um
  arquivo antigo é lido pela posição, com o leiaute do período dele (o `DT_INI` do 0000).
- **Os tipos:** só o campo N com casas decimais vira número; todo `DT_` vira data (ddmmaaaa: há `DT_` sem o `*` no
  bloco K e um C no 1391); o resto fica texto. A regra "N sem tamanho exato vira número" foi descartada ao olhar a
  lista: estragaria a chave do CF-e (44 dígitos), o CNPJ ou CPF com zero à esquerda, o TIPO_ITEM ("00"), o COD_SIT
  e o NUM_AUT.
- **O leitor** (`efd_icms_ipi_ler(arquivos, registros)`): uma tabela por registro, com `arquivo`, `linha` e
  `linha_pai` (a última linha antes, com o nível um a menos: liga o C170 ao C100), e as tabelas `arquivos` e
  `problemas` (a linha fora do formato, o registro que o leiaute do período não tem, o número de campos diferente, o
  valor de número ou de data fora do formato, que fica `NA`). O arquivo em Latin-1 (o do leiaute), em Windows-1252
  ou em UTF-8; a assinatura do PVA depois do 9999, com bytes nulos, é cortada antes de virar texto. Erro meu achado
  no primeiro teste: o corte procurava o primeiro "|9999|", que está no 9900 que o conta; agora é a linha que começa
  por ele. 77 linhas do exemplo em 0,17 s.
- **O exemplo** (`inst/exemplos/efd_icms_ipi_sp.txt`, `ferramentas/gerar_efd_de_exemplo.py`): outubro de 2026, a
  empresa fictícia da NF-e de exemplo, com a venda da nota 1001 do `nfe_proc_sp.xml` (C100 e C190), uma compra com o
  item (C170), as apurações do ICMS e do IPI e as contagens dos blocos e do bloco 9, montado pelos nomes do leiaute e
  conferido no número de campos; em Latin-1, com CR LF.
- **Testes:** 63 conferências da leitura (o exemplo, os tipos, a hierarquia, as contagens do bloco 9, um arquivo de
  2016, a assinatura, o UTF-8 e cada problema); a suíte inteira, 2.602, sem falha, e o R CMD check sem NOTE, no
  GitHub (a máquina local não carrega o testthat).
- **Em aberto:** a conferência com arquivos reais (quando o usuário copiar alguns do servidor); validar o exemplo no
  PVA (o uso para que ele serve, mas é instalar um programa da Receita: só com o usuário). Os próximos passos da
  etapa: cruzar a EFD com as NF-e (a nota que falta, o valor ou a situação diferentes), a EFD-Contribuições (o mesmo
  formato, outro leiaute) e a pré-conferência da NF-e.

## Etapa 5, segundo passo: a EFD contra as NF-e (05/11/2026)

- **Pedido do usuário:** "já vai fazendo logo tudo e só fale quando finalizar e tiver tudo ok" (o resto do plano,
  sem relatórios no meio; ele testa as funções no fim).
- **`efd_icms_ipi_cruzar_nfe(efd, notas, eventos)`:** cada C100 dos modelos 55 e 65 com o XML dela, pela chave, e as
  notas do contribuinte do 0000 (emitente ou destinatário) emitidas no período e fora do C100. Compara o modelo, a
  série, o número, a data, o valor do documento, o desconto, as mercadorias, o frete, o seguro e as outras despesas;
  na emissão própria, também as bases e os valores do ICMS, do ICMS-ST, do IPI, do PIS e da COFINS (na nota de
  terceiros, o Guia Prático manda informar só o crédito do declarante: não se comparam); o `IND_EMIT` contra o
  emitente, o `IND_OPER` contra o `tpNF` na emissão própria, o participante (o CNPJ ou CPF do 0150) contra o outro
  lado da nota e, com os eventos, a situação (o cancelamento 110111 contra o `COD_SIT` 02 ou 03). A nota cancelada,
  denegada ou inutilizada na EFD só traz a identificação, e só ela se compara. A nota de terceiros que falta pode ter
  entrado em outro período (vem com a observação); a de terceiros cancelada não é escriturada.
- **A EFD-Contribuições ficou de fora** (não estava no pedido; era sugestão minha no passo 1): o Guia Prático dela é
  de 18/06/2021 (versão 1.35), a mudança de leiaute de 2025 está só na NT 010/2025, em Word, e a NT 011/2026 diz que
  ela deixa de ser usada para fatos geradores a partir de 2027 (o PIS e a COFINS acabam). Montar o leiaute de 2025
  sobre um guia de 2021 não teria a mesma certeza do da EFD ICMS/IPI. Fica para o usuário decidir.

## Etapa 5, terceiro passo: a pré-conferência da NF-e (05/11/2026)

- **`nfe_conferir(arquivos, agora, todas_as_regras)`:** a NF-e e a NFC-e como a SEFAZ confere ao receber. O schema é
  o do pacote de liberação mais novo do Portal (PL_010g v1.03, de 26/10/2026), copiado para `inst/schemas/nfe` (os
  cinco arquivos da pasta NFe; 456 KB). Cada NFe do arquivo vira um documento só dela antes de validar
  (`xml_new_root`, que leva o namespace), e o erro de assinatura que falta não conta: a nota pode ainda não estar
  assinada. As regras vêm de `inst/extdata/regras_nfe.csv` (247 regras: código, mensagem, aplicação, fonte e as
  datas), escritas em `R/nfe_conferir_regras.R`, um grupo do Anexo I por função; as da Reforma vêm de
  `ibs_cbs_conferir()`, na mesma tabela (a B25b-20, que as duas têm, fica com a redação da NT 2026.002).
- **As fontes:** o Anexo I do MOC 7.0 (466 regras, de 2020) e as notas técnicas da NF-e publicadas de 2020 em diante
  (190 PDF, a versão mais nova de cada uma), baixadas do Portal. Para cada regra escolhida, a redação vale a da nota
  técnica mais nova que a traz como linha de tabela.
- **O texto riscado:** as notas técnicas marcam o que sai com o texto riscado, que a extração do PDF não mostra. Por
  isso cada regra que alguma nota técnica mudou foi conferida na imagem da página. Mudou o que vinha do texto: a
  C02a-04 (NFC-e de emitente CPF) saiu na NT 2022.003; a BA06-10, a BA13-10 e a BA14-10 saíram na NT 2026.002, e a
  BA03-10, a BA10-10 e a BA20-30 passaram a proibir a NF modelo 1 e 2, a de produtor e o cupom fiscal (05/10/2026); a
  X03-10 e a X03-20 saíram na NT 2023.004; na B26-10 e na B26-20 a parte do PAA foi riscada (vale a B26-24, da
  SVRS); a B25c-10 tirou o indPres 1; a W16-40 a W16-60 voltaram a ser só da NFC-e; na W16-10, a exceção 3 saiu e a 4
  ficou, e no faturamento direto de veículos o ICMS monofásico com retenção saiu da conta; o B03-10 e o BA20-30
  deixaram de valer para a NFC-e.
- **O que ficou de fora:** o que a SEFAZ confere na base dela (cadastro, duplicidade, a nota referenciada, o CCC e a
  LCC), o cálculo da inscrição estadual de cada UF, as tabelas de cada UF (benefício fiscal, GTIN do CCG, limite da
  NFC-e de cada UF além do padrão), o país do Banco Central, os prazos que dependem de parâmetro da UF e as regras com
  "implementação futura" (a G01-10, a YA03-10 na NF-e). A B28-40 (a data de entrada em contingência) ficou de fora
  porque a redação não diz em que sentido conta os 30 dias. Onde a NT 2026.002 deixa a regra em dúvida para a NF-e com
  DANFE Simplificado Tipo 2 (a E01-10, a E04-10 e a E05-10, que ela não mudou), a regra fica sem conferir com o motivo.
- **As datas:** cada regra tem `em_producao_desde` (a que entrou depois, como as do PAA, 05/10/2026, e as da NT
  2026.007, 16/11/2026), `em_producao_ate` (a C17-10, até 15/11/2026) e `mudou_em_producao_em` (a YA03-30, que passou a
  valer para o tPag 91 em 03/11/2025): a nota de antes da mudança que não confere pela redação de hoje fica sem
  conferir, com o motivo.
- **O acervo:** 4.200 NF-e autorizadas (300 de cada pasta, de todas as UF, 2021 a 2026), só contagens. Corrigido pelo
  que apareceu: a B10-40 compara as datas, não as horas (há saída minutos antes da emissão, no mesmo dia); o B03-10
  compara o cNF com o nNF como texto (há NF-e com o cNF 00000856 e o nNF 856); o CNPJ vazio da retirada e da entrega
  (o leiaute aceita) não é "informado"; a BA02-30 e a BA02-40 só valem para a chave da NF-e e da NFC-e (a do CF-e é
  montada de outro jeito); o NCM de nota de antes de 01/04/2022 (o começo da tabela) fica sem conferir; o tPag e a
  bandeira só precisam estar na tabela (o início das linhas é o da descrição de hoje: o 05 e o 17 já existiam); o
  troco zero com o pagamento abaixo do total é a YA03-10, não a YA09-10; a IE ISENTO do transportador não pede a UF;
  depois de 30 dias de atraso a rejeição é escolha da UF (B09-20 sem conferir); a E16a-30 na operação interna fica
  sem conferir (PE autorizou). Ficaram acusando erro em nota autorizada as facultativas e as que nem toda SEFAZ
  aplica, com a observação dizendo isso (B25c-10 em SP, X05-10 no RN, Y01-20 no RJ, Y06-10 no PI, Y08-10 no AM,
  I03-30 e I12-60 em SP, I08-160 em AL e MG). Erro meu achado nos testes: o dígito da chave era comparado com `%in%`
  (contra todos os dígitos da tabela, não o da linha).
- **O schema e as notas antigas:** o PL_010g mudou o grupo do monofásico da Reforma (o `gMonoPadrao` e o `gMonoRet`
  saíram para os grupos ad rem e ad valorem). A nota emitida no leiaute anterior acusa erro de schema aqui, e a
  `descANP` mudou de padrão. Para a nota nova, vale o pacote mais novo; para a antiga, o erro de schema pode ser só a
  versão do leiaute.
- **Achado para a revisão da etapa 5:** a NT 2026.002 usa o código VC02-40 para outra regra (o modelo da chave
  referenciada no item, 679, em 14/12/2026) que a NT 2025.002 (o emitente igual em todos os itens, 1193): a
  `ibs_cbs_conferir()` tem a da NT 2025.002.
- **Tempo:** perto de 10 ms por nota na leitura e nas regras, 30 ms no schema e 30 ms nas regras da Reforma (que
  monta um `data.frame` por arquivo); a primeira leitura de muitos arquivos pequenos no Windows é mais lenta.

## Revisão da etapa 5 (05/11/2026)

- **Como:** uma revisão independente (um agente para a NF-e e outro para a EFD), que leu o código, o CSV das regras e
  as fontes e rodou cada achado com XML e EFD inventados. Cada achado foi conferido de novo na fonte antes de mudar
  alguma coisa; o texto riscado, na imagem da página.
- **O que mudou na pré-conferência:**
  - a mesma nota em dois arquivos (o XML assinado e o `nfeProc`) derrubava o `nfe_conferir` (o fator com a chave
    repetida): cada chave é conferida uma vez, a do primeiro arquivo com o protocolo, também no schema;
  - as regras da Reforma saem da mesma leitura do arquivo (eram três leituras; são duas, porque o schema precisa do
    namespace que a leitura das regras tira) e recebem o momento do envio: a UB132-10 da nota sem protocolo usa o mês
    do envio;
  - a VC02-04 vale também para a NF-e com DANFE Simplificado Tipo 2 (NT 2026.002 v1.11, pág. 18, que tirou a VC02-50);
  - as datas que faltavam: as regras criadas pela NT 2019.001 (B03-10, E03a-30, E14-30, E16a-40 e H02-10) valem
    desde 02/09/2019 (a produção da v1.00); a N12-30, a N12a-20 e a ZX02-10, desde 01/04/2016 (a exceção delas); a
    C17-42 vale até 2032 ("não se aplica a partir de 2033", NT 2026.007);
  - 17 regras que dá para conferir só com o XML e faltavam: B22-34, I23d-10, I23d-20, I23d1-10, I23e-10, N12-10,
    N12a-81, N12a-91, N28-12, NA09-10, NA09-20, W16-30, YA03a-10, YA04-10, YA05-10, ZX02-220 e ZX02-228 (266 regras
    no CSV). A YA04-10 e a YA05-10 passaram a obrigatórias na NT 2025.001 v1.00 (01/09/2025): a nota de antes que não
    confere fica sem conferir, com o motivo;
  - cada valor passado a uma regra vem um só ou um por linha (`linhas_da_regra` para com erro): pega o vetor da nota
    passado a uma regra do item, a mesma família do erro do `%in%`;
  - o primeiro teste usava a hora do relógio e falharia a partir de 20/11/2026.
- **O que a revisão apontou e ficou como estava, com o motivo:**
  - a W16-40 a W16-60 para a NF-e com DANFE Simplificado: na imagem da pág. 19 da NT 2026.002 v1.11, o "55/" e o
    "ou NF-e com DANFE Simplificado Tipo 2" estão riscados (o texto copiado do PDF não mostra o risco);
  - o B03-10 comparando o cNF e o nNF como número: há NF-e autorizada com o cNF 00000856 e o nNF 856 (agora com teste);
  - a IE ISENTO do transportador (X07-10) e o troco zero com o pagamento abaixo do total (YA09-10): ganharam a
    observação no CSV e o comentário no código;
  - a W16-10 aceita a conta antiga do faturamento direto de veículos: a NT 2023.004 tirou o monofásico com retenção
    sem dizer desde quando, e a regra é facultativa (o comentário, que dizia "as duas formas são aceitas", foi
    corrigido).
- **Ainda de fora**, com muitas exceções por CFOP, código ANP e região: N12-70, N12-80, N16-20, NA01-30 e NA09-30 (do
  Anexo I). A UB12-11 (NT 2026.007) e a BA02a-50 não foram olhadas.
- **No cruzamento da EFD** (Guia Prático 3.2.2, registros C100 e C190):
  - o PIS e a COFINS vazios (de quem entrega a EFD-Contribuições) não se comparam;
  - na NFC-e, o C100 não traz o ICMS-ST, o IPI, o PIS e a COFINS (exceção 9);
  - o ICMS do C100 é comparado com o vICMS mais o vFCP, e o ICMS-ST com o vST mais o vFCPST (o C190 inclui o FCP);
  - os impostos não se comparam em toda entrada (`IND_OPER` 0), não só na de terceiros;
  - na complementar (06, 07) e na de regime especial (08), os valores vazios não se comparam (exceções 3 e 4);
  - a emissão própria denegada não é cobrada (deixou de ser obrigatória em 01/12/2021), nem a NFC-e recebida ("as
    NFC-e não devem ser escrituradas nas entradas"); o XML sem protocolo é cobrado, com o aviso;
  - o cancelamento por substituição (110112, MOC 7.0) também cancela;
  - de 2027 em diante, o valor do documento confere com o `vNF` ou com o `vNFTot` (o campo 12 do C100: em 2026, sem o
    IBS, a CBS e o IS);
  - o cruzamento ficou vetorizado: 20.000 notas em 1 s (o laço nota a nota levava uns 8 ms por nota);
  - a leitura aceita o UTF-8 com BOM, e a coluna que um arquivo antigo não tem vem com o tipo das outras (uma data
    vazia não vira número no `rbind`).
- **No acervo depois da revisão:** outra amostra de 4.200 NF-e autorizadas. As regras novas não acusaram nenhuma; a
  E16a-30 (do PR para AL, 2026) e a E16a-40 (RN, 2023) acusaram uma nota cada, e ganharam a observação de que nem toda
  SEFAZ aplica.
- **Testes:** 2.828 no GitHub, sem falha, e o R CMD check sem nota.

## Última etapa, primeiro passo: assinatura, autorização e eventos (05/11/2026)

- **Tudo em homologação** (decisão do usuário: "fique à vontade para usar os certificados desde que use em ambiente de
  homologação e nada em produção ainda"). A produção é recusada antes de montar qualquer coisa.
- **`xml_assinar()`:** a canonicalização C14N 1.0 é feita pelo RNFe (o `xml2` não tem); conferida com 1.000 NF-e reais
  (o mesmo resumo e a assinatura verificada em todas) e com o PyNFe 0.6.5, que assina o mesmo XML igual, byte a byte.
  O `xml2` devolve as declarações de namespace como atributos: elas saem da forma canônica (o erro que fazia 299 de
  1.000 resumos não baterem). A DPS da NFS-e Nacional usa o SHA-256; o resto, o SHA-1.
- **`sefaz_autorizar()`:** uma nota por lote, síncrono; se a SEFAZ responde 103, o recibo é consultado até a resposta.
  A nota autorizada volta no `nfeProc`.
- **Eventos da NF-e:** cancelamento, carta de correção e manifestação (no Ambiente Nacional, órgão 91), com o
  `procEventoNFe` de volta. O evento sai sem quebra de linha no fim (a SEFAZ rejeitou com o 588).
- **Testado na SVRS em 05/11/2026** com o certificado de uma empresa do RJ: NF-e autorizada (100), carta de correção e
  cancelamento (135), ciência (136). As rejeições do caminho: 434 (o intermediador, que a pré-conferência já
  acusava), 203 (a empresa do CE não está habilitada na homologação do CE), 543 (o CPF zerado do transportador, que a
  pré-conferência acusava), 900 (o vencimento antes da emissão: entraram a Y09-20 e a Y09-30) e 575 na manifestação
  (o autor tem de ser o destinatário: a nota foi emitida para a própria empresa).
- **`nfce_qrcode()`:** o QR-Code da versão 3 (NT 2025.001 e o Manual do DANFE NFC-e 6.0), sem o CSC; na contingência
  off-line, o dia, o valor, o destinatário e a assinatura RSA-SHA1 deles com o certificado. Os endereços da UF vêm de
  quem usa (a página do Portal da NFC-e não tem uma lista que dê para ler sem erro). O resultado valida no schema.
- **`sefaz_cte_desacordo()` e `sefaz_cte_cancelar_desacordo()`:** os eventos 610110 e 610111 do tomador, pelo MOC
  do CT-e 4.00 on-line (o evento vai sozinho, sem lote e sem compactação; o `nSeqEvento` com 3 algarismos no Id). O
  órgão é a UF da chave: testado na SVRS em 05/11/2026 com um CT-e inventado, voltou 217 ("CT-e não consta na base
  de dados"), depois da regra do órgão de recepção (677).
- **A inutilização não entrou:** a NT 2023.002 v1.02 acaba com o serviço em 11/11/2026.
- **MDF-e (`sefaz_mdfe_autorizar`, `sefaz_mdfe_encerrar`, `sefaz_mdfe_incluir_condutor`):** pelo MOC do MDF-e 3.00b
  (Anexo XII, no Confaz): a recepção é síncrona, sem lote, com o MDF-e em gzip dentro do base64; os eventos vão em XML
  sem compactação; o cabeçalho SOAP foi descontinuado e não vai; o Id do evento leva o `nSeqEvento` com 2 algarismos.
  O QR-Code (`infMDFeSupl`) entra sozinho quando falta, com o endereço da SVRS. Testado na SVRS em 05/11/2026 com o
  certificado da empresa do RJ: um MDF-e de carga própria dentro da UF, levando a NF-e autorizada no teste, foi
  autorizado (100; antes, o cavalo mecânico sem reboque voltou 523), ganhou um condutor e foi encerrado (135 nos dois).
- **NFS-e Nacional (`nfse_emitir`, `nfse_cancelar`):** pela especificação OpenAPI da Sefin (`POST /nfse` com o
  `dpsXmlGZipB64`; `POST /nfse/{chave}/eventos` com o `pedidoRegistroEventoXmlGZipB64`). A DPS e o pedido vão
  assinados com o SHA-256 (no acervo, a Sefin aceitou os dois algoritmos) e com a declaração do XML: sem ela, a Sefin
  rejeita com o E1229. As mensagens de erro vieram com a inicial maiúscula (`Codigo`, `Descricao`), não como na
  especificação; o RNFe lê as duas formas. Testado na Produção Restrita em 05/11/2026: uma DPS montada sobre uma nota
  real da empresa (só localmente) gerou a NFS-e (201) e o cancelamento foi registrado (201). No caminho: a Produção
  Restrita já valida pelo leiaute da NT 009 (o XSD de 20/10/2026: o `finNFSe` no `infDPS`, o `cNBS` antes da
  descrição do serviço), que o vigia não pegou (a página da RTC devolve "Conteúdo Restrito"); a cópia do XSD veio do
  repositório t3wv/nfse. A série 70000 (a do Emissor Nacional) voltou E0010 para a DPS de sistema próprio, e a 1 passou.
  O `nfse_ler()` segue o pacote 1.01 de 09/02/2026 e leu a NFS-e gerada; a NT 009 fica para a etapa da NFS-e.
- **O vigia das notas técnicas** (`ferramentas/vigiar_notas_tecnicas.R`, no mesmo robô dos schemas): abre um aviso
  para cada nota técnica nova no Portal da NF-e, que pode mudar as regras da pré-conferência. As 326 que o portal
  listava em 05/11/2026 estão em `ferramentas/notas_tecnicas_vistas.csv`.

## Última etapa, segundo passo: os PDFs (05/11/2026)

- **Desenho:** o `grid` do próprio R, no dispositivo `pdf()` com a codificação do Windows (`WinAnsi.enc`; o
  `CP1252.enc` não existe no R e o Latin-1 desenha o hífen como sinal de menos; o hífen vai como o hífen opcional,
  U+00AD). Só o QR-Code precisa de outro pacote (`qrcode`, em Suggests). Nada de modelo pronto de outra biblioteca:
  cada desenho vem do manual oficial.
- **Código de barras da chave:** o CODE-128C do Anexo II do MOC 7.0, conferido com o exemplo do manual (09758364, o
  dígito 48 e a sequência de larguras); com o CNPJ alfanumérico, o modelo C e A da NT Conjunta 2025.001 (item 6). Os
  códigos e os QR-Code de todos os exemplos foram lidos de volta pelo zxing, com a chave e o endereço certos.
- **DANFE** (`danfe_pdf`): A4 retrato, nas posições do Anexo II (3.8.1), com as folhas adicionais quando os itens não
  cabem e a continuação das informações complementares. **DANFE Simplificado e Etiqueta**
  (`danfe_simplificado_pdf`): o manual (3.11 e 3.12) só dá os campos mínimos, o papel (55 mm ou mais) e a chave no
  alto; o desenho é do pacote, em 10 cm de largura, porque a chave com o CNPJ alfanumérico em 7,4 cm daria o módulo
  de 0,0198 cm, abaixo do mínimo de 0,02 cm do item 2. O Tipo 2 da NT 2026.002 ficou de fora: a nota não traz leiaute.
- **DANFE NFC-e** (`danfce_pdf`): a bobina de 80 mm do Manual de Padrões Técnicos 6.0, com as divisões I a IX, a
  contingência e o QR-Code de 3 cm. **DACTE** (`dacte_pdf`), do CT-e e do CT-e OS; **DAMDFE** (`damdfe_pdf`), o
  modelo do rodoviário (2.8.1 do Anexo II do MDF-e).
- **DANFSe** (`danfse_pdf`): a versão 2.0 da NT 008/2026 (Anexo I), com a disposição do modelo quando a tabela de
  tamanhos não bate com ele; as linhas únicas das notas 2, 3 e 4 (sem tomador, destinatário, intermediário ou
  ISSQN; o ISSQN "não sujeito" é a falta do grupo ou o `tribISSQN` 4); a linha do PIS e da COFINS só até a
  competência de 2026 (nota 6); as exclusões da base do IBS e da CBS somam o que a nota tiver, também os dois ajustes
  da NT 009 que substituíram o `vCalcReeRepRes`. A logomarca da NFS-e não vai (o texto "NFS-e" no lugar dela).
- **Carta de correção** (`dacce_pdf`): não há modelo oficial; o desenho é do pacote (a chave em código de barras, o
  registro, a correção e as condições de uso; a do CT-e em tabela).

## Revisão da última etapa (06/11/2026)

Revisão independente (um revisor sem o contexto do trabalho, com os manuais no rascunho), e cada achado conferido na
fonte antes de corrigir:

- **O autor dos eventos** era o CNPJ do certificado. O MOC da NF-e (P12-44), o do MDF-e (J09) e o do CT-e (N19) pedem
  o emitente da chave (ou, no desacordo, o tomador); o certificado pode ser o da matriz ou o de uma filial (o mesmo
  CNPJ-base, item 5.9 do MOC 7.0). Agora o autor sai da chave (o CPF nas séries do emitente pessoa física: 910 a 999 na
  NF-e, 920 a 969 no MDF-e), e o certificado de outro CNPJ-base é recusado antes de montar o evento. Na manifestação e
  no desacordo, `destinatario` e `tomador` informam a filial. O cancelamento da NFS-e segue com o CNPJ do certificado:
  as fontes à mão não dizem a regra do autor dele.
- **A autorização:** o recibo é consultado de novo só em 105 (lote em processamento); 106 e as rejeições do pedido são
  a resposta final. A nota denegada (110, 301, 302, 303) ganha o `nfeProc` (item 5.1.6).
- **O DANFE:** os volumes de mais de um grupo `vol` somados; a fatura com os valores (`vOrig`, `vDesc`, `vLiq`) e as
  duplicatas que não cabem no quadro nas informações complementares (o 3.3.2 deixa reduzir o quadro, não aumentar); o
  FCP com os seis campos e a unidade tributável quando o valor unitário tributável é outro (3.1.7); as alíquotas com
  até 4 casas; o canhoto em duas linhas; a contingência FS e FS-DA com o código "Dados da NF-e" e o EPEC com o
  protocolo do evento (3.9.2 e 3.9.3); as informações complementares em quantas folhas precisarem. O ";" não quebra
  mais a linha em PDF nenhum: nenhum manual pede isso.
- **O DACTE OS:** o tomador (o grupo `toma`), a descrição e a quantidade do serviço, o seguro, o modal rodoviário do OS
  (TAF, registro estadual, veículo), os tipos de serviço 6 a 8; no DACTE, o ICMS ST retido e o de outra UF, e o uso do
  emissor e o reservado ao Fisco (`ObsCont`, `ObsFisco`).
- **O DANFSe:** o `indDest` 0 é o destinatário igual ao tomador (nota 3); o benefício municipal e as deduções nos
  lugares da tabela da NT 008; as máscaras do código de tributação, da NBS e do CEP; o município do cabeçalho (que sai
  quando o item do código é o 99); o país da prestação e da incidência; a UF da incidência do IBS e da CBS.
- **O MDF-e em contingência:** o QR-Code com o `sign` (9.2.2) e o DAMDFE com as chaves dos documentos (11.1); as
  observações que não cabem seguem em folhas adicionais.
- **Os QR-Code:** a borda em branco da matriz do `qrcode` sai, e o lado pedido é o do símbolo (no DANFE NFC-e, 2,4 cm
  numa área de 3 cm, acima dos 22 mm de conteúdo do manual); o DANFE NFC-e mostra o endereço de entrega.
- **Números acima de 2.147.483.647** saíam "NA" no formato brasileiro.
- **Testes:** o do QR-Code da NFC-e normal usava uma nota impossível (o `tpEmis` 1 com a chave de contingência); o do
  DANFE longo confere as três folhas.

## A NFS-e de prefeitura (06/11/2026)

- **O acervo** (as NFS-e de prefeitura do Fiscal, fora as 11 mil nacionais): o leiaute de São Paulo (raiz `NFe` com o
  `ChaveNFe`, 1.559), a ABRASF 1.00 (o `InfNfse` com o `Servico`: 173 sem namespace dentro do `CompNfse` e 147 do Ginfes,
  com o prefixo `ns4`) e a ABRASF 2.0x (o `InfNfse` com a `DeclaracaoPrestacaoServico`, 42, nas versões 2.02 e 2.04).
  Ficaram de fora dois leiautes próprios de município: o `nfe/NotaFiscal/NfeCabecario` (222) e o `CompNfe/Nfe/InfNFe`
  (105, parecido com a ABRASF 2, com outros nomes). Para eles não achei schema nem manual público; o arquivo fica em
  `arquivos`, com o motivo.
- **As fontes:** os schemas da Prefeitura de São Paulo (o pacote da Reforma, TiposNFe_v02, baixado do portal da Nota
  Fiscal Paulistana) e o Manual de Utilização do Web Service 3.3.4; o schema e o Modelo Conceitual da ABRASF 1.00
  (29/12/2008) e o schema e o Manual de Orientação do Contribuinte da 2.04 (setembro de 2018), da biblioteca pública da
  ABRASF. Os significados dos códigos saem desses manuais; a opção pelo Simples de São Paulo sai do schema v02, que tem
  o 6 (DAMSP) que o manual 3.3.4 ainda junta ao 0. O que nenhum descreve (o regime 0 do Ginfes, que aparece no acervo)
  fica sem descrição.
- **`nfse_prefeitura_ler()`:** as mesmas colunas nos três leiautes; os caminhos buscam pelo nome local, por causa do
  prefixo do Ginfes. A identificação da nota é o documento do prestador, o número e o código de verificação (não há
  chave); a data e hora ficam como no XML, sem fuso (os padrões municipais não trazem, e a hora é a do município). A
  situação vem do status de São Paulo e, na ABRASF, do `CompNfse` (cancelamento e substituição); a nota da ABRASF
  sozinha fica com a situação `NA`. A alíquota fica como no XML: São Paulo manda a fração (o manual: 5% é 0,05), a
  ABRASF 2 o percentual (5% é 5; os manuais da 2.02, da 2.03 e da 2.04), e a 1.00 não diz; no acervo da 1.00 há 0,02 e
  2,00. `aliquota_percentual` só onde o manual diz a escala.
- **Conferido** com o cache do Fiscal (outro leitor, independente), pelo arquivo, nas 1.682 que os dois leram: o número,
  o tomador, o valor dos serviços, o valor líquido e o cancelamento bateram em todas; o prestador, em todas menos uma, que
  o Fiscal deixou vazio. As 19 identificações repetidas são a mesma nota guardada duas vezes (os valores iguais). A
  leitura das 2.248 levou 22 segundos.
- **Revisão independente (06/11/2026)**, conferida achado por achado nos schemas e manuais, e corrigida:
  - o cancelamento da ABRASF vale pela presença do `NfseCancelamento` no `CompNfse`, e a data é a que estiver nele
    (`DataHoraCancelamento` na 1.00, `DataHora` na 2.04, outro grupo em algum provedor); antes, só um caminho fixo;
  - com o cancelamento e a substituição no mesmo `CompNfse`, a nota é substituída (a substituta cancela a nota);
  - as datas só no formato ISO, e a competência em AAAAMM, que o Modelo Conceitual da 1.00 descreve, vira o dia 1º do
    mês; outro formato fica `NA` (antes, um formato estranho no primeiro arquivo parava a leitura);
  - o `CodigoServico` de São Paulo (a tabela de serviços do município) foi para `codigo_tributacao_municipio`, como o
    da ABRASF, e o item da LC 116 da ABRASF ganhou coluna própria, `item_lista_servico` (antes, os dois juntos em
    `codigo_servico`);
  - o `IncentivoFiscal` da ABRASF 2 ("prestador possui incentivo fiscal") saiu da coluna do incentivador cultural da
    1.00: `incentivador_cultural` e `incentivo_fiscal`;
  - o ISS retido de São Paulo aceita o `0` e o `1` do boolean do XML Schema;
  - o município da prestação de São Paulo também vem do `cLocPrestacao` (a Reforma);
  - a `Assinatura` de São Paulo ("assinatura digital da NFS-e", diz o schema) saiu dos `campos`, como o `Signature`;
  - `aliquota_percentual` só nas versões da ABRASF 2 cujo manual diz a escala: a 2.04 (Manual de Orientação) e,
    baixados para conferir, os Manuais de Integração da 2.02 (11/2012) e da 2.03 (02/2016), que dizem o mesmo
    ("Valor percentual. Formato: 00.00"); de outra versão, `NA`;
  - a mensagem de quem lê uma NF-e com outro leitor não diz mais "sem o infNFe".
  Depois das correções, o acervo de novo (23,5 s): nenhuma cancelada sem data, nenhum campo de assinatura nos `campos`,
  e contra o Fiscal tudo igual como antes, menos uma nota da ABRASF 1.00 com o cancelamento e a substituição, que o
  Fiscal dá como cancelada e o RNFe como substituída (com a data do cancelamento).

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
- **A terceira camada, desde 04/11/2026** (pedido do usuário depois da revisão, "faça todos"):
  `tabelas_atualizar()` baixa do ramo `main` do repositório (`raw.githubusercontent.com`) as tabelas fiscais e os
  endereços da SEFAZ para a pasta de cache do R para o RNFe (`tools::R_user_dir`), e a leitura passa a usá-las. As
  decisões:
  - **do `main`, não do ramo do robô:** só o que uma pessoa já conferiu chega a quem usa;
  - **só quando a pessoa chama:** o pacote não sai para a internet sozinho ao ler uma tabela;
  - **o formato tem de ser o mesmo:** a tabela baixada só substitui a do pacote se tiver as mesmas colunas; senão
    fica a do pacote, e o resultado pede para atualizar o pacote (uma versão velha não quebra com uma tabela de
    formato novo);
  - `tabelas_atualizar(usar_as_do_pacote = TRUE)` apaga a cópia e volta às do pacote.
  Testado em 04/11/2026 de verdade, com uma pasta de cache temporária: as 17 tabelas em 5,5 s, nenhuma diferente
  (o `main` e o pacote estavam iguais), e a leitura usando a cópia baixada e voltando à do pacote.
- **Refeita no mesmo dia, depois da revisão independente do código novo** (veja "Revisão do código novo"), que
  achou tabela quebrada entrando como certa, mistura de tabelas numa falha no meio e a escolha pela data errada:
  - **a lista de conferência** (`inst/extdata/tabelas/conferencia.csv`): de cada tabela, as linhas e a soma de
    conferência (md5) do arquivo, e a versão do conjunto (a data e a hora, em UTC, em que alguma tabela mudou).
    Quem grava é `ferramentas/gerar_conferencia_das_tabelas.R`, que o `gerar_tabelas.R` roda no fim; a versão só
    muda quando alguma tabela mudou. O teste reclama se a lista ficar para trás das tabelas (quem mexe numa tabela à
    mão roda a ferramenta). O robô não conta a lista ao ver se algo mudou (ela muda junto com o `fontes.csv`);
  - **a lista vem primeiro;** quando a versão do pacote instalado já é a dela ou mais nova, nada mais é baixado e
    a cópia velha sai;
  - **cada tabela confere:** o md5 e as linhas com a lista, as colunas com as do pacote, e a leitura sem erro nem
    aviso. Página da web no lugar da tabela (um proxy) tem mensagem própria;
  - **tudo ou nada:** tudo vai para uma pasta ao lado; se uma tabela der problema, nenhuma é trocada (antes, a falha
    no meio deixava tabelas de origens diferentes, e a `fontes` mentia). A pasta entra no lugar de uma vez; se a
    troca falha (no Windows, um arquivo aberto por outro programa), volta a que estava, e o resultado diz;
  - **a escolha pela versão do conjunto, não pela data do arquivo:** a data do `DESCRIPTION` falhava ao reinstalar
    a mesma versão (a cópia nova era ignorada) e com `load_all()` (a cópia velha vencia um `git pull`). A tabela
    baixada com colunas diferentes das do pacote fica com a do pacote também na leitura;
  - **os testes não leem a pasta de cache de quem roda** (`tests/testthat/setup.R` a troca por uma temporária).

## O vigia dos schemas

- Os leitores seguem um pacote de schemas por documento (`ferramentas/schemas_usados.csv`), e o código dos
  leitores é escrito à mão a partir dele. Quando a SEFAZ publica um pacote novo, nada muda sozinho: o vigia
  avisa e uma pessoa atualiza.
- `.github/workflows/vigiar-schemas.yml` roda toda segunda às 9h30 UTC (6h30 em Brasília), e também à mão.
  Ele lê as listas de schemas dos portais da NF-e, do CT-e, do MDF-e e da NFS-e Nacional (`ferramentas/vigiar_schemas.R`) e
  abre um aviso (issue) para cada publicação que não está em `ferramentas/schemas_vistos.csv`. Quando a
  publicação traz o schema principal, o aviso diz os campos que entraram, que saíram e que mudaram de regra
  (ocorrências, tipo, padrão, valores aceitos, seguindo o tipo de origem). Nunca abre dois avisos com o mesmo
  título, aberto ou fechado. Se um portal não responde, termina com erro depois de abrir os avisos dos outros.
- Depois de atualizar um leitor (ou de ver que a publicação não afeta o RNFe), rodar
  `Rscript ferramentas/vigiar_schemas.R --registrar`. Quando o aviso diz que mudaram os valores aceitos de um
  campo, rodar também `Rscript ferramentas/conferir_codigos_dos_campos.R`: ele diz o código novo que ficou
  sem significado.
- `ferramentas/baixar_schemas.R` baixa os pacotes seguidos, e `ferramentas/validar_exemplos.R` sem argumentos
  usa ele: a validação não depende mais de uma cópia guardada à mão. Com argumentos, o validador recebe uma
  pasta por linha de `schemas_usados.csv` (`nfe=<pasta> cte=<pasta>...`).
- **Os eventos da NF-e têm pacotes à parte**, que entraram em `schemas_usados.csv` com nomes próprios
  (`nfe_eventos`, `nfe_cancelamento`, `nfe_carta_correcao`, `nfe_distribuicao`): só o validador os usa. O vigia
  continua comparando cada publicação com a linha do documento (`nfe`); uma publicação só de eventos ganha o
  aviso de que não traz o schema principal.
- **Zip dentro do zip:** o pacote 010d da NF-e guarda os schemas em zips internos (`PL_Evento.zip`,
  `PL_010d_NT2026.004.zip`). O `baixar_pacote()` agora abre esses zips também, o que vale para o vigia: antes,
  um pacote assim seria dado como "não traz o schema principal".
- **Testado em 30/10/2026:** os três portais responderam aos servidores do GitHub (205 publicações). Num ramo
  de teste sem uma publicação no registro, o robô abriu um aviso (nº 2) e, na rodada seguinte, não abriu
  outro; o aviso foi fechado com a explicação e o ramo apagado. Os pacotes que o `baixar_schemas.R` traz são
  idênticos, arquivo por arquivo, aos usados para validar os exemplos.
- **Detalhes dos portais:** o do MDF-e monta os links por JavaScript (o nome do arquivo está no `onclick`);
  o da NF-e às vezes publica o `+` do código do arquivo como espaço (os dois vão como `%2B`, e o portal aceita).
  A NFS-e publica no gov.br, em duas páginas (a documentação atual e a da Reforma, RTC), com o link direto
  para o `.zip`. Em 30/10/2026 o link da página da RTC apontava para a área de produção restrita, que devolve
  uma página de "Conteúdo Restrito" no lugar do arquivo; o aviso diz quando o endereço não devolve um `.zip`.
- **NFS-e no vigia, testado em 30/10/2026:** os quatro portais responderam (207 publicações, as duas da NFS-e
  novas). O aviso do pacote que o `nfse_ler()` segue saiu sem nenhuma diferença, e o da RTC disse que o
  endereço não devolveu um `.zip`. Comparando a 1.00 com a 1.01 do mesmo pacote, o vigia achou o `xOutInf`
  que mudou de lugar e a lista nova de situações (`cStat`). Depois, as duas foram registradas.
- **O arquivo principal muda de nome com a versão** na NFS-e (`NFSe_v1.00.xsd`, `NFSe_v1.01.xsd`), e um
  pacote pode trazer mais de uma versão. Num pacote novo, o vigia compara pela versão mais nova do arquivo
  principal que o pacote traz, e o aviso diz qual foi.
- **O primeiro uso já achou lacunas:** comparando o pacote 010f da NF-e com o 010g, que o `nfe_ler()` segue,
  entraram os valores líquidos (`vProdLiq`, `vUnComLiq`, `vProdLiqTot`) e o pagamento vinculado
  (`gPgtoVinc`), que o leitor ainda não lia; no CT-e, o `pgtoVinc`. **Resolvidas em 30/10/2026:** colunas
  `valor_unitario_liquido`, `valor_produto_liquido`, `valor_produtos_liquido` e `valor_icms_previsto`, e a
  tabela `pagamentos_vinculados` na NF-e e no CT-e (o código do meio de pagamento é o do IT 2026.001 v1.01:
  15, 17, 18, 20, 23, 24). Nenhum dos 133.310 XMLs reais do Fiscal (118.783 NF-e, 14.527 CT-e) traz esses
  campos ainda; a conferência foi pelo schema e pelos exemplos, que ganharam esses campos.
- **Grupos opcionais e escolhas:** as regras de cada campo dizem também se ele está num grupo que pode faltar
  ("num grupo [0..1]") ou numa escolha entre campos ("numa escolha"). Sem isso, o `vProdLiq` aparecia como
  obrigatório, e um grupo que passasse a ser obrigatório não apareceria no aviso.
- **Node 24:** o GitHub avisou que as ações em Node 20 vão parar. Nos dois robôs, só o `actions/checkout@v4`
  usava Node 20 (o `r-lib/actions/setup-r@v2` já usa o 24); os dois passaram para o `actions/checkout@v7`
  em 30/10/2026. O que a v7 muda (recusar o checkout de pull request de fork em `pull_request_target` e
  `workflow_run`) não afeta robôs que rodam por agenda ou à mão.

## CEST: pelo SPED (06/11/2026; adiado em 29/10/2026)

Entrou a primeira das duas opções abaixo, a única que se faz com certeza: a tabela externa 996 do SPED (versão 18,
de 03/10/2024), baixada pelo `gerar_tabelas.R` como as outras do SPED (`tabela_fiscal("cest")`, 2.185 linhas, 1.049
códigos), e a descrição ao lado do CEST de cada item do `nfe_ler()`, pela data da nota. Para as notas de 01/09/2023 em
diante, a descrição é o aviso do próprio SPED ("Verificar, para o CEST, a descrição vigente para cada período no
Convênio ICMS 142/18"). A segunda opção (o texto do Confaz, revisado caso a caso com o usuário) segue em aberto.

O que se viu em 29/10/2026, quando foi adiado:

Nenhuma fonte oficial dá a descrição atual do CEST sem ambiguidade, e o Portal da NF-e não publica tabela de
CEST (conferidas 495 publicações em cinco seções).

| Fonte | O que dá com certeza | O problema |
|---|---|---|
| SPED, tabela externa 996 (v18) | os 1.049 códigos e as descrições, com datas, até 31/08/2023 | desde 01/09/2023 as 1.038 linhas vigentes dizem só "Verificar, para o CEST, a descrição vigente para cada período no Convênio ICMS 142/18" |
| Convênio ICMS 142/18, página do Confaz | a redação atual (linhas de classe `A7-*`; as anteriores são `A9-*`) e o NCM de cada CEST | as seções de RETIFICAÇÃO e as tabelas repetidas da cláusula vigésima segunda deixam 36 códigos com mais de um texto "atual"; 3 códigos vigentes só no SPED e 15 só no Confaz; as notas de alteração têm 99 modelos de "nova redação" e 58 de "redação anterior" (com "sem efeitos", intervalos e erros de digitação) |

Opções quando voltar: só o SPED (descrições até 31/08/2023), ou o Confaz revisado caso a caso com o usuário.

## As datas da Reforma numa tabela (09/11/2026)

Pedido do usuário ("é bom deixar de um jeito que seja fácil pra caso algo passe a valer com o tempo"):

- **`tabela_fiscal("marcos_ibs_cbs")`**, escrita à mão: cada data da Reforma que a conferência, o cálculo e o
  cruzamento da EFD usam, com o nome que o código procura, o primeiro dia em que vale, a descrição, a base legal e
  onde é usada (20 marcos, com o do DANFSe que a revisão achou). Antes, os anos estavam no código (2026, 2027, 2029,
  2033, 16/11/2026...), em seis arquivos. Agora o código só pede o marco pelo nome (`R/ibs_cbs_marcos.R`), e os textos ("a partir de 2029", "até
  2028") saem da data. Os componentes da base do cálculo dizem em que marco entram e em que marco saem.
- **`tabela_fiscal("regras_ibs_cbs")`**: a planilha das regras saiu de `inst/extdata/` para a pasta das tabelas,
  para que `tabelas_atualizar()` leve também a mudança de data de produção de uma regra (a NT adia e antecipa com
  frequência). Ganhou as 31 regras que a NT v1.53 marca como implementação futura, sem a data de produção, conferidas
  no texto e na imagem das páginas (as do Imposto Seletivo, UB01 a UB11 e W33-10; UB12-10 e UB13-40; UB16-10, a base;
  as contas do monofásico retido e da diferença do biocombustível ad valorem, UB88a, UB93a, UB94b, UB98a, UB103a e
  UB104b; os totais do monofásico, UB105a e UB105b; o vItem e o vNFTot, VB01 e W60; VC02-20, VC03-20, I05k-30 e
  11BC01-30). Nas quatro "a" do monofásico retido a NT deixa o modelo em branco, e ele fica vazio.
- **Um teste** reclama se um ano da Reforma voltar a ser escrito no código desses arquivos, se o código pedir um
  marco que a tabela não tem, se a tabela tiver um marco que ninguém usa, e se o código passar a conferir uma regra
  futura sem a data dela na tabela. Outro mostra que mudar a data na tabela muda o resultado, sem mexer no código.
- **O resultado não muda.** O acervo inteiro com IBS, CBS ou IS (12.561 XML, 12.376 NF-e), conferido e calculado com o
  código de antes e com o de agora: as 1.688.508 conferências iguais em todas as colunas, e o cálculo dos 63.150 itens
  igual. Nos testes mudam só alguns textos de `esperado`, que agora saem da data: "não informado em 2026" virou "não
  informado até 2026" (UB95a-10 e UB100-20, que valem também em 2025), e "depois de 2028" ou "depois de 2026", "a
  partir de 2029" ou "a partir de 2027" (no acervo nenhuma conferência usa esses textos). CI: 3.175 testes, check OK;
  o robô das tabelas rodou no ramo e não achou mudança.
- O que não mudou: as alíquotas já estavam numa tabela (`aliquotas_ibs_cbs`), e as regras da pré-conferência
  (`regras_nfe.csv`), que não são da Reforma, continuam onde estavam.
- **Revisão independente, no mesmo dia** (pergunta do usuário: "você tem certeza de que tá tudo ok?"). Um revisor com
  o código de antes e o de agora, sem as minhas conclusões, rodou 23 variantes da nota de exemplo em 19 datas de
  fronteira (437 conferências, 32.934 linhas) e o cálculo nas mesmas datas. Achados, conferidos e corrigidos:
  - **Erro meu:** a observação da VC02-14 na janela da devolução (30/10 a 15/11/2026) passou a dizer "em produção
    desde 16/11/2026"; a NT diz "até 16/11/2026", e é por isso que a janela existe. Voltou ao texto de antes, com teste.
  - **Uma data que ficou no código:** o DANFSe mostra o PIS e a COFINS próprios só até a competência de 2026 (nota 6
    da NT 008/2026). Virou o marco `danfse_sem_pis_e_cofins_proprios_desde`, separado do cálculo (outra base legal),
    e o `danfse.R` entrou no teste que procura anos no código.
  - **Uma armadilha para quando uma regra futura for ligada:** sem a data de emissão, o filtro deixava passar a regra
    sem data de produção, e as quatro sem modelo davam linha vazia. Agora a regra sem data nunca vale, e o modelo
    vazio não vale para nenhum (com teste). Hoje nada disso acontecia: o código não gera essas regras.
  - Os testes que leem o código-fonte passam a dizer que foram pulados no pacote instalado (o R CMD check), em vez de
    passar sem conferir; no CI eles rodam pelo `test_local()`, na pasta do código.
  - Não eram erro: as mudanças dos textos do monofásico (já ditas acima) e a tabela baixada que falta ou mudou de
    formato, que fica com a do pacote (é de propósito e tem teste; o "nunca misturar" da ajuda é da troca).
  Com as correções, as mesmas 437 conferências: só os seis textos do monofásico diferentes do código de antes; o
  cálculo igual.
- **Segunda revisão independente, das correções** (o usuário perguntou de novo: "está tudo realmente ok?"). Confirmou
  as três, com o filtro igual ao antigo em tudo o que o código gera (207 códigos de regra, todos com data e modelo; as
  282 chamadas dos testes, também sem a data de emissão e sem o modelo) e a lista de conferência batendo com os
  arquivos do jeito que o GitHub os entrega (o md5 e as linhas das 27). Um achado de verdade: o teste da regra futura
  usava uma regra também sem modelo, e passava mesmo com o filtro da data antigo. Agora usa a UB16-10 (com modelo), e
  um teste à parte tira o modelo de uma regra com data; com cada filtro antigo de volta, numa cópia, o teste falha.
  Também: o comentário do filtro, o `fontes.csv` dos marcos com a NT do DANFSe e os textos que não citavam o DANFSe.

## O README em páginas, e a máquina local liberada (10/11/2026)

- **Pedido do usuário:** "acho que a documentação no github tá muito extensa pra uma página inicial [...] não
  consegue deixar numa segunda página?". O README (707 linhas) ficou com o que é, como instalar, um exemplo, a lista
  das páginas, de onde vêm as regras e os agradecimentos. O resto foi para `guia/`, uma página por assunto (ler os
  documentos, SEFAZ, emitir, PDFs, pré-conferência, IBS e CBS, SPED e tabelas), com o texto como estava: uma
  conferência linha a linha mostrou as 550 linhas de texto do README antigo nas páginas, iguais e na mesma ordem.
  `guia/` fica fora do pacote (`.Rbuildignore`). Páginas do GitHub e não vinhetas: não pedem knitr nem pandoc no
  check; para o CRAN, elas podem virar vinhetas depois.
- **No caminho, duas frases velhas do README corrigidas:** "nada aqui consulta a SEFAZ" (vale só para a leitura) e
  "a assinatura, quando chegar aqui, vai ser conferida com a do PyNFe" (já foi: o mesmo XML sai assinado igual).
- **O Controle Inteligente de Aplicativos foi desligado** (o usuário: "o bloqueio do windows acho que já tá ok";
  `VerifiedAndReputablePolicyState` 0). O curl, o httr2, o testthat, o processx, o roxygen2 e o knitr carregam; 15
  pacotes da biblioteca de teste que tinham ficado quebrados do tempo do bloqueio foram reinstalados. A suíte
  inteira rodou aqui (3.183 testes, nenhuma falha, nada pulado) e o R CMD check local também (só as notas da versão
  de desenvolvimento e da falta do pandoc nesta máquina). O ramo temporário no GitHub deixa de ser necessário.

## A NFS-e Nacional no leiaute da NT 009, e o MA no cadastro (10/11/2026)

- **Pedido do usuário:** "veja o que dá pra adiantar". A NT SE/CGNFS-e 009 (v1.01), que a Produção Restrita já usa
  (a produção ainda sem cronograma: "será publicado no portal da NFS-e"), mudou de lugar campos que o `nfse_ler()`
  lia: numa nota dela, a finalidade, o destinatário, o CST e a classificação do IBS e da CBS e as deduções do ISSQN
  saíam `NA`.
- **Como foi achado:** os caminhos do leitor contra a cópia do XSD da NT 009 (a do repositório t3wv/nfse, a que a
  emissão na Produção Restrita usou) deram seis campos; a revisão independente, pelo PDF oficial, achou o sétimo (o
  item 2.11: o `indDest` e o `dest` foram para o `infDPS`), que essa cópia do XSD ainda põe no `IBSCBS`. **Vale o
  texto da NT.** Os itens 2.1 a 2.16 foram lidos inteiros: nenhum outro campo das colunas mudou.
- **O que mudou:** cada coluna aceita o caminho antigo ou o novo (o "a|b" do leitor; os dois nunca existem juntos):
  `finalidade` (item 2.2), `destinatario_indicador`, `destinatario_documento` e `destinatario_nome` (2.11),
  `cst_ibs_cbs` e `classificacao_ibs_cbs` (2.16), `deducao_percentual` e `deducao_valor` (o `vAjusteBC`, que juntou o
  `vDedRed` e o `gReeRepRes`) e `deducao_calculada` (o `vCalcDR` virou `vCalcAjusteBCISSQN`, com outra fórmula), do
  item 2.3. O DANFSe também: o destinatário no `infDPS` e, na nota da NT 009, a dedução do ISSQN é o
  `vAjusteBCISSQN` mais o `vCalcAjusteBCISSQN` (a fórmula da base, pág. 8: `vBC = vServ - descIncond -
  (vAjusteBCISSQN + vCalcAjusteBCISSQN) - ...`); antes dela, o `vDR` ou o `vCalcDR`, como era.
- **As notas de hoje não mudam:** a revisão comparou o `nfses`, o `campos` e o texto do DANFSe dos dois exemplos com
  o código de antes: iguais. Teste novo com uma nota fictícia no leiaute da NT 009 (`helper-nfse_nt_009.R`), no
  leitor e no DANFSe.
- **Fica para quando o schema oficial da NT 009 sair no portal:** os significados novos (o `finNFSe` 1, crédito, e
  2, débito; o `opSimpNac` 4, "optante pendente"). A ferramenta que confere `codigos_dos_campos` exige que todo
  código esteja no schema oficial, e o da NT 009 por enquanto só existe na cópia de terceiros. Até lá, a descrição
  desses códigos fica vazia.
- **O MA no `sefaz_cadastro()`:** a linha do MA dizia só que "a Relação de Serviços Web não traz este serviço".
  Agora diz que o MA não oferece a consulta por web service (a SVAN não tem o serviço, a SVRS respondeu 410 em
  03/11/2026 e os endereços da SEFAZ-MA devolveram 404 e 405 em 30/10/2026) e que o cadastro de lá só se consulta
  no site do Sintegra do MA. O PE e o RN em produção (o que a sessão do app Python viu) ficaram de fora da ajuda: a
  informação não veio de uma consulta que eu tenha à mão.
- **Conferido:** a suíte inteira aqui (3.199 testes, nenhuma falha, nada pulado) e o R CMD check local.

## A inclusão de DF-e no MDF-e (10/11/2026)

- **Pedido do usuário:** "faça" (a inclusão de DF-e, o evento que faltava do MDF-e). `sefaz_mdfe_incluir_dfe()`: o
  evento 110115 pelo MOC do MDF-e 3.00b (itens 2.1.9 e 6.4) e o schema `evInclusaoDFeMDFe_v3.00.xsd` do pacote
  PL_MDFe_300b_NT012025_1.05: o protocolo do MDF-e, o município de carregamento e, para cada NF-e (só NF-e, `chNFe`),
  o município de descarregamento. Antes de ir à SEFAZ: protocolo de 15 algarismos, municípios de 7, nomes de 2 a 60
  sem espaço nas pontas, chaves válidas do modelo 55, sem NF-e repetida.
- **Só serve ao MDF-e com carregamento posterior** (`indCarregaPosterior` 1, carga própria em operação dentro da UF,
  quando o emitente, no início da viagem, não tem acesso aos documentos transportados); o outro é rejeitado (708), e
  o com carregamento posterior só se encerra depois de uma inclusão (715).
- **A sequência:** o MOC diz que a do evento é "=1" (K01), mas a regra K14 fala da NF-e "vinculada ao MDF-e por outro
  evento de inclusão". Em homologação, a SVRS registrou a segunda inclusão com a sequência 2: a função aceita de 1 a
  99, como a do condutor.
- **Testado na SVRS de homologação**, pelas funções do próprio RNFe (o curl voltou a carregar aqui), com o
  certificado da empresa do RJ: duas NF-e montadas a partir de uma nota real, autorizadas (100); o MDF-e com
  carregamento posterior, sem documento, autorizado (100); as duas inclusões (135), lidas pelo `eventos_ler()`; o
  encerramento (135); e as duas NF-e canceladas no fim (135). As cópias com dados da empresa foram apagadas.
- **Testes sem rede:** o evento montado (o `Id` com a sequência, o `detEvento` inteiro), a segunda inclusão com a
  sequência 2 e a NF-e com o CNPJ alfanumérico, e os erros antes de qualquer conexão.
- **Revisão independente:** o evento montado passa no schema oficial (também com o CNPJ alfanumérico, acento e "&",
  60 caracteres); as mensagens do encerramento ficaram iguais. Achou uma falha que já existia na conferência dos
  textos dos eventos (a justificativa, a correção, a observação do desacordo, o nome do condutor e agora os dos
  municípios): o travessão, a quebra de linha e a tabulação passavam, e o `TString` dos schemas (NF-e, CT-e, MDF-e e
  NFS-e, o mesmo padrão nos quatro) só aceita do espaço ao U+00FF. Agora a conferência recusa antes de enviar. E a
  sequência com casas decimais (1,5) não vira mais 1 calada.

## A distribuição da NFS-e com documentos de verdade (10/11/2026)

- **Pedido do usuário:** "faça" (o item em aberto "conferir a distribuição da NFS-e com notas de verdade"). Na
  Produção Restrita já havia uma: a NFS-e gerada e cancelada no teste da emissão (05/11/2026).
- **`nfse_distribuicao()` com o certificado do prestador, do NSU 0 até o fim:** o primeiro pedido trouxe dois
  documentos (a NFS-e e o evento de cancelamento; o ADN autorizou por `CnpjBase`), o segundo, o E2220 (nenhum
  documento). Os dois XML vieram descompactados e abriram: a NFS-e no `nfse_ler()` (a chave igual à da distribuição,
  o emitente o do certificado, o ambiente 2) e o cancelamento (101101) no `eventos_ler()`, da mesma chave. O
  `gerado_em` ficou a menos de um minuto do `dhProc` da nota e da data do evento, no horário de Brasília.
- **A mesma nota confirma a correção da NT 009:** ela foi gerada no leiaute da NT 009 (o `finNFSe` no `infDPS`); o
  `nfse_ler()` de agora lê a finalidade, o de antes da correção a deixava `NA`, e o resto das colunas saiu igual. A
  nota não tem o grupo do IBS e da CBS, então o CST e o destinatário não aparecem nela (nem antes, nem agora).
- As cópias com os documentos foram apagadas.

## A revisão final de 10/11/2026

- **Pedido do usuário:** "só me retorne se tiver realmente tudo ok sobre tudo, sem brechas". Um revisor independente
  leu o diff do dia inteiro (124d799 a bd966cd), com a NT 009, os schemas do MDF-e e da NF-e e o MOC do MDF-e.
- **Sem regressão nem erro de lógica:** a recusa dos caracteres fora do `TString` vale igual em todos os schemas que
  usam a conferência (o `TJust` e o `TString` da NF-e, o `xObs` do desacordo do CT-e, o `TString` do MDF-e, o
  `TSMotivo` da NFS-e); a nota antiga sai igual no leitor e no DANFSe (seis variantes); a soma da dedução só na nota
  da NT 009; o evento do MDF-e passa no schema nos casos válidos e para antes do envio nos errados.
- **Corrigido a partir dela:** o `@source` do `danfse_pdf()` e o `guia/pdf.md` passam a citar a NT 009 (itens 2.3 e
  2.11); os links do README para o `guia/` viraram endereços completos (a pasta fica fora do pacote, e no CRAN o link
  relativo daria nota de arquivo inválido); a frase da assinatura ganhou a ressalva dos acentos; testes do
  destinatário no `infDPS` com documento e nome (no leitor e no DANFSe), a trava de rede nos testes de erro do MDF-e,
  e a carta de correção também recusa a sequência com casas decimais e o texto com quebra de linha; um número no
  lugar do texto do evento não cai mais no erro cru do R.
- **No ambiente:** dez pacotes da biblioteca de teste (scratchpad/rlib) perderam o DESCRIPTION e o NAMESPACE às
  17:10 (pdftools, qrcode, magick, opencv, tesseract, qpdf, Rcpp, digest, assertthat, rappdirs; a política do Windows
  continua desligada) e 19 testes de PDF e OCR passaram a ser pulados; reinstalados, a suíte voltou a rodar inteira:
  3.226 testes, nenhuma falha, nada pulado.
