# Montar os documentos

[Voltar ao início](../README.md)

```r
nota = list(
  ide = list(cUF = 35, natOp = "VENDA DE MERCADORIA", mod = 55, serie = 1, nNF = 1, dhEmi = Sys.time(),
             tpNF = 1, idDest = 1, cMunFG = "3550308", tpImp = 1, tpEmis = 1, finNFe = 1, indFinal = 1,
             indPres = 1, procEmi = 0, verProc = "MEU SISTEMA"),
  emit = list(CNPJ = "11222333000181", xNome = "EMPRESA DE TESTE LTDA", IE = "123456789012", CRT = 3,
              enderEmit = list(xLgr = "RUA DE TESTE", nro = "100", xBairro = "CENTRO", cMun = "3550308",
                               xMun = "SAO PAULO", UF = "SP", CEP = "01001000")),
  dest = list(CPF = "12345678909", xNome = "NF-E EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL",
              indIEDest = 9,
              enderDest = list(xLgr = "AVENIDA DE TESTE", nro = "200", xBairro = "CENTRO", cMun = "3550308",
                               xMun = "SAO PAULO", UF = "SP", CEP = "01002000")),
  det = list(
    list(prod = list(cProd = "001", cEAN = "SEM GTIN", xProd = "PRODUTO DE TESTE", NCM = "22011000",
                     CFOP = 5102, uCom = "UN", qCom = 2, vUnCom = 5, vProd = 10, cEANTrib = "SEM GTIN",
                     uTrib = "UN", qTrib = 2, vUnTrib = 5, indTot = 1),
         imposto = list(ICMS = list(ICMS00 = list(orig = 0, modBC = 3, vBC = 10, pICMS = 18, vICMS = 1.8)),
                        PIS = list(PISNT = list(CST = "07")),
                        COFINS = list(COFINSNT = list(CST = "07"))))
  ),
  total = list(ICMSTot = list(vBC = 10, vICMS = 1.8, vICMSDeson = 0, vFCP = 0, vBCST = 0, vST = 0, vFCPST = 0,
                              vFCPSTRet = 0, vProd = 10, vFrete = 0, vSeg = 0, vDesc = 0, vII = 0, vIPI = 0,
                              vIPIDevol = 0, vPIS = 0, vCOFINS = 0, vOutro = 0, vNF = 10)),
  transp = list(modFrete = 9),
  pag = list(detPag = list(tPag = 1, vPag = 10))
)

montada = nfe_montar(nota)        # o XML da NF-e (ou da NFC-e, com o mod 65), ainda sem a assinatura
nfe_conferir(montada)             # as regras da SEFAZ, antes de enviar
assinada = xml_assinar(montada, "empresa.pfx", senha)
resposta = sefaz_autorizar(assinada, "empresa.pfx", senha)

# A partir de um documento que já existe: trocar o que muda e montar de novo
nota = xml_para_lista("nota_autorizada.xml")
nota$ide$nNF = 2
nota$ide$cNF = NULL      # sorteado de novo
nota$ide$cDV = NULL
nota$Id = NULL           # a chave nova sai dos campos
montada = nfe_montar(nota)

# Os outros documentos, do mesmo jeito
cte_montar(xml_para_lista("cte.xml"))         # CT-e, CT-e OS, GTV-e e CT-e simplificado (pelo mod e pelo tpCTe)
mdfe_montar(xml_para_lista("mdfe.xml"))
nfse_dps_montar(xml_para_lista("dps.xml"))    # a DPS da NFS-e Nacional, no leiaute da Produção Restrita
```

