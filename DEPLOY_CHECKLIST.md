# ✅ Checklist de Deploy para Produção

## 📋 Pré-Deploy

### Backend
- [ ] Verificar `.env` configurado para produção
- [ ] `APP_ENV=production`
- [ ] `APP_DEBUG=false`
- [ ] `APP_URL=https://srv1113923.hstgr.cloud`
- [ ] Credenciais do banco de dados corretas
- [ ] Redis configurado
- [ ] SSL/TLS configurado no Nginx

### Frontend
- [ ] `api_config.dart` atualizado com URL de produção
- [ ] Build de produção testado localmente
- [ ] Verificar se `--dart-define=API_BASE_URL` está correto

### Git
- [ ] Todos os arquivos commitados
- [ ] `.env` não está no repositório (verificar `.gitignore`)
- [ ] Branch `main` atualizada
- [ ] Tags de versão criadas (se aplicável)

---

## 🚀 Deploy

### 1. Build Local (Opcional)
- [ ] Build Flutter Web executado
- [ ] Build testado localmente
- [ ] Arquivos copiados para `backend/public/app/`

### 2. Push para GitHub
- [ ] `git add .`
- [ ] `git commit -m "feat: Deploy produção v2.0.0"`
- [ ] `git push origin main`

### 3. Deploy na VPS
- [ ] Conectado via SSH: `ssh root@srv1113923.hstgr.cloud`
- [ ] Código atualizado: `git pull origin main`
- [ ] Build Flutter Web executado
- [ ] Migrations executadas: `php artisan migrate --force`
- [ ] Cache limpo: `php artisan optimize:clear`
- [ ] Cache otimizado: `php artisan optimize`
- [ ] Containers reiniciados

### 4. Verificação
- [ ] Healthcheck OK: `curl https://srv1113923.hstgr.cloud/api/health`
- [ ] App Web carrega: `curl -I https://srv1113923.hstgr.cloud/app/`
- [ ] Login funciona
- [ ] Dashboard carrega corretamente
- [ ] Sem erros no console do navegador
- [ ] Sem erros nos logs do Laravel

---

## 📱 Build de APK (Opcional)

- [ ] Keystore configurado
- [ ] Build APK executado: `bash scripts/build_flutter_apk.sh`
- [ ] APK testado em dispositivo Android
- [ ] APK assinado para produção

---

## 🔒 Segurança

- [ ] SSL/TLS configurado e funcionando
- [ ] Firewall configurado (portas 22, 80, 443)
- [ ] Senhas fortes configuradas
- [ ] `.env` não exposto
- [ ] Logs não expõem informações sensíveis

---

## 📊 Monitoramento

- [ ] Logs sendo monitorados
- [ ] Uptime verificado
- [ ] Recursos do servidor verificados
- [ ] Backup configurado

---

## 🐛 Troubleshooting

Se algo der errado:

1. Verificar logs: `docker compose logs`
2. Verificar containers: `docker compose ps`
3. Verificar permissões: `ls -la backend/public/app/`
4. Fazer rollback se necessário: `bash scripts/vps_rollback.sh`

---

## ✅ Pós-Deploy

- [ ] Testar todas as funcionalidades principais
- [ ] Verificar performance
- [ ] Documentar problemas encontrados
- [ ] Atualizar changelog
- [ ] Notificar equipe sobre deploy

---

**Data do Deploy**: _______________  
**Versão**: 2.0.0  
**Responsável**: _______________

