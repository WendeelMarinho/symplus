# Guia de Deploy - Conectando Flutter App à VPS

## 📋 Resumo Executivo

Este guia documenta o processo completo de conexão do app Flutter à API hospedada em `https://srv1113923.hstgr.cloud`, incluindo execução em Chrome (dev), Android, iOS e geração de builds de produção.

---

## ✅ Fase 0 - Compreensão do Projeto

### Arquivos Principais Identificados

- **Entrypoint**: `app/lib/main.dart` → inicializa `SymplusApp`
- **Configuração de Rede**: `app/lib/config/api_config.dart` → define `baseUrl`
- **Cliente HTTP**: `app/lib/core/network/dio_client.dart` → usa `ApiConfig.baseUrl`
- **Camadas de Dados**: `app/lib/features/*/data/services/` → serviços que consomem a API

### Origem da URL Base da API

**Arquivo**: `app/lib/config/api_config.dart`

**Lógica Atual**:
1. **Prioridade 1**: `--dart-define API_BASE_URL=...` (se definido)
2. **Prioridade 2**: Modo release → `https://api.symplus.dev`
3. **Prioridade 3**: Dev Web → `http://localhost:8000`
4. **Prioridade 4**: Dev Android (emulador) → `http://10.0.2.2:8000`
5. **Prioridade 5**: Dev iOS/outros → `http://localhost:8000`

**✅ Conclusão**: O projeto já suporta `--dart-define API_BASE_URL`, então **NÃO é necessário alterar código-fonte**.

---

## ✅ Fase 1 - Checklist do Ambiente Local

### Versões Detectadas

- **Flutter**: 3.32.4 (stable)
- **Dart**: 3.8.1
- **Canal**: stable

### Validação do Certificado HTTPS

**URL da API**: `https://srv1113923.hstgr.cloud`

**Endpoint de Health Check**: `https://srv1113923.hstgr.cloud/api/health`

**Comando para validar**:
```bash
curl -I https://srv1113923.hstgr.cloud/api/health
```

**Resultado esperado**: Status 200 OK

---

## ✅ Fase 2 - Estratégia de Configuração da URL da API

### Estratégia Definida

**Usar `--dart-define API_BASE_URL=https://srv1113923.hstgr.cloud`**

O código já está preparado para ler essa variável em runtime via:
```dart
const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
if (envUrl.isNotEmpty) {
  return envUrl;
}
```

### Como o App Enxerga o Valor

1. `ApiConfig.baseUrl` verifica `String.fromEnvironment('API_BASE_URL')`
2. Se definido, usa esse valor (prioridade máxima)
3. `DioClient` usa `ApiConfig.baseUrl` como `baseUrl` do Dio

**✅ Nenhuma alteração de código necessária!**

---

## ⚠️ Fase 3 - Ajustes no Backend (CORS)

### CORS Atual

**Middleware**: `backend/app/Http/Middleware/CorsMiddleware.php`

**Comportamento Atual**:
- Permite **qualquer origem** (`$allowedOrigin = $origin ?? '*'`)
- Headers permitidos: `Content-Type, Authorization, X-Organization-Id, Accept, X-Requested-With`
- Métodos permitidos: `GET, POST, PUT, DELETE, OPTIONS, PATCH`

### Análise

O middleware atual já aceita qualquer origem, então **deve funcionar para desenvolvimento local** sem alterações.

**⚠️ Para Produção**: Recomenda-se restringir origens específicas.

### Origem de Desenvolvimento do Flutter Web

Quando o Flutter roda em modo web (Chrome), a origem será:
- `http://localhost:<porta>` (geralmente 8080, 5173, 3000)
- `http://127.0.0.1:<porta>`

### Ajuste Proposto (Opcional)

Se quiser restringir CORS apenas para desenvolvimento, podemos adicionar uma lista de origens permitidas baseada em `APP_ENV`:

**Origem de desenvolvimento a liberar**:
- `http://localhost:*` (qualquer porta)
- `http://127.0.0.1:*` (qualquer porta)
- `https://srv1113923.hstgr.cloud` (própria API)

**Aguardando sua confirmação para implementar este ajuste.**

---

## 🚀 Fase 4 - Rodar Flutter no Chrome

### Comando para Executar

```bash
cd app
flutter run -d chrome --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

### Validação

1. Abra o app em `http://localhost:<porta>` (geralmente 8080)
2. Abra o DevTools do Chrome (F12)
3. Verifique no console se há erros de CORS
4. Faça uma chamada de health check à API

### Health Check Manual

No console do navegador:
```javascript
fetch('https://srv1113923.hstgr.cloud/api/health')
  .then(r => r.json())
  .then(console.log)
  .catch(console.error);
```

**Resultado esperado**: `{status: "ok", timestamp: "..."}`

---

## 📱 Fase 5 - Rodar no Android e iOS

### Android

**1. Verificar dispositivos disponíveis**:
```bash
flutter devices
```

**2. Executar no Android**:
```bash
cd app
flutter run -d android --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

**3. Validação**:
- Verificar logs do Flutter para erros de rede
- Testar login ou health check no app

### iOS (apenas macOS)

**1. Verificar dispositivos disponíveis**:
```bash
flutter devices
```

**2. Executar no iOS**:
```bash
cd app
flutter run -d ios --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

**3. Validação**:
- Verificar logs do Flutter para erros de rede
- Testar login ou health check no app

