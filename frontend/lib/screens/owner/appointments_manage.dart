import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/owner_drawer.dart';
import '../../services/owner/appointment_service.dart';
import 'contract_form.dart';

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

  // Tải danh sách lịch hẹn từ SQL Server qua API
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
            'roomId': a.roomId,
            'roomName': a.roomName,
            'propertyId': a.propertyId,
            'propertyName': a.propertyName,
            'propertyAddress': a.propertyAddress,
            'roomPrice': a.roomPrice,
            'roomDeposit': a.roomDeposit,
            'roomArea': a.roomArea,
            'roomInfo': a.roomInfo,
            'time': a.time,
            'rawTime': a.rawTime,
            'date': a.date,
            'status': a.status,
            'note': a.note ?? 'Khách hẹn xem phòng trực tiếp',
            'ownerNote': a.ownerNote,
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
    String successMessage, {
    String? ownerNote,
    String? newDate,
    String? newTime,
  }) async {
    final prevStatus = item['status'];
    setState(() => item['status'] = newStatus);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final success = await AppointmentService.updateAppointmentStatus(
        item['id'].toString(),
        newStatus,
        ownerNote: ownerNote,
        newDate: newDate,
        newTime: newTime,
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

  // Hộp thoại Từ chối lịch hẹn kèm lý do (Bận hoặc Hết phòng)
  Future<void> _showRejectDialog(Map<String, dynamic> item) async {
    final reasonController = TextEditingController();
    String selectedPreset = 'Chủ trọ bận khung giờ này';
    reasonController.text = selectedPreset;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Từ chối lịch xem phòng',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khách: ${item['name']} - ${item['roomInfo']}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chọn nhanh lý do:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Chủ trọ bận khung giờ này',
                    'Phòng đã hết / đã nhận cọc',
                    'Đang bảo trì phòng',
                  ].map((reason) {
                    final isSelected = selectedPreset == reason;
                    return ChoiceChip(
                      label: Text(reason, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      selectedColor: Colors.red.shade50,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.red.shade800 : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setDialogState(() {
                          selectedPreset = reason;
                          reasonController.text = reason;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Lý do từ chối gửi cho khách',
                    hintText: 'Nhập lý do từ chối...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Xác nhận từ chối',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final note = reasonController.text.trim().isEmpty
          ? 'Chủ trọ bận hoặc phòng đã hết'
          : reasonController.text.trim();
      await _updateStatus(
        item,
        'rejected',
        'Đã từ chối lịch hẹn và gửi thông báo cho khách thuê',
        ownerNote: note,
      );
    }
  }

  // Hộp thoại Đổi giờ hẹn mới kèm ghi chú OwnerNote
  Future<void> _showRescheduleDialog(Map<String, dynamic> item) async {
    DateTime selectedDate = DateTime.tryParse(item['date'] ?? '') ??
        DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 30);

    final rawTime = (item['rawTime'] ?? '').toString();
    if (rawTime.contains(':')) {
      final parts = rawTime.split(':');
      final h = int.tryParse(parts[0]) ?? 9;
      final m = int.tryParse(parts[1]) ?? 30;
      selectedTime = TimeOfDay(hour: h, minute: m);
    }

    final noteController = TextEditingController(
      text: item['ownerNote']?.toString() ??
          'Khung giờ cũ mình bận, bạn xem giúp mình giờ mới này nhé!',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final formattedDate =
              '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
          final formattedTime =
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Đề xuất đổi giờ xem phòng',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khách: ${item['name']}\n${item['roomInfo']}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ngày & giờ mới đề xuất:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(formattedDate, style: const TextStyle(fontSize: 13)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(formattedTime, style: const TextStyle(fontSize: 13)),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setDialogState(() => selectedTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú gửi khách (OwnerNote)',
                      hintText: 'Nhập lời nhắn đề xuất đổi lịch...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Gửi đề xuất đổi giờ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      final apiDate =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      final apiTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      await _updateStatus(
        item,
        'rescheduled',
        'Đã gửi đề xuất đổi giờ xem phòng cho khách thuê',
        ownerNote: noteController.text.trim(),
        newDate: apiDate,
        newTime: apiTime,
      );
    }
  }

  String _formatVndNumber(double value) {
    final intVal = value.toInt().toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return intVal.replaceAllMapped(reg, (m) => '.');
  }

  // Mở thẳng form Tạo hợp đồng (Contract_form) với thông tin khách và phòng điền sẵn
  void _openCreateContract(Map<String, dynamic> item) {
    final double rentVal = (item['roomPrice'] as num?)?.toDouble() ?? 3500000;
    final double depositVal = (item['roomDeposit'] as num?)?.toDouble() ?? rentVal;
    final String formattedRent = _formatVndNumber(rentVal);
    final String formattedDeposit = _formatVndNumber(depositVal);

    final String propName = (item['propertyName'] ?? '').toString();
    final String propAddr = (item['propertyAddress'] ?? '').toString();
    final String fullAddress = propAddr.isNotEmpty
        ? '$propName - $propAddr'
        : (propName.isNotEmpty ? propName : 'Khu trọ An Khang');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Contract_form(
          contract: {
            'tenantName': item['name'] ?? '',
            'tenantPhone': item['phone'] ?? '',
            'room': item['roomInfo'] ?? '',
            'propertyName': propName.isNotEmpty ? propName : item['roomInfo'],
            'address': fullAddress,
            'rentPrice': formattedRent,
            'depositPrice': formattedDeposit,
            'area': item['roomArea'] != null ? item['roomArea'].toString() : '25',
            'appointmentInfo':
                '#${item['id']} - ${item['name']} (${item['time']})',
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _appointments
        .where((a) =>
            a['status'] == 'pending' ||
            a['status'] == 'confirmed' ||
            a['status'] == 'rescheduled')
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
            Tab(text: 'Chờ xác nhận / Sắp tới (${upcoming.length})'),
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
    final String status = item['status'] ?? 'pending';

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
                      if ((item['phone'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'SĐT: ${item['phone']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đang gọi số ${item['phone']}...'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
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
                  'Ghi chú khách: ${item['note']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
            if (item['ownerNote'] != null &&
                item['ownerNote'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  'Phản hồi chủ trọ: ${item['ownerNote']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status == 'pending' || status == 'rescheduled') ...[
                  OutlinedButton(
                    onPressed: () => _showRejectDialog(item),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Từ chối',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showRescheduleDialog(item),
                    icon: const Icon(Icons.schedule, size: 15, color: Colors.orange),
                    label: const Text(
                      'Đổi giờ',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _updateStatus(
                      item,
                      'confirmed',
                      'Đã xác nhận lịch hẹn và gửi thông báo cho khách',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    onPressed: () => _showRejectDialog(item),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Từ chối / Hủy',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showRescheduleDialog(item),
                    icon: const Icon(Icons.schedule, size: 15, color: Colors.orange),
                    label: const Text(
                      'Đổi giờ',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(
                      item,
                      'completed',
                      'Đã xác nhận khách xem phòng xong',
                    ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
                if (status == 'completed') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã hoàn tất xem phòng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openCreateContract(item),
                        icon: const Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Lập hợp đồng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (status == 'cancelled' || status == 'rejected') ...[
                  Text(
                    status == 'rejected'
                        ? 'Đã từ chối lịch hẹn'
                        : 'Đã hủy lịch hẹn',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
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
      case 'rescheduled':
        bg = const Color(0xFFE3F2FD);
        text = const Color(0xFF1565C0);
        label = 'Chờ khách duyệt giờ mới';
        break;
      case 'completed':
        bg = const Color(0xFFE0F2F1);
        text = const Color(0xFF00695C);
        label = 'Hoàn thành';
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        label = 'Đã từ chối';
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
