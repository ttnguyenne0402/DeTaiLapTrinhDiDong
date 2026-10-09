import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'room_detail_screen.dart';
import 'home_screen.dart';
import 'booking_screen.dart';
import 'my_invoices_screen.dart';
import 'my_contracts_screen.dart';
import 'profile_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // =========================
  // BỘ LỌC
  // =========================
  String _selectedPriceFilter = 'Tất cả';
  String _selectedFeatureFilter = 'Tất cả';

  // =========================
  // SẮP XẾP
  // =========================
  String _selectedSort = 'Mới lưu';

  final List<String> _sorts = ['Mới lưu', 'Giá thấp', 'Giá cao', 'Diện tích'];

  // =========================
  // DỮ LIỆU PHÒNG YÊU THÍCH
  // =========================
  final List<Map<String, dynamic>> _favorites = [
    {
      'id': 'ROOM001',
      'propertyName': 'Khu trọ Nguyễn Văn Quá',
      'title': 'Phòng đầy đủ nội thất gần Đại học Công Thương',
      'district': 'Quận 12',
      'ward': 'Đông Hưng Thuận',
      'area': 22,
      'price': 2800000,
      'maxPeople': 2,
      'isNew': true,
      'nearSchool': true,
      'goodPrice': true,
      'amenities': ['Máy lạnh', 'Wifi', 'Tủ lạnh', 'WC riêng'],
      'image':
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': 'ROOM003',
      'propertyName': 'Khu trọ Tân Phú',
      'title': 'Phòng mới xây, an ninh tốt, giờ giấc tự do',
      'district': 'Tân Phú',
      'ward': 'Tân Sơn Nhì',
      'area': 24,
      'price': 3200000,
      'maxPeople': 2,
      'isNew': true,
      'nearSchool': false,
      'goodPrice': true,
      'amenities': ['Wifi', 'Camera', 'WC riêng', 'Chỗ để xe'],
      'image':
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'id': 'ROOM004',
      'propertyName': 'Saigon Green House',
      'title': 'Phòng rộng, gần chợ và tuyến Metro',
      'district': 'Bình Thạnh',
      'ward': 'Phường 25',
      'area': 28,
      'price': 4500000,
      'maxPeople': 2,
      'isNew': false,
      'nearSchool': true,
      'goodPrice': false,
      'amenities': ['Máy lạnh', 'Wifi', 'Máy giặt', 'Camera'],
      'image':
          'https://images.unsplash.com/photo-1560185008-b033106af5c3?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // LỌC + SẮP XẾP
  // ============================================================

  List<Map<String, dynamic>> get _filteredFavorites {
    List<Map<String, dynamic>> result = List.from(_favorites);

    // ----------------------------------------------------------
    // LỌC THEO GIÁ
    // ----------------------------------------------------------

    if (_selectedPriceFilter == 'Dưới 3 triệu') {
      result = result.where((room) {
        return (room['price'] as int) < 3000000;
      }).toList();
    }

    if (_selectedPriceFilter == '3 - 4 triệu') {
      result = result.where((room) {
        final price = room['price'] as int;

        return price >= 3000000 && price <= 4000000;
      }).toList();
    }

    if (_selectedPriceFilter == '4 - 5 triệu') {
      result = result.where((room) {
        final price = room['price'] as int;

        return price > 4000000 && price <= 5000000;
      }).toList();
    }

    if (_selectedPriceFilter == 'Trên 5 triệu') {
      result = result.where((room) {
        return (room['price'] as int) > 5000000;
      }).toList();
    }

    // ----------------------------------------------------------
    // LỌC THEO ĐẶC ĐIỂM
    // ----------------------------------------------------------

    if (_selectedFeatureFilter == 'Giá tốt') {
      result = result.where((room) {
        return room['goodPrice'] == true;
      }).toList();
    }

    if (_selectedFeatureFilter == 'Gần trường') {
      result = result.where((room) {
        return room['nearSchool'] == true;
      }).toList();
    }

    if (_selectedFeatureFilter == 'Có nội thất') {
      result = result.where((room) {
        final amenities = List<String>.from(room['amenities']);

        return amenities.any(
          (item) =>
              item == 'Máy lạnh' || item == 'Tủ lạnh' || item == 'Máy giặt',
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // SẮP XẾP
    // ----------------------------------------------------------

    if (_selectedSort == 'Giá thấp') {
      result.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
    }

    if (_selectedSort == 'Giá cao') {
      result.sort((a, b) => (b['price'] as int).compareTo(a['price'] as int));
    }

    if (_selectedSort == 'Diện tích') {
      result.sort((a, b) => (b['area'] as int).compareTo(a['area'] as int));
    }

    return result;
  }

  // ============================================================
  // FORMAT GIÁ
  // ============================================================

  String _formatPrice(int price) {
    final value = price ~/ 100000;
    final million = value ~/ 10;
    final hundred = value % 10;

    if (hundred == 0) {
      return '$million triệu';
    }

    return '$million.$hundred triệu';
  }

  // ============================================================
  // BỎ YÊU THÍCH
  // ============================================================

  void _removeFavorite(Map<String, dynamic> room) {
    setState(() {
      _favorites.remove(room);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: const Text(
          'Đã bỏ phòng khỏi danh sách yêu thích',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ============================================================
  // MỞ CHI TIẾT PHÒNG
  // ============================================================

  void _openRoom(Map<String, dynamic> room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomDetailScreen(room: room)),
    );
  }

  // ============================================================
  // ĐIỀU HƯỚNG
  // ============================================================

  void _openScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    }
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final color = selected ? AppColors.primaryGreen : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
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


  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final rooms = _filteredFavorites;

    return Scaffold(
      backgroundColor: AppColors.background,



      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ======================================================
          // HEADER
          // ======================================================
          SliverAppBar(
            expandedHeight: 245,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,


            flexibleSpace: FlexibleSpaceBar(
              background: _FavoriteHeader(total: _favorites.length),
            ),
            title: const Text(
              'Yêu thích',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),

          // ======================================================
          // SUMMARY
          // ======================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: _buildSummary(),
            ),
          ),

          // ======================================================
          // SỐ LƯỢNG + NÚT LỌC + SẮP XẾP
          // ======================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Row(
                children: [
                  Text(
                    '${rooms.length} phòng',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  _ActionButton(
                    icon: Icons.tune_rounded,
                    label: 'Lọc',
                    onTap: _showFilterBottomSheet,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.swap_vert_rounded,
                    label: 'Sắp xếp',
                    onTap: _showSortBottomSheet,
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // DANH SÁCH PHÒNG
          // ======================================================
          if (rooms.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final room = rooms[index];

                  final animation = CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index * 0.12).clamp(0.0, 0.7),
                      0.75 + (index * 0.08).clamp(0.0, 0.2),
                      curve: Curves.easeOutCubic,
                    ),
                  );

                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: animation.value,
                        child: Transform.translate(
                          offset: Offset(0, 25 * (1 - animation.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _FavoriteRoomCard(
                        room: room,
                        priceText: _formatPrice(room['price']),
                        onTap: () => _openRoom(room),
                        onRemove: () => _removeFavorite(room),
                      ),
                    ),
                  );
                }, childCount: rooms.length),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final goodPriceCount = _favorites
        .where((room) => room['goodPrice'] == true)
        .length;

    final newCount = _favorites.where((room) => room['isNew'] == true).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryBox(
            icon: Icons.favorite_rounded,
            value: '${_favorites.length}',
            label: 'Đã lưu',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryBox(
            icon: Icons.local_offer_rounded,
            value: '$goodPriceCount',
            label: 'Giá tốt',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryBox(
            icon: Icons.auto_awesome_rounded,
            value: '$newCount',
            label: 'Phòng mới',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 55,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Không tìm thấy phòng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Không có phòng yêu thích nào phù hợp với điều kiện lọc hiện tại.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedPriceFilter = 'Tất cả';
                  _selectedFeatureFilter = 'Tất cả';
                  _selectedSort = 'Mới lưu';
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Xóa bộ lọc',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET - LỌC
  // ============================================================

  void _showFilterBottomSheet() {
    String tempPriceFilter = _selectedPriceFilter;
    String tempFeatureFilter = _selectedFeatureFilter;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh kéo
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Lọc phòng',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Chọn điều kiện phù hợp với nhu cầu của bạn.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ------------------------------------------------
                      // GIÁ
                      // ------------------------------------------------
                      const Text(
                        'Khoảng giá',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _FilterOption(
                        icon: Icons.apps_rounded,
                        title: 'Tất cả mức giá',
                        selected: tempPriceFilter == 'Tất cả',
                        onTap: () {
                          setModalState(() {
                            tempPriceFilter = 'Tất cả';
                          });
                        },
                      ),

                      _FilterOption(
                        icon: Icons.savings_rounded,
                        title: 'Dưới 3 triệu',
                        selected: tempPriceFilter == 'Dưới 3 triệu',
                        onTap: () {
                          setModalState(() {
                            tempPriceFilter = 'Dưới 3 triệu';
                          });
                        },
                      ),

                      _FilterOption(
                        icon: Icons.price_change_rounded,
                        title: '3 - 4 triệu',
                        selected: tempPriceFilter == '3 - 4 triệu',
                        onTap: () {
                          setModalState(() {
                            tempPriceFilter = '3 - 4 triệu';
                          });
                        },
                      ),

                      _FilterOption(
                        icon: Icons.account_balance_wallet_rounded,
                        title: '4 - 5 triệu',
                        selected: tempPriceFilter == '4 - 5 triệu',
                        onTap: () {
                          setModalState(() {
                            tempPriceFilter = '4 - 5 triệu';
                          });
                        },
                      ),

                      _FilterOption(
                        icon: Icons.currency_exchange_rounded,
                        title: 'Trên 5 triệu',
                        selected: tempPriceFilter == 'Trên 5 triệu',
                        onTap: () {
                          setModalState(() {
                            tempPriceFilter = 'Trên 5 triệu';
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      // ------------------------------------------------
                      // ĐẶC ĐIỂM
                      // ------------------------------------------------
                      const Text(
                        'Tiện ích & vị trí',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _FilterOption(
                        icon: Icons.apps_rounded,
                        title: 'Không giới hạn',
                        selected: tempFeatureFilter == 'Tất cả',
                        onTap: () {
                          setModalState(() {
                            tempFeatureFilter = 'Tất cả';
                          });
                        },
                      ),

                      _FilterOption(
                        icon: Icons.local_offer_rounded,
                        title: 'Giá tốt',
                        selected: tempFeatureFilter == 'Giá tốt',
                        onTap: () {
                          setModalState(() {
                            tempFeatureFilter = 'Giá tốt';
                          });
                        },
                      ),

                      _FilterOption(
                        icon: Icons.school_rounded,
                        title: 'Gần trường',
                        selected: tempFeatureFilter == 'Gần trường',
                        onTap: () {
                          setModalState(() {
                            tempFeatureFilter = 'Gần trường';
                          });
                        },
                      ),

                      _FilterOption(
                        icon: Icons.weekend_rounded,
                        title: 'Có nội thất',
                        selected: tempFeatureFilter == 'Có nội thất',
                        onTap: () {
                          setModalState(() {
                            tempFeatureFilter = 'Có nội thất';
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      // ------------------------------------------------
                      // BUTTON
                      // ------------------------------------------------
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempPriceFilter = 'Tất cả';
                                  tempFeatureFilter = 'Tất cả';
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                side: const BorderSide(
                                  color: AppColors.primaryGreen,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Đặt lại',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPriceFilter = tempPriceFilter;
                                  _selectedFeatureFilter = tempFeatureFilter;
                                });

                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Áp dụng',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BOTTOM SHEET - SẮP XẾP
  // ============================================================

  void _showSortBottomSheet() {
    String tempSort = _selectedSort;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Sắp xếp phòng',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Chọn cách hiển thị danh sách phòng yêu thích.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _FilterOption(
                      icon: Icons.access_time_rounded,
                      title: 'Mới lưu',
                      selected: tempSort == 'Mới lưu',
                      onTap: () {
                        setModalState(() {
                          tempSort = 'Mới lưu';
                        });
                      },
                    ),

                    _FilterOption(
                      icon: Icons.arrow_downward_rounded,
                      title: 'Giá thấp',
                      selected: tempSort == 'Giá thấp',
                      onTap: () {
                        setModalState(() {
                          tempSort = 'Giá thấp';
                        });
                      },
                    ),

                    _FilterOption(
                      icon: Icons.arrow_upward_rounded,
                      title: 'Giá cao',
                      selected: tempSort == 'Giá cao',
                      onTap: () {
                        setModalState(() {
                          tempSort = 'Giá cao';
                        });
                      },
                    ),

                    _FilterOption(
                      icon: Icons.square_foot_rounded,
                      title: 'Diện tích',
                      selected: tempSort == 'Diện tích',
                      onTap: () {
                        setModalState(() {
                          tempSort = 'Diện tích';
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedSort = tempSort;
                          });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Áp dụng',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==================================================================
// ACTION BUTTON
// ==================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.lightGreen),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: AppColors.primaryGreen),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// FILTER OPTION
// ==================================================================

class _FilterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.lightGreen : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primaryGreen : Colors.grey.shade400,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// FAVORITE HEADER
// ==================================================================

class _FavoriteHeader extends StatelessWidget {
  final int total;

  const _FavoriteHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -55,
          top: -45,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -80,
          bottom: -85,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.accentYellow.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 82,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.accentYellow,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'KHÔNG GIAN CỦA BẠN',
                style: TextStyle(
                  color: AppColors.accentYellow,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Những căn phòng bạn yêu thích',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$total phòng đang được lưu',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// SUMMARY BOX
// ==================================================================

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: AppColors.primaryGreen),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// FAVORITE ROOM CARD
// ==================================================================

class _FavoriteRoomCard extends StatefulWidget {
  final Map<String, dynamic> room;
  final String priceText;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteRoomCard({
    required this.room,
    required this.priceText,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_FavoriteRoomCard> createState() => _FavoriteRoomCardState();
}

class _FavoriteRoomCardState extends State<_FavoriteRoomCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final amenities = List<String>.from(room['amenities']);

    return MouseRegion(
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
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.10 : 0.045),
              blurRadius: _hovered ? 25 : 17,
              offset: Offset(0, _hovered ? 10 : 7),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(room),
                const SizedBox(width: 13),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3, right: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (room['isNew'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentYellow.withOpacity(
                                    0.16,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'MỚI',
                                  style: TextStyle(
                                    color: Color(0xFF996F00),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            GestureDetector(
                              onTap: widget.onRemove,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.07),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.redAccent,
                                  size: 19,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 9),

                        Text(
                          room['title'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          room['propertyName'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${room['ward']}, ${room['district']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 9),

                        Row(
                          children: [
                            Text(
                              widget.priceText,
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              ' /tháng',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            _InfoTag(
                              icon: Icons.square_foot_rounded,
                              text: '${room['area']} m²',
                            ),
                            const SizedBox(width: 6),
                            _InfoTag(
                              icon: Icons.people_alt_rounded,
                              text: '${room['maxPeople']} người',
                            ),
                          ],
                        ),

                        const SizedBox(height: 9),

                        SizedBox(
                          height: 25,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: amenities.length > 2
                                ? 2
                                : amenities.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 5),
                            itemBuilder: (_, index) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  amenities[index],
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> room) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Image.network(
            room['image'],
            width: 118,
            height: 190,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                width: 118,
                height: 190,
                color: AppColors.lightGreen,
                child: const Icon(
                  Icons.home_rounded,
                  color: AppColors.primaryGreen,
                  size: 40,
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'Đã lưu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// INFO TAG
// ==================================================================

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primaryGreen),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
