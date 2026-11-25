import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebasePhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Chuẩn hóa số điện thoại Việt Nam sang định dạng quốc tế E.164 (+84...)
  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    if (cleaned.startsWith('0')) {
      return '+84${cleaned.substring(1)}';
    }
    if (!cleaned.startsWith('+')) {
      return '+84$cleaned';
    }
    return cleaned;
  }

  // Gửi mã OTP SMS qua Firebase
  static Future<void> sendOtp({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
    Function(PhoneAuthCredential credential)? onAutoVerified,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final String formattedPhone = formatPhoneNumber(phone);
    debugPrint('[FIREBASE AUTH] Đang gửi OTP tới số: $formattedPhone');

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: timeout,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('[FIREBASE AUTH] Tự động xác thực thành công!');
          if (onAutoVerified != null) {
            onAutoVerified(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('[FIREBASE AUTH] Lỗi gửi OTP: ${e.code} - ${e.message}');
          String message = 'Không thể gửi mã xác nhận.';
          if (e.code == 'invalid-phone-number') {
            message = 'Số điện thoại không hợp lệ.';
          } else if (e.code == 'too-many-requests') {
            message = 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
          } else if (e.message != null) {
            message = e.message!;
          }
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('[FIREBASE AUTH] Mã OTP đã được gửi. Verification ID: $verificationId');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('[FIREBASE AUTH] Hết thời gian tự động lấy OTP: $verificationId');
        },
      );
    } catch (e) {
      debugPrint('[FIREBASE AUTH] Ngoại lệ khi gửi OTP: $e');
      onError(e.toString());
    }
  }

  // Xác minh mã OTP do người dùng nhập
  static Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('[FIREBASE AUTH] Lỗi xác minh OTP: ${e.code}');
      if (e.code == 'invalid-verification-code') {
        throw Exception('Mã xác nhận OTP không chính xác.');
      } else if (e.code == 'session-expired') {
        throw Exception('Mã xác nhận OTP đã hết hạn. Vui lòng gửi lại mã.');
      }
      throw Exception(e.message ?? 'Xác minh OTP thất bại.');
    } catch (e) {
      throw Exception('Lỗi xác thực: $e');
    }
  }
}
