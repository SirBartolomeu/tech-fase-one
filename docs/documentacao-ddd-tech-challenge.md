# Documentacao DDD - Tech Challenge Fase 1

Este documento consolida a documentacao pedida no desafio com foco em:

- Domain Storytelling dos fluxos principais
- Event Storming dos fluxos de criacao/acompanhamento da OS e gestao de pecas/insumos
- Linguagem ubiqua e regras de dominio

Base de referencia: codigo da aplicacao em `src/OficinaMvp.Api`.

## 1) Escopo e contexto

O MVP implementa um sistema integrado de oficina com os seguintes blocos:

- Gestao administrativa autenticada (JWT):
  - CRUD de clientes, veiculos, servicos, pecas/insumos
  - criacao e transicao de ordem de servico (OS)
- Consulta publica do cliente:
  - acompanhamento da OS por `id` + `document`
- Dominio central:
  - entidade/agregado principal `WorkOrder`
  - suporte por `Customer`, `Vehicle`, `RepairService`, `PartSupply`

## 2) Linguagem ubiqua aplicada

| Termo | Significado no dominio | Evidencia no codigo |
|---|---|---|
| Ordem de Servico (OS) | Registro de atendimento com servicos/pecas, status e historico | `Domain/Entities/WorkOrder.cs` |
| Cliente | Pessoa fisica/juridica identificada por CPF/CNPJ | `Domain/Entities/Customer.cs` |
| Veiculo | Veiculo vinculado a cliente e identificado por placa | `Domain/Entities/Vehicle.cs` |
| Servico | Item de mao de obra que compoe o orcamento | `Domain/Entities/RepairService.cs` |
| Peca/Insumo | Item de estoque consumido na OS | `Domain/Entities/PartSupply.cs` |
| Orcamento | Soma de servicos + pecas da OS | `WorkOrder.RecalculateTotals()` |
| Status da OS | Ciclo: Received -> InDiagnosis -> AwaitingApproval -> InExecution -> Finalized -> Delivered | `Domain/Entities/WorkOrderStatus.cs` |
| Historico de status | Registro temporal das transicoes de status | `Domain/Entities/WorkOrderStatusHistory.cs` |
| Acompanhamento do cliente | Consulta de status da OS por API publica | `Controllers/ClientTrackingController.cs` |

## 3) Domain Storytelling (visual)

Diagrama:

![Domain Storytelling](./diagramas/domain-storytelling-oficina-mvp.svg)

Narrativa principal derivada do codigo:

1. Cliente informa documento e dados do veiculo.
2. Atendente/Admin cria OS com servicos e pecas.
3. Sistema valida CPF/CNPJ e placa, localiza cliente e vincula/atualiza veiculo.
4. Sistema calcula orcamento automaticamente.
5. Sistema debita estoque das pecas na criacao da OS.
6. Sistema registra OS recebida e historico inicial.
7. Atendente executa transicoes operacionais (diagnostico, envio de orcamento, aprovacao, finalizacao, entrega).
8. Cliente acompanha status por API publica e valida documento.

## 4) Event Storming (visual)

Diagrama:

![Event Storming](./diagramas/event-storming-oficina-mvp.svg)

### 4.1 Comandos (API)

- `POST /api/work-orders` (criar OS)
- `POST /api/work-orders/{id}/start-diagnosis`
- `POST /api/work-orders/{id}/send-budget`
- `POST /api/work-orders/{id}/approve-budget`
- `POST /api/work-orders/{id}/finalize`
- `POST /api/work-orders/{id}/deliver`
- CRUD administrativos:
  - `/api/customers`
  - `/api/vehicles`
  - `/api/services`
  - `/api/parts`

### 4.2 Eventos de dominio observados

- OS criada
- Orcamento calculado
- Estoque atualizado (pecas debitadas)
- OS em diagnostico
- OS aguardando aprovacao
- OS em execucao
- OS finalizada
- OS entregue

### 4.3 Politicas/regras de negocio

- OS deve conter pelo menos um servico ou uma peca.
- Nao permite transicao de status fora da sequencia valida.
- Documento e placa devem ser validos.
- Placa nao pode pertencer a cliente diferente na criacao de OS.
- Estoque nao pode ficar negativo.
- Endpoints administrativos exigem autenticacao JWT.
- Tracking publico exige combinacao valida de `workOrderId` e `document`.

## 5) Bounded contexts praticos no monolito

Mesmo em monolito em camadas, o dominio aparece separado em subareas:

- Atendimento e Ordem de Servico
  - foco: lifecycle da OS e historico
  - principal: `WorkOrder`
- Cadastro e Catalogo
  - foco: clientes, veiculos, servicos
  - principais: `Customer`, `Vehicle`, `RepairService`
- Estoque
  - foco: pecas/insumos e saldo
  - principal: `PartSupply`
- Identidade e Acesso
  - foco: token JWT para area administrativa
  - principal: `AuthController` + `TokenService`

## 6) Matriz de aderencia ao desafio (DDD)

| Entregavel solicitado | Evidencia |
|---|---|
| Event Storming dos fluxos de criacao/acompanhamento da OS | `diagramas/event-storming-oficina-mvp.svg` |
| Event Storming da gestao de pecas e insumos | Mesmo diagrama com comandos/eventos/politicas de estoque |
| Diagramas da disciplina de DDD | Domain Storytelling + Event Storming visuais |
| Linguagem ubiqua aplicada | Secao 2 deste documento |
| Baseado na implementacao real | Secoes 2, 4 e referencias a classes/endpoints |

