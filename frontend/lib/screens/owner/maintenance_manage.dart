import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/owner_drawer.dart';

class MaintenanceManageScreen extends StatefulWidget {
  const MaintenanceManageScreen({super.key});

  @override
  State<MaintenanceManageScreen> createState() => _MaintenanceManageScreenState();
}

class _MaintenanceManageScreenState extends State<MaintenanceManageScreen> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'Tất cả (5)',
    'Chờ xử lý (2)',
    'Đang sửa (1)',
    'Đã xong (2)',
  ];

  // hàm mở modal bottom sheet tạo sự cố dành cho chủ trọ ghi nhận tại chỗ
  void _showCreateIssueBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedProperty = 'Khu Trọ Tân Bình 1';
    String selectedRoom = 'Khu vực chung';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // tiêu đề modal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chủ trọ ghi nhận sự cố',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // dropdown chọn khu trọ
                DropdownButtonFormField<String>(
                  value: selectedProperty,
                  decoration: InputDecoration(
                    labelText: 'Khu trọ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Khu Trọ Tân Bình 1', 'Khu Trọ Bình Thạnh 2']
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedProperty = val;
                  },
                ),
                const SizedBox(height: 12),

                // dropdown chọn phòng hoặc khu vực chung
                DropdownButtonFormField<String>(
                  value: selectedRoom,
                  decoration: InputDecoration(
                    labelText: 'Vị trí / Phòng',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Khu vực chung', 'Phòng 101', 'Phòng 201', 'Phòng 302']
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedRoom = val;
                  },
                ),
                const SizedBox(height: 12),

                // ô nhập tiêu đề sự cố
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề sự cố (ví dụ: Hỏng ổ khóa cổng)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // ô nhập mô tả chi tiết
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mô tả ngắn (không bắt buộc)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // nút bấm chụp ảnh hiện trạng tại chỗ
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                  label: const Text(
                    'Chụp ảnh hiện trạng',
                    style: TextStyle(color: AppColors.primaryGreen),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // nút xác nhận lưu sự cố
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Lưu sự cố & Tiến hành sửa',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      drawer:OwnerDrawer(
        currentRoute: 'maintenance',
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Quản lý sửa chữa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),

          SizedBox(width: 10,),
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 16,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),

          SizedBox(width: 10,)
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // phần thân chứa danh sách sự cố với góc bo 24px
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // thẻ tổng quan báo cáo chi phí sự cố
                    _buildSummaryCard(),
                    const SizedBox(height: 16),

                    // thanh tìm kiếm sự cố
                    _buildSearchBar(),
                    const SizedBox(height: 12),

                    // danh sách chip lọc trạng thái
                    _buildFilterChips(),
                    const SizedBox(height: 16),

                    // thẻ sự cố phòng 302 - trạng thái chờ tiếp nhận
                    _buildMaintenanceCard(
                      propertyName: 'Khu Trọ Tân Bình 1',
                      room: 'Phòng 302',
                      floor: 'Tầng 3',
                      tenantName: 'Trần Thị Bích',
                      tenantPhone: '0933 555 799',
                      title: 'Rò rỉ ống nước bồn rửa chén gây tràn sàn',
                      description: 'Nước rỉ mạnh từ co nối bên dưới bồn, chảy tràn ra sàn gỗ phòng khách.',
                      timeAgo: '15 phút trước',
                      imageCount: 2,
                      priorityText: 'Khẩn cấp',
                      priorityColor: Colors.red,
                      statusText: 'Chờ tiếp nhận',
                      statusColor: AppColors.textSecondary,
                      actionButtons: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.phone, size: 16, color: AppColors.primaryGreen),
                              label: const Text(
                                'Gọi khách',
                                style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primaryGreen),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Tiếp nhận',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // thẻ sự cố phòng 201 - trạng thái đang xử lý
                    _buildMaintenanceCard(
                      propertyName: 'Khu Trọ Bình Thạnh 2',
                      room: 'Phòng 201',
                      floor: 'Tầng 2',
                      tenantName: 'Nguyễn Văn An',
                      tenantPhone: '0908 123 456',
                      title: 'Máy lạnh không mát, chớp đèn báo lỗi',
                      description: 'Đã bật 18 độ quạt gió mạnh 1 tiếng nhưng chỉ ra gió thường, phòng rất ngột ngạt.',
                      timeAgo: 'Báo lúc 09:30 hôm nay',
                      imageCount: 1,
                      priorityText: 'Ưu tiên cao',
                      priorityColor: AppColors.warningOrange,
                      statusText: 'Đang xử lý',
                      statusColor: AppColors.warningOrange,
                      actionButtons: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                          label: const Text(
                            'Xác nhận đã sửa xong',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // thẻ sự cố phòng 105 - trạng thái đã hoàn thành
                    _buildMaintenanceCard(
                      propertyName: 'Khu Trọ Tân Bình 1',
                      room: 'Phòng 105',
                      floor: 'Tầng 1',
                      tenantName: 'Phạm Hoàng Nam',
                      tenantPhone: '0911 222 333',
                      title: 'Thay bóng đèn tuýp LED ban công bị hỏng',
                      description: '',
                      timeAgo: 'Xong lúc: 26/08/2024',
                      imageCount: 1,
                      priorityText: 'Bình thường',
                      priorityColor: AppColors.textSecondary,
                      statusText: 'Đã hoàn thành',
                      statusColor: AppColors.primaryGreen,
                      costText: 'Chi phí: 80.000đ (Đã cộng hóa đơn T8)',
                      actionButtons: const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 60), // khoảng trống cuộn cho fab
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // nút fab mở modal thêm sự cố mới cho chủ trọ
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateIssueBottomSheet(context),
        backgroundColor: AppColors.accentYellow,
        icon: const Icon(Icons.add, color: AppColors.textPrimary),
        label: const Text(
          'Tạo sự cố mới',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // widget thẻ tổng quan chỉ số sự cố và chi phí
  Widget _buildSummaryCard() {
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
              const Text(
                'THÁNG 08/2024\nTổng quan sự cố kỹ thuật',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business_center, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng sự cố',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '5 ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'vụ việc',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dự toán chi phí',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '1.450.000 đ',
                        style: TextStyle(
                          color: AppColors.accentYellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // widget ô tìm kiếm sự cố
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo khu trọ, số phòng, tên khách...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
          Icon(Icons.tune, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  // widget thanh cuộn danh sách chip lọc trạng thái
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(_filters[index]),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: AppColors.cardSurface,
              selectedColor: AppColors.primaryGreen,
              onSelected: (bool selected) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryGreen : AppColors.borderLight,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // widget khung hiển thị chi tiết thẻ sự cố
  Widget _buildMaintenanceCard({
    required String propertyName,
    required String room,
    required String floor,
    required String tenantName,
    required String tenantPhone,
    required String title,
    required String description,
    required String timeAgo,
    required int imageCount,
    required String priorityText,
    required Color priorityColor,
    required String statusText,
    required Color statusColor,
    required Widget actionButtons,
    String? costText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
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
          // tiêu đề thẻ: tên khu trọ, số phòng, tên khách thuê và nhãn trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // tên khu trọ
                    Row(
                      children: [
                        const Icon(Icons.location_city, size: 14, color: AppColors.primaryGreen),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            propertyName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          room,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $floor',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$tenantName • $tenantPhone',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priorityText,
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderLight),

          // nội dung sự cố kèm ảnh đính kèm
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageCount > 0) ...[
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      timeAgo,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // dòng hiển thị chi phí sửa chữa nếu đã hoàn thành
          if (costText != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                costText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],

          // các nút bấm hành động phía dưới thẻ
          if (actionButtons is! SizedBox) ...[
            const SizedBox(height: 16),
            actionButtons,
          ],
        ],
      ),
    );
  }
}