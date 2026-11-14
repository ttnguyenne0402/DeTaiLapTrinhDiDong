import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'owner_dashboard.dart';
import 'owner_profile_screen.dart';
import 'owner_notifications_screen.dart';
import 'property_form.dart';
import 'rooms_manage.dart';
import 'tenant_list_screen.dart';
import '../../core/constants/app_colors.dart';
import 'utility_history.dart';
import 'utility_readings.dart';
import '../../services/owner/property_service.dart';
import 'owner_profile_screen.dart';
import '../../services/auth_storage.dart';


class PropertiesManageScreen extends StatefulWidget {
  const PropertiesManageScreen({super.key});

  @override
  State<PropertiesManageScreen> createState() => _PropertiesManageScreenState();
}

class _PropertiesManageScreenState extends State<PropertiesManageScreen> {
  final Color primaryColor = const Color(0xFF1B5E55);

  void _refreshList() {
    setState(() {});
  }

  Future<void> _openPropertyRooms(PropertyModel item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomsManageScreen(
          propertyId: item.id,
          propertyName: item.name,
        ),
      ),
    );
    _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.primaryGreen,
        drawer: const OwnerDrawer(currentRoute: 'properties'),
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
              tooltip: 'Thông báo',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OwnerNotificationsScreen(),
                  ),
                );
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
                icon: const Icon(Icons.person, color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
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
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PropertyFormScreen(),
              ),
            );
            if (result == true) {
              _refreshList();
            }
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
              _buildNavItem(Icons.apartment, 'Tòa nhà', true, () {}),
              const SizedBox(width: 40), // Khoảng trống chừa chỗ cho nút thêm (+) ở giữa
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
                    builder: (context) => const OwnerProfileScreen(), // Điều hướng đúng trang profile chủ trọ
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyList(String filter) {
    return FutureBuilder<List<PropertyModel>>(
      future: AuthStorage.getUserId().then((id) => PropertyService.fetchProperties(id ?? '', filter)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Không có bất động sản nào',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          );
        }

        final filtered = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return _buildPropertyCard(context, item);
          },
        );
      },
    );
  }

  Widget _buildPropertyImage(String imgPath) {
    final fallback = Container(
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apartment, size: 44, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            'Chưa có ảnh',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );

    if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (!imgPath.startsWith('frontend/') && !imgPath.startsWith('assets/')) {
      final file = File(imgPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      }
    }
    return Image.asset(
      imgPath,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  Widget _buildPropertyCard(BuildContext context, PropertyModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openPropertyRooms(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildPropertyImage(item.image),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildStatusBadge(item.status),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
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
                          item.address,
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
                      _buildStatItem('Tổng phòng', '${item.totalRooms}'),
                      _buildStatItem(
                        'Đang thuê',
                        '${item.rentedRooms}',
                        color: Colors.green[700],
                      ),
                      _buildStatItem(
                        'Còn trống',
                        '${item.emptyRooms}',
                        color: Colors.orange[800],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InvoiceCreateScreen(),
                              ),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LandlordUtilityScreen(),
                              ),
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openPropertyRooms(item),
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
