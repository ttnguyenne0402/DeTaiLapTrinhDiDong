
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class EmailJsService {
  static const String _serviceId = 'service_gidbn5n';
  static const String _templateId = 'template_qnq1lya';
  static const String _publicKey = 'T5fa77aeI-jtHOhFL';

  static String generateOtp() {
    return (Random.secure().nextInt(900000) + 100000).toString();
  }

  static Future<void> sendOtp({
    required String email,
    required String name,
    required String otp,
    required DateTime expiresAt,
  }) async {
    final time =
        '${expiresAt.hour.toString().padLeft(2, '0')}:'
        '${expiresAt.minute.toString().padLeft(2, '0')}';

    final response = await http
        .post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'service_id': _serviceId,
            'template_id': _templateId,
            'user_id': _publicKey,
            'template_params': {
              'to_email': email,
              'name': name,
              'passcode': otp,
              'time': time,
            },
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'EmailJS lỗi ${response.statusCode}: ${response.body}',
      );
    }
  }
}
