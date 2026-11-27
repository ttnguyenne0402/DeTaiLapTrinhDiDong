import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_storage.dart';
import '../../services/owner/invoice_service.dart';
import '../../widgets/owner/utility_card_w.dart';
import 'invoice_form.dart';
import 'invoices_manage..dart';

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
  final Map<String, bool> _roomIsPaid = {};

  @override
  void initState() {
    super.initState();
    _fetchRoomsSummary();
  }

  Future<void> _fetchRoomsSummary() async {
    setState(() => _isLoading = true);

    try {
      final ownerId = await AuthStorage.getUserId();
      final res = await OwnerInvoiceService.getRoomsUtilitySummary(
        ownerId: ownerId,
        propertyId: widget.propertyId,
      );

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
          final elecNew = item['elecNew']?.toString();
          final waterNew = item['waterNew']?.toString();
          final isRecorded = item['isRecorded'] == true;
          final isPaid = item['isPaid'] == true;

          _roomIsPaid[id] = isPaid;

          if (isRecorded && elecNew != null && waterNew != null) {
            _elecNewValues[id] = elecNew;
            _waterNewValues[id] = waterNew;
            _roomStatuses[id] = RoomUtilityStatus.completed;
          } else if (_roomStatuses[id] == null) {
            _roomStatuses[id] = RoomUtilityStatus.pending;
          }

          loaded.add(_RoomInfo(
            id: id,
            contractId: contractId,
            roomName: roomName,
            tenant: tenant,
            phone: phone,
            status: _roomStatuses[id]!,
            elecOld: elecOld,
            waterOld: waterOld,
          ));
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
    if (_roomIsPaid[room] == true) {
      final targetRoom = _rooms.firstWhere((r) => r.id == room, orElse: () => _rooms.first);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.primaryGreen, size: 26),
              SizedBox(width: 8),
              Text('Đã thanh toán', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Hóa đơn phòng ${targetRoom.roomName} đã được người thuê thanh toán thành công! Không thể sửa chỉ số điện nước nữa.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _roomStatuses[room] = RoomUtilityStatus.inputting;
    });
  }

  Future<void> _saveReading(String room, String elec, String water) async {
    final index = _rooms.indexWhere((r) => r.id == room);
    final newEl = double.tryParse(elec);
    final newWt = double.tryParse(water);
    if (index < 0 || _roomIsPaid[room] == true || newEl == null || newWt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu chỉ số cho phòng này.')),
      );
      return;
    }
    final targetRoom = _rooms[index];

    final success = await OwnerInvoiceService.saveUtilityReading(
      contractId: targetRoom.contractId,
      newElectric: newEl,
      newWater: newWt,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _elecNewValues[room] = elec;
          _waterNewValues[room] = water;
          _roomStatuses[room] = RoomUtilityStatus.completed;
        });
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.info_outline,
                color: success ? AppColors.primaryGreen : Colors.orange,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                success ? 'Đã lưu chỉ số' : 'Chưa lưu được chỉ số',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            success
                ? 'Đã lưu chỉ số điện nước cho phòng ${targetRoom.roomName} vào CSDL thành công!'
                : 'Máy chủ chưa xác nhận lưu chỉ số phòng ${targetRoom.roomName}. Vui lòng thử lại.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
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
        const SnackBar(
          content: Text('Vui lòng nhập chỉ số điện nước mới và bấm "Lưu chỉ số" trước!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final ownerId = await AuthStorage.getUserId() ?? '';
    final monthlyData = await OwnerInvoiceService.getMonthlyInvoices(
      ownerId: ownerId,
      month: now.month,
      year: now.year,
    );

    List<dynamic> existingInvoices = [];
    if (monthlyData != null && monthlyData is Map && monthlyData['invoices'] is List) {
      existingInvoices = monthlyData['invoices'];
    }

    // Lọc ra các phòng đã thanh toán xong
    final paidRoomNames = <String>[];
    final processRooms = <_RoomInfo>[];

    for (var room in completedRooms) {
      final matchedInvoice = existingInvoices.firstWhere(
        (inv) {
          final rName = (inv['room'] ?? '').toString().toLowerCase();
          return rName.contains(room.roomName.toLowerCase()) || inv['id']?.toString() == room.contractId;
        },
        orElse: () => null,
      );

      if (matchedInvoice != null) {
        final invData = InvoiceData.fromJson(matchedInvoice as Map<String, dynamic>);
        if (invData.status == InvoiceStatus.paid) {
          paidRoomNames.add(room.roomName);
          continue;
        }
      }
      processRooms.add(room);
    }

    // Nếu TẤT CẢ các phòng được chọn đều ĐÃ THANH TOÁN
    if (processRooms.isEmpty && paidRoomNames.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.primaryGreen, size: 26),
              SizedBox(width: 8),
              Text('Tất cả đã thanh toán', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Hóa đơn Tháng ${now.month}/${now.year} của các phòng (${paidRoomNames.join(', ')}) đều đã được thanh toán thành công! Không cần lập hoặc cập nhật nữa.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // Nếu có phòng đã thanh toán xen kẽ phòng chưa thanh toán -> Báo nhẹ tên phòng đã thanh toán
    if (paidRoomNames.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bỏ qua ${paidRoomNames.join(', ')} do đã thanh toán xong.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    int issuedCount = 0;

    for (var room in processRooms) {
      if (!mounted) break;

      final newEl = double.tryParse(_elecNewValues[room.id] ?? '') ?? double.tryParse(room.elecOld ?? '0') ?? 0;
      final newWt = double.tryParse(_waterNewValues[room.id] ?? '') ?? double.tryParse(room.waterOld ?? '0') ?? 0;

      final matchedInvoice = existingInvoices.firstWhere(
        (inv) {
          final rName = (inv['room'] ?? '').toString().toLowerCase();
          return rName.contains(room.roomName.toLowerCase()) || inv['id']?.toString() == room.contractId;
        },
        orElse: () => null,
      );

      InvoiceData? invData;
      if (matchedInvoice != null) {
        invData = InvoiceData.fromJson(matchedInvoice as Map<String, dynamic>);
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Invoice_form(
            invoice: invData,
            contractId: room.contractId,
            initialNewElectric: newEl,
            initialNewWater: newWt,
          ),
        ),
      );

      if (result == true) {
        issuedCount++;
      } else {
        break;
      }
    }

    if (mounted) {
      _fetchRoomsSummary();

      if (issuedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã hoàn tất phát hành hóa đơn cho $issuedCount phòng!'),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                                isPaid: _roomIsPaid[room.id] == true,
                                totalAmount: room.totalAmount,
                                elecOld: num.tryParse(room.elecOld ?? ''),
                                elecNew: num.tryParse(_elecNewValues[room.id] ?? ''),
                                waterOld: num.tryParse(room.waterOld ?? ''),
                                waterNew: num.tryParse(_waterNewValues[room.id] ?? ''),
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
          icon: Icon(
            Icons.arrow_forward_rounded,
            color: completed > 0 ? Colors.white : Colors.grey.shade600,
          ),
          label: Text(
            completed > 0
                ? 'Xem / Cập nhật Hóa đơn ($completed phòng)'
                : 'Nhập số điện nước để lập hóa đơn',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: completed > 0 ? Colors.white : Colors.grey.shade600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            disabledBackgroundColor: Colors.grey.shade200,
            elevation: completed > 0 ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
