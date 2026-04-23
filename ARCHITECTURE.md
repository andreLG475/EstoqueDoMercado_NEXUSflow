# 🏗️ Arquitetura Técnica - NEXUS flow

Documentação técnica da arquitetura e fluxo de dados do NEXUS flow.

## 📊 Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                      Browser (Cliente)                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  React Components (Pages + UI Components)           │    │
│  │  ├── Dashboard                                      │    │
│  │  ├── Estoque (Products)                            │    │
│  │  ├── PDV (Sales)                                   │    │
│  │  └── Relatórios (Reports)                          │    │
│  └─────────────────────────────────────────────────────┘    │
└──────────────┬──────────────────────────────────────────────┘
               │ HTTP/HTTPS
               ▼
┌──────────────────────────────────────────────────────────────┐
│            Next.js Server (Node.js Runtime)                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  API Routes & Server Components                      │   │
│  │  ├── lib/supabase/client.ts (Browser Client)        │   │
│  │  └── lib/supabase/server.ts (Server Client)         │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────┬──────────────────────────────────────────────┘
               │ SQL/REST API
               ▼
┌──────────────────────────────────────────────────────────────┐
│           Supabase Cloud (PostgreSQL + Auth)                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Database                                            │   │
│  │  ├── products (Produtos)                             │   │
│  │  ├── sales (Vendas)                                  │   │
│  │  └── sale_items (Itens de Venda)                     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗂️ Estrutura de Pastas e Responsabilidades

### `/app` - Páginas (Next.js App Router)

```
app/
├── layout.tsx              # Layout principal com sidebar, navbar
├── page.tsx                # Dashboard (rota raiz /)
├── estoque/page.tsx        # Página de gestão de estoque
├── pdv/page.tsx            # Página de ponto de venda
└── relatorios/page.tsx     # Página de relatórios
```

**Fluxo**: URL → Página → Componente de Conteúdo → Banco de Dados

### `/components` - Componentes React

```
components/
├── app-layout.tsx          # Wrapper de layout
├── app-sidebar.tsx         # Menu lateral com navegação
├── dashboard-content.tsx   # Conteúdo do dashboard
├── estoque-content.tsx     # Formulário + tabela de produtos
├── pdv-content.tsx         # Interface de vendas
├── relatorios-content.tsx  # Gráficos e análises
└── ui/                     # Componentes base (Radix UI)
    ├── button.tsx
    ├── dialog.tsx
    ├── input.tsx
    ├── table.tsx
    ├── chart.tsx
    └── ... (outros componentes)
```

**Padrão**: Componentes base reutilizáveis + componentes específicos de página

### `/lib` - Lógica e Utilitários

```
lib/
├── supabase/
│   ├── client.ts           # Cliente Supabase para browser (React)
│   └── server.ts           # Cliente Supabase para servidor
├── types.ts                # TypeScript types/interfaces
└── utils.ts                # Funções helper (formatCurrency, etc)
```

**Uso**: Importar utilitários em componentes e páginas

### `/public` - Arquivos Estáticos

```
public/
├── images/
│   ├── logo.png            # Logo da aplicação
│   └── ... (outras imagens)
```

---

## 🔄 Fluxo de Dados

### 1. **Fluxo de Leitura (Fetch)**

```
Componente React
    ↓
useSWR("chave", fetchFunction)
    ↓
fetchFunction() chama supabase.from().select()
    ↓
Supabase (PostgreSQL)
    ↓
Retorna dados em JSON
    ↓
Componente renderiza com dados
```

**Exemplo:**
```typescript
// estoque-content.tsx
async function fetchProducts() {
  const { data } = await supabase
    .from("products")
    .select("*")
  return data
}

const { data: products } = useSWR("products", fetchProducts)
// products é reativo e cacheado
```

### 2. **Fluxo de Escrita (Insert/Update/Delete)**

```
Usuário preenche formulário
    ↓
onSubmit(handleSubmit)
    ↓
supabase.from().insert() / update() / delete()
    ↓
Supabase grava no PostgreSQL
    ↓
mutate("chave") - invalida cache SWR
    ↓
Componente refetch automático
    ↓
UI atualiza com novos dados
```

**Exemplo:**
```typescript
// estoque-content.tsx
const handleSubmit = async (e) => {
  await supabase.from("products").insert(formData)
  mutate("products") // Invalida e refetch
}
```

---

## 🗄️ Banco de Dados - Schema

### Tabela: `products`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID | Chave primária |
| `barcode` | TEXT | Código de barras (UNIQUE) |
| `name` | TEXT | Nome do produto |
| `description` | TEXT | Descrição |
| `purchase_price` | DECIMAL | Preço de custo |
| `sale_price` | DECIMAL | Preço de venda |
| `min_sale_price` | DECIMAL | Mínimo (calculado) |
| `profit_margin` | DECIMAL | Margem de lucro % |
| `stock_quantity` | INTEGER | Quantidade em estoque |
| `min_stock` | INTEGER | Alerta quando atinge |
| `category` | TEXT | Categoria |
| `created_at` | TIMESTAMPTZ | Data criação (auto) |
| `updated_at` | TIMESTAMPTZ | Data atualização (auto) |

**Índices para Performance:**
- `idx_products_barcode` - busca rápida por código
- `idx_products_name` - busca por nome

### Tabela: `sales`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID | Chave primária |
| `total` | DECIMAL | Valor total da venda |
| `payment_method` | TEXT | Dinheiro/Cartão/Pix |
| `amount_paid` | DECIMAL | Valor pago |
| `change_amount` | DECIMAL | Troco |
| `created_at` | TIMESTAMPTZ | Data da venda (auto) |

**Índice para Performance:**
- `idx_sales_created_at` - relatórios por data

