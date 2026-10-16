import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ContractDetailScreen extends StatelessWidget {
  const ContractDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DỮ LIỆU GIẢ
    const String roomName = 'Phòng 101 - KDC Nhơn Đức';
    const String contractCode = 'HD-2026-0012';
    const String status = 'Đang hiệu lực';
    const String startDate = '01/10/2026';
    const String endDate = '01/10/2027';
    const String price = '2.800.000 đ/tháng';
    const String deposit = '2.800.000 đ';
    const String paymentCycle = 'Hàng tháng';
    const String initialElec = '1250 kWh';
    const String initialWater = '105 khối';
    const String ownerName = 'Nguyễn Văn A';
    const String ownerPhone = '0987654321';

    // DỊCH VỤ
    final List<Map<String, String>> services = [
      {'name': 'Rác sinh hoạt', 'price': '30.000 đ', 'unit': 'tháng'},
      {'name': 'Wifi', 'price': '50.000 đ', 'unit': 'phòng'},
      {'name': 'Gửi xe máy', 'price': '100.000 đ', 'unit': 'chiếc'},
    ];


    final List<Map<String, String>> members = [
      {'name': 'Nguễn Văn B', 'phone': '0901234567', 'role': 'Đại diện thuê'},
    ];

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
                  _buildInfoRow('Giá thuê:', price),
                  _buildInfoRow('Tiền cọc:', deposit),
                  _buildInfoRow('Chu kỳ thanh toán:', paymentCycle),
                  _buildInfoRow('Điện đầu kỳ:', initialElec),
                  _buildInfoRow('Nước đầu kỳ:', initialWater),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 4, color: AppColors.lightGreen),

            //  DỊCH VỤ
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DỊCH VỤ ĐI KÈM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(height: 12),
                  ...services.map((srv) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            Text(srv['name']!, style: const TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                        Text('${srv['price']} / ${srv['unit']}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 4, color: AppColors.lightGreen),

            // LIÊN HỆ
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LIÊN HỆ CHỦ NHÀ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(height: 12),
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: const Text('XEM FILE HỢP ĐỒNG (PDF)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () { /* Xem PDF */ },
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
}