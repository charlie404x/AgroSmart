import 'package:agrosmart_peru/models/crop_recommendation.dart';
import 'package:agrosmart_peru/models/recommendation_result.dart';
import 'package:agrosmart_peru/widgets/recommendation/recommendation_result_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  final crops = RecommendationResult.fromJson(fixture('recommend_response.json')).crops;

  test('ordenar por ingreso, precio y rendimiento', () {
    List<double> values(CropSort s, double Function(CropRecommendation) f) =>
        arrangeCrops(crops, sort: s).map(f).toList();
    List<double> desc(List<double> l) => [...l]..sort((a, b) => b.compareTo(a));

    final income = values(CropSort.income, (c) => c.estimatedIncomePerHa ?? 0.0);
    expect(income, desc(income));
    final price = values(CropSort.price, (c) => c.pricePerKg);
    expect(price, desc(price));
    final yields = values(CropSort.yieldAvg, (c) => c.yieldAvg);
    expect(yields, desc(yields));
  });

  test('filtros', () {
    final idealSoil = arrangeCrops(crops, filters: {CropFilter.idealSoil});
    expect(idealSoil.every((c) => c.soilMatch), isTrue);
    final noWater = arrangeCrops(crops, filters: {CropFilter.noExtraWater});
    expect(noWater.every((c) => c.waterMatch), isTrue);
    final both = arrangeCrops(crops, filters: {CropFilter.idealSoil, CropFilter.highSuitability});
    expect(both.length, lessThanOrEqualTo(idealSoil.length));
  });

  test('no modifica la lista original', () {
    final before = crops.map((c) => c.cropKey).toList();
    arrangeCrops(crops, sort: CropSort.price);
    expect(crops.map((c) => c.cropKey).toList(), before);
  });
}
