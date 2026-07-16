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
