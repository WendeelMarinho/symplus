# Configuração Android

A estrutura Android foi criada manualmente. Se você precisar regenerá-la, execute:

```bash
flutter create . --platforms=android
```

## Configuração do Gradle

O projeto está configurado para:
- **minSdkVersion**: 21 (Android 5.0+)
- **targetSdkVersion**: 34 (Android 14)
- **compileSdkVersion**: 34
- **Gradle**: 8.3
- **Kotlin**: 1.9.0

## local.properties

Antes de fazer build, você precisa criar o arquivo `android/local.properties`:

```properties
sdk.dir=/caminho/para/android/sdk
flutter.sdk=/caminho/para/flutter/sdk
```

O Flutter geralmente cria este arquivo automaticamente, mas se não existir, crie-o manualmente.

## Build

```bash
# Build APK
flutter build apk

# Build App Bundle (para Play Store)
flutter build appbundle

# Build e instala no dispositivo
flutter install
```

## Ícones

Os ícones do launcher precisam ser gerados. Você pode:
1. Usar o Flutter para gerar automaticamente: `flutter create . --platforms=android`
2. Ou criar manualmente os arquivos PNG em `app/src/main/res/mipmap-*/`

