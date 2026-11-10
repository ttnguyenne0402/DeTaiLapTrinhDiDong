import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/admin/admin_post_service.dart';

class RoomApprovalDetailScreen extends StatefulWidget {
  const RoomApprovalDetailScreen({super.key});

  @override
  State<RoomApprovalDetailScreen> createState() => _RoomApprovalDetailScreenState();
}

class _RoomApprovalDetailScreenState extends State<RoomApprovalDetailScreen> {
  final TextEditingController _rejectionController = TextEditingController();
  AdminPostDetail? _detail;
  bool _isLoading = true;
  String? _postId;

  final List<String> _quickReasons = [
    'Ảnh mờ / thiếu sáng',
    'Thiếu cam kết PCCC',
    'Sai giá so với hợp đồng',
    'Tiêu đề sai lệch',
  ];

  // Khởi tạo mặc định 4 tiêu chí chưa được tick
  final List<bool> _checklistStatus = [false, false, false, false];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_postId == null) {
      _postId = ModalRoute.of(context)?.settings.arguments as String?;
      if (_postId != null) {
        _loadDetail(_postId!);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDetail(String id) async {
    try {
      final data = await AdminPostService.getPostDetail(id);
      setState(() {
        _detail = data;
        _isLoading = false;
        if (data.rejectionReason != null && data.rejectionReason!.isNotEmpty) {
          _rejectionController.text = data.rejectionReason!;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Lỗi tải chi tiết: $e");
    }
  }

  // LOGIC KIỂM DUYỆT CÓ RÀNG BUỘC CHECKLIST
  Future<void> _handleModerate(String action) async {
    if (_postId == null) return;

    // 1. Phê duyệt: Bắt buộc đạt đủ 4/4 tiêu chí
    if (action == 'approve') {
      final bool isAllChecked = _checklistStatus.every((status) => status == true);
      if (!isAllChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Vui lòng kiểm tra và tích đủ 4/4 tiêu chí thẩm định trước khi phê duyệt!'),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return; // Dừng lại, không gửi API
      }
    }

    // 2. Từ chối: Bắt buộc có lý do
    if (action == 'reject') {
      final reason = _rejectionController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Vui lòng chọn hoặc nhập lý do từ chối bài đăng!'),
          ),
        );
        return; // Dừng lại
      }
    }

    // Gửi yêu cầu lên Backend
    final success = await AdminPostService.moderatePost(
      id: _postId!,
      action: action,
      rejectionReason: _rejectionController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: action == 'approve' ? AppColors.primaryGreen : Colors.red,
          content: Text(action == 'approve' ? 'Đã phê duyệt tin thành công!' : 'Đã từ chối tin đăng!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem đã đạt đủ 4 tiêu chí chưa để cập nhật màu nút
    final bool isAllChecked = _checklistStatus.every((status) => status == true);

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
          'Chi tiết tin',
          style: TextStyle(color: AppColors.cardSurface, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _detail == null
          ? const Center(child: Text('Không tìm thấy thông tin bài đăng.', style: TextStyle(color: Colors.white)))
          : Column(
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
                    _buildTopMetadata(),
                    const SizedBox(height: 16),
                    _buildImageSection(),
                    const SizedBox(height: 16),
                    _buildPropertyDetails(),
                    const SizedBox(height: 16),
                    _buildValidationChecklist(),
                    const SizedBox(height: 16),
                    _buildRejectionSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomActionBar(isAllChecked),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTopMetadata() {
    final statusText = _detail?.status == 'published'
        ? 'ĐÃ DUYỆT'
        : _detail?.status == 'rejected'
        ? 'TỪ CHỐI'
        : 'CHỜ KIỂM DUYỆT';

    final statusColor = _detail?.status == 'published'
        ? AppColors.primaryGreen
        : _detail?.status == 'rejected'
        ? Colors.redAccent
        : AppColors.warningOrange;

    final dateStr = _detail?.createdAt != null
        ? '${_detail!.createdAt!.day.toString().padLeft(2, '0')}/${_detail!.createdAt!.month.toString().padLeft(2, '0')}/${_detail!.createdAt!.year}'
        : '--/--/----';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Mã tin: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(
              '#${_detail?.id ?? ''}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
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
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ngày gửi', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Người đăng', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          Text(
                            _detail?.ownerName ?? 'Ẩn danh',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
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

  Widget _buildImageSection() {
    final images = _detail?.images ?? [];
    final firstImage = images.isNotEmpty ? images.first : '';

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
            children: [
              const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                'Hình ảnh xác thực (${images.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: firstImage.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    firstImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                )
                    : const Center(
                  child: Text('Chưa có ảnh', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
            ],
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length - 1,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final imgUrl = images[index + 1];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imgUrl,
                      width: 70,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 20, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

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
          Text(
            _detail?.title ?? '',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Giá thuê niêm yết', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatCurrency(_detail?.price ?? 0),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                          ),
                          const SizedBox(width: 2),
                          const Text('đ/tháng', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tiền đặt cọc', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatCurrency(_detail?.deposit ?? 0)} đ',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.warningOrange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ChipInfo(icon: Icons.square_foot, label: '${_detail?.area ?? 0} m²'),
              const SizedBox(width: 8),
              _ChipInfo(icon: Icons.layers_outlined, label: 'Tầng ${_detail?.floor ?? 1}'),
              const SizedBox(width: 8),
              _ChipInfo(icon: Icons.people_outline, label: 'Tối đa ${_detail?.maxPeople ?? 1} người'),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Tiện ích đi kèm', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _detail?.amenities.isNotEmpty == true
              ? Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _detail!.amenities.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(item, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
              );
            }).toList(),
          )
              : const Text('Chưa có thông tin tiện ích.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          const Text('Mô tả bài đăng (description)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              _detail?.description ?? 'Không có mô tả.',
              style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationChecklist() {
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
                  color: passedCount == 4 ? AppColors.lightGreen : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$passedCount/4 Đạt',
                  style: TextStyle(
                    fontSize: 10,
                    color: passedCount == 4 ? AppColors.primaryGreen : AppColors.warningOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCheckItem(
            index: 0,
            title: 'Tính xác thực phòng & chủ sở hữu',
            subtitle: 'Khớp với thông tin đăng ký của chủ nhà',
          ),
          _buildCheckItem(
            index: 1,
            title: 'Hình ảnh chất lượng & minh bạch',
            subtitle: 'Không chèn số điện thoại lạ hay ảnh mạng trùng lặp',
          ),
          _buildCheckItem(
            index: 2,
            title: 'Tiêu chuẩn PCCC & an toàn',
            subtitle: 'Đáp ứng lối thoát hiểm và không gian thông thoáng',
          ),
          _buildCheckItem(
            index: 3,
            title: 'Khung giá thuê khu vực hợp lý',
            subtitle: 'Giá thuê và tiền cọc phù hợp mặt bằng chung',
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required int index,
    required String title,
    required String subtitle,
  }) {
    bool isChecked = _checklistStatus[index];

    return InkWell(
      onTap: () {
        setState(() {
          _checklistStatus[index] = !_checklistStatus[index];
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isChecked ? AppColors.lightGreen.withOpacity(0.3) : Colors.transparent,
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
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            ],
          ),
          const SizedBox(height: 8),
          const Text('Gợi ý lý do phổ biến', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
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
          TextField(
            controller: _rejectionController,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Nhập chi tiết yêu cầu người đăng bổ sung/chỉnh sửa...',
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

  Widget _buildBottomActionBar(bool isAllChecked) {
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _handleModerate('reject'),
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
                  backgroundColor: isAllChecked ? AppColors.primaryGreen : Colors.grey.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _handleModerate('approve'),
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