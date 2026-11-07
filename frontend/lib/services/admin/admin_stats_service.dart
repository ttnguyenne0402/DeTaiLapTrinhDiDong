import 'dart:convert';
import 'package:http/http.dart' as http;

class RevenueChartItem {
  final String label;
  final double value;

  RevenueChartItem(this.label, this.value);
}

class UserShareItem {
  final String roleName;
  final double percentage;
  final int count;

  UserShareItem(this.roleName, this.percentage, this.count);
}

class TopPropertyItem {
  final String name;
  final String owner;
  final int rooms;
  final double commission;
  final String occupancyRate;

  TopPropertyItem({
    required this.name,
    required this.owner,
    required this.rooms,
    required this.commission,
    required this.occupancyRate,
  });

  factory TopPropertyItem.fromJson(Map<String, dynamic> json) {
    return TopPropertyItem(
      name: json['name'] ?? '',
      owner: json['owner'] ?? 'Ẩn danh',
      rooms: json['rooms'] ?? 0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
      occupancyRate: json['occupancyRate'] ?? '0%',
    );
  }
}

class AdminStatsData {
  final double totalCommission;
  final int totalProperties;
  final int totalUsers;
  final int pendingRequests;
  final List<RevenueChartItem> revenueChart;
  final List<UserShareItem> userShare;
  final List<TopPropertyItem> topProperties;

  AdminStatsData({
    required this.totalCommission,
    required this.totalProperties,
    required this.totalUsers,
    required this.pendingRequests,
    required this.revenueChart,
    required this.userShare,
    required this.topProperties,
  });

  factory AdminStatsData.fromJson(Map<String, dynamic> json) {
    var rawChart = json['revenueChart'] as List? ?? [];
    var rawShare = json['userShare'] as List? ?? [];
    var rawTop = json['topProperties'] as List? ?? [];

    return AdminStatsData(
      totalCommission: (json['totalCommission'] as num?)?.toDouble() ?? 0.0,
      totalProperties: json['totalProperties'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      revenueChart: rawChart.map((e) => RevenueChartItem(e['label'] ?? '', (e['value'] as num?)?.toDouble() ?? 0.0)).toList(),
      userShare: rawShare.map((e) => UserShareItem(e['roleName'] ?? '', (e['percentage'] as num?)?.toDouble() ?? 0.0, e['count'] ?? 0)).toList(),
      topProperties: rawTop.map((e) => TopPropertyItem.fromJson(e)).toList(),
    );
  }
}

class AdminStatsService {
  static const String baseUrl = 'http://10.0.2.2:5093/api/AdminStats';

  static Future<AdminStatsData> getStatistics(String period) async {
    final response = await http.get(
      Uri.parse('$baseUrl?period=$period'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AdminStatsData.fromJson(jsonDecode(response.body));
    }
    throw Exception('Lỗi khi lấy dữ liệu thống kê: ${response.statusCode}');
  }
}