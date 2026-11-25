import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_phone_auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialAccount = ''});

  final String initialAccount;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // true: Quên mật khẩu qua Email (Gmail SMTP)
  // false: Quên mật khẩu qua Số điện thoại (Firebase SMS / OTP Test)
  bool _isEmailMode = true;

  bool _codeSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Lưu mã xác thực từ Firebase Phone Auth
  String _firebaseVerificationId = '';

  @override
  void initState() {
    super.initState();
    _accountController = TextEditingController(text: widget.initialAccount);
    // Tự động nhận diện nếu người dùng truyền vào là số điện thoại
    if (widget.initialAccount.isNotEmpty &&
        !widget.initialAccount.contains('@') &&
        RegExp(r'^[0-9+]+$').hasMatch(widget.initialAccount)) {
      _isEmailMode = false;
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // GỬI MÃ XÁC NHẬN (EMAIL HOẶC SĐT FIREBASE)
  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final account = _accountController.text.trim();

    if (_isEmailMode) {
      // 1. GỬI MÃ QUA EMAIL (GMAIL SMTP BACKEND)
      try {
        await AuthService.requestPasswordReset(email: account);
        if (!mounted) return;
        setState(() => _codeSent = true);
        _showMessage('Nếu email thuộc tài khoản hợp lệ, mã xác nhận sẽ được gửi tới hộp thư.');
      } catch (error) {
        _showMessage(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // 2. GỬI MÃ QUA SỐ ĐIỆN THOẠI (FIREBASE PHONE AUTH)
      await FirebasePhoneAuthService.sendOtp(
        phone: account,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() {
            _firebaseVerificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
          _showMessage('Mã OTP xác nhận đã được gửi về số điện thoại của bạn.');
        },
        onError: (errorMessage) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showMessage(errorMessage, isError: true);
        },
      );
    }
  }

  // ĐẶT LẠI MẬT KHẨU
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final account = _accountController.text.trim();
    final newPassword = _passwordController.text;

    try {
      if (_isEmailMode) {
        // 1. ĐẶT LẠI MẬT KHẨU QUA EMAIL
        await AuthService.resetPassword(
          email: account,
          code: _codeController.text.trim(),
          newPassword: newPassword,
        );
      } else {
        // 2. ĐẶT LẠI MẬT KHẨU QUA SỐ ĐIỆN THOẠI
        // Bước 2.1: Xác thực OTP với Firebase
        await FirebasePhoneAuthService.verifyOtp(
          verificationId: _firebaseVerificationId,
          smsCode: _codeController.text.trim(),
        );

        // Bước 2.2: Gọi Backend cập nhật mật khẩu mới cho số điện thoại này
        await AuthService.resetPasswordByPhone(
          phone: account,
          newPassword: newPassword,
        );
      }

      if (!mounted) return;
      _showMessage('Đặt lại mật khẩu thành công! Hãy đăng nhập bằng mật khẩu mới.');
      Navigator.pop(context, true);
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Khôi phục mật khẩu'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.lock_reset_rounded,
                size: 62,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 18),
              Text(
                _codeSent ? 'Nhập mã xác nhận OTP' : 'Bạn quên mật khẩu?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                _codeSent
                    ? (_isEmailMode
                        ? 'Mã có hiệu lực trong 10 phút. Kiểm tra hộp thư Gmail hoặc thư mục spam.'
                        : 'Vui lòng nhập mã OTP 6 số đã gửi về số điện thoại.')
                    : 'Chọn phương thức khôi phục bằng Email hoặc Số điện thoại (Zalo) để đặt mật khẩu mới.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // CHỌN PHƯƠNG THỨC EMAIL HOẶC SỐ ĐIỆN THOẠI (CHỈ HIỆN KHI CHƯA GỬI MÃ)
              if (!_codeSent)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isLoading) return;
                            setState(() {
                              _isEmailMode = true;
                              _accountController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isEmailMode ? AppColors.primaryGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Khôi phục qua Email',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isEmailMode ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isLoading) return;
                            setState(() {
                              _isEmailMode = false;
                              _accountController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isEmailMode ? AppColors.primaryGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Số điện thoại (OTP)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isEmailMode ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Ô NHẬP EMAIL HOẶC SỐ ĐIỆN THOẠI
              TextFormField(
                controller: _accountController,
                enabled: !_codeSent && !_isLoading,
                keyboardType: _isEmailMode ? TextInputType.emailAddress : TextInputType.phone,
                autocorrect: false,
                decoration: _decoration(
                  _isEmailMode ? 'Email đăng ký' : 'Số điện thoại đăng ký (Zalo)',
                  _isEmailMode ? Icons.email_outlined : Icons.phone_android_outlined,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (_isEmailMode) {
                    if (text.isEmpty || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
                      return 'Nhập địa chỉ email hợp lệ.';
                    }
                  } else {
                    if (text.length < 9 || text.length > 12) {
                      return 'Nhập số điện thoại hợp lệ (9-12 chữ số).';
                    }
                  }
                  return null;
                },
              ),

              if (_codeSent) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: _decoration('Mã OTP 6 chữ số', Icons.pin_outlined),
                  validator: (value) => value == null || value.trim().length != 6
                      ? 'Nhập mã gồm 6 chữ số.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  decoration: _decoration(
                    'Mật khẩu mới',
                    Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.length < 8
                      ? 'Mật khẩu cần ít nhất 8 ký tự.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  obscureText: true,
                  decoration: _decoration(
                    'Nhập lại mật khẩu mới',
                    Icons.lock_outline_rounded,
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'Mật khẩu nhập lại không khớp.'
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_codeSent ? _resetPassword : _sendCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_codeSent ? 'Đặt lại mật khẩu' : 'Gửi mã xác nhận'),
                ),
              ),
              if (_codeSent)
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _codeSent = false;
                            _codeController.clear();
                          }),
                  child: Text(_isEmailMode ? 'Đổi email khác' : 'Đổi số điện thoại khác'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
