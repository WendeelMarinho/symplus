# 🧪 QA de Navegação - Checklist de Validação

Este documento contém o checklist completo para validar a navegação, RBAC, responsividade e funcionalidades do app Flutter.

---

## 📋 Checklist Geral

### ✅ 1. Autenticação e Redirecionamento

#### 1.1. Tela de Splash
- [ ] Splash aparece por ~2 segundos
- [ ] Com token salvo: redireciona para `/app/dashboard`
- [ ] Sem token: redireciona para `/login`

#### 1.2. Login
- [ ] Login bem-sucedido redireciona para `/app/dashboard`
- [ ] Login falha mostra mensagem de erro
- [ ] Token e organization ID são salvos

#### 1.3. Logout
- [ ] Botão de logout no AppBar funciona
- [ ] Dialog de confirmação aparece
- [ ] Logout limpa storage e redireciona para `/login`
- [ ] Toast informa logout bem-sucedido

#### 1.4. Proteção de Rotas
- [ ] Acesso direto a `/app/*` sem autenticação redireciona para `/login`
- [ ] Acesso a `/login` estando autenticado redireciona para `/app/dashboard`

---

## 🔐 2. RBAC (Role-Based Access Control)

### 2.1. Papel: Owner
- [ ] **Menu deve mostrar TODAS as seções:**
  - [ ] Dashboard
  - [ ] Contas
  - [ ] Transações
  - [ ] Categorias
  - [ ] Vencimentos
  - [ ] Documentos
  - [ ] Tickets
  - [ ] Notificações
  - [ ] **Assinatura** (apenas Owner/Admin)
  - [ ] Relatórios
  - [ ] Perfil
  - [ ] **Configurações** (apenas Owner)

- [ ] Navegação direta para todas as rotas funciona

### 2.2. Papel: Admin
- [ ] **Menu deve mostrar:**
  - [ ] Dashboard
  - [ ] Contas
  - [ ] Transações
  - [ ] Categorias
  - [ ] Vencimentos
  - [ ] Documentos
  - [ ] Tickets
  - [ ] Notificações
  - [ ] **Assinatura** ✓
  - [ ] Relatórios
  - [ ] Perfil
  - [ ] **Configurações** ❌ (NÃO aparece)

- [ ] Tentativa de acesso direto a `/app/settings` redireciona para dashboard

### 2.3. Papel: User
- [ ] **Menu deve mostrar:**
  - [ ] Dashboard
  - [ ] Contas
  - [ ] Transações
  - [ ] Categorias
  - [ ] Vencimentos
  - [ ] Documentos
  - [ ] Tickets
  - [ ] Notificações
  - [ ] **Assinatura** ❌ (NÃO aparece)
  - [ ] Relatórios
  - [ ] Perfil
  - [ ] **Configurações** ❌ (NÃO aparece)

- [ ] Tentativa de acesso direto a `/app/subscription` redireciona para dashboard
- [ ] Tentativa de acesso direto a `/app/settings` redireciona para dashboard

---

## 📱 3. Navegação e Menu

### 3.1. Desktop (≥1000px)
- [ ] **NavigationRail aparece na lateral esquerda**
  - [ ] Todos os itens permitidos aparecem
  - [ ] Item atual está destacado
  - [ ] Ao clicar em um item, navega para a rota correta
  - [ ] Ícone e label visíveis

- [ ] **AppBar mostra:**
  - [ ] Título da seção atual
  - [ ] Quick Switch (PopupMenu) com todas as seções
  - [ ] Chip com nome da organização
  - [ ] Chip com papel do usuário (PROPRIETÁRIO/ADMINISTRADOR/USUÁRIO)
  - [ ] Botão de logout

### 3.2. Mobile (<1000px)
- [ ] **BottomNavigationBar aparece na parte inferior**
  - [ ] Mostra apenas os 5 primeiros itens permitidos
  - [ ] Item atual está destacado
  - [ ] Ao tocar, navega para a rota correta

- [ ] **Drawer disponível (menu hamburger)**
  - [ ] Mostra itens restantes (além dos 5 do bottom nav)
  - [ ] Header do drawer mostra:
    - [ ] Nome da organização
    - [ ] Nome do usuário
    - [ ] Chip com papel
  - [ ] Lista todos os itens adicionais
  - [ ] Botão de logout no drawer

- [ ] **AppBar mostra:**
  - [ ] Título da seção atual
  - [ ] Subtítulo com nome da organização (se disponível)
  - [ ] Botão de menu rápido (abre BottomSheet)
  - [ ] Botão de logout

### 3.3. Quick Switch
- [ ] **Desktop:**
  - [ ] PopupMenuButton mostra todas as seções permitidas
  - [ ] Seção atual marcada com check e destaque
  - [ ] Seleção navega corretamente

