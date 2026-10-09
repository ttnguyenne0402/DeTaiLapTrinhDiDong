import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/tenant/room_card.dart';
import 'search_filter_screen.dart';
import 'room_detail_screen.dart';



import 'booking_history_screen.dart';
import 'favorites_screen.dart';
import 'my_invoices_screen.dart';
import 'notifications_screen.dart';
import 'my_contracts_screen.dart';
import 'profile_screen.dart'; // Đảm bảo bạn đã có file này

// ============================================================
// KHUNG CHỨA THANH ĐIỀU HƯỚNG CỐ ĐỊNH
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình tương ứng với từng Tab
  final List<Widget> _screens = [
    const _HomeContent(),         // 0: Nội dung trang chủ gốc
    const MyInvoicesScreen(),     // 1: Hóa đơn
    const booking_history_screen(),       // 2: Đặt lịch
    const MyContractsScreen(),    // 3: Hợp đồng
    const FavoritesScreen(),      // 4: Yêu thích
    const ProfileScreen(),        // 5: Cá nhân
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _selectedIndex == index;
    final color = selected ? AppColors.primaryGreen : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(14),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Dùng IndexedStack để chuyển tab mà không cần dùng Router
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: BottomAppBar(
            color: const Color(0xFFF4EEF5),
            elevation: 12,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                _buildBottomNavItem(icon: Icons.home_rounded, label: 'Trang chủ', index: 0),
                _buildBottomNavItem(icon: Icons.receipt_long_rounded, label: 'Hóa đơn', index: 1),
                _buildBottomNavItem(icon: Icons.event_note_rounded, label: 'Đặt lịch', index: 2),
                _buildBottomNavItem(icon: Icons.description_outlined, label: 'Hợp đồng', index: 3),
                _buildBottomNavItem(icon: Icons.favorite_border_rounded, label: 'Yêu thích', index: 4),
                _buildBottomNavItem(icon: Icons.person_outline_rounded, label: 'Cá nhân', index: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NỘI DUNG TRANG CHỦ GỐC
// ============================================================
class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final Set<String> _selectedQuickFilters = {};

  final List<Map<String, dynamic>> _allRooms = [
    {
      'id': 'ROOM001',
      'propertyId': 'PROP001',
      'propertyName': 'Khu trọ Nguyễn Văn Quá',
      'title': 'Phòng đầy đủ nội thất gần Đại học Công Thương',
      'district': 'Quận 12',
      'ward': 'Đông Hưng Thuận',
      'area': 22,
      'price': 2800000,
      'deposit': 2800000,
      'maxPeople': 2,
      'status': 'available',
      'amenities': ['Máy lạnh', 'Wifi', 'Tủ lạnh', 'WC riêng'],
      'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': 'ROOM002',
      'propertyId': 'PROP002',
      'propertyName': 'An Phú Residence',
      'title': 'Căn hộ mini cao cấp, ban công thoáng',
      'district': 'TP. Thủ Đức',
      'ward': 'An Phú',
      'area': 35,
      'price': 6800000,
      'deposit': 6800000,
      'maxPeople': 3,
      'status': 'available',
      'amenities': ['Máy lạnh', 'Ban công', 'Thang máy', 'Wifi'],
      'image': 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': 'ROOM003',
      'propertyId': 'PROP003',
      'propertyName': 'Khu trọ Tân Phú',
      'title': 'Phòng mới xây, an ninh tốt, giờ giấc tự do',
      'district': 'Tân Phú',
      'ward': 'Tân Sơn Nhì',
      'area': 24,
      'price': 3200000,
      'deposit': 3200000,
      'maxPeople': 2,
      'status': 'available',
      'amenities': ['Wifi', 'Camera', 'WC riêng', 'Chỗ để xe'],
      'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': 'ROOM004',
      'propertyId': 'PROP004',
      'propertyName': 'Saigon Green House',
      'title': 'Phòng rộng, gần chợ và tuyến Metro',
      'district': 'Bình Thạnh',
      'ward': 'Phường 25',
      'area': 28,
      'price': 4500000,
      'deposit': 4500000,
      'maxPeople': 2,
      'status': 'available',
      'amenities': ['Máy lạnh', 'Wifi', 'Máy giặt', 'Camera'],
      'image': 'https://images.unsplash.com/photo-1560185008-b033106af5c3?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  List<Map<String, dynamic>> rooms = [];

  @override
  void initState() {
    super.initState();
    rooms = List<Map<String, dynamic>>.from(_allRooms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _removeVietnameseDiacritics(String value) {
    const replacements = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a', 'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o', 'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u', 'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'đ': 'd',
    };
    String result = value.toLowerCase();
    replacements.forEach((key, replacement) {
      result = result.replaceAll(key, replacement);
    });
    return result;
  }

  String _normalize(String value) {
    return _removeVietnameseDiacritics(value.trim().toLowerCase());
  }

  List<Map<String, dynamic>> _applyKeyword(List<Map<String, dynamic>> source) {
    final keyword = _normalize(_searchController.text);
    if (keyword.isEmpty) return source;
    return source.where((room) {
      final title = _normalize(room['title']?.toString() ?? '');
      final propertyName = _normalize(room['propertyName']?.toString() ?? '');
      final district = _normalize(room['district']?.toString() ?? '');
      final ward = _normalize(room['ward']?.toString() ?? '');
      return title.contains(keyword) || propertyName.contains(keyword) || district.contains(keyword) || ward.contains(keyword);
    }).toList();
  }

  List<Map<String, dynamic>> _applyQuickFilters(List<Map<String, dynamic>> source) {
    List<Map<String, dynamic>> result = source;
    if (_selectedQuickFilters.contains('price')) {
      result = result.where((room) {
        final price = (room['price'] as num?)?.toDouble() ?? 0;
        return price <= 3500000;
      }).toList();
    }
    if (_selectedQuickFilters.contains('school')) {
      result = result.where((room) {
        final title = _normalize(room['title']?.toString() ?? '');
        return title.contains('dai hoc') || title.contains('truong') || title.contains('gan');
      }).toList();
    }
    if (_selectedQuickFilters.contains('furniture')) {
      result = result.where((room) {
        final amenities = List<String>.from(room['amenities'] ?? const <String>[]);
        return amenities.contains('Máy lạnh') || amenities.contains('Tủ lạnh') || amenities.contains('Máy giặt') || amenities.contains('Ban công');
      }).toList();
    }
    if (_selectedQuickFilters.contains('new')) {
      result = result.where((room) {
        final title = _normalize(room['title']?.toString() ?? '');
        return title.contains('moi') || title.contains('xay');
      }).toList();
    }
    return result;
  }

  void _searchFromHome() {
    List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(_allRooms);
    result = _applyKeyword(result);
    result = _applyQuickFilters(result);
    final hasSearch = _searchController.text.trim().isNotEmpty || _selectedQuickFilters.isNotEmpty;
    setState(() {
      rooms = result;
      _isSearching = hasSearch;
    });
    FocusScope.of(context).unfocus();
  }

  void _toggleQuickFilter(String filter) {
    if (_selectedQuickFilters.contains(filter)) {
      _selectedQuickFilters.remove(filter);
    } else {
      _selectedQuickFilters.add(filter);
    }
    _searchFromHome();
  }

  Future<void> _openFilterScreen() async {
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchFilterScreen(
          rooms: _allRooms,
          initialKeyword: _searchController.text,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      rooms = result;
      _selectedQuickFilters.clear();
      _isSearching = true;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _selectedQuickFilters.clear();
      rooms = List<Map<String, dynamic>>.from(_allRooms);
      _isSearching = false;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchBar(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _buildQuickFilters(),
            ),
          ),
          if (_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _buildSearchStatus(),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: _buildSectionTitle(),
            ),
          ),
          if (rooms.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final room = rooms[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RoomCard(
                      room: room,
                      onTap: () {
                        // Vẫn dùng Router để chuyển sang Chi tiết phòng đè lên toàn bộ màn hình
                        Navigator.pushNamed(context, '/room-detail', arguments: room);
                      },
                      onFavorite: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.accentYellow,
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Đã thêm phòng vào yêu thích',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }, childCount: rooms.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 265,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF005D4B), Color(0xFF157762), Color(0xFF2D8D73)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(42),
                bottomRight: Radius.circular(42),
              ),
            ),
          ),
          Positioned(
            right: -35,
            top: -35,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: 10,
            child: Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                _buildLogo(),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/tenant/notifications');
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 21,
            top: 88,
            right: 155,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào 👋',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 5),
                Text(
                  'Tìm phòng dễ dàng,\nsống thoải mái hơn.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
          Positioned(right: 15, bottom: -1, child: _buildHouseIllustration()),
          Positioned(
            left: 21,
            bottom: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: AppColors.accentYellow,
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Tìm trọ tại TP.HCM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.home_work_rounded,
          color: Colors.white,
          size: 29,
          shadows: [Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
        ),
        SizedBox(width: 9),
        Text(
          'TRỌ ƠI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
            shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3))],
          ),
        ),
      ],
    );
  }

  Widget _buildHouseIllustration() {
    return SizedBox(
      width: 140,
      height: 125,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 125,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF7EFE0),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          Positioned(
            top: 14,
            child: CustomPaint(
              size: const Size(105, 70),
              painter: _HomeHousePainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.11),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLines: 1,
                      onSubmitted: (_) {
                        _searchFromHome();
                      },
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Tìm quận, khu vực, tên phòng...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _searchFromHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Tìm',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Material(
            color: AppColors.accentYellow,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _openFilterScreen,
              child: const SizedBox(
                width: 50,
                height: 50,
                child: Icon(
                  Icons.tune_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = [
      {'key': 'price', 'title': 'Giá tốt', 'subtitle': '≤ 3.5 triệu', 'icon': Icons.local_offer_outlined, 'color': const Color(0xFFE7A900)},
      {'key': 'school', 'title': 'Gần trường', 'subtitle': 'Tiện đi học', 'icon': Icons.school_outlined, 'color': const Color(0xFF356D9E)},
      {'key': 'furniture', 'title': 'Có nội thất', 'subtitle': 'Dọn vào ngay', 'icon': Icons.weekend_outlined, 'color': const Color(0xFF8059A9)},
      {'key': 'new', 'title': 'Phòng mới', 'subtitle': 'Mới xây', 'icon': Icons.auto_awesome_outlined, 'color': const Color(0xFF27856F)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tìm nhanh',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_selectedQuickFilters.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: const Text(
                  'Bỏ chọn',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Chạm vào thẻ để tìm nhanh',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 11),
            itemBuilder: (context, index) {
              final item = filters[index];
              final key = item['key'] as String;
              final selected = _selectedQuickFilters.contains(key);
              final color = item['color'] as Color;

              return GestureDetector(
                onTap: () {
                  _toggleQuickFilter(key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 150,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryGreen : AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? AppColors.primaryGreen : const Color(0xFFE5E7EB),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(selected ? 0.08 : 0.025),
                        blurRadius: selected ? 12 : 7,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selected ? Colors.white.withOpacity(0.14) : color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: selected ? Colors.white : color,
                              size: 19,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 21,
                            height: 21,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? AppColors.accentYellow : Colors.transparent,
                              border: Border.all(
                                color: selected ? AppColors.accentYellow : const Color(0xFFD1D5DB),
                                width: 1.5,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.textPrimary,
                            )
                                : null,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'] as String,
                        style: TextStyle(
                          color: selected ? Colors.white70 : AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchStatus() {
    final keyword = _searchController.text.trim();
    final String text = keyword.isNotEmpty ? '${rooms.length} phòng cho "$keyword"' : '${rooms.length} phòng phù hợp';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.filter_alt_outlined,
              color: AppColors.primaryGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text(
                'Xóa',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _isSearching ? 'Kết quả tìm kiếm' : 'Phòng nổi bật',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (!_isSearching)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${rooms.length} phòng',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.primaryGreen,
              size: 35,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy phòng',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy thử đổi từ khóa hoặc dùng bộ lọc nâng cao.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: _clearSearch,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Xóa tìm kiếm',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _openFilterScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mở bộ lọc',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeHousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roofPaint = Paint()..color = const Color(0xFFD49A55);
    final wallPaint = Paint()..color = const Color(0xFF2E6E5F);
    final windowPaint = Paint()..color = const Color(0xFFFFE7A4);
    final doorPaint = Paint()..color = const Color(0xFF1E4D45);

    final roof = Path()
      ..moveTo(size.width * 0.10, size.height * 0.43)
      ..lineTo(size.width * 0.50, size.height * 0.07)
      ..lineTo(size.width * 0.90, size.height * 0.43)
      ..close();
    canvas.drawPath(roof, roofPaint);

    final body = Rect.fromLTWH(
      size.width * 0.17,
      size.height * 0.38,
      size.width * 0.66,
      size.height * 0.48,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(4)),
      wallPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.28, size.height * 0.51, size.width * 0.17, size.height * 0.17),
        const Radius.circular(2),
      ),
      windowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.51, size.width * 0.17, size.height * 0.17),
        const Radius.circular(2),
      ),
      windowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.41, size.height * 0.68, size.width * 0.18, size.height * 0.18),
        const Radius.circular(2),
      ),
      doorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}