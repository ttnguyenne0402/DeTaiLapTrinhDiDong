import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key});

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
          'Xem chi tiết hóa đơn',
          style: TextStyle(
            color: AppColors.cardSurface,
            fontSize: 18,
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
      body: Column(
        children: [
          //khung giao diện chính bo góc trên bên trái và bên phải
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24.0),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24.0),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildHeaderInvoiceCard(),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Chi tiết các khoản thu', '5 hạng mục'),
                    const SizedBox(height: 8),
                    //gộp toàn bộ khoản thu vào cùng một container
                    _buildAllInOneServicesCard(),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Chứng từ & Giao dịch VietQR', 'Đã đối soát'),
                    const SizedBox(height: 8),
                    _buildPaymentProofCard(),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Nhật ký lập & thu hóa đơn', ''),
                    const SizedBox(height: 8),
                    _buildAuditLogCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  //thẻ tổng quan hóa đơn ở đầu trang
  Widget _buildHeaderInvoiceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
              const Text(
                '#INV-2024-08-P201',
                style: TextStyle(color: AppColors.cardSurface, fontSize: 11),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 12, color: AppColors.primaryGreen),
                    SizedBox(width: 4),
                    Text(
                      'ĐÃ THANH TOÁN',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tổng tiền kỳ Tháng 08/2024',
            style: TextStyle(color: AppColors.cardSurface, fontSize: 11),
          ),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '5.375.000',
                style: TextStyle(
                  color: AppColors.cardSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              Text('VNĐ', style: TextStyle(color: AppColors.cardSurface, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.meeting_room, color: AppColors.accentYellow, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Phòng 201',
                    style: TextStyle(color: AppColors.cardSurface, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Text('• HĐ #HD-2024-P201', style: TextStyle(color: AppColors.cardSurface, fontSize: 10)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Hạn: 05/09', style: TextStyle(color: AppColors.cardSurface, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: AppColors.cardSurface, size: 14),
                  SizedBox(width: 4),
                  Text('Nguyễn Văn An', style: TextStyle(color: AppColors.cardSurface, fontSize: 11)),
                ],
              ),
              Text('0908 123 456', style: TextStyle(color: AppColors.cardSurface, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.check, size: 12, color: AppColors.accentYellow),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Khớp 100% qua Techcombank • 14:20 02/09/2024',
                  style: TextStyle(color: AppColors.accentYellow, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //tiêu đề từng phần
  Widget _buildSectionHeader(String title, String tag) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.article_outlined, size: 16, color: AppColors.primaryGreen),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
        ),
        if (tag.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tag,
              style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10),
            ),
          ),
      ],
    );
  }

  //gộp tất cả các khoản chi phí vào trong cùng một container
  Widget _buildAllInOneServicesCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          //mục tiền thuê phòng
          Row(
            children: [
              _buildIconContainer(Icons.apartment),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tiền thuê phòng cố định', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Định kỳ tháng 08/2024 (25 m²)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Text('4.500.000 đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),

          //mục điện tiêu thụ
          Column(
            children: [
              Row(
                children: [
                  _buildIconContainer(Icons.bolt, color: Colors.orange.shade100, iconColor: Colors.orange),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Điện tiêu thụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('1.420 -> 1.545 [125 kWh × 3.800đ]', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Text('475.000 đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.image, size: 18, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chốt: 30/08', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          Text('Xem ảnh gốc', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen, decoration: TextDecoration.underline)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('+125 kWh', style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),

          //mục nước sinh hoạt
          Column(
            children: [
              Row(
                children: [
                  _buildIconContainer(Icons.water_drop, color: Colors.blue.shade100, iconColor: Colors.blue),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nước sinh hoạt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('85 -> 91 (6 m³ × 25.000đ)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Text('150.000 đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.image, size: 18, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chốt: 30/08', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          Text('Xem ảnh gốc', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen, decoration: TextDecoration.underline)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('+6 m³', style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),

          //mục wifi & rác
          Row(
            children: [
              _buildIconContainer(Icons.wifi),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Internet Wifi & Vệ sinh rác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('WiFi 100k + Thu gom rác 50k', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Text('150.000 đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),

          //mục xe máy
          Row(
            children: [
              _buildIconContainer(Icons.two_wheeler),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phí giữ xe máy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('2 xe định mức × 50.000đ/xe', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Text('100.000 đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),

          //tổng cộng thực thu nằm cùng trong container
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TỔNG CỘNG THỰC THU',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Năm triệu ba trăm bảy mươi lăm\nnghìn đồng',
                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '5.375.000',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                  ),
                  SizedBox(width: 2),
                  Text('đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  //thẻ minh chứng giao dịch vietqr
  Widget _buildPaymentProofCard() {
    return _buildCardWrapper(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('TCB', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Techcombank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('1903 8888 6688 • NGUYEN VAN CHU TRO', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MÃ THAM CHIẾU (FT)', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                      Text('FT24246998129033', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THỜI GIAN NHẬN', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                      Text('02/09/2024 14:20:15', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('UNC Khách tải lên:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.receipt_long, size: 40, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mã VietQR đối soát:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2, size: 45, color: AppColors.primaryGreen),
                            Text('VietQR NAPAS 247', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //thẻ nhật ký lịch sử lập và thu hóa đơn
  Widget _buildAuditLogCard() {
    return _buildCardWrapper(
      child: Column(
        children: [
          _buildLogStep('Chốt số & Lập hóa đơn', '30/08 • 09:15', 'Chủ trọ cập nhật chỉ số điện nước tại phòng 201 và tạo biểu phí tháng 08.', true),
          _buildLogStep('Đã gửi thông báo hóa đơn', '31/08 • 08:30', 'Tự động gửi thông báo qua Zalo ZNS và thông báo ứng dụng khách thuê.', true),
          _buildLogStep('Thanh toán & Gạch nợ tự động', '02/09 • 14:20', 'Khách chuyển khoản đúng cú pháp qua VietQR, hệ thống kích hoạt xác nhận ngay lập tức.', false),
        ],
      ),
    );
  }

  //dòng bước trong nhật ký
  Widget _buildLogStep(String title, String time, String desc, bool hasLine) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.check_circle, size: 14, color: AppColors.primaryGreen),
            if (hasLine)
              Container(
                width: 1,
                height: 35,
                color: AppColors.borderLight,
              ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  Text(time, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                ],
              ),
              Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  //thanh nút thao tác ở đáy màn hình
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf, size: 14, color: AppColors.textPrimary),
                  label: const Text('In phiếu thu PDF', style: TextStyle(color: AppColors.textPrimary, fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send, size: 14, color: AppColors.textPrimary),
                  label: const Text('Gửi Zalo cho khách', style: TextStyle(color: AppColors.textPrimary, fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.receipt, size: 16, color: AppColors.textPrimary),
            label: const Text(
              'Xuất biên lai điện tử',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

          const SizedBox(height: 10,)
        ],
      ),
    );
  }

  //hàm bọc card dùng chung
  Widget _buildCardWrapper({required Widget child, Color? backgroundColor, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.borderLight),
      ),
      child: child,
    );
  }

  //hàm bọc icon tròn dùng chung
  Widget _buildIconContainer(IconData icon, {Color? color, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color ?? AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: iconColor ?? AppColors.primaryGreen),
    );
  }
}