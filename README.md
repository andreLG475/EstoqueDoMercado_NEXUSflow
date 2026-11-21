# NEXUSflow — Sistema de Estoque e PDV

Sistema completo de gerenciamento de estoque e ponto de venda (PDV) para mercados, desenvolvido com Flutter (frontend) e Dart Frog (backend).

## 📋 Visão Geral

O NEXUSflow oferece:
- **Gerenciamento de estoque** com controle de quantidades e alertas
- **Ponto de venda (PDV)** com suporte a múltiplas formas de pagamento
- **Controle de usuários** com três níveis de permissão
- **Emissão de comprovantes** em PDF para controle interno
- **Relatórios** de vendas e movimentação

## 🏗️ Arquitetura

```
nexusflow/
├── nexusflow_backend/    # API REST (Dart Frog + PostgreSQL)
├── nexusflow_app/        # Aplicativo (Flutter)
└── deploy/               # Configuração para produção (Docker)
```

## 🔐 Níveis de Permissão

| Papel | Permissões |
|-------|-----------|
| **Gerente Geral** | Acesso total: estoque, PDV, usuários, relatórios |
| **Gerente de Estoque** | Gerenciar produtos e visualizar estoque |
| **Atendente** | Apenas PDV (registrar vendas) |

**Importante:** Cadastros públicos criam apenas usuários `atendente`. Perfis administrativos só podem ser criados por um Gerente Geral autenticado.

## 🚀 Início Rápido

### Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (para banco de dados)
- [Dart SDK](https://dart.dev/get-dart) `^3.11.0`
- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.12.0`

### Opção 1: Desenvolvimento (Backend + Frontend separados)

#### 1. Banco de Dados

```bash
cd nexusflow_backend
cp .env.example .env
# Edite o .env e defina senhas seguras para POSTGRES_PASSWORD e SESSION_SECRET
docker compose up -d db
```

Aguarde o banco inicializar (cerca de 10 segundos), então execute as migrações na ordem:

```bash
# Linux/Mac
docker compose exec -T db psql -U nexusflow -d nexusflow < scripts/001_create_tables.sql
docker compose exec -T db psql -U nexusflow -d nexusflow < scripts/002_auth_roles_invoices.sql
docker compose exec -T db psql -U nexusflow -d nexusflow < scripts/003_customer_cpf.sql

# Windows PowerShell
Get-Content scripts/001_create_tables.sql | docker compose exec -T db psql -U nexusflow -d nexusflow
Get-Content scripts/002_auth_roles_invoices.sql | docker compose exec -T db psql -U nexusflow -d nexusflow
Get-Content scripts/003_customer_cpf.sql | docker compose exec -T db psql -U nexusflow -d nexusflow
```

#### 2. Backend (API)

```bash
cd nexusflow_backend
dart pub global activate dart_frog_cli   # Apenas na primeira vez
dart pub get
dart_frog dev
```

API disponível em `http://localhost:8080`.

#### 3. Criar Primeiro Usuário

Cadastre um atendente pelo endpoint público:

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Seu Nome","email":"seu@email.com","password":"senha123"}'
```

**Para criar um Gerente Geral:** Use um client PostgreSQL para inserir diretamente no banco:

```sql
INSERT INTO profiles (name, email, password_hash, role)
VALUES (
  'Admin',
  'admin@nexusflow.com',
  '$2a$10$exemplo_hash',  -- Use bcrypt para gerar o hash
  'gerente_geral'
);
```

Ou peça a outro gerente geral para criar via `POST /api/usuarios`.

#### 4. Frontend (App)

```bash
cd nexusflow_app
flutter pub get
flutter run
```

O app se conecta automaticamente a `http://localhost:8080` (Web/Windows) ou `http://10.0.2.2:8080` (emulador Android).

Para conectar a outro endereço:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_IP:8080
```

### Opção 2: Deploy com Docker (Recomendado para Produção)

Consulte [`deploy/README.md`](deploy/README.md) para instruções completas de deploy com Docker Compose.

## 🧪 Testando o Sistema

### 1. Teste de Autenticação

```bash
# Registrar usuário (será criado como atendente)
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Teste","email":"teste@example.com","password":"senha123"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"teste@example.com","password":"senha123"}'
```

Guarde o `token` retornado para as próximas requisições.

### 2. Teste de Cadastro de Produto

```bash
# Requer permissão de gerente (gerente_geral ou gerente_estoque)
curl -X POST http://localhost:8080/api/produtos \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "barcode": "7891234567890",
    "name": "Produto Teste",
    "purchase_price": 10.00,
    "sale_price": 15.00,
    "stock_quantity": 100
  }'
```

### 3. Teste de Venda

```bash
curl -X POST http://localhost:8080/api/vendas \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "dinheiro",
    "amount_paid": 50.00,
    "items": [
      {"product_id": "UUID_DO_PRODUTO", "quantity": 2}
    ]
  }'
```

### 4. Teste de Persistência

```bash
# Parar containers (sem apagar dados)
docker compose down

# Reiniciar
docker compose up -d

# Verificar que dados ainda existem
curl -X GET http://localhost:8080/api/produtos \
  -H "Authorization: Bearer SEU_TOKEN"
