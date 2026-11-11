import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_assets.dart';
import '../config/theme.dart';
import '../core/app_preferences.dart';
import '../models/history_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/climate_provider.dart';
import '../providers/history_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/app_banner.dart';
import '../widgets/crop_avatar.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/metric_tile.dart';
import '../widgets/recommendation/history_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';

/// Panel principal: bienvenida, acceso rápido, actividad, clima y últimas consultas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    final history = context.read<HistoryProvider>();
    final climate = context.read<ClimateProvider>();
    final dept = context.read<AppPreferences>().lastDepartment;
    await Future.wait([
      force ? history.refresh() : history.loadIfNeeded(),
      if (dept != null) climate.load(dept, force: force),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final history = context.watch<HistoryProvider>();
    final dept = context.watch<AppPreferences>().lastDepartment;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(force: true),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
                children: [
                  _Header(name: user?.firstName, initials: user?.initials ?? '?'),
                  const SizedBox(height: AppSpacing.lg),
                  const FadeSlideIn(child: _HeroCard()),
                  const SizedBox(height: AppSpacing.lg),
                  if (history.errorMessage != null && !history.loadedOnce) ...[
                    AppBanner(
                      tone: BannerTone.error,
                      message: history.errorMessage!,
                      actionLabel: 'Reintentar',
                      onAction: () => _load(force: true),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const SectionHeader(title: 'Tu actividad'),
                  FadeSlideIn(index: 1, child: _ActivityRow(history: history)),
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(
                    title: dept == null ? 'Clima referencial' : 'Clima referencial · $dept',
                    actionLabel: 'Ver más',
                    onAction: () => context.go('/climate'),
                  ),
                  FadeSlideIn(index: 2, child: _ClimateCard(department: dept)),
                  if (history.latest != null && history.latest!.topCropKeys.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      title: 'Destacados de tu última consulta',
                      subtitle: '${history.latest!.department} · ${Formatters.altitude(history.latest!.altitude)}',
                    ),
                    FadeSlideIn(index: 3, child: _FeaturedCrops(entry: history.latest!)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(
                    title: 'Últimas consultas',
                    actionLabel: history.items.isEmpty ? null : 'Ver todo',
                    onAction: () => context.go('/history'),
                  ),
                  _RecentList(history: history),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.initials});

  final String? name;
  final String initials;

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar tu sesión en este dispositivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final greeting = Formatters.greeting();
    final date = Formatters.longDate(DateTime.now());
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date[0].toUpperCase()}${date.substring(1)}',
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              Text(name == null || name!.isEmpty ? greeting : '$greeting, $name', style: context.text.headlineSmall),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Menú de cuenta',
          onSelected: (v) {
            if (v == 'logout') _confirmLogout(context);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'logout',
              child: ListTile(leading: Icon(Icons.logout_rounded), title: Text('Cerrar sesión')),
            ),
          ],
          child: CircleAvatar(
            radius: 22,
            backgroundColor: context.colors.primaryContainer,
            child: Text(initials, style: context.text.titleSmall?.copyWith(color: context.colors.onPrimaryContainer)),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final agro = context.agro;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          colors: [agro.heroStart, agro.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.push('/recommend'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Qué sembrar en tu terreno?',
                        style: context.text.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Responde 4 preguntas sobre tu parcela y te sugerimos los cultivos más adecuados.',
                        style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: agro.heroStart,
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () => context.push('/recommend'),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Nueva recomendación'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Foto del agricultor andino (identidad visual), sin texto incrustado.
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.asset(
                    AppAssets.agricultorCampo,
                    width: 96,
                    height: 150,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.history});

  final HistoryProvider history;

  @override
  Widget build(BuildContext context) {
    if (history.isLoading && !history.loadedOnce) {
      return const Row(
        children: [
          Expanded(child: Skeleton(height: 110, radius: AppRadius.md)),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Skeleton(height: 110, radius: AppRadius.md)),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Skeleton(height: 110, radius: AppRadius.md)),
        ],
      );
    }
    final latest = history.latest;
    // Sin IntrinsicHeight: con textos de dos líneas calculaba una altura menor a la
    // real y la columna de MetricTile se desbordaba. minHeight mantiene las tarjetas parejas.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: MetricTile(
            icon: Icons.fact_check_outlined,
            asset: AppAssets.estadisticas,
            label: 'Consultas',
            value: '${history.total}',
            caption: history.total == 1 ? 'guardada' : 'guardadas',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: MetricTile(
            icon: Icons.place_outlined,
            asset: AppAssets.mapa,
            label: 'Última zona',
            value: latest?.department ?? '—',
            caption: latest == null ? 'Sin consultas' : Formatters.altitude(latest.altitude),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: MetricTile(
            icon: Icons.eco_outlined,
            asset: AppAssets.cultivos,
            label: 'Más sugerido',
            value: history.mostFrequentCrop ?? '—',
            caption: history.mostFrequentCrop == null ? 'Aún sin datos' : 'en tus consultas',
            color: context.agro.earth,
          ),
        ),
      ],
    );
  }
}

