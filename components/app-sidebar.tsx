"use client"

import Link from "next/link"
import Image from "next/image"
import { usePathname } from "next/navigation"
import { 
  LayoutDashboard, 
  Package, 
  ShoppingCart, 
  BarChart3
} from "lucide-react"
import { cn } from "@/lib/utils"

const navigation = [
  { name: "Dashboard", href: "/", icon: LayoutDashboard },
  { name: "Estoque", href: "/estoque", icon: Package },
  { name: "PDV - Caixa", href: "/pdv", icon: ShoppingCart },
  { name: "Relatórios", href: "/relatorios", icon: BarChart3 },
]

export function AppSidebar() {
  const pathname = usePathname()

  return (
    <aside className="flex flex-col w-64 bg-sidebar text-sidebar-foreground min-h-screen">
      <div className="flex items-center gap-3 px-4 py-4 border-b border-sidebar-border">
        <Image 
          src="/images/logo.png" 
          alt="NEXUS flow Logo" 
          width={140} 
          height={50} 
          className="object-contain"
          priority
        />
      </div>
      
      <nav className="flex-1 px-3 py-4 space-y-1">
        {navigation.map((item) => {
          const isActive = pathname === item.href
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors",
                isActive
                  ? "bg-sidebar-primary text-sidebar-primary-foreground"
                  : "text-sidebar-foreground/70 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
              )}
            >
              <item.icon className="w-5 h-5" />
              {item.name}
            </Link>
          )
        })}
      </nav>
      
      <div className="px-4 py-4 border-t border-sidebar-border">
        <p className="text-xs text-sidebar-foreground/50 text-center">
          NEXUS flow v1.0
        </p>
      </div>
    </aside>
  )
}
