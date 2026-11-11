import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Opción seleccionable con retroalimentación visual (borde, fondo y check).
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.leading,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final borderColor = selected ? scheme.primary : scheme.outlineVariant;
    final lead =
        leading ?? (icon == null ? null : Icon(icon, color: selected ? scheme.primary : scheme.onSurfaceVariant));

    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: AppDurations.curve,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.55) : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(dense ? AppSpacing.sm + 4 : AppSpacing.md),
              child: Row(
                children: [
                  if (lead != null) ...[lead, const SizedBox(width: AppSpacing.md)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: text.titleSmall),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(subtitle!, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedSwitcher(
                    duration: AppDurations.fast,
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: selected
                        ? Icon(Icons.check_circle_rounded, key: const ValueKey(true), color: scheme.primary)
                        : Icon(Icons.radio_button_unchecked, key: const ValueKey(false), color: scheme.outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
