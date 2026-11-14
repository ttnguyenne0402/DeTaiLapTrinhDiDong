import 'package:flutter/material.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'properties_manage.dart';
import 'appointments_manage.dart';
import 'owner_notifications_screen.dart';
import 'maintenance_manage.dart';
import 'rooms_manage.dart';
import 'post_form.dart';
import '../tenant/profile_screen.dart';
import 'tenant_list_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/owner_dashboard_service.dart';
import '../../services/owner/owner_notification_service.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final Color primaryColor = const Color(0xFF1B5E55);
  late Future<OwnerDashboardModel> _dashboardFuture;
  int _unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardFuture = OwnerDashboardService.fetchDashboardData('USER_OWNER_01');
    });
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final list = await OwnerNotificationService.fetchNotifications('USER_OWNER_01');
    if (mounted) {
      setState(() {
        _unreadNotifCount = list.where((n) => !n.isRead).length;
      });
    }
  }

  Future<void> _openAppointmentsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppointmentsManageScreen(),
      ),
    );
    _refreshDashboard();
  }

  Future<void> _openNotificationsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OwnerNotificationsScreen(),
      ),
    );
    _refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      drawer: const OwnerDrawer(),
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Trang chủ', style: TextStyle(color: Colors.white)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: _openNotificationsScreen,
                tooltip: 'Thông báo',
                icon: const Icon(Icons.notifications, color: Colors.white),
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: _openNotificationsScreen,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: FutureBuilder<OwnerDashboardModel>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Không có dữ liệu'));
            }

            final data = snapshot.data!;

            return RefreshIndicator(
              onRefresh: () async => _refreshDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần Thông tin cá nhân
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                            "frontend/assets/images/avatarDemo.jpg",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, ${data.ownerName} 👋',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              data.ownerRole,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tổng quan hôm nay
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng quan hôm nay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RoomsManageScreen(),
                                      ),
                                    );
                                    _refreshDashboard();
                                  },
                                  child: _buildDashboardCard(
                                    icon: Icons.meeting_room,
                                    value: '${data.totalRentedRooms}',
                                    label: 'Phòng đang cho thuê',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: _openAppointmentsScreen,
                                  child: _buildDashboardCard(
                                    icon: Icons.calendar_today,
                                    value: '${data.scheduledAppointments}',
                                    label: 'Lịch xem phòng',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RoomsManageScreen(),
                                      ),
                                    );
                                    _refreshDashboard();
                                  },
                                  child: _buildDashboardCard(
                                    icon: Icons.door_front_door_outlined,
                                    value: '${data.emptyRooms}',
                                    label: 'Phòng trống',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MaintenanceManageScreen(),
                                      ),
                                    );
                                    _refreshDashboard();
                                  },
                                  child: _buildDashboardCard(
                                    icon: Icons.build_circle_outlined,
                                    value: '${data.repairRequests}',
                                    label: 'Yêu cầu sửa chữa',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lịch xem phòng sắp tới',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _openAppointmentsScreen,
                          child: const Text(
                            'Xem tất cả',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Hiển thị danh sách lịch hẹn lấy động từ Database (Nhấn vô mở trang duyệt đặt lịch)
                    data.upcomingAppointments.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text('Không có lịch hẹn nào sắp tới'),
                            ),
                          )
                        : Column(
                            children: data.upcomingAppointments.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildViewingItem(
                                  avatarPath:
                                      "frontend/assets/images/avatarDemo.jpg",
                                  time: item.time,
                                  name: item.name,
                                  roomInfo: item.roomInfo,
                                  status: item.status,
                                  statusColor: item.status == 'Đã xác nhận'
                                      ? Colors.green
                                      : (item.status == 'Đã đổi giờ'
                                          ? Colors.blue
                                          : Colors.orange),
                                  onTap: _openAppointmentsScreen,
                                  onCallTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đang gọi ${item.phone}...'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostFormScreen()),
          );
          _refreshDashboard();
        },
        backgroundColor: Colors.orange,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Trang chủ', true, () {}),
            _buildNavItem(Icons.apartment, 'Tòa nhà', false, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PropertiesManageScreen(),
                ),
              );
              _refreshDashboard();
            }),
            const SizedBox(width: 40),
            _buildNavItem(Icons.people_outline, 'Người thuê', false, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TenantListScreen(),
                ),
              );
              _refreshDashboard();
            }),
            _buildNavItem(Icons.person_outline, 'Cá nhân', false, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(
                    user: {
                      'Name': 'Nguyễn Văn A',
                      'Email': '',
                      'Phone': '',
                      'Avatar': '',
                      'Role': 'owner',
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  // Card lịch hẹn: Nhấn vô nhảy sang trang duyệt đặt lịch xem phòng
  Widget _buildViewingItem({
    required String avatarPath,
    required String time,
    required String name,
    required String roomInfo,
    required String status,
    Color statusColor = Colors.green,
    VoidCallback? onTap,
    VoidCallback? onCallTap,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 20, backgroundImage: AssetImage(avatarPath)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(name, style: const TextStyle(fontSize: 15)),
                    Text(
                      roomInfo,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onCallTap,
                    child: Icon(Icons.phone_in_talk, color: primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? primaryColor : Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? primaryColor : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
