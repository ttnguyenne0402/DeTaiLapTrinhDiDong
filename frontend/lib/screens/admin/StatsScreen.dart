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
  // Bộ lọc thời gian cho Admin
  String _selectedReportType = 'Năm 2026';
  final List<String> _reportTypes = ['Tháng này', 'Quý 4/2026', 'Năm 2026'];

  // Các bộ dữ liệu mẫu tương ứng với từng mốc thời gian
  final List<_RevenueData> _dataThangNay = [
    _RevenueData('Tuần 1', 2.1),
    _RevenueData('Tuần 2', 3.5),
    _RevenueData('Tuần 3', 4.0),
    _RevenueData('Tuần 4', 5.2),
  ];

  final List<_RevenueData> _dataQuy4 = [
    _RevenueData('Tháng 10', 8.5),
    _RevenueData('Tháng 11', 10.2),
    _RevenueData('Tháng 12', 12.3),
  ];

  final List<_RevenueData> _dataNam2026 = [
    _RevenueData('Q1', 12.5),
    _RevenueData('Q2', 18.0),
    _RevenueData('Q3', 24.0),
    _RevenueData('Q4', 31.0),
  ];

  // Biến lưu trữ dữ liệu hiện tại của biểu đồ cột
  late List<_RevenueData> _currentRevenueData;

  // Các chỉ số tổng quan thay đổi theo bộ lọc
  String _totalCommission = '85.500.000 ₫';
  String _totalProperties = '42 khu';
  String _totalUsers = '1.250';

  // Dữ liệu biểu đồ vành khuyên: Tỷ lệ phân bổ tài khoản
  List<_SystemUserShareData> _userShareData = [
    _SystemUserShareData('Khách thuê', 75, Colors.blue),
    _SystemUserShareData('Chủ trọ ', 25, AppColors.primaryGreen),
  ];

  late TooltipBehavior _tooltipBehavior;

  // Danh sách Top khu trọ đóng góp hoa hồng cao
  final List<Map<String, dynamic>> _topSystemProperties = [
    {
      'name': 'Khu trọ Sinh Viên Tân Phú',
      'owner': 'Nguyễn Văn A',
      'rooms': 24,
      'commission': '4.520.000 đ',
      'rate': '95%',
    },
    {
      'name': 'Căn hộ dịch vụ Mini Q.10',
      'owner': 'Trần Thị B',
      'rooms': 12,
      'commission': '3.850.000 đ',
      'rate': '100%',
    },
    {
      'name': 'Nhà nguyên căn Bình Thạnh',
      'owner': 'Lê Văn C',
      'rooms': 8,
      'commission': '2.800.000 đ',
      'rate': '87%',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentRevenueData = _dataNam2026; //mặc định ban đầu là Năm 2026
    _tooltipBehavior = TooltipBehavior(enable: true);// cho hiển thị hộp
  }

  //hàm xử lý đổi dữ liệu khi chọn Dropdown
  void _updateReportData(String selectedType) {
    setState(() {
      _selectedReportType = selectedType;
      if (selectedType == 'Tháng này') {
        _currentRevenueData = _dataThangNay;
        _totalCommission = '14.800.000 ₫';
        _totalProperties = '42 khu';
        _totalUsers = '1.250';
        _userShareData = [
          _SystemUserShareData('Khách thuê ', 25, Colors.blue),
          _SystemUserShareData('Chủ trọ', 35, AppColors.primaryGreen),
        ];

      } else if (selectedType == 'Quý 4/2026') {
        _currentRevenueData = _dataQuy4;
        _totalCommission = '31.000.000 ₫';
        _totalProperties = '42 khu';
        _totalUsers = '1.250';
        _userShareData = [
          _SystemUserShareData('Khách thuê ', 15, Colors.blue),
          _SystemUserShareData('Chủ trọ', 25, AppColors.primaryGreen),
        ];

      } else {
        _currentRevenueData = _dataNam2026;
        _totalCommission = '85.500.000 ₫';
        _totalProperties = '42 khu';
        _totalUsers = '1.250';
        _userShareData = [
          _SystemUserShareData('Khách thuê ', 50, Colors.blue),
          _SystemUserShareData('Chủ trọ', 15, AppColors.primaryGreen),
        ];

      }
    });
  }

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(// cái phần loc xuống để chọn
                child: DropdownButton<String>(
                  value: _selectedReportType,//năm 2026
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  items: _reportTypes.map((String type) { // các ngày tháng
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _updateReportData(val);
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
                        _totalCommission,
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
                            value: _totalProperties,
                            icon: Icons.apartment,
                          ),
                          _OverviewIndicator(
                            title: 'Tổng người dùng',
                            value: _totalUsers,
                            icon: Icons.group,
                          ),
                          const _OverviewIndicator(
                            title: 'Yêu cầu hỗ trợ',
                            value: '5 chờ xử lý',
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
                          series: <CartesianSeries<_RevenueData, String>>[
                            ColumnSeries<_RevenueData, String>(
                              dataSource: _currentRevenueData,
                              xValueMapper: (_RevenueData data, _) => data.x,
                              yValueMapper: (_RevenueData data, _) => data.y,
                              name: 'Hoa hồng (Tr VNĐ)',
                              color: AppColors.primaryGreen,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
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

                //biểu đồ hình tròn vành khuyên
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 210,
                        child: SfCircularChart(
                          tooltipBehavior: _tooltipBehavior,// hiển thị hộp thoại
                          legend: const Legend(
                            isVisible:true,
                            position: LegendPosition.bottom,
                            overflowMode: LegendItemOverflowMode.wrap,
                          ),
                          series: <CircularSeries<_SystemUserShareData, String>>[
                            DoughnutSeries<_SystemUserShareData, String>(
                              dataSource: _userShareData,
                              xValueMapper: (_SystemUserShareData data, _) => data.x,
                              yValueMapper: (_SystemUserShareData data, _) => data.y,
                              pointColorMapper: (_SystemUserShareData data, _) => data.color, // đọc dữ liệu màu
                              name: 'Tỷ lệ',
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,// cho phép hiện thị số
                                labelPosition: ChartDataLabelPosition.outside,// đưa các con số bên ngoài
                              ),
                              innerRadius: '60%',//tạo lỗ rỗng ở giữa tâm biểu đồ
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                //top hoa hồng
                const Text(
                  'Top khu trọ đóng góp hoa hồng cao nhất',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topSystemProperties.length,
                  itemBuilder: (context, index) {
                    final item = _topSystemProperties[index];
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
                                        item['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Chủ: ${item['owner']} • ${item['rooms']} phòng',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
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
                                item['commission'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                  fontSize: 13,
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

      //bottom admin
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
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

// Model cho Biểu đồ cột
class _RevenueData {
  _RevenueData(this.x, this.y);
  final String x;
  final double y;
}

// Model cho Biểu đồ tròn vành khuyên
class _SystemUserShareData {
  _SystemUserShareData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}

// Widget con hiển thị chỉ số nhỏ trong thẻ Tổng quan vĩ mô
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