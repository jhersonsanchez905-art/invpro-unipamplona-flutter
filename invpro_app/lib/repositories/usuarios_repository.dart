import '../core/api_client.dart';

class UsuariosRepository {
  final ApiClient _apiClient;
  UsuariosRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getUsuarios({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _apiClient.dio.get(
      '/usuarios/',
      queryParameters: params,
    );
    return response.data;
  }
}