import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/crop_recommendation.dart';
import '../../models/recommendation_result.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../crop_avatar.dart';

/// Comparación lado a lado de 2 o 3 cultivos.
Future<void> showCropCompareSheet(
  BuildContext context, {
  required List<CropRecommendation> crops,
  required RecommendationResult result,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        children: [
          Text('Comparar cultivos', style: context.text.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Valores referenciales para ${result.department}.',
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - AppSpacing.lg * 2),
              child: _CompareTable(crops: crops, result: result),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.crops, required this.result});

  final List<CropRecommendation> crops;
  final RecommendationResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    String yesNo(bool v) => v ? 'Sí' : 'No';
    final rows = <(String, String Function(CropRecommendation))>[
      (
        'Ingreso bruto est. (S/ por ha)',
        (c) => c.estimatedIncomePerHa == null ? '—' : Formatters.soles(c.estimatedIncomePerHa!),
      ),
      ('Rendimiento', (c) => Formatters.tonnesPerHa(c.yieldAvg)),
      ('Precio por kg', (c) => Formatters.soles(c.pricePerKg)),
      ('Adecuación', (c) => c.tag),
      ('Tu suelo es ideal', (c) => yesNo(c.soilMatch)),
      ('Agua suficiente', (c) => yesNo(c.waterMatch)),
      ('Necesidad de agua', (c) => c.waterNeed),
      ('Altitud', (c) => '${Formatters.altitude(c.minAltitude)}–${Formatters.altitude(c.maxAltitude)}'),
      ('Siembra', (c) => c.sowingSeason),
      ('Cosecha', (c) => c.harvestSeason),
    ];

    Widget cell(Widget child, {bool header = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm + 2),
      child: DefaultTextStyle.merge(style: header ? context.text.titleSmall : context.text.bodyMedium, child: child),
    );

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FixedColumnWidth(140),
        for (var i = 1; i <= crops.length; i++) i: const FixedColumnWidth(130),
      },
      border: TableBorder(horizontalInside: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
      children: [
        TableRow(
          children: [
            cell(const SizedBox()),
            for (final c in crops)
              cell(
                Column(
                  children: [
                    CropAvatar(cropKey: c.cropKey, size: 40),
                    const SizedBox(height: AppSpacing.xs),
                    Text(c.name, textAlign: TextAlign.center, maxLines: 2),
                  ],
                ),
                header: true,
              ),
          ],
        ),
        for (final (label, value) in rows)
          TableRow(
            children: [
              cell(Text(label, style: context.text.labelLarge?.copyWith(color: scheme.onSurfaceVariant))),
              for (final c in crops) cell(Text(value(c), textAlign: TextAlign.center)),
            ],
          ),
      ],
    );
  }
}
