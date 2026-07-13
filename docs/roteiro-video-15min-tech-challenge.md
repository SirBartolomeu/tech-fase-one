# Roteiro de Video (ate 15 min) - Tech Challenge Fase 2

## Objetivo do video

Demonstrar que a Fase 2 evolui a entrega anterior com qualidade de codigo, arquitetura limpa, automacao de infraestrutura, Kubernetes, CI/CD, banco adequado para escala e APIs obrigatorias de OS.

## Estrategia recomendada

- Use Docker Compose como trilha principal se o Docker Desktop estiver ativo.
- Use execucao local como fallback se o Docker falhar durante a gravacao.
- Nao rode pipelines longos ao vivo; mostre os arquivos e resultados validados.
- Mostre Kubernetes/Terraform por manifests, Kustomize, `terraform plan` e workflows; nao precisa aplicar em cluster se o ambiente da gravacao nao estiver pronto.
- Priorize evidencias objetivas: README, diagramas, Swagger, testes, workflows e relatorio de vulnerabilidades.

## Pre-check antes de gravar

Executar na raiz do projeto:

```powershell
dotnet build .\OficinaMvp.sln --configuration Release --no-restore --maxcpucount:1
dotnet test .\OficinaMvp.sln --configuration Release --no-build --verbosity minimal --maxcpucount:1
docker compose config --quiet
kubectl kustomize .\k8s
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
terraform -chdir=infra/terraform plan
```

Se Docker estiver disponivel:

```powershell
docker info
docker compose down --remove-orphans
docker compose up -d --build
Invoke-WebRequest http://localhost:8080/health/ready
Invoke-WebRequest http://localhost:8080/swagger/v1/swagger.json
```

Abas recomendadas:

1. `README.md`
2. `CHANGELOG.md`
3. `docs/documentacao-ddd-tech-challenge.md`
4. `docs/diagramas/arquitetura-fase2-kubernetes.svg`
5. `docs/diagramas/event-storming-fase2-linha-do-tempo.svg`
6. `src/OficinaMvp.Api/Program.cs`
7. `src/OficinaMvp.Application/Services/WorkOrderApplicationService.cs`
8. `src/OficinaMvp.Domain/Entities/WorkOrder.cs`
9. `docker-compose.yml`
10. `k8s/deployment.yaml`, `k8s/hpa.yaml`, `k8s/secret.example.yaml`, `k8s/kustomization.yaml`
11. `infra/terraform/main.tf`
12. `.github/workflows/build-test.yml`, `.github/workflows/container.yml`, `.github/workflows/deploy-kind.yml`
13. Swagger: `http://localhost:8080/swagger` ou `http://localhost:5245/swagger`

## Roteiro minuto a minuto

| Tempo | O que mostrar | Fala objetiva |
|---|---|---|
| 00:00-01:00 | `README.md` | Explicar que a Fase 2 evolui a Fase 1 para escalabilidade, automacao, qualidade e Kubernetes. |
| 01:00-02:30 | `README.md` e `CHANGELOG.md` | Mostrar stack: .NET 8, Clean Architecture, JWT, EF Core, SQLite local/testes, PostgreSQL em Docker/K8s, Docker, Kubernetes, Terraform e GitHub Actions. |
| 02:30-04:00 | `docs/diagramas/arquitetura-fase2-kubernetes.svg` | Explicar os componentes: API, banco PostgreSQL, ConfigMap, Secret, HPA, probes, PVC, CI/CD e Terraform kind. |
| 04:00-05:15 | `docs/documentacao-ddd-tech-challenge.md` e Event Storming Fase 2 | Mostrar linguagem ubiqua, contextos, eventos pivotais, politicas e agregado `WorkOrder`. |
| 05:15-06:30 | `Program.cs`, `WorkOrderApplicationService.cs`, `WorkOrder.cs` | Mostrar DI, JWT, providers SQLite/Postgres, health checks, regras de dominio, transicoes e notificacao. |
| 06:30-08:00 | `docker-compose.yml` | Explicar API, PostgreSQL, Mailpit, porta `8080`, healthcheck, seed demo e porque PostgreSQL substitui SQLite no ambiente containerizado. |
| 08:00-09:30 | `k8s/` | Mostrar Deployment non-root, readiness/liveness, resources, HPA CPU/memoria, Secret template e ConfigMap. |
| 09:30-10:30 | `infra/terraform/main.tf` e `.github/workflows/` | Mostrar provisionamento kind, build/test, Docker build e deploy kind com smoke test. |
| 10:30-12:30 | Swagger | Gerar JWT, chamar endpoint protegido, criar OS, consultar status, usar decisao externa e tracking publico. |
| 12:30-13:30 | Terminal e testes | Mostrar `dotnet test` verde e cobertura minima de 80% via `scripts/validate-domain-coverage.ps1`. |
| 13:30-14:20 | `security-report/relatorio-vulnerabilidades.md` | Explicar SCA NuGet sem achados, Semgrep sem achados e Docker Scout com 1 CVE medium da imagem base sem fix disponivel. |
| 14:20-15:00 | README | Recapitular requisitos atendidos, collection Swagger/OpenAPI e proximos passos para publicar video/repo. |