class _ClimateCard extends StatelessWidget {
  const _ClimateCard({required this.department});

  final String? department;

  @override
  Widget build(BuildContext context) {
    final dept = department;
    if (dept == null) {
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          leading: Icon(Icons.cloud_outlined, color: context.colors.primary),
          title: const Text('Elige tu departamento'),
          subtitle: const Text('Verás aquí el clima referencial de tu zona.'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.go('/climate'),
        ),
      );
    }
    final climate = context.watch<ClimateProvider>();
    final info = climate.climateFor(dept);
    final error = climate.errorFor(dept);
    if (info == null && error != null) {
      return AppBanner(
        tone: BannerTone.error,
        message: error,
        actionLabel: 'Reintentar',
        onAction: () => climate.load(dept, force: true),
      );
    }
    if (info == null) return const Skeleton(height: 120, radius: AppRadius.lg);
    return Card(
      child: InkWell(
        onTap: () => context.go('/climate'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ClimateValue(
                      icon: Icons.thermostat_rounded,
                      label: 'Temperatura',
                      value: info.temperatureRange,
                    ),
                  ),
                  Expanded(
                    child: _ClimateValue(
                      icon: Icons.umbrella_outlined,
                      label: 'Lluvia anual',
                      value: info.precipitation,
                    ),
                  ),
                  Expanded(
                    child: _ClimateValue(icon: Icons.water_drop_outlined, label: 'Humedad', value: info.humidity),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Promedios referenciales (SENAMHI), no datos en tiempo real.',
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClimateValue extends StatelessWidget {
  const _ClimateValue({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.agro.info),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
        Text(value, style: context.text.titleSmall),
      ],
    ),
  );
}

class _FeaturedCrops extends StatelessWidget {
  const _FeaturedCrops({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entry.topCropKeys.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final name = i < entry.topCrops.length ? entry.topCrops[i] : entry.topCropKeys[i];
          return SizedBox(
            width: 118,
            child: Card(
              child: InkWell(
                onTap: () => context.go('/history/${entry.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CropAvatar(cropKey: entry.topCropKeys[i]),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        name,
                        style: context.text.labelLarge,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.history});

  final HistoryProvider history;

  @override
  Widget build(BuildContext context) {
    if (history.isLoading && !history.loadedOnce) return const SkeletonCardList(count: 2);
    if (history.items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 40, color: context.colors.primary),
              const SizedBox(height: AppSpacing.sm),
              Text('Aún no tienes consultas', style: context.text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tus recomendaciones aparecerán aquí para revisarlas cuando quieras.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    final recent = history.items.take(3).toList();
    return Column(
      children: [
        for (var i = 0; i < recent.length; i++) ...[
          FadeSlideIn(
            index: i + 3,
            child: HistoryTile(entry: recent[i], onTap: () => context.go('/history/${recent[i].id}')),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
