import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/property_card.dart';
import 'owner_dashboard.dart';
import 'room_form.dart';

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
              Tab(text: 'Đang cho thuê'),
              Tab(text: 'Còn trống'),
              Tab(text: 'Tất cả'),
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
                _buildRoomList('rented'), // Lọc phòng đang cho thuê
                _buildRoomList('empty'), // Lọc phòng còn trống
                _buildRoomList('all'), // Hiển thị tất cả
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
              _buildNavItem(Icons.people_outline, 'Người thuê', false, () {}),
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

  // Thẻ hiển thị thông tin từng phòng
  Widget _buildRoomCard({
    required String roomName,
    required String detail,
    required String price,
    required String status,
    required String images,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ảnh phòng
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              images,
              width: 85,
              height: 85,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 85,
                height: 85,
                color: Colors.grey[200],
                child: const Icon(Icons.apartment, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Thông tin chi tiết phòng
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),

                // Badge trạng thái phòng
                _buildStatusBadge(status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Badge nhãn trạng thái phòng
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Đang cho thuê':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'Còn trống':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
        break;
      case 'Bảo trì':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
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
