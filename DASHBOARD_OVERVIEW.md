# 📊 Overview do Dashboard - Symplus Finance

## 🎯 Resumo Executivo

O dashboard do Symplus Finance foi completamente refatorado e evoluído para um **sistema multi-layout, personalizável e inteligente**, com suporte completo a drag & drop, insights automáticos, e persistência de layouts. Todas as correções de layout foram implementadas, garantindo uma experiência fluida no Flutter Web.

---

## 📁 Estrutura de Arquivos

### **Data Layer (Modelos e Serviços)**

#### Modelos (`data/models/`)
- **`dashboard_widget.dart`**: Modelo genérico de widget do dashboard
  - `DashboardWidget`: Representa um widget configurável (id, type, defaultSpan, defaultOrder, visible, metadata)
  - `DashboardView`: Enum com 3 visões (cash, result, collection)

- **`dashboard_layout.dart`**: Modelo de layout completo
  - `DashboardLayout`: Representa um layout completo (id, view, widgets, isTemplate, updatedAt)
  - `DashboardInsight`: Modelo de insights automáticos (widgetId, type, message, icon)

- **`dashboard_data.dart`**: Modelo de dados do dashboard (já existente)

#### Serviços (`data/services/`)
- **`dashboard_service.dart`**: Serviço principal para buscar dados do dashboard (já existente)
- **`dashboard_layout_service.dart`**: **NOVO** - Gerencia layouts e templates
  - `getLayout()`: Busca layout salvo do usuário (com fallback automático para template em caso de 404)
  - `saveLayout()`: Salva layout personalizado
  - `getTemplates()`: Busca templates disponíveis do backend
  - `getTemplate()`: Busca template específico para uma visão
  - `getDefaultTemplate()`: Template local padrão (fallback se backend não disponível)
  
- **`dashboard_insights_service.dart`**: **NOVO** - Busca insights automáticos
  - `getInsights()`: Retorna insights baseados em dados consolidados

### **Presentation Layer (UI e Estado)**

#### Providers (`presentation/providers/`)
- **`dashboard_layout_provider.dart`**: Provider antigo (compatibilidade) - gerencia ordem de widgets
- **`dashboard_view_provider.dart`**: **NOVO** - Gerencia visão selecionada e layout atual
  - `DashboardViewState`: Estado com selectedView, currentLayout, isLoading, error
  - `DashboardViewNotifier`: Carrega e salva layouts, gerencia mudanças de visão

#### Widgets (`presentation/widgets/`)
- **`kpi_main_card.dart`**: Cards principais de KPI (refatorado)
  - Cards compactos com padding reduzido
  - Exibe valor principal, mês anterior, variação percentual
  - Suporte a insights automáticos
  - Botão [Detalhes] para navegação filtrada

- **`reorderable_dashboard_grid.dart`**: **NOVO** - Grid responsivo e reordenável
  - Mobile: `ReorderableListView` (scroll vertical)
  - Desktop/Tablet: `SingleChildScrollView` + `Column` com linhas responsivas
  - Suporta 1, 2 ou 3 colunas baseado na largura da tela
  - Usa `Expanded` dentro de `Row` para evitar overflow

- **`draggable_dashboard_item.dart`**: Wrapper para tornar widgets arrastáveis
  - Adiciona drag handle visual
  - Feedback durante drag operations

- **`dashboard_view_selector.dart`**: **NOVO** - Seletor de visão do dashboard
  - Desktop: `SegmentedButton`
  - Mobile: `DropdownButton`

- **`dashboard_charts.dart`**: Gráficos (já existente)
- **`quarterly_summary.dart`**: Resumo trimestral (já existente)
- **`due_items_calendar.dart`**: Calendário de vencimentos (já existente)
- **`kpi_card.dart`**: Card de KPI simples (já existente)

#### Pages (`presentation/pages/`)
- **`dashboard_page.dart`**: Página principal do dashboard (refatorada)
  - Integra todos os widgets em um sistema reordenável
  - Suporta múltiplas visões (Caixa, Resultado, Cobrança)
  - Carrega insights e exibe nos cards
  - Widget de alertas recentes unificado

- **`dashboard_details_page.dart`**: Página de detalhes filtrados (já existente)

---

## ✨ Funcionalidades Implementadas

### 1. **Sistema Multi-Layout**

