import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';

/// Persistencia de la sesión (token + usuario).
abstract class SessionStorage {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

/// Implementación cifrada: Keychain (iOS) y EncryptedSharedPreferences/Keystore (Android).
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  static const _key = 'agrosmart.session';
  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      final session = AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return session.token.isEmpty ? null : session;
    } catch (e) {
      // Datos corruptos o llave del Keystore invalidada: se descarta la sesión.
      debugPrint('No se pudo leer la sesión guardada: $e');
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) => _storage.write(key: _key, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (e) {
      debugPrint('No se pudo borrar la sesión guardada: $e');
    }
  }
}

/// Implementación en memoria (pruebas).
class InMemorySessionStorage implements SessionStorage {
  InMemorySessionStorage([this._session]);

  AuthSession? _session;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
