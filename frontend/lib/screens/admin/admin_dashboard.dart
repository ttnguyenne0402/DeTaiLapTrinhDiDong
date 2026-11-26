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
      'subtitle': 'Chủ trọ vừa gửi bài đăng phòng mới cần kiểm duyệt',
      'time': '5 phút trước',
      'isRead': false,
    },
    {
      'title': 'Đăng ký tài khoản mới',
      'subtitle': 'Có 18 tài khoản người dùng vừa đăng ký tham gia hệ thống',
      'time': '1 giờ trước',
      'isRead': false,
    },
    {
      'title': 'Cập nhật trạng thái tài khoản',
      'subtitle': 'Admin vừa xác nhận kích hoạt/khóa tài khoản hệ thống',
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
    String currentFilter = 'all';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final unreadCount = _notifications.where((n) => n['isRead'] == false).length;

            List<Map<String, dynamic>> filteredList = _notifications;
            if (currentFilter == 'unread') {
              filteredList = _notifications.where((n) => n['isRead'] == false).toList();
            } else if (currentFilter == 'post') {
              filteredList = _notifications.where((n) => (n['title'] ?? '').toString().toLowerCase().contains('tin') || (n['title'] ?? '').toString().toLowerCase().contains('bài')).toList();
            } else if (currentFilter == 'user') {
              filteredList = _notifications.where((n) => (n['title'] ?? '').toString().toLowerCase().contains('người') || (n['title'] ?? '').toString().toLowerCase().contains('báo cáo')).toList();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, color: AppColors.primaryGreen, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              unreadCount > 0 ? 'Thông báo ($unreadCount mới)' : 'Thông báo Admin',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        if (unreadCount > 0)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                for (var n in _notifications) {
                                  n['isRead'] = true;
                                }
                              });
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.done_all, size: 16, color: AppColors.primaryGreen),
                            label: const Text('Đọc tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                          ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        {'key': 'all', 'label': 'Tất cả (${_notifications.length})'},
                        {'key': 'unread', 'label': 'Chưa đọc ($unreadCount)'},
                        {'key': 'post', 'label': 'Duyệt tin đăng'},
                        {'key': 'user', 'label': 'Tài khoản người dùng'},
                      ].map((chip) {
                        final isSel = currentFilter == chip['key'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(chip['label']!),
                            selected: isSel,
                            selectedColor: AppColors.primaryGreen,
                            backgroundColor: Colors.white,
                            showCheckmark: false,
                            side: BorderSide(color: isSel ? AppColors.primaryGreen : Colors.grey.shade300),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : Colors.black87,
                            ),
                            onSelected: (selected) {
                              if (selected) setModalState(() => currentFilter = chip['key']!);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(child: Text('Không có thông báo nào', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              final bool isRead = item['isRead'] == true;
                              final String title = item['title'] ?? '';

                              IconData iconData = Icons.notifications_active;
                              Color iconColor = AppColors.primaryGreen;
                              Color iconBg = Colors.green.shade50;

                              if (title.contains('Tin') || title.contains('bài')) {
                                iconData = Icons.article_outlined;
                                iconColor = Colors.blue;
                                iconBg = Colors.blue.shade50;
                              } else if (title.contains('Tài khoản') || title.contains('người')) {
                                iconData = Icons.person_outline;
                                iconColor = Colors.teal;
                                iconBg = Colors.teal.shade50;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isRead ? Colors.white : Colors.green.shade50.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isRead ? Colors.grey.shade200 : AppColors.primaryGreen.withValues(alpha: 0.3)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: iconBg,
                                    child: Icon(iconData, color: iconColor, size: 22),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                            fontSize: 14,
                                            color: isRead ? Colors.black87 : Colors.black,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 3),
                                      Text(
                                        item['subtitle'] ?? '',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['time'] ?? '',
                                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() => item['isRead'] = true);
                                    Navigator.pop(context);
                                    if (title.contains('Tin') || title.contains('bài') || title.contains('Báo cáo')) {
                                      Navigator.pushNamed(context, AppRoutes.rewview);
                                    } else {
                                      Navigator.pushNamed(context, AppRoutes.usersManage);
                                    }
                                  },
                                ),
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
                      IconButton(
                        tooltip: 'Trợ lý AI Quản trị',
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.aiChat, arguments: {'role': 'admin'});
                        },
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Colors.amberAccent,
                        ),
                      ),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
        label: const Text(
          'AI Quản trị',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.aiChat, arguments: {'role': 'admin'});
        },
      ),
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