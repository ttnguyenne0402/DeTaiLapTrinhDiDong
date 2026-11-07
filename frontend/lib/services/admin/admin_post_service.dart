import 'dart:convert';
import 'package:http/http.dart' as http;

// 1. Model cho từng tin ở màn hình danh sách
class AdminPostItem {
  final String id;
  final String title;
  final double price;
  final String address;
  final String ownerName;
  final String status;
  final String? thumbnail;
  final DateTime? createdAt;

  AdminPostItem({
    required this.id,
    required this.title,
    required this.price,
    required this.address,
    required this.ownerName,
    required this.status,
    this.thumbnail,
    this.createdAt,
  });

  factory AdminPostItem.fromJson(Map<String, dynamic> json) {
    return AdminPostItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      ownerName: json['ownerName'] ?? 'Ẩn danh',
      status: json['status'] ?? 'pending',
      thumbnail: json['thumbnail'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

// 2. Model cho chi tiết tin ở màn hình thẩm định
class AdminPostDetail {
  final String id;
  final String roomId;
  final String title;
  final String description;
  final String status;
  final String? rejectionReason;
  final DateTime? createdAt; // <-- THÊM DÒNG NÀY
  final String ownerName;
  final String? ownerPhone;
  final String propertyName;
  final String address;
  final double price;
  final double deposit;
  final double area;
  final int maxPeople;
  final int? floor;
  final List<String> images;
  final List<String> amenities;

  AdminPostDetail({
    required this.id,
    required this.roomId,
    required this.title,
    required this.description,
    required this.status,
    this.rejectionReason,
    this.createdAt, // <-- THÊM VÀO CONSTRUCTOR
    required this.ownerName,
    this.ownerPhone,
    required this.propertyName,
    required this.address,
    required this.price,
    required this.deposit,
    required this.area,
    required this.maxPeople,
    this.floor,
    required this.images,
    required this.amenities,
  });

  factory AdminPostDetail.fromJson(Map<String, dynamic> json) {
    return AdminPostDetail(
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null, // <-- THÊM PARSE TỪ JSON
      ownerName: json['ownerName'] ?? 'Ẩn danh',
      ownerPhone: json['ownerPhone'],
      propertyName: json['propertyName'] ?? '',
      address: json['address'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      deposit: (json['deposit'] as num?)?.toDouble() ?? 0.0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      maxPeople: json['maxPeople'] ?? 0,
      floor: json['floor'],
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

// 3. Service gọi HTTP
class AdminPostService {
  // Cổng HTTP 5093 đã cấu hình cho máy ảo Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5093/api/AdminPosts';

  // Lấy danh sách tin theo trạng thái
  static Future<List<AdminPostItem>> getPosts(String status) async {
    final response = await http.get(
      Uri.parse('$baseUrl?status=$status'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => AdminPostItem.fromJson(e)).toList();
    }
    throw Exception('Lỗi lấy danh sách bài đăng: ${response.statusCode}');
  }

  // Lấy chi tiết 1 tin đăng
  static Future<AdminPostDetail> getPostDetail(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AdminPostDetail.fromJson(jsonDecode(response.body));
    }
    throw Exception('Lỗi lấy chi tiết tin đăng: ${response.statusCode}');
  }

  // Duyệt hoặc Từ chối tin đăng
  static Future<bool> moderatePost({
    required String id,
    required String action, // "approve" hoặc "reject"
    String? rejectionReason,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id/moderate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': action,
        'rejectionReason': rejectionReason,
      }),
    );

    return response.statusCode == 200;
  }
}