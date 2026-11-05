"""Gera inst/exemplos/efd_icms_ipi_sp.txt: uma EFD ICMS/IPI inventada, de outubro de 2026, da empresa fictícia da NF-e
de exemplo (CNPJ 11.222.333/0001-81), com a venda da nota 1001 do nfe_proc_sp.xml, uma compra com o item e as apurações.

Cada linha é montada pelos nomes de campo do leiaute (inst/extdata/tabelas/leiaute_efd_icms_ipi.csv), na ordem dele, e
o número de campos é conferido; as contagens dos blocos e do bloco 9 são feitas aqui. Grava em ISO 8859-1 (Latin-1),
com CR LF no fim de cada linha, como pede o leiaute.

Uso, na raiz do repositório:
    python ferramentas/gerar_efd_de_exemplo.py
"""
import csv
import sys
from collections import Counter
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
ARQUIVO_DO_LEIAUTE = Path("inst/extdata/tabelas/leiaute_efd_icms_ipi.csv")
ARQUIVO_DO_EXEMPLO = Path("inst/exemplos/efd_icms_ipi_sp.txt")
INICIO_DO_PERIODO = "2026-10-01"


def numero_do_campo(campo):
    return int(campo["numero"])


def campos_de_cada_registro():
    """Os nomes das colunas de cada registro no leiaute de outubro de 2026, na ordem."""
    with open(ARQUIVO_DO_LEIAUTE, encoding="utf-8") as arquivo:
        linhas = list(csv.DictReader(arquivo))
    campos = {}
    for linha in linhas:
        vale_no_periodo = (linha["inicio"] == "" or linha["inicio"] <= INICIO_DO_PERIODO) and (
            linha["fim"] == "" or linha["fim"] >= INICIO_DO_PERIODO)
        if vale_no_periodo:
            campos.setdefault(linha["registro"], []).append(linha)
    return {registro: [campo["coluna"] for campo in sorted(lista, key=numero_do_campo)] for registro, lista in campos.items()}


def digito_da_chave(chave_sem_digito):
    """O dígito verificador da chave de acesso: módulo 11, com os pesos de 2 a 9 da direita para a esquerda."""
    soma = 0
    peso = 2
    for algarismo in reversed(chave_sem_digito):
        soma += int(algarismo) * peso
        peso = 2 if peso == 9 else peso + 1
    resto = soma % 11
    return "0" if resto < 2 else str(11 - resto)


def montar_linha(colunas_do_registro, registro, valores):
    desconhecidos = set(valores) - set(colunas_do_registro)
    if desconhecidos:
        raise ValueError(f"{registro}: campos fora do leiaute {sorted(desconhecidos)}")
    campos = [registro] + [valores.get(coluna, "") for coluna in colunas_do_registro[1:]]
    return "|" + "|".join(campos) + "|"


def encerramento_do_bloco(colunas, linhas, bloco):
    """O registro X990 do bloco: as linhas dele, contando a abertura (X001) e o próprio encerramento."""
    quantidade_do_bloco = sum(1 for linha in linhas if linha[1] == bloco) + 1
    return montar_linha(colunas[f"{bloco}990"], f"{bloco}990", {f"QTD_LIN_{bloco}": str(quantidade_do_bloco)})


