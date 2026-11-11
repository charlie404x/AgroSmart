import 'package:flutter/material.dart';

import '../config/app_assets.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../widgets/app_logo.dart';

/// Estructura común de login y registro: encabezado de marca + formulario centrado.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.subtitle, required this.child, this.footer});

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.formMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: AspectRatio(
                      aspectRatio: 2.4,
                      child: Image.asset(
                        AppAssets.paisajeAndino,
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Logo, título y subtítulo centrados (login y registro comparten este layout).
                  const Center(child: AppWordmark()),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    header: true,
                    child: Text(title, style: context.text.headlineMedium, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  child,
                  if (footer != null) ...[const SizedBox(height: AppSpacing.lg), footer!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
