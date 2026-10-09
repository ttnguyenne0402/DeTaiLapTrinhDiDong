import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/owner_drawer.dart';

class AppointmentsManageScreen extends StatefulWidget {
  const AppointmentsManageScreen({super.key});

  @override
  State<AppointmentsManageScreen> createState() =>
      _AppointmentsManageScreenState();
}

class _AppointmentsManageScreenState extends State<AppointmentsManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _appointments = [
    {
      'id': 'a1',
      'name': 'Nguyễn Văn A',
      'phone': '0901234567',
      'roomInfo': 'Phòng 202 - Chung cư Mini Q7',
      'time': '10:00 - Hôm nay',
      'date': '09/10/2026',
      'status': 'confirmed',
      'note': 'Hẹn gặp tại cổng chính, khách xin xem thêm chỗ để xe.',
      'avatar': 'frontend/assets/images/avatarDemo.jpg',
    },
    {
      'id': 'a2',
      'name': 'Trần Thị B',
      'phone': '0912345678',
      'roomInfo': 'Phòng 101 - Dãy trọ Lê Văn Sỹ',
      'time': '14:30 - Hôm nay',
      'date': '09/10/2026',
      'status': 'pending',
      'note': 'Khách muốn xem phòng vào buổi chiều.',
      'avatar': 'frontend/assets/images/avatarDemo.jpg',
    },
    {
      'id': 'a3',
      'name': 'Lê Hoàng C',
      'phone': '0987654321',
      'roomInfo': 'Phòng 301 - Chung cư Mini Q7',
      'time': '09:00 - Ngày mai',
      'date': '10/10/2026',
      'status': 'confirmed',
      'note': 'Khách muốn đặt cọc luôn nếu phòng sạch đẹp.',
      'avatar': 'frontend/assets/images/avatarDemo.jpg',
    },
    {
      'id': 'a4',
      'name': 'Phạm Minh D',
      'phone': '0933445566',
      'roomInfo': 'Phòng 201 - Dãy trọ Lê Văn Sỹ',
      'time': '16:00 - 05/10/2026',
      'date': '05/10/2026',
      'status': 'completed',
      'note': 'Đã xem phòng và chốt ký hợp đồng ngày 15/10.',
      'avatar': 'frontend/assets/images/avatarDemo.jpg',
    },
    {
      'id': 'a5',
      'name': 'Vũ Hoàng E',
      'phone': '0977889900',
      'roomInfo': 'Phòng 102 - Chung cư Mini Q7',
      'time': '11:00 - 02/10/2026',
      'date': '02/10/2026',
      'status': 'cancelled',
      'note': 'Khách bận việc đột xuất không qua được.',
      'avatar': 'frontend/assets/images/avatarDemo.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _appointments
        .where((a) => a['status'] == 'pending' || a['status'] == 'confirmed')
        .toList();
    final completed = _appointments
        .where((a) => a['status'] == 'completed')
        .toList();
    final cancelled = _appointments
        .where((a) => a['status'] == 'cancelled')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      drawer: const OwnerDrawer(currentRoute: 'appointments'),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Quản lý lịch hẹn xem phòng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'Sắp tới (${upcoming.length})'),
            Tab(text: 'Hoàn thành (${completed.length})'),
            Tab(text: 'Đã hủy (${cancelled.length})'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentList(upcoming),
            _buildAppointmentList(completed),
            _buildAppointmentList(cancelled),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Không có lịch hẹn nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildAppointmentCard(item);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> item) {
    final String status = item['status'];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(status),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item['time'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(
                    'frontend/assets/images/avatarDemo.jpg',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['roomInfo'] ?? '',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.phone, color: AppColors.primaryGreen),
                  tooltip: 'Gọi điện',
                ),
              ],
            ),
            if (item['note'] != null &&
                (item['note'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ghi chú: ${item['note']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending') ...[
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        item['status'] = 'cancelled';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Từ chối',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        item['status'] = 'confirmed';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Xác nhận lịch',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
                if (status == 'confirmed') ...[
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        item['status'] = 'cancelled';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Hủy lịch',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        item['status'] = 'completed';
                      });
                    },
                    icon: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Đã xem xong',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
                if (status == 'completed' || status == 'cancelled') ...[
                  Text(
                    status == 'completed'
                        ? 'Đã hoàn tất xem phòng'
                        : 'Đã hủy lịch hẹn',
                    style: TextStyle(
                      fontSize: 12,
                      color: status == 'completed'
                          ? Colors.green[700]
                          : Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'confirmed':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        label = 'Đã xác nhận';
        break;
      case 'pending':
        bg = const Color(0xFFFFF3E0);
        text = const Color(0xFFE65100);
        label = 'Chờ xác nhận';
        break;
      case 'completed':
        bg = const Color(0xFFE0F2F1);
        text = const Color(0xFF00695C);
        label = 'Hoàn thành';
        break;
      case 'cancelled':
      default:
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        label = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
