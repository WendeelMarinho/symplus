# Symplus Finance

Plataforma completa de gestão financeira multi-tenant.

## 📚 Documentação

### Documentação Principal
- **[DEPLOY.md](./DEPLOY.md)** - Guia técnico de deploy para produção
- **[PROMPT_IA.md](./PROMPT_IA.md)** - Prompt direto para IA fazer deploy
- **[REBUILD_FLUTTER_WEB.md](./REBUILD_FLUTTER_WEB.md)** - Instruções para rebuild do Flutter Web
- `docs/` - Documentação geral
- `backend/README.md` - Documentação do backend
- `app/README.md` - Documentação do app Flutter

## 🚀 Quick Start

Ver `docs/QUICK_START.md` para instruções de setup.

## 🚀 Deploy para Produção

**Guia completo:** [DEPLOY.md](./DEPLOY.md)  
**Prompt para IA:** [PROMPT_IA.md](./PROMPT_IA.md)

### Comandos Rápidos

```bash
# 1. Migration
cd backend && docker compose -f docker-compose.prod.yml exec php php artisan migrate

# 2. Build Flutter
cd app && flutter build web --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud --base-href=/app/

# 3. Commit e Push
git add . && git commit -m "feat: Deploy produção" && git push origin main
```

## 📊 Status da Implementação

**Versão:** 1.0.0  
**Status:** ✅ **Pronto para Produção** (95% - aguardando migration do backend)

### Funcionalidades Implementadas (12/12 - 100%)

1. ✅ Dashboard Completo (KPIs, Indicadores, Resumo Trimestral, Calendário, Gráficos)
2. ✅ Filtro Global de Período
3. ✅ 4 KPIs Principais com Detalhes
4. ✅ Indicadores Personalizados (CRUD completo) - ⚠️ Requer migration no backend
5. ✅ Resumo Trimestral
6. ✅ Calendário com Navegação e Modal
7. ✅ Gráficos Responsivos
8. ✅ Upload de Documento em Transações (Obrigatório)
9. ✅ Página de Detalhes da Transação
10. ✅ Sistema de Moeda Global (BRL/USD)
11. ✅ Sistema de Idiomas (PT/EN)
12. ✅ Upload de Avatar/Logo do Usuário

### ✅ Correções Aplicadas

- ✅ Erros de compilação corrigidos
- ✅ Erros de layout e renderização corrigidos
- ✅ Verificações `mounted` adicionadas
- ✅ Código de debug removido (`print()` → `TelemetryService`)
- ✅ Build de produção configurado
- ✅ Scripts de deploy prontos

### Compatibilidade

- ✅ Flutter Web (100% compatível)
- ✅ Mobile (Android/iOS - preparado)
- ✅ Desktop (preparado)
- ✅ Responsividade completa
- ✅ Acessibilidade implementada

## 🏗️ Arquitetura

- **Backend:** Laravel 11 (PHP 8.3)
- **Frontend:** Flutter (Dart)
- **State Management:** Riverpod
- **Routing:** GoRouter
- **Design System:** Material 3

## 📝 Licença

Ver [LICENSE](./LICENSE)
