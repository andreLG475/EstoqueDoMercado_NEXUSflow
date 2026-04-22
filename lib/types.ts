export interface Product {
  id: string
  barcode: string
  name: string
  description: string | null
  purchase_price: number
  sale_price: number
  min_sale_price: number
  profit_margin: number
  stock_quantity: number
  min_stock: number
  category: string | null
  created_at: string
  updated_at: string
}

export interface Sale {
  id: string
  total: number
  payment_method: string
  amount_paid: number
  change_amount: number
  created_at: string
}

export interface SaleItem {
  id: string
  sale_id: string
  product_id: string
  product_name: string
  quantity: number
  unit_price: number
  subtotal: number
  created_at: string
}

export interface CartItem {
  product_id: string
  product_name: string
  quantity: number
  unit_price: number
  subtotal: number
  stock_available: number
}
