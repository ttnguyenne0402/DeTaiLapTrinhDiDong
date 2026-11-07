import 'owner_profile_screen.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/utility_card_w.dart';
import '../../services/owner/invoice_service.dart';

class InvoiceCreateScreen extends StatefulWidget {
  final String? propertyId;
  final String? propertyName;

  const InvoiceCreateScreen({super.key, this.propertyId, this.propertyName});

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  int _selectedFilterIndex = 0;
  bool _isLoading = true;

  List<_RoomInfo> _rooms = [];
  final Map<String, RoomUtilityStatus> _roomStatuses = {};
  final Map<String, String> _elecNewValues = {};
  final Map<String, String> _waterNewValues = {};

  @override
  void initState() {
    super.initState();
    _fetchRoomsSummary();
  }

  Future<void> _fetchRoomsSummary() async {
    setState(() => _isLoading = true);

    try {
      final res = await OwnerInvoiceService.getRoomsUtilitySummary(propertyId: widget.propertyId);

      if (mounted && res is List) {
        final List<_RoomInfo> loaded = [];

        for (var item in res) {
          final id = item['roomId']?.toString() ?? item['contractId']?.toString() ?? '';
          final contractId = item['contractId']?.toString() ?? '';
          final roomName = item['roomName']?.toString() ?? 'Phòng';
          final tenant = item['tenantName']?.toString() ?? 'Khách thuê';
          final phone = item['phone']?.toString() ?? '';
          final elecOld = item['elecOld']?.toString() ?? '0';
          final waterOld = item['waterOld']?.toString() ?? '0';

          loaded.add(_RoomInfo(
            id: id,
            contractId: contractId,
            roomName: roomName,
            tenant: tenant,
            phone: phone,
            status: RoomUtilityStatus.pending,
            elecOld: elecOld,
            waterOld: waterOld,
          ));

          _roomStatuses[id] = RoomUtilityStatus.pending;
        }

        setState(() {
          _rooms = loaded;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Lỗi nạp danh sách phòng: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _enterInput(String room) {
    setState(() {
      _roomStatuses[room] = RoomUtilityStatus.inputting;
    });
  }

  void _saveReading(String room, String elec, String water) {
    setState(() {
      _elecNewValues[room] = elec;
      _waterNewValues[room] = water;
      _roomStatuses[room] = RoomUtilityStatus.completed;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã ghi nhận chỉ số phòng $room.')),
    );
  }

  bool _matchesFilter(RoomUtilityStatus status) {
    switch (_selectedFilterIndex) {
      case 1:
        return status == RoomUtilityStatus.pending || status == RoomUtilityStatus.inputting;
      case 2:
        return status == RoomUtilityStatus.completed;
      case 3:
        return status == RoomUtilityStatus.abnormal;
      default:
        return true;
    }
  }

  Future<void> _submitAllCompleted() async {
    final completedRooms = _rooms.where((r) => _roomStatuses[r.id] == RoomUtilityStatus.completed).toList();

    if (completedRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có phòng nào được nhập chỉ số mới để chốt!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    int successCount = 0;
    final now = DateTime.now();

    for (var r in completedRooms) {
      final newEl = double.tryParse(_elecNewValues[r.id] ?? '') ?? double.tryParse(r.elecOld ?? '0') ?? 0;
      final newWt = double.tryParse(_waterNewValues[r.id] ?? '') ?? double.tryParse(r.waterOld ?? '0') ?? 0;

      final body = {
        'contractId': r.contractId,
        'month': now.month,
        'year': now.year,
        'newElectric': newEl,
        'newWater': newWt,
        'discountAmount': 0,
        'status': 'unpaid',
      };

      final res = await OwnerInvoiceService.createInvoice(body);
      if (res != null) successCount++;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chốt số và tạo thành công $successCount hóa đơn!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRooms = _rooms.where((room) {
      return _matchesFilter(_roomStatuses[room.id] ?? room.status);
    }).toList();

    final completedCount = _roomStatuses.values.where((status) => status == RoomUtilityStatus.completed).length;

    final pendingCount = _roomStatuses.values
        .where((status) => status == RoomUtilityStatus.pending || status == RoomUtilityStatus.inputting)
        .length;

    final totalCount = _rooms.isEmpty ? 1 : _rooms.length;
    final progress = (completedCount / totalCount).clamp(0.0, 1.0);

    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Column(
                          children: [
                            _buildGreenInfoCard(now),
                            const SizedBox(height: 12),
                            _buildProgressCard(completedCount, _rooms.length, pendingCount, progress),
                            const SizedBox(height: 12),
                            _buildFilterTabs(_rooms.length, pendingCount, completedCount),
                            const SizedBox(height: 12),

                            if (filteredRooms.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.inbox_outlined, size: 38, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Không có phòng nào cần hiển thị.'),
                                  ],
                                ),
                              ),

                            for (final room in filteredRooms) ...[
                              RoomUtilityCard(
                                key: ValueKey('${room.id}_${_roomStatuses[room.id]}'),
                                roomName: room.roomName,
                                tenantName: room.tenant,
                                phone: room.phone,
                                status: _roomStatuses[room.id] ?? room.status,
                                totalAmount: room.totalAmount,
                                elecOld: int.tryParse(room.elecOld ?? ''),
                                elecNew: int.tryParse(_elecNewValues[room.id] ?? ''),
                                waterOld: int.tryParse(room.waterOld ?? ''),
                                waterNew: int.tryParse(_waterNewValues[room.id] ?? ''),
                                waterCost: room.waterCost,
                                warningTag: room.warningTag,
                                warningMessage: room.warningMessage,
                                proofImagesCount: room.proofCount,
                                onEnterInput: () => _enterInput(room.id),
                                onSave: (elec, water) => _saveReading(room.id, elec, water),
                              ),
                              const SizedBox(height: 12),
                            ],

                            _buildTipBox(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomFooter(completedCount),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Ghi số điện nước đồng loạt',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchRoomsSummary,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildGreenInfoCard(DateTime now) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Kỳ chốt: Tháng ${now.month.toString().padLeft(2, '0')}/${now.year}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.history, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.corporate_fare, color: AppColors.accentYellow, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.propertyName ?? 'Cơ sở cho thuê',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Text('${_rooms.length} phòng', style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, int pending, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiến độ ghi số', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Còn $pending phòng', style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Đã hoàn thành $completed trên $total phòng', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.lightGreen,
              color: AppColors.warningOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(int total, int pending, int completed) {
    final filters = [
      {'title': 'Tất cả', 'count': '$total'},
      {'title': 'Chưa ghi', 'count': '$pending'},
      {'title': 'Đã ghi', 'count': '$completed'},
    ];

    return Row(
      children: List.generate(filters.length, (index) {
        final selected = _selectedFilterIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            selected: selected,
            showCheckmark: false,
            selectedColor: AppColors.primaryGreen,
            backgroundColor: Colors.white,
            label: Text(
              '${filters[index]['title']} (${filters[index]['count']})',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            onSelected: (_) => setState(() => _selectedFilterIndex = index),
          ),
        );
      }),
    );
  }

  Widget _buildTipBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.primaryGreen, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nhập chỉ số mới cho các phòng và bấm "Chốt số & Tạo hóa đơn" để hệ thống tự động sinh hóa đơn hàng loạt.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomFooter(int completed) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton.icon(
          onPressed: completed > 0 ? _submitAllCompleted : null,
          icon: const Icon(Icons.receipt_long, color: Colors.white),
          label: Text(
            'Chốt số & Tạo hóa đơn ($completed phòng)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warningOrange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}

class _RoomInfo {
  final String id;
  final String contractId;
  final String roomName;
  final String tenant;
  final String? phone;
  final RoomUtilityStatus status;
  final String? elecOld;
  final String? waterOld;
  final String? totalAmount;
  final String? elecCost;
  final String? waterCost;
  final String? warningTag;
  final String? warningMessage;
  final int proofCount;

  const _RoomInfo({
    required this.id,
    required this.contractId,
    required this.roomName,
    required this.tenant,
    required this.status,
    this.phone,
    this.elecOld,
    this.waterOld,
    this.totalAmount,
    this.elecCost,
    this.waterCost,
    this.warningTag,
    this.warningMessage,
    this.proofCount = 0,
  });
}