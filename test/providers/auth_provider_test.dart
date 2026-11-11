import 'package:agrosmart_peru/core/session_storage.dart';
import 'package:agrosmart_peru/models/user.dart';
import 'package:agrosmart_peru/providers/auth_provider.dart';
import 'package:agrosmart_peru/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeHttpAdapter http;
  late InMemorySessionStorage storage;

  AuthProvider build() {
    final api = fakeApi(http);
    final auth = AuthProvider(AuthService(api, storage));
    api.onUnauthorized = auth.handleUnauthorized;
    return auth;
  }

  AuthSession session({Duration validFor = const Duration(minutes: 30)}) {
    final token = fakeJwt(validFor: validFor);
    return AuthSession(
      token: token,
      user: const User(email: 'ana@example.com', fullName: 'Ana Quispe'),
      expiresAt: DateTime.now().add(validFor),
    );
  }

  setUp(() {
    http = FakeHttpAdapter();
    storage = InMemorySessionStorage();
  });

  test('sin sesión guardada queda no autenticado', () async {
    final auth = build();
    await auth.bootstrap();
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.noticeMessage, isNull);
  });

  test('sesión guardada vencida se descarta con aviso en español, sin llamar al servidor', () async {
    await storage.write(session(validFor: const Duration(seconds: -5)));
    final auth = build();
    await auth.bootstrap();
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.noticeMessage, AuthProvider.expiredMessage);
    expect(await storage.read(), isNull);
    expect(http.requests, isEmpty);
  });

  test('sesión guardada rechazada por el servidor (401) cierra sesión', () async {
    await storage.write(session());
    http.on('GET', '/auth/me', (_) => FakeResponse(401, fixture('error_unauthorized_response.json')));
    final auth = build();
    await auth.bootstrap();
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.noticeMessage, contains('sesión expiró'));
    expect(await storage.read(), isNull);
  });

  test('sesión válida se restaura y envía el token Bearer', () async {
    final s = session();
    await storage.write(s);
    http.on(
      'GET',
      '/auth/me',
      (_) => const FakeResponse(200, {'id': 1, 'email': 'ana@example.com', 'full_name': 'Ana Q.'}),
    );
    final auth = build();
    await auth.bootstrap();
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.user!.fullName, 'Ana Q.');
    expect(http.requests.single.headers['Authorization'], 'Bearer ${s.token}');
  });

  test('sin conexión se mantiene la sesión si el token sigue vigente', () async {
    await storage.write(session());
    http.on('GET', '/auth/me', (_) => const FakeResponse(503, {'detail': 'caído'}));
    final auth = build();
    await auth.bootstrap();
    expect(auth.status, AuthStatus.authenticated);
  });

  test('login correcto guarda la sesión cifrada y el nombre', () async {
    http.on('POST', '/auth/login', (_) => FakeResponse(200, loginBody()));
    final auth = build();
    await auth.bootstrap();
    final ok = await auth.login(email: 'ANA@example.com ', password: 'Cultivo2026');
    expect(ok, isTrue);
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.user!.fullName, 'Ana Quispe');
    expect((await storage.read())!.expiresAt, isNotNull);
    expect(http.requests.last.data, containsPair('email', 'ana@example.com'));
  });

  test('login incorrecto muestra el mensaje del backend y no cambia el estado', () async {
    http.on(
      'POST',
      '/auth/login',
      (_) => const FakeResponse(401, {'detail': 'Correo o contraseña incorrectos.'}),
    );
    var signOuts = 0;
    final auth = build()..addSignOutListener(() => signOuts++);
    await auth.bootstrap();
    signOuts = 0;
    final ok = await auth.login(email: 'ana@example.com', password: 'mala');
    expect(ok, isFalse);
    expect(auth.errorMessage, 'Correo o contraseña incorrectos.');
    expect(auth.status, AuthStatus.unauthenticated);
    // Un 401 en /auth/login no debe interpretarse como "sesión expirada".
    expect(signOuts, 0);
  });

  test('un 401 en cualquier solicitud autenticada cierra la sesión', () async {
    http.on('POST', '/auth/login', (_) => FakeResponse(200, loginBody()));
    http.on('GET', '/history/', (_) => FakeResponse(401, fixture('error_unauthorized_response.json')));
    final api = fakeApi(http);
    final auth = AuthProvider(AuthService(api, storage));
    api.onUnauthorized = auth.handleUnauthorized;
    var cleared = false;
    auth.addSignOutListener(() => cleared = true);
    await auth.bootstrap();
    await auth.login(email: 'ana@example.com', password: 'Cultivo2026');

    await expectLater(api.get('/history/'), throwsA(anything));
    await Future<void>.delayed(Duration.zero);
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.noticeMessage, AuthProvider.expiredMessage);
    expect(cleared, isTrue);
    expect(await storage.read(), isNull);
  });

  test('logout manual no muestra aviso de expiración', () async {
    http.on('POST', '/auth/login', (_) => FakeResponse(200, loginBody()));
    final auth = build();
    await auth.bootstrap();
    await auth.login(email: 'ana@example.com', password: 'Cultivo2026');
    await auth.logout();
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.noticeMessage, isNull);
  });
}
