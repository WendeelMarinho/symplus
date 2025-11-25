# Dashboard Multi-Layout - Documentação de Implementação

## 📋 Resumo

Implementação completa de um sistema de dashboard personalizável e multi-layout para o Symplus Finance, permitindo que usuários escolham entre diferentes visões (Caixa, Resultado, Cobrança) e personalizem a ordem dos widgets via drag & drop.

## ✅ Funcionalidades Implementadas

### 1. Ajuste Visual dos Cards Principais
- ✅ Cards mais compactos (altura reduzida, padding menor)
- ✅ Ícones menores (16px) alinhados à esquerda
- ✅ Valor principal em destaque (fontSize: 20-22px)
- ✅ Linha com mês anterior e variação percentual
- ✅ Layout responsivo (2x2 desktop, lista mobile)
- ✅ Botão [Detalhes] mais compacto

### 2. Sistema Multi-Layout
- ✅ Modelos criados: `DashboardWidget`, `DashboardLayout`, `DashboardView`, `DashboardInsight`
- ✅ 3 visões disponíveis: Caixa, Resultado, Cobrança
- ✅ Templates pré-definidos para cada visão
- ✅ Seletor de visão no header (segmented control desktop, dropdown mobile)

### 3. Drag & Drop
- ✅ Reordenação vertical funcional
- ✅ Suporte mobile (ReorderableListView) e desktop (Column com DragTarget)
- ✅ Feedback visual durante arraste
- ✅ Integrado com sistema de layouts

### 4. Persistência de Layout
- ✅ LocalStorage (shared_preferences) para experiência instantânea
- ✅ Backend (endpoints GET/PUT /api/dashboard/layout)
- ✅ Fallback para templates locais se backend indisponível
- ✅ Sincronização automática ao reordenar

### 5. Insights Automáticos
- ✅ Serviço no backend (`/api/dashboard/insights`)
- ✅ Insights exibidos nos cards KPI
- ✅ Cores e ícones por tipo (success/warning/error)
- ✅ Fallback se API indisponível

### 6. Alertas Unificados
- ✅ Widget `alerts_recent` combinando vencidos e próximos vencimentos
- ✅ Posicionado antes do calendário por padrão
- ✅ Links para páginas de Due Items e Notificações
- ✅ Integrado ao sistema de layouts

## 🏗️ Estrutura de Arquivos

### Frontend (Flutter)

```
app/lib/features/dashboard/
├── data/
│   ├── models/
│   │   ├── dashboard_data.dart (existente)
│   │   ├── dashboard_widget.dart (NOVO)
│   │   └── dashboard_layout.dart (NOVO)
│   └── services/
│       ├── dashboard_service.dart (existente)
│       ├── dashboard_layout_service.dart (ATUALIZADO)
│       └── dashboard_insights_service.dart (NOVO)
├── presentation/
│   ├── pages/
│   │   └── dashboard_page.dart (ATUALIZADO)
│   ├── providers/
│   │   ├── dashboard_layout_provider.dart (existente)
│   │   └── dashboard_view_provider.dart (NOVO)
│   └── widgets/
│       ├── kpi_main_card.dart (ATUALIZADO)
│       ├── reorderable_dashboard_grid.dart (ATUALIZADO)
│       └── dashboard_view_selector.dart (NOVO)
```

### Backend (Laravel)

```
backend/app/Http/Controllers/Api/
└── DashboardController.php (ATUALIZADO - novos métodos)

backend/routes/
└── api.php (ATUALIZADO - novas rotas)
```

## 🔌 Endpoints da API

### GET /api/dashboard/layout
Busca o layout salvo do usuário/organização para uma visão específica.

**Query Parameters:**
- `view` (string, opcional): `cash`, `result`, ou `collection`

**Resposta:**
```json
{
  "data": {
    "id": "layout_123",
    "view": "cash",
    "widgets": [...],
    "is_template": false,
    "updated_at": "2025-01-01T00:00:00Z"
  }
}
```

**Status Codes:**
- `200`: Layout encontrado
- `404`: Layout não encontrado (usa template padrão)

### PUT /api/dashboard/layout
Salva o layout personalizado do usuário/organização.

**Body:**
```json
{
  "view": "cash",
  "widgets": [
    {
      "id": "kpi_cards",
      "type": "kpi",
      "default_span": 12,
      "default_order": 1,
      "visible": true
    },
    ...
  ]
}
```

**Resposta:**
```json
{
  "data": {
    "id": "layout_123",
    "view": "cash",
    "widgets": [...],
    "is_template": false,
    "updated_at": "2025-01-01T00:00:00Z"
  }
}
```

### GET /api/dashboard/templates
Lista todos os templates disponíveis.

**Resposta:**
```json
{
  "data": [
    {
      "view": "cash",
      "is_template": true,
      "widgets": [...]
    },
    ...
  ]
}
```

### GET /api/dashboard/insights
Retorna insights automáticos para os widgets do dashboard.

