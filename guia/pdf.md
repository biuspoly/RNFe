# Os documentos auxiliares em PDF

[Voltar ao início](../README.md)

```r
danfe_pdf("nota_autorizada.xml", "danfe.pdf")        # A4, com quantas folhas os itens pedirem
danfe_simplificado_pdf("nota_autorizada.xml", "simplificado.pdf")                 # o DANFE Simplificado
danfe_simplificado_pdf("nota_autorizada.xml", "etiqueta.pdf", etiqueta = TRUE)    # a Etiqueta, sem os itens
danfce_pdf("nfce_autorizada.xml", "danfce.pdf")      # a bobina de 80 mm, com o QR-Code
dacte_pdf("cte_autorizado.xml", "dacte.pdf")         # o CT-e e o CT-e OS
damdfe_pdf("mdfe_autorizado.xml", "damdfe.pdf")      # o MDF-e (o modal rodoviário completo)
danfse_pdf("nfse.xml", "danfse.pdf")                 # o DANFSe v2.0 da NFS-e Nacional
dacce_pdf("carta_de_correcao.xml", "carta.pdf")      # a carta de correção da NF-e ou do CT-e
```

Cada um segue o manual do documento: o DANFE, o Anexo II do Manual de Orientação da NF-e (as posições dos quadros e
o código de barras da chave em CODE-128C, conferido com o exemplo do manual, 09758364 com o dígito 48); com o CNPJ
alfanumérico, a chave vai em CODE-128 C e A, como manda a Nota Técnica Conjunta 2025.001. O DANFE Simplificado e a
Etiqueta seguem os campos mínimos dos itens 3.11 e 3.12 do mesmo anexo, que não traz leiaute: o desenho é o do RNFe,
em papel de 10 cm, para a chave com o CNPJ alfanumérico caber com o módulo mínimo do código de barras (0,02 cm). O
DANFE Simplificado Tipo 2 da NT 2026.002 não entrou: a nota técnica não traz o leiaute dele. O DANFE NFC-e segue o
Manual de Padrões Técnicos do DANFE NFC-e e QR Code (as divisões da bobina, a contingência e o consumidor); o DACTE, o
do CT-e 4.00 (também o DACTE OS); o DAMDFE, o Anexo II do Manual do MDF-e; e o DANFSe, a Nota Técnica SE/CGNFS-e
008/2026 (a versão 2.0, com os blocos do IBS e da CBS e as linhas únicas de quando a nota não tem tomador,
destinatário, intermediário ou ISSQN); na nota do leiaute da NT SE/CGNFS-e 009, o destinatário vem do lugar novo
(item 2.11) e a dedução do ISSQN soma o ajuste informado e o calculado, como a fórmula da base (item 2.3). A logomarca da NFS-e não vai: no lugar dela, o texto "NFS-e". A carta de
correção não tem modelo oficial: o desenho é o do RNFe, com a chave em código de barras, o registro na SEFAZ, a
correção e as condições de uso. Os documentos de homologação saem com a marca de sem valor fiscal (no DANFSe, "NFS-e
SEM VALIDADE JURÍDICA"). Na contingência, o DANFE com formulário de segurança leva o segundo código de barras "Dados da
NF-e", o do EPEC leva o protocolo do evento, e o DAMDFE leva as chaves dos documentos e o QR-Code assinado. Os códigos
de barras e os QR-Code dos exemplos foram lidos de volta por um leitor (o zxing), com a chave e o endereço certos. Tudo é desenhado com o `grid` do próprio R; o QR-Code precisa do pacote `qrcode`.

---

[Voltar ao início](../README.md)
