EXEMPLO_DA_NFE = system.file("exemplos", "nfe_proc_sp.xml", package = "RNFe")

# O infNFe de um XML, na forma canônica (o que a assinatura cobre).
info_canonico = function(xml) {
  documento = xml2::read_xml(xml, options = "NOBLANKS")
  xml_canonico(xml2::xml_find_first(documento, "//*[local-name()='infNFe']"))
}

campo_montado = function(xml, campo) {
  xml2::xml_text(xml2::xml_find_all(xml2::read_xml(xml), paste0("//*[local-name()='", campo, "']")))
}

test_that("a NF-e e a NFC-e de exemplo voltam iguais, byte a byte, pela lista", {
  for (exemplo in c("nfe_proc_sp.xml", "nfe_ce_simples_cpf.xml", "nfce_ce_contingencia.xml")) {
    arquivo = system.file("exemplos", exemplo, package = "RNFe")
    montada = nfe_montar(xml_para_lista(arquivo))
    expect_identical(info_canonico(montada), info_canonico(arquivo), info = exemplo)
  }
})

test_that("os campos podem vir em qualquer ordem: sai a ordem do schema", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide = rev(nota$ide)
  nota$emit$enderEmit = rev(nota$emit$enderEmit)
  nota = rev(nota)
  expect_identical(info_canonico(nfe_montar(nota)), info_canonico(EXEMPLO_DA_NFE))
})

test_that("o n\u00famero sai com as casas do tipo do campo, e a data e hora do R com o fuso", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$cNF = NULL
  nota$ide$cDV = NULL
  nota$Id = NULL
  # TDec_1302: duas casas; TDec_1104v: de 1 a 4 casas; TDec_1110v: de 1 a 10 casas.
  nota$det[[1]]$prod$vProd = 50
  nota$det[[1]]$prod$qCom = 10
  nota$det[[1]]$prod$vUnCom = 5
  nota$det[[1]]$prod$vUnTrib = 4.25
  nota$ide$dhEmi = as.POSIXct("2026-11-11 10:00:00", tz = "America/Recife")
  nota$ide$dhSaiEnt = NULL
  nota$cobr$dup[[1]]$dVenc = as.Date("2026-12-11")
  # TDec_1302Opc (o vDup e o vDesc do item): duas casas, e o padrão tem alternativas de uma casa só para o zero.
  nota$cobr$dup[[1]]$vDup = 57.5
  nota$cobr$dup[[2]]$vDup = 57.5
  nota$det[[1]]$prod$vDesc = 5
  nota$total$ICMSTot$vDesc = 0.3 - 0.1 - 0.2
  montada = nfe_montar(nota)
  expect_identical(campo_montado(montada, "vProd")[1], "50.00")
  expect_identical(campo_montado(montada, "qCom")[1], "10.0")
  expect_identical(campo_montado(montada, "vUnCom")[1], "5.0")
  expect_identical(campo_montado(montada, "vUnTrib")[1], "4.25")
  expect_identical(campo_montado(montada, "dhEmi"), "2026-11-11T10:00:00-03:00")
  expect_identical(campo_montado(montada, "dVenc")[1], "2026-12-11")
  expect_identical(campo_montado(montada, "vDup"), c("57.50", "57.50"))
  expect_identical(xml2::xml_text(xml2::xml_find_first(xml2::read_xml(montada), "//*[local-name()='prod']/*[local-name()='vDesc']")),
                   "5.00")
  # O zero da conta (0.3 - 0.1 - 0.2 dá -2.8e-17) sai 0.00, sem o sinal.
  expect_identical(xml2::xml_text(xml2::xml_find_first(xml2::read_xml(montada), "//*[local-name()='ICMSTot']/*[local-name()='vDesc']")),
                   "0.00")
  # A data entra no AAMM da chave.
  expect_identical(substr(xml2::xml_attr(xml2::xml_find_first(xml2::read_xml(montada), "//*[local-name()='infNFe']"),
                                         "Id"), 6, 9), "2611")
})

