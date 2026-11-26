import 'dart:convert';

import 'package:http/http.dart' as http;

class AdminDashboardData {
  const AdminDashboardData({
    required this.totalUsers,
    required this.totalRooms,
    required this.pendingPosts,
    required this.approvedPosts,
    required this.rejectedPosts,
  });

  final int totalUsers;
  final int totalRooms;
  final int pendingPosts;
  final int approvedPosts;
  final int rejectedPosts;

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      totalUsers: json['totalUsers'] as int,
      totalRooms: json['totalRooms'] as int,
      pendingPosts: json['pendingPosts'] as int,
      approvedPosts: json['approvedPosts'] as int,
      rejectedPosts: json['rejectedPosts'] as int,
    );
  }
}

class AdminDashboardService {
  static const String baseUrl = 'http://10.0.2.2:5093';

  static Future<AdminDashboardData> fetchStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final url = Uri.parse('$baseUrl/stats').replace(
      queryParameters: {
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
      },
    );
    final response = await http
        .get(url, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception(
        'Không tải được tổng quan (HTTP ${response.statusCode}).',
      );
    }
    return AdminDashboardData.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
