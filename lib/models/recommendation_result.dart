import 'crop_recommendation.dart';
import 'json_utils.dart';

/// Datos del terreno que el usuario ingresa en el formulario.
class FarmInput {
  const FarmInput({
    required this.department,
    required this.altitude,
    required this.soilType,
    required this.waterAvailability,
  });

  final String department;
  final double altitude;
  final String soilType;
  final String waterAvailability;

  Map<String, dynamic> toJson() => {
    'department': department,
    'altitude': altitude,
    'soil_type': soilType,
    'water_availability': waterAvailability,
  };
}

/// Respuesta de /recommend/ y de /history/{id}.
class RecommendationResult {
  const RecommendationResult({
    required this.id,
    required this.createdAt,
    required this.department,
    required this.altitude,
    required this.altitudeBand,
    required this.soilType,
    required this.waterAvailability,
    required this.crops,
    required this.usedFallback,
    required this.notice,
    required this.priceDisclaimer,
    required this.sortCriteria,
  });

  final int? id;
  final DateTime? createdAt;
  final String department;
  final double altitude;
  final String altitudeBand;
  final String soilType;
  final String waterAvailability;
  final List<CropRecommendation> crops;
  final bool usedFallback;
  final String? notice;
  final String priceDisclaimer;
  final String sortCriteria;

  bool get hasCrops => crops.isNotEmpty;

  factory RecommendationResult.fromJson(Map<String, dynamic> json) => RecommendationResult(
    id: json['id'] == null ? null : readInt(json['id']),
    createdAt: readDate(json['created_at']),
    department: readString(json['department']),
    altitude: readDouble(json['altitude']),
    altitudeBand: readString(json['altitude_band']),
    soilType: readString(json['soil_type']),
    waterAvailability: readString(json['water_availability']),
    crops: (json['recommended_crops'] is List ? json['recommended_crops'] as List : const [])
        .whereType<Map<String, dynamic>>()
        .map(CropRecommendation.fromJson)
        .toList(),
    usedFallback: readBool(json['used_fallback']),
    notice: readNullableString(json['notice']),
    priceDisclaimer: readString(json['price_disclaimer']),
    sortCriteria: readString(json['sort_criteria']),
  );
}
