import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Timer? _pollingTimer;

  // Lưu danh sách ID đã biết để không bung lặp lại thông báo cũ
  final Set<String> _knownIds = {};
  String? _lastUserId;

  // Dùng để điều hướng khi người dùng bấm vào banner thông báo
  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap();
      },
    );

    // Xin quyền hiển thị thông báo trên Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Bắt đầu quét định kỳ mỗi 5 giây
    startPolling();
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      checkNow();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Gọi hàm này bất cứ lúc nào muốn kiểm tra thông báo NGAY LẬP TỨC (0 giây)
  Future<void> checkNow() async {
    try {
      final userId = await AuthStorage.getUserId();
      final role = (await AuthStorage.getRole() ?? '').toLowerCase();

      // Chưa đăng nhập hoặc vừa đăng xuất -> reset bộ nhớ tạm
      if (userId == null || userId.isEmpty) {
        _knownIds.clear();
        _lastUserId = null;
        return;
      }

      // Kiểm tra xem có phải lần đầu lấy dữ liệu của tài khoản này không
      final bool isFirstLoadForUser = (_lastUserId != userId);
      if (isFirstLoadForUser) {
        _knownIds.clear();
        _lastUserId = userId;
      }

      // Chọn đúng API theo vai trò (Chủ trọ / Người thuê)
      final bool isOwner = role.contains('owner') || role.contains('landlord');
      final String url = isOwner
          ? 'http://10.0.2.2:5093/api/owner/notifications/$userId'
          : 'http://10.0.2.2:5093/api/notifications/user/$userId';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;

      final List<dynamic> data = json.decode(response.body);

      for (final item in data) {
        final String id = item['id']?.toString() ?? '';
        final bool isRead = item['isRead'] == true;
        if (id.isEmpty) continue;

        if (!_knownIds.contains(id)) {
          _knownIds.add(id);

          // Lần đầu mở app chỉ ghi nhận ID cũ để tránh bung hàng loạt banner cũ.
          // Từ lần quét sau trở đi, cứ có thông báo mới chưa đọc là bung ra ngoài thiết bị!
          if (!isFirstLoadForUser && !isRead) {
            await _showBanner(
              id: id.hashCode,
              title: item['title']?.toString() ?? 'Thông báo mới',
              body: item['message']?.toString() ?? '',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi kiểm tra thông báo ngầm: $e');
    }
  }

  Future<void> _showBanner({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tro_oi_notifications',
      'Thông báo Trọ Ơi',
      channelDescription: 'Thông báo hóa đơn, lịch hẹn và sửa chữa',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  Future<void> _handleNotificationTap() async {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    final role = (await AuthStorage.getRole() ?? '').toLowerCase();
    final bool isOwner = role.contains('owner') || role.contains('landlord');

    if (!isOwner) {
      // Đẩy sang màn hình thông báo của Người thuê
      nav.pushNamed('/tenant/notifications');
    }
  }
}