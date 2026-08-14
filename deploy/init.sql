-- Script de inicialização completo do banco de dados NexusFlow
-- Este arquivo é executado automaticamente quando o container do PostgreSQL
-- é criado pela primeira vez.

-- ============================================================
-- 001 - Tabelas principais
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  purchase_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
  sale_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
  min_sale_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
  profit_margin DECIMAL(5, 2) NOT NULL DEFAULT 30,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  min_stock INTEGER NOT NULL DEFAULT 5,
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  total DECIMAL(10, 2) NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL DEFAULT 'dinheiro',
  amount_paid DECIMAL(10, 2) NOT NULL DEFAULT 0,
  change_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sale_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10, 2) NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- 002 - Autenticação, Papéis e Nota Fiscal
-- ============================================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'atendente'
    CHECK (role IN ('gerente_geral', 'gerente_estoque', 'atendente')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START 1;

ALTER TABLE sales ADD COLUMN IF NOT EXISTS invoice_number BIGINT UNIQUE;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES profiles(id);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS customer_cpf TEXT;

CREATE INDEX IF NOT EXISTS idx_sales_user_id ON sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_invoice_number ON sales(invoice_number);

-- ============================================================
-- 003 - Função create_sale (com CPF do cliente)
-- ============================================================

CREATE OR REPLACE FUNCTION create_sale(
  p_user_id UUID,
  p_payment_method TEXT,
  p_amount_paid NUMERIC,
  p_items JSONB,
  p_customer_cpf TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_role TEXT;
  v_item JSONB;
  v_product RECORD;
  v_qty INTEGER;
  v_total NUMERIC(10,2) := 0;
  v_sale_id UUID;
  v_invoice_number BIGINT;
  v_change NUMERIC(10,2) := 0;
  v_paid NUMERIC(10,2);
BEGIN
  SELECT role INTO v_role FROM profiles WHERE id = p_user_id;
  IF v_role IS NULL OR v_role NOT IN ('atendente', 'gerente_geral') THEN
    RAISE EXCEPTION 'Usuário sem permissão para registrar vendas';
  END IF;

  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'A venda precisa de ao menos um item';
  END IF;

  IF p_payment_method NOT IN ('dinheiro', 'credito', 'debito', 'pix') THEN
    RAISE EXCEPTION 'Forma de pagamento inválida';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_qty := (v_item ->> 'quantity')::INTEGER;
    IF v_qty IS NULL OR v_qty <= 0 THEN
      RAISE EXCEPTION 'Quantidade inválida';
    END IF;

    SELECT id, name, sale_price, stock_quantity INTO v_product
    FROM products
    WHERE id = (v_item ->> 'product_id')::UUID
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Produto não encontrado: %', v_item ->> 'product_id';
    END IF;

    IF v_product.stock_quantity < v_qty THEN
      RAISE EXCEPTION 'Estoque insuficiente para o produto %', v_product.name;
    END IF;

    v_total := v_total + (v_product.sale_price * v_qty);
  END LOOP;

  IF p_payment_method = 'dinheiro' THEN
    v_paid := COALESCE(p_amount_paid, 0);
    IF v_paid < v_total THEN
      RAISE EXCEPTION 'Valor pago insuficiente';
    END IF;
    v_change := v_paid - v_total;
  ELSE
    v_paid := v_total;
    v_change := 0;
  END IF;

  v_invoice_number := nextval('invoice_number_seq');

  INSERT INTO sales (total, payment_method, amount_paid, change_amount, invoice_number, user_id, customer_cpf)
  VALUES (v_total, p_payment_method, v_paid, v_change, v_invoice_number, p_user_id, p_customer_cpf)
  RETURNING id INTO v_sale_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_qty := (v_item ->> 'quantity')::INTEGER;

    SELECT id, name, sale_price INTO v_product
    FROM products WHERE id = (v_item ->> 'product_id')::UUID;

    INSERT INTO sale_items (sale_id, product_id, product_name, quantity, unit_price, subtotal)
    VALUES (v_sale_id, v_product.id, v_product.name, v_qty, v_product.sale_price, v_product.sale_price * v_qty);

    UPDATE products
    SET stock_quantity = stock_quantity - v_qty
    WHERE id = v_product.id;
  END LOOP;

  RETURN jsonb_build_object(
    'sale_id', v_sale_id,
    'invoice_number', v_invoice_number,
    'total', v_total,
    'amount_paid', v_paid,
    'change_amount', v_change
  );
END;
$$;
