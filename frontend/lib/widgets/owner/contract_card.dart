import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ContractCard extends StatelessWidget {
  final String room;              // Tên phòng và vị trí tầng
  final String address;           // Địa chỉ hoặc thông tin khu trọ
  final String status;            // Tên trạng thái của hợp đồng
  final Color statusBgColor;      // Màu nền của nhãn trạng thái
  final Color statusTextColor;    // Màu chữ của nhãn trạng thái
  final String code;              // Mã định danh hợp đồng
  final String timeText;          // Văn bản hiển thị thời gian còn lại/đã quá hạn
  final Color timeColor;          // Màu chữ hiển thị thời gian
  final String tenantName;        // Tên người thuê
  final String tenantPhone;       // Số điện thoại người thuê
  final String rentPrice;         // Giá tiền thuê phòng
  final String depositPrice;      // Số tiền cọc
  final String? duration;         // Thời hạn hợp đồng (có thể trống)
  final String? cycleText;        // Thông tin kỳ thu tiền (có thể trống)
  final String? noteText;         // Ghi chú phụ/thông tin người ở ghép (có thể trống)
  final String primaryBtnText;    // Tên nút hành động chính
  final Color primaryBtnColor;    // Màu nền nút hành động chính
  final VoidCallback? onTapDetail;     // Sự kiện khi bấm nút "Xem chi tiết"
  final VoidCallback? onTapPrimaryBtn; // Sự kiện khi bấm nút hành động chính

  const ContractCard({
    super.key,
    required this.room,
    required this.address,
    required this.status,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.code,
    required this.timeText,
    required this.timeColor,
    required this.tenantName,
    required this.tenantPhone,
    required this.rentPrice,
    required this.depositPrice,
    this.duration,
    this.cycleText,
    this.noteText,
    required this.primaryBtnText,
    required this.primaryBtnColor,
    this.onTapDetail,
    this.onTapPrimaryBtn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.apartment, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    room,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              address,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: status == 'Sắp hết hạn' ? Colors.red.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.subtitles,
                      size: 16,
                      color: status == 'Sắp hết hạn' ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: status == 'Sắp hết hạn' ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  timeText,
                  style: TextStyle(
                    color: timeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenantName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      tenantPhone,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.phone, size: 16, color: Colors.green),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tiền thuê', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  Text(
                    rentPrice,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tiền cọc', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  Text(
                    depositPrice,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),

          if (duration != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(duration!, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                if (cycleText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cycleText!,
                      style: TextStyle(
                        fontSize: 11,
                        color: status == 'Sắp hết hạn' ? Colors.red : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (noteText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    noteText!,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTapDetail,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Xem chi tiết', style: TextStyle(color: Colors.black87, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onTapPrimaryBtn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBtnColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    primaryBtnText,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}