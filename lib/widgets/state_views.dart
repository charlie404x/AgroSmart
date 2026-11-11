import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../utils/constants.dart';
import 'app_button.dart';

/// Estado vacío con ilustración, mensaje y acción opcional.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.illustration,
  });

  final IconData icon;

  /// Imagen opcional que reemplaza al ícono circular.
  final String? illustration;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (illustration != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Image.asset(
                    illustration!,
                    height: compact ? 120 : 180,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                )
              else
                Container(
                  width: compact ? 72 : 96,
                  height: compact ? 72 : 96,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: compact ? 34 : 44, color: scheme.primary),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: context.text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: actionLabel!, onPressed: onAction, expand: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado de error con botón de reintento.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyStateView(
    icon: Icons.cloud_off_rounded,
    title: 'No pudimos cargar la información',
    message: message,
    actionLabel: onRetry == null ? null : 'Reintentar',
    onAction: onRetry,
  );
}

/// Indicador de carga centrado con texto.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(label!, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ],
    ),
  );
}
