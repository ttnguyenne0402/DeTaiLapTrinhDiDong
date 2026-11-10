import 'dart:convert';
import 'package:http/http.dart' as http;

class ServiceModel {
  final String id;
  final String? ownerId;
  final String name;
  final double price;
  final String priceFormatted;
  final String unit;
  final bool isMandatory;
  final bool status;
  final String description;
  final String icon;

  ServiceModel({
    required this.id,
    this.ownerId,
    required this.name,
    required this.price,
    required this.priceFormatted,
    required this.unit,
    required this.isMandatory,
    required this.status,
    required this.description,
    required this.icon,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'],
      name: json['name'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      priceFormatted: json['priceFormatted'] ?? '',
      unit: json['unit'] ?? 'kWh',
      isMandatory: json['isMandatory'] ?? false,
      status: json['status'] ?? true,
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'bolt',
    );
  }
}

class ServiceManagementService {
  static const String baseUrl = 'http://10.0.2.2:5093';

  // Lấy danh sách dịch vụ của chủ trọ
  static Future<List<ServiceModel>> fetchServices(String ownerId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/owner/services/$ownerId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((item) => ServiceModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách dịch vụ');
    }
  }

  // Thêm dịch vụ mới
  static Future<bool> createService(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/owner/services'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // Cập nhật dịch vụ
  static Future<bool> updateService(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/owner/services/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // Bật / tắt nhanh trạng thái hoạt động của dịch vụ
  static Future<bool> toggleServiceStatus(String id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/owner/services/$id/toggle-status'),
    );
    return response.statusCode == 200;
  }

  // Xóa dịch vụ
  static Future<bool> deleteService(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/owner/services/$id'),
    );
    return response.statusCode == 200;
  }
}

