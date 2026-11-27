import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/owner/appointments_manage.dart';
import '../../screens/owner/contracts_manage.dart';
import '../../screens/owner/invoices_manage..dart';
import '../../screens/owner/maintenance_manage.dart';
import '../../screens/owner/owner_dashboard.dart';
import '../../screens/owner/posts_manage.dart';
import '../../screens/owner/properties_manage.dart';
import '../../services/auth_storage.dart';
import '../../services/local_notification_service.dart';
import '../../services/owner/owner_dashboard_service.dart';

class OwnerDrawer extends StatefulWidget {
  /// Mã định danh màn hình hiện tại để làm nổi bật:
  /// 'contracts', 'invoices', 'utilities', 'maintenance', 'posts', 'appointments', 'notifications', 'ai_chat'
  final String? currentRoute;

  const OwnerDrawer({super.key, this.currentRoute});

  @override
  State<OwnerDrawer> createState() => _OwnerDrawerState();
}

class _OwnerDrawerState extends State<OwnerDrawer> {
  static const Color _primaryColor = Color(0xFF1B5E55);
  static const String _fallbackAvatar = 'frontend/assets/images/avatarDemo.jpg';

  String _ownerName = 'Chủ trọ';
  String _ownerAvatar = '';
  String _ownerPhone = '';
  String _ownerArea = 'Khu vực quản lý';

  @override
  void initState() {
    super.initState();
    _loadOwnerProfile();
  }

  Future<void> _loadOwnerProfile() async {
    final results = await Future.wait([
      AuthStorage.getUserName(),
      AuthStorage.getUserAvatar(),
      AuthStorage.getPhone(),
      AuthStorage.getUserId(),
    ]);

    if (mounted) {
      setState(() {
        final cachedName = results[0]?.trim() ?? '';
        if (cachedName.isNotEmpty) _ownerName = cachedName;
        _ownerAvatar = results[1]?.trim() ?? '';
        _ownerPhone = results[2]?.trim() ?? '';
      });
    }

    final userId = results[3]?.trim();
    if (userId == null || userId.isEmpty) return;

    try {
      final dashboard = await OwnerDashboardService.fetchDashboardData(userId);
      if (!mounted) return;
      setState(() {
        if (dashboard.ownerName.trim().isNotEmpty) {
          _ownerName = dashboard.ownerName.trim();
        }
        if (dashboard.ownerAvatar.trim().isNotEmpty) {
          _ownerAvatar = dashboard.ownerAvatar.trim();
        }
        if (dashboard.ownerPhone.trim().isNotEmpty) {
          _ownerPhone = dashboard.ownerPhone.trim();
        }
        if (dashboard.ownerArea.trim().isNotEmpty) {
          _ownerArea = dashboard.ownerArea.trim();
        }
      });
      if (dashboard.ownerAvatar.trim().isNotEmpty) {
        await AuthStorage.saveUserAvatar(dashboard.ownerAvatar.trim());
      }
    } catch (_) {
      // Giữ thông tin đã lưu cục bộ nếu máy chủ chưa phản hồi
    }
  }