#### Visões Disponíveis
- **Visão Caixa** (`cash`): Foco em saldos, fluxo diário, alertas e calendário
- **Visão Resultado** (`result`): Foco em P&L, categorias, indicadores e gráficos
- **Visão Cobrança** (`collection`): Foco em itens vencidos, próximos vencimentos, inadimplência

#### Templates Pré-definidos
Cada visão possui um template padrão definido no backend (`/api/dashboard/templates`):

**Visão Caixa:**
1. KPIs principais (Entrada, Saída, Resultado, Percentual)
2. Saldos das Contas
3. Gráfico de Fluxo de Caixa
4. Alertas Recentes
5. Calendário

**Visão Resultado:**
1. KPIs principais
2. Indicadores Personalizados
3. Gráficos P&L
4. Gráficos de Categorias
5. Resumo Trimestral

**Visão Cobrança:**
1. KPIs de Cobrança
2. Alertas Recentes
3. Calendário

### 2. **Drag & Drop Personalizável**

- ✅ Todos os widgets são arrastáveis e reordenáveis
- ✅ Persistência local (SharedPreferences) para compatibilidade
- ✅ Persistência no backend (`PUT /api/dashboard/layout`)
- ✅ Suporte a mobile (vertical) e desktop (grid responsivo)
- ✅ Feedback visual durante drag operations
- ✅ Drag handles visíveis nos widgets

### 3. **Insights Automáticos**

- ✅ Endpoint backend: `GET /api/dashboard/insights`
- ✅ Insights exibidos nos cards principais de KPI
- ✅ Suporte a diferentes tipos: `success`, `warning`, `error`, `info`
- ✅ Ícones dinâmicos baseados no tipo
- ✅ Fallback gracioso se API não disponível

### 4. **Alertas Recentes Unificados**

- ✅ Widget único que consolida:
  - Itens vencidos
  - Próximos vencimentos
  - Alertas de metas/limites
- ✅ Links para páginas de Due Items e Notificações
- ✅ Integrado ao sistema de layout (participa do drag & drop)
- ✅ Posicionado acima do calendário por padrão

### 5. **Persistência de Sessão**

- ✅ Token, userId, organizationId salvos em `StorageService`
- ✅ Restauração automática na inicialização
- ✅ Validação via `/api/me` ao restaurar sessão
- ✅ Tratamento elegante de 401 (logout automático com mensagem)
- ✅ Sessão mantida ao recarregar página

### 6. **Cards Compactos e Responsivos**

- ✅ Padding reduzido (10-12px em vez de 20px)
- ✅ Ícones menores (16px em vez de 24px)
- ✅ Tipografia ajustada (22px para valores principais)
- ✅ Layout 2x2 em desktop, 1x4 em mobile
- ✅ Aspect ratio 2.2 para cards mais baixos

---

## 🔧 Correções de Layout Implementadas

### Problemas Resolvidos

1. **NavigationRail Overflow (24px)**
   - ✅ Removido `trailing` do NavigationRail
   - ✅ Avatar e logout movidos para AppBar

2. **RenderFlex com Constraints Não Limitadas**
   - ✅ Removido `Expanded`/`Flexible` de contextos sem constraints válidas
   - ✅ Substituído por `Wrap` ou `SizedBox` com largura calculada
   - ✅ `kpi_main_card.dart`: `Row` com `Expanded` → `Wrap` com spacing

3. **SliverGrid com childAspectRatio Fixo**
   - ✅ Substituído por `SingleChildScrollView` + `Column` + `Row` com `Expanded`
   - ✅ Cálculo dinâmico de colunas baseado na largura

4. **Overflow em Charts Section**
   - ✅ Substituído `Flexible` por `SizedBox` com largura calculada (2/3 e 1/3)

5. **Overflow de 16px no Grid**
   - ✅ Usado `Expanded` dentro de `Row` para distribuição automática
   - ✅ Adicionado `ConstrainedBox` para garantir largura limitada

---

## 🌐 Integração com Backend

### Endpoints Utilizados

#### Dashboard Data
- `GET /api/dashboard?from={date}&to={date}`: Dados principais do dashboard
- `GET /api/dashboard/insights?from={date}&to={date}`: Insights automáticos

#### Layouts e Templates
- `GET /api/dashboard/layout?view={view}`: Layout salvo do usuário (404 → fallback para template)
- `PUT /api/dashboard/layout`: Salva layout personalizado
- `GET /api/dashboard/templates`: Lista de templates disponíveis

