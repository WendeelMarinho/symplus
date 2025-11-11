# 📱 Deploy do App Flutter em Produção

Este guia explica como fazer o build e deploy do app Flutter Symplus Finance para produção.

## 🎯 Opções de Deploy

### 1. App Web (Flutter Web)
- **Vercel** (Recomendado) - CDN global, HTTPS automático
- **Netlify** - Similar ao Vercel
- **Firebase Hosting** - Integração com Firebase
- **Nginx na VPS** - Controle total, mesmo servidor da API

### 2. App Mobile (Android/iOS)
- **Google Play Store** (Android)
- **Apple App Store** (iOS)
- **TestFlight** (iOS - beta testing)

---

## 🌐 Deploy do App Web

### Opção 1: Vercel (Recomendado)

#### Pré-requisitos
- Conta no Vercel (gratuita)
- Vercel CLI instalado: `npm i -g vercel`

#### Passos

1. **Build do app:**
```bash
cd app
flutter build web --release --web-renderer html
```

2. **Deploy:**
```bash
cd build/web
vercel --prod
```

3. **Configurar variáveis de ambiente:**
   - No dashboard do Vercel, adicione:
   - `API_BASE_URL=https://api.symplus.dev`

4. **Configurar domínio customizado:**
   - No dashboard do Vercel, vá em Settings > Domains
   - Adicione seu domínio (ex: `app.symplus.dev`)
   - Configure DNS conforme instruções

**Vantagens:**
- ✅ Deploy automático via Git
- ✅ HTTPS automático
- ✅ CDN global
- ✅ Preview de PRs
- ✅ Rollback fácil

#### Deploy Automático via Git

1. Conecte o repositório no Vercel
2. Configure:
   - **Framework Preset**: Other
   - **Build Command**: `cd app && flutter build web --release --web-renderer html`
   - **Output Directory**: `app/build/web`
   - **Install Command**: `cd app && flutter pub get`

### Opção 2: Netlify

#### Passos

1. **Build do app:**
```bash
cd app
flutter build web --release --web-renderer html
```

