import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/crop_recommendation.dart';
import '../../models/recommendation_result.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../app_banner.dart';
import '../fade_slide_in.dart';
import '../state_views.dart';
import 'crop_card.dart';
import 'crop_compare_sheet.dart';
import 'crop_detail_sheet.dart';

enum CropSort {
  income('Ingreso estimado'),
  price('Precio por kg'),
  yieldAvg('Rendimiento'),
  suitability('Adecuación');

  const CropSort(this.label);
  final String label;
}

enum CropFilter {
  highSuitability('Muy adecuados'),
  idealSoil('Mi suelo es ideal'),
  noExtraWater('Sin riego extra');

  const CropFilter(this.label);
  final String label;

  bool test(CropRecommendation c) => switch (this) {
    CropFilter.highSuitability => c.suitability == Suitability.high,
    CropFilter.idealSoil => c.soilMatch,
    CropFilter.noExtraWater => c.waterMatch,
  };
}

/// Ordena y filtra cultivos (lógica pura, probada en test/).
List<CropRecommendation> arrangeCrops(
  List<CropRecommendation> crops, {
  CropSort sort = CropSort.income,
  Set<CropFilter> filters = const {},
}) {
  final list = crops.where((c) => filters.every((f) => f.test(c))).toList();
  int byDesc(double a, double b) => b.compareTo(a);
  switch (sort) {
    case CropSort.income:
      list.sort((a, b) => byDesc(a.estimatedIncomePerHa ?? -1, b.estimatedIncomePerHa ?? -1));
    case CropSort.price:
      list.sort((a, b) => byDesc(a.pricePerKg, b.pricePerKg));
    case CropSort.yieldAvg:
      list.sort((a, b) => byDesc(a.yieldAvg, b.yieldAvg));
    case CropSort.suitability:
      list.sort((a, b) {
        final s = a.suitability.index.compareTo(b.suitability.index);
        return s != 0 ? s : byDesc(a.estimatedIncomePerHa ?? -1, b.estimatedIncomePerHa ?? -1);
      });
  }
  return list;
}

/// Presentación completa de un resultado (se usa en Resultados y en el detalle del Historial).
class RecommendationResultView extends StatefulWidget {
  const RecommendationResultView({super.key, required this.result, this.onNewQuery, this.showDate = false});

  final RecommendationResult result;
  final VoidCallback? onNewQuery;
  final bool showDate;

  @override
  State<RecommendationResultView> createState() => _RecommendationResultViewState();
}

class _RecommendationResultViewState extends State<RecommendationResultView> {
  static const _maxCompare = 3;
  CropSort _sort = CropSort.income;
  final Set<CropFilter> _filters = {};
  final Set<String> _compare = {};

  RecommendationResult get result => widget.result;

