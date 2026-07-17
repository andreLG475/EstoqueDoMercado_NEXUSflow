# nexusflow_backend

API REST em [Dart Frog](https://dart-frog.dev) para o sistema NEXUSflow (estoque, vendas/PDV e relatórios), com autenticação própria (JWT) e Postgres.

[![style: dart frog lint][dart_frog_lint_badge]][dart_frog_lint_link]
[![License: MIT][license_badge]][license_link]
[![Powered by Dart Frog](https://img.shields.io/endpoint?url=https://tinyurl.com/dartfrog-badge)](https://dart-frog.dev)

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) — para rodar o Postgres
- [Dart SDK](https://dart.dev/get-dart) `^3.11`

## 1. Banco de dados (Postgres via Docker)

O Postgres roda em container, definido em `docker-compose.yml` (porta `5434`, banco `nexusflow`).

### 1.1 Criar o arquivo `.env`

```bash
cp .env.example .env
```

Edite o `.env` e defina uma senha própria:

```env
POSTGRES_PASSWORD=sua-senha
DATABASE_URL=postgresql://nexusflow:sua-senha@localhost:5434/nexusflow?sslmode=disable
SESSION_SECRET=uma-string-aleatoria-bem-longa
```

> A senha em `DATABASE_URL` precisa ser **igual** à `POSTGRES_PASSWORD`. `SESSION_SECRET` assina os tokens JWT — use qualquer string longa e aleatória.

### 1.2 Subir o container

```bash
docker compose up -d
docker compose ps   # confirma que o container está saudável
```

### 1.3 Rodar as migrações (scripts SQL)

Os scripts estão em `scripts/` e devem ser executados **nesta ordem**:

1. `001_create_tables.sql` — cria `products`, `sales`, `sale_items`.
2. `002_auth_roles_invoices.sql` — cria `profiles` (usuários/papéis), numeração de nota fiscal e a função `create_sale`.

```bash
docker compose exec -T db psql -U nexusflow -d nexusflow < scripts/001_create_tables.sql
docker compose exec -T db psql -U nexusflow -d nexusflow < scripts/002_auth_roles_invoices.sql
```

No Windows, se o redirecionamento `<` não funcionar no seu terminal (ex.: PowerShell), use:

```powershell
Get-Content scripts/001_create_tables.sql | docker compose exec -T db psql -U nexusflow -d nexusflow
Get-Content scripts/002_auth_roles_invoices.sql | docker compose exec -T db psql -U nexusflow -d nexusflow
```

## 2. Rodar a API

### 2.1 Instalar a CLI do Dart Frog (uma única vez)

```bash
dart pub global activate dart_frog_cli
```

Garanta que o diretório de pacotes globais do Dart esteja no `PATH` (ex.: `%LOCALAPPDATA%\Pub\Cache\bin` no Windows) para o comando `dart_frog` ser reconhecido no terminal.

### 2.2 Instalar as dependências

```bash
dart pub get
```

### 2.3 Subir o servidor

```bash
dart_frog dev
```

A API sobe por padrão em `http://localhost:8080`.

### 2.4 Criar o primeiro usuário

Não há seed automático — crie o primeiro usuário chamando a rota de cadastro:

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Admin","email":"admin@nexusflow.com","password":"senha123","role":"gerente_geral"}'
```

Papéis disponíveis: `gerente_geral`, `gerente_estoque`, `atendente`.

## Parar tudo

```bash
# Encerre o `dart_frog dev` com Ctrl+C

# Para o banco (mantém os dados no volume Docker)
docker compose down

# Para apagar também os dados do banco
docker compose down -v
```

## App cliente

O app Flutter que consome esta API fica em [`../nexusflow_app`](../nexusflow_app) — veja o README de lá para rodá-lo.

[dart_frog_lint_badge]: https://img.shields.io/badge/style-dart_frog_lint-1DF9D2.svg
[dart_frog_lint_link]: https://pub.dev/packages/dart_frog_lint
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
