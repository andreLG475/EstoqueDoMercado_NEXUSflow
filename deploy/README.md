# 🚀 NexusFlow — Estoque do Mercado

Sistema de gerenciamento de estoque e PDV (Ponto de Venda) desenvolvido com **Flutter** (frontend) e **Dart Frog** (backend).

---

## Como rodar o Backend (Docker)

### Pré-requisito

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e rodando

### Passo a passo

1. **Abra o terminal** nesta pasta (`deploy/`)

2. **Execute o comando:**

```bash
docker compose up
```

3. **Pronto!** O sistema vai:
   - Baixar a imagem do backend do Docker Hub
   - Criar o banco de dados PostgreSQL
   - Criar todas as tabelas automaticamente
   - Iniciar o servidor na porta **8080**

4. **Acesse o backend:** [http://localhost:8080](http://localhost:8080)

### Para parar

Pressione `Ctrl+C` no terminal, ou rode:

```bash
docker compose down
```

### Para apagar os dados do banco e recomeçar do zero

```bash
docker compose down -v
```

---

## Estrutura

| Serviço  | Porta | Descrição                     |
|----------|-------|-------------------------------|
| Backend  | 8080  | API REST (Dart Frog)          |
| Postgres | 5434  | Banco de dados                |

---

## Frontend (App Flutter)

O app Flutter se conecta ao backend na porta 8080. Para rodar o app:

```bash
cd nexusflow_app
flutter pub get
flutter run
```

> **Nota:** É necessário ter o [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado.

---

## Tecnologias

- **Backend:** Dart Frog (Dart)
- **Banco de Dados:** PostgreSQL 16
- **Frontend:** Flutter
- **Containerização:** Docker
