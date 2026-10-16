import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/tenant/image_slider.dart';
import 'favorites_screen.dart';
import 'reviews_screen.dart';
import 'booking_screen.dart';
import '../../widgets/tenant/open_street_map_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomDetailScreen extends StatefulWidget {
  final Map<String, dynamic> room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic> get room => widget.room;

  String get roomTitle => room['title']?.toString() ?? 'Phòng trọ chưa có tên';

  String get propertyName =>
      room['propertyName']?.toString() ?? 'Khu trọ Trọ Ơi';

  String get district => room['district']?.toString() ?? '';

  String get ward => room['ward']?.toString() ?? '';

  String get address {
    final street = (room['street'] ?? '').toString().trim();
    final rawAddress = (room['address'] ?? room['fullAddress'] ?? '')
        .toString()
        .trim();

    final parts = <String>[
      if (street.isNotEmpty) street else if (rawAddress.isNotEmpty) rawAddress,
      if (ward.isNotEmpty) ward,
      if (district.isNotEmpty) district,
      'TP. Hồ Chí Minh',
      'Việt Nam',
    ];

    // Loại bỏ các phần địa chỉ bị trùng, không phân biệt chữ hoa/thường.
    final uniqueParts = <String>[];
    final seen = <String>{};

    for (final part in parts) {
      final normalized = part.toLowerCase().trim();
      if (normalized.isNotEmpty && seen.add(normalized)) {
        uniqueParts.add(part);
      }
    }

    return uniqueParts.join(', ');
  }

  int get price => (room['price'] as num?)?.toInt() ?? 0;

  int get area => (room['area'] as num?)?.toInt() ?? 0;

  int get maxPeople => (room['maxPeople'] as num?)?.toInt() ?? 1;

  String get status => room['status']?.toString() ?? 'available';

  List<String> get amenities {
    final data = room['amenities'];

    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }

    return [];
  }

  List<String> get images {
    final data = room['images'];

    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }

    final singleImage = room['image']?.toString();

    if (singleImage != null && singleImage.isNotEmpty) {
      return [singleImage];
    }

    return [];
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatPrice(int value) {
    if (value <= 0) {
      return 'Chưa cập nhật';
    }

    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return '${buffer.toString()}đ';
  }

  IconData _amenityIcon(String amenity) {
    final value = amenity.toLowerCase();

    if (value.contains('máy lạnh') || value.contains('điều hòa')) {
      return Icons.ac_unit_rounded;
    }

    if (value.contains('wifi')) {
      return Icons.wifi_rounded;
    }

    if (value.contains('tủ lạnh')) {
      return Icons.kitchen_rounded;
    }

    if (value.contains('máy giặt')) {
      return Icons.local_laundry_service_rounded;
    }

    if (value.contains('ban công')) {
      return Icons.balcony_rounded;
    }

    if (value.contains('camera')) {
      return Icons.videocam_rounded;
    }

    if (value.contains('wc') || value.contains('vệ sinh')) {
      return Icons.wc_rounded;
    }

    if (value.contains('xe') || value.contains('để xe')) {
      return Icons.two_wheeler_rounded;
    }

    if (value.contains('thang máy')) {
      return Icons.elevator_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1300),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavorite ? AppColors.accentYellow : Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              _isFavorite ? 'Đã thêm vào yêu thích' : 'Đã bỏ khỏi yêu thích',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _openReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewsScreen(room: room)),
    );
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHero(),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRoomHeader(),

                          const SizedBox(height: 20),

                          _buildQuickInfo(),

                          const SizedBox(height: 24),

                          _buildSectionTitle(
                            icon: Icons.home_work_rounded,
                            title: 'Thông tin phòng',
                          ),

                          const SizedBox(height: 12),

                          _buildRoomInfoCard(),

                          const SizedBox(height: 24),

                          _buildSectionTitle(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Tiện nghi',
                          ),

                          const SizedBox(height: 12),

                          _buildAmenities(),

                          const SizedBox(height: 24),

                          _buildSectionTitle(
                            icon: Icons.description_outlined,
                            title: 'Mô tả phòng',
                          ),

                          const SizedBox(height: 12),

                          _buildDescription(),

                          const SizedBox(height: 24),

                          _buildReviewsSection(),

                          const SizedBox(height: 24),

                          _buildLocationSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          _buildBottomAction(),
        ],
      ),
    );
  }

  Future<void> _openGoogleMapsFallback() async {
    final fullAddress = (room['address'] ?? room['fullAddress'] ?? address)
        .toString()
        .trim();

    if (fullAddress.isEmpty) {
      _showComingSoon('Phòng chưa có thông tin địa chỉ.');
      return;
    }

    final destination = '$fullAddress, Việt Nam';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showComingSoon('Không thể mở Google Maps lúc này.');
      }
    } catch (_) {
      if (mounted) {
        _showComingSoon('Không thể mở Google Maps lúc này.');
      }
    }
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero() {
    return SliverAppBar(
      expandedHeight: 310,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryGreen,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: _CircleActionButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: _CircleActionButton(
            icon: _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: _isFavorite ? AppColors.accentYellow : Colors.white,
            onTap: _toggleFavorite,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ImageSlider(
              images: images,
              onFavoritePressed: _toggleFavorite,
              isFavorite: _isFavorite,
            ),

            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryGreen.withOpacity(0.22),
                      Colors.transparent,
                      AppColors.primaryGreen.withOpacity(0.40),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 20,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: status == 'available'
                            ? Colors.green
                            : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      status == 'available'
                          ? 'Đang còn phòng'
                          : 'Đang được cập nhật',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ROOM HEADER
  // ============================================================

  Widget _buildRoomHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          propertyName.toUpperCase(),
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          roomTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 25,
            height: 1.22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: AppColors.primaryGreen,
              size: 20,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // QUICK INFO
  // ============================================================

  Widget _buildQuickInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickInfoItem(
              icon: Icons.payments_rounded,
              label: 'Giá thuê',
              value: _formatPrice(price),
              highlight: true,
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _QuickInfoItem(
              icon: Icons.square_foot_rounded,
              label: 'Diện tích',
              value: '$area m²',
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _QuickInfoItem(
              icon: Icons.people_alt_rounded,
              label: 'Số người',
              value: '$maxPeople người',
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 48, color: const Color(0xFFE5E7EB));
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 20),
        ),
        const SizedBox(width: 11),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ROOM INFORMATION
  // ============================================================

  Widget _buildRoomInfoCard() {
    return _HoverCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge_outlined,
            title: 'Mã phòng',
            value: room['id']?.toString() ?? 'Chưa cập nhật',
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.home_work_outlined,
            title: 'Khu trọ',
            value: propertyName,
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.people_outline_rounded,
            title: 'Số người tối đa',
            value: '$maxPeople người',
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Tiền cọc',
            value: _formatPrice((room['deposit'] as num?)?.toInt() ?? price),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AMENITIES
  // ============================================================

  Widget _buildAmenities() {
    if (amenities.isEmpty) {
      return _HoverCard(
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 10),
            Text(
              'Chưa có thông tin tiện nghi',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: amenities.map((amenity) {
        return _AmenityChip(label: amenity, icon: _amenityIcon(amenity));
      }).toList(),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescription() {
    final rawDescription = room['description']?.toString().trim();

    final description = rawDescription != null && rawDescription.isNotEmpty
        ? rawDescription
        : 'Phòng được thiết kế phù hợp cho sinh viên và người đi làm, '
              'không gian thoải mái, tiện nghi và thuận tiện cho sinh hoạt '
              'hằng ngày.';

    return _HoverCard(
      child: Text(
        description,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.7,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  Widget _buildReviewsSection() {
    return _HoverCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.primaryGreen,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đánh giá phòng',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Xem trải nghiệm từ những người thuê trước',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withOpacity(.55),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Text(
                  '4.5',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.star_rounded,
                  color: AppColors.accentYellow,
                  size: 22,
                ),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '• 12 đánh giá',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Rất tốt',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: _openReviews,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: BorderSide(
                  color: AppColors.primaryGreen.withOpacity(.25),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Xem tất cả đánh giá',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.location_on_rounded,
          title: 'Vị trí phòng',
        ),
        const SizedBox(height: 12),
        _buildLocationCard(),
      ],
    );
  }

  Widget _buildLocationCard() {
    final fullSearchAddress = address;

    debugPrint('DỮ LIỆU PHÒNG: $room');
    debugPrint('ĐỊA CHỈ HIỂN THỊ: $address');
    debugPrint('ĐỊA CHỈ GỬI BẢN ĐỒ: $fullSearchAddress');

    return _HoverCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Gọi widget bản đồ tách riêng
          Padding(
            padding: const EdgeInsets.all(16),
            child: OpenStreetMapWidget(
              address: address,
              latitude: double.tryParse(room['latitude']?.toString() ?? ''),
              longitude: double.tryParse(room['longitude']?.toString() ?? ''),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // 2. Phần hiển thị chữ địa chỉ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Địa chỉ',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
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

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

  Widget _buildBottomAction() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface.withOpacity(0.96),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 25,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 150,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    backgroundColor: AppColors.lightGreen,
                    side: BorderSide(
                      color: AppColors.primaryGreen.withOpacity(0.18),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 20,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Xem yêu thích',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _PrimaryHoverButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const booking_screen()),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Đặt lịch xem phòng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUPPORTING WIDGETS
// ============================================================

class _CircleActionButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    this.iconColor = Colors.white,
    required this.onTap,
  });

  @override
  State<_CircleActionButton> createState() => _CircleActionButtonState();
}

class _CircleActionButtonState extends State<_CircleActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withOpacity(0.30)
                : Colors.black.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: AnimatedScale(
            scale: _hovered ? 1.12 : 1,
            duration: const Duration(milliseconds: 180),
            child: Icon(widget.icon, color: widget.iconColor, size: 21),
          ),
        ),
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
        Icon(icon, size: 21, color: AppColors.primaryGreen),
        const SizedBox(height: 7),
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
          style: TextStyle(
            color: highlight ? AppColors.primaryGreen : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 19),
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
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _HoverCard({
    required this.child,
    this.padding = const EdgeInsets.all(17),
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? AppColors.primaryGreen.withOpacity(0.18)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(_hovered ? 0.12 : 0.05),
              blurRadius: _hovered ? 28 : 16,
              offset: Offset(0, _hovered ? 12 : 6),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _AmenityChip extends StatefulWidget {
  final String label;
  final IconData icon;

  const _AmenityChip({required this.label, required this.icon});

  @override
  State<_AmenityChip> createState() => _AmenityChipState();
}

class _AmenityChipState extends State<_AmenityChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.primaryGreen : AppColors.lightGreen,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? AppColors.primaryGreen
                : AppColors.primaryGreen.withOpacity(0.08),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 17,
              color: _hovered ? Colors.white : AppColors.primaryGreen,
            ),
            const SizedBox(width: 7),
            Text(
              widget.label,
              style: TextStyle(
                color: _hovered ? Colors.white : AppColors.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryHoverButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PrimaryHoverButton({required this.onTap, required this.child});

  @override
  State<_PrimaryHoverButton> createState() => _PrimaryHoverButtonState();
}

class _PrimaryHoverButtonState extends State<_PrimaryHoverButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed
              ? 0.97
              : _hovered
              ? 1.015
              : 1,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 54,
            decoration: BoxDecoration(
              color: _hovered
                  ? const Color(0xFF00745E)
                  : AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(
                    _hovered ? 0.32 : 0.20,
                  ),
                  blurRadius: _hovered ? 20 : 12,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
