import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/post_service.dart';
import 'post_form.dart';

class PostDetailOwnerScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailOwnerScreen({super.key, required this.post});

  @override
  State<PostDetailOwnerScreen> createState() => _PostDetailOwnerScreenState();
}

class _PostDetailOwnerScreenState extends State<PostDetailOwnerScreen> {
  late Map<String, dynamic> _post;
  bool _hasChanged = false;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.post);
    if (_post['isSqlite'] != true && _post['id'] != null) {
      _refreshFromServer();
    }
  }

  Future<void> _refreshFromServer() async {
    setState(() => _isLoadingDetail = true);
    try {
      final detail = await PostService.fetchPostDetail(_post['id'].toString());
      if (mounted) {
        setState(() {
          _post = {
            'id': detail.id,
            'roomId': detail.roomId,
            'roomName': detail.roomName,
            'propertyId': detail.propertyId,
            'propertyName': detail.propertyName,
            'propertyAddress': detail.propertyAddress,
            'room': detail.room,
            'roomArea': detail.roomArea,
            'roomDeposit': detail.roomDeposit,
            'roomMaxPeople': detail.roomMaxPeople,
            'roomFloor': detail.roomFloor,
            'roomStatus': detail.roomStatus,
            'roomDescription': detail.roomDescription,
            'title': detail.title,
            'description': detail.description,
            'rawPrice': detail.price,
            'price': detail.priceFormatted,
            'amenities': detail.amenities,
            'views': detail.views,
            'likes': detail.likes,
            'date': detail.date,
            'status': detail.status,
            'submitNote': detail.submitNote,
            'rejectReason': detail.rejectReason,
            'image': detail.image,
            'images': detail.images,
          };
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải chi tiết bài đăng: $e');
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0đ';
    final numVal = (value is num) ? value.toInt() : int.tryParse(value.toString()) ?? 0;
    if (numVal <= 0) return 'Thỏa thuận';
    final str = numVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${str}đ';
  }

  String _roomStatusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'available':
        return 'Phòng trống';
      case 'rented':
        return 'Đang cho thuê';
      case 'maintenance':
        return 'Đang bảo trì';
      default:
        return 'Phòng trống';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = _post['status'] ?? 'draft';
    final List<String> amenities = (_post['amenities'] is List)
        ? (_post['amenities'] as List).map((e) => e.toString()).toList()
        : (_post['amenities'] is String && (_post['amenities'] as String).isNotEmpty)
            ? (_post['amenities'] as String).split(',').map((e) => e.trim()).toList()
            : [];

    final String imageUrl = _post['image'] ?? 'frontend/assets/images/anhPhongDemo.jpg';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _hasChanged);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
          title: const Text(
            'Chi tiết tin đăng & Phòng',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_isLoadingDetail)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Chỉnh sửa tin đăng',
                onPressed: _openEditForm,
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Ảnh bìa bài đăng
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 230,
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'frontend/assets/images/anhPhongDemo.jpg',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 64, color: Colors.grey),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _buildStatusBadge(status),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${_post['views'] ?? 0} lượt xem',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            '${_post['likes'] ?? 0}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Thông tin chính của bài đăng
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _post['price'] ?? 'Thỏa thuận',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                              Text(
                                'Ngày đăng: ${_post['date'] ?? ''}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _post['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.apartment_rounded, size: 16, color: AppColors.primaryGreen),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _post['room'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((_post['propertyAddress'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _post['propertyAddress'].toString(),
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (status == 'pending' && _post['submitNote'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade800, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _post['submitNote'].toString(),
                                style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (status == 'rejected') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Lý do từ chối: ${_post['rejectReason'] ?? 'Chưa đạt tiêu chí phê duyệt'}',
                                style: const TextStyle(fontSize: 13, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 3. Thông số chi tiết của phòng
                    _buildSectionCard(
                      title: 'Thông số chi tiết phòng',
                      icon: Icons.meeting_room_outlined,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoTile(
                                  icon: Icons.square_foot_rounded,
                                  label: 'Diện tích',
                                  value: (_post['roomArea'] != null && (_post['roomArea'] as num) > 0)
                                      ? '${_post['roomArea']} m²'
                                      : '25 m²',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInfoTile(
                                  icon: Icons.people_outline_rounded,
                                  label: 'Tối đa',
                                  value: (_post['roomMaxPeople'] != null && (_post['roomMaxPeople'] as num) > 0)
                                      ? '${_post['roomMaxPeople']} người'
                                      : '2 - 3 người',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoTile(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: 'Tiền đặt cọc',
                                  value: (_post['roomDeposit'] != null && (_post['roomDeposit'] as num) > 0)
                                      ? _formatCurrency(_post['roomDeposit'])
                                      : _formatCurrency(_post['rawPrice']),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInfoTile(
                                  icon: Icons.layers_outlined,
                                  label: 'Vị trí tầng',
                                  value: _post['roomFloor'] != null
                                      ? 'Tầng ${_post['roomFloor']}'
                                      : 'Tầng 1',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoTile(
                                  icon: Icons.domain_verification_outlined,
                                  label: 'Trạng thái phòng',
                                  value: _roomStatusLabel(_post['roomStatus']?.toString()),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInfoTile(
                                  icon: Icons.qr_code_rounded,
                                  label: 'Mã phòng',
                                  value: (_post['roomId'] ?? 'room_101').toString(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Tiện ích có sẵn
                    _buildSectionCard(
                      title: 'Tiện ích có sẵn',
                      icon: Icons.stars_outlined,
                      child: amenities.isEmpty
                          ? Text(
                              'Chưa cập nhật tiện ích cho bài đăng này.',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: amenities.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 15,
                                        color: AppColors.primaryGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // 5. Mô tả chi tiết bài đăng
                    _buildSectionCard(
                      title: 'Mô tả chi tiết bài đăng',
                      icon: Icons.description_outlined,
                      child: Text(
                        (_post['description'] ?? '').toString().trim().isNotEmpty
                            ? _post['description'].toString()
                            : 'Chưa có mô tả chi tiết cho bài đăng này.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),

                    if ((_post['roomDescription'] ?? '').toString().trim().isNotEmpty &&
                        _post['roomDescription'] != _post['description']) ...[
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Ghi chú gốc của phòng',
                        icon: Icons.info_outline,
                        child: Text(
                          _post['roomDescription'].toString(),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey[800],
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openEditForm,
                  icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                  label: const Text(
                    'CHỈNH SỬA TIN ĐĂNG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditForm() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostFormScreen(initialData: _post),
      ),
    );
    if (res == true) {
      _hasChanged = true;
      if (_post['isSqlite'] == true) {
        if (mounted) Navigator.pop(context, true);
      } else {
        await _refreshFromServer();
      }
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case 'active':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        label = 'Đang hiển thị';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        bg = const Color(0xFFFFF3E0);
        text = const Color(0xFFE65100);
        label = 'Chờ Admin duyệt';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        label = 'Admin từ chối';
        icon = Icons.highlight_off;
        break;
      case 'hidden':
        bg = const Color(0xFFECEFF1);
        text = const Color(0xFF546E7A);
        label = 'Đã ẩn';
        icon = Icons.visibility_off_outlined;
        break;
      case 'draft':
      default:
        bg = const Color(0xFFF5F5F5);
        text = const Color(0xFF757575);
        label = 'Bản nháp';
        icon = Icons.edit_note;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

