import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_assets.dart';
import '../providers/history_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_banner.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/recommendation/history_tile.dart';
import '../widgets/skeleton.dart';
import '../widgets/state_views.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HistoryProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
      context.read<HistoryProvider>().loadMore();
    }
  }

  Future<bool> _confirmDelete() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar consulta'),
          content: const Text('Esta consulta se borrará de tu historial.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de consultas')),
      floatingActionButton: history.items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/recommend'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva consulta'),
            ),
      body: AnimatedSwitcher(duration: AppDurations.normal, child: _body(history)),
    );
  }

  Widget _body(HistoryProvider history) {
    if (history.isLoading && !history.loadedOnce) {
      return const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.all(AppSpacing.md),
        child: SkeletonCardList(count: 5, height: 120),
      );
    }
    if (history.errorMessage != null && !history.loadedOnce) {
      return ErrorStateView(key: const ValueKey('error'), message: history.errorMessage!, onRetry: history.refresh);
    }
    if (history.items.isEmpty) {
      return RefreshIndicator(
        key: const ValueKey('empty'),
        onRefresh: history.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: EmptyStateView(
                icon: Icons.history_rounded,
                illustration: AppAssets.agriculturaInteligente,
                title: 'Tu historial está vacío',
                message: 'Cada recomendación que pidas se guardará aquí con su fecha y los datos de tu terreno.',
                actionLabel: 'Pedir mi primera recomendación',
                onAction: () => context.push('/recommend'),
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      key: const ValueKey('list'),
      onRefresh: history.refresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
        itemCount: history.items.length + 2,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${history.total} ${history.total == 1 ? 'consulta guardada' : 'consultas guardadas'} · '
                  'desliza una consulta hacia la izquierda para eliminarla',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (history.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppBanner(tone: BannerTone.error, message: history.errorMessage!),
                ],
              ],
            );
          }
          if (i == history.items.length + 1) {
            return history.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }
          final entry = history.items[i - 1];
          return Dismissible(
            key: ValueKey('history-${entry.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(),
            onDismissed: (_) async {
              final messenger = ScaffoldMessenger.of(context);
              final error = await history.delete(entry.id);
              messenger.showSnackBar(SnackBar(content: Text(error ?? 'Consulta eliminada.')));
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            child: FadeSlideIn(
              index: i - 1,
              child: HistoryTile(entry: entry, onTap: () => context.go('/history/${entry.id}')),
            ),
          );
        },
      ),
    );
  }
}