test_that("o c\u00f3digo que perdeu o zero \u00e0 esquerda volta a ter, e o campo de um valor s\u00f3 entra sozinho", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$pag$detPag[[1]]$tPag = 1
  nota$det[[1]]$imposto$PIS$PISAliq$CST = 1
  nota$det[[1]]$imposto$ICMS$ICMS00$CST = NULL
  # O CST do IBS e da CBS é "\d{3}" e a classificação, "\d{6}".
  nota$det[[1]]$imposto$IBSCBS$CST = 0
  nota$det[[1]]$imposto$IBSCBS$cClassTrib = 1
  nota$ide$cNF = 345
  nota$ide$cDV = NULL
  nota$Id = NULL
  montada = nfe_montar(nota)
  documento = xml2::read_xml(montada)
  expect_identical(campo_montado(montada, "tPag"), "01")
  expect_identical(xml2::xml_text(xml2::xml_find_first(documento, "//*[local-name()='PISAliq']/*[local-name()='CST']")), "01")
  # O CST do ICMS00 só aceita "00": ele entra mesmo sem vir.
  expect_identical(xml2::xml_text(xml2::xml_find_first(documento, "//*[local-name()='ICMS00']/*[local-name()='CST']")), "00")
  expect_identical(xml2::xml_text(xml2::xml_find_first(documento, "//*[local-name()='IBSCBS']/*[local-name()='CST']")), "000")
  expect_identical(xml2::xml_text(xml2::xml_find_first(documento, "//*[local-name()='IBSCBS']/*[local-name()='cClassTrib']")),
                   "000001")
  # O cNF é "[0-9]{8}": o número ganha os zeros.
  expect_identical(campo_montado(montada, "cNF"), "00000345")
})

test_that("o n\u00famero que n\u00e3o diz o zero \u00e0 esquerda, o grande demais e o nome repetido s\u00e3o recusados", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$dest$IE = 61234567
  expect_error(nfe_montar(nota), "dest/IE aceita zeros \u00e0 esquerda .*informe como texto")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$emit$enderEmit$fone = 8533334444
  expect_error(nfe_montar(nota), "enderEmit/fone aceita zeros \u00e0 esquerda")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$NFref = list(refNFe = 35261011222333000181550010000010011123456785)
  expect_error(nfe_montar(nota), "NFref/refNFe recebeu um n\u00famero grande demais")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$det[[1]]$prod = c(nota$det[[1]]$prod, list(vProd = 99))
  expect_error(nfe_montar(nota), "\"vProd\" aparece mais de uma vez em NFe/infNFe/det/prod")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$serie = "1a"
  expect_no_warning(expect_error(nfe_montar(nota), "n\u00e3o formam uma chave"))
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$dhEmi = c("2026-10-15T10:30:00-03:00", "2026-10-16T10:30:00-03:00")
  expect_error(nfe_montar(nota), "ide/dhEmi recebeu mais de um valor")
})

test_that("o texto com caractere de controle ou fora do UTF-8 e o fator vazio", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$emit$xNome = "EMPRESA\001TESTE"
  expect_error(nfe_montar(nota), "emit/xNome tem um caractere de controle")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  sem_marca = rawToChar(as.raw(c(0x53, 0xc3, 0x4f)))
  Encoding(sem_marca) = "unknown"
  nota$emit$xFant = sem_marca
  expect_error(nfe_montar(nota), "emit/xFant tem um texto que n\u00e3o est\u00e1 em UTF-8")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$compra = list(xPed = factor(""))
  expect_false(grepl("<compra>", nfe_montar(nota), fixed = TRUE))
})

test_that("a chave sai dos campos: o exemplo do chave_digito()", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$emit$CNPJ = "11444777000161"
  nota$ide$nNF = 123
  nota$ide$cNF = "12345678"
  nota$ide$cDV = NULL
  nota$Id = NULL
  montada = nfe_montar(nota)
  informacao = xml2::xml_find_first(xml2::read_xml(montada), "//*[local-name()='infNFe']")
  expect_identical(xml2::xml_attr(informacao, "Id"), "NFe35261011444777000161550010000001231123456783")
  expect_identical(campo_montado(montada, "cDV"), "3")
})

