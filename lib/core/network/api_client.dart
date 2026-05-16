/// EduCinema LMS — API Client (Dio)
/// Centralized HTTP client with JWT interceptor for automatic token refresh.
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── Request Interceptor: Attach JWT ──
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Attempt token refresh
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry original request with new token
              final token = await _storage.read(key: AppConstants.accessTokenKey);
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConstants.baseUrl}${AppConstants.apiPrefix}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        await _storage.write(
          key: AppConstants.accessTokenKey,
          value: response.data['access_token'],
        );
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: response.data['refresh_token'],
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Convenience Methods ──
  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      dio.patch(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      dio.put(path, data: data);

  Future<Response> delete(String path) => dio.delete(path);
}
