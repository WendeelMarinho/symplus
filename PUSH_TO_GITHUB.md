# 🚀 Push para GitHub - Guia Completo

## 📋 Informações do Repositório

- **URL:** https://github.com/WendeelMarinho/symplus.git
- **Branch padrão:** `main` (ou `master`)

## 🔒 Verificação de Segurança (IMPORTANTE!)

Antes de fazer push, verifique se não há arquivos sensíveis:

### Arquivos que NÃO devem ser commitados:

- ❌ `backend/.env` - Contém credenciais do banco de dados
- ❌ `backend/.env.backup` - Backup de variáveis de ambiente
- ❌ `*.key` - Chaves privadas
- ❌ `*.pem`, `*.p12`, `*.jks` - Certificados e keystores
- ❌ `app/android/key.properties` - Chaves de assinatura Android
- ❌ Arquivos de build (`app/build/`, `backend/vendor/`)

✅ **Boa notícia:** O `.gitignore` já está configurado para ignorar esses arquivos!

---

## 🚀 Opção 1: Usar Script Automatizado (Recomendado)

```bash
# 1. Tornar o script executável
chmod +x scripts/push_to_github.sh

# 2. Executar o script
bash scripts/push_to_github.sh
```

O script irá:
1. ✅ Verificar se é um repositório Git
2. ✅ Configurar o remote do GitHub
3. ✅ Verificar arquivos sensíveis
4. ✅ Adicionar todos os arquivos
5. ✅ Fazer commit com mensagem descritiva
6. ✅ Fazer push para o GitHub

---

## 🛠️ Opção 2: Comandos Manuais

### Passo 1: Verificar Status

```bash
cd /home/wendeel/projetos/symplus2
git status
```

### Passo 2: Configurar Remote (se necessário)

```bash
# Verificar remote atual
git remote -v

# Se não estiver configurado ou estiver errado:
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/WendeelMarinho/symplus.git

# Ou atualizar o remote existente:
git remote set-url origin https://github.com/WendeelMarinho/symplus.git
```

### Passo 3: Verificar Arquivos Sensíveis

```bash
# Verificar se há arquivos .env no staging
git diff --cached --name-only | grep -E "\.env$|\.env\."

# Se encontrar algum, remova do staging:
# git reset HEAD <arquivo>
```

### Passo 4: Adicionar Arquivos

```bash
# Adicionar todos os arquivos (respeitando .gitignore)
git add .

# Verificar o que será commitado
git status
```

### Passo 5: Fazer Commit

```bash
git commit -m "feat: Atualização completa do projeto - Dashboard, Indicadores, i18n, Moeda, Avatar

- ✅ Dashboard completo com KPIs, gráficos e calendário
- ✅ Filtro global de período
- ✅ Indicadores personalizados (CRUD)
- ✅ Resumo trimestral
- ✅ Sistema de moeda (BRL/USD)
- ✅ Sistema de idiomas (PT/EN)
- ✅ Upload de avatar/logo
- ✅ Correções de layout e renderização
- ✅ Build de produção configurado
- ✅ Documentação atualizada"
```

### Passo 6: Verificar Branch

```bash
# Ver qual branch está usando
git branch --show-current

# Se não estiver na main/master, criar ou mudar:
git checkout -b main  # Se não existir
# ou
git checkout main     # Se já existir
```

### Passo 7: Fazer Push

```bash
# Primeiro push (cria a branch no remote)
git push -u origin main

# Ou se a branch já existir no remote:
git push origin main
```

---

## 🔍 Verificação Pós-Push

### 1. Verificar no GitHub

Acesse: https://github.com/WendeelMarinho/symplus

Verifique se:
- ✅ Os arquivos foram enviados
- ✅ O commit aparece no histórico
- ✅ A branch está atualizada

### 2. Verificar Localmente

```bash
# Ver último commit
git log -1

# Ver status
git status

# Verificar se está sincronizado
git fetch origin
git status
```

---

## 🐛 Troubleshooting

### Erro: "remote origin already exists"

```bash
# Remover e adicionar novamente
git remote remove origin
git remote add origin https://github.com/WendeelMarinho/symplus.git
```

### Erro: "Permission denied"

```bash
# Verificar autenticação
# Opção 1: Usar HTTPS com token
git remote set-url origin https://SEU_TOKEN@github.com/WendeelMarinho/symplus.git

# Opção 2: Configurar SSH (recomendado)
# 1. Gerar chave SSH: ssh-keygen -t ed25519 -C "seu_email@example.com"
# 2. Adicionar ao GitHub: Settings > SSH and GPG keys
# 3. Mudar remote para SSH:
git remote set-url origin git@github.com:WendeelMarinho/symplus.git
```

### Erro: "Updates were rejected"

```bash
# Se houver commits no remote que não estão localmente:
git pull origin main --rebase

# Depois fazer push novamente:
git push origin main
```

### Erro: "Large files detected"

Se o GitHub rejeitar por arquivos grandes:

```bash
# Verificar arquivos grandes
find . -type f -size +50M -not -path "./.git/*"

# Adicionar ao .gitignore se necessário
# Remover do histórico se já foi commitado:
git rm --cached <arquivo>
git commit -m "Remove large file"
```

---

## 📝 Checklist Antes do Push

- [ ] ✅ Verificar que `.env` não está no staging
- [ ] ✅ Verificar que arquivos de build não estão no staging
- [ ] ✅ Verificar que chaves privadas não estão no staging
- [ ] ✅ Verificar que o remote está configurado corretamente
- [ ] ✅ Verificar que está na branch correta (main)
- [ ] ✅ Fazer commit com mensagem descritiva
- [ ] ✅ Fazer push

---

## 🎯 Após o Push Bem-Sucedido

1. ✅ **Verificar no GitHub** - Acessar o repositório e confirmar
2. ✅ **Executar Migration** - `cd backend && make migrate`
3. ✅ **Build Flutter Web** - `bash scripts/build_flutter_web.sh`
4. ✅ **Deploy no VPS** - Copiar arquivos para o servidor

---

## 🔐 Informações do VPS (Para Referência)

- **Host:** srv1113923.hstgr.cloud
- **IP:** 72.61.6.135
- **SO:** Ubuntu 22.04 LTS
- **Localização:** United States - Boston
- **Usuário SSH:** root

---

## 📚 Próximos Passos

Após fazer push com sucesso:

1. **No VPS:**
   ```bash
   # Conectar via SSH
   ssh root@srv1113923.hstgr.cloud
   
   # Fazer pull do código
   cd /var/www/symplus
   git pull origin main
   
   # Executar migration
   cd backend
   make migrate
   
   # Build do Flutter Web
   cd ../app
   bash ../scripts/build_flutter_web.sh
   ```

2. **Verificar Deploy:**
   - Acessar: https://srv1113923.hstgr.cloud/app/
   - Testar funcionalidades
   - Verificar logs se necessário

---

## ✅ Resumo dos Comandos

```bash
# Tudo em um comando (se já estiver configurado):
cd /home/wendeel/projetos/symplus2 && \
git add . && \
git commit -m "feat: Atualização completa do projeto" && \
git push -u origin main
```

