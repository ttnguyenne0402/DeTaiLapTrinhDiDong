import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  // Bộ lọc thời gian cho trang Thống kê
  String _selectedReportType = 'Năm 2026';
  final List<String> _reportTypes = ['Tháng này', 'Quý 4/2026', 'Năm 2026'];

  // Dữ liệu biểu đồ cột: Doanh thu theo Quý/Tháng
  final List<_RevenueData> _revenueData = [
    _RevenueData('Q1', 125000000),
    _RevenueData('Q2', 180000000),
    _RevenueData('Q3', 240000000),
    _RevenueData('Q4', 310000000),
  ];

  // Dữ liệu biểu đồ tròn: Tỷ lệ trạng thái phòng trọ
  final List<_RoomStatusData> _roomStatusData = [
    _RoomStatusData('Đang cho thuê', 68, Colors.green),
    _RoomStatusData('Trống (Chờ khách)', 22, Colors.amber),
    _RoomStatusData('Đang bảo trì', 10, Colors.redAccent),
  ];

  // Danh sách top khu trọ có doanh thu cao (Dữ liệu Mock cho Prototype)
  final List<Map<String, dynamic>> _topProperties = [
    {
      'name': 'Khu trọ Sinh Viên Tân Phú',
      'owner': 'Nguyễn Văn A',
      'rooms': 24,
      'revenue': '45.200.000 đ',
      'rate': '95%',
    },
    {
      'name': 'Căn hộ dịch vụ Mini Q.10',
      'owner': 'Trần Thị B',
      'rooms': 12,
      'revenue': '38.500.000 đ',
      'rate': '100%',
    },
    {
      'name': 'Nhà nguyên căn Bình Thạnh',
      'owner': 'Lê Văn C',
      'rooms': 8,
      'revenue': '28.000.000 đ',
      'rate': '87%',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Thống kê',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Dropdown chọn loại báo cáo
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
                      child: Text(
                        type,
                        style: const TextStyle(color:Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedReportType = val;
                      });
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
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. THẺ TỔNG QUAN TÀI CHÍNH ---
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
                        'TỔNG DOANH THU HỆ THỐNG (VNĐ)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '855.000.000 ₫',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          _OverviewIndicator(
                            title: 'Tỷ lệ lấp đầy',
                            value: '84.5%',
                            icon: Icons.pie_chart_outline,
                          ),
                          _OverviewIndicator(
                            title: 'Tổng khu trọ',
                            value: '42 khu',
                            icon: Icons.apartment,
                          ),
                          _OverviewIndicator(
                            title: 'Giao dịch',
                            value: '1.420',
                            icon: Icons.receipt_long,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- 2. BIỂU ĐỒ CỘT: DOANH THU THEO KỲ ---
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
                            'Biểu đồ tăng trưởng doanh thu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _selectedReportType,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 210,
                        child: SfCartesianChart(
                          margin: EdgeInsets.zero,
                          plotAreaBorderWidth: 0,
                          primaryXAxis: const CategoryAxis(
                            majorGridLines: MajorGridLines(width: 0),
                          ),
                          primaryYAxis: const NumericAxis(
                            isVisible: true,
                            axisLine: AxisLine(width: 0),
                            majorTickLines: MajorTickLines(color: Colors.transparent),
                          ),
                          tooltipBehavior: TooltipBehavior(enable: true),
                          series: <CartesianSeries<_RevenueData, String>>[
                            ColumnSeries<_RevenueData, String>(
                              dataSource: _revenueData,
                              xValueMapper: (_RevenueData data, _) => data.period,
                              yValueMapper: (_RevenueData data, _) => data.revenue,
                              color: AppColors.primaryGreen,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                textStyle: TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- 3. BIỂU ĐỒ TRÒN: TỶ LỆ TRẠNG THÁI PHÒNG ---
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
                        'Tỷ lệ trạng thái phòng trọ toàn hệ thống',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: SfCircularChart(
                          legend: const Legend(
                            isVisible: true,
                            position: LegendPosition.bottom,
                            overflowMode: LegendItemOverflowMode.wrap,
                          ),
                          series: <DoughnutSeries<_RoomStatusData, String>>[
                            DoughnutSeries<_RoomStatusData, String>(
                              dataSource: _roomStatusData,
                              xValueMapper: (_RoomStatusData data, _) => data.status,
                              yValueMapper: (_RoomStatusData data, _) => data.percentage,
                              pointColorMapper: (_RoomStatusData data, _) => data.color,
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

                // --- 4. BẢNG XẾP HẠNG TOP KHU TRỌ ---
                const Text(
                  'Top Khu trọ hiệu suất cao',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topProperties.length,
                  itemBuilder: (context, index) {
                    final item = _topProperties[index];
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
                          Row(
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Chủ trọ: ${item['owner']} • ${item['rooms']} phòng',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item['revenue'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lấp đầy: ${item['rate']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
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

      // --- BOTTOM NAVIGATION BAR ĐỒNG BỘ ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Tab 2 đang được chọn là Thống kê
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.rewview);
              break;
            case 2:
            // Đang ở Thống kê rồi
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.usersManage);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'Quản lý',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

// Model cho Biểu đồ cột Doanh thu
class _RevenueData {
  _RevenueData(this.period, this.revenue);
  final String period;
  final double revenue;
}

// Model cho Biểu đồ tròn Trạng thái phòng
class _RoomStatusData {
  _RoomStatusData(this.status, this.percentage, this.color);
  final String status;
  final double percentage;
  final Color color;
}

// Widget con hiển thị chỉ số nhỏ trong thẻ Tổng quan
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
            Text(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}