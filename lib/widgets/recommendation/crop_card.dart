import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/crop_recommendation.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../crop_avatar.dart';
import '../suitability_tag.dart';

/// Tarjeta resumida de un cultivo recomendado.
class CropCard extends StatelessWidget {
  const CropCard({
    super.key,
    required this.crop,
    required this.rank,
    required this.onTap,
    this.compareSelected = false,
    this.onToggleCompare,
  });

  final CropRecommendation crop;
  final int rank;
  final VoidCallback onTap;
  final bool compareSelected;
  final VoidCallback? onToggleCompare;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final income = crop.estimatedIncomePerHa;
    final isTop = rank == 1;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: isTop ? scheme.primary.withValues(alpha: 0.7) : scheme.outlineVariant.withValues(alpha: 0.6),
          width: isTop ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CropAvatar(cropKey: crop.cropKey, size: 52),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('#$rank', style: context.text.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                            const SizedBox(width: AppSpacing.xs + 2),
                            Expanded(
                              child: Text(
                                crop.name,
                                style: context.text.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            SuitabilityTag(label: crop.tag, suitability: crop.suitability),
                            if (isTop) _MiniChip(label: 'Mayor ingreso estimado', color: context.agro.earth),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onToggleCompare != null)
                    IconButton(
                      tooltip: compareSelected ? 'Quitar de la comparación' : 'Agregar a la comparación',
                      isSelected: compareSelected,
                      icon: const Icon(Icons.compare_arrows_rounded),
                      selectedIcon: const Icon(Icons.check_box_rounded),
                      onPressed: onToggleCompare,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Ingreso bruto estimado', style: context.text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
              Text(
                income == null ? 'Sin datos suficientes' : '≈ ${Formatters.soles(income)} por hectárea',
                style: context.text.titleLarge?.copyWith(color: context.agro.earth),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  _Fact(icon: Icons.scale_outlined, text: Formatters.tonnesPerHa(crop.yieldAvg)),
                  _Fact(icon: Icons.sell_outlined, text: '${Formatters.soles(crop.pricePerKg)}/kg'),
                  _Fact(icon: Icons.event_outlined, text: 'Siembra: ${crop.sowingSeason}'),
                ],
              ),
              if (crop.warnings.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: context.agro.warning),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        crop.warnings.length == 1 ? '1 observación' : '${crop.warnings.length} observaciones',
                        style: context.text.bodySmall?.copyWith(color: context.agro.warning),
                      ),
                    ),
                    Text('Ver detalle', style: context.text.labelMedium?.copyWith(color: scheme.primary)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: context.colors.onSurfaceVariant),
      const SizedBox(width: AppSpacing.xs),
      // Flexible evita el desborde cuando el texto (p. ej. la temporada de siembra)
      // es más ancho que la tarjeta en pantallas angostas.
      Flexible(child: Text(text, style: context.text.bodySmall)),
    ],
  );
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: color.withValues(alpha: 0.6)),
    ),
    child: Text(
      label,
      style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
    ),
  );
}
