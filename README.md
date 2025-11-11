# Symplus Finance

Uma plataforma completa de gestão financeira multi-empresa (multi-tenant) desenvolvida com Laravel 11 e Flutter.

## 🚀 Características

- **Multi-tenant**: Suporte a múltiplas organizações com isolamento completo de dados
- **Gestão Financeira**: Contas, categorias, transações e relatórios P&L
- **Vencimentos**: Controle de pagamentos e recebimentos com lembretes automáticos
- **Documentos**: Armazenamento seguro de documentos com S3/MinIO
- **Tickets**: Sistema de solicitações (service requests) com comentários e estágios
- **Notificações**: Sistema completo de notificações em tempo real
- **Billing**: Integração com Stripe para assinaturas e limites por plano
- **Dashboard**: Dashboard agregado com visão geral financeira e operacional
- **Mobile App**: Aplicativo Flutter para Android e iOS

## 📋 Tecnologias

### Backend
- **PHP 8.3** com Laravel 11
- **Laravel Sanctum** para autenticação JWT
- **Laravel Horizon** para monitoramento de filas
- **Redis** para cache e filas
- **MySQL** (produção) / SQLite (testes)
- **S3/MinIO** para armazenamento de arquivos
- **Stripe SDK** para billing
- **Docker Compose** para desenvolvimento

### Mobile
- **Flutter** com Dart
- **Riverpod** para gerenciamento de estado
- **GoRouter** para navegação
- **Dio** para requisições HTTP
- **Secure Storage** para dados sensíveis

### Qualidade
- **PHPUnit** para testes
- **PHPStan** para análise estática
- **Laravel Pint** para formatação de código
- **GitHub Actions** para CI/CD

## 📁 Estrutura do Projeto

```
symplus2/
├── backend/          # API Laravel 11
│   ├── app/
│   │   ├── Http/
│   │   │   ├── Controllers/Api/
│   │   │   ├── Middleware/
│   │   │   ├── Requests/
│   │   │   └── Resources/
│   │   ├── Models/
│   │   ├── Jobs/
│   │   ├── Scopes/
│   │   └── Traits/
│   ├── database/
│   │   ├── migrations/
│   │   ├── seeders/
│   │   └── factories/
│   ├── tests/
│   └── routes/
├── app/             # App Flutter
│   └── lib/
│       ├── features/
│       ├── core/
│       └── config/
└── docs/            # Documentação adicional
```

## 🛠️ Instalação e Configuração

### Pré-requisitos

- Docker e Docker Compose
- Make (opcional, mas recomendado)
- Flutter SDK (para desenvolvimento mobile)

### Backend

1. **Entre no diretório do backend:**
```bash
cd backend
```

2. **Configure as variáveis de ambiente:**
```bash
cp env.example .env
# Geralmente os valores padrão funcionam, mas verifique se necessário
```

3. **Inicie os containers Docker:**
```bash
make up
# ou
docker compose up -d
```

4. **Instale dependências do Composer:**
```bash
make install
```

5. **Gere a chave da aplicação (se necessário):**
```bash
docker compose exec php php artisan key:generate
```

6. **Execute as migrations:**
```bash
make migrate
```

7. **Popule o banco com dados realistas:**
```bash
make seed-realistic
```

8. **Verifique se está funcionando:**
```bash
curl http://localhost:8000/api/health
# Deve retornar: {"status":"ok","timestamp":"..."}
```

**✅ Backend rodando em: `http://localhost:8000`**

### Mobile App (Flutter)

1. **Entre no diretório do app:**
```bash
cd app
```

2. **Instale dependências:**
```bash
flutter pub get
```

3. **Configure a API** (se necessário):
   - Edite `lib/config/api_config.dart`
   - Para web/emulador: `http://localhost:8000` (já está configurado)
   - Para dispositivo físico Android: use seu IP local
   - Exemplo: `http://192.168.1.100:8000`

4. **Execute o app:**

   **Opção 1: Web (mais fácil para começar):**
   ```bash
   flutter run -d chrome
   ```

   **Opção 2: Android:**
   ```bash
   flutter run -d android
   # ou
   make app-run-android
   ```

   **Opção 3: iOS (apenas macOS):**
   ```bash
   flutter run -d ios
   # ou
   make app-run-ios
   ```

**⚠️ Nota:** O app não está configurado para Linux desktop. Use web, Android ou iOS.

## 📚 Documentação da API

A documentação completa da API está disponível na collection do Postman:

- **Collection**: `backend/postman/Symplus_API.postman_collection.json`
- **README**: `backend/postman/README.md`

### Autenticação

Todas as rotas protegidas requerem:

- **Header `Authorization`**: `Bearer {token}`
- **Header `X-Organization-Id`**: ID da organização

### Endpoints Principais

#### Autenticação
- `POST /api/auth/login` - Login e obtenção de token
- `GET /api/me` - Dados do usuário atual
- `POST /api/auth/logout` - Logout

