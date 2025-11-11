# Documentação da API

## Base URL

```
http://localhost:8000/api
```

## Autenticação

Todas as rotas protegidas requerem autenticação via **Bearer Token**.

### Headers Obrigatórios

```
Authorization: Bearer {token}
X-Organization-Id: {organization_id}
```

### Obter Token

**Endpoint**: `POST /api/auth/login`

**Request:**
```json
{
  "email": "admin@symplus.dev",
  "password": "password"
}
```

**Response:**
```json
{
  "token": "1|abc123...",
  "user": {
    "id": 1,
    "name": "Admin User",
    "email": "admin@symplus.dev",
    "organizations": [...]
  }
}
```

## Recursos

### Accounts

Gerenciamento de contas bancárias.

#### Listar Contas
```
GET /api/accounts
```

#### Criar Conta
```
POST /api/accounts
Content-Type: application/json

{
  "name": "Conta Corrente",
  "currency": "BRL",
  "opening_balance": 5000.00
}
```

#### Obter Conta
```
GET /api/accounts/{id}
```

#### Atualizar Conta
```
PUT /api/accounts/{id}
```

#### Deletar Conta
```
DELETE /api/accounts/{id}
```

### Categories

Gerenciamento de categorias de receitas e despesas.

#### Listar Categorias
```
GET /api/categories?type=expense
```

**Query Parameters:**
- `type`: `income` ou `expense` (opcional)

#### Criar Categoria
```
POST /api/categories

{
  "type": "expense",
  "name": "Transporte",
  "color": "#ef4444"
}
```

### Transactions

Gerenciamento de transações financeiras.

#### Listar Transações
```
GET /api/transactions?type=expense&from=2024-01-01&to=2024-12-31&page=1
```

**Query Parameters:**
- `type`: `income` ou `expense`
- `account_id`: Filtrar por conta
- `category_id`: Filtrar por categoria
- `from`: Data inicial (YYYY-MM-DD)
- `to`: Data final (YYYY-MM-DD)
- `page`: Número da página

#### Criar Transação
```
POST /api/transactions

{
  "account_id": 1,
  "category_id": 1,
  "type": "expense",
  "amount": 150.50,
  "occurred_at": "2024-10-15T10:30:00Z",
  "description": "Compra no supermercado"
}
```

### Due Items

Gerenciamento de vencimentos (pagamentos e recebimentos).

#### Listar Due Items
```
GET /api/due-items?status=pending&type=pay
```

**Query Parameters:**
- `status`: `pending`, `paid`, `overdue`
- `type`: `pay` ou `receive`
- `from`: Data inicial
- `to`: Data final

#### Criar Due Item
```
POST /api/due-items

{
  "title": "Pagamento fornecedor",
  "amount": 2500.00,
  "due_date": "2024-11-15",
  "type": "pay",
  "description": "Pagamento mensal"
}
```

#### Marcar como Pago
```
POST /api/due-items/{id}/mark-paid
```

### Documents

Gerenciamento de documentos.

#### Listar Documentos
```
GET /api/documents?category=invoice
```

#### Upload Documento
```
POST /api/documents
Content-Type: multipart/form-data

file: [arquivo]
name: "Invoice October 2024"
category: "invoice"
description: "Monthly invoice"
```

#### Download Documento
```
GET /api/documents/{id}/download
```

#### Obter URL Temporária
```
GET /api/documents/{id}/url
```

### Service Requests

Sistema de tickets/solicitações.

#### Listar Service Requests
```
GET /api/service-requests?status=open&priority=high
```

#### Criar Service Request
```
POST /api/service-requests

{
  "title": "Bug no relatório",
  "description": "O relatório está com valores incorretos",
  "category": "bug",
  "priority": "high",
  "assigned_to": 1
}
```

#### Adicionar Comentário
```
POST /api/service-requests/{id}/comments

{
  "comment": "Investigando o problema",
  "is_internal": false
}
```

#### Marcar como Resolvido
```
POST /api/service-requests/{id}/mark-resolved
```

### Notifications

Gerenciamento de notificações.

#### Listar Notificações
```
GET /api/notifications?read=false
```

#### Contador de Não Lidas
```
GET /api/notifications/unread-count
```

#### Marcar como Lida
```
POST /api/notifications/{id}/mark-as-read
```

#### Marcar Todas como Lidas
```
POST /api/notifications/mark-all-as-read
```

### Reports

Relatórios financeiros.

#### P&L Report
```
GET /api/reports/pl?from=2024-01-01&to=2024-12-31&group_by=category
```

**Query Parameters:**
- `from`: Data inicial (obrigatório)
- `to`: Data final (obrigatório)
- `group_by`: `category` ou `month` (opcional)

**Response:**
```json
{
  "data": {
    "total_income": 50000.00,
    "total_expenses": 35000.00,
    "net": 15000.00,
    "grouped": [...]
  }
}
```

### Dashboard

Dashboard agregado com resumo financeiro.

```
GET /api/dashboard
```

**Response:**
```json
{
  "data": {
    "financial_summary": {
      "current_month_income": 5000.00,
      "current_month_expenses": 3500.00,
      "net": 1500.00
    },
    "recent_transactions": [...],
    "upcoming_due_items": [...],
    "overdue_items": [...],
    "account_balances": [...],
    "monthly_income_expense": [...],
    "top_categories": {
      "income": [...],
      "expenses": [...]
    },
    "cash_flow_projection": [...]
  }
}
```

### Subscription

Gerenciamento de assinatura.

#### Obter Assinatura
```
GET /api/subscription
```

#### Atualizar Assinatura
```
PUT /api/subscription

{
  "plan": "basic"
}
```

#### Cancelar Assinatura
```
POST /api/subscription/cancel
```

## Códigos de Status

- `200` - Sucesso
- `201` - Criado com sucesso
- `400` - Requisição inválida
- `401` - Não autenticado
- `403` - Proibido (sem permissão ou limite excedido)
- `404` - Não encontrado
- `422` - Erro de validação
- `500` - Erro interno do servidor

## Erros

### Formato de Erro

```json
{
  "message": "Mensagem de erro",
  "errors": {
    "campo": ["Mensagem de validação"]
  }
}
```

### Erros Comuns

#### 401 Unauthorized
Token inválido ou expirado. Faça login novamente.

#### 403 Forbidden
- Limite do plano excedido
- Sem permissão para acessar o recurso

#### 422 Unprocessable Entity
Erro de validação. Verifique os campos no objeto `errors`.

## Paginação

Endpoints de listagem retornam dados paginados:

```json
{
  "data": [...],
  "links": {
    "first": "...",
    "last": "...",
    "prev": null,
    "next": "..."
  },
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 10,
    "per_page": 15,
    "to": 15,
    "total": 150
  }
}
```

## Collection Postman

Uma collection completa do Postman está disponível em:
- `backend/postman/Symplus_API.postman_collection.json`

Importe no Postman para testar todos os endpoints com exemplos prontos.

## Rate Limiting

Por padrão, a API permite **60 requisições por minuto** por IP. Em produção, ajuste conforme necessário no arquivo de configuração do Laravel.

## Webhooks

### Stripe Webhook

```
POST /api/webhooks/stripe
```

Endpoint público (protegido por assinatura do Stripe) para receber eventos de assinatura.

---

Para exemplos práticos, consulte a collection do Postman em `backend/postman/`.