  void _toggleCompare(CropRecommendation crop) {
    setState(() {
      if (_compare.remove(crop.cropKey)) return;
      if (_compare.length >= _maxCompare) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Puedes comparar hasta 3 cultivos a la vez.')));
        return;
      }
      _compare.add(crop.cropKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final crops = arrangeCrops(result.crops, sort: _sort, filters: _filters);
    final ranks = {for (var i = 0; i < result.crops.length; i++) result.crops[i].cropKey: i + 1};
    final compareCrops = result.crops.where((c) => _compare.contains(c.cropKey)).toList();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              sliver: SliverList.list(
                children: [
                  _SummaryCard(result: result, showDate: widget.showDate),
                  if (result.notice != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppBanner(
                      tone: result.hasCrops ? BannerTone.warning : BannerTone.info,
                      title: result.hasCrops ? 'Alternativas con reservas' : 'Sin cultivos compatibles',
                      message: result.notice!,
                    ),
                  ],
                  if (result.hasCrops) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _Controls(
                      sort: _sort,
                      filters: _filters,
                      onSort: (s) => setState(() => _sort = s),
                      onFilter: (f, on) => setState(() => on ? _filters.add(f) : _filters.remove(f)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Mostrando ${crops.length} de ${result.crops.length} cultivos · '
                      'toca un cultivo para ver el detalle',
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                  ],
                ],
              ),
            ),
            if (!result.hasCrops)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  compact: true,
                  icon: Icons.search_off_rounded,
                  title: 'No hay cultivos para estas condiciones',
                  message:
                      'Prueba con otra altitud o disponibilidad de agua, o consulta a la agencia agraria de tu zona.',
                  actionLabel: widget.onNewQuery == null ? null : 'Nueva consulta',
                  onAction: widget.onNewQuery,
                ),
              )
            else if (crops.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: EmptyStateView(
                    compact: true,
                    icon: Icons.filter_alt_off_outlined,
                    title: 'Ningún cultivo cumple los filtros',
                    message: 'Quita algún filtro para ver más resultados.',
                    actionLabel: 'Quitar filtros',
                    onAction: () => setState(_filters.clear),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList.separated(
                  itemCount: crops.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm + 4),
                  itemBuilder: (context, i) {
                    final crop = crops[i];
                    return FadeSlideIn(
                      key: ValueKey('${crop.cropKey}-${_sort.name}'),
                      index: i,
                      child: CropCard(
                        crop: crop,
                        rank: _sort == CropSort.income && _filters.isEmpty ? i + 1 : ranks[crop.cropKey] ?? i + 1,
                        compareSelected: _compare.contains(crop.cropKey),
                        onToggleCompare: result.crops.length > 1 ? () => _toggleCompare(crop) : null,
                        onTap: () => showCropDetailSheet(context, crop: crop, result: result),
                      ),
                    );
                  },
                ),
              ),
            if (result.hasCrops)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 120),
                sliver: SliverToBoxAdapter(child: _Disclaimer(result: result)),
              ),
          ],
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: SafeArea(
            top: false,
            child: AnimatedSlide(
              duration: AppDurations.normal,
              curve: AppDurations.curve,
              offset: compareCrops.length >= 2 ? Offset.zero : const Offset(0, 2),
              child: AnimatedOpacity(
                duration: AppDurations.normal,
                opacity: compareCrops.length >= 2 ? 1 : 0,
                child: IgnorePointer(
                  ignoring: compareCrops.length < 2,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.compare_arrows_rounded),
                    label: Text('Comparar ${compareCrops.length} cultivos'),
                    onPressed: () => showCropCompareSheet(context, crops: compareCrops, result: result),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result, required this.showDate});

  final RecommendationResult result;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final agro = context.agro;
    final date = result.createdAt;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(colors: [agro.heroStart, agro.heroEnd]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.hasCrops
                ? '${result.crops.length} ${result.crops.length == 1 ? 'cultivo recomendado' : 'cultivos recomendados'}'
                : 'Resultado de tu consulta',
            style: context.text.titleLarge?.copyWith(color: Colors.white),
          ),
          if (showDate && date != null)
            Text(
              Formatters.relativeDateTime(date),
              style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
            ),
          const SizedBox(height: AppSpacing.sm + 4),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Pill(icon: Icons.place_outlined, text: result.department),
              _Pill(
                icon: Icons.terrain_rounded,
                text: '${Formatters.altitude(result.altitude)} · ${result.altitudeBand}',
              ),
              _Pill(icon: Icons.layers_outlined, text: result.soilType),
              _Pill(icon: Icons.water_drop_outlined, text: 'Agua ${result.waterAvailability.toLowerCase()}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: context.text.labelMedium?.copyWith(color: Colors.white)),
      ],
    ),
  );
}

class _Controls extends StatelessWidget {
  const _Controls({required this.sort, required this.filters, required this.onSort, required this.onFilter});

  final CropSort sort;
  final Set<CropFilter> filters;
  final ValueChanged<CropSort> onSort;
  final void Function(CropFilter filter, bool enabled) onFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Cultivos recomendados', style: context.text.titleMedium)),
            PopupMenuButton<CropSort>(
              tooltip: 'Ordenar resultados',
              initialValue: sort,
              onSelected: onSort,
              itemBuilder: (context) => [
                for (final s in CropSort.values)
                  CheckedPopupMenuItem(value: s, checked: s == sort, child: Text(s.label)),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 18, color: context.colors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(sort.label, style: context.text.labelLarge?.copyWith(color: context.colors.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in CropFilter.values) ...[
                FilterChip(label: Text(f.label), selected: filters.contains(f), onSelected: (on) => onFilter(f, on)),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.result});

  final RecommendationResult result;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: context.colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text('Sobre estos valores', style: context.text.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (result.sortCriteria.isNotEmpty) Text('Orden: ${result.sortCriteria}', style: muted),
          const SizedBox(height: AppSpacing.xs),
          Text(result.priceDisclaimer, style: muted),
        ],
      ),
    );
  }
}
