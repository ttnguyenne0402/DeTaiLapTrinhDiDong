import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LandlordUtilityScreen extends StatefulWidget {
  const LandlordUtilityScreen({super.key});

  @override
  State<LandlordUtilityScreen> createState() => _LandlordUtilityScreenState();
}

class _LandlordUtilityScreenState extends State<LandlordUtilityScreen> {
  bool isRoomView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
          onPressed: () => Navigator.maybePop(context),
        ),

        title: const Text(
          'Quản Lí Điện Nước',
          style: TextStyle(
            color: AppColors.cardSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.cardSurface),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 4),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
        ],
      ),

      // fab ghi chỉ số dành riêng cho chủ trọ
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add, color: AppColors.cardSurface),
        label: const Text(
          'Ghi chỉ số kỳ này',
          style: TextStyle(color: AppColors.cardSurface, fontWeight: FontWeight.bold),
        ),
      ),

      // toàn bộ body được bọc bởi container bo 2 góc trên
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background, // màu nền của nội dung bên dưới (trắng/kem)
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24), // bo cong 2 góc trên (trái & phải)
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoomHeaderCard(),
              const SizedBox(height: 12),

              // tab lọc theo phòng / khu trọ
              _buildLandlordTabs(),
              const SizedBox(height: 12),

              _buildAverageStats(),
              const SizedBox(height: 12),
              _buildEfficiencyCard(),
              const SizedBox(height: 16),
              _buildConsumptionChartCard(),
              const SizedBox(height: 20),

              _buildHistoryHeader(),
              const SizedBox(height: 8),

              _buildLatestPeriodCard(),
              const SizedBox(height: 12),

              _buildPastPeriodCard('07', '07/2024', '598.400đ', '31/07/2024', 'N.V. Chu Trọ'),
              const SizedBox(height: 12),
              _buildPastPeriodCard('06', '06/2024', '569.600đ', '30/06/2024', 'Tự động chốt kỳ'),
              const SizedBox(height: 20),

              // khối xuất file & in ấn
              _buildLandlordBottomActions(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // --- widgets của chủ trọ ---

  Widget _buildRoomHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.meeting_room, color: AppColors.primaryGreen, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Phòng 201', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Tầng 2', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Khu Trọ Xanh • Hợp đồng đang chạy', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.unfold_more, color: AppColors.textSecondary), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildLandlordTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isRoomView = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isRoomView ? AppColors.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.domain, size: 18, color: isRoomView ? AppColors.cardSurface : AppColors.textPrimary),
                    const SizedBox(width: 6),
                    Text('Xem theo Phòng', style: TextStyle(color: isRoomView ? AppColors.cardSurface : AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isRoomView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isRoomView ? AppColors.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_city, size: 18, color: !isRoomView ? AppColors.cardSurface : AppColors.textPrimary),
                    const SizedBox(width: 6),
                    Text('Toàn bộ Khu trọ', style: TextStyle(color: !isRoomView ? AppColors.cardSurface : AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.bolt, AppColors.accentYellow, 'TB Tiêu thụ Điện', '120 kWh', '~456.000đ/tháng')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.water_drop, Colors.teal, 'TB Tiêu thụ Nước', '6.2 m³', '~155.000đ/tháng')),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, Color iconColor, String title, String value, String subText) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(6)), child: const Text('6 Tháng', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen))),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(subText, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppColors.cardSurface, shape: BoxShape.circle), child: const Icon(Icons.trending_down, color: AppColors.primaryGreen)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hiệu suất tiêu thụ tốt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                Text('Điện và nước giảm ổn định', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(20)),
            child: const Text('Giảm 4%', style: TextStyle(color: AppColors.cardSurface, fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildConsumptionChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Biểu đồ tiêu thụ 6 tháng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const Text('Tháng 03 - Tháng 08/2024', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text('Kỳ T08/2024 (Đang chọn):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                Spacer(),
                Text('125 kWh • 6 m³ (625.000đ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarGroup('T03', 0.6, 0.5, false),
                _buildBarGroup('T04', 0.7, 0.4, false),
                _buildBarGroup('T05', 0.9, 0.6, false),
                _buildBarGroup('T06', 0.75, 0.35, false),
                _buildBarGroup('T07', 0.8, 0.45, false),
                _buildBarGroup('T08', 0.85, 0.55, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarGroup(String label, double elecRatio, double waterRatio, bool isHighlight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(width: 10, height: 70 * elecRatio, decoration: BoxDecoration(color: isHighlight ? AppColors.primaryGreen : AppColors.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 2),
            Container(width: 10, height: 70 * waterRatio, decoration: BoxDecoration(color: AppColors.accentYellow, borderRadius: BorderRadius.circular(4))),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal, color: isHighlight ? AppColors.primaryGreen : AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Lịch sử ghi chỉ số', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.tune, size: 18, color: AppColors.textSecondary),
          label: const Text('Bộ lọc', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildLatestPeriodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: AppColors.primaryGreen, child: Text('08', style: TextStyle(color: AppColors.cardSurface, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kỳ Tháng 08/2024', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('31/08/2024 • Ghi bởi Chủ nhà (N.V. Chu Trọ)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Text('625.000đ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 12),
          _buildMeterSubCard(Icons.bolt, 'Điện: 1.420 → 1.545', '+125 kWh × 3.800đ', '475.000đ'),
          const SizedBox(height: 8),
          _buildMeterSubCard(Icons.water_drop, 'Nước: 85 → 91', '+6 m³ × 25.000đ', '150.000đ'),
        ],
      ),
    );
  }

  Widget _buildMeterSubCard(IconData icon, String title, String detail, String amount) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPastPeriodCard(String code, String month, String amount, String date, String creator) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.lightGreen, child: Text(code, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kỳ Tháng $month', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('Tạo bởi: $creator • $date', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildLandlordBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Xuất & Chia sẻ Dữ liệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          const Text('Báo cáo kiểm toán, đối soát khách thuê', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.table_chart, color: AppColors.cardSurface),
              label: const Text('Xuất file Excel đối soát (XLSX)', style: TextStyle(color: AppColors.cardSurface, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.print, color: AppColors.textPrimary),
              label: const Text('In bảng chỉ số & biên nhận', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(backgroundColor: AppColors.background, side: const BorderSide(color: AppColors.borderLight), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }
}