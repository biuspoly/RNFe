# RNFe

Pacote em R de documentos fiscais eletrônicos brasileiros (NF-e, NFC-e, CT-e, MDF-e, NFS-e): chave de acesso,
leitura do XML, tabelas fiscais e, mais adiante, certificado e SEFAZ. Projeto pessoal do Marlon (biuspoly),
parte do portfólio, irmão do `veiculosbr`. Só em R (decisão do usuário, 29/10/2026: no Python já existe o
PyNFe). O nome é **RNFe**, com o F maiúsculo como o PyNFe (era RNfe até 30/10/2026). O plano e a situação
ficam em `docs/plano.md`; o README é o que quem usa o pacote lê.

## Testar

- Mudou documentação ou export: `roxygen2::roxygenise()` na raiz.
- `R CMD build .` e `R CMD check --as-cran --no-manual RNFe_*.tar.gz` (sem LaTeX nesta máquina), fora da
  pasta do pacote. O R fica em `C:\Program Files\R\R-4.6.1\bin`, fora do PATH; no PowerShell, `R` é o alias
  de `Invoke-History`: chamar `R.exe`/`Rscript.exe` pelo caminho inteiro e rodar R por arquivo `.R`.

## Regras

- **Responder em português (PT-BR).** Código, nomes de função e documentação também.
- **Escrever como o usuário escreve**: nomes descritivos, nada de `x`, `df`, `tmp`, `i`; `=` para atribuir,
  R base, passo a passo com `if`/`else`. Comentário só para o "porquê".
- **Nada da empresa entra aqui.** O usuário trabalha num grupo de revendas, e o código de lá (ERP, revendas,
  CNPJs, regras internas) não pode ser copiado. O plano cita arquivos do projeto da empresa só como lista do
  que fazer: nunca copiar nem traduzir linha a linha. Tudo é escrito do zero pela especificação pública
  (Manual de Orientação do Contribuinte, notas técnicas, schemas).
- **Dados de teste inventados.** CNPJ só os fictícios (11.222.333/0001-81, 11.444.777/0001-61) e o exemplo da
  Receita (12.ABC.345/01DE-35); CPF 123.456.789-09. Nota de teste é XML montado à mão, nunca uma nota real
  com os números trocados.
- **Toda regra diz de onde vem**: o manual ou a nota técnica, com a versão, no `@source` da função e no
  README. Exemplo de teste com resultado calculado à parte (pelo algoritmo do anexo da NT), não pelo próprio
  pacote.
- **Lista pública enxuta**: só o que o plano prevê; peça interna fica interna.
- **CRAN:** strings do código R só em ASCII, com `\u00e3` no lugar do acento (comentário e roxygen podem ter
  acento). A ferramenta de escrita de arquivo transforma `\u00e3` na própria letra: depois de escrever um
  `.R`, converter de volta e conferir com `R CMD check` ("code files for non-ASCII characters").
- **Autor e mantenedor: Marlon Amaral <marlonsouzapro@outlook.com>.** Nunca deduzir nome de e-mail.
- **Sem emoji em arquivo-fonte**, nem em comentário.