#### Outros
- `GET /api/custom-indicators`: Indicadores personalizados
- `GET /api/transactions`: Transações recentes
- `GET /api/me`: Validação de sessão

---

## 📱 Responsividade

### Breakpoints
- **Mobile**: < 768px → 1 coluna, lista vertical
- **Tablet**: 768px - 1200px → 2 colunas
- **Desktop**: > 1200px → 3 colunas

### Adaptações
- Cards KPI: Grid 2x2 (desktop) → Lista vertical (mobile)
- Charts: Row horizontal (desktop) → Column vertical (mobile)
- View Selector: SegmentedButton (desktop) → Dropdown (mobile)

---

## 🔐 Segurança e Permissões

- ✅ RBAC respeitado em todos os widgets
- ✅ Widgets ocultos baseados em permissões do usuário
- ✅ Validação de permissões antes de exibir dados sensíveis
- ✅ Logs de telemetria para acesso negado

---

## 🎨 Design e UX

### Cards Principais (KPI)
- Bordas suaves com cor temática
- Ícone discreto no canto superior esquerdo
- Valor principal em destaque
- Linha de "Mês anterior" com variação percentual
- Badge de insight (se disponível)
- Botão [Detalhes] compacto

### Layout Geral
- Espaçamento consistente (16px entre widgets)
- Padding responsivo (maior em desktop, menor em mobile)
- Scroll suave e performático
- Feedback visual durante interações

---

## 🧪 Testes e Qualidade

### Checklist de Testes (Web - Chrome)

#### Layout e Responsividade
- [x] Dashboard carrega sem erros de layout
- [x] Cards exibidos corretamente em desktop (3 colunas)
- [x] Cards exibidos corretamente em tablet (2 colunas)
- [x] Cards exibidos corretamente em mobile (1 coluna)
- [x] Sem overflow amarelo nos cards
- [x] Sem erros de "RenderFlex children have non-zero flex"
- [x] Sem erros de "Cannot hit test a render box with no size"

#### Funcionalidades
- [x] Seletor de visão funciona (Caixa/Resultado/Cobrança)
- [x] Layout muda ao trocar de visão
- [x] Drag & drop funciona (mobile e desktop)
- [x] Ordem persiste após recarregar página
- [x] Insights aparecem nos cards principais
- [x] Alertas recentes exibidos corretamente
- [x] Fallback para template quando layout não encontrado (404)

#### Sessão
- [x] Login mantido após recarregar página
- [x] Logout limpa sessão corretamente
- [x] Redirecionamento elegante em caso de 401

---

## 📊 Widgets Disponíveis

### Widgets Implementados

1. **`kpi_cards`**: Grupo de 4 cards principais (Entrada, Saída, Resultado, Percentual)
2. **`custom_indicators`**: Indicadores personalizados do usuário
3. **`quarterly_summary`**: Resumo trimestral de receitas/despesas
4. **`charts`**: Gráficos de P&L e categorias
5. **`alerts_recent`**: Alertas unificados (vencidos + próximos vencimentos)
6. **`recent_transactions`**: Lista de transações recentes
7. **`account_balances`**: Saldos das contas
8. **`calendar`**: Calendário com due items e transações

### Identificadores de Widgets

Cada widget possui um ID único usado para:
- Identificação no layout
- Ordenação
- Associação de insights
- Persistência de ordem

---

## 🔄 Fluxo de Dados

### Carregamento Inicial

1. Usuário acessa `/app/dashboard`
2. `DashboardViewProvider` carrega visão salva (ou padrão: `cash`)
3. Tenta buscar layout salvo via `GET /api/dashboard/layout?view={view}`
4. Se 404 → Busca template via `GET /api/dashboard/templates`
5. Se falhar → Usa template local padrão
6. `DashboardPage` carrega dados via `GET /api/dashboard`
7. Carrega insights via `GET /api/dashboard/insights`
8. Renderiza widgets na ordem do layout

### Salvamento de Layout

1. Usuário reordena widgets via drag & drop
2. `ReorderableDashboardGrid` chama `onLayoutChanged`
3. `DashboardViewProvider.updateWidgetOrder()` atualiza ordem
4. `DashboardLayoutService.saveLayout()` salva no backend
5. Layout persistido para usuário/organização/visão

---

## 🚀 Melhorias Futuras (Preparado)

