# Roteiro curto de video - Tech Challenge Fase 2

Objetivo: demonstrar em poucos minutos o minimo exigido pela Fase 2: deploy da aplicacao, execucao do CI/CD, consumo das APIs e escalabilidade no Kubernetes.

## Ideia central

A entrega nao usa cloud. O deploy demonstravel acontece em um cluster Kubernetes efemero criado com `kind` dentro do GitHub Actions.

Fluxo principal para o video:

- Mostrar os arquivos principais de infraestrutura e CI/CD.
- Mostrar os checks `build-test` e `container` executados.
- Disparar manualmente o workflow `deploy-kind`.
- Usar os logs do `deploy-kind` como evidencia de deploy, consumo das APIs e escalabilidade.

Docker Compose local fica opcional, apenas para abrir o Swagger visualmente se quiser demonstrar JWT com clique.

## O que o workflow `deploy-kind` prova

No console do GitHub Actions, o workflow executa:

- Terraform cria o cluster local `kind` no runner.
- Docker build gera a imagem `oficina-mvp-api:local`.
- A imagem e importada no containerd do cluster `kind`.
- Secrets efemeros de demo sao criados no Kubernetes.
- `kubectl apply -k ./k8s` publica API, PostgreSQL, Service, PVC e HPA.
- Rollout aguarda PostgreSQL e API ficarem prontos.
- Smoke test consome APIs reais:
  - `GET /health/ready`.
  - `GET /swagger/v1/swagger.json`.
  - `POST /api/auth/token`.
  - `GET /api/customers` com Bearer token.
  - `GET /api/services` e `GET /api/parts`.
  - `POST /api/work-orders` usando seed demo.
  - `GET /api/work-orders/{id}/status`.
  - `GET /api/client/work-orders/{id}?document=52998224725`.
- Evidencia de escalabilidade:
  - exibe HPA;
  - instala metrics-server no cluster efemero;
  - reduz temporariamente o alvo de CPU apenas para demo;
  - gera carga contra a API;
  - tenta mostrar o HPA aumentando replicas automaticamente;
  - se o ambiente nao estabilizar metricas, usa fallback manual;
  - exibe deployment e pods;
  - escala manualmente a API para 3 replicas;
  - volta para 1 replica.

## Roteiro sugerido, 6 a 8 minutos

| Tempo | Mostrar | O que falar |
|---|---|---|
| 00:00-00:40 | `README.md` e `CHANGELOG.md` | Esta e a evolucao da Fase 1 para Fase 2: Clean Architecture, Docker, Kubernetes, Terraform, CI/CD, testes e seguranca. |
| 00:40-01:30 | GitHub Actions: `build-test` e `container` | `build-test` roda restore, build, testes e cobertura minima. `container` valida o build da imagem Docker. |
| 01:30-02:20 | `.github/workflows/deploy-kind.yml` | Explicar que este workflow e a trilha principal da demo: cria cluster kind, faz deploy, consome APIs e demonstra escala. |
| 02:20-03:10 | `k8s/deployment.yaml` e `k8s/hpa.yaml` | Mostrar probes, resources, usuario non-root, Service e HPA de 1 a 5 replicas. |
| 03:10-05:40 | GitHub Actions: executar/abrir `deploy-kind` | Mostrar logs: `Terraform apply`, `Deploy manifests`, `API smoke test`, `Automatic HPA autoscaling evidence` e `Manual horizontal scaling fallback`. |
| 05:40-06:40 | Swagger local opcional | Se quiser, abrir `http://localhost:8080/swagger` via Docker Compose e demonstrar JWT visualmente. |
| 06:40-07:30 | Testes e seguranca | Mostrar cobertura >= 80% e relatorio de vulnerabilidades atualizado. |
| 07:30-08:00 | Fechamento | Recapitular: deploy funcionando, CI/CD executando, APIs respondendo e Kubernetes/HPA configurado. |

## Como disparar o deploy no GitHub

No GitHub:

1. Abra `Actions`.
2. Selecione `deploy-kind`.
3. Clique em `Run workflow`.
4. Aguarde concluir.
5. Abra os logs das etapas:
   - `Terraform apply`.
   - `Deploy manifests`.
   - `API smoke test`.
   - `Automatic HPA autoscaling evidence`.
   - `Manual horizontal scaling fallback`.

Frase curta para explicar:

> Como nao ha cloud no projeto, o deploy acontece em um cluster Kubernetes temporario criado pelo proprio GitHub Actions com kind. Isso prova o fluxo de deploy e validacao sem depender de uma conta AWS, Azure ou GCP.

## Docker Compose local opcional

Use apenas se quiser abrir o Swagger visualmente:

```powershell
docker compose down --remove-orphans
docker compose up -d --build
Invoke-WebRequest http://localhost:8080/health/ready
Invoke-WebRequest http://localhost:8080/swagger/v1/swagger.json
```

Swagger:

```text
http://localhost:8080/swagger
```

Credenciais JWT de demo:

```json
{
  "username": "admin",
  "password": "Admin@123"
}
```

Ao terminar:

```powershell
docker compose down
```

## Script local de fallback

Se o GitHub Actions estiver lento ou indisponivel durante a gravacao, use o script local:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\demo-kubernetes-local.ps1
```

Ele executa localmente o equivalente da parte Kubernetes:

- valida Docker, Terraform, kubectl e kind;
- cria/usa o cluster `oficina-local`;
- builda e carrega a imagem;
- cria secrets locais;
- aplica os manifests;
- valida health e Swagger;
- mostra HPA;
- escala a API para 3 replicas e volta para 1.

## Fala curta sobre escalabilidade

Se o step automatico escalar:

> A API e stateless e usa PostgreSQL fora do container da aplicacao. O workflow instala metrics-server no cluster kind, reduz temporariamente o alvo de CPU apenas para demonstracao e cria carga contra a API. Sem usar `kubectl scale`, o HPA observa as metricas e aumenta automaticamente as replicas. O manifesto real continua conservador, com CPU 70% e memoria 75%.

Se o step automatico nao escalar no tempo limite:

> O HPA esta configurado e o workflow tentou demonstrar autoscaling real com metrics-server e carga. Como o GitHub Actions usa um cluster efemero, as metricas podem nao estabilizar a tempo. Por isso o workflow mantem um fallback manual, que comprova que a API suporta multiplas replicas, mas eu nao vendo esse fallback como autoscaling automatico.

## O que nao precisa mostrar

- Nao precisa rodar scan de vulnerabilidade ao vivo.
- Nao precisa demonstrar todos os CRUDs.
- Nao precisa explicar todo DDD; cite apenas que o agregado `WorkOrder` concentra as regras de OS.
- Nao precisa usar cloud, porque o deploy Kubernetes efemero no GitHub Actions atende a demonstracao academica da entrega.
