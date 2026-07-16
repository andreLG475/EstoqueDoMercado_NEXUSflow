import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/role.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/estoque/estoque_screen.dart';
import '../screens/historico/historico_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/pdv/pdv_screen.dart';
import '../screens/relatorios/relatorios_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/usuarios/novo_usuario_screen.dart';
import 'router_refresh.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loading = authState.isLoading;
      final profile = authState.valueOrNull;
      final location = state.matchedLocation;

      if (loading) {
        return location == '/splash' ? null : '/splash';
      }

      if (profile == null) {
        return (location == '/login' || location == '/cadastro') ? null : '/login';
      }

      final home = Role.home[profile.role]!;
      if (location == '/login' || location == '/splash') return home;
      if (!profile.role.canAccess(location)) return home;
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/cadastro',
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/login'),
            ),
          ),
          body: const NovoUsuarioScreen(isPublic: true),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/estoque', builder: (context, state) => const EstoqueScreen()),
          GoRoute(path: '/pdv', builder: (context, state) => const PdvScreen()),
          GoRoute(path: '/relatorios', builder: (context, state) => const RelatoriosScreen()),
          GoRoute(path: '/historico', builder: (context, state) => const HistoricoScreen()),
          GoRoute(path: '/usuarios/novo', builder: (context, state) => const NovoUsuarioScreen()),
        ],
      ),
    ],
  );
});
