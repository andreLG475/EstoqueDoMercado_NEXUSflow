import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

String formatCurrency(num value) => _currencyFormat.format(value);

String formatDateTime(DateTime value) => _dateTimeFormat.format(value.toLocal());

double calculateMinSalePrice(double purchasePrice, double profitMargin) =>
    purchasePrice * (1 + profitMargin / 100);
