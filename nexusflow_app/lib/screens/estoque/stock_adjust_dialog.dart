import 'package:flutter/material.dart';

import '../../models/product.dart';

class StockAdjustResult {
  StockAdjustResult(this.delta);
  final int delta;
}

Future<StockAdjustResult?> showStockAdjustDialog(BuildContext context, Product product) {
  return showDialog<StockAdjustResult>(
    context: context,
    builder: (context) => _StockAdjustDialog(product: product),
  );
}

class _StockAdjustDialog extends StatefulWidget {
  const _StockAdjustDialog({required this.product});
  final Product product;

  @override
  State<_StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<_StockAdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  bool _isAdding = true;

  int get _quantity => int.tryParse(_quantityController.text) ?? 0;
  int get _newStock =>
      widget.product.stockQuantity + (_isAdding ? _quantity : -_quantity);

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(StockAdjustResult(_isAdding ? _quantity : -_quantity));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajustar Estoque'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'Estoque atual: ${widget.product.stockQuantity}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Adicionar'), icon: Icon(Icons.add)),
                  ButtonSegment(value: false, label: Text('Remover'), icon: Icon(Icons.remove)),
                ],
                selected: {_isAdding},
                onSelectionChanged: (selection) => setState(() => _isAdding = selection.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade *'),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Informe uma quantidade válida';
                  if (!_isAdding && n > widget.product.stockQuantity) return 'Maior que o estoque atual';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text('Novo estoque: $_newStock', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Confirmar')),
      ],
    );
  }
}
