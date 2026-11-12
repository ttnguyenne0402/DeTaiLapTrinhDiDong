import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/tenant/utility_service.dart';

class TenantUtilityScreen extends StatefulWidget {
  const TenantUtilityScreen({super.key});

  @override
  State<TenantUtilityScreen> createState() => _TenantUtilityScreenState();
}

class _TenantUtilityScreenState extends State<TenantUtilityScreen> {
  bool _isLoading = true;
  String? _error;
  String _roomName = 'Ph\u00f2ng thu\u00ea';
  String _propertyName = 'Nh\u00e0 tr\u1ecd';
  List<Map<String, dynamic>> _readings = [];

  @override
  void initState() {
    super.initState();
    _loadUtilityHistory();
  }

  Future<void> _loadUtilityHistory() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await TenantUtilityService.getMyUtilityHistory();
      if (!mounted) return;
      setState(() {
        _roomName = data['roomName']?.toString() ?? 'Ph\u00f2ng thu\u00ea';
        _propertyName = data['propertyName']?.toString() ?? 'Nh\u00e0 tr\u1ecd';
        _readings = (data['readings'] as List? ?? [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  num _value(Map<String, dynamic>? reading, String key) => reading?[key] is num ? reading![key] as num : num.tryParse(reading?[key]?.toString() ?? '') ?? 0;
  Map<String, dynamic>? get _latest => _readings.isEmpty ? null : _readings.first;
  String _money(num value) => '${value.toStringAsFixed(0)}\u0111';
  String _month(Map<String, dynamic> reading) => reading['month']?.toString() ?? '';
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton(onPressed: _loadUtilityHistory, child: const Text('Th\u1eed l\u1ea1i'))])))
                : SingleChildScrollView(
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

              ..._readings.skip(1).map((reading) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPastPeriodCard(
                  _month(reading).split('/').first,
                  _month(reading),
                  _money(_value(reading, 'totalCost')),
                  reading['recordedAt']?.toString().split('T').first ?? '',
                ),
              )),
              const SizedBox(height: 8),

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
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.meeting_room, color: AppColors.primaryGreen, size: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_roomName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('$_propertyName \u2022 \u0110ang thu\u00ea', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ])),
      ]),
    );
  }

  Widget _buildAverageStats() {
    final recent = _readings.take(6).toList();
    final divisor = recent.isEmpty ? 1 : recent.length;
    final averageElectric = recent.fold<num>(0, (sum, item) => sum + _value(item, 'electricUsage')) / divisor;
    final averageWater = recent.fold<num>(0, (sum, item) => sum + _value(item, 'waterUsage')) / divisor;
    final electricCost = recent.fold<num>(0, (sum, item) => sum + _value(item, 'electricCost')) / divisor;
    final waterCost = recent.fold<num>(0, (sum, item) => sum + _value(item, 'waterCost')) / divisor;
    return Row(children: [
      Expanded(child: _buildStatCard(Icons.bolt, AppColors.accentYellow, 'TB ti\u00eau th\u1ee5 \u0111i\u1ec7n', '${averageElectric.toStringAsFixed(1)} kWh', '${_money(electricCost)}/th\u00e1ng')),
      const SizedBox(width: 12),
      Expanded(child: _buildStatCard(Icons.water_drop, Colors.teal, 'TB ti\u00eau th\u1ee5 n\u01b0\u1edbc', '${averageWater.toStringAsFixed(1)} m\u00b3', '${_money(waterCost)}/th\u00e1ng')),
    ]);
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
    final previous = _readings.length > 1 ? _readings[1] : null;
    final currentUsage = _value(_latest, 'electricUsage') + _value(_latest, 'waterUsage');
    final previousUsage = _value(previous, 'electricUsage') + _value(previous, 'waterUsage');
    final hasComparison = previous != null;
    final change = previousUsage == 0 ? 0 : ((currentUsage - previousUsage) / previousUsage * 100);
    final wentDown = change <= 0;
    final label = hasComparison
        ? '${wentDown ? 'Ti?u th? gi?m' : 'Ti?u th? t?ng'} ${change.abs().toStringAsFixed(1)}% so v?i k? tr??c.'
        : 'C?n th?m d? li?u k? tr??c ?? so s?nh m?c ti?u th?.';
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(12)), child: Row(children: [
      Icon(wentDown ? Icons.trending_down : Icons.trending_up, color: AppColors.primaryGreen),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold))),
    ]));
  }

  Widget _buildConsumptionChartCard() {
    final chartData = _readings.take(6).toList().reversed.toList();
    final maxElectric = chartData.fold<num>(1, (maxValue, item) => _value(item, 'electricUsage') > maxValue ? _value(item, 'electricUsage') : maxValue);
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ti?u th? ?i?n 6 k? g?n nh?t', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      if (chartData.isEmpty) const Text('Ch?a c? d? li?u ch? s?.'),
      ...chartData.map((reading) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        SizedBox(width: 62, child: Text(_month(reading))),
        Expanded(child: LinearProgressIndicator(value: (_value(reading, 'electricUsage') / maxElectric).toDouble(), minHeight: 8, color: AppColors.accentYellow, backgroundColor: AppColors.background)),
        const SizedBox(width: 8),
        Text('${_value(reading, 'electricUsage')} kWh', style: const TextStyle(fontSize: 11)),
      ]))),
    ]));
  }

  Widget _buildLatestPeriodCard() {
    final reading = _latest;
    if (reading == null) {
      return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16)), child: const Text('Ch?a c? k? n?o ???c ghi ch? s?.'));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text('K\u1ef3 ${_month(reading)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))), Text(_money(_value(reading, 'totalCost')), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen))]),
        const SizedBox(height: 12),
        _buildMeterSubCard(Icons.bolt, '\u0110i\u1ec7n: ${_value(reading, 'electricOld')} \u2192 ${_value(reading, 'electricNew')}', _money(_value(reading, 'electricCost'))),
        const SizedBox(height: 8),
        _buildMeterSubCard(Icons.water_drop, 'N\u01b0\u1edbc: ${_value(reading, 'waterOld')} \u2192 ${_value(reading, 'waterNew')}', _money(_value(reading, 'waterCost'))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _showComplainDialog, icon: const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warningOrange), label: const Text('G?i khi?u n?i / B?o sai s?', style: TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.warningOrange, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
      ]),
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