test_that("o c\u00f3digo num\u00e9rico sorteado fica fora dos que a SEFAZ recusa, e a chave confere", {
  skip_if_not_installed("openssl")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$cDV = NULL
  nota$Id = NULL
  codigos = character()
  for (vez in 1:30) {
    nota$ide$cNF = NULL
    montada = nfe_montar(nota)
    codigo = campo_montado(montada, "cNF")
    codigos = c(codigos, codigo)
    expect_match(codigo, "^[0-9]{8}$")
    expect_false(codigo %in% CODIGOS_NUMERICOS_PROIBIDOS)
    expect_false(codigo == "00001001")
    identificador = xml2::xml_attr(xml2::xml_find_first(xml2::read_xml(montada), "//*[local-name()='infNFe']"), "Id")
    expect_true(chave_valida(identificador))
  }
  expect_gt(length(unique(codigos)), 25)
  # O sorteio é do gerador do sistema: não depende do set.seed nem mexe no gerador do R de quem usa.
  set.seed(1)
  gerador_antes = .Random.seed
  nota$ide$cNF = NULL
  primeiro = campo_montado(nfe_montar(nota), "cNF")
  expect_identical(.Random.seed, gerador_antes)
  set.seed(1)
  nota$ide$cNF = NULL
  segundo = campo_montado(nfe_montar(nota), "cNF")
  expect_false(identical(primeiro, segundo))
  # O sorteio passa por cima de um código recusado (12345678) e do número do documento (1001, com os zeros).
  sorteios = c(12345678L, 1001L, 4566L)
  vez_do_sorteio = 0
  sortear_o_proximo = function() {
    vez_do_sorteio <<- vez_do_sorteio + 1
    sorteios[vez_do_sorteio]
  }
  local_mocked_bindings(numero_sorteado = sortear_o_proximo)
  expect_identical(sortear_codigo_numerico(1001), "00004566")
  expect_identical(vez_do_sorteio, 3)
})

test_that("a NF-e avulsa leva na chave o CNPJ do \u00f3rg\u00e3o do Fisco", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$cDV = NULL
  nota$Id = NULL
  nota$ide$cNF = "12345678"
  nota$ide$nNF = 123
  nota$ide$serie = 890
  nota$ide$procEmi = "1"
  nota$avulsa = list(CNPJ = "11444777000161")
  completada = completar_a_chave(nota, "NFe", "nNF", "cNF", cnpj_no_lugar = cnpj_da_chave_da_avulsa(nota))
  # A chave sem o dígito, com o CNPJ do grupo avulsa, e o dígito calculado à parte (módulo 11, pesos de 2 a 9).
  sem_digito = "3526101144477700016155890000000123112345678"
  algarismos = as.integer(strsplit(sem_digito, "")[[1]])
  pesos = rev(rep(2:9, length.out = 43))
  resto = sum(algarismos * pesos) %% 11
  digito_esperado = if (resto < 2) 0 else 11 - resto
  expect_identical(completada$Id, paste0("NFe", sem_digito, digito_esperado))
  # Sem o procEmi 1, a chave leva o CNPJ do emitente; no procEmi 2, a regra não foi conferida, e a montagem para.
  nota$ide$procEmi = "0"
  expect_identical(cnpj_da_chave_da_avulsa(nota), NA_character_)
  nota$ide$procEmi = "2"
  expect_error(cnpj_da_chave_da_avulsa(nota), "procEmi 2")
})

