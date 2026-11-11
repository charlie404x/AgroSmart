import 'json_utils.dart';

/// Clima referencial de un departamento (GET /climate/{departamento}).
class ClimateInfo {
  const ClimateInfo({
    required this.department,
    required this.classification,
    required this.temperatureRange,
    required this.precipitation,
    required this.humidity,
    required this.description,
    required this.typicalAltitudeMin,
    required this.typicalAltitudeMax,
    required this.commonSoils,
    required this.commonCrops,
    required this.dataType,
    required this.source,
    required this.disclaimer,
  });

  final String department;
  final String classification;
  final String temperatureRange;
  final String precipitation;
  final String humidity;
  final String description;
  final int typicalAltitudeMin;
  final int typicalAltitudeMax;
  final List<String> commonSoils;
  final List<String> commonCrops;

  /// "referencial": promedios climáticos, no mediciones en tiempo real.
  final String dataType;
  final String source;
  final String disclaimer;

  bool get isReference => dataType == 'referencial';

  factory ClimateInfo.fromJson(Map<String, dynamic> json) => ClimateInfo(
    department: readString(json['department']),
    classification: readString(json['classification']),
    temperatureRange: readString(json['temperature_range']),
    precipitation: readString(json['precipitation']),
    humidity: readString(json['humidity']),
    description: readString(json['description']),
    typicalAltitudeMin: readInt(json['typical_altitude_min']),
    typicalAltitudeMax: readInt(json['typical_altitude_max']),
    commonSoils: readStringList(json['common_soils']),
    commonCrops: readStringList(json['common_crops']),
    dataType: readString(json['data_type'], 'referencial'),
    source: readString(json['source']),
    disclaimer: readString(json['disclaimer']),
  );
}
