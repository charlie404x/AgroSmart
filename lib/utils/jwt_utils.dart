import 'dart:convert';

/// Lee el vencimiento (`exp`) de un JWT sin verificar la firma.
///
/// Sólo se usa para saber localmente si el token ya venció; la validación real
/// la hace siempre el backend.
DateTime? jwtExpiry(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final data = jsonDecode(payload);
    final exp = data is Map ? data['exp'] : null;
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true).toLocal();
    }
  } on FormatException {
    return null;
  }
  return null;
}