test_that("o n\u00famero com mais casas do que o campo aceita \u00e9 recusado, e o texto num\u00e9rico ganha as casas sem mudar", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$det[[1]]$prod$vProd = 50.005
  expect_error(nfe_montar(nota), "vProd aceita at\u00e9 2 casas decimais e recebeu 50.005")
  nota$det[[1]]$prod$vProd = 0.1 + 0.2 + 49.7
  expect_identical(campo_montado(nfe_montar(nota), "vProd")[1], "50.00")
  nota$det[[1]]$prod$vProd = "50.5"
  expect_identical(campo_montado(nfe_montar(nota), "vProd")[1], "50.50")
  nota$det[[1]]$prod$vProd = "50.500"
  expect_identical(campo_montado(nfe_montar(nota), "vProd")[1], "50.50")
  nota$det[[1]]$prod$vProd = "50.5001"
  expect_error(nfe_montar(nota), "aceita at\u00e9 2 casas decimais e recebeu 50.5001")
  # O texto que já está dentro das casas do tipo fica como veio (de 1 a 10 casas no vUnCom).
  nota$det[[1]]$prod$vProd = "50.00"
  nota$det[[1]]$prod$vUnCom = "5.00"
  expect_identical(campo_montado(nfe_montar(nota), "vUnCom")[1], "5.00")
  nota$det[[1]]$prod$vProd = NaN
  expect_error(nfe_montar(nota), "vProd recebeu um n\u00famero inv\u00e1lido")
  nota$det[[1]]$prod$vProd = Inf
  expect_error(nfe_montar(nota), "vProd recebeu um n\u00famero inv\u00e1lido")
  # A tolerância só cobre a sobra da conta de máquina, em qualquer tamanho de número.
  nota$det[[1]]$prod$vProd = "50.00"
  nota$det[[1]]$prod$vUnCom = 1000 / 3
  expect_error(nfe_montar(nota), "vUnCom aceita at\u00e9 10 casas decimais")
  nota$det[[1]]$prod$vUnCom = "5.0000000000"
  nota$det[[1]]$prod$qCom = 60000000.12345
  expect_error(nfe_montar(nota), "qCom aceita at\u00e9 4 casas decimais")
  nota$det[[1]]$prod$qCom = "10.0000"
  nota$total$ICMSTot$vNF = 12345678901.235
  expect_error(nfe_montar(nota), "vNF aceita at\u00e9 2 casas decimais")
})

test_that("a mensagem do schema traz o padr\u00e3o inteiro", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$emit$CNPJ = "1122233300018"
  nota$ide$cDV = NULL
  nota$Id = NULL
  # O CNPJ com 13 posições forma uma chave errada; o Id informado à mão passa, e o schema recusa o CNPJ.
  expect_error(nfe_montar(nota), "n\u00e3o formam uma chave")
  documento = xml2::read_xml('<NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe/></NFe>')
  schema = schema_para_montar("nfe", "nfe_v4.00.xsd")
  erros = erros_do_documento_montado(as.character(documento), schema, "NFe")
  expect_false(any(grepl("{http", erros, fixed = TRUE)))
  com_padrao = erros_do_documento_montado(
    sub("<infNFe/>", "<infNFe versao=\"4.00\" Id=\"NFe1\"/>", as.character(documento), fixed = TRUE), schema, "NFe")
  # O padrão do Id sai com os quantificadores ([0-9]{6}...), que antes a limpeza das chaves do namespace tirava.
  expect_true(any(grepl("Id.*\\[0-9\\]\\{[0-9]+\\}", com_padrao)))
})

test_that("dois campos de uma escolha juntos t\u00eam mensagem pr\u00f3pria", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$det[[1]]$imposto$ICMS$ICMS10 = list(orig = 0, CST = "10")
  expect_error(nfe_montar(nota), "\"ICMS10\" n\u00e3o cabe em NFe/infNFe/det/imposto/ICMS junto com ICMS00")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$dest$CPF = "12345678909"
  expect_error(nfe_montar(nota), "\"CPF\" n\u00e3o cabe em NFe/infNFe/dest junto com CNPJ:")
})

test_that("os campos que o schema repete juntos saem intercalados", {
  # Os filhos a, b (repetidos juntos) e c: a1 b1 a2 b2 a3 c.
  # Os filhos x e y se repetem juntos: x1 y1 x2 y2; em quantidades diferentes, não dá para saber a vez de cada um.
  ocorrencias = list("<a>1</a>", c("<x>1</x>", "<x>2</x>"), c("<y>1</y>", "<y>2</y>"), "<z>1</z>")
  blocos = c(NA, "x,y", "x,y", NA)
  nomes = c("a", "x", "y", "z")
  expect_identical(conteudo_na_ordem(ocorrencias, blocos, nomes, "grupo"),
                   "<a>1</a><x>1</x><y>1</y><x>2</x><y>2</y><z>1</z>")
  ocorrencias[[2]] = c(ocorrencias[[2]], "<x>3</x>")
  expect_error(conteudo_na_ordem(ocorrencias, blocos, nomes, "grupo"), "x, y se repetem juntos em grupo")
})

