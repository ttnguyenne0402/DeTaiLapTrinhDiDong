import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../widgets/common/status_badge.dart';

class booking_history_screen extends StatefulWidget {
  const booking_history_screen({Key? key}) : super(key: key);

  @override
  State<booking_history_screen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<booking_history_screen> {

  final List<Map<String, dynamic>> mockAppointments = [
    {
      "id": "A01",
      "roomName": "Phòng 101",
      "address": "KDC Nhơn Đức, Xã Nhơn Đức, Huyện Nhà Bè",
      "date": "18/09/2026",
      "time": "14:30",
      "status": "pending",
      "message": "Mình đi làm về muộn, chủ nhà hỗ trợ chờ giúp mình nhé.",
      "ownerNote": null
    },
    {
      "id": "A02",
      "roomName": "Căn hộ mini Lê Trọng Tấn",
      "address": "Phường Tây Thạnh, Quận Tân Phú",
      "date": "20/09/2026",
      "time": "09:00",
      "status": "rescheduled",
      "message": "Hẹn xem buổi sáng.",
      "ownerNote": "Sáng anh đi vắng, em đổi sang 15:00 chiều cùng ngày được không?"
    },
    {
      "id": "A03",
      "roomName": "Phòng 205 KTX HUIT",
      "address": "140 Lê Trọng Tấn, Tân Phú",
      "date": "15/09/2026",
      "time": "18:00",
      "status": "confirmed",
      "message": "",
      "ownerNote": null
    },
    {
      "id": "A04",
      "roomName": "Phòng trọ sinh viên",
      "address": "Khu công nghiệp Tân Bình",
      "date": "10/09/2026",
      "time": "19:00",
      "status": "rejected",
      "message": "",
      "ownerNote": "Phòng vừa được cọc hồi chiều, mong bạn thông cảm."
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          'Lịch xem phòng của tôi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
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
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: mockAppointments.length,
        itemBuilder: (context, index) {
          final appointment = mockAppointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  // thẻ lịch hẹn
  Widget _buildAppointmentCard(Map<String, dynamic> data) {
    final status = data['status'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // tên phòng và trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['roomName'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: status), //trạng thái
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE5E7EB)),

            // thời gian
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  "${data['time']} - Ngày ${data['date']}",
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // địa chỉ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['address'],
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),

            // ghi chú
            if (data['message'] != null && data['message'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Lời nhắn: ${data['message']}",
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],

            // lời nhắn của chủ nhà (nếu trạng thái là từ chối hoặc đề xuất giờ khác)
            if (data['ownerNote'] != null && (status == 'rejected' || status == 'rescheduled')) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Chủ nhà: ${data['ownerNote']}",
                        style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // gọi hàm _buildActionButtons
            if (status == 'pending' || status == 'rescheduled') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(status),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // hàm xử lý nếu bị từ chối
  List<Widget> _buildActionButtons(String status) {
    if (status == 'pending') {
      return [
        OutlinedButton(
          onPressed: () {
            // gọi API PATCH /api/viewing-appointments/{id}/cancel
            print("Đã nhấn Hủy lịch");
          },
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Hủy lịch"),
        ),
      ];
    } else if (status == 'rescheduled') {
      return [
        OutlinedButton(
          onPressed: () {
            // gọi API từ chối giờ mới
          },
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Từ chối"),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            // gọi API chấp nhận giờ mới
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
          child: const Text("Đồng ý giờ mới", style: TextStyle(color: Colors.white)),
        ),
      ];
    }
    return [];
}
}