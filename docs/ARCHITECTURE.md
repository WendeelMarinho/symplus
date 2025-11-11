# Arquitetura do Sistema

## Visão Geral

Symplus Finance é uma plataforma de gestão financeira multi-tenant construída com arquitetura moderna e escalável.

## Arquitetura Backend

### Stack Tecnológica

- **Framework**: Laravel 11 (PHP 8.3)
- **Banco de Dados**: MySQL (produção) / SQLite (testes)
- **Cache/Filas**: Redis
- **Armazenamento**: S3/MinIO
- **Autenticação**: Laravel Sanctum (JWT)
- **Filas**: Laravel Horizon + Redis
- **Billing**: Stripe SDK

### Multi-Tenancy

O sistema implementa multi-tenancy usando **shared database com tenant isolation**:

1. **TenantScope**: Scope global que filtra todas as queries por `organization_id`
2. **HasTenant Trait**: Automatiza a aplicação do scope e set do `organization_id`
3. **EnsureTenantIsSet Middleware**: Valida e garante que o header `X-Organization-Id` está presente

```php
// Middleware valida acesso do usuário à organização
Route::middleware(['auth:sanctum', 'tenant'])->group(function () {
    // Todas as rotas aqui são isoladas por tenant
});
```

### Estrutura de Camadas

```
Controllers (API)
    ↓
Requests (Validation)
    ↓
Resources (Transformation)
    ↓
Models (Business Logic)
    ↓
Database
```

### Padrões de Design

- **Repository Pattern**: Implícito através dos Models Eloquent
- **Resource Pattern**: API Resources para transformação de dados
- **Factory Pattern**: Para criação de entidades de teste
- **Observer Pattern**: Events e Listeners para ações side-effect
- **Strategy Pattern**: Diferentes estratégias de agrupamento em relatórios

## Autenticação e Autorização

### Fluxo de Autenticação

1. Usuário faz login em `/api/auth/login`
2. Sistema retorna token JWT (Sanctum)
3. Cliente inclui token no header `Authorization: Bearer {token}`
4. Cliente inclui `X-Organization-Id` para identificar tenant

### Autorização

- **Roles**: `owner`, `admin`, `member` (definido em `organization_user` pivot)
- **Middleware**: `EnsureTenantIsSet` valida acesso à organização
- **Plan Limits**: Middleware `CheckPlanLimit` verifica limites do plano

## Banco de Dados

### Modelo de Dados

#### Core
- `users` - Usuários do sistema
- `organizations` - Empresas/Organizações (tenants)
- `organization_user` - Relação many-to-many com roles

#### Financeiro
- `accounts` - Contas bancárias
- `categories` - Categorias (income/expense)
- `transactions` - Transações financeiras
- `due_items` - Vencimentos (pagamentos/recebimentos)

#### Operacional
- `documents` - Documentos (polimórfico)
- `service_requests` - Tickets/Solicitações
- `service_request_comments` - Comentários em tickets
- `notifications` - Notificações do sistema

#### Billing
- `subscriptions` - Assinaturas
- `plan_limits` - Limites por plano

### Isolamento de Dados

Todas as tabelas multi-tenant possuem:
- `organization_id` com foreign key
- Index composto para performance
- TenantScope aplicado automaticamente

## Filas e Jobs

### Sistema de Filas

- **Driver**: Redis
- **Monitoramento**: Laravel Horizon
- **Queue dedicada**: `notifications` para notificações

### Jobs

- `SendDueItemReminderJob` - Envia lembretes de vencimentos
- Futuras: Jobs para processamento assíncrono, emails, etc.

## Armazenamento de Arquivos

### Configuração

- **Local**: Para desenvolvimento
- **S3/MinIO**: Para produção e staging
- **Polimórfico**: Documents podem ser associados a qualquer modelo

### Segurança

- Arquivos privados por padrão
- URLs temporárias com expiração
- Validação de tipo e tamanho

## Relatórios

### P&L (Profit & Loss)

- Agrupamento por categoria ou mês
- Filtros por período
- Cálculo de totais (receitas, despesas, saldo)
- Isolado por tenant

### Dashboard

Endpoint agregado que retorna:
- Resumo financeiro
- Transações recentes
- Due items (próximos e vencidos)
- Balances de contas
- Receitas/Despesas mensais
- Top categorias
- Projeção de fluxo de caixa

## Billing e Assinaturas

### Integração Stripe

- Webhooks para eventos de assinatura
- Sincronização de status
- Limites por plano aplicados via middleware

### Planos

```php
free       → Limites básicos
basic      → Limites intermediários
premium    → Limites avançados
enterprise → Ilimitado
```

### Middleware de Limites

`CheckPlanLimit` middleware verifica limites antes de processar requests:
- Contagem de recursos existentes
- Comparação com limites do plano
- Retorna 403 se exceder limite

## Testes

### Estrutura

- **Feature Tests**: Testam rotas completas da API
- **Unit Tests**: Testam lógica isolada
- **Factories**: Criam dados de teste consistentes

### Coverage

Alvo de cobertura: **70%+**

### CI/CD

- GitHub Actions executa testes em cada push
- PHPStan para análise estática
- Pint para formatação de código

## Mobile App (Flutter)

### Arquitetura

- **State Management**: Riverpod
- **Navigation**: GoRouter
- **HTTP**: Dio com interceptors
- **Storage**: Secure Storage para tokens

### Estrutura

```
lib/
├── features/        # Features isoladas
│   ├── auth/
│   └── dashboard/
├── core/           # Serviços compartilhados
│   ├── network/
│   └── storage/
└── config/         # Configurações
```

## Segurança

### Práticas Implementadas

1. **JWT Authentication**: Tokens seguros com expiração
2. **Tenant Isolation**: Isolamento completo de dados
3. **Input Validation**: Validação em todas as rotas
4. **SQL Injection**: Protegido pelo Eloquent ORM
5. **XSS**: Sanitização de inputs
6. **CSRF**: Não aplicável em APIs stateless
7. **Rate Limiting**: Configurável via Laravel

## Performance

### Otimizações

- **Eager Loading**: Para evitar N+1 queries
- **Indexes**: Em colunas frequentemente consultadas
- **Cache**: Redis para dados frequentes
- **Queue**: Processamento assíncrono
- **Pagination**: Em todas as listagens

### Monitoramento

- **Laravel Horizon**: Monitoramento de filas
- **Logs**: Sistema de logs estruturado
- **Health Check**: Endpoint `/api/health`

## Escalabilidade

### Horizontal

- Stateless API permite múltiplas instâncias
- Redis compartilhado para cache/filas
- Database com replicação (preparado)

### Vertical

- Otimização de queries
- Cache de resultados
- Processamento assíncrono

## Deploy

### Ambiente

- Docker Compose para desenvolvimento
- Configuração preparada para produção
- Variáveis de ambiente para configuração

### Requisitos

- PHP 8.3+
- MySQL 8.0+
- Redis 7+
- MinIO ou S3

---

Para mais detalhes sobre componentes específicos, consulte:
- [API Documentation](backend/postman/README.md)
- [Testing Guide](backend/TESTING.md)
- [Contributing Guide](CONTRIBUTING.md)