**A lista usa os nomes do leiaute**, os mesmos do XML e dos manuais (`ide`, `emit`, `det`, `prod`, `vProd`...). Cada
grupo é uma lista com os campos dele; o grupo que o leiaute deixa repetir (os itens, as duplicatas, as formas de
pagamento) é uma lista de listas; o campo que se repete é um vetor; os atributos (`versao`, `Id`, `nItem`) vão com os
campos, pelo nome. A ordem dos campos não importa. O `xml_para_lista()` faz o caminho de volta: qualquer NF-e, NFC-e,
CT-e, MDF-e, DPS ou evento vira essa lista, com todo valor em texto, e o grupo que o leiaute deixa repetir vira sempre
uma lista de listas, mesmo quando aparece uma vez (`nota$det[[1]]` vale em toda nota). No evento da NFS-e, vem o
evento inteiro, com o pedido do autor dentro (`evento$pedRegEvento$infPedReg`).

**Quem decide o formato é o schema oficial**, lido na hora: o pacote traz os schemas dos portais (`inst/schemas`), e a
montagem tira deles a ordem dos campos, o que é atributo, as casas decimais de cada número, o formato da data, os
zeros à esquerda e o que vai no `xs:any` (os modais do CT-e e do MDF-e, conferidos no schema deles). O código não tem a
lista dos campos: quando a SEFAZ publica um leiaute novo, trocar os arquivos do schema basta para a montagem aceitar o
campo novo (o robô dos schemas deixa essa troca pronta num ramo, com os testes, e só troca um arquivo pelo de data
mais nova: o pacote antigo que o portal lista de novo não volta nada para trás). Cada valor é conferido no padrão do
tipo dele, e o XML inteiro, no schema oficial no fim.

**Os valores podem vir como o R os guarda:**

- o número sai com as casas do tipo do campo (`10` vira `10.00` no valor e `10.0` na quantidade, que aceita de 1 a 4
  casas); o número com mais casas do que o campo aceita é recusado, sem arredondar: a regra do arredondamento é de
  quem emite (`round(valor, 2)` antes). A sobra da conta de máquina passa (`0.1 + 0.2` vira `0.30`). O número com mais
  de 15 algarismos, contando a parte inteira e as casas (`12345678901.123455`), vai como texto: com mais, o R não
  guarda todos. O número em texto com casas de menos (`"10.5"` num valor) ganha os zeros;
- a data e hora do R (`Sys.time()`, `as.POSIXct(..., tz = "America/Recife")`, também o `POSIXlt`) sai com o fuso, e a
  data (`as.Date(...)`) como `AAAA-MM-DD`;
- o código que perdeu o zero à esquerda volta a tê-lo quando o leiaute só aceita a forma com zero: `1` vira `"01"`
  no meio de pagamento e `345` vira `"00000345"` no código numérico. O número num campo que aceita o zero à esquerda
  com e sem ele (a IE, o telefone, o GTIN) é recusado: o número não diz qual era, e vai como texto. A quantidade
  (`qVol`, os campos que começam por `q`) vai sem o zero. CNPJ, NCM e CEST vão melhor como texto;
- o `integer64` (do pacote bit64, como chega o BIGINT de um banco) vira o texto do número;
- o espaço nas pontas sai quando o tipo do campo não o aceita (o texto da NF-e); onde ele aceita (o nome na NFS-e),
  fica. O texto vai em UTF-8; o `&` e o `<` vão escapados. Acento fica como veio (o leiaute aceita até o `ÿ`).

**O RNFe completa sozinho o que não vier:** o `tpAmb` do ambiente; o `nItem` de cada item, na ordem; o código numérico
(`cNF`, `cCT`, `cMDF`), sorteado pelo gerador do sistema fora dos que a SEFAZ recusa (a regra B03-10: as sequências,
os repetidos e o próprio número); o dígito e o `Id` com a chave de acesso (na NF-e avulsa, com o CNPJ do órgão do grupo
`avulsa`; na DPS, o `Id` do Anexo I, com a inscrição de quem o `tpEmit` aponta); a versão do leiaute; e o campo
obrigatório que só aceita um valor, como o `CST` do `ICMS00`, também dentro do grupo opcional que veio. Quando o
dígito ou o `Id` vêm, eles têm de conferir com os campos do documento. O código numérico informado vai como veio (o
`nfe_conferir()` confere a regra B03-10).

