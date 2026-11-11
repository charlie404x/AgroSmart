/// Lectura defensiva de JSON: evita excepciones si el backend omite un campo.
double readDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? readNullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int readInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String readString(Object? value, [String fallback = '']) => value is String ? value : (value?.toString() ?? fallback);

String? readNullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return null;
}

bool readBool(Object? value, [bool fallback = false]) => value is bool ? value : fallback;

List<String> readStringList(Object? value) => value is List ? value.map((e) => e.toString()).toList() : const [];

DateTime? readDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}

Map<String, dynamic> asMap(Object? value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
