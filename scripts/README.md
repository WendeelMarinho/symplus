# 📜 Scripts de Deploy e Manutenção

Este diretório contém scripts úteis para deploy e manutenção da aplicação Symplus Finance em produção.

## 📋 Scripts Disponíveis

### `deploy.sh`

Script principal de deploy. Atualiza o código, instala dependências, executa migrations e otimiza cache.

**Uso:**
```bash
./deploy.sh [branch]
```

**Exemplo:**
```bash
./deploy.sh main
```

**O que faz:**
- Cria backup do .env
- Atualiza código do repositório
- Instala/atualiza dependências do Composer
- Executa migrations
- Limpa e recria cache otimizado
- Verifica permissões
- Testa saúde da aplicação

### `backup.sh`

Script de backup completo da aplicação.

**Uso:**
```bash
./backup.sh
```

**O que faz:**
- Backup do banco de dados MySQL
- Backup do storage (arquivos)
- Backup do .env
- Backup do MinIO (opcional)
- Compacta tudo em um único arquivo
- Remove backups antigos (mais de 7 dias)

**Localização dos backups:**
```
/var/backups/symplus/
```

**Formato:**
- `backup_completo_YYYYMMDD_HHMMSS.tar.gz` - Backup completo
- `db_YYYYMMDD_HHMMSS.sql.gz` - Apenas banco
- `storage_YYYYMMDD_HHMMSS.tar.gz` - Apenas storage

### `restore.sh`

Script de restauração de backup.

**Uso:**
```bash
./restore.sh <arquivo_backup.tar.gz>
```

**Exemplo:**
```bash
./restore.sh /var/backups/symplus/backup_completo_20240101_120000.tar.gz
```

**O que faz:**
- Extrai backup
- Restaura banco de dados
- Restaura storage
- Restaura .env (com confirmação)
- Restaura MinIO (se disponível)
- Limpa cache

**⚠️ ATENÇÃO:** Este script substitui dados atuais. Use com cuidado!

## 🔧 Configuração

### Tornar Scripts Executáveis

```bash
chmod +x scripts/*.sh
```

### Configurar Backup Automático

Adicione ao crontab para backup diário:

```bash
sudo crontab -e
```

Adicione a linha:
```
0 2 * * * /var/www/symplus/scripts/backup.sh >> /var/log/symplus-backup.log 2>&1
```

Isso fará backup diário às 2h da manhã.

## 📝 Variáveis de Ambiente

Os scripts leem variáveis do arquivo `.env` do backend:

- `DB_DATABASE` - Nome do banco
- `DB_USERNAME` - Usuário do banco
- `DB_PASSWORD` - Senha do banco
- `AWS_BUCKET` - Bucket do MinIO

## 🐛 Troubleshooting

### Erro de permissão

```bash
sudo chmod +x scripts/*.sh
```

### Erro ao ler .env

Certifique-se de que o arquivo `.env` existe em `backend/.env` e está formatado corretamente.

### Erro ao conectar no banco

Verifique se os containers estão rodando:
```bash
docker compose -f backend/docker-compose.prod.yml ps
```

### Backup muito grande

Os backups são compactados automaticamente. Se ainda assim estiver grande, considere:
- Excluir arquivos temporários antes do backup
- Aumentar retenção de backups antigos
- Usar backup incremental

## 📚 Documentação Relacionada

- [Guia Completo de Deploy](../docs/DEPLOY_VPS.md)
- [Guia Rápido de Deploy](../docs/DEPLOY_QUICK_START.md)

