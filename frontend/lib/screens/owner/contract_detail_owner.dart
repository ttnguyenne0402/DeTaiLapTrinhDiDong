import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../screens/owner/contract_members.dart';
import '../../services/owner/contract_service.dart';

class ContractDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? contract;

  const ContractDetailScreen({super.key, required this.contract});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  Map<String, dynamic> get _c => widget.contract ?? {};
  String get _contractId => (_c['id'] ?? _c['code'] ?? '').toString();

  List<dynamic> _members = [];
  List<dynamic> _services = [];
  bool _isLoadingExtra = false;

  @override
  void initState() {
    super.initState();
    _loadExtraData();
  }

  Future<void> _loadExtraData() async {
    if (_contractId.isEmpty) return;
    setState(() => _isLoadingExtra = true);

    // Tải danh sách người ở cùng thực tế
    final mems = await ContractService.getContractMembers(_contractId);

    // Tải dịch vụ nếu có roomId
    final roomId = (_c['roomId'] ?? _c['RoomId'])?.toString();
    List<dynamic> srvs = [];
    if (roomId != null && roomId.isNotEmpty) {
      final srvRes = await ContractService.getRoomServices(roomId);
      if (srvRes is Map) {
        srvs = (srvRes['defaultServices'] as List<dynamic>? ?? []);
      }
    }

    if (mounted) {
      setState(() {
        _members = mems;
        _services = srvs;
        _isLoadingExtra = false;
      });
    }
  }

  String _formatMoney(dynamic amount) {
    if (amount == null) return '0 đ';
    final str = amount.toString().replaceAll('đ', '').replaceAll('.', '').replaceAll(',', '').trim();
    final numVal = double.tryParse(str) ?? 0;
    return '${numVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết hợp đồng thuê',
          style: TextStyle(color: AppColors.cardSurface, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildContractSummaryCard(),
                    const SizedBox(height: 16),
                    _buildTenantSection(),
                    const SizedBox(height: 16),
                    _buildFinancialSection(),
                    const SizedBox(height: 16),
                    _buildESignatureSection(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractSummaryCard() {
    final code = _c['code'] ?? 'Chưa có mã';
    final status = _c['status'] ?? 'Đang hiệu lực';
    final room = _c['room'] ?? 'Phòng trọ';
    final address = _c['address'] ?? 'Khu trọ';
    final duration = _c['duration'] ?? '';
    final timeText = _c['timeText'] ?? 'Đang hoạt động';

    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MÃ HỢP ĐỒNG: $code',
                  style: const TextStyle(color: AppColors.cardSurface, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status, style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            room,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.cardSurface),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.lightGreen),
              const SizedBox(width: 4),
              Expanded(
                child: Text(address, style: const TextStyle(color: AppColors.lightGreen, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: AppColors.accentYellow),
                    const SizedBox(width: 6),
                    Text(duration.isNotEmpty ? duration : 'Thời hạn hợp đồng', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(timeText, style: const TextStyle(color: AppColors.accentYellow, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantSection() {
    final name = _c['tenantName'] ?? 'Chưa rõ họ tên';
    final phone = _c['tenantPhone'] ?? 'Chưa có SĐT';
    final totalOccupants = 1 + _members.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text('Người thuê đại diện (Chủ hộ)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.lightGreen,
                child: Icon(Icons.person, color: AppColors.primaryGreen, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('SĐT: $phone', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.group_outlined, size: 18, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nhân khẩu trong phòng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('$totalOccupants người lưu trú (1 đại diện + ${_members.length} ở ghép)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TenantManagementScreen(contract: _c),
                      ),
                    );
                    _loadExtraData();
                  },
                  child: const Row(
                    children: [
                      Text('Quản lý', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.primaryGreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection() {
    final rent = _c['rentPrice'] ?? '0';
    final deposit = _c['depositPrice'] ?? '0';
    final cycle = _c['cycleText'] ?? 'Hàng tháng';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text('Tài chính & Dịch vụ áp dụng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIỀN THUÊ', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_formatMoney(rent), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(cycle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIỀN ĐẶT CỌC', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_formatMoney(deposit), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      const SizedBox(height: 2),
                      const Text('Đã đối soát cọc', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_services.isNotEmpty) ...[
            const Text('Bảng giá dịch vụ đã áp dụng:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            ..._services.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s['name'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  Text('${_formatMoney(s['price'])} / ${s['unit'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  // Widget hiển thị chữ ký hai bên đồng bộ giống màn hình thanh lý
  Widget _buildESignatureSection() {
    final tenantName = _c['tenantName'] ?? 'Khách thuê';
    final ownerName = _c['ownerName'] ?? 'Trần Thanh Trúc';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text('Chữ ký số hợp đồng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _signatureBox('Chủ nhà (Bên A)', ownerName)),
              const SizedBox(width: 12),
              Expanded(child: _signatureBox('Khách thuê (Bên B)', tenantName)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signatureBox(String role, String name) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(role,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Text(name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.primaryGreen, size: 14),
              SizedBox(width: 4),
              Text('Đã ký số',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
        label: const Text('Quay lại danh sách', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}