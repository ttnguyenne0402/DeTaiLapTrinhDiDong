import 'dart:convert';
import 'package:http/http.dart' as http;

class OwnerAppointmentModel {
  final String id;
  final String tenantId;
  final String name;
  final String phone;
  final String roomId;
  final String roomInfo;
  final String time;
  final String date;
  final String status;
  final String? note;
  final String avatar;

  OwnerAppointmentModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.phone,
    required this.roomId,
    required this.roomInfo,
    required this.time,
    required this.date,
    required this.status,
    this.note,
    required this.avatar,
  });

  factory OwnerAppointmentModel.fromJson(Map<String, dynamic> json) {
    return OwnerAppointmentModel(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      roomId: json['roomId'] ?? '',
      roomInfo: json['roomInfo'] ?? '',
      time: json['time'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
      note: json['note'],
      avatar: json['avatar'] ?? 'frontend/assets/images/avatarDemo.jpg',
    );
  }
}

class AppointmentService {
  static const String baseUrl = 'http://10.0.2.2:5093';

  // Lấy danh sách lịch hẹn: 'upcoming', 'completed', 'cancelled', 'all'
  static Future<List<OwnerAppointmentModel>> fetchOwnerAppointments(
    String ownerId, {
    String status = 'all',
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/owner/appointments/$ownerId?status=$status'),
    );

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((item) => OwnerAppointmentModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách lịch hẹn');
    }
  }

  // Cập nhật trạng thái lịch hẹn: 'confirmed', 'completed', 'cancelled'
  static Future<bool> updateAppointmentStatus(
    String id,
    String status, {
    String? ownerNote,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/owner/appointments/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': status,
        'ownerNote': ownerNote,
      }),
    );
    return response.statusCode == 200;
  }
}

