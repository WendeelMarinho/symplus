# 🌐 Deploy do Flutter Web - Symplus Finance

Este guia explica como fazer o build e deploy do app Flutter Web para produção na VPS.

## 📋 Pré-requisitos

- Flutter SDK instalado (versão 3.0+)
- Acesso SSH à VPS
- Backend Laravel já configurado e funcionando

## 🚀 Passo a Passo

### 1. Build do Flutter Web

Execute o script de build na sua máquina local (ou na VPS se tiver Flutter instalado):

```bash
cd /var/www/symplus
bash scripts/build_flutter_web.sh
```

**O que o script faz:**
- Limpa builds anteriores
- Instala dependências do Flutter
- Faz build de produção com `--release`
- Configura `API_BASE_URL=https://srv1113923.hstgr.cloud`
- Copia arquivos para `backend/public/app/`
- Ajusta `base-href` para `/app/`

### 2. Build Manual (Alternativa)

Se preferir fazer manualmente:

```bash
cd /var/www/symplus/app

# Limpar build anterior
flutter clean

# Instalar dependências
flutter pub get

# Build de produção
flutter build web \
    --release \
    --web-renderer html \
    --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
    --base-href=/app/

# Copiar para diretório de deploy
mkdir -p ../backend/public/app
rm -rf ../backend/public/app/*
cp -r build/web/* ../backend/public/app/
```

### 3. Verificar Configuração do Nginx

O Nginx já está configurado para servir o app em `/app/`. Verifique se o arquivo `backend/nginx/default.conf` contém:

```nginx
# App Flutter Web (SPA)
location /app/ {
    alias /var/www/symplus/backend/public/app/;
    try_files $uri $uri/ /app/index.html;
    
    # Headers para SPA
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;
}
```

### 4. Reiniciar Nginx

Após o build, reinicie o Nginx:

```bash
cd /var/www/symplus/backend
docker compose -f docker-compose.prod.yml restart nginx
```

### 5. Testar

Acesse no navegador:
- **URL:** `https://srv1113923.hstgr.cloud/app/`
- **API:** `https://srv1113923.hstgr.cloud/api/`

## 🔧 Configuração da API

O app Flutter está configurado para usar a URL da API automaticamente:

- **Em produção (release):** `https://srv1113923.hstgr.cloud`
- **Em desenvolvimento:** `http://localhost:8000`

**Arquivo:** `app/lib/config/api_config.dart`

Para usar uma URL customizada, use `--dart-define`:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://sua-api.com
```

## 📁 Estrutura de Arquivos

Após o build, a estrutura será:

```
/var/www/symplus/
├── app/                          # Código fonte Flutter
│   └── build/web/               # Build gerado
└── backend/
    └── public/
        └── app/                  # Arquivos servidos pelo Nginx
            ├── index.html
            ├── main.dart.js
            ├── flutter.js
            └── assets/
```

## 🔄 Atualização do App

Para atualizar o app após mudanças:

1. **Fazer build novamente:**
   ```bash
   bash scripts/build_flutter_web.sh
   ```

2. **Reiniciar Nginx (se necessário):**
   ```bash
   docker compose -f docker-compose.prod.yml restart nginx
   ```

3. **Limpar cache do navegador** (Ctrl+Shift+R ou Cmd+Shift+R)

## 🐛 Troubleshooting

### App não carrega (404)

1. Verifique se os arquivos estão em `backend/public/app/`:
   ```bash
   ls -la /var/www/symplus/backend/public/app/
   ```

2. Verifique logs do Nginx:
   ```bash
   docker compose -f docker-compose.prod.yml logs nginx
   ```

3. Verifique se o Nginx está configurado corretamente:
   ```bash
   cat /var/www/symplus/backend/nginx/default.conf | grep -A 5 "location /app/"
   ```

### Erro de CORS

Se aparecer erro de CORS, verifique se o backend permite requisições de `https://srv1113923.hstgr.cloud`:

```bash
# Verificar config/cors.php
cat /var/www/symplus/backend/config/cors.php
```

O CORS já está configurado para aceitar o domínio de produção.

### App não conecta na API

1. Verifique se a API está funcionando:
   ```bash
   curl https://srv1113923.hstgr.cloud/api/health
   ```

2. Verifique a URL da API no build:
   ```bash
   grep -r "srv1113923" /var/www/symplus/backend/public/app/
   ```

3. Verifique logs do navegador (F12 > Console)

### Build falha

1. Limpe o build:
   ```bash
   cd /var/www/symplus/app
   flutter clean
   flutter pub get
   ```

2. Verifique versão do Flutter:
   ```bash
   flutter --version
   ```

3. Verifique erros:
   ```bash
   flutter doctor
   flutter analyze
   ```

## ✅ Checklist de Deploy

- [ ] Flutter SDK instalado
- [ ] Build de produção gerado
- [ ] Arquivos copiados para `backend/public/app/`
- [ ] Nginx configurado para servir `/app/`
- [ ] Nginx reiniciado
- [ ] App acessível em `https://srv1113923.hstgr.cloud/app/`
- [ ] API funcionando em `https://srv1113923.hstgr.cloud/api/`
- [ ] Login funcionando
- [ ] CORS configurado corretamente

## 📚 Recursos

- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Nginx Configuration](https://nginx.org/en/docs/)
- [CORS Configuration](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

---

**🎉 Seu app web está em produção!**

Acesse: `https://srv1113923.hstgr.cloud/app/`

