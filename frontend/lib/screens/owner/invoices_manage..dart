import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../widgets/owner/owner_drawer.dart';

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
  final String room;
  final String code;
  final String tenant;
  final String phone;
  final DateTime dueDate;
  final double total;
  final InvoiceStatus initialStatus;
  final String paymentInfo;

  InvoiceStatus status;

  InvoiceData({
    required this.room,
    required this.code,
    required this.tenant,
    required this.phone,
    required this.dueDate,
    required this.total,
    required this.initialStatus,
    this.paymentInfo = '',
  }) : status = initialStatus;
}

class Invoice_mana extends StatefulWidget {
  const Invoice_mana({super.key});

  @override
  State<Invoice_mana> createState() => _InvoiceManaState();
}

class _InvoiceManaState extends State<Invoice_mana> {
  int _selectedFilter = 0;
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedMonth = DateTime(2024, 8);

  final List<InvoiceData> _invoices = [
    InvoiceData(
      room: '102',
      code: '#HD-T08-P102',
      tenant: 'Lê Văn Cường',
      phone: '',
      dueDate: DateTime(2024, 9, 5),
      total: 4850000,
      initialStatus: InvoiceStatus.paid,
      paymentInfo: 'QR Techcombank (02/09 - 14:20)',
    ),
    InvoiceData(
      room: '201',
      code: '#HD-T08-P201',
      tenant: 'Nguyễn Văn An',
      phone: '0908123456',
      dueDate: DateTime(2024, 9, 5),
      total: 5275000,
      initialStatus: InvoiceStatus.unpaid,
    ),
    InvoiceData(
      room: '302',
      code: '#HD-T08-P302',
      tenant: 'Trần Thị Bích',
      phone: '',
      dueDate: DateTime(2024, 8, 30),
      total: 6120000,
      initialStatus: InvoiceStatus.overdue,
    ),
    InvoiceData(
      room: '401',
      code: '#HD-T08-P401',
      tenant: 'Phạm Minh Tuấn',
      phone: '0912345678',
      dueDate: DateTime(2024, 9, 5),
      total: 4500000,
      initialStatus: InvoiceStatus.draft,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  // tháng
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
        return 'Chờ duyệt thanh toán';
      case InvoiceStatus.paid:
        return 'Đã thanh toán';
      case InvoiceStatus.partiallyPaid:
        return 'Đã thanh toán một phần';
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

  // trả về các icon
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

  // bộ lọc các thẻ
  List<InvoiceData> get _filteredInvoices {
    final keyword = _searchController.text.trim().toLowerCase();

    return _invoices.where((invoice) {
      final matchesSearch =
          invoice.room.toLowerCase().contains(keyword) ||
              invoice.code.toLowerCase().contains(keyword) ||
              invoice.tenant.toLowerCase().contains(keyword);

      bool matchesFilter;

      switch (_selectedFilter) {
        case 1:
          matchesFilter = invoice.status == InvoiceStatus.unpaid ||
              invoice.status == InvoiceStatus.overdue ||
              invoice.status == InvoiceStatus.partiallyPaid;
          break;
        case 2:
          matchesFilter =
              invoice.status == InvoiceStatus.pendingConfirmation;
          break;
        case 3:
          matchesFilter = invoice.status == InvoiceStatus.paid;
          break;
        case 4:
          matchesFilter = invoice.status == InvoiceStatus.draft;
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // hiển thị thông báo
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // nhấn nút chuyển trang
  void _handleAction(InvoiceData invoice, String action) {
    setState(() {
      switch (action) {
        case 'issue':
          invoice.status = InvoiceStatus.unpaid;
          _showMessage('Đã phát hành hóa đơn ${invoice.code}.');
          break;

        case 'confirm':
          invoice.status = InvoiceStatus.paid;
          _showMessage('Đã cập nhật hóa đơn thành đã thanh toán.');
          break;

        case 'approve':
          invoice.status = InvoiceStatus.paid;
          _showMessage('Đã xác nhận thanh toán.');
          break;

        case 'reject':
          invoice.status = InvoiceStatus.unpaid;
          _showMessage('Đã từ chối giao dịch. Hóa đơn vẫn chưa thu.');
          break;

        case 'remind':
          _showMessage('Chức năng gửi nhắc thanh toán cần tích hợp Zalo/SMS.');
          break;

        case 'call':
          if (invoice.phone.isEmpty) {
            _showMessage('Chưa có số điện thoại của khách thuê.');
          } else {
            _showMessage('Số điện thoại: ${invoice.phone}');
          }
          break;

        case 'urgent':
          _showMessage('Chức năng nhắc nợ cần tích hợp thông báo.');
          break;

        case 'receipt':
          Navigator.pushNamed(context, AppRoutes.invoiceDetailOwner);
          break;

        case 'share':
          _showMessage('Chức năng in/chia sẻ cần được tích hợp thêm.');
          break;

        case 'transaction':
          _showMessage('Xem giao dịch của ${invoice.code}.');
          break;

        case 'partial':
          _showMessage('Mở chức năng ghi nhận khoản thu tiếp theo.');
          break;

        case 'edit':
          _showMessage('Mở chức năng chỉnh sửa bản nháp.');
          break;

        case 'detail':
          _showMessage('Xem chi tiết hóa đơn ${invoice.code}.');
          break;
      }
    });
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
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 10,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // hiển thị các nút tương tác
  Widget _buildActions(InvoiceData invoice) {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Row(
          children: [
            _actionButton(
              invoice,
              label: 'Sửa nháp',
              icon: Icons.edit_outlined,
              action: 'edit',
            ),
            const SizedBox(width: 8),
            _actionButton(
              invoice,
              label: 'Phát hành',
              icon: Icons.send_outlined,
              action: 'issue',
              primary: true,
            ),
          ],
        );

      case InvoiceStatus.unpaid:
        return Row(
          children: [
            _actionButton(
              invoice,
              label: 'Gửi nhắc thanh toán',
              icon: Icons.chat_bubble_outline,
              action: 'remind',
            ),
            const SizedBox(width: 8),
            _actionButton(
              invoice,
              label: 'Xác nhận đã thu',
              icon: Icons.check,
              action: 'confirm',
              primary: true,
            ),
          ],
        );

      case InvoiceStatus.overdue:
        return Row(
          children: [
            _actionButton(
              invoice,
              label: 'Gọi điện ngay',
              icon: Icons.phone,
              action: 'call',
            ),
            const SizedBox(width: 8),
            _actionButton(
              invoice,
              label: 'Nhắc nợ gấp',
              icon: Icons.notifications_active_outlined,
              action: 'urgent',
              primary: true,
              color: Colors.red.shade700,
            ),
          ],
        );

      case InvoiceStatus.pendingConfirmation:
        return Row(
          children: [
            _actionButton(
              invoice,
              label: 'Xem giao dịch',
              icon: Icons.receipt_long,
              action: 'transaction',
            ),
            const SizedBox(width: 8),
            _actionButton(
              invoice,
              label: 'Xác nhận',
              icon: Icons.check_circle_outline,
              action: 'approve',
              primary: true,
            ),
            const SizedBox(width: 8),
            _actionButton(
              invoice,
              label: 'Từ chối',
              icon: Icons.close,
              action: 'reject',
            ),
          ],
        );

      case InvoiceStatus.paid:
        return Row(
          children: [
            _actionButton(
              invoice,
              label: 'Xem phiếu thu',
              icon: Icons.receipt_long,
              action: 'receipt',
            ),
            const SizedBox(width: 8),
            _actionButton(
              invoice,
              label: 'In / Chia sẻ',
              icon: Icons.share_outlined,
              action: 'share',
            ),
          ],
        );

      case InvoiceStatus.partiallyPaid:
        return Row(
          children: [
            _actionButton(
              invoice,
              label: 'Gửi nhắc thanh toán',
              icon: Icons.chat_bubble_outline,
              action: 'remind',
            ),
            const SizedBox(width: 8),
            _actionButton(
              invoice,
              label: 'Xác nhận thu tiếp',
              icon: Icons.payments_outlined,
              action: 'partial',
              primary: true,
            ),
          ],
        );

      case InvoiceStatus.cancelled:
        return Row(
          children: [
            _actionButton(
              invoice,
              label: 'Xem chi tiết',
              icon: Icons.visibility_outlined,
              action: 'detail',
            ),
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
            color: Colors.black.withOpacity(0.03),
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
                child: const Icon(
                  Icons.home_work_outlined,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ${invoice.room}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      invoice.code,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      invoice.tenant,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusBackground(invoice.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(invoice.status),
                      size: 13,
                      color: _statusForeground(invoice.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel(invoice.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _statusForeground(invoice.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (invoice.status == InvoiceStatus.paid &&
              invoice.paymentInfo.isNotEmpty)...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.lightGreen.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                invoice.paymentInfo,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice.status == InvoiceStatus.paid
                    ? 'Số tiền đã thanh toán'
                    : 'Hạn nộp: ${_date(invoice.dueDate)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _money(invoice.total), // tính tiền
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: invoice.status == InvoiceStatus.overdue ||
                      invoice.status == InvoiceStatus.unpaid
                      ? Colors.red
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActions(invoice),// gọi mấy cái nút
        ],
      ),
    );
  }

  // chọn cái lọc
  Widget _buildFilterChip(String label, int index) {
    final selected = _selectedFilter == index;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryGreen
                : Colors.grey.shade300,
          ),
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

  // đổi ngày
  void _changeMonth(int amount) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + amount,
      );
    });
  }

  // phàn thiế kế
  @override
  Widget build(BuildContext context) {
    final invoices = _filteredInvoices;

    final totalPaid = _invoices
        .where((e) => e.status == InvoiceStatus.paid)
        .fold<double>(0, (sum, e) => sum + e.total);

    final totalOutstanding = _invoices
        .where((e) =>
    e.status == InvoiceStatus.unpaid ||
        e.status == InvoiceStatus.overdue ||
        e.status == InvoiceStatus.partiallyPaid)
        .fold<double>(0, (sum, e) => sum + e.total);

    final totalExpected = totalPaid + totalOutstanding;
    final progress = totalExpected == 0 ? 0.0 : totalPaid / totalExpected;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      drawer: const OwnerDrawer(currentRoute: 'invoices'),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Hóa Đơn Thu Tiền',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions:  [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(
                            Icons.arrow_left,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _monthLabel(_selectedMonth),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(
                            Icons.arrow_right,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm phòng, mã hóa đơn, tên khách...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: Colors.grey.shade300),
                        ),
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
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng quan tài chính',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_invoices.length} hóa đơn',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _summaryBox(
                                  'Đã thu',
                                  _money(totalPaid),
                                  AppColors.lightGreen,
                                  AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _summaryBox(
                                  'Còn phải thu',
                                  _money(totalOutstanding),
                                  Colors.red.shade50,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng dự kiến cần thu',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _money(totalExpected),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: Colors.red.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primaryGreen,
                              ),
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
                          // mấy cái nút lọc
                          _buildFilterChip('Tất cả', 0),
                          const SizedBox(width: 8),
                          _buildFilterChip('Chưa thu', 1),
                          const SizedBox(width: 8),
                          _buildFilterChip('Chờ duyệt', 2),
                          const SizedBox(width: 8),
                          _buildFilterChip('Đã thu', 3),
                          const SizedBox(width: 8),
                          _buildFilterChip('Bản nháp', 4),
                          const SizedBox(width: 8),

                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (invoices.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Không tìm thấy hóa đơn phù hợp.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      // giúp đưa nhiều widget từ một danh sách vào children
                      ...invoices.map(_buildInvoiceCard),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        // hiển thị hóa đơn
                        'Đang hiển thị ${invoices.length}/${_invoices.length} hóa đơn',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _showMessage(
                            'Mở chức năng ghi điện nước nhanh.',
                          );
                        },
                        icon: const Icon(
                          Icons.bolt,
                          size: 14,
                          color: Colors.amber,
                        ),
                        label: const Text(
                          'Ghi điện nước nhanh',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.invoiceForm,
                        );
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Lập hóa đơn mới',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentYellow,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // hộp
  Widget _summaryBox(
      String title,
      String amount,
      Color background,
      Color titleColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}