#### Recursos Financeiros
- `GET|POST /api/accounts` - Listar/Criar contas
- `GET|POST /api/categories` - Listar/Criar categorias
- `GET|POST /api/transactions` - Listar/Criar transações

#### Vencimentos
- `GET|POST /api/due-items` - Listar/Criar vencimentos
- `POST /api/due-items/{id}/mark-paid` - Marcar como pago

#### Documentos
- `GET|POST /api/documents` - Listar/Upload de documentos
- `GET /api/documents/{id}/download` - Download
- `GET /api/documents/{id}/url` - URL temporária

#### Service Requests
- `GET|POST /api/service-requests` - Listar/Criar tickets
- `POST /api/service-requests/{id}/mark-resolved` - Marcar como resolvido
- `POST /api/service-requests/{id}/comments` - Adicionar comentário

#### Notificações
- `GET /api/notifications` - Listar notificações
- `GET /api/notifications/unread-count` - Contador de não lidas
- `POST /api/notifications/{id}/mark-as-read` - Marcar como lida

#### Relatórios
- `GET /api/reports/pl` - Relatório P&L (Profit & Loss)

#### Dashboard
- `GET /api/dashboard` - Dashboard agregado

#### Assinatura
- `GET /api/subscription` - Status da assinatura
- `PUT /api/subscription` - Atualizar plano
- `POST /api/subscription/cancel` - Cancelar assinatura

## 🧪 Testes

### Backend

Execute todos os testes:
```bash
make test
```

Com cobertura de código:
```bash
make test-coverage
```

Testes filtrados:
```bash
make test-filter FILTER='nome_do_teste'
```

### Qualidade de Código

Verificar estilo:
```bash
make pint
```

Corrigir estilo automaticamente:
```bash
make pint-fix
```

Análise estática:
```bash
make phpstan
```

Todas as verificações:
```bash
make quality
```

## 📊 Seeds e Dados de Teste

### Seeder Básico
```bash
make seed
```

Cria:
- Organização de desenvolvimento
- Usuário admin (`admin@symplus.dev` / `password`)
- Assinatura gratuita

### Seeder Realista
```bash
make seed-realistic
```

Cria dados completos para desenvolvimento:
- 2 organizações
- 2-3 usuários por organização
- 12 categorias
- 3 contas
- Transações dos últimos 12 meses
- Due items
- Service requests
- Notificações

**Credenciais:**
- `admin@symplus.dev` / `password` (Free plan)
- `demo@example.com` / `password` (Basic plan - owner)
- `team@example.com` / `password` (Basic plan - admin)

## 🔐 Planos e Limites

O sistema suporta 4 planos com limites diferentes:

- **Free**: 1 conta, 50 transações/mês, 10 documentos, 2 usuários
- **Basic**: 5 contas, 500 transações/mês, 100 documentos, 5 usuários
- **Premium**: 20 contas, 5000 transações/mês, 1000 documentos, 20 usuários
- **Enterprise**: Ilimitado

## 🐳 Docker

### Comandos Úteis

```bash
make up          # Iniciar containers
make down        # Parar containers
make sh          # Acessar container PHP
make logs        # Ver logs
make horizon     # Iniciar Laravel Horizon
```

### Serviços

- **API**: `http://localhost:8000`
- **MySQL**: `localhost:3306`
- **Redis**: `localhost:6379`
- **MinIO**: `http://localhost:9000` (API) / `http://localhost:9001` (Console)

## 📖 Comandos Make

```bash
make help         # Lista todos os comandos disponíveis
make install      # Instalar dependências
make migrate      # Executar migrations
make seed         # Executar seeders básicos
make seed-realistic # Executar seeders realistas
make test         # Executar testes
make test-coverage # Testes com cobertura
make pint         # Verificar estilo de código
make pint-fix     # Corrigir estilo automaticamente
make phpstan      # Análise estática
make quality      # Todas as verificações de qualidade
```

## 🤝 Contribuindo

Por favor, leia [CONTRIBUTING.md](CONTRIBUTING.md) para detalhes sobre nosso código de conduta e processo de submissão de pull requests.

### Convenções de Commit

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `docs:` Documentação
- `style:` Formatação
- `refactor:` Refatoração
- `test:` Testes
- `chore:` Manutenção

## 📄 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👥 Equipe

- Desenvolvido por Wendeel Marinho

## 📞 Suporte

Para questões e suporte:
- Abra uma issue no GitHub
- Consulte a documentação em `docs/`
- Veja a collection do Postman em `backend/postman/`

## 🗺️ Roadmap

- [ ] Exportação de relatórios (PDF/Excel)
- [ ] Integração com bancos brasileiros (Open Banking)
- [ ] App mobile completo
- [ ] Dashboard de analytics avançado
- [ ] Sistema de templates de transações
- [ ] Integração com sistemas de ERP

---

**Symplus Finance** - Gestão financeira simplificada para empresas modernas.
