import 'package:dio/dio.dart';
import '../core/api_client.dart';

class DashboardRepository {
  final ApiClient _apiClient;
  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _apiClient.dio.get('/dashboard/');
      return response.data;
    } catch (_) {
      final productos = await _apiClient.dio.get('/productos/');
      final movimientos = await _apiClient.dio.get('/movimientos/');
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'productos': productos.data['data'] ?? [],
          'movimientos': movimientos.data['data'] ?? [],
        },
      };
    }
  }
}
