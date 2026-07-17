import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class ApiClient {
  /// Chamado sempre que uma requisição volta 401, para que o estado de
  /// autenticação da UI seja limpo imediatamente (não só na próxima navegação).
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query});
  Future<dynamic> post(String path, {Object? body});
  Future<dynamic> put(String path, {Object? body});
  Future<dynamic> delete(String path);
  Future<Uint8List> getBytes(String path);
}

class DioApiClient implements ApiClient {
  DioApiClient(this._tokenStorage)
      : _dio = Dio(BaseOptions(baseUrl: apiBaseUrl, connectTimeout: const Duration(seconds: 10))) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) => handler.next(response),
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStorage.clear();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  @override
  void Function()? onUnauthorized;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _request(() => _dio.get(path, queryParameters: query));

  @override
  Future<dynamic> post(String path, {Object? body}) =>
      _request(() => _dio.post(path, data: body));

  @override
  Future<dynamic> put(String path, {Object? body}) =>
      _request(() => _dio.put(path, data: body));

  @override
  Future<dynamic> delete(String path) => _request(() => _dio.delete(path));

  @override
  Future<Uint8List> getBytes(String path) async {
    try {
      final response = await _dio.get<List<int>>(path, options: Options(responseType: ResponseType.bytes));
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw ApiException(_errorMessage(e.response?.data), statusCode: e.response?.statusCode);
    }
  }

  String _errorMessage(Object? data) {
    if (data is Map && data['error'] != null) return data['error'] as String;
    if (data is List<int>) {
      try {
        final decoded = jsonDecode(utf8.decode(data));
        if (decoded is Map && decoded['error'] != null) return decoded['error'] as String;
      } catch (_) {
        // corpo não é JSON (ex.: PDF) — usa a mensagem genérica abaixo.
      }
    }
    return 'Erro de conexão com o servidor';
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['error'] != null
          ? data['error'] as String
          : 'Erro de conexão com o servidor';
      throw ApiException(message, statusCode: e.response?.statusCode);
    }
  }
}
