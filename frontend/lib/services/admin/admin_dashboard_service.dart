import 'dart:convert';
import 'package:http/http.dart' as http;

// 1. Model hứng dữ liệu từ API Backend trả về
class AdminDashboardData {
  final int totalUsers;
  final int totalRooms;
  final int approvedPosts;
  final int reports;
  final List<DashboardChartPoint> chartData;

  AdminDashboardData({
    required this.totalUsers,
    required this.totalRooms,
    required this.approvedPosts,
    required this.reports,
    required this.chartData,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    var rawList = json['chartData'] as List? ?? [];
    List<DashboardChartPoint> points = rawList.map((item) {
      return DashboardChartPoint(
        item['label'] ?? '',
        (item['views'] as num?)?.toDouble() ?? 0.0,
        (item['searches'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return AdminDashboardData(
      totalUsers: json['totalUsers'] ?? 0,
      totalRooms: json['totalRooms'] ?? 0,
      approvedPosts: json['approvedPosts'] ?? 0,
      reports: json['pendingOrReportedPosts'] ?? 0,
      chartData: points,
    );
  }
}

// 2. Model điểm dữ liệu vẽ lên biểu đồ Syncfusion
class DashboardChartPoint {
  final String day;
  final double views;
  final double searches;

  DashboardChartPoint(this.day, this.views, this.searches);
}

// 3. Service gọi HTTP request sang ASP.NET Core Web API
class AdminDashboardService {
  // LƯU Ý CẤU HÌNH ĐỊA CHỈ IP:
  // - Máy ảo Android Emulator: dùng 'http://10.0.2.2:5xxx' hoặc 'https://10.0.2.2:7203'
  // - Máy thật cắm dây (cùng Wi-Fi): dùng 'http://<IP_MÁY_TÍNH>:PORT' (VD: http://192.168.1.5:5000)
  // - Trình duyệt Chrome Web: dùng 'https://localhost:7203/api/AdminDashboard'
  static const String baseUrl = 'http://10.0.2.2:5093';

  static Future<AdminDashboardData> fetchStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Gọi thẳng vào /stats giống y hệt Swagger:
    String url = '$baseUrl/stats';
    if (startDate != null && endDate != null) {
      url += '?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AdminDashboardData.fromJson(data);
      } else {
        throw Exception('Server trả về mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối tới Server: $e');
    }
  }
}