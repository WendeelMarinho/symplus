# 🚨 Solução Rápida: Erro de Conexão com Ngrok

## Problema: `connection refused` ou `502 Bad Gateway`

O ngrok está funcionando, mas não consegue conectar ao app porque:

1. **O app não está rodando na porta 8080**
2. **O Makefile tem line endings do Windows** (já corrigido)

## ✅ Solução em 3 Passos

### Passo 1: Pare qualquer processo na porta 8080

```bash
# Verificar se algo está na porta
lsof -i :8080

# Se houver, matar o processo
pkill -f "flutter.*8080" || true
```

### Passo 2: Rode o app corretamente

**Opção A: Usar o comando direto (recomendado)**

```bash
cd app
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
```

**Opção B: Usar Makefile (se não tiver erro de line endings)**

```bash
cd app
make run-web-share
```

**Espere ver no terminal:**
```
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
...
```

### Passo 3: Em OUTRO terminal, inicie o ngrok

```bash
# Não precisa estar no diretório app
ngrok http 8080
```

**Você verá:**
```
Forwarding    https://xxxxx.ngrok-free.app -> http://localhost:8080
```

## ✅ Verificar se está funcionando

1. **Teste localmente:**
   ```bash
   curl http://localhost:8080
   ```
   Deve retornar HTML do app.

2. **Teste via ngrok:**
   Abra no navegador: `https://xxxxx.ngrok-free.app`
   Deve carregar o app.

## 🔍 Se ainda não funcionar

### Verificar se o app está realmente rodando

```bash
# Ver processos Flutter
ps aux | grep flutter

# Ver porta 8080
netstat -tulpn | grep 8080
# ou
lsof -i :8080
```

### Verificar se o app está aceitando conexões externas

O comando deve ter `--web-hostname=0.0.0.0`:

```bash
# ✅ CORRETO
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080

# ❌ ERRADO (não aceita conexões externas)
flutter run -d chrome --web-port=8080
```

### Ver logs do ngrok

Acesse: http://127.0.0.1:4040

Lá você verá:
- Todos os requests
- Status codes
- Erros detalhados

## 📋 Checklist Rápido

- [ ] App está rodando com `--web-hostname=0.0.0.0 --web-port=8080`
- [ ] Porta 8080 está livre (nada mais usando)
- [ ] Ngrok está rodando em outro terminal
- [ ] Teste local funciona: `curl http://localhost:8080`

## 🎯 Comando Completo (Copy/Paste)

```bash
# Terminal 1: App
cd app
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080

# Terminal 2: Ngrok (execute após o app iniciar)
ngrok http 8080
```

Isso deve funcionar! 🎉