**Query Parameters:**
- `from` (string, opcional): Data inicial (Y-m-d)
- `to` (string, opcional): Data final (Y-m-d)

**Resposta:**
```json
{
  "data": [
    {
      "widget_id": "kpi_income",
      "type": "success",
      "message": "Suas entradas aumentaram 15.3% em relação ao período anterior.",
      "icon": "trending_up"
    },
    ...
  ]
}
```

## 🎨 Templates de Layout

### Visão Caixa
1. KPIs principais (Entrada, Saída, Resultado, Percentual)
2. Saldos de Contas
3. Gráfico de Fluxo de Caixa
4. Alertas Recentes
5. Calendário

### Visão Resultado
1. KPIs principais
2. Indicadores Personalizados
3. Gráficos P&L
4. Gráficos de Categorias
5. Resumo Trimestral

### Visão Cobrança
1. KPIs de Cobrança
2. Alertas Recentes
3. Calendário

## 🧪 Como Testar

### 1. Executar a aplicação
```bash
cd app
flutter run -d chrome
```

### 2. Testes Manuais

#### Teste 1: Seletor de Visão
1. Acesse `/app/dashboard`
2. Verifique se o seletor de visão aparece no header
3. Clique em cada visão (Caixa, Resultado, Cobrança)
4. Verifique se os widgets mudam conforme a visão selecionada

#### Teste 2: Drag & Drop
1. No dashboard, arraste um widget para outra posição
2. Verifique se o feedback visual aparece durante o arraste
3. Solte o widget na nova posição
4. Verifique se a ordem foi atualizada
5. Recarregue a página (F5)
6. Verifique se a ordem foi mantida

#### Teste 3: Insights
1. Verifique se os cards KPI exibem insights (se disponíveis)
2. Verifique se as cores e ícones estão corretos
3. Verifique se o layout não quebra quando não há insights

#### Teste 4: Alertas
1. Verifique se o widget "Alertas Recentes" aparece antes do calendário
2. Verifique se os links funcionam (Due Items, Notificações)
3. Verifique se o widget pode ser reordenado via drag & drop

#### Teste 5: Responsividade
1. Redimensione a janela do navegador
2. Verifique se o layout se adapta corretamente
3. Teste em mobile (DevTools > Toggle device toolbar)

### 3. Checklist de Validação

- [ ] Dashboard abre com layout correto (template + layout salvo)
- [ ] Troca de visão reorganiza os widgets corretamente
- [ ] Drag & drop funciona com mouse, reordenando widgets
- [ ] Atualizar página mantém a ordem configurada
- [ ] Se trocar de organização/usuário, o layout adequado é carregado
- [ ] "Alertas recentes" está acima do calendário (por default)
- [ ] Alertas podem ser reposicionados via drag & drop
- [ ] Insights aparecem nos cards principais sem quebrar o layout
- [ ] Nenhuma exceção é logada no console do navegador
- [ ] Cards principais estão mais compactos
- [ ] Linha de variação aparece nos cards KPI
- [ ] Seletor de visão funciona em desktop e mobile

## 🔧 Configuração

### Frontend
Nenhuma configuração adicional necessária. Os serviços usam os endpoints padrão configurados em `ApiConfig`.

### Backend
Os endpoints estão protegidos pelo middleware `auth:sanctum` e `tenant`, então requerem:
- Token de autenticação válido
- Header `X-Organization-Id`

## 📝 Notas Técnicas

### Compatibilidade
- O sistema mantém compatibilidade com o sistema antigo de ordenação via `dashboardLayoutProvider`
- Se o novo sistema de layouts não estiver disponível, usa fallback para o sistema antigo

### Performance
- Layouts são carregados uma vez por visão e armazenados em memória
- Insights são carregados em paralelo com os dados do dashboard
- Drag & drop não causa rebuilds desnecessários

### Segurança
- Layouts são salvos por usuário/organização
- Validação de widgets no backend antes de salvar
- RBAC continua funcionando (widgets não visíveis não aparecem)

## 🐛 Troubleshooting

### Problema: Dashboard não carrega
- Verifique se o backend está rodando
- Verifique se os endpoints estão acessíveis
- Verifique o console do navegador para erros

### Problema: Drag & drop não funciona
- Verifique se o layout foi carregado corretamente
- Verifique se há widgets disponíveis
- Verifique o console para erros JavaScript

### Problema: Ordem não persiste
- Verifique se o backend está salvando corretamente
- Verifique o localStorage do navegador
- Verifique se há erros de rede

## 🚀 Próximos Passos (Opcional)

1. Adicionar mais widgets ao dashboard
2. Implementar grid responsivo com colunas (2-3 colunas em desktop)
3. Adicionar animações suaves durante reordenação
4. Implementar salvamento automático (debounce)
5. Adicionar preview de templates antes de aplicar
6. Implementar exportação/importação de layouts

