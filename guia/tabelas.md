# Tabelas fiscais

[Voltar ao início](../README.md)

```r
tabela_fiscal("cfop")                    # título, nota explicativa e indicadores de cada CFOP
tabela_fiscal("ncm")                     # a NCM vigente, com a descrição completa de cada código
tabela_fiscal("classificacao_ibs_cbs")   # a cClassTrib da Reforma, e "cst_ibs_cbs", com os indicadores de cada um
tabela_fiscal("credito_presumido_ibs_cbs")  # o cCredPres: os grupos que cada código exige e se desconta do IBS
tabela_fiscal("mudancas_ibs_cbs")        # o que mudou nessas três de uma versão para a outra, com o prazo de produção
tabela_fiscal("aliquotas_ibs_cbs")       # as alíquotas do IBS e da CBS de cada ano, com a base legal
tabela_fiscal("marcos_ibs_cbs")          # as datas da Reforma que o pacote usa, cada uma com a base legal
tabela_fiscal("regras_ibs_cbs")          # as regras da NT 2025.002: código, mensagem e desde quando valem
tabela_fiscal("local_operacao_ibs_cbs")  # o cIndOp (local da operação), do Anexo VII da NFS-e Nacional
tabela_fiscal("biocombustivel_ibs_cbs")  # o etanol anidro obrigatório em cada gasolina C, com a vigência
tabela_fiscal("combustiveis_monofasicos") # os combustíveis do ICMS monofásico e a alíquota ad rem de cada período
tabela_fiscal("cst_icms")                # e "origem", "csosn", "cst_ipi", "cst_pis", "cst_cofins"
tabela_fiscal("cest")                    # o CEST da tabela do SPED, com a vigência de cada código
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
Siscomex (NCM), as tabelas do SPED Fiscal, da Receita (CSTs e CEST), e a API de localidades do IBGE (municípios).
O CEST traz as descrições até 31/08/2023; desde então o SPED só manda conferir o Convênio ICMS 142/18, e é esse o
texto que vem para as notas desse período (o do Confaz tem códigos com mais de uma redação em vigor, e não entrou).
O CST e a classificação do IBS e da CBS trazem os indicadores da planilha oficial (os grupos que cada um exige ou
não permite no documento e os documentos em que a classificação vale), que as regras de validação da NT 2025.002
consultam. As alíquotas do IBS e da CBS vêm da LC 214/2025: 0,1% de IBS da UF e 0,9% de CBS em 2026, e 0,05% de IBS
da UF e do município em 2027 e 2028; a CBS de 2027 e 2028 é a alíquota de referência que o Senado fixa menos 0,1
ponto percentual, e fica vazia até ser publicada. A tabela vai até 2028.

As datas da Reforma não estão no código: ficam em `tabela_fiscal("marcos_ibs_cbs")`, uma por linha, com a base
legal (por exemplo, a CBS ad rem no monofásico a partir de 2027, a nota de crédito do tipo 02 a partir de 2029, o ICMS
fora da base a partir de 2033). As regras de validação ficam em `tabela_fiscal("regras_ibs_cbs")`, com a data em que
cada uma entrou em produção; as que a NT deixa para implementação futura também estão lá, sem a data. Quando a lei ou
a NT muda uma data, muda a linha da tabela, e `tabelas_atualizar()` leva a mudança a quem já tem o pacote. Conferir
uma regra nova ainda pede o código dela, numa versão nova do pacote.
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

---

[Voltar ao início](../README.md)
