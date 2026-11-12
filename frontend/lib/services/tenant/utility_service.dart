import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth_storage.dart';

class TenantUtilityService {
  static const String _url = 'http://10.0.2.2:5093/api/tenant-utilities/mine';

  static Future<Map<String, dynamic>> getMyUtilityHistory() async {
    final token = await AuthStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Vui lòng đăng nhập lại để xem chỉ số điện nước.');
    }

    final response = await http.get(
      Uri.parse(_url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    }

    if (response.statusCode == 200) return body;
    throw Exception(body['message']?.toString() ?? 'Không tải được lịch sử điện nước.');
  }
}
