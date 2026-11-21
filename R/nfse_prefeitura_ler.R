# Leitura do XML da NFS-e de prefeitura (os padrões municipais, anteriores à NFS-e Nacional) em tabelas: o leiaute da
# Prefeitura de São Paulo (o tpNFe dos schemas da Nota Fiscal Paulistana) e o padrão ABRASF, nas versões 1.00 (também
# a do Ginfes, com prefixo no namespace) e 2.0x. Os três dão as mesmas colunas; o que um leiaute não tem fica NA.

#' @include ler_xml.R
NULL

# As notas de cada leiaute: o NFe de São Paulo (com o ChaveNFe, para não confundir com a NF-e) e o InfNfse da ABRASF.
# A busca é pelo nome local: o Ginfes usa prefixo no namespace, que a leitura não tira.
CAMINHO_DAS_NOTAS_DE_SAO_PAULO = "//*[local-name()='NFe'][*[local-name()='ChaveNFe']]"
CAMINHO_DAS_NOTAS_DA_ABRASF = "//*[local-name()='InfNfse']"
CAMINHO_DAS_NFSES_DE_PREFEITURA = paste(CAMINHO_DAS_NOTAS_DE_SAO_PAULO, CAMINHO_DAS_NOTAS_DA_ABRASF, sep = " | ")
# Nos caminhos da ABRASF 2, "Declaracao" é o InfDeclaracaoPrestacaoServico, onde fica o que o prestador declarou.
DECLARACAO_DA_ABRASF_2 = "DeclaracaoPrestacaoServico/InfDeclaracaoPrestacaoServico"

