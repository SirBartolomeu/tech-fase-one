# Roteiro de Video (15 min) - Tech Challenge Oficina MVP

## Objetivo do video
Demonstrar, em 15 minutos, que a entrega atende o desafio com foco em:
- DDD e coerencia de dominio
- API com JWT funcionando
- qualidade com testes
- seguranca com relatorio de vulnerabilidades

## Estrategia de demonstracao
- Trilha principal: Docker Compose (reprodutivel para banca)
- Trilha final curta: smoke local sem Docker
- Evitar pipelines longos ao vivo
- Priorizar Swagger + leitura rapida de codigo e documentos

## Pre-check (fazer antes de iniciar a gravacao)
Na raiz do repositorio `oficina-mvp`:

```powershell
docker info
docker compose down --remove-orphans
dotnet --version
```

Abas que devem ficar abertas:
1. `README.md`
2. `docs/documentacao-ddd-tech-challenge.md`
3. `docs/diagramas/domain-storytelling-oficina-mvp.svg`
4. `docs/diagramas/event-storming-oficina-mvp.svg`
5. Swagger (`http://localhost:8080/swagger`) quando subir o Compose
6. Arquivos de codigo-chave:
   - `src/OficinaMvp.Api/Program.cs`
   - `src/OficinaMvp.Api/Domain/Entities/WorkOrder.cs`
   - `src/OficinaMvp.Api/Application/Services/WorkOrderApplicationService.cs`

## Roteiro minuto a minuto (15:00)

| Tempo | O que mostrar | O que comentar |
|---|---|---|
| 00:00-01:00 | `README.md` | Contexto do desafio, stack (`.NET 8`, `SQLite`, Docker, xUnit) e objetivo do MVP. |
| 01:00-02:30 | `docs/documentacao-ddd-tech-challenge.md` | Arquitetura em camadas: Domain, Application, Infrastructure, API. |
| 02:30-03:30 | `domain-storytelling-oficina-mvp.svg` | Narrativa: cliente -> atendimento -> OS -> status -> entrega. |
| 03:30-04:30 | `event-storming-oficina-mvp.svg` | Comandos, eventos e politicas (validacao, estoque, transicoes). |
| 04:30-06:00 | Terminal + `docker-compose.yml` + Swagger | `docker compose up -d --build`, mostrar porta `8080` e volume `/data/oficina.db`. |
| 06:00-08:00 | Swagger (Auth + Customers) | Gerar token em `POST /api/auth/token`, aplicar `Bearer`, chamar `/api/customers`. |
| 08:00-10:30 | Swagger (fluxo OS) | Criar cliente/servico/peca/OS, fazer transicoes ate `Delivered`, consultar tracking publico. |
| 10:30-12:00 | `Program.cs`, `WorkOrder.cs`, `WorkOrderApplicationService.cs` | Mostrar JWT + `EnsureCreated` + seed + regras de transicao e estoque. |
| 12:00-13:15 | Testes | Mostrar arquivos de teste e rodar `dotnet test .\OficinaMvp.sln --verbosity minimal -m:1`. |
| 13:15-14:15 | `security-report/relatorio-vulnerabilidades.md` | Explicar SCA + SAST + imagem e priorizacao por severidade. |
| 14:15-15:00 | Terminal | Recapitular requisitos atendidos e finalizar com `docker compose down`. |

## Comandos que voce vai executar no video

### 1) Subida principal (Docker)
```powershell
docker compose up -d --build
```

### 2) Testes (1 unica execucao)
```powershell
dotnet test .\OficinaMvp.sln --verbosity minimal -m:1
```

### 3) Encerramento Docker
```powershell
docker compose down
```

### 4) Fallback local rapido (se Docker falhar)
```powershell
dotnet run --project .\src\OficinaMvp.Api --launch-profile http
```

## Payloads prontos para Swagger

### Auth - `POST /api/auth/token`
```json
{
  "username": "admin",
  "password": "Admin@123"
}
```

### Customer - `POST /api/customers`
```json
{
  "name": "Cliente Video",
  "document": "52998224725",
  "phone": "(11) 99999-1111",
  "email": "cliente.video@oficina.local"
}
```

### Service - `POST /api/services`
```json
{
  "name": "Revisao Video",
  "description": "Servico para demonstracao",
  "laborPrice": 180.0,
  "averageDurationMinutes": 60
}
```

### Part - `POST /api/parts`
```json
{
  "name": "Peca Video",
  "unitPrice": 45.0,
  "stockQuantity": 15
}
```

### WorkOrder - `POST /api/work-orders`
Substituir `SERVICE_ID` e `PART_ID` pelos GUIDs retornados na criacao.

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
  "notes": "OS criada durante video de apresentacao"
}
```

### Transicoes da OS
Use o `workOrderId` criado:
- `POST /api/work-orders/{id}/start-diagnosis`
- `POST /api/work-orders/{id}/send-budget`
- `POST /api/work-orders/{id}/approve-budget`
- `POST /api/work-orders/{id}/finalize`
- `POST /api/work-orders/{id}/deliver`

### Tracking publico
```http
GET /api/client/work-orders/{id}?document=52998224725
```

## Pontos obrigatorios para comentar (sem falhar)
1. Motivo do SQLite no MVP e persistencia em arquivo/volume.
2. Diferenca entre `AdminCredentials` (login) e `Jwt` (assinatura/validacao de token).
3. Regras de dominio: transicoes validas de status e controle de estoque.
4. Evidencia de qualidade: testes automatizados e cobertura minima em dominios criticos.
5. Evidencia de seguranca: relatorio consolidado de vulnerabilidades e priorizacao de correcao.

## Plano B (se algo der errado durante a gravacao)
1. Se Docker falhar, usar fallback local (`dotnet run ...`) e seguir no Swagger local (`http://localhost:5245/swagger`).
2. Se nao houver tempo para rodar testes ao vivo, mostrar a ultima execucao verde no terminal e abrir os arquivos de teste.
3. Se algum endpoint falhar por token expirado, gerar novo token rapidamente em `POST /api/auth/token`.
4. Se faltar tempo no fim, priorizar fechamento com requisitos atendidos + links dos documentos e diagramas.