### Extensibilidade
- ✅ Modelo `DashboardWidget` com `metadata` para extensões
- ✅ Sistema de templates preparado para novos widgets
- ✅ Service de insights preparado para novos tipos

### Possíveis Evoluções
- Widgets customizáveis pelo usuário
- Mais visões de dashboard
- Widgets condicionais baseados em regras de negócio
- Exportação/importação de layouts
- Layouts compartilhados entre usuários da organização

---

## 📝 Notas Técnicas

### Dependências Adicionadas
- `reorderable_grid_view: ^2.0.6` (não usado no final, mas disponível)

### Padrões Mantidos
- ✅ Riverpod para gerenciamento de estado
- ✅ GoRouter para navegação
- ✅ Dio para chamadas HTTP
- ✅ ResponsiveUtils para breakpoints
- ✅ TelemetryService para logs
- ✅ RBAC e permissões
- ✅ Acessibilidade (Semantics, Tooltips)

### Performance
- ✅ Lazy loading de widgets quando possível
- ✅ Memoização de dados via providers
- ✅ Scroll otimizado com `SingleChildScrollView`
- ✅ Build otimizado (evita rebuilds desnecessários)

---

## 🐛 Problemas Conhecidos e Soluções

### Resolvidos
1. ✅ NavigationRail overflow → Removido trailing
2. ✅ RenderFlex unbounded constraints → Substituído por Wrap/SizedBox
3. ✅ SliverGrid constraints → Substituído por Column/Row responsivo
4. ✅ Overflow de 16px → Usado Expanded dentro de Row
5. ✅ 404 de layout → Fallback automático para template
6. ✅ Sessão não persistia → Implementado restore completo
7. ✅ Cards muito grandes → Reduzido padding e fontes

---

## 📚 Documentação de Referência

### Arquivos Principais Modificados/Criados

**Novos:**
- `app/lib/features/dashboard/data/models/dashboard_widget.dart`
- `app/lib/features/dashboard/data/models/dashboard_layout.dart`
- `app/lib/features/dashboard/data/services/dashboard_layout_service.dart`
- `app/lib/features/dashboard/data/services/dashboard_insights_service.dart`
- `app/lib/features/dashboard/presentation/providers/dashboard_view_provider.dart`
- `app/lib/features/dashboard/presentation/widgets/dashboard_view_selector.dart`
- `app/lib/features/dashboard/presentation/widgets/reorderable_dashboard_grid.dart`
- `app/lib/features/dashboard/presentation/widgets/draggable_dashboard_item.dart`
- `app/lib/core/auth/auth_session_handler.dart`

**Modificados:**
- `app/lib/features/dashboard/presentation/pages/dashboard_page.dart`
- `app/lib/features/dashboard/presentation/widgets/kpi_main_card.dart`
- `app/lib/core/navigation/app_shell.dart`
- `app/lib/core/auth/auth_provider.dart`
- `app/lib/core/storage/storage_service.dart`
- `app/lib/core/network/dio_client.dart`
- `app/lib/config/api_config.dart`
- `app/lib/config/router.dart`
- `app/lib/app.dart`

**Backend (Laravel):**
- `backend/app/Http/Controllers/Api/DashboardController.php` (novos métodos)
- `backend/routes/api.php` (novas rotas)

---

## ✅ Status Atual

### Funcionalidades Completas
- ✅ Sistema multi-layout com 3 visões
- ✅ Drag & drop funcional
- ✅ Persistência de layouts (local + backend)
- ✅ Insights automáticos
- ✅ Alertas recentes unificados
- ✅ Cards compactos e responsivos
- ✅ Sessão persistente
- ✅ Fallback para templates
- ✅ Correções de layout (sem overflow)

### Pronto para Produção
- ✅ Sem erros de compilação
- ✅ Sem erros de layout no console
- ✅ Responsivo em todos os breakpoints
- ✅ Integração com backend funcional
- ✅ Tratamento de erros implementado

---

## 🎯 Próximos Passos Sugeridos

1. **Testes Automatizados**: Adicionar testes unitários para providers e serviços
2. **Otimizações**: Implementar cache de layouts e insights
3. **UX**: Adicionar animações suaves durante drag & drop
4. **Features**: Permitir ocultar/exibir widgets individualmente
5. **Analytics**: Adicionar telemetria para uso de layouts e visões

---

**Última atualização**: 2025-11-24  
**Versão**: 2.0.0 (Dashboard Multi-Layout)

