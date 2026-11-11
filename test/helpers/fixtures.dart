import 'dart:convert';
import 'dart:io';

/// Utilidades de prueba sin dependencias de Flutter.
/// Lee un fixture JSON generado a partir del backend real (ver test/fixtures/README.md).
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

/// JWT sintáctico con `exp` = ahora + [validFor] (la firma no se valida en el cliente).
String fakeJwt({Duration validFor = const Duration(minutes: 30), String sub = 'ana@example.com'}) {
  String enc(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  final exp = DateTime.now().add(validFor).millisecondsSinceEpoch ~/ 1000;
  return '${enc({'alg': 'HS256', 'typ': 'JWT'})}.${enc({'sub': sub, 'exp': exp})}.firma';
}

/// Respuesta de login/registro con un token vigente.
Map<String, dynamic> loginBody({Duration validFor = const Duration(minutes: 30)}) => {
  ...fixture('login_response.json'),
  'access_token': fakeJwt(validFor: validFor),
};
