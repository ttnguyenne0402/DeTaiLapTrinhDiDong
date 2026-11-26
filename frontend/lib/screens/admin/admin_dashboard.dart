import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../services/admin/admin_dashboard_service.dart';
import '../../services/auth_storage.dart';
import '../tenant/profile_screen.dart';

enum _ReviewPeriod {
  today('Hôm nay'),
  week('7 ngày qua'),
  month('Tháng này'),
  previousMonth('Tháng trước'),
  quarter('Quý này'),
  year('Năm nay'),
  custom('Chọn khoảng ngày');

  const _ReviewPeriod(this.label);
  final String label;
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const _ink = Color(0xFF122C26);
  static const _paper = Color(0xFFF4F7F3);
  static const _muted = Color(0xFF526760);
  static const _line = Color(0xFFDCE7DF);
  static const _accent = Color(0xFFC8F1A7);
  static const _published = Color(0xFF247052);
  static const _rejected = Color(0xFFA14C2E);

  _ReviewPeriod _period = _ReviewPeriod.month;
  DateTimeRange? _customRange;
  AdminDashboardData? _data;
  bool _isLoading = true;
  bool _loadFailed = false;
  int _request = 0;
  late Future<String?> _name;

  @override
  void initState() {
    super.initState();
    _name = AuthStorage.getUserName();
    _loadDashboard();
  }

  (DateTime, DateTime) _dates() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final month = DateTime(now.year, now.month);
    return switch (_period) {
      _ReviewPeriod.today => (midnight, now),
      _ReviewPeriod.week => (DateTime(now.year, now.month, now.day - 6), now),
      _ReviewPeriod.month => (month, now),
      _ReviewPeriod.previousMonth => (
        DateTime(now.year, now.month - 1),
        month.subtract(const Duration(milliseconds: 1)),
      ),
      _ReviewPeriod.quarter => (
        DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1),
        now,
      ),
      _ReviewPeriod.year => (DateTime(now.year), now),
      _ReviewPeriod.custom => (
        _customRange!.start,
        DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day + 1,
        ).subtract(const Duration(milliseconds: 1)),
      ),
    };
  }

  Future<void> _loadDashboard() async {
    final request = ++_request;
    final (startDate, endDate) = _dates();
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final data = await AdminDashboardService.fetchStats(
        startDate: startDate,
        endDate: endDate,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Không tải được trang quản trị: $error');
      if (!mounted || request != _request) return;
      setState(() {
        _data = null;
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _selectPeriod(_ReviewPeriod period) async {
    if (period == _ReviewPeriod.custom) {
      final now = DateTime.now();
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
        initialDateRange: _customRange,
      );
      if (!mounted || range == null) return;
      _customRange = range;
    }

    setState(() => _period = period);
    await _loadDashboard();
  }

  Future<void> _openSection(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) await _loadDashboard();
  }

  Future<void> _openProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
    if (mounted) setState(() => _name = AuthStorage.getUserName());
  }

  String _count(int? value) {
    if (_isLoading || value == null) return '—';
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }

  String get _periodLabel {
    if (_period != _ReviewPeriod.custom) return _period.label;
    final range = _customRange!;
    return '${range.start.day}/${range.start.month} – '
        '${range.end.day}/${range.end.month}/${range.end.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Text(
          'Trang quản trị',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              tooltip: 'Hồ sơ của tôi',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.lightGreen,
                foregroundColor: _ink,
              ),
              onPressed: _openProfile,
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _loadDashboard,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth >= 600 ? 32 : 20,
                12,
                constraints.maxWidth >= 600 ? 32 : 20,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FutureBuilder<String?>(
                        future: _name,
                        builder: (context, snapshot) {
                          final name = snapshot.data?.trim() ?? '';
                          return Text(
                            name.isEmpty
                                ? 'Xin chào, quản trị viên'
                                : 'Xin chào, $name',
                            style: const TextStyle(fontSize: 16, color: _muted),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildQueue(),
                      if (_loadFailed) ...[
                        const SizedBox(height: 14),
                        _buildLoadError(),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Tổng quan hệ thống',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _metricCard(
                              icon: Icons.people_outline_rounded,
                              label: 'Người dùng',
                              count: _data?.totalUsers,
                              onTap: () => _openSection(AppRoutes.usersManage),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              icon: Icons.apartment_rounded,
                              label: 'Phòng',
                              count: _data?.totalRooms,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildReviewResults(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.lightGreen,
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              _openSection(AppRoutes.rewview);
            case 2:
              _openSection(AppRoutes.adminStats);
            case 3:
              _openSection(AppRoutes.usersManage);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Duyệt tin',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _buildQueue() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF104638),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tin chờ duyệt',
                        style: TextStyle(
                          color: Color(0xFFD8EDE2),
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _count(_data?.pendingPosts),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF245B4A),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(
                      Icons.fact_check_outlined,
                      size: 29,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _openSection(AppRoutes.rewview),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _ink,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Mở trang duyệt tin'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required int? count,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: _published, size: 23),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_outward_rounded,
                      size: 17,
                      color: _muted,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(color: _muted)),
              const SizedBox(height: 2),
              Text(
                _count(count),
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewResults() {
    final approved = _data?.approvedPosts ?? 0;
    final rejected = _data?.rejectedPosts ?? 0;
    final total = approved + rejected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              const Text(
                'Kết quả duyệt tin',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              PopupMenuButton<_ReviewPeriod>(
                tooltip: 'Lọc kết quả theo ngày',
                onSelected: _selectPeriod,
                itemBuilder: (context) => _ReviewPeriod.values.map((period) {
                  return PopupMenuItem(
                    value: period,
                    child: Text(period.label),
                  );
                }).toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.date_range_outlined,
                        size: 17,
                        color: _published,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _periodLabel,
                        style: const TextStyle(color: _published),
                      ),
                      const Icon(
                        Icons.expand_more_rounded,
                        size: 17,
                        color: _published,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _reviewBar('Đã duyệt', _data?.approvedPosts, total, _published),
          const SizedBox(height: 14),
          _reviewBar('Đã từ chối', _data?.rejectedPosts, total, _rejected),
        ],
      ),
    );
  }

  Widget _reviewBar(String label, int? count, int total, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: _muted)),
            Text(
              _count(count),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: _isLoading || total == 0 ? 0 : (count ?? 0) / total,
          minHeight: 7,
          borderRadius: BorderRadius.circular(7),
          color: color,
          backgroundColor: _paper,
          semanticsLabel: label,
          semanticsValue: _count(count),
        ),
      ],
    );
  }

  Widget _buildLoadError() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Không tải được số liệu.',
            style: TextStyle(color: _rejected),
          ),
        ),
        TextButton(onPressed: _loadDashboard, child: const Text('Thử lại')),
      ],
    );
  }
}
