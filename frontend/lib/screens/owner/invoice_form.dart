import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/invoice_form_w.dart';

class Invoice_form extends StatefulWidget {
  const Invoice_form({super.key});

  @override
  State<Invoice_form> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<Invoice_form> {
  final TextEditingController _dienCuController = TextEditingController(text: '1.420');
  final TextEditingController _dienMoiController = TextEditingController(text: '1.545');

  final TextEditingController _nuocCuController = TextEditingController(text: '85');
  final TextEditingController _nuocMoiController = TextEditingController(text: '91');

  @override
  void dispose() {
    _dienCuController.dispose();
    _dienMoiController.dispose();
    _nuocCuController.dispose();
    _nuocMoiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        ),
        title: const Text(
          'Ghi Điện Nước Lập Hóa Đơn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. Trạng thái & Kỳ thu ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade800,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ĐANG SOẠN THẢO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Kỳ thu: T08/2024',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- 2. Thông tin phòng & Hợp đồng ---
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.apartment, size: 18, color: AppColors.primaryGreen),
                                  SizedBox(width: 8),
                                  Text(
                                    'Thông tin phòng & Hợp đồng',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: const Text(
                                  '#HD-2024-P201',
                                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('Chọn Nhà & Phòng', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Khu Trọ Xanh • Phòng 201 – Tầng 2', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Nguyễn Văn An', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.lightGreen,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('Hiệu lực', style: TextStyle(fontSize: 9, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      const Text('0912 ••• 889 • HĐ 12 tháng', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: const [
                                          Icon(Icons.calendar_today, size: 10, color: AppColors.textSecondary),
                                          SizedBox(width: 4),
                                          Text('01/08 - 31/08/2024', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                          SizedBox(width: 10),
                                          Icon(Icons.access_time, size: 10, color: Colors.red),
                                          SizedBox(width: 4),
                                          Text('Hạn đóng: 05/09/2024', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- 3. Chỉ số Điện & Nước ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bolt, size: 18, color: Colors.amber),
                            SizedBox(width: 6),
                            Text('Chỉ số Điện & Nước', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Tính tự động', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Card Điện
                    InvoiceWidgetHelpers.buildUtilityCard(
                      icon: Icons.electric_bolt,
                      title: 'Điện sinh hoạt',
                      unitPrice: 'Đơn giá: 3.800 đ/kWh',
                      totalAmount: '475.000 đ',
                      oldController: _dienCuController,
                      newController: _dienMoiController,
                      unitLabel: 'kWh',
                      consumption: '125 kWh',
                      actionText: 'Đổi ảnh',
                      actionIcon: Icons.camera_alt_outlined,
                      onActionPressed: () {},
                    ),
                    const SizedBox(height: 10),

                    // Card Nước
                    InvoiceWidgetHelpers.buildUtilityCard(
                      icon: Icons.water_drop,
                      title: 'Nước sinh hoạt',
                      unitPrice: 'Đơn giá: 25.000 đ/m³',
                      totalAmount: '150.000 đ',
                      oldController: _nuocCuController,
                      newController: _nuocMoiController,
                      unitLabel: 'm³',
                      consumption: '6 m³',
                      actionText: 'Chụp lại',
                      actionIcon: Icons.camera_alt_outlined,
                      onActionPressed: () {},
                    ),
                    const SizedBox(height: 14),

                    // --- 4. Chi tiết các khoản thu ---
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Row(
                                children: [
                                  Icon(Icons.receipt_long, size: 18, color: AppColors.primaryGreen),
                                  SizedBox(width: 8),
                                  Text('Chi tiết các khoản thu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                ],
                              ),
                              Text('7 mục', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InvoiceWidgetHelpers.buildFeeItem('Tiền phòng cố định', '4.500.000 đ', subtitle: 'HĐ #HD-2024-P201', icon: Icons.bed),
                          InvoiceWidgetHelpers.buildFeeItem('Tiền điện sinh hoạt', '475.000 đ', subtitle: '125 kWh × 3.800 đ', icon: Icons.electric_bolt),
                          InvoiceWidgetHelpers.buildFeeItem('Tiền nước sinh hoạt', '150.000 đ', subtitle: '6 m³ × 25.000 đ', icon: Icons.water_drop),
                          InvoiceWidgetHelpers.buildFeeItem('Wifi & Internet cáp quang', '100.000 đ', subtitle: 'Gói tốc độ cao', icon: Icons.wifi),
                          InvoiceWidgetHelpers.buildFeeItem('Vệ sinh & Rác hành lang', '50.000 đ', subtitle: 'Cố định tháng', icon: Icons.cleaning_services),
                          InvoiceWidgetHelpers.buildFeeItem('Phí giữ xe', '100.000 đ', subtitle: '2 xe máy (50.000 đ/xe)', icon: Icons.two_wheeler),

                          // Dòng giảm giá đỏ
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.local_offer, size: 14, color: Colors.red),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text('Giảm giá / Ưu đãi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                        Text('Ưu đãi đóng sớm', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                                const Text('- 100.000 đ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                          ),
                          const Divider(height: 16),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add_circle_outline, size: 14, color: AppColors.primaryGreen),
                            label: const Text('Thêm khoản thu phát sinh (sửa chữa, dịch vụ khác)', style: TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- 5. Tổng kết & Nhận tiền ---
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.calculate, size: 18, color: AppColors.primaryGreen),
                                  SizedBox(width: 8),
                                  Text('Tổng kết & Nhận tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('VietQR 24/7', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Tạm tính (Subtotal):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text('5.375.000 đ', style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Giảm trừ ưu đãi:', style: TextStyle(fontSize: 11, color: Colors.red)),
                              Text('- 100.000 đ', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('TỔNG CỘNG CẦN THU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              RichText(
                                text: const TextSpan(
                                  text: '5.275.000 ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                                  children: [
                                    TextSpan(text: 'VNĐ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Thông tin ngân hàng
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Row(
                                        children: [
                                          Icon(Icons.account_balance, size: 12, color: AppColors.textSecondary),
                                          SizedBox(width: 4),
                                          Text('Techcombank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text('1903 8888 6688', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                                      Text('NGUYEN VAN CHU TRO', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 2),
                                      Text('Nội dung: P201 T082024', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: const Icon(Icons.qr_code_2, size: 45, color: AppColors.primaryGreen),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- 6. Thanh hành động dưới cùng ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save_outlined, size: 16, color: AppColors.textPrimary),
                          SizedBox(width: 6),
                          Text('Lưu nháp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentYellow,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.send, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Phát hành & Báo khách', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}