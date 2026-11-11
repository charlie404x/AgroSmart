import 'package:agrosmart_peru/models/climate_info.dart';
import 'package:agrosmart_peru/models/crop_recommendation.dart';
import 'package:agrosmart_peru/models/history_entry.dart';
import 'package:agrosmart_peru/models/recommendation_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

/// Verifica que los modelos de Flutter interpretan las respuestas reales del backend.
void main() {
  test('recomendación normal', () {
    final r = RecommendationResult.fromJson(fixture('recommend_response.json'));
    expect(r.id, isNotNull);
    expect(r.createdAt, isNotNull);
    expect(r.department, 'Cusco');
    expect(r.altitudeBand, 'Alta');
    expect(r.usedFallback, isFalse);
    expect(r.crops, isNotEmpty);
    final first = r.crops.first;
    expect(first.estimatedIncomePerHa, closeTo(first.yieldAvg * 1000 * first.pricePerKg, 0.01));
    expect(first.reasons, isNotEmpty);
    expect(first.maxAltitude, greaterThan(first.minAltitude));
    expect(r.priceDisclaimer, contains('referenciales'));
    // El backend entrega los cultivos ordenados por ingreso estimado.
    final incomes = r.crops.map((c) => c.estimatedIncomePerHa ?? 0.0).toList();
    final sorted = [...incomes]..sort((a, b) => b.compareTo(a));
    expect(incomes, orderedEquals(sorted));
  });

  test('recomendación con alternativas de respaldo', () {
    final r = RecommendationResult.fromJson(fixture('recommend_fallback_response.json'));
    expect(r.usedFallback, isTrue);
    expect(r.notice, isNotNull);
    expect(r.crops.every((c) => c.isFallback), isTrue);
    expect(r.crops.first.suitability, Suitability.low);
    expect(r.crops.first.warnings, isNotEmpty);
  });

  test('recomendación vacía', () {
    final r = RecommendationResult.fromJson(fixture('recommend_empty_response.json'));
    expect(r.hasCrops, isFalse);
    expect(r.notice, contains('Agencia Agraria'));
  });

  test('historial', () {
    final page = HistoryPage.fromJson(fixture('history_response.json'));
    expect(page.total, page.items.length);
    expect(page.items.first.createdAt, isNotNull);
    final withCrops = page.items.firstWhere((e) => e.topCrops.isNotEmpty);
    expect(withCrops.topCropKeys.length, withCrops.topCrops.length);
  });

  test('clima referencial', () {
    final c = ClimateInfo.fromJson(fixture('climate_response.json'));
    expect(c.department, 'Cusco');
    expect(c.isReference, isTrue);
    expect(c.temperatureRange, contains('°C'));
    expect(c.commonCrops, isNotEmpty);
  });

  test('campos ausentes no rompen el parseo', () {
    final c = CropRecommendation.fromJson(const {'crop_key': 'papa'});
    expect(c.name, '');
    expect(c.estimatedIncomePerHa, isNull);
    expect(c.suitability, Suitability.medium);
  });
}
