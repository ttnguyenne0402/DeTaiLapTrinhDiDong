import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notificationData;
  final VoidCallback onTap;

  const NotificationItem({
    super.key,
    required this.notificationData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final bool isRead = notificationData['read_at'] != null;


    IconData getIcon() {
      switch (notificationData['type']) {
        case 'invoice':
          return Icons.receipt_long;
        case 'viewing_appointment':
          return Icons.calendar_month;
        case 'maintenance':
          return Icons.build;
        case 'contract':
          return Icons.description;
        default:
          return Icons.notifications;
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(

        color: isRead ? AppColors.cardSurface : AppColors.lightGreen.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            CircleAvatar(
              backgroundColor: isRead ? Colors.grey.shade200 : AppColors.primaryGreen.withValues(alpha: 0.15),
              radius: 24,
              child: Icon(
                getIcon(),
                color: isRead ? Colors.grey.shade600 : AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 16),


            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificationData['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notificationData['message'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notificationData['created_at'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),


            if (!isRead)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 8.0),
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: Colors.redAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}