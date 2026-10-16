import 'package:flutter/material.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import '../../core/constants/app_colors.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final Function(DateTime) onDateSelected;
  final Function(TimeOfDay) onTimeSelected;

  const CalendarWidget({
    Key? key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateSelected,
    required this.onTimeSelected,
  }) : super(key: key);

 //chọn ngày
  Future<void> _pickDate(BuildContext context) async {
    // lấy tọa độ của nút bấm để hiển thị popup lịch cho chuẩn
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final DateTime now = DateTime.now();

    final DateTime? picked = await showCupertinoCalendarPicker(
      context,
      widgetRenderBox: renderBox,
      initialDateTime: selectedDate ?? now,
      minimumDateTime: now,
      maximumDateTime: now.add(const Duration(days: 60)),
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  // chọn giờ
  Future<void> _pickTime(BuildContext context) async {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;

    final TimeOfDay? picked = await showCupertinoTimePicker(
      context,
      widgetRenderBox: renderBox,
      initialTime: selectedTime ?? TimeOfDay.now(),
      use24hFormat: true,
    );

    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Expanded(
          child: Builder(
              builder: (buttonContext) {
                return _buildPickerButton(
                  context: buttonContext,
                  title: "Ngày xem phòng",
                  value: selectedDate != null
                      ? "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}"
                      : "Chọn ngày",
                  icon: Icons.calendar_month_outlined,
                  onTap: () => _pickDate(buttonContext),
                  hasValue: selectedDate != null,
                );
              }
          ),
        ),
        const SizedBox(width: 16),

        Expanded(
          child: Builder(
              builder: (buttonContext) {
                return _buildPickerButton(
                  context: buttonContext,
                  title: "Giờ dự kiến",
                  value: selectedTime != null
                      ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
                      : "Chọn giờ",
                  icon: Icons.access_time_outlined,
                  onTap: () => _pickTime(buttonContext),
                  hasValue: selectedTime != null,
                );
              }
          ),
        ),
      ],
    );
  }


  Widget _buildPickerButton({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasValue ? AppColors.primaryGreen : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                Icon(
                  icon,
                  color: hasValue ? AppColors.primaryGreen : AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}