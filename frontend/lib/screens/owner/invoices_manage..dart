import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../services/owner/invoice_service.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'invoice_form.dart';
import '../../screens/owner/invoice_detail_owner.dart';

enum InvoiceStatus {
  draft,
  unpaid,
  overdue,
  pendingConfirmation,
  paid,
  partiallyPaid,
  cancelled,
}

class InvoiceData {
  final String id;
  final String room;
  final String code;
  final String tenant;
  final String phone;
  final DateTime dueDate;
  final double total;
  InvoiceStatus status;
  final String paymentInfo;

  InvoiceData({
    required this.id,
    required this.room,
    required this.code,
    required this.tenant,
    required this.phone,
    required this.dueDate,
    required this.total,
    required this.status,
    this.paymentInfo = '',
  });

  factory InvoiceData.fromJson(Map<String, dynamic> json) {
    InvoiceStatus parseStatus(String? st) {
      switch ((st ?? '').toLowerCase()) {
        case 'paid':
          return InvoiceStatus.paid;
        case 'draft':
          return InvoiceStatus.draft;
        case 'overdue':
          return InvoiceStatus.overdue;
        case 'pending':
        case 'pendingconfirmation':
          return InvoiceStatus.pendingConfirmation;
        case 'partiallypaid':
          return InvoiceStatus.partiallyPaid;
        case 'cancelled':
          return InvoiceStatus.cancelled;
        default:
          return InvoiceStatus.unpaid;
      }
    }

    return InvoiceData(
      id: (json['id'] ?? '').toString(),
      room: (json['room'] ?? 'Phòng').toString(),
      code: (json['code'] ?? '').toString(),
      tenant: (json['tenant'] ?? 'Khách thuê').toString(),
      phone: (json['phone'] ?? '').toString(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      total: (json['total'] is num) ? (json['total'] as num).toDouble() : 0.0,
      status: parseStatus(json['status']?.toString()),
      paymentInfo: (json['paymentInfo'] ?? '').toString(),
    );
  }
}

class Invoice_mana extends StatefulWidget {
  const Invoice_mana({super.key});

  @override
  State<Invoice_mana> createState() => _InvoiceManaState();
}

class _InvoiceManaState extends State<Invoice_mana> {
  int _selectedFilter = 0;
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedMonth = DateTime.now();

  List<InvoiceData> _invoices = [];
  double _totalPaid = 0.0;
  double _totalOutstanding = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    final data = await OwnerInvoiceService.getMonthlyInvoices(
      month: _selectedMonth.month,
      year: _selectedMonth.year,
      search: _searchController.text.trim(),
    );

    if (mounted) {
      if (data != null && data is Map<String, dynamic>) {
        final list = (data['invoices'] as List<dynamic>? ?? [])
            .map((e) => InvoiceData.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _invoices = list;
          _totalPaid = (data['totalPaid'] is num)
              ? (data['totalPaid'] as num).toDouble()
              : 0.0;
          _totalOutstanding = (data['totalOutstanding'] is num)
              ? (data['totalOutstanding'] as num).toDouble()
              : 0.0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  String _money(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    )} đ';
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _monthLabel(DateTime date) {
    return 'Tháng ${date.month.toString().padLeft(2, '0')} / ${date.year}';
  }

  String _statusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Bản nháp';
      case InvoiceStatus.unpaid:
        return 'Chưa nộp';
      case InvoiceStatus.overdue:
        return 'Quá hạn';
      case InvoiceStatus.pendingConfirmation:
        return 'Chờ duyệt';
      case InvoiceStatus.paid:
        return 'Đã thanh toán';
      case InvoiceStatus.partiallyPaid:
        return 'Thu 1 phần';
      case InvoiceStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color _statusBackground(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey.shade200;
      case InvoiceStatus.unpaid:
        return Colors.orange.shade100;
      case InvoiceStatus.overdue:
        return Colors.red.shade100;
      case InvoiceStatus.pendingConfirmation:
        return Colors.amber.shade100;
      case InvoiceStatus.paid:
        return AppColors.lightGreen;
      case InvoiceStatus.partiallyPaid:
        return Colors.blue.shade100;
      case InvoiceStatus.cancelled:
        return Colors.grey.shade300;
    }
  }

  Color _statusForeground(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
      case InvoiceStatus.cancelled:
        return Colors.grey.shade800;
      case InvoiceStatus.unpaid:
        return Colors.orange.shade900;
      case InvoiceStatus.overdue:
        return Colors.red.shade800;
      case InvoiceStatus.pendingConfirmation:
        return Colors.amber.shade900;
      case InvoiceStatus.paid:
        return AppColors.primaryGreen;
      case InvoiceStatus.partiallyPaid:
        return Colors.blue.shade800;
    }
  }