### Possíveis Problemas

**Android - Permissão de Internet**:
- Verificar `app/android/app/src/main/AndroidManifest.xml`
- Deve conter: `<uses-permission android:name="android.permission.INTERNET" />`

**iOS - ATS (App Transport Security)**:
- Verificar `app/ios/Runner/Info.plist`
- HTTPS deve funcionar por padrão, mas pode precisar de exceções para desenvolvimento

---

## 📦 Fase 6 - Builds de Produção

### Android APK

```bash
cd app
flutter build apk --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

**Artefato gerado**: `app/build/app/outputs/flutter-apk/app-release.apk`

### Android AAB (App Bundle)

```bash
cd app
flutter build appbundle --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

**Artefato gerado**: `app/build/app/outputs/bundle/release/app-release.aab`

### iOS (apenas macOS)

```bash
cd app
flutter build ios --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

**Artefato gerado**: `app/build/ios/archive/` (requer Xcode para gerar IPA)

---

## 🌐 Fase 7 - Flutter Web Estático na VPS (Opcional)

### Build Web

```bash
cd app
flutter build web --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

**Artefato gerado**: `app/build/web/`

### Upload para VPS

**Diretório sugerido**: `/var/www/symplus/webapp`

**Comandos**:
```bash
# Na máquina local
cd app/build/web
tar czf webapp.tar.gz *
scp webapp.tar.gz user@srv1113923.hstgr.cloud:/tmp/

# Na VPS
ssh user@srv1113923.hstgr.cloud
sudo mkdir -p /var/www/symplus/webapp
sudo tar xzf /tmp/webapp.tar.gz -C /var/www/symplus/webapp
sudo chown -R www-data:www-data /var/www/symplus/webapp
```

### Configuração Nginx (Plano)

**Host**: `srv1113923.hstgr.cloud` (ou subdomínio)

**Root**: `/var/www/symplus/webapp`

**Configuração proposta**:
```nginx
server {
    listen 80;
    server_name srv1113923.hstgr.cloud;  # ou webapp.srv1113923.hstgr.cloud
    
    root /var/www/symplus/webapp;
    index index.html;
    
    # SPA routing - redirecionar todas as rotas para index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

**⚠️ Aguardando sua autorização antes de aplicar no Nginx.**

---

## ✅ Fase 8 - Validações Finais

### Checklist de Validação

- [ ] Chrome dev consumindo a API sem CORS
- [ ] Android consumindo a API
- [ ] iOS consumindo a API (se disponível)
- [ ] Health check retornando 200 em todas as plataformas
- [ ] Builds de produção gerados com sucesso

### Relatório Final

**Ambiente Local**:
- Flutter: 3.32.4 (stable)
- Dart: 3.8.1
- Devices: (será preenchido após execução)

**Estratégia de URL Base**:
- Variável: `--dart-define API_BASE_URL=https://srv1113923.hstgr.cloud`
- Implementação: Já existente no código (sem alterações necessárias)

**CORS**:
- Status: Permite qualquer origem (funciona para dev)
- Recomendação: Restringir para produção

**Comandos de Execução**:

**Chrome**:
```bash
cd app
flutter run -d chrome --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

**Android**:
```bash
cd app
flutter run -d android --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

**iOS**:
```bash
cd app
flutter run -d ios --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

**Builds**:
```bash
# APK
flutter build apk --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud

# AAB
flutter build appbundle --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud

# iOS
flutter build ios --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud

# Web
flutter build web --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
```

**Artefatos de Build**:
- APK: `app/build/app/outputs/flutter-apk/app-release.apk`
- AAB: `app/build/app/outputs/bundle/release/app-release.aab`
- iOS: `app/build/ios/archive/` (requer Xcode)
- Web: `app/build/web/`

### Próximos Passos Recomendados

1. **CORS em Produção**: Restringir origens permitidas quando o frontend estiver em produção
2. **Play Store**: Preparar metadados, screenshots, descrição para publicação
3. **App Store**: Preparar metadados, screenshots, descrição para publicação
4. **CI/CD**: Automatizar builds com GitHub Actions ou similar
5. **Monitoramento**: Implementar analytics e crash reporting (Firebase, Sentry)

---

## 🔧 Troubleshooting

### Erro de CORS no Chrome

**Sintoma**: `Access-Control-Allow-Origin` error no console

**Solução**: Verificar se o backend está retornando headers CORS corretos. O middleware atual deve permitir qualquer origem.

### Erro de Certificado SSL

**Sintoma**: `CERTIFICATE_VERIFY_FAILED` ou similar

**Solução**: Verificar se o certificado SSL da VPS está válido e confiável.

### App não conecta no Android/iOS

**Sintoma**: Timeout ou erro de rede

**Solução**:
1. Verificar se o dispositivo/emulador tem acesso à internet
2. Verificar se a URL da API está correta
3. Verificar permissões de internet no AndroidManifest.xml (Android)
4. Verificar ATS no Info.plist (iOS)

---

## 📝 Notas Finais

- **Nenhuma alteração de código foi necessária** - o projeto já suporta `--dart-define`
- **CORS está configurado** - permite qualquer origem (funciona para dev)
- **Todos os comandos estão documentados** - prontos para execução
- **Builds estão prontos** - apenas executar os comandos com a URL da VPS

