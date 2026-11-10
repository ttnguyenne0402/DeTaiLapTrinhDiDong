import 'dart:convert';
import 'package:http/http.dart' as http;

class RoomService {
  static const String baseUrl = 'http://10.0.2.2:5093/api';

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

        room['image'] ??= '';
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

      room['image'] ??= '';
      room['amenities'] = List<String>.from(room['amenities'] ?? []);

      return room;
    } catch (e) {
      throw Exception('Lỗi tải chi tiết phòng: $e');
    }
  }
}
