import 'package:dio/dio.dart';
import '../core/api_client.dart';

class ProductoRepository {
  final ApiClient _apiClient;
  ProductoRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getProductos({
    int page = 1,
    String? search,
    String? categoriaId,
    bool? tieneAlerta,
  }) async {
    final query = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (categoriaId != null) query['categoria'] = categoriaId;
    if (tieneAlerta != null) query['tiene_alerta'] = tieneAlerta;
    final response =
        await _apiClient.dio.get('/productos/', queryParameters: query);
    return response.data;
  }

  Future<Map<String, dynamic>> getProducto(String id) async {
    final response = await _apiClient.dio.get('/productos/$id/');
    return response.data;
  }

  Future<Map<String, dynamic>> createProducto(
    Map<String, dynamic> data,
  ) async {
    final response =
        await _apiClient.dio.post('/productos/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProducto(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response =
        await _apiClient.dio.patch('/productos/$id/', data: data);
    return response.data;
  }

  Future<void> deleteProducto(String id) async {
    await _apiClient.dio.delete('/productos/$id/');
  }
}
