import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../services/admin/admin_stats_service.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  String _selectedReportType = 'Năm 2026';
  final List<String> _reportTypes = ['Tháng này', 'Quý 4/2026', 'Năm 2026'];

  AdminStatsData? _statsData;
  bool _isLoading = true;
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
    _loadStats();
  }

  String _mapReportTypeToPeriod(String type) {
    if (type == 'Tháng này') return 'month';
    if (type == 'Quý 4/2026') return 'quarter';
    return 'year';
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final period = _mapReportTypeToPeriod(_selectedReportType);
      final data = await AdminStatsService.getStatistics(period);
      setState(() {
        _statsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Lỗi nạp thống kê: $e");
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Chuyển đổi dữ liệu cho biểu đồ tròn
    final List<_SystemUserShareData> userShareChartData = _statsData?.userShare.map((item) {
      final color = item.roleName.contains('Chủ') ? AppColors.primaryGreen : Colors.blue;
      return _SystemUserShareData(item.roleName, item.percentage, color);
    }).toList() ?? [];

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Thống kê',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReportType,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  items: _reportTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedReportType = val);
                      _loadStats();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. THẺ TỔNG QUAN VĨ MÔ CHO ADMIN ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryGreen, Colors.teal.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DOANH THU HOA HỒNG NỀN TẢNG (VNĐ)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatCurrency(_statsData?.totalCommission ?? 0)} ₫',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _OverviewIndicator(
                              title: 'Tổng khu trọ',
                              value: '${_statsData?.totalProperties ?? 0} khu',
                              icon: Icons.apartment,
                            ),
                            _OverviewIndicator(
                              title: 'Tổng người dùng',
                              value: '${_statsData?.totalUsers ?? 0}',
                              icon: Icons.group,
                            ),
                            _OverviewIndicator(
                              title: 'Yêu cầu hỗ trợ',
                              value: '${_statsData?.pendingRequests ?? 0} chờ xử lý',
                              icon: Icons.support_agent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 2. BIỂU ĐỒ CỘT: TĂNG TRƯỞNG HOA HỒNG ---
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Biểu đồ tăng trưởng hoa hồng',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              _selectedReportType,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 220,
                          child: SfCartesianChart(
                            margin: EdgeInsets.zero,
                            plotAreaBorderWidth: 0,
                            primaryXAxis: const CategoryAxis(
                              majorGridLines: MajorGridLines(width: 0),
                              axisLine: AxisLine(width: 0),
                            ),
                            primaryYAxis: const NumericAxis(
                              isVisible: true,
                              axisLine: AxisLine(width: 0),
                              majorTickLines: MajorTickLines(color: Colors.transparent),
                            ),
                            tooltipBehavior: _tooltipBehavior,
                            series: <CartesianSeries<RevenueChartItem, String>>[
                              ColumnSeries<RevenueChartItem, String>(
                                dataSource: _statsData?.revenueChart ?? [],
                                xValueMapper: (RevenueChartItem data, _) => data.label,
                                yValueMapper: (RevenueChartItem data, _) => data.value,
                                name: 'Hoa hồng (Tr VNĐ)',
                                color: AppColors.primaryGreen,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 3. BIỂU ĐỒ TRÒN VÀNH KHUYÊN: TỶ LỆ TÀI KHOẢN ---
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tỷ lệ phân bổ tài khoản người dùng',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 210,
                          child: SfCircularChart(
                            tooltipBehavior: _tooltipBehavior,
                            legend: const Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                              overflowMode: LegendItemOverflowMode.wrap,
                            ),
                            series: <CircularSeries<_SystemUserShareData, String>>[
                              DoughnutSeries<_SystemUserShareData, String>(
                                dataSource: userShareChartData,
                                xValueMapper: (_SystemUserShareData data, _) => data.x,
                                yValueMapper: (_SystemUserShareData data, _) => data.y,
                                pointColorMapper: (_SystemUserShareData data, _) => data.color,
                                name: 'Tỷ lệ',
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  labelPosition: ChartDataLabelPosition.outside,
                                ),
                                innerRadius: '60%',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 4. TOP KHU TRỌ ĐÓNG GÓP CAO NHẤT ---
                  const Text(
                    'Top khu trọ đóng góp hoa hồng cao nhất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _statsData?.topProperties.length ?? 0,
                    itemBuilder: (context, index) {
                      final item = _statsData!.topProperties[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                                    child: Text(
                                      '#${index + 1}',
                                      style: TextStyle(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Chủ: ${item.owner} • ${item.rooms} phòng',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_formatCurrency(item.commission)} đ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lấp đầy: ${item.occupancyRate}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, AppRoutes.adminDashboard);
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.rewview);
              break;
            case 2:
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.usersManage);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.article_outlined), label: 'Quản lý'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Thống kê'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

class _SystemUserShareData {
  _SystemUserShareData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}

class _OverviewIndicator extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _OverviewIndicator({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}