# Guia de Testes - Symplus Finance

Este documento descreve como executar e contribuir com testes no projeto.

## Executando Testes

### Todos os Testes

```bash
# Via Makefile
make test

# Via Docker
docker compose exec php php artisan test

# Via Artisan diretamente
php artisan test
```

### Testes Específicos

```bash
# Por arquivo
php artisan test --filter AccountTest

# Por método
php artisan test --filter "user can create account"

# Por diretório
php artisan test tests/Feature/
```

### Com Cobertura

```bash
php artisan test --coverage

# Com limite mínimo de cobertura
php artisan test --coverage --min=70
```

## Estrutura de Testes

```
tests/
├── Feature/          # Testes de integração/feature
│   ├── AccountTest.php
│   ├── AuthTest.php
│   ├── DashboardTest.php
│   └── ...
└── Unit/            # Testes unitários (a implementar)
```

## Tipos de Testes

### Feature Tests

Testes que verificam funcionalidades completas, incluindo:
- Requisições HTTP
- Rotas e controllers
- Integração com banco de dados
- Middleware
- Validações

Exemplo:
```php
public function test_user_can_create_account(): void
{
    $response = $this->withHeader('Authorization', "Bearer {$token}")
        ->withHeader('X-Organization-Id', (string) $this->organization->id)
        ->postJson('/api/accounts', [
            'name' => 'Conta Corrente',
            'currency' => 'BRL',
        ]);

    $response->assertStatus(201);
}
```

### Unit Tests

Testes de unidades isoladas (models, helpers, etc.):

```php
public function test_account_balance_calculation(): void
{
    $account = Account::factory()->create(['opening_balance' => 100]);
    
    Transaction::factory()->create([
        'account_id' => $account->id,
        'type' => 'income',
        'amount' => 50,
    ]);

    $this->assertEquals(150.0, $account->current_balance);
}
```

## Boas Práticas

### 1. Use Factories

```php
// ✅ Bom
$account = Account::factory()->create([
    'organization_id' => $this->organization->id,
]);

// ❌ Evite
$account = Account::create([
    'organization_id' => $this->organization->id,
    'name' => 'Test Account',
    // ...
]);
```

### 2. Isolamento entre Testes

Sempre use `RefreshDatabase`:

```php
use Illuminate\Foundation\Testing\RefreshDatabase;

class AccountTest extends TestCase
{
    use RefreshDatabase;
    // ...
}
```

### 3. Arrange-Act-Assert

```php
public function test_example(): void
{
    // Arrange - Preparar dados
    $account = Account::factory()->create();
    
    // Act - Executar ação
    $response = $this->getJson("/api/accounts/{$account->id}");
    
    // Assert - Verificar resultado
    $response->assertStatus(200)
        ->assertJsonPath('data.name', $account->name);
}
```

### 4. Nomes Descritivos

```php
// ✅ Bom
public function test_user_cannot_access_other_organization_accounts(): void

// ❌ Evite
public function test_accounts(): void
```

### 5. Teste Edge Cases

- Validações de entrada
- Erros de autorização
- Limites de plano
- Dados vazios/null

## Cobertura de Testes

### Cobertura Atual

Execute para ver a cobertura:
```bash
php artisan test --coverage
```

### Meta de Cobertura

- **Mínimo**: 70% para código crítico (controllers, models)
- **Ideal**: 80%+ para toda a aplicação

## Executando Análises Estáticas

### PHPStan

```bash
# Análise completa
vendor/bin/phpstan analyse

# Com nível específico (atual: 5)
vendor/bin/phpstan analyse --level=5
```

### Pint (Code Style)

```bash
# Verificar
vendor/bin/pint --test

# Corrigir automaticamente
vendor/bin/pint
```

## Troubleshooting

### Erro: "Class 'Database\Factories\XxxFactory' not found"

```bash
# Regenerar autoload
composer dump-autoload
```

### Testes falhando por dados residuais

Certifique-se de usar `RefreshDatabase` em todos os testes que mexem no banco.

### Erro de conexão com banco

Verifique se o `.env.testing` está configurado corretamente:
```env
DB_CONNECTION=sqlite
DB_DATABASE=:memory:
```

ou para MySQL:
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_DATABASE=symplus_test
```

## CI/CD

Os testes são executados automaticamente no GitHub Actions em:
- Push para `main` ou `develop`
- Pull Requests

O workflow verifica:
1. ✅ Pint (code style)
2. ✅ PHPStan (static analysis)
3. ✅ PHPUnit (testes + cobertura mínima de 70%)

