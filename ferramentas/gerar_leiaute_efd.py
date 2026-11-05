"""Gera inst/extdata/tabelas/leiaute_efd_icms_ipi.csv: os registros e os campos da EFD ICMS/IPI, com a vigência.

As fontes são as duas publicações do portal do SPED que trazem a tabela de campos de cada registro: o Guia Prático da
EFD ICMS/IPI e a Nota Técnica do leiaute (o Manual de Orientação do Ato COTEPE/ICMS 44/2018). As duas são PDF, e o PDF
quebra as linhas das tabelas de jeitos diferentes: cada uma é lida duas vezes (pelo texto corrido e pelas linhas e
colunas da tabela), e cada coluna de cada campo sai da votação das quatro leituras. O nome que o texto corrido do Guia
escreve por extenso ("Campo 06 (COD_MOT_REST_COMPL)") vale mais que o nome cortado na coluna estreita. O que não se
decide na votação (as duas fontes discordam de verdade) está em ferramentas/leiaute_efd_decisoes.csv, com o motivo:
quando as duas discordam, vale o Guia, que é o mais novo. A vigência vem do título do registro ("VÁLIDO ATÉ ...") e do
histórico de campos incluídos de cada ano (Capítulo II do Guia).

Uso, na raiz do repositório (Python com pdfplumber e pypdfium2):
    python ferramentas/gerar_leiaute_efd.py
Depois, a lista de conferência das tabelas:
    Rscript ferramentas/gerar_conferencia_das_tabelas.R
"""
import csv
import html
import logging
import re
import sys
import tempfile
import urllib.request
from collections import Counter
from datetime import date
from pathlib import Path

import pdfplumber
import pypdfium2

sys.stdout.reconfigure(encoding="utf-8")
logging.getLogger("pdfminer").setLevel(logging.ERROR)

PAGINA_DOS_MANUAIS = "http://sped.rfb.gov.br/pasta/show/1573"
ENDERECO_DO_ARQUIVO = "http://sped.rfb.gov.br/arquivo/download/{}"
ARQUIVO_DA_TABELA = Path("inst/extdata/tabelas/leiaute_efd_icms_ipi.csv")
ARQUIVO_DAS_DECISOES = Path("ferramentas/leiaute_efd_decisoes.csv")
LEITURAS = ["faixas_nt", "texto_nt", "faixas_guia", "texto_guia"]

CABECALHO_DO_REGISTRO = re.compile(r"^REGISTRO\s+([0-9A-Z]{4})\b")
VALIDO_ATE = re.compile(r"V[ÁA]LIDO\s+AT[ÉE]\s+(\d{2})/(\d{2})/(\d{4})", re.I)
VALIDO_DESDE = re.compile(r"V[ÁA]LIDO\s+A\s+PARTIR\s+DE\s+(\d{2})/(\d{2})/(\d{4})", re.I)
NIVEL = re.compile(r"Nível hierárquico\s*[-–:]\s*(\d)")
LINHA_DE_PAGINA = re.compile(r"^(=== página|Guia Prático EFD-ICMS/IPI|Atualização: |Página \d+ de|NT \d{4}\.\d{3} v)")
INICIO_DO_CAMPO = re.compile(r"^(\d{1,3})\s+([A-Z][A-Z0-9_]*)\b\s*(.*)$")
FIM_NA_NT = re.compile(r"(?:^|\s)([CN])\s+(\d+\*?|-)\s+(\d+|-)\s*$")
FIM_NO_GUIA = re.compile(r"(?:^|\s)([CN])\s+(\d+\*?|-)\s+(?:(\d+|-)\s+)?((?:OC|O|N|Não|Obrigat|Opcional)\b.*)$")
SO_OBRIGATORIEDADE = re.compile(r"^((?:OC|O|N)(?:\s+(?:OC|O|N))?)$")
FIM_DA_TABELA = re.compile(r"^(Observaç|Nível hierárquico|Ocorrência|Validação|Campo \d|REGISTRO |Exemplo|Obs\.?:)")
MENCAO = re.compile(r"Campos?\s+(\d{2,3})\s*\(\s*([A-Z][A-Z0-9_]*)\s*\)")
NOME_LIMPO = re.compile(r"^[A-ZÀ-Ý][A-Za-zÀ-ÿ0-9_]*$")
FORMATOS = {"tipo": re.compile(r"^[CN]$"), "tamanho": re.compile(r"^(\d+\*?|-)$"), "decimais": re.compile(r"^(\d+|-)$")}
COLUNAS_DA_TABELA = ["numero", "campo", "descricao", "tipo", "tamanho", "decimais", "obrigatorio"]
FOLGA_DA_COLUNA = 6


