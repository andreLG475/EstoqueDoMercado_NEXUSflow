# NEXUSflow — Estoque do Mercado

Controle de estoque, vendas (PDV) e relatórios para mercado.

- `nexusflow_backend` — API em Dart Frog + Postgres
- `nexusflow_app` — App em Flutter (Android, iOS, Web, Windows)

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Dart SDK](https://dart.dev/get-dart) `^3.11`
- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.12`

## 1. Banco de dados

```bash
cd nexusflow_backend
cp .env.example .env    # edite e defina uma senha em POSTGRES_PASSWORD/DATABASE_URL
docker compose up -d
```

Rode as migrações (uma vez só):

```bash
docker compose exec -T db psql -U nexusflow -d nexusflow < scripts/001_create_tables.sql
docker compose exec -T db psql -U nexusflow -d nexusflow < scripts/002_auth_roles_invoices.sql
```

No PowerShell, troque o `<` por:

```powershell
Get-Content scripts/001_create_tables.sql | docker compose exec -T db psql -U nexusflow -d nexusflow
Get-Content scripts/002_auth_roles_invoices.sql | docker compose exec -T db psql -U nexusflow -d nexusflow
```

## 2. Backend (API)

```bash
cd nexusflow_backend
dart pub global activate dart_frog_cli   # só na primeira vez
dart pub get
dart_frog dev
```

API disponível em `http://localhost:8080`.

Crie o primeiro usuário:

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Admin","email":"admin@nexusflow.com","password":"senha123","role":"gerente_geral"}'
```

## 3. Frontend (App Flutter)

Com a API rodando, em outro terminal:

```bash
cd nexusflow_app
flutter pub get
flutter run
```

Por padrão o app aponta pra `http://localhost:8080` (Web/Windows) ou `http://10.0.2.2:8080` (emulador Android). Para outro endereço:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_IP:8080
```

## Parar tudo

```bash
cd nexusflow_backend
docker compose down       # mantém os dados
docker compose down -v    # apaga os dados também
```
