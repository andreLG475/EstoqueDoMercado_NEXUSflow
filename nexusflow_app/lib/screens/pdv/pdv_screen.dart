import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../providers/pdv_provider.dart';
import 'payment_dialog.dart';

class PdvScreen extends ConsumerStatefulWidget {
  const PdvScreen({super.key});

  @override
  ConsumerState<PdvScreen> createState() => _PdvScreenState();
}

class _PdvScreenState extends ConsumerState<PdvScreen> {
  final _barcodeController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitBarcode() async {
    final code = _barcodeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      await ref.read(cartProvider.notifier).addByBarcode(code);
      _barcodeController.clear();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSearching = false);
      _barcodeFocusNode.requestFocus();
    }
  }

  Future<void> _openPayment() async {
    final total = ref.read(cartTotalProvider);
    if (ref.read(cartProvider).isEmpty) return;
    await showPaymentDialog(context, ref, total);
    _barcodeFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final scanCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.barcode_reader),
                SizedBox(width: 8),
                Text('Leitura de Código de Barras', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    focusNode: _barcodeFocusNode,
                    autofocus: true,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(hintText: 'Digite ou escaneie o código de barras...'),
                    onSubmitted: (_) => _submitBarcode(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSearching ? null : _submitBarcode,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Text(_isSearching ? 'Buscando...' : 'Adicionar'),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 6),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    final cartCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Itens do Carrinho', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (cart.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => ref.read(cartProvider.notifier).clear(),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Limpar'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (cart.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text('Carrinho vazio'),
                      Text('Escaneie um produto para começar',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              ...cart.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '${formatCurrency(item.unitPrice)} cada',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.productId, -1),
                        ),
                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: item.quantity >= item.stockAvailable
                              ? null
                              : () => ref.read(cartProvider.notifier).updateQuantity(item.productId, 1),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            formatCurrency(item.subtotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                          onPressed: () => ref.read(cartProvider.notifier).removeItem(item.productId),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final summaryColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total da Compra', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(total),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cart.length} ${cart.length == 1 ? 'item' : 'itens'}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: cart.isEmpty ? null : _openPayment,
          icon: const Icon(Icons.point_of_sale),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Finalizar Venda', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: cart.isEmpty ? null : () => ref.read(cartProvider.notifier).clear(),
          child: const Text('Cancelar Venda'),
        ),
      ],
    );

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [scanCard, const SizedBox(height: 16), Expanded(child: cartCard)],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(width: 280, child: summaryColumn),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        scanCard,
        const SizedBox(height: 16),
        cartCard,
        const SizedBox(height: 16),
        summaryColumn,
      ],
    );
  }
}