# ---- Baixar ----

def pagina_do_portal(endereco):
    pedido = urllib.request.Request(endereco, headers={"User-Agent": "RNFe (ferramentas/gerar_leiaute_efd.py)"})
    return html.unescape(urllib.request.urlopen(pedido, timeout=120).read().decode("utf-8", "replace"))


def versao_como_numeros(texto):
    return tuple(int(parte) for parte in re.findall(r"\d+", texto))


def publicacoes_mais_novas():
    """O Guia Prático e a Nota Técnica do leiaute mais novos da página de manuais do portal do SPED."""
    pagina = pagina_do_portal(PAGINA_DOS_MANUAIS)
    links = re.findall(r'href="/item/show/(\d+)"[^>]*>([^<]+)<', pagina)
    guias = [(versao_como_numeros(re.search(r"(\d+\.\d+\.\d+)", titulo).group(1)), numero, titulo.strip())
             for numero, titulo in links if re.search(r"Guia Pr.tic.*EFD ICMS IPI.*?\d+\.\d+\.\d+", titulo)]
    notas = [(versao_como_numeros(re.search(r"leiaute vers.o (\d+)", titulo).group(1)), numero, titulo.strip())
             for numero, titulo in links if re.search(r"Nota T.cnica .*leiaute vers.o \d+", titulo)]
    return max(guias), max(notas)


def baixar(numero_do_item, destino):
    pedido = urllib.request.Request(ENDERECO_DO_ARQUIVO.format(numero_do_item),
                                    headers={"User-Agent": "RNFe (ferramentas/gerar_leiaute_efd.py)"})
    dados = urllib.request.urlopen(pedido, timeout=300).read()
    if not dados.startswith(b"%PDF"):
        raise RuntimeError(f"O item {numero_do_item} do portal não é um PDF.")
    destino.write_bytes(dados)


def linhas_do_texto(caminho_do_pdf):
    documento = pypdfium2.PdfDocument(str(caminho_do_pdf))
    linhas = []
    for numero_da_pagina in range(len(documento)):
        linhas.append(f"=== página {numero_da_pagina + 1} ===")
        linhas += documento[numero_da_pagina].get_textpage().get_text_range().split("\n")
    return linhas


# ---- A versão do registro no título ----

def data_iso(achado):
    return f"{achado.group(3)}-{achado.group(2)}-{achado.group(1)}"


class TituloDoRegistro:
    """O código do registro e a validade escrita no título, que às vezes quebra em mais de uma linha."""

    def __init__(self, codigo, primeira_linha):
        self.codigo = codigo
        self.texto = primeira_linha
        self.linhas_lidas = 0
        self.fim = None
        self.inicio = None
        self.procurar_validade()

    def acrescentar(self, linha):
        if self.linhas_lidas < 3 and self.fim is None and self.inicio is None:
            self.texto += " " + linha
            self.linhas_lidas += 1
            self.procurar_validade()

    def procurar_validade(self):
        ate = VALIDO_ATE.search(self.texto)
        desde = VALIDO_DESDE.search(self.texto)
        if ate:
            self.fim = data_iso(ate)
        if desde:
            self.inicio = data_iso(desde)

    def chave(self):
        """A versão antiga leva a data do fim junto do código; a de hoje, só o código."""
        return f"{self.codigo}|{self.fim}" if self.fim else self.codigo


# ---- Leitura pelo texto corrido ----

