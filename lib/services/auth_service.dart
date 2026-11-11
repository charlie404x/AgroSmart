import '../config/app_config.dart';
import '../core/api_client.dart';
import '../core/session_storage.dart';
import '../models/json_utils.dart';
import '../models/user.dart';
import '../utils/jwt_utils.dart';

/// Autenticación contra la API y persistencia segura de la sesión.
class AuthService {
  AuthService(this._api, this._storage);

  final ApiClient _api;
  final SessionStorage _storage;

  Future<AuthSession> login({required String email, required String password}) async {
    final data = await _api.post(ApiEndpoints.login, data: {'email': email.trim().toLowerCase(), 'password': password});
    return _persist(asMap(data));
  }

  Future<AuthSession> register({required String fullName, required String email, required String password}) async {
    final data = await _api.post(
      ApiEndpoints.register,
      data: {'full_name': fullName.trim(), 'email': email.trim().toLowerCase(), 'password': password},
    );
    return _persist(asMap(data));
  }

  /// Sesión guardada en el dispositivo (sin validar contra el servidor).
  Future<AuthSession?> storedSession() => _storage.read();

  /// Valida el token con el servidor y devuelve el usuario actualizado.
  Future<User> fetchCurrentUser() async {
    final data = await _api.get(ApiEndpoints.me);
    return User.fromJson(asMap(data));
  }

  void useSession(AuthSession session) => _api.setToken(session.token);

  Future<void> saveSession(AuthSession session) => _storage.write(session);

  Future<void> clearSession() async {
    _api.setToken(null);
    await _storage.clear();
  }

  Future<AuthSession> _persist(Map<String, dynamic> json) async {
    final token = readString(json['access_token']);
    final expiresIn = readInt(json['expires_in']);
    final expiresAt = jwtExpiry(token) ?? (expiresIn > 0 ? DateTime.now().add(Duration(seconds: expiresIn)) : null);
    final session = AuthSession(
      token: token,
      expiresAt: expiresAt,
      user: User(email: readString(json['user_email']), fullName: readString(json['full_name'])),
    );
    useSession(session);
    await _storage.write(session);
    return session;
  }
}
