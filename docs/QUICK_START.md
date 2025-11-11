# Guia de Início Rápido

Este guia te ajudará a executar o projeto Symplus Finance do zero.

## 🚀 Passo a Passo

### 1. Backend (API Laravel)

#### 1.1. Configure o ambiente

```bash
cd backend
cp env.example .env
```

Edite o `.env` se necessário (geralmente funciona com os valores padrão).

#### 1.2. Inicie os containers Docker

```bash
make up
# ou
docker compose up -d
```

Aguarde alguns segundos para os serviços iniciarem.

#### 1.3. Instale dependências

```bash
make install
```

#### 1.4. Configure a aplicação

```bash
# Gerar chave da aplicação
docker compose exec php php artisan key:generate

# Executar migrations
make migrate

# Popular banco com dados realistas
make seed-realistic
```

#### 1.5. Verifique se está funcionando

Acesse: `http://localhost:8000/api/health`

Você deve ver:
```json
{
  "status": "ok",
  "timestamp": "..."
}
```

**✅ Backend rodando!**

### 2. Testar a API (Postman)

#### 2.1. Importar collection

1. Abra o Postman
2. Import > Selecione `backend/postman/Symplus_API.postman_collection.json`
3. Configure as variáveis:
   - `base_url`: `http://localhost:8000`
   - `organization_id`: `1` (ou obtenha após login)

#### 2.2. Fazer login

1. Execute: **Auth > Login**
2. Body:
   ```json
   {
     "email": "admin@symplus.dev",
     "password": "password"
   }
   ```
3. Copie o `token` da resposta
4. Cole na variável `token` da collection

#### 2.3. Testar outros endpoints

Agora você pode testar qualquer endpoint da collection!

### 3. App Flutter

#### 3.1. Habilitar Suporte Web (primeira vez)

```bash
cd app
flutter create . --platforms=web
# ou
make setup-web
```

#### 3.2. Pré-requisitos

- Flutter SDK instalado
- Android Studio ou Xcode (para Android/iOS)
- Ou navegador (para web)

#### 3.3. Configure a API

Edite `app/lib/config/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:8000';
```

**Nota**: Para Android, use `http://10.0.2.2:8000` (emulador) ou `http://SEU_IP_LOCAL:8000` (dispositivo físico).

#### 3.4. Instale dependências

```bash
cd app
flutter pub get
```

#### 3.5. Execute o app

**Web (mais fácil para começar):**
```bash
flutter run -d chrome
```

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

### 4. Comandos Úteis

#### Backend

```bash
# Ver logs
make logs

# Executar testes
make test

# Acessar container
make sh

# Iniciar Horizon (filas)
make horizon

# Verificar qualidade
make quality
```

#### App

```bash
# Limpar build
flutter clean

# Atualizar dependências
flutter pub upgrade

# Verificar setup
flutter doctor
```

## 🔍 Verificação Rápida

### Backend funcionando?

```bash
curl http://localhost:8000/api/health
```

### Banco populado?

```bash
cd backend
docker compose exec php php artisan tinker
>>> \App\Models\Organization::count()
>>> \App\Models\User::count()
```

### App configurado?

Verifique `app/lib/config/api_config.dart` - a URL deve apontar para o backend.

## 🐛 Troubleshooting

### Backend não inicia

1. Verifique se as portas estão livres:
   ```bash
   # Porta 8000 (Nginx)
   # Porta 3306 (MySQL)
   # Porta 6379 (Redis)
   ```

2. Veja os logs:
   ```bash
   make logs
   ```

3. Reconstrua os containers:
   ```bash
   make down
   docker compose build --no-cache
   make up
   ```

### Erro de conexão com banco

1. Verifique se MySQL está rodando:
   ```bash
   docker compose ps
   ```

2. Teste conexão:
   ```bash
   docker compose exec php php artisan migrate:status
   ```

### App não conecta ao backend

1. **Android Emulator**: Use `http://10.0.2.2:8000`
2. **iOS Simulator**: Use `http://localhost:8000`
3. **Dispositivo físico**: Use `http://SEU_IP_LOCAL:8000`
4. **Web**: Use `http://localhost:8000`

Para descobrir seu IP:
```bash
# Linux/Mac
ifconfig | grep "inet "

# Windows
ipconfig
```

### Erro "No Linux desktop project configured"

O app Flutter está configurado para mobile/web. Para rodar:

```bash
# Web (recomendado)
flutter run -d chrome

# Ou configure Android/iOS
flutter doctor
```

## 📱 Credenciais de Teste

Após executar `make seed-realistic`:

- `admin@symplus.dev` / `password` (Free plan)
- `demo@example.com` / `password` (Basic plan - owner)
- `team@example.com` / `password` (Basic plan - admin)

## 🎯 Próximos Passos

1. ✅ Backend rodando
2. ✅ API testada no Postman
3. ✅ App Flutter executando
4. 📖 Explore a documentação em `docs/`
5. 🧪 Execute testes: `make test`
6. 💡 Explore o código e contribua!

## 📚 Documentação Completa

- [README.md](../README.md) - Visão geral
- [ARCHITECTURE.md](ARCHITECTURE.md) - Arquitetura
- [API.md](API.md) - Documentação da API
- [TESTING.md](../backend/TESTING.md) - Guia de testes

---

**Dúvidas?** Abra uma issue no GitHub!

