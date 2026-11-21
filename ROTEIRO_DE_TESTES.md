# 🧪 ROTEIRO DE TESTES DE INTEGRAÇÃO - NEXUSflow

Este documento contém todos os testes que devem ser executados para validar as melhorias implementadas no sistema NEXUSflow.

---

## 📋 Pré-requisitos para Testes

Antes de iniciar os testes:

1. ✅ PostgreSQL rodando (porta 5434)
2. ✅ Backend rodando (porta 8080)
3. ✅ Banco de dados inicializado com todos os scripts SQL
4. ✅ Ferramenta para requisições HTTP (cURL, Postman, Insomnia ou similar)

### Inicializar Ambiente de Testes

```bash
# Opção 1: Desenvolvimento
cd nexusflow_backend
docker compose up -d db
# Executar scripts SQL na ordem (001, 002, 003)
dart_frog dev

# Opção 2: Deploy
cd deploy
docker compose up -d
```

---

## 🔐 ETAPA 1 - CONTROLE DE PERMISSÕES

### Objetivo
Validar que o cadastro público **SOMENTE** cria usuários com perfil `atendente`, independente do que for enviado no corpo da requisição.

### Teste 1.1: Cadastro Público Forçando Atendente

**Descrição:** Tentar criar um gerente_geral via rota pública.

**Requisição:**
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Hacker Teste",
    "email": "hacker@nexusflow.test",
    "password": "senha123",
    "role": "gerente_geral"
  }'
```

**Resultado Esperado:**
- Status: `201 Created`
- Resposta contém `"role": "atendente"` (NÃO "gerente_geral")
- Usuário criado no banco com role = `atendente`

**Validação no Banco:**
```sql
SELECT email, role FROM profiles WHERE email = 'hacker@nexusflow.test';
```

**Resultado esperado no banco:**
```
        email          |   role    
-----------------------+-----------
 hacker@nexusflow.test | atendente
```

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 1.2: Cadastro Público Sem Especificar Role

**Descrição:** Criar usuário sem enviar campo `role`.

**Requisição:**
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Usuario Normal",
    "email": "usuario@nexusflow.test",
    "password": "senha123"
  }'
```

**Resultado Esperado:**
- Status: `201 Created`
- Resposta contém `"role": "atendente"`

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 1.3: Tentar Acessar Rota Protegida com Atendente

**Descrição:** Verificar que atendentes não conseguem acessar rotas administrativas.

**Passo 1 - Login como atendente:**
```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"hacker@nexusflow.test","password":"senha123"}' \
  | jq -r '.token')

echo $TOKEN
```

**Passo 2 - Tentar acessar rota de produtos (requer gerente):**
```bash
curl -X GET http://localhost:8080/api/produtos \
  -H "Authorization: Bearer $TOKEN"
```

**Resultado Esperado:**
- Status: `403 Forbidden`
- Erro: `"Sem permissão para acessar produtos"`

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 1.4: Criar Gerente Via Rota Autenticada

**Descrição:** Apenas gerente_geral pode criar outros gerentes via `/api/usuarios`.

**Pré-requisito:** Ter um gerente_geral no banco (criar manualmente via SQL se necessário):

```sql
INSERT INTO profiles (name, email, password_hash, role)
VALUES (
  'Admin Teste',
  'admin@nexusflow.test',
  crypt('admin123', gen_salt('bf')),
  'gerente_geral'
);
```

**Passo 1 - Login como gerente_geral:**
```bash
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nexusflow.test","password":"admin123"}' \
  | jq -r '.token')
```

**Passo 2 - Criar gerente_estoque:**
```bash
curl -X POST http://localhost:8080/api/usuarios \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Gerente Estoque Teste",
    "email": "estoque@nexusflow.test",
    "password": "senha123",
    "role": "gerente_estoque"
  }'
```

**Resultado Esperado:**
- Status: `201 Created`
- Resposta contém `"role": "gerente_estoque"`

**Validação no Banco:**
```sql
SELECT email, role FROM profiles WHERE email = 'estoque@nexusflow.test';
```

**Resultado esperado:**
```
          email          |      role       
-------------------------+-----------------
 estoque@nexusflow.test  | gerente_estoque
```

✅ **PASSOU** | ❌ **FALHOU**

---

## 📦 ETAPA 2 - CONSISTÊNCIA DE VENDAS E ESTOQUE

### Objetivo
Validar que produtos duplicados na mesma venda têm suas quantidades somadas e validadas corretamente contra o estoque.

### Teste 2.1: Produto Duplicado Ultrapassando Estoque

