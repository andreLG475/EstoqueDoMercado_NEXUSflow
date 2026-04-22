"use client"

import { useState, useRef, useEffect, useCallback } from "react"
import { mutate } from "swr"
import { createClient } from "@/lib/supabase/client"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Badge } from "@/components/ui/badge"
import { 
  ShoppingCart, 
  Barcode, 
  Trash2, 
  Plus, 
  Minus, 
  CreditCard, 
  Banknote,
  CheckCircle2,
  AlertCircle,
  X
} from "lucide-react"
import { formatCurrency } from "@/lib/utils"
import type { Product, CartItem } from "@/lib/types"

const supabase = createClient()

export function PdvContent() {
  const [cart, setCart] = useState<CartItem[]>([])
  const [barcode, setBarcode] = useState("")
  const [isSearching, setIsSearching] = useState(false)
  const [error, setError] = useState("")
  const [isPaymentOpen, setIsPaymentOpen] = useState(false)
  const [paymentMethod, setPaymentMethod] = useState("dinheiro")
  const [amountPaid, setAmountPaid] = useState("")
  const [isProcessing, setIsProcessing] = useState(false)
  const [saleComplete, setSaleComplete] = useState(false)
  const [changeAmount, setChangeAmount] = useState(0)
  const barcodeInputRef = useRef<HTMLInputElement>(null)

  const total = cart.reduce((acc, item) => acc + item.subtotal, 0)

  useEffect(() => {
    barcodeInputRef.current?.focus()
  }, [])

  const searchProduct = useCallback(async (code: string) => {
    if (!code.trim()) return

    setIsSearching(true)
    setError("")

    try {
      const { data, error: fetchError } = await supabase
        .from("products")
        .select("id, name, barcode, sale_price, stock_quantity")
        .eq("barcode", code.trim())
        .single()

      if (fetchError || !data) {
        setError("Produto não encontrado")
        return
      }

      const product = data as Product

      if (product.stock_quantity <= 0) {
        setError("Produto sem estoque disponível")
        return
      }

      const existingItem = cart.find((item) => item.product_id === product.id)

      if (existingItem) {
        if (existingItem.quantity >= product.stock_quantity) {
          setError("Quantidade máxima em estoque atingida")
          return
        }

        setCart((prev) =>
          prev.map((item) =>
            item.product_id === product.id
              ? {
                  ...item,
                  quantity: item.quantity + 1,
                  subtotal: (item.quantity + 1) * item.unit_price,
                }
              : item
          )
        )
      } else {
        const newItem: CartItem = {
          product_id: product.id,
          product_name: product.name,
          quantity: 1,
          unit_price: Number(product.sale_price),
          subtotal: Number(product.sale_price),
          stock_available: product.stock_quantity,
        }
        setCart((prev) => [...prev, newItem])
      }

      setBarcode("")
    } catch {
      setError("Erro ao buscar produto")
    } finally {
      setIsSearching(false)
    }
  }, [cart])

  const handleBarcodeSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    searchProduct(barcode)
  }

  const updateQuantity = (productId: string, delta: number) => {
    setCart((prev) =>
      prev
        .map((item) => {
          if (item.product_id === productId) {
            const newQuantity = item.quantity + delta
            if (newQuantity <= 0) return null
            if (newQuantity > item.stock_available) return item
            return {
              ...item,
              quantity: newQuantity,
              subtotal: newQuantity * item.unit_price,
            }
          }
          return item
        })
        .filter(Boolean) as CartItem[]
    )
  }

  const removeItem = (productId: string) => {
    setCart((prev) => prev.filter((item) => item.product_id !== productId))
  }

  const clearCart = () => {
    setCart([])
    setError("")
    barcodeInputRef.current?.focus()
  }

  const openPayment = () => {
    if (cart.length === 0) return
    setAmountPaid("")
    setPaymentMethod("dinheiro")
    setIsPaymentOpen(true)
  }

  const calculateChange = () => {
    const paid = parseFloat(amountPaid) || 0
    return Math.max(0, paid - total)
  }

  const processPayment = async () => {
    const paid = parseFloat(amountPaid) || 0
    
    if (paymentMethod === "dinheiro" && paid < total) {
      setError("Valor pago insuficiente")
      return
    }

    setIsProcessing(true)
    setError("")

    try {
      const change = paymentMethod === "dinheiro" ? calculateChange() : 0
      const finalPaid = paymentMethod === "dinheiro" ? paid : total

      // Criar venda
      const { data: saleData, error: saleError } = await supabase
        .from("sales")
        .insert({
          total,
          payment_method: paymentMethod,
          amount_paid: finalPaid,
          change_amount: change,
        })
        .select()
        .single()

      if (saleError) throw saleError

      // Criar itens da venda
      const saleItems = cart.map((item) => ({
        sale_id: saleData.id,
        product_id: item.product_id,
        product_name: item.product_name,
        quantity: item.quantity,
        unit_price: item.unit_price,
        subtotal: item.subtotal,
      }))

      const { error: itemsError } = await supabase
        .from("sale_items")
        .insert(saleItems)

      if (itemsError) throw itemsError

      // Atualizar estoque
      for (const item of cart) {
        const { error: updateError } = await supabase.rpc("decrement_stock", {
          product_id: item.product_id,
          quantity: item.quantity,
        }).maybeSingle()
        
        // Se RPC não existir, fazer update direto
        if (updateError) {
          await supabase
            .from("products")
            .update({ 
              stock_quantity: item.stock_available - item.quantity 
            })
            .eq("id", item.product_id)
        }
      }

      setChangeAmount(change)
      setSaleComplete(true)
      mutate("products")
      mutate("dashboard")
    } catch (err) {
      console.error("Erro ao processar venda:", err)
      setError("Erro ao processar pagamento")
    } finally {
      setIsProcessing(false)
    }
  }

  const finishSale = () => {
    setCart([])
    setSaleComplete(false)
    setIsPaymentOpen(false)
    setChangeAmount(0)
    barcodeInputRef.current?.focus()
  }

  return (
    <div className="p-6 h-full">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-full">
        {/* Área de leitura e lista de produtos */}
        <div className="lg:col-span-2 space-y-4">
          <Card className="border-0 shadow-sm">
            <CardHeader className="pb-4">
              <CardTitle className="flex items-center gap-2">
                <Barcode className="w-5 h-5" />
                Leitura de Código de Barras
              </CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleBarcodeSubmit} className="flex gap-3">
                <div className="relative flex-1">
                  <Input
                    ref={barcodeInputRef}
                    type="text"
                    placeholder="Digite ou escaneie o código de barras..."
                    value={barcode}
                    onChange={(e) => setBarcode(e.target.value)}
                    className="text-lg h-12"
                    autoFocus
                  />
                </div>
                <Button type="submit" size="lg" disabled={isSearching}>
                  {isSearching ? "Buscando..." : "Adicionar"}
                </Button>
              </form>
              {error && (
                <div className="flex items-center gap-2 mt-3 text-destructive">
                  <AlertCircle className="w-4 h-4" />
                  <span className="text-sm">{error}</span>
                </div>
              )}
            </CardContent>
          </Card>

          <Card className="border-0 shadow-sm flex-1">
            <CardHeader className="pb-4">
              <div className="flex items-center justify-between">
                <CardTitle className="flex items-center gap-2">
                  <ShoppingCart className="w-5 h-5" />
                  Itens do Carrinho
                </CardTitle>
                {cart.length > 0 && (
                  <Button variant="ghost" size="sm" onClick={clearCart} className="text-destructive hover:text-destructive">
                    <Trash2 className="w-4 h-4 mr-2" />
                    Limpar
                  </Button>
                )}
              </div>
            </CardHeader>
            <CardContent>
              {cart.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <ShoppingCart className="w-16 h-16 mx-auto mb-4 opacity-20" />
                  <p>Carrinho vazio</p>
                  <p className="text-sm">Escaneie um produto para começar</p>
                </div>
              ) : (
                <div className="space-y-3 max-h-[400px] overflow-y-auto">
                  {cart.map((item) => (
                    <div
                      key={item.product_id}
                      className="flex items-center justify-between p-4 bg-muted/50 rounded-lg"
                    >
                      <div className="flex-1">
                        <p className="font-medium">{item.product_name}</p>
                        <p className="text-sm text-muted-foreground">
                          {formatCurrency(item.unit_price)} cada
                        </p>
                      </div>
                      <div className="flex items-center gap-3">
                        <div className="flex items-center gap-2">
                          <Button
                            variant="outline"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => updateQuantity(item.product_id, -1)}
                          >
                            <Minus className="w-4 h-4" />
                          </Button>
                          <span className="w-8 text-center font-medium">
                            {item.quantity}
                          </span>
                          <Button
                            variant="outline"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => updateQuantity(item.product_id, 1)}
                            disabled={item.quantity >= item.stock_available}
                          >
                            <Plus className="w-4 h-4" />
                          </Button>
                        </div>
                        <p className="w-24 text-right font-bold">
                          {formatCurrency(item.subtotal)}
                        </p>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="text-destructive hover:text-destructive"
                          onClick={() => removeItem(item.product_id)}
                        >
                          <X className="w-4 h-4" />
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Resumo da venda */}
        <div className="space-y-4">
          <Card className="border-0 shadow-sm bg-primary text-primary-foreground">
            <CardContent className="pt-6">
              <p className="text-sm opacity-80 mb-2">Total da Compra</p>
              <p className="text-4xl font-bold">{formatCurrency(total)}</p>
              <p className="text-sm opacity-80 mt-2">
                {cart.length} {cart.length === 1 ? "item" : "itens"}
              </p>
            </CardContent>
          </Card>

          <Card className="border-0 shadow-sm">
            <CardContent className="pt-6 space-y-3">
              <Button
                className="w-full h-14 text-lg gap-2"
                onClick={openPayment}
                disabled={cart.length === 0}
              >
                <CreditCard className="w-5 h-5" />
                Finalizar Venda
              </Button>
              <Button
                variant="outline"
                className="w-full"
                onClick={clearCart}
                disabled={cart.length === 0}
              >
                Cancelar Venda
              </Button>
            </CardContent>
          </Card>

          <Card className="border-0 shadow-sm">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Atalhos
              </CardTitle>
            </CardHeader>
            <CardContent className="text-sm space-y-2 text-muted-foreground">
              <p><Badge variant="secondary">Enter</Badge> Adicionar produto</p>
              <p><Badge variant="secondary">F2</Badge> Finalizar venda</p>
              <p><Badge variant="secondary">Esc</Badge> Cancelar</p>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Modal de Pagamento */}
      <Dialog open={isPaymentOpen} onOpenChange={setIsPaymentOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>
              {saleComplete ? "Venda Concluída" : "Finalizar Pagamento"}
            </DialogTitle>
          </DialogHeader>

          {saleComplete ? (
            <div className="text-center py-6">
              <CheckCircle2 className="w-16 h-16 mx-auto text-success mb-4" />
              <p className="text-2xl font-bold mb-2">Pagamento Confirmado!</p>
              {changeAmount > 0 && (
                <div className="bg-warning/10 p-4 rounded-lg mt-4">
                  <p className="text-sm text-warning-foreground">Troco a devolver:</p>
                  <p className="text-3xl font-bold text-warning">
                    {formatCurrency(changeAmount)}
                  </p>
                </div>
              )}
              <Button onClick={finishSale} className="w-full mt-6">
                Nova Venda
              </Button>
            </div>
          ) : (
            <div className="space-y-6">
              <div className="text-center py-4 bg-muted rounded-lg">
                <p className="text-sm text-muted-foreground">Total a Pagar</p>
                <p className="text-3xl font-bold">{formatCurrency(total)}</p>
              </div>

              <div className="space-y-2">
                <Label>Forma de Pagamento</Label>
                <Select value={paymentMethod} onValueChange={setPaymentMethod}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="dinheiro">
                      <div className="flex items-center gap-2">
                        <Banknote className="w-4 h-4" />
                        Dinheiro
                      </div>
                    </SelectItem>
                    <SelectItem value="credito">
                      <div className="flex items-center gap-2">
                        <CreditCard className="w-4 h-4" />
                        Cartão de Crédito
                      </div>
                    </SelectItem>
                    <SelectItem value="debito">
                      <div className="flex items-center gap-2">
                        <CreditCard className="w-4 h-4" />
                        Cartão de Débito
                      </div>
                    </SelectItem>
                    <SelectItem value="pix">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-xs">PIX</span>
                        PIX
                      </div>
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {paymentMethod === "dinheiro" && (
                <div className="space-y-2">
                  <Label htmlFor="amountPaid">Valor Recebido</Label>
                  <Input
                    id="amountPaid"
                    type="number"
                    step="0.01"
                    min={total}
                    value={amountPaid}
                    onChange={(e) => setAmountPaid(e.target.value)}
                    placeholder="0,00"
                    className="text-lg h-12"
                  />
                  {parseFloat(amountPaid) >= total && (
                    <div className="bg-success/10 p-3 rounded-lg">
                      <p className="text-sm text-success">Troco:</p>
                      <p className="text-xl font-bold text-success">
                        {formatCurrency(calculateChange())}
                      </p>
                    </div>
                  )}
                </div>
              )}

              {error && (
                <div className="flex items-center gap-2 text-destructive">
                  <AlertCircle className="w-4 h-4" />
                  <span className="text-sm">{error}</span>
                </div>
              )}

              <div className="flex gap-3">
                <Button
                  variant="outline"
                  className="flex-1"
                  onClick={() => setIsPaymentOpen(false)}
                >
                  Cancelar
                </Button>
                <Button
                  className="flex-1"
                  onClick={processPayment}
                  disabled={
                    isProcessing ||
                    (paymentMethod === "dinheiro" && parseFloat(amountPaid) < total)
                  }
                >
                  {isProcessing ? "Processando..." : "Confirmar Pagamento"}
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
