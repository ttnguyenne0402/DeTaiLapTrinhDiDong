import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../utils/post_image_path.dart';

class RoomService {
  static const String baseUrl = '$postImageApiOrigin/api';

  Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      final uri = Uri.parse('$baseUrl/Room');

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Lỗi HTTP: ${response.statusCode}');
      }

      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonData['success'] != true) {
        throw Exception(jsonData['message'] ?? 'Không thể tải danh sách phòng');
      }

      final List<dynamic> data = jsonData['data'] ?? [];

      return data.map((item) {
        final room = Map<String, dynamic>.from(item);

        _applyImages(room);
        room['amenities'] = List<String>.from(room['amenities'] ?? []);

        return room;
      }).toList();
    } catch (e) {
      throw Exception('Lỗi tải danh sách phòng: $e');
    }
  }

  Future<Map<String, dynamic>> getRoomById(String roomId) async {
    try {
      final uri = Uri.parse('$baseUrl/Room/${Uri.encodeComponent(roomId)}');

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Lỗi HTTP: ${response.statusCode}');
      }

      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonData['success'] != true || jsonData['data'] == null) {
        throw Exception(jsonData['message'] ?? 'Không thể tải chi tiết phòng');
      }

      final room = Map<String, dynamic>.from(jsonData['data']);

      _applyImages(room);
      room['amenities'] = List<String>.from(room['amenities'] ?? []);

      return room;
    } catch (e) {
      throw Exception('Lỗi tải chi tiết phòng: $e');
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(String roomId, {String? userId}) async {
    try {
      final query = (userId != null && userId.isNotEmpty) ? '?userId=$userId' : '';
      final uri = Uri.parse('$baseUrl/Room/${Uri.encodeComponent(roomId)}/favorite$query');
      final response = await http
          .post(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {}
    return {};
  }

  void _applyImages(Map<String, dynamic> room) {
    final images = (room['images'] as List? ?? [])
        .whereType<String>()
        .where(isSharedPostImage)
        .toList();
    if (images.isEmpty) {
      final fallback = room['image']?.toString() ?? '';
      images.addAll(
        fallback.split(',').map((s) => s.trim()).where(isSharedPostImage),
      );
    }
    final paths = images.map(postImageDisplayPath).toList();
    room['images'] = paths;
    room['image'] = paths.isEmpty ? '' : paths.first;
  }
}
