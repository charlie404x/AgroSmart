import 'dart:convert';
import 'dart:typed_data';

import 'package:agrosmart_peru/core/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

export 'fixtures.dart';

class FakeResponse {
  const FakeResponse(this.status, this.body);
  final int status;
  final Object? body;
}

typedef FakeHandler = FakeResponse Function(RequestOptions options);

/// Adaptador HTTP en memoria: responde según "MÉTODO /ruta" y registra cada solicitud.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter([Map<String, FakeHandler>? routes]) : routes = routes ?? {};

  final Map<String, FakeHandler> routes;
  final List<RequestOptions> requests = [];

  void on(String method, String path, FakeHandler handler) => routes['$method $path'] = handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final handler = routes['${options.method} ${options.path}'];
    final response = handler?.call(options) ?? const FakeResponse(404, {'detail': 'Recurso no encontrado.'});
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Cliente real conectado al adaptador falso.
ApiClient fakeApi(FakeHttpAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(baseUrl: 'http://test.local', dio: dio);
}

/// Usa una pantalla de teléfono (412x915 dp) en lugar de la de 800x600 por defecto,
/// para que listas y botones queden visibles igual que en un dispositivo real.
void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