def leitura_pelo_texto(linhas, fonte):
    fim_do_campo = FIM_NO_GUIA if fonte == "guia" else FIM_NA_NT
    campos = []
    niveis = {}
    inicios = {}
    titulo = None
    campo_aberto = None
    numero_esperado = None
    for linha_crua in linhas:
        linha = linha_crua.strip()
        if not linha or LINHA_DE_PAGINA.match(linha):
            continue
        cabecalho = CABECALHO_DO_REGISTRO.match(linha)
        if cabecalho:
            titulo = TituloDoRegistro(cabecalho.group(1), linha)
            campo_aberto = None
            numero_esperado = 1
            continue
        if titulo is None:
            continue
        titulo.acrescentar(linha)
        if titulo.inicio:
            inicios[titulo.chave()] = titulo.inicio
        nivel = NIVEL.search(linha)
        if nivel and titulo.chave() not in niveis:
            niveis[titulo.chave()] = nivel.group(1)
        obrigatoriedade = SO_OBRIGATORIEDADE.match(linha)
        if obrigatoriedade and campo_aberto is not None and campo_aberto["tipo"]:
            continue
        inicio = INICIO_DO_CAMPO.match(linha)
        numero_do_inicio = int(inicio.group(1)) if inicio else None
        comeca_campo = inicio is not None and numero_esperado is not None and (
            numero_do_inicio == numero_esperado or (
                numero_esperado < numero_do_inicio <= numero_esperado + 2 and campo_aberto is not None
                and campo_aberto["tipo"] != ""))
        if comeca_campo:
            campo_aberto = {"registro": titulo.chave(), "numero": f"{numero_do_inicio:02d}", "campo": inicio.group(2),
                            "descricao": inicio.group(3), "tipo": "", "tamanho": "", "decimais": "", "pagina": ""}
            campos.append(campo_aberto)
            numero_esperado = numero_do_inicio + 1
            resto = inicio.group(3)
        elif campo_aberto is not None and not campo_aberto["tipo"]:
            campo_aberto["descricao"] += " " + linha
            resto = linha
        else:
            continue
        fim = fim_do_campo.search(resto) or (FIM_NA_NT.search(resto) if fonte == "guia" else None)
        if fim:
            campo_aberto["tipo"] = fim.group(1)
            campo_aberto["tamanho"] = fim.group(2)
            campo_aberto["decimais"] = fim.group(3) or ""
    for campo in campos:
        campo["nivel"] = niveis.get(campo["registro"], "")
        campo["inicio_do_registro"] = inicios.get(campo["registro"], "")
    return campos


# ---- Leitura pelas linhas e colunas da tabela ----

def posicao_vertical_e_horizontal(palavra):
    return (palavra["top"], palavra["x0"])


def posicao_horizontal(palavra):
    return palavra["x0"]


def linhas_da_pagina(palavras):
    linhas = []
    for palavra in sorted(palavras, key=posicao_vertical_e_horizontal):
        if linhas and abs(linhas[-1]["top"] - palavra["top"]) < 2:
            linhas[-1]["palavras"].append(palavra)
        else:
            linhas.append({"top": palavra["top"], "palavras": [palavra]})
    for linha in linhas:
        linha["palavras"].sort(key=posicao_horizontal)
        linha["texto"] = " ".join(palavra["text"] for palavra in linha["palavras"])
    return linhas


def inicios_das_colunas(linha):
    """O começo de cada coluna, pelo cabeçalho da tabela (Nº, Campo, Descrição, Tipo, Tam, Dec e a obrigatoriedade)."""
    textos = [palavra["text"].lower() for palavra in linha["palavras"]]
    if len(textos) < 6 or textos[0] not in ("nº", "n°", "no", "n.º") or textos[1] != "campo":
        return None
    inicios = [palavra["x0"] for palavra in linha["palavras"][:6]]
    if len(linha["palavras"]) > 6:
        inicios.append(linha["palavras"][6]["x0"])
    return inicios


def coluna_da_palavra(palavra, inicios):
    coluna = 0
    for posicao, inicio in enumerate(inicios):
        if palavra["x0"] >= inicio - FOLGA_DA_COLUNA:
            coluna = posicao
    return COLUNAS_DA_TABELA[coluna]


def bordas_da_coluna_do_numero(pagina, inicios):
    """As linhas horizontais que cruzam a coluna Nº: são as que separam um campo do seguinte."""
    coluna_do_numero = inicios[0]
    return sorted({round(borda["top"], 1) for borda in pagina.horizontal_edges
                   if borda["x0"] <= coluna_do_numero + 2 and borda["x1"] >= coluna_do_numero + 8})


def ordem_de_leitura(palavra):
    return (round(palavra["top"]), palavra["x0"])


def campos_do_pedaco(palavras_do_pedaco, inicios, bordas, chave_do_registro, numero_da_pagina):
    """Os campos de um pedaço de tabela numa página: cada faixa entre duas bordas é um campo."""
    campos = []
    faixa_de_cada_palavra = {}
    for posicao, palavra in enumerate(palavras_do_pedaco):
        meio = (palavra["top"] + palavra["bottom"]) / 2
        faixa_de_cada_palavra[posicao] = sum(1 for borda in bordas if borda <= meio)
    for faixa in sorted(set(faixa_de_cada_palavra.values())):
        da_faixa = sorted([palavra for posicao, palavra in enumerate(palavras_do_pedaco)
                           if faixa_de_cada_palavra[posicao] == faixa], key=ordem_de_leitura)
        tem_numero = any(coluna_da_palavra(palavra, inicios) == "numero" and re.fullmatch(r"\d{1,3}", palavra["text"])
                         for palavra in da_faixa)
        if not tem_numero:
            if campos:
                for palavra in da_faixa:
                    campos[-1][coluna_da_palavra(palavra, inicios)].append(palavra["text"])
            continue
        campo = {coluna: [] for coluna in COLUNAS_DA_TABELA}
        campo["registro"] = chave_do_registro
        campo["pagina"] = numero_da_pagina
        for palavra in da_faixa:
            campo[coluna_da_palavra(palavra, inicios)].append(palavra["text"])
        campos.append(campo)
    return campos


