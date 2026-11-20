import 'dart:convert';
import 'package:http/http.dart' as http;

class PropertyModel {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final int totalRooms;
  final int rentedRooms;
  final int emptyRooms;
  final String status;
  final String image;

  PropertyModel({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.totalRooms,
    required this.rentedRooms,
    required this.emptyRooms,
    required this.status,
    required this.image,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      totalRooms: json['totalRooms'] ?? 0,
      rentedRooms: json['rentedRooms'] ?? 0,
      emptyRooms: json['emptyRooms'] ?? 0,
      status: json['status'] ?? 'Đang hoạt động',
      image: json['image'] ?? 'frontend/assets/images/anhPhongDemo.jpg',
    );
  }
}

class PropertyService {
  // Dùng HTTP (cổng 5093) để tránh lỗi SSL certificate trên Android Emulator (đồng bộ với các service khác)
  static const String baseUrl = 'http://10.0.2.2:5093';

  static Future<List<PropertyModel>> fetchProperties(
    String ownerId,
    String filter,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/owner/properties/$ownerId?status=$filter'),
    );

    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((item) => PropertyModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách bất động sản');
    }
  }

  static Future<bool> createProperty(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/owner/properties'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }
}