**Descrição:** Venda com mesmo produto em várias linhas, totalizando quantidade maior que o estoque disponível.

**Preparação - Criar produto com estoque limitado:**
```bash
# Login como gerente (usar ADMIN_TOKEN do teste anterior)
PRODUCT_ID=$(curl -s -X POST http://localhost:8080/api/produtos \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "barcode": "TEST001",
    "name": "Produto Teste Estoque",
    "purchase_price": 5.00,
    "sale_price": 10.00,
    "stock_quantity": 5,
    "min_stock": 1
  }' | jq -r '.id')

echo "Produto criado: $PRODUCT_ID"
```

**Tentar vender 4 + 4 unidades (total 8, estoque 5):**
```bash
curl -X POST http://localhost:8080/api/vendas \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"payment_method\": \"pix\",
    \"amount_paid\": 80.00,
    \"items\": [
      {\"product_id\": \"$PRODUCT_ID\", \"quantity\": 4},
      {\"product_id\": \"$PRODUCT_ID\", \"quantity\": 4}
    ]
  }"
```

**Resultado Esperado:**
- Status: `400 Bad Request`
- Erro contém: `"Estoque insuficiente"`

**Validação no Banco - Estoque deve permanecer 5:**
```sql
SELECT name, stock_quantity FROM products WHERE barcode = 'TEST001';
```

**Resultado esperado:**
```
         name          | stock_quantity 
-----------------------+----------------
 Produto Teste Estoque |              5
```

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 2.2: Produto Duplicado Dentro do Estoque

**Descrição:** Venda com mesmo produto duplicado, mas dentro do estoque disponível.

**Tentar vender 2 + 2 unidades (total 4, estoque 5):**
```bash
curl -s -X POST http://localhost:8080/api/vendas \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"payment_method\": \"dinheiro\",
    \"amount_paid\": 50.00,
    \"items\": [
      {\"product_id\": \"$PRODUCT_ID\", \"quantity\": 2},
      {\"product_id\": \"$PRODUCT_ID\", \"quantity\": 2}
    ]
  }"
```

**Resultado Esperado:**
- Status: `201 Created`
- Resposta contém `sale_id`, `invoice_number`, `total`: 40.00

**Validação no Banco - Estoque deve ser 1 (5 - 4):**
```sql
SELECT name, stock_quantity FROM products WHERE barcode = 'TEST001';
```

**Resultado esperado:**
```
         name          | stock_quantity 
-----------------------+----------------
 Produto Teste Estoque |              1
```

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 2.3: Venda Normal (Sem Duplicatas)

**Descrição:** Venda com produtos diferentes funciona normalmente.

**Criar segundo produto:**
```bash
PRODUCT_ID_2=$(curl -s -X POST http://localhost:8080/api/produtos \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "barcode": "TEST002",
    "name": "Produto Teste 2",
    "purchase_price": 3.00,
    "sale_price": 7.00,
    "stock_quantity": 10
  }' | jq -r '.id')
```

**Vender produtos diferentes:**
```bash
curl -s -X POST http://localhost:8080/api/vendas \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"payment_method\": \"credito\",
    \"amount_paid\": 17.00,
    \"items\": [
      {\"product_id\": \"$PRODUCT_ID\", \"quantity\": 1},
      {\"product_id\": \"$PRODUCT_ID_2\", \"quantity\": 1}
    ]
  }"
```

**Resultado Esperado:**
- Status: `201 Created`
- Total: 17.00 (10 + 7)

**Validação no Banco:**
```sql
SELECT barcode, stock_quantity FROM products WHERE barcode IN ('TEST001', 'TEST002');
```

**Resultado esperado:**
```
 barcode | stock_quantity 
---------+----------------
 TEST001 |              0  (1 - 1)
 TEST002 |              9  (10 - 1)
```

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 2.4: Concorrência (Opcional - Requer Script)

**Descrição:** Duas vendas simultâneas do mesmo produto não podem ultrapassar o estoque.

**Criar produto com estoque de 5 unidades para teste:**
```bash
PRODUCT_ID_CONC=$(curl -s -X POST http://localhost:8080/api/produtos \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "barcode": "TESTCONC001",
    "name": "Produto Teste Concorrência",
    "purchase_price": 5.00,
    "sale_price": 10.00,
    "stock_quantity": 5
  }' | jq -r '.id')
```