def leitura_pelas_faixas(caminho_do_pdf):
    campos = []
    niveis = {}
    inicios_dos_registros = {}
    titulo = None
    inicios = None
    na_tabela = False
    with pdfplumber.open(str(caminho_do_pdf)) as documento:
        for numero_da_pagina, pagina in enumerate(documento.pages, start=1):
            palavras = pagina.extract_words(keep_blank_chars=False, use_text_flow=False, x_tolerance=1.5)
            pedaco = []
            for linha in linhas_da_pagina(palavras):
                texto = linha["texto"].strip()
                if LINHA_DE_PAGINA.match(texto):
                    continue
                cabecalho = CABECALHO_DO_REGISTRO.match(texto)
                novos_inicios = inicios_das_colunas(linha)
                acabou = na_tabela and (cabecalho or novos_inicios or FIM_DA_TABELA.match(texto)
                                        or linha["palavras"][0]["x0"] < inicios[0] - 20)
                if acabou:
                    if pedaco:
                        campos += campos_do_pedaco(pedaco, inicios, bordas_da_coluna_do_numero(pagina, inicios),
                                                   titulo.chave(), numero_da_pagina)
                    pedaco = []
                    na_tabela = False
                if cabecalho:
                    titulo = TituloDoRegistro(cabecalho.group(1), texto)
                    continue
                if titulo is None:
                    continue
                titulo.acrescentar(texto)
                if titulo.inicio:
                    inicios_dos_registros[titulo.chave()] = titulo.inicio
                nivel = NIVEL.search(texto)
                if nivel and titulo.chave() not in niveis:
                    niveis[titulo.chave()] = nivel.group(1)
                if novos_inicios:
                    inicios = novos_inicios
                    na_tabela = True
                    continue
                if na_tabela:
                    pedaco += linha["palavras"]
            if pedaco:
                campos += campos_do_pedaco(pedaco, inicios, bordas_da_coluna_do_numero(pagina, inicios),
                                           titulo.chave(), numero_da_pagina)
    lidos = []
    for campo in campos:
        numero = "".join(campo["numero"])
        lidos.append({
            "registro": campo["registro"], "numero": f"{int(numero):02d}" if numero.isdigit() else numero,
            "campo": "".join(campo["campo"]), "tipo": "".join(campo["tipo"]), "tamanho": "".join(campo["tamanho"]),
            "decimais": " ".join(campo["decimais"]), "pagina": campo["pagina"], "descricao": " ".join(campo["descricao"]),
            "nivel": niveis.get(campo["registro"], ""),
            "inicio_do_registro": inicios_dos_registros.get(campo["registro"], "")})
    return lidos


# ---- Os nomes escritos por extenso e o histórico ----

def nomes_mencionados(linhas):
    """Os nomes dos campos como o texto corrido os escreve ("Campo 06 (COD_MOT_REST_COMPL)"), por registro."""
    mencoes = {}
    titulo = None
    for linha in linhas:
        cabecalho = CABECALHO_DO_REGISTRO.match(linha.strip())
        if cabecalho:
            titulo = TituloDoRegistro(cabecalho.group(1), linha.strip())
            continue
        if titulo is None:
            continue
        titulo.acrescentar(linha.strip())
        for numero, nome in MENCAO.findall(linha):
            mencoes.setdefault((titulo.chave(), f"{int(numero):02d}"), set()).add(nome)
    return mencoes


