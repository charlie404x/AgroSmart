import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/crop_recommendation.dart';
import '../../models/recommendation_result.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../crop_avatar.dart';
import '../metric_tile.dart';
import '../suitability_tag.dart';
import 'altitude_range_bar.dart';

/// Abre la ficha completa del cultivo en una hoja inferior desplazable.
Future<void> showCropDetailSheet(
  BuildContext context, {
  required CropRecommendation crop,
  required RecommendationResult result,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => _CropDetail(crop: crop, result: result, controller: controller),
    ),
  );
}

class _CropDetail extends StatelessWidget {
  const _CropDetail({required this.crop, required this.result, required this.controller});

  final CropRecommendation crop;
  final RecommendationResult result;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final income = crop.estimatedIncomePerHa;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      children: [
        Row(
          children: [
            CropAvatar(cropKey: crop.cropKey, size: 64),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(crop.name, style: context.text.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  SuitabilityTag(label: crop.tag, suitability: crop.suitability),
                ],
              ),
            ),
          ],
        ),
        if (crop.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(crop.description, style: context.text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
        const SizedBox(height: AppSpacing.lg),
        // Filas de altura flexible (antes GridView con proporción fija 1.45, que
        // desbordaba en teléfonos cuando el valor ocupaba dos líneas).
        Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.payments_outlined,
                    label: 'Ingreso bruto est.',
                    value: income == null ? '—' : Formatters.soles(income),
                    caption: 'por hectárea',
                    color: context.agro.earth,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: MetricTile(
                    icon: Icons.scale_outlined,
                    label: 'Rendimiento prom.',
                    value: Formatters.tonnesPerHa(crop.yieldAvg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.sell_outlined,
                    label: 'Precio referencial',
                    value: '${Formatters.soles(crop.pricePerKg)}/kg',
                    caption: result.department,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: MetricTile(
                    icon: Icons.water_drop_outlined,
                    label: 'Necesidad de agua',
                    value: crop.waterNeed,
                    caption: crop.waterMatch ? 'Cubierta con tu disponibilidad' : 'Requiere riego extra',
                    color: crop.waterMatch ? context.agro.info : context.agro.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _Title('Altitud adecuada'),
        AltitudeRangeBar(min: crop.minAltitude, max: crop.maxAltitude, userAltitude: result.altitude),
        const SizedBox(height: AppSpacing.lg),
        const _Title('Por qué se recomienda'),
        for (final reason in crop.reasons)
          _Bullet(icon: Icons.check_circle_rounded, color: context.agro.success, text: reason),
        if (crop.warnings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const _Title('Ten en cuenta'),
          for (final warning in crop.warnings)
            _Bullet(icon: Icons.warning_amber_rounded, color: context.agro.warning, text: warning),
        ],
        const SizedBox(height: AppSpacing.lg),
        const _Title('Calendario'),
        Row(
          children: [
            Expanded(
              child: MetricTile(icon: Icons.grass_rounded, label: 'Siembra', value: crop.sowingSeason),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MetricTile(icon: Icons.agriculture_rounded, label: 'Cosecha', value: crop.harvestSeason),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _Title('Suelos ideales'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final soil in crop.idealSoils)
              Chip(
                avatar: soil == result.soilType ? Icon(Icons.check_rounded, size: 18, color: scheme.primary) : null,
                label: Text(soil == result.soilType ? '$soil (tu suelo)' : soil),
                backgroundColor: soil == result.soilType ? scheme.primaryContainer : null,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Temperatura óptima: ${crop.optimalTemperature}', style: context.text.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        Text(result.priceDisclaimer, style: context.text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Semantics(header: true, child: Text(text, style: context.text.titleMedium)),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    ),
  );
}
