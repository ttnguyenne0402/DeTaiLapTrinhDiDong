import 'dart:convert';
import 'package:http/http.dart' as http;

class PostModel {
  final String id;
  final String roomId;
  final String roomName;
  final String propertyId;
  final String propertyName;
  final String propertyAddress;
  final String room;
  final double roomArea;
  final double roomDeposit;
  final int roomMaxPeople;
  final int? roomFloor;
  final String roomStatus;
  final String roomDescription;
  final String title;
  final String description;
  final double price;
  final String priceFormatted;
  final List<String> amenities;
  final int views;
  final int likes;
  final String date;
  final String status;
  final String? submitNote;
  final String? rejectReason;
  final String image;
  final List<String> images;

  PostModel({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.propertyId,
    required this.propertyName,
    required this.propertyAddress,
    required this.room,
    required this.roomArea,
    required this.roomDeposit,
    required this.roomMaxPeople,
    this.roomFloor,
    required this.roomStatus,
    required this.roomDescription,
    required this.title,
    required this.description,
    required this.price,
    required this.priceFormatted,
    required this.amenities,
    required this.views,
    required this.likes,
    required this.date,
    required this.status,
    this.submitNote,
    this.rejectReason,
    required this.image,
    required this.images,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    var imgList = json['images'] as List? ?? [];
    List<String> images = imgList.map((e) => e.toString()).toList();

    var amnList = json['amenities'] as List? ?? [];
    List<String> amenities = amnList.map((e) => e.toString()).toList();

    return PostModel(
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      roomName: json['roomName'] ?? '',
      propertyId: json['propertyId'] ?? '',
      propertyName: json['propertyName'] ?? '',
      propertyAddress: json['propertyAddress'] ?? '',
      room: json['room'] ?? '',
      roomArea: (json['roomArea'] is num) ? (json['roomArea'] as num).toDouble() : 0.0,
      roomDeposit: (json['roomDeposit'] is num) ? (json['roomDeposit'] as num).toDouble() : 0.0,
      roomMaxPeople: (json['roomMaxPeople'] is num) ? (json['roomMaxPeople'] as num).toInt() : 0,
      roomFloor: (json['roomFloor'] is num) ? (json['roomFloor'] as num).toInt() : null,
      roomStatus: json['roomStatus'] ?? 'available',
      roomDescription: json['roomDescription'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      priceFormatted: json['priceFormatted'] ?? '',
      amenities: amenities,
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
      submitNote: json['submitNote'],
      rejectReason: json['rejectReason'],
      image: json['image'] ?? 'frontend/assets/images/anhPhongDemo.jpg',
      images: images,
    );
  }
}

class PostService {
  static const String baseUrl = 'http://10.0.2.2:5093';

  // Lấy danh sách bài đăng theo bộ lọc: 'all', 'active', 'pending', 'draft_or_other'
  static Future<List<PostModel>> fetchPosts(
    String ownerId, {
    String status = 'all',
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/owner/posts/$ownerId?status=$status'),
    );

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((item) => PostModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách bài đăng');
    }
  }

  // Lấy chi tiết một bài đăng
  static Future<PostModel> fetchPostDetail(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/owner/posts/detail/$id'),
    );

    if (response.statusCode == 200) {
      return PostModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không thể tải chi tiết bài đăng');
    }
  }

  // Đăng tin mới
  static Future<bool> createPost(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/owner/posts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // Cập nhật nội dung tin đăng
  static Future<bool> updatePost(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/owner/posts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // Cập nhật trạng thái tin (ẩn, hiện, gửi duyệt)
  static Future<bool> updatePostStatus(String id, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/owner/posts/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  // Xóa tin đăng
  static Future<bool> deletePost(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/owner/posts/$id'),
    );
    return response.statusCode == 200;
  }
}

