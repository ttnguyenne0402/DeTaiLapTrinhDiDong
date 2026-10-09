
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ProfileInfoCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;

  const ProfileInfoCard({
    super.key,
    required this.user,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['Name']?.toString() ?? 'Người dùng';
    final email = user['Email']?.toString() ?? '';
    final phone = user['Phone']?.toString() ?? '';
    final avatar = user['Avatar']?.toString() ?? '';

    final hasAvatar =
        avatar.startsWith('https://') ||
        avatar.startsWith('http://');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.lightGreen,
            backgroundImage:
                hasAvatar ? NetworkImage(avatar) : null,
            child: hasAvatar
                ? null
                : const Icon(
                    Icons.person_outline,
                    size: 44,
                    color: AppColors.primaryGreen,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Sửa thông tin'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(
                color: AppColors.primaryGreen,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
