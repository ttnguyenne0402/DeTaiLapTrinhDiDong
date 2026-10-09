
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/tenant/profile_info_card.dart';
import '../auth/login_screen.dart';
import 'edit_profile_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const ProfileScreen({
    super.key,
    this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();

    _userData = Map<String, dynamic>.from(
      widget.user ??
          {
            'Name': 'Người dùng',
            'Email': '',
            'Phone': '',
            'Avatar': '',
            'Role': 'tenant',
          },
    );
  }

  // =========================
  // CHỈNH SỬA THÔNG TIN
  // =========================

  Future<void> _editProfile() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EditProfileDialog(
        initialData: Map<String, dynamic>.from(_userData),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _userData.addAll(result);
    });

    _showMessage('Đã cập nhật thông tin trên giao diện.');
  }

  // =========================
  // ĐĂNG XUẤT
  // =========================

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Em có chắc muốn đăng xuất khỏi tài khoản không?',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // =========================
  // THÔNG BÁO
  // =========================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // =========================
  // GIAO DIỆN
  // =========================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // TIÊU ĐỀ
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),

          // THÔNG TIN NGƯỜI THUÊ
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin của bạn',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Quản lý thông tin cá nhân của bạn tại đây.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Thẻ thông tin cá nhân hiện có
                  ProfileInfoCard(
                    user: _userData,
                    onEdit: _editProfile,
                  ),
                ],
              ),
            ),
          ),

          // THẺ LƯU Ý
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _buildPrivacyCard(),
            ),
          ),

          // NÚT ĐĂNG XUẤT
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            sliver: SliverToBoxAdapter(
              child: _buildLogoutButton(),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HEADER
  // =========================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF005D4B),
            Color(0xFF157762),
            Color(0xFF2D8D73),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -35,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -55,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentYellow.withOpacity(0.10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.home_work_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'TRỌ ƠI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 27),
              Row(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.45),
                        width: 1.5,
                      ),
                    ),
                    child: _buildAvatar(),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xin chào 👋',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: AppColors.accentYellow,
                                size: 14,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Người thuê',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatar = _userData['Avatar']?.toString().trim() ?? '';

    if (avatar.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          avatar,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        ),
      );
    }

    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return const Icon(
      Icons.person_rounded,
      color: Colors.white,
      size: 38,
    );
  }

  String get _displayName {
    final name = _userData['Name']?.toString().trim() ?? '';
    return name.isEmpty ? 'Người dùng' : name;
  }

  // =========================
  // THẺ GỢI Ý
  // =========================

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primaryGreen,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Hãy đảm bảo email và số điện thoại của bạn luôn chính xác để thuận tiện khi liên hệ về phòng trọ.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // NÚT ĐĂNG XUẤT
  // =========================

  Widget _buildLogoutButton() {
    return Material(
      color: AppColors.cardSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF0DADA),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Color(0xFFC62828),
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đăng xuất tài khoản',
                  style: TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFC62828),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
