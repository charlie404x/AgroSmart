/// Configuración global de la app.
///
/// Por defecto la app consume el backend desplegado en Render.
/// Para trabajar con el backend local, indica la URL al ejecutar:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8002        (emulador Android)
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8002    (teléfono en la misma red)
class AppConfig {
  AppConfig._();

  static const String appName = 'AgroSMART Perú';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://agrosmart-api.onrender.com',
  );

  // El plan gratuito de Render suspende el servicio cuando no se usa y tarda
  // alrededor de un minuto en despertar; estos tiempos cubren ese arranque.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 70);

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
