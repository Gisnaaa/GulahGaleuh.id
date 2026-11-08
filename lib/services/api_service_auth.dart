import 'package:dio/dio.dart'; // <-- Pastikan baris ini ada di paling atas

import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class ApiServiceAuth {
  final Dio _dio = Dio(
    BaseOptions(
      // PERBAIKI DI SINI: Hapus garis miring ganda dan buang /auth di belakang
      baseUrl: 'http://10.182.31.211:8080',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<AuthResult> login(String username, String password) async {
    try {
      // PERBAIKI DI SINI: Sertakan /auth/login secara lengkap
      final res = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return AuthResult.fromJson(res.data);
    } on DioException catch (e) {
      throw AuthException(_messageFrom(e));
    }
  }

  Future<AuthResult> register({
    required String name,
    required String username,
    required String password,
  }) async {
    try {
      // PERBAIKI DI SINI: Sertakan /auth/register secara lengkap
      final res = await _dio.post(
        '/auth/register',
        data: {'name': name, 'username': username, 'password': password},
      );
      return AuthResult.fromJson(res.data);
    } on DioException catch (e) {
      throw AuthException(_messageFrom(e));
    }
  }

  Future<AuthUser?> me(String token) async {
    try {
      // PERBAIKI DI SINI: Sertakan /auth/me secara lengkap
      final res = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return AuthUser.fromJson(res.data['user'] ?? {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'];
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server';
    }
    return 'Terjadi kesalahan, coba lagi';
  }
}