# Coluna e caminho em cada leiaute (a partir do NFe de São Paulo e do InfNfse da ABRASF), e tipo. "a|b" pega o que
# existir; "-" é o campo que o leiaute não tem. Os nomes dos caminhos seguem os schemas: TiposNFe_v02 de São Paulo, o
# nfse.xsd da ABRASF 1.00 e o da 2.04 (a 2.02, ainda comum, chama o tomador de Tomador e põe a identificação do
# prestador no PrestadorServico). O CodigoServico de São Paulo é o código do serviço na tabela do município, como o
# CodigoTributacaoMunicipio da ABRASF; o ItemListaServico da ABRASF é o item da lista da LC 116. O cancelamento da
# ABRASF vem do CompNfse, à parte (colunas_da_nfse_de_prefeitura).
CAMPOS_DA_NFSE_DE_PREFEITURA = ler_campos("
coluna                         sao_paulo                                           abrasf_1                                                                          abrasf_2                                                                                                      tipo
numero                         ChaveNFe/NumeroNFe                                  Numero                                                                            Numero                                                                                                        texto
codigo_verificacao             ChaveNFe/CodigoVerificacao                          CodigoVerificacao                                                                 CodigoVerificacao                                                                                             texto
chave_nacional                 ChaveNFe/ChaveNotaNacional                          -                                                                                 -                                                                                                             texto
emissao                        DataEmissaoNFe                                      DataEmissao                                                                       DataEmissao                                                                                                   texto
data_emissao                   DataEmissaoNFe                                      DataEmissao                                                                       DataEmissao                                                                                                   data
competencia                    DataFatoGeradorNFe                                  Competencia                                                                       Declaracao/Competencia                                                                                        data
situacao_codigo                StatusNFe                                           -                                                                                 -                                                                                                             texto
cancelamento                   DataCancelamento                                    -                                                                                 -                                                                                                             texto
nfse_substituida               -                                                   NfseSubstituida                                                                   NfseSubstituida                                                                                               texto
nfse_substituidora             -                                                   ../../NfseSubstituicao/SubstituicaoNfse/NfseSubstituidora                         ../../NfseSubstituicao/SubstituicaoNfse/NfseSubstituidora                                                     texto
municipio_gerador              -                                                   OrgaoGerador/CodigoMunicipio                                                      OrgaoGerador/CodigoMunicipio                                                                                  texto
uf_gerador                     -                                                   OrgaoGerador/Uf                                                                   OrgaoGerador/Uf                                                                                               texto
rps_numero                     ChaveRPS/NumeroRPS                                  IdentificacaoRps/Numero                                                           Declaracao/Rps/IdentificacaoRps/Numero                                                                        texto
rps_serie                      ChaveRPS/SerieRPS                                   IdentificacaoRps/Serie                                                            Declaracao/Rps/IdentificacaoRps/Serie                                                                         texto
rps_tipo                       TipoRPS                                             IdentificacaoRps/Tipo                                                             Declaracao/Rps/IdentificacaoRps/Tipo                                                                          texto
rps_emissao                    DataEmissaoRPS                                      DataEmissaoRps                                                                    Declaracao/Rps/DataEmissao                                                                                    data
prestador_documento            CPFCNPJPrestador/CNPJ|CPFCNPJPrestador/CPF          PrestadorServico/IdentificacaoPrestador/Cnpj|PrestadorServico/IdentificacaoPrestador/CpfCnpj/Cnpj|PrestadorServico/IdentificacaoPrestador/CpfCnpj/Cpf Declaracao/Prestador/CpfCnpj/Cnpj|Declaracao/Prestador/CpfCnpj/Cpf|PrestadorServico/IdentificacaoPrestador/CpfCnpj/Cnpj|PrestadorServico/IdentificacaoPrestador/CpfCnpj/Cpf texto
prestador_inscricao_municipal  ChaveNFe/InscricaoPrestador                         PrestadorServico/IdentificacaoPrestador/InscricaoMunicipal                        Declaracao/Prestador/InscricaoMunicipal|PrestadorServico/IdentificacaoPrestador/InscricaoMunicipal               texto
prestador_nome                 RazaoSocialPrestador                                PrestadorServico/RazaoSocial                                                      PrestadorServico/RazaoSocial                                                                                  texto
prestador_nome_fantasia        -                                                   PrestadorServico/NomeFantasia                                                     PrestadorServico/NomeFantasia                                                                                 texto
prestador_codigo_municipio     EnderecoPrestador/Cidade                            PrestadorServico/Endereco/CodigoMunicipio                                         PrestadorServico/Endereco/CodigoMunicipio                                                                     texto
prestador_uf                   EnderecoPrestador/UF                                PrestadorServico/Endereco/Uf                                                      PrestadorServico/Endereco/Uf                                                                                  texto
prestador_cep                  EnderecoPrestador/CEP                               PrestadorServico/Endereco/Cep                                                     PrestadorServico/Endereco/Cep                                                                                 texto
prestador_email                EmailPrestador                                      PrestadorServico/Contato/Email                                                    PrestadorServico/Contato/Email                                                                                texto
tomador_documento              CPFCNPJTomador/CNPJ|CPFCNPJTomador/CPF|CPFCNPJTomador/NIF TomadorServico/IdentificacaoTomador/CpfCnpj/Cnpj|TomadorServico/IdentificacaoTomador/CpfCnpj/Cpf Declaracao/TomadorServico/IdentificacaoTomador/CpfCnpj/Cnpj|Declaracao/TomadorServico/IdentificacaoTomador/CpfCnpj/Cpf|Declaracao/Tomador/IdentificacaoTomador/CpfCnpj/Cnpj|Declaracao/Tomador/IdentificacaoTomador/CpfCnpj/Cpf|Declaracao/TomadorServico/NifTomador texto
tomador_inscricao_municipal    InscricaoMunicipalTomador                           TomadorServico/IdentificacaoTomador/InscricaoMunicipal                            Declaracao/TomadorServico/IdentificacaoTomador/InscricaoMunicipal|Declaracao/Tomador/IdentificacaoTomador/InscricaoMunicipal texto
tomador_inscricao_estadual     InscricaoEstadualTomador                            -                                                                                 -                                                                                                             texto
tomador_nome                   RazaoSocialTomador                                  TomadorServico/RazaoSocial                                                        Declaracao/TomadorServico/RazaoSocial|Declaracao/Tomador/RazaoSocial                                          texto
tomador_codigo_municipio       EnderecoTomador/Cidade                              TomadorServico/Endereco/CodigoMunicipio                                           Declaracao/TomadorServico/Endereco/CodigoMunicipio|Declaracao/Tomador/Endereco/CodigoMunicipio                texto
tomador_uf                     EnderecoTomador/UF                                  TomadorServico/Endereco/Uf                                                        Declaracao/TomadorServico/Endereco/Uf|Declaracao/Tomador/Endereco/Uf                                          texto
tomador_cep                    EnderecoTomador/CEP                                 TomadorServico/Endereco/Cep                                                       Declaracao/TomadorServico/Endereco/Cep|Declaracao/Tomador/Endereco/Cep                                        texto
tomador_email                  EmailTomador                                        TomadorServico/Contato/Email                                                      Declaracao/TomadorServico/Contato/Email|Declaracao/Tomador/Contato/Email                                      texto
intermediario_documento        CPFCNPJIntermediario/CNPJ|CPFCNPJIntermediario/CPF  IntermediarioServico/CpfCnpj/Cnpj|IntermediarioServico/CpfCnpj/Cpf              Declaracao/Intermediario/IdentificacaoIntermediario/CpfCnpj/Cnpj|Declaracao/Intermediario/IdentificacaoIntermediario/CpfCnpj/Cpf texto
intermediario_inscricao_municipal InscricaoMunicipalIntermediario                  IntermediarioServico/InscricaoMunicipal                                           Declaracao/Intermediario/IdentificacaoIntermediario/InscricaoMunicipal                                         texto
intermediario_nome             -                                                   IntermediarioServico/RazaoSocial                                                  Declaracao/Intermediario/RazaoSocial                                                                          texto
item_lista_servico             -                                                   Servico/ItemListaServico                                                          Declaracao/Servico/ItemListaServico                                                                           texto
codigo_tributacao_municipio    CodigoServico                                       Servico/CodigoTributacaoMunicipio                                                 Declaracao/Servico/CodigoTributacaoMunicipio                                                                  texto
cnae                           -                                                   Servico/CodigoCnae                                                                Declaracao/Servico/CodigoCnae                                                                                 texto
nbs                            NBS                                                 -                                                                                 Declaracao/Servico/CodigoNbs                                                                                  texto
discriminacao                  Discriminacao                                       Servico/Discriminacao                                                             Declaracao/Servico/Discriminacao                                                                              texto
municipio_prestacao            MunicipioPrestacao|cLocPrestacao                    Servico/CodigoMunicipio                                                          Declaracao/Servico/CodigoMunicipio                                                                            texto
municipio_incidencia           -                                                   -                                                                                 Declaracao/Servico/MunicipioIncidencia                                                                        texto
natureza_operacao              -                                                   NaturezaOperacao                                                                  -                                                                                                             texto
exigibilidade_iss              -                                                   -                                                                                 Declaracao/Servico/ExigibilidadeISS                                                                           texto
tributacao                     TributacaoNFe                                       -                                                                                 -                                                                                                             texto
regime_especial                -                                                   RegimeEspecialTributacao                                                          Declaracao/RegimeEspecialTributacao                                                                           texto
optante_simples                OpcaoSimples                                        OptanteSimplesNacional                                                            Declaracao/OptanteSimplesNacional                                                                             texto
incentivador_cultural          -                                                   IncentivadorCultural                                                              -                                                                                                             texto
incentivo_fiscal               -                                                   -                                                                                 Declaracao/IncentivoFiscal                                                                                    texto
valor_servicos                 ValorServicos                                       Servico/Valores/ValorServicos                                                     Declaracao/Servico/Valores/ValorServicos                                                                      numero
valor_deducoes                 ValorDeducoes                                       Servico/Valores/ValorDeducoes                                                     Declaracao/Servico/Valores/ValorDeducoes                                                                      numero
desconto_incondicionado        -                                                   Servico/Valores/DescontoIncondicionado                                            Declaracao/Servico/Valores/DescontoIncondicionado                                                             numero
desconto_condicionado          -                                                   Servico/Valores/DescontoCondicionado                                              Declaracao/Servico/Valores/DescontoCondicionado                                                               numero
base_calculo                   -                                                   Servico/Valores/BaseCalculo                                                       ValoresNfse/BaseCalculo                                                                                       numero
aliquota                       AliquotaServicos                                    Servico/Valores/Aliquota                                                          ValoresNfse/Aliquota|Declaracao/Servico/Valores/Aliquota                                                      numero
valor_iss                      ValorISS                                            Servico/Valores/ValorIss                                                          ValoresNfse/ValorIss|Declaracao/Servico/Valores/ValorIss                                                      numero
iss_retido_codigo              ISSRetido                                           Servico/Valores/IssRetido                                                         Declaracao/Servico/IssRetido                                                                                  texto
valor_iss_retido               -                                                   Servico/Valores/ValorIssRetido                                                    -                                                                                                             numero
valor_pis                      ValorPIS                                            Servico/Valores/ValorPis                                                          Declaracao/Servico/Valores/ValorPis                                                                           numero
valor_cofins                   ValorCOFINS                                         Servico/Valores/ValorCofins                                                       Declaracao/Servico/Valores/ValorCofins                                                                        numero
valor_inss                     ValorINSS                                           Servico/Valores/ValorInss                                                         Declaracao/Servico/Valores/ValorInss                                                                          numero
valor_ir                       ValorIR                                             Servico/Valores/ValorIr                                                           Declaracao/Servico/Valores/ValorIr                                                                            numero
valor_csll                     ValorCSLL                                           Servico/Valores/ValorCsll                                                         Declaracao/Servico/Valores/ValorCsll                                                                          numero
outras_retencoes               -                                                   Servico/Valores/OutrasRetencoes                                                   Declaracao/Servico/Valores/OutrasRetencoes                                                                    numero
valor_liquido                  -                                                   Servico/Valores/ValorLiquidoNfse                                                  ValoresNfse/ValorLiquidoNfse                                                                                  numero
valor_credito                  ValorCredito                                        ValorCredito                                                                      ValorCredito                                                                                                  numero
valor_total_tributos           ValorCargaTributaria                                -                                                                                 Declaracao/Servico/Valores/ValTotTributos                                                                     numero
outras_informacoes             -                                                   OutrasInformacoes                                                                 OutrasInformacoes                                                                                             texto
")

# As versões da ABRASF 2 cujo manual diz que a alíquota vem em percentual ("Valor percentual. Formato: 00.00").
VERSOES_DA_ABRASF_COM_ALIQUOTA_EM_PERCENTUAL = c("2.02", "2.03", "2.04")

LEIAUTES_DA_NFSE_DE_PREFEITURA = c(sao_paulo ="S\u00e3o Paulo", abrasf_1 = "ABRASF 1", abrasf_2 = "ABRASF 2")

#' Ler o XML da NFS-e de prefeitura
#'
#' Lê o XML da NFS-e dos padrões municipais, anteriores à NFS-e Nacional, e
#' devolve uma lista de tabelas: `nfses` (uma linha por NFS-e, com as mesmas
#' colunas nos três leiautes), `campos` (todos os campos, um por linha) e
#' `arquivos` (o que foi lido e o motivo do que não deu). Lê:
#'
#' - o leiaute da Prefeitura de São Paulo (a NFS-e da Nota Fiscal Paulistana,
#'   raiz `NFe` com o `ChaveNFe`), também o da Reforma (versão 2 do schema,
#'   com a chave da nota no ambiente nacional);
#' - o padrão ABRASF 1.00 (o `InfNfse` com o `Servico` e o `TomadorServico`),
#'   também o do Ginfes, que usa prefixo no namespace;
#' - o padrão ABRASF 2.0x (o `InfNfse` com a `DeclaracaoPrestacaoServico`),
#'   nas versões 2.02 a 2.04.
#'
#' Cada município usa um desses leiautes ou um próprio; o arquivo de outro
#' leiaute fica em `arquivos`, com o motivo. A NFS-e Nacional é lida por
#' [nfse_ler()].
#'
#' A situação vem do próprio XML: a de São Paulo traz o status (normal,
#' cancelada, extraviada); na ABRASF, a nota cancelada ou substituída vem
#' dentro do `CompNfse`, com o cancelamento ou a substituição (com os dois, é
#' substituída: a substituta cancela a nota), e a nota sozinha (sem o
#' `CompNfse`) fica com a situação `NA`: o XML não diz.
#'
#' O código do serviço muda de sentido de um leiaute para o outro: o
#' `CodigoServico` de São Paulo é o da tabela de serviços do município e vai
#' para `codigo_tributacao_municipio`, como o da ABRASF; `item_lista_servico`
#' é o item da lista da Lei Complementar 116, que só a ABRASF traz.
#'
#' A alíquota vem como está no XML, e a escala muda de um leiaute para o
#' outro: São Paulo manda a fração (0,05 é 5%) e a ABRASF 2, o percentual
#' (5 é 5%); o Modelo Conceitual da ABRASF 1.00 não diz qual, e cada município
#' escolhe. `aliquota_percentual` traz o percentual onde o manual diz a escala
#' (São Paulo e as versões 2.02, 2.03 e 2.04 da ABRASF) e `NA` nas outras.
#'
#' @section nfses:
#' Uma linha por NFS-e: `identificacao` (o documento do prestador, o número e
#' o código de verificação, juntos: liga a NFS-e aos `campos`), `leiaute`
#' (`"São Paulo"`, `"ABRASF 1"` ou `"ABRASF 2"`), `versao` (a do `Nfse` da
#' ABRASF, quando vem), as colunas
#' `r paste0("\x60", CAMPOS_DA_NFSE_DE_PREFEITURA$coluna, "\x60", collapse = ", ")`,
#' e ainda `situacao` (Normal, Cancelada, Substituída ou Extraviada),
#' `iss_retido` (`TRUE` ou `FALSE`), `aliquota_percentual` e `arquivo`.
#' `emissao` e `cancelamento` ficam como estão no XML (texto): os padrões
#' municipais não trazem o fuso, e a hora é a do município; `data_emissao`,
#' `competencia` e `rps_emissao` são datas (a competência em AAAAMM, como o
#' Modelo Conceitual da ABRASF 1.00 descreve, vira o dia 1º do mês; outro
#' formato fica `NA`, com o texto nos `campos`). Os municípios vêm pelo código
#' do IBGE.
#'
#' @section campos:
#' Com `todos_os_campos = TRUE`, o padrão. Todos os campos de cada NFS-e,
#' menos os da assinatura digital (o `Signature` e, em São Paulo, a
#' `Assinatura`), um por linha: `identificacao`, `caminho`
#' (a partir do `NFe` de São Paulo ou do `InfNfse` da ABRASF, sem os
#' prefixos), `grupo`, `campo` e `valor`.
#'
#' @section arquivos:
#' Uma linha por arquivo pedido: `arquivo`, `nfses` (quantas NFS-e tinha) e
#' `problema` (`NA` quando deu certo).
#'
#' @inheritParams nfse_ler
#' @return Uma lista com os `data.frame`s `nfses`, `campos` (só com
#'   `todos_os_campos = TRUE`) e `arquivos`.
#' @seealso [nfse_ler()] para a NFS-e Nacional.
#' @source Prefeitura de São Paulo: os schemas TiposNFe_v02 (o pacote da
#'   Reforma Tributária, versão 2) e o Manual de Utilização do Web Service,
#'   versão 3.3.4; ABRASF: o schema nfse.xsd e o Modelo Conceitual da versão
#'   1.00 (29/12/2008) e o schema e o Manual de Orientação do Contribuinte da
#'   versão 2.04 (setembro de 2018), da biblioteca pública da ABRASF, e os
#'   Manuais de Integração das versões 2.02 (novembro de 2012) e 2.03
#'   (fevereiro de 2016), para a escala da alíquota.
#' @examples
#' nfse = system.file("exemplos", "nfse_prefeitura_sp.xml", package = "RNFe")
#' lida = nfse_prefeitura_ler(nfse)
#' lida$nfses[, c("leiaute", "numero", "prestador_documento", "valor_servicos",
#'                "valor_iss", "situacao")]
#' @export
nfse_prefeitura_ler = function(arquivos, todos_os_campos = TRUE) {
  arquivos_lidos = ler_arquivos_xml(arquivos, CAMINHO_DAS_NFSES_DE_PREFEITURA, "uma NFS-e de prefeitura",
                                    colunas_da_nfse_de_prefeitura, todos_os_campos)
  colunas_vazias = colunas_da_nfse_de_prefeitura(NULL, NA_character_, todos_os_campos)
  tabelas = list(nfses = juntar_tabela(arquivos_lidos, "nfses", colunas_vazias$nfses))
  if (todos_os_campos) {
    tabelas$campos = juntar_tabela(arquivos_lidos, "campos", colunas_vazias$campos)
  }
  tabelas$arquivos = resumo_dos_arquivos_da_prefeitura(arquivos_lidos)
  tabelas$nfses = completar_as_nfses_de_prefeitura(tabelas$nfses)
  tabelas
}

# As colunas das tabelas de um arquivo, cada uma num vetor; com xml_lido NULL, vazias, com os nomes e os tipos certos.
colunas_da_nfse_de_prefeitura = function(xml_lido, nome_do_arquivo, todos_os_campos) {
  if (is.null(xml_lido)) {
    xml_lido = xml2::read_xml("<vazio/>")
  }
  notas_de_sao_paulo = xml2::xml_find_all(xml_lido, CAMINHO_DAS_NOTAS_DE_SAO_PAULO)
  notas_da_abrasf = xml2::xml_find_all(xml_lido, CAMINHO_DAS_NOTAS_DA_ABRASF)
  # O InfNfse da ABRASF 2 tem a DeclaracaoPrestacaoServico; o da 1.00, não.
  declaracao_de_cada = xml2::xml_find_first(notas_da_abrasf, "./*[local-name()='DeclaracaoPrestacaoServico']")
  da_abrasf_2 = !is.na(xml2::xml_name(declaracao_de_cada))
  grupos = list(sao_paulo = notas_de_sao_paulo, abrasf_1 = notas_da_abrasf[!da_abrasf_2], abrasf_2 = notas_da_abrasf[da_abrasf_2])
  nfses = list()
  campos = list()
  for (leiaute in names(grupos)) {
    notas = grupos[[leiaute]]
    caminhos = CAMPOS_DA_NFSE_DE_PREFEITURA[[leiaute]]
    caminhos = gsub("Declaracao/", paste0(DECLARACAO_DA_ABRASF_2, "/"), caminhos, fixed = TRUE)
    lista_de_campos = data.frame(coluna = CAMPOS_DA_NFSE_DE_PREFEITURA$coluna, caminho = caminhos,
                                 tipo = CAMPOS_DA_NFSE_DE_PREFEITURA$tipo)
    valores = valores_pelo_nome_local(notas, lista_de_campos)
    identificacao = paste(valores$prestador_documento, valores$numero, valores$codigo_verificacao, sep = "-")
    versao = if (leiaute == "sao_paulo") rep(NA_character_, length(notas)) else
      xml2::xml_attr(xml2::xml_find_first(notas, "parent::*[local-name()='Nfse']"), "versao")
    # Na ABRASF, a nota dentro do CompNfse vem com o cancelamento ou a substituição, quando houve. A data do cancelamento
    # muda de nome e de lugar (DataHoraCancelamento na 1.00, DataHora na 2.04): vale a que estiver no NfseCancelamento.
    comp_nfse_de_cada = xml2::xml_find_first(notas, "parent::*/parent::*[local-name()='CompNfse']")
    cancelamento_de_cada = xml2::xml_find_first(comp_nfse_de_cada, "./*[local-name()='NfseCancelamento']")
    substituicao_de_cada = xml2::xml_find_first(comp_nfse_de_cada, "./*[local-name()='NfseSubstituicao']")
    if (leiaute != "sao_paulo") {
      data_do_cancelamento = xml2::xml_find_first(
        cancelamento_de_cada, ".//*[local-name()='DataHoraCancelamento' or local-name()='DataHora']"
      )
      valores$cancelamento = xml2::xml_text(data_do_cancelamento)
    }
    nfses[[leiaute]] = c(list(identificacao = identificacao, leiaute = rep(LEIAUTES_DA_NFSE_DE_PREFEITURA[[leiaute]], length(notas)),
                              versao = versao),
                         valores, list(dentro_do_comp_nfse = !is.na(xml2::xml_name(comp_nfse_de_cada)),
                                       com_cancelamento = !is.na(xml2::xml_name(cancelamento_de_cada)),
                                       com_substituicao = !is.na(xml2::xml_name(substituicao_de_cada)),
                                       arquivo = rep(nome_do_arquivo, length(notas))))
    if (todos_os_campos) {
      campos[[leiaute]] = campos_da_nfse_de_prefeitura(notas, identificacao)
    }
  }
  colunas = list(nfses = juntar_os_leiautes(nfses))
  if (todos_os_campos) {
    colunas$campos = juntar_os_leiautes(campos)
  }
  colunas
}

# Junta as colunas dos três leiautes, na ordem das do primeiro.
juntar_os_leiautes = function(colunas_de_cada_leiaute) {
  juntas = colunas_de_cada_leiaute[[1]]
  for (nome_da_coluna in names(juntas)) {
    pedacos = list()
    for (leiaute in names(colunas_de_cada_leiaute)) {
      pedacos[[leiaute]] = colunas_de_cada_leiaute[[leiaute]][[nome_da_coluna]]
    }
    juntas[[nome_da_coluna]] = do.call(c, unname(pedacos))
  }
  juntas
}

# Uma coluna por campo, já no tipo certo (as datas ficam como texto), buscando cada passo pelo nome local; "-" é o
# campo que o leiaute não tem.
valores_pelo_nome_local = function(notas, lista_de_campos) {
  colunas = list()
  for (numero_do_campo in seq_len(nrow(lista_de_campos))) {
    coluna = lista_de_campos$coluna[numero_do_campo]
    caminho = lista_de_campos$caminho[numero_do_campo]
    if (caminho == "-") {
      textos = rep(NA_character_, length(notas))
    } else {
      textos = xml2::xml_text(xml2::xml_find_first(notas, caminho_pelo_nome_local(caminho)))
    }
    if (lista_de_campos$tipo[numero_do_campo] == "numero") {
      colunas[[coluna]] = as.numeric(textos)
    } else {
      colunas[[coluna]] = textos
    }
  }
  colunas
}

# "a/b|c" vira o XPath que busca cada passo pelo nome local, sem olhar o namespace ("..", o grupo de cima, fica igual).
caminho_pelo_nome_local = function(caminho) {
  alternativas = character()
  for (alternativa in strsplit(caminho, "|", fixed = TRUE)[[1]]) {
    passos = strsplit(alternativa, "/", fixed = TRUE)[[1]]
    passos_do_xpath = ifelse(passos == "..", "..", paste0("*[local-name()='", passos, "']"))
    alternativas = c(alternativas, paste0("./", paste(passos_do_xpath, collapse = "/")))
  }
  paste(alternativas, collapse = " | ")
}

# Todos os campos (os elementos sem filhos) de cada NFS-e, menos os da assinatura digital (o Signature e, em São Paulo,
# a Assinatura da NFS-e), com o caminho a partir da nota e sem os prefixos do namespace.
CAMINHO_DOS_CAMPOS_DA_NFSE_DE_PREFEITURA = paste0(".//*[not(*)][not(ancestor::*[local-name()='Signature'])]",
                                                  "[not(local-name()='Assinatura')]")

campos_da_nfse_de_prefeitura = function(notas, identificacao) {
  colunas = list(identificacao = character(), caminho = character(), grupo = character(), campo = character(),
                 valor = character())
  for (posicao in seq_along(notas)) {
    folhas = xml2::xml_find_all(notas[[posicao]], CAMINHO_DOS_CAMPOS_DA_NFSE_DE_PREFEITURA)
    # O caminho de cada campo começa no da nota: o resto dele é o caminho a partir dela.
    caminhos = substring(xml2::xml_path(folhas), nchar(xml2::xml_path(notas[[posicao]])) + 2)
    grupos = xml2::xml_name(xml2::xml_find_first(folhas, "parent::*"))
    colunas$identificacao = c(colunas$identificacao, rep(identificacao[posicao], length(folhas)))
    colunas$caminho = c(colunas$caminho, gsub("[A-Za-z0-9_.-]+:", "", caminhos))
    colunas$grupo = c(colunas$grupo, sub("^.*:", "", grupos))
    colunas$campo = c(colunas$campo, sub("^.*:", "", xml2::xml_name(folhas)))
    colunas$valor = c(colunas$valor, xml2::xml_text(folhas))
  }
  colunas
}

# Uma linha por arquivo: o nome, quantas NFS-e tinha e o problema (a contagem pela identificação).
resumo_dos_arquivos_da_prefeitura = function(arquivos_lidos) {
  for (posicao in seq_along(arquivos_lidos)) {
    arquivos_lidos[[posicao]]$nfses$chave = arquivos_lidos[[posicao]]$nfses$identificacao
  }
  resumo_dos_arquivos(arquivos_lidos, "nfses", "nfses")
}

# As datas, a situação, o ISS retido e a alíquota em percentual.
completar_as_nfses_de_prefeitura = function(nfses) {
  # A data e hora ficam como no XML: os padrões municipais não trazem o fuso, e a hora é a do município.
  nfses$data_emissao = data_da_nfse_de_prefeitura(nfses$data_emissao)
  nfses$competencia = data_da_nfse_de_prefeitura(nfses$competencia)
  nfses$rps_emissao = data_da_nfse_de_prefeitura(nfses$rps_emissao)
  situacao = rep(NA_character_, nrow(nfses))
  de_sao_paulo = nfses$leiaute == LEIAUTES_DA_NFSE_DE_PREFEITURA[["sao_paulo"]]
  situacao[de_sao_paulo] = c(N = "Normal", C = "Cancelada", E = "Extraviada")[nfses$situacao_codigo[de_sao_paulo]]
  # Na ABRASF, o CompNfse diz: com o cancelamento, cancelada; com a substituição, substituída (a substituta cancela a
  # nota, e o CompNfse pode trazer os dois); sem os dois, normal. Sem o CompNfse (só a nota), o XML não diz a situação.
  da_abrasf = !de_sao_paulo
  situacao[da_abrasf & nfses$dentro_do_comp_nfse] = "Normal"
  situacao[da_abrasf & nfses$com_cancelamento] = "Cancelada"
  situacao[da_abrasf & nfses$com_substituicao] = "Substitu\u00edda"
  nfses = inserir_coluna_depois(nfses, "situacao", situacao, "situacao_codigo")
  nfses$dentro_do_comp_nfse = NULL
  nfses$com_cancelamento = NULL
  nfses$com_substituicao = NULL
  # São Paulo usa o boolean do XML Schema (true, false, 1 ou 0); a ABRASF, 1 (sim) e 2 (não).
  iss_retido = rep(NA, nrow(nfses))
  iss_retido[de_sao_paulo & nfses$iss_retido_codigo %in% c("true", "1")] = TRUE
  iss_retido[de_sao_paulo & nfses$iss_retido_codigo %in% c("false", "0")] = FALSE
  iss_retido[da_abrasf & nfses$iss_retido_codigo %in% "1"] = TRUE
  iss_retido[da_abrasf & nfses$iss_retido_codigo %in% "2"] = FALSE
  nfses = inserir_coluna_depois(nfses, "iss_retido", iss_retido, "iss_retido_codigo")
  # O percentual só onde o manual diz a escala: São Paulo (a fração) e as ABRASF 2.02, 2.03 e 2.04 (o percentual, nos
  # Manuais de Integração 2.02 e 2.03 e no Manual de Orientação do Contribuinte 2.04).
  percentual = rep(NA_real_, nrow(nfses))
  percentual[de_sao_paulo] = round(nfses$aliquota[de_sao_paulo] * 100, 4)
  em_percentual = nfses$leiaute == LEIAUTES_DA_NFSE_DE_PREFEITURA[["abrasf_2"]] &
    nfses$versao %in% VERSOES_DA_ABRASF_COM_ALIQUOTA_EM_PERCENTUAL
  percentual[em_percentual] = nfses$aliquota[em_percentual]
  nfses = inserir_coluna_depois(nfses, "aliquota_percentual", percentual, "aliquota")
  nfses
}

# A data do texto do XML: a data ISO (AAAA-MM-DD, com ou sem a hora) e a competência em AAAAMM do Modelo Conceitual
# da ABRASF 1.00, que vira o dia 1º do mês; outro formato fica NA (o texto continua nos campos).
data_da_nfse_de_prefeitura = function(textos) {
  datas = as.Date(rep(NA_character_, length(textos)))
  no_formato_iso = grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}", textos)
  datas[no_formato_iso] = as.Date(substr(textos[no_formato_iso], 1, 10), format = "%Y-%m-%d")
  so_mes_e_ano = grepl("^[0-9]{6}$", textos)
  datas[so_mes_e_ano] = as.Date(paste0(substr(textos[so_mes_e_ano], 1, 4), "-", substr(textos[so_mes_e_ano], 5, 6), "-01"),
                                format = "%Y-%m-%d")
  datas
}