```

### 5. Reset Completo

```bash
# Apagar TODOS os dados do banco (use com cuidado!)
docker compose down -v
```

## 📊 Consistência de Estoque

O sistema garante consistência de estoque mesmo quando:
- Um mesmo produto aparece múltiplas vezes na mesma venda
- Múltiplas vendas simultâneas tentam vender o mesmo produto

**Como funciona:**
1. O sistema soma todas as quantidades do mesmo produto na venda
2. Valida o total contra o estoque disponível
3. Usa lock de linha (`FOR UPDATE`) para prevenir race conditions
4. Rejeita a venda inteira se qualquer produto tiver estoque insuficiente

**Exemplo:**
```json
{
  "items": [
    {"product_id": "abc-123", "quantity": 4},
    {"product_id": "abc-123", "quantity": 4}
  ]
}
```
Sistema detecta: 8 unidades solicitadas do produto `abc-123`. Se o estoque for 5, a venda é rejeitada e o estoque permanece inalterado.

## 📄 Comprovantes de Venda

Os PDFs gerados são **comprovantes de venda para controle interno** e **NÃO possuem validade fiscal**.

⚠️ Para emissão de documentos fiscais (NF-e, NFC-e), é necessário:
- Inscrição estadual/municipal ativa
- Certificado digital
- Integração com sistema autorizado pela SEFAZ

## 📁 Estrutura de Pastas

```
nexusflow_backend/
├── lib/src/
│   ├── auth/          # Autenticação JWT, sessão, senhas
│   ├── models/        # Modelos de dados (Product, Sale, Profile, Role)
│   ├── db.dart        # Conexão PostgreSQL
│   └── invoice_pdf.dart  # Geração de PDFs
├── routes/api/        # Endpoints da API REST
├── scripts/           # Migrações SQL (executar na ordem)
└── docker-compose.yml

nexusflow_app/
├── lib/
│   ├── core/          # API client, tema, constantes
│   ├── models/        # Modelos de dados do app
│   ├── providers/     # Estado global (Riverpod)
│   ├── router/        # Navegação (go_router)
│   ├── screens/       # Telas do aplicativo
│   └── widgets/       # Componentes reutilizáveis
└── pubspec.yaml
```

## 🛠️ Comandos Úteis

### Backend

```bash
# Instalar dependências
dart pub get

# Rodar testes
dart test

# Build de produção
dart_frog build

# Compilar para binário nativo
dart compile exe build/bin/server.dart -o build/bin/server
```

### Frontend

```bash
# Instalar dependências
flutter pub get

# Rodar testes
flutter test

# Build para produção
flutter build web       # Web
flutter build windows   # Windows
flutter build apk       # Android
```

### Banco de Dados

```bash
# Acessar console PostgreSQL
docker compose exec db psql -U nexusflow -d nexusflow

# Ver logs do banco
docker compose logs db

# Backup
docker compose exec db pg_dump -U nexusflow nexusflow > backup.sql

# Restore
cat backup.sql | docker compose exec -T db psql -U nexusflow -d nexusflow
```

## 🐛 Resolução de Problemas

### Backend não conecta ao banco

```bash
# Verificar se o banco está rodando
docker compose ps

# Ver logs
docker compose logs db

# Reiniciar banco
docker compose restart db
```

### Erro "Variável de ambiente ausente"

Certifique-se de criar o arquivo `.env` a partir do `.env.example` e definir todas as variáveis:

```env
POSTGRES_PASSWORD=sua_senha_segura_aqui
DATABASE_URL=postgresql://nexusflow:sua_senha_segura_aqui@localhost:5434/nexusflow?sslmode=disable
SESSION_SECRET=string_aleatoria_bem_longa_e_segura
```

### Frontend não conecta à API

Verifique se o backend está rodando em `http://localhost:8080`. Se estiver usando outro endereço:

```bash
flutter run --dart-define=API_BASE_URL=http://seu_ip:8080
```

## 📝 Variáveis de Ambiente

### Backend (.env)

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `POSTGRES_PASSWORD` | Senha do banco PostgreSQL | `senha_muito_segura_123` |
| `DATABASE_URL` | URL completa de conexão | `postgresql://nexusflow:senha@localhost:5434/nexusflow?sslmode=disable` |
| `SESSION_SECRET` | Chave para assinar tokens JWT | `string_aleatoria_minimo_32_caracteres` |

**Importante:** NUNCA commite o arquivo `.env` com senhas reais. Use `.env.example` como template.

## 🔒 Segurança

- ✅ Senhas hasheadas com bcrypt (custo 10)
- ✅ Autenticação JWT com expiração de 7 dias
- ✅ Autorização por role em todas as rotas sensíveis
- ✅ Validações no backend (não apenas no frontend)
- ✅ Prepared statements para prevenir SQL injection
- ✅ CORS configurado para origens específicas
- ✅ Cadastro público restrito a role `atendente`

## 📞 Suporte

Para dúvidas ou problemas, consulte a documentação dos frameworks utilizados:

- [Dart Frog](https://dartfrog.vgv.dev/)
- [Flutter](https://flutter.dev/docs)
- [PostgreSQL](https://www.postgresql.org/docs/)

## 📄 Licença

Este projeto é de uso acadêmico/interno. Consulte os responsáveis para informações sobre licenciamento.

---

**Desenvolvido para o controle de estoque de mercados.**
