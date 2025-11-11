# Symplus Finance - Flutter App

Aplicativo mobile do Symplus Finance desenvolvido com Flutter.

## 🚀 Como Rodar

### Pré-requisitos

- Flutter SDK instalado
- Android Studio ou Xcode (para mobile)
- Ou navegador Chrome (para web)

### Instalação Inicial

**⚠️ IMPORTANTE:** Execute primeiro para habilitar suporte web:

```bash
# Habilitar suporte web (execute uma vez)
make setup-web
# ou
flutter create . --platforms=web
```

Depois:

```bash
# Instalar dependências
make install
# ou
flutter pub get
```

### Configuração da API

O app detecta automaticamente a plataforma e configura a URL da API:

- **Web**: `http://localhost:8000` (automático)
- **Android Emulator**: `http://10.0.2.2:8000` (automático)
- **iOS Simulator**: `http://localhost:8000` (automático)
- **Dispositivo Físico**: Configure via `--dart-define` durante o build

**Para Build em Dispositivo Físico Android:**

1. Descubra o IP da sua máquina na rede local:
   ```bash
   # Linux/Mac
   ip addr show | grep "inet " | grep -v 127.0.0.1
   # ou
   ifconfig | grep "inet " | grep -v 127.0.0.1
   
   # Windows
   ipconfig
   ```

2. Faça o build com o IP:
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.100:8000
   ```
   (Substitua `192.168.1.100` pelo IP da sua máquina)

**Ou use o Makefile:**
```bash
make build-android-device
# Ele pedirá o IP interativamente
```

### Executar

**Web (Recomendado para começar):**
```bash
make run-web
# ou
flutter run -d chrome
```

**Android:**
```bash
# Conecte um dispositivo ou inicie emulador primeiro
make run
# ou
flutter run -d android
```

**iOS (apenas macOS):**
```bash
# Abra o Simulator primeiro
make run-ios
# ou
flutter run -d ios
```

## ⚠️ Importante

O app **não está configurado para Linux desktop**. Para executar, use:
- **Web** (Chrome): `flutter run -d chrome`
- **Android**: Conecte dispositivo ou emulador
- **iOS**: Abra Simulator (macOS apenas)

## 📱 Plataformas Suportadas

- ✅ Web (Chrome, Edge, etc.)
- ✅ Android
- ✅ iOS
- ❌ Linux Desktop (não configurado)
- ❌ Windows Desktop (não configurado)
- ❌ macOS Desktop (não configurado)

## 🔧 Comandos Úteis

```bash
# Verificar setup
flutter doctor

# Ver dispositivos disponíveis
flutter devices

# Limpar build
flutter clean

# Atualizar dependências
flutter pub upgrade

# Verificar problemas
flutter analyze
```

## 🌐 Compartilhar App Web

Para compartilhar o app com outras pessoas via Chrome, veja o guia completo:

📖 **[Guia de Compartilhamento](docs/SHARING_WEB_APP.md)**

**Resumo rápido:**

```bash
# Opção 1: Ngrok (testes rápidos) - ⚠️ USE run-web-share!
make run-web-share    # Terminal 1 (prepara app para compartilhar)
make share-ngrok      # Terminal 2 (cria túnel)

# Opção 2: Cloudflare Tunnel (gratuito, ilimitado)
make run-web-share    # Terminal 1
make share-cloudflare # Terminal 2

# Opção 3: Comandos manuais
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080  # Terminal 1
ngrok http 8080                                               # Terminal 2
```

**⚠️ IMPORTANTE:** Use `make run-web-share` ou `--web-hostname=0.0.0.0` para aceitar conexões externas!

Se receber erro **502 Bad Gateway**, veja: **[Troubleshooting Ngrok](docs/TROUBLESHOOTING_NGROK.md)**

## 📚 Estrutura

```
lib/
├── config/           # Configurações (API, router)
├── core/             # Serviços compartilhados
│   ├── network/      # Dio client
│   └── storage/      # Secure storage
└── features/         # Features isoladas
    ├── auth/         # Autenticação
    └── dashboard/    # Dashboard
```

## 🔌 Conectando ao Backend

### Backend Local

1. Certifique-se que o backend está rodando em `http://localhost:8000`
2. Para web: use `localhost:8000`
3. Para Android físico: descubra seu IP e configure em `api_config.dart`

### Descobrir IP Local

**Linux/Mac:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Windows:**
```bash
ipconfig
# Procure "IPv4 Address"
```

## 🐛 Troubleshooting

### "No Linux desktop project configured"

**Solução:** Use web ou mobile:
```bash
flutter run -d chrome  # Web
flutter run -d android # Android
```

### App não conecta ao backend

1. Verifique se backend está rodando
2. Para Android físico, use IP local, não localhost
3. Verifique firewall e rede

### Flutter doctor mostra problemas

```bash
flutter doctor
# Siga as instruções para resolver
```

## 📖 Documentação

- [README Principal](../README.md)
- [Quick Start](../docs/QUICK_START.md)
- [Running Guide](../docs/RUNNING.md)
