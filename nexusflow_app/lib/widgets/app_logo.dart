import 'package:flutter/material.dart';

/// Logo da NEXUS flow. Espera a imagem em `assets/images/logo.png`;
/// caso o asset ainda não exista, cai para um ícone de marca.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 48});

  final double height;

  @override
  Widget build(BuildContext context) {
    // A imagem da logo tem fundo branco sólido (sem transparência), então
    // ela ganha um cartão branco por trás para não "sumir" no tema escuro.
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(
        'assets/images/logo.png',
        height: height,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.storefront_rounded,
          size: height,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
