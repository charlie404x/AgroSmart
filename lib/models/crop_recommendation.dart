import 'json_utils.dart';

/// Nivel de adecuación calculado por el backend.
enum Suitability {
  high('alta'),
  medium('media'),
  low('baja');

  const Suitability(this.apiValue);
  final String apiValue;

  static Suitability parse(Object? value) =>
      Suitability.values.firstWhere((s) => s.apiValue == value, orElse: () => Suitability.medium);
}

class CropRecommendation {
  const CropRecommendation({
    required this.cropKey,
    required this.name,
    required this.description,
    required this.pricePerKg,
    required this.estimatedIncomePerHa,
    required this.justification,
    required this.reasons,
    required this.warnings,
    required this.suitability,
    required this.tag,
    required this.isFallback,
    required this.soilMatch,
    required this.waterMatch,
    required this.idealSoils,
    required this.waterNeed,
    required this.optimalTemperature,
    required this.sowingSeason,
    required this.harvestSeason,
    required this.yieldAvg,
    required this.minAltitude,
    required this.maxAltitude,
  });

  final String cropKey;
  final String name;
  final String description;

  /// Precio referencial (S/ por kg).
  final double pricePerKg;

  /// Ingreso bruto estimado (S/ por ha). Null si los datos no permiten calcularlo.
  final double? estimatedIncomePerHa;
  final String justification;
  final List<String> reasons;
  final List<String> warnings;
  final Suitability suitability;
  final String tag;
  final bool isFallback;
  final bool soilMatch;
  final bool waterMatch;
  final List<String> idealSoils;
  final String waterNeed;
  final String optimalTemperature;
  final String sowingSeason;
  final String harvestSeason;

  /// Rendimiento promedio (t/ha).
  final double yieldAvg;
  final int minAltitude;
  final int maxAltitude;

  factory CropRecommendation.fromJson(Map<String, dynamic> json) => CropRecommendation(
    cropKey: readString(json['crop_key']),
    name: readString(json['name']),
    description: readString(json['description']),
    pricePerKg: readDouble(json['price_per_kg']),
    estimatedIncomePerHa: readNullableDouble(json['estimated_income_per_ha']),
    justification: readString(json['justification']),
    reasons: readStringList(json['reasons']),
    warnings: readStringList(json['warnings']),
    suitability: Suitability.parse(json['suitability']),
    tag: readString(json['tag'], 'Recomendado'),
    isFallback: readBool(json['is_fallback']),
    soilMatch: readBool(json['soil_match'], true),
    waterMatch: readBool(json['water_match'], true),
    idealSoils: readStringList(json['ideal_soils']),
    waterNeed: readString(json['water_need']),
    optimalTemperature: readString(json['optimal_temperature']),
    sowingSeason: readString(json['sowing_season']),
    harvestSeason: readString(json['harvest_season']),
    yieldAvg: readDouble(json['yield_avg']),
    minAltitude: readInt(json['min_altitude']),
    maxAltitude: readInt(json['max_altitude']),
  );
}
