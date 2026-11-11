import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Estado de la sesión. El router escucha este provider para redirigir.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  static const expiredMessage = 'Tu sesión expiró. Inicia sesión nuevamente.';

  final AuthService _service;
  final List<VoidCallback> _onSignedOut = [];

  AuthStatus _status = AuthStatus.unknown;
  AuthSession? _session;
  bool _isBusy = false;
  String? _errorMessage;
  String? _noticeMessage;
  Timer? _expiryTimer;
  bool _bootstrapped = false;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  User? get user => _session?.user;
  bool get isBusy => _isBusy;

  /// Error del último intento de login/registro.
  String? get errorMessage => _errorMessage;

  /// Aviso informativo para la pantalla de login (p. ej. sesión expirada).
  String? get noticeMessage => _noticeMessage;

  /// Registra una acción a ejecutar al cerrar sesión (limpiar cachés de otros providers).
  void addSignOutListener(VoidCallback callback) => _onSignedOut.add(callback);

  /// Restaura la sesión guardada y la valida con el servidor.
  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    final stored = await _service.storedSession();
    if (stored == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }
    if (stored.isExpired()) {
      await _signOut(notice: expiredMessage);
      return;
    }
    _service.useSession(stored);
    try {
      final freshUser = await _service.fetchCurrentUser();
      _session = stored.copyWith(user: freshUser);
      await _service.saveSession(_session!);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _signOut(notice: expiredMessage);
        return;
      }
      // Sin conexión u otro error temporal: se confía en el token aún vigente.
      _session = stored;
    }
    _scheduleExpiry();
    _setStatus(AuthStatus.authenticated);
  }

  Future<bool> login({required String email, required String password}) =>
      _authenticate(() => _service.login(email: email, password: password));

  Future<bool> register({required String fullName, required String email, required String password}) =>
      _authenticate(() => _service.register(fullName: fullName, email: email, password: password));

  Future<void> logout() => _signOut();

  /// Llamado por el cliente HTTP cuando el servidor rechaza el token (401).
  void handleUnauthorized() {
    if (_status != AuthStatus.authenticated) return;
    unawaited(_signOut(notice: expiredMessage));
  }

  void clearMessages() {
    if (_errorMessage == null && _noticeMessage == null) return;
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
  }

  Future<bool> _authenticate(Future<AuthSession> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
    try {
      _session = await action();
      _scheduleExpiry();
      _isBusy = false;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Ocurrió un error inesperado. Inténtalo nuevamente.';
    }
    _isBusy = false;
    notifyListeners();
    return false;
  }

  Future<void> _signOut({String? notice}) async {
    _expiryTimer?.cancel();
    _session = null;
    await _service.clearSession();
    for (final callback in _onSignedOut) {
      callback();
    }
    _noticeMessage = notice;
    _errorMessage = null;
    _setStatus(AuthStatus.unauthenticated, force: true);
  }

  /// Cierra la sesión automáticamente cuando vence el token, sin reiniciar la app.
  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final exp = _session?.expiresAt;
    if (exp == null) return;
    final remaining = exp.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      unawaited(_signOut(notice: expiredMessage));
      return;
    }
    _expiryTimer = Timer(remaining, () => unawaited(_signOut(notice: expiredMessage)));
  }

  void _setStatus(AuthStatus status, {bool force = false}) {
    if (_status == status && !force) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