  IconData _statusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Icons.edit_note;
      case InvoiceStatus.unpaid:
        return Icons.access_time;
      case InvoiceStatus.overdue:
        return Icons.warning_amber_rounded;
      case InvoiceStatus.pendingConfirmation:
        return Icons.hourglass_top;
      case InvoiceStatus.paid:
        return Icons.verified_rounded;
      case InvoiceStatus.partiallyPaid:
        return Icons.payments_outlined;
      case InvoiceStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  List<InvoiceData> get _filteredInvoices {
    return _invoices.where((invoice) {
      switch (_selectedFilter) {
        case 1:
          return invoice.status == InvoiceStatus.unpaid ||
              invoice.status == InvoiceStatus.overdue;
        case 2:
          return invoice.status == InvoiceStatus.pendingConfirmation;
        case 3:
          return invoice.status == InvoiceStatus.paid;
        case 4:
          return invoice.status == InvoiceStatus.draft;
        default:
          return true;
      }
    }).toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  void _handleAction(InvoiceData invoice, String action) async {
    // 1. Xác nhận thu tiền mặt & gạch nợ (kèm Dialog chống bấm nhầm)
    if (action == 'confirm' || action == 'approve') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.payments_outlined, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('Xác nhận thu tiền mặt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xác nhận đã thu đủ số tiền ${_money(invoice.total)} cho phòng ${invoice.room} (${invoice.tenant})?',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đã nhận tiền', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final success = await OwnerInvoiceService.updateStatus(invoice.id, 'paid');
      if (success) {
        _showMessage('Đã gạch nợ thành công cho hóa đơn ${invoice.code}!');
        _fetchInvoices();
      } else {
        _showMessage('Lỗi khi cập nhật trạng thái hóa đơn.');
      }
      return;
    }

    // 2. Chuyển sang xem phiếu thu chi tiết
    if (action == 'receipt' || action == 'detail') {
      final res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceDetailScreen(
            invoice: invoice,
            invoiceId: invoice.id,
          ),
        ),
      );
      if (res == true) _fetchInvoices();
      return;
    }

