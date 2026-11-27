import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/service_service.dart';
import '../../services/owner/property_service.dart';
import 'service_form.dart';
import '../../services/auth_storage.dart';

class ServicesManageScreen extends StatefulWidget {
  final String? initialPropertyId;

  const ServicesManageScreen({super.key, this.initialPropertyId});

  @override
  State<ServicesManageScreen> createState() => _ServicesManageScreenState();
}

class _ServicesManageScreenState extends State<ServicesManageScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _services = [];

  List<PropertyModel> _properties = [];
  String? _selectedPropertyId; // null = Tất cả khu trọ

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.initialPropertyId;
    _initData();
  }

  Future<void> _initData() async {
    await _loadProperties();
    await _loadServices();
  }

  Future<void> _loadProperties() async {
    try {
      final ownerId = await AuthStorage.getUserId() ?? '';
      final props = await PropertyService.fetchProperties(ownerId, 'All');
      if (mounted) {
        setState(() {
          _properties = props;
          if ((_selectedPropertyId == null || !_properties.any((p) => p.id == _selectedPropertyId)) && _properties.isNotEmpty) {
            _selectedPropertyId = _properties.first.id;
          }
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách bất động sản: $e');
    }
  }

  // Tải danh sách dịch vụ trực tiếp từ SQL Server qua Backend Web API (hỗ trợ lọc theo khu trọ)
  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ownerId = await AuthStorage.getUserId() ?? '';
      final list = await ServiceManagementService.fetchServices(
        ownerId,
        propertyId: _selectedPropertyId,
      );
      if (mounted) {
        setState(() {
          _services = list.map((s) => {
            'id': s.id,
            'name': s.name,
            'price': s.priceFormatted.isNotEmpty ? s.priceFormatted : '${s.price.toInt()}',
            'rawPrice': s.price,
            'unit': s.unit,
            'icon': _getIconData(s.icon),
            'iconName': s.icon,
            'isMandatory': s.isMandatory,
            'status': s.status,
            'isAssigned': s.isAssigned,
            'propertyId': _selectedPropertyId,
            'description': s.description,
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách dịch vụ từ API: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không kết nối được tới máy chủ.\nKiểm tra lại Backend đã chạy chưa rồi thử lại.';
        });
      }
    }
  }

  IconData _getIconData(String icon) {
    switch (icon.toLowerCase()) {
      case 'bolt':
        return Icons.bolt;
      case 'water_drop':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'elevator':
        return Icons.elevator;
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'security':
        return Icons.security;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      default:
        return Icons.miscellaneous_services;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Quản lý Dịch vụ & Bảng giá',
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
            tooltip: 'Làm mới',
            onPressed: _loadServices,
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
          onRefresh: _loadServices,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Bộ chọn Khu trọ / Tòa nhà áp dụng
                _buildPropertySelector(),
                const SizedBox(height: 14),

                // 2. Banner Thông tin hướng dẫn
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đang cấu hình dịch vụ cho: ${_getSelectedPropertyName()}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Bắt buộc: Dịch vụ chung cả dãy trọ đều đóng (Điện, Nước, Rác...)\n• Theo nhu cầu: Dịch vụ riêng (Gửi xe, Wifi, Máy lạnh...), chỉ phòng nào đăng ký dùng mới tính tiền.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primaryGreen.withValues(alpha: 0.9),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Tiêu đề danh sách
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dịch vụ của khu trọ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_services.length} dịch vụ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Danh sách dịch vụ
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_services.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            _errorMessage ?? 'Chưa có dịch vụ nào trong cơ sở dữ liệu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _errorMessage != null ? Colors.red[400] : Colors.grey,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _loadServices,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return _buildServiceCard(service);
                    },
                  ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceFormScreen(
                initialPropertyId: _selectedPropertyId,
              ),
            ),
          );
          if (result == true) {
            _loadServices();
          }
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm dịch vụ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getSelectedPropertyName() {
    if (_properties.isEmpty) return 'Đang tải...';
    final match = _properties.where((p) => p.id == _selectedPropertyId);
    return match.isNotEmpty ? match.first.name : _properties.first.name;
  }

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
            Icon(Icons.apartment, size: 20, color: AppColors.primaryGreen),
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
            color: Colors.black.withValues(alpha: 0.03),
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
          items: _properties.map((p) => DropdownMenuItem<String>(
            value: p.id,
            child: Row(
              children: [
                Icon(Icons.apartment, size: 20, color: AppColors.primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.name,
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
              _loadServices();
            }
          },
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final bool isActive = service['status'] ?? true;
    final bool isAssigned = service['isAssigned'] ?? true;

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
                color: (isActive && isAssigned)
                    ? AppColors.primaryGreen.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                service['icon'] as IconData? ?? Icons.miscellaneous_services,
                color: (isActive && isAssigned)
                    ? AppColors.primaryGreen
                    : Colors.grey.shade500,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          service['name'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: (isActive && isAssigned) ? Colors.black87 : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (service['isMandatory'] == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Bắt buộc',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Theo nhu cầu',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      text: '${service['price']}đ ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: (isActive && isAssigned) ? AppColors.primaryGreen : Colors.grey,
                      ),
                      children: [
                        TextSpan(
                          text: '/ ${service['unit']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedPropertyId != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAssigned ? Colors.green[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isAssigned ? 'Áp dụng cho khu này' : 'Chưa áp dụng cho khu này',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isAssigned ? Colors.green[800] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else if (service['description'] != null && (service['description'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      service['description'] ?? '',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: _selectedPropertyId != null ? isAssigned : isActive,
                  activeThumbColor: AppColors.primaryGreen,
                  onChanged: (val) async {
                    setState(() {
                      if (_selectedPropertyId != null) {
                        service['isAssigned'] = val;
                        service['status'] = val;
                      } else {
                        service['status'] = val;
                      }
                    });
                    try {
                      if (_selectedPropertyId != null) {
                        await ServiceManagementService.togglePropertyService(
                          service['id'],
                          _selectedPropertyId!,
                        );
                      } else {
                        await ServiceManagementService.toggleServiceStatus(service['id']);
                      }
                    } catch (e) {
                      debugPrint('Lỗi chuyển trạng thái dịch vụ: $e');
                      _loadServices();
                    }
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceFormScreen(
                          initialData: service,
                          initialPropertyId: _selectedPropertyId,
                        ),
                      ),
                    );
                    if (res == true) {
                      _loadServices();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sửa giá',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