- [ ] **Mobile:**
  - [ ] Botão de menu no AppBar abre BottomSheet
  - [ ] BottomSheet lista todas as seções permitidas
  - [ ] Seção atual marcada com check e destaque
  - [ ] Seleção navega e fecha o sheet

---

## 🎨 4. Páginas e Layout

### 4.1. Estrutura das Páginas
Todas as 12 páginas devem ter:

- [ ] **PageHeader:**
  - [ ] Título grande e visível
  - [ ] Subtítulo explicativo
  - [ ] Breadcrumbs (ex: "Financeiro / Contas")
  - [ ] Ações no header (filtros, exportar, etc.) quando aplicável

- [ ] **ActionBar:**
  - [ ] Botões principais (ex: "Nova Conta")
  - [ ] Botões secundários (ex: "Filtrar")
  - [ ] Scroll horizontal se necessário

- [ ] **Conteúdo:**
  - [ ] EmptyState quando sem dados
  - [ ] CTA claro no empty state
  - [ ] Sem crashes mesmo sem dados

### 4.2. Páginas Específicas

#### Dashboard
- [ ] Carrega dados da API (se disponível)
- [ ] Mostra loading state durante carregamento
- [ ] Mostra error state em caso de erro
- [ ] Pull-to-refresh funciona
- [ ] Botão de atualizar no header funciona

#### Demais Páginas (Placeholders)
- [ ] Todas abrem sem crash
- [ ] Header, ActionBar e EmptyState aparecem
- [ ] Botões não causam erro (ainda não implementam lógica)

---

## 📐 5. Responsividade

### 5.1. Breakpoints
- [ ] **Mobile (360-599px):**
  - [ ] BottomNavigationBar aparece
  - [ ] Drawer disponível
  - [ ] Componentes não "estouram" lateralmente
  - [ ] Textos têm tamanho adequado (não muito pequenos)
  - [ ] Botões têm tamanho mínimo de toque (48x48)

- [ ] **Tablet (600-999px):**
  - [ ] Ainda usa BottomNavigationBar + Drawer
  - [ ] Layout aproveita melhor o espaço
  - [ ] Padding maior que mobile

- [ ] **Desktop (≥1000px):**
  - [ ] NavigationRail aparece
  - [ ] Conteúdo centralizado com largura máxima (1200px)
  - [ ] Quick Switch via PopupMenu
  - [ ] Informações da org e papel visíveis

### 5.2. Resize Dinâmico
- [ ] Redimensionar janela (web) alterna layout corretamente:
  - [ ] De desktop para mobile: NavigationRail → BottomNav
  - [ ] De mobile para desktop: BottomNav → NavigationRail
- [ ] Sem quebras visuais durante a transição
- [ ] Estado da navegação mantido

### 5.3. Scroll e Overflow
- [ ] Breadcrumbs longos fazem scroll horizontal
- [ ] ActionBar com muitos botões faz scroll horizontal
- [ ] Títulos longos têm ellipsis (não quebram layout)
- [ ] Nenhum componente "estoura" lateralmente

---

## ♿ 6. Acessibilidade

### 6.1. Semântica
- [ ] Todos os ícones têm `semanticLabel`
- [ ] Ícones de navegação indicam estado (selecionado/não selecionado)
- [ ] Textos têm labels semânticos quando necessário
- [ ] Botões têm labels descritivos

### 6.2. Text Scalability
- [ ] Texto escala de 0.8x a 1.5x sem quebrar layout
- [ ] Componentes adaptam-se ao aumento de fonte
- [ ] Não há sobreposição de elementos em fontes grandes

### 6.3. Navegação por Teclado (Desktop Web)
- [ ] Tab navigation funciona
- [ ] Enter/Space ativa botões
- [ ] Focus visível nos elementos interativos

---

## 🔄 7. Estados e Feedback

### 7.1. Estados das Páginas
- [ ] **Loading State:**
  - [ ] Aparece durante carregamento
  - [ ] Mensagem opcional visível

- [ ] **Error State:**
  - [ ] Aparece em caso de erro
  - [ ] Mensagem clara
  - [ ] Botão "Tentar novamente" funciona

- [ ] **Empty State:**
  - [ ] Mensagem explicativa
  - [ ] CTA presente quando aplicável
  - [ ] Ícone grande e visível

### 7.2. Toasts/Snackbars
- [ ] **Toast de Sucesso:**
  - [ ] Cor verde
  - [ ] Ícone de check
  - [ ] Duração apropriada (3s)
  - [ ] Botão "OK" para fechar

- [ ] **Toast de Erro:**
  - [ ] Cor vermelha
  - [ ] Ícone de erro
  - [ ] Duração maior (4s)

- [ ] **Toast de Aviso:**
  - [ ] Cor laranja
  - [ ] Ícone de aviso

