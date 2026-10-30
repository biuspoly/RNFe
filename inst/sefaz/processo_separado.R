# Roda num processo R à parte, que o RNFe abre com CURL_SSL_BACKEND=openssl quando a sessão usa o Schannel (o motor
# padrão do curl no Windows, que não conecta com todas as SEFAZ). Recebe a tarefa (os pedidos, as opções e a função
# que envia, de R/sefaz.R) e grava as respostas. A senha do certificado vem na variável de ambiente, nunca em arquivo.
# Uso (pelo RNFe): Rscript --vanilla processo_separado.R <arquivo da tarefa> <arquivo do resultado>
argumentos = commandArgs(trailingOnly = TRUE)
tarefa = readRDS(argumentos[1])
.libPaths(tarefa$bibliotecas)
opcoes = tarefa$opcoes
opcoes$keypasswd = Sys.getenv("RNFE_SENHA_DO_CERTIFICADO")
respostas = tarefa$enviar(tarefa$pedidos, opcoes, tarefa$tempo_limite)
saveRDS(list(motor = curl::curl_version()$ssl_version, respostas = respostas), argumentos[2])
