import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String firstName = '',
    String lastName = '',
  }) async {
    final response = await _apiClient.dio.post('/auth/register/', data: {
      'username': username,
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'first_name': firstName,
      'last_name': lastName,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String userId,
    required String code,
  }) async {
    final response = await _apiClient.dio.post('/auth/verify-email/', data: {
      'user_id': userId,
      'code': code,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String userId,
    required String code,
  }) async {
    final response = await _apiClient.dio.post('/auth/verify-otp/', data: {
      'user_id': userId,
      'code': code,
    });
    if (response.data['success'] == true) {
      final data = response.data['data'];
      await _apiClient.saveTokens(data['access'], data['refresh']);
    }
    return response.data;
  }

  Future<Map<String, dynamic>> resendOtp({
    required String userId,
    required String purpose,
  }) async {
    final response = await _apiClient.dio.post('/auth/resend-otp/', data: {
      'user_id': userId,
      'purpose': purpose,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    final response = await _apiClient.dio.post('/auth/password-reset/', data: {
      'email': email,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/password-reset/confirm/',
      data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      },
    );
    return response.data;
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await _apiClient.dio.get('/auth/me/');
      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout/');
    } catch (_) {}
    await _apiClient.clearTokens();
  }

  Future<bool> checkEmailAvailable(String email) async {
    final response = await _apiClient.dio.get(
      '/auth/check-email/',
      queryParameters: {'email': email},
    );
    return response.data['data']['available'] ?? false;
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getAccessToken();
    return token != null;
  }
}
