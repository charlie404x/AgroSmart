import 'package:flutter/material.dart';

import '../config/app_assets.dart';

/// Icono cuadrado de la app (hoja, montaña y campos).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Logotipo de AgroSMART Perú',
    image: true,
    child: Image.asset(AppAssets.appIcon, width: size, height: size, excludeFromSemantics: true),
  );
}

/// Logotipo completo "AgroSMART Perú — Cultiva Inteligente, Cosecha Mejor".
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(AppAssets.logo, height: height, fit: BoxFit.contain, excludeFromSemantics: true);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'AgroSMART Perú. Cultiva inteligente, cosecha mejor',
      image: true,
      // El logotipo es verde oscuro: en modo oscuro va sobre una placa clara para ser legible.
      child: dark
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: image),
            )
          : image,
    );
  }
}

/// Icono de módulo de la identidad visual (inicio, clima, historial…).
class ModuleIcon extends StatelessWidget {
  const ModuleIcon(this.asset, {super.key, this.size = 24, this.dimmed = false});

  final String asset;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: dimmed ? 0.55 : 1,
    child: Image.asset(asset, width: size, height: size, excludeFromSemantics: true),
  );
}
