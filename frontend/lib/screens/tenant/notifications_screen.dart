import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../widgets/tenant/notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  List<Map<String, dynamic>> dummyNotifications = [
    {
      'id': 'NOTIF-001',
      'title': 'Hóa đơn tháng 10/2026 đã được tạo',
      'message': 'Chủ nhà vừa phát hành hóa đơn mới. Vui lòng kiểm tra và thanh toán trước ngày 05/10/2026.',
      'type': 'invoice',
      'read_at': null,
      'created_at': '10 phút trước',
    },
    {
      'id': 'NOTIF-002',
      'title': 'Lịch hẹn xem phòng đã được duyệt',
      'message': 'Chủ nhà đã đồng ý lịch xem phòng 101 vào lúc 09:00 ngày 20/09/2026. Vui lòng đến đúng giờ.',
      'type': 'viewing_appointment',
      'read_at': null,
      'created_at': '2 giờ trước',
    },
    {
      'id': 'NOTIF-003',
      'title': 'Cập nhật sự cố sửa chữa',
      'message': 'Yêu cầu "Hư ống nước nhà vệ sinh" của bạn đang được xử lý (Processing). Thợ sẽ đến trong chiều nay.',
      'type': 'maintenance',
      'read_at': '2026-09-28 14:00:00',
      'created_at': 'Hôm qua',
    },
    {
      'id': 'NOTIF-004',
      'title': 'Hợp đồng thuê phòng sắp hết hạn',
      'message': 'Hợp đồng phòng 202 của bạn sẽ hết hạn vào ngày 30/10/2026. Vui lòng liên hệ Chủ nhà nếu muốn gia hạn.',
      'type': 'contract',
      'read_at': '2026-09-25 09:00:00',
      'created_at': '5 ngày trước',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'THÔNG BÁO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {

              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                    (route) => false,
              );
            }
          },
        ),
        actions: [

          IconButton(
            icon: const Icon(Icons.checklist, color: Colors.white),
            tooltip: 'Đánh dấu đã đọc tất cả',
            onPressed: () {
              setState(() {
                for (var notif in dummyNotifications) {
                  notif['read_at'] = DateTime.now().toString();
                }
              });
            },
          ),
        ],
      ),
      body: dummyNotifications.isEmpty
          ? const Center(
        child: Text(
          'Bạn không có thông báo nào.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      )
          : ListView.separated(
        itemCount: dummyNotifications.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: AppColors.lightGreen,
        ),
        itemBuilder: (context, index) {
          final notif = dummyNotifications[index];
          return NotificationItem(
            notificationData: notif,
            onTap: () {

              if (notif['read_at'] == null) {
                setState(() {
                  notif['read_at'] = DateTime.now().toString();
                });
              }


              switch (notif['type']) {
                case 'invoice':
                  Navigator.pushNamed(context, '/tenant/invoices/detail');
                  break;
                case 'viewing_appointment':
                  Navigator.pushNamed(context, '/tenant/booking-history');
                  break;
                case 'contract':
                  Navigator.pushNamed(context, '/tenant/contracts/detail');
                  break;

              // MAINTENANCE SẼ DO TV4 LÀM NÊN TẠM THỜI CHƯA CÓ ROUTE CỤ THỂ CỦA TENANT
              }

              // TUẦN 7 VIẾT LỆNH ĐIỀU HƯỚNG

            },
          );
        },
      ),
    );
  }
}