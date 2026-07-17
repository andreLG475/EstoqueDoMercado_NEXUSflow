enum Role {
  gerenteGeral('gerente_geral', 'Gerente Geral'),
  gerenteEstoque('gerente_estoque', 'Gerente de Estoque'),
  atendente('atendente', 'Atendente');

  const Role(this.value, this.label);

  final String value;
  final String label;

  static Role fromString(String value) {
    return Role.values.firstWhere((role) => role.value == value);
  }

  static const Map<Role, List<String>> routes = {
    Role.gerenteGeral: ['/', '/estoque', '/pdv', '/relatorios', '/historico', '/usuarios', '/usuarios/novo'],
    Role.gerenteEstoque: ['/', '/estoque'],
    Role.atendente: ['/pdv'],
  };

  static const Map<Role, String> home = {
    Role.gerenteGeral: '/',
    Role.gerenteEstoque: '/',
    Role.atendente: '/pdv',
  };

  bool canAccess(String path) => routes[this]!.contains(path);
}
