import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../services/owner/invoice_service.dart'; // Đảm bảo đúng đường dẫn tới service chứa hàm getLiquidationDetails của bạn

class ContractLiquidationScreen extends StatefulWidget {
  final String? contractId; // Nhận mã hợp đồng từ màn hình danh sách truyền sang

  const ContractLiquidationScreen({super.key, this.contractId});

  @override
  State<ContractLiquidationScreen> createState() =>
      _ContractLiquidationScreenState();
}

class _ContractLiquidationScreenState
    extends State<ContractLiquidationScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  final List<Map<String, dynamic>> _deductions = [];

  double get _totalDeductionAmount {
    double sum = 0;
    for (var d in _deductions) {
      if (d['amount'] is num) sum += (d['amount'] as num).toDouble();
    }
    return sum;
  }

  void _showAddDeductionDialog() {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Thêm khoản khấu trừ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tên hạng mục / Hư hỏng', hintText: 'VD: Hỏng khóa cửa'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Ghi chú lý do', hintText: 'VD: Làm gãy tay gạt khóa'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền khấu trừ (VNĐ)', hintText: 'VD: 150000'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () {
              final title = titleController.text.trim();
              final note = noteController.text.trim();
              final amt = double.tryParse(amountController.text.trim()) ?? 0;

              if (title.isNotEmpty) {
                setState(() {
                  _deductions.add({
                    'title': title,
                    'subtitle': note.isNotEmpty ? note : 'Khấu trừ khi bàn giao',
                    'amount': amt,
                    'isWarning': amt > 0,
                  });
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Thêm mới', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  final TextEditingController _elecNewController = TextEditingController();
  final TextEditingController _waterNewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _elecNewController.addListener(() => setState(() {}));
    _waterNewController.addListener(() => setState(() {}));
    _fetchLiquidationData();
  }

  @override
  void dispose() {
    _elecNewController.dispose();
    _waterNewController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiquidationData() async {
    setState(() => _isLoading = true);

    final id = widget.contractId ?? 'ctr_01';
    final res = await OwnerInvoiceService.getLiquidationDetails(id);

    if (mounted) {
      setState(() {
        _data = res;
        if (_data != null) {
          final eOld = (_data!['elecOld'] is num) ? (_data!['elecOld'] as num).toDouble() : 0.0;
          final wOld = (_data!['waterOld'] is num) ? (_data!['waterOld'] as num).toDouble() : 0.0;
          final eNew = (_data!['elecNew'] is num) ? (_data!['elecNew'] as num).toDouble() : eOld;
          final wNew = (_data!['waterNew'] is num) ? (_data!['waterNew'] as num).toDouble() : wOld;

          _elecNewController.text = eNew.toInt().toString();
          _waterNewController.text = wNew.toInt().toString();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primaryGreen,
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_data == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryGreen,
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Không tìm thấy dữ liệu thanh lý hợp đồng',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

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
        title: const Text(
          'Thanh lý hợp đồng',
          style: TextStyle(
            color: AppColors.cardSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 16,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // bo góc tròn 24px phía trên trái và phải
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // thanh tiến trình step tracker
              _buildStepTracker(),
              const SizedBox(height: 20),

              // thẻ thông tin hợp đồng & cọc
              _buildContractCard(),
              const SizedBox(height: 16),

              // phần kiểm tra hiện trạng bàn giao
              _buildInspectionSection(),
              const SizedBox(height: 16),

              // phần chốt chỉ số điện nước
              _buildUtilitySection(),
              const SizedBox(height: 16),

              // bảng quyết toán thanh lý
              _buildSettlementSummaryCard(),
              const SizedBox(height: 16),

              // thông tin chuyển khoản & bàn giao
              _buildTransferAndHandoverCard(),
              const SizedBox(height: 16),

              // phần chữ ký hai bên
              _buildSignatureSection(),
              const SizedBox(height: 24),

              // các nút hành động chính ở đáy
              _buildBottomActionButtons(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // thanh tiến trình 3 bước
  Widget _buildStepTracker() {
    return Row(
      children: [
        _buildStepItem(Icons.check, 'Nghiệm thu', true),
        Expanded(child: Container(height: 2, color: AppColors.primaryGreen)),
        _buildStepItem(Icons.check, 'Điện & Nước', true),
        Expanded(child: Container(height: 2, color: AppColors.primaryGreen)),
        _buildStepItem(Icons.grid_view, 'Quyết toán', true, isCurrent: true),
      ],
    );
  }

  Widget _buildStepItem(IconData icon, String label, bool isDone,
      {bool isCurrent = false}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isCurrent
              ? Colors.orange.shade700
              : (isDone ? AppColors.primaryGreen : Colors.grey.shade300),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Colors.orange.shade800 : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // thẻ thông tin hợp đồng và tiền cọc (Đã gắn dữ liệu thật từ API)
  Widget _buildContractCard() {
    final roomName = _data?['roomName'] ?? 'Phòng';
    final contractCode = _data?['contractCode'] ?? 'HD-000';
    final tenantName = _data?['tenantName'] ?? 'Khách thuê';
    final tenantPhone = _data?['tenantPhone'] ?? '';
    final startDate = _data?['startDate'] ?? '';
    final endDate = _data?['endDate'] ?? '';
    final deposit = _data?['deposit'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F382C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_outline, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(roomName,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Thanh lý hợp đồng',
                    style: TextStyle(color: Color(0xFFCBE2B5), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'HĐ #$contractCode',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.lightGreen, size: 16),
              const SizedBox(width: 6),
              Text('$tenantName • $tenantPhone',
                  style: const TextStyle(color: AppColors.lightGreen, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.lightGreen, size: 16),
              const SizedBox(width: 6),
              Text('$startDate ➔ $endDate',
                  style: const TextStyle(color: AppColors.lightGreen, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tiền cọc gốc đang giữ:',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                Text('$deposit đ',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // hạng mục kiểm tra bàn giao
  Widget _buildInspectionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1.5,
            color: Colors.grey.shade300,
          )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.archive_outlined, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text('Kiểm Tra Hiện Trạng Bàn Giao',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ],
              ),
              Text('${_deductions.length} hạng mục',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          if (_deductions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Chưa có khoản khấu trừ / bồi thường nào.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            for (var item in _deductions) ...[
              _buildInspectionItem(
                title: item['title'] ?? '',
                subtitle: item['subtitle'] ?? '',
                statusText: (item['amount'] == null || item['amount'] == 0) ? 'Bình thường' : null,
                amount: (item['amount'] != null && item['amount'] > 0) ? '-${_formatMoney(item['amount'])}' : null,
                isWarning: item['isWarning'] == true,
                hasImage: item['hasImage'] == true,
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddDeductionDialog,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Thêm khoản bồi thường / khấu trừ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionItem({
    required String title,
    required String subtitle,
    String? statusText,
    String? amount,
    required bool isWarning,
    bool hasImage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF1F1) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: isWarning ? Colors.red : AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: isWarning ? Colors.red : AppColors.textSecondary)),
                  ],
                ),
              ),
              if (statusText != null)
                Text(statusText,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              if (amount != null)
                Text(amount,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
            ],
          ),
          if (hasImage) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 50,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Ảnh chụp biên bản bàn giao',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUtilitySection() {
    final elecOld = (_data?['elecOld'] is num) ? (_data!['elecOld'] as num).toDouble() : 0.0;
    final waterOld = (_data?['waterOld'] is num) ? (_data!['waterOld'] as num).toDouble() : 0.0;

    final elecPrice = (_data?['elecPrice'] is num) ? (_data!['elecPrice'] as num).toDouble() : 3800.0;
    final waterPrice = (_data?['waterPrice'] is num) ? (_data!['waterPrice'] as num).toDouble() : 25000.0;

    final elecNew = double.tryParse(_elecNewController.text) ?? elecOld;
    final waterNew = double.tryParse(_waterNewController.text) ?? waterOld;

    final elecUsage = (elecNew - elecOld) > 0 ? (elecNew - elecOld) : 0.0;
    final waterUsage = (waterNew - waterOld) > 0 ? (waterNew - waterOld) : 0.0;

    final elecCost = elecUsage * elecPrice;
    final waterCost = waterUsage * waterPrice;
    final utilityTotal = elecCost + waterCost;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5
          )
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text('Chốt Chỉ Số Điện & Nước',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Kỳ cuối',
                    style: TextStyle(fontSize: 11, color: AppColors.primaryGreen)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUtilityInputRow(
            Icons.bolt,
            'Điện sinh hoạt (kWh)',
            elecOld,
            _elecNewController,
            elecUsage,
            elecPrice,
            elecCost,
          ),
          const SizedBox(height: 10),
          _buildUtilityInputRow(
            Icons.water_drop,
            'Nước sinh hoạt (m³)',
            waterOld,
            _waterNewController,
            waterUsage,
            waterPrice,
            waterCost,
          ),
          const SizedBox(height: 12),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng tiền dịch vụ kỳ cuối:',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              Text(_formatMoney(utilityTotal),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityInputRow(
    IconData icon,
    String title,
    double oldVal,
    TextEditingController newController,
    double usage,
    double price,
    double cost,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Text('-${_formatMoney(cost)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Số cũ: ${oldVal.toInt()}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              const Text('➔ Số mới: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 70,
                height: 32,
                child: TextField(
                  controller: newController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text('+${usage.toInt()} (${_formatMoney(price)}/đv)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMoney(dynamic amount) {
    if (amount == null) return '0 đ';
    final str = amount.toString().replaceAll('đ', '').replaceAll('.', '').replaceAll(',', '').trim();
    final numVal = double.tryParse(str) ?? 0;
    return '${numVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  // bảng quyết toán thanh lý (Đã gắn dữ liệu thật từ API)
  Widget _buildSettlementSummaryCard() {
    final deposit = (_data?['deposit'] is num) ? (_data!['deposit'] as num).toDouble() : (double.tryParse(_data?['deposit']?.toString() ?? '') ?? 0.0);

    final elecOld = (_data?['elecOld'] is num) ? (_data!['elecOld'] as num).toDouble() : 0.0;
    final waterOld = (_data?['waterOld'] is num) ? (_data!['waterOld'] as num).toDouble() : 0.0;
    final elecPrice = (_data?['elecPrice'] is num) ? (_data!['elecPrice'] as num).toDouble() : 3800.0;
    final waterPrice = (_data?['waterPrice'] is num) ? (_data!['waterPrice'] as num).toDouble() : 25000.0;

    final elecNew = double.tryParse(_elecNewController.text) ?? elecOld;
    final waterNew = double.tryParse(_waterNewController.text) ?? waterOld;

    final elecUsage = (elecNew - elecOld) > 0 ? (elecNew - elecOld) : 0.0;
    final waterUsage = (waterNew - waterOld) > 0 ? (waterNew - waterOld) : 0.0;

    final utilityTotal = (elecUsage * elecPrice) + (waterUsage * waterPrice);
    final deductionTotal = _totalDeductionAmount;
    final totalDeductions = utilityTotal + deductionTotal;
    final refundAmount = (deposit - totalDeductions) > 0 ? (deposit - totalDeductions) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5
          )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text('Bảng Quyết Toán Thanh Lý',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Tiền đặt cọc ban đầu:', '+$deposit đ',
              isBold: true, color: AppColors.textPrimary),
          const SizedBox(height: 6),
          _buildSummaryRow('• Điện nước cuối kỳ:', '-$utilityTotal đ', color: Colors.red),
          _buildSummaryRow('• Khấu trừ bàn giao / bồi thường:', '-$deductionTotal đ', color: Colors.red),
          const SizedBox(height: 8),
          _buildSummaryRow('Tổng các khoản trừ:', '-$totalDeductions đ',
              isBold: true, color: Colors.red),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'TIỀN THỰC TẾ HOÀN TRẢ KHÁCH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$refundAmount VNĐ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đã đối soát đầy đủ mọi chi phí phát sinh',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textPrimary)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }

  // chuyển khoản & bàn giao (Đã gắn dữ liệu thật từ API)
  Widget _buildTransferAndHandoverCard() {
    final bankName = _data?['bankName'] ?? 'Techcombank';
    final bankAccount = _data?['bankAccount'] ?? '';
    final accountHolder = _data?['accountHolder'] ?? '';
    final endDate = _data?['endDate'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5
          )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Thông Tin Chuyển Khoản & Bàn Giao',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TÀI KHOẢN NHẬN LẠI CỌC (KHÁCH THUÊ)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code_2,
                          size: 16, color: AppColors.primaryGreen),
                      label: const Text(
                        'Mở mã QR',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.primaryGreen),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _BankInfoRow(label: 'Ngân hàng:', value: bankName),
                const SizedBox(height: 4),
                _BankInfoRow(label: 'Số tài khoản:', value: bankAccount),
                const SizedBox(height: 4),
                _BankInfoRow(label: 'Chủ tài khoản:', value: accountHolder),
                const SizedBox(height: 4),
                _BankInfoRow(label: 'Hạn hoàn tiền:', value: endDate),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.vpn_key_outlined,
                    color: AppColors.primaryGreen, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thu hồi chìa khóa & Thẻ từ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Đã nhận đủ 02 chìa khóa cổng chính + 01 thẻ từ xe máy tầng hầm.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
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

  // phần chữ ký hai bên
  Widget _buildSignatureSection() {
    final ownerName = _data?['ownerName'] ?? 'Trần Thanh Trúc'; // Lấy tên chủ nhà thật
    final tenantName = _data?['tenantName'] ?? 'Khách thuê';     // Lấy tên khách thuê thật

    return Row(
      children: [
        Expanded(child: _signatureBox('Chủ nhà (Bên A)', ownerName)),
        const SizedBox(width: 12),
        Expanded(child: _signatureBox('Khách thuê (Bên B)', tenantName)),
      ],
    );
  }

  Widget _signatureBox(String role, String name) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            role,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
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

  // nút xác nhận và xuất biên bản pdf
  Widget _buildBottomActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () async {
              final contractId = _data?['contractId'] ?? widget.contractId;
              if (contractId == null) return;

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final response = await http.post(
                Uri.parse('http://10.0.2.2:5093/api/OwnerContracts/$contractId/terminate'),
                headers: {'Content-Type': 'application/json'},
              );

              if (response.statusCode == 200 && mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Thanh lý hợp đồng thành công! Phòng đã được đưa về trạng thái trống.'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
                navigator.pop(true);
              }
            },
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text(
              'Xác nhận Hoàn Cọc & Ký Thanh Lý',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primaryGreen),
            label: const Text(
              'Xuất biên bản PDF bàn giao',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// widget hàng thông tin ngân hàng
class _BankInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _BankInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
      ],
    );
  }
}