# 🌐 Compartilhando o App Web - Guia Completo

Este guia explica várias formas de compartilhar o app Flutter web para que outras pessoas possam acessar via Chrome.

## 📋 Opções Disponíveis

### 1. 🚀 Ngrok (Recomendado para testes rápidos)

**Vantagens:**
- ✅ Setup rápido (2 minutos)
- ✅ HTTPS automático
- ✅ URL pública temporária
- ✅ Gratuito (com limitações)

**Como usar:**

1. **Instalar ngrok:**
   ```bash
   # Linux/Mac
   curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc
   echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
   sudo apt update && sudo apt install ngrok
   
   # Ou via snap
   snap install ngrok
   
   # Ou baixe de: https://ngrok.com/download
   ```

2. **Criar conta e obter token:**
   - Acesse: https://dashboard.ngrok.com/signup
   - Faça login e copie seu authtoken
   - Configure: `ngrok config add-authtoken SEU_TOKEN`

3. **Rodar o app Flutter (IMPORTANTE: use --web-hostname=0.0.0.0):**
   ```bash
   cd app
   flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
   ```
   
   **⚠️ CRÍTICO:** O `--web-hostname=0.0.0.0` é necessário para aceitar conexões externas via ngrok!

4. **Em outro terminal, criar túnel:**
   ```bash
   ngrok http 8080
   ```

5. **Compartilhar a URL:**
   - Ngrok mostrará uma URL como: `https://abc123.ngrok.io`
   - Compartilhe essa URL com quem precisa acessar

**⚠️ Importante:** O backend precisa estar acessível. Se o app usa `localhost:8000`, você também precisa expor o backend:

```bash
# Terminal 1: Backend
cd backend
make up

# Terminal 2: Túnel para backend
ngrok http 8000

# Terminal 3: App Flutter
cd app
flutter run -d chrome --web-port=8080

# Terminal 4: Túnel para app
ngrok http 8080
```

**Ou use o Makefile:**
```bash
cd app
make share-ngrok
```

---

### 2. 🔷 Cloudflare Tunnel (Cloudflared) - Gratuito e Ilimitado

**Vantagens:**
- ✅ Completamente gratuito
- ✅ Sem limite de tempo
- ✅ HTTPS automático
- ✅ Melhor performance que ngrok

**Como usar:**

1. **Instalar cloudflared:**
   ```bash
   # Linux
   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
   chmod +x cloudflared-linux-amd64
   sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
   
   # Ou via snap
   snap install cloudflared
   ```

2. **Rodar o app e criar túnel:**
   ```bash
   # Terminal 1: App Flutter
   cd app
   flutter run -d chrome --web-port=8080
   
   # Terminal 2: Túnel
   cloudflared tunnel --url http://localhost:8080
   ```

3. **Compartilhar a URL gerada**

**Ou use o Makefile:**
```bash
cd app
make share-cloudflare
```

---

### 3. 🌍 localhost.run - Sem instalação

**Vantagens:**
- ✅ Não precisa instalar nada
- ✅ Usa SSH (já vem no Linux/Mac)
- ✅ Gratuito

**Como usar:**

1. **Rodar o app:**
   ```bash
   cd app
   flutter run -d chrome --web-port=8080
   ```

2. **Em outro terminal, criar túnel via SSH:**
   ```bash
   ssh -R 80:localhost:8080 ssh.localhost.run
   ```

3. **Compartilhar a URL mostrada**

---

### 4. 📦 Deploy Permanente (Vercel, Netlify, Firebase)

**Vantagens:**
- ✅ URL permanente
- ✅ HTTPS automático
- ✅ Deploy automático via Git
- ✅ Melhor para produção

#### **Vercel (Recomendado)**

1. **Build do app:**
   ```bash
   cd app
   flutter build web --release
   ```

2. **Instalar Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

3. **Deploy:**
   ```bash
   cd build/web
   vercel --prod
   ```

