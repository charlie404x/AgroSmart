import 'package:dio/dio.dart';

enum ApiErrorType { network, timeout, unauthorized, validation, notFound, conflict, rateLimited, server, unknown }

/// Error de la API ya traducido a un mensaje comprensible para el usuario.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.type = ApiErrorType.unknown});

  final String message;
  final int? statusCode;
  final ApiErrorType type;

  bool get isUnauthorized => type == ApiErrorType.unauthorized;
  bool get isNetwork => type == ApiErrorType.network || type == ApiErrorType.timeout;

  @override
  String toString() => message;

  /// Convierte cualquier [DioException] en un [ApiException] con mensaje en español.
  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'El servidor tardó demasiado en responder. Inténtalo nuevamente.',
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'No pudimos conectar con el servidor. Revisa tu conexión a internet.',
          type: ApiErrorType.network,
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          'La conexión con el servidor no es segura (certificado inválido).',
          type: ApiErrorType.network,
        );
      case DioExceptionType.cancel:
        return const ApiException('La solicitud fue cancelada.');
      case DioExceptionType.badResponse:
        return ApiException.fromResponse(e.response?.statusCode, e.response?.data);
      // `unknown` y cualquier tipo agregado en versiones futuras de Dio.
      default:
        return const ApiException(
          'No pudimos conectar con el servidor. Revisa tu conexión a internet.',
          type: ApiErrorType.network,
        );
    }
  }

  factory ApiException.fromResponse(int? status, Object? data) {
    String? detail;
    if (data is Map) {
      final d = data['detail'];
      if (d is String && d.trim().isNotEmpty) detail = d;
    }
    final type = switch (status) {
      401 => ApiErrorType.unauthorized,
      404 => ApiErrorType.notFound,
      409 => ApiErrorType.conflict,
      422 || 400 => ApiErrorType.validation,
      429 => ApiErrorType.rateLimited,
      final s? when s >= 500 => ApiErrorType.server,
      _ => ApiErrorType.unknown,
    };
    final fallback = switch (type) {
      ApiErrorType.unauthorized => 'Tu sesión expiró. Inicia sesión nuevamente.',
      ApiErrorType.notFound => 'No encontramos la información solicitada.',
      ApiErrorType.conflict => 'Ese registro ya existe.',
      ApiErrorType.validation => 'Revisa los datos ingresados.',
      ApiErrorType.rateLimited => 'Demasiados intentos. Espera un minuto e inténtalo de nuevo.',
      ApiErrorType.server => 'El servidor tuvo un problema. Inténtalo más tarde.',
      _ => 'Ocurrió un error inesperado (código ${status ?? '-'}).',
    };
    // En errores 5xx nunca se muestran detalles técnicos del servidor.
    final message = type == ApiErrorType.server ? fallback : (detail ?? fallback);
    return ApiException(message, statusCode: status, type: type);
  }
}
