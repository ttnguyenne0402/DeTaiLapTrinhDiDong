import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/owner/post_service.dart';
import '../../services/tenant/review_service.dart';
import '../../utils/post_image_path.dart';
import '../../widgets/common/shared_post_image.dart';
import '../../widgets/tenant/open_street_map_widget.dart';
import '../tenant/reviews_screen.dart';
import 'post_form.dart';

class PostDetailOwnerScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailOwnerScreen({super.key, required this.post});

  @override
  State<PostDetailOwnerScreen> createState() => _PostDetailOwnerScreenState();
}

class _PostDetailOwnerScreenState extends State<PostDetailOwnerScreen> {
  late Map<String, dynamic> _post;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  bool _hasChanged = false;
  bool _isLoadingDetail = false;

  double _averageRating = 0;
  int _reviewCount = 0;
  bool _isReviewLoading = false;
  String _loadedReviewRoomId = '';

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.post);
    if (_post['isSqlite'] != true) {
      final roomId = (_post['roomId'] ?? '').toString().trim();
      if (roomId.isNotEmpty) {
        _loadReviewSummary(roomId);
      }
      if (_post['id'] != null) {
        _refreshFromServer();
      }
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _refreshFromServer() async {
    setState(() => _isLoadingDetail = true);
    try {
      final detail = await PostService.fetchPostDetail(_post['id'].toString());
      if (!mounted) return;
      setState(() {
        _post = {
          'id': detail.id,
          'roomId': detail.roomId,
          'roomName': detail.roomName,
          'propertyId': detail.propertyId,
          'propertyName': detail.propertyName,
          'propertyAddress': detail.propertyAddress,
          'propertyWard': detail.propertyWard,
          'propertyDistrict': detail.propertyDistrict,
          'latitude': detail.latitude,
          'longitude': detail.longitude,
          'ownerName': detail.ownerName,
          'ownerPhone': detail.ownerPhone,
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
          'services': detail.services,
          'views': detail.views,
          'likes': detail.likes,
          'date': detail.date,
          'status': detail.status,
          'submitNote': detail.submitNote,
          'rejectReason': detail.rejectReason,
          'image': detail.image,
          'images': detail.images,
        };
        _currentImageIndex = 0;
        _isLoadingDetail = false;
      });
      final newRoomId = detail.roomId.trim();
      if (newRoomId.isNotEmpty && newRoomId != _loadedReviewRoomId) {
        _loadReviewSummary(newRoomId);
      }
    } catch (e) {
      debugPrint('Lỗi tải chi tiết bài đăng: $e');
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  Future<void> _loadReviewSummary(String roomId) async {
    _loadedReviewRoomId = roomId;
    if (mounted) setState(() => _isReviewLoading = true);
    try {
      final summary = await ReviewService.getRoomReviewSummary(roomId);
      if (!mounted) return;
      final avgVal = summary['averageRating'];
      final countVal = summary['totalReviews'];
      setState(() {
        _averageRating = avgVal is num
            ? avgVal.toDouble()
            : double.tryParse(avgVal?.toString() ?? '') ?? 0;
        _reviewCount = countVal is num
            ? countVal.toInt()
            : int.tryParse(countVal?.toString() ?? '') ?? 0;
        _isReviewLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isReviewLoading = false);
      }
    }
  }

  List<String> get _galleryImages {
    final rawList = _post['images'];
    final list = <String>[];
    if (rawList is List) {
      for (final item in rawList) {
        final str = item.toString().trim();
        if (str.isNotEmpty && !list.contains(str)) {
          list.add(str);
        }
      }
    }
    if (list.isEmpty) {
      final single = (_post['image'] ?? '').toString().trim();
      list.add(single.isNotEmpty ? single : postImageFallback);
    }
    return list;
  }

  List<String> get _amenities {
    final raw = _post['amenities'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> get _services {
    final raw = _post['services'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  String get _fullAddress {
    final rawAddr = (_post['propertyAddress'] ?? '').toString().trim();
    final ward = (_post['propertyWard'] ?? '').toString().trim();
    final district = (_post['propertyDistrict'] ?? '').toString().trim();
    final parts = <String>[
      ...rawAddr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty),
      if (ward.isNotEmpty) ward,
      if (district.isNotEmpty) district,
    ];
    final unique = <String>[];
    final seen = <String>{};
    for (final p in parts) {
      final key = p.toLowerCase();
      if (seen.add(key)) unique.add(p);
    }
    return unique.join(', ');
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _formatCurrency(dynamic value) {
    final numVal = (value is num)
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    if (numVal <= 0) return 'Thỏa thuận';
    final str = numVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$strđ';
  }

  String _formatArea(double area) {
    if (area == area.roundToDouble()) return area.toInt().toString();
    return area.toStringAsFixed(1);
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
        return 'Đang cập nhật';
    }
  }

  Color _roomStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'rented':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRatingLabel(double rating) {
    if (_reviewCount == 0) return 'Chưa có đánh giá';
    if (rating >= 4.5) return 'Xuất sắc';
    if (rating >= 4.0) return 'Rất tốt';
    if (rating >= 3.0) return 'Tốt';
    if (rating >= 2.0) return 'Trung bình';
    return 'Cần cải thiện';
  }

  IconData _amenityIcon(String amenity) {
    final value = amenity.toLowerCase();
    if (value.contains('máy lạnh') || value.contains('điều hòa')) {
      return Icons.ac_unit_rounded;
    }
    if (value.contains('wifi')) return Icons.wifi_rounded;
    if (value.contains('tủ lạnh') || value.contains('bếp')) {
      return Icons.kitchen_rounded;
    }
    if (value.contains('máy giặt')) return Icons.local_laundry_service_rounded;
    if (value.contains('ban công') || value.contains('cửa sổ')) {
      return Icons.balcony_rounded;
    }
    if (value.contains('camera')) return Icons.videocam_rounded;
    if (value.contains('wc') || value.contains('vệ sinh')) {
      return Icons.wc_rounded;
    }
    if (value.contains('xe')) return Icons.two_wheeler_rounded;
    if (value.contains('thang máy')) return Icons.elevator_rounded;
    if (value.contains('vân tay') || value.contains('thẻ từ')) {
      return Icons.fingerprint_rounded;
    }
    if (value.contains('pccc')) return Icons.fire_extinguisher_rounded;
    if (value.contains('giờ giấc')) return Icons.access_time_rounded;
    if (value.contains('gác')) return Icons.stairs_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildImageItem(String path, {double? width, double? height}) {
    final displayPath = postImageDisplayPath(path);
    if (!isSharedPostImage(displayPath) && File(displayPath).existsSync()) {
      return Image.file(
        File(displayPath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => SharedPostImage(
          path: postImageFallback,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      );
    }
    return SharedPostImage(
      path: displayPath,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _galleryImages;
    final status = (_post['status'] ?? 'draft').toString();
    final roomId = (_post['roomId'] ?? '').toString().trim();
    final isSqlite = _post['isSqlite'] == true;
    final fullAddress = _fullAddress;
    final lat = _toDouble(_post['latitude']);
    final lng = _toDouble(_post['longitude']);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _hasChanged);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeroAppBar(images, status),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (images.length > 1) ...[
                      _buildThumbnailStrip(images),
                      const SizedBox(height: 16),
                    ],
                    _buildHeaderSection(fullAddress),
                    const SizedBox(height: 14),
                    _buildMetadataRow(),
                    if (status == 'pending' && _post['submitNote'] != null) ...[
                      const SizedBox(height: 12),
                      _buildBanner(
                        icon: Icons.hourglass_top_rounded,
                        color: Colors.amber.shade800,
                        bgColor: Colors.amber.shade50,
                        borderColor: Colors.amber.shade300,
                        text: _post['submitNote'].toString(),
                      ),
                    ],
                    if (status == 'rejected') ...[
                      const SizedBox(height: 12),
                      _buildBanner(
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                        bgColor: Colors.red.shade50,
                        borderColor: Colors.red.shade200,
                        text:
                            'Lý do từ chối: ${_post['rejectReason'] ?? 'Chưa đạt tiêu chí phê duyệt'}',
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildQuickInfo(),
                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      icon: Icons.home_work_rounded,
                      title: 'Thông tin phòng',
                    ),
                    const SizedBox(height: 10),
                    _buildRoomInfoCard(),
                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Tiện nghi phòng trọ',
                    ),
                    const SizedBox(height: 10),
                    _buildAmenitiesSection(),
                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      icon: Icons.payments_outlined,
                      title: 'Bảng giá dịch vụ đi kèm',
                    ),
                    const SizedBox(height: 10),
                    _buildServicesSection(),
                    const SizedBox(height: 22),

                    _buildSectionTitle(
                      icon: Icons.description_outlined,
                      title: 'Mô tả bài đăng',
                    ),
                    const SizedBox(height: 10),
                    _buildDescriptionSection(),

                    if (!isSqlite && roomId.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _buildReviewsSection(roomId),
                    ],

                    if (fullAddress.isNotEmpty ||
                        (lat != null && lng != null)) ...[
                      const SizedBox(height: 22),
                      _buildSectionTitle(
                        icon: Icons.location_on_rounded,
                        title: 'Vị trí phòng',
                      ),
                      const SizedBox(height: 10),
                      _buildLocationCard(fullAddress, lat, lng),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
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
            child: ElevatedButton.icon(
              onPressed: _openEditForm,
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
              label: const Text(
                'CHỈNH SỬA TIN ĐĂNG',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAppBar(List<String> images, String status) {
    final safeIndex =
        _currentImageIndex < images.length ? _currentImageIndex : 0;

    return SliverAppBar(
      expandedHeight: 290,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryGreen,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _CircleHeaderButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Quay lại',
          onTap: () => Navigator.pop(context, _hasChanged),
        ),
      ),
      title: const Text(
        'Chi tiết tin đăng',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _isLoadingDetail
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : _CircleHeaderButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Chỉnh sửa tin đăng',
                  onTap: _openEditForm,
                ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _imagePageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return _buildImageItem(
                  images[index],
                  width: double.infinity,
                  height: 290,
                );
              },
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: _buildStatusBadge(status),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye_outlined,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${_post['views'] ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.favorite,
                        size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${_post['likes'] ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (images.length > 1) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.photo_library_outlined,
                          size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${safeIndex + 1}/${images.length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    final active = index == safeIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip(List<String> images) {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _currentImageIndex;
          return GestureDetector(
            onTap: () {
              _imagePageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
              );
            },
            child: Container(
              width: 74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.borderLight,
                  width: isSelected ? 2.2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageItem(images[index], width: 74, height: 62),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(String fullAddress) {
    final propertyName = (_post['propertyName'] ?? '').toString().trim();
    final roomLabel = (_post['room'] ?? '').toString().trim();
    final postId = (_post['id'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                (propertyName.isNotEmpty ? propertyName : 'NHÀ TRỌ TRỌ ƠI')
                    .toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            if (postId.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$postId',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          (_post['title'] ?? '').toString(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (roomLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.apartment_rounded,
                  size: 17, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  roomLabel,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (fullAddress.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fullAddress,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataRow() {
    final ownerName = (_post['ownerName'] ?? '').toString().trim();
    final dateStr = (_post['date'] ?? '').toString().trim();

    return Row(
      children: [
        Expanded(
          child: _MetadataChip(
            icon: Icons.calendar_today_rounded,
            label: 'Ngày đăng',
            value: dateStr.isNotEmpty ? dateStr : '--/--/----',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetadataChip(
            icon: Icons.person_outline_rounded,
            label: 'Người đăng',
            value: ownerName.isNotEmpty ? ownerName : 'Chủ trọ',
          ),
        ),
      ],
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: color, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo() {
    final area = _toDouble(_post['roomArea']) ?? 0;
    final maxPeople = _toInt(_post['roomMaxPeople']) ?? 0;
    final rawPrice = _toDouble(_post['rawPrice']) ?? 0;
    final priceDisplay = rawPrice > 0
        ? _formatCurrency(rawPrice)
        : ((_post['price'] ?? 'Thỏa thuận').toString());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickInfoItem(
              icon: Icons.payments_rounded,
              label: 'Giá thuê/tháng',
              value: priceDisplay,
              highlight: true,
            ),
          ),
          Container(width: 1, height: 46, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: _QuickInfoItem(
              icon: Icons.square_foot_rounded,
              label: 'Diện tích',
              value: area > 0 ? '${_formatArea(area)} m²' : 'Chưa cập nhật',
            ),
          ),
          Container(width: 1, height: 46, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: _QuickInfoItem(
              icon: Icons.people_alt_rounded,
              label: 'Số người',
              value: maxPeople > 0 ? '$maxPeople người' : 'Chưa cập nhật',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 19),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSurfaceCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRoomInfoCard() {
    final roomId = (_post['roomId'] ?? '').toString().trim();
    final propertyName = (_post['propertyName'] ?? '').toString().trim();
    final roomFloor = _toInt(_post['roomFloor']);
    final deposit = _toDouble(_post['roomDeposit']) ?? 0;
    final roomStatus = _post['roomStatus']?.toString();

    return _buildSurfaceCard(
      child: Column(
        children: [
          _DetailInfoRow(
            icon: Icons.badge_outlined,
            title: 'Mã phòng',
            value: roomId.isNotEmpty ? roomId : 'Chưa cập nhật',
          ),
          const Divider(height: 22),
          _DetailInfoRow(
            icon: Icons.home_work_outlined,
            title: 'Khu trọ',
            value: propertyName.isNotEmpty ? propertyName : 'Chưa cập nhật',
          ),
          const Divider(height: 22),
          _DetailInfoRow(
            icon: Icons.layers_outlined,
            title: 'Vị trí tầng',
            value: roomFloor != null ? 'Tầng $roomFloor' : 'Chưa cập nhật',
          ),
          const Divider(height: 22),
          _DetailInfoRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Tiền đặt cọc',
            value: deposit > 0 ? _formatCurrency(deposit) : 'Chưa cập nhật',
            valueColor: deposit > 0 ? AppColors.warningOrange : null,
          ),
          const Divider(height: 22),
          _DetailInfoRow(
            icon: Icons.domain_verification_outlined,
            title: 'Trạng thái phòng',
            value: _roomStatusLabel(roomStatus),
            valueColor: _roomStatusColor(roomStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    final amenities = _amenities;
    if (amenities.isEmpty) {
      return _buildSurfaceCard(
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chưa cập nhật tiện nghi cho bài đăng này.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: amenities.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_amenityIcon(item), size: 17, color: AppColors.primaryGreen),
              const SizedBox(width: 7),
              Text(
                item,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServicesSection() {
    final services = _services;
    if (services.isEmpty) {
      return _buildSurfaceCard(
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chưa cấu hình bảng giá dịch vụ đi kèm cho khu trọ này.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildSurfaceCard(
      child: Column(
        children: services.map((srv) {
          final name = (srv['name'] ?? 'Dịch vụ').toString();
          final price = _toInt(srv['price']) ?? 0;
          final unit = (srv['unit'] ?? 'tháng').toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_formatCurrency(price)} / $unit',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final postDesc = (_post['description'] ?? '').toString().trim();
    final roomDesc = (_post['roomDescription'] ?? '').toString().trim();

    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            postDesc.isNotEmpty
                ? postDesc
                : 'Chưa có mô tả chi tiết cho bài đăng này.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (roomDesc.isNotEmpty && roomDesc != postDesc) ...[
            const Divider(height: 24),
            const Text(
              'Ghi chú gốc của phòng',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              roomDesc,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection(String roomId) {
    final roomTitle = (_post['roomName'] ?? _post['title'] ?? 'Phòng trọ').toString();
    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.star_rounded,
                    color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đánh giá phòng',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Phản hồi từ khách thuê phòng này',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(
                  _isReviewLoading ? '...' : _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 21),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isReviewLoading
                        ? 'Đang tải đánh giá...'
                        : '• $_reviewCount đánh giá',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                Text(
                  _isReviewLoading ? '' : _getRatingLabel(_averageRating),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewsScreen(
                      room: {'id': roomId, 'title': roomTitle},
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text(
                'Xem tất cả đánh giá',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: BorderSide(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    String fullAddress,
    double? latitude,
    double? longitude,
  ) {
    return _buildSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: OpenStreetMapWidget(
              address: fullAddress,
              latitude: latitude,
              longitude: longitude,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Địa chỉ đầy đủ',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        fullAddress,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(20),
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

class _CircleHeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _QuickInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: highlight ? AppColors.primaryGreen : AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _DetailInfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
