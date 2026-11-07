import 'dart:convert';
import 'package:http/http.dart' as http;

class ContractSummaryResponse {
  final int activeCount;
  final double expectedRevenue;
  final List<dynamic> contracts;

  ContractSummaryResponse({
    required this.activeCount,
    required this.expectedRevenue,
    required this.contracts,
  });

  factory ContractSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ContractSummaryResponse(
      activeCount: json['activeCount'] ?? 0,
      expectedRevenue: (json['expectedRevenue'] as num?)?.toDouble() ?? 0.0,
      contracts: json['contracts'] as List<dynamic>? ?? [],
    );
  }
}

class ContractService {
  static const String baseUrl = 'http://10.0.2.2:5093/api/OwnerContracts';

  // 1. Lấy danh sách hợp đồng
  static Future<ContractSummaryResponse> getContracts({
    String? status,
    String? search,
  }) async {
    List<String> params = [];
    if (status != null && status.isNotEmpty && status != 'Tất cả') {
      params.add('status=${Uri.encodeComponent(status)}');
    }
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }

    String url = baseUrl;
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ContractSummaryResponse.fromJson(data);
    }
    throw Exception('Lỗi nạp danh sách hợp đồng: ${response.statusCode}');
  }

  // 2. Tạo hợp đồng mới hoặc lưu bản nháp
  static Future<bool> createContract(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 3. Ký hợp đồng điện tử
  static Future<bool> signContract({
    required String contractId,
    required String ownerSignatureBase64,
    required String tenantSignatureBase64,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$contractId/sign'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ownerSignature': ownerSignatureBase64,
          'tenantSignature': tenantSignatureBase64,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


  // Lấy danh sách phòng trống từ database
  static Future<List<dynamic>> getAvailableRooms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/available-rooms'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Lấy danh sách lịch hẹn để liên kết
  static Future<List<dynamic>> getAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/appointments'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Xóa hợp đồng bản nháp
  static Future<bool> deleteDraftContract(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Lấy dịch vụ mặc định của phòng và các dịch vụ khác trong CSDL
  static Future<dynamic> getRoomServices(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/room-services/$roomId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }


  // 1. Lấy danh sách người ở cùng
  static Future<List<dynamic>> getContractMembers(String contractId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$contractId/members'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Thêm người ở cùng mới
  static Future<bool> addContractMember(String contractId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$contractId/members'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 3. Xóa người ở cùng
  static Future<bool> deleteContractMember(String memberId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/members/$memberId'),
        headers: {'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}