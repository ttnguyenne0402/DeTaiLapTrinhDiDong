
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import 'emailjs_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String initialOtp;
  final DateTime initialExpiry;

  const OtpScreen({
    super.key,
    required this.email,
    required this.fullName,
    required this.initialOtp,
    required this.initialExpiry,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  late String _currentOtp;
  late DateTime _expiresAt;
  bool _sendingOtp = false;

  static const primaryColor = Color(0xFF005D4B);

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.initialOtp;
    _expiresAt = widget.initialExpiry;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _verifyOtp() {
    final enteredOtp = _controllers.map((e) => e.text).join();

    if (!RegExp(r'^\d{6}$').hasMatch(enteredOtp)) {
      _showNotice('Vui lòng nhập đủ 6 chữ số OTP.');
      return;
    }

    if (!DateTime.now().isBefore(_expiresAt)) {
      _showNotice('Mã OTP đã hết hạn. Vui lòng gửi lại mã.');
      return;
    }

    if (enteredOtp != _currentOtp) {
      _showNotice('Mã OTP không chính xác. Vui lòng thử lại.');
      return;
    }

    // Trả kết quả xác thực thành công về màn hình đăng ký.
    Navigator.pop(context, true);
  }

  Future<void> _resendOtp() async {
    if (_sendingOtp) return;

    setState(() => _sendingOtp = true);

    try {
      final newOtp = EmailJsService.generateOtp();
      final newExpiry = DateTime.now().add(
        const Duration(minutes: 15),
      );

      await EmailJsService.sendOtp(
        email: widget.email,
        name: widget.fullName,
        otp: newOtp,
        expiresAt: newExpiry,
      );

      if (!mounted) return;

      setState(() {
        _currentOtp = newOtp;
        _expiresAt = newExpiry;

        for (final controller in _controllers) {
          controller.clear();
        }
      });

      _focusNodes.first.requestFocus();
      _showNotice('Đã gửi mã OTP mới. Em kiểm tra email nhé.');
    } catch (e) {
      debugPrint('Resend OTP error: $e');

      if (mounted) {
        _showNotice('Gửi lại OTP thất bại. Em vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _sendingOtp = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F6),
        elevation: 0,
        foregroundColor: primaryColor,
        title: const Text('Xác thực email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 36),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0EB),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 44,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Kiểm tra email của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nhập mã OTP gồm 6 chữ số để xác thực địa chỉ email:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận mã OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa nhận được mã? ',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  TextButton(
                    onPressed: _sendingOtp ? null : _resendOtp,
                    child: _sendingOtp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Gửi lại mã',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Vui lòng kiểm tra cả thư mục Spam hoặc Quảng cáo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
