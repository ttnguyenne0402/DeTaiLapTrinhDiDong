import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../route/app_routes.dart';
import 'auth_service.dart';

class LocalNotificationService with WidgetsBindingObserver {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  String? _deviceToken;
  String? _registeredToken;
  String? _pushSession;
  String? _pushUserId;
  String? _pushRole;
  String? _pendingPushUserId;
  Future<void> _deviceUpdate = Future.value();
  static const _channelId = 'tro_oi_notifications';
  static final _devicesUrl = Uri.parse(
    '${AuthService.baseUrl.substring(0, AuthService.baseUrl.lastIndexOf('/'))}/notifications/devices',
  );

  final Set<String> _displayedIds = {};
  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    if (!Platform.isAndroid) return;
    _navigatorKey = navigatorKey;
    WidgetsBinding.instance.addObserver(this);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Thông báo Trọ Ơi',
        importance: Importance.high,
      ),
    );
    await android?.requestNotificationsPermission();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      final session = _pushSession;
      if (session != null) unawaited(_registerDevice(session, token));
    }, onError: (Object error) => debugPrint('FCM token refresh failed'));
    FirebaseMessaging.onMessage.listen(_handlePushMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data['userId']);
    });
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _handleNotificationTap(launch?.notificationResponse?.payload);
      }
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data['userId']);
      }
    } catch (_) {
      debugPrint('Unable to read the notification that opened the app');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = _pushSession;
    if (state == AppLifecycleState.resumed && session != null) {
      unawaited(_registerDevice(session));
    }
  }

  void startPushSession({
    required String userId,
    required String role,
    required String accessToken,
  }) {
    if (!Platform.isAndroid) return;
    _pushSession = accessToken;
    _pushUserId = userId;
    _pushRole = role.toLowerCase();
    _displayedIds.clear();
    unawaited(_registerDevice(accessToken));

    if (_pendingPushUserId == userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pushUserId == userId) _handleNotificationTap(userId);
      });
    }
    _pendingPushUserId = null;
  }

  Future<void> endPushSession() async {
    if (!Platform.isAndroid) return;
    final session = _pushSession;
    _pushSession = null;
    _pushUserId = null;
    _pushRole = null;
    _pendingPushUserId = null;
    _displayedIds.clear();
    try {
      await _plugin.cancelAll();
    } catch (_) {
      debugPrint('Could not clear displayed notifications');
    }
    await _deviceUpdate;
    final tokens = {_deviceToken, _registeredToken}.whereType<String>();
    _deviceToken = null;
    _registeredToken = null;
    if (session == null || tokens.isEmpty) return;
    try {
      final responses = await Future.wait(
        tokens.map((token) => _updateDevice('DELETE', session, token)),
      );
      if (responses.every((response) => response.statusCode == 204)) return;
    } catch (_) {
      debugPrint('Could not unregister FCM token from backend');
    }
    try {
      await FirebaseMessaging.instance.deleteToken().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      debugPrint('Could not delete FCM token');
    }
  }

  Future<void> _registerDevice(String session, [String? refreshedToken]) {
    _deviceUpdate = _deviceUpdate.then((_) async {
      if (_pushSession != session) return;
      try {
        final token =
            refreshedToken ??
            await FirebaseMessaging.instance.getToken().timeout(
              const Duration(seconds: 5),
            );
        if (token == null || _pushSession != session) return;
        if (_registeredToken == token) return;
        final previousToken = _registeredToken;
        _deviceToken = token;
        final response = await _updateDevice('PUT', session, token);
        if (response.statusCode != 204) {
          debugPrint('FCM registration returned HTTP ${response.statusCode}');
          return;
        }
        _registeredToken = token;
        if (previousToken != null && previousToken != token) {
          await _updateDevice('DELETE', session, previousToken);
        }
      } catch (_) {
        debugPrint('Could not register FCM token');
      }
    });
    return _deviceUpdate;
  }

  Future<http.Response> _updateDevice(
    String method,
    String session,
    String token,
  ) async {
    final request = http.Request(method, _devicesUrl)
      ..headers.addAll({
        'Authorization': 'Bearer $session',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({'token': token});
    final client = http.Client();
    try {
      return await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 3));
    } finally {
      client.close();
    }
  }

  Future<void> _handlePushMessage(RemoteMessage message) async {
    final id = message.data['notificationId'];
    final notification = message.notification;
    final userId = _pushUserId;
    if (id is! String ||
        userId == null ||
        message.data['userId'] != userId ||
        notification == null ||
        !_displayedIds.add(id)) {
      return;
    }
    if (_displayedIds.length > 100) _displayedIds.remove(_displayedIds.first);
    await _showBanner(
      id: id.hashCode,
      title: notification.title ?? 'Thông báo mới',
      body: notification.body ?? '',
      userId: userId,
    );
  }

  void _handleNotificationTap(Object? userId) {
    if (userId is! String) return;
    if (_pushUserId == null) {
      _pendingPushUserId = userId;
    }
    if (userId != _pushUserId) return;
    final route = switch (_pushRole) {
      'owner' || 'landlord' => AppRoutes.ownerNotifications,
      'admin' => AppRoutes.adminDashboard,
      _ => AppRoutes.tenantNotifications,
    };
    _navigatorKey?.currentState?.pushNamed(route);
  }

  Future<void> _showBanner({
    required int id,
    required String title,
    required String body,
    required String userId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Thông báo Trọ Ơi',
      channelDescription: 'Thông báo hóa đơn, lịch hẹn và sửa chữa',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details, payload: userId);
  }
}
