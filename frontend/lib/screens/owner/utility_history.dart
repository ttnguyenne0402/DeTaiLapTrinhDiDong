import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/invoice_service.dart';
import 'utility_readings.dart';
import 'owner_profile_screen.dart';

class LandlordUtilityScreen extends StatefulWidget {
  final String? propertyId;
  final String? propertyName;

  const LandlordUtilityScreen({super.key, this.propertyId, this.propertyName});

  @override
  State<LandlordUtilityScreen> createState() => _LandlordUtilityScreenState();
}

class _LandlordUtilityScreenState extends State<LandlordUtilityScreen> {
  bool _isLoading = true;
  bool _isRoomView = true;

  List<dynamic> _rooms = [];
  String? _selectedRoomId;
  String _selectedRoomName = 'Phòng';

  List<dynamic> _historyData = [];
  double _avgElec = 0;
  double _avgWater = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    // Truyền propertyId vào đây để lọc đúng phòng của khu trọ được bấm
    final contracts = await OwnerInvoiceService.getActiveContracts(propertyId: widget.propertyId);

    if (mounted && contracts is List && contracts.isNotEmpty) {
      _rooms = contracts;
      _selectedRoomId = _rooms.first['roomId']?.toString() ?? _rooms.first['contractId']?.toString();
      _selectedRoomName = _rooms.first['roomName']?.toString() ?? 'Phòng';

      if (_selectedRoomId != null) {
        await _fetchData();
      }
    } else {
      if (mounted) {
        setState(() {
          _rooms = [];
          _historyData = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    if (_isRoomView) {
      if (_selectedRoomId != null) {
        final res = await OwnerInvoiceService.getRoomUtilityHistory(_selectedRoomId!);
        if (mounted && res is List) {
          _historyData = res;
          _calculateAverages();
        }
      }
    } else {
      final Map<String, Map<String, dynamic>> combined = {};

      for (var r in _rooms) {
        final rId = r['roomId']?.toString() ?? r['contractId']?.toString();
        if (rId != null) {
          final res = await OwnerInvoiceService.getRoomUtilityHistory(rId);
          if (res is List) {
            for (var item in res) {
              final month = item['month']?.toString() ?? '';
              if (!combined.containsKey(month)) {
                combined[month] = {
                  'month': month,
                  'monthCode': item['monthCode'] ?? '',
                  'elecUsage': 0.0,
                  'waterUsage': 0.0,
                  'totalCost': 0.0,
                  'createdAt': item['createdAt'] ?? '',
                };
              }
              combined[month]!['elecUsage'] = (combined[month]!['elecUsage'] as double) + ((item['elecUsage'] as num?)?.toDouble() ?? 0.0);
              combined[month]!['waterUsage'] = (combined[month]!['waterUsage'] as double) + ((item['waterUsage'] as num?)?.toDouble() ?? 0.0);
              combined[month]!['totalCost'] = (combined[month]!['totalCost'] as double) + ((item['totalCost'] as num?)?.toDouble() ?? 0.0);
            }
          }
        }
      }

      if (mounted) {
        _historyData = combined.values.toList();
        _calculateAverages();
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _calculateAverages() {
    if (_historyData.isNotEmpty) {
      double totalE = 0;
      double totalW = 0;
      for (var item in _historyData) {
        totalE += (item['elecUsage'] as num?)?.toDouble() ?? 0;
        totalW += (item['waterUsage'] as num?)?.toDouble() ?? 0;
      }
      _avgElec = totalE / _historyData.length;
      _avgWater = totalW / _historyData.length;
    } else {
      _avgElec = 0;
      _avgWater = 0;
    }
  }

  String _formatMoney(double val) {
    return '${val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    )}đ';
  }

  @override
  Widget build(BuildContext context) {
    final latestPeriod = _historyData.isNotEmpty ? _historyData.first : null;

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
        title: Text(
          widget.propertyName != null ? 'Tiêu thụ: ${widget.propertyName}' : 'Lịch Sử Tiêu Thụ Điện Nước',
          style: const TextStyle(color: AppColors.cardSurface, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 16,
            child: IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.person, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerProfileScreen()));
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceCreateScreen(
                propertyId: widget.propertyId,
                propertyName: widget.propertyName,
              ),
            ),
          );
          if (res == true) {
            _fetchData();
          }
        },
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add, color: AppColors.cardSurface),
        label: const Text('Ghi chỉ số kỳ này', style: TextStyle(color: AppColors.cardSurface, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildViewTabs(),
              const SizedBox(height: 12),
              if (_isRoomView) ...[
                _buildRoomSelectorCard(),
                const SizedBox(height: 14),
              ],
              _buildAverageStats(),
              const SizedBox(height: 16),
              _buildConsumptionChartCard(),
              const SizedBox(height: 20),
              Text(
                _isRoomView ? 'Lịch sử chốt số: $_selectedRoomName' : 'Lịch sử tiêu thụ: Toàn bộ Khu trọ',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              if (_historyData.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('Chưa có dữ liệu chốt số điện nước trong hệ thống.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else ...[
                if (latestPeriod != null) ...[
                  _buildLatestPeriodCard(latestPeriod),
                  const SizedBox(height: 12),
                ],
                for (int i = 1; i < _historyData.length; i++) ...[
                  _buildPastPeriodCard(_historyData[i]),
                  const SizedBox(height: 10),
                ]
              ],
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isRoomView) {
                  setState(() => _isRoomView = true);
                  _fetchData();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isRoomView ? AppColors.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.meeting_room, size: 18, color: _isRoomView ? Colors.white : AppColors.textPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Xem theo Phòng',
                      style: TextStyle(color: _isRoomView ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isRoomView) {
                  setState(() => _isRoomView = false);
                  _fetchData();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isRoomView ? AppColors.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apartment, size: 18, color: !_isRoomView ? Colors.white : AppColors.textPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Toàn bộ Khu trọ',
                      style: TextStyle(color: !_isRoomView ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelectorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedRoomId,
          hint: const Text('Chọn phòng xem lịch sử'),
          items: _rooms.map((r) {
            final rid = r['roomId']?.toString() ?? r['contractId']?.toString() ?? '';
            final name = r['roomName']?.toString() ?? 'Phòng';
            final tenant = r['tenantName']?.toString() ?? 'Khách';
            return DropdownMenuItem<String>(
              value: rid,
              child: Text('$name ($tenant)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            );
          }).toList(),
          onChanged: (newId) {
            if (newId != null && newId != _selectedRoomId) {
              final matched = _rooms.firstWhere(
                    (r) => (r['roomId']?.toString() ?? r['contractId']?.toString()) == newId,
                orElse: () => null,
              );
              setState(() {
                _selectedRoomId = newId;
                _selectedRoomName = matched?['roomName']?.toString() ?? 'Phòng';
              });
              _fetchData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildAverageStats() {
    final titleSuffix = _isRoomView ? 'Phòng' : 'Khu trọ';
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.bolt,
            AppColors.accentYellow,
            'TB Điện ($titleSuffix)',
            '${_avgElec.toStringAsFixed(0)} kWh',
            'Dựa trên ${_historyData.length} kỳ chốt',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.water_drop,
            Colors.teal,
            'TB Nước ($titleSuffix)',
            '${_avgWater.toStringAsFixed(1)} m³',
            'Dựa trên ${_historyData.length} kỳ chốt',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, Color iconColor, String title, String value, String subText) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16), border: Border.all(width: 1.5, color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(subText, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildConsumptionChartCard() {
    final chartList = _historyData.reversed.toList();
    final chartTitle = _isRoomView ? 'Biểu đồ tiêu thụ $_selectedRoomName' : 'Tổng tiêu thụ Toàn bộ Khu trọ';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(chartTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              const Text('Xanh: Điện | Vàng: Nước', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          chartList.isEmpty
              ? const SizedBox(height: 120, child: Center(child: Text('Chưa có đủ dữ liệu để vẽ biểu đồ')))
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (chartList.length * 55.0).clamp(300.0, 1000.0),
              height: 240,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.grey.shade800,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = chartList[group.x.toInt()];
                        final type = rodIndex == 0 ? 'Điện' : 'Nước';
                        final unit = rodIndex == 0 ? 'kWh' : 'm³';
                        return BarTooltipItem(
                          '${item['month']}\n$type: ${rod.toY.toStringAsFixed(1)} $unit',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx < 0 || idx >= chartList.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              chartList[idx]['monthCode'] ?? '',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          );
                        },
                        reservedSize: 26,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(chartList.length, (i) {
                    final eVal = (chartList[i]['elecUsage'] as num?)?.toDouble() ?? 0.0;
                    final wVal = (chartList[i]['waterUsage'] as num?)?.toDouble() ?? 0.0;
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(toY: eVal, color: AppColors.primaryGreen, width: 8, borderRadius: BorderRadius.circular(3)),
                        BarChartRodData(toY: wVal, color: AppColors.accentYellow, width: 8, borderRadius: BorderRadius.circular(3)),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestPeriodCard(dynamic period) {
    final eUsage = (period['elecUsage'] as num?)?.toDouble() ?? 0;
    final wUsage = (period['waterUsage'] as num?)?.toDouble() ?? 0;
    final total = (period['totalCost'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryGreen,
                child: Text(period['monthCode'] ?? '01', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kỳ Tháng ${period['month']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('Ngày ghi: ${period['createdAt']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(_formatMoney(total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 12),
          _buildMeterSubCard(
            Icons.bolt,
            _isRoomView ? 'Điện: ${period['elecOld'] ?? 0} → ${period['elecNew'] ?? 0}' : 'Tổng tiêu thụ điện',
            '+${eUsage.toStringAsFixed(0)} kWh',
            _formatMoney((period['elecCost'] as num?)?.toDouble() ?? (eUsage * 3800)),
          ),
          const SizedBox(height: 8),
          _buildMeterSubCard(
            Icons.water_drop,
            _isRoomView ? 'Nước: ${period['waterOld'] ?? 0} → ${period['waterNew'] ?? 0}' : 'Tổng tiêu thụ nước',
            '+${wUsage.toStringAsFixed(1)} m³',
            _formatMoney((period['waterCost'] as num?)?.toDouble() ?? (wUsage * 25000)),
          ),
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
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPastPeriodCard(dynamic period) {
    final total = (period['totalCost'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lightGreen,
            child: Text(period['monthCode'] ?? '01', style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kỳ Tháng ${period['month']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                Text('Ngày ghi: ${period['createdAt']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(_formatMoney(total), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}