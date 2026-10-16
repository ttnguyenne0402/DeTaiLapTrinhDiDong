
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class BankAccountCard extends StatelessWidget {
  final Map<String, dynamic> account;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const BankAccountCard({
    super.key,
    required this.account,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = account['IsDefault'] == true;
    final bankName = account['BankName']?.toString() ?? '';
    final bankCode = account['BankCode']?.toString() ?? '';
    final accountNumber =
        account['AccountNumber']?.toString() ?? '';
    final accountHolder =
        account['AccountHolder']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault
              ? AppColors.primaryGreen
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankName.isNotEmpty ? bankName : bankCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (bankName.isNotEmpty && bankCode.isNotEmpty)
                      Text(
                        bankCode,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'default':
                      onSetDefault();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Sửa tài khoản'),
                  ),
                  if (!isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Đặt làm mặc định'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa tài khoản'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Số tài khoản: $accountNumber',
            style: const TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Chủ tài khoản: $accountHolder',
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          if (isDefault) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: 17,
                ),
                SizedBox(width: 6),
                Text(
                  'Tài khoản mặc định',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
