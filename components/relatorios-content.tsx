"use client"

import { useState } from "react"
import useSWR from "swr"
import { createClient } from "@/lib/supabase/client"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { 
  BarChart3, 
  TrendingUp, 
  Package, 
  Calendar,
  DollarSign,
  ShoppingBag,
  ArrowUpRight,
  ArrowDownRight
} from "lucide-react"
import { formatCurrency } from "@/lib/utils"
import type { Sale, SaleItem } from "@/lib/types"

const supabase = createClient()

interface SaleWithItems extends Sale {
  sale_items: SaleItem[]
}

async function fetchReportData(period: string) {
  const now = new Date()
  let startDate = new Date()
  
  switch (period) {
    case "today":
      startDate.setHours(0, 0, 0, 0)
      break
    case "week":
      startDate.setDate(now.getDate() - 7)
      break
    case "month":
      startDate.setMonth(now.getMonth() - 1)
      break
    case "year":
      startDate.setFullYear(now.getFullYear() - 1)
      break
    default:
      startDate = new Date(0)
  }

  // Queries paralelas otimizadas
  const [salesRes, productsRes] = await Promise.all([
    supabase
      .from("sales")
      .select(`
        id, total, payment_method, created_at,
        sale_items (product_id, product_name, quantity, subtotal)
      `)
      .gte("created_at", startDate.toISOString())
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("products")
      .select("id, name, barcode, stock_quantity, min_stock")
      .order("stock_quantity", { ascending: true })
      .limit(10)
  ])

  if (salesRes.error) throw salesRes.error
  const sales = salesRes.data
  const products = productsRes.data

  // Calcular estatísticas
  const salesData = (sales as SaleWithItems[]) || []
  const totalRevenue = salesData.reduce((acc, sale) => acc + Number(sale.total), 0)
  const totalSales = salesData.length
  const avgTicket = totalSales > 0 ? totalRevenue / totalSales : 0

  // Produtos mais vendidos
  const productSales: Record<string, { name: string; quantity: number; revenue: number }> = {}
  
  salesData.forEach((sale) => {
    sale.sale_items?.forEach((item) => {
      if (!productSales[item.product_id]) {
        productSales[item.product_id] = {
          name: item.product_name,
          quantity: 0,
          revenue: 0,
        }
      }
      productSales[item.product_id].quantity += item.quantity
      productSales[item.product_id].revenue += Number(item.subtotal)
    })
  })

  const topProducts = Object.entries(productSales)
    .map(([id, data]) => ({ id, ...data }))
    .sort((a, b) => b.quantity - a.quantity)
    .slice(0, 5)

  // Vendas por método de pagamento
  const paymentMethods: Record<string, { count: number; total: number }> = {}
  salesData.forEach((sale) => {
    const method = sale.payment_method
    if (!paymentMethods[method]) {
      paymentMethods[method] = { count: 0, total: 0 }
    }
    paymentMethods[method].count++
    paymentMethods[method].total += Number(sale.total)
  })

  return {
    totalRevenue,
    totalSales,
    avgTicket,
    topProducts,
    paymentMethods,
    recentSales: salesData.slice(0, 10),
    lowStockProducts: products || [],
  }
}

const paymentMethodLabels: Record<string, string> = {
  dinheiro: "Dinheiro",
  credito: "Crédito",
  debito: "Débito",
  pix: "PIX",
}

