import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../core/api_client.dart';
import '../../providers/pdv_provider.dart';

Future<void> showInvoicePreviewDialog(
  BuildContext context,
  WidgetRef ref, {
  required String saleId,
  required int invoiceNumber,
}) {
  return showDialog(
    context: context,
    builder: (context) =>
        _InvoicePreviewDialog(saleId: saleId, invoiceNumber: invoiceNumber),
  );
}

class _InvoicePreviewDialog extends ConsumerStatefulWidget {
  const _InvoicePreviewDialog({
    required this.saleId,
    required this.invoiceNumber,
  });

  final String saleId;
  final int invoiceNumber;

  @override
  ConsumerState<_InvoicePreviewDialog> createState() =>
      _InvoicePreviewDialogState();
}

class _InvoicePreviewDialogState extends ConsumerState<_InvoicePreviewDialog> {
  Uint8List? _bytes;
  bool _isDownloading = false;
  String? _error;

  Future<Uint8List> _loadBytes(PdfPageFormat format) async {
    final cached = _bytes;
    if (cached != null) return cached;
    final bytes = await ref
        .read(checkoutControllerProvider)
        .downloadInvoicePdf(widget.saleId);
    _bytes = bytes;
    return bytes;
  }

  Future<void> _download() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });
    try {
      final bytes =
          _bytes ??
          await ref
              .read(checkoutControllerProvider)
              .downloadInvoicePdf(widget.saleId);
      _bytes = bytes;
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'nota-fiscal-${widget.invoiceNumber}.pdf',
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 560,
        height: 680,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pré-visualização · Nota Fiscal nº ${widget.invoiceNumber}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: _loadBytes,
                allowPrinting: false,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                onError: (context, error) => Center(
                  child: Text(
                    'Não foi possível gerar a pré-visualização: $error',
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isDownloading ? null : _download,
                    icon: _isDownloading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_outlined),
                    label: const Text('Baixar Nota Fiscal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
