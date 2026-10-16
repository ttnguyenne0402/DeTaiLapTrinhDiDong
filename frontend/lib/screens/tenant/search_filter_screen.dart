import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SearchFilterScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rooms;
  final String initialKeyword;

  const SearchFilterScreen({
    super.key,
    required this.rooms,
    this.initialKeyword = '',
  });

  @override
  State<SearchFilterScreen> createState() =>
      _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  late final TextEditingController _searchController;

  static const double _priceMax = 10;
  static const double _areaMax = 100;

  double _minPrice = 0;
  double _maxPrice = _priceMax;

  double _minArea = 0;
  double _maxArea = _areaMax;

  String? _selectedDistrict;
  int? _selectedPeople;

  final Set<String> _selectedAmenities = {};

  final List<String> _districts = [
    'Quận 12',
    'Tân Phú',
    'Bình Thạnh',
    'Gò Vấp',
    'Tân Bình',
    'TP. Thủ Đức',
    'Quận 7',
    'Quận 10',
  ];

  final List<String> _amenities = [
    'Máy lạnh',
    'Wifi',
    'Tủ lạnh',
    'WC riêng',
    'Ban công',
    'Thang máy',
    'Máy giặt',
    'Camera',
    'Chỗ để xe',
  ];

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(
      text: widget.initialKeyword,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // TÌM KIẾM TIẾNG VIỆT
  // ============================================================

  String _normalize(String value) {
    const map = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };

    String result = value.trim().toLowerCase();

    map.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    return result;
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> _getFilteredRooms() {
    final keyword = _normalize(
      _searchController.text,
    );

    return widget.rooms.where((room) {
      final title = _normalize(
        room['title']?.toString() ?? '',
      );

      final propertyName = _normalize(
        room['propertyName']?.toString() ?? '',
      );

      final district = _normalize(
        room['district']?.toString() ?? '',
      );

      final ward = _normalize(
        room['ward']?.toString() ?? '',
      );

      final price =
          (room['price'] as num?)?.toDouble() ?? 0;

      final area =
          (room['area'] as num?)?.toDouble() ?? 0;

      final people =
          (room['maxPeople'] as num?)?.toInt() ?? 0;

      final amenities = List<String>.from(
        room['amenities'] ?? const [],
      );

      final status =
          room['status']?.toString() ?? '';

      // Từ khóa
      final keywordMatch = keyword.isEmpty ||
          title.contains(keyword) ||
          propertyName.contains(keyword) ||
          district.contains(keyword) ||
          ward.contains(keyword);

      // Khu vực
      final districtMatch =
          _selectedDistrict == null ||
          room['district'] == _selectedDistrict;

      // Giá
      final priceMillion = price / 1000000;

      final priceMatch =
          priceMillion >= _minPrice &&
          priceMillion <= _maxPrice;

      // Diện tích
      final areaMatch =
          area >= _minArea &&
          area <= _maxArea;

      // Số người
      final peopleMatch =
          _selectedPeople == null ||
          people >= _selectedPeople!;

      // Tiện nghi
      final amenityMatch =
          _selectedAmenities.isEmpty ||
          _selectedAmenities.every(
            (item) => amenities.contains(item),
          );

      // Chỉ lấy phòng đang trống
      final statusMatch =
          status.toLowerCase() == 'available';

      return keywordMatch &&
          districtMatch &&
          priceMatch &&
          areaMatch &&
          peopleMatch &&
          amenityMatch &&
          statusMatch;
    }).toList();
  }

  // ============================================================
  // APPLY
  // ============================================================

  void _applyFilter() {
    Navigator.pop(
      context,
      _getFilteredRooms(),
    );
  }

  // ============================================================
  // RESET
  // ============================================================

  void _resetFilter() {
    setState(() {
      _searchController.clear();

      _minPrice = 0;
      _maxPrice = _priceMax;

      _minArea = 0;
      _maxArea = _areaMax;

      _selectedDistrict = null;
      _selectedPeople = null;
      _selectedAmenities.clear();
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final result = _getFilteredRooms();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tìm & lọc phòng',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilter,
            child: const Text(
              'Đặt lại',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                25,
              ),
              children: [
                _buildSearchField(),

                const SizedBox(height: 18),

                _buildResultCount(result.length),

                const SizedBox(height: 18),

                _buildSectionCard(
                  icon: Icons.location_on_outlined,
                  title: 'Khu vực',
                  child: _buildDistrict(),
                ),

                const SizedBox(height: 14),

                _buildSectionCard(
                  icon: Icons.payments_outlined,
                  title: 'Khoảng giá',
                  child: _buildPriceFilter(),
                ),

                const SizedBox(height: 14),

                _buildSectionCard(
                  icon: Icons.square_foot_rounded,
                  title: 'Diện tích',
                  child: _buildAreaFilter(),
                ),

                const SizedBox(height: 14),

                _buildSectionCard(
                  icon: Icons.people_outline_rounded,
                  title: 'Số người ở',
                  child: _buildPeopleFilter(),
                ),

                const SizedBox(height: 14),

                _buildSectionCard(
                  icon: Icons.home_repair_service_outlined,
                  title: 'Tiện nghi',
                  child: _buildAmenities(),
                ),

                const SizedBox(height: 22),

                _buildPreview(result),
              ],
            ),
          ),

          _buildBottomButton(result.length),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8E4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryGreen,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
          hintText:
              'Tên phòng, khu vực, quận...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESULT COUNT
  // ============================================================

  Widget _buildResultCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Tìm thấy $count phòng phù hợp',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E9E5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryGreen,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // DISTRICT
  // ============================================================

  Widget _buildDistrict() {
    return DropdownButtonFormField<String>(
      value: _selectedDistrict,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Tất cả khu vực',
        prefixIcon: const Icon(
          Icons.map_outlined,
          color: AppColors.primaryGreen,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFFE0E6E2),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
      items: _districts.map((district) {
        return DropdownMenuItem<String>(
          value: district,
          child: Text(district),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDistrict = value;
        });
      },
    );
  }

  // ============================================================
  // PRICE
  // ============================================================

  Widget _buildPriceFilter() {
    return Column(
      children: [
        Row(
          children: [
            _buildValueBox(
              'Từ',
              '${_minPrice.toStringAsFixed(1)} triệu',
            ),
            const Spacer(),
            _buildValueBox(
              'Đến',
              '${_maxPrice.toStringAsFixed(1)} triệu',
            ),
          ],
        ),

        const SizedBox(height: 6),

        RangeSlider(
          values: RangeValues(
            _minPrice,
            _maxPrice,
          ),
          min: 0,
          max: _priceMax,
          divisions: 20,
          activeColor: AppColors.primaryGreen,
          inactiveColor: const Color(0xFFDDE7E2),
          labels: RangeLabels(
            '${_minPrice.toStringAsFixed(1)} triệu',
            '${_maxPrice.toStringAsFixed(1)} triệu',
          ),
          onChanged: (values) {
            setState(() {
              _minPrice = values.start;
              _maxPrice = values.end;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // AREA
  // ============================================================

  Widget _buildAreaFilter() {
    return Column(
      children: [
        Row(
          children: [
            _buildValueBox(
              'Từ',
              '${_minArea.toStringAsFixed(0)} m²',
            ),
            const Spacer(),
            _buildValueBox(
              'Đến',
              '${_maxArea.toStringAsFixed(0)} m²',
            ),
          ],
        ),

        const SizedBox(height: 6),

        RangeSlider(
          values: RangeValues(
            _minArea,
            _maxArea,
          ),
          min: 0,
          max: _areaMax,
          divisions: 20,
          activeColor: AppColors.primaryGreen,
          inactiveColor: const Color(0xFFDDE7E2),
          labels: RangeLabels(
            '${_minArea.toStringAsFixed(0)} m²',
            '${_maxArea.toStringAsFixed(0)} m²',
          ),
          onChanged: (values) {
            setState(() {
              _minArea = values.start;
              _maxArea = values.end;
            });
          },
        ),
      ],
    );
  }

  Widget _buildValueBox(
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PEOPLE
  // ============================================================

  Widget _buildPeopleFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [1, 2, 3, 4].map((people) {
        final selected =
            _selectedPeople == people;

        return ChoiceChip(
          label: Text('$people người'),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _selectedPeople =
                  selected ? null : people;
            });
          },
          selectedColor:
              AppColors.primaryGreen,
          backgroundColor:
              AppColors.background,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: selected
                ? Colors.white
                : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(
            color: selected
                ? AppColors.primaryGreen
                : const Color(0xFFE0E6E2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(11),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // AMENITIES
  // ============================================================

  Widget _buildAmenities() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _amenities.map((amenity) {
        final selected =
            _selectedAmenities.contains(
          amenity,
        );

        return FilterChip(
          label: Text(amenity),
          selected: selected,
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedAmenities.add(
                  amenity,
                );
              } else {
                _selectedAmenities.remove(
                  amenity,
                );
              }
            });
          },
          selectedColor:
              AppColors.lightGreen,
          backgroundColor:
              AppColors.background,
          checkmarkColor:
              AppColors.primaryGreen,
          labelStyle: TextStyle(
            color: selected
                ? AppColors.primaryGreen
                : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
          side: BorderSide(
            color: selected
                ? AppColors.primaryGreen
                : const Color(0xFFE0E6E2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  Widget _buildPreview(
    List<Map<String, dynamic>> rooms,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E9E5),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Xem trước',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            rooms.isEmpty
                ? 'Không có phòng phù hợp'
                : 'Có ${rooms.length} phòng phù hợp',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          if (rooms.isEmpty)
            _buildNoResult()
          else
            ...rooms.take(3).map(
              (room) => _buildPreviewRoom(room),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewRoom(
    Map<String, dynamic> room,
  ) {
    final price =
        (room['price'] as num?)?.toDouble() ??
            0;

    final area =
        (room['area'] as num?)?.toDouble() ??
            0;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      padding:
          const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
                  AppColors.lightGreen,
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color:
                  AppColors.primaryGreen,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  room['title']?.toString() ??
                      'Phòng trọ',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${room['district']} • ${area.toStringAsFixed(0)} m²',
                  style:
                      const TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)} triệu/tháng',
                  style:
                      const TextStyle(
                    color:
                        AppColors.primaryGreen,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResult() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppColors.primaryGreen,
            size: 42,
          ),
          SizedBox(height: 8),
          Text(
            'Chưa có phòng phù hợp',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Hãy thử bỏ bớt một vài điều kiện.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM BUTTON
  // ============================================================

  Widget _buildBottomButton(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        16,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _applyFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(
              Icons.check_rounded,
              size: 19,
            ),
            label: Text(
              'Xem $count phòng phù hợp',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}