export function RelatoriosContent() {
  const [period, setPeriod] = useState("today")
  const { data, isLoading } = useSWR(
    ["reports", period],
    () => fetchReportData(period),
    { 
      refreshInterval: 60000,
      dedupingInterval: 5000,
      revalidateOnFocus: false,
      keepPreviousData: true,
    }
  )

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Relatórios</h1>
          <p className="text-muted-foreground">Análise de vendas e estoque</p>
        </div>
        <Select value={period} onValueChange={setPeriod}>
          <SelectTrigger className="w-40">
            <Calendar className="w-4 h-4 mr-2" />
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="today">Hoje</SelectItem>
            <SelectItem value="week">Última Semana</SelectItem>
            <SelectItem value="month">Último Mês</SelectItem>
            <SelectItem value="year">Último Ano</SelectItem>
            <SelectItem value="all">Todo Período</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="h-32 bg-muted rounded-xl animate-pulse" />
          ))}
        </div>
      ) : (
        <>
          {/* Cards de Resumo */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Card className="border-0 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Faturamento Total
                </CardTitle>
                <div className="p-2 rounded-lg bg-success/10">
                  <DollarSign className="w-5 h-5 text-success" />
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-2xl font-bold">
                  {formatCurrency(data?.totalRevenue || 0)}
                </p>
                <div className="flex items-center gap-1 text-sm text-success mt-1">
                  <ArrowUpRight className="w-4 h-4" />
                  <span>+12% vs período anterior</span>
                </div>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Total de Vendas
                </CardTitle>
                <div className="p-2 rounded-lg bg-accent/10">
                  <ShoppingBag className="w-5 h-5 text-accent" />
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-2xl font-bold">{data?.totalSales || 0}</p>
                <p className="text-sm text-muted-foreground mt-1">
                  vendas realizadas
                </p>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Ticket Médio
                </CardTitle>
                <div className="p-2 rounded-lg bg-primary/10">
                  <TrendingUp className="w-5 h-5 text-primary" />
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-2xl font-bold">
                  {formatCurrency(data?.avgTicket || 0)}
                </p>
                <div className="flex items-center gap-1 text-sm text-destructive mt-1">
                  <ArrowDownRight className="w-4 h-4" />
                  <span>-3% vs período anterior</span>
                </div>
              </CardContent>
            </Card>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Produtos Mais Vendidos */}
            <Card className="border-0 shadow-sm">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-lg">
                  <BarChart3 className="w-5 h-5" />
                  Produtos Mais Vendidos
                </CardTitle>
              </CardHeader>
              <CardContent>
                {data?.topProducts && data.topProducts.length > 0 ? (
                  <div className="space-y-4">
                    {data.topProducts.map((product, index) => (
                      <div key={product.id} className="flex items-center gap-4">
                        <div className="flex items-center justify-center w-8 h-8 rounded-full bg-primary/10 text-primary font-bold text-sm">
                          {index + 1}
                        </div>
                        <div className="flex-1">
                          <p className="font-medium">{product.name}</p>
                          <p className="text-sm text-muted-foreground">
                            {product.quantity} unidades vendidas
                          </p>
                        </div>
                        <p className="font-bold text-success">
                          {formatCurrency(product.revenue)}
                        </p>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-center text-muted-foreground py-8">
                    Nenhuma venda no período
                  </p>
                )}
              </CardContent>
            </Card>

            {/* Vendas por Método de Pagamento */}
            <Card className="border-0 shadow-sm">
              <CardHeader>
                <CardTitle className="text-lg">Formas de Pagamento</CardTitle>
              </CardHeader>
              <CardContent>
                {data?.paymentMethods && Object.keys(data.paymentMethods).length > 0 ? (
                  <div className="space-y-4">
                    {Object.entries(data.paymentMethods).map(([method, stats]) => (
                      <div key={method} className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <Badge variant="secondary">
                            {paymentMethodLabels[method] || method}
                          </Badge>
                          <span className="text-sm text-muted-foreground">
                            {stats.count} vendas
                          </span>
                        </div>
                        <p className="font-bold">{formatCurrency(stats.total)}</p>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-center text-muted-foreground py-8">
                    Nenhuma venda no período
                  </p>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Produtos com Estoque Baixo */}
          <Card className="border-0 shadow-sm">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <Package className="w-5 h-5" />
                Produtos com Estoque Baixo
              </CardTitle>
            </CardHeader>
            <CardContent>
              {data?.lowStockProducts && data.lowStockProducts.length > 0 ? (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Produto</TableHead>
                      <TableHead>Código</TableHead>
                      <TableHead className="text-center">Estoque Atual</TableHead>
                      <TableHead className="text-center">Estoque Mínimo</TableHead>
                      <TableHead className="text-center">Status</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {data.lowStockProducts.map((product) => (
                      <TableRow key={product.id}>
                        <TableCell className="font-medium">{product.name}</TableCell>
                        <TableCell className="font-mono text-sm">
                          {product.barcode}
                        </TableCell>
                        <TableCell className="text-center">
                          {product.stock_quantity}
                        </TableCell>
                        <TableCell className="text-center">
                          {product.min_stock}
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge
                            variant={
                              product.stock_quantity === 0
                                ? "destructive"
                                : product.stock_quantity <= product.min_stock
                                ? "secondary"
                                : "default"
                            }
                          >
                            {product.stock_quantity === 0
                              ? "Sem Estoque"
                              : product.stock_quantity <= product.min_stock
                              ? "Baixo"
                              : "Normal"}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              ) : (
                <p className="text-center text-muted-foreground py-8">
                  Todos os produtos estão com estoque adequado
                </p>
              )}
            </CardContent>
          </Card>

          {/* Vendas Recentes */}
          <Card className="border-0 shadow-sm">
            <CardHeader>
              <CardTitle className="text-lg">Vendas Recentes</CardTitle>
            </CardHeader>
            <CardContent>
              {data?.recentSales && data.recentSales.length > 0 ? (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>ID</TableHead>
                      <TableHead>Data/Hora</TableHead>
                      <TableHead>Itens</TableHead>
                      <TableHead>Pagamento</TableHead>
                      <TableHead className="text-right">Total</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {data.recentSales.map((sale) => (
                      <TableRow key={sale.id}>
                        <TableCell className="font-mono text-sm">
                          #{sale.id.slice(0, 8)}
                        </TableCell>
                        <TableCell>
                          {new Date(sale.created_at).toLocaleString("pt-BR")}
                        </TableCell>
                        <TableCell>
                          {sale.sale_items?.length || 0} itens
                        </TableCell>
                        <TableCell>
                          <Badge variant="secondary">
                            {paymentMethodLabels[sale.payment_method] || sale.payment_method}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-right font-bold text-success">
                          {formatCurrency(Number(sale.total))}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              ) : (
                <p className="text-center text-muted-foreground py-8">
                  Nenhuma venda no período
                </p>
              )}
            </CardContent>
          </Card>
        </>
      )}
    </div>
  )
}
