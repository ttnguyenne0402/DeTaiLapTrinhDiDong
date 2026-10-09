import 'package:flutter/material.dart';
import '../../widgets/owner/dashboard_card.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'properties_manage.dart';
import '../tenant/profile_screen.dart';
import 'tenant_list_screen.dart';
import '../../core/constants/app_colors.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  final Color primaryColor = const Color(0xFF1B5E55);

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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Phần Thông tin cá nhân
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
                      const Text(
                        'Xin chào, Nguyễn Văn A 👋',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Chủ trọ khu vực Quận 9',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: DashboardCard(
                            icon: Icons.meeting_room,
                            value: '12',
                            label: 'Phòng đang cho thuê',
                          ),
                        ),
                        Expanded(
                          child: DashboardCard(
                            icon: Icons.calendar_today,
                            value: '5',
                            label: 'Lịch xem phòng',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: DashboardCard(
                            icon: Icons.door_front_door_outlined,
                            value: '8',
                            label: 'Phòng trống',
                          ),
                        ),
                        Expanded(
                          child: DashboardCard(
                            icon: Icons.build_circle_outlined,
                            value: '3',
                            label: 'Yêu cầu sửa chữa',
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),

              //Item Danh sách
              _buildViewingItem(
                avatarPath: "frontend/assets/images/avatarDemo.jpg",
                time: "Hôm nay, 10:00",
                name: "Nguyễn Văn A",
                roomInfo: "Phòng 202 - Chung cư mini",
                status: "Đã xác nhận",
                onCallTap: () {},
              ),

              const SizedBox(height: 8),
              _buildViewingItem(
                avatarPath: "frontend/assets/images/avatarDemo.jpg",
                time: "Hôm nay, 10:00",
                name: "Nguyễn Thị B",
                roomInfo: "Phòng 201 - Chung cư mini",
                status: "Đã xác nhận",
                onCallTap: () {},
              ),

              const SizedBox(height: 8),
              _buildViewingItem(
                avatarPath: "frontend/assets/images/avatarDemo.jpg",
                time: "Ngày mai, 14:30",
                name: "Trần Văn C",
                roomInfo: "Phòng 102 - Nhà trọ A",
                status: "Chờ xác nhận",
                statusColor: Colors.orange,
                onCallTap: () {},
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
            _buildNavItem(Icons.apartment, 'Tòa nhà', false, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PropertiesManageScreen(),
                ),
              );
            }),
            const SizedBox(width: 40),
            _buildNavItem(Icons.people_outline, 'Người thuê', false, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TenantListScreen(),
                ),
              );
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

  //hàm các card
  Widget _buildViewingItem({
    required String avatarPath,
    required String time,
    required String name,
    required String roomInfo,
    required String status,
    Color statusColor = Colors.green,
    VoidCallback? onCallTap,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  //hàm cho bottom
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
