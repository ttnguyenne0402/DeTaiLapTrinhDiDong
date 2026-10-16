import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PaymentScreen extends StatefulWidget {
  final String invoiceCode;
  final double amountToPay;

  const PaymentScreen({
    super.key,
    this.invoiceCode = 'INV-202610-001',
    this.amountToPay = 3380000,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {

  String _selectedMethod = 'qr';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'THANH TOÁN HÓA ĐƠN',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      // NÚT XÁC NHẬN
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                _showSuccessDialog();
              },
              child: const Text(
                'XÁC NHẬN ĐÃ THANH TOÁN',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // THẺ SỐ TIỀN CẦN THANH TOÁN
            Container(
              color: AppColors.primaryGreen,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Card(
                color: AppColors.cardSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        'SỐ TIỀN CẦN THANH TOÁN (${widget.invoiceCode})',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_formatCurrency(widget.amountToPay)} đ',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // CHỌN PHƯƠNG THỨC THANH TOÁN
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHỌN PHƯƠNG THỨC THANH TOÁN',
                    style: TextStyle(color: AppColors.primaryGreen, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // QUÉT MÃ VÀ TIỀN MẶT
                  Card(
                    color: AppColors.cardSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: Column(
                      children: [
                        _buildPaymentOption('qr', 'Quét mã QR Pay', Icons.qr_code_scanner),
                        const Divider(height: 1, indent: 50),
                        _buildPaymentOption('cash', 'Tiền mặt (Đưa trực tiếp)', Icons.money),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // HIỂN THỊ THÔNG TIN CHI TIẾT THEO PHƯƠNG THỨC
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildPaymentDetails(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // RADIO CHỌN PHƯƠNG THỨC
  Widget _buildPaymentOption(String methodValue, String title, IconData icon) {

    bool isSelected = _selectedMethod == methodValue;

    return ListTile(

      onTap: () {
        setState(() {
          _selectedMethod = methodValue;
        });
      },
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
        ),
      ),

      trailing: isSelected
          ? const Icon(Icons.radio_button_checked, color: AppColors.primaryGreen)
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
    );
  }

  // HIỂN THỊ NỘI DUNG
  Widget _buildPaymentDetails() {
    switch (_selectedMethod) {
      case 'qr':
        return _buildInfoCard(
          key: const ValueKey('qr'),
          title: 'MÃ QR THANH TOÁN TỰ ĐỘNG',
          children: [
            const Center(
              child: Icon(Icons.qr_code_2, size: 150, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            // NỘI DUNG HÓA ĐƠN
            _buildDetailRow('Nội dung tự động:', 'Thanh toan ${widget.invoiceCode}', isHighlight: true),
            const SizedBox(height: 8),
            const Center(
              child: Text('Dùng ứng dụng ngân hàng để quét mã', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        );
      case 'cash':
        return _buildInfoCard(
          key: const ValueKey('cash'),
          title: 'HƯỚNG DẪN ĐÓNG TIỀN MẶT',
          children: [
            const Text(
              'Vui lòng gặp trực tiếp Ban quản lý hoặc Chủ nhà để đóng tiền mặt. Sau khi đóng, Chủ nhà sẽ cập nhật trạng thái hóa đơn trên hệ thống.',
              style: TextStyle(color: AppColors.textPrimary, height: 1.5),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }


  Widget _buildInfoCard({required Key key, required String title, required List<Widget> children}) {
    return Card(
      key: key,
      color: AppColors.lightGreen.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightGreen, width: 2),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }


  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? AppColors.primaryGreen : AppColors.textPrimary,
                fontSize: isHighlight ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 60),
          content: Text(
            _selectedMethod == 'cash'
                ? 'Đã gửi yêu cầu xác nhận thanh toán tiền mặt đến Chủ nhà. Trạng thái giao dịch đang là "Chờ duyệt" (Pending).'
                : 'Hệ thống đang kiểm tra trạng thái giao dịch quét mã QR...',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('ĐÓNG', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // FORMAT TIỀN TỆ
  String _formatCurrency(double amount) {
    String result = amount.toInt().toString();
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return result;
  }
}