import 'package:dio/dio.dart';
import '../core/api_client.dart';

class CategoriaRepository {
  final ApiClient _apiClient;
  CategoriaRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getCategorias({int page = 1}) async {
    final response = await _apiClient.dio.get(
      '/categorias/',
      queryParameters: {'page': page},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createCategoria(
    Map<String, dynamic> data,
  ) async {
    final response =
        await _apiClient.dio.post('/categorias/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateCategoria(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response =
        await _apiClient.dio.patch('/categorias/$id/', data: data);
    return response.data;
  }

  Future<void> deleteCategoria(String id) async {
    await _apiClient.dio.delete('/categorias/$id/');
  }
}
