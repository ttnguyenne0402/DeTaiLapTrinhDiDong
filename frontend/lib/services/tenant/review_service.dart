
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth_storage.dart';

class ReviewService {
  static const String baseUrl = 'http://10.0.2.2:5093/api/Review';

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    final body = utf8.decode(response.bodyBytes);

    Map<String, dynamic> data = {};

    if (body.isNotEmpty) {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ??
            data['title']?.toString() ??
            'Lỗi máy chủ: ${response.statusCode}',
      );
    }

    if (data['success'] == false) {
      throw Exception(
        data['message']?.toString() ?? 'Thao tác không thành công.',
      );
    }

    return data;
  }

  // Lấy danh sách đánh giá của phòng
  static Future<List<Map<String, dynamic>>> getRoomReviews(
    String roomId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/room/$roomId'),
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    final result = _decodeResponse(response);
    final dynamic data = result['data'];

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Lấy thống kê đánh giá
  static Future<Map<String, dynamic>> getRoomReviewSummary(
    String roomId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/room/$roomId/summary'),
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    final result = _decodeResponse(response);
    final dynamic data = result['data'];

    if (data is! Map) {
      throw Exception('Dữ liệu thống kê đánh giá không hợp lệ.');
    }

    return Map<String, dynamic>.from(data);
  }

  // Gửi đánh giá
  static Future<Map<String, dynamic>> createReview({
    required String roomId,
    required int rating,
    required String comment,
  }) async {
    final tenantId = await AuthStorage.getUserId();
    final token = await AuthStorage.getAccessToken();

    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Không tìm thấy tài khoản đăng nhập.');
    }

    if (token == null || token.isEmpty) {
      throw Exception('Không tìm thấy token đăng nhập.');
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'roomId': roomId,
        'tenantId': tenantId,
        'rating': rating,
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 15));

    final result = _decodeResponse(response);
    final dynamic data = result['data'];

    if (data is! Map) {
      throw Exception('Backend không trả về đánh giá hợp lệ.');
    }

    return Map<String, dynamic>.from(data);
  }
}
 