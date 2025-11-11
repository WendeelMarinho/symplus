# Database Seeders

Este diretório contém os seeders para popular o banco de dados.

## Seeders Disponíveis

### DatabaseSeeder

Seeder básico que cria:
- Limites de planos (via `PlanLimitSeeder`)
- Uma organização de desenvolvimento
- Um usuário administrador
- Uma assinatura gratuita

**Uso:**
```bash
make seed
# ou
docker compose exec php php artisan db:seed
```

**Credenciais criadas:**
- Email: `admin@symplus.dev`
- Password: `password`

### RealisticDataSeeder

Seeder completo com dados realistas para desenvolvimento e testes:

- **2 organizações** com diferentes planos (free e basic)
- **2-3 usuários** por organização
- **12 categorias** (4 receitas, 8 despesas)
- **3 contas** (Conta Corrente, Poupança, Cartão de Crédito)
- **Transações dos últimos 12 meses** (15-30 transações por mês)
- **10 due items** (pagamentos e recebimentos)
- **8 service requests** com comentários
- **Notificações** para cada usuário

**Uso:**
```bash
make seed-realistic
# ou
docker compose exec php php artisan db:seed --class=RealisticDataSeeder
```

**Credenciais criadas:**

**Organização 1 - Symplus Dev (Free plan):**
- Email: `admin@symplus.dev` / Password: `password` (owner)

**Organização 2 - Demo Company (Basic plan):**
- Email: `demo@example.com` / Password: `password` (owner)
- Email: `team@example.com` / Password: `password` (admin)

## Estrutura dos Dados

### Categorias

**Receitas:**
- Salário
- Freelance
- Investimentos
- Vendas

**Despesas:**
- Alimentação
- Transporte
- Moradia
- Saúde
- Educação
- Lazer
- Compras
- Contas

### Contas

- Conta Corrente (Saldo inicial: R$ 5.000,00)
- Conta Poupança (Saldo inicial: R$ 15.000,00)
- Cartão de Crédito (Saldo inicial: -R$ 2.500,00)

### Transações

- Distribuídas ao longo dos últimos 12 meses
- Receita mensal no dia 5 de cada mês
- 15-30 despesas variadas por mês
- Valores realistas baseados na categoria

### Due Items

- Mix de pagamentos e recebimentos
- Datas variadas (passadas e futuras)
- Alguns marcados como pagos
- Status: pending, paid, overdue

### Service Requests

- Diversos títulos e descrições
- Prioridades variadas (low, medium, high)
- Status variados (open, in_progress, resolved, closed)
- Comentários associados

## Limpar e Recriar

Para limpar o banco e recriar com dados realistas:

```bash
make migrate
make seed-realistic
```

Ou reset completo:

```bash
docker compose exec php php artisan migrate:fresh --seed --class=RealisticDataSeeder
```

