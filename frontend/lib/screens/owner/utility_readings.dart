
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/utility_card_w.dart';
import '../../widgets/owner/owner_drawer.dart';

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  int _selectedFilterIndex = 0;

  final Map<String, RoomUtilityStatus> _roomStatuses = {
    '201': RoomUtilityStatus.completed,
    '302': RoomUtilityStatus.abnormal,
    '102': RoomUtilityStatus.inputting,
    '204': RoomUtilityStatus.pending,
  };

  final Map<String, String> _elecNewValues = {
    '201': '1545',
  };

  final Map<String, String> _waterNewValues = {
    '201': '91',
  };

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
      SnackBar(content: Text('Đã lưu chỉ số mẫu phòng $room.')),
    );
  }

  bool _matchesFilter(RoomUtilityStatus status) {
    switch (_selectedFilterIndex) {
      case 1:
        return status == RoomUtilityStatus.pending ||
            status == RoomUtilityStatus.inputting;
      case 2:
        return status == RoomUtilityStatus.completed;
      case 3:
        return status == RoomUtilityStatus.abnormal;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = [
      _RoomInfo(
        id: '201',
        roomName: 'Phòng 201',
        tenant: 'Hoàng Minh Trí (Tầng 2)',
        status: RoomUtilityStatus.completed,
        elecOld: '1420',
        waterOld: '85',
        totalAmount: '625.000đ',
        elecCost: '475.000đ',
        waterCost: '150.000đ',
        proofCount: 2,
      ),
      _RoomInfo(
        id: '302',
        roomName: 'Phòng 302',
        tenant: 'Trần Thị Bích',
        phone: '0933 555 789',
        status: RoomUtilityStatus.abnormal,
        elecOld: '980',
        waterOld: '42',
        warningTag: 'Tăng đột biến +85%',
        warningMessage:
        'Số điện tháng này cao bất thường. Khuyến nghị đối chiếu lại ảnh đồng hồ trước khi lập hóa đơn.',
      ),
      _RoomInfo(
        id: '102',
        roomName: 'Phòng 102',
        tenant: 'Lê Văn Cường (Tầng 1)',
        status: RoomUtilityStatus.inputting,
        elecOld: '650',
        waterOld: '38',
      ),
      _RoomInfo(
        id: '204',
        roomName: 'Phòng 204',
        tenant: 'Phạm Thị Duyên (Tầng 2)',
        status: RoomUtilityStatus.pending,
        elecOld: '810',
        waterOld: '49',
      ),
    ];

    final filteredRooms = rooms.where((room) {
      return _matchesFilter(_roomStatuses[room.id] ?? room.status);
    }).toList();

    final completedCount = _roomStatuses.values
        .where((status) => status == RoomUtilityStatus.completed)
        .length;

    final pendingCount = _roomStatuses.values
        .where((status) =>
    status == RoomUtilityStatus.pending ||
        status == RoomUtilityStatus.inputting)
        .length;

    final progress = completedCount / rooms.length;

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
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            _buildGreenInfoCard(),
                            const SizedBox(height: 12),
                            _buildProgressCard(
                              completedCount,
                              rooms.length,
                              pendingCount,
                              progress,
                            ),
                            const SizedBox(height: 12),
                            _buildOcrBanner(),
                            const SizedBox(height: 12),
                            _buildFilterTabs(
                              rooms.length,
                              pendingCount,
                              completedCount,
                            ),
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
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 38,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text('Không có phòng phù hợp.'),
                                  ],
                                ),
                              ),

                            for (final room in filteredRooms) ...[
                              RoomUtilityCard(
                                key: ValueKey(
                                  '${room.id}_${_roomStatuses[room.id]}',
                                ),
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
                                onSave: (elec, water) =>
                                    _saveReading(room.id, elec, water),
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
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          const Expanded(
            child: Text(
              'Ghi số điện nước',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildGreenInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Kỳ chốt: Tháng 08/2024',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(Icons.history, color: Colors.white70, size: 18),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'CƠ SỞ CHO THUÊ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.corporate_fare,
                color: AppColors.warningOrange,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Khu Trọ Xanh - Bình Thạnh',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '12 phòng',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      int completed,
      int total,
      int pending,
      double progress,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiến độ ghi số',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'Còn $pending phòng',
                style: const TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã hoàn thành $completed trên $total phòng',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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

  Widget _buildOcrBanner() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chức năng quét AI OCR dùng để demo UI.'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.document_scanner_outlined,
              color: AppColors.primaryGreen,
              size: 26,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quét AI OCR hàng loạt',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Chụp đồng hồ và nhận diện chỉ số tự động',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(
      int total,
      int pending,
      int completed,
      ) {
    final filters = [
      {'title': 'Tất cả', 'count': '$total'},
      {'title': 'Chưa ghi', 'count': '$pending'},
      {'title': 'Đã ghi', 'count': '$completed'},
      {'title': 'Bất thường', 'count': ''},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final selected = _selectedFilterIndex == index;
          final alert = index == 3;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              showCheckmark: false,
              selectedColor: alert
                  ? Colors.redAccent
                  : AppColors.primaryGreen,
              backgroundColor: Colors.white,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (alert) ...[
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    filters[index]['title']!,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : alert
                          ? Colors.redAccent
                          : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (filters[index]['count']!.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Text(
                      filters[index]['count']!,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTipBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppColors.primaryGreen,
            size: 28,
          ),
          SizedBox(height: 5),
          Text(
            'Mẹo ghi nhanh chỉ số',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(height: 5),
          Text(
            'Có thể bật đèn flash khi chụp ảnh đồng hồ '
                'để dễ đọc chỉ số trong khu vực thiếu sáng.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
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
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng dự kiến ($completed phòng đã ghi)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Text(
                    '6.850.000 đ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.water_drop_outlined,
                color: AppColors.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã lưu bản nháp giao diện mẫu.'),
                      ),
                    );
                  },
                  child: const Text('Lưu nháp'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chốt số và tạo hóa đơn mẫu.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text(
                    'Chốt số & Tạo hóa đơn',
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warningOrange,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomInfo {
  final String id;
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
