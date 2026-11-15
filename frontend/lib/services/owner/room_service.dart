import 'dart:convert';
import 'package:http/http.dart' as http;

class RoomModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String name;
  final double area;
  final int? floor;
  final double price;
  final double deposit;
  final int maxPeople;
  final String status;
  final String statusText;
  final bool isRented;
  final String detail;
  final String priceFormatted;
  final String images;
  final String? description;

  RoomModel({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.name,
    required this.area,
    this.floor,
    required this.price,
    required this.deposit,
    required this.maxPeople,
    required this.status,
    required this.statusText,
    required this.isRented,
    required this.detail,
    required this.priceFormatted,
    required this.images,
    this.description,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? '',
      propertyId: json['propertyId'] ?? '',
      propertyName: json['propertyName'] ?? '',
      name: json['name'] ?? '',
      area: (json['area'] is num) ? (json['area'] as num).toDouble() : 0.0,
      floor: json['floor'],
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      deposit: (json['deposit'] is num) ? (json['deposit'] as num).toDouble() : 0.0,
      maxPeople: json['maxPeople'] ?? 2,
      status: json['status'] ?? 'available',
      statusText: json['statusText'] ?? 'Còn trống',
      isRented: json['isRented'] ?? false,
      detail: json['detail'] ?? '',
      priceFormatted: json['priceFormatted'] ?? '',
      images: json['images'] ?? 'frontend/assets/images/anhPhongDemo.jpg',
      description: json['description'],
    );
  }
}

class RoomService {
  static const String baseUrl = 'http://10.0.2.2:5093';

  // Lấy danh sách phòng theo bộ lọc: 'all', 'rented', 'empty'
  static Future<List<RoomModel>> fetchRooms(
    String ownerId, {
    String status = 'all',
    String? propertyId,
  }) async {
    String url = '$baseUrl/api/owner/rooms/$ownerId?status=$status';
    if (propertyId != null && propertyId.isNotEmpty && propertyId != 'all') {
      url += '&propertyId=$propertyId';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((item) => RoomModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách phòng trọ');
    }
  }

  // Thêm mới phòng (trả về null nếu thành công, hoặc chuỗi thông báo lỗi)
  static Future<String?> createRoomWithMessage(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/owner/rooms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return null;
    try {
      final err = jsonDecode(response.body);
      if (err is Map && err['message'] != null) {
        return err['message'].toString();
      }
    } catch (_) {}
    return 'Thêm phòng thất bại. Vui lòng thử lại!';
  }

  // Cập nhật phòng (trả về null nếu thành công, hoặc chuỗi thông báo lỗi)
  static Future<String?> updateRoomWithMessage(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/owner/rooms/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return null;
    try {
      final err = jsonDecode(response.body);
      if (err is Map && err['message'] != null) {
        return err['message'].toString();
      }
    } catch (_) {}
    return 'Cập nhật phòng thất bại. Vui lòng thử lại!';
  }

  // Thêm mới phòng
  static Future<bool> createRoom(Map<String, dynamic> data) async {
    final err = await createRoomWithMessage(data);
    return err == null;
  }

  // Cập nhật thông tin phòng
  static Future<bool> updateRoom(String id, Map<String, dynamic> data) async {
    final err = await updateRoomWithMessage(id, data);
    return err == null;
  }

  // Xóa phòng
  static Future<bool> deleteRoom(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/owner/rooms/$id'),
    );
    return response.statusCode == 200;
  }
}