4. **Configurar backend:**
   - Configure CORS no backend para permitir o domínio Vercel
   - Ou use variáveis de ambiente no Vercel para apontar para API pública

#### **Netlify**

1. **Build:**
   ```bash
   cd app
   flutter build web --release
   ```

2. **Arraste a pasta `build/web` para:** https://app.netlify.com/drop

3. **Ou use CLI:**
   ```bash
   npm i -g netlify-cli
   cd build/web
   netlify deploy --prod
   ```

#### **Firebase Hosting**

1. **Instalar Firebase CLI:**
   ```bash
   npm i -g firebase-tools
   firebase login
   ```

2. **Inicializar:**
   ```bash
   cd app
   firebase init hosting
   # Selecione: build/web como diretório público
   ```

3. **Build e deploy:**
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

---

### 5. 🖥️ Servidor Local (Rede local)

Se a pessoa está na mesma rede (WiFi/escritório):

1. **Descubra seu IP:**
   ```bash
   ip addr show | grep "inet " | grep -v 127.0.0.1
   # Exemplo: 192.168.1.100
   ```

2. **Configure o app para aceitar conexões externas:**
   ```bash
   cd app
   flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
   ```

3. **Compartilhe:**
   - URL: `http://192.168.1.100:8080`
   - ⚠️ Certifique-se que o firewall permite conexões na porta 8080

---

## 🔧 Comandos Makefile

Adicionei comandos no Makefile para facilitar:

```bash
# Ngrok
make share-ngrok

# Cloudflare Tunnel
make share-cloudflare

# Build para deploy
make build-web
```

---

## ⚠️ Considerações Importantes

### 1. **Backend também precisa estar acessível**

Se o app usa `localhost:8000` para a API, o backend também precisa estar exposto:

```bash
# Opção 1: Expor backend também via túnel
ngrok http 8000  # Para backend
ngrok http 8080  # Para app (em outro terminal)

# Opção 2: Configurar app para usar backend público
flutter run -d chrome --dart-define=API_BASE_URL=https://seu-backend.ngrok.io
```

### 2. **CORS no Backend**

Certifique-se que o backend permite requisições do domínio do app:

```php
// backend/app/Http/Middleware/CorsMiddleware.php
// Já deve estar configurado, mas verifique se permite todos os origins
```

### 3. **Segurança**

- ⚠️ Túneis temporários (ngrok, cloudflare) são seguros para testes
- ⚠️ Não use em produção sem autenticação adequada
- ⚠️ URLs públicas podem ser acessadas por qualquer pessoa

### 4. **Performance**

- Túneis gratuitos têm limitações de bandwidth
- Para produção, use deploy permanente (Vercel/Netlify)

---

## 🎯 Qual opção escolher?

| Cenário | Recomendação |
|---------|-------------|
| **Teste rápido (< 2 horas)** | Ngrok |
| **Demonstração (vários dias)** | Cloudflare Tunnel |
| **Compartilhar com equipe (mesma rede)** | Servidor Local |
| **Produção/Staging** | Vercel ou Netlify |
| **Sem instalação** | localhost.run |

---

## 📝 Exemplo Completo: Ngrok

```bash
# Terminal 1: Backend
cd backend
make up

# Terminal 2: Túnel Backend
ngrok http 8000
# Copie a URL: https://abc123.ngrok.io

# Terminal 3: App com backend configurado
cd app
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=https://abc123.ngrok.io

# Terminal 4: Túnel App
ngrok http 8080
# Compartilhe: https://xyz789.ngrok.io
```

---

## 🆘 Troubleshooting

### "Cannot connect to backend"
- Verifique se o backend está rodando
- Verifique se o túnel do backend está ativo
- Configure `API_BASE_URL` no app com a URL do túnel do backend

### "CORS error"
- Verifique `CorsMiddleware.php` no backend
- Adicione o domínio do túnel nas origens permitidas

### "Connection refused"
- Verifique se as portas estão corretas
- Verifique firewall
- Certifique-se que o app está rodando antes de criar o túnel

