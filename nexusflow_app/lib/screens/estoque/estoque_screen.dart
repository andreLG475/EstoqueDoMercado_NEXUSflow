import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/products_provider.dart';
import 'product_form_dialog.dart';
import 'stock_adjust_dialog.dart';

class EstoqueScreen extends ConsumerStatefulWidget {
  const EstoqueScreen({super.key});

  @override
  ConsumerState<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends ConsumerState<EstoqueScreen> {
  String _search = '';

  Future<void> _openCreateDialog() async {
    final result = await showProductFormDialog(context);
    if (result == null || !mounted) return;
    try {
      await ref.read(productsControllerProvider).create(result.payload);
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    }
  }

  Future<void> _openEditDialog(Product product) async {
    final result = await showProductFormDialog(context, product: product);
    if (result == null || !mounted) return;
    try {
      await ref.read(productsControllerProvider).update(product.id, result.payload);
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    }
  }

  Future<void> _openStockAdjustDialog(Product product) async {
    final result = await showStockAdjustDialog(context, product);
    if (result == null || !mounted) return;
    try {
      await ref.read(productsControllerProvider).adjustStock(product.id, result.delta);
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Tem certeza que deseja excluir "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(productsControllerProvider).delete(product.id);
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Controle de Estoque',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Gerencie seus produtos e preços',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Novo Produto'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nome, código ou categoria...',
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (products) {
                final term = _search.trim().toLowerCase();
                final filtered = term.isEmpty
                    ? products
                    : products
                        .where((p) =>
                            p.name.toLowerCase().contains(term) ||
                            p.barcode.contains(_search) ||
                            (p.category?.toLowerCase().contains(term) ?? false))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(term.isEmpty ? 'Nenhum produto cadastrado ainda' : 'Nenhum produto encontrado'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(productsProvider.future),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ListTile(
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${product.barcode}'
                          '${product.category != null ? ' · ${product.category}' : ''}'
                          ' · ${formatCurrency(product.salePrice)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (product.isLowStock ? Theme.of(context).colorScheme.error : colors.success)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${product.stockQuantity}',
                                style: TextStyle(
                                  color: product.isLowStock ? Theme.of(context).colorScheme.error : colors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Ajustar estoque',
                              icon: const Icon(Icons.inventory_2_outlined),
                              onPressed: () => _openStockAdjustDialog(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openEditDialog(product),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                              onPressed: () => _confirmDelete(product),
                            ),
                          ],
                        ),
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
