# Plano do RNFe

Situação em 04/11/2026: **etapas 1, 2 e 3 feitas, e revisadas** (seção "Revisão das etapas 1 a 3", no fim
das da etapa 3). Etapa 1: chave de acesso, leitura do XML da NF-e/NFC-e e tabelas fiscais, conferidas com
notas reais; o CEST foi adiado por decisão do usuário. Etapa 2: a leitura do CT-e e do CT-e OS (14.370 CT-e
reais), da GTV-e, do CT-e simplificado e do MDF-e (os dois pelo schema oficial, sem documentos reais para
comparar), da NFS-e Nacional (11.207 reais) e dos eventos de todos; a NFS-e de prefeitura fica para depois, por
decisão do usuário. Etapa 3:
certificado, SEFAZ (status, consulta pela chave, cadastro, MDF-e não encerrados, Distribuição da NF-e e do
CT-e) e a NFS-e Nacional, em homologação, e a situação do CNPJ na Receita. O que a revisão de 04/11/2026
deixou em aberto está no fim dela.
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
| 1 | Tabelas fiscais (CFOP, CST, CSOSN; depois NCM, CEST, as da Reforma e os municípios), com a data em que cada linha valeu | Não | prontas, menos o CEST (adiado, veja abaixo) |
| 2 | Ler CT-e, MDF-e e a NFS-e nacional, e os eventos de todos | Não | prontos (CT-e, CT-e OS, CT-e simplificado, GTV-e, MDF-e, NFS-e Nacional, eventos e o resumo da NF-e); a NFS-e de prefeitura fica para depois |
| 3 | Certificado digital, SEFAZ no ar, baixar as notas recebidas | Sim | pronta, em homologação: certificado, status do serviço e consulta pela chave nas 27 UFs (NF-e, NFC-e, CT-e, CT-e OS, GTV-e e MDF-e), MDF-e não encerrados, consulta de cadastro nas 26 que têm o serviço e a Distribuição de DF-e da NF-e e do CT-e, em homologação; da NFS-e Nacional, a consulta pela chave (com os eventos) e a distribuição, na Produção Restrita; a chave num PDF ou numa foto; a situação do CNPJ na Receita (sem certificado) |
| 4 | Calculadora da Reforma (CBS e IBS): conferir e simular | Não | em andamento: as tabelas e a conferência (`ibs_cbs_conferir`) prontas (04/11/2026); simular a seguir |
| 5 | Ler o SPED; pré-conferência do que a SEFAZ rejeitaria | Não | |
| por último | Assinatura, emissão e eventos (manifestação, desacordo do CT-e) | Sim | |

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
| Certificado A1, assinatura e conexão segura (mTLS) | sim | sim | não | etapa 3 e última |
| Emitir NF-e e NFC-e (normal e contingência) | sim | não | não | última |
| Cancelamento, carta de correção, inutilização | NF-e | NFS-e (cancelamento) | não | última |
| Manifestação do destinatário | sim | não | não | última |
| MDF-e: emitir, encerrar, incluir condutor e DF-e | sim | não | não | última (entrou agora no plano) |
| CT-e: consultar e registrar desacordo | não | não | não | consultar: pronto em homologação (etapa 3); desacordo: última |
| NFS-e Nacional: emitir, consultar, cancelar, eventos | não | sim | não | consultar e ler os eventos: pronto na Produção Restrita (etapa 3); emitir e cancelar: última |
| NFS-e no padrão Abrasf (Ginfes, Betha) | sim | não | não | ler: depois (decisão do usuário, 03/11/2026), pelos formatos que mais aparecem no acervo; emitir: não previsto, o padrão nacional substitui |
| Baixar o DANFSe oficial | não | sim | não | não existe mais: a API do DANFSe foi desativada em 03/08/2026 (NT 008/2026, veja a etapa 3); o DANFSe vai para os PDFs, no leiaute da NT 008 |
| PDFs: DANFE, DANFCe, DACTE, DAMDFE, DANFSe, DACCe e etiqueta | não (usa o BrazilFiscalReport) | só o DANFSe não oficial | sim | última (entraram agora no plano) |
| Calculadora da Reforma: conferir e simular | não | não | não | etapa 4: conferir pronto (NF-e e NFC-e, como a SEFAZ conferia no dia da emissão); simular a seguir |
| Ler o SPED e pré-conferência | não | não | não | etapa 5 |

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
  CBS. Devolve `ctes`, `componentes`, `documentos`, `cargas`, `impostos`, `parcelas`, `observacoes` e
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
    de produção do controle de versões do IT 2025.002 v1.71 (a 1.30, a 1.31 e a 1.40 não têm prazo lá: valem até o
    da 1.50, 04/05/2026, que já as traz). A coluna DataAtualização da planilha não serve para isso: a 1.70 mexeu no
    texto das 170 linhas, e todas ficaram com 01/10/2026. O robô refaz a comparação toda semana; versão nova sem
    prazo em `VERSOES_DA_TABELA_DA_REFORMA` gera um aviso e as mudanças dela ficam sem prazo (a conferência as trata
    como talvez não em produção).
  - **Como fica:** o que não confere pela regra e pela tabela de hoje, numa nota emitida antes da mudança, vem com
    `confere` vazio e o motivo (para a tabela, "a SEFAZ conferiu" quando a nota é de antes da publicação e "pode ter
    conferido" entre a publicação e o prazo).
  - **Fica de fora, por enquanto:** a tributação monofásica (reformulada na v1.50, produção em novembro de 2026), o
    crédito presumido (UB122 a UB130, que consultam a tabela `cCredPres`, ainda fora do RNFe), o Imposto Seletivo,
    a UB16-10 e as outras de implementação futura; e regras simples que ainda não entraram: UB14-60 a UB14-80 (o
    cClassTrib e o tipo da nota de débito e de crédito), UB66a a UB66e (a CBS da ZFM), UB106, UB112-30, UB116-30,
    UB131-40, UB131-50, UB132-10, UB133-10 e W07-10.

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

## CEST: adiado (decisão do usuário, 29/10/2026)

Nenhuma fonte oficial dá a descrição atual do CEST sem ambiguidade, e o Portal da NF-e não publica tabela de
CEST (conferidas 495 publicações em cinco seções).

| Fonte | O que dá com certeza | O problema |
|---|---|---|
| SPED, tabela externa 996 (v18) | os 1.049 códigos e as descrições, com datas, até 31/08/2023 | desde 01/09/2023 as 1.038 linhas vigentes dizem só "Verificar, para o CEST, a descrição vigente para cada período no Convênio ICMS 142/18" |
| Convênio ICMS 142/18, página do Confaz | a redação atual (linhas de classe `A7-*`; as anteriores são `A9-*`) e o NCM de cada CEST | as seções de RETIFICAÇÃO e as tabelas repetidas da cláusula vigésima segunda deixam 36 códigos com mais de um texto "atual"; 3 códigos vigentes só no SPED e 15 só no Confaz; as notas de alteração têm 99 modelos de "nova redação" e 58 de "redação anterior" (com "sem efeitos", intervalos e erros de digitação) |

Opções quando voltar: só o SPED (descrições até 31/08/2023), ou o Confaz revisado caso a caso com o usuário.
