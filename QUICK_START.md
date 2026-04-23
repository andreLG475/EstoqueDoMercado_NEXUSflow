# Guia Rápido - NEXUS flow

Siga este guia para colocar o NEXUS flow rodando em 5 minutos!

## 1. Pré-requisitos

- Node.js 18+ instalado ([Download](https://nodejs.org/))
- Uma conta Supabase ([Criar aqui](https://supabase.com))

## 2. Clone o Repositório

```bash
git clone https://github.com/seu-usuario/nexus-flow.git
cd nexus-flow
```

## 3. Instale as Dependências

```bash
npm install
```

## 4. Configure o Supabase

### A. Crie um Projeto Supabase

1. Vá para [supabase.com](https://supabase.com)
2. Clique em "New Project"
3. Escolha um nome e senha
4. Aguarde o projeto ser criado

### B. Execute o Script SQL

1. No painel do Supabase, vá para **SQL Editor**
2. Clique em **New Query**
3. Copie o conteúdo do arquivo `scripts/001_create_tables.sql`
4. Cole no editor e clique em **Run**

### C. Obtenha as Credenciais

1. Vá para **Settings** → **API**
2. Copie:
   - **Project URL** (URL do projeto)
   - **anon public** (chave anonima)

## 5. Configure Variáveis de Ambiente

Crie um arquivo `.env.local` na raiz do projeto:

```env
NEXT_PUBLIC_SUPABASE_URL=https://seu-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sua-chave-aqui
```

## 6. Inicie o Servidor

```bash
npm run dev
```

Pronto! Acesse `http://localhost:3000`

---

## ❓ Dúvidas?

Consulte o [`README.md`](README.md) para documentação completa.

## Checklist de Setup

- [ ] Node.js instalado
- [ ] Repositório clonado
- [ ] Dependências instaladas (`npm install`)
- [ ] Projeto Supabase criado
- [ ] Tabelas criadas (SQL executado)
- [ ] `.env.local` configurado
- [ ] Servidor rodando (`npm run dev`)
- [ ] Acesso em `http://localhost:3000`

Qualquer dúvida, consulte o README.md ou a seção Troubleshooting!
