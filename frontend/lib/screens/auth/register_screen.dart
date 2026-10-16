import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter_zalo/flutter_zalo.dart';
import 'otp_screen.dart';
import 'emailjs_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  void initState() {
    super.initState();
    FlutterZalo().init();
  }

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _sendingOtp = false;
  String _selectedRole =
      'tenant'; // 'tenant' (Người thuê) hoặc 'landlord' (Chủ trọ)

  // Khai báo đối tượng GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _goToOtpScreen() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailOrPhoneController.text.trim();
    final name = _fullNameController.text.trim();

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      _showNotice('Vui lòng nhập địa chỉ email hợp lệ!');
      return;
    }

    if (_sendingOtp) return;

    setState(() => _sendingOtp = true);

    try {
      final otp = EmailJsService.generateOtp();
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      await EmailJsService.sendOtp(
        email: email,
        name: name,
        otp: otp,
        expiresAt: expiresAt,
      );

      if (!mounted) return;

      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: email,
            fullName: name,
            initialOtp: otp,
            initialExpiry: expiresAt,
          ),
        ),
      );

      if (!mounted) return;

      if (verified == true) {
        _showNotice('Xác thực email thành công!');
      }
    } catch (e, stackTrace) {
      debugPrint('Send OTP error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showNotice('Lỗi gửi OTP: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _sendingOtp = false);
      }
    }
  }

  void _showNotice(String title) {
    debugPrint('REGISTER BUTTON: $title');

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    debugPrint('Bat dau dang nhap Google');

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (!mounted) return;

      if (googleUser == null) {
        debugPrint('Nguoi dung huy dang nhap Google');
        _showNotice('Bạn đã hủy đăng nhập Google.');
        return;
      }

      debugPrint('Google email: ${googleUser.email}');
      debugPrint('Google name: ${googleUser.displayName}');

      _showNotice('Chọn tài khoản thành công: ${googleUser.email}');
    } catch (error, stackTrace) {
      debugPrint('Google Sign-In error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showNotice('Đăng nhập Google thất bại: $error');
      }
    }
  }

  Future<void> _handleZaloSignIn() async {
    try {
      final zalo = FlutterZalo();

      final bool? result = await zalo.logIn();

      if (!mounted) return;

      if (result != true) {
        _showNotice('Đăng nhập Zalo thất bại hoặc đã bị hủy.');
        return;
      }

      final profile = await zalo.getProfile();

      if (!mounted) return;

      if (profile == null) {
        _showNotice('Đăng nhập thành công nhưng chưa lấy được hồ sơ.');
        return;
      }

      final name = profile['name']?.toString() ?? 'người dùng Zalo';

      debugPrint('Zalo profile: $profile');
      _showNotice('Đăng nhập Zalo thành công: $name');
    } catch (error, stackTrace) {
      debugPrint('Zalo Sign-In error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showNotice('Đăng nhập Zalo thất bại: $error');
      }
    }
  }

  void _handleRegister() {
    _showNotice('Vui lòng xác thực email trước khi hoàn tất đăng ký.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                const Text(
                  'Tạo tài khoản mới ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cùng Trọ Ơi khám phá và kết nối không gian sống lý tưởng',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // CHỌN VAI TRÒ (Sinh viên / Chủ trọ)
                const Text(
                  'Bạn là:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        title: 'Người thuê trọ',
                        icon: Icons.person_search_rounded,
                        isSelected: _selectedRole == 'tenant',
                        onTap: () => setState(() => _selectedRole = 'tenant'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        title: 'Chủ cho thuê',
                        icon: Icons.home_work_rounded,
                        isSelected: _selectedRole == 'landlord',
                        onTap: () => setState(() => _selectedRole = 'landlord'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // INPUT HỌ VÀ TÊN
                _CustomInputField(
                  controller: _fullNameController,
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên của bạn',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // INPUT EMAIL / SỐ ĐIỆN THOẠI
                _CustomInputField(
                  controller: _emailOrPhoneController,
                  label: 'Email hoặc Số điện thoại',
                  hint: 'nhanvien@gmail.com hoặc 0901234567',
                  icon: Icons.alternate_email_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập Email hoặc SĐT';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // INPUT MẬT KHẨU
                _CustomInputField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải từ 6 ký tự trở lên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // INPUT XÁC NHẬN MẬT KHẨU
                _CustomInputField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  hint: 'Nhập lại mật khẩu vừa đặt',
                  icon: Icons.lock_reset_rounded,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Mật khẩu xác nhận không trùng khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // NÚT ĐĂNG KÝ CHÍNH
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _sendingOtp ? null : _goToOtpScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Đăng ký tài khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // HOẶC ĐĂNG KÝ BẰNG
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Hoặc đăng ký nhanh bằng',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  ],
                ),
                const SizedBox(height: 20),

                // NÚT MẠNG XÃ HỘI (Google, Zalo, SĐT OTP)
                Row(
                  children: [
                    // NÚT GOOGLE (Đã gắn hàm nảy tài khoản Google)
                    Expanded(
                      child: _SocialAuthButton(
                        label: 'Google',
                        iconWidget: const Icon(
                          Icons.g_mobiledata_rounded,
                          color: Colors.redAccent,
                          size: 30,
                        ),
                        onTap:
                            _handleGoogleSignIn, // <-- Gọi hàm Google Sign-In ở đây
                      ),
                    ),
                    const SizedBox(width: 10),

                    // NÚT ZALO
                    Expanded(
                      child: _SocialAuthButton(
                        label: 'Zalo',
                        iconWidget: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0068FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            'Z',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        onTap: _handleZaloSignIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 32),

                // FOOTER: CHUYỂN SANG ĐĂNG NHẬP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Đăng nhập ngay',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// WIDGET CHỌN VAI TRÒ
class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.primaryGreen
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGET Ô NHẬP LIỆU CHUẨN
class _CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;

  const _CustomInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            prefixIcon: Icon(icon, size: 20, color: AppColors.primaryGreen),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryGreen,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _SocialAuthButton({
    required this.label,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          debugPrint('Da bam nut: $label');
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
