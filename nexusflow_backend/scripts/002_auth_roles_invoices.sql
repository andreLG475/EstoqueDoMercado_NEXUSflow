-- ============================================================
-- NEXUS flow - Script 002
-- Autenticação própria (sem Supabase), Papéis (roles), Nota Fiscal
-- Execute APÓS o script 001_create_tables.sql
-- ============================================================

-- ------------------------------------------------------------
-- 1. PERFIS DE USUÁRIO (autenticação própria, senha com hash)
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 2. NOTA FISCAL: numeração sequencial e vínculo com a venda
-- ------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START 1;

ALTER TABLE sales ADD COLUMN IF NOT EXISTS invoice_number BIGINT UNIQUE;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES profiles(id);

CREATE INDEX IF NOT EXISTS idx_sales_user_id ON sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_invoice_number ON sales(invoice_number);

-- ------------------------------------------------------------
-- 3. VENDA ATÔMICA (create_sale)
--    Insere venda + itens, baixa estoque e emite nº de NF em
--    uma única transação. Preços são lidos do banco (não do cliente).
--    Autorização por papel é checada na API route; aqui validamos
--    de novo lendo o papel do usuário informado (defesa em profundidade,
--    já que não há mais auth.uid()/RLS do Supabase).
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_sale(
  p_user_id UUID,
  p_payment_method TEXT,
  p_amount_paid NUMERIC,
  p_items JSONB  -- [{"product_id": "...", "quantity": 1}, ...]
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
  -- Autorização: apenas atendente e gerente geral vendem
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

  -- Calcula o total com preços do banco e valida estoque (com lock)
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

  -- Pagamento
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

  INSERT INTO sales (total, payment_method, amount_paid, change_amount, invoice_number, user_id)
  VALUES (v_total, p_payment_method, v_paid, v_change, v_invoice_number, p_user_id)
  RETURNING id INTO v_sale_id;

  -- Itens + baixa de estoque
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

-- ------------------------------------------------------------
-- Observação sobre segurança:
-- Sem Supabase, a única credencial que fala com este banco é a
-- da própria aplicação (DATABASE_URL). Não há RLS nem múltiplos
-- papéis de conexão — a autorização por papel (gerente_geral,
-- gerente_estoque, atendente) é aplicada nas API routes do Next.js
-- e, para vendas, também dentro de create_sale() acima.
-- ------------------------------------------------------------
