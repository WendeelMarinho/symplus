# 🔧 Troubleshooting CORS - Flutter Web

## Problema: "XMLHttpRequest onError" ao tentar conectar com a API

Este erro indica que o navegador está bloqueando a requisição antes mesmo de chegar ao servidor, geralmente por problemas de CORS.

## 🔍 Diagnóstico Rápido

### 1. Teste direto no Console do Navegador

Abra o DevTools (F12) e execute:

```javascript
// Teste 1: Health check simples
fetch('https://srv1113923.hstgr.cloud/api/health', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
})
.then(r => {
  console.log('✅ Status:', r.status);
  console.log('✅ Headers CORS:', {
    'Access-Control-Allow-Origin': r.headers.get('Access-Control-Allow-Origin'),
    'Access-Control-Allow-Methods': r.headers.get('Access-Control-Allow-Methods'),
    'Access-Control-Allow-Headers': r.headers.get('Access-Control-Allow-Headers')
  });
  return r.json();
})
.then(data => console.log('✅ Data:', data))
.catch(err => {
  console.error('❌ Erro:', err);
  console.error('   Isso indica problema de CORS ou rede');
});

// Teste 2: Preflight OPTIONS
fetch('https://srv1113923.hstgr.cloud/api/auth/login', {
  method: 'OPTIONS',
  headers: {
    'Origin': window.location.origin,
    'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'content-type,authorization'
  }
})
.then(r => {
  console.log('✅ Preflight Status:', r.status);
  console.log('✅ Preflight Headers:', {
    'Access-Control-Allow-Origin': r.headers.get('Access-Control-Allow-Origin'),
    'Access-Control-Allow-Methods': r.headers.get('Access-Control-Allow-Methods'),
    'Access-Control-Allow-Headers': r.headers.get('Access-Control-Allow-Headers')
  });
})
.catch(err => console.error('❌ Preflight Error:', err));
```

### 2. Verificar no Network Tab

1. Abra o DevTools (F12)
2. Vá na aba **Network**
3. Tente fazer login
4. Procure pela requisição `POST /api/auth/login`
5. Verifique:
   - **Status**: Se é `(failed)` ou `CORS error`
   - **Headers**: Se há headers CORS na resposta
   - **Request Headers**: Se o `Origin` está sendo enviado

### 3. Verificar se o Backend está Aplicando CORS

No servidor (VPS), execute:

```bash
# Testar preflight OPTIONS
curl -v -X OPTIONS https://srv1113923.hstgr.cloud/api/auth/login \
  -H "Origin: http://localhost:39801" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type,authorization"

# Verificar se retorna:
# Access-Control-Allow-Origin: http://localhost:39801
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
# Access-Control-Allow-Headers: Content-Type, Authorization, X-Organization-Id, Accept, X-Requested-With
```

## 🔧 Soluções

### Solução 1: Verificar se o Middleware CORS está Aplicado

No backend, verifique se o `CorsMiddleware` está sendo executado:

1. **Arquivo**: `backend/bootstrap/app.php`
   - Deve ter: `\App\Http\Middleware\CorsMiddleware::class` no array `api(prepend: [...])`

2. **Limpar cache do Laravel**:
```bash
cd backend
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan optimize:clear
```

3. **Reiniciar o servidor** (se estiver usando PHP-FPM):
```bash
sudo systemctl restart php8.3-fpm  # ou a versão do seu PHP
# Ou se estiver usando Docker:
docker-compose restart
```

### Solução 2: Verificar Configuração do Nginx (se aplicável)

Se estiver usando Nginx como proxy reverso, verifique se não está bloqueando headers CORS:

```nginx
location /api {
    # Permitir headers CORS
    add_header 'Access-Control-Allow-Origin' $http_origin always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Organization-Id, Accept, X-Requested-With' always;
    
    # Tratar preflight
    if ($request_method = 'OPTIONS') {
        return 204;
    }
    
    # Proxy para PHP-FPM
    fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    # ... resto da configuração
}
```

**⚠️ IMPORTANTE**: Se o Laravel já está adicionando headers CORS, não adicione no Nginx também (pode causar duplicação).

### Solução 3: Verificar Certificado SSL

Se o certificado SSL estiver inválido ou expirado, o navegador pode bloquear:

```bash
# Verificar certificado
openssl s_client -connect srv1113923.hstgr.cloud:443 -servername srv1113923.hstgr.cloud
```

### Solução 4: Testar com CORS Desabilitado (Temporário)

Para testar se é realmente CORS, você pode temporariamente permitir todas as origens no backend:

```php
// backend/app/Http/Middleware/CorsMiddleware.php
$allowedOrigin = '*'; // TEMPORÁRIO - apenas para teste
```

**⚠️ NÃO use isso em produção!**

## 📋 Checklist

- [ ] Middleware CORS está registrado em `bootstrap/app.php`
- [ ] Cache do Laravel foi limpo
- [ ] Servidor foi reiniciado
- [ ] Teste no console do navegador mostra headers CORS
- [ ] Certificado SSL é válido
- [ ] Nginx (se usado) não está bloqueando CORS
- [ ] A origem `http://localhost:39801` está sendo permitida

## 🐛 Erros Comuns

### "No 'Access-Control-Allow-Origin' header"
- **Causa**: Middleware CORS não está sendo executado
- **Solução**: Verificar `bootstrap/app.php` e limpar cache

### "Preflight request doesn't pass"
- **Causa**: OPTIONS não está retornando headers corretos
- **Solução**: Verificar se o middleware trata OPTIONS corretamente

### "Credentials flag is true, but Access-Control-Allow-Credentials is not"
- **Causa**: Headers CORS não incluem `Access-Control-Allow-Credentials: true`
- **Solução**: Verificar se o middleware adiciona esse header quando necessário

## 📞 Próximos Passos

Se nenhuma solução funcionar:

1. Verifique os logs do servidor (Laravel e Nginx)
2. Capture um HAR file do Network tab do navegador
3. Teste com uma ferramenta como Postman (que não tem CORS)
4. Verifique se há firewall bloqueando requisições

