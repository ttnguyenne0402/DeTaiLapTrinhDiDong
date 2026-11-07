import 'dart:convert';
import 'package:http/http.dart' as http;

class OwnerInvoiceService {
  static const String baseUrl = 'http://10.0.2.2:5093/api/OwnerInvoices';

  // 1. Lấy danh sách hóa đơn theo tháng
  static Future<dynamic> getMonthlyInvoices({
    required int month,
    required int year,
    String? search,
  }) async {
    try {
      var url = '$baseUrl?month=$month&year=$year';
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
      return null;
    } catch (e) {
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
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
  static Future<List<dynamic>?> getActiveContracts({String? propertyId}) async {
    try {
      var urlStr = '$baseUrl/api/OwnerInvoices/active-contracts';
      if (propertyId != null && propertyId.isNotEmpty) {
        urlStr += '?propertyId=$propertyId';
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
  static Future<List<dynamic>?> getRoomsUtilitySummary({String? propertyId}) async {
    try {
      var urlStr = '$baseUrl/api/OwnerInvoices/rooms-utility-summary';
      if (propertyId != null && propertyId.isNotEmpty) {
        urlStr += '?propertyId=$propertyId';
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
      final res = await http.get(Uri.parse('$baseUrl/api/OwnerInvoices/room-utility-history/$roomId'));
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
        Uri.parse('$baseUrl/api/OwnerContracts/$contractId/liquidation-details'),
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
}