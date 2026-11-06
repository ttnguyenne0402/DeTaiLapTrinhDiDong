import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import 'payment_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Map<String, dynamic>? _invoiceDetail;
  bool _isLoading = true;
  late String _invoiceId;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        _invoiceId = args.toString();
        _fetchInvoiceDetail();
      } else {

        setState(() {
          _isLoading = false;
        });
        print("LỖI LỚN: Không nhận được ID hóa đơn truyền sang từ trang trước!");
      }
      _isInit = false;
    }
  }

  // Gọi API lấy chi tiết các khoản thu
  Future<void> _fetchInvoiceDetail() async {
    final url = 'https://10.0.2.2:7203/api/invoices/$_invoiceId';
    print("ĐANG GỌI API: $url");

    final client = _getCustomClient();
    try {
      final response = await client.get(Uri.parse(url));
      print("MÃ TRẠNG THÁI SERVER TRẢ VỀ: ${response.statusCode}");

      if (response.statusCode == 200) {
        setState(() {
          _invoiceDetail = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        // TẮT LOADING KHI SERVER BÁO LỖI (404, 500...)
        print("LỖI TỪ SERVER: ${response.body}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("LỖI KẾT NỐI HOẶC CODE: $e");
      setState(() => _isLoading = false);
    } finally {
      client.close();
    }
  }

  // Khởi tạo Custom Client bỏ qua SSL
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_invoiceDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không thể tải chi tiết hóa đơn.')),
      );
    }

    // Bóc tách dữ liệu an toàn
    final invoiceCode = _invoiceDetail!['invoiceCode'] ?? '';
    final billingMonth = _invoiceDetail!['billingMonth'] ?? '';
    final dueDate = _invoiceDetail!['dueDate'] ?? '';
    final status = _invoiceDetail!['status'] ?? '';
    final discount = (_invoiceDetail!['discount'] as num?)?.toDouble() ?? 0;
    final total = (_invoiceDetail!['total'] as num?)?.toDouble() ?? 0;
    final items = _invoiceDetail!['items'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
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
                    _buildInfoRow('MÃ HÓA ĐƠN:', invoiceCode, isBold: true),
                    const SizedBox(height: 8),
                    _buildInfoRow('Kỳ thanh toán:', billingMonth),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        'Hạn chót:',
                        dueDate,
                        valueColor: status == 'overdue' ? Colors.red : AppColors.textPrimary
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CHI TIẾT CÁC KHOẢN THU
          Expanded(
            child: Container(
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'CHI TIẾT CÁC KHOẢN THU',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Card(
                          color: AppColors.cardSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: items.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              color: AppColors.lightGreen,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              return _buildInvoiceItem(items[index]);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                )
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
                  if (discount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Giảm giá:', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            '- ${_formatCurrency(discount)} đ',
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
                        '${_formatCurrency(total)} đ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chỉ mở nút thanh toán khi trạng thái là unpaid hoặc overdue
                  if (status == 'unpaid' || status == 'overdue')
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
                        onPressed: () async {
                         await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                invoiceId: _invoiceId,
                                invoiceCode: invoiceCode,
                                amountToPay: total,
                              ),
                            ),
                          );
                         setState(() {
                           _isLoading = true;
                         });
                         _fetchInvoiceDetail();
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

  // HÀM BUILD TỪNG KHOẢN THU TỪ JSON
  Widget _buildInvoiceItem(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    final description = item['description'] ?? '';
    final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
    final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
    final amount = (item['amount'] as num?)?.toDouble() ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: CircleAvatar(
        backgroundColor: AppColors.lightGreen,
        child: Icon(_getTypeIcon(type), color: AppColors.primaryGreen),
      ),
      title: Text(
        description,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          '${_formatNumber(quantity)} x ${_formatCurrency(unitPrice)} đ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
      trailing: Text(
        '${_formatCurrency(amount)} đ',
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

  String _formatNumber(double number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    return number.toString();
  }

  String _formatCurrency(double amount) {
    String result = amount.toInt().toString();
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return result;
  }
}