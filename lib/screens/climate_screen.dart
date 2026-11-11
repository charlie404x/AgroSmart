import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_assets.dart';
import '../config/theme.dart';
import '../core/app_preferences.dart';
import '../models/climate_info.dart';
import '../providers/climate_provider.dart';
import '../utils/agro_options.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/metric_tile.dart';
import '../widgets/skeleton.dart';
import '../widgets/state_views.dart';

/// Clima referencial por departamento, obtenido del backend.
class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  late String _department;

  @override
  void initState() {
    super.initState();
    _department = context.read<AppPreferences>().lastDepartment ?? AgroOptions.departments[3];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _select(_department);
    });
  }

  void _select(String department) {
    setState(() => _department = department);
    unawaited(context.read<ClimateProvider>().load(department));
  }

  @override
  Widget build(BuildContext context) {
    final climate = context.watch<ClimateProvider>();
    final info = climate.climateFor(_department);
    final error = climate.errorFor(_department);

    final Widget body;
    if (info != null) {
      body = _ClimateDetails(key: ValueKey(_department), info: info);
    } else if (error != null) {
      body = ErrorStateView(
        key: const ValueKey('error'),
        message: error,
        onRetry: () => climate.load(_department, force: true),
      );
    } else {
      body = const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Skeleton(height: 120, radius: AppRadius.lg),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: Skeleton(height: 110, radius: AppRadius.md)),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Skeleton(height: 110, radius: AppRadius.md)),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Skeleton(height: 110, radius: AppRadius.md)),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Clima de tu zona')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              itemCount: AgroOptions.departments.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final d = AgroOptions.departments[i];
                return ChoiceChip(label: Text(d), selected: d == _department, onSelected: (_) => _select(d));
              },
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(duration: AppDurations.normal, child: body),
          ),
        ],
      ),
    );
  }
}

class _ClimateDetails extends StatelessWidget {
  const _ClimateDetails({super.key, required this.info});

  final ClimateInfo info;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
          children: [
            FadeSlideIn(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(info.department, style: context.text.headlineSmall)),
                          _DataBadge(isReference: info.isReference),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        info.classification,
                        style: context.text.bodyMedium?.copyWith(color: context.colors.primary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(info.description, style: context.text.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MetricTile(
                      icon: Icons.thermostat_rounded,
                      asset: AppAssets.clima,
                      label: 'Temperatura',
                      value: info.temperatureRange,
                      caption: 'promedio',
                      color: context.agro.earth,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.umbrella_outlined,
                      asset: AppAssets.agua,
                      label: 'Precipitación',
                      value: info.precipitation,
                      color: context.agro.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.water_drop_outlined,
                      label: 'Humedad',
                      value: info.humidity,
                      caption: 'relativa',
                      color: context.agro.info,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 2,
              child: MetricTile(
                icon: Icons.terrain_rounded,
                label: 'Altitud típica de las zonas agrícolas',
                value:
                    '${Formatters.altitude(info.typicalAltitudeMin)} – ${Formatters.altitude(info.typicalAltitudeMax)}',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Suelos frecuentes', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final s in info.commonSoils) Chip(label: Text(s))],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Cultivos frecuentes en la zona', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final c in info.commonCrops) Chip(label: Text(c))],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () async {
                await context.read<AppPreferences>().setLastDepartment(info.department);
                if (context.mounted) unawaited(context.push('/recommend'));
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text('Recomendar cultivos en ${info.department}'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(info.disclaimer, style: muted),
            const SizedBox(height: AppSpacing.xs),
            Text('Fuente: ${info.source}', style: muted),
          ],
        ),
      ),
    );
  }
}

class _DataBadge extends StatelessWidget {
  const _DataBadge({required this.isReference});

  final bool isReference;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: isReference ? 'Promedio climático, no medición en tiempo real' : 'Dato medido',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 1),
      decoration: BoxDecoration(color: context.agro.infoContainer, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        isReference ? 'Dato referencial' : 'Dato medido',
        style: context.text.labelSmall?.copyWith(color: context.agro.onInfoContainer, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
