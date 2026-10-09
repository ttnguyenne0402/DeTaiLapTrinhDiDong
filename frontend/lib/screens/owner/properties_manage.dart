import 'package:flutter/material.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'owner_dashboard.dart';
import 'owner_profile_screen.dart';
import 'property_form.dart';
import 'rooms_manage.dart';
import 'tenant_list_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';

class PropertiesManageScreen extends StatelessWidget {
  const PropertiesManageScreen({super.key});

  final Color primaryColor = const Color(0xFF1B5E55);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.primaryGreen,
        drawer: const OwnerDrawer(currentRoute: 'utilities'),
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: 'Mở danh mục',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {

              },
            ),

            const SizedBox(width: 10),
             CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 16,
              child: IconButton(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.person, color: Colors.white,size: 20,),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const OwnerProfileScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 16),
          ],
          title: const Text(
            'Quản lý Bất động sản',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,

          // THANH TAB BAR LỌC TÒA NHÀ
          bottom: TabBar(
            labelColor: AppColors.lightGreen,
            unselectedLabelColor: AppColors.lightGreen,
            indicatorColor: Colors.orange,
            indicatorWeight: 1,
            indicatorSize: TabBarIndicatorSize.label,
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
              Tab(text: 'Đang hoạt động'),
              Tab(text: 'Bảo trì / Khác'),
            ],
          ),
        ),

        //body bo góc trên và trái
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: TabBarView(
              children: [
                _buildPropertyList('all'),
                _buildPropertyList('active'),
                _buildPropertyList('maintenance'),
              ],
            ),
          ),
        ),

        // NÚT THÊM BẤT ĐỘNG SẢN MỚI
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PropertyFormScreen(),
              ),
            );
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
              _buildNavItem(Icons.home, 'Trang chủ', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OwnerDashboard(),
                  ),
                );
              }),
              _buildNavItem(Icons.apartment, 'Tòa nhà', true, () {
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
              _buildNavItem(Icons.person_outline, 'Cá nhân', false, () {}),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm xây dựng danh sách các Tòa nhà / Bất động sản theo filter
  Widget _buildPropertyList(String filter) {
    // Dữ liệu mẫu các Tòa nhà / Bất động sản
    final sampleProperties = [
      {
        'id': 'p1',
        'name': 'Chung cư Mini Q7',
        'address': '123 Nguyễn Thị Thập, P. Tân Quy, Quận 7, TP.HCM',
        'totalRooms': 20,
        'rentedRooms': 16,
        'emptyRooms': 4,
        'status': 'Đang hoạt động',
        'image': 'frontend/assets/images/anhPhongDemo.jpg',
      },
      {
        'id': 'p2',
        'name': 'Dãy trọ Xô Viết Nghệ Tĩnh',
        'address': '456 Xô Viết Nghệ Tĩnh, P.25, Q. Bình Thạnh, TP.HCM',
        'totalRooms': 12,
        'rentedRooms': 12,
        'emptyRooms': 0,
        'status': 'Đang hoạt động',
        'image': 'frontend/assets/images/anhPhongDemo.jpg',
      },
      {
        'id': 'p3',
        'name': 'Tòa nhà Căn hộ Lê Văn Sỹ',
        'address': '789 Lê Văn Sỹ, P.14, Quận 3, TP.HCM',
        'totalRooms': 15,
        'rentedRooms': 8,
        'emptyRooms': 7,
        'status': 'Bảo trì',
        'image': 'frontend/assets/images/anhPhongDemo.jpg',
      },
    ];

    // Logic lọc danh sách Tòa nhà
    final filtered = sampleProperties.where((property) {
      if (filter == 'active') return property['status'] == 'Đang hoạt động';
      if (filter == 'maintenance') return property['status'] == 'Bảo trì';
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'Không có bất động sản nào',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _buildPropertyCard(context, item);
      },
    );
  }

  // Widget Thẻ Tòa nhà / Bất động sản
  Widget _buildPropertyCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Khung chứa Ảnh Bất động sản + Status Badge
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      item['image'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apartment, size: 44, color: Colors.grey),
                            SizedBox(height: 4),
                            Text(
                              'Chưa có ảnh',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildStatusBadge(item['status'] as String),
                  ),
                ],
              ),
            ),
          ),

          // Thông tin Tòa nhà
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item['address'] as String,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Tổng phòng', '${item['totalRooms']}'),
                    _buildStatItem(
                      'Đang thuê',
                      '${item['rentedRooms']}',
                      color: Colors.green[700],
                    ),
                    _buildStatItem(
                      'Còn trống',
                      '${item['emptyRooms']}',
                      color: Colors.orange[800],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                //2 nút ghi điện nước và xem tiêu thụ
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.utilityReadings,
                          );
                        },
                        icon: const Icon(
                          Icons.bolt,
                          size: 16,
                          color: Colors.amber,
                        ),
                        label: const Text(
                          'Ghi điện nước',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.utilityHistory,
                          );
                        },
                        icon: const Icon(
                          Icons.bar_chart,
                          size: 16,
                          color: Colors.blue,
                        ),
                        label: const Text(
                          'Xem tiêu thụ',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ----------------------------------------------------

                // Nút chuyển sang màn hình Quản lý Phòng
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoomsManageScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.door_sliding_outlined,
                      size: 18,
                      color: primaryColor,
                    ),
                    label: Text(
                      'Quản lý danh sách phòng',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor = status == 'Đang hoạt động'
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    Color textColor = status == 'Đang hoạt động'
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
