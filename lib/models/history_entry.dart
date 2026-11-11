import 'json_utils.dart';

/// Resumen de una consulta guardada (GET /history/).
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.createdAt,
    required this.department,
    required this.altitude,
    required this.soilType,
    required this.waterAvailability,
    required this.altitudeBand,
    required this.resultCount,
    required this.usedFallback,
    required this.topCrops,
    required this.topCropKeys,
  });

  final int id;
  final DateTime? createdAt;
  final String department;
  final double altitude;
  final String soilType;
  final String waterAvailability;
  final String altitudeBand;
  final int resultCount;
  final bool usedFallback;
  final List<String> topCrops;
  final List<String> topCropKeys;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: readInt(json['id']),
    createdAt: readDate(json['created_at']),
    department: readString(json['department']),
    altitude: readDouble(json['altitude']),
    soilType: readString(json['soil_type']),
    waterAvailability: readString(json['water_availability']),
    altitudeBand: readString(json['altitude_band']),
    resultCount: readInt(json['result_count']),
    usedFallback: readBool(json['used_fallback']),
    topCrops: readStringList(json['top_crops']),
    topCropKeys: readStringList(json['top_crop_keys']),
  );
}

class HistoryPage {
  const HistoryPage({required this.items, required this.total, required this.offset});

  final List<HistoryEntry> items;
  final int total;
  final int offset;

  factory HistoryPage.fromJson(Map<String, dynamic> json) => HistoryPage(
    items: (json['items'] is List ? json['items'] as List : const [])
        .whereType<Map<String, dynamic>>()
        .map(HistoryEntry.fromJson)
        .toList(),
    total: readInt(json['total']),
    offset: readInt(json['offset']),
  );
}
