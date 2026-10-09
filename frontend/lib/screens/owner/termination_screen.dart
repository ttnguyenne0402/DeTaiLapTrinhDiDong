import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ContractLiquidationScreen extends StatefulWidget {
  const ContractLiquidationScreen({super.key});

  @override
  State<ContractLiquidationScreen> createState() =>
      _ContractLiquidationScreenState();
}

class _ContractLiquidationScreenState
    extends State<ContractLiquidationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Invoice Create',
          style: TextStyle(
            color: AppColors.cardSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 16,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // bo góc tròn 24px phía trên trái và phải
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // thanh tiến trình step tracker
              _buildStepTracker(),
              const SizedBox(height: 20),

              // thẻ thông tin hợp đồng & cọc
              _buildContractCard(),
              const SizedBox(height: 16),

              // phần kiểm tra hiện trạng bàn giao
              _buildInspectionSection(),
              const SizedBox(height: 16),

              // phần chốt chỉ số điện nước
              _buildUtilitySection(),
              const SizedBox(height: 16),

              // bảng quyết toán thanh lý
              _buildSettlementSummaryCard(),
              const SizedBox(height: 16),

              // thông tin chuyển khoản & bàn giao
              _buildTransferAndHandoverCard(),
              const SizedBox(height: 16),

              // phần chữ ký hai bên
              _buildSignatureSection(),
              const SizedBox(height: 24),

              // các nút hành động chính ở đáy
              _buildBottomActionButtons(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // thanh tiến trình 3 bước
  Widget _buildStepTracker() {
    return Row(
      children: [
        _buildStepItem(Icons.check, 'Nghiệm thu', true),
        Expanded(child: Container(height: 2, color: AppColors.primaryGreen)),
        _buildStepItem(Icons.check, 'Điện & Nước', true),
        Expanded(child: Container(height: 2, color: AppColors.primaryGreen)),
        _buildStepItem(Icons.grid_view, 'Quyết toán', true, isCurrent: true),
      ],
    );
  }

  Widget _buildStepItem(IconData icon, String label, bool isDone,
      {bool isCurrent = false}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isCurrent
              ? Colors.orange.shade700
              : (isDone ? AppColors.primaryGreen : Colors.grey.shade300),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Colors.orange.shade800 : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // thẻ thông tin hợp đồng và tiền cọc
  Widget _buildContractCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F382C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bookmark_outline, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Phòng 201',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Thanh lý hợp đồng',
                    style: TextStyle(color: Color(0xFFCBE2B5), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'HĐ #HD-2024-P201',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.lightGreen, size: 16),
              SizedBox(width: 6),
              Text('Nguyễn Văn An • 0908 123 456',
                  style: TextStyle(color: AppColors.lightGreen, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: AppColors.lightGreen, size: 16),
              SizedBox(width: 6),
              Text('01/09/2023 ➔ 31/08/2024 (12 tháng)',
                  style: TextStyle(color: AppColors.lightGreen, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tiền cọc gốc đang giữ:',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                Text('9.000.000 đ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // hạng mục kiểm tra bàn giao
  Widget _buildInspectionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1.5,
          color: Colors.grey.shade300,
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.archive_outlined, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text('Kiểm Tra Hiện Trạng Bàn Giao',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ],
              ),
              Text('4 hạng mục',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildInspectionItem(
            title: 'Giường & Nệm',
            subtitle: 'Đạt chuẩn, sạch sẽ, không rách',
            statusText: 'Bình thường',
            isWarning: false,
          ),
          const SizedBox(height: 8),
          _buildInspectionItem(
            title: 'Máy lạnh & Remote',
            subtitle: 'Làm lạnh tốt, remote đầy đủ pin',
            statusText: 'Bình thường',
            isWarning: false,
          ),
          const SizedBox(height: 8),
          _buildInspectionItem(
            title: 'Vỡ mặt kính tủ bếp',
            subtitle: 'Nứt vỡ góc phải do va đập',
            amount: '-500.000 đ',
            isWarning: true,
            hasImage: true,
          ),
          const SizedBox(height: 8),
          _buildInspectionItem(
            title: 'Vệ sinh phòng cuối kỳ',
            subtitle: 'Chưa tổng vệ sinh bàn giao sàn & WC',
            amount: '-200.000 đ',
            isWarning: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Thêm khoản bồi thường / khấu trừ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionItem({
    required String title,
    required String subtitle,
    String? statusText,
    String? amount,
    required bool isWarning,
    bool hasImage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF1F1) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: isWarning ? Colors.red : AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: isWarning ? Colors.red : AppColors.textSecondary)),
                  ],
                ),
              ),
              if (statusText != null)
                Text(statusText,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              if (amount != null)
                Text(amount,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
            ],
          ),
          if (hasImage) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 50,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Ảnh chụp biên bản 31/08/2024',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // phần chốt chỉ số điện nước
  Widget _buildUtilitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5
        )
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text('Chốt Chỉ Số Điện & Nước',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Kỳ cuối',
                    style: TextStyle(fontSize: 11, color: AppColors.primaryGreen)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUtilityRow(
              Icons.bolt, 'Điện sinh hoạt', '1.420 ➔ 1.475 kWh', '55 kWh × 3.800 đ', '-209.000 đ'),
          const SizedBox(height: 8),
          _buildUtilityRow(
              Icons.water_drop, 'Nước sinh hoạt', '85 ➔ 88 m³', '3 m³ × 25.000 đ', '-75.000 đ'),
          const SizedBox(height: 12),
          const Divider(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng tiền dịch vụ kỳ cuối:',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              Text('284.000 đ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityRow(IconData icon, String title, String detail,
      String calc, String amount) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
              Text(calc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // bảng quyết toán thanh lý
  Widget _buildSettlementSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text('Bảng Quyết Toán Thanh Lý',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Tiền đặt cọc ban đầu:', '+9.000.000 đ',
              isBold: true, color: AppColors.textPrimary),
          const SizedBox(height: 6),
          _buildSummaryRow('• Điện nước cuối kỳ:', '-284.000 đ', color: Colors.red),
          _buildSummaryRow('• Phí dọn phòng vệ sinh:', '-200.000 đ', color: Colors.red),
          _buildSummaryRow('• Khẩu trừ vỡ kính tủ bếp:', '-500.000 đ', color: Colors.red),
          const SizedBox(height: 8),
          _buildSummaryRow('Tổng các khoản trừ:', '-984.000 đ',
              isBold: true, color: Colors.red),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'TIỀN THỰC TẾ HOÀN TRẢ KHÁCH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '8.016.000 VNĐ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Đã đối soát đầy đủ mọi chi phí phát sinh',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textPrimary)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }

  // chuyển khoản & bàn giao
  Widget _buildTransferAndHandoverCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5
          )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Thông Tin Chuyển Khoản & Bàn Giao',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TÀI KHOẢN NHẬN LẠI CỌC (KHÁCH THUÊ)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code_2,
                          size: 16, color: AppColors.primaryGreen),
                      label: const Text(
                        'Mở mã QR',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.primaryGreen),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _BankInfoRow(label: 'Ngân hàng:', value: 'Techcombank'),
                const SizedBox(height: 4),
                const _BankInfoRow(label: 'Số tài khoản:', value: '190334888291'),
                const SizedBox(height: 4),
                const _BankInfoRow(label: 'Chủ tài khoản:', value: 'NGUYEN VAN AN'),
                const SizedBox(height: 4),
                const _BankInfoRow(label: 'Hạn hoàn tiền:', value: '31/08/2024'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.vpn_key_outlined,
                    color: AppColors.primaryGreen, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thu hồi chìa khóa & Thẻ từ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Đã nhận đủ 02 chìa khóa cổng chính + 01 thẻ từ xe máy tầng hầm.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // phần chữ ký hai bên
  Widget _buildSignatureSection() {
    return Row(
      children: [
        Expanded(child: _buildSignatureBox('Chủ nhà (Bên A)', 'Trần Thanh Trúc')),
        const SizedBox(width: 12),
        Expanded(child: _buildSignatureBox('Khách thuê (Bên B)', 'Nguyễn Văn An')),
      ],
    );
  }

  Widget _buildSignatureBox(String role, String name) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5
          )
      ),
      child: Column(
        children: [
          Text(role,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Text(name,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.primaryGreen, size: 14),
              SizedBox(width: 4),
              Text('Đã ký số',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }

  // nút xác nhận và xuất biên bản pdf
  Widget _buildBottomActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text('Xác nhận Hoàn Cọc & Ký Thanh Lý',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primaryGreen),
            label: const Text('Xuất biên bản PDF bàn giao',
                style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// widget hàng thông tin ngân hàng
class _BankInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _BankInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
      ],
    );
  }
}