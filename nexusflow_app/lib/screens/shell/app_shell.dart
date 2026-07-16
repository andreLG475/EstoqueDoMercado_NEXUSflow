import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../widgets/app_logo.dart';

class _ThemeModeToggle extends ConsumerWidget {
  const _ThemeModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;
    return IconButton(
      tooltip: isDark ? 'Mudar para tema claro' : 'Mudar para tema escuro',
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}

const _allNavItems = [
  _NavItem('/', 'Dashboard', Icons.dashboard_outlined),
  _NavItem('/estoque', 'Estoque', Icons.inventory_2_outlined),
  _NavItem('/pdv', 'PDV - Caixa', Icons.point_of_sale_outlined),
  _NavItem('/relatorios', 'Relatórios', Icons.bar_chart_outlined),
  _NavItem('/historico', 'Histórico', Icons.history),
  _NavItem('/usuarios/novo', 'Usuários', Icons.person_add_outlined),
];

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).valueOrNull;
    if (profile == null) return child;

    final items = _allNavItems.where((item) => profile.role.canAccess(item.path)).toList();
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = items.indexWhere((item) => item.path == location).clamp(0, items.length - 1);

    final isWide = MediaQuery.sizeOf(context).width >= 720;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(items[index].path),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: AppLogo(height: 32),
              ),
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _ThemeModeToggle(),
                        IconButton(
                          tooltip: 'Sair (${profile.name})',
                          icon: const Icon(Icons.logout),
                          onPressed: () => ref.read(authProvider.notifier).logout(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(items.isEmpty ? 'NEXUS flow' : items[selectedIndex].label),
        actions: [
          const _ThemeModeToggle(),
          IconButton(
            tooltip: 'Sair (${profile.name})',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: items.length > 1
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(items[index].path),
              destinations: [
                for (final item in items)
                  NavigationDestination(icon: Icon(item.icon), label: item.label),
              ],
            )
          : null,
    );
  }
}
