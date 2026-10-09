import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ContractFormWidgets {

  // 1. Widget khung
  static Widget buildSectionCard({
    required String step,
    required String title,
    required String subtitle,
    required Widget content
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(5)),
                child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryGreen)),
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          content,
        ],
      ),
    );
  }

  // 2. Widget TextField
  static Widget buildTextField(
      String label,
      String initialValue,
      bool isTrue, {
        IconData? suffixIcon,
        String? suffixText
      }) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,// là nếu kh rỗng thì nó được đưa lên trên
        fillColor: isTrue ? AppColors.lightGreen : Colors.white,
        filled: true,
        labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: isTrue ? BorderSide.none : BorderSide(color: Colors.grey.shade100),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 16, color: AppColors.textSecondary) : null,
        suffixText: suffixText,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: isTrue ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
      ),
    );
  }

  // 3. Widget Dropdown giả lập giao diện
  static Widget buildDropdownField(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        color: AppColors.lightGreen,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
          const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  // 4. Widget dòng dịch vụ
  static Widget buildServiceRow(IconData icon, String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
          Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // 5. Widget hiển thị quy định điều khoản
  static Widget buildRuleItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.accentYellow),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
              children: [
                TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: desc, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}