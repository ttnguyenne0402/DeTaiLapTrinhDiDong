import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:5093/api/Auth';

  // Đọc và xử lý phản hồi từ backend
  static Map<String, dynamic> _parseResponse(
    http.Response response,
    String defaultMessage,
  ) {
    Map<String, dynamic> data = {};
    final String body = response.body.trim();

    if (body.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else {
          data = {'data': decoded};
        }
      } catch (_) {
        data = {'message': body};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final dynamic errorMessage =
        data['message'] ?? data['title'] ?? data['detail'];

    final String message = errorMessage?.toString().isNotEmpty == true
        ? errorMessage.toString()
        : body.isNotEmpty
        ? body
        : defaultMessage;

    throw Exception('HTTP ${response.statusCode}: $message');
  }

  // ĐĂNG NHẬP
  static Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'emailOrPhone': emailOrPhone,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return _parseResponse(response, 'Đăng nhập thất bại');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Không thể kết nối tới máy chủ: $e');
    }
  }

  // ĐĂNG KÝ
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String emailOrPhone,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'fullName': fullName,
              'emailOrPhone': emailOrPhone,
              'password': password,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return _parseResponse(response, 'Đăng ký thất bại');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Không thể kết nối tới máy chủ: $e');
    }
  }

  // ĐĂNG NHẬP GOOGLE
  static Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
  }) async {
    final url = Uri.parse('$baseUrl/google-login');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 15));

      return _parseResponse(response, 'Đăng nhập Google thất bại');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Không thể kết nối tới máy chủ: $e');
    }
  }

  // ĐĂNG KÝ GOOGLE
  static Future<Map<String, dynamic>> googleRegister({
    required String idToken,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/google-register');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'idToken': idToken, 'role': role}),
          )
          .timeout(const Duration(seconds: 15));

      return _parseResponse(response, 'Đăng ký Google thất bại');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Không thể kết nối tới máy chủ: $e');
    }
  }

  // ĐĂNG KÝ ZALO
  static Future<Map<String, dynamic>> zaloRegister({
    required String accessToken,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/zalo-register');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'accessToken': accessToken, 'role': role}),
          )
          .timeout(const Duration(seconds: 20));

      // In thông tin phản hồi để xác định lỗi từ backend
      debugPrint('[ZALO API] Status: ${response.statusCode}');
      debugPrint('[ZALO API] Body: ${response.body}');

      return _parseResponse(response, 'Đăng ký Zalo thất bại');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi gọi API đăng ký Zalo: $e');
    }
  }

  // ĐĂNG NHẬP ZALO: chỉ đăng nhập tài khoản đã liên kết
  static Future<Map<String, dynamic>> zaloLogin({
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/zalo-login');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'accessToken': accessToken}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('[ZALO LOGIN] Status: ${response.statusCode}');
      debugPrint('[ZALO LOGIN] Body: ${response.body}');

      return _parseResponse(response, 'Đăng nhập Zalo thất bại');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi gọi API đăng nhập Zalo: $e');
    }
  }
}
