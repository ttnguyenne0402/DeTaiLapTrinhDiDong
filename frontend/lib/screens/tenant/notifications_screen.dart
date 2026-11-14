import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../utils/database_helper.dart';
import '../../widgets/tenant/notification_item.dart';
import 'dart:io';
import 'package:http/io_client.dart';
import '../../services/auth_storage.dart';
import '../../utils/database_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  List _notifications = [];
  bool _isLoading = true;


  late String _apiUrl;

  @override
  void initState() {
    super.initState();
    _initData();
  }
  Future<void> _initData() async {
    final userId = await AuthStorage.getUserId(); // Lấy ID thật
    _apiUrl = 'http://10.0.2.2:5093/api/notifications/user/${userId ?? ""}';
    await _loadData();
  }
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }




  Future<void> _loadData() async {
    // 1. Lấy dữ liệu từ SQLite (Hiển thị ngay lập tức)
    final localData = await DatabaseHelper.instance.getLocalNotifications();
    if (localData.isNotEmpty) {
      setState(() {
        _notifications = localData.map((e) =><String, dynamic> {
          ...e,
          'isRead': e['isRead'] == 1
        }).toList();
        _isLoading = false;
      });
    }

    // 2. Gọi API để lấy dữ liệu mới nhất
    final client = _getCustomClient();
    try {
      final response = await client.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> apiData = json.decode(response.body);

        // 3. Lưu đè dữ liệu mới vào SQLite
        await DatabaseHelper.instance.insertNotifications(apiData);

        // 4. Cập nhật lại UI
        if (mounted) {
          setState(() {
            _notifications = List.from(apiData);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Bắt lỗi nếu không có mạng. Lúc này UI vẫn hiển thị được dữ liệu từ localData
      print("Lỗi khi lấy thông báo từ server: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      // Luôn đóng client để giải phóng bộ nhớ
      client.close();
    }
  }


  // HÀM ĐÁNH DẤU ĐÃ ĐỌC THÔNG BÁO

  Future<void> _markAsRead(String id) async {
    // 1. URL API PATCH
    final url = 'http://10.0.2.2:5093/api/notifications/$id/read';

    // 2. Sử dụng Client tùy chỉnh
    final client = _getCustomClient();

    try {
      final response = await client.patch(Uri.parse(url));

      if (response.statusCode == 200) {
        // 3. Nếu server thành công, cập nhật UI và lưu lại vào SQLite
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'] == id);
          if (index != -1) {
            _notifications[index]['isRead'] = true;
          }
        });
        await DatabaseHelper.instance.insertNotifications(_notifications);
      }
    } catch (e) {
      print("Lỗi đánh dấu đã đọc: $e");
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'THÔNG BÁO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                    (route) => false,
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist, color: Colors.white),
            tooltip: 'Đánh dấu đã đọc tất cả',
            onPressed: () async {
              final unreadNotifs = _notifications.where((n) => n['isRead'] == false).toList();

              if (unreadNotifs.isNotEmpty) {
                setState(() => _isLoading = true);

                for (var notif in unreadNotifs) {
                  await _markAsRead(notif['id']);
                }
                setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? const Center(
            child: Text(
              'Bạn không có thông báo nào.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          )
              : ListView.separated(
            itemCount: _notifications.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: AppColors.lightGreen,
            ),
            itemBuilder: (context, index) {
              final notif = _notifications[index];
              return NotificationItem(
                notificationData: notif,
                onTap: () {
                  if (notif['isRead'] == false) {
                    _markAsRead(notif['id']);
                  }

                  switch (notif['type']) {
                    case 'invoice':
                      Navigator.pushNamed(context, '/tenant/invoices/detail');
                      break;
                    case 'viewing_appointment':
                      Navigator.pushNamed(context, '/tenant/booking-history');
                      break;
                    case 'contract':
                      Navigator.pushNamed(context, '/tenant/contracts/detail');
                      break;
                    case 'maintenance':
                      Navigator.pushNamed(context, '/tenant/maintenance/request');
                      break;
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}