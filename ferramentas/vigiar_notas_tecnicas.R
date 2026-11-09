# Olha a lista de notas técnicas do Portal da NF-e e escreve um aviso para cada uma que ainda não está em
# ferramentas/notas_tecnicas_vistas.csv. Uso, na raiz do repositório:
#   Rscript ferramentas/vigiar_notas_tecnicas.R <pasta dos avisos>
#   Rscript ferramentas/vigiar_notas_tecnicas.R --registrar
# Uma nota técnica nova (ou uma versão nova dela) pode mudar as regras de validação que a pré-conferência
# (nfe_conferir) e a conferência da Reforma (ibs_cbs_conferir) seguem: conferir é trabalho de uma pessoa. O robô
# (.github/workflows/vigiar-schemas.yml) abre um aviso (issue) por arquivo, como os dos schemas. "--registrar" grava
# tudo o que o portal lista hoje: rodar depois de conferir as regras.

source("ferramentas/schemas.R", encoding = "UTF-8")

PAGINA_DAS_NOTAS_TECNICAS = "https://www.nfe.fazenda.gov.br/portal/listaConteudo.aspx?tipoConteudo=04BIflQt1aY="
NOTAS_TECNICAS_VISTAS = "ferramentas/notas_tecnicas_vistas.csv"

listar_notas_tecnicas = function(pasta_temporaria) {
  pagina_da_lista = abrir_pagina("nfe_notas_tecnicas", PAGINA_DAS_NOTAS_TECNICAS, pasta_temporaria)
  links_da_pagina = links_dos_portais_da_nfe_e_do_cte(pagina_da_lista, PAGINA_DAS_NOTAS_TECNICAS)
  if (length(links_da_pagina$links) == 0) {
    stop("A página das notas técnicas não tem mais os links de download: ", PAGINA_DAS_NOTAS_TECNICAS, call. = FALSE)
  }
  titulos = gsub("\\s+", " ", trimws(xml2::xml_text(links_da_pagina$links)))
  notas_tecnicas = data.frame(titulo = titulos, endereco = unname(links_da_pagina$enderecos))
  notas_tecnicas[!duplicated(notas_tecnicas$titulo), ]
}

escrever_aviso_da_nota_tecnica = function(nota_tecnica, pasta_dos_avisos, numero_do_aviso) {
  titulo_do_aviso = substr(paste0("Nota técnica nova no portal da NF-e: ", nota_tecnica$titulo), 1, 250)
  linhas_do_aviso = c(
    titulo_do_aviso,
    paste0("O portal da NF-e publicou: **", nota_tecnica$titulo, "**"),
    "",
    paste0("Endereço: ", nota_tecnica$endereco),
    "",
    paste0("O que fazer: ler a tabela de versões do começo da nota técnica (as regras de validação alteradas, criadas ",
           "e excluídas, e a data de produção de cada versão) e conferir se ela muda alguma regra de ",
           "`inst/extdata/regras_nfe.csv` (a pré-conferência) ou de `inst/extdata/tabelas/regras_ibs_cbs.csv` (a ",
           "Reforma: as regras de implementação futura estão lá, sem data) e se muda alguma data de ",
           "`inst/extdata/tabelas/marcos_ibs_cbs.csv`. O texto que sai vem riscado: confira na página do PDF, não no ",
           "texto copiado. Mexeu numa tabela, rodar `Rscript ferramentas/gerar_conferencia_das_tabelas.R`. Depois, rodar ",
           "`Rscript ferramentas/vigiar_notas_tecnicas.R --registrar`.")
  )
  arquivo_do_aviso = file.path(pasta_dos_avisos, sprintf("nt_%03d.md", numero_do_aviso))
  conexao_com_o_arquivo = file(arquivo_do_aviso, "w", encoding = "UTF-8")
  writeLines(linhas_do_aviso, conexao_com_o_arquivo)
  close(conexao_com_o_arquivo)
  titulo_do_aviso
}

argumentos = commandArgs(trailingOnly = TRUE)
if (length(argumentos) != 1) {
  stop("Uso: Rscript ferramentas/vigiar_notas_tecnicas.R <pasta dos avisos> | --registrar", call. = FALSE)
}
pasta_temporaria = tempfile("vigia_das_notas_tecnicas_")
dir.create(pasta_temporaria)
notas_tecnicas_de_hoje = listar_notas_tecnicas(pasta_temporaria)
if (argumentos[1] == "--registrar") {
  gravar_csv(notas_tecnicas_de_hoje, NOTAS_TECNICAS_VISTAS)
  cat("Registradas", nrow(notas_tecnicas_de_hoje), "notas técnicas em", NOTAS_TECNICAS_VISTAS, "\n")
} else {
  pasta_dos_avisos = argumentos[1]
  dir.create(pasta_dos_avisos, showWarnings = FALSE, recursive = TRUE)
  ja_vistas = ler_csv(NOTAS_TECNICAS_VISTAS)
  novas = notas_tecnicas_de_hoje[!(notas_tecnicas_de_hoje$titulo %in% ja_vistas$titulo), ]
  for (numero in seq_len(nrow(novas))) {
    cat("Aviso:", escrever_aviso_da_nota_tecnica(novas[numero, ], pasta_dos_avisos, numero), "\n")
  }
  cat("Notas técnicas novas:", nrow(novas), "\n")
}