def historico_do_leiaute(linhas):
    """Os registros e os campos incluídos em cada período, das subseções "Alterações no leiaute" do Guia (Capítulo II,
    Seção 1). Devolve os campos (pelo registro e o número) e os registros, cada um com a data em que entrou."""
    periodo_da_frase = re.compile(r"A PARTIR DO PER[ÍI]ODO DE APURA[ÇC][ÃA]O DE (JANEIRO|JULHO) DE (\d{4})")
    linha_de_campo = re.compile(r"^([0-9A-Z]{4})\s+(\d{2})\s+([A-Za-zÀ-ÿ0-9_ ]+?)\s*$")
    # Na tabela de registros: o código seguido do nível e da ocorrência ("K200 3 1:N OC"); em 2010, o código no começo
    # da linha, seguido da descrição ("C105 OPERAÇÕES COM ICMS ST...").
    registro_na_tabela = re.compile(r"(?:^|\s)([0-9BCDEGHK][0-9]{3})(?=\s+(?:\d\s+)?(?:1:N|1:1|1:4|V|1)(?:\s|$))")
    registro_no_comeco = re.compile(r"^([0-9BCDEGHK][0-9]{3})\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ]{2}")
    meses = {"JANEIRO": "01", "JULHO": "07"}
    inicio = next(posicao for posicao, linha in enumerate(linhas) if linha.startswith("SUBSEÇÃO 1 –"))
    fim = next(posicao for posicao, linha in enumerate(linhas)
               if posicao > inicio and linha.startswith("Seção 2 – Registros a serem apresentados"))
    # Em 2012 os registros vêm em prosa ("Registro D195 – Observações..."), e um campo também ("Alteração do Registro
    # H005, com a inclusão do campo 04 - MOT_INV").
    registro_em_prosa = re.compile(r"^Registro ([0-9BCDEGHK][0-9]{3})\s+[–-]")
    campo_em_prosa = re.compile(r"Registro ([0-9A-Z]{4}), com a inclus[ãa]o do campo (\d{2})\s*-\s*([A-Z][A-Z0-9_]*)")
    campos = {}
    registros = {}
    modo = None
    periodo = None
    trecho = [linha.strip() for linha in linhas[inicio:fim]]
    for posicao, linha in enumerate(trecho):
        # O título do período às vezes quebra a linha antes do ano ("... JANEIRO DE" / "2011.").
        proxima = trecho[posicao + 1] if posicao + 1 < len(trecho) else ""
        achado = periodo_da_frase.search(linha) or periodo_da_frase.search(linha + " " + proxima)
        if achado and re.search(r"A PARTIR DO PER", linha):
            periodo = f"{achado.group(2)}-{meses[achado.group(1)]}-01"
            modo = "campos" if re.match(r"^CAMPOS? INCLU", linha) else "registros"
            continue
        # A renumeração do E310 em 2017 é a versão nova do registro inteiro, que tem título próprio; a mudança de regra
        # de validação ("3. Alteração da regra...") não inclui registro.
        if linha.startswith("Registro E310 (altera") or linha.startswith("SUBSEÇÃO") or re.match(
                r"^\d+\.\s+Altera[çc][ãa]o da regra", linha):
            modo = None
            continue
        incluido_em_prosa = campo_em_prosa.search(linha)
        if incluido_em_prosa and periodo:
            campos[(incluido_em_prosa.group(1), incluido_em_prosa.group(2))] = {
                "campo": incluido_em_prosa.group(3), "desde": periodo}
            continue
        if modo == "campos":
            campo = linha_de_campo.match(linha)
            if campo:
                campos[(campo.group(1), campo.group(2))] = {"campo": campo.group(3).replace(" ", ""), "desde": periodo}
        elif modo == "registros":
            achados = registro_na_tabela.findall(linha)
            comeco = registro_no_comeco.match(linha) or registro_em_prosa.match(linha)
            if comeco:
                achados.append(comeco.group(1))
            for registro in achados:
                registros.setdefault(registro, periodo)
    return campos, registros


# ---- A votação ----

def numero_sem_zeros(valor):
    """O tamanho e as casas decimais sem os zeros da frente ("011" é 11, "001*" é 1*), para comparar."""
    numero = re.match(r"^(\d+)(\*?)$", valor)
    return f"{int(numero.group(1))}{numero.group(2)}" if numero else valor


def valores_lidos(leituras, chave, coluna):
    valores = []
    for nome in LEITURAS:
        linha = leituras[nome].get(chave)
        if linha is None:
            continue
        valor = linha[coluna].strip()
        if coluna == "decimais":
            valor = (re.match(r"^(\d+|-)?", valor).group(1) or "")
        if coluna == "campo":
            valor = valor.replace("*", "")
            if NOME_LIMPO.match(valor):
                valores.append(valor)
        elif FORMATOS[coluna].match(valor):
            valores.append(numero_sem_zeros(valor))
    return valores


