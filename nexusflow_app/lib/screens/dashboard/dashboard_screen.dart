import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Visão geral do seu supermercado',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 560 ? 2 : 1);
                final cards = [
                  _StatCard(
                    title: 'Total de Produtos',
                    value: '${data.totalProducts}',
                    icon: Icons.inventory_2_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _StatCard(
                    title: 'Vendas Realizadas',
                    value: '${data.totalSales}',
                    icon: Icons.shopping_cart_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  _StatCard(
                    title: 'Faturamento Hoje',
                    value: formatCurrency(data.todayRevenue),
                    icon: Icons.trending_up,
                    color: colors.success,
                  ),
                  _StatCard(
                    title: 'Produtos em Baixa',
                    value: '${data.lowStockCount}',
                    icon: Icons.warning_amber_outlined,
                    color: colors.warning,
                  ),
                  _StatCard(
                    title: 'Valor em Estoque',
                    value: formatCurrency(data.totalStockValue),
                    icon: Icons.attach_money,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _StatCard(
                    title: 'Faturamento Total',
                    value: formatCurrency(data.totalRevenue),
                    icon: Icons.bar_chart,
                    color: colors.success,
                  ),
                ];
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.8,
                  children: cards,
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vendas Recentes', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (data.recentSales.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Nenhuma venda realizada ainda',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      for (final sale in data.recentSales)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Venda #${sale.id.substring(0, 8)}'),
                          subtitle: Text(formatDateTime(sale.createdAt)),
                          trailing: Text(
                            formatCurrency(sale.total),
                            style: TextStyle(fontWeight: FontWeight.bold, color: colors.success),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
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
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
