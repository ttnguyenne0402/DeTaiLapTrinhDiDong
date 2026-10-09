import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';

//DỮ LIỆU GIẢ
class InvoiceMock {
  final String invoiceCode;
  final String billingMonth;
  final String issueDate;
  final String dueDate;
  final double subtotal;
  final double discount;
  final double total;
  final String status;

  InvoiceMock({
    required this.invoiceCode,
    required this.billingMonth,
    required this.issueDate,
    required this.dueDate,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
  });
}

class MyInvoicesScreen extends StatefulWidget {
  const MyInvoicesScreen({super.key});

  @override
  State<MyInvoicesScreen> createState() => _MyInvoicesScreenState();
}

class _MyInvoicesScreenState extends State<MyInvoicesScreen> {

  final List<InvoiceMock> dummyInvoices = [
    InvoiceMock(
      invoiceCode: 'INV-202610-001',
      billingMonth: '10/2026',
      issueDate: '25/09/2026',
      dueDate: '05/10/2026',
      subtotal: 3500000,
      discount: 0,
      total: 3500000,
      status: 'unpaid',
    ),
    InvoiceMock(
      invoiceCode: 'INV-202609-001',
      billingMonth: '09/2026',
      issueDate: '25/08/2026',
      dueDate: '05/09/2026',
      subtotal: 3500000,
      discount: 50000,
      total: 3450000,
      status: 'paid',
    ),
    InvoiceMock(
      invoiceCode: 'INV-202608-001',
      billingMonth: '08/2026',
      issueDate: '25/07/2026',
      dueDate: '05/08/2026',
      subtotal: 3500000,
      discount: 0,
      total: 3500000,
      status: 'overdue',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // TÍNH TỔNG NỢ
    double totalDebt = dummyInvoices
        .where((inv) => inv.status == 'unpaid' || inv.status == 'overdue')
        .fold(0, (sum, item) => sum + item.total);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Hóa đơn & Thanh toán',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {

              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                    (route) => false,
              );
            }
          },
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // THẺ DƯ NỢ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: AppColors.primaryGreen,
            child: Card(
              color: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Column(
                  children: [
                    const Text(
                      'TỔNG DƯ NỢ HIỆN TẠI',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatCurrency(totalDebt)} đ',
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          //  DANH SÁCH LỊCH SỬ HÓA ĐƠN
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            child: const Text(
              'LỊCH SỬ HÓA ĐƠN',
              style: TextStyle(color: AppColors.primaryGreen, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: dummyInvoices.length,
              itemBuilder: (context, index) {
                final invoice = dummyInvoices[index];
                return _buildInvoiceCard(invoice);
              },
            ),
          ),
        ],
      ),
    );
  }

  //HÀM BUILD TỪNG CARD HÓA ĐƠN
  Widget _buildInvoiceCard(InvoiceMock invoice) {

    final statusUI = _getStatusUI(invoice.status);

    return Card(
      color: AppColors.cardSurface,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // CHUYỂN SANG MÀN HÌNH CHI TIẾT HÓA ĐƠN
          Navigator.pushNamed(context, '/tenant/invoices/detail');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TIÊU ĐỀ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kỳ ${invoice.billingMonth}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusUI['bgColor'], borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      statusUI['text'],
                      style: TextStyle(color: statusUI['textColor'], fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: AppColors.lightGreen),

              // THÔNG TIN
              _buildRow('Mã hóa đơn:', invoice.invoiceCode),
              _buildRow('Ngày phát hành:', invoice.issueDate),
              _buildRow('Hạn thanh toán:', invoice.dueDate, isWarning: invoice.status == 'overdue'),

              if (invoice.discount > 0) // GIẢM GIÁ
                _buildRow('Giảm giá:', '- ${_formatCurrency(invoice.discount)} đ', color: Colors.green),

              const SizedBox(height: 8),
              // TỔNG TIỀN THANH TOÁN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng cộng:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${_formatCurrency(invoice.total)} đ',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HÀM TIỆN ÍCH DÙNG CHO THÔNG TIN TRÊN CARD
  Widget _buildRow(String label, String value, {bool isWarning = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: color ?? (isWarning ? Colors.redAccent : AppColors.textPrimary),
              fontSize: 14,
              fontWeight: isWarning ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  //HÀM ĐỔI E SANG VI
  Map<String, dynamic> _getStatusUI(String status) {
    switch (status) {
      case 'paid':
        return {'text': 'Đã thanh toán', 'bgColor': AppColors.lightGreen, 'textColor': AppColors.primaryGreen};
      case 'unpaid':
        return {'text': 'Chưa thanh toán', 'bgColor': Colors.orange.shade100, 'textColor': Colors.orange.shade800};
      case 'overdue':
        return {'text': 'Quá hạn', 'bgColor': Colors.red.shade100, 'textColor': Colors.red.shade800};
      case 'pending':
        return {'text': 'Đang chờ duyệt', 'bgColor': Colors.blue.shade100, 'textColor': Colors.blue.shade800};
      case 'cancelled':
        return {'text': 'Đã hủy', 'bgColor': Colors.grey.shade200, 'textColor': AppColors.textSecondary};
      default:
        return {'text': 'Không xác định', 'bgColor': Colors.grey.shade200, 'textColor': AppColors.textSecondary};
    }
  }

  // HÀM ĐỔI TIỀN CHO ĐẸP
  String _formatCurrency(double amount) {

    String result = amount.toInt().toString();
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return result;
  }
}