**Script de teste (salvar como `test_concurrency.sh`):**
```bash
#!/bin/bash
TOKEN="$1"
PRODUCT_ID="$2"

# Executar 10 vendas simultâneas de 3 unidades cada
for i in {1..10}; do
  curl -s -X POST http://localhost:8080/api/vendas \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"payment_method\":\"pix\",\"amount_paid\":30,\"items\":[{\"product_id\":\"$PRODUCT_ID\",\"quantity\":3}]}" &
done

wait
echo "Vendas concorrentes finalizadas"
```

**Executar:**
```bash
chmod +x test_concurrency.sh
./test_concurrency.sh "$ADMIN_TOKEN" "$PRODUCT_ID_CONC"
```

**Resultado Esperado:**
- Apenas 1 venda de 3 unidades deve ter sucesso
- As outras 9 devem retornar erro de estoque insuficiente
- Estoque final deve ser 2 (5 - 3)

**Validação no Banco:**
```sql
SELECT stock_quantity FROM products WHERE barcode = 'TESTCONC001';
SELECT COUNT(*) as vendas_ok FROM sales WHERE created_at > NOW() - INTERVAL '1 minute';
```

**Resultado esperado:**
```
 stock_quantity 
----------------
              2

 vendas_ok 
-----------
         1
```

✅ **PASSOU** | ❌ **FALHOU**

---

## 🐳 ETAPA 3 - CONFIGURAÇÃO E TESTES

### Objetivo
Validar que a configuração Docker, variáveis de ambiente e persistência funcionam corretamente.

### Teste 3.1: Variáveis de Ambiente

**Descrição:** Sistema deve falhar se variáveis obrigatórias estiverem ausentes.

**Teste:**
```bash
# Renomear .env temporariamente
cd nexusflow_backend
mv .env .env.backup

# Tentar iniciar backend
dart_frog dev
```

**Resultado Esperado:**
- Erro claro indicando variável ausente: `"Variável de ambiente ausente: defina DATABASE_URL no arquivo .env"`
- Backend não inicia

**Restaurar:**
```bash
mv .env.backup .env
```

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 3.2: Scripts SQL na Ordem Correta

**Descrição:** Verificar que todos os 3 scripts SQL executam sem erros.

**Teste (com banco limpo):**
```bash
docker compose down -v
docker compose up -d db
sleep 10  # Aguardar banco inicializar

# Executar na ordem
docker compose exec -T db psql -U nexusflow -d nexusflow < scripts/001_create_tables.sql
docker compose exec -T db psql -U nexusflow -d nexusflow < scripts/002_auth_roles_invoices.sql
docker compose exec -T db psql -U nexusflow -d nexusflow < scripts/003_customer_cpf.sql
```

**Resultado Esperado:**
- Todos os scripts executam sem erros
- Mensagens de `CREATE TABLE`, `CREATE FUNCTION`, etc.

**Validação - Verificar tabelas criadas:**
```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
```

**Resultado esperado:**
```
  tablename   
--------------
 products
 sales
 sale_items
 profiles
```

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 3.3: Deploy com init.sql Automático

**Descrição:** O deploy/ deve inicializar o banco automaticamente.

**Teste:**
```bash
cd deploy
docker compose down -v
docker compose up -d
sleep 15  # Aguardar inicialização

# Verificar tabelas
docker compose exec db psql -U nexusflow -d nexusflow -c "\dt"
```

**Resultado Esperado:**
- Tabelas `products`, `sales`, `sale_items`, `profiles` existem
- Função `create_sale` existe

**Validação:**
```bash
docker compose exec db psql -U nexusflow -d nexusflow -c "\df create_sale"
```

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 3.4: Persistência de Dados

**Descrição:** Dados devem persistir após `docker compose down` (sem `-v`).

**Passo 1 - Criar produto:**
```bash
curl -X POST http://localhost:8080/api/produtos \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "barcode": "PERSIST001",
    "name": "Produto Persistência",
    "purchase_price": 1.00,
    "sale_price": 2.00,
    "stock_quantity": 99
  }'
```

**Passo 2 - Parar containers:**
```bash
docker compose down
```

**Passo 3 - Reiniciar:**
```bash
docker compose up -d
sleep 10
```

**Passo 4 - Verificar produto existe:**
```bash
docker compose exec db psql -U nexusflow -d nexusflow \
  -c "SELECT barcode, name FROM products WHERE barcode = 'PERSIST001';"
```

**Resultado Esperado:**
```
  barcode   |        name         
------------+---------------------
 PERSIST001 | Produto Persistência
```

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 3.5: Reset Completo

**Descrição:** `docker compose down -v` deve apagar todos os dados.

**Teste:**
```bash
docker compose down -v
docker compose up -d
sleep 10

# Verificar que não há produtos
docker compose exec db psql -U nexusflow -d nexusflow \
  -c "SELECT COUNT(*) FROM products;"
```

