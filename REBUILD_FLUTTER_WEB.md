# Instruções para Rebuild do Flutter Web

## Problema Identificado

O build do Flutter Web está desatualizado (último build: 11/11/2025). Todas as novas features implementadas não estão disponíveis na versão web porque o código não foi recompilado.

## Features Implementadas que Precisam do Rebuild

1. ✅ **Filtro de Período Global** - `PeriodFilter` widget e provider
2. ✅ **4 Cards Principais de KPI** - `KpiMainCard` com botão [Detalhes]
3. ✅ **Indicadores Personalizados** - CRUD completo com seção no dashboard
4. ✅ **Resumo Trimestral** - `QuarterlySummary` widget
5. ✅ **Calendário com Transações** - `DueItemsCalendar` com modal ao clicar no dia
6. ✅ **Sistema de Moeda (BRL/USD)** - `CurrencyProvider` e `CurrencyFormatter`
7. ✅ **Sistema de Idiomas (PT/EN)** - `LocaleProvider` e `AppLocalizations`
8. ✅ **Avatar/Logo Upload** - `AvatarProvider` e `UserAvatar` widget

## Correções Aplicadas no Código

1. ✅ Calendário agora usa `CurrencyProvider` para formatação de moeda
2. ✅ Calendário agora usa `AppLocalizations` para textos traduzidos
3. ✅ Calendário convertido para `ConsumerStatefulWidget` para acessar providers

## Como Fazer o Rebuild

### Opção 1: Build Local e Upload

```bash
# 1. No seu ambiente local com Flutter instalado
cd /caminho/para/symplus/app

# 2. Limpar build anterior
flutter clean

# 3. Obter dependências
flutter pub get

# 4. Build para web (com configurações de produção)
flutter build web \
    --release \
    --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
    --base-href=/app/

# 5. Copiar arquivos para o servidor
# Os arquivos estarão em: app/build/web/
# Copiar para: backend/public/app/
cp -r build/web/* ../backend/public/app/
```

### Opção 2: Build no Servidor (se Flutter estiver instalado)

```bash
# 1. No servidor
cd /var/www/symplus/app

# 2. Limpar build anterior
flutter clean

# 3. Obter dependências
flutter pub get

# 4. Build para web (com configurações de produção)
flutter build web \
    --release \
    --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
    --base-href=/app/

# 5. Os arquivos serão gerados em: app/build/web/
# 6. Copiar para: backend/public/app/
cp -r build/web/* ../backend/public/app/
```

### Opção 3: Usar Docker (se disponível)

Se houver um Dockerfile para Flutter Web, usar:

```bash
docker build -t symplus-web ./app
docker run --rm -v $(pwd)/backend/public/app:/output symplus-web
```

## Verificação Pós-Build

Após o rebuild, verificar:

1. ✅ Dashboard carrega com header (organização + avatar)
2. ✅ Filtro de período aparece no topo
3. ✅ 4 cards principais aparecem (Entrada, Saída, Resultado, Percentual)
4. ✅ Botão [Detalhes] em cada card funciona
5. ✅ Indicadores Personalizados aparecem abaixo dos KPIs
6. ✅ Resumo Trimestral aparece abaixo dos indicadores
7. ✅ Calendário aparece na parte inferior
8. ✅ Clicar em um dia no calendário abre modal com transações
9. ✅ Navegação entre meses no calendário funciona
10. ✅ Moeda e idioma são respeitados em todos os componentes

## Arquivos Modificados que Precisam do Rebuild

- `app/lib/core/widgets/period_filter.dart`
- `app/lib/core/providers/period_filter_provider.dart`
- `app/lib/features/dashboard/presentation/widgets/kpi_main_card.dart`
- `app/lib/features/dashboard/presentation/widgets/quarterly_summary.dart`
- `app/lib/features/dashboard/presentation/widgets/due_items_calendar.dart`
- `app/lib/features/dashboard/presentation/widgets/calendar_day_modal.dart`
- `app/lib/features/custom_indicators/**` (todos os arquivos)
- `app/lib/core/providers/currency_provider.dart`
- `app/lib/core/providers/locale_provider.dart`
- `app/lib/core/providers/avatar_provider.dart`
- `app/lib/core/widgets/user_avatar.dart`
- `app/lib/core/l10n/app_localizations.dart`
- `app/lib/app.dart` (configuração de i18n)
- `app/assets/locales/pt.json`
- `app/assets/locales/en.json`

## Notas Importantes

1. **Cache do Navegador**: Após o rebuild, pode ser necessário limpar o cache do navegador (Ctrl+Shift+R ou Cmd+Shift+R)

2. **Service Worker**: O Flutter Web usa service worker. Se houver problemas, verificar:
   - `backend/public/app/flutter_service_worker.js`
   - Limpar cache do service worker no navegador

3. **Assets**: Verificar se os arquivos de tradução estão incluídos:
   - `backend/public/app/assets/locales/pt.json`
   - `backend/public/app/assets/locales/en.json`

4. **Permissões**: Após copiar os arquivos, verificar permissões:
   ```bash
   chmod -R 755 /var/www/symplus/backend/public/app
   ```

## Status Atual

- ✅ Código corrigido e pronto para build
- ✅ Script de build atualizado (removida flag --web-renderer obsoleta)
- ✅ Todas as features implementadas e testadas
- ⏳ Aguardando rebuild do Flutter Web
- ⏳ Features não visíveis até o rebuild ser concluído

## Como Executar o Rebuild

### Opção Recomendada: Usar o Script

```bash
# No diretório raiz do projeto
bash scripts/build_flutter_web.sh
```

O script irá:
1. Limpar builds anteriores
2. Instalar dependências
3. Fazer build de produção
4. Copiar arquivos para `backend/public/app/`
5. Ajustar base-href no index.html

### Verificação Pós-Build

Após executar o build, verifique se os arquivos foram gerados:

```bash
ls -la backend/public/app/
# Deve conter: index.html, main.dart.js, flutter.js, assets/, etc.
```

