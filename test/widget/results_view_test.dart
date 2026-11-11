import 'package:agrosmart_peru/config/theme.dart';
import 'package:agrosmart_peru/models/recommendation_result.dart';
import 'package:agrosmart_peru/widgets/recommendation/crop_card.dart';
import 'package:agrosmart_peru/widgets/recommendation/recommendation_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  usePhoneViewport(tester);
  await tester.pumpWidget(_wrap(child));
}

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('muestra resumen, cultivos ordenados e ingreso estimado', (tester) async {
    final result = RecommendationResult.fromJson(fixture('recommend_response.json'));
    await _pump(tester, RecommendationResultView(result: result));
    await tester.pumpAndSettle();

    expect(find.textContaining('cultivos recomendados'), findsOneWidget);
    expect(find.text('Cusco'), findsOneWidget);
    expect(find.byType(CropCard), findsWidgets);
    expect(find.textContaining('por hectárea'), findsWidgets);
    expect(find.text(result.crops.first.name), findsOneWidget);
  });

  testWidgets('las alternativas de respaldo se marcan con aviso', (tester) async {
    final result = RecommendationResult.fromJson(fixture('recommend_fallback_response.json'));
    await _pump(tester, RecommendationResultView(result: result));
    await tester.pumpAndSettle();
    expect(find.text('Alternativas con reservas'), findsOneWidget);
    expect(find.text('Alternativa con reservas'), findsWidgets);
  });

  testWidgets('resultado vacío explica el motivo', (tester) async {
    final result = RecommendationResult.fromJson(fixture('recommend_empty_response.json'));
    await _pump(tester, RecommendationResultView(result: result, onNewQuery: () {}));
    await tester.pumpAndSettle();
    expect(find.text('No hay cultivos para estas condiciones'), findsOneWidget);
    expect(find.text('Nueva consulta'), findsOneWidget);
  });

  testWidgets('tocar un cultivo abre su detalle con justificación', (tester) async {
    final result = RecommendationResult.fromJson(fixture('recommend_response.json'));
    await _pump(tester, RecommendationResultView(result: result));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CropCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CropCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Por qué se recomienda', skipOffstage: false), findsOneWidget);
    expect(find.text('Altitud adecuada'), findsOneWidget);
  });

  testWidgets('filtro sin coincidencias ofrece quitar filtros', (tester) async {
    final result = RecommendationResult.fromJson(fixture('recommend_fallback_response.json'));
    await _pump(tester, RecommendationResultView(result: result));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mi suelo es ideal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi suelo es ideal'));
    await tester.pumpAndSettle();
    expect(find.text('Ningún cultivo cumple los filtros'), findsOneWidget);
    await tester.ensureVisible(find.text('Quitar filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();
    expect(find.byType(CropCard), findsWidgets);
  });
}