**Resultado Esperado:**
```
 count 
-------
     0
```

✅ **PASSOU** | ❌ **FALHOU**

---

## 📄 ETAPA 4 - DOCUMENTAÇÃO E COMPROVANTES

### Objetivo
Validar que os comprovantes usam nomenclatura correta e não se apresentam como documentos fiscais.

### Teste 4.1: Download de Comprovante

**Descrição:** Rota agora é `/comprovante` (não `/nota-fiscal`).

**Preparação - Criar uma venda:**
```bash
SALE_ID=$(curl -s -X POST http://localhost:8080/api/vendas \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"payment_method\": \"dinheiro\",
    \"amount_paid\": 20.00,
    \"items\": [{\"product_id\": \"$PRODUCT_ID_2\", \"quantity\": 2}]
  }" | jq -r '.sale_id')

echo "Venda criada: $SALE_ID"
```

**Baixar comprovante pela nova rota:**
```bash
curl -X GET "http://localhost:8080/api/vendas/$SALE_ID/comprovante" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  --output comprovante_teste.pdf
```

**Resultado Esperado:**
- Status: `200 OK`
- Header: `Content-Type: application/pdf`
- Header: `Content-Disposition: attachment; filename="comprovante-venda-{uuid}.pdf"`
- Arquivo PDF baixado com sucesso

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 4.2: Verificar Rota Antiga Não Existe

**Descrição:** Rota `/nota-fiscal` não deve mais existir.

**Teste:**
```bash
curl -X GET "http://localhost:8080/api/vendas/$SALE_ID/nota-fiscal" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Resultado Esperado:**
- Status: `404 Not Found`

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 4.3: Conteúdo do PDF

**Descrição:** PDF deve conter "Comprovante de Venda", não "Nota Fiscal".

**Teste Manual:**
1. Abrir arquivo `comprovante_teste.pdf`
2. Verificar visualmente

**Checklist:**
- [ ] Título: "NEXUSflow Mercado"
- [ ] Subtítulo: "Comprovante de Venda"
- [ ] NÃO contém: "Nota Fiscal", "NF-e", "Documento Fiscal"
- [ ] Contém: dados da venda (produtos, quantidades, total)
- [ ] Contém: forma de pagamento
- [ ] Contém: data/hora

✅ **PASSOU** | ❌ **FALHOU**

---

### Teste 4.4: Validar Documentação

**Descrição:** READMEs devem estar atualizados e corretos.

**Checklist README.md (raiz):**
- [ ] Instruções de instalação estão claras
- [ ] Explica diferença entre desenvolvimento e deploy
- [ ] Documenta os 3 níveis de permissão
- [ ] Contém seção sobre comprovantes (não são notas fiscais)
- [ ] Testes estão documentados
- [ ] Seção sobre consistência de estoque

**Checklist deploy/README.md:**
- [ ] Instruções de inicialização com Docker
- [ ] Como criar gerente_geral
- [ ] Testes de persistência documentados
- [ ] Seção de segurança em produção
- [ ] Troubleshooting completo

✅ **PASSOU** | ❌ **FALHOU**

---

## 📊 RESUMO DOS TESTES

### Estatísticas

| Etapa | Testes | Passaram | Falharam |
|-------|--------|----------|----------|
| ETAPA 1 - Permissões | 4 | ___ | ___ |
| ETAPA 2 - Estoque | 4 | ___ | ___ |
| ETAPA 3 - Configuração | 5 | ___ | ___ |
| ETAPA 4 - Documentação | 4 | ___ | ___ |
| **TOTAL** | **17** | **___** | **___** |

---

## 🐛 Registro de Problemas Encontrados

### Problema 1
**Teste:** ___________
**Descrição:** ___________
**Resolução:** ___________

### Problema 2
**Teste:** ___________
**Descrição:** ___________
**Resolução:** ___________

---

## ✅ Conclusão

Data dos testes: ___________

Responsável: ___________

Status final: ⬜ Todos os requisitos atendidos | ⬜ Pendências identificadas

**Observações:**

---

## 📝 Notas Importantes

1. **Ordem dos testes:** Executar na sequência apresentada
2. **Limpeza entre testes:** Alguns testes requerem banco limpo (`docker compose down -v`)
3. **Tokens:** Guardar tokens de autenticação para reutilizar
4. **IDs de produtos:** Guardar UUIDs dos produtos criados
5. **Backups:** Fazer backup antes de testes destrutivos

---

**Documento criado automaticamente pelo sistema de implementação NEXUSflow**
