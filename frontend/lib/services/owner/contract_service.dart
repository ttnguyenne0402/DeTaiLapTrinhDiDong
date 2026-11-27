import 'dart:convert';
import 'dart:math' as logger;
import 'package:http/http.dart' as http;
import '../auth_storage.dart';

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
    String? ownerId,
    String? status,
    String? search,
  }) async {
    List<String> params = [];
    if (ownerId != null && ownerId.isNotEmpty) {
      params.add('ownerId=${Uri.encodeComponent(ownerId)}');
    }

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

    final token = await AuthStorage.getAccessToken();
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ContractSummaryResponse.fromJson(data);
    }

    throw Exception('Lỗi nạp danh sách hợp đồng: ${response.statusCode}');
  }

  // 2. Tạo hợp đồng mới hoặc lưu bản nháp
  static Future<dynamic> createContract(Map<String, dynamic> data) async {
    try {
      final token = await AuthStorage.getAccessToken();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'error': true,
        'message': _errorMessage(response, 'Không thể tạo hợp đồng.'),
      };
    } catch (e) {
      return {'error': true, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  // 3. Ký hợp đồng điện tử
  static Future<bool> signContract({
    required String contractId,
    required String ownerSignatureBase64,
    required String tenantSignatureBase64,
  }) async {
    try {
      final token = await AuthStorage.getAccessToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$contractId/sign'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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

  static Future<String?> closeSigning({
    required String contractId,
    required bool reject,
    required String reason,
  }) async {
    try {
      final token = await AuthStorage.getAccessToken();
      if (token == null || token.isEmpty) return 'Vui lòng đăng nhập lại.';

      final action = reject ? 'reject-signing' : 'withdraw-signing';
      final id = Uri.encodeComponent(contractId);
      final response = await http.put(
        Uri.parse('$baseUrl/$id/$action'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'reason': reason}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return null;
      return _errorMessage(response, 'Không thể cập nhật yêu cầu ký.');
    } catch (_) {
      return 'Không thể kết nối máy chủ. Vui lòng thử lại.';
    }
  }

  static String _errorMessage(http.Response response, String fallback) {
    if (response.statusCode == 401) return 'Vui lòng đăng nhập lại.';
    if (response.statusCode == 403) return 'Bạn không có quyền thực hiện thao tác này.';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['message'] is String) return body['message'] as String;
    } on FormatException {
      return fallback;
    }
    return fallback;
  }

  // Lấy danh sách phòng trống theo mã Chủ trọ
  static Future<List<dynamic>> getAvailableRooms({
    String? ownerId,
    String? selectedRoomId,
    String? includeRoomId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/available-rooms').replace(queryParameters: {
        if (ownerId != null && ownerId.isNotEmpty) 'ownerId': ownerId,
        if (selectedRoomId != null && selectedRoomId.isNotEmpty) 'selectedRoomId': selectedRoomId,
        if (includeRoomId != null && includeRoomId.isNotEmpty) 'includeRoomId': includeRoomId,
      });

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Lỗi nạp phòng trống: $e');
    }

    return [];
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
  static Future<dynamic> addContractMember(String contractId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$contractId/members'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body;
      }
      return {
        'error': true,
        'message': body['message'] ?? 'Không thể thêm người ở ghép.'
      };
    } catch (e) {
      return {'error': true, 'message': 'Lỗi kết nối máy chủ.'};
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
