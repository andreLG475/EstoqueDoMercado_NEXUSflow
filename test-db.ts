import { createClient } from "@/lib/supabase/client"

async function testDatabase() {
  try {
    const supabase = createClient()
    console.log("✓ Cliente Supabase criado com sucesso")

    // Test 1: Listar tabelas (schema)
    const { data: tables, error: tablesError } = await supabase
      .from("products")
      .select("id")
      .limit(1)
    
    if (tablesError) {
      console.log("✗ Erro ao conectar à tabela 'products':", tablesError.message)
    } else {
      console.log("✓ Tabela 'products' acessível")
    }

    // Test 2: Listar vendas
    const { data: sales, error: salesError } = await supabase
      .from("sales")
      .select("id")
      .limit(1)
    
    if (salesError) {
      console.log("✗ Erro ao conectar à tabela 'sales':", salesError.message)
    } else {
      console.log("✓ Tabela 'sales' acessível")
    }

    return {
      success: !tablesError && !salesError,
      tables: {
        products: !tablesError,
        sales: !salesError,
      }
    }
  } catch (error) {
    console.error("✗ Erro geral:", error)
    return { success: false, error: String(error) }
  }
}

testDatabase().then(result => {
  console.log("\n=== RESULTADO DO TESTE ===")
  console.log(JSON.stringify(result, null, 2))
})