**O vazio:** o campo com `NULL` ou `NA` fica de fora. O texto vazio (`""`) fica de fora no campo opcional e sai como
tag vazia no obrigatório que aceita o vazio (o `cEAN`, por exemplo). Com `manter_vazios = TRUE`, o texto vazio sai
como tag vazia também no campo e no grupo opcionais (`<cBenef></cBenef>`, `<compra></compra>`), para quando ela for
preciso: campo por campo, `""` é a tag vazia e `NA` é a falta dela. O vazio que o tipo não aceita (o `xFant`, de 1 a 60
caracteres) é recusado, com o nome do campo.

**O que é recusado, com o nome e o lugar:** o campo que o leiaute não tem (`O campo "xPreco" não existe em
NFe/infNFe/det/prod`, com a lista do que ele aceita ali), dois campos de uma escolha juntos (o `ICMS10` com o `ICMS00`,
o `CPF` com o `CNPJ` no destinatário), o mesmo nome duas vezes num grupo, o grupo no lugar de um valor e o contrário,
o texto que o tipo do campo recusa (`O campo NFe/infNFe/det/prod/NCM recebeu "220110001", que o tipo dele não aceita
(padrão: [0-9]{2}|[0-9]{8})`, também onde a conferência do schema deixaria passar), o número com casas, o grande
demais para o R ou o vetor num campo da chave, o texto fora do UTF-8, o número inválido (`NaN`, `Inf`) e o que o
schema oficial recusa no fim (o campo obrigatório que falta). O documento de produção (`tpAmb` 1) também, como em
todo o RNFe por enquanto.

**O que a montagem não faz:** as regras de negócio da SEFAZ (os totais, o CFOP do destino, o texto do destinatário em
homologação) ficam no [`nfe_conferir()`](conferir.md); o QR-Code da NFC-e, no `nfce_qrcode()`, depois de montar (o do
CT-e entra no `sefaz_cte_autorizar()`); a assinatura, no `xml_assinar()`.

**Os eventos também seguem o schema:** o detalhe de cada evento da NF-e (o cancelamento, a carta de correção, a
manifestação, o comprovante e o insucesso de entrega, o ator interessado e o EPEC) é montado pelo schema oficial dele
(`inst/schemas/nfe_eventos`), e a mensagem inteira, assinada, é conferida no schema geral antes de ir à SEFAZ; os do
CT-e e do MDF-e, nos schemas deles. Veja [Enviar à SEFAZ](emitir.md).

**Conferido com documentos de verdade** (só contagens; nenhum dado sai do acervo):

- 3.000 NF-e autorizadas, sorteadas de um acervo de 119 mil, lidas pelo `xml_para_lista()` e montadas de novo: com
  `manter_vazios = TRUE`, as 2.967 que o schema de hoje aceita saíram iguais ao original, byte a byte; sem ele, iguais
  menos as tags vazias opcionais. As 33 que ele recusa: 30 no leiaute antigo do IBS/CBS monofásico (o `gMonoPadrao`
  direto no `gIBSCBSMono`) e 3 com um texto em UTF-8 lido duas vezes ("Ã“"), fora do que o leiaute aceita. A chave de
  acesso calculada pela montagem bateu com a das notas autorizadas, avulsas incluídas;
- 2.518 CT-e 4.00 do acervo: iguais ao original (8 com outra declaração de namespace, os dados iguais), e a chave
  calculada bateu em todos; 1.650 DPS da NFS-e Nacional (1.01): iguais ao original (1 com outra declaração de
  namespace);
- em homologação: a NF-e e o MDF-e montados foram autorizados (100), e o MDF-e, encerrado (135).

A montagem de uma nota de dois itens leva uns 17 ms, e a conferência no schema, uns 10 ms; uma de 990 itens, uns
5 segundos.

---

[Voltar ao início](../README.md)
