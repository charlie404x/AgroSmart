import 'package:agrosmart_peru/app.dart';
import 'package:agrosmart_peru/core/app_preferences.dart';
import 'package:agrosmart_peru/core/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeHttpAdapter http;

  Future<void> pumpApp(WidgetTester tester, {InMemorySessionStorage? storage}) async {
    usePhoneViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      AgroSmartApp(
        api: fakeApi(http),
        sessionStorage: storage ?? InMemorySessionStorage(),
        preferences: AppPreferences(prefs),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    http = FakeHttpAdapter()
      ..on('POST', '/auth/login', (_) => FakeResponse(200, loginBody()))
      ..on('GET', '/history/', (_) => FakeResponse(200, fixture('history_response.json')));
  });

  testWidgets('sin sesión muestra el login y valida campos vacíos', (tester) async {
    await pumpApp(tester);
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);

    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(http.requests, isEmpty);
  });

  testWidgets('login correcto lleva al dashboard con datos reales del historial', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Cultivo2026');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ana'), findsWidgets);
    expect(find.text('Nueva recomendación'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Últimas consultas'), 300);
    expect(find.text('Últimas consultas'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('error de credenciales se muestra en español', (tester) async {
    http.on(
      'POST',
      '/auth/login',
      (_) => const FakeResponse(401, {'detail': 'Correo o contraseña incorrectos.'}),
    );
    await pumpApp(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Incorrecta1');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });

  testWidgets('el enlace de registro muestra el formulario con requisitos de contraseña', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Incluye números'), findsOneWidget);
  });
}
