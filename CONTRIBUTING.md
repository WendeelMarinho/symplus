# Guia de Contribuição

Obrigado por considerar contribuir com o Symplus Finance! Este documento fornece diretrizes para contribuir com o projeto.

## 📋 Padrões de Commit

Este projeto segue o padrão [Conventional Commits](https://www.conventionalcommits.org/). Use os seguintes tipos:

- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Alterações na documentação
- `style`: Alterações de formatação (não afetam funcionalidade)
- `refactor`: Refatoração de código
- `test`: Adição ou correção de testes
- `chore`: Tarefas de manutenção (deps, config, etc.)

### Formato

```
<tipo>(<escopo>): <descrição curta>

[corpo opcional]

[rodapé opcional]
```

### Exemplos

```
feat(api): adicionar endpoint de exportação de relatórios P&L

Implementa endpoint GET /api/exports/pl que permite exportar
relatórios em formato CSV/Excel com filtros de período.

Closes #123
```

```
fix(auth): corrigir validação de token expirado

O middleware EnsureTenantIsSet não estava tratando corretamente
tokens expirados, causando 500 em vez de 401.

Fixes #456
```

```
docs(readme): atualizar instruções de instalação

Adiciona seção sobre configuração de variáveis de ambiente
para desenvolvimento local.
```

## 🔀 Pull Requests

### Processo

1. **Fork** o repositório
2. Crie uma **branch** a partir de `main`:
   ```bash
   git checkout -b feat/minha-nova-funcionalidade
   ```
3. Faça suas **alterações** e commits seguindo os padrões
4. **Teste** suas alterações:
   ```bash
   make backend-test
   cd backend && docker compose exec php vendor/bin/phpstan analyse
   cd backend && docker compose exec php vendor/bin/pint --test
   ```
5. **Push** para sua branch:
   ```bash
   git push origin feat/minha-nova-funcionalidade
   ```
6. Abra um **Pull Request** usando o template abaixo

### Template de PR

Use o arquivo `.github/pull_request_template.md` ao criar um PR. Preencha:

- **Descrição**: O que foi alterado e por quê
- **Tipo de mudança**: feat/fix/docs/refactor/test
- **Como testar**: Passos para validar
- **Checklist**: Itens obrigatórios verificados

## 📝 Padrões de Código

### Backend (PHP/Laravel)

- Siga **PSR-12** (enforce via Pint)
- **PHPStan** nível 6 ou superior
- **Uma classe por arquivo** (PSR-4)
- **Type hints** completos em métodos públicos
- **Testes** para novas funcionalidades (cobertura mínima: 70%)

### Frontend (Flutter/Dart)

- Siga o **Effective Dart** style guide
- Use **Riverpod** para gerenciamento de estado
- **Separação de responsabilidades**: UI, providers, services
- **Testes unitários** para lógica de negócio

## 🧪 Testes

### Backend

- **Feature Tests**: para endpoints e fluxos completos
- **Unit Tests**: para serviços e lógica isolada
- Todos os testes devem passar antes do PR

```bash
make backend-test
```

### Flutter

- Testes unitários para providers
- Testes de widget para componentes principais

```bash
cd app && flutter test
```

## 📚 Documentação

- Atualize a documentação quando necessário
- Adicione exemplos de uso para novas APIs
- Mantenha o README.md atualizado

## ❓ Dúvidas?

Se você tem dúvidas ou sugestões, abra uma **Issue** com a tag apropriada:

- `question`: Dúvidas sobre o projeto
- `bug`: Reportar bugs
- `enhancement`: Sugestões de melhorias
- `documentation`: Melhorias na documentação

---

Obrigado por contribuir! 🎉

