import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/property_card.dart';
import 'owner_dashboard.dart';
import 'room_form.dart';
import 'tenant_list_screen.dart';

// Màn hình quản lý danh sách phòng trọ của chủ trọ
class RoomsManageScreen extends StatelessWidget {
  const RoomsManageScreen({super.key});

  final Color primaryColor = const Color(0xFF1B5E55);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.primaryGreen,
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Quản lý phòng',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,

          // Thanh bộ lọc trạng thái phòng
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Tất cả'),
              Tab(text: 'Đang cho thuê'),
              Tab(text: 'Còn trống'),
            ],
          ),
        ),

        // Thân màn hình bo góc lồng 2 lớp Container
        body: Container(
          color: AppColors.primaryGreen,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9FB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: TabBarView(
              children: [
                _buildRoomList('all'), // Hiển thị tất cả
                _buildRoomList('rented'), // Lọc phòng đang cho thuê
                _buildRoomList('empty'), // Lọc phòng còn trống
              ],
            ),
          ),
        ),

        // Nút thêm phòng mới
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RoomFormScreen()),
            );
          },
          backgroundColor: Colors.orange,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // Thanh điều hướng đáy
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Trang chủ', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OwnerDashboard(),
                  ),
                );
              }),
              _buildNavItem(Icons.apartment, 'Phòng', true, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoomsManageScreen(),
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
              _buildNavItem(Icons.person_outline, 'Cá nhân', false, () {}),
            ],
          ),
        ),
      ),
    );
  }

  // Danh sách phòng có bộ lọc theo tab
  Widget _buildRoomList(String filter) {
    // Dữ liệu danh sách phòng mẫu
    final sampleRooms = [
      {
        'roomName': 'Phòng 201',
        'detail': '25 m² - Tầng 2',
        'price': '4.000.000đ',
        'status': 'Đang cho thuê',
        'isRented': true,
        'images': "frontend/assets/images/anhPhongDemo.jpg",
      },
      {
        'roomName': 'Phòng 202',
        'detail': '25 m² - Tầng 2',
        'price': '4.500.000đ',
        'status': 'Còn trống',
        'isRented': false,
        'images': "frontend/assets/images/anhPhongDemo.jpg",
      },
      {
        'roomName': 'Phòng 301',
        'detail': '30 m² - Tầng 3',
        'price': '5.000.000đ',
        'status': 'Đang cho thuê',
        'isRented': true,
        'images': "frontend/assets/images/anhPhongDemo.jpg",
      },
      {
        'roomName': 'Phòng 302',
        'detail': '20 m² - Tầng 3',
        'price': '4.000.000đ',
        'status': 'Bảo trì',
        'isRented': false,
        'images': "frontend/assets/images/anhPhongDemo.jpg",
      },
    ];

    // Lọc danh sách phòng theo tham số
    final filtered = sampleRooms.where((room) {
      if (filter == 'rented') return room['isRented'] == true;
      if (filter == 'empty') return room['isRented'] == false;
      return true;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final room = filtered[index];
        return PropertyCard(
          title: room['roomName'] as String,
          subtitle: room['detail'] as String,
          price: room['price'] as String,
          status: room['status'] as String,
          isRented: room['isRented'] as bool,
          imageUrl: room['images'] as String,
          onTap: () {},
        );
      },
    );
  }
  // Nút điều hướng thanh dưới
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