### Tabela: `sale_items`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID | Chave primária |
| `sale_id` | UUID | FK para sales (CASCADE) |
| `product_id` | UUID | FK para products |
| `product_name` | TEXT | Nome do produto (snapshot) |
| `quantity` | INTEGER | Quantidade vendida |
| `unit_price` | DECIMAL | Preço unitário |
| `subtotal` | DECIMAL | qty × price |
| `created_at` | TIMESTAMPTZ | Data (auto) |

**Índice para Performance:**
- `idx_sale_items_sale_id` - busca itens de uma venda

---

## 🔐 Segurança e Autenticação

### RLS (Row Level Security)

Atualmente **desabilitado** para permitir acesso público interno:

```sql
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items DISABLE ROW LEVEL SECURITY;
```

⚠️ **Para produção com múltiplos usuários**, habilitar RLS:

```sql
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
-- Criar políticas por usuário
```

### Variáveis de Ambiente

- `NEXT_PUBLIC_SUPABASE_URL` - URL do projeto (pública)
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Chave anônima (pública)

✅ Prefixo `NEXT_PUBLIC_` significa que é exposto ao cliente

---

## 📡 Clientes Supabase

### Client-side (`lib/supabase/client.ts`)

```typescript
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(url, key)
}

// Uso em componentes React:
const supabase = createClient()
const { data } = await supabase.from("products").select()
```

**Quando usar:**
- ✅ Componentes React (Client Components)
- ✅ Interações do usuário
- ✅ SWR fetching

### Server-side (`lib/supabase/server.ts`)

```typescript
import { createServerClient } from '@supabase/ssr'

export async function createClient() {
  const cookieStore = await cookies()
  return createServerClient(url, key, { cookies: cookieStore })
}
```

**Quando usar:**
- ✅ Server Components
- ✅ API Routes
- ✅ Servidor Node.js

---

## ⚙️ Tecnologias Principais

### Frontend
- **Next.js 16** - Framework React com SSR/SSG
- **React 19** - UI library
- **TypeScript** - Type safety
- **TailwindCSS** - Utility-first CSS
- **Radix UI** - Headless UI primitives
- **SWR** - Data fetching hook
- **React Hook Form** - Form state management
- **Recharts** - Chart library
- **Lucide React** - Icons

### Backend
- **Next.js API Routes** - Serverless functions
- **Node.js** - JavaScript runtime

### Banco de Dados
- **PostgreSQL** (via Supabase)
- **Supabase** - Platform completa

---

## 🔄 Padrões de Código

### 1. Componentes com SWR

```typescript
const MyComponent = () => {
  const { data, isLoading, error } = useSWR(
    "chave-cache",
    async () => {
      return await supabase.from("tabela").select()
    },
    { dedupingInterval: 3000 } // Não fazer 2+ requests em 3s
  )

  if (isLoading) return <Skeleton />
  if (error) return <Error />
  return <YourUI data={data} />
}
```

### 2. Formulários com React Hook Form

```typescript
const { register, handleSubmit, watch } = useForm()

const onSubmit = async (data) => {
  await supabase.from("tabela").insert(data)
  mutate("chave") // Revalidar
}

return (
  <form onSubmit={handleSubmit(onSubmit)}>
    <input {...register("name")} />
    <button type="submit">Salvar</button>
  </form>
)
```

### 3. Cálculos (Exemplo: Margem de Lucro)

```typescript
// lib/utils.ts
export function calculateMinSalePrice(cost: number, margin: number): number {
  return cost * (1 + margin / 100)
}

// Uso em componente
const minPrice = calculateMinSalePrice(purchase, margin)
```

---

## 🚀 Performance

### Otimizações Implementadas

1. **SWR Caching**
   - `dedupingInterval: 3000` - Evita requisições duplicadas
   - `revalidateOnFocus: false` - Não refetch ao focar janela
   - `keepPreviousData: true` - Mantém dados antigos durante fetch

2. **Índices de Banco**
   - `idx_products_barcode` - Busca por código
   - `idx_products_name` - Busca por nome
   - `idx_sales_created_at` - Filtro de data

3. **Lazy Loading**
   - Componentes dinâmicos com `React.lazy()`
   - Código splitting automático do Next.js

4. **Image Optimization**
   - `<Image />` do Next.js com lazy loading

---

## 📝 Convenções

### Nomenclatura

- **Componentes**: `PascalCase` (ex: `EstoqueContent`)
- **Arquivos**: `kebab-case` (ex: `estoque-content.tsx`)
- **Variáveis**: `camelCase` (ex: `formData`)
- **Constantes**: `UPPERCASE` (ex: `DEFAULT_MARGIN`)
- **Tipos**: `PascalCase` + sufixo (ex: `ProductType`)

### TypeScript

```typescript
// Good
interface Product {
  id: string
  name: string
}

// Evitar
type Product = {
  id: string
  name: string
}
```

---

## 🐛 Debug

### Console do Navegador

```typescript
// Ver requisições SWR
console.log(data, isLoading, error)

// Debugar form
console.log(watch()) // React Hook Form
```

### Logs do Servidor

```bash
npm run dev
# Veja logs no terminal
```

### Supabase Studio

Acesse [supabase.com/dashboard](https://supabase.com/dashboard):
- Veja dados em tempo real
- Execute queries manualmente
- Monitore performance

---

## 📚 Referências

- [Next.js Docs](https://nextjs.org/docs)
- [Supabase Docs](https://supabase.com/docs)
- [React Docs](https://react.dev)
- [TailwindCSS](https://tailwindcss.com)
- [Radix UI](https://www.radix-ui.com)
- [SWR](https://swr.vercel.app)

---

**Última atualização**: 2026-04-20
