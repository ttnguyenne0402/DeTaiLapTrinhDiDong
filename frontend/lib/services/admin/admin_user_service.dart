import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;   // "admin", "owner", "tenant"
  final String status; // "active", "inactive", "blocked"

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    required this.status,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'] ?? 'tenant',
      status: json['status'] ?? 'active',
    );
  }

  // Chuyển role tiếng Anh sang tiếng Việt để hiển thị
  String get displayRole {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Chủ trọ';
      case 'tenant':
        return 'Người thuê';
      case 'admin':
        return 'Quản trị viên';
      default:
        return role;
    }
  }

  // Chuyển status tiếng Anh sang tiếng Việt
  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Kích hoạt';
      case 'blocked':
        return 'Đã khóa';
      default:
        return 'Chưa kích hoạt';
    }
  }

  bool get isActive => status.toLowerCase() == 'active';
}

class AdminUserService {
  static const String baseUrl = 'http://10.0.2.2:5093/api/AdminUsers';

  // Lấy danh sách tài khoản
  static Future<List<AdminUserModel>> getUsers({String? role, String? search}) async {
    String url = baseUrl;
    List<String> params = [];

    if (role != null && role.isNotEmpty && role != 'all') {
      params.add('role=$role');
    }
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => AdminUserModel.fromJson(e)).toList();
    }
    throw Exception('Lỗi nạp danh sách tài khoản: ${response.statusCode}');
  }

  // Cập nhật trạng thái (active / blocked)
  static Future<bool> toggleUserStatus(String id, String newStatus) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
    );
    return response.statusCode == 200;
  }
}