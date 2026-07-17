import 'package:flutter/material.dart';

/// Cores semânticas que o Material `ColorScheme` não modela nativamente
/// (sucesso/aviso), usadas nos indicadores de estoque e vendas.
class AppSemanticColors {
  const AppSemanticColors({required this.success, required this.warning});

  final Color success;
  final Color warning;

  static const light = AppSemanticColors(
    success: Color(0xFF16A34A),
    warning: Color(0xFFCA8A04),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFACC15),
  );
}

/// Cores extraídas por amostragem de pixel da logo NEXUS flow (gradiente
/// roxo -> vermelho sobre fundo branco), usadas em destaques de marca
/// (cabeçalhos, logo, CTAs).
class AppBrand {
  static const purple = Color(0xFF7B2CBF);
  static const red = Color(0xFFEE3E4E);

  static const gradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [purple, red],
  );
}

const _seedColor = AppBrand.purple;

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor).copyWith(
    tertiary: AppBrand.red,
    surface: Colors.white,
    // Material 3 tinta superfícies (AppBar, Card, NavigationRail...) com
    // o "surface tint" na cor primária por padrão, o que lava tudo de
    // lilás. Zerando isso, essas superfícies ficam brancas de verdade,
    // com o roxo aparecendo só nos elementos de destaque (botões, ícones
    // selecionados), igual à logo.
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppBrand.purple,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      // Sem elevação/sombra, o card branco se confundia com o fundo branco
      // (e o equivalente no tema escuro). A borda garante que dá pra ver
      // onde o card começa e termina nos dois temas.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  ).copyWith(tertiary: AppBrand.red);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
