# Atividade 5 — A stack completa

## Serviços saudáveis

Comando:

```bash
docker compose ps
```

Saída após recriar a stack:

```text
NAME                       IMAGE                             COMMAND                  SERVICE   CREATED          STATUS                    PORTS
ufla-devops-shop-api-1     ghcr.io/youserz/ufla-shop:1.0.0   "uvicorn app:api --h…"   api       37 seconds ago   Up 28 seconds (healthy)   8000/tcp
ufla-devops-shop-banco-1   postgres:16-alpine                "docker-entrypoint.s…"   banco     38 seconds ago   Up 34 seconds (healthy)   5432/tcp
ufla-devops-shop-cache-1   redis:7-alpine                    "docker-entrypoint.s…"   cache     38 seconds ago   Up 34 seconds (healthy)   6379/tcp
ufla-devops-shop-nginx-1   nginx:1.27-alpine                 "/docker-entrypoint.…"   nginx     36 seconds ago   Up 22 seconds (healthy)   0.0.0.0:80->80/tcp, [::]:80->80/tcp
```

Somente o Nginx publica uma porta na máquina. A API acessa PostgreSQL
e Redis pelos nomes dos serviços, `banco` e `cache`.

## Acesso pelo Nginx

```bash
curl -I http://localhost
```

Resposta:

```text
HTTP/1.1 200 OK
Server: nginx/1.27.5
Content-Type: text/html; charset=utf-8
```

A configuração da página inicial encaminha a consulta ao upstream
usando GET, permitindo que o Nginx responda ao HEAD enviado por curl -I.

```bash
curl -fsS http://localhost/api/info
```

```json
{"aplicacao":"ufla-devops-shop","versao":"1.0.0","banco":"postgresql","cache":"redis","instancia":"da867cff892d"}
```

## Prova de persistência

Criação do produto:

```bash
curl -fsS -X POST http://localhost/api/produtos \
  -H 'Content-Type: application/json' \
  -d '{"nome":"Prova de persistencia","preco":9.9,"estoque":1}'
```

Resposta:

```json
{"id":13,"nome":"Prova de persistencia","descricao":"","preco":9.9,"estoque":1,"criado_em":"2026-10-17T18:19:05.730173+00:00"}
```

Remoção dos containers e da rede, preservando o volume:

```bash
docker compose down
```

```text
✔ Container ufla-devops-shop-nginx-1 Removed
✔ Container ufla-devops-shop-api-1 Removed
✔ Container ufla-devops-shop-cache-1 Removed
✔ Container ufla-devops-shop-banco-1 Removed
✔ Network ufla-devops-shop_default Removed
```

Recriação:

```bash
docker compose up -d --wait
```

```text
✔ Network ufla-devops-shop_default Created
✔ Container ufla-devops-shop-banco-1 Healthy
✔ Container ufla-devops-shop-cache-1 Healthy
✔ Container ufla-devops-shop-api-1 Healthy
✔ Container ufla-devops-shop-nginx-1 Healthy
```

Busca após a recriação:

```bash
curl -fsS 'http://localhost/api/busca?q=persistencia'
```

```json
{"termo":"persistencia","total":1,"resultados":[{"id":13,"nome":"Prova de persistencia","descricao":"","preco":9.9,"estoque":1,"criado_em":"2026-10-17T18:19:05.730173+00:00"}]}
```

O produto permaneceu porque o PostgreSQL armazena seus dados no volume
nomeado `dados_banco`, montado em `/var/lib/postgresql/data`.
O comando down foi executado sem -v.

## Imagem pública no GHCR

Imagem utilizada no Compose:

```text
ghcr.io/youserz/ufla-shop:1.0.0
```

Página do pacote:
https://github.com/users/youserz/packages/container/package/ufla-shop

Download verificado após encerrar a autenticação:

```bash
docker logout ghcr.io
docker pull ghcr.io/youserz/ufla-shop:1.0.0
```

```text
Digest: sha256:48978e9fe3ebb64b235b0340db79e026e05e6be356a320ad7de9f5fdf663dcc5
Status: Image is up to date for ghcr.io/youserz/ufla-shop:1.0.0
```

A imagem foi construída com Python Alpine e multi-stage.
O tamanho medido nesta máquina foi de 140 MB.

## Por que depends_on sozinho não resolve?

O depends_on simples controla a ordem de inicialização dos containers,
mas um processo iniciado ainda pode não estar pronto para aceitar conexões.
Com condition: service_healthy, o Compose aguarda os healthchecks do
PostgreSQL e do Redis indicarem que estão saudáveis antes de iniciar a API.
