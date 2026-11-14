import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'owner_dashboard.dart';
import 'room_form.dart';
import 'tenant_list_screen.dart';
import '../../services/owner/room_service.dart';
import '../../services/auth_storage.dart';

// Màn hình quản lý danh sách phòng trọ (lọc theo đúng Bất động sản khi bấm từ Quản lý BĐS)
class RoomsManageScreen extends StatefulWidget {
  final String? propertyId;
  final String? propertyName;

  const RoomsManageScreen({
    super.key,
    this.propertyId,
    this.propertyName,
  });

  @override
  State<RoomsManageScreen> createState() => _RoomsManageScreenState();
}

class _RoomsManageScreenState extends State<RoomsManageScreen> {
  final Color primaryColor = const Color(0xFF1B5E55);
  int _refreshCounter = 0;

  void _reload() {
    setState(() {
      _refreshCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String screenTitle = (widget.propertyName != null && widget.propertyName!.isNotEmpty)
        ? 'Phòng - ${widget.propertyName}'
        : 'Quản lý phòng';

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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Làm mới',
              onPressed: _reload,
            ),
          ],
          title: Text(
            screenTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          centerTitle: true,

          // Thanh bộ lọc trạng thái phòng
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: [
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
                _buildRoomList('rented'), // Lọc phòng đang cho thuê của đúng BĐS
                _buildRoomList('empty'),  // Lọc phòng còn trống của đúng BĐS
                _buildRoomList('all'),    // Hiển thị tất cả phòng của đúng BĐS
              ],
            ),
          ),
        ),

        // Nút thêm phòng mới (gắn sẵn propertyId nếu đang ở trong 1 bất động sản cụ thể)
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomFormScreen(
                  initialPropertyId: widget.propertyId,
                ),
              ),
            );
            if (res == true) {
              _reload();
            }
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
              _buildNavItem(Icons.apartment, 'Phòng', true, () {}),
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

  // Danh sách phòng có bộ lọc theo tab VÀ theo đúng Bất động sản được chọn
  Widget _buildRoomList(String filter) {
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
      },
      child: FutureBuilder<List<RoomModel>>(
        key: ValueKey('$filter-${widget.propertyId ?? 'all'}-$_refreshCounter'),
        future: RoomService.fetchRooms(
          'USER_OWNER_01',
          status: filter,
          propertyId: widget.propertyId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 54, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Lỗi kết nối máy chủ: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          var rooms = snapshot.data ?? [];

          // Đảm bảo chỉ hiển thị đúng phòng thuộc bất động sản đang chọn (không phân biệt hoa/thường)
          if (widget.propertyId != null && widget.propertyId!.trim().isNotEmpty) {
            final targetPropId = widget.propertyId!.trim().toLowerCase();
            rooms = rooms
                .where((r) => r.propertyId.trim().toLowerCase() == targetPropId)
                .toList();
          }

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room_outlined, size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    widget.propertyName != null
                        ? 'Chưa có phòng nào thuộc ${widget.propertyName} ở mục này'
                        : 'Không có phòng nào trong danh mục này',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _buildRoomCard(room);
            },
          );
        },
      ),
    );
  }

  Widget _buildRoomImage(String imgPath) {
    final fallback = Container(
      width: 85,
      height: 85,
      color: Colors.grey[200],
      child: const Icon(Icons.apartment, color: Colors.grey),
    );

    if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
      return Image.network(
        imgPath,
        width: 85,
        height: 85,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (!imgPath.startsWith('frontend/') && !imgPath.startsWith('assets/')) {
      final file = File(imgPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 85,
          height: 85,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      }
    }
    return Image.asset(
      imgPath,
      width: 85,
      height: 85,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  // Thẻ hiển thị thông tin từng phòng và nút Sửa
  Widget _buildRoomCard(RoomModel room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildRoomImage(room.images),
          ),
          const SizedBox(width: 14),

          // Thông tin chi tiết phòng
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  room.propertyName.isNotEmpty
                      ? '${room.propertyName} • ${room.detail}'
                      : room.detail,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  room.priceFormatted,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStatusBadge(room.statusText),
              ],
            ),
          ),

          // Nút Sửa thông tin phòng
          GestureDetector(
            onTap: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomFormScreen(initialData: room),
                ),
              );
              if (res == true) {
                _reload();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Sửa',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
