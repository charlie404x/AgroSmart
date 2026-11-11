import '../config/app_config.dart';

/// Validadores de formularios con mensajes en español.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_emailRegex.hasMatch(v)) return 'Ingresa un correo válido (ej. nombre@correo.com)';
    return null;
  }

  /// Contraseña para inicio de sesión: sólo se exige que no esté vacía.
  static String? loginPassword(String? value) => (value == null || value.isEmpty) ? 'Ingresa tu contraseña' : null;

  /// Contraseña para registro: misma política que el backend.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Crea una contraseña';
    final missing = passwordIssues(v);
    return missing.isEmpty ? null : 'La contraseña debe tener ${missing.join(', ')}';
  }

  /// Requisitos que aún no cumple la contraseña (para la ayuda en tiempo real).
  static List<String> passwordIssues(String value) => [
    if (value.length < AppConfig.passwordMinLength) 'al menos ${AppConfig.passwordMinLength} caracteres',
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) 'letras',
    if (!RegExp(r'\d').hasMatch(value)) 'números',
  ];

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Repite tu contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu nombre';
    if (v.length < 2) return 'El nombre es demasiado corto';
    if (v.length > 120) return 'El nombre es demasiado largo';
    return null;
  }

  /// Acepta "3200", "3 200", "3200.5" y "3200,5".
  static double? parseAltitude(String? value) {
    final cleaned = (value ?? '').replaceAll(RegExp(r'[\s\u202F]'), '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  static String? altitude(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa la altitud de tu terreno';
    final parsed = parseAltitude(value);
    if (parsed == null) return 'Ingresa sólo números (ej. 3200)';
    if (parsed < AppConfig.minAltitude || parsed > AppConfig.maxAltitude) {
      return 'La altitud debe estar entre ${AppConfig.minAltitude.toInt()} y '
          '${AppConfig.maxAltitude.toInt()} m';
    }
    return null;
  }
}