test_that("o texto em outra codifica\u00e7\u00e3o vai em UTF-8", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nome_em_latin1 = iconv("EMPRESA S\u00c3O JO\u00c3O LTDA", "UTF-8", "latin1")
  Encoding(nome_em_latin1) = "latin1"
  nota$emit$xNome = nome_em_latin1
  montada = nfe_montar(nota)
  expect_identical(campo_montado(montada, "xNome")[1], "EMPRESA S\u00c3O JO\u00c3O LTDA")
  expect_identical(Encoding(montada), "UTF-8")
})

test_that("o cDV e o Id informados t\u00eam de conferir com os campos", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  errada = nota
  errada$ide$cDV = "4"
  expect_error(nfe_montar(errada), "cDV informado \\(4\\).*o certo \u00e9 5")
  errada = nota
  errada$Id = "NFe35261011222333000181550010000010011123456780"
  expect_error(nfe_montar(errada), "o certo \u00e9 NFe35261011222333000181550010000010011123456785")
  sem_numero = nota
  sem_numero$ide$nNF = NULL
  sem_numero$emit$CNPJ = NULL
  expect_error(nfe_montar(sem_numero), "faltam: ide/nNF, emit/CNPJ \\(ou emit/CPF\\)")
})

test_that("o campo que o leiaute n\u00e3o tem \u00e9 recusado com o nome e o lugar", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$campoInventado = "1"
  expect_error(nfe_montar(nota), "\"campoInventado\" n\u00e3o existe em NFe/infNFe/ide \\(o schema aceita ali: cUF, cNF")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$det[[2]]$prod$xPreco = 1
  expect_error(nfe_montar(nota), "\"xPreco\" n\u00e3o existe em NFe/infNFe/det/prod")
})

test_that("o vazio fica de fora, menos no campo obrigat\u00f3rio que aceita o vazio", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$emit$xFant = ""
  nota$emit$enderEmit$fone = NA
  nota$infAdic = list(infCpl = "   ")
  nota$det[[1]]$prod$cEAN = ""
  nota$dest$CPF = ""
  montada = nfe_montar(nota)
  expect_length(campo_montado(montada, "xFant"), 0)
  expect_length(campo_montado(montada, "infAdic"), 0)
  expect_length(xml2::xml_find_all(xml2::read_xml(montada), "//*[local-name()='enderEmit']/*[local-name()='fone']"), 0)
  # O cEAN é obrigatório e o schema aceita o vazio; o CPF vazio, na escolha com o CNPJ, não conta.
  expect_match(montada, "<cProd>001</cProd><cEAN></cEAN><xProd>", fixed = TRUE)
  expect_length(campo_montado(montada, "CPF"), 0)
})

test_that("com manter_vazios, o texto vazio sai como tag vazia tamb\u00e9m no opcional, e o NA continua fora", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$emit$enderEmit$fone = NA
  nota$compra = ""
  nota$det[[1]]$prod$cBenef = ""
  montada = nfe_montar(nota, manter_vazios = TRUE)
  # O cBenef aceita o vazio; o compra só tem campos opcionais.
  expect_match(montada, "<compra></compra>", fixed = TRUE)
  expect_match(montada, "<NCM>22011000</NCM><cBenef></cBenef><CFOP>", fixed = TRUE)
  expect_length(xml2::xml_find_all(xml2::read_xml(montada), "//*[local-name()='enderEmit']/*[local-name()='fone']"), 0)
  sem_manter = nfe_montar(nota)
  expect_false(grepl("<compra>", sem_manter, fixed = TRUE))
  expect_false(grepl("<cBenef>", sem_manter, fixed = TRUE))
  # O vazio que o schema não aceita (o xFant tem de ter de 1 a 60 caracteres) não passa calado.
  nota$emit$xFant = ""
  expect_error(nfe_montar(nota, manter_vazios = TRUE), "xFant recebeu \"\".*tamanho de 1 a 60")
  # A nota com os vazios dela volta exatamente como era.
  com_vazios = sub("<NCM>22011000</NCM>", "<NCM>22011000</NCM><cBenef></cBenef>",
                   paste(readLines(EXEMPLO_DA_NFE, encoding = "UTF-8"), collapse = "\n"), fixed = TRUE)
  expect_identical(info_canonico(nfe_montar(xml_para_lista(com_vazios), manter_vazios = TRUE)), info_canonico(com_vazios))
  expect_false(grepl("<cBenef>", nfe_montar(xml_para_lista(com_vazios)), fixed = TRUE))
  expect_error(nfe_montar(nota, manter_vazios = NA), "TRUE ou FALSE")
})

