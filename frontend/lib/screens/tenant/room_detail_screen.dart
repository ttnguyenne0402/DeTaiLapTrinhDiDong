import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/tenant/image_slider.dart';
import 'favorites_screen.dart';
import 'reviews_screen.dart';
import 'booking_screen.dart';

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
    final parts = <String>[
      if (ward.isNotEmpty) ward,
      if (district.isNotEmpty) district,
      'TP. Hồ Chí Minh',
    ];

    return parts.join(', ');
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
    return _HoverCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 230,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: _FakeMap(address: address),
            ),
          ),

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

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 17),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  _showComingSoon(
                    'Chức năng mở Google Maps sẽ được bổ sung sau.',
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: AppColors.primaryGreen,
                        size: 19,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Mở bằng Google Maps',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

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
              // =================================================
              // XEM DANH SÁCH YÊU THÍCH
              // =================================================
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

              // =================================================
              // ĐẶT LỊCH XEM PHÒNG
              // =================================================
              Expanded(
                child: _PrimaryHoverButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const booking_screen(),
                      ),
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
// CIRCLE ACTION BUTTON
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
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
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

// ============================================================
// QUICK INFO ITEM
// ============================================================

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

// ============================================================
// INFO ROW
// ============================================================

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

// ============================================================
// FAKE MAP
// ============================================================

class _FakeMap extends StatefulWidget {
  final String address;

  const _FakeMap({required this.address});

  @override
  State<_FakeMap> createState() => _FakeMapState();
}

class _FakeMapState extends State<_FakeMap> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: AnimatedScale(
        scale: _hovered ? 1.015 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _FakeMapPainter())),

            const Positioned(
              left: 24,
              top: 30,
              child: _MapStreetLabel(text: 'NGUYỄN VĂN QUÁ', angle: -0.04),
            ),

            const Positioned(
              right: 30,
              top: 78,
              child: _MapStreetLabel(text: 'QUANG TRUNG', angle: 1.52),
            ),

            const Positioned(
              left: 100,
              bottom: 34,
              child: _MapStreetLabel(text: 'TÂN SƠN NHÌ', angle: -0.02),
            ),

            const Positioned(
              right: 22,
              bottom: 28,
              child: _MapStreetLabel(text: 'LÊ VĂN KHƯƠNG', angle: 0.02),
            ),

            Positioned(
              left: 22,
              top: 72,
              child: _MapBuilding(width: 65, height: 43),
            ),

            Positioned(
              right: 34,
              top: 22,
              child: _MapBuilding(width: 70, height: 45),
            ),

            Positioned(
              left: 36,
              bottom: 28,
              child: _MapBuilding(width: 58, height: 42),
            ),

            Positioned(
              right: 25,
              bottom: 62,
              child: _MapBuilding(width: 75, height: 46),
            ),

            Positioned(
              left: 125,
              top: 26,
              child: Container(
                width: 74,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFE5C7),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFB9D5AF)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.park_rounded,
                    color: Color(0xFF6B9B63),
                    size: 25,
                  ),
                ),
              ),
            ),

            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 850),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -18 * (1 - value)),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home_work_rounded,
                            color: AppColors.primaryGreen,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Phòng trọ',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.35),
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 12,
              top: 12,
              child: Column(
                children: [
                  _MapControlButton(icon: Icons.add_rounded, onTap: () {}),
                  const SizedBox(height: 6),
                  _MapControlButton(icon: Icons.remove_rounded, onTap: () {}),
                ],
              ),
            ),

            Positioned(
              right: 12,
              bottom: 12,
              child: _MapControlButton(
                icon: Icons.my_location_rounded,
                onTap: () {},
              ),
            ),

            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Text(
                  'Trọ Ơi Map',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAP STREET LABEL
// ============================================================

class _MapStreetLabel extends StatelessWidget {
  final String text;
  final double angle;

  const _MapStreetLabel({required this.text, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF718071),
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================================
// MAP BUILDING
// ============================================================

class _MapBuilding extends StatelessWidget {
  final double width;
  final double height;

  const _MapBuilding({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E1D7),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD2CDC0)),
      ),
      child: Center(
        child: Wrap(
          spacing: 5,
          runSpacing: 4,
          children: List.generate(
            6,
            (index) => Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFB9B4A7),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MAP CONTROL
// ============================================================

class _MapControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.onTap});

  @override
  State<_MapControlButton> createState() => _MapControlButtonState();
}

class _MapControlButtonState extends State<_MapControlButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primaryGreen
                : Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: 19,
            color: _hovered ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MAP PAINTER
// ============================================================

class _FakeMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFFF1F0E8);

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final greenPaint = Paint()..color = const Color(0xFFDDEBD5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-20, size.height * 0.58, 115, 85),
        const Radius.circular(22),
      ),
      greenPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 105, size.height * 0.30, 130, 95),
        const Radius.circular(22),
      ),
      greenPaint,
    );

    final smallRoad = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    final road1 = Path()
      ..moveTo(-20, size.height * 0.46)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.40,
        size.width * 0.65,
        size.height * 0.53,
        size.width + 20,
        size.height * 0.44,
      );

    canvas.drawPath(road1, smallRoad);

    final road2 = Path()
      ..moveTo(size.width * 0.72, -20)
      ..cubicTo(
        size.width * 0.67,
        size.height * 0.25,
        size.width * 0.47,
        size.height * 0.62,
        size.width * 0.35,
        size.height + 20,
      );

    canvas.drawPath(road2, smallRoad);

    final mainRoad = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 27
      ..strokeCap = StrokeCap.round;

    final mainRoadPath = Path()
      ..moveTo(-20, size.height * 0.78)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.69,
        size.width * 0.62,
        size.height * 0.83,
        size.width + 20,
        size.height * 0.68,
      );

    canvas.drawPath(mainRoadPath, mainRoad);

    final edgePaint = Paint()
      ..color = const Color(0xFFE0DED4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(road1, edgePaint);

    canvas.drawPath(road2, edgePaint);

    canvas.drawPath(mainRoadPath, edgePaint);

    final centerPaint = Paint()
      ..color = const Color(0xFFD8D3A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawDashedPath(canvas, mainRoadPath, centerPaint);

    final thinRoad = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final paths = [
      Path()
        ..moveTo(-10, size.height * 0.17)
        ..lineTo(size.width + 10, size.height * 0.25),
      Path()
        ..moveTo(-10, size.height * 0.61)
        ..lineTo(size.width + 10, size.height * 0.56),
      Path()
        ..moveTo(size.width * 0.15, -10)
        ..lineTo(size.width * 0.22, size.height + 10),
      Path()
        ..moveTo(size.width * 0.88, -10)
        ..lineTo(size.width * 0.77, size.height + 10),
    ];

    for (final path in paths) {
      canvas.drawPath(path, thinRoad);
    }

    final waterPaint = Paint()..color = const Color(0xFFD6E9EA);

    final waterPath = Path()
      ..moveTo(size.width * 0.72, size.height)
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.82,
        size.width * 0.92,
        size.height * 0.76,
        size.width,
        size.height * 0.80,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(waterPath, waterPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;

      while (distance < metric.length) {
        final next = distance + 9;

        final segment = metric.extractPath(
          distance,
          next.clamp(0, metric.length),
        );

        canvas.drawPath(segment, paint);

        distance += 18;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// HOVER CARD
// ============================================================

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
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
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

// ============================================================
// AMENITY CHIP
// ============================================================

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
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
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

// ============================================================
// PRIMARY BUTTON
// ============================================================

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
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _pressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _pressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _pressed = false;
          });
        },
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
