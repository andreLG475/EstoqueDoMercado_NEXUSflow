import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/product.dart';

class ProductFormResult {
  ProductFormResult(this.payload);
  final Map<String, dynamic> payload;
}

Future<ProductFormResult?> showProductFormDialog(BuildContext context, {Product? product}) {
  return showDialog<ProductFormResult>(
    context: context,
    builder: (context) => _ProductFormDialog(product: product),
  );
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.product});

  final Product? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
  late final _nameController = TextEditingController(text: widget.product?.name ?? '');
  late final _categoryController = TextEditingController(text: widget.product?.category ?? '');
  late final _descriptionController = TextEditingController(text: widget.product?.description ?? '');
  late final _purchasePriceController =
      TextEditingController(text: (widget.product?.purchasePrice ?? 0).toStringAsFixed(2));
  late final _profitMarginController =
      TextEditingController(text: (widget.product?.profitMargin ?? 30).toStringAsFixed(1));
  late final _salePriceController =
      TextEditingController(text: (widget.product?.salePrice ?? 0).toStringAsFixed(2));
  late final _stockController =
      TextEditingController(text: '${widget.product?.stockQuantity ?? 0}');
  late final _minStockController = TextEditingController(text: '${widget.product?.minStock ?? 5}');

  bool _salePriceTouched = false;

  double get _purchasePrice => double.tryParse(_purchasePriceController.text.replaceAll(',', '.')) ?? 0;
  double get _profitMargin => double.tryParse(_profitMarginController.text.replaceAll(',', '.')) ?? 0;
  double get _minSalePrice => calculateMinSalePrice(_purchasePrice, _profitMargin);

  @override
  void initState() {
    super.initState();
    _purchasePriceController.addListener(_onPricingChanged);
    _profitMarginController.addListener(_onPricingChanged);
  }

  void _onPricingChanged() {
    if (!_salePriceTouched) {
      _salePriceController.text = _minSalePrice.toStringAsFixed(2);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _profitMarginController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final salePrice = double.tryParse(_salePriceController.text.replaceAll(',', '.')) ?? 0;
    final minSalePrice = _minSalePrice;

    Navigator.of(context).pop(
      ProductFormResult({
        'barcode': _barcodeController.text.trim(),
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        'description':
            _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'purchase_price': _purchasePrice,
        'profit_margin': _profitMargin,
        'sale_price': salePrice < minSalePrice ? minSalePrice : salePrice,
        'stock_quantity': int.tryParse(_stockController.text) ?? 0,
        'min_stock': int.tryParse(_minStockController.text) ?? 5,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final salePrice = double.tryParse(_salePriceController.text.replaceAll(',', '.')) ?? 0;
    final belowMin = salePrice > 0 && salePrice < _minSalePrice;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Produto' : 'Novo Produto'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(labelText: 'Código de Barras *'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome do Produto *'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Preço de Compra *'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _profitMarginController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Margem (%)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Preço mínimo de venda: ${formatCurrency(_minSalePrice)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _salePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Preço de Venda *',
                    errorText: belowMin ? 'Deve ser maior que ${formatCurrency(_minSalePrice)}' : null,
                  ),
                  onChanged: (_) => setState(() => _salePriceTouched = true),
                  validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qtd. em Estoque'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Estoque Mínimo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Atualizar' : 'Cadastrar'),
        ),
      ],
    );
  }
}
