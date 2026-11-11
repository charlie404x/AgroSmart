import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/history_entry.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../crop_avatar.dart';

/// Elemento del historial de consultas.
class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final date = entry.createdAt;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(entry.department, style: context.text.titleMedium)),
                  if (date != null)
                    Text(
                      Formatters.relativeDateTime(date),
                      style: context.text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${Formatters.altitude(entry.altitude)} · Suelo ${entry.soilType} · Agua ${entry.waterAvailability.toLowerCase()}',
                style: context.text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              if (entry.topCrops.isEmpty)
                Text('Sin cultivos compatibles', style: context.text.bodyMedium)
              else
                Row(
                  children: [
                    for (var i = 0; i < entry.topCropKeys.length && i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: CropAvatar(cropKey: entry.topCropKeys[i], size: 30),
                      ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        entry.topCrops.join(', ') +
                            (entry.resultCount > entry.topCrops.length
                                ? ' y ${entry.resultCount - entry.topCrops.length} más'
                                : ''),
                        style: context.text.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                  ],
                ),
              if (entry.usedFallback) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Incluye alternativas con reservas',
                  style: context.text.labelSmall?.copyWith(color: context.agro.warning),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
