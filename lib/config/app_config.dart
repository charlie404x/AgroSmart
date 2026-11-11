/// Configuración global de la app.
///
/// La URL de la API se define en tiempo de compilación:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8002
///   flutter build apk --release --dart-define=API_BASE_URL=https://api.midominio.pe
/// Por defecto apunta al backend local visto desde el emulador de Android.
class AppConfig {
  AppConfig._();

  static const String appName = 'AgroSMART Perú';
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8002');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const int passwordMinLength = 8;
  static const double minAltitude = 0;
  static const double maxAltitude = 5000;
  static const int historyPageSize = 20;
}

/// Rutas de la API (deben coincidir con el backend FastAPI).
class ApiEndpoints {
  ApiEndpoints._();

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String recommend = '/recommend/';
  static const String history = '/history/';
  static String historyItem(int id) => '/history/$id';
  static String climate(String department) => '/climate/${Uri.encodeComponent(department)}';

  /// Endpoints donde un 401 significa "credenciales incorrectas" y no "sesión expirada".
  static const Set<String> publicAuth = {register, login, '/auth/token'};
}
