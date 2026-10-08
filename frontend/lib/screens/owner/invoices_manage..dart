import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/invoices_manage_w.dart';
import '../../route/app_routes.dart';
import '../../widgets/owner/owner_drawer.dart';
class Invoice_mana extends StatefulWidget {
  const Invoice_mana({super.key});

  @override
  State<Invoice_mana> createState() => _InvoiceManaState();
}

class _InvoiceManaState extends State<Invoice_mana> {
  int _selectedFilter = 0; // 0: Tất cả, 1: Chưa thu, 2: Chờ duyệt, 3: Đã thu

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      drawer:OwnerDrawer(
        currentRoute: 'invoices',
      ) ,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text('Hóa Đơn Thu Tiền', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
          ),

          const SizedBox(width: 8),

          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 16,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),

          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
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
                    // Thanh chọn tháng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_left, color: AppColors.textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.calendar_month, size: 16, color: Colors.amber),
                              SizedBox(width: 6),
                              Text('Tháng 08 / 2024', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_right, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Thanh tìm kiếm
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm theo phòng (P.201), mã HĐ, tên khách...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        suffixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.textSecondary, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thẻ tài chính tổng quan
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Tài chính kỳ thu tháng 8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              Text('16 phòng', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Đã thu (62%)', style: TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4),
                                      Text('42.100.000 đ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Còn phải thu', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4),
                                      Text('26.350.000 đ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Tổng dự kiến cần thu', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text('68.450.000 VNĐ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.62,
                              minHeight: 6,
                              backgroundColor: Colors.red.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('● Đã thanh toán (9)', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen)),
                              Text('● Đang chờ (7)', style: TextStyle(fontSize: 10, color: Colors.amber)),
                              Text('● Quá hạn (1)', style: TextStyle(fontSize: 10, color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Các nút lọc trạng thái (Gọi từ file widget ngoài)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          buildFilterChip('Tất cả 16', 0, _selectedFilter, (index) => setState(() => _selectedFilter = index)),
                          const SizedBox(width: 12),
                          buildFilterChip('Chưa thu 5', 1, _selectedFilter, (index) => setState(() => _selectedFilter = index)),
                          const SizedBox(width: 12),
                          buildFilterChip('Chờ duyệt 2', 2, _selectedFilter, (index) => setState(() => _selectedFilter = index)),
                          const SizedBox(width: 12),
                          buildFilterChip('Đã thu', 3, _selectedFilter, (index) => setState(() => _selectedFilter = index)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // DANH SÁCH HÓA ĐƠN
                    // 1. Hóa đơn Đã thanh toán qua QR (Phòng 102)
                    buildInvoiceCard(
                      room: '102',
                      roomCode: '#HD-T08-P102',
                      tenantName: 'Lê Văn Cường',
                      tenantPhone: '',
                      isRoomOnlyTitle: true,
                      statusText: 'Đã thanh toán',
                      statusColor: AppColors.lightGreen,
                      statusTextColor: AppColors.primaryGreen,
                      statusIcon: Icons.verified_rounded,
                      contentWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Row(
                                  children: [
                                    Icon(Icons.account_balance, size: 14, color: AppColors.primaryGreen),
                                    SizedBox(width: 6),
                                    Text('QR Techcombank (02/09 - 14:20)', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                                  ],
                                ),
                                Text('Khớp 100%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Số tiền đã quyết toán:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              RichText(
                                text: const TextSpan(
                                  text: '4.850.000 ',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  children: [
                                    TextSpan(text: 'VNĐ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.receipt_long, size: 14),
                            label: const Text('Xem phiếu thu', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              backgroundColor: Colors.grey.shade100,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.share_outlined, size: 14),
                            label: const Text('In / Chia sẻ', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              backgroundColor: Colors.grey.shade100,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. Hóa đơn Chưa nộp (Phòng 201)
                    buildInvoiceCard(
                      room: '201',
                      roomCode: '#HD-T08-P201',
                      tenantName: 'Nguyễn Văn An',
                      tenantPhone: '0908123456',
                      statusText: 'Chưa nộp',
                      statusColor: Colors.orange.shade100,
                      statusTextColor: Colors.orange.shade800,
                      statusIcon: Icons.access_time,
                      contentWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('Tiền phòng:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text('4.500.000đ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('Điện (125 số):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text('475.000đ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('Nước (6m³):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text('150.000đ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('Dịch vụ rác, wifi:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text('150.000đ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Hạn nộp: 05/09/2024', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              RichText(
                                text: const TextSpan(
                                  text: 'Tổng: ',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  children: [
                                    TextSpan(text: '5.275.000 ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                                    TextSpan(text: 'VNĐ', style: TextStyle(fontSize: 10, color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.chat_bubble_outline, size: 14),
                            label: const Text('Gửi Zalo / SMS', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              backgroundColor: AppColors.lightGreen,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.check, size: 14, color: Colors.white),
                            label: const Text('Xác nhận đã thu', style: TextStyle(fontSize: 11, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. Hóa đơn Quá hạn (Phòng 302)
                    buildInvoiceCard(
                      room: '302',
                      roomCode: '#HD-T08-P302',
                      tenantName: 'Trần Thị Bích',
                      tenantPhone: '',
                      isRoomOnlyTitle: true,
                      statusText: 'Quá hạn 3 ngày',
                      statusColor: Colors.red.shade100,
                      statusTextColor: Colors.red.shade800,
                      statusIcon: Icons.warning_amber_rounded,
                      contentWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Đã nhắc hẹn qua app 02 lần', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text('Lịch sử', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Hạn chót: 30/08/2024', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              RichText(
                                text: const TextSpan(
                                  text: 'Cần thanh toán: ',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  children: [
                                    TextSpan(text: '6.120.000 ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                                    TextSpan(text: 'VNĐ', style: TextStyle(fontSize: 10, color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.phone, size: 14),
                            label: const Text('Gọi điện ngay', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              backgroundColor: Colors.grey.shade100,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_active, size: 14, color: Colors.white),
                            label: const Text('Nhắc nợ gấp', style: TextStyle(fontSize: 11, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Thanh thao tác dưới cùng
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đã hiển thị 3/16 hóa đơn', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.bolt, size: 14, color: Colors.amber),
                        label: const Text('Ghi điện nước nhanh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.invoiceForm);
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}