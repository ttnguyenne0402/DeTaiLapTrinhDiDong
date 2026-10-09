import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MaintenanceDetailScreen extends StatefulWidget {
  const MaintenanceDetailScreen({super.key});

  @override
  State<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  // 0: chủ nhà chịu (hao mòn), 1: trừ vào cọc/tiền phòng khách
  int _costPayerGroup = 0;
  final TextEditingController _costController = TextEditingController(text: '350.000');
  final TextEditingController _noteController = TextEditingController(
    text: 'Thay co nối PVC 34 và băng keo lụa chống rò rỉ.',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Màu nền Scaffold đặt là màu xanh của AppBar
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi Tiết Sửa Chữa',
          style: TextStyle(
            color: Colors.white,
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
      // Container chính bọc toàn bộ body, bo 2 góc trên trái và phải
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background, // Màu nền trắng/kem bên dưới
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24), // Bo góc 2 bên trái & phải ở cạnh trên
          ),
        ),
        child: ClipRRect(
          // Bo góc luôn cho nội dung bên trong để không bị lem ra ngoài khi cuộn
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: Column(
            children: [
              // Nội dung chi tiết dạng cuộn
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // mã sự cố và tên tiêu đề
                    _buildHeaderInfoCard(),
                    const SizedBox(height: 16),

                    // thông tin phòng và người thuê
                    _buildTenantInfoCard(),
                    const SizedBox(height: 16),

                    // hình ảnh hiện trường sự cố
                    _buildImagesCard(),
                    const SizedBox(height: 16),

                    // chi phí và phân bổ thanh toán
                    _buildCostAndPayerCard(),
                    const SizedBox(height: 16),

                    // lịch sử tiến trình sự cố
                    _buildTimelineCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // thanh nút bấm thao tác ở đáy màn hình
              _buildBottomActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // widget thông tin tiêu đề và mô tả sự cố
  Widget _buildHeaderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Text(
                '#SC-2024-0829',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Đang xử lý',
                  style: TextStyle(
                    color: AppColors.warningOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Rò rỉ ống nước bồn rửa chén gây tràn sàn bếp',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              const Text(
                '09:15 - 31/08/2024 (cách đây 2 giờ)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // khung mô tả từ khách
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MÔ TẢ SỰ CỐ TỪ KHÁCH:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '"Nước rỉ liên tục từ đầu van co T bên dưới chậu rửa chén, hiện nước đã tràn ra sàn hành lang. Khách đã khóa van tạm thời."',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // widget thông tin phòng và người thuê
  Widget _buildTenantInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work, color: AppColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phòng 302 • Tầng 3',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Khu Trọ Bình Thạnh (Nhà A)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HĐ còn hạn',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderLight),
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.lightGreen,
                child: Icon(Icons.person, color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trần Thị Bích',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '0933 555 789',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.phone, color: AppColors.primaryGreen),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightGreen,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.message, color: AppColors.primaryGreen),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // widget hình ảnh hiện trường
  Widget _buildImagesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  Icon(Icons.photo_library, size: 18, color: AppColors.primaryGreen),
                  SizedBox(width: 8),
                  Text(
                    'Hình ảnh hiện trường (2)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.fullscreen, size: 16, color: AppColors.textSecondary),
                label: const Text(
                  'Phóng to',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, color: AppColors.primaryGreen),
                        SizedBox(height: 4),
                        Text('Dưới bồn rửa', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, color: AppColors.primaryGreen),
                        SizedBox(height: 4),
                        Text('Nước tràn sàn', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // widget nhập chi phí sửa chữa và phân bổ thanh toán
  Widget _buildCostAndPayerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.payments, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text(
                'Chi phí & Phân bổ thanh toán',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // nhập số tiền chi phí
          TextField(
            controller: _costController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Chi phí thực tế (đ)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Phân bổ chi trả:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          Row(
            children: [
              Expanded(
                child: RadioListTile<int>(
                  value: 0,
                  groupValue: _costPayerGroup,
                  title: const Text('Chủ nhà chịu (Hao mòn)', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (val) {
                    setState(() {
                      _costPayerGroup = val!;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<int>(
                  value: 1,
                  groupValue: _costPayerGroup,
                  title: const Text('Trừ cọc / Tính khách', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (val) {
                    setState(() {
                      _costPayerGroup = val!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ghi chú chi phí
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Ghi chú vật tư / hạng mục sửa',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  // widget tiến trình sự cố đã giản lược
  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.timeline, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text(
                'Lịch sử tiến trình',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            time: '09:15',
            title: 'Khách báo hỏng bồn rửa',
            subtitle: 'Trần Thị Bích gửi ảnh hiện trường qua app',
            isDone: true,
          ),
          _buildTimelineItem(
            time: '09:20',
            title: 'Chủ trọ tiếp nhận',
            subtitle: 'Chuyển trạng thái sang Đang xử lý',
            isDone: true,
          ),
          _buildTimelineItem(
            time: 'Đang chờ',
            title: 'Nghiệm thu & Hoàn thành',
            subtitle: 'Lưu chi phí vào sổ sách thu chi',
            isDone: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // widget từng dòng timeline
  Widget _buildTimelineItem({
    required String time,
    required String title,
    required String subtitle,
    required bool isDone,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDone ? AppColors.primaryGreen : AppColors.textSecondary,
            ),
          ),
        ),
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: isDone ? AppColors.primaryGreen : AppColors.textSecondary,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: AppColors.borderLight,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  // widget nút bấm xử lý ở đáy màn hình
  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.accentYellow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Nghiệm thu & Đóng',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}