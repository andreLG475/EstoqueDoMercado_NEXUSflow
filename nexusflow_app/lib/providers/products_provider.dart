import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/product.dart';
import 'core_providers.dart';
import 'dashboard_provider.dart';

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/api/produtos') as List<dynamic>;
  return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
});

class ProductsController {
  ProductsController(this._ref);

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> create(Map<String, dynamic> payload) async {
    await _api.post('/api/produtos', body: payload);
    _refresh();
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _api.put('/api/produtos/$id', body: payload);
    _refresh();
  }

  Future<void> delete(String id) async {
    await _api.delete('/api/produtos/$id');
    _refresh();
  }

  Future<void> adjustStock(String id, int quantity) async {
    await _api.post('/api/produtos/estoque/$id', body: {'quantity': quantity});
    _refresh();
  }

  void _refresh() {
    _ref.invalidate(productsProvider);
    _ref.invalidate(dashboardProvider);
  }
}

final productsControllerProvider = Provider((ref) => ProductsController(ref));
