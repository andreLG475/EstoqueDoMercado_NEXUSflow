# 🚀 NEXUSflow — Deploy com Docker

Sistema de gerenciamento de estoque e PDV pronto para produção usando **Docker Compose**.

---

## 📋 Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e rodando
- Mínimo 2GB de RAM disponível
- Portas 8080 (backend) e 5434 (banco) disponíveis

---

## ⚡ Início Rápido

### 1. Configurar Variáveis de Ambiente

Crie o arquivo `.env` nesta pasta (`deploy/`) com suas credenciais:

```env
POSTGRES_PASSWORD=sua_senha_muito_segura_aqui
SESSION_SECRET=string_aleatoria_bem_longa_minimo_32_caracteres
```

**Exemplo de geração de chave aleatória:**

```bash
# Linux/Mac
openssl rand -hex 32

# Windows PowerShell
-join ((65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})
```

### 2. Iniciar o Sistema

```bash
docker compose up -d
```

Aguarde cerca de 15 segundos para o sistema inicializar completamente.

### 3. Verificar Status

```bash
docker compose ps
```

Deve mostrar dois containers rodando:
- `nexusflow-postgres` (porta 5434)
- `nexusflow-backend` (porta 8080)

### 4. Acessar o Sistema

- **API Backend:** http://localhost:8080
- **Banco de Dados:** `localhost:5434` (usuário: `nexusflow`)

---

## 🧪 Testando o Sistema

### Teste 1: Health Check da API

```bash
curl http://localhost:8080/
```

Deve retornar: `"Welcome to Dart Frog!"`

### Teste 2: Registrar Primeiro Usuário

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Admin","email":"admin@nexusflow.com","password":"senha123"}'
```

**Nota:** Este usuário será criado como `atendente`. Para criar um Gerente Geral, veja a seção "Criando Gerente Geral" abaixo.

### Teste 3: Login

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nexusflow.com","password":"senha123"}'
```

Guarde o `token` retornado para usar nas próximas requisições.

### Teste 4: Cadastrar Produto (requer permissão de gerente)

```bash
curl -X POST http://localhost:8080/api/produtos \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "barcode": "7891234567890",
    "name": "Produto Exemplo",
    "purchase_price": 5.00,
    "sale_price": 10.00,
    "stock_quantity": 50,
    "category": "Alimentos"
  }'
```

### Teste 5: Registrar Venda

```bash
curl -X POST http://localhost:8080/api/vendas \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "dinheiro",
    "amount_paid": 50.00,
    "items": [
      {"product_id": "UUID_DO_PRODUTO", "quantity": 2}
    ]
  }'
```

### Teste 6: Persistência de Dados

```bash
# Parar containers (mantém os dados)
docker compose down

# Reiniciar
docker compose up -d

# Verificar que os dados ainda existem
curl -X GET http://localhost:8080/api/produtos \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

**Resultado esperado:** Produtos cadastrados anteriormente ainda estão presentes.

---

## 👤 Criando Gerente Geral

Como o cadastro público só cria usuários `atendente`, existem duas formas de criar um Gerente Geral:

### Opção 1: Via Console PostgreSQL

```bash
# Acessar o console do banco
docker compose exec db psql -U nexusflow -d nexusflow

# Criar gerente geral (substitua os valores)
INSERT INTO profiles (name, email, password_hash, role)
VALUES (
  'Gerente Admin',
  'gerente@nexusflow.com',
  crypt('senha_do_gerente', gen_salt('bf')),  -- bcrypt automático
  'gerente_geral'
);

# Sair do console
\q
```

### Opção 2: Via Script SQL

Crie um arquivo `create_manager.sql`:

```sql
INSERT INTO profiles (name, email, password_hash, role)
VALUES (
  'Gerente Admin',
  'gerente@nexusflow.com',
  crypt('senha_do_gerente', gen_salt('bf')),
  'gerente_geral'
);
```

Execute:

```bash
# Linux/Mac
docker compose exec -T db psql -U nexusflow -d nexusflow < create_manager.sql

# Windows PowerShell
Get-Content create_manager.sql | docker compose exec -T db psql -U nexusflow -d nexusflow
```

---

## 🔐 Segurança em Produção

### 1. Altere as Senhas Padrão

**Nunca use senhas simples em produção!** Gere senhas fortes:

```bash
# Senha PostgreSQL (mínimo 16 caracteres)
openssl rand -base64 24

