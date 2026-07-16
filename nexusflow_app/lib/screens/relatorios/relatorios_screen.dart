import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/sale.dart';
import '../../providers/reports_provider.dart';

const _periods = {
  'today': 'Hoje',
  'week': 'Última Semana',
  'month': 'Último Mês',
  'year': 'Último Ano',
  'all': 'Todo Período',
};

class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportsProvider);
    final period = ref.watch(reportPeriodProvider);
    final colors =
        Theme.of(context).brightness == Brightness.dark ? AppSemanticColors.dark : AppSemanticColors.light;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Relatórios',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Análise de vendas e estoque',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            DropdownButton<String>(
              value: period,
              items: [
                for (final entry in _periods.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) {
                if (value != null) ref.read(reportPeriodProvider.notifier).state = value;
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        reportAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text(error.toString())),
          ),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720 ? 3 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _SummaryCard(
                        title: 'Faturamento Total',
                        value: formatCurrency(data.totalRevenue),
                        icon: Icons.attach_money,
                        color: colors.success,
                      ),
                      _SummaryCard(
                        title: 'Total de Vendas',
                        value: '${data.totalSales}',
                        icon: Icons.shopping_bag_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      _SummaryCard(
                        title: 'Ticket Médio',
                        value: formatCurrency(data.avgTicket),
                        icon: Icons.trending_up,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 800;
                  final topProductsCard = _SectionCard(
                    title: 'Produtos Mais Vendidos',
                    icon: Icons.bar_chart,
                    child: data.topProducts.isEmpty
                        ? const _EmptyText('Nenhuma venda no período')
                        : Column(
                            children: [
                              for (var i = 0; i < data.topProducts.length; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(data.topProducts[i].name,
                                                style: const TextStyle(fontWeight: FontWeight.w600)),
                                            Text('${data.topProducts[i].quantity} unidades vendidas',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                          ],
                                        ),
                                      ),
                                      Text(formatCurrency(data.topProducts[i].revenue),
                                          style: TextStyle(fontWeight: FontWeight.bold, color: colors.success)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  );

                  final paymentMethodsCard = _SectionCard(
                    title: 'Formas de Pagamento',
                    child: data.paymentMethods.isEmpty
                        ? const _EmptyText('Nenhuma venda no período')
                        : Column(
                            children: [
                              for (final entry in data.paymentMethods.entries)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(paymentMethodLabels[entry.key] ?? entry.key),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('${entry.value.count} vendas',
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                      const Spacer(),
                                      Text(formatCurrency(entry.value.total),
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: topProductsCard),
                        const SizedBox(width: 16),
                        Expanded(child: paymentMethodsCard),
                      ],
                    );
                  }
                  return Column(
                    children: [topProductsCard, const SizedBox(height: 16), paymentMethodsCard],
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Produtos com Estoque Baixo',
                icon: Icons.inventory_2_outlined,
                child: data.lowStockProducts.isEmpty
                    ? const _EmptyText('Todos os produtos estão com estoque adequado')
                    : Column(
                        children: [
                          for (final product in data.lowStockProducts)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(product.name),
                              subtitle: Text(product.barcode),
                              trailing: _StockBadge(product: product, colors: colors),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Vendas Recentes',
                child: data.recentSales.isEmpty
                    ? const _EmptyText('Nenhuma venda no período')
                    : Column(
                        children: [
                          for (final sale in data.recentSales)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Venda #${sale.id.substring(0, 8)}'),
                              subtitle: Text(
                                '${formatDateTime(sale.createdAt)} · ${sale.itemCount} itens · '
                                '${paymentMethodLabels[sale.paymentMethod] ?? sale.paymentMethod}',
                              ),
                              trailing: Text(
                                formatCurrency(sale.total),
                                style: TextStyle(fontWeight: FontWeight.bold, color: colors.success),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product, required this.colors});
  final LowStockProduct product;
  final AppSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (product.stockQuantity == 0) {
      color = Theme.of(context).colorScheme.error;
      label = 'Sem Estoque';
    } else if (product.stockQuantity <= product.minStock) {
      color = colors.warning;
      label = 'Baixo';
    } else {
      color = colors.success;
      label = 'Normal';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.icon});
  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}
