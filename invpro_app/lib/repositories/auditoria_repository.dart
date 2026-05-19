import '../core/api_client.dart';

class AuditoriaRepository {
  final ApiClient _apiClient;
  AuditoriaRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getLogs({
    int page = 1,
    String? action,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (action != null) params['action'] = action;

    final response = await _apiClient.dio.get(
      '/auditoria/',
      queryParameters: params,
    );
    return response.data;
  }
}