test_that("o texto perde os espa\u00e7os das pontas e o caractere especial vai escapado", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$emit$xNome = "  EMPRESA DE TESTE & FILHOS LTDA "
  montada = nfe_montar(nota)
  expect_match(montada, "<xNome>EMPRESA DE TESTE &amp; FILHOS LTDA</xNome>", fixed = TRUE)
})

test_that("os itens sem nItem s\u00e3o numerados na ordem, e um item s\u00f3 pode vir sem a lista de fora", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$det[[1]]$nItem = NULL
  nota$det[[2]]$nItem = NULL
  montada = nfe_montar(nota)
  itens = xml2::xml_find_all(xml2::read_xml(montada), "//*[local-name()='det']")
  expect_identical(xml2::xml_attr(itens, "nItem"), c("1", "2"))
  um_item = nota
  um_item$det = nota$det[[1]]
  expect_length(xml2::xml_find_all(xml2::read_xml(nfe_montar(um_item)), "//*[local-name()='det']"), 1)
})

test_that("a nota montada passa no schema, na pr\u00e9-confer\u00eancia e na assinatura", {
  skip_if_not_installed("openssl")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$nNF = 1002
  nota$ide$cDV = NULL
  nota$Id = NULL
  montada = nfe_montar(nota)
  assinada = xml_assinar(montada, test_path("certificados", "pessoa_juridica.pfx"), "teste")
  conferida = nfe_conferir(assinada)
  expect_true(conferida$notas$assinada)
  expect_true(conferida$notas$schema_valido)
  lida = nfe_ler(assinada)
  expect_identical(lida$notas$numero, 1002L)
  expect_equal(nrow(lida$itens), 2)
})

test_that("o que o schema recusa para a montagem com os erros dele", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$mod = "99"
  nota$ide$cDV = NULL
  nota$Id = NULL
  # O valor que o tipo recusa para no campo; o que só o documento inteiro mostra (o campo obrigatório que falta), no
  # schema oficial.
  expect_error(nfe_montar(nota), "ide/mod recebeu \"99\".*valores aceitos: \"55\", \"65\"")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$emit$xNome = NULL
  expect_error(nfe_montar(nota), "n\u00e3o passa no schema oficial.*xNome")
})

test_that("o texto que o tipo recusa para no campo, tamb\u00e9m onde a confer\u00eancia do libxml2 deixaria passar", {
  # O libxml2 aceita o tamanho errado nos padrões com alternativas ([0-9]{2}|[0-9]{8} aceita 9 algarismos); a montagem
  # confere cada texto no padrão do tipo antes.
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$det[[1]]$prod$NCM = "220110001"
  expect_error(nfe_montar(nota), "det/prod/NCM recebeu \"220110001\".*padr\u00e3o: \\[0-9\\]\\{2\\}\\|\\[0-9\\]\\{8\\}")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$det[[1]]$prod$cEAN = "7891234567895123456"
  expect_error(nfe_montar(nota), "cEAN recebeu")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$det[[1]]$prod$cBenef = "ABCDEFGHIJKLMNOPQ"
  expect_error(nfe_montar(nota), "cBenef recebeu")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$Id = "NFe123"
  expect_error(nfe_montar(nota), "O Id informado \\(NFe123\\) n\u00e3o confere")
})

