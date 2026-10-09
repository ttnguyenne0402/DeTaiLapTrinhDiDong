import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TenantManagementScreen extends StatelessWidget {
  const TenantManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Người ở cùng',
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
                    _buildRoomHeaderCard(),
                    const SizedBox(height: 16),
                    _buildMainTenantCard(),
                    const SizedBox(height: 16),
                    _buildCoTenantCard(),
                    const SizedBox(height: 16),
                    _buildAddMemberCard(),
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

  //thông tin phòng và trạng thái khai báo công an
  Widget _buildRoomHeaderCard() {
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
              const Row(
                children: [
                  Icon(Icons.meeting_room, color: AppColors.accentYellow, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Phòng 201 – Tầng 2',
                    style: TextStyle(
                      color: AppColors.cardSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HĐ #HD-2024-P201',
                  style: TextStyle(color: AppColors.cardSurface, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people, color: AppColors.cardSurface, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Đang ở: 2 / Tối đa: 3 người',
                    style: TextStyle(color: AppColors.cardSurface, fontSize: 12),
                  ),
                ],
              ),
              const Text(
                'Còn trống 1 suất',
                style: TextStyle(color: AppColors.accentYellow, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 2 / 3,
              minHeight: 5,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentYellow),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.lightGreen, size: 14),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '2/2 Đã hoàn thành khai báo CA Phường 25, Bình Thạnh',
                  style: TextStyle(color: AppColors.lightGreen, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //thông tin đại diện hợp đồng (chủ hộ)
  Widget _buildMainTenantCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  Icon(Icons.badge, color: AppColors.primaryGreen, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Đại diện hợp đồng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Chủ hộ đứng tên',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.lightGreen,
                    child: Icon(Icons.person, color: AppColors.primaryGreen, size: 30),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nguyễn Văn An',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Chính chủ',
                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Nam • Sinh năm 1998 (26 tuổi)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const Text(
                      '0908 123 456',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),
          _buildInfoRow('CCCD số:', '079098001234'),
          _buildInfoRow('Cấp ngày:', '12/04/2021 (Cục CSQLHC)'),
          _buildInfoRow('Thường trú:', 'Xuân Lộc, Đồng Nai'),
          _buildInfoRowWithBadge('Tạm trú:', 'Đã duyệt 28/08/2024 (TT-77291)'),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ảnh CCCD 2 mặt (Đã lưu trữ)',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Row(
                children: [
                  Icon(Icons.verified, size: 12, color: AppColors.primaryGreen),
                  SizedBox(width: 4),
                  Text(
                    'Đã đối soát khớp',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildCccdThumbnail('Mặt trước')),
              const SizedBox(width: 8),
              Expanded(child: _buildCccdThumbnail('Mặt sau')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, size: 14, color: AppColors.textPrimary),
                  label: const Text('Gọi điện', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
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
                  icon: const Icon(Icons.message, size: 14, color: AppColors.textPrimary),
                  label: const Text('Nhắn tin', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.badge_outlined, size: 14, color: AppColors.cardSurface),
                  label: const Text('Chi tiết', style: TextStyle(color: AppColors.cardSurface, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //thông tin người ở cùng (ở ghép)
  Widget _buildCoTenantCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  Icon(Icons.group_add, color: AppColors.primaryGreen, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Người ở cùng (Ở ghép)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '1 thành viên',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.lightGreen,
                child: Icon(Icons.person, color: AppColors.primaryGreen, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Lê Thị Hoa',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Vợ / Bạn cùng phòng',
                            style: TextStyle(
                              color: AppColors.warningOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Cai Lậy, Tiền Giang',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow('CCCD:', '079199005678 (05/01/2022)'),
          _buildInfoRow('Số điện thoại:', '0791 990 567'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Xe máy đăng ký:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Row(
                children: [
                  const Icon(Icons.two_wheeler, size: 14, color: AppColors.textPrimary),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '63-B1 889.21 (Thẻ #TX-01)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 12, color: AppColors.primaryGreen),
                    SizedBox(width: 4),
                    Text(
                      'Đã khai báo qua VNeID',
                      style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.person_remove, size: 16, color: Colors.red),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  //thêm thành viên ở ghép mới
  Widget _buildAddMemberCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.lightGreen,
            child: Icon(Icons.group_add, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            '+ Thêm thành viên ở ghép mới',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Phòng còn trống 1 chỗ theo quy chuẩn hợp đồng.\nKhai báo nhanh chỉ với ảnh CCCD.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: AppColors.warningOrange, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lưu ý: Khai báo đầy đủ để tránh mức phạt hành chính tạm trú từ 500.000đ - 1.000.000đ khi đoàn kiểm tra định kỳ.',
                    style: TextStyle(fontSize: 9, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_back, size: 14, color: AppColors.textPrimary),
              label: const Text('Hợp đồng', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add, size: 14, color: AppColors.textPrimary),
              label: const Text(
                '+ Thêm người ở ghép',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentYellow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //hàm helper dựng dòng thông tin đơn
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  //hàm helper dựng dòng thông tin có badge
  Widget _buildInfoRowWithBadge(String label, String badgeText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 12, color: AppColors.primaryGreen),
              const SizedBox(width: 4),
              Text(
                badgeText,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //hàm helper dựng khung ảnh cccd
  Widget _buildCccdThumbnail(String label) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.credit_card, color: AppColors.textSecondary, size: 30),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}