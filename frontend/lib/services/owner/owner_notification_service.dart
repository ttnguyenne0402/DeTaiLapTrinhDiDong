import 'dart:convert';
import 'package:http/http.dart' as http;

class OwnerNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? referenceId;
  final String? referenceType;
  bool isRead;
  final String time;
  final String createdAt;

  OwnerNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    required this.time,
    required this.createdAt,
  });

  factory OwnerNotificationModel.fromJson(Map<String, dynamic> json) {
    return OwnerNotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'appointment_new',
      referenceId: json['referenceId'],
      referenceType: json['referenceType'],
      isRead: json['isRead'] ?? false,
      time: json['time'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class OwnerNotificationService {
  static const String baseUrl = 'http://10.0.2.2:5093';

  static Future<List<OwnerNotificationModel>> fetchNotifications(String ownerId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/owner/notifications/$ownerId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((item) => OwnerNotificationModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách thông báo');
    }
  }

  static Future<bool> markAsRead(String id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/owner/notifications/$id/read'),
    );
    return response.statusCode == 200;
  }

  static Future<bool> markAllAsRead(String ownerId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/owner/notifications/read-all/$ownerId'),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteNotification(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/owner/notifications/$id'),
    );
    return response.statusCode == 200;
  }
}

