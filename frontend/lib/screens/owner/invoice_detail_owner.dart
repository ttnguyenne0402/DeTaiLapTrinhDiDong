import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/invoice_service.dart';
import '../../screens/owner/invoices_manage..dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceData? invoice;
  final String? invoiceId;

  const InvoiceDetailScreen({
    super.key,
    this.invoice,
    this.invoiceId,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  Map<String, dynamic>? _detailData;
  String _activeId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        _activeId = args;
      } else if (args is InvoiceData) {
        _activeId = args.id;
      } else {
        _activeId = widget.invoiceId ?? widget.invoice?.id ?? '';
      }

      if (_activeId.isNotEmpty) {
        _fetchDetail(_activeId);
      } else {
        setState(() => _isLoading = false);
      }
      _isInit = false;
    }
  }

  Future<void> _fetchDetail(String id) async {
    setState(() => _isLoading = true);

    final res = await OwnerInvoiceService.getInvoiceDetail(id);
    if (mounted) {
      setState(() {
        if (res is Map<String, dynamic>) {
          _detailData = res;
        }
        _isLoading = false;
      });
    }
  }

  String _money(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    )} đ';
  }

  // Xác nhận thu thủ công (khi khách trả tiền mặt hoặc chuyển khoản ngoài)
  Future<void> _confirmPaid() async {
    if (_activeId.isEmpty) return;
    setState(() => _isLoading = true);

    final success = await OwnerInvoiceService.updateStatus(_activeId, 'paid');
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận thu tiền và gạch nợ thành công!')),
        );
        _fetchDetail(_activeId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi cập nhật trạng thái hóa đơn.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _detailData?['code'] ?? widget.invoice?.code ?? '#HD-INV';
    final room = _detailData?['room'] ?? widget.invoice?.room ?? 'Phòng trọ';
    final tenant = _detailData?['tenant'] ?? widget.invoice?.tenant ?? 'Khách thuê';
    final phone = _detailData?['phone'] ?? widget.invoice?.phone ?? '';
    final billingMonth = _detailData?['billingMonth'] ?? 'Kỳ thu';
    final statusStr = _detailData?['status'] ?? (widget.invoice?.status == InvoiceStatus.paid ? 'paid' : 'unpaid');
    final isPaid = statusStr == 'paid';

    final totalVal = (_detailData?['total'] is num)
        ? (_detailData!['total'] as num).toDouble()
        : (widget.invoice?.total ?? 0.0);

    final rentVal = (_detailData?['rentPrice'] is num) ? (_detailData!['rentPrice'] as num).toDouble() : 0.0;
    final electricVal = (_detailData?['electricAmount'] is num) ? (_detailData!['electricAmount'] as num).toDouble() : 0.0;
    final waterVal = (_detailData?['waterAmount'] is num) ? (_detailData!['waterAmount'] as num).toDouble() : 0.0;
    final discountVal = (_detailData?['discount'] is num) ? (_detailData!['discount'] as num).toDouble() : 0.0;
    final otherServices = (_detailData?['otherServices'] as List<dynamic>? ?? []);

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Xem chi tiết phiếu thu',
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 1. Thẻ tổng quan
                    Container(
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
                              Text(code, style: const TextStyle(color: AppColors.cardSurface, fontSize: 12, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPaid ? AppColors.lightGreen : Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(isPaid ? Icons.check_circle : Icons.access_time, size: 12, color: isPaid ? AppColors.primaryGreen : Colors.amber.shade900),
                                    const SizedBox(width: 4),
                                    Text(
                                      isPaid ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN',
                                      style: TextStyle(
                                        color: isPaid ? AppColors.primaryGreen : Colors.amber.shade900,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Tổng tiền kỳ $billingMonth', style: const TextStyle(color: AppColors.cardSurface, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            _money(totalVal),
                            style: const TextStyle(color: AppColors.cardSurface, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Divider(color: Colors.white24, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.meeting_room, color: AppColors.accentYellow, size: 16),
                                  const SizedBox(width: 6),
                                  Text(room, style: const TextStyle(color: AppColors.cardSurface, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text(tenant, style: const TextStyle(color: AppColors.cardSurface, fontSize: 12)),
                            ],
                          ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('SĐT khách: $phone', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text('Chi tiết các khoản thu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),

                    // 2. Thẻ chi tiết dịch vụ
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          if (rentVal > 0) ...[
                            _buildFeeRow(Icons.apartment, 'Tiền thuê phòng', _money(rentVal)),
                            const Divider(height: 16),
                          ],
                          if (electricVal > 0) ...[
                            _buildFeeRow(Icons.electric_bolt, 'Tiền điện sinh hoạt', _money(electricVal)),
                            const Divider(height: 16),
                          ],
                          if (waterVal > 0) ...[
                            _buildFeeRow(Icons.water_drop, 'Tiền nước sinh hoạt', _money(waterVal)),
                            const Divider(height: 16),
                          ],
                          ...otherServices.map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: _buildFeeRow(
                              Icons.miscellaneous_services,
                              s['name'] ?? 'Dịch vụ',
                              _money((s['price'] as num?)?.toDouble() ?? 0.0),
                            ),
                          )),
                          if (discountVal > 0) ...[
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.local_offer, size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Giảm trừ ưu đãi', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text('- ${_money(discountVal)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TỔNG CỘNG THỰC THU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                _money(totalVal),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Thông tin ghi nhận thanh toán
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isPaid ? AppColors.lightGreen : Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPaid ? Icons.verified_user_outlined : Icons.info_outline,
                            color: isPaid ? AppColors.primaryGreen : Colors.amber.shade900,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isPaid
                                  ? 'Hóa đơn đã được thanh toán và đối soát gạch nợ thành công trên hệ thống.'
                                  : 'Hóa đơn đang chờ người thuê thanh toán online qua VNPay hoặc đóng tiền mặt.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isPaid ? AppColors.primaryGreen : Colors.amber.shade900,
                                fontWeight: FontWeight.w500,
                              ),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nút này chỉ xuất hiện khi khách CHƯA THANH TOÁN (dành cho chủ nhà thu tiền mặt)
            if (!isPaid) ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _confirmPaid,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  label: const Text('Xác nhận đã thu tiền mặt', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang tạo và gửi phiếu thu Zalo cho khách...')),
                  );
                },
                icon: const Icon(Icons.send_outlined, size: 16, color: AppColors.textPrimary),
                label: const Text('Gửi phiếu thu qua Zalo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(IconData icon, String title, String amount) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}