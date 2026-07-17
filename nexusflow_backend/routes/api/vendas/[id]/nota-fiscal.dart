import 'package:dart_frog/dart_frog.dart';
import 'package:nexusflow_backend/src/auth/guards.dart';
import 'package:nexusflow_backend/src/db.dart';
import 'package:nexusflow_backend/src/invoice_pdf.dart';
import 'package:nexusflow_backend/src/models/sale.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final profile = currentProfile(context);
  if (profile == null) return unauthorizedResponse();

  final Result saleResult;
  try {
    saleResult = await db.execute(
      Sql.named('''
        SELECT s.*, p.name AS cashier_name
        FROM sales s
        LEFT JOIN profiles p ON p.id = s.user_id
        WHERE s.id = @id
      '''),
      parameters: {'id': id},
    );
  } on ServerException {
    return Response.json(statusCode: 404, body: {'error': 'Venda não encontrada'});
  }

  if (saleResult.isEmpty) {
    return Response.json(statusCode: 404, body: {'error': 'Venda não encontrada'});
  }

  final row = saleResult.first.toColumnMap();
  final sale = Sale.fromRow(row);
  final cashierName = row['cashier_name'] as String?;

  final itemsResult = await db.execute(
    Sql.named('SELECT * FROM sale_items WHERE sale_id = @saleId'),
    parameters: {'saleId': sale.id},
  );
  final items = itemsResult.map((r) => SaleItem.fromRow(r.toColumnMap())).toList();

  final bytes = await buildInvoicePdf(sale.withItems(items), cashierName: cashierName);

  return Response.bytes(
    body: bytes,
    headers: {
      'Content-Type': 'application/pdf',
      'Content-Disposition':
          'attachment; filename="nota-fiscal-${sale.invoiceNumber ?? sale.id}.pdf"',
    },
  );
}
