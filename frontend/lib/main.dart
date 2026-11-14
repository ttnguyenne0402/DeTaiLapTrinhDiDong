
import 'dart:io' ; // 1. Thư viện xử lý HTTP Overrides để bypass SSL trên máy ảo
import 'package:flutter/material.dart';
import 'route/app_router.dart';
import 'screens/auth/login_screen.dart';

// 2. Class cấu hình bỏ qua lỗi chứng chỉ SSL tự ký của .NET trên máy ảo Android
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}


void main() {

  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // initialRoute: AppRoutes.invoicesManage,
      onGenerateRoute: AppRouter.generateRoute,
      title: 'Trọ Ơi',
      theme: ThemeData(
        // Đã sửa lỗi cú pháp dấu chấm thừa trước fromSeed
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginScreen(),
    );
  }
}

