/// EduCinema LMS — API Repository
/// Generic data fetching for all modules.
library;

import '../../core/network/api_client.dart';

class ApiRepository {
  final ApiClient _api = ApiClient();

  // ── Generic ──
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async {
    final res = await _api.get(path, params: params);
    return res.data is Map<String, dynamic> ? res.data : {'data': res.data};
  }

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? params}) async {
    final res = await _api.get(path, params: params);
    return res.data is List ? res.data : [];
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    final res = await _api.post(path, data: data);
    return res.data is Map<String, dynamic> ? res.data : {'data': res.data};
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic data}) async {
    final res = await _api.patch(path, data: data);
    return res.data is Map<String, dynamic> ? res.data : {'data': res.data};
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    final res = await _api.put(path, data: data);
    return res.data is Map<String, dynamic> ? res.data : {'data': res.data};
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await _api.delete(path);
    return res.data is Map<String, dynamic> ? res.data : {'data': res.data};
  }
}
