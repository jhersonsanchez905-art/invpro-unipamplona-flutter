import 'package:dio/dio.dart';
import '../core/api_client.dart';

class MovimientoRepository {
  final ApiClient _apiClient;
  MovimientoRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getMovimientos({
    int page = 1,
    String? tipo,
    String? productoId,
  }) async {
    final query = <String, dynamic>{'page': page};
    if (tipo != null && tipo.isNotEmpty) query['tipo'] = tipo;
    if (productoId != null) query['producto'] = productoId;
    final response =
        await _apiClient.dio.get('/movimientos/', queryParameters: query);
    return response.data;
  }

  Future<Map<String, dynamic>> createMovimiento(
    Map<String, dynamic> data,
  ) async {
    final response =
        await _apiClient.dio.post('/movimientos/', data: data);
    return response.data;
  }
}
