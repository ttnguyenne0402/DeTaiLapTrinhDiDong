import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'owner_dashboard.dart';
import 'properties_manage.dart';
import 'owner_profile_screen.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {

  final List<Map<String, dynamic>> _tenants = [
    {
      'name': 'Nguyễn Thị Hạnh',
      'room': 'Phòng 201',
      'date': '01/06/2024',
      'avatar': 'frontend/assets/images/avatarDemo.jpg',
      'phone': '0901234567'
    },
    {
      'name': 'Trần Văn Nam',
      'room': 'Phòng 101',
      'date': '15/05/2024',
      'avatar': 'frontend/assets/images/avatarDemo.jpg',
      'phone': '0901234568'
    },
    {
      'name': 'Lê Thị Mai',
      'room': 'Phòng 301',
      'date': '20/04/2024',
      'avatar': 'frontend/assets/images/avatarDemo.jpg',
      'phone': '0901234569'
    },
    {
      'name': 'Phạm Văn An',
      'room': 'Phòng 302',
      'date': '01/04/2024',
      'avatar': 'frontend/assets/images/avatarDemo.jpg',
      'phone': '0901234570'
    },
    {
      'name': 'Hoàng Thị Cúc',
      'room': 'Phòng 105',
      'date': '10/03/2024',
      'avatar': 'frontend/assets/images/avatarDemo.jpg',
      'phone': '0901234571'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      drawer: const OwnerDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          'Người thuê',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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
        child: Column(
          children: [
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người thuê...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),


            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tenants.length,
                itemBuilder: (context, index) {
                  final tenant = _tenants[index];
                  return _buildTenantItem(tenant);
                },
              ),
            ),
          ],
        ),
      ),


      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.accentYellow,
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
            _buildNavItem(Icons.home, 'Trang chủ', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const OwnerDashboard()),
              );
            }),
            _buildNavItem(Icons.apartment, 'Tòa nhà', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PropertiesManageScreen()),
              );
            }),
            const SizedBox(width: 40),
            _buildNavItem(Icons.people_alt, 'Người thuê', true, () {}),
            _buildNavItem(Icons.person_outline, 'Cá nhân', false, () {

            }),
          ],
        ),
      ),
    );
  }


  Widget _buildTenantItem(Map<String, dynamic> tenant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0
        )
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.lightGreen,

          child: const Icon(Icons.person, color: AppColors.primaryGreen, size: 28),
        ),
        title: Text(
          tenant['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${tenant['room']} • ${tenant['date']}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.phone_in_talk, color: AppColors.primaryGreen),
          onPressed: () {
            // Xử lý gọi điện
          },
        ),
      ),
    );
  }

  // Thanh Navigation Item
  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? AppColors.primaryGreen : Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.primaryGreen : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}