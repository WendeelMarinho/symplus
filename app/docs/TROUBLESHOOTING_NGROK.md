# 🔧 Troubleshooting: Erro 502 Bad Gateway no Ngrok

## ❌ Problema: 502 Bad Gateway

O ngrok está funcionando, mas o app Flutter não está respondendo na porta 8080.

## ✅ Soluções

### 1. Verificar se o app está rodando

```bash
# Verificar se algo está ouvindo na porta 8080
lsof -i :8080
# ou
netstat -tulpn | grep 8080
```

Se nada estiver na porta 8080, o app não está rodando.

**Solução:**
```bash
cd app
flutter run -d chrome --web-port=8080
```

### 2. App precisa aceitar conexões externas

Por padrão, o Flutter web pode estar ouvindo apenas em `localhost`, não aceitando conexões externas.

**Solução:**
```bash
cd app
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
```

O `--web-hostname=0.0.0.0` faz o app aceitar conexões de qualquer IP.

### 3. Verificar se o app está realmente acessível

Antes de usar ngrok, teste localmente:

```bash
# Em um terminal, rode o app
cd app
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
```

Em outro terminal, teste:
```bash
curl http://localhost:8080
```

Se não funcionar, há um problema com o app.

### 4. Usar o script helper melhorado

Criei um script que verifica tudo antes de iniciar o ngrok:

```bash
cd app
./scripts/share-app.sh ngrok
```

### 5. Passo a passo completo

```bash
# Terminal 1: Backend (se necessário)
cd backend
make up

# Terminal 2: App Flutter (IMPORTANTE: use --web-hostname=0.0.0.0)
cd app
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080

# Terminal 3: Ngrok
ngrok http 8080
```

### 6. Verificar logs do ngrok

O ngrok tem uma interface web para ver os requests:

Abra: http://127.0.0.1:4040

Lá você pode ver:
- Os requests que estão chegando
- Os erros detalhados
- O que o app está retornando

## 🔍 Diagnóstico

### Teste 1: App responde localmente?

```bash
# Terminal 1
cd app
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080

# Terminal 2
curl http://localhost:8080
```

**Esperado:** Deve retornar HTML do app.

### Teste 2: App responde via IP local?

```bash
# Descubra seu IP
ip addr show | grep "inet " | grep -v 127.0.0.1

# Teste (substitua pelo seu IP)
curl http://192.168.1.100:8080
```

**Esperado:** Deve retornar HTML do app.

Se este teste falhar, o problema é que o app não está aceitando conexões externas. Use `--web-hostname=0.0.0.0`.

### Teste 3: Ngrok consegue acessar?

```bash
# Terminal 1: App
cd app
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080

# Terminal 2: Ngrok
ngrok http 8080

# Terminal 3: Teste a URL do ngrok
curl https://SEU_ID.ngrok-free.app
```

## ⚠️ Problemas Comuns

### Problema: "Connection refused"

**Causa:** App não está rodando ou porta errada.

**Solução:**
```bash
# Verifique se está rodando
lsof -i :8080

# Se não estiver, rode:
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
```

### Problema: "502 Bad Gateway"

**Causa:** App está rodando mas não aceita conexões externas.

**Solução:**
Use `--web-hostname=0.0.0.0`:
```bash
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
```

### Problema: "CORS error" no navegador

**Causa:** Backend não permite requisições do domínio ngrok.

**Solução:** O backend já tem CORS configurado, mas se persistir:
1. Verifique `backend/app/Http/Middleware/CorsMiddleware.php`
2. Certifique-se que permite `*` ou o domínio do ngrok

### Problema: App funciona localmente mas não via ngrok

**Causa:** App está ouvindo apenas em `localhost`.

**Solução:**
```bash
# Use --web-hostname=0.0.0.0
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
```

## 📝 Comando Correto (Resumo)

```bash
# ✅ CORRETO - Aceita conexões externas
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080

# ❌ ERRADO - Só aceita localhost
flutter run -d chrome --web-port=8080
```

## 🎯 Solução Rápida

Execute estes comandos em ordem:

```bash
# 1. Pare qualquer processo na porta 8080
pkill -f "flutter.*8080" || true

# 2. Rode o app aceitando conexões externas
cd app
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080

# 3. Em outro terminal, inicie o ngrok
ngrok http 8080
```

Agora deve funcionar! 🎉

