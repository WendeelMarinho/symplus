# 💰 Symplus Finance

Plataforma completa de gestão financeira multi-tenant com dashboard personalizável, insights automáticos e suporte completo a web, mobile e desktop.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Laravel](https://img.shields.io/badge/Laravel-11-FF2D20?logo=laravel)](https://laravel.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Funcionalidades](#-funcionalidades)
- [Tecnologias](#-tecnologias)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação](#-instalação)
- [Deploy para Produção](#-deploy-para-produção)
- [Build de Aplicativos](#-build-de-aplicativos)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Documentação](#-documentação)
- [Contribuindo](#-contribuindo)
- [Licença](#-licença)

---

## 🎯 Sobre o Projeto

**Symplus Finance** é uma plataforma SaaS completa para gestão financeira empresarial, oferecendo:

- 📊 **Dashboard Multi-Layout**: 3 visões personalizáveis (Caixa, Resultado, Cobrança) com drag & drop
- 💡 **Insights Automáticos**: Análises inteligentes baseadas em dados financeiros
- 🔔 **Alertas Unificados**: Notificações de itens vencidos, próximos vencimentos e limites
- 📱 **Multi-Plataforma**: Web, Android e iOS com código compartilhado
- 🌐 **Multi-Tenant**: Suporte completo a múltiplas organizações
- 🔐 **RBAC**: Controle de acesso baseado em papéis (owner, admin, user)

---

## ✨ Funcionalidades

### Dashboard (v2.0.0)

- ✅ **Sistema Multi-Layout** com 3 visões pré-configuradas
- ✅ **Drag & Drop** para personalização completa do layout
- ✅ **Insights Automáticos** exibidos nos cards principais
- ✅ **Alertas Recentes** unificados (vencidos + próximos vencimentos)
- ✅ **Persistência de Layouts** (local + backend)
- ✅ **Cards Compactos** otimizados para web
- ✅ **Responsividade Completa** (mobile, tablet, desktop)

### Gestão Financeira

- ✅ **4 KPIs Principais**: Entrada, Saída, Resultado, Percentual
- ✅ **Indicadores Personalizados**: CRUD completo com métricas customizadas
- ✅ **Resumo Trimestral**: Análise de receitas e despesas por trimestre
- ✅ **Gráficos Interativos**: P&L, categorias, fluxo de caixa
- ✅ **Calendário de Vencimentos**: Visualização e gestão de due items
- ✅ **Transações**: CRUD completo com upload de documentos
- ✅ **Contas e Categorias**: Gestão completa de contas bancárias e categorias

### Sistema

- ✅ **Autenticação**: Login, logout, persistência de sessão
- ✅ **Multi-Moeda**: Suporte a BRL e USD com conversão automática
- ✅ **i18n**: Português e Inglês
- ✅ **Upload de Arquivos**: Avatar do usuário, documentos de transações
- ✅ **Notificações**: Sistema completo de notificações
- ✅ **Telemetria**: Logs de ações e erros

---

## 🛠️ Tecnologias

### Backend
- **Laravel 11** (PHP 8.3)
- **MySQL 8.0**
- **Docker & Docker Compose**
- **Nginx**
- **Sanctum** (Autenticação)

### Frontend
- **Flutter 3.0+** (Dart)
- **Riverpod** (State Management)
- **GoRouter** (Navegação)
- **Dio** (HTTP Client)
- **Material Design 3**

### DevOps
- **GitHub** (Versionamento)
- **Docker** (Containerização)
- **Nginx** (Web Server)
- **Ubuntu 22.04 LTS** (VPS)

---

## 📦 Pré-requisitos

### Desenvolvimento Local

- **Flutter SDK** 3.0+ ([Instalação](https://docs.flutter.dev/get-started/install))
- **Docker** e **Docker Compose**
- **Git**
- **Node.js** (opcional, para ferramentas)

### Produção (VPS)

- **Ubuntu 22.04 LTS**
- **Docker** e **Docker Compose**
- **Nginx**
- **Git**
- **SSL Certificate** (Let's Encrypt recomendado)

---

## 🚀 Instalação

### 1. Clonar Repositório

```bash
git clone https://github.com/WendeelMarinho/symplus.git
cd symplus
```

### 2. Backend (Laravel)

```bash
cd backend

# Copiar arquivo de ambiente
cp .env.example .env

# Editar .env com suas configurações
nano .env

# Iniciar containers
docker compose up -d

# Instalar dependências
docker compose exec php composer install

# Gerar chave da aplicação
docker compose exec php php artisan key:generate

# Executar migrations
docker compose exec php php artisan migrate

# (Opcional) Popular banco de dados
docker compose exec php php artisan db:seed
```

### 3. Frontend (Flutter)

```bash
cd app

# Instalar dependências
flutter pub get

# Executar em modo desenvolvimento
flutter run -d chrome
```

Para mais detalhes, consulte:
- [docs/QUICK_START.md](./docs/QUICK_START.md)
- [backend/README.md](./backend/README.md)
- [app/README.md](./app/README.md)

---

## 🌐 Deploy para Produção

### Informações da VPS

- **Host**: `srv1113923.hstgr.cloud`
- **IP**: `72.61.6.135`
- **SO**: Ubuntu 22.04 LTS
- **Usuário SSH**: `root`
- **Path de Deploy**: `/var/www/symplus`

### Deploy Automatizado

O projeto inclui scripts automatizados para deploy zero-downtime:

```bash
# Configurar variáveis de ambiente
export VPS_HOST="srv1113923.hstgr.cloud"
export VPS_USER="root"
export VPS_PATH="/var/www/symplus"
export GIT_REPO="https://github.com/WendeelMarinho/symplus.git"
export BRANCH="main"
export DOMAIN_HEALTHCHECK="https://srv1113923.hstgr.cloud/api/health"

# Executar deploy
bash scripts/vps_deploy.sh
```

### Deploy Manual

#### 1. Build Flutter Web

```bash
cd app
flutter clean && flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
  --base-href=/app/

# Copiar para diretório de deploy
mkdir -p ../backend/public/app
rm -rf ../backend/public/app/*
cp -r build/web/* ../backend/public/app/
```

#### 2. Deploy no Servidor

```bash
# Conectar ao servidor
ssh root@srv1113923.hstgr.cloud

# No servidor
cd /var/www/symplus
git pull origin main

# Executar migrations
cd backend
docker compose -f docker-compose.prod.yml exec php php artisan migrate --force

# Copiar build do Flutter (se não foi feito localmente)
cd ../app
flutter build web --release \
  --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
  --base-href=/app/
mkdir -p ../backend/public/app
rm -rf ../backend/public/app/*
cp -r build/web/* ../backend/public/app/

# Reiniciar serviços
cd ../backend
docker compose -f docker-compose.prod.yml restart nginx
```

### Verificação

```bash
# Healthcheck da API
curl https://srv1113923.hstgr.cloud/api/health

# Verificar app web
curl -I https://srv1113923.hstgr.cloud/app/
```

**Documentação completa**: [DEPLOY.md](./DEPLOY.md)

---

## 📱 Build de Aplicativos

### Android (APK)

```bash
# Build de produção
bash scripts/build_flutter_apk.sh

# Ou manualmente
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

O APK será gerado em: `app/build/app/outputs/flutter-apk/app-release.apk`

**Nota**: Para produção, configure um keystore de assinatura:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### iOS (IPA)

```bash
cd app
flutter build ios --release \
  --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

### Build Completo (Web + APK)

```bash
bash scripts/build_all.sh
```

---

## 📁 Estrutura do Projeto

```
symplus/
├── app/                    # Frontend Flutter
│   ├── lib/
│   │   ├── config/         # Configurações (API, Router)
│   │   ├── core/           # Core (Auth, Storage, Network)
│   │   └── features/       # Features (Dashboard, Transactions, etc.)
│   ├── android/            # Configuração Android
│   ├── ios/                # Configuração iOS
│   └── web/                # Configuração Web
│
├── backend/                # Backend Laravel
│   ├── app/                # Código da aplicação
│   ├── config/             # Configurações
│   ├── database/           # Migrations e Seeders
│   ├── routes/             # Rotas da API
│   └── public/             # Arquivos públicos (inclui build do Flutter)
│
├── scripts/                # Scripts de automação
│   ├── build_flutter_web.sh
│   ├── build_flutter_apk.sh
│   ├── vps_deploy.sh
│   └── ...
│
└── docs/                   # Documentação
    ├── QUICK_START.md
    ├── DEPLOY_VPS.md
    └── ...
```

---

## 📚 Documentação

### Documentação Principal

- **[DEPLOY.md](./DEPLOY.md)** - Guia completo de deploy para produção
- **[DASHBOARD_OVERVIEW.md](./DASHBOARD_OVERVIEW.md)** - Overview completo do sistema de dashboard
- **[DASHBOARD_SUMMARY.md](./DASHBOARD_SUMMARY.md)** - Resumo executivo do dashboard
- **[PROMPT_IA.md](./PROMPT_IA.md)** - Prompt para IA fazer deploy

### Documentação por Módulo

- **Backend**: [backend/README.md](./backend/README.md)
- **Frontend**: [app/README.md](./app/README.md)
- **Scripts**: [scripts/README.md](./scripts/README.md)

### Documentação Técnica

- [docs/QUICK_START.md](./docs/QUICK_START.md) - Setup rápido
- [docs/DEPLOY_VPS.md](./docs/DEPLOY_VPS.md) - Deploy na VPS
- [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) - Arquitetura do sistema
- [docs/API.md](./docs/API.md) - Documentação da API

---

## 📊 Status da Implementação

**Versão**: 2.0.0  
**Status**: ✅ **Pronto para Produção**

### Funcionalidades Principais (100%)

1. ✅ Dashboard Multi-Layout com 3 visões
2. ✅ Drag & Drop para personalização
3. ✅ Insights Automáticos
4. ✅ Alertas Unificados
5. ✅ 4 KPIs Principais com Detalhes
6. ✅ Indicadores Personalizados (CRUD completo)
7. ✅ Resumo Trimestral
8. ✅ Gráficos Interativos (P&L, Categorias)
9. ✅ Calendário de Vencimentos
10. ✅ Gestão de Transações (CRUD + Upload)
11. ✅ Sistema de Moeda Global (BRL/USD)
12. ✅ Sistema de Idiomas (PT/EN)
13. ✅ Upload de Avatar/Logo
14. ✅ Persistência de Sessão
15. ✅ RBAC Completo

### Correções Aplicadas

- ✅ Erros de compilação corrigidos
- ✅ Erros de layout e renderização corrigidos
- ✅ Overflow de layout resolvido
- ✅ Constraints não limitadas corrigidas
- ✅ Verificações `mounted` adicionadas
- ✅ Build de produção configurado
- ✅ Scripts de deploy prontos

### Compatibilidade

- ✅ Flutter Web (100% compatível)
- ✅ Android (APK funcional)
- ✅ iOS (preparado)
- ✅ Desktop (preparado)
- ✅ Responsividade completa
- ✅ Acessibilidade implementada

---

## 🏗️ Arquitetura

### Backend (Laravel)

- **API RESTful** com autenticação via Sanctum
- **Multi-tenant** com isolamento por organização
- **RBAC** (Role-Based Access Control)
- **Docker** para containerização
- **MySQL** para persistência

### Frontend (Flutter)

- **Riverpod** para gerenciamento de estado
- **GoRouter** para navegação declarativa
- **Dio** para requisições HTTP
- **Material Design 3** para UI
- **Responsive Design** para todas as plataformas

### DevOps

- **GitHub** para versionamento
- **Docker Compose** para orquestração
- **Nginx** como reverse proxy
- **Zero-downtime Deploy** com releases

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

**Guia de Contribuição**: [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## 📝 Licença

Este projeto é proprietário. Todos os direitos reservados.

Ver [LICENSE](./LICENSE) para mais detalhes.

---

## 📞 Contato

- **Repositório**: https://github.com/WendeelMarinho/symplus
- **Issues**: https://github.com/WendeelMarinho/symplus/issues

---

## 🎯 Roadmap

### Próximas Funcionalidades

- [ ] App iOS nativo
- [ ] App Desktop (Windows, macOS, Linux)
- [ ] Exportação de relatórios (PDF, Excel)
- [ ] Integração com bancos (Open Banking)
- [ ] Dashboard analytics avançado
- [ ] Notificações push
- [ ] Modo offline

---

**Desenvolvido com ❤️ usando Flutter e Laravel**
