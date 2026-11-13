import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_zalo/flutter_zalo.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '843670435307-mngs2e74rvnfc3rb7044alb5m60fs2ea.apps.googleusercontent.com',
  );

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String _selectedRole = 'tenant';

  @override
  void initState() {
    super.initState();
    FlutterZalo().init();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showNotice(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : AppColors.primaryGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ĐĂNG KÝ BẰNG EMAIL HOẶC SỐ ĐIỆN THOẠI
  Future<void> _handleRegister() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (!mounted) return;

      _showNotice('??ng k? th?nh c?ng. Em c? th? ??ng nh?p.');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      _showNotice(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ĐĂNG KÝ BẰNG GOOGLE
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Đăng xuất phiên Google đang lưu để yêu cầu chọn tài khoản lại.
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (!mounted) return;

      if (googleUser == null) {
        _showNotice('Bạn đã hủy đăng ký Google.');
        return;
      }

      final GoogleSignInAuthentication authentication =
          await googleUser.authentication;

      final String? idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        _showNotice(
          'Không lấy được Google ID token. '
          'Vui lòng kiểm tra cấu hình OAuth.',
          isError: true,
        );
        return;
      }

      // Gọi API ĐĂNG KÝ riêng, không gọi API đăng nhập.
      final result = await AuthService.googleRegister(
        idToken: idToken,
        role: _selectedRole,
      );

      if (!mounted) return;

      final String message = result['message']?.toString() ?? '';

      // Chỉ báo thành công khi backend xác nhận tạo tài khoản mới.
      final bool isNewUser = result['isNewUser'] == true;

      if (isNewUser) {
        _showNotice(
          message.isNotEmpty
              ? message
              : 'Đăng ký Google thành công! Vui lòng đăng nhập.',
        );

        await Future.delayed(const Duration(milliseconds: 900));

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showNotice(
          message.isNotEmpty
              ? message
              : 'Tài khoản Google đã tồn tại hoặc chưa được tạo mới. '
                    'Vui lòng thử đăng nhập.',
          isError: true,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Google register error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showNotice(
        'Đăng ký Google thất bại: '
        '${error.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ĐĂNG KÝ BẰNG ZALO
  Future<void> _handleZaloSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    debugPrint('[ZALO] 1. Bắt đầu đăng nhập');

    try {
      final zalo = FlutterZalo();

      debugPrint('[ZALO] 2. Đang chờ kết quả từ Zalo');

      final bool? result = await zalo.logIn().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Quá thời gian chờ phản hồi từ Zalo');
        },
      );

      debugPrint('[ZALO] 3. Kết quả đăng nhập: $result');

      if (!mounted) return;

      if (result != true) {
        _showNotice('Đăng nhập Zalo thất bại hoặc đã bị hủy.', isError: true);
        return;
      }

      debugPrint('[ZALO] 4. Đang lấy access token');

      final String? accessToken = await zalo.getAccessToken().timeout(
        const Duration(seconds: 20),
      );

      debugPrint(
        '[ZALO] 5. Có access token: '
        '${accessToken != null && accessToken.isNotEmpty}',
      );

      if (!mounted) return;

      if (accessToken == null || accessToken.isEmpty) {
        _showNotice(
          'Đăng nhập Zalo thành công nhưng chưa lấy được token.',
          isError: true,
        );
        return;
      }

      debugPrint('[ZALO] 6. Đang lấy hồ sơ');

      final Map<String, dynamic>? profile = await zalo.getProfile().timeout(
        const Duration(seconds: 20),
      );

      debugPrint('[ZALO] 7. Có hồ sơ: ${profile != null}');

      if (!mounted) return;

      if (profile == null) {
        _showNotice('Chưa lấy được hồ sơ Zalo.', isError: true);
        return;
      }

      debugPrint('[ZALO] 8. Đang gửi yêu cầu đăng ký đến backend');

      // Gửi access token và vai trò đã chọn đến ASP.NET Core.
      final resultApi = await AuthService.zaloRegister(
        accessToken: accessToken,
        role: _selectedRole == 'landlord' ? 'owner' : 'tenant',
      );

      debugPrint('[ZALO] 9. Backend trả kết quả: $resultApi');

      if (!mounted) return;

      final bool isNewUser = resultApi['isNewUser'] == true;
      final String message = resultApi['message']?.toString() ?? '';

      if (isNewUser) {
        _showNotice(
          message.isNotEmpty
              ? message
              : 'Đăng ký Zalo thành công! Vui lòng đăng nhập.',
        );

        await Future.delayed(const Duration(milliseconds: 900));

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showNotice(
          message.isNotEmpty
              ? message
              : 'Tài khoản Zalo đã tồn tại. Vui lòng đăng nhập.',
          isError: true,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[ZALO] LỖI: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showNotice(
        'Đăng ký Zalo thất bại: '
        '${error.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                const Text(
                  'Tạo tài khoản mới',
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
                        onTap: () {
                          if (!_isLoading) {
                            setState(() {
                              _selectedRole = 'tenant';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        title: 'Chủ cho thuê',
                        icon: Icons.home_work_rounded,
                        isSelected: _selectedRole == 'landlord',
                        onTap: () {
                          if (!_isLoading) {
                            setState(() {
                              _selectedRole = 'landlord';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _CustomInputField(
                  controller: _fullNameController,
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên của bạn',
                  icon: Icons.person_outline_rounded,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập họ và tên'
                      : null,
                ),
                const SizedBox(height: 16),

                _CustomInputField(
                  controller: _emailController,
                  label: 'Email thật',
                  hint: 'ten@gmail.com',
                  icon: Icons.alternate_email_rounded,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(email)
                        ? null
                        : 'Vui lòng nhập email hợp lệ';
                  },
                ),
                const SizedBox(height: 16),

                _CustomInputField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hint: '0901234567',
                  icon: Icons.phone_outlined,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập số điện thoại'
                      : null,
                ),
                const SizedBox(height: 16),

                _CustomInputField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu (tối thiểu 8 ký tự)',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 8) {
                      return 'Mật khẩu phải từ 8 ký tự trở lên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _CustomInputField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  hint: 'Nhập lại mật khẩu vừa đặt',
                  icon: Icons.lock_reset_rounded,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu xác nhận không trùng khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Đăng ký tài khoản',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),

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

                Row(
                  children: [
                    Expanded(
                      child: _SocialAuthButton(
                        label: 'Google',
                        iconWidget: const Icon(
                          Icons.g_mobiledata_rounded,
                          color: Colors.redAccent,
                          size: 30,
                        ),
                        onTap: _handleGoogleSignIn,
                      ),
                    ),
                    const SizedBox(width: 10),
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
                  ],
                ),
                const SizedBox(height: 32),

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
                      onTap: _isLoading ? null : () => Navigator.pop(context),
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
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        onTap: onTap,
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
