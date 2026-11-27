import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../utils/post_image_path.dart';
import '../auth_storage.dart';

class PostModel {
  final String id;
  final String roomId;
  final String roomName;
  final String propertyId;
  final String propertyName;
  final String propertyAddress;
  final String propertyWard;
  final String propertyDistrict;
  final double? latitude;
  final double? longitude;
  final String ownerName;
  final String? ownerPhone;
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
  final List<Map<String, dynamic>> services;
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
    this.propertyWard = '',
    this.propertyDistrict = '',
    this.latitude,
    this.longitude,
    this.ownerName = '',
    this.ownerPhone,
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
    this.services = const [],
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
    final images = imgList
        .map((e) => postImageDisplayPath(e.toString()))
        .toList();

    var amnList = json['amenities'] as List? ?? [];
    List<String> amenities = amnList.map((e) => e.toString()).toList();

    final servicesList = (json['services'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return PostModel(
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      roomName: json['roomName'] ?? '',
      propertyId: json['propertyId'] ?? '',
      propertyName: json['propertyName'] ?? '',
      propertyAddress: json['propertyAddress'] ?? '',
      propertyWard: json['propertyWard']?.toString() ?? '',
      propertyDistrict: json['propertyDistrict']?.toString() ?? '',
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? ''),
      ownerName: json['ownerName']?.toString() ?? '',
      ownerPhone: json['ownerPhone']?.toString(),
      room: json['room'] ?? '',
      roomArea: (json['roomArea'] is num)
          ? (json['roomArea'] as num).toDouble()
          : 0.0,
      roomDeposit: (json['roomDeposit'] is num)
          ? (json['roomDeposit'] as num).toDouble()
          : 0.0,
      roomMaxPeople: (json['roomMaxPeople'] is num)
          ? (json['roomMaxPeople'] as num).toInt()
          : 0,
      roomFloor: (json['roomFloor'] is num)
          ? (json['roomFloor'] as num).toInt()
          : null,
      roomStatus: json['roomStatus'] ?? 'available',
      roomDescription: json['roomDescription'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      priceFormatted: json['priceFormatted'] ?? '',
      amenities: amenities,
      services: servicesList,
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
      submitNote: json['submitNote'],
      rejectReason: json['rejectReason'],
      image: postImageDisplayPath(
        json['image']?.toString() ?? postImageFallback,
      ),
      images: images,
    );
  }
}

class PostService {
  static const String baseUrl = postImageApiOrigin;

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
    return _savePost('POST', '/api/owner/posts/with-images', data);
  }

  // Cập nhật nội dung tin đăng
  static Future<bool> updatePost(String id, Map<String, dynamic> data) async {
    return _savePost(
      'PUT',
      '/api/owner/posts/${Uri.encodeComponent(id)}/with-images',
      data,
    );
  }

  static Future<bool> _savePost(
    String method,
    String route,
    Map<String, dynamic> data,
  ) async {
    final client = http.Client();
    try {
      final token = await AuthStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw const PostSaveException('Vui lòng đăng nhập lại để lưu tin.');
      }

      final request = http.MultipartRequest(method, Uri.parse('$baseUrl$route'))
        ..headers['Authorization'] = 'Bearer $token';
      final references = <String>[];
      for (final path in (data['images'] as List? ?? []).whereType<String>()) {
        if (isSharedPostImage(path)) {
          final localPrefix = '$baseUrl$uploadedPostImagePrefix';
          references.add(
            path.startsWith(localPrefix)
                ? path.substring(baseUrl.length)
                : path,
          );
          continue;
        }

        final file = File(path);
        if (!await file.exists()) {
          throw const PostSaveException(
            'Có ảnh cũ không còn trên máy. Hãy bỏ ảnh đó và chọn lại.',
          );
        }
        if (await file.length() > 4 * 1024 * 1024) {
          throw const PostSaveException('Mỗi ảnh có dung lượng tối đa 4 MB.');
        }
        references.add('upload:${request.files.length}');
        request.files.add(await http.MultipartFile.fromPath('Files', path));
      }

      request.fields['Post'] = jsonEncode({...data, 'images': references});
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) return true;
      if (response.statusCode == 401) {
        throw const PostSaveException(
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        );
      }
      if (response.statusCode == 403) {
        throw const PostSaveException(
          'Bạn chỉ có thể đăng tin cho phòng thuộc tài khoản của mình.',
        );
      }
      if (response.statusCode == 413) {
        throw const PostSaveException('Ảnh quá lớn. Hãy chọn ảnh nhỏ hơn.');
      }
      final payload = response.headers['content-type']?.contains('json') == true
          ? jsonDecode(utf8.decode(response.bodyBytes))
          : null;
      final message = payload is Map ? payload['message'] : null;
      throw PostSaveException(
        message is String ? message : 'Không thể lưu tin đăng.',
      );
    } on PostSaveException {
      rethrow;
    } catch (_) {
      throw const PostSaveException(
        'Không thể gửi tin và ảnh. Vui lòng kiểm tra kết nối rồi thử lại.',
      );
    } finally {
      client.close();
    }
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

class PostSaveException implements Exception {
  const PostSaveException(this.message);
  final String message;
}
