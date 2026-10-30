"""Gera os certificados FALSOS dos testes (tests/testthat/certificados), autoassinados, com CNPJ e CPF fictícios.

Seguem o DOC-ICP-04 v8.3 nos campos otherName da extensão Subject Alternative Name, codificados como nos
certificados reais (PrintableString): o de pessoa jurídica traz os quatro campos que eles trazem (2.16.76.1.3.4,
.2, .3 e .7), o de pessoa física, o 2.16.76.1.3.1. A senha de todos é "teste". Uso, na raiz do repositório
(precisa do pacote cryptography):
    python ferramentas/gerar_certificados_de_teste.py
"""

import datetime
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import NameOID

PASTA_DOS_CERTIFICADOS = Path("tests/testthat/certificados")
SENHA = b"teste"
EMISSOR = "AC DE TESTE DO RNFE"


def texto_imprimivel(texto):
    conteudo = texto.encode("ascii")
    return bytes([0x13, len(conteudo)]) + conteudo


def outro_nome(oid, texto):
    return x509.OtherName(x509.ObjectIdentifier(oid), texto_imprimivel(texto))


def gravar_certificado(nome_do_arquivo, nome_do_titular, outros_nomes, valido_desde, valido_ate):
    chave = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    titular = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, "BR"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "ICP-Brasil"),
        x509.NameAttribute(NameOID.COMMON_NAME, nome_do_titular),
    ])
    emissor = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, "BR"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "ICP-Brasil"),
        x509.NameAttribute(NameOID.COMMON_NAME, EMISSOR),
    ])
    construtor = (
        x509.CertificateBuilder()
        .subject_name(titular)
        .issuer_name(emissor)
        .public_key(chave.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(valido_desde)
        .not_valid_after(valido_ate)
    )
    if outros_nomes:
        construtor = construtor.add_extension(x509.SubjectAlternativeName(outros_nomes), critical=False)
    certificado = construtor.sign(chave, hashes.SHA256())
    conteudo = pkcs12.serialize_key_and_certificates(
        b"teste", chave, certificado, None, serialization.BestAvailableEncryption(SENHA)
    )
    (PASTA_DOS_CERTIFICADOS / nome_do_arquivo).write_bytes(conteudo)
    print(nome_do_arquivo)


PASTA_DOS_CERTIFICADOS.mkdir(parents=True, exist_ok=True)
DESDE = datetime.datetime(2026, 1, 1, 12, 0, 0, tzinfo=datetime.timezone.utc)
ATE = datetime.datetime(2036, 1, 1, 12, 0, 0, tzinfo=datetime.timezone.utc)
gravar_certificado(
    "pessoa_juridica.pfx",
    "EMPRESA DE TESTE LTDA:11222333000181",
    [
        outro_nome("2.16.76.1.3.4", "01011990" + "12345678909" + "00000000000" + "000000000000000" + "000000"),
        outro_nome("2.16.76.1.3.2", "RESPONSAVEL DE TESTE"),
        outro_nome("2.16.76.1.3.3", "11222333000181"),
        outro_nome("2.16.76.1.3.7", "000000000000"),
    ],
    DESDE,
    ATE,
)
gravar_certificado(
    "pessoa_fisica.pfx",
    "PESSOA DE TESTE:12345678909",
    [outro_nome("2.16.76.1.3.1", "01011990" + "12345678909" + "00000000000" + "000000000000000" + "000000")],
    DESDE,
    ATE,
)
gravar_certificado("sem_os_campos.pfx", "EMPRESA, FILIAL DE TESTE:11444777000161", [], DESDE, ATE)
gravar_certificado(
    "vencido.pfx",
    "EMPRESA DE TESTE LTDA:11222333000181",
    [outro_nome("2.16.76.1.3.3", "11222333000181")],
    datetime.datetime(2020, 1, 1, 12, 0, 0, tzinfo=datetime.timezone.utc),
    datetime.datetime(2021, 1, 1, 12, 0, 0, tzinfo=datetime.timezone.utc),
)