    // 3. Chỉnh sửa bản nháp
    if (action == 'edit') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Invoice_form(invoice: invoice),
        ),
      );
      if (result != null) _fetchInvoices();
      return;
    }

    // 4. Gọi điện thoại
    if (action == 'call') {
      if (invoice.phone.isEmpty) {
        _showMessage('Chưa có số điện thoại của khách thuê.');
      } else {
        _showMessage('Số điện thoại: ${invoice.phone}');
      }
      return;
    }
  }

  Widget _actionButton(
      InvoiceData invoice, {
        required String label,
        required IconData icon,
        required String action,
        bool primary = false,
        Color? color,
      }) {
    return Expanded(
      child: primary
          ? ElevatedButton.icon(
        onPressed: () => _handleAction(invoice, action),
        icon: Icon(icon, size: 14, color: Colors.white),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      )
          : OutlinedButton.icon(
        onPressed: () => _handleAction(invoice, action),
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildActions(InvoiceData invoice) {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Row(
          children: [
            _actionButton(invoice, label: 'Sửa nháp', icon: Icons.edit_outlined, action: 'edit'),
            const SizedBox(width: 8),
            _actionButton(invoice, label: 'Phát hành', icon: Icons.send_outlined, action: 'confirm', primary: true),
          ],
        );
      case InvoiceStatus.unpaid:
      case InvoiceStatus.overdue:
        return Row(
          children: [
            _actionButton(invoice, label: 'Gọi khách', icon: Icons.phone, action: 'call'),
            const SizedBox(width: 8),
            _actionButton(invoice, label: 'Thu tiền mặt', icon: Icons.payments_outlined, action: 'confirm', primary: true),
          ],
        );
      case InvoiceStatus.pendingConfirmation:
        return Row(
          children: [
            _actionButton(invoice, label: 'Xem chi tiết', icon: Icons.receipt_long, action: 'detail'),
            const SizedBox(width: 8),
            _actionButton(invoice, label: 'Duyệt', icon: Icons.check_circle_outline, action: 'approve', primary: true),
          ],
        );
      case InvoiceStatus.paid:
        return Row(
          children: [
            _actionButton(invoice, label: 'Xem phiếu thu', icon: Icons.receipt_long, action: 'receipt'),
          ],
        );
      default:
        return Row(
          children: [
            _actionButton(invoice, label: 'Xem chi tiết', icon: Icons.visibility_outlined, action: 'detail'),
          ],
        );
    }
  }

  Widget _buildInvoiceCard(InvoiceData invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home_work_outlined, color: AppColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.room,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(invoice.code, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 3),
                    Text(invoice.tenant, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusBackground(invoice.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(invoice.status), size: 13, color: _statusForeground(invoice.status)),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel(invoice.status),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusForeground(invoice.status)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (invoice.status == InvoiceStatus.paid && invoice.paymentInfo.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.lightGreen.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(invoice.paymentInfo, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice.status == InvoiceStatus.paid ? 'Đã thu xong' : 'Hạn nộp: ${_date(invoice.dueDate)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                _money(invoice.total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: invoice.status == InvoiceStatus.paid ? AppColors.primaryGreen : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActions(invoice),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final selected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primaryGreen : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _changeMonth(int amount) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + amount);
    });
    _fetchInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _filteredInvoices;
    final totalExpected = _totalPaid + _totalOutstanding;
    final progress = totalExpected == 0 ? 0.0 : _totalPaid / totalExpected;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      drawer: const OwnerDrawer(currentRoute: 'invoices'),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text('Hóa Đơn Thu Tiền', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchInvoices,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.arrow_left, color: AppColors.textSecondary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 16, color: Colors.amber),
                                const SizedBox(width: 6),
                                Text(_monthLabel(_selectedMonth), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _changeMonth(1),
                            icon: const Icon(Icons.arrow_right, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _fetchInvoices(),
                        decoration: InputDecoration(
                          hintText: 'Tìm phòng, mã hóa đơn, tên khách...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              _fetchInvoices();
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tổng quan tài chính', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                Text('${_invoices.length} hóa đơn', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _summaryBox('Đã thu', _money(_totalPaid), AppColors.lightGreen, AppColors.primaryGreen)),
                                const SizedBox(width: 8),
                                Expanded(child: _summaryBox('Còn phải thu', _money(_totalOutstanding), Colors.red.shade50, Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tổng dự kiến cần thu', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(_money(totalExpected), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 7),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.red.shade100,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Tất cả', 0),
                            const SizedBox(width: 8),
                            _buildFilterChip('Chưa thu', 1),
                            const SizedBox(width: 8),
                            _buildFilterChip('Chờ duyệt', 2),
                            const SizedBox(width: 8),
                            _buildFilterChip('Đã thu', 3),
                            const SizedBox(width: 8),
                            _buildFilterChip('Bản nháp', 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                      else if (invoices.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Không tìm thấy hóa đơn nào trong tháng này.', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      else
                        ...invoices.map(_buildInvoiceCard),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Invoice_form(invoice: null)),
                    );
                    if (result != null) {
                      _fetchInvoices();
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                  label: const Text('Lập hóa đơn mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentYellow,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBox(String title, String amount, Color background, Color titleColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: titleColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}