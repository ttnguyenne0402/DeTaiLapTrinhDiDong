import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../services/auth_storage.dart';
import '../../utils/database_helper.dart';
import 'invoice_detail_screen.dart';
class MyInvoicesScreen extends StatefulWidget {
  const MyInvoicesScreen({super.key});

  @override
  State<MyInvoicesScreen> createState() => _MyInvoicesScreenState();
}

class _MyInvoicesScreenState extends State<MyInvoicesScreen> {
  List _invoices = [];
  bool _isLoading = true;

// URL API Backend
  late String _apiUrl;

  @override
  void initState() {
    super.initState();
    _initData();
  }
  Future<void> _initData() async {
    final userId = await AuthStorage.getUserId();
    _apiUrl = 'http://10.0.2.2:5093/api/invoices/tenant/${userId ?? ""}';
    await _loadData();
  }

  // Hàm tạo Client tùy chỉnh bỏ qua lỗi SSL
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  Future<void> _loadData() async {
    // 1. Lấy dữ liệu từ SQLite
    final localData = await DatabaseHelper.instance.getLocalInvoices();
    if (localData.isNotEmpty) {
      setState(() {
        _invoices = List.from(localData);
        _isLoading = false;
      });
    }

    // 2. Gọi API để lấy dữ liệu mới nhất
    final client = _getCustomClient();
    try {
      final response = await client.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> apiData = json.decode(response.body);
        await DatabaseHelper.instance.insertInvoices(apiData);
        if (mounted) {
          setState(() {
            _invoices = List.from(apiData);
            _isLoading = false;
          });
        }
      } else {
        print("Lỗi hóa đơn từ server: ${response.statusCode} - ${response.body}");
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print("Lỗi khi lấy hóa đơn từ server: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {

    double totalDebt = _invoices
        .where((inv) => inv['status'] == 'unpaid' || inv['status'] == 'overdue'||inv['status']=='pending')
        .fold(0, (sum, item) => sum + (item['total'] as num).toDouble());

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Hóa đơn & Thanh toán',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // THẺ DƯ NỢ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LỊCH SỬ HÓA ĐƠN
          Expanded(
            child: Container(
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
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                      child: Text(
                        'LỊCH SỬ HÓA ĐƠN',
                        style: TextStyle(color: AppColors.primaryGreen, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _invoices.isEmpty
                          ? const Center(
                        child: Text('Không có hóa đơn nào.', style: TextStyle(color: AppColors.textSecondary)),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _invoices[index];
                          return _buildInvoiceCard(invoice);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HÀM BUILD TỪNG CARD HÓA ĐƠN
  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final statusUI = _getStatusUI(invoice['status']);

    // Ép kiểu an toàn cho các số thập phân
    final discount = (invoice['discount'] as num).toDouble();
    final total = (invoice['total'] as num).toDouble();

    return Card(
      color: AppColors.cardSurface,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {

        await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InvoiceDetailScreen(),
              settings: RouteSettings(arguments: invoice['id']),
            ),
          );
        setState(() {
          _isLoading = true;
        });
        await _loadData();
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
                    'Kỳ ${invoice['billingMonth']}',
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
              _buildRow('Mã hóa đơn:', invoice['invoiceCode']),
              _buildRow('Ngày phát hành:', invoice['issueDate']),
              _buildRow('Hạn thanh toán:', invoice['dueDate'], isWarning: invoice['status'] == 'overdue'),

              if (discount > 0) // GIẢM GIÁ
                _buildRow('Giảm giá:', '- ${_formatCurrency(discount)} đ', color: Colors.green),

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
                    '${_formatCurrency(total)} đ',
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

  String _formatCurrency(double amount) {
    String result = amount.toInt().toString();
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return result;
  }
}