2. **Criar arquivo `netlify.toml` na raiz do projeto:**
```toml
[build]
  command = "cd app && flutter build web --release --web-renderer html"
  publish = "app/build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

3. **Deploy:**
   - Conecte o repositório no Netlify
   - Ou use CLI: `netlify deploy --prod --dir=app/build/web`

### Opção 3: Nginx na VPS

Veja o guia completo em [DEPLOY_VPS.md](../../docs/DEPLOY_VPS.md#-configuração-do-app-flutter).

**Resumo:**
1. Build: `flutter build web --release --web-renderer html`
2. Copiar para VPS: `scp -r build/web/* usuario@vps:/var/www/symplus/app/build/web`
3. Configurar Nginx (veja guia completo)

---

## 📱 Deploy do App Mobile

### Android (Google Play Store)

#### 1. Preparar App Bundle

```bash
cd app

# Build do App Bundle (formato recomendado pelo Google Play)
flutter build appbundle --release

# Arquivo gerado em:
# app/build/app/outputs/bundle/release/app-release.aab
```

#### 2. Configurar Assinatura

Se ainda não tiver uma keystore:

```bash
# Gerar keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configurar em android/key.properties:
storePassword=sua_senha
keyPassword=sua_senha
keyAlias=upload
storeFile=/caminho/para/upload-keystore.jks
```

#### 3. Configurar build.gradle

Edite `app/android/app/build.gradle` para usar a keystore:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### 4. Upload no Google Play Console

1. Acesse [Google Play Console](https://play.google.com/console)
2. Crie um novo app ou selecione existente
3. Vá em **Production** > **Create new release**
4. Faça upload do arquivo `.aab`
5. Preencha as informações de release
6. Revise e publique

### iOS (Apple App Store)

#### 1. Pré-requisitos

- Mac com Xcode instalado
- Conta de desenvolvedor Apple ($99/ano)
- Certificados e provisioning profiles configurados

#### 2. Build do App

```bash
cd app

# Build para iOS
flutter build ios --release

# Abrir no Xcode
open ios/Runner.xcworkspace
```

#### 3. Configurar no Xcode

1. Selecione o target **Runner**
2. Vá em **Signing & Capabilities**
3. Selecione seu **Team**
4. Xcode gerará automaticamente os certificados

#### 4. Archive e Upload

1. No Xcode: **Product** > **Archive**
2. Após o archive, abra o **Organizer**
3. Selecione o archive e clique em **Distribute App**
4. Escolha **App Store Connect**
5. Siga o assistente
6. Ou use CLI:

```bash
# Upload via CLI (requer app-specific password)
flutter build ipa --release
# Depois use Transporter ou Xcode
```

#### 5. TestFlight (Beta Testing)

1. Após upload, vá em [App Store Connect](https://appstoreconnect.apple.com)
2. Selecione seu app
3. Vá em **TestFlight**
4. Adicione testadores internos ou externos

---

## ⚙️ Configuração da API para Produção

### Atualizar URL da API

O app já está configurado para usar a URL de produção automaticamente quando compilado em modo release.

**Arquivo:** `app/lib/config/api_config.dart`

```dart
// Em modo release, usa automaticamente:
return 'https://api.symplus.dev';
```

### Para usar URL customizada:

```bash
# Build com URL customizada
flutter build web --release --dart-define=API_BASE_URL=https://sua-api.com
```

### Configurar CORS no Backend

Certifique-se de que o backend permite requisições do domínio do app:

**Arquivo:** `backend/config/cors.php` (Laravel)

```php
'paths' => ['api/*', 'sanctum/csrf-cookie'],

'allowed_methods' => ['*'],

'allowed_origins' => [
    'https://app.symplus.dev',
    'https://symplus.vercel.app',
],

'allowed_origins_patterns' => [],

'allowed_headers' => ['*'],

'exposed_headers' => [],

'max_age' => 0,

'supports_credentials' => true,
```

---

## 🔐 Variáveis de Ambiente

### Para Web (Vercel/Netlify)

Configure no dashboard:
- `API_BASE_URL` - URL da API (opcional, já tem padrão)

### Para Mobile

Use `--dart-define` no build:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.symplus.dev
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.symplus.dev
flutter build ios --release --dart-define=API_BASE_URL=https://api.symplus.dev
```

---

## 📊 Monitoramento

### Analytics

Considere adicionar:
- **Firebase Analytics** - Análise de uso
- **Sentry** - Rastreamento de erros
- **Mixpanel** - Analytics avançado

### Performance

- Use `flutter build web --release` (não debug)
- Habilite tree-shaking
- Otimize imagens
- Use lazy loading

---

## ✅ Checklist de Deploy

### App Web
- [ ] Build de produção gerado
- [ ] URL da API configurada
- [ ] CORS configurado no backend
- [ ] Deploy realizado (Vercel/Netlify/Nginx)
- [ ] Domínio configurado
- [ ] SSL/HTTPS funcionando
- [ ] Testes de funcionalidades básicas

### App Mobile
- [ ] Keystore configurado (Android)
- [ ] Certificados iOS configurados
- [ ] Build de produção gerado
- [ ] URL da API configurada
- [ ] Testado em dispositivos reais
- [ ] Upload realizado
- [ ] Testes internos (TestFlight/Internal Testing)
- [ ] Publicação na loja

---

## 🐛 Troubleshooting

### App não conecta na API

1. Verifique URL da API no código
2. Verifique CORS no backend
3. Verifique se API está acessível
4. Verifique logs do navegador/dispositivo

### Build falha

1. Limpe o build: `flutter clean`
2. Atualize dependências: `flutter pub get`
3. Verifique versão do Flutter: `flutter --version`
4. Verifique erros: `flutter doctor`

### Erro de assinatura (Android)

1. Verifique se `key.properties` existe
2. Verifique senhas da keystore
3. Verifique caminho da keystore

### Erro de certificado (iOS)

1. Verifique certificados no Keychain
2. Verifique provisioning profiles
3. Limpe build: `flutter clean && cd ios && pod deintegrate && pod install`

---

## 📚 Recursos

- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)
- [iOS App Distribution](https://developer.apple.com/distribute/)
- [Vercel Documentation](https://vercel.com/docs)
- [Netlify Documentation](https://docs.netlify.com/)

---

**🎉 Seu app está em produção!**

Para suporte, consulte a documentação principal ou abra uma issue no GitHub.

