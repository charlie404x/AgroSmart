import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../models/recommendation_result.dart';
import '../providers/history_provider.dart';
import '../utils/formatters.dart';
import '../widgets/recommendation/recommendation_result_view.dart';
import '../widgets/state_views.dart';

/// Detalle de una consulta anterior, tal como se entregó en su momento.
class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late Future<RecommendationResult> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<HistoryProvider>().detail(widget.id);
  }

  void _retry() => setState(() => _future = context.read<HistoryProvider>().detail(widget.id));

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar consulta'),
        content: const Text('Esta consulta se borrará de tu historial. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<HistoryProvider>().delete(widget.id);
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Consulta eliminada.')));
    if (error == null && mounted) context.go('/history');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecommendationResult>(
      future: _future,
      builder: (context, snapshot) {
        final result = snapshot.data;
        final date = result?.createdAt;
        return Scaffold(
          appBar: AppBar(
            title: Text(date == null ? 'Consulta' : Formatters.shortDate(date)),
            actions: [
              if (result != null)
                IconButton(
                  tooltip: 'Eliminar consulta',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _delete,
                ),
            ],
          ),
          body: switch (snapshot.connectionState) {
            ConnectionState.done when snapshot.hasError => ErrorStateView(
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'No pudimos abrir esta consulta.',
              onRetry: _retry,
            ),
            ConnectionState.done when result != null => RecommendationResultView(
              result: result,
              showDate: true,
              onNewQuery: () => context.push('/recommend'),
            ),
            _ => const LoadingView(label: 'Cargando consulta…'),
          },
        );
      },
    );
  }
}
