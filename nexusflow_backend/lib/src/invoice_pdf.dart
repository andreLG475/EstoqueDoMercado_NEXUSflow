import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models/sale.dart';

const _paymentMethodLabels = {
  'dinheiro': 'Dinheiro',
  'credito': 'Cartão de Crédito',
  'debito': 'Cartão de Débito',
  'pix': 'PIX',
};

String _currency(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

String _dateTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

String _formatCpf(String digits) =>
    '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9, 11)}';

Future<Uint8List> buildInvoicePdf(Sale sale, {String? cashierName}) async {
  final doc = pw.Document()
    ..addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('NEXUSflow Mercado', style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('Nota Fiscal de Venda', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Nº ${sale.invoiceNumber ?? '-'}', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_dateTime(sale.createdAt)),
              ],
            ),
            if (cashierName != null) ...[
              pw.SizedBox(height: 4),
              pw.Text('Atendente: $cashierName'),
            ],
            if (sale.customerCpf != null) ...[
              pw.SizedBox(height: 4),
              pw.Text('CPF do cliente: ${_formatCpf(sale.customerCpf!)}'),
            ],
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Produto', 'Qtd', 'Unit.', 'Subtotal'],
              data: [
                for (final item in sale.items)
                  [
                    item.productName,
                    '${item.quantity}',
                    _currency(item.unitPrice),
                    _currency(item.subtotal),
                  ],
              ],
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total: ${_currency(sale.total)}',
                    style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Forma de pagamento: ${_paymentMethodLabels[sale.paymentMethod] ?? sale.paymentMethod}'),
                  if (sale.paymentMethod == 'dinheiro') ...[
                    pw.Text('Valor pago: ${_currency(sale.amountPaid)}'),
                    pw.Text('Troco: ${_currency(sale.changeAmount)}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

  return doc.save();
}
