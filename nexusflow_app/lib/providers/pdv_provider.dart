import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/cart_item.dart';
import 'core_providers.dart';
import 'dashboard_provider.dart';
import 'products_provider.dart';

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  Future<void> addByBarcode(String barcode) async {
    final api = ref.read(apiClientProvider);
    final data = await api.get('/api/produtos/barcode/$barcode') as Map<String, dynamic>;

    final productId = data['id'] as String;
    final name = data['name'] as String;
    final salePrice = (data['sale_price'] as num).toDouble();
    final stock = data['stock_quantity'] as int;

    if (stock <= 0) {
      throw ApiException('Produto sem estoque disponível');
    }

    final existingIndex = state.indexWhere((item) => item.productId == productId);
    if (existingIndex >= 0) {
      final existing = state[existingIndex];
      if (existing.quantity >= stock) {
        throw ApiException('Quantidade máxima em estoque atingida');
      }
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == existingIndex) existing.copyWith(quantity: existing.quantity + 1) else state[i],
      ];
    } else {
      state = [
        ...state,
        CartItem(productId: productId, productName: name, quantity: 1, unitPrice: salePrice, stockAvailable: stock),
      ];
    }
  }

  void updateQuantity(String productId, int delta) {
    state = state
        .map((item) {
          if (item.productId != productId) return item;
          final newQuantity = item.quantity + delta;
          if (newQuantity <= 0) return null;
          if (newQuantity > item.stockAvailable) return item;
          return item.copyWith(quantity: newQuantity);
        })
        .whereType<CartItem>()
        .toList();
  }

  void removeItem(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  void clear() => state = [];
}

final cartProvider = NotifierProvider<CartController, List<CartItem>>(CartController.new);

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold<double>(0, (sum, item) => sum + item.subtotal);
});

class SaleResult {
  SaleResult({required this.invoiceNumber, required this.total, required this.changeAmount});

  factory SaleResult.fromJson(Map<String, dynamic> json) => SaleResult(
        invoiceNumber: json['invoice_number'] as int?,
        total: (json['total'] as num).toDouble(),
        changeAmount: (json['change_amount'] as num).toDouble(),
      );

  final int? invoiceNumber;
  final double total;
  final double changeAmount;
}

class CheckoutController {
  CheckoutController(this._ref);
  final Ref _ref;

  Future<SaleResult> checkout({required String paymentMethod, required double amountPaid}) async {
    final api = _ref.read(apiClientProvider);
    final cart = _ref.read(cartProvider);

    final data = await api.post(
      '/api/vendas',
      body: {
        'payment_method': paymentMethod,
        'amount_paid': amountPaid,
        'items': [
          for (final item in cart) {'product_id': item.productId, 'quantity': item.quantity},
        ],
      },
    ) as Map<String, dynamic>;

    _ref.read(cartProvider.notifier).clear();
    _ref.invalidate(productsProvider);
    _ref.invalidate(dashboardProvider);

    return SaleResult.fromJson(data);
  }
}

final checkoutControllerProvider = Provider((ref) => CheckoutController(ref));
