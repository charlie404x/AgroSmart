import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../utils/constants.dart';

/// Indicador compacto: ícono, etiqueta y valor.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.color,
    this.asset,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color? color;

  /// Icono de módulo (PNG) que reemplaza a [icon] cuando se indica.
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.colors.primary;
    return Semantics(
      label: '$label: $value${caption == null ? '' : ', $caption'}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 128),
        padding: const EdgeInsets.all(AppSpacing.sm + 6),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.colors.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (asset != null)
              Image.asset(asset!, width: 26, height: 26, excludeFromSemantics: true)
            else
              Icon(icon, size: 20, color: accent),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(value, style: context.text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (caption != null)
              Text(
                caption!,
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
