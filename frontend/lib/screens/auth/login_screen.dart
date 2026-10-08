import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../tenant/home_screen.dart';
import '../owner/owner_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // INPUT
  // ============================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.textSecondary,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE1E7E3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: AppColors.primaryGreen,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // QUÊN MẬT KHẨU
  // ============================================================

  void _showForgotPasswordDialog() {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          title: const Row(
            children: [
              Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primaryGreen,
                size: 25,
              ),
              SizedBox(width: 10),
              Text(
                'Quên mật khẩu',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhập email hoặc số điện thoại đã đăng ký để nhận mã khôi phục.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hintText: 'Email hoặc số điện thoại',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email hoặc SĐT';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                controller.dispose();
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final String target = controller.text.trim();

                Navigator.pop(dialogContext);
                controller.dispose();

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Mã khôi phục đã được gửi tới $target',
                    ),
                    backgroundColor: AppColors.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(105, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Gửi mã',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ĐĂNG NHẬP
  // ============================================================

  void _login() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String email = _emailController.text.trim().toLowerCase();
    final String password = _passwordController.text;

    // ==========================================================
    // TÀI KHOẢN TEST
    // ==========================================================

    const String tenantEmail = 'tenant@gmail.com';
    const String ownerEmail = 'owner@gmail.com';
    const String testPassword = '123456';

    // ==========================================================
    // TENANT - NGƯỜI THUÊ
    // ==========================================================

    if (email == tenantEmail && password == testPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const HomeScreen(),
        ),
      );

      return;
    }

    // ==========================================================
    // OWNER - CHỦ TRỌ
    // ==========================================================

    if (email == ownerEmail && password == testPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const OwnerDashboard(),
        ),
      );

      return;
    }

    // ==========================================================
    // SAI TÀI KHOẢN / MẬT KHẨU
    // ==========================================================

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Email hoặc mật khẩu không chính xác.',
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // ĐI TỚI ĐĂNG KÝ
  // ============================================================

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const RegisterScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final double heroHeight = size.height * 0.49;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ========================================================
          // HERO - PHÒNG TRỌ
          // ========================================================

          SizedBox(
            height: heroHeight,
            width: double.infinity,
            child: CustomPaint(
              painter: const CozyRoomHeroPainter(),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 28,
                    left: 26,
                    right: 26,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.home_work_rounded,
                            color: Colors.white,
                            size: 30,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          Text(
                            'TRỌ ƠI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Tìm phòng dễ dàng - Sống thoải mái',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.15,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ========================================================
          // LOGIN CARD
          // ========================================================

          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                top: size.height * 0.355,
                left: 19,
                right: 19,
                bottom: 30,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  22,
                  27,
                  22,
                  24,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 32,
                      spreadRadius: 1,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Đăng nhập',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'Chào mừng bạn quay trở lại!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 27),

                      // EMAIL / SĐT
                      const Text(
                        'Email hoặc số điện thoại',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          hintText: 'Nhập email hoặc số điện thoại',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập Email hoặc SĐT';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // MẬT KHẨU
                      const Text(
                        'Mật khẩu',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: _inputDecoration(
                          hintText: 'Nhập mật khẩu',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 11),

                      // GHI NHỚ + QUÊN MẬT KHẨU
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFC8D1CC),
                                  ),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Ghi nhớ đăng nhập',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showForgotPasswordDialog,
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // BUTTON ĐĂNG NHẬP
                      SizedBox(
                        height: 53,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentYellow,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'ĐĂNG NHẬP',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // HOẶC
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFFE1E5E2),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 13,
                            ),
                            child: Text(
                              'HOẶC',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFFE1E5E2),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ĐĂNG KÝ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Chưa có tài khoản? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: _goToRegister,
                            child: const Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COZY ROOM HERO PAINTER
// ============================================================================

class CozyRoomHeroPainter extends CustomPainter {
  const CozyRoomHeroPainter();

  static const Color skyTop = Color(0xFFBFE3F5);
  static const Color skyMid = Color(0xFFF7E4BE);
  static const Color skyBottom = Color(0xFFFFF7EA);
  static const Color sunGlow = Color(0xFFFFF3D0);

  static const Color buildingFar = Color(0xFFC2D7E2);
  static const Color buildingMid = Color(0xFFA3C1CF);
  static const Color buildingNear = Color(0xFF87ABBC);
  static const Color windowLit = Color(0xFFFFE9A8);

  static const Color wall = Color(0xFFF4EFE2);

  static const Color greenDark = Color(0xFF1E4D45);
  static const Color green = Color(0xFF2E6E5F);
  static const Color leafDark = Color(0xFF4C8C5B);
  static const Color leafLight = Color(0xFF74B076);

  static const Color wood = Color(0xFFC69A6C);
  static const Color woodDark = Color(0xFF8A6240);

  static const Color cream = Color(0xFFFDF8ED);
  static const Color cardboard = Color(0xFFD9C7A8);
  static const Color paperWhite = Color(0xFFFBFAF5);
  static const Color inkGreen = Color(0xFF2E6E5F);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    _paintSkyAndCity(canvas, w, h);
    _paintRightCurtain(canvas, w, h);
    _paintRightWall(canvas, w, h);
    _paintBedCorner(canvas, w, h);
    _paintShelfAndPlant(canvas, w, h);
    _paintPinboard(canvas, w, h);
    _paintDeskForeground(canvas, w, h);
    _paintLightVignette(canvas, w, h);
  }

  void _paintSkyAndCity(
    Canvas canvas,
    double w,
    double h,
  ) {
    final Rect skyRect = Rect.fromLTWH(
      0,
      0,
      w,
      h * 0.80,
    );

    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          skyTop,
          skyMid,
          skyBottom,
        ],
        stops: [
          0.0,
          0.55,
          1.0,
        ],
      ).createShader(skyRect);

    canvas.drawRect(skyRect, skyPaint);

    final Offset sunCenter = Offset(
      w * 0.56,
      h * 0.46,
    );

    canvas.drawCircle(
      sunCenter,
      h * 0.22,
      Paint()..color = sunGlow.withOpacity(0.55),
    );

    canvas.drawCircle(
      sunCenter,
      h * 0.075,
      Paint()..color = Colors.white.withOpacity(0.90),
    );

    final Paint cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.55);

    _cloud(
      canvas,
      Offset(w * 0.18, h * 0.12),
      46,
      cloudPaint,
    );

    _cloud(
      canvas,
      Offset(w * 0.75, h * 0.08),
      60,
      cloudPaint,
    );

    final Paint cloudPaintSmall = Paint()
      ..color = Colors.white.withOpacity(0.40);

    _cloud(
      canvas,
      Offset(w * 0.40, h * 0.20),
      38,
      cloudPaintSmall,
    );

    _buildingRow(
      canvas,
      w,
      h,
      baseY: h * 0.66,
      heightScale: 0.10,
      color: buildingFar,
      seed: 1,
    );

    _buildingRow(
      canvas,
      w,
      h,
      baseY: h * 0.70,
      heightScale: 0.16,
      color: buildingMid,
      seed: 2,
    );

    _buildingRow(
      canvas,
      w,
      h,
      baseY: h * 0.74,
      heightScale: 0.24,
      color: buildingNear,
      seed: 3,
    );

    final Paint treeLinePaint = Paint()
      ..color = leafDark.withOpacity(0.85);

    final Path treePath = Path()
      ..moveTo(0, h * 0.80);

    final math.Random rnd = math.Random(7);

    double x = 0;

    while (x < w) {
      final double bumpW = 30 + rnd.nextDouble() * 26;
      final double bumpH = 10 + rnd.nextDouble() * 14;

      treePath.quadraticBezierTo(
        x + bumpW / 2,
        h * 0.80 - bumpH,
        x + bumpW,
        h * 0.80,
      );

      x += bumpW;
    }

    treePath
      ..lineTo(w, h * 0.86)
      ..lineTo(0, h * 0.86)
      ..close();

    canvas.drawPath(treePath, treeLinePaint);
  }

  void _cloud(
    Canvas canvas,
    Offset center,
    double scale,
    Paint paint,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: scale * 1.6,
        height: scale * 0.6,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(
          -scale * 0.4,
          scale * 0.05,
        ),
        width: scale * 0.9,
        height: scale * 0.5,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(
          scale * 0.45,
          scale * 0.08,
        ),
        width: scale,
        height: scale * 0.5,
      ),
      paint,
    );
  }

  void _buildingRow(
    Canvas canvas,
    double w,
    double h, {
    required double baseY,
    required double heightScale,
    required Color color,
    required int seed,
  }) {
    final math.Random rnd = math.Random(seed);

    final Paint buildingPaint = Paint()..color = color;

    final Paint litPaint = Paint()
      ..color = windowLit.withOpacity(0.85);

    double x = -20;

    while (x < w + 20) {
      final double bw = 30 + rnd.nextDouble() * 46;

      final double bh =
          h * heightScale * (0.5 + rnd.nextDouble());

      final Rect rect = Rect.fromLTWH(
        x,
        baseY - bh,
        bw,
        bh + (h - baseY),
      );

      canvas.drawRect(rect, buildingPaint);

      final int cols = math.max(
        1,
        math.min(
          6,
          (bw / 12).floor(),
        ),
      );

      final int rows = math.max(
        1,
        math.min(
          8,
          (bh / 14).floor(),
        ),
      );

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (rnd.nextDouble() > 0.6) {
            canvas.drawRect(
              Rect.fromLTWH(
                x + 4 + c * (bw / cols),
                baseY - bh + 4 + r * 14,
                4,
                6,
              ),
              litPaint,
            );
          }
        }
      }

      x += bw + 6 + rnd.nextDouble() * 8;
    }
  }

  void _paintRightCurtain(
    Canvas canvas,
    double w,
    double h,
  ) {
    final double curtainW = w * 0.16;

    final Rect rect = Rect.fromLTWH(
      w - curtainW,
      0,
      curtainW,
      h * 0.90,
    );

    final Path path = Path()
      ..moveTo(
        rect.left + curtainW * 0.15,
        rect.top,
      )
      ..quadraticBezierTo(
        rect.left - curtainW * 0.1,
        rect.top + rect.height * 0.5,
        rect.left + curtainW * 0.25,
        rect.bottom,
      )
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.top)
      ..close();

    final Paint curtainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.78),
        ],
      ).createShader(rect);

    canvas.drawPath(path, curtainPaint);

    final Paint foldPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 2;

    for (int i = 0; i < 4; i++) {
      final double fx =
          rect.left + curtainW * (0.35 + i * 0.15);

      canvas.drawLine(
        Offset(fx, rect.top + 10),
        Offset(fx + 6, rect.bottom - 10),
        foldPaint,
      );
    }
  }

  void _paintRightWall(
    Canvas canvas,
    double w,
    double h,
  ) {
    final Rect rect = Rect.fromLTWH(
      w * 0.90,
      0,
      w * 0.10,
      h,
    );

    canvas.drawRect(
      rect,
      Paint()..color = wall,
    );

    _polaroid(
      canvas,
      Offset(w * 0.935, h * 0.30),
      w * 0.06,
      tilt: -0.05,
      photoColor: buildingMid,
    );

    _polaroid(
      canvas,
      Offset(w * 0.945, h * 0.42),
      w * 0.055,
      tilt: 0.06,
      photoColor: leafLight,
    );

    final Rect noteRect = Rect.fromLTWH(
      w * 0.905,
      h * 0.04,
      w * 0.085,
      h * 0.16,
    );

    canvas.save();

    canvas.translate(
      noteRect.center.dx,
      noteRect.center.dy,
    );

    canvas.rotate(-0.03);

    canvas.translate(
      -noteRect.center.dx,
      -noteRect.center.dy,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        noteRect,
        const Radius.circular(3),
      ),
      Paint()..color = paperWhite,
    );

    final Paint linePaint = Paint()
      ..color = inkGreen.withOpacity(0.55)
      ..strokeWidth = 1.4;

    for (int i = 0; i < 3; i++) {
      final double ly =
          noteRect.top +
          noteRect.height * (0.35 + i * 0.2);

      canvas.drawLine(
        Offset(noteRect.left + 6, ly),
        Offset(noteRect.right - 10, ly),
        linePaint,
      );
    }

    canvas.restore();
  }

  void _polaroid(
    Canvas canvas,
    Offset center,
    double size, {
    double tilt = 0,
    required Color photoColor,
  }) {
    final Rect rect = Rect.fromCenter(
      center: center,
      width: size,
      height: size * 1.2,
    );

    canvas.save();

    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawRect(
      rect,
      Paint()..color = Colors.white,
    );

    final Rect photoRect = Rect.fromLTWH(
      rect.left + size * 0.08,
      rect.top + size * 0.08,
      size * 0.84,
      size * 0.80,
    );

    canvas.drawRect(
      photoRect,
      Paint()..color = photoColor.withOpacity(0.8),
    );

    canvas.restore();
  }

  void _paintBedCorner(
    Canvas canvas,
    double w,
    double h,
  ) {
    final Rect bedRect = Rect.fromLTWH(
      w * 0.80,
      h * 0.66,
      w * 0.20,
      h * 0.34,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bedRect,
        const Radius.circular(18),
      ),
      Paint()..color = green,
    );

    final Rect pillowRect = Rect.fromLTWH(
      bedRect.left + 10,
      bedRect.top + 6,
      bedRect.width * 0.75,
      bedRect.height * 0.45,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        pillowRect,
        const Radius.circular(10),
      ),
      Paint()..color = cream,
    );

    final Paint checkPaint = Paint()
      ..color = green.withOpacity(0.55);

    const double step = 10;

    for (
      double gx = pillowRect.left;
      gx < pillowRect.right;
      gx += step * 2
    ) {
      canvas.drawRect(
        Rect.fromLTWH(
          gx,
          pillowRect.top,
          step,
          pillowRect.height,
        ),
        checkPaint,
      );
    }

    for (
      double gy = pillowRect.top;
      gy < pillowRect.bottom;
      gy += step * 2
    ) {
      canvas.drawRect(
        Rect.fromLTWH(
          pillowRect.left,
          gy,
          pillowRect.width,
          step,
        ),
        checkPaint,
      );
    }
  }

  void _paintShelfAndPlant(
    Canvas canvas,
    double w,
    double h,
  ) {
    final Rect shelfRect = Rect.fromLTWH(
      -10,
      h * 0.03,
      w * 0.22,
      h * 0.045,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        shelfRect,
        const Radius.circular(3),
      ),
      Paint()..color = wood,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        shelfRect.left,
        shelfRect.bottom,
        shelfRect.width,
        4,
      ),
      Paint()..color = woodDark,
    );

    final Offset potCenter = Offset(
      shelfRect.left + shelfRect.width * 0.25,
      shelfRect.top,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: potCenter.translate(0, -6),
          width: 34,
          height: 22,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = cardboard,
    );

    final Paint vinePaint = Paint()
      ..color = leafDark
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final Offset vineStart = Offset(
      shelfRect.left + shelfRect.width * 0.55,
      shelfRect.bottom,
    );

    final Offset control = Offset(
      vineStart.dx - 30,
      vineStart.dy + h * 0.18,
    );

    final Offset end = Offset(
      vineStart.dx + 10,
      vineStart.dy + h * 0.34,
    );

    final Path vinePath = Path()
      ..moveTo(vineStart.dx, vineStart.dy)
      ..quadraticBezierTo(
        control.dx,
        control.dy,
        end.dx,
        end.dy,
      );

    canvas.drawPath(vinePath, vinePaint);

    final Paint leafPaint = Paint()..color = leafLight;

    final math.Random rnd = math.Random(5);

    for (
      double t = 0.1;
      t < 0.95;
      t += 0.12
    ) {
      final Offset point = _quadPoint(
        vineStart,
        control,
        end,
        t,
      );

      _leaf(
        canvas,
        point,
        16 + rnd.nextDouble() * 6,
        (t * 6) % math.pi,
        leafPaint,
      );
    }
  }

  Offset _quadPoint(
    Offset p0,
    Offset p1,
    Offset p2,
    double t,
  ) {
    final double x =
        (1 - t) * (1 - t) * p0.dx +
        2 * (1 - t) * t * p1.dx +
        t * t * p2.dx;

    final double y =
        (1 - t) * (1 - t) * p0.dy +
        2 * (1 - t) * t * p1.dy +
        t * t * p2.dy;

    return Offset(x, y);
  }

  void _leaf(
    Canvas canvas,
    Offset pos,
    double size,
    double rotate,
    Paint paint,
  ) {
    canvas.save();

    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotate);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size,
        height: size * 0.55,
      ),
      paint,
    );

    canvas.restore();
  }

  void _paintPinboard(
    Canvas canvas,
    double w,
    double h,
  ) {
    final Rect board = Rect.fromLTWH(
      -16,
      h * 0.20,
      w * 0.16,
      h * 0.34,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        board,
        const Radius.circular(6),
      ),
      Paint()..color = cardboard,
    );

    final Paint dotPaint = Paint()
      ..color = woodDark.withOpacity(0.08);

    final math.Random rnd = math.Random(11);

    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(
          board.left + rnd.nextDouble() * board.width,
          board.top + rnd.nextDouble() * board.height,
        ),
        1.2,
        dotPaint,
      );
    }

    _pinnedNote(
      canvas,
      Rect.fromLTWH(
        board.left + 8,
        board.top + 8,
        board.width * 0.70,
        board.height * 0.40,
      ),
      tilt: -0.04,
    );

    _polaroid(
      canvas,
      Offset(
        board.left + board.width * 0.42,
        board.top + board.height * 0.68,
      ),
      board.width * 0.55,
      tilt: 0.05,
      photoColor: leafDark,
    );

    final Rect sticky = Rect.fromLTWH(
      board.left + 4,
      board.bottom - board.height * 0.22,
      board.width * 0.32,
      board.height * 0.20,
    );

    canvas.drawRect(
      sticky,
      Paint()..color = const Color(0xFFF7D774),
    );

    final Paint heartPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.7);

    canvas.drawCircle(
      sticky.center.translate(-3, -2),
      3,
      heartPaint,
    );

    canvas.drawCircle(
      sticky.center.translate(3, -2),
      3,
      heartPaint,
    );

    final Path heartPath = Path()
      ..moveTo(
        sticky.center.dx - 6,
        sticky.center.dy - 1,
      )
      ..lineTo(
        sticky.center.dx,
        sticky.center.dy + 6,
      )
      ..lineTo(
        sticky.center.dx + 6,
        sticky.center.dy - 1,
      )
      ..close();

    canvas.drawPath(heartPath, heartPaint);
  }

  void _pinnedNote(
    Canvas canvas,
    Rect rect, {
    double tilt = 0,
  }) {
    canvas.save();

    canvas.translate(
      rect.center.dx,
      rect.center.dy,
    );

    canvas.rotate(tilt);

    canvas.translate(
      -rect.center.dx,
      -rect.center.dy,
    );

    final Path shadowPath = Path()..addRect(rect);

    canvas.drawShadow(
      shadowPath,
      Colors.black.withOpacity(0.15),
      3,
      true,
    );

    canvas.drawRect(
      rect,
      Paint()..color = paperWhite,
    );

    final Paint linePaint = Paint()
      ..color = inkGreen.withOpacity(0.6)
      ..strokeWidth = 1.3;

    for (int i = 0; i < 3; i++) {
      final double ly =
          rect.top + rect.height * (0.30 + i * 0.22);

      canvas.drawLine(
        Offset(rect.left + 5, ly),
        Offset(rect.right - 6, ly),
        linePaint,
      );
    }

    canvas.restore();

    canvas.drawCircle(
      Offset(rect.center.dx, rect.top),
      2.6,
      Paint()..color = Colors.redAccent,
    );
  }

  void _paintDeskForeground(
    Canvas canvas,
    double w,
    double h,
  ) {
    final Rect deskRect = Rect.fromLTWH(
      0,
      h * 0.86,
      w,
      h * 0.14,
    );

    final Paint deskPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          wood,
          woodDark,
        ],
      ).createShader(deskRect);

    canvas.drawRect(deskRect, deskPaint);

    final Paint grainPaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final double gy =
          deskRect.top + deskRect.height * (i / 5);

      canvas.drawLine(
        Offset(0, gy),
        Offset(w, gy),
        grainPaint,
      );
    }

    final Offset bookBase = Offset(
      w * 0.02,
      deskRect.top - 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          bookBase.dx,
          bookBase.dy - 10,
          w * 0.09,
          12,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = green,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          bookBase.dx + 4,
          bookBase.dy - 20,
          w * 0.08,
          11,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = greenDark,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -w * 0.02,
          deskRect.top - 2,
          w * 0.14,
          8,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFB9C2BC),
    );

    final Offset mugCenter = Offset(
      w * 0.18,
      deskRect.top - 24,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: mugCenter,
          width: 46,
          height: 40,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = cream,
    );

    final Paint mugHandlePaint = Paint()
      ..color = cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawArc(
      Rect.fromCenter(
        center: mugCenter.translate(26, 0),
        width: 16,
        height: 20,
      ),
      -math.pi / 2,
      math.pi,
      false,
      mugHandlePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          mugCenter.dx - 16,
          mugCenter.dy - 20,
          32,
          6,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = woodDark,
    );

    final Paint mugLeafPaint = Paint()
      ..color = leafDark;

    const List<double> angles = [
      -0.7,
      -0.2,
      0.25,
      0.7,
    ];

    for (final double angle in angles) {
      canvas.save();

      canvas.translate(
        mugCenter.dx,
        mugCenter.dy - 20,
      );

      canvas.rotate(angle);

      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0, -14),
          width: 10,
          height: 22,
        ),
        mugLeafPaint,
      );

      canvas.restore();
    }

    // Điện thoại
    final Rect phoneRect = Rect.fromLTWH(
      w * 0.30,
      deskRect.top - 10,
      w * 0.12,
      18,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        phoneRect,
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF20242B),
    );
  }

  void _paintLightVignette(
    Canvas canvas,
    double w,
    double h,
  ) {
    final Rect fullRect = Rect.fromLTWH(
      0,
      0,
      w,
      h,
    );

    final Paint glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.1,
        colors: [
          Colors.white.withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(fullRect);

    canvas.drawRect(fullRect, glow);

    final Rect topRect = Rect.fromLTWH(
      0,
      0,
      w,
      h * 0.35,
    );

    final Paint edge = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(topRect);

    canvas.drawRect(topRect, edge);
  }

  @override
  bool shouldRepaint(covariant CozyRoomHeroPainter oldDelegate) {
    return false;
  }
}