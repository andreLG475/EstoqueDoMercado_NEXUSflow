-- ============================================================
-- NEXUS flow - Script 003
-- CPF do cliente na nota fiscal (informado, opcionalmente, no
-- fechamento da venda no PDV)
-- Execute APÓS o script 002_auth_roles_invoices.sql
-- ============================================================

ALTER TABLE sales ADD COLUMN IF NOT EXISTS customer_cpf TEXT;

-- CREATE OR REPLACE FUNCTION não substitui uma função quando a lista de
-- parâmetros muda (vira uma sobrecarga nova) — removemos a assinatura
-- antiga explicitamente antes de recriar com o novo parâmetro.
DROP FUNCTION IF EXISTS create_sale(UUID, TEXT, NUMERIC, JSONB);

CREATE OR REPLACE FUNCTION create_sale(
  p_user_id UUID,
  p_payment_method TEXT,
  p_amount_paid NUMERIC,
  p_items JSONB,  -- [{"product_id": "...", "quantity": 1}, ...]
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

  INSERT INTO sales (total, payment_method, amount_paid, change_amount, invoice_number, user_id, customer_cpf)
  VALUES (v_total, p_payment_method, v_paid, v_change, v_invoice_number, p_user_id, p_customer_cpf)
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
