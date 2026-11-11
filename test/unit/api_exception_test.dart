import 'package:agrosmart_peru/core/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  test('usa el detalle en español del backend', () {
    final e = ApiException.fromResponse(422, fixture('error_validation_response.json'));
    expect(e.type, ApiErrorType.validation);
    expect(e.message, startsWith('Departamento no válido'));
  });

  test('401 se marca como no autorizado', () {
    final e = ApiException.fromResponse(401, fixture('error_unauthorized_response.json'));
    expect(e.isUnauthorized, isTrue);
    expect(e.message, contains('sesión'));
  });

  test('errores 5xx nunca muestran detalles técnicos', () {
    final e = ApiException.fromResponse(500, {'detail': 'Traceback (most recent call last)...'});
    expect(e.type, ApiErrorType.server);
    expect(e.message, isNot(contains('Traceback')));
  });

  test('errores de conexión y tiempo de espera', () {
    final options = RequestOptions(path: '/x');
    final conn = ApiException.fromDio(
      DioException(requestOptions: options, type: DioExceptionType.connectionError),
    );
    final timeout = ApiException.fromDio(
      DioException(requestOptions: options, type: DioExceptionType.receiveTimeout),
    );
    expect(conn.type, ApiErrorType.network);
    expect(conn.message, contains('conexión'));
    expect(timeout.type, ApiErrorType.timeout);
    expect(conn.isNetwork && timeout.isNetwork, isTrue);
  });

  test('429 sugiere esperar', () {
    expect(ApiException.fromResponse(429, null).message, contains('Espera'));
  });
}
