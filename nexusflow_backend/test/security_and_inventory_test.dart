import 'package:nexusflow_backend/src/models/role.dart';
import 'package:test/test.dart';

void main() {
  group('cadastro público', () {
    test('rejeita cargos administrativos', () {
      expect(
        () => validatePublicRegistrationRole(Role.atendente),
        returnsNormally,
      );
      expect(
        () => validatePublicRegistrationRole(Role.gerenteEstoque),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => validatePublicRegistrationRole(Role.gerenteGeral),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('validação de estoque por produto', () {
    test('soma as quantidades antes de comparar com o estoque', () {
      const items = [
        {'product_id': 'prod-1', 'quantity': 4},
        {'product_id': 'prod-1', 'quantity': 4},
      ];

      final totals = summarizeRequestedQuantities(items);

      expect(totals['prod-1'], equals(8));
      expect(validateRequestedStock(5, totals), isFalse);
      expect(validateRequestedStock(8, totals), isTrue);
    });
  });
}
