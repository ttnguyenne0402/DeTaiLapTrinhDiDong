import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RoomApprovalDetailScreen extends StatefulWidget {
  const RoomApprovalDetailScreen({super.key});

  @override
  State<RoomApprovalDetailScreen> createState() => _RoomApprovalDetailScreenState();
}

class _RoomApprovalDetailScreenState extends State<RoomApprovalDetailScreen> {
  // controller quản lý ô nhập lý do từ chối
  final TextEditingController _rejectionController = TextEditingController();

  // danh sách các chip gợi ý lý do nhanh
  final List<String> _quickReasons = [
    'Ảnh mờ / thiếu sáng',
    'Thiếu cam kết PCCC',
    'Sai giá so với hợp đồng',
    'Tiêu đề sai lệch',
  ];

  // mảng lưu trạng thái chọn của 4 tiêu chí thẩm định
  final List<bool> _checklistStatus = [true, true, true, false];

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen, // dùng màu primary green cho header phía trên
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết tin',
          style: TextStyle(color: AppColors.cardSurface, fontSize: 18, fontWeight: FontWeight.bold),
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
          // container chính bo hai góc tròn phía trên
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background, // dùng màu nền chung của app
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24.0), // bo góc trái phải trên
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24.0),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 1. top metadata card
                    _buildTopMetadata(),
                    const SizedBox(height: 16),

                    // 2. hình ảnh xác thực & ai safety check
                    _buildImageSection(),
                    const SizedBox(height: 16),

                    // 3. thông tin bài đăng
                    _buildPropertyDetails(),
                    const SizedBox(height: 16),

                    // 4. tiêu chí thẩm định
                    _buildValidationChecklist(),
                    const SizedBox(height: 16),

                    // 5. lý do từ chối / yêu cầu sửa
                    _buildRejectionSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // thanh bottom bar cố định dưới cùng
          _buildBottomActionBar(),

          SizedBox(height: 10,)
        ],
      ),
    );
  }

  // widget thẻ thông tin mã tin và người đăng
  Widget _buildTopMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mã tin: ',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const Text(
              '#POST-2024-889',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'CHỜ KIỂM DUYỆT',
                style: TextStyle(fontSize: 10, color: AppColors.warningOrange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ngày gửi', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        Text('31/08/2024', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Người đăng', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        Text('QL Bình Thạnh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // widget khối hình ảnh xác thực và ai safety check
  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library_outlined, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 6),
                  Text('Hình ảnh xác thực (5)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                ],
              ),

            ],
          ),
          const SizedBox(height: 8),

          // ai safety check banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),

          ),
          const SizedBox(height: 10),

          // ảnh đại diện chính
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('IMAGE', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, color: AppColors.accentYellow, size: 12),
                      SizedBox(width: 4),
                      Text('Ảnh đại diện chính', style: TextStyle(color: AppColors.cardSurface, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('is_thumbnail = true', style: TextStyle(color: AppColors.cardSurface, fontSize: 9)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // danh sách ảnh nhỏ phía dưới
          Row(
            children: [
              _buildThumbTile('#1 Bếp'),
              const SizedBox(width: 6),
              _buildThumbTile('#2 WC'),
              const SizedBox(width: 6),
              _buildThumbTile('#3 Ban công'),
              const SizedBox(width: 6),
              _buildThumbTile('#4 Nệm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbTile(String label) {
    return Expanded(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.textPrimary.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.cardSurface, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // widget khối thông tin bài đăng
  Widget _buildPropertyDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TIÊU ĐỀ BÀI ĐĂNG', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Studio Cao Cấp 28m² Ban Công Thoáng – Full Nội Thất Khu Bình Thạnh (P.202)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          // khung giá thuê và tiền cọc
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Giá thuê niêm yết', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('4.800.000', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                          SizedBox(width: 2),
                          Text('đ/tháng', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tiền đặt cọc (2T)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      SizedBox(height: 2),
                      Text('9.600.000 đ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.warningOrange)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // thông số nhanh
          const Row(
            children: [
              _ChipInfo(icon: Icons.square_foot, label: '28 m²'),
              SizedBox(width: 8),
              _ChipInfo(icon: Icons.layers_outlined, label: 'Tầng 2 (P.202)'),
            ],
          ),
          const SizedBox(height: 6),
          const _ChipInfo(icon: Icons.people_outline, label: 'Tối đa 2 người'),
          const SizedBox(height: 12),

          // danh sách tiện ích
          const Text('Tiện ích đi kèm', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const GridViewWidget(),

          const SizedBox(height: 12),
          const Text('Mô tả bài đăng (description)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Text(
              'Phòng mới decor cực xinh, ban công đón gió mát rượi, giờ giấc tự do không chung chủ, có bảo vệ 24/7, camera an ninh toàn dãy. Đầy đủ tiện nghi cao cấp chỉ việc xách vali vào ở. Gần trường ĐH HUTECH, Ngoại Thương, Landmark 81 di chuyển 5 phút..',
              style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // widget tiêu chí thẩm định (có tính năng nhấp chọn checkbox)
  Widget _buildValidationChecklist() {
    // tự động tính số lượng tiêu chí đã đạt
    int passedCount = _checklistStatus.where((item) => item).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.fact_check_outlined, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 6),
                  Text('Tiêu chí thẩm định', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$passedCount/4 Đạt',
                  style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _buildCheckItem(
            index: 0,
            title: 'Tính xác thực phòng & chủ sở hữu',
            subtitle: 'Khớp với hồ sơ giấy tờ nhà đất phòng P.202',
          ),
          _buildCheckItem(
            index: 1,
            title: 'Hình ảnh chất lượng & minh bạch',
            subtitle: 'Không chèn số điện thoại liệu hay ảnh mạng',
          ),
          _buildCheckItem(
            index: 2,
            title: 'Tiêu chuẩn PCCC & lối thoát hiểm',
            subtitle: 'Có ban công mở và bình bọt chữa cháy hành lang',
          ),
          _buildCheckItem(
            index: 3,
            title: 'Khung giá thuê khu vực',
            subtitle: 'Khu vực P.25 Bình Thạnh studio đang ở mức 4.2 - 4.6 triệu',
            badgeText: 'Cần rà soát',
            isWarning: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required int index,
    required String title,
    required String subtitle,
    String? badgeText,
    bool isWarning = false,
  }) {
    bool isChecked = _checklistStatus[index];

    return InkWell(
      onTap: () {
        setState(() {
          _checklistStatus[index] = !_checklistStatus[index]; // toggle tick/bỏ tick
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isWarning ? AppColors.accentYellow.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              color: isChecked ? AppColors.primaryGreen : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warningOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badgeText, style: const TextStyle(fontSize: 9, color: AppColors.warningOrange, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              isWarning ? Icons.more_horiz : Icons.check_circle_outline,
              color: isWarning ? AppColors.warningOrange : AppColors.primaryGreen,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // widget khối lý do từ chối
  Widget _buildRejectionSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: Colors.redAccent),
                  SizedBox(width: 6),
                  Text('Lý do từ chối / Yêu cầu sửa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                ],
              ),
              Text('rejection_reason', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Gợi ý lý do phổ biến', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 6),

          // wrap danh sách chip gợi ý
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickReasons.map((reason) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _rejectionController.text = reason;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(reason, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // ô textField nhập chi tiết
          TextField(
            controller: _rejectionController,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Nhập chi tiết yêu cầu người đăng bổ sung/chỉnh sửa trước khi được xuất bản...',
              hintStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              fillColor: AppColors.background,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }

  // widget thanh nút bấm duyệt ở bottom
  Widget _buildBottomActionBar() {
    return Container(
      color: AppColors.cardSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // // xử lý từ chối duyệt bài
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                    SizedBox(width: 4),
                    Text('Từ chối duyệt', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // // xử lý phê duyệt bài đăng ngay
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.cardSurface, size: 18),
                    SizedBox(width: 4),
                    Text('Phê duyệt ngay', style: TextStyle(color: AppColors.cardSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),

              ),
            ),
          ),
        ],
      ),
    );
  }
}

// widget phụ: hiển thị chip thông tin nhỏ
class _ChipInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChipInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// widget phụ: hiển thị grid tiện ích
class GridViewWidget extends StatelessWidget {
  const GridViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final amenities = [
      {'icon': Icons.ac_unit, 'label': 'Máy lạnh Inverter'},
      {'icon': Icons.kitchen, 'label': 'Tủ lạnh 2 cánh'},
      {'icon': Icons.local_laundry_service, 'label': 'Máy giặt riêng'},
      {'icon': Icons.fingerprint, 'label': 'Khóa vân tay'},
      {'icon': Icons.elevator, 'label': 'Thang máy thẻ từ'},
      {'icon': Icons.access_time, 'label': 'Giờ giấc tự do 24/7'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 6,
      ),
      itemCount: amenities.length,
      itemBuilder: (context, index) {
        return Row(
          children: [
            Icon(amenities[index]['icon'] as IconData, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                amenities[index]['label'] as String,
                style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}