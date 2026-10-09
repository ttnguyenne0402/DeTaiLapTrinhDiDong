import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/owner/contracts_manage.dart';
import '../../screens/owner/invoices_manage..dart';
import '../../screens/owner/maintenance_manage.dart';
import '../../screens/owner/posts_manage.dart';
import '../../screens/owner/utility_readings.dart';
import '../../screens/owner/properties_manage.dart';
import '../../screens/owner/appointments_manage.dart';
import '../../screens/owner/services_manage.dart';
import '../../screens/owner/utility_readings.dart';

class OwnerDrawer extends StatelessWidget {
  /// Mã định danh màn hình hiện tại để làm nổi bật (nếu có):
  /// 'contracts', 'invoices', 'utilities', 'maintenance', 'posts', 'appointments', 'services'
  final String? currentRoute;

  const OwnerDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1B5E55);

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // HEADER THÔNG TIN CHỦ TRỌ
          _buildDrawerHeader(context, primaryColor),

          // DANH SÁCH CÁC NGHIỆP VỤ QUẢN LÝ (KHÔNG CÓ TRÊN BOTTOM NAV BAR)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSectionTitle('NGHIỆP VỤ QUẢN LÝ'),

                // 1. Quản lý Hợp đồng thuê
                _buildDrawerItem(
                  context: context,
                  icon: Icons.assignment_outlined,
                  title: 'Quản lý Hợp đồng',
                  subtitle: 'Theo dõi, gia hạn & tạo hợp đồng',
                  isActive: currentRoute == 'contracts',
                  onTap: () {
                    Navigator.pop(context); // Đóng drawer
                    if (currentRoute != 'contracts') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Contracts_manager(),
                        ),
                      );
                    }
                  },
                ),

                // 2. Quản lý Hóa đơn & Thu tiền
                _buildDrawerItem(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Hóa đơn & Thu tiền',
                  subtitle: 'Lập phiếu thu, chốt tiền phòng',
                  isActive: currentRoute == 'invoices',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != 'invoices') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Invoice_mana(),
                        ),
                      );
                    }
                  },
                ),

                // 3. Quản lý Chỉ số Điện & Nước
                _buildDrawerItem(
                  context: context,
                  icon: Icons.electric_bolt_outlined,
                  title: 'Chỉ số Điện & Nước',
                  subtitle: 'Ghi số công tơ, tính tiền dịch vụ',
                  isActive: currentRoute == 'utilities',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != 'utilities') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InvoiceCreateScreen(),
                        ),
                      );
                    }
                  },
                ),

                // 4. Quản lý Bảo trì & Sửa chữa
                _buildDrawerItem(
                  context: context,
                  icon: Icons.build_circle_outlined,
                  title: 'Yêu cầu Bảo trì',
                  subtitle: 'Tiếp nhận báo hỏng từ khách thuê',
                  isActive: currentRoute == 'maintenance',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != 'maintenance') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MaintenanceManageScreen(),
                        ),
                      );
                    }
                  },
                ),

                // 5. Quản lý Tin đăng cho thuê
                _buildDrawerItem(
                  context: context,
                  icon: Icons.campaign_outlined,
                  title: 'Quản lý Tin đăng',
                  subtitle: 'Đăng phòng trống tìm người thuê',
                  isActive: currentRoute == 'posts',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != 'posts') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PostsManageScreen(),
                        ),
                      );
                    }
                  },
                ),

                // 6. Quản lý Lịch hẹn xem phòng (MỚI THÊM)
                _buildDrawerItem(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  title: 'Lịch hẹn xem phòng',
                  subtitle: 'Quản lý, xác nhận lịch xem phòng',
                  isActive: currentRoute == 'appointments',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != 'appointments') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AppointmentsManageScreen(),
                        ),
                      );
                    }
                  },
                ),

                // 7. Quản lý Dịch vụ & Bảng giá (MỚI THÊM)
                _buildDrawerItem(
                  context: context,
                  icon: Icons.room_service_outlined,
                  title: 'Dịch vụ & Bảng giá',
                  subtitle: 'Cấu hình đơn giá điện, nước, wifi...',
                  isActive: currentRoute == 'services',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != 'services') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServicesManageScreen(),
                        ),
                      );
                    }
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFEEEEEE),
                  ),
                ),

                _buildSectionTitle('HỆ THỐNG'),

                // Cài đặt
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt hệ thống',
                  subtitle: 'Thông báo, bảo mật & biểu phí chung',
                  isActive: currentRoute == 'settings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng cài đặt đang được hoàn thiện'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                // Trợ giúp & Hỗ trợ
                _buildDrawerItem(
                  context: context,
                  icon: Icons.headset_mic_outlined,
                  title: 'Trợ giúp & Hỗ trợ',
                  subtitle: 'Hotline kỹ thuật và hướng dẫn',
                  isActive: false,
                  onTap: () {
                    Navigator.pop(context);
                    _showSupportDialog(context);
                  },
                ),
              ],
            ),
          ),

          // NÚT ĐĂNG XUẤT Ở DƯỚI CÙNG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _confirmLogout(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
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
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header của Drawer
  Widget _buildDrawerHeader(BuildContext context, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: primaryColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, AppColors.primaryGreen],
        ),
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
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF2C7D73),
                  backgroundImage: AssetImage(
                    'frontend/assets/images/avatarDemo.jpg',
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nguyễn Văn A',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Chủ trọ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Colors.lightGreenAccent,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.phone, color: Colors.white70, size: 13),
                SizedBox(width: 6),
                Text(
                  '0901 234 567',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                Spacer(),
                Text(
                  'Khu vực Q.9',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tiêu đề nhóm mục
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 6),
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

  // Item danh mục Drawer
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    const Color primaryColor = Color(0xFF1B5E55);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? primaryColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? primaryColor : const Color(0xFF263238),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isActive
                ? primaryColor.withOpacity(0.8)
                : const Color(0xFF78909C),
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isActive ? primaryColor : const Color(0xFFB0BEC5),
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  // Hộp thoại xác nhận đăng xuất
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
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  // Hộp thoại thông tin hỗ trợ
  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.headset_mic_outlined, color: Color(0xFF1B5E55)),
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
                  'hotro@trotot.vn',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Đóng',
              style: TextStyle(color: Color(0xFF1B5E55)),
            ),
          ),
        ],
      ),
    );
  }
}
