import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// Widget tạo nút Filter nhỏ
Widget buildFilterChip(String label, int index, int selectedIndex, Function(int) onSelected) {
  bool isSelected = selectedIndex == index;
  return ChoiceChip(
    label: Text(label),
    selected: isSelected,
    onSelected: (bool selected) {
      onSelected(index);
    },
    selectedColor: AppColors.primaryGreen,
    backgroundColor: Colors.white,
    labelStyle: TextStyle(
      fontSize: 11,
      color: isSelected ? Colors.white : AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
    ),
  );
}

// Widget khung Card Hóa Đơn dùng chung
Widget buildInvoiceCard({
  required String room,
  required String roomCode,
  required String tenantName,
  required String tenantPhone,
  bool isRoomOnlyTitle = false,
  required String statusText,
  required Color statusColor,
  required Color statusTextColor,
  required IconData statusIcon,
  required Widget contentWidget,
  required List<Widget> actions,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(6)),
                  child: Text(room, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryGreen)),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isRoomOnlyTitle
                        ? Row(
                      children: [
                        Text('Phòng $room', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(width: 6),
                        Text(roomCode, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    )
                        : Text('Phòng $room', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    if (!isRoomOnlyTitle) Text(roomCode, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  Icon(statusIcon, size: 12, color: statusTextColor),
                  const SizedBox(width: 4),
                  Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusTextColor)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            isRoomOnlyTitle ? 'Khách: $tenantName' : '$tenantName • $tenantPhone',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 8),
        contentWidget,
        const SizedBox(height: 10),
        Row(children: actions),
      ],
    ),
  );
}