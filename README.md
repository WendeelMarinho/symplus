# 💰 Symplus Finance

Plataforma completa de gestão financeira multi-tenant com dashboard personalizável, insights automáticos e suporte completo a web, mobile e desktop.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Laravel](https://img.shields.io/badge/Laravel-11-FF2D20?logo=laravel)](https://laravel.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production-green)](https://srv1113923.hstgr.cloud)

> **⚠️ Projeto Privado**: Este repositório é privado e não aceita contribuições externas. Todos os direitos reservados.

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

### 📊 Dashboard (v2.0.0)

**Sistema Multi-Layout Avançado**
- ✅ **3 Visões Pré-configuradas**: Caixa, Resultado e Cobrança
- ✅ **Drag & Drop**: Personalização completa do layout via arrastar e soltar
- ✅ **Persistência de Layouts**: Salvo localmente e no backend (sincronização cross-device)
- ✅ **Sistema de Widgets**: Cada elemento do dashboard é um widget independente e arrastável
- ✅ **Templates Dinâmicos**: Templates de layout configuráveis via backend

**KPIs e Métricas**
- ✅ **4 KPIs Principais**: Entrada, Saída, Resultado e Percentual
- ✅ **Detalhes dos KPIs**: Visualização detalhada de cada KPI com filtros
- ✅ **Insights Automáticos**: Análises inteligentes exibidas nos cards principais
- ✅ **Indicadores Personalizados**: CRUD completo para criar métricas customizadas
- ✅ **Resumo Trimestral**: Análise de receitas e despesas por trimestre

**Visualizações e Gráficos**
- ✅ **Gráficos Interativos**: P&L, categorias (donut), fluxo de caixa (barras)
- ✅ **Calendário de Vencimentos**: Visualização mensal com transações e due items
- ✅ **Modal de Dia**: Detalhamento de transações e vencimentos por dia
- ✅ **Top Categorias**: Gráficos donut para receitas e despesas por categoria

**Alertas e Notificações**
- ✅ **Alertas Recentes Unificados**: Itens vencidos + próximos vencimentos em um único widget
- ✅ **Integração com Notificações**: Alertas sincronizados com sistema de notificações

**Responsividade**
- ✅ **Layout Adaptativo**: Desktop (grid), Tablet (2 colunas), Mobile (lista vertical)
- ✅ **Cards Compactos**: Otimizados para visualização web
- ✅ **Performance**: Renderização otimizada para Flutter Web

### 💰 Gestão Financeira

**Transações**
- ✅ **CRUD Completo**: Criar, editar, visualizar e excluir transações
- ✅ **Upload de Documentos**: Anexar documentos (comprovantes, recibos, etc.)
- ✅ **Filtros Avançados**: Por tipo, categoria, conta, período, valor
- ✅ **Busca**: Busca por descrição, categoria ou conta
- ✅ **Paginação**: Listagem paginada para grandes volumes
- ✅ **Detalhamento**: Página de detalhes com histórico completo
- ✅ **Formulário Moderno**: Material Design 3 com validação completa

**Contas Bancárias**
- ✅ **CRUD Completo**: Gestão de contas correntes, poupança, cartões de crédito
- ✅ **Saldos em Tempo Real**: Visualização de saldos atualizados
- ✅ **Detalhamento por Conta**: Página de detalhes com transações da conta
- ✅ **Filtros**: Por tipo de conta e status

**Categorias**
- ✅ **CRUD Completo**: Criar, editar e excluir categorias
- ✅ **Cores Personalizadas**: Cada categoria pode ter sua cor
- ✅ **Ícones**: Seleção de ícones para categorias
- ✅ **Organização**: Categorias de receitas e despesas separadas

**Vencimentos (Due Items)**
- ✅ **Gestão Completa**: Itens a pagar e a receber
- ✅ **Status**: Pendente, Pago, Vencido
- ✅ **Calendário Visual**: Visualização mensal de vencimentos
- ✅ **Filtros**: Por tipo, status, período
- ✅ **Alertas**: Destaque para itens vencidos e próximos vencimentos
- ✅ **CRUD Completo**: Criar, editar e marcar como pago/recebido

### 📈 Relatórios e Análises

**Relatórios P&L (Profit & Loss)**
- ✅ **Gráficos Interativos**: Gráfico de barras empilhadas (Receitas x Despesas)
- ✅ **Tabela Detalhada**: Dados tabulares com totais
- ✅ **Agrupamento**: Por mês ou por categoria
- ✅ **Filtros de Período**: Seleção de data inicial e final
- ✅ **Exportação**: Exportar para CSV e PDF (preparado)
- ✅ **Resumo do Período**: Totais de receitas, despesas e lucro líquido
- ✅ **Visualização Alternada**: Alternar entre gráfico e tabela

**Análises do Dashboard**
- ✅ **Fluxo de Caixa**: Projeção de saldo futuro
- ✅ **Top Categorias**: Ranking de categorias por valor
- ✅ **Tendências**: Comparação com períodos anteriores
- ✅ **Insights Automáticos**: Análises contextuais baseadas em dados

### 📄 Documentos

- ✅ **Upload e Download**: Gerenciamento completo de documentos
- ✅ **Associação com Transações**: Documentos vinculados a transações
- ✅ **Organização**: Listagem e busca de documentos
- ✅ **Visualização**: Preview de documentos

### 🎫 Tickets/Service Requests

- ✅ **Sistema de Tickets**: Criação e gestão de tickets de suporte
- ✅ **Status**: Aberto, Em Andamento, Resolvido, Fechado
- ✅ **Prioridades**: Baixa, Média, Alta, Urgente
- ✅ **Kanban View**: Visualização em colunas (desktop)
- ✅ **Lista View**: Visualização em lista (mobile)
- ✅ **Detalhamento**: Página de detalhes com histórico
- ✅ **Filtros**: Por status, prioridade, período

### 🔔 Notificações

- ✅ **Sistema Completo**: Notificações em tempo real
- ✅ **Tipos**: Alertas, Informações, Avisos
- ✅ **Marcação**: Marcar como lida/não lida
- ✅ **Filtros**: Por tipo e status
- ✅ **Integração**: Integrado com alertas do dashboard

### 👤 Perfil e Configurações

**Perfil do Usuário**
- ✅ **Informações Pessoais**: Nome, email, telefone
- ✅ **Avatar**: Upload e visualização de foto de perfil
- ✅ **Preferências**: Tema, idioma, moeda padrão
- ✅ **Alteração de Senha**: Formulário seguro para troca de senha
- ✅ **Logout**: Encerramento de sessão

**Configurações da Aplicação**
- ✅ **Aparência**: Seleção de tema (claro/escuro)
- ✅ **Idioma**: Português e Inglês (i18n completo)
- ✅ **Moeda**: BRL e USD com conversão automática
- ✅ **Logo da Organização**: Upload de logo personalizado
- ✅ **Configurações Globais**: Aplicadas a toda organização

### 💳 Assinatura

- ✅ **Gestão de Assinatura**: Visualização de plano atual
- ✅ **Status**: Ativa, Cancelada, Expirada
- ✅ **Renovação**: Informações sobre renovação automática
- ✅ **Histórico**: Histórico de assinaturas

### 🔐 Autenticação e Segurança

**Autenticação**
- ✅ **Login**: Autenticação via email e senha
- ✅ **Persistência de Sessão**: Mantém usuário logado entre sessões
- ✅ **Logout**: Encerramento seguro de sessão
- ✅ **Expiração de Token**: Tratamento automático de tokens expirados
- ✅ **Redirecionamento**: Redirecionamento automático após login

**RBAC (Role-Based Access Control)**
- ✅ **3 Níveis de Acesso**: Owner, Admin, User
- ✅ **Permissões Granulares**: Controle fino de acesso por funcionalidade
- ✅ **Menu Dinâmico**: Menu adaptado às permissões do usuário
- ✅ **Proteção de Rotas**: Rotas protegidas por permissões
- ✅ **Feedback Visual**: Mensagens de acesso negado

### 🌐 Multi-Tenant

- ✅ **Isolamento Completo**: Dados isolados por organização
- ✅ **Múltiplas Organizações**: Usuário pode pertencer a várias organizações
- ✅ **Seleção de Organização**: Troca de contexto entre organizações
- ✅ **Configurações por Organização**: Logo, moeda e preferências por org

### 🌍 Internacionalização (i18n)

- ✅ **2 Idiomas**: Português (pt_BR) e Inglês (en_US)
- ✅ **Tradução Completa**: Todas as telas e mensagens traduzidas
- ✅ **Seleção Dinâmica**: Troca de idioma em tempo real
- ✅ **Persistência**: Idioma salvo nas preferências do usuário

### 💱 Multi-Moeda

- ✅ **2 Moedas**: Real Brasileiro (BRL) e Dólar Americano (USD)
- ✅ **Conversão Automática**: Conversão em tempo real
- ✅ **Formatação**: Formatação correta por moeda
- ✅ **Seleção Global**: Moeda aplicada em toda aplicação
- ✅ **Persistência**: Moeda salva nas preferências

### 📱 Multi-Plataforma

**Flutter Web**
- ✅ **100% Funcional**: Todas as features disponíveis
- ✅ **Responsivo**: Adaptação para diferentes tamanhos de tela
- ✅ **Performance**: Otimizado para navegadores modernos
- ✅ **PWA Ready**: Preparado para Progressive Web App

**Android**
- ✅ **APK Funcional**: Build de produção disponível
- ✅ **Responsivo**: Adaptação para diferentes tamanhos de tela
- ✅ **Navegação Nativa**: Navegação otimizada para mobile

**iOS**
- ✅ **Preparado**: Estrutura pronta para build
- ✅ **Configuração**: iOS configurado e pronto

**Desktop**
- ✅ **Preparado**: Estrutura pronta para Windows, macOS e Linux

### 🎨 Interface e UX

**Material Design 3**
- ✅ **Design Moderno**: Interface seguindo Material Design 3
- ✅ **Componentes Customizados**: Cards, botões, inputs acessíveis
- ✅ **Cores Consistentes**: Paleta de cores unificada
- ✅ **Tipografia**: Sistema de tipografia consistente
- ✅ **Espaçamento**: Sistema de espaçamento padronizado

**Acessibilidade**
- ✅ **Screen Readers**: Suporte completo para leitores de tela
- ✅ **Navegação por Teclado**: Atalhos e navegação via teclado
- ✅ **Contraste**: Cores com contraste adequado
- ✅ **Tooltips**: Dicas contextuais em elementos interativos
- ✅ **Labels Semânticos**: Labels descritivos para todos os elementos

**Responsividade**
- ✅ **Breakpoints**: Desktop (≥1000px), Tablet (600-999px), Mobile (<600px)
- ✅ **Layout Adaptativo**: Layouts diferentes por tamanho de tela
- ✅ **Navegação Adaptativa**: NavigationRail (desktop) e BottomNavigation (mobile)
- ✅ **Componentes Responsivos**: Todos os componentes se adaptam ao tamanho

### 🔧 Funcionalidades Técnicas

**Telemetria**
- ✅ **Logs de Ações**: Registro de ações do usuário
- ✅ **Logs de Erros**: Captura e registro de erros
- ✅ **Analytics**: Preparado para integração com analytics

**Upload de Arquivos**
- ✅ **Avatar**: Upload de foto de perfil
- ✅ **Logo**: Upload de logo da organização
- ✅ **Documentos**: Upload de documentos de transações
- ✅ **Validação**: Validação de tipo e tamanho de arquivo

**Performance**
- ✅ **Lazy Loading**: Carregamento sob demanda
- ✅ **Cache**: Cache de dados quando apropriado
- ✅ **Otimização**: Builds otimizados para produção
- ✅ **Code Splitting**: Preparado para code splitting

**DevOps**
- ✅ **Deploy Zero-Downtime**: Sistema de releases com rollback
- ✅ **Scripts Automatizados**: Build e deploy automatizados
- ✅ **Healthcheck**: Verificação automática de saúde
- ✅ **Backup**: Sistema de backup de configurações

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

### ⚠️ Informações Confidenciais

**Nota**: As informações abaixo são confidenciais e devem ser mantidas em segurança.

- **Host**: `srv1113923.hstgr.cloud`
- **SO**: Ubuntu 22.04 LTS
- **Path de Deploy**: `/var/www/symplus`
- **URL de Produção**: `https://srv1113923.hstgr.cloud`

### Deploy Automatizado

O projeto inclui scripts automatizados para deploy zero-downtime com sistema de releases:

```bash
# Configurar variáveis de ambiente
export VPS_HOST="srv1113923.hstgr.cloud"
export VPS_USER="root"
export VPS_PATH="/var/www/symplus"
export GIT_REPO="https://github.com/WendeelMarinho/symplus.git"
export BRANCH="main"
export DOMAIN_HEALTHCHECK="https://srv1113923.hstgr.cloud/api/health"

# Executar deploy (zero-downtime)
bash scripts/vps_deploy.sh
```

**Características do Deploy**:
- ✅ Zero-downtime com sistema de releases
- ✅ Healthcheck automático antes de ativar nova release
- ✅ Rollback automático em caso de falha
- ✅ Limpeza automática de releases antigas (mantém últimas 5)
- ✅ Backup automático de configurações

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

**Opção A: Deploy Automatizado (Recomendado)**

```bash
# Usar script de deploy automatizado
bash scripts/vps_deploy.sh
```

**Opção B: Deploy Manual**

```bash
# Conectar ao servidor
ssh root@srv1113923.hstgr.cloud

# No servidor
cd /var/www/symplus
git pull origin main

# Executar migrations
cd backend
docker compose -f docker-compose.prod.yml exec php php artisan migrate --force

# Build do Flutter (se não foi feito localmente)
cd ../app
flutter build web --release \
  --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
  --base-href=/app/ \
  --web-renderer canvaskit

# Copiar build para diretório público
mkdir -p ../backend/public/app
rm -rf ../backend/public/app/*
cp -r build/web/* ../backend/public/app/

# Otimizar cache do Laravel
cd ../backend
docker compose -f docker-compose.prod.yml exec php php artisan optimize

# Reiniciar serviços
docker compose -f docker-compose.prod.yml restart nginx
```

### Verificação Pós-Deploy

```bash
# Healthcheck da API
curl https://srv1113923.hstgr.cloud/api/health

# Verificar app web
curl -I https://srv1113923.hstgr.cloud/app/

# Verificar logs (se necessário)
ssh root@srv1113923.hstgr.cloud
cd /var/www/symplus/backend
docker compose -f docker-compose.prod.yml logs --tail=50
```

### Rollback

Em caso de problemas, é possível fazer rollback para a release anterior:

```bash
bash scripts/vps_rollback.sh
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

### Documentação por Módulo

- **Backend**: [backend/README.md](./backend/README.md)
- **Frontend**: [app/README.md](./app/README.md)

---

## 📊 Status da Implementação

**Versão**: 2.0.0  
**Status**: ✅ **Pronto para Produção**

### Módulos Implementados (100%)

#### Dashboard e Analytics
1. ✅ Dashboard Multi-Layout (3 visões: Caixa, Resultado, Cobrança)
2. ✅ Drag & Drop para personalização de layout
3. ✅ Insights Automáticos nos cards
4. ✅ Alertas Recentes Unificados
5. ✅ 4 KPIs Principais (Entrada, Saída, Resultado, Percentual)
6. ✅ Indicadores Personalizados (CRUD completo)
7. ✅ Resumo Trimestral
8. ✅ Gráficos Interativos (P&L, Categorias, Fluxo de Caixa)
9. ✅ Calendário de Vencimentos
10. ✅ Visão Geral (Overview)

#### Gestão Financeira
11. ✅ Transações (CRUD completo + Upload de documentos)
12. ✅ Contas Bancárias (CRUD completo + Detalhamento)
13. ✅ Categorias (CRUD completo + Cores e Ícones)
14. ✅ Vencimentos/Due Items (CRUD completo + Calendário)

#### Relatórios
15. ✅ Relatórios P&L (Gráficos + Tabelas + Exportação)

#### Documentos e Tickets
16. ✅ Documentos (Upload, Download, Organização)
17. ✅ Tickets/Service Requests (CRUD + Kanban + Lista)

#### Sistema e Configurações
18. ✅ Notificações (Sistema completo)
19. ✅ Perfil do Usuário (Edição + Avatar + Senha)
20. ✅ Configurações (Tema, Idioma, Moeda, Logo)
21. ✅ Assinatura (Gestão de planos)

#### Autenticação e Segurança
22. ✅ Autenticação (Login, Logout, Sessão Persistente)
23. ✅ RBAC Completo (Owner, Admin, User)
24. ✅ Multi-Tenant (Isolamento por organização)

#### Internacionalização e Moeda
25. ✅ i18n (Português e Inglês)
26. ✅ Multi-Moeda (BRL e USD com conversão)

#### Plataformas
27. ✅ Flutter Web (100% funcional)
28. ✅ Android (APK funcional)
29. ✅ iOS (Preparado)
30. ✅ Desktop (Preparado)

#### UX e Acessibilidade
31. ✅ Material Design 3
32. ✅ Responsividade Completa
33. ✅ Acessibilidade (Screen Readers, Teclado, Contraste)
34. ✅ Telemetria e Logs

### Correções Aplicadas (v2.0.0)

- ✅ Erros de compilação corrigidos
- ✅ Erros de layout e renderização corrigidos
- ✅ Overflow de layout resolvido (Dashboard e Reports)
- ✅ Constraints não limitadas corrigidas
- ✅ TextFormField/DropdownButtonFormField com largura definida
- ✅ TopCategoriesDonutChart com altura controlada
- ✅ Verificações `mounted` adicionadas
- ✅ Build de produção configurado
- ✅ Scripts de deploy prontos
- ✅ Layout seguro para Flutter Web

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

## 📝 Licença

Este projeto é **privado e proprietário**. Todos os direitos reservados.

**⚠️ Aviso**: Este repositório é privado e não aceita contribuições externas.

Ver [LICENSE](./LICENSE) para mais detalhes.

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
- [ ] Relatórios avançados com filtros customizados
- [ ] Integração com APIs de cotação de moedas
- [ ] Sistema de backup automático

---

## 🔒 Segurança

Este é um projeto **privado**. Não compartilhe credenciais, tokens ou informações sensíveis.

### Informações Sensíveis

- Arquivos `.env` não devem ser commitados
- Credenciais de banco de dados devem estar apenas no servidor
- Tokens de API devem ser configurados via variáveis de ambiente
- Chaves de assinatura (Android/iOS) devem ser mantidas em local seguro

---

**Desenvolvido com ❤️ usando Flutter e Laravel**