def principal():
    colunas = campos_de_cada_registro()
    chave_da_compra = "33261011444777000161550010000005551876543210"[:43]
    chave_da_compra = chave_da_compra + digito_da_chave(chave_da_compra)
    registros = [
        ("0000", {"COD_VER": "020", "COD_FIN": "0", "DT_INI": "01102026", "DT_FIN": "31102026",
                  "NOME": "EMPRESA DE TESTE LTDA", "CNPJ": "11222333000181", "UF": "SP", "IE": "123456789012",
                  "COD_MUN": "3550308", "IND_PERFIL": "A", "IND_ATIV": "0"}),
        ("0001", {"IND_MOV": "0"}),
        ("0005", {"FANTASIA": "TESTE", "CEP": "01001000", "END": "RUA DE TESTE", "NUM": "100", "BAIRRO": "CENTRO",
                  "FONE": "1133334444"}),
        ("0100", {"NOME": "CONTADORA DE TESTE", "CPF": "12345678909", "CRC": "1SP000000O0", "CEP": "01001000",
                  "END": "RUA DE TESTE", "NUM": "200", "BAIRRO": "CENTRO", "FONE": "1133335555",
                  "EMAIL": "contabilidade@exemplo.invalid", "COD_MUN": "3550308"}),
        ("0150", {"COD_PART": "P001", "NOME": "DESTINATÁRIO DE TESTE LTDA", "COD_PAIS": "01058",
                  "CNPJ": "11444777000161", "IE": "12345678", "COD_MUN": "3304557", "END": "AVENIDA DE TESTE",
                  "NUM": "200", "BAIRRO": "CENTRO"}),
        ("0190", {"UNID": "UN", "DESCR": "UNIDADE"}),
        ("0200", {"COD_ITEM": "001", "DESCR_ITEM": "ÁGUA MINERAL DE TESTE 500 ML", "UNID_INV": "UN",
                  "TIPO_ITEM": "00", "COD_NCM": "22011000"}),
        ("0200", {"COD_ITEM": "002", "DESCR_ITEM": "REFRIGERANTE DE TESTE 2 L", "UNID_INV": "UN",
                  "TIPO_ITEM": "00", "COD_NCM": "22021000"}),
        ("B001", {"IND_DAD": "1"}),
        ("C001", {"IND_MOV": "0"}),
        # A venda: a nota 1001 do nfe_proc_sp.xml (água com ICMS de 12% e IPI; refrigerante com o ICMS-ST retido).
        ("C100", {"IND_OPER": "1", "IND_EMIT": "0", "COD_PART": "P001", "COD_MOD": "55", "COD_SIT": "00", "SER": "1",
                  "NUM_DOC": "1001", "CHV_NFE": "35261011222333000181550010000010011123456785", "DT_DOC": "15102026",
                  "DT_E_S": "15102026", "VL_DOC": "115,00", "IND_PGTO": "1", "VL_DESC": "0,00", "VL_ABAT_NT": "0,00",
                  "VL_MERC": "110,00", "IND_FRT": "0", "VL_FRT": "0,00", "VL_SEG": "0,00", "VL_OUT_DA": "0,00",
                  "VL_BC_ICMS": "50,00", "VL_ICMS": "6,00", "VL_BC_ICMS_ST": "0,00", "VL_ICMS_ST": "0,00",
                  "VL_IPI": "5,00", "VL_PIS": "0,83", "VL_COFINS": "3,80", "VL_PIS_ST": "0,00", "VL_COFINS_ST": "0,00"}),
        ("C190", {"CST_ICMS": "000", "CFOP": "6102", "ALIQ_ICMS": "12,00", "VL_OPR": "55,00", "VL_BC_ICMS": "50,00",
                  "VL_ICMS": "6,00", "VL_BC_ICMS_ST": "0,00", "VL_ICMS_ST": "0,00", "VL_RED_BC": "0,00",
                  "VL_IPI": "5,00"}),
        ("C190", {"CST_ICMS": "060", "CFOP": "6404", "ALIQ_ICMS": "0,00", "VL_OPR": "60,00", "VL_BC_ICMS": "0,00",
                  "VL_ICMS": "0,00", "VL_BC_ICMS_ST": "0,00", "VL_ICMS_ST": "0,00", "VL_RED_BC": "0,00",
                  "VL_IPI": "0,00"}),
        # A compra: 20 águas do mesmo participante, com o crédito do ICMS, do PIS e da COFINS.
        ("C100", {"IND_OPER": "0", "IND_EMIT": "1", "COD_PART": "P001", "COD_MOD": "55", "COD_SIT": "00", "SER": "1",
                  "NUM_DOC": "555", "CHV_NFE": chave_da_compra, "DT_DOC": "10102026", "DT_E_S": "12102026",
                  "VL_DOC": "100,00", "IND_PGTO": "1", "VL_DESC": "0,00", "VL_ABAT_NT": "0,00", "VL_MERC": "100,00",
                  "IND_FRT": "1", "VL_FRT": "0,00", "VL_SEG": "0,00", "VL_OUT_DA": "0,00", "VL_BC_ICMS": "100,00",
                  "VL_ICMS": "12,00", "VL_BC_ICMS_ST": "0,00", "VL_ICMS_ST": "0,00", "VL_IPI": "0,00",
                  "VL_PIS": "1,65", "VL_COFINS": "7,60", "VL_PIS_ST": "0,00", "VL_COFINS_ST": "0,00"}),
        ("C170", {"NUM_ITEM": "1", "COD_ITEM": "001", "QTD": "20,00000", "UNID": "UN", "VL_ITEM": "100,00",
                  "VL_DESC": "0,00", "IND_MOV": "0", "CST_ICMS": "000", "CFOP": "2102", "VL_BC_ICMS": "100,00",
                  "ALIQ_ICMS": "12,00", "VL_ICMS": "12,00", "VL_BC_ICMS_ST": "0,00", "ALIQ_ST": "0,00",
                  "VL_ICMS_ST": "0,00", "CST_PIS": "50", "VL_BC_PIS": "100,00", "ALIQ_PIS_27": "1,6500",
                  "VL_PIS": "1,65", "CST_COFINS": "50", "VL_BC_COFINS": "100,00", "ALIQ_COFINS_33": "7,6000",
                  "VL_COFINS": "7,60", "VL_ABAT_NT": "0,00"}),
        ("C190", {"CST_ICMS": "000", "CFOP": "2102", "ALIQ_ICMS": "12,00", "VL_OPR": "100,00", "VL_BC_ICMS": "100,00",
                  "VL_ICMS": "12,00", "VL_BC_ICMS_ST": "0,00", "VL_ICMS_ST": "0,00", "VL_RED_BC": "0,00",
                  "VL_IPI": "0,00"}),
        ("D001", {"IND_MOV": "1"}),
        ("E001", {"IND_MOV": "0"}),
        ("E100", {"DT_INI": "01102026", "DT_FIN": "31102026"}),
        ("E110", {"VL_TOT_DEBITOS": "6,00", "VL_AJ_DEBITOS": "0,00", "VL_TOT_AJ_DEBITOS": "0,00",
                  "VL_ESTORNOS_CRED": "0,00", "VL_TOT_CREDITOS": "12,00", "VL_AJ_CREDITOS": "0,00",
                  "VL_TOT_AJ_CREDITOS": "0,00", "VL_ESTORNOS_DEB": "0,00", "VL_SLD_CREDOR_ANT": "0,00",
                  "VL_SLD_APURADO": "0,00", "VL_TOT_DED": "0,00", "VL_ICMS_RECOLHER": "0,00",
                  "VL_SLD_CREDOR_TRANSPORTAR": "6,00", "DEB_ESP": "0,00"}),
        ("E500", {"IND_APUR": "0", "DT_INI": "01102026", "DT_FIN": "31102026"}),
        ("E510", {"CFOP": "6102", "CST_IPI": "50", "VL_CONT_IPI": "55,00", "VL_BC_IPI": "50,00", "VL_IPI": "5,00"}),
        ("E520", {"VL_SD_ANT_IPI": "0,00", "VL_DEB_IPI": "5,00", "VL_CRED_IPI": "0,00", "VL_OD_IPI": "0,00",
                  "VL_OC_IPI": "0,00", "VL_SC_IPI": "0,00", "VL_SD_IPI": "5,00"}),
        ("G001", {"IND_MOV": "1"}),
        ("H001", {"IND_MOV": "1"}),
        ("K001", {"IND_MOV": "1"}),
        ("1001", {"IND_MOV": "0"}),
        ("1010", {coluna: "N" for coluna in colunas["1010"][1:]}),
    ]
    linhas = []
    bloco_atual = None
    for registro, valores in registros:
        # O encerramento de cada bloco vem logo depois do último registro dele.
        if bloco_atual is not None and registro[0] != bloco_atual:
            linhas.append(encerramento_do_bloco(colunas, linhas, bloco_atual))
        linhas.append(montar_linha(colunas[registro], registro, valores))
        bloco_atual = registro[0]
    linhas.append(encerramento_do_bloco(colunas, linhas, bloco_atual))
    linhas.append(montar_linha(colunas["9001"], "9001", {"IND_MOV": "0"}))
    contagem = Counter(linha[1:5] for linha in linhas)
    tipos_na_ordem = list(dict.fromkeys(linha[1:5] for linha in linhas)) + ["9900", "9990", "9999"]
    for registro in tipos_na_ordem:
        quantidade = contagem.get(registro, 0)
        if registro == "9900":
            quantidade = len(tipos_na_ordem)
        if registro in ("9990", "9999"):
            quantidade = 1
        linhas.append(montar_linha(colunas["9900"], "9900", {"REG_BLC": registro, "QTD_REG_BLC": str(quantidade)}))
    linhas_do_bloco_9 = sum(1 for linha in linhas if linha[1] == "9") + 2
    linhas.append(montar_linha(colunas["9990"], "9990", {"QTD_LIN_9": str(linhas_do_bloco_9)}))
    linhas.append(montar_linha(colunas["9999"], "9999", {"QTD_LIN": str(len(linhas) + 1)}))
    for linha in linhas:
        registro = linha[1:5]
        if len(linha.split("|")) - 2 != len(colunas[registro]):
            raise ValueError(f"{registro}: o número de campos não confere com o leiaute")
    ARQUIVO_DO_EXEMPLO.write_bytes(("\r\n".join(linhas) + "\r\n").encode("latin-1"))
    print(f"Gravado {ARQUIVO_DO_EXEMPLO}: {len(linhas)} linhas; chave da compra {chave_da_compra}")


if __name__ == "__main__":
    principal()
