
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_storage.dart';

class ProfileService {
  static const String baseUrl = 'http://10.0.2.2:5093/api/Profile';

  // Lấy token đăng nhập
  static Future<String> _getToken() async {
    final token = await AuthStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }

    return token;
  }

  // Đọc JSON phản hồi từ Backend
  static Map<String, dynamic> _decodeResponse(String body) {
    if (body.trim().isEmpty) return {};

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  // Kiểm tra kết quả API
  static Map<String, dynamic> _handleResponse(
    http.Response response,
    String defaultMessage,
  ) {
    final result = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    final message = result['message'] ??
        result['title'] ??
        result['detail'] ??
        defaultMessage;

    throw Exception('HTTP ${response.statusCode}: $message');
  }

  // Headers dùng cho API cần xác thực
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // =====================================================
  // 1. LẤY THÔNG TIN NGƯỜI DÙNG ĐANG ĐĂNG NHẬP
  // GET: api/Profile
  // =====================================================
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final result = _handleResponse(
        response,
        'Không thể lấy thông tin cá nhân.',
      );

      final data = result['data'];

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Dữ liệu hồ sơ trả về không hợp lệ.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi kết nối API hồ sơ: $e');
    }
  }

  // =====================================================
  // 2. CẬP NHẬT THÔNG TIN CÁ NHÂN
  // PUT: api/Profile
  // =====================================================
  static Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(baseUrl),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 15));

      _handleResponse(
        response,
        'Không thể cập nhật thông tin cá nhân.',
      );
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi cập nhật thông tin cá nhân: $e');
    }
  }

  // =====================================================
  // 3. THÊM TÀI KHOẢN NGÂN HÀNG
  // POST: api/Profile/bank-accounts
  // =====================================================
  static Future<Map<String, dynamic>> addBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    String? bankCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bank-accounts'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'bankCode': bankCode,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountHolder': accountHolder,
        }),
      ).timeout(const Duration(seconds: 15));

      final result = _handleResponse(
        response,
        'Không thể thêm tài khoản ngân hàng.',
      );

      final data = result['data'];

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Dữ liệu tài khoản ngân hàng trả về không hợp lệ.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi thêm tài khoản ngân hàng: $e');
    }
  }

  // =====================================================
  // 4. CẬP NHẬT TÀI KHOẢN NGÂN HÀNG
  // PUT: api/Profile/bank-accounts/{id}
  // =====================================================
  static Future<Map<String, dynamic>> updateBankAccount({
    required String id,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    String? bankCode,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bank-accounts/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'bankCode': bankCode,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountHolder': accountHolder,
        }),
      ).timeout(const Duration(seconds: 15));

      final result = _handleResponse(
        response,
        'Không thể cập nhật tài khoản ngân hàng.',
      );

      final data = result['data'];

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Dữ liệu tài khoản ngân hàng trả về không hợp lệ.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi cập nhật tài khoản ngân hàng: $e');
    }
  }
}
