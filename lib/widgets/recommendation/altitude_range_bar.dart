import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

/// Barra 0–5000 m con el rango del cultivo resaltado y la altitud del usuario marcada.
class AltitudeRangeBar extends StatelessWidget {
  const AltitudeRangeBar({super.key, required this.min, required this.max, required this.userAltitude});

  final int min;
  final int max;
  final double userAltitude;

  @override
  Widget build(BuildContext context) {
    const total = AppConfig.maxAltitude;
    final scheme = context.colors;
    return Semantics(
      label:
          'Rango del cultivo de ${Formatters.altitude(min)} a ${Formatters.altitude(max)}. '
          'Tu terreno está a ${Formatters.altitude(userAltitude)}.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              double x(num v) => (v.clamp(0, total) / total) * w;
              final markerX = x(userAltitude).clamp(6.0, w - 6);
              return SizedBox(
                height: 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 14,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    Positioned(
                      left: x(min),
                      width: (x(max) - x(min)).clamp(4.0, w),
                      top: 14,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    Positioned(
                      left: markerX - 6,
                      top: 6,
                      child: Container(
                        width: 12,
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.agro.earth,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _Legend(color: scheme.primary, text: 'Cultivo: ${Formatters.altitude(min)}–${Formatters.altitude(max)}'),
              const SizedBox(width: AppSpacing.md),
              _Legend(color: context.agro.earth, text: 'Tu terreno: ${Formatters.altitude(userAltitude)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(text, style: context.text.bodySmall, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}
