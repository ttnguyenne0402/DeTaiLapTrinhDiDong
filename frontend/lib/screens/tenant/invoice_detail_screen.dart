import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';

//DỮ LIỆU GIẢ

class InvoiceItemMock {
  final String type;
  final String description;
  final double quantity;
  final double unitPrice;
  final double amount;

  InvoiceItemMock({
    required this.type,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });
}


class InvoiceDetailMock {
  final String invoiceCode;
  final String billingMonth;
  final String dueDate;
  final double discount;
  final double total;
  final String status;
  final List<InvoiceItemMock> items;

  InvoiceDetailMock({
    required this.invoiceCode,
    required this.billingMonth,
    required this.dueDate,
    required this.discount,
    required this.total,
    required this.status,
    required this.items,
  });
}

class InvoiceDetailScreen extends StatelessWidget {
  InvoiceDetailScreen({super.key});


  final InvoiceDetailMock invoiceDetail = InvoiceDetailMock(
    invoiceCode: 'INV-202610-001',
    billingMonth: '10/2026',
    dueDate: '05/10/2026',
    discount: 50000,
    total: 3380000,
    status: 'unpaid',
    items: [
      InvoiceItemMock(
        type: 'rent',
        description: 'Tiền thuê phòng (1 tháng)',
        quantity: 1,
        unitPrice: 2800000,
        amount: 2800000,
      ),
      InvoiceItemMock(
        type: 'electricity',
        description: 'Điện (Từ 1250 đến 1350)',
        quantity: 100,
        unitPrice: 3500,
        amount: 350000,
      ),
      InvoiceItemMock(
        type: 'water',
        description: 'Nước (Từ 105 đến 115)',
        quantity: 10,
        unitPrice: 20000,
        amount: 200000,
      ),
      InvoiceItemMock(
        type: 'service',
        description: 'Rác sinh hoạt',
        quantity: 1,
        unitPrice: 30000,
        amount: 30000,
      ),
      InvoiceItemMock(
        type: 'service',
        description: 'Phí quản lý chung',
        quantity: 1,
        unitPrice: 50000,
        amount: 50000,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'CHI TIẾT HÓA ĐƠN',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // THÔNG TIN CHUNG HÓA ĐƠN
          Container(
            color: AppColors.primaryGreen,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              color: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('MÃ HÓA ĐƠN:', invoiceDetail.invoiceCode, isBold: true),
                    const SizedBox(height: 8),
                    _buildInfoRow('Kỳ thanh toán:', invoiceDetail.billingMonth),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        'Hạn chót:',
                        invoiceDetail.dueDate,
                        valueColor: invoiceDetail.status == 'overdue' ? Colors.red : AppColors.textPrimary
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CHI TIẾT CÁC KHOẢN THU
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHI TIẾT CÁC KHOẢN THU',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),


                  Card(
                    color: AppColors.cardSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: invoiceDetail.items.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: AppColors.lightGreen,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final item = invoiceDetail.items[index];
                        return _buildInvoiceItem(item);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // NÚT THANH TOÁN
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  if (invoiceDetail.discount > 0)// NẾU GIẢM GIÁ
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Giảm giá:', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            '- ${_formatCurrency(invoiceDetail.discount)} đ',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TỔNG CỘNG:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${_formatCurrency(invoiceDetail.total)} đ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),


                  if (invoiceDetail.status != 'paid')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // CHUYỂN SANG MÀN HÌNH THANH TOÁN
                          Navigator.pushNamed(context, AppRoutes.tenantPayment);
                        },
                        child: const Text(
                          'THANH TOÁN NGAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  HÀM BUILD TỪNG KHOẢN THU
  Widget _buildInvoiceItem(InvoiceItemMock item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: CircleAvatar(
        backgroundColor: AppColors.lightGreen,
        child: Icon(_getTypeIcon(item.type), color: AppColors.primaryGreen),
      ),
      title: Text(
        item.description,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(

          '${_formatNumber(item.quantity)} x ${_formatCurrency(item.unitPrice)} đ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
      trailing: Text(
        '${_formatCurrency(item.amount)} đ',
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15),
      ),
    );
  }


  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // iCON
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'rent':
        return Icons.house;
      case 'electricity':
        return Icons.electric_bolt;
      case 'water':
        return Icons.water_drop;
      case 'service':
        return Icons.cleaning_services;
      default:
        return Icons.receipt;
    }
  }

  // FORMAT SỐ LƯỢNG
  String _formatNumber(double number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    return number.toString();
  }

  // FORMAT TIỀN
  String _formatCurrency(double amount) {
    String result = amount.toInt().toString();
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return result;
  }
}