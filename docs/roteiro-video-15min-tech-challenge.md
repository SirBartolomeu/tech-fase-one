# Roteiro curto de video - Tech Challenge Fase 2

Objetivo: demonstrar, em menos de 10 minutos, o minimo exigido: deploy da aplicacao, CI/CD, consumo das APIs e escalabilidade automatica.

## Ideia central para explicar

Nao existe cloud nesta entrega. O deploy Kubernetes foi preparado para ambiente local/efemero com `kind`.

- Localmente: Docker Compose sobe API, PostgreSQL e Mailpit para demonstracao rapida.
- No CI/CD: o workflow `deploy-kind` cria um cluster Kubernetes `kind` dentro do runner do GitHub Actions, faz build da imagem, carrega a imagem no cluster, aplica os manifests e executa smoke test.
- Em uma cloud real, a mesma ideia seria trocar o cluster `kind` por AKS/EKS/GKE e trocar secrets efemeros por secrets do ambiente.

## Pre-check antes de gravar

Na raiz do projeto:

```powershell
docker compose down --remove-orphans
docker compose up -d --build
Invoke-WebRequest http://localhost:8080/health/ready
Invoke-WebRequest http://localhost:8080/swagger/v1/swagger.json
```

Se quiser mostrar testes no terminal:

```powershell
dotnet test .\OficinaMvp.sln --configuration Release --no-build --verbosity minimal --maxcpucount:1
powershell -ExecutionPolicy Bypass -File .\scripts\validate-domain-coverage.ps1 -Minimum 80
```

Ao terminar:

```powershell
docker compose down
```

## Roteiro sugerido, 6 a 8 minutos

| Tempo | Mostrar | O que falar |
|---|---|---|
| 00:00-00:40 | `README.md` | Esta e a evolucao da Fase 1 para Fase 2: Clean Architecture, Docker, Kubernetes local com kind, CI/CD, testes e seguranca. |
| 00:40-01:40 | GitHub Actions | Mostrar checks `build-test` e `container`. Explicar que `build-test` roda restore, build, testes e cobertura minima; `container` valida build da imagem. |
| 01:40-02:40 | `.github/workflows/deploy-kind.yml` | Explicar o deploy: Terraform cria cluster kind no runner, Docker build gera a imagem, `kind load` carrega a imagem, `kubectl apply -k ./k8s` publica API e banco, smoke test valida `/health/ready` e Swagger. |
| 02:40-03:40 | `k8s/deployment.yaml` e `k8s/hpa.yaml` | Mostrar probes, requests/limits, container non-root e HPA de 1 a 5 replicas por CPU/memoria. |
| 03:40-04:30 | Terminal com Docker Compose | Mostrar `docker compose up -d --build` ja executado e `http://localhost:8080/swagger`. Isso e o deploy local rapido para demonstrar a aplicacao rodando. |
| 04:30-06:30 | Swagger | Gerar JWT, autorizar, chamar `/api/customers`, `/api/work-orders`, `/api/work-orders/{id}/status` e tracking publico. |
| 06:30-07:20 | Escalabilidade | Mostrar `k8s/hpa.yaml` e explicar que o HPA escala automaticamente. Se quiser simular sem carga real: `kubectl -n oficina scale deploy/oficina-api --replicas=3` demonstra multiplas replicas; o HPA faria isso automaticamente com carga/metrics-server. |
| 07:20-08:00 | `security-report/relatorio-vulnerabilidades.md` ou testes | Fechar mostrando cobertura >= 80%, relatorio de vulnerabilidades e checks verdes. |

## Sequencia minima de APIs no Swagger

### 1. Autenticacao

`POST /api/auth/token`

```json
{
  "username": "admin",
  "password": "Admin@123"
}
```

Copie `accessToken` e use `Authorize` com:

```text
Bearer TOKEN_AQUI
```

### 2. Validar API protegida

`GET /api/customers`

Fala: rota administrativa exige JWT.

### 3. Criar OS usando seed demo

A seed cria cliente `52998224725`, veiculo `BRA2E19`, servicos e pecas. Para facilitar, primeiro consulte:

- `GET /api/services`
- `GET /api/parts`

Depois use os IDs retornados em `POST /api/work-orders`:

```json
{
  "customerDocument": "52998224725",
  "vehicle": {
    "licensePlate": "BRA2E19",
    "brand": "Volkswagen",
    "model": "Gol",
    "year": 2021
  },
  "services": [
    {
      "serviceId": "COLE_UM_SERVICE_ID",
      "quantity": 1
    }
  ],
  "parts": [
    {
      "partId": "COLE_UM_PART_ID",
      "quantity": 1
    }
  ],
  "notes": "OS criada no video"
}
```

### 4. Consultar status

`GET /api/work-orders/{id}/status`

Fala: endpoint explicito pedido na Fase 2.

### 5. Tracking publico

`GET /api/client/work-orders/{id}?document=52998224725`

Fala: rota publica nao usa JWT, mas exige documento do cliente.

## Como falar sobre escalabilidade sem complicar

Fala curta:

> A aplicacao esta stateless e usa PostgreSQL fora do container da API. Por isso o Kubernetes pode subir multiplas replicas da API. O `HorizontalPodAutoscaler` esta configurado para variar de 1 a 5 replicas conforme CPU e memoria. Em demo local, eu posso mostrar o manifesto ou escalar manualmente para 3 replicas; em ambiente com metrics-server e carga real, o HPA faria isso automaticamente.

Comandos opcionais se houver cluster kind ativo:

```powershell
kubectl -n oficina get hpa
kubectl -n oficina get pods
kubectl -n oficina scale deploy/oficina-api --replicas=3
kubectl -n oficina get pods
kubectl -n oficina scale deploy/oficina-api --replicas=1
```

## O que nao precisa mostrar

- Nao precisa rodar scan de vulnerabilidade ao vivo.
- Nao precisa aplicar Terraform ao vivo se isso demorar.
- Nao precisa demonstrar todos os CRUDs.
- Nao precisa explicar todo DDD; cite apenas que o agregado `WorkOrder` concentra regras de OS.

## Fechamento sugerido

> A entrega atende o pedido com API funcionando, deploy local por Docker Compose, deploy Kubernetes reproduzivel por GitHub Actions com kind, CI/CD com build/test/cobertura, consumo das APIs pelo Swagger e HPA configurado para escalabilidade automatica.
