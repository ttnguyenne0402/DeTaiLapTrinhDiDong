import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';

class PaymentScreen extends StatefulWidget {
  final String invoiceId;
  final String invoiceCode;
  final double amountToPay;

  const PaymentScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceCode,
    required this.amountToPay,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'qr';
  bool _isSubmitting = false;

  // Giả lập ID người thuê hiện tại
  final String _currentTenantId = 'TENANT01';

  // Khởi tạo Custom Client bỏ qua SSL
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  // HÀM XỬ LÝ THANH TOÁN CHUNG CHO CẢ 2 PHƯƠNG THỨC
  Future<void> _submitPayment() async {
    setState(() => _isSubmitting = true);

    final requestData = {
      "invoiceId": widget.invoiceId,
      "payerId": _currentTenantId,
      "amount": widget.amountToPay,
      "method": _selectedMethod //
    };

    final client = _getCustomClient();
    try {
      final response = await client.post(
        Uri.parse('https://10.0.2.2:7203/api/payments'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // NẾU LÀ VNPay VÀ CÓ TRẢ VỀ LINK
        if (responseData['paymentUrl'] != null && responseData['paymentUrl'].toString().isNotEmpty) {
          final Uri url = Uri.parse(responseData['paymentUrl']);

          try {

            await launchUrl(url, mode: LaunchMode.inAppBrowserView);

            if (mounted) {
              _showSuccessDialog('Hệ thống đang chờ bạn hoàn tất giao dịch quét mã QR trên trình duyệt...');
            }
          } catch (e) {
            _showErrorSnackBar("Không thể mở trang thanh toán VNPay.");
          }
        }
        // NẾU LÀ TIỀN MẶT
        else {
          _showSuccessDialog('Đã gửi yêu cầu xác nhận thanh toán tiền mặt đến Chủ nhà. Trạng thái giao dịch đang là "Chờ duyệt" (Pending).');
        }
      } else {
        // Xử lý lỗi trả về từ server (ví dụ 400 Bad Request)
        print("Lỗi server: ${response.body}");
        _showErrorSnackBar("Giao dịch thất bại. Hóa đơn có thể không hợp lệ hoặc đã được thanh toán.");
      }
    } catch (e) {
      print("Lỗi kết nối API: $e");
      _showErrorSnackBar("Không thể kết nối đến máy chủ. Vui lòng thử lại sau.");
    } finally {
      client.close();
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 60),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();

                Navigator.of(context).pop();
              },
              child: const Text('ĐÓNG VÀ QUAY LẠI', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'THANH TOÁN HÓA ĐƠN',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      // NÚT XÁC NHẬN ĐÃ TÍCH HỢP LOADING VÀ GỌI HÀM
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submitPayment,
                child: _isSubmitting
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                  'XÁC NHẬN THANH TOÁN',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),

      body: Column(
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

          // PHẦN CHỌN PHƯƠNG THỨC THANH TOÁN
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SingleChildScrollView(
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
                            _buildPaymentOption('qr', 'Quét mã QR Pay (VNPay)', Icons.qr_code_scanner),
                            const Divider(height: 1, indent: 50),
                            _buildPaymentOption('cash', 'Tiền mặt (Đưa trực tiếp)', Icons.money),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildPaymentDetails(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildPaymentDetails() {
    switch (_selectedMethod) {
      case 'qr':
        return _buildInfoCard(
          key: const ValueKey('qr'),
          title: 'MÃ QR THANH TOÁN QUA VNPAY',
          children: [
            const Center(
              child: Icon(Icons.security, size: 80, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Hệ thống sẽ tự động chuyển hướng bạn đến cổng thanh toán bảo mật của VNPay. Vui lòng chuẩn bị ứng dụng ngân hàng hoặc thẻ ATM.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, height: 1.5),
              ),
            ),
          ],
        );
      case 'cash':
        return _buildInfoCard(
          key: const ValueKey('cash'),
          title: 'HƯỚNG DẪN ĐÓNG TIỀN MẶT',
          children: [
            const Text(
              'Vui lòng gặp trực tiếp Ban quản lý hoặc Chủ nhà để đóng tiền mặt. Sau khi bấm xác nhận bên dưới, hệ thống sẽ gửi yêu cầu chờ duyệt đến Chủ nhà.',
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
      color: AppColors.lightGreen.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightGreen, width: 2),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    String result = amount.toInt().toString();
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return result;
  }
}