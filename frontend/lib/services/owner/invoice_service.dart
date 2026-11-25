import 'dart:convert';
import 'package:http/http.dart' as http;

class OwnerInvoiceService {
  static const String baseUrl = 'http://10.0.2.2:5093/api/OwnerInvoices';

  // 1. Lấy danh sách hóa đơn theo tháng
  static Future<dynamic> getMonthlyInvoices({
    String? ownerId,
    required int month,
    required int year,
    String? search,
  }) async {
    try {
      var url = '$baseUrl?month=$month&year=$year';
      if (ownerId != null && ownerId.isNotEmpty) {
        url += '&ownerId=${Uri.encodeComponent(ownerId)}';
      }
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print('Lỗi getMonthlyInvoices: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Lỗi gọi getMonthlyInvoices: $e');
      return null;
    }
  }

  // 2. Lấy chỉ số điện nước kỳ trước
  static Future<dynamic> getPreviousReading(String contractId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/previous-reading/$contractId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 3. Tạo hóa đơn mới
  static Future<dynamic> createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body;
      }
      return {
        'error': true,
        'message': body['message'] ?? 'Không thể lập hóa đơn.'
      };
    } catch (e) {
      return {'error': true, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  // 4. Cập nhật trạng thái hóa đơn
  static Future<bool> updateStatus(String invoiceId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$invoiceId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


  // 5. Lấy chi tiết đầy đủ của một hóa đơn
  static Future<dynamic> getInvoiceDetail(String invoiceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$invoiceId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  // Lấy danh sách hợp đồng/phòng đang thuê để chọn khi lập hóa đơn
  static Future<List<dynamic>?> getActiveContracts({String? propertyId, String? ownerId}) async {
    try {
      var urlStr = '$baseUrl/active-contracts';
      List<String> params = [];
      if (ownerId != null && ownerId.isNotEmpty) {
        params.add('ownerId=$ownerId');
      }
      if (propertyId != null && propertyId.isNotEmpty) {
        params.add('propertyId=$propertyId');
      }
      if (params.isNotEmpty) {
        urlStr += '?${params.join('&')}';
      }

      final res = await http.get(Uri.parse(urlStr), headers: {
        'Content-Type': 'application/json',
      });

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('Lỗi getActiveContracts: $e');
    }
    return null;
  }


  // Lấy danh sách các phòng ghi điện nước đồng loạt
  static Future<List<dynamic>?> getRoomsUtilitySummary({String? ownerId, String? propertyId}) async {
    try {
      List<String> params = [];
      if (ownerId != null && ownerId.isNotEmpty) {
        params.add('ownerId=${Uri.encodeComponent(ownerId)}');
      }
      if (propertyId != null && propertyId.isNotEmpty) {
        params.add('propertyId=${Uri.encodeComponent(propertyId)}');
      }

      var urlStr = '$baseUrl/rooms-utility-summary';
      if (params.isNotEmpty) {
        urlStr += '?${params.join('&')}';
      }

      final res = await http.get(Uri.parse(urlStr), headers: {
        'Content-Type': 'application/json',
      });

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('Lỗi gọi getRoomsUtilitySummary: $e');
    }
    return null;
  }

  // 2. Lấy lịch sử 12 tháng chốt số của 1 phòng
  static Future<List<dynamic>?> getRoomUtilityHistory(String roomId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/room-utility-history/$roomId'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('Lỗi getRoomUtilityHistory: $e');
    }
    return null;
  }

  // Lấy chi tiết quyết toán thanh lý hợp đồng từ Backend C#
  static Future<dynamic> getLiquidationDetails(String contractId) async {
    try {
      final res = await http.get(
        Uri.parse('http://10.0.2.2:5093/api/OwnerContracts/$contractId/liquidation-details'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      print('Lỗi API: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Lỗi gọi getLiquidationDetails: $e');
    }

    return null;
  }

  static Future<List<dynamic>?> getBankAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bank-accounts'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error loading bank accounts: $e');
    }
    return null;
  }

  // Cập nhật và phát hành lại hóa đơn
  static Future<dynamic> updateInvoice(String invoiceId, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/$invoiceId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final resBody = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return resBody;
      }
      return {
        'error': true,
        'message': resBody['message'] ?? 'Không thể cập nhật hóa đơn.'
      };
    } catch (e) {
      return {'error': true, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  // 3. Lưu vĩnh viễn chỉ số điện nước vào CSDL SQL Server ngay khi bấm nút "Lưu chỉ số"
  static Future<bool> saveUtilityReading({
    required String contractId,
    required double newElectric,
    required double newWater,
  }) async {
    try {
      final now = DateTime.now();
      final response = await http.post(
        Uri.parse('$baseUrl/save-utility-reading'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contractId': contractId,
          'newElectric': newElectric,
          'newWater': newWater,
          'month': now.month,
          'year': now.year,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi saveUtilityReading: $e');
      return false;
    }
  }
}