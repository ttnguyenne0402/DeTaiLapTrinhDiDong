import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/owner_notification_service.dart';
import 'appointments_manage.dart';
import 'posts_manage.dart';
import 'maintenance_manage.dart';
import 'invoices_manage..dart';

class OwnerNotificationsScreen extends StatefulWidget {
  const OwnerNotificationsScreen({super.key});

  @override
  State<OwnerNotificationsScreen> createState() => _OwnerNotificationsScreenState();
}

class _OwnerNotificationsScreenState extends State<OwnerNotificationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';
  List<OwnerNotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await OwnerNotificationService.fetchNotifications('USER_OWNER_01');
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải thông báo: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải thông báo từ máy chủ SQL Server.';
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    try {
      await OwnerNotificationService.markAllAsRead('USER_OWNER_01');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu đã đọc tất cả thông báo'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {}
  }

  Future<void> _handleTapNotification(OwnerNotificationModel item) async {
    if (!item.isRead) {
      setState(() => item.isRead = true);
      try {
        await OwnerNotificationService.markAsRead(item.id);
      } catch (_) {}
    }

    if (!mounted) return;
    final String t = item.type.toLowerCase();

    if (t.contains('appointment')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AppointmentsManageScreen()),
      );
    } else if (t.contains('post')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostsManageScreen()),
      );
    } else if (t.contains('maintenance')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MaintenanceManageScreen()),
      );
    } else if (t.contains('invoice') || t.contains('payment')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Invoice_mana()),
      );
    }
  }

  List<OwnerNotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'appointment') {
      return _notifications.where((n) => n.type.toLowerCase().contains('appointment')).toList();
    } else if (_selectedFilter == 'post') {
      return _notifications.where((n) => n.type.toLowerCase().contains('post')).toList();
    } else if (_selectedFilter == 'other') {
      return _notifications
          .where((n) =>
              n.type.toLowerCase().contains('maintenance') ||
              n.type.toLowerCase().contains('invoice') ||
              n.type.toLowerCase().contains('payment'))
          .toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    final int unreadCount = _notifications.where((n) => !n.isRead).length;
    final list = _filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          unreadCount > 0 ? 'Thông báo ($unreadCount mới)' : 'Thông báo Chủ trọ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              tooltip: 'Đánh dấu đã đọc tất cả',
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Làm mới',
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9FB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Bộ lọc nhanh các loại thông báo
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  _buildFilterChip('all', 'Tất cả (${_notifications.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('unread', 'Chưa đọc ($unreadCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('appointment', 'Lịch hẹn xem phòng'),
                  const SizedBox(width: 8),
                  _buildFilterChip('post', 'Duyệt tin đăng'),
                  const SizedBox(width: 8),
                  _buildFilterChip('other', 'Bảo trì & Hóa đơn'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_off, size: 52, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red[400]),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _loadNotifications,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : list.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 56,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Không có thông báo nào trong mục này',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotifications,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(14),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  return _buildNotificationCard(list[index]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final bool selected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.primaryGreen,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.primaryGreen : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildNotificationCard(OwnerNotificationModel item) {
    final style = _getNotificationStyle(item.type);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        setState(() {
          _notifications.removeWhere((n) => n.id == item.id);
        });
        try {
          await OwnerNotificationService.deleteNotification(item.id);
        } catch (_) {}
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: item.isRead ? 0.5 : 2,
        color: item.isRead ? Colors.white : const Color(0xFFF1F8F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: item.isRead
                ? Colors.grey.shade200
                : AppColors.primaryGreen.withValues(alpha: 0.35),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleTapNotification(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, color: style.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: style.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              style.badgeLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: style.color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.time,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          if (!item.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            style.actionLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _NotifStyle _getNotificationStyle(String type) {
    final t = type.toLowerCase();
    if (t.contains('appointment_cancelled')) {
      return _NotifStyle(
        icon: Icons.event_busy_rounded,
        color: Colors.redAccent,
        badgeLabel: 'Khách hủy lịch hẹn',
        actionLabel: 'Xem lịch hẹn',
      );
    } else if (t.contains('appointment')) {
      return _NotifStyle(
        icon: Icons.calendar_month_rounded,
        color: Colors.blue.shade700,
        badgeLabel: 'Đặt lịch xem phòng',
        actionLabel: 'Xác nhận / Đổi giờ',
      );
    } else if (t.contains('post_rejected')) {
      return _NotifStyle(
        icon: Icons.unpublished_outlined,
        color: Colors.red.shade700,
        badgeLabel: 'Từ chối tin đăng',
        actionLabel: 'Chỉnh sửa tin đăng',
      );
    } else if (t.contains('post')) {
      return _NotifStyle(
        icon: Icons.verified_outlined,
        color: Colors.green.shade700,
        badgeLabel: 'Duyệt bài đăng',
        actionLabel: 'Xem quản lý tin',
      );
    } else if (t.contains('maintenance')) {
      return _NotifStyle(
        icon: Icons.build_circle_outlined,
        color: Colors.orange.shade800,
        badgeLabel: 'Báo hỏng / Bảo trì',
        actionLabel: 'Xử lý bảo trì',
      );
    } else if (t.contains('invoice') || t.contains('payment')) {
      return _NotifStyle(
        icon: Icons.payments_outlined,
        color: Colors.teal.shade700,
        badgeLabel: 'Thanh toán hóa đơn',
        actionLabel: 'Đối soát & Gạch nợ',
      );
    }
    return _NotifStyle(
      icon: Icons.notifications_active_outlined,
      color: AppColors.primaryGreen,
      badgeLabel: 'Hệ thống',
      actionLabel: 'Xem chi tiết',
    );
  }
}

class _NotifStyle {
  final IconData icon;
  final Color color;
  final String badgeLabel;
  final String actionLabel;

  _NotifStyle({
    required this.icon,
    required this.color,
    required this.badgeLabel,
    required this.actionLabel,
  });
}