test_that("os campos da chave n\u00e3o aceitam n\u00famero com casas, vetor nem texto fora do UTF-8", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$Id = NULL
  nota$ide$cDV = NULL
  com_casas = nota
  com_casas$ide$cNF = 345.5
  expect_error(nfe_montar(com_casas), "ide/cNF recebeu 345.5: informe um n\u00famero inteiro")
  com_casas = nota
  com_casas$emit$CNPJ = 11222333000180.6
  expect_error(nfe_montar(com_casas), "emit/CNPJ recebeu 11222333000180.6")
  com_na = nota
  com_na$ide$tpAmb = c(NA, "2")
  expect_error(nfe_montar(com_na), "ide/tpAmb recebeu mais de um valor")
  fora_do_utf8 = nota
  fora_do_utf8$ide$serie = iconv("1\u00ba", "UTF-8", "latin1")
  Encoding(fora_do_utf8$ide$serie) = "bytes"
  expect_error(nfe_montar(fora_do_utf8), "infNFe/ide/serie tem um texto que n\u00e3o est\u00e1 em UTF-8")
  # A data do POSIXlt vale como a do POSIXct.
  com_posixlt = nota
  com_posixlt$ide$dhEmi = as.POSIXlt(as.POSIXct("2026-10-15 10:30:00", tz = "America/Sao_Paulo"))
  expect_match(nfe_montar(com_posixlt), "<dhEmi>2026-10-15T10:30:00-03:00</dhEmi>", fixed = TRUE)
})

test_that("o integer64 (bit64) n\u00e3o vira um n\u00famero min\u00fasculo", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$Id = NULL
  nota$ide$cDV = NULL
  # O integer64 guarda os 8 bytes do inteiro num double: lido como número do R, o 11444777000161 viraria 5,6e-311.
  bytes = as.raw(c(0xe1, 0x1c, 0xde, 0xb1, 0x68, 0x0a, 0x00, 0x00))
  cnpj = readBin(bytes, "double", size = 8, endian = "little")
  class(cnpj) = "integer64"
  nota$emit$CNPJ = cnpj
  if (requireNamespace("bit64", quietly = TRUE)) {
    expect_match(nfe_montar(nota), "<CNPJ>11444777000161</CNPJ>", fixed = TRUE)
  } else {
    expect_error(nfe_montar(nota), "emit/CNPJ veio como integer64")
  }
})

test_that("o n\u00famero com casas al\u00e9m das do campo \u00e9 recusado tamb\u00e9m nos trilh\u00f5es", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$total$ICMSTot$vNF = 1234567890123.451
  expect_error(nfe_montar(nota), "vNF aceita at\u00e9 2 casas decimais e recebeu 1234567890123.451")
  nota$total$ICMSTot$vNF = 0.1 + 0.2
  expect_match(nfe_montar(nota), "<vNF>0.30</vNF>", fixed = TRUE)
  # Com mais de 15 algarismos, o round() do R devolve o próprio número: ele vai como texto, sem arredondar calado.
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$det[[1]]$prod$vUnCom = 12345678901.123455
  expect_error(nfe_montar(nota), "vUnCom recebeu 12345678901.12345.*passa dos 15 algarismos.*informe como texto")
  nota$det[[1]]$prod$vUnCom = 1234567890.1234567
  expect_error(nfe_montar(nota), "passa dos 15 algarismos")
  nota$det[[1]]$prod$vUnCom = 1234567890.12345
  expect_match(nfe_montar(nota), "<vUnCom>1234567890.12345</vUnCom>", fixed = TRUE)
  nota$det[[1]]$prod$vUnCom = "12345678901.123455"
  expect_match(nfe_montar(nota), "<vUnCom>12345678901.123455</vUnCom>", fixed = TRUE)
})

test_that("a nota de produ\u00e7\u00e3o \u00e9 recusada, e o tpAmb que falta vem do ambiente", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$tpAmb = "1"
  expect_error(nfe_montar(nota), "homologa\u00e7\u00e3o \\(tpAmb 2\\)")
  expect_error(nfe_montar(xml_para_lista(EXEMPLO_DA_NFE), ambiente = "producao"), "homologacao")
  nota$ide$tpAmb = NULL
  expect_identical(campo_montado(nfe_montar(nota), "tpAmb"), "2")
})

