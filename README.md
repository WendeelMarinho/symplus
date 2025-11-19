# Symplus Finance

Plataforma completa de gestão financeira multi-tenant.

## 📚 Documentação

### Documentação Principal
- **[REBUILD_FLUTTER_WEB.md](./REBUILD_FLUTTER_WEB.md)** - Instruções para rebuild do Flutter Web
- `docs/` - Documentação geral
- `backend/README.md` - Documentação do backend
- `app/README.md` - Documentação do app Flutter

## 🚀 Quick Start

Ver `docs/QUICK_START.md` para instruções de setup.

## 🚀 Deploy para Produção

### 1. Executar Migration (Backend)
```bash
cd backend
make migrate
```

### 2. Build Flutter Web
```bash
bash scripts/build_flutter_web.sh
```

### 3. Push para GitHub
```bash
bash scripts/push_to_github.sh
```

Ver documentação completa em:
- [PRODUCTION_CHECKLIST.md](./PRODUCTION_CHECKLIST.md)
- [NEXT_STEP_MIGRATION.md](./NEXT_STEP_MIGRATION.md)
- [PUSH_TO_GITHUB.md](./PUSH_TO_GITHUB.md)

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