  void _navigateToPage(String routeKey, Widget page) {
    Navigator.pop(context);
    if (widget.currentRoute != routeKey) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = widget.currentRoute;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildSectionTitle('QUẢN LÝ CHO THUÊ'),
                _buildDrawerItem(
                  icon: Icons.assignment_outlined,
                  title: 'Quản lý Hợp đồng',
                  subtitle: 'Tạo mới, ký & thanh lý hợp đồng',
                  isActive: currentRoute == 'contracts',
                  onTap: () =>
                      _navigateToPage('contracts', const Contracts_manager()),
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Hóa đơn & Thu tiền',
                  subtitle: 'Lập hóa đơn, chốt tiền & VietQR',
                  isActive: currentRoute == 'invoices',
                  onTap: () => _navigateToPage('invoices', const Invoice_mana()),
                ),
                _buildDrawerItem(
                  icon: Icons.electric_bolt_outlined,
                  title: 'Chỉ số Điện & Nước',
                  subtitle: 'Ghi công tơ & tính tiền dịch vụ',
                  isActive: currentRoute == 'utilities',
                  onTap: () => _navigateToPage(
                    'utilities',
                    const PropertiesManageScreen(),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.build_circle_outlined,
                  title: 'Yêu cầu Bảo trì',
                  subtitle: 'Tiếp nhận & xử lý báo hỏng phòng',
                  isActive: currentRoute == 'maintenance',
                  onTap: () => _navigateToPage(
                    'maintenance',
                    const MaintenanceManageScreen(),
                  ),
                ),

                _buildDivider(),
                _buildSectionTitle('TIẾP THỊ & KHÁCH HÀNG'),
                _buildDrawerItem(
                  icon: Icons.campaign_outlined,
                  title: 'Quản lý Tin đăng',
                  subtitle: 'Đăng tin phòng trống & theo dõi duyệt',
                  isActive: currentRoute == 'posts',
                  onTap: () =>
                      _navigateToPage('posts', const PostsManageScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Lịch hẹn xem phòng',
                  subtitle: 'Xác nhận & quản lý lịch xem phòng',
                  isActive: currentRoute == 'appointments',
                  onTap: () => _navigateToPage(
                    'appointments',
                    const AppointmentsManageScreen(),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo',
                  subtitle: 'Lịch hẹn, duyệt tin, bảo trì, thu tiền',
                  isActive: currentRoute == 'notifications',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != 'notifications') {
                      Navigator.pushNamed(context, AppRoutes.ownerNotifications);
                    }
                  },
                ),

                _buildDivider(),
                _buildSectionTitle('TIỆN ÍCH & HỖ TRỢ'),
                _buildDrawerItem(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Trợ lý AI Chủ trọ',
                  subtitle: 'Tư vấn quản lý, thống kê & soạn tin',
                  isActive: currentRoute == 'ai_chat',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != 'ai_chat') {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.aiChat,
                        arguments: {'role': 'owner'},
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.headset_mic_outlined,
                  title: 'Trợ giúp & Hỗ trợ',
                  subtitle: 'Hotline 1900 6868 & hướng dẫn',
                  isActive: false,
                  onTap: () {
                    Navigator.pop(context);
                    _showSupportDialog(context);
                  },
                ),
              ],
            ),
          ),

          // NÚT ĐĂNG XUẤT CỐ ĐỊNH Ở DƯỚI CÙNG
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _confirmLogout(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đăng xuất',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Thoát tài khoản quản lý',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final displayPhone = _ownerPhone.isNotEmpty
        ? _ownerPhone
        : 'Chưa cập nhật SĐT';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: _primaryColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, AppColors.primaryGreen],
        ),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OwnerDashboard(),
                      ),
                    );
                  },
                  child: _buildHeaderAvatar(radius: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ownerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Chủ trọ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Colors.lightGreenAccent,
                          size: 15,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone, color: Colors.white70, size: 13),
                const SizedBox(width: 6),
                Text(
                  displayPhone,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _ownerArea,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAvatar({required double radius}) {
    final resolved = _ownerAvatar.startsWith('/')
        ? 'http://10.0.2.2:5093$_ownerAvatar'
        : _ownerAvatar;
    final isNetwork =
        resolved.startsWith('http://') || resolved.startsWith('https://');
    final size = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2C7D73),
      child: ClipOval(
        child: isNetwork
            ? Image.network(
                resolved,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  _fallbackAvatar,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                resolved.startsWith('frontend/assets/')
                    ? resolved
                    : _fallbackAvatar,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? _primaryColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? _primaryColor
                : _primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : _primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? _primaryColor : const Color(0xFF263238),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isActive
                ? _primaryColor.withValues(alpha: 0.8)
                : const Color(0xFF78909C),
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isActive ? _primaryColor : const Color(0xFFB0BEC5),
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Đăng xuất'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản chủ trọ?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(dialogCtx);

              await LocalNotificationService.instance.endPushSession();
              await AuthStorage.clearLogin();

              if (!navigator.mounted) return;

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.headset_mic_outlined, color: _primaryColor),
            SizedBox(width: 8),
            Text('Hỗ trợ chủ trọ'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng đài hỗ trợ kỹ thuật và giải đáp thắc mắc:'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone_in_talk, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text(
                  '1900 6868 (8:00 - 21:00)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email_outlined, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Text(
                  'hotro@trooi.vn',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Đóng', style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }
}
