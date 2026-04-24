# Oficina MVP - Tech Challenge Fase 1

API REST para gestao de oficina mecanica, implementada em `.NET 8` com `C#`, arquitetura em camadas inspirada em DDD, banco `SQLite`, autenticacao JWT, testes automatizados e execucao via Docker Compose.

## Objetivo do projeto

Entregar um MVP com:
- cadastro de clientes, veiculos, servicos e pecas
- abertura e ciclo de vida de ordens de servico
- controle de estoque de pecas
- autenticacao para endpoints administrativos
- acompanhamento de status da OS para o cliente

## Arquitetura da solucao

Monolito modular em camadas:

- `Domain`
  - Entidades centrais: `WorkOrder`, `Customer`, `Vehicle`, `PartSupply`, `RepairService`, `WorkOrderStatusHistory`
  - Regras de negocio e validacoes de dominio (`DocumentValidator`, `LicensePlateValidator`)

- `Application`
  - Orquestracao de casos de uso da OS via `WorkOrderApplicationService`
  - Contratos de entrada/saida (DTOs) em `Application/Contracts`

- `Infrastructure`
  - Persistencia com EF Core e `WorkshopDbContext`
  - Seguranca com JWT (`TokenService`, `JwtOptions`, `AdminCredentialsOptions`)

- `Presentation (API)`
  - Controllers REST (`WorkOrdersController`, `CustomersController`, `VehiclesController`, `PartsController`, `ServicesController`, `AuthController`, `ClientTrackingController`)
  - Middleware global de tratamento de excecoes (`ExceptionHandlingMiddleware`)
  - Swagger/OpenAPI para exploracao da API

## Estrutura de pastas

```text
oficina-mvp/
  src/OficinaMvp.Api/                  # API + dominio + aplicacao + infraestrutura
  tests/OficinaMvp.Domain.Tests/       # testes unitarios de dominio
  tests/OficinaMvp.Integration.Tests/  # testes de integracao da API
  docker-compose.yml
  README.md
```

## Tecnologias e bibliotecas

- Plataforma:
  - `.NET 8`
  - `ASP.NET Core Web API`
- Persistencia:
  - `Entity Framework Core 8`
  - `Microsoft.EntityFrameworkCore.Sqlite`
- Seguranca:
  - `Microsoft.AspNetCore.Authentication.JwtBearer`
- Documentacao de API:
  - `Swashbuckle.AspNetCore` (Swagger)
- Testes:
  - `xUnit`
  - `Microsoft.NET.Test.Sdk`
  - `Microsoft.AspNetCore.Mvc.Testing` (WebApplicationFactory)
  - `coverlet.collector` (cobertura)

## Banco de dados: por que SQLite

`SQLite` foi escolhido para o MVP porque:
- reduz custo de operacao e setup (arquivo local, sem servidor dedicado)
- acelera desenvolvimento e validacao funcional
- integra nativamente com EF Core
- facilita execucao local e em container

No projeto atual:
- ambiente local/compose usa arquivo SQLite (`Data Source=oficina.db` ou `/data/oficina.db`)
- testes de integracao usam SQLite em memoria (`Data Source=:memory:`) para isolamento e velocidade
- nao ha pasta de migrations; o schema e criado com `EnsureCreated()`

## Pre-requisitos

- `.NET SDK` compativel com `net8.0`
- Docker Desktop (para execucao com compose)

Instalacao do Docker Desktop (Windows):

```powershell
winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
```

Se `docker` nao for reconhecido apos instalar:
- abra nova sessao de terminal
- ou use o caminho absoluto:

```powershell
& "C:\Program Files\Docker\Docker\resources\bin\docker.exe" --version
```

## Como rodar localmente (sem Docker)

Na raiz `oficina-mvp`:

```powershell
dotnet restore .\OficinaMvp.sln --source https://api.nuget.org/v3/index.json
dotnet run --project .\src\OficinaMvp.Api
```

Endpoints:
- API: `http://localhost:5232`
- Swagger: `http://localhost:5232/swagger`

## Autenticacao

Credenciais administrativas padrao:
- usuario: `admin`
- senha: `Admin@123`

Gerar token:
- `POST /api/auth/token`

Uso no Swagger:
- `Bearer {token}`

## Como rodar no Docker Compose

Na raiz `oficina-mvp`:

```powershell
docker compose up -d --build
```

Caso `docker` nao esteja no PATH:

```powershell
& "C:\Program Files\Docker\Docker\resources\bin\docker.exe" compose up -d --build
```

Endpoints em container:
- API: `http://localhost:8080`
- Swagger: `http://localhost:8080/swagger`

Parar containers:

```powershell
docker compose down
```

## Testes automatizados

Execucao unica de todos os testes da solucao:

```powershell
dotnet test .\OficinaMvp.sln --verbosity minimal -m:1
```

Cobertura (opcional):

```powershell
dotnet test .\OficinaMvp.sln --collect:"XPlat Code Coverage" -m:1
```

## Observacoes de desempenho e gargalos

Diagnostico observado durante execucao:
- nao ha migrations em execucao
- nao ha criacao de banco por teste individual
- a criacao de schema ocorre via `EnsureCreated()` no startup e no setup da factory de integracao
- testes executados uma unica vez na solucao: `23` testes aprovados

Principais fontes de lentidao percebida:
- `restore`/auditoria de vulnerabilidades de pacotes em feeds inacessiveis (warnings `NU1900`)
- acumulacao de processos `dotnet` orfaos apos execucoes interrompidas
- ambiente Docker sem permissao de acesso ao pipe do daemon

## Troubleshooting rapido

Erro de permissao no Docker (`permission denied ... dockerDesktopLinuxEngine`):
- garantir usuario no grupo local `docker-users`
- fazer logoff/login apos ajustar grupo
- validar:

```powershell
docker info
docker compose version
```

Se houver muitos processos `dotnet` apos cancelamentos:

```powershell
Get-Process | Where-Object { $_.ProcessName -match 'dotnet|vstest|testhost|MSBuild' } | Stop-Process -Force
```
