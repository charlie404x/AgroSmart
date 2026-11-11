import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/crop_recommendation.dart';
import '../utils/constants.dart';

/// Etiqueta de recomendación coloreada según el nivel de adecuación.
class SuitabilityTag extends StatelessWidget {
  const SuitabilityTag({super.key, required this.label, required this.suitability});

  final String label;
  final Suitability suitability;

  @override
  Widget build(BuildContext context) {
    final agro = context.agro;
    final (Color bg, Color fg, IconData icon) = switch (suitability) {
      Suitability.high => (agro.successContainer, agro.onSuccessContainer, Icons.verified_rounded),
      Suitability.medium => (agro.infoContainer, agro.onInfoContainer, Icons.thumb_up_alt_outlined),
      Suitability.low => (agro.warningContainer, agro.onWarningContainer, Icons.error_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: context.text.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
