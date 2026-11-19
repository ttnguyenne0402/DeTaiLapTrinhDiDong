import 'dart:io'; // 1. Thư viện xử lý HTTP Overrides để bypass SSL trên máy ảo
import 'package:flutter/material.dart';
import 'route/app_router.dart';
import 'screens/auth/login_screen.dart';
import 'services/local_notification_service.dart'; // <--- THÊM DÒNG NÀY

// 2. Class cấu hình bỏ qua lỗi chứng chỉ SSL tự ký của .NET trên máy ảo Android
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// <--- THÊM KEY ĐIỀU HƯỚNG TOÀN CỤC
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
//KHỞI TẠO THÔNG BÁO
  await LocalNotificationService.instance.init(navigatorKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.generateRoute,
      title: 'Trọ Ơi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginScreen(),
    );
  }
}