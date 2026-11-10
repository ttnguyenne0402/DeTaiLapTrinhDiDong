import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardAppointment {
  final String time;
  final String name;
  final String roomInfo;
  final String status;
  final String phone;

  DashboardAppointment({
    required this.time,
    required this.name,
    required this.roomInfo,
    required this.status,
    required this.phone,
  });

  factory DashboardAppointment.fromJson(Map<String, dynamic> json) {
    return DashboardAppointment(
      time: json['time'] ?? '',
      name: json['name'] ?? '',
      roomInfo: json['roomInfo'] ?? '',
      status: json['status'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class OwnerDashboardModel {
  final String ownerName;
  final String ownerRole;
  final int totalRentedRooms;
  final int scheduledAppointments;
  final int emptyRooms;
  final int repairRequests;
  final List<DashboardAppointment> upcomingAppointments;

  OwnerDashboardModel({
    required this.ownerName,
    required this.ownerRole,
    required this.totalRentedRooms,
    required this.scheduledAppointments,
    required this.emptyRooms,
    required this.repairRequests,
    required this.upcomingAppointments,
  });

  factory OwnerDashboardModel.fromJson(Map<String, dynamic> json) {
    var list = json['upcomingAppointments'] as List? ?? [];
    List<DashboardAppointment> appointments = list
        .map((i) => DashboardAppointment.fromJson(i))
        .toList();

    return OwnerDashboardModel(
      ownerName: json['ownerName'] ?? '',
      ownerRole: json['ownerRole'] ?? '',
      totalRentedRooms: json['totalRentedRooms'] ?? 0,
      scheduledAppointments: json['scheduledAppointments'] ?? 0,
      emptyRooms: json['emptyRooms'] ?? 0,
      repairRequests: json['repairRequests'] ?? 0,
      upcomingAppointments: appointments,
    );
  }
}

class OwnerDashboardService {
  // Đổi cổng (port) sao cho khớp với cổng chạy Backend .NET của bạn (ví dụ: 5093)
  static const String baseUrl = 'http://10.0.2.2:5093';

  static Future<OwnerDashboardModel> fetchDashboardData(String ownerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/owner/dashboard/$ownerId'),
    );

    if (response.statusCode == 200) {
      return OwnerDashboardModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không thể tải dữ liệu trang chủ chủ trọ');
    }
  }
}
