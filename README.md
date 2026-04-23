# NEXUS flow - Sistema de Gestão Integrado

Um sistema completo de gestão para pequenos e médios negócios, desenvolvido com as tecnologias mais modernas. Gerencia **estoque**, **ponto de venda (PDV)** e **relatórios** em tempo real.

---

## Sumário

- [Sobre](#sobre)
- [Tecnologias](#tecnologias)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Instalação e Setup](#instalação-e-setup)
- [Configuração do Banco de Dados](#configuração-do-banco-de-dados)
- [Variáveis de Ambiente](#variáveis-de-ambiente)
- [Como Usar](#como-usar)
- [Scripts Disponíveis](#scripts-disponíveis)

---

## Sobre

NEXUS flow é um sistema integrado que permite gerenciar sua loja ou negócio com facilidade. O sistema oferece:

- Dashboard - Visão geral com estatísticas em tempo real
- Controle de Estoque - Cadastro, edição e exclusão de produtos
- PDV (Ponto de Venda) - Registro de vendas com cálculo automático
- Relatórios - Análise de vendas, estoque e desempenho

---

## Tecnologias

### Frontend
- **Next.js 16** - Framework React com SSR
- **React 19** - Biblioteca UI
- **TypeScript** - Type safety
- **TailwindCSS** - Estilização
- **Radix UI** - Componentes acessíveis
- **Recharts** - Gráficos e dashboards
- **SWR** - Fetching de dados com cache

### Backend
- **Next.js API Routes** - Endpoints backend
- **Supabase** - PostgreSQL + Authentication
- **Node.js** - Runtime JavaScript

### Banco de Dados
- **PostgreSQL** (via Supabase)
- **Tabelas**: `products`, `sales`, `sale_items`

---

## Estrutura do Projeto

```
NEXUS flow/
├── app/                        # Páginas Next.js
│   ├── layout.tsx             # Layout principal
│   ├── page.tsx               # Dashboard
│   ├── estoque/               # Página de estoque
│   ├── pdv/                   # Página de vendas
│   └── relatorios/            # Página de relatórios
│
├── components/                # Componentes React reutilizáveis
│   ├── app-sidebar.tsx        # Sidebar da aplicação
│   ├── dashboard-content.tsx  # Conteúdo do dashboard
│   ├── estoque-content.tsx    # Formulário e tabela de produtos
│   ├── pdv-content.tsx        # Sistema de vendas
│   ├── relatorios-content.tsx # Gráficos e relatórios
│   └── ui/                    # Componentes base (Button, Input, Dialog, etc)
│
├── lib/                       # Utilitários e configurações
│   ├── supabase/
│   │   ├── client.ts         # Cliente Supabase (browser)
│   │   └── server.ts         # Cliente Supabase (server)
│   ├── types.ts              # Tipos TypeScript
│   └── utils.ts              # Funções helper
│
├── public/                    # Arquivos estáticos
│   └── images/               # Imagens (logo, etc)
│
├── scripts/                   # Scripts SQL
│   └── 001_create_tables.sql # Script para criar tabelas
│
├── .env.local                # Variáveis de ambiente (NÃO commitar)
├── next.config.mjs           # Configuração Next.js
├── tsconfig.json             # Configuração TypeScript
├── tailwind.config.ts        # Configuração TailwindCSS
└── package.json              # Dependências do projeto
```

---

## Instalação e Setup

### Pré-requisitos

- Node.js 18+ ([Download](https://nodejs.org/))
- pnpm (já vem com o projeto)

### Passo a Passo

**1. Instalar dependências:**

```bash
pnpm install
```

**2. Criar arquivo de configuração:**

Crie um arquivo `.env.local` na raiz do projeto com:

```env
NEXT_PUBLIC_SUPABASE_URL=https://seu-projeto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sua-chave-aqui
```

**3. Criar banco de dados:**

1. Crie uma conta em [Supabase](https://supabase.com) e um novo projeto
2. Vá em **SQL Editor** e execute o conteúdo de `scripts/001_create_tables.sql`
3. Em **Settings → API**, copie a URL do projeto e a chave `anon public`

**4. Rodar o projeto:**

```bash
pnpm dev
```

Acesse `http://localhost:3000`

---

## Configuração do Banco de Dados

### Tabelas Criadas

#### `products` - Produtos/Estoque
```sql
- id (UUID) - ID único
- barcode (TEXT) - Código de barras
- name (TEXT) - Nome do produto
- description (TEXT) - Descrição
- purchase_price (DECIMAL) - Preço de custo
- sale_price (DECIMAL) - Preço de venda
- min_sale_price (DECIMAL) - Preço mínimo de venda
- profit_margin (DECIMAL) - Margem de lucro (%)
- stock_quantity (INTEGER) - Quantidade em estoque
- min_stock (INTEGER) - Estoque mínimo
- category (TEXT) - Categoria do produto
- created_at, updated_at (TIMESTAMPTZ) - Datas
```

#### `sales` - Vendas
```sql
- id (UUID) - ID único
- total (DECIMAL) - Valor total
- payment_method (TEXT) - Método de pagamento
- amount_paid (DECIMAL) - Valor pago
- change_amount (DECIMAL) - Troco
- created_at (TIMESTAMPTZ) - Data da venda
```

#### `sale_items` - Itens da Venda
```sql
- id (UUID) - ID único
- sale_id (UUID) - Referência da venda
- product_id (UUID) - Referência do produto
- product_name (TEXT) - Nome do produto
- quantity (INTEGER) - Quantidade
- unit_price (DECIMAL) - Preço unitário
- subtotal (DECIMAL) - Subtotal
- created_at (TIMESTAMPTZ) - Data
```

### Executar Migrações (Criar Tabelas)

No painel Supabase, vá para **SQL Editor** e execute o arquivo `scripts/001_create_tables.sql`.

---

## Variáveis de Ambiente

Crie um arquivo `.env.local` na raiz do projeto com as seguintes variáveis:

```env
NEXT_PUBLIC_DEV_SUPABASE_REDIRECT_URL=https://v0.app/chat/api/supabase/redirect/f5zS1U0mcWx
NEXT_PUBLIC_SUPABASE_URL=https://ehyqfrvmjdwldnwviqif.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVoeXFmcnZtamR3bGRud3ZpcWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2NjkwNDMsImV4cCI6MjA5MjI0NTA0M30.LuMJsw-JV4264mFjNm519hSQSMBZ-IlXmZkLpB2dgwo

```

### Como Obter as Chaves Supabase?

1. Acesse [dashboard.supabase.com](https://dashboard.supabase.com)
2. Selecione seu projeto
3. Vá para **Settings** → **API**
4. Copie:
   - `Project URL` → `NEXT_PUBLIC_SUPABASE_URL`
   - `anon public` key → `NEXT_PUBLIC_SUPABASE_ANON_KEY`

IMPORTANTE: Não commitar o arquivo `.env.local`. Adicione ao `.gitignore`:
```
.env.local
.env.*.local
```

---

## Como Usar

### Dashboard
Visão geral com:
- Total de produtos
- Vendas realizadas
- Faturamento do dia
- Produtos em baixa
- Valor total em estoque
- Últimas vendas

### Estoque

1. Clique em **"Novo Produto"**
2. Preencha os dados:
   - **Código de Barras** - Identificador único
   - **Nome** - Nome do produto
   - **Categoria** - Categoria opcional
   - **Preço de Compra** - Custo
   - **Margem de Lucro** - Percentual (calcula preço mínimo)
   - **Preço de Venda** - Preço final (mínimo calculado)
   - **Quantidade** - Estoque inicial
   - **Estoque Mínimo** - Alerta ao atingir

3. Clique em **"Cadastrar"**
4. Para editar ou deletar, use os botões de ação na tabela

### PDV (Ponto de Venda)

1. Adicione produtos ao carrinho (por código ou nome)
2. Ajuste quantidades
3. Escolha método de pagamento
4. Insira valor recebido
5. O troco é calculado automaticamente
6. Clique em **"Finalizar Venda"**

### Relatórios

Visualize:
- Vendas por período
- Produtos mais vendidos
- Análise de estoque
- Receita por categoria
- Gráficos dinâmicos

---

## Scripts Disponíveis

```bash
# Desenvolvimento (com reload automático)
npm run dev
pnpm dev

# Build para produção
npm run build
pnpm build

# Iniciar servidor de produção
npm start
pnpm start

# Lint/Verificar código
npm run lint
pnpm lint
```

---

## Troubleshooting

### "Variáveis de ambiente ausentes"
- Verifique se `.env.local` existe
- Confirme `NEXT_PUBLIC_SUPABASE_URL` e `NEXT_PUBLIC_SUPABASE_ANON_KEY`

### "Erro ao conectar ao banco"
- Teste a conexão em [Supabase Dashboard](https://supabase.com/dashboard)
- Confirme que as tabelas foram criadas (execute `001_create_tables.sql`)
- Reinicie o servidor: `npm run dev`

### "Página em branco ou componentes não carregam"
- Limpe cache: `rm -rf .next` (ou delete a pasta `.next`)
- Reinstale dependências: `rm -rf node_modules && npm install`
- Reinicie o servidor

### "Porta 3000 já em uso"
```bash
# Use outra porta
npm run dev -- -p 3001
```

---

## Documentação Útil

- [Next.js Documentation](https://nextjs.org/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [TailwindCSS](https://tailwindcss.com/docs)
- [Radix UI](https://www.radix-ui.com/docs/primitives/overview/introduction)
- [React Hook Form](https://react-hook-form.com/)

---

## Deploy

### Deploy no Vercel

1. Faça push do código para um repositório GitHub
2. Acesse [vercel.com](https://vercel.com) e conecte seu repositório
3. Configure as variáveis de ambiente no painel Vercel
4. Clique em "Deploy"

### Deploy Manual

```bash
npm run build
npm start
```

---

## Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/NovaFuncionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

---

## Licença

Este projeto é fornecido como está. Livre para uso pessoal e comercial.

---

## Suporte

Se encontrar problemas:
1. Verifique o console do navegador (F12)
2. Consulte a seção [Troubleshooting](#troubleshooting)
3. Abra uma issue no repositório

---

## Mapa Completo de Arquivos

```
NEXUS flow/
├── app/                              # Páginas principais do Next.js
│   ├── globals.css                   # Estilos globais da aplicação
│   ├── layout.tsx                    # Layout principal (root layout)
│   ├── page.tsx                      # Página inicial (Dashboard)
│   ├── estoque/
│   │   └── page.tsx                  # Página de Controle de Estoque
│   ├── pdv/
│   │   └── page.tsx                  # Página do Ponto de Venda (PDV)
│   └── relatorios/
│       └── page.tsx                  # Página de Relatórios
│
├── components/                       # Componentes React
│   ├── app-layout.tsx                # Layout principal da aplicação
│   ├── app-sidebar.tsx               # Sidebar de navegação
│   ├── dashboard-content.tsx         # Conteúdo do Dashboard
│   ├── estoque-content.tsx           # Formulário e tabela de produtos
│   ├── pdv-content.tsx               # Sistema de vendas/PDV
│   ├── relatorios-content.tsx        # Gráficos e relatórios
│   ├── theme-provider.tsx            # Provider de tema (dark/light)
│   │
│   └── ui/                           # Componentes base (Radix UI + Shadcn)
│       ├── accordion.tsx             # Componente Accordion
│       ├── alert.tsx                 # Componente Alert
│       ├── alert-dialog.tsx          # Componente Alert Dialog
│       ├── aspect-ratio.tsx          # Componente Aspect Ratio
│       ├── avatar.tsx                # Componente Avatar
│       ├── badge.tsx                 # Componente Badge
│       ├── breadcrumb.tsx            # Componente Breadcrumb
│       ├── button.tsx                # Componente Button
│       ├── button-group.tsx          # Componente Button Group
│       ├── calendar.tsx              # Componente Calendar
│       ├── card.tsx                  # Componente Card
│       ├── carousel.tsx              # Componente Carousel
│       ├── chart.tsx                 # Componente Chart (Recharts)
│       ├── checkbox.tsx              # Componente Checkbox
│       ├── collapsible.tsx           # Componente Collapsible
│       ├── command.tsx               # Componente Command
│       ├── context-menu.tsx          # Componente Context Menu
│       ├── dialog.tsx                # Componente Dialog
│       ├── drawer.tsx                # Componente Drawer
│       ├── dropdown-menu.tsx         # Componente Dropdown Menu
│       ├── empty.tsx                 # Componente Empty
│       ├── field.tsx                 # Componente Field
│       ├── form.tsx                  # Componente Form
│       ├── hover-card.tsx            # Componente Hover Card
│       ├── input.tsx                 # Componente Input
│       ├── input-group.tsx           # Componente Input Group
│       ├── input-otp.tsx             # Componente Input OTP
│       ├── item.tsx                  # Componente Item
│       ├── kbd.tsx                   # Componente Keyboard (Kbd)
│       ├── label.tsx                 # Componente Label
│       ├── menubar.tsx               # Componente Menu Bar
│       ├── navigation-menu.tsx       # Componente Navigation Menu
│       ├── pagination.tsx            # Componente Pagination
│       ├── popover.tsx               # Componente Popover
│       ├── progress.tsx              # Componente Progress
│       ├── radio-group.tsx           # Componente Radio Group
│       ├── resizable.tsx             # Componente Resizable
│       ├── scroll-area.tsx           # Componente Scroll Area
│       ├── select.tsx                # Componente Select
│       ├── separator.tsx             # Componente Separator
│       ├── sheet.tsx                 # Componente Sheet
│       ├── sidebar.tsx               # Componente Sidebar
│       ├── skeleton.tsx              # Componente Skeleton
│       ├── slider.tsx                # Componente Slider
│       ├── sonner.tsx                # Componente Sonner (toast)
│       ├── spinner.tsx               # Componente Spinner
│       ├── switch.tsx                # Componente Switch
│       ├── table.tsx                 # Componente Table
│       ├── tabs.tsx                  # Componente Tabs
│       ├── textarea.tsx              # Componente Textarea
│       ├── toast.tsx                 # Componente Toast
│       ├── toaster.tsx               # Componente Toaster
│       ├── toggle.tsx                # Componente Toggle
│       ├── toggle-group.tsx          # Componente Toggle Group
│       ├── tooltip.tsx               # Componente Tooltip
│       ├── use-mobile.tsx            # Hook useMobile (mobile detection)
│       └── use-toast.ts              # Hook useToast (toast management)
│
├── hooks/                            # Custom Hooks
│   ├── use-mobile.ts                 # Hook para detectar dispositivos móveis
│   └── use-toast.ts                  # Hook para gerenciamento de toasts
│
├── lib/                              # Utilitários e configurações
│   ├── supabase/
│   │   ├── client.ts                 # Cliente Supabase (browser/client-side)
│   │   └── server.ts                 # Cliente Supabase (server-side)
│   ├── types.ts                      # Definições de tipos TypeScript
│   └── utils.ts                      # Funções utilitárias (cn, formatação)
│
├── public/                           # Arquivos estáticos públicos
│   └── images/
│       └── logo.png                  # Logo da aplicação
│
├── scripts/                          # Scripts SQL e utilitários
│   └── 001_create_tables.sql         # Script de criação das tabelas do banco
│
├── styles/                           # Estilos adicionais
│   └── globals.css                   # Estilos globais alternativos
│
├── .env.example                      # Exemplo de variáveis de ambiente
├── .env.local                        # Variáveis de ambiente locais (desenvolvimento)
├── .env.local.example                # Exemplo de .env.local
├── .gitignore                        # Arquivos ignorados pelo Git
├── ARCHITECTURE.md                   # Documentação de arquitetura
├── components.json                   # Configuração de componentes Shadcn
├── next.config.mjs                   # Configuração do Next.js
├── next-env.d.ts                     # Tipos TypeScript do Next.js
├── package.json                      # Dependências do projeto
├── package-lock.json                 # Lockfile do npm
├── pnpm-lock.yaml                    # Lockfile do pnpm
├── postcss.config.mjs                # Configuração do PostCSS
├── QUICK_START.md                    # Guia de início rápido
├── README.md                         # Documentação principal
├── test-db.ts                        # Script de teste de banco de dados
└── tsconfig.json                     # Configuração do TypeScript
```

---

Desenvolvido para gerenciar negócios com eficiência
