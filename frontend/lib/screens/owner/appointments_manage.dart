import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/owner_drawer.dart';
import '../../services/owner/appointment_service.dart';
import '../../services/auth_storage.dart';

class AppointmentsManageScreen extends StatefulWidget {
  const AppointmentsManageScreen({super.key});

  @override
  State<AppointmentsManageScreen> createState() =>
      _AppointmentsManageScreenState();
}

class _AppointmentsManageScreenState extends State<AppointmentsManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  // Tải danh sách lịch hẹn thực tế từ SQL Server qua Backend Web API
  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final ownerId = await AuthStorage.getUserId() ?? '';
      final list = await AppointmentService.fetchOwnerAppointments(ownerId);
      if (mounted) {
        setState(() {
          _appointments = list.map((a) => {
            'id': a.id,
            'name': a.name,
            'phone': a.phone,
            'roomInfo': a.roomInfo,
            'time': a.time,
            'date': a.date,
            'status': a.status,
            'note': a.note ?? 'Khách hẹn xem phòng trực tiếp',
            'avatar': a.avatar,
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải lịch hẹn từ API: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(
    Map<String, dynamic> item,
    String newStatus,
    String successMessage,
  ) async {
    final prevStatus = item['status'];
    setState(() => item['status'] = newStatus);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final success = await AppointmentService.updateAppointmentStatus(
        item['id'].toString(),
        newStatus,
      );

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await _loadAppointments();
      } else {
        setState(() => item['status'] = prevStatus);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Cập nhật lịch hẹn thất bại. Vui lòng kiểm tra kết nối!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi cập nhật lịch hẹn: $e');
      setState(() => item['status'] = prevStatus);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Lỗi kết nối máy chủ khi cập nhật lịch hẹn'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        .where((a) => a['status'] == 'cancelled' || a['status'] == 'rejected')
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Làm mới',
            onPressed: _loadAppointments,
          ),
        ],
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAppointments,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentList(upcoming),
                    _buildAppointmentList(completed),
                    _buildAppointmentList(cancelled),
                  ],
                ),
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
                    onPressed: () => _updateStatus(item, 'cancelled', 'Hủy lịch hẹn thành công'),
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
                    onPressed: () => _updateStatus(item, 'confirmed', 'Xác nhận lịch hẹn thành công'),
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
                    onPressed: () => _updateStatus(item, 'cancelled', 'Hủy lịch hẹn thành công'),
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
                    onPressed: () => _updateStatus(item, 'completed', 'Cập nhật xem phòng thành công'),
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
