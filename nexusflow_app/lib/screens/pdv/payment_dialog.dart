import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/cpf.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/pdv_provider.dart';
import 'invoice_preview_dialog.dart';

const _paymentMethods = {
  'dinheiro': ('Dinheiro', Icons.payments_outlined),
  'credito': ('Cartão de Crédito', Icons.credit_card),
  'debito': ('Cartão de Débito', Icons.credit_card_outlined),
  'pix': ('PIX', Icons.qr_code),
};

Future<void> showPaymentDialog(
  BuildContext context,
  WidgetRef ref,
  double total,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PaymentDialog(total: total),
  );
}

class _PaymentDialog extends ConsumerStatefulWidget {
  const _PaymentDialog({required this.total});
  final double total;

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'dinheiro';
  final _amountController = TextEditingController();
  final _cpfController = TextEditingController();
  bool _isProcessing = false;
  String? _error;
  SaleResult? _result;

  double get _amountPaid =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
  double get _change => (_amountPaid - widget.total).clamp(0, double.infinity);

  @override
  void dispose() {
    _amountController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentMethod == 'dinheiro' && _amountPaid < widget.total) {
      setState(() => _error = 'Valor pago insuficiente');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final cpf = _cpfController.text.trim();
      final result = await ref
          .read(checkoutControllerProvider)
          .checkout(
            paymentMethod: _paymentMethod,
            amountPaid: _paymentMethod == 'dinheiro'
                ? _amountPaid
                : widget.total,
            customerCpf: cpf.isEmpty ? null : cpf,
          );
      setState(() => _result = result);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showInvoicePreview() {
    showInvoicePreviewDialog(
      context,
      ref,
      saleId: _result!.saleId,
      invoiceNumber: _result!.invoiceNumber!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;

    if (_result != null) {
      final change = _result!.changeAmount;
      return AlertDialog(
        title: const Text('Venda Concluída'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 56, color: colors.success),
            const SizedBox(height: 12),
            Text(
              'Pagamento Confirmado!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_result!.invoiceNumber != null) ...[
              const SizedBox(height: 4),
              Text('Nota fiscal nº ${_result!.invoiceNumber}'),
            ],
            if (change > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Troco a devolver:'),
                    Text(
                      formatCurrency(change),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          if (_result!.invoiceNumber != null)
            OutlinedButton.icon(
              onPressed: _showInvoicePreview,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Pré-visualizar Nota Fiscal'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nova Venda'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Finalizar Pagamento'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Total a Pagar'),
                    Text(
                      formatCurrency(widget.total),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                inputFormatters: [CpfInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'CPF na nota (opcional)',
                  hintText: '000.000.000-00',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return isValidCpf(value) ? null : 'CPF inválido';
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Forma de Pagamento',
                ),
                items: [
                  for (final entry in _paymentMethods.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Icon(entry.value.$2, size: 18),
                          const SizedBox(width: 8),
                          Text(entry.value.$1),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _paymentMethod = value ?? 'dinheiro'),
              ),
              if (_paymentMethod == 'dinheiro') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor Recebido',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_amountPaid >= widget.total && _amountPaid > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Troco:'),
                        Text(
                          formatCurrency(_change),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _confirm,
          child: _isProcessing
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirmar Pagamento'),
        ),
      ],
    );
  }
}