def votado(valores):
    """O valor da maioria; None quando empata ou não há nenhum."""
    if not valores:
        return None
    contagem = Counter(valores).most_common()
    if len(contagem) > 1 and contagem[0][1] == contagem[1][1]:
        return None
    return contagem[0][0]


def nome_votado(leituras, mencoes, chave):
    candidatos = valores_lidos(leituras, chave, "campo")
    mencionados = sorted(mencoes.get(chave, set()))
    if len(mencionados) == 1:
        mencionado = mencionados[0]
        for candidato in candidatos:
            if mencionado.startswith(candidato) or candidato.startswith(mencionado):
                return mencionado
    # O nome cortado numa leitura conta para o inteiro de outra.
    completos = []
    for candidato in candidatos:
        mais_longo = candidato
        for outro in candidatos:
            if outro.startswith(candidato) and len(outro) > len(mais_longo):
                mais_longo = outro
        completos.append(mais_longo)
    return votado(completos)


def descricao_limpa(texto):
    return re.sub(r"\s+", " ", texto or "").strip()


def ler_decisoes():
    decisoes = {}
    with open(ARQUIVO_DAS_DECISOES, encoding="utf-8") as arquivo:
        for linha in csv.DictReader(arquivo):
            decisoes[(linha["registro"], linha["numero"], linha["coluna"])] = linha
    return decisoes


def montar_o_leiaute(leituras, mencoes, decisoes):
    chaves = set()
    for leitura in leituras.values():
        chaves |= set(leitura)
    leiaute = []
    pendencias = []
    decisoes_usadas = set()
    for chave in sorted(chaves):
        registro, numero = chave
        if not numero.isdigit():
            continue
        if decisoes.get((registro, numero, "linha"), {}).get("valor") == "excluir":
            decisoes_usadas.add((registro, numero, "linha"))
            continue
        linha = {"chave": registro, "numero": numero}
        for coluna in ("campo", "tipo", "tamanho", "decimais"):
            valor = nome_votado(leituras, mencoes, chave) if coluna == "campo" else votado(
                valores_lidos(leituras, chave, coluna))
            decisao = decisoes.get((registro, numero, coluna))
            if decisao:
                decisoes_usadas.add((registro, numero, coluna))
                if valor is not None and valor != decisao["valor"]:
                    print(f"  aviso: a decisão de {registro} {numero} {coluna} ({decisao['valor']}) troca o que a "
                          f"votação deu ({valor})")
                valor = decisao["valor"]
            if valor is None and coluna == "decimais" and linha.get("tipo") == "C":
                valor = "-"
            if valor is None:
                lidos = " / ".join(f"{nome}={leituras[nome][chave][coluna]!r}" for nome in LEITURAS if chave in leituras[nome])
                pendencias.append(f"{registro} {numero} {coluna}: {lidos}")
            linha[coluna] = valor or ""
        decisao = decisoes.get((registro, numero, "nivel"))
        niveis = [leituras[nome][chave]["nivel"] for nome in LEITURAS if chave in leituras[nome] and leituras[nome][chave]["nivel"]]
        if decisao:
            decisoes_usadas.add((registro, numero, "nivel"))
            linha["nivel"] = decisao["valor"]
        else:
            linha["nivel"] = votado(niveis) or ""
            if not linha["nivel"]:
                pendencias.append(f"{registro} {numero} nível: {'/'.join(niveis)}")
        inicios_do_registro = [leituras[nome][chave]["inicio_do_registro"] for nome in LEITURAS
                               if chave in leituras[nome] and leituras[nome][chave]["inicio_do_registro"]]
        linha["inicio_do_registro"] = votado(inicios_do_registro) or ""
        descricao = descricao_limpa((leituras["faixas_guia"].get(chave) or {}).get("descricao"))
        if not descricao:
            descricao = descricao_limpa((leituras["texto_nt"].get(chave) or {}).get("descricao"))
        linha["descricao"] = descricao
        leiaute.append(linha)
    for chave_da_decisao in sorted(set(decisoes) - decisoes_usadas):
        print("  aviso: decisão que não se aplicou a nenhum campo:", chave_da_decisao)
    return leiaute, pendencias


# ---- As conferências e a tabela ----

def numero_do_campo(linha):
    return int(linha["numero"])