- [ ] **Toast de Informação:**
  - [ ] Cor azul
  - [ ] Ícone de informação

### 7.3. Dialogs
- [ ] **ConfirmDialog:**
  - [ ] Aparece para ações destrutivas (logout, exclusão)
  - [ ] Título e mensagem claros
  - [ ] Botões "Cancelar" e "Confirmar" funcionam
  - [ ] Ícone opcional aparece quando fornecido

- [ ] **InfoDialog:**
  - [ ] Mensagem informativa clara
  - [ ] Botão "OK" fecha o dialog

---

## 🎯 8. Fluxos de Navegação

### 8.1. Fluxo Principal
1. [ ] Splash → Login (sem token)
2. [ ] Login → Dashboard (com sucesso)
3. [ ] Dashboard → qualquer seção (via menu)
4. [ ] Qualquer seção → Dashboard (via menu)
5. [ ] Qualquer seção → Logout → Login

### 8.2. Navegação Rápida
1. [ ] Quick Switch desktop: abre popup, seleciona, navega
2. [ ] Quick Switch mobile: abre bottom sheet, seleciona, navega e fecha
3. [ ] BottomNavigationBar: tocar item navega instantaneamente
4. [ ] NavigationRail: clicar item navega instantaneamente
5. [ ] Drawer: tocar item navega e fecha drawer

### 8.3. Navegação Direta (URL)
- [ ] Acesso direto a `/app/dashboard` funciona
- [ ] Acesso direto a `/app/accounts` funciona
- [ ] Acesso direto a rotas proibidas redireciona para dashboard
- [ ] URL na barra de endereços reflete a rota atual

---

## 🔍 9. Validação Visual

### 9.1. Consistência
- [ ] Todas as páginas têm a mesma estrutura (Header → ActionBar → Content)
- [ ] Breadcrumbs seguem padrão consistente
- [ ] Cores e estilos são uniformes
- [ ] Espaçamentos são consistentes

### 9.2. Hierarquia Visual
- [ ] Títulos são maiores que subtítulos
- [ ] Breadcrumbs são menores e mais discretos
- [ ] Ações primárias são mais destacadas que secundárias
- [ ] Estados vazios são visualmente distintos

### 9.3. Cores e Feedback
- [ ] Item atual no menu destacado visualmente
- [ ] Botões hover/active funcionam (web)
- [ ] Cores de toasts são intuitivas (verde=sucesso, vermelho=erro)
- [ ] Estados de erro usam cor vermelha consistentemente

---

## 📝 10. Casos Especiais

### 10.1. Múltiplas Organizações
- [ ] Se usuário tem múltiplas orgs, primeira é selecionada automaticamente
- [ ] Organization ID é salvo corretamente

### 10.2. Mudança de Papel (Teste)
- [ ] Se houver forma de trocar papel (dev mode), menu atualiza imediatamente
- [ ] Rotas proibidas tornam-se acessíveis e vice-versa após troca

### 10.3. Sessão Expirada (Futuro)
- [ ] Quando API retornar 401, logout automático funciona
- [ ] Redireciona para login com mensagem

---

## ✅ Checklist de Validação Rápida

### Teste Mínimo (5 minutos)
1. [ ] Login funciona
2. [ ] Menu mostra itens corretos (Owner/Admin/User)
3. [ ] Navegação entre seções funciona
4. [ ] Layout alterna mobile ↔ desktop
5. [ ] Logout funciona

### Teste Completo (30 minutos)
1. [ ] Todos os itens acima
2. [ ] Testar todas as 12 páginas
3. [ ] Testar todos os 3 papéis (Owner/Admin/User)
4. [ ] Testar em 3 tamanhos de tela (mobile/tablet/desktop)
5. [ ] Testar todos os estados (loading/error/empty)
6. [ ] Testar todos os tipos de toast
7. [ ] Testar dialogs de confirmação
8. [ ] Validar acessibilidade básica

---

## 🐛 Problemas Conhecidos e Limitações

### Limitações Atuais
- ⚠️ **Papel do usuário é mockado** (determinado pelo email temporariamente)
- ⚠️ **Páginas são placeholders** (sem integração com API ainda)
- ⚠️ **Botões de ação não implementam lógica** (apenas UI)

### Próximos Passos
1. Integrar papel real da API após login
2. Implementar lógica real nas páginas
3. Adicionar testes automatizados

---

## 📊 Relatório de QA

**Data de Teste:** _______________  
**Testador:** _______________  
**Ambiente:** Web / Android / iOS  
**Versão:** _______________

### Resultados:
- ✅ Passou
- ⚠️ Passou com ressalvas
- ❌ Falhou

**Observações:**
```
[Anotações do testador]
```

---

**Última atualização:** Janeiro 2025

