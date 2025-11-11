# Symplus API - Postman Collection

Esta pasta contém a collection do Postman para testar a API do Symplus Finance.

## Como usar

### 1. Importar no Postman

1. Abra o Postman
2. Clique em **Import**
3. Selecione o arquivo `Symplus_API.postman_collection.json`
4. A collection será importada com todas as rotas organizadas

### 2. Configurar Variáveis

A collection usa variáveis para facilitar os testes:

- **`base_url`**: URL base da API (padrão: `http://localhost:8000`)
- **`token`**: Token de autenticação (será preenchido após login)
- **`organization_id`**: ID da organização (padrão: `1`)

Para configurar:

1. Clique na collection **Symplus Finance API**
2. Vá na aba **Variables**
3. Ajuste os valores conforme necessário

### 3. Fluxo de Autenticação

1. Execute a requisição **Auth > Login** com as credenciais:
   - Email: `admin@symplus.dev`
   - Password: `password`

2. Copie o `token` da resposta

3. Cole o token na variável `token` da collection:
   - Clique na collection
   - Aba **Variables**
   - Cole o token no campo `token`

4. Todas as outras requisições agora usarão este token automaticamente

### 4. Configurar Organization ID

Após fazer login, você receberá informações sobre o usuário e suas organizações. Use o ID da organização desejada:

1. Execute **Auth > Get Current User**
2. Veja o array `organizations` na resposta
3. Copie o `id` da organização desejada
4. Cole na variável `organization_id` da collection

## Estrutura da Collection

A collection está organizada em pastas:

- **Auth**: Autenticação (login, logout, dados do usuário)
- **Accounts**: Gerenciamento de contas
- **Categories**: Gerenciamento de categorias
- **Transactions**: Gerenciamento de transações
- **Due Items**: Gerenciamento de vencimentos
- **Documents**: Upload e download de documentos
- **Service Requests**: Sistema de tickets/solicitações
- **Notifications**: Gerenciamento de notificações
- **Reports**: Relatórios (P&L)
- **Dashboard**: Dashboard agregado
- **Subscription**: Gerenciamento de assinaturas

## Autenticação

Todas as rotas protegidas requerem:

- **Header `Authorization`**: `Bearer {token}`
- **Header `X-Organization-Id`**: ID da organização

Esses headers são configurados automaticamente nas requisições usando as variáveis da collection.

## Exemplos de Uso

### Criar uma transação

1. Execute **Transactions > Create Transaction**
2. Ajuste o JSON no body:
   ```json
   {
       "account_id": 1,
       "category_id": 1,
       "type": "expense",
       "amount": 150.50,
       "occurred_at": "2024-10-15T10:30:00Z",
       "description": "Compra no supermercado"
   }
   ```
3. Execute a requisição

### Filtrar transações

1. Execute **Transactions > List Transactions**
2. Use os query parameters na URL:
   - `type`: `income` ou `expense`
   - `from`: Data inicial (YYYY-MM-DD)
   - `to`: Data final (YYYY-MM-DD)
   - `page`: Número da página

### Upload de documento

1. Execute **Documents > Upload Document**
2. No body, selecione:
   - `file`: Selecione um arquivo
   - `name`: Nome do documento
   - `category`: Categoria (ex: `invoice`, `receipt`)
   - `description`: Descrição opcional

## Notas

- A collection inclui exemplos de requisições para todas as rotas principais
- Alguns endpoints requerem IDs de recursos existentes (substitua `:id` nas URLs)
- Use o seeder `RealisticDataSeeder` para criar dados de teste realistas

