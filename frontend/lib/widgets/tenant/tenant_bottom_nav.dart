import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class TenantBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const TenantBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  static const _items = [
    (Icons.home_rounded, 'Trang chủ'),
    (Icons.receipt_long_rounded, 'Hóa đơn'),
    (Icons.event_note_rounded, 'Đặt lịch'),
    (Icons.description_outlined, 'Hợp đồng'),
    (Icons.favorite_border_rounded, 'Yêu thích'),
    (Icons.person_outline_rounded, 'Cá nhân'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 68,
        child: BottomAppBar(
          color: const Color(0xFFF4EEF5),
          elevation: 12,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: InkWell(
                    onTap: () => onItemTapped(index),
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox.expand(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _items[index].$1,
                            size: 22,
                            color: selectedIndex == index
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _items[index].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selectedIndex == index
                                  ? AppColors.primaryGreen
                                  : AppColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: selectedIndex == index
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
