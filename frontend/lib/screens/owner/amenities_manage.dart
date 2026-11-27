import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_storage.dart';
import '../../services/owner/amenity_service.dart';
import '../../services/owner/property_service.dart';

class AmenitiesManageScreen extends StatefulWidget {
  final String? initialPropertyId;

  const AmenitiesManageScreen({super.key, this.initialPropertyId});

  @override
  State<AmenitiesManageScreen> createState() => _AmenitiesManageScreenState();
}

class _AmenitiesManageScreenState extends State<AmenitiesManageScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AmenityModel> _amenities = [];
  List<PropertyModel> _properties = [];
  String? _selectedPropertyId; // null = Tất cả khu trọ
  String? _currentOwnerId;

  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.initialPropertyId;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ownerId = await AuthStorage.getUserId();
      _currentOwnerId = ownerId;

      if (ownerId == null || ownerId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không tìm thấy thông tin đăng nhập.';
        });
        return;
      }

      // Tải danh sách bất động sản song song với tiện ích
      final props = await PropertyService.fetchProperties(ownerId, 'All');
      if ((_selectedPropertyId == null || !props.any((p) => p.id == _selectedPropertyId)) && props.isNotEmpty) {
        _selectedPropertyId = props.first.id;
      }
      final list = await AmenityManagementService.fetchAmenities(
        ownerId,
        propertyId: _selectedPropertyId,
      );

      if (mounted) {
        setState(() {
          _properties = props;
          _amenities = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi tải danh sách tiện ích: $e';
        });
      }
    }
  }

  Future<void> _loadAmenitiesOnly() async {
    if (_currentOwnerId == null) return;
    setState(() => _isLoading = true);
    try {
      final list = await AmenityManagementService.fetchAmenities(
        _currentOwnerId!,
        propertyId: _selectedPropertyId,
      );
      if (mounted) {
        setState(() {
          _amenities = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi khi tải lại dữ liệu: $e';
        });
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'kitchen':
        return Icons.kitchen;
      case 'elevator':
        return Icons.elevator;
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'videocam':
        return Icons.videocam;
      case 'access_time':
        return Icons.access_time;
      case 'stairs':
        return Icons.stairs;
      case 'balcony':
        return Icons.balcony;
      case 'fingerprint':
        return Icons.fingerprint;
      case 'fire_extinguisher':
        return Icons.fire_extinguisher;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'pool':
        return Icons.pool;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_parking':
        return Icons.local_parking;
      case 'pets':
        return Icons.pets;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'security':
        return Icons.security;
      case 'bed':
        return Icons.bed;
      case 'wc':
        return Icons.wc;
      case 'directions_car':
        return Icons.directions_car;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _getPropertyName(String? propertyId) {
    if (_properties.isEmpty) return 'Đang tải...';
    final prop = _properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => _properties.first,
    );
    return prop.name;
  }

  List<AmenityModel> get _filteredAmenities {
    if (_searchKeyword.isEmpty) return _amenities;
    return _amenities.where((item) {
      final matchName = item.name.toLowerCase().contains(_searchKeyword.toLowerCase());
      final matchDesc = item.description.toLowerCase().contains(_searchKeyword.toLowerCase());
      return matchName || matchDesc;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAmenities;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý Tiện ích Khu trọ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAmenitiesOnly,
            tooltip: 'Làm mới danh sách',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9FB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadAmenitiesOnly,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Dropdown chọn khu trọ
                _buildPropertySelector(),
                const SizedBox(height: 12),

                // 2. Banner giải thích nghiệp vụ
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Đang cấu hình tiện ích cho: ${_getPropertyName(_selectedPropertyId)}. Bật công tắc để gắn tiện ích vào khu này.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.primaryGreen,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Thanh tìm kiếm tiện ích
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tiện ích (wifi, thang máy, máy giặt...)',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchKeyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchKeyword = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchKeyword = val.trim());
                  },
                ),
                const SizedBox(height: 16),

                // 4. Header danh sách tiện ích
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiện ích khu trọ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${filtered.length} tiện ích',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Danh sách hiển thị
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage ?? 'Không tìm thấy tiện ích nào.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _errorMessage != null ? Colors.red[400] : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildAmenityCard(filtered[index]);
                    },
                  ),
                const SizedBox(height: 70),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm tiện ích',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _showAddAmenityDialog,
      ),
    );
  }

  // Widget chọn Khu trọ
  Widget _buildPropertySelector() {
    if (_properties.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.home_work_outlined, color: AppColors.primaryGreen, size: 20),
            const SizedBox(width: 10),
            const Text(
              'Đang tải danh sách khu trọ...',
              style: TextStyle(fontSize: 13.5, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final selectedValue = _properties.any((p) => p.id == _selectedPropertyId)
        ? _selectedPropertyId!
        : _properties.first.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedValue,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGreen),
          items: _properties.map((prop) => DropdownMenuItem<String>(
            value: prop.id,
            child: Row(
              children: [
                Icon(Icons.home_work_outlined, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prop.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedPropertyId = val;
              });
              _loadAmenitiesOnly();
            }
          },
        ),
      ),
    );
  }

  // Card hiển thị từng tiện ích
  Widget _buildAmenityCard(AmenityModel item) {
    final bool isPropSelected = _selectedPropertyId != null;
    final bool isEnabled = isPropSelected ? item.isAssigned : item.status;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? AppColors.primaryGreen.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconData(item.icon),
                color: isEnabled ? AppColors.primaryGreen : Colors.grey.shade500,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (isPropSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.isAssigned ? Colors.green[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: item.isAssigned ? Colors.green.shade200 : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        item.isAssigned ? 'Đang có tại khu này' : 'Chưa gắn vào khu này',
                        style: TextStyle(
                          fontSize: 11,
                          color: item.isAssigned ? Colors.green[800] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.status ? Colors.blue[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.status ? 'Đang hoạt động' : 'Tạm ẩn',
                        style: TextStyle(
                          fontSize: 11,
                          color: item.status ? Colors.blue[800] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              activeThumbColor: AppColors.primaryGreen,
              onChanged: (val) async {
                setState(() {
                  // Cập nhật optimistic
                  final idx = _amenities.indexWhere((a) => a.id == item.id);
                  if (idx != -1) {
                    final old = _amenities[idx];
                    _amenities[idx] = AmenityModel(
                      id: old.id,
                      ownerId: old.ownerId,
                      name: old.name,
                      description: old.description,
                      icon: old.icon,
                      status: isPropSelected ? old.status : val,
                      statusCode: isPropSelected ? old.statusCode : (val ? 'active' : 'inactive'),
                      isAssigned: isPropSelected ? val : old.isAssigned,
                      propertyId: old.propertyId,
                    );
                  }
                });

                try {
                  if (isPropSelected) {
                    await AmenityManagementService.togglePropertyAmenity(
                      _selectedPropertyId!,
                      item.id,
                    );
                  } else {
                    await AmenityManagementService.updateAmenity(item.id, {
                      'status': val,
                      'name': item.name,
                      'description': item.description,
                      'icon': item.icon,
                    });
                  }
                } catch (e) {
                  debugPrint('Lỗi toggle tiện ích: $e');
                  _loadAmenitiesOnly();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dialog thêm tiện ích mới
  void _showAddAmenityDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedIcon = 'wifi';

    final availableIcons = [
      {'name': 'wifi', 'icon': Icons.wifi, 'label': 'Wifi'},
      {'name': 'ac_unit', 'icon': Icons.ac_unit, 'label': 'Máy lạnh'},
      {'name': 'elevator', 'icon': Icons.elevator, 'label': 'Thang máy'},
      {'name': 'two_wheeler', 'icon': Icons.two_wheeler, 'label': 'Nhà xe'},
      {'name': 'videocam', 'icon': Icons.videocam, 'label': 'Camera'},
      {'name': 'kitchen', 'icon': Icons.kitchen, 'label': 'Bếp / Tủ lạnh'},
      {'name': 'local_laundry_service', 'icon': Icons.local_laundry_service, 'label': 'Máy giặt'},
      {'name': 'balcony', 'icon': Icons.balcony, 'label': 'Ban công'},
      {'name': 'fingerprint', 'icon': Icons.fingerprint, 'label': 'Khoá vân tay'},
      {'name': 'fire_extinguisher', 'icon': Icons.fire_extinguisher, 'label': 'PCCC'},
      {'name': 'access_time', 'icon': Icons.access_time, 'label': 'Giờ giấc tự do'},
      {'name': 'security', 'icon': Icons.security, 'label': 'Bảo vệ 24/7'},
      {'name': 'bed', 'icon': Icons.bed, 'label': 'Giường nệm'},
      {'name': 'wc', 'icon': Icons.wc, 'label': 'WC riêng'},
      {'name': 'pool', 'icon': Icons.pool, 'label': 'Hồ bơi'},
      {'name': 'directions_car', 'icon': Icons.directions_car, 'label': 'Đỗ ô tô'},
      {'name': 'pets', 'icon': Icons.pets, 'label': 'Nuôi thú cưng'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Thêm Tiện ích mới',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên tiện ích *',
                    hintText: 'VD: Hồ bơi, Bãi đỗ ô tô...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mô tả ngắn',
                    hintText: 'VD: Tự do sử dụng, mở cửa 24/7...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chọn biểu tượng đại diện:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableIcons.map((ic) {
                    final isSel = selectedIcon == ic['name'];
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedIcon = ic['name'] as String;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryGreen : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel ? AppColors.primaryGreen : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ic['icon'] as IconData,
                              size: 16,
                              color: isSel ? Colors.white : Colors.grey.shade800,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              ic['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSel ? Colors.white : Colors.grey.shade800,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                if (name.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên tiện ích')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                try {
                  final ok = await AmenityManagementService.createAmenity({
                    'ownerId': _currentOwnerId,
                    'propertyId': _selectedPropertyId,
                    'name': name,
                    'description': descCtrl.text.trim(),
                    'icon': selectedIcon,
                    'status': true,
                  });
                  if (ok) {
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Thêm tiện ích thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    _loadData();
                  } else {
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Không thể thêm tiện ích. Vui lòng thử lại!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              child: const Text('Thêm mới', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
