enum Role {
  gerenteGeral('gerente_geral'),
  gerenteEstoque('gerente_estoque'),
  atendente('atendente');

  const Role(this.value);

  final String value;

  static Role fromString(String value) {
    return Role.values.firstWhere(
      (role) => role.value == value,
      orElse: () => throw ArgumentError('Papel desconhecido: $value'),
    );
  }

  /// Páginas (rotas do app) que cada papel pode acessar.
  static const Map<Role, List<String>> routes = {
    Role.gerenteGeral: ['/', '/estoque', '/pdv', '/relatorios'],
    Role.gerenteEstoque: ['/', '/estoque'],
    Role.atendente: ['/pdv'],
  };

  /// Página inicial de cada papel após o login.
  static const Map<Role, String> home = {
    Role.gerenteGeral: '/',
    Role.gerenteEstoque: '/',
    Role.atendente: '/pdv',
  };
}

Role validatePublicRegistrationRole(Role role) {
  if (role == Role.atendente) {
    return role;
  }

  throw ArgumentError(
    'Cadastro público só permite o papel atendente. Para perfis administrativos, use o procedimento autorizado pela gestão.',
  );
}

Map<String, int> summarizeRequestedQuantities(
  List<Map<String, dynamic>> items,
) {
  final totals = <String, int>{};

  for (final item in items) {
    final productId = (item['product_id'] ?? '').toString();
    final quantity = int.tryParse(item['quantity']?.toString() ?? '') ?? 0;

    if (productId.isEmpty || quantity <= 0) {
      continue;
    }

    totals[productId] = (totals[productId] ?? 0) + quantity;
  }

  return totals;
}

bool validateRequestedStock(
  int availableStock,
  Map<String, int> requestedTotals,
) {
  return requestedTotals.values.every((quantity) => quantity <= availableStock);
}
