import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_router.dart';
import '../../route/app_routes.dart';

class ContractDetailScreen extends StatefulWidget {
  const ContractDetailScreen({super.key});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen, // màu nền thanh appBar phía trên
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết hợp đồng thuê',
          style: TextStyle(color: AppColors.cardSurface, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
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
      body: Column(
        children: [
          // container chính bo hai góc tròn phía trên
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24.0), // bo góc trái và phải phía trên
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24.0),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 1. thẻ lịch xem phòng gốc
                    _buildAppointmentHeader(),
                    const SizedBox(height: 12),

                    // 2. thẻ mã hợp đồng & thời hạn
                    _buildContractSummaryCard(),
                    const SizedBox(height: 16),

                    // 3. thông tin người thuê đại diện
                    _buildTenantSection(),
                    const SizedBox(height: 16),

                    // 4. tài chính & điều khoản cọc
                    _buildFinancialSection(),
                    const SizedBox(height: 16),

                    // 5. danh sách hóa đơn hợp đồng
                    _buildInvoicesSection(),
                    const SizedBox(height: 16),

                    // 6. ký điện tử & quy định cam kết
                    _buildESignatureSection(),
                    const SizedBox(height: 20),

                    // 7. các nút thao tác phía dưới
                    _buildActionButtons(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // widget lịch xem phòng gốc
  Widget _buildAppointmentHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LỊCH XEM PHÒNG GỐC', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('#AP-8823 • Đã hoàn tất 24/08/...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.cardSurface,
              side: const BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {},
            child: const Row(
              children: [
                Text('Chi tiết', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                Icon(Icons.chevron_right, size: 14, color: AppColors.textPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // widget thẻ mã hợp đồng & thời hạn
  Widget _buildContractSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MÃ HỢP ĐỒNG: #HD-2024-P201',
                  style: TextStyle(color: AppColors.cardSurface, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: AppColors.primaryGreen),
                    SizedBox(width: 4),
                    Text('Đang hiệu lực', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Phòng 201 – Tầng 2',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.cardSurface),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.domain, size: 14, color: AppColors.lightGreen),
              SizedBox(width: 6),
              Text('Khu Trọ Bình Thạnh (Nhà A • 12 phòng)', style: TextStyle(color: AppColors.lightGreen, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),

          // thanh tiến trình thời hạn
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(Icons.event, size: 14, color: AppColors.accentYellow),
                  SizedBox(width: 6),
                  Text('Thời hạn: 12 tháng', style: TextStyle(color: AppColors.cardSurface, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('Còn 11 tháng', style: TextStyle(color: AppColors.cardSurface, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.08,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentYellow),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('01/09/2024 (Bắt đầu)', style: TextStyle(color: AppColors.lightGreen, fontSize: 10)),
              Text('Hạn tới: 31/08/2025', style: TextStyle(color: AppColors.lightGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // widget người thuê đại diện
  Widget _buildTenantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.badge_outlined, size: 18, color: AppColors.textPrimary),
                SizedBox(width: 6),
                Text('Người thuê đại diện', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Chính thức', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 50,
                          height: 50,
                          color: AppColors.borderLight,
                          child: const Icon(Icons.person, color: AppColors.textSecondary),
                        ),
                      ),
                      const CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColors.primaryGreen,
                        child: Icon(Icons.check, size: 10, color: AppColors.cardSurface),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Nguyễn Văn An', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('SĐT: 0908 123 456', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('CCCD: 079098001234', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Đồng Nai', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // trạng thái xác thực cccd / tạm trú
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 14, color: AppColors.primaryGreen),
                    SizedBox(width: 4),
                    Text('Đã xác thực CCCD', style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    Text('  •  ', style: TextStyle(color: AppColors.textSecondary)),
                    Icon(Icons.assignment_ind_outlined, size: 14, color: AppColors.primaryGreen),
                    SizedBox(width: 4),
                    Text('Đã nộp tạm trú CT01', style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // nút gọi điện / nhắn zalo
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.phone_outlined, size: 16, color: AppColors.textPrimary),
                      label: const Text('Gọi điện ngay', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primaryGreen),
                      label: const Text('Nhắn tin Zalo', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // thành viên
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group_outlined, size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cùng phòng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('2 người đăng ký lưu trú', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.contractMembers);
                      },
                      child: Row(
                        children: const [
                          Text('Xem 2 người', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Icon(Icons.chevron_right, size: 16, color: AppColors.textPrimary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // widget tài chính & điều khoản cọc
  Widget _buildFinancialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.textPrimary),
            SizedBox(width: 6),
            Text('Tài chính & Điều khoản cọc', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            // tiền thuê phòng
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TIỀN THUÊ PHÒNG', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('4.500.000', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        SizedBox(width: 2),
                        Text('đ/th', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.access_time, size: 12, color: AppColors.warningOrange),
                        SizedBox(width: 4),
                        Text('Hạn thu: Ngày 01-05', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // tiền đặt cọc
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('TIỀN ĐẶT CỌC', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        Icon(Icons.check_circle_outline, size: 14, color: AppColors.primaryGreen),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('9.000.000 đ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Đã thu đủ 2 tháng (25/08)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // chỉ số bàn giao lúc nhận phòng
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.speed, size: 16, color: AppColors.warningOrange),
                      SizedBox(width: 6),
                      Text('Chỉ số bàn giao lúc nhận phòng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  Text('Ngày 01/09/2024', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.flash_on, size: 16, color: AppColors.primaryGreen),
                          SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Điện bàn giao', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                              Text('1.420 kWh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.water_drop, size: 16, color: Colors.blue),
                          SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nước bàn giao', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                              Text('85 m³', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // dịch vụ đi kèm theo hợp đồng
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dịch vụ đi kèm theo hợp đồng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _buildServiceRow(Icons.lightbulb_outline, 'Điện sinh hoạt', '3.800 đ/kWh'),
              _buildServiceRow(Icons.water_damage_outlined, 'Nước sinh hoạt', '25.000 đ/m³'),
              _buildServiceRow(Icons.wifi, 'Internet Wi-Fi cáp quang', '100.000 đ/phòng'),
              _buildServiceRow(Icons.delete_outline, 'Thu gom rác & Vệ sinh chung', '50.000 đ/phòng'),
              _buildServiceRow(Icons.two_wheeler, 'Giữ xe máy (tối đa 2 xe)', 'Miễn phí'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceRow(IconData icon, String title, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          const Spacer(),
          Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // widget hóa đơn hợp đồng
  Widget _buildInvoicesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Hóa đơn hợp đồng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('2 kỳ', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen)),
                ),
              ],
            ),
            InkWell(
              onTap: () {},
              child: const Row(
                children: [
                  Text('Tất cả', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.textPrimary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // item hóa đơn tháng 08/2024
        _buildInvoiceItem(
          period: 'Kỳ Tháng 08/2024',
          amount: '5.275.000 đ',
          status: 'Đã thanh toán',
          code: 'Mã: #HD-T08-P201 • VietQR 03/09/2024',
        ),
        const SizedBox(height: 8),

        // item hóa đơn tháng 07/2024
        _buildInvoiceItem(
          period: 'Kỳ Tháng 07/2024',
          amount: '5.150.000 đ',
          status: 'Đã thanh toán',
          code: 'Mã: #HD-T07-P201 • Chuyển khoản 02/08',
        ),
        const SizedBox(height: 10),

        // nút lập hóa đơn kỳ mới
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.lightGreen.withOpacity(0.5),
            side: BorderSide.none,
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {},
          icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.textPrimary),
          label: const Text('+ Lập hóa đơn kỳ mới cho phòng này', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildInvoiceItem({
    required String period,
    required String amount,
    required String status,
    required String code,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(period, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(code, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status, style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 2),
                  Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Xem chi tiết phiếu hóa đơn', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                Icon(Icons.chevron_right, size: 14, color: AppColors.textPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // widget ký điện tử & quy định cam kết
  Widget _buildESignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.edit_note, size: 18, color: AppColors.textPrimary),
            SizedBox(width: 6),
            Text('Ký điện tử & Quy định cam kết', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // thời gian ký hợp lệ
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: AppColors.primaryGreen),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text('Hợp đồng được ký số hợp lệ vào:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                    Text('25/08/2024 lúc 16:30', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // thông tin bên a và bên b
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHỦ TRỌ / BÊN A', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Trần Thanh Trúc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 10),
                          const Text('Thanh Trúc', style: TextStyle(fontSize: 18, fontFamily: 'Cursive', color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            children: const [
                              Icon(Icons.check_circle_outline, size: 12, color: AppColors.primaryGreen),
                              SizedBox(width: 4),
                              Text('Đã ký điện tử', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('KHÁCH THUÊ / BÊN B', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Nguyễn Văn An', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 10),
                          const Text('Van An', style: TextStyle(fontSize: 18, fontFamily: 'Cursive', color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            children: const [
                              Icon(Icons.security, size: 12, color: AppColors.primaryGreen),
                              SizedBox(width: 4),
                              Text('Xác thực SmartCA', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text('3 CAM KẾT AN TOÀN & VẬN HÀNH QUAN TRỌNG:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 8),

              _buildCommitmentItem(Icons.info_outline, 'Báo hủy trả phòng trước ít nhất 30 ngày để được hoàn cọc hợp lệ.'),
              _buildCommitmentItem(Icons.local_fire_department_outlined, 'Nghiêm cấm đun nấu bằng bếp than/củi; tuân thủ nghiệm thu PCCC toà nhà.'),
              _buildCommitmentItem(Icons.volume_off_outlined, 'Giữ gìn vệ sinh và không gây ồn ào sau 23:00 mỗi đêm.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommitmentItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.warningOrange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.3)),
          ),
        ],
      ),
    );
  }

  // widget các nút thao tác xuất pdf / thanh lý / gia hạn
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.lightGreen.withOpacity(0.5),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primaryGreen),
                  label: const Text('Xuất PDF / Zalo', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.redAccent),
                  label: const Text('Thanh lý & Trả cọc', style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // nút gia hạn hợp đồng
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.subtitles_outlined, color: AppColors.textPrimary, size: 18),
            label: const Text('Gia hạn hợp đồng phòng 201', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
        ),
      ],
    );
  }
}