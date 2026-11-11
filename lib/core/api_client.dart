import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Cliente HTTP único de la app.
///
/// - Añade el token Bearer a cada solicitud.
/// - Traduce los errores a [ApiException] con mensajes en español.
/// - Avisa mediante [onUnauthorized] cuando una solicitud autenticada recibe 401
///   (token vencido o revocado) para cerrar la sesión y volver al login.
class ApiClient {
  ApiClient({required String baseUrl, Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          final hadToken = error.requestOptions.headers.containsKey('Authorization');
          if (status == 401 && hadToken && !ApiEndpoints.publicAuth.contains(path)) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
    if (kDebugMode) {
      // Nunca se registran cabeceras: contienen el token.
      _dio.interceptors.add(LogInterceptor(logPrint: (o) => debugPrint(o.toString())));
    }
  }

  final Dio _dio;
  String? _token;

  /// Se invoca cuando el backend rechaza el token de una solicitud autenticada.
  VoidCallback? onUnauthorized;

  String get baseUrl => _dio.options.baseUrl;

  void setToken(String? token) => _token = token;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) => _send(() => _dio.post<dynamic>(path, data: data));

  Future<dynamic> delete(String path) => _send(() => _dio.delete<dynamic>(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
