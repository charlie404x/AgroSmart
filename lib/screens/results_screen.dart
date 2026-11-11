import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/recommendation_provider.dart';
import '../widgets/recommendation/recommendation_result_view.dart';
import '../widgets/state_views.dart';

/// Resultado de la consulta recién enviada.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  void _newQuery(BuildContext context) => context.pushReplacement('/recommend');

  @override
  Widget build(BuildContext context) {
    final result = context.watch<RecommendationProvider>().current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recomendaciones'),
        leading: IconButton(
          tooltip: 'Volver al inicio',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: 'Nueva consulta',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => _newQuery(context),
          ),
        ],
      ),
      body: result == null
          ? EmptyStateView(
              icon: Icons.manage_search_rounded,
              title: 'Aún no hay resultados',
              message: 'Completa los datos de tu terreno para obtener una recomendación.',
              actionLabel: 'Ingresar datos del terreno',
              onAction: () => _newQuery(context),
            )
          : RecommendationResultView(result: result, onNewQuery: () => _newQuery(context)),
    );
  }
}
