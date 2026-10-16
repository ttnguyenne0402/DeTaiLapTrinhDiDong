import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../tenant/profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // 1. State quản lý bộ lọc thời gian và khoảng ngày tùy chọn
  String _selectedPeriod = 'Tháng này';
  DateTimeRange? _customDateRange;

  final List<String> _periods = [
    'Hôm nay',
    '7 ngày qua',
    'Tháng này',
    'Tháng trước',
    'Quý này (Q4)',
    'Năm nay',
    'Tùy chọn ngày...',
  ];

  // 2. State quản lý danh sách thông báo nhanh cho Admin
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Tin đăng mới chờ duyệt',
      'subtitle': 'Chủ trọ Nguyễn Văn A vừa đăng 2 phòng mới tại Q.Tân Phú',
      'time': '5 phút trước',
      'isRead': false,
    },
    {
      'title': 'Báo cáo vi phạm',
      'subtitle': 'Người dùng phản ánh tin đăng #POST-12 sai giá thực tế',
      'time': '1 giờ trước',
      'isRead': false,
    },
    {
      'title': 'Người dùng mới',
      'subtitle': 'Có 18 tài khoản mới đăng ký trong hôm nay',
      'time': '3 giờ trước',
      'isRead': true,
    },
  ];

  // Đếm số lượng thông báo chưa đọc
  int get _unreadCount =>
      _notifications.where((item) => item['isRead'] == false).length;

  // Nhãn hiển thị trên nút chọn thời gian (Hiện ngày cụ thể nếu chọn lịch)
  String get _displayPeriodLabel {
    if (_selectedPeriod == 'Tùy chọn ngày...' && _customDateRange != null) {
      final start = _customDateRange!.start;
      final end = _customDateRange!.end;
      return '${start.day}/${start.month} - ${end.day}/${end.month}';
    }
    return _selectedPeriod;
  }

  // Hàm định dạng số có dấu chấm phân cách hàng nghìn (VD: 1256 -> 1.256)
  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  // 3. Tự động tính số liệu 4 thẻ StarCard theo mọi mốc thời gian
  Map<String, String> get _currentStats {
    int multiplier = 30;
    switch (_selectedPeriod) {
      case 'Hôm nay':
        multiplier = 1;
        break;
      case '7 ngày qua':
        multiplier = 7;
        break;
      case 'Tháng này':
        multiplier = 30;
        break;
      case 'Tháng trước':
        multiplier = 28;
        break;
      case 'Quý này (Q4)':
        multiplier = 90;
        break;
      case 'Năm nay':
        multiplier = 365;
        break;
      case 'Tùy chọn ngày...':
        multiplier = (_customDateRange?.duration.inDays ?? 5) + 1;
        break;
    }

    return {
      'users': _formatNumber(42 * multiplier),
      'rooms': _formatNumber(78 * multiplier),
      'approved': _formatNumber(63 * multiplier),
      'reports': _formatNumber(15 * multiplier),
    };
  }

  // 4. Tự động sinh dữ liệu Biểu đồ theo mốc thời gian hoặc khoảng ngày trên lịch
  List<_ChartData> get _currentChartData {
    switch (_selectedPeriod) {
      case 'Hôm nay':
        return [
          _ChartData('08h', 15, 8),
          _ChartData('12h', 42, 29),
          _ChartData('16h', 38, 25),
          _ChartData('20h', 85, 64),
          _ChartData('23h', 50, 35),
        ];
      case '7 ngày qua':
        return [
          _ChartData('T2', 120, 80),
          _ChartData('T3', 190, 130),
          _ChartData('T4', 150, 110),
          _ChartData('T5', 240, 180),
          _ChartData('T6', 200, 160),
          _ChartData('T7', 310, 250),
          _ChartData('CN', 280, 210),
        ];
      case 'Tháng trước':
        return [
          _ChartData('Tuần 1', 420, 310),
          _ChartData('Tuần 2', 510, 390),
          _ChartData('Tuần 3', 480, 350),
          _ChartData('Tuần 4', 620, 490),
        ];
      case 'Quý này (Q4)':
        return [
          _ChartData('Tháng 10', 2100, 1650),
          _ChartData('Tháng 11', 2450, 1900),
          _ChartData('Tháng 12', 2900, 2300),
        ];
      case 'Năm nay':
        return [
          _ChartData('Q1', 5200, 3850),
          _ChartData('Q2', 6850, 5400),
          _ChartData('Q3', 8400, 6950),
          _ChartData('Q4', 9100, 7600),
        ];
      case 'Tùy chọn ngày...':
        if (_customDateRange == null) return [];
        final int totalDays = _customDateRange!.duration.inDays + 1;
        // Nếu chọn quá nhiều ngày thì gom bước nhảy để biểu đồ không bị dày đặc chữ
        final int step = totalDays > 7 ? (totalDays / 6).ceil() : 1;
        List<_ChartData> customPoints = [];

        for (int i = 0; i < totalDays; i += step) {
          final date = _customDateRange!.start.add(Duration(days: i));
          final label = '${date.day}/${date.month}';
          final double views = 80.0 + ((date.day * 17 + i * 23) % 150);
          final double searches = views * 0.72;
          customPoints.add(
            _ChartData(label, views.roundToDouble(), searches.roundToDouble()),
          );
        }
        return customPoints;
      case 'Tháng này':
      default:
        return [
          _ChartData('Tuần 1', 480, 340),
          _ChartData('Tuần 2', 620, 470),
          _ChartData('Tuần 3', 550, 410),
          _ChartData('Tuần 4', 790, 630),
        ];
    }
  }

  // Hàm mở hộp thoại Thông báo khi bấm vào quả chuông
  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thông báo hệ thống',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            for (var n in _notifications) {
                              n['isRead'] = true;
                            }
                          });
                          setModalState(() {});
                        },
                        child: const Text('Đánh dấu đã đọc'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Flexible( //  có thể co lại nhỏ hơn nếu màn hình bị thiếu không gian,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        final bool isRead = item['isRead'];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRead
                                ? Colors.grey.shade200
                                : AppColors.primaryGreen.withOpacity(0.15),
                            child: Icon(
                              Icons.notifications_active_outlined,
                              color: isRead
                                  ? Colors.grey
                                  : AppColors.primaryGreen,
                            ),
                          ),
                          title: Text(
                            item['title'],
                            style: TextStyle(
                              fontWeight:
                              isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('${item['subtitle']}\n${item['time']}'),
                          isThreeLine: true,//  dùng để tối ưu khi có nội dung dài
                          onTap: () {
                            setState(() {
                              item['isRead'] = true;
                            });
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.rewview);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStats = _currentStats;
    final currentChartData = _currentChartData;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Admin",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      // Nút chuông thông báo kèm số lượng chưa đọc
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          IconButton(
                            onPressed: _showNotificationsSheet,
                            icon: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                            ),
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Avatar mở trang Profile
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(
                                user: {
                                  'Name': 'Quản trị viên',
                                  'Email': 'admin@phongtro.vn',
                                  'Phone': '0901234567',
                                  'Avatar': '',
                                  'Role': 'admin',
                                },
                              ),
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          backgroundColor: Colors.white24,
                          radius: 16,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),

            // --- BODY ---
            Expanded(
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
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề Dashboard + Nút chọn thời gian / Lịch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPeriod,
                                isDense: true,
                                isExpanded: false, // Giữ nguyên hoặc đặt false để rộng vừa đủ nội dung
                                icon: const Icon(
                                  Icons.calendar_month_outlined,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                selectedItemBuilder: (BuildContext context) {
                                  return _periods.map((String period) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: Text(_displayPeriodLabel),
                                      ),
                                    );
                                  }).toList();
                                },
                                items: _periods.map((String period) {
                                  return DropdownMenuItem<String>(
                                    value: period,
                                    // Bọc trong SizedBox để kiểm soát chính xác chiều rộng của từng item khi mở dropdown
                                    child: SizedBox(
                                      width: 150,
                                      child: Row(
                                        children: [
                                          Icon(
                                            period == 'Tùy chọn ngày...'
                                                ? Icons.date_range
                                                : Icons.access_time,
                                            size: 15,
                                            color: period == 'Tùy chọn ngày...'
                                                ? AppColors.primaryGreen
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              period,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: period == _selectedPeriod
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: period == 'Tùy chọn ngày...'
                                                    ? AppColors.primaryGreen
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) async {
                                  if (newValue == null) return;

                                  if (newValue == 'Tùy chọn ngày...') {
                                    final DateTimeRange? pickedRange =
                                    await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2025, 1, 1),
                                      lastDate: DateTime.now(),
                                      initialDateRange: _customDateRange ??
                                          DateTimeRange(
                                            start: DateTime.now().subtract(
                                              const Duration(days: 6),
                                            ),
                                            end: DateTime.now(),
                                          ),
                                      helpText: 'CHỌN KHOẢNG THỜI GIAN THỐNG KÊ',
                                      cancelText: 'HỦY',
                                      confirmText: 'ÁP DỤNG',
                                    );

                                    if (pickedRange != null) {
                                      setState(() {
                                        _customDateRange = pickedRange;
                                        _selectedPeriod = newValue;
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      _selectedPeriod = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 4 Thẻ thống kê chia 2 dòng
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          StarCard(
                            title: 'Tổng người dùng',
                            value: currentStats['users']!,
                            icon: Icons.person_outline,
                            iconColor: Colors.green,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.usersManage,
                            ),
                          ),
                          StarCard(
                            title: 'Phòng đăng',
                            value: currentStats['rooms']!,
                            icon: Icons.home_outlined,
                            iconColor: Colors.amber,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.rewview,
                            ),
                          ),
                          StarCard(
                            title: 'Tin đã duyệt',
                            value: currentStats['approved']!,
                            icon: Icons.description_outlined,
                            iconColor: Colors.blue,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.rewview,
                            ),
                          ),
                          StarCard(
                            title: 'Báo cáo',
                            value: currentStats['reports']!,
                            icon: Icons.assignment_outlined,
                            iconColor: Colors.deepOrange,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đang có ${currentStats['reports']} báo cáo trong kỳ ($_displayPeriodLabel)',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.all(4),
                        child: Text(
                          "Thống kê",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Biểu đồ đường tương tác
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lượt tương tác ($_displayPeriodLabel)",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 200,
                              child: SfCartesianChart(
                                margin: EdgeInsets.zero,
                                plotAreaBorderWidth: 0, //tắt đường viền bao quanh khu vực vẽ đồ thị
                                tooltipBehavior: TooltipBehavior(enable: true),// hiển thị hộp thoại
                                legend: const Legend(  // chú thích
                                  isVisible: true,
                                  position: LegendPosition.top,
                                  overflowMode: LegendItemOverflowMode.wrap,//tự động xuống dòng nếu tên các mục chú giải quá dài
                                  toggleSeriesVisibility: true,// tính năng tương tác
                                ),
                                primaryXAxis: const CategoryAxis(
                                  majorGridLines: MajorGridLines(width: 0),// ẩn các đường lưới dọc
                                ),
                                primaryYAxis: const NumericAxis(
                                  axisLine: AxisLine(width: 0),// ẩn đường trục y
                                  majorTickLines: MajorTickLines( //  Ẩn các vạch chia nhỏ trên trục Y
                                    color: Colors.transparent,
                                  ),
                                ),
                                series: <CartesianSeries<_ChartData, String>>[
                                  // Đường 1: Lượt truy cập
                                  LineSeries<_ChartData, String>(
                                    name: 'Lượt truy cập',
                                    dataSource: currentChartData,
                                    xValueMapper: (_ChartData data, _) =>
                                    data.day,
                                    yValueMapper: (_ChartData data, _) =>
                                    data.views,
                                    color: AppColors.primaryGreen,
                                    width: 3,
                                    enableTooltip: true,// cho phép kích hoạt hiển thị hộp thoại
                                    markerSettings: const MarkerSettings( // vẽ các chấm tròn
                                      isVisible: true,
                                    ),
                                  ),

                                  // Đường 2: Lượt tìm phòng
                                  LineSeries<_ChartData, String>(
                                    name: 'Lượt tìm phòng',
                                    dataSource: currentChartData,
                                    xValueMapper: (_ChartData data, _) =>
                                    data.day,
                                    yValueMapper: (_ChartData data, _) =>
                                    data.searches,
                                    color: Colors.amber,
                                    width: 3,
                                    enableTooltip: true,
                                    markerSettings: const MarkerSettings(
                                      isVisible: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.rewview);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.adminStats);
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

// Dữ liệu biểu đồ
class _ChartData {
  _ChartData(this.day, this.views, this.searches);
  final String day;
  final double views;
  final double searches;
}

// Sub-widget Thẻ Thống kê
class StarCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const StarCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: iconColor),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}