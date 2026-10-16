import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    Color backgroundColor;
    Color textColor;
    String displayText;


    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        displayText = 'ĐANG CHỜ';
        break;
      case 'confirmed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        displayText = 'ĐÃ XÁC NHẬN';
        break;
      case 'rescheduled':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        displayText = 'ĐỀ XUẤT GIỜ KHÁC';
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        displayText = 'TỪ CHỐI';
        break;
      case 'cancelled':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        displayText = 'ĐÃ HỦY';
        break;
      case 'completed':
        backgroundColor = Colors.teal.shade100;
        textColor = Colors.teal.shade800;
        displayText = 'ĐÃ XEM PHÒNG';
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        displayText = 'KHÔNG RÕ';
    }


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}