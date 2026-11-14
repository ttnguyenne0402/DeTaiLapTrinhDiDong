import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/owner_drawer.dart';
import '../../services/owner/service_service.dart';
import 'service_form.dart';
import '../../services/auth_storage.dart';

class ServicesManageScreen extends StatefulWidget {
  const ServicesManageScreen({super.key});

  @override
  State<ServicesManageScreen> createState() => _ServicesManageScreenState();
}

class _ServicesManageScreenState extends State<ServicesManageScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  // Tải danh sách dịch vụ trực tiếp từ SQL Server qua Backend Web API
  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ownerId = await AuthStorage.getUserId() ?? '';
      final list = await ServiceManagementService.fetchServices(ownerId);
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
      drawer: const OwnerDrawer(currentRoute: 'services'),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadServices,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
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
                                'Bảng giá dịch vụ lấy trực tiếp từ SQL Server và được áp dụng khi lập hóa đơn hàng tháng.',
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
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Danh sách dịch vụ áp dụng',
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
                      _services.isEmpty
                          ? Padding(
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
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _services.length,
                              itemBuilder: (context, index) {
                                final service = _services[index];
                                return _buildServiceCard(service);
                              },
                            ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ServiceFormScreen()),
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

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final bool isActive = service['status'] ?? true;

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
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                service['icon'] as IconData? ?? Icons.miscellaneous_services,
                color: AppColors.primaryGreen,
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
                      Text(
                        service['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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
                        color: AppColors.primaryGreen,
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
                  if (service['description'] != null) ...[
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
                  value: isActive,
                  activeThumbColor: AppColors.primaryGreen,
                  onChanged: (val) async {
                    setState(() {
                      service['status'] = val;
                    });
                    try {
                      await ServiceManagementService.toggleServiceStatus(service['id']);
                    } catch (e) {
                      debugPrint('Lỗi chuyển trạng thái dịch vụ: $e');
                    }
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ServiceFormScreen(initialData: service),
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
                      'Sửa',
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
