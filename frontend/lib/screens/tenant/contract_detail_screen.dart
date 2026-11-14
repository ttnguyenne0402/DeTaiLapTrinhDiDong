import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import 'tenant_maintenance_request_screen.dart';

class ContractDetailScreen extends StatefulWidget {
  const ContractDetailScreen({super.key});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  Map<String, dynamic>? _contractDetail;
  bool _isLoading = true;
  late String _contractId;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lấy ID hợp đồng được truyền từ màn hình danh sách sang
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        _contractId = args.toString();
        _fetchContractDetail();
      } else {
        setState(() => _isLoading = false);
        print("LỖI: Không nhận được ID hợp đồng!");
      }
      _isInit = false;
    }
  }

  // Khởi tạo Custom Client bỏ qua SSL
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  // Gọi API lấy chi tiết hợp đồng
  Future<void> _fetchContractDetail() async {
    // URL API Backend
    final url = 'http://10.0.2.2:5093/api/contracts/$_contractId';
    print("ĐANG GỌI API: $url");

    final client = _getCustomClient();
    try {
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _contractDetail = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        print("LỖI TỪ SERVER: ${response.statusCode} - ${response.body}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("LỖI KẾT NỐI HOẶC CODE: $e");
      setState(() => _isLoading = false);
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_contractDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không thể tải chi tiết hợp đồng.')),
      );
    }

    // Bóc tách dữ liệu an toàn từ API (fallback về chuỗi rỗng/mặc định nếu null)
    final roomName = _contractDetail!['roomName'] ?? 'Phòng trống';
    final contractCode = _contractDetail!['contractCode'] ?? 'Chưa cập nhật';

    // Đổi trạng thái E sang V
    String status = 'Chưa xác định';
    if (_contractDetail!['status'] == 'active') status = 'Đang hiệu lực';
    else if (_contractDetail!['status'] == 'expired') status = 'Đã hết hạn';
    else if (_contractDetail!['status'] == 'terminated') status = 'Đã thanh lý';
    else if (_contractDetail!['status'] == 'draft') status = 'Bản nháp';

    final startDate = _contractDetail!['startDate'] ?? 'N/A';
    final endDate = _contractDetail!['endDate'] ?? 'N/A';
    final rent = (_contractDetail!['rent'] as num?)?.toDouble() ?? 0;
    final deposit = (_contractDetail!['deposit'] as num?)?.toDouble() ?? 0;

    String paymentCycle = _contractDetail!['paymentCycle'] == 'quarterly' ? 'Hàng quý' : 'Hàng tháng';

    final initialElec = (_contractDetail!['initialElectricityReading'] as num?)?.toString() ?? '0';
    final initialWater = (_contractDetail!['initialWaterReading'] as num?)?.toString() ?? '0';

    // Thông tin chủ nhà (Giả sử API trả về object owner)
    final ownerName = _contractDetail!['ownerName'] ?? 'Đang cập nhật';
    final ownerPhone = _contractDetail!['ownerPhone'] ?? 'Đang cập nhật';

    // Dịch vụ (Giả sử API trả về mảng services)
    final services = _contractDetail!['services'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chi tiết hợp đồng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ẢNH
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.grey,
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=1000&auto=format&fit=crop'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏠 $roomName',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mã HĐ: $contractCode', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 4, color: AppColors.lightGreen),

            //  THÔNG TIN
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('THÔNG TIN CHUNG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(height: 16),
                  _buildInfoRow('Ngày bắt đầu:', startDate),
                  _buildInfoRow('Ngày kết thúc:', endDate),
                  _buildInfoRow('Giá thuê:', '${_formatCurrency(rent)} đ/tháng'),
                  _buildInfoRow('Tiền cọc:', '${_formatCurrency(deposit)} đ'),
                  _buildInfoRow('Chu kỳ thanh toán:', paymentCycle),
                  _buildInfoRow('Điện đầu kỳ:', '$initialElec kWh'),
                  _buildInfoRow('Nước đầu kỳ:', '$initialWater khối'),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 4, color: AppColors.lightGreen),

            //  DỊCH VỤ
            if (services.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DỊCH VỤ ĐI KÈM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                    const SizedBox(height: 12),
                    ...services.map((srv) {
                      final srvName = srv['name'] ?? '';
                      final srvPrice = (srv['price'] as num?)?.toDouble() ?? 0;
                      final srvUnit = srv['unit'] ?? 'tháng';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, size: 16, color: AppColors.primaryGreen),
                                const SizedBox(width: 8),
                                Text(srvName, style: const TextStyle(color: AppColors.textPrimary)),
                              ],
                            ),
                            Text('${_formatCurrency(srvPrice)} đ / $srvUnit', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 4, color: AppColors.lightGreen),
            ],

            // LIÊN HỆ & SỬA CHỮA
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HỖ TRỢ & LIÊN HỆ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(height: 12),

                  // Thông tin chủ nhà
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: AppColors.lightGreen, child: Icon(Icons.support_agent, color: AppColors.primaryGreen)),
                    title: Text(ownerName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    subtitle: Text(ownerPhone, style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.primaryGreen),
                      onPressed: () { /* GỌI CHỦ NHÀ */ },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GỬI YÊU CẦU SỬA CHỮA (Chỉ hiện khi hợp đồng đang hiệu lực)
                  if (_contractDetail!['status'] == 'active')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warningOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.build_circle, color: Colors.white),
                        label: const Text('GỬI YÊU CẦU SỬA CHỮA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TenantMaintenanceRequestScreen(
                                roomId: _contractDetail!['roomId']?.toString() ?? '',
                                roomName: _contractDetail!['roomName'] ?? 'Phòng trống',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Nút xem PDF
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, color: AppColors.primaryGreen),
                      label: const Text('XEM FILE HỢP ĐỒNG (PDF)', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      onPressed: () { /* Xử lý tải/xem PDF sau */ },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    String result = amount.toInt().toString();
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return result;
  }
}