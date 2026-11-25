import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AmenityModel {
  final String id;
  final String? ownerId;
  final String name;
  final String description;
  final String icon;
  final bool status;
  final String statusCode;
  final bool isAssigned;
  final String? propertyId;

  AmenityModel({
    required this.id,
    this.ownerId,
    required this.name,
    required this.description,
    required this.icon,
    required this.status,
    required this.statusCode,
    required this.isAssigned,
    this.propertyId,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'check_circle',
      status: json['status'] ?? true,
      statusCode: json['statusCode'] ?? 'active',
      isAssigned: json['isAssigned'] ?? false,
      propertyId: json['propertyId'],
    );
  }
}

class AmenityManagementService {
  static const String baseUrl = 'http://10.0.2.2:5093';

  // Lấy danh sách tiện ích của chủ trọ (kèm trạng thái đã bật theo từng khu trọ nếu truyền propertyId)
  static Future<List<AmenityModel>> fetchAmenities(String ownerId, {String? propertyId}) async {
    final query = (propertyId != null && propertyId.isNotEmpty) ? '?propertyId=$propertyId' : '';
    final url = '$baseUrl/api/owner/amenities/$ownerId$query';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((item) => AmenityModel.fromJson(item)).toList();
    }
    throw Exception('Lỗi SQL Server (${response.statusCode}): ${response.body}');
  }

  // Thêm tiện ích mới
  static Future<bool> createAmenity(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/owner/amenities'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Lỗi createAmenity: $e');
      return false;
    }
  }

  // Cập nhật tiện ích
  static Future<bool> updateAmenity(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/owner/amenities/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // Bật / tắt nhanh một tiện ích cho một khu trọ cụ thể
  static Future<bool> togglePropertyAmenity(String propertyId, String amenityId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/owner/amenities/property/$propertyId/toggle/$amenityId'),
    );
    return response.statusCode == 200;
  }

  // Đồng bộ danh sách tiện ích cho một khu trọ cụ thể
  static Future<bool> syncPropertyAmenities(String propertyId, List<String> amenityIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/owner/amenities/property/$propertyId/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(amenityIds),
    );
    return response.statusCode == 200;
  }

  // Xóa tiện ích
  static Future<bool> deleteAmenity(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/owner/amenities/$id'),
    );
    return response.statusCode == 200;
  }
}