## Comandos para demonstracao

### Docker Compose

```powershell
docker compose up -d --build
Invoke-WebRequest http://localhost:8080/health/ready
Invoke-WebRequest http://localhost:8080/swagger/v1/swagger.json
```

### Testes

```powershell
dotnet test .\OficinaMvp.sln --configuration Release --no-build --verbosity minimal --maxcpucount:1
```

### Kubernetes renderizado

```powershell
kubectl kustomize .\k8s
```

### Terraform

```powershell
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
terraform -chdir=infra/terraform plan
```

### Encerrar Docker

```powershell
docker compose down
```

### Fallback local

```powershell
dotnet run --project .\src\OficinaMvp.Api --launch-profile http
```

Swagger local: `http://localhost:5245/swagger`.

## Payloads para Swagger

### Auth - `POST /api/auth/token`

```json
{
  "username": "admin",
  "password": "Admin@123"
}
```

Use o retorno `accessToken` no Swagger em `Authorize` como `Bearer {token}`.

### Customer - `POST /api/customers`

```json
{
  "name": "Cliente Video Fase 2",
  "document": "52998224725",
  "phone": "(11) 99999-1111",
  "email": "cliente.video@oficina.local"
}
```

### Service - `POST /api/services`

```json
{
  "name": "Revisao Video Fase 2",
  "description": "Servico para demonstracao da Fase 2",
  "laborPrice": 180.0,
  "averageDurationMinutes": 60
}
```

### Part - `POST /api/parts`

```json
{
  "name": "Peca Video Fase 2",
  "unitPrice": 45.0,
  "stockQuantity": 15
}
```

### WorkOrder - `POST /api/work-orders`

Substituir `SERVICE_ID` e `PART_ID` pelos GUIDs retornados.

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
      "serviceId": "SERVICE_ID",
      "quantity": 1
    }
  ],
  "parts": [
    {
      "partId": "PART_ID",
      "quantity": 2
    }
  ],
  "notes": "OS criada durante video da Fase 2"
}
```

### Fluxo de status da OS

Use o `workOrderId` criado:

- `GET /api/work-orders/{id}/status`
- `POST /api/work-orders/{id}/start-diagnosis`
- `POST /api/work-orders/{id}/send-budget`
- `POST /api/work-orders/{id}/approve-budget`
- `POST /api/work-orders/{id}/finalize`
- `POST /api/work-orders/{id}/deliver`

### Decisao externa de orcamento

Endpoint:

```http
POST /api/integrations/work-orders/{id}/budget-decision
Header: X-Integration-Token: oficina-integration-token-local-123456
```

Body de aprovacao:

```json
{
  "approved": true,
  "reason": "Cliente aprovou por canal externo"
}
```

Body de recusa:

```json
{
  "approved": false,
  "reason": "Cliente pediu revisao do orcamento"
}
```

### Tracking publico

```http
GET /api/client/work-orders/{id}?document=52998224725
```

## Pontos essenciais para comentar

- A Fase 2 nao reescreveu a solucao; ela evoluiu a base da Fase 1.
- Clean Architecture separa dominio, casos de uso, infraestrutura e API.
- SQLite fica para local simples/testes; PostgreSQL e usado em Docker/Kubernetes por ser mais adequado a escala horizontal.
- JWT protege rotas administrativas; tracking publico segue aberto por OS + documento.
- `X-Integration-Token` separa integracao externa do login administrativo.
- `WorkOrder` concentra invariantes de status, historico e transicoes.
- HPA depende de metrics-server no cluster.
- Secrets reais nao sao versionados; `secret.example.yaml` e template.
- O relatorio de vulnerabilidades foi validado com SCA NuGet, Semgrep e Docker Scout; se reexecutar ao vivo, confirme Docker Desktop ativo e login realizado.

## Plano B

- Se Docker falhar, use `dotnet run` e apresente Swagger local em `http://localhost:5245/swagger`.
- Se nao houver cluster Kubernetes, mostre `kubectl kustomize .\k8s` e explique os manifests.
- Se nao houver Terraform instalado no ambiente de gravacao, mostre `infra/terraform/main.tf`, `.terraform.lock.hcl` e o workflow `deploy-kind`.
- Se o tempo apertar, priorize README, arquitetura, Swagger, testes e CI/CD.
