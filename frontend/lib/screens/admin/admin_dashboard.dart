import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../tenant/profile_screen.dart';
import '../../services/admin/admin_dashboard_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // 1. Quản lý bộ lọc thời gian
  String _selectedPeriod = 'Tháng này';
  DateTimeRange? _customDateRange;

  // Dữ liệu hứng từ Backend API
  AdminDashboardData? _dashboardData;
  bool _isLoading = false;

  final List<String> _periods = [
    'Hôm nay',
    '7 ngày qua',
    'Tháng này',
    'Tháng trước',
    'Quý này (Q4)',
    'Năm nay',
    'Tùy chọn ngày...',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData(); // Gọi API ngay khi mở màn hình
  }

  // Chuyển chuỗi lựa chọn thành khoảng ngày (start, end) gửi về Backend
  (DateTime, DateTime) _resolveDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Hôm nay':
        return (DateTime(now.year, now.month, now.day), now);
      case '7 ngày qua':
        return (now.subtract(const Duration(days: 7)), now);
      case 'Tháng trước':
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        final endOfPrevMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
        return (prevMonth, endOfPrevMonth);
      case 'Quý này (Q4)':
        return (DateTime(now.year, 10, 1), DateTime(now.year, 12, 31, 23, 59, 59));
      case 'Năm nay':
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31, 23, 59, 59));
      case 'Tùy chọn ngày...':
        if (_customDateRange != null) {
          return (_customDateRange!.start, _customDateRange!.end);
        }
        return (DateTime(now.year, now.month, 1), now);
      case 'Tháng này':
      default:
        return (DateTime(now.year, now.month, 1), now);
    }
  }

  // Hàm gọi API lấy dữ liệu thực tế
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final (start, end) = _resolveDateRange();
      final data = await AdminDashboardService.fetchStats(
        startDate: start,
        endDate: end,
      );
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Lỗi tải API Dashboard: $e");
    }
  }

  // 2. Danh sách thông báo nhanh
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

  int get _unreadCount =>
      _notifications.where((item) => item['isRead'] == false).length;

  String get _displayPeriodLabel {
    if (_selectedPeriod == 'Tùy chọn ngày...' && _customDateRange != null) {
      final start = _customDateRange!.start;
      final end = _customDateRange!.end;
      return '${start.day}/${start.month} - ${end.day}/${end.month}';
    }
    return _selectedPeriod;
  }

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
                  Flexible(
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
                          isThreeLine: true,
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
                      // Tiêu đề Dashboard + Dropdown chọn thời gian
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
                                isExpanded: false,
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
                                      _loadDashboardData(); // Gọi lại API sau khi chọn ngày
                                    }
                                  } else {
                                    setState(() {
                                      _selectedPeriod = newValue;
                                    });
                                    _loadDashboardData(); // Gọi lại API khi đổi mốc thời gian
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 4 Thẻ thống kê lấy số liệu từ API
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
                            value: _isLoading
                                ? '...'
                                : _formatNumber(_dashboardData?.totalUsers ?? 0),
                            icon: Icons.person_outline,
                            iconColor: Colors.green,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.usersManage,
                            ),
                          ),
                          StarCard(
                            title: 'Phòng đăng',
                            value: _isLoading
                                ? '...'
                                : _formatNumber(_dashboardData?.totalRooms ?? 0),
                            icon: Icons.home_outlined,
                            iconColor: Colors.amber,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.rewview,
                            ),
                          ),
                          StarCard(
                            title: 'Tin đã duyệt',
                            value: _isLoading
                                ? '...'
                                : _formatNumber(_dashboardData?.approvedPosts ?? 0),
                            icon: Icons.description_outlined,
                            iconColor: Colors.blue,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.rewview,
                            ),
                          ),
                          StarCard(
                            title: 'Báo cáo',
                            value: _isLoading
                                ? '...'
                                : _formatNumber(_dashboardData?.reports ?? 0),
                            icon: Icons.assignment_outlined,
                            iconColor: Colors.deepOrange,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đang có ${_dashboardData?.reports ?? 0} báo cáo trong kỳ ($_displayPeriodLabel)',
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

                      // Biểu đồ đường lấy điểm từ API
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
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : SfCartesianChart(
                                margin: EdgeInsets.zero,
                                plotAreaBorderWidth: 0,
                                tooltipBehavior: TooltipBehavior(enable: true),
                                legend: const Legend(
                                  isVisible: true,
                                  position: LegendPosition.top,
                                  overflowMode: LegendItemOverflowMode.wrap,
                                  toggleSeriesVisibility: true,
                                ),
                                primaryXAxis: const CategoryAxis(
                                  majorGridLines: MajorGridLines(width: 0),
                                ),
                                primaryYAxis: const NumericAxis(
                                  axisLine: AxisLine(width: 0),
                                  majorTickLines: MajorTickLines(
                                    color: Colors.transparent,
                                  ),
                                ),
                                series: <CartesianSeries<DashboardChartPoint, String>>[
                                  // Đường 1: Lượt truy cập
                                  LineSeries<DashboardChartPoint, String>(
                                    name: 'Lượt truy cập',
                                    dataSource: _dashboardData?.chartData ?? [],
                                    xValueMapper: (DashboardChartPoint data, _) =>
                                    data.day,
                                    yValueMapper: (DashboardChartPoint data, _) =>
                                    data.views,
                                    color: AppColors.primaryGreen,
                                    width: 3,
                                    enableTooltip: true,
                                    markerSettings: const MarkerSettings(
                                      isVisible: true,
                                    ),
                                  ),

                                  // Đường 2: Lượt tìm phòng
                                  LineSeries<DashboardChartPoint, String>(
                                    name: 'Lượt tìm phòng',
                                    dataSource: _dashboardData?.chartData ?? [],
                                    xValueMapper: (DashboardChartPoint data, _) =>
                                    data.day,
                                    yValueMapper: (DashboardChartPoint data, _) =>
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