test_that("o valor e o grupo no lugar errado t\u00eam mensagem pr\u00f3pria", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$transp = "TRANSPORTADORA"
  expect_error(nfe_montar(nota), "NFe/infNFe/transp \u00e9 um grupo")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$natOp = list(texto = "VENDA")
  expect_error(nfe_montar(nota), "NFe/infNFe/ide/natOp guarda um valor")
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  nota$ide$natOp = TRUE
  expect_error(nfe_montar(nota), "recebeu um valor do tipo logical")
  expect_error(nfe_montar(list(1, 2)), "Informe a nota numa lista")
  expect_error(nfe_montar(list(emit = list())), "precisa do grupo ide")
})

test_that("xml_para_lista: grupo repetido vira lista de listas, campo repetido vira vetor, atributo entra pelo nome", {
  nota = xml_para_lista(EXEMPLO_DA_NFE)
  expect_identical(nota$versao, "4.00")
  expect_identical(nota$Id, "NFe35261011222333000181550010000010011123456785")
  expect_null(names(nota$det))
  expect_length(nota$det, 2)
  expect_identical(nota$det[[2]]$nItem, "2")
  expect_length(nota$cobr$dup, 2)
  # O gPgto pode repetir (até 99): vira lista de listas mesmo com uma só.
  expect_identical(nota$gPgtoVinc$gPgto[[1]]$idTransacao, "TRANSACAO-DE-TESTE-1")
  expect_null(names(nota$pag$detPag))
  expect_null(nota$Signature)
  expect_identical(nota$ide$nNF, "1001")
  lista_do_texto = xml_para_lista(paste(readLines(EXEMPLO_DA_NFE, encoding = "UTF-8"), collapse = "\n"))
  expect_identical(lista_do_texto, nota)
  # O campo que se repete vira vetor (o NVE do item, até 8), e o item único também vem numa lista de listas.
  com_nve = xml_para_lista(paste0('<NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe><det><prod><NVE>AA0001</NVE>',
                                  '<NVE>AB0002</NVE></prod></det></infNFe></NFe>'))
  expect_identical(com_nve$det[[1]]$prod$NVE, c("AA0001", "AB0002"))
  uma_nve = xml_para_lista('<NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe><det><prod><NVE>AA0001</NVE></prod></det></infNFe></NFe>')
  expect_identical(uma_nve$det[[1]]$prod$NVE, "AA0001")
  # A nota de um item só: o det[[1]] do guia vale nela também.
  um_item = xml_para_lista(system.file("exemplos", "nfe_ce_simples_cpf.xml", package = "RNFe"))
  expect_null(names(um_item$det))
  expect_false(is.null(um_item$det[[1]]$prod$xProd))
  # O grupo vazio vira texto vazio; o lote com duas notas é recusado.
  com_vazio = xml_para_lista('<NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe><compra/></infNFe></NFe>')
  expect_identical(com_vazio$compra, "")
  lote = paste0('<enviNFe xmlns="http://www.portalfiscal.inf.br/nfe"><NFe><infNFe Id="NFe1"/></NFe>',
                '<NFe><infNFe Id="NFe2"/></NFe></enviNFe>')
  expect_error(xml_para_lista(lote), "traz 2 documentos")
})

test_that("a NFC-e montada recebe o QR-Code da conting\u00eancia e passa no schema assinada", {
  skip_if_not_installed("openssl")
  certificado = test_path("certificados", "pessoa_juridica.pfx")
  nota = xml_para_lista(system.file("exemplos", "nfce_ce_contingencia.xml", package = "RNFe"))
  nota$ide$nNF = 77
  nota$ide$cDV = NULL
  nota$Id = NULL
  montada = nfe_montar(nota)
  expect_false(grepl("infNFeSupl", montada, fixed = TRUE))
  com_qrcode = nfce_qrcode(montada, "https://www.sefaz.exemplo/nfce/qrcode", "https://www.sefaz.exemplo/nfce/consulta",
                           certificado, "teste")
  assinada = xml_assinar(com_qrcode, certificado, "teste")
  conferida = nfe_conferir(assinada)
  expect_true(conferida$notas$schema_valido)
  expect_match(assinada, "<infNFeSupl[^>]*><qrCode>https://www.sefaz.exemplo/nfce/qrcode")
})
