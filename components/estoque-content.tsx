"use client"

import { useState, useMemo } from "react"
import useSWR, { mutate } from "swr"
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
  DialogTrigger,
  DialogPortal,
} from "@/components/ui/dialog"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { Plus, Pencil, Trash2, Search, Package } from "lucide-react"
import { formatCurrency, calculateMinSalePrice } from "@/lib/utils"
import type { Product } from "@/lib/types"

const supabase = createClient()

async function fetchProducts() {
  const { data, error } = await supabase
    .from("products")
    .select("id, barcode, name, description, category, purchase_price, sale_price, min_sale_price, profit_margin, stock_quantity, min_stock")
    .order("name", { ascending: true })
    .limit(500)
  
  if (error) throw error
  return data as Product[]
}

const emptyProduct = {
  barcode: "",
  name: "",
  description: "",
  purchase_price: 0,
  profit_margin: 30,
  sale_price: 0,
  stock_quantity: 0,
  min_stock: 5,
  category: "",
}

export function EstoqueContent() {
  const { data: products, isLoading } = useSWR("products", fetchProducts, {
    dedupingInterval: 3000,
    revalidateOnFocus: false,
    keepPreviousData: true,
  })
  const [searchTerm, setSearchTerm] = useState("")
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingProduct, setEditingProduct] = useState<Product | null>(null)
  const [formData, setFormData] = useState(emptyProduct)
  const [isSaving, setIsSaving] = useState(false)

  const filteredProducts = useMemo(() => {
    if (!searchTerm) return products
    const term = searchTerm.toLowerCase()
    return products?.filter(
      (p) =>
        p.name.toLowerCase().includes(term) ||
        p.barcode.includes(searchTerm) ||
        p.category?.toLowerCase().includes(term)
    )
  }, [products, searchTerm])

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type } = e.target
    const newValue = type === "number" ? parseFloat(value) || 0 : value
    
    setFormData((prev) => {
      const updated = { ...prev, [name]: newValue }
      
      if (name === "purchase_price" || name === "profit_margin") {
        const purchasePrice = name === "purchase_price" ? (newValue as number) : prev.purchase_price
        const profitMargin = name === "profit_margin" ? (newValue as number) : prev.profit_margin
        updated.sale_price = calculateMinSalePrice(purchasePrice, profitMargin)
        updated.min_sale_price = updated.sale_price
      }
      
      return updated
    })
  }

  const handleSalePriceChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseFloat(e.target.value) || 0
    setFormData((prev) => ({ ...prev, sale_price: value }))
  }

  const openAddDialog = () => {
    setEditingProduct(null)
    setFormData(emptyProduct)
    setIsDialogOpen(true)
  }

  const openEditDialog = (product: Product) => {
    setEditingProduct(product)
    setFormData({
      barcode: product.barcode,
      name: product.name,
      description: product.description || "",
      purchase_price: Number(product.purchase_price),
      profit_margin: Number(product.profit_margin),
      sale_price: Number(product.sale_price),
      stock_quantity: product.stock_quantity,
      min_stock: product.min_stock,
      category: product.category || "",
    })
    setIsDialogOpen(true)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSaving(true)

    try {
      const minSalePrice = calculateMinSalePrice(formData.purchase_price, formData.profit_margin)
      const productData = {
        ...formData,
        min_sale_price: minSalePrice,
        sale_price: Math.max(formData.sale_price, minSalePrice),
      }

      if (editingProduct) {
        await supabase
          .from("products")
          .update(productData)
          .eq("id", editingProduct.id)
      } else {
        await supabase.from("products").insert(productData)
      }

      mutate("products")
      mutate("dashboard")
      setIsDialogOpen(false)
      setFormData(emptyProduct)
    } catch (error) {
      console.error("Erro ao salvar produto:", error)
    } finally {
      setIsSaving(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm("Tem certeza que deseja excluir este produto?")) return

    await supabase.from("products").delete().eq("id", id)
    mutate("products")
    mutate("dashboard")
  }

  const minSalePrice = calculateMinSalePrice(formData.purchase_price, formData.profit_margin)

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Controle de Estoque</h1>
          <p className="text-muted-foreground">Gerencie seus produtos e preços</p>
        </div>
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={openAddDialog} className="gap-2">
              <Plus className="w-4 h-4" />
              Novo Produto
            </Button>
          </DialogTrigger>
          <DialogPortal>
            <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>
                  {editingProduct ? "Editar Produto" : "Novo Produto"}
                </DialogTitle>
              </DialogHeader>
              <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="barcode">Código de Barras *</Label>
                  <Input
                    id="barcode"
                    name="barcode"
                    value={formData.barcode}
                    onChange={handleInputChange}
                    placeholder="7891234567890"
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="name">Nome do Produto *</Label>
                  <Input
                    id="name"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    placeholder="Ex: Arroz 5kg"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="category">Categoria</Label>
                  <Input
                    id="category"
                    name="category"
                    value={formData.category}
                    onChange={handleInputChange}
                    placeholder="Ex: Alimentos"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="description">Descrição</Label>
                  <Input
                    id="description"
                    name="description"
                    value={formData.description}
                    onChange={handleInputChange}
                    placeholder="Descrição do produto"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="purchase_price">Preço de Compra *</Label>
                  <Input
                    id="purchase_price"
                    name="purchase_price"
                    type="number"
                    step="0.01"
                    min="0"
                    value={formData.purchase_price}
                    onChange={handleInputChange}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="profit_margin">Margem de Lucro (%)</Label>
                  <Input
                    id="profit_margin"
                    name="profit_margin"
                    type="number"
                    step="0.1"
                    min="0"
                    value={formData.profit_margin}
                    onChange={handleInputChange}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Preço Mínimo de Venda</Label>
                  <div className="h-10 px-3 py-2 rounded-md bg-muted text-muted-foreground flex items-center">
                    {formatCurrency(minSalePrice)}
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="sale_price">Preço de Venda *</Label>
                <Input
                  id="sale_price"
                  name="sale_price"
                  type="number"
                  step="0.01"
                  min={minSalePrice}
                  value={formData.sale_price}
                  onChange={handleSalePriceChange}
                  required
                />
                {formData.sale_price < minSalePrice && formData.sale_price > 0 && (
                  <p className="text-xs text-destructive">
                    O preço de venda deve ser maior que {formatCurrency(minSalePrice)}
                  </p>
                )}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="stock_quantity">Quantidade em Estoque</Label>
                  <Input
                    id="stock_quantity"
                    name="stock_quantity"
                    type="number"
                    min="0"
                    value={formData.stock_quantity}
                    onChange={handleInputChange}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="min_stock">Estoque Mínimo</Label>
                  <Input
                    id="min_stock"
                    name="min_stock"
                    type="number"
                    min="0"
                    value={formData.min_stock}
                    onChange={handleInputChange}
                  />
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-4">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setIsDialogOpen(false)}
                >
                  Cancelar
                </Button>
                <Button type="submit" disabled={isSaving}>
                  {isSaving ? "Salvando..." : editingProduct ? "Atualizar" : "Cadastrar"}
                </Button>
              </div>
            </form>
            </DialogContent>
          </DialogPortal>
        </Dialog>
      </div>

      <Card className="border-0 shadow-sm">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <CardTitle className="text-lg flex items-center gap-2">
              <Package className="w-5 h-5" />
              Produtos Cadastrados
            </CardTitle>
            <div className="relative w-72">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Buscar por nome, código ou categoria..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9"
              />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-3">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="h-12 bg-muted rounded animate-pulse" />
              ))}
            </div>
          ) : filteredProducts && filteredProducts.length > 0 ? (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Código</TableHead>
                    <TableHead>Produto</TableHead>
                    <TableHead>Categoria</TableHead>
                    <TableHead className="text-right">P. Compra</TableHead>
                    <TableHead className="text-right">P. Mín.</TableHead>
                    <TableHead className="text-right">P. Venda</TableHead>
                    <TableHead className="text-center">Estoque</TableHead>
                    <TableHead className="text-right">Ações</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredProducts.map((product) => (
                    <TableRow key={product.id}>
                      <TableCell className="font-mono text-sm">{product.barcode}</TableCell>
                      <TableCell className="font-medium">{product.name}</TableCell>
                      <TableCell>
                        {product.category && (
                          <Badge variant="secondary">{product.category}</Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        {formatCurrency(Number(product.purchase_price))}
                      </TableCell>
                      <TableCell className="text-right text-muted-foreground">
                        {formatCurrency(Number(product.min_sale_price))}
                      </TableCell>
                      <TableCell className="text-right font-medium text-primary">
                        {formatCurrency(Number(product.sale_price))}
                      </TableCell>
                      <TableCell className="text-center">
                        <Badge
                          variant={
                            product.stock_quantity <= product.min_stock
                              ? "destructive"
                              : "secondary"
                          }
                        >
                          {product.stock_quantity}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => openEditDialog(product)}
                          >
                            <Pencil className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => handleDelete(product.id)}
                            className="text-destructive hover:text-destructive"
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          ) : (
            <div className="text-center py-12">
              <Package className="w-12 h-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">
                {searchTerm
                  ? "Nenhum produto encontrado"
                  : "Nenhum produto cadastrado ainda"}
              </p>
              {!searchTerm && (
                <Button onClick={openAddDialog} className="mt-4 gap-2">
                  <Plus className="w-4 h-4" />
                  Cadastrar Primeiro Produto
                </Button>
              )}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
