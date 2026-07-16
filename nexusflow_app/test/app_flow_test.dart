import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexusflow_app/core/api_client.dart';
import 'package:nexusflow_app/core/theme_mode_storage.dart';
import 'package:nexusflow_app/core/token_storage.dart';
import 'package:nexusflow_app/main.dart';
import 'package:nexusflow_app/providers/core_providers.dart';

class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

class InMemoryThemeModeStorage implements ThemeModeStorage {
  ThemeMode? _mode;

  @override
  Future<ThemeMode?> read() async => _mode;

  @override
  Future<void> write(ThemeMode mode) async => _mode = mode;
}

const _profileJson = {
  'id': 'e47140c6-7a44-4287-b555-d917d5e73d9c',
  'name': 'Teste QA',
  'email': 'qa@nexusflow.test',
  'role': 'gerente_geral',
};

const _productJson = {
  'id': 'a36f6751-9637-4fdc-ba57-baebb857c270',
  'barcode': '7891234567890',
  'name': 'Arroz 5kg',
  'description': null,
  'category': 'Alimentos',
  'purchase_price': 15.0,
  'sale_price': 19.5,
  'min_sale_price': 19.5,
  'profit_margin': 30.0,
  'stock_quantity': 48,
  'min_stock': 5,
};

class FakeApiClient implements ApiClient {
  bool loggedIn = false;

  @override
  void Function()? onUnauthorized;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == '/api/auth/me') {
      if (!loggedIn) throw ApiException('Não autenticado', statusCode: 401);
      return {'user': _profileJson};
    }
    if (path == '/api/dashboard') {
      return {
        'total_products': 1,
        'total_sales': 1,
        'today_revenue': 39.0,
        'low_stock_count': 0,
        'total_stock_value': 720.0,
        'total_revenue': 39.0,
        'recent_sales': [
          {
            'id': '715598d2-b40c-422c-943a-3d61e03da652',
            'total': 39.0,
            'created_at': '2026-07-15T22:49:54.982041Z',
          },
        ],
      };
    }
    if (path == '/api/produtos') {
      return [_productJson];
    }
    if (path.startsWith('/api/produtos/barcode/')) {
      return _productJson;
    }
    if (path == '/api/relatorios') {
      return {
        'total_revenue': 39.0,
        'total_sales': 1,
        'avg_ticket': 39.0,
        'top_products': [
          {'id': _productJson['id'], 'name': 'Arroz 5kg', 'quantity': 2, 'revenue': 39.0},
        ],
        'payment_methods': {
          'dinheiro': {'count': 1, 'total': 39.0},
        },
        'recent_sales': [
          {
            'id': '715598d2-b40c-422c-943a-3d61e03da652',
            'total': 39.0,
            'payment_method': 'dinheiro',
            'created_at': '2026-07-15T22:49:54.982041Z',
            'item_count': 1,
          },
        ],
        'low_stock_products': [
          {
            'id': _productJson['id'],
            'name': 'Arroz 5kg',
            'barcode': '7891234567890',
            'stock_quantity': 48,
            'min_stock': 5,
          },
        ],
      };
    }
    throw ApiException('Rota não encontrada: $path', statusCode: 404);
  }

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    if (path == '/api/auth/login') {
      final data = body as Map<String, dynamic>;
      if (data['email'] != 'qa@nexusflow.test' || data['password'] != 'teste123') {
        throw ApiException('Credenciais incorretas', statusCode: 401);
      }
      loggedIn = true;
      return {'token': 'fake-token', 'user': _profileJson, 'redirect': '/'};
    }
    if (path == '/api/auth/logout') {
      loggedIn = false;
      return {'message': 'Sessão encerrada'};
    }
    if (path == '/api/vendas') {
      return {
        'sale_id': '715598d2-b40c-422c-943a-3d61e03da652',
        'invoice_number': 1,
        'total': 39.0,
        'amount_paid': 50.0,
        'change_amount': 11.0,
      };
    }
    if (path == '/api/produtos') return _productJson;
    throw ApiException('Rota não encontrada: $path', statusCode: 404);
  }

  @override
  Future<dynamic> put(String path, {Object? body}) async => _productJson;

  @override
  Future<dynamic> delete(String path) async => {'message': 'ok'};
}

void main() {
  testWidgets('fluxo completo: login -> dashboard -> estoque -> pdv -> relatorios', (tester) async {
    final fakeApi = FakeApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          apiClientProvider.overrideWithValue(fakeApi),
          themeModeStorageProvider.overrideWithValue(InMemoryThemeModeStorage()),
        ],
        child: const NexusFlowApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tela de login
    expect(find.text('NEXUS flow'), findsWidgets);
    expect(find.text('Entrar'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'qa@nexusflow.test');
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'teste123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    // Dashboard
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Total de Produtos'), findsOneWidget);

    // Navega para Estoque
    await tester.tap(find.text('Estoque').first);
    await tester.pumpAndSettle();
    expect(find.text('Controle de Estoque'), findsOneWidget);
    expect(find.text('Arroz 5kg'), findsOneWidget);

    // Navega para PDV
    await tester.tap(find.text('PDV - Caixa').first);
    await tester.pumpAndSettle();
    expect(find.text('Leitura de Código de Barras'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '7891234567890');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Arroz 5kg'), findsWidgets);
    expect(find.text('Finalizar Venda'), findsOneWidget);

    // Navega para Relatórios
    await tester.tap(find.text('Relatórios').first);
    await tester.pumpAndSettle();
    expect(find.text('Relatórios'), findsWidgets);
    expect(find.text('Faturamento Total'), findsOneWidget);
    expect(find.text('Produtos Mais Vendidos'), findsOneWidget);

    // Alterna para o tema escuro
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.light);
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.dark);

    // Alterna de volta para o tema claro
    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.light);
  });
}
