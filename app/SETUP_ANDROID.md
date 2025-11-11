# Setup Android - Instruções

## Configuração Inicial

A estrutura Android básica foi criada, mas você precisa gerar os ícones e finalizar a configuração.

### 1. Gerar ícones e estrutura completa

Execute o comando do Flutter para gerar tudo automaticamente:

```bash
cd app
flutter create . --platforms=android
```

Isso irá:
- Gerar os ícones do launcher em todas as densidades
- Criar o arquivo `local.properties` automaticamente
- Adicionar qualquer configuração faltante

**Nota:** O Flutter pode sobrescrever alguns arquivos, mas isso é normal e esperado.

### 2. Verificar configuração

```bash
flutter doctor -v
```

Certifique-se de que o Android SDK está configurado corretamente.

### 3. Build do APK

Após a configuração, você pode fazer build:

```bash
# Build APK
flutter build apk

# Build App Bundle (para Play Store)
flutter build appbundle

# Build em modo debug
flutter build apk --debug
```

### 4. Executar no dispositivo/emulador

```bash
# Listar dispositivos disponíveis
flutter devices

# Executar
flutter run
# ou
flutter run -d android
```

## Troubleshooting

### Erro: "Gradle project not supported"

Se você receber este erro após executar `flutter create`, tente:

1. Limpar o projeto:
   ```bash
   flutter clean
   ```

2. Regenerar novamente:
   ```bash
   flutter create . --platforms=android
   ```

3. Executar pub get:
   ```bash
   flutter pub get
   ```

### Erro: "local.properties not found"

O Flutter cria este arquivo automaticamente quando você executa `flutter create` ou `flutter build`. Se ainda não existir:

1. Crie o arquivo `android/local.properties`
2. Adicione:
   ```properties
   sdk.dir=/caminho/para/android/sdk
   flutter.sdk=/caminho/para/flutter/sdk
   ```

   Para descobrir o caminho do Flutter SDK:
   ```bash
   flutter --version
   which flutter
   ```

   Para o Android SDK, geralmente está em:
   - Linux/Mac: `~/Android/Sdk` ou `~/Library/Android/sdk`
   - Windows: `%LOCALAPPDATA%\Android\Sdk`

### Erro: "SDK not found"

1. Instale o Android SDK via Android Studio
2. Configure as variáveis de ambiente:
   ```bash
   export ANDROID_HOME=~/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
   ```

3. Ou adicione ao `local.properties`:
   ```properties
   sdk.dir=/caminho/para/android/sdk
   ```

## Próximos Passos

Após a configuração inicial, você pode:
- Desenvolver normalmente: `flutter run`
- Testar builds: `flutter build apk`
- Configurar assinatura para release (veja documentação do Flutter)