def conferir_o_leiaute(leiaute, incluidos, registros_incluidos):
    problemas = []
    por_chave = {}
    for linha in leiaute:
        por_chave.setdefault(linha["chave"], []).append(linha)
    codigos_do_leiaute = {chave.partition("|")[0] for chave in por_chave}
    for registro, desde in sorted(registros_incluidos.items()):
        if registro not in codigos_do_leiaute:
            problemas.append(f"histórico: o registro {registro} (incluído em {desde}) não está no leiaute")
    for chave, campos in sorted(por_chave.items()):
        numeros = sorted(numero_do_campo(campo) for campo in campos)
        if numeros != list(range(1, len(numeros) + 1)):
            problemas.append(f"{chave}: numeração com buraco {numeros}")
        primeiro = min(campos, key=numero_do_campo)
        if (primeiro["campo"], primeiro["tipo"]) != ("REG", "C"):
            problemas.append(f"{chave}: o campo 01 não é o REG")
        niveis = {campo["nivel"] for campo in campos}
        if len(niveis) != 1:
            problemas.append(f"{chave}: mais de um nível {sorted(niveis)}")
    for (registro, numero), incluido in sorted(incluidos.items()):
        campos = por_chave.get(registro, [])
        do_leiaute = [campo for campo in campos if campo["numero"] == numero]
        if not do_leiaute:
            problemas.append(f"histórico: {registro} {numero} {incluido['campo']} não está no leiaute")
        elif do_leiaute[0]["campo"] != incluido["campo"]:
            print(f"  aviso: o histórico chama {registro} {numero} de {incluido['campo']}; as tabelas, de "
                  f"{do_leiaute[0]['campo']} (vale o das tabelas)")
    # Os campos incluídos ocupam o fim do registro: é o que deixa ler um arquivo antigo pela posição.
    for registro in sorted({registro for registro, numero in incluidos}):
        total = len(por_chave.get(registro, []))
        numeros_incluidos = sorted((int(numero) for chave, numero in incluidos if chave == registro), reverse=True)
        for posicao, numero in enumerate(numeros_incluidos):
            if numero != total - posicao:
                problemas.append(f"{registro}: o campo incluído {numero:02d} não está no fim (o registro tem {total})")
                break
    return problemas


def coluna_de_cada_campo(campos):
    """O nome da coluna na leitura: o do leiaute; repetido no mesmo registro (o ALIQ_PIS do C170, em percentual e em
    reais), cada um com o número do campo."""
    contagem = Counter(campo["campo"] for campo in campos)
    for campo in campos:
        campo["coluna"] = campo["campo"] if contagem[campo["campo"]] == 1 else f"{campo['campo']}_{campo['numero']}"


def linhas_da_tabela(leiaute, incluidos, registros_incluidos):
    por_chave = {}
    for linha in leiaute:
        por_chave.setdefault(linha["chave"], []).append(linha)
    tabela = []
    for chave in sorted(por_chave, key=ordem_do_registro):
        campos = sorted(por_chave[chave], key=numero_do_campo)
        coluna_de_cada_campo(campos)
        registro, _, fim = chave.partition("|")
        # A data em que o registro entrou vale para a versão de hoje e para a antiga que já existia nela (o E310 de
        # 2016); não para a antiga que acabou antes (o C177 que valeu até 2018, trocado pelo de 2019).
        registro_desde = registros_incluidos.get(registro, "")
        if fim and registro_desde > fim:
            registro_desde = ""
        for campo in campos:
            incluido = incluidos.get((registro, campo["numero"])) if not fim else None
            inicios = [data for data in (campo["inicio_do_registro"], registro_desde, incluido["desde"] if incluido else "")
                       if data]
            tabela.append({
                "registro": registro, "inicio": max(inicios) if inicios else "", "fim": fim,
                "nivel": campo["nivel"], "numero": campo["numero"], "campo": campo["campo"], "coluna": campo["coluna"],
                "tipo": campo["tipo"], "tamanho": campo["tamanho"], "decimais": campo["decimais"],
                "descricao": campo["descricao"]})
    return tabela


def ordem_do_registro(chave):
    """Na ordem do arquivo: o bloco 0, depois B, C, D, E, G, H, K, 1 e 9; a versão antiga antes da de hoje."""
    blocos = "0BCDEGHK19"
    registro, _, fim = chave.partition("|")
    return (blocos.index(registro[0]), registro, 0 if fim else 1)


def gravar(tabela):
    with open(ARQUIVO_DA_TABELA, "w", encoding="utf-8", newline="") as arquivo:
        escritor = csv.DictWriter(arquivo, fieldnames=list(tabela[0].keys()), quoting=csv.QUOTE_NONNUMERIC,
                                  lineterminator="\n")
        escritor.writeheader()
        escritor.writerows(tabela)


