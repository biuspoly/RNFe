# Os certificados de tests/testthat/certificados são falsos (ferramentas/gerar_certificados_de_teste.py):
# autoassinados, com CNPJ e CPF fictícios nos campos que o DOC-ICP-04 reserva para eles, e senha "teste".
CERTIFICADO_PJ = test_path("certificados", "pessoa_juridica.pfx")
CERTIFICADO_PF = test_path("certificados", "pessoa_fisica.pfx")
CERTIFICADO_SEM_OS_CAMPOS = test_path("certificados", "sem_os_campos.pfx")
CERTIFICADO_VENCIDO = test_path("certificados", "vencido.pfx")

test_that("o certificado de pessoa jur\u00eddica: o CNPJ do campo 2.16.76.1.3.3, n\u00e3o o CPF do respons\u00e1vel", {
  skip_if_not_installed("openssl")
  certificado = certificado_ler(CERTIFICADO_PJ, "teste")
  expect_identical(certificado$titular, "EMPRESA DE TESTE LTDA")
  expect_identical(certificado$documento, "11222333000181")
  expect_identical(certificado$tipo_documento, "CNPJ")
  expect_identical(certificado$emissor, "AC DE TESTE DO RNFE")
  expect_equal(as.numeric(certificado$valido_desde), as.numeric(as.POSIXct("2026-01-01 12:00:00", tz = "UTC")))
  expect_equal(as.numeric(certificado$valido_ate), as.numeric(as.POSIXct("2036-01-01 12:00:00", tz = "UTC")))
  expect_identical(attr(certificado$valido_ate, "tzone"), "America/Sao_Paulo")
  expect_false(certificado$vencido)
  expect_gt(certificado$dias_para_vencer, 3000)
  expect_true(is.na(certificado$problema))
})

test_that("o de pessoa f\u00edsica, o sem os campos (o n\u00famero do fim do nome) e o vencido", {
  skip_if_not_installed("openssl")
  certificados = certificado_ler(c(CERTIFICADO_PF, CERTIFICADO_SEM_OS_CAMPOS, CERTIFICADO_VENCIDO), "teste")
  expect_identical(certificados$titular, c("PESSOA DE TESTE", "EMPRESA, FILIAL DE TESTE", "EMPRESA DE TESTE LTDA"))
  expect_identical(certificados$documento, c("12345678909", "11444777000161", "11222333000181"))
  expect_identical(certificados$tipo_documento, c("CPF", "CNPJ", "CNPJ"))
  expect_identical(certificados$vencido, c(FALSE, FALSE, TRUE))
  expect_lt(certificados$dias_para_vencer[3], 0)
})

test_that("senha errada, arquivo que n\u00e3o existe e nenhum arquivo", {
  skip_if_not_installed("openssl")
  certificados = certificado_ler(c(CERTIFICADO_PJ, "nao_existe.pfx"), c("errada", "teste"))
  expect_match(certificados$problema[1], "senha")
  expect_identical(certificados$problema[2], "arquivo n\u00e3o encontrado")
  expect_true(all(is.na(certificados$documento)))
  vazio = certificado_ler(character(), "teste")
  expect_identical(nrow(vazio), 0L)
  expect_identical(names(vazio), names(certificados))
})

test_that("a validade em ingl\u00eas vira data em qualquer idioma", {
  expect_equal(as.numeric(data_do_certificado("Mar  5 14:10:00 2027 GMT")),
               as.numeric(as.POSIXct("2027-03-05 14:10:00", tz = "UTC")))
  expect_equal(as.numeric(data_do_certificado("Oct 30 00:00:01 2026 GMT")),
               as.numeric(as.POSIXct("2026-10-30 00:00:01", tz = "UTC")))
})
