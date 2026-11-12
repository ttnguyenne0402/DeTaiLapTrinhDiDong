import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialAccount = ''});

  final String initialAccount;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialAccount);
  }

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await AuthService.requestPasswordReset(
        email: _emailController.text.trim(),
      );
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
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await AuthService.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (mounted) Navigator.pop(context, true);
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
                _codeSent ? 'Nhập mã xác nhận' : 'Bạn quên mật khẩu?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                _codeSent
                    ? 'Mã có hiệu lực trong 10 phút. Kiểm tra hộp thư và thư mục spam.'
                    : 'Nhập email thật đã đăng ký. Trọ Ơi sẽ gửi mã đặt lại mật khẩu tới email đó.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailController,
                enabled: !_codeSent && !_isLoading,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: _decoration('Email đăng ký', Icons.email_outlined),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty ||
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                    return 'Nhập địa chỉ email hợp lệ.';
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
                  decoration: _decoration('Mã 6 chữ số', Icons.pin_outlined),
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
                  child: const Text('Đổi email'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
