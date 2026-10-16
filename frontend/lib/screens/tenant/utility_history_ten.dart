import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TenantUtilityScreen extends StatefulWidget {
  const TenantUtilityScreen({super.key});

  @override
  State<TenantUtilityScreen> createState() => _TenantUtilityScreenState();
}

class _TenantUtilityScreenState extends State<TenantUtilityScreen> {
  void _showComplainDialog() {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warningOrange),
            SizedBox(width: 8),
            Text('Gửi khiếu nại / Báo sai số', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập lý do sai số chỉ số điện/nước...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi phản hồi đến chủ trọ!')));
            },
            child: const Text('Gửi', style: TextStyle(color: AppColors.cardSurface)),
          ),
        ],
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Theo dõi Điện Nước',
          style: TextStyle(
            color: AppColors.cardSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.cardSurface),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 4),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
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

              _buildAverageStats(),
              const SizedBox(height: 12),
              _buildEfficiencyCard(),
              const SizedBox(height: 16),
              _buildConsumptionChartCard(),
              const SizedBox(height: 20),

              const Text('Lịch sử ghi chỉ số', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),

              _buildLatestPeriodCard(),
              const SizedBox(height: 12),

              _buildPastPeriodCard('07', '07/2024', '598.400đ', '31/07/2024'),
              const SizedBox(height: 12),
              _buildPastPeriodCard('06', '06/2024', '569.600đ', '30/06/2024'),
              const SizedBox(height: 20),

              // nút tải pdf & liên hệ chủ trọ
              _buildTenantBottomActions(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- widgets của người thuê ---

  Widget _buildRoomHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.meeting_room, color: AppColors.primaryGreen, size: 28),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phòng 201', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              SizedBox(height: 4),
              Text('Khu Trọ Xanh • Đang thuê', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
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
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
      child: const Row(
        children: [
          Icon(Icons.trending_down, color: AppColors.primaryGreen),
          SizedBox(width: 12),
          Expanded(child: Text('Dùng điện nước tiết kiệm hơn tháng trước 4%', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildConsumptionChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Biểu đồ tiêu thụ 6 tháng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Text('Kỳ T08/2024: 125 kWh • 6 m³ (625.000đ)', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
        ],
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kỳ Tháng 08/2024', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('625.000đ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 12),
          _buildMeterSubCard(Icons.bolt, 'Điện: 1.420 → 1.545', '475.000đ'),
          const SizedBox(height: 8),
          _buildMeterSubCard(Icons.water_drop, 'Nước: 85 → 91', '150.000đ'),
          const SizedBox(height: 12),

          // nút khiếu nại dành riêng cho người thuê
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showComplainDialog,
              icon: const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warningOrange),
              label: const Text('Gửi khiếu nại / Báo sai số', style: TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.warningOrange, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterSubCard(IconData icon, String title, String amount) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const Spacer(),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPastPeriodCard(String code, String month, String amount, String date) {
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
                Text('Thanh toán ngày $date', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTenantBottomActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download, color: AppColors.cardSurface),
            label: const Text('Tải hóa đơn PDF / Biên nhận', style: TextStyle(color: AppColors.cardSurface, fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen),
            label: const Text('Liên hệ Chủ trọ', style: TextStyle(color: AppColors.primaryGreen, fontSize: 15, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}