import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/sale.dart';
import '../../providers/core_providers.dart';
import '../../providers/historico_provider.dart';

const _groupLabels = {'day': 'Dia', 'month': 'Mês', 'year': 'Ano'};

class HistoricoScreen extends ConsumerWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bucketsAsync = ref.watch(historicoProvider);
    final groupBy = ref.watch(historicoGroupByProvider);
    final colors =
        Theme.of(context).brightness == Brightness.dark ? AppSemanticColors.dark : AppSemanticColors.light;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Histórico de Vendas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text('Faturamento agrupado por período',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              for (final entry in _groupLabels.entries)
                ButtonSegment(value: entry.key, label: Text(entry.value)),
            ],
            selected: {groupBy},
            onSelectionChanged: (selection) =>
                ref.read(historicoGroupByProvider.notifier).state = selection.first,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bucketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (buckets) {
                if (buckets.isEmpty) {
                  return const Center(child: Text('Nenhuma venda registrada ainda'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(historicoProvider.future),
                  child: ListView.separated(
                    itemCount: buckets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bucket = buckets[index];
                      return ListTile(
                        title: Text(_bucketLabel(bucket.bucket, groupBy),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${bucket.totalSales} vendas'),
                        trailing: Text(
                          formatCurrency(bucket.totalRevenue),
                          style: TextStyle(fontWeight: FontWeight.bold, color: colors.success),
                        ),
                        onTap: () => _showBucketDetail(context, ref, bucket, groupBy),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _bucketLabel(DateTime bucket, String groupBy) {
  switch (groupBy) {
    case 'month':
      return DateFormat('MMMM \'de\' yyyy', 'pt_BR').format(bucket);
    case 'year':
      return DateFormat('yyyy', 'pt_BR').format(bucket);
    default:
      return DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(bucket);
  }
}

Future<void> _showBucketDetail(
  BuildContext context,
  WidgetRef ref,
  HistoricoBucket bucket,
  String groupBy,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _BucketDetailSheet(bucket: bucket, groupBy: groupBy),
  );
}

class _BucketDetailSheet extends ConsumerStatefulWidget {
  const _BucketDetailSheet({required this.bucket, required this.groupBy});

  final HistoricoBucket bucket;
  final String groupBy;

  @override
  ConsumerState<_BucketDetailSheet> createState() => _BucketDetailSheetState();
}

class _BucketDetailSheetState extends ConsumerState<_BucketDetailSheet> {
  late final Future<List<Sale>> _salesFuture = _fetchSales();

  Future<List<Sale>> _fetchSales() async {
    final api = ref.read(apiClientProvider);
    final data = await api.get('/api/vendas', query: {
      'from': widget.bucket.bucket.toIso8601String(),
      'to': widget.bucket.bucketEnd(widget.groupBy).toIso8601String(),
    }) as List<dynamic>;
    return data.map((e) => Sale.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).brightness == Brightness.dark ? AppSemanticColors.dark : AppSemanticColors.light;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_bucketLabel(widget.bucket.bucket, widget.groupBy),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Sale>>(
                future: _salesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }
                  final sales = snapshot.data!;
                  if (sales.isEmpty) {
                    return const Center(child: Text('Nenhuma venda neste período'));
                  }
                  return ListView.separated(
                    controller: scrollController,
                    itemCount: sales.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      return ListTile(
                        title: Text(sale.invoiceNumber != null
                            ? 'Nota fiscal nº ${sale.invoiceNumber}'
                            : 'Venda #${sale.id.substring(0, 8)}'),
                        subtitle: Text(
                          '${formatDateTime(sale.createdAt)} · ${sale.itemCount} itens · '
                          '${paymentMethodLabels[sale.paymentMethod] ?? sale.paymentMethod}',
                        ),
                        trailing: Text(
                          formatCurrency(sale.total),
                          style: TextStyle(fontWeight: FontWeight.bold, color: colors.success),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