# Session Secret (mínimo 32 caracteres)
openssl rand -hex 32
```

### 2. Configure Firewall

Bloqueie a porta 5434 externamente (acesso ao banco deve ser apenas local):

```bash
# Exemplo com ufw (Ubuntu)
sudo ufw deny 5434
sudo ufw allow 8080
```

### 3. Use HTTPS em Produção

Configure um proxy reverso (Nginx ou Caddy) com certificado SSL:

```nginx
server {
    listen 443 ssl;
    server_name seu-dominio.com;
    
    ssl_certificate /caminho/certificado.crt;
    ssl_certificate_key /caminho/chave.key;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 4. Backups Automáticos

Configure backups regulares do banco de dados:

```bash
# Criar backup
docker compose exec db pg_dump -U nexusflow nexusflow > backup_$(date +%Y%m%d).sql

# Agendar via cron (diário às 2h)
0 2 * * * cd /caminho/deploy && docker compose exec -T db pg_dump -U nexusflow nexusflow > /backups/nexusflow_$(date +\%Y\%m\%d).sql
```

---

## 🔧 Comandos Úteis

### Gerenciamento de Containers

```bash
# Ver logs em tempo real
docker compose logs -f

# Ver logs apenas do backend
docker compose logs -f backend

# Ver logs apenas do banco
docker compose logs -f db

# Reiniciar um serviço específico
docker compose restart backend

# Parar tudo
docker compose down

# Parar e remover volumes (APAGA TODOS OS DADOS!)
docker compose down -v
```

### Manutenção do Banco

```bash
# Acessar console PostgreSQL
docker compose exec db psql -U nexusflow -d nexusflow

# Backup do banco
docker compose exec db pg_dump -U nexusflow nexusflow > backup.sql

# Restaurar backup
cat backup.sql | docker compose exec -T db psql -U nexusflow -d nexusflow

# Ver tamanho do banco
docker compose exec db psql -U nexusflow -d nexusflow -c "SELECT pg_size_pretty(pg_database_size('nexusflow'));"

# Ver tabelas
docker compose exec db psql -U nexusflow -d nexusflow -c "\dt"
```

### Monitoramento

```bash
# Status dos containers
docker compose ps

# Uso de recursos
docker stats

# Espaço em disco dos volumes
docker system df -v
```

---

## 🗄️ Estrutura do Banco de Dados

O arquivo `init.sql` cria automaticamente:

### Tabelas Principais

- **products** — Cadastro de produtos com estoque
- **sales** — Registro de vendas
- **sale_items** — Itens de cada venda
- **profiles** — Usuários do sistema

### Roles (Níveis de Permissão)

- **gerente_geral** — Acesso total
- **gerente_estoque** — Gerenciar produtos
- **atendente** — Apenas PDV

### Stored Procedure

- **create_sale()** — Registra vendas atomicamente com validação de estoque

---

## 🐛 Resolução de Problemas

### Backend não inicia

```bash
# Verificar logs
docker compose logs backend

# Erros comuns:
# - Falta variáveis no .env
# - Banco ainda não está pronto
# - Porta 8080 já em uso
```

### Banco não conecta

```bash
# Verificar se o container está rodando
docker compose ps db

# Ver logs do banco
docker compose logs db

# Testar conexão
docker compose exec db psql -U nexusflow -d nexusflow -c "SELECT version();"
```

### Erro "relation does not exist"

Significa que as tabelas não foram criadas. O `init.sql` só roda na primeira inicialização.

**Solução:**

```bash
# Apagar tudo e recomeçar
docker compose down -v
docker compose up -d
```

### Porta já em uso

```bash
# Verificar o que está usando a porta 8080
netstat -ano | findstr :8080  # Windows
lsof -i :8080                 # Linux/Mac

# Alterar porta no docker-compose.yml:
services:
  backend:
    ports:
      - "8081:8080"  # Usar 8081 externamente
```

### Performance lenta

```bash
# Verificar recursos
docker stats

# Aumentar memória no Docker Desktop:
# Settings > Resources > Memory (mínimo 2GB)

# Ver queries lentas no PostgreSQL
docker compose exec db psql -U nexusflow -d nexusflow
SELECT * FROM pg_stat_activity WHERE state = 'active';
```

---

## 📊 Monitoramento em Produção

### Métricas Importantes

1. **Uso de disco do volume:**
```bash
docker system df -v | grep nexusflow_pgdata
```

2. **Conexões ativas no banco:**
```bash
docker compose exec db psql -U nexusflow -d nexusflow -c "SELECT count(*) FROM pg_stat_activity;"
```

3. **Uptime dos containers:**
```bash
docker compose ps
```

### Alertas Recomendados

- Espaço em disco < 10% disponível
- Memória > 80% de uso
- Containers reiniciando frequentemente
- Tempo de resposta da API > 2 segundos

---

## 🔄 Atualizações

### Atualizar para Nova Versão

```bash
# Parar sistema atual
docker compose down

# Baixar nova imagem
docker compose pull

# Reiniciar
docker compose up -d
```

### Aplicar Novas Migrações SQL

Se houver novos scripts SQL:

```bash
docker compose exec -T db psql -U nexusflow -d nexusflow < nova_migracao.sql
```

---

## 📞 Checklist de Deploy

Antes de colocar em produção, verifique:

- [ ] Arquivo `.env` com senhas fortes (mínimo 16 caracteres)
- [ ] Variável `SESSION_SECRET` é única e aleatória
- [ ] Porta 5434 bloqueada externamente (firewall)
- [ ] Backup automático configurado
- [ ] HTTPS configurado com certificado válido
- [ ] Gerente Geral criado e testado
- [ ] Monitoramento de recursos ativo
- [ ] Logs sendo salvos e rotacionados
- [ ] Teste de recuperação de backup realizado

---

## 📄 Arquitetura

```
┌─────────────┐
│   Cliente   │
│  (Flutter)  │
└──────┬──────┘
       │ HTTPS
       ↓
┌─────────────────┐      ┌──────────────┐
│  nexusflow      │◄────►│  nexusflow   │
│  backend        │      │  postgres    │
│  (Dart Frog)    │      │  (PostgreSQL)│
└─────────────────┘      └──────────────┘
     8080                     5434
```

---

## 📝 Variáveis de Ambiente

| Variável | Obrigatória | Descrição | Exemplo |
|----------|-------------|-----------|---------|
| `POSTGRES_PASSWORD` | ✅ | Senha do PostgreSQL | `P@ssw0rd_S3cur3!` |
| `SESSION_SECRET` | ✅ | Chave JWT (min. 32 chars) | `a1b2c3d4...` |
| `DOCKERHUB_USER` | ❌ | Usuário DockerHub (build) | `seu_usuario` |

---

## 🆘 Suporte

Em caso de problemas:

1. Verifique os logs: `docker compose logs`
2. Consulte a seção "Resolução de Problemas"
3. Revise as configurações do `.env`
4. Teste cada componente separadamente

---

**Sistema pronto para produção! 🎉**
