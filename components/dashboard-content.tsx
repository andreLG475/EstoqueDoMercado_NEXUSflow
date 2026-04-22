"use client"

import useSWR from "swr"
import { createClient } from "@/lib/supabase/client"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Package, ShoppingCart, TrendingUp, AlertTriangle, DollarSign, BarChart3 } from "lucide-react"
import { formatCurrency } from "@/lib/utils"

const supabase = createClient()

async function fetchDashboardData() {
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  
  // Queries otimizadas com select mínimo e limites
  const [productsRes, salesCountRes, todaySalesRes, lowStockRes, recentSalesRes] = await Promise.all([
    supabase.from("products").select("stock_quantity, purchase_price", { count: "exact", head: false }),
    supabase.from("sales").select("total", { count: "exact", head: false }),
    supabase.from("sales").select("total").gte("created_at", today.toISOString()),
    supabase.from("products").select("id", { count: "exact", head: true }).lt("stock_quantity", 5),
    supabase.from("sales").select("id, total, created_at").order("created_at", { ascending: false }).limit(5),
  ])

  const products = productsRes.data || []
  const sales = salesCountRes.data || []
  const todaySales = todaySalesRes.data || []

  const totalProducts = productsRes.count || products.length
  const totalSales = salesCountRes.count || sales.length
  const todayRevenue = todaySales.reduce((acc, sale) => acc + Number(sale.total), 0)
  const lowStockCount = lowStockRes.count || 0
  const totalStockValue = products.reduce((acc, p) => acc + (Number(p.purchase_price) * Number(p.stock_quantity)), 0)
  const totalRevenue = sales.reduce((acc, sale) => acc + Number(sale.total), 0)

  return {
    totalProducts,
    totalSales,
    todayRevenue,
    lowStockCount,
    totalStockValue,
    totalRevenue,
    recentSales: recentSalesRes.data || [],
  }
}

export function DashboardContent() {
  const { data, isLoading } = useSWR("dashboard", fetchDashboardData, {
    refreshInterval: 30000,
    dedupingInterval: 5000,
    revalidateOnFocus: false,
    keepPreviousData: true,
  })

  if (isLoading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-6">
          <div className="h-8 w-64 bg-muted rounded" />
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="h-32 bg-muted rounded-xl" />
            ))}
          </div>
        </div>
      </div>
    )
  }

  const stats = [
    {
      title: "Total de Produtos",
      value: data?.totalProducts || 0,
      icon: Package,
      color: "text-primary",
      bgColor: "bg-primary/10",
    },
    {
      title: "Vendas Realizadas",
      value: data?.totalSales || 0,
      icon: ShoppingCart,
      color: "text-accent",
      bgColor: "bg-accent/10",
    },
    {
      title: "Faturamento Hoje",
      value: formatCurrency(data?.todayRevenue || 0),
      icon: TrendingUp,
      color: "text-success",
      bgColor: "bg-success/10",
    },
    {
      title: "Produtos em Baixa",
      value: data?.lowStockCount || 0,
      icon: AlertTriangle,
      color: "text-warning",
      bgColor: "bg-warning/10",
    },
    {
      title: "Valor em Estoque",
      value: formatCurrency(data?.totalStockValue || 0),
      icon: DollarSign,
      color: "text-primary",
      bgColor: "bg-primary/10",
    },
    {
      title: "Faturamento Total",
      value: formatCurrency(data?.totalRevenue || 0),
      icon: BarChart3,
      color: "text-success",
      bgColor: "bg-success/10",
    },
  ]

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-foreground">Dashboard</h1>
        <p className="text-muted-foreground">Visão geral do seu supermercado</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {stats.map((stat) => (
          <Card key={stat.title} className="border-0 shadow-sm">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {stat.title}
              </CardTitle>
              <div className={`p-2 rounded-lg ${stat.bgColor}`}>
                <stat.icon className={`w-5 h-5 ${stat.color}`} />
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">{stat.value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card className="border-0 shadow-sm">
        <CardHeader>
          <CardTitle className="text-lg">Vendas Recentes</CardTitle>
        </CardHeader>
        <CardContent>
          {data?.recentSales && data.recentSales.length > 0 ? (
            <div className="space-y-3">
              {data.recentSales.map((sale: { id: string; total: number; created_at: string }) => (
                <div key={sale.id} className="flex items-center justify-between py-2 border-b border-border last:border-0">
                  <div>
                    <p className="font-medium">Venda #{sale.id.slice(0, 8)}</p>
                    <p className="text-sm text-muted-foreground">
                      {new Date(sale.created_at).toLocaleString("pt-BR")}
                    </p>
                  </div>
                  <p className="font-bold text-success">{formatCurrency(Number(sale.total))}</p>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-muted-foreground text-center py-8">
              Nenhuma venda realizada ainda
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
