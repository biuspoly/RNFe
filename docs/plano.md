# Plano do RNfe

Situação em 30/10/2026: **etapa 1 concluída** (chave de acesso, leitura do XML da NF-e/NFC-e e tabelas
fiscais, conferidas com notas reais; o CEST foi adiado por decisão do usuário). **Etapa 2 concluída:** a
leitura do CT-e e do CT-e OS, conferida com 14.370 CT-e reais; a do MDF-e, conferida pelo schema oficial,
sem MDF-e reais para comparar; e a da NFS-e Nacional, conferida com 11.207 NFS-e reais. Os quatro leitores
têm a tabela `campos` e o vigia olha os quatro portais. **Fechadas em 30/10/2026 as lacunas achadas na
revisão das duas etapas:** a NFC-e (que nunca tinha sido lida de verdade: ganhou exemplo, QR-Code e
contingência), a leitura dos eventos de todos os documentos e a tabela de municípios do IBGE. A próxima é a
etapa 3 (certificado e SEFAZ).
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
| 1 | Tabelas fiscais (CFOP, CST, CSOSN; depois NCM, CEST, as da Reforma e os municípios), com a data em que cada linha valeu | Não | prontas, menos o CEST (adiado, veja abaixo) |
| 2 | Ler CT-e, MDF-e e a NFS-e nacional, e os eventos de todos | Não | prontos (CT-e, CT-e OS, MDF-e, NFS-e Nacional e eventos) |
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
| Ler CT-e, CT-e OS e MDF-e em tabelas | não | não | não | pronto (etapa 2) |
| Ler NFS-e Nacional em tabelas | não | não | não | pronto (etapa 2) |
| Ler os eventos (cancelamento, carta de correção, manifestação, encerramento) em tabelas | não | não | não | pronto (etapa 2) |
| Tabelas fiscais com vigência (CFOP, NCM, CST, Reforma) e municípios | não | não | não | pronto (etapa 1) |
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
| Municípios | IBGE | sim (desde 30/10/2026) |
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
- **Municípios (30/10/2026):** a API de localidades do IBGE, na visão nivelada
  (`localidades/municipios?view=nivelado`): 5.571 municípios, com o código de 7 dígitos, o nome, a UF e o
  código da UF. A visão completa traz a UF dentro da microrregião, e um município vinha sem microrregião (ficaria
  sem UF). O IBGE só publica a lista de hoje: a tabela vai sem datas, como o CSOSN. O código 9999999, que a NF-e
  usa para o exterior (está no schema), não é do IBGE e não entra. O robô das tabelas passa a baixá-la junto
  com as outras.

## Etapa 2, leitura do CT-e: o que se decidiu

- `cte_ler()` lê o CT-e (modelo 57) e o CT-e OS (modelo 67), leiautes 3.00 e 4.00, pelo schema oficial do
  pacote PL_CTe_400 NT 2026.004 RTC 1.00 (Portal do CT-e, republicado em 16/10/2026), que já traz o IBS e a
  CBS. Devolve `ctes`, `componentes`, `documentos`, `cargas`, `impostos`, `parcelas`, `observacoes` e
  `arquivos`, ligadas pela chave, no mesmo molde do `nfe_ler()`. O que as duas leituras fazem igual está em
  `R/ler_xml.R`.
- **O CT-e OS entrou junto** porque usa o mesmo `infCte` e quase os mesmos grupos; muda o tomador (grupo
  `toma`), o serviço (`infServico`) e os tributos federais (`infTribFed`). A GTV-e e o CT-e simplificado
  também usam `infCte`, com outro conteúdo, e ficam de fora; o simplificado avisa que ainda não é lido.
- **O tomador sai pronto.** No `toma3` o XML só diz o papel (0 remetente, 1 expedidor, 2 recebedor,
  3 destinatário, como está no schema) e o pacote copia os dados dessa pessoa; no `toma4` e no CT-e OS os
  dados vêm do próprio grupo.
- **`documentos` junta tudo o que o CT-e cita**, com o grupo de origem em `tipo`: os transportados (NF-e,
  nota em papel, outros, DC-e), os de transporte anterior (com o emitente), o CT-e complementado, o
  substituído, o multimodal e, no CT-e OS, os referenciados e as GTV-e.
- O `ICMSOutraUF` vai nas mesmas colunas de base, alíquota e valor do ICMS, e `grupo_icms` diz de qual grupo
  veio. O CST do ICMS fica sem nome ao lado: a tabela do pacote é a da NF-e, que não tem o CST 45 do CT-e.
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
  (Abrasf, Ginfes...), não é lida: avisa em `arquivos` com a raiz que o XML tem.
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
  não (100 da 1.00, 2 da 1.01). Os motivos são do schema e do próprio sistema nacional, não do RNfe:
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
    espaços no começo ou no fim: o Fiscal tira os espaços e o RNfe deixa o nome como está no XML;
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
  `observacao` entrou depois da conferência: o Fiscal mostrava o `xObs` de 4 eventos de desacordo que o RNfe só
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
  - A data difere na forma: o Fiscal guarda o relógio escrito no XML sem o fuso, e o RNfe guarda o instante.
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
- Depois de atualizar um leitor (ou de ver que a publicação não afeta o RNfe), rodar
  `Rscript ferramentas/vigiar_schemas.R --registrar`.
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