def texto_entre_aspas(valor):
    """Como o R grava as fontes: o texto entre aspas e o vazio sem nada."""
    return "" if valor == "" else '"' + valor.replace('"', '""') + '"'


def gravar_a_fonte(titulo_do_guia, titulo_da_nota, texto_do_guia):
    """A linha do leiaute em fontes.csv: as duas publicações, a data de atualização do Guia e o dia de hoje."""
    meses = {"janeiro": "01", "fevereiro": "02", "março": "03", "abril": "04", "maio": "05", "junho": "06",
             "julho": "07", "agosto": "08", "setembro": "09", "outubro": "10", "novembro": "11", "dezembro": "12"}
    atualizacao = next(re.search(r"Atualização: (\d{1,2}) de (\w+) de (\d{4})", linha) for linha in texto_do_guia
                       if linha.startswith("Atualização: "))
    data_do_guia = f"{atualizacao.group(3)}-{meses[atualizacao.group(2).lower()]}-{int(atualizacao.group(1)):02d}"
    versao = re.search(r"(\d+\.\d+\.\d+)", titulo_do_guia).group(1)
    fonte = (f"Portal do SPED, {titulo_do_guia} e {titulo_da_nota}: as tabelas de campos das duas, lidas e conferidas "
             "uma contra a outra por ferramentas/gerar_leiaute_efd.py (as divergências em "
             "ferramentas/leiaute_efd_decisoes.csv); a vigência pelo título do registro e pelo histórico de campos "
             "incluídos do Guia")
    linha_nova = ",".join([texto_entre_aspas("leiaute_efd_icms_ipi"), texto_entre_aspas(fonte), texto_entre_aspas(versao),
                           texto_entre_aspas(data_do_guia), texto_entre_aspas(str(date.today()))])
    arquivo_das_fontes = ARQUIVO_DA_TABELA.parent / "fontes.csv"
    linhas = arquivo_das_fontes.read_text(encoding="utf-8").rstrip("\n").split("\n")
    linhas = [linha for linha in linhas if not linha.startswith('"leiaute_efd_icms_ipi"')] + [linha_nova]
    arquivo_das_fontes.write_text("\n".join(linhas) + "\n", encoding="utf-8", newline="")


def principal():
    (versao_do_guia, item_do_guia, titulo_do_guia), (versao_da_nt, item_da_nt, titulo_da_nt) = publicacoes_mais_novas()
    print("Guia:", titulo_do_guia, "| Nota Técnica:", titulo_da_nt)
    pasta = Path(tempfile.mkdtemp(prefix="leiaute_efd_"))
    guia, nota = pasta / "guia.pdf", pasta / "nota_tecnica.pdf"
    baixar(item_do_guia, guia)
    baixar(item_da_nt, nota)
    texto_do_guia, texto_da_nota = linhas_do_texto(guia), linhas_do_texto(nota)
    leituras = {}
    for nome, lidos in (("texto_nt", leitura_pelo_texto(texto_da_nota, "nt")),
                        ("texto_guia", leitura_pelo_texto(texto_do_guia, "guia")),
                        ("faixas_nt", leitura_pelas_faixas(nota)),
                        ("faixas_guia", leitura_pelas_faixas(guia))):
        leituras[nome] = {(linha["registro"], linha["numero"]): linha for linha in lidos}
        print(f"  {nome}: {len(lidos)} campos")
    mencoes = nomes_mencionados(texto_do_guia)
    incluidos, registros_incluidos = historico_do_leiaute(texto_do_guia)
    leiaute, pendencias = montar_o_leiaute(leituras, mencoes, ler_decisoes())
    problemas = conferir_o_leiaute(leiaute, incluidos, registros_incluidos)
    if pendencias or problemas:
        print("Sem gravar: o que a votação não decidiu e as conferências que falharam (veja a página e acrescente a",
              "decisão em", ARQUIVO_DAS_DECISOES, "com o motivo):")
        for linha in pendencias + problemas:
            print("  ", linha)
        sys.exit(1)
    tabela = linhas_da_tabela(leiaute, incluidos, registros_incluidos)
    gravar(tabela)
    gravar_a_fonte(titulo_do_guia, titulo_da_nt, texto_do_guia)
    print(f"Gravado {ARQUIVO_DA_TABELA}: {len({linha['registro'] for linha in tabela})} registros, {len(tabela)} campos;",
          f"a data em que entraram: {len(registros_incluidos)} registros e {len(incluidos)} campos.",
          "Agora: Rscript ferramentas/gerar_conferencia_das_tabelas.R")


if __name__ == "__main__":
    principal()
