import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/service_service.dart';

class ServiceFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ServiceFormScreen({super.key, this.initialData});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  String _selectedUnit = 'kWh';
  bool _isMandatory = false;
  IconData _selectedIcon = Icons.bolt;

  final List<String> _units = [
    'kWh',
    'm³',
    'người/tháng',
    'phòng/tháng',
    'xe/tháng',
    'lần',
  ];

  final List<IconData> _availableIcons = [
    Icons.bolt,
    Icons.water_drop,
    Icons.wifi,
    Icons.cleaning_services,
    Icons.elevator,
    Icons.two_wheeler,
    Icons.security,
    Icons.local_laundry_service,
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nameController = TextEditingController(text: data?['name'] ?? '');

    // Trích xuất đơn giá sạch để người dùng tiện chỉnh sửa
    String priceText = '';
    if (data != null) {
      if (data['rawPrice'] != null) {
        final num val = data['rawPrice'];
        priceText = val == val.roundToDouble() ? '${val.toInt()}' : '$val';
      } else if (data['price'] != null) {
        priceText = data['price'].toString().replaceAll('.', '').replaceAll(',', '').trim();
      }
    }
    _priceController = TextEditingController(text: priceText);
    _descriptionController = TextEditingController(
      text: data?['description'] ?? '',
    );

    if (data != null) {
      String unit = data['unit'] ?? 'kWh';
      if (unit == 'm3') unit = 'm³';
      if (!_units.contains(unit)) {
        _units.add(unit);
      }
      _selectedUnit = unit;
      _isMandatory = data['isMandatory'] ?? false;

      if (data['iconName'] != null) {
        _selectedIcon = _getIconDataByName(data['iconName'].toString());
      } else if (data['icon'] is IconData) {
        _selectedIcon = data['icon'];
      }
    }
  }

  IconData _getIconDataByName(String icon) {
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
        return Icons.bolt;
    }
  }

  String _getIconString(IconData icon) {
    if (icon == Icons.bolt) return 'bolt';
    if (icon == Icons.water_drop) return 'water_drop';
    if (icon == Icons.wifi) return 'wifi';
    if (icon == Icons.cleaning_services) return 'cleaning_services';
    if (icon == Icons.elevator) return 'elevator';
    if (icon == Icons.two_wheeler) return 'two_wheeler';
    if (icon == Icons.security) return 'security';
    if (icon == Icons.local_laundry_service) return 'local_laundry_service';
    return 'bolt';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.initialData != null;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Chỉnh sửa dịch vụ' : 'Thêm dịch vụ mới',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9FB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Biểu tượng đại diện'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _availableIcons.map((icon) {
                            final isSelected = _selectedIcon == icon;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = icon;
                                });
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.grey[100],
                                child: Icon(
                                  icon,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('Thông tin chi tiết dịch vụ'),
                      const SizedBox(height: 8),
                      _buildCardGroup(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Vui lòng nhập tên dịch vụ'
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Tên dịch vụ',
                              hintText: 'VD: Tiền điện sinh hoạt',
                              prefixIcon: Icon(
                                Icons.label_outline,
                                color: AppColors.primaryGreen,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  validator: (val) => val == null || val.trim().isEmpty
                                      ? 'Nhập đơn giá'
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: 'Đơn giá (VNĐ)',
                                    hintText: '3500',
                                    prefixIcon: Icon(
                                      Icons.attach_money,
                                      color: AppColors.primaryGreen,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedUnit,
                                  decoration: InputDecoration(
                                    labelText: 'Đơn vị tính',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: _units
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(u),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedUnit = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Mô tả tính toán',
                              hintText: 'VD: Tính theo chỉ số công tơ điện hàng tháng',
                              prefixIcon: Icon(
                                Icons.description_outlined,
                                color: AppColors.primaryGreen,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('Quy định áp dụng'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SwitchListTile(
                          activeTrackColor: AppColors.primaryGreen,
                          title: const Text(
                            'Bắt buộc đối với tất cả các phòng',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Tự động cộng vào hóa đơn hàng tháng không cần chọn thêm.',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isMandatory,
                          onChanged: (val) {
                            setState(() {
                              _isMandatory = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
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
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);

                                setState(() => _isSaving = true);
                                try {
                                  final rawPrice = _priceController.text
                                      .replaceAll('.', '')
                                      .replaceAll(',', '')
                                      .replaceAll(' ', '')
                                      .trim();
                                  final priceVal = double.tryParse(rawPrice) ?? 0.0;
                                  final iconStr = _getIconString(_selectedIcon);

                                  final payload = {
                                    'ownerId': 'USER_OWNER_01',
                                    'name': _nameController.text.trim(),
                                    'price': priceVal,
                                    'unit': _selectedUnit,
                                    'isMandatory': _isMandatory,
                                    'icon': iconStr,
                                    'description': _descriptionController.text.trim(),
                                    'status': widget.initialData?['status'] ?? true,
                                  };

                                  bool ok = false;
                                  if (isEdit && widget.initialData != null && widget.initialData!['id'] != null) {
                                    final serviceId = widget.initialData!['id'].toString();
                                    ok = await ServiceManagementService.updateService(serviceId, payload);
                                  } else {
                                    ok = await ServiceManagementService.createService(payload);
                                  }

                                  if (!mounted) return;
                                  setState(() => _isSaving = false);

                                  if (ok) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(isEdit
                                            ? 'Cập nhật dịch vụ thành công'
                                            : 'Thêm dịch vụ thành công'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    navigator.pop(true);
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Lưu dịch vụ thất bại. Vui lòng thử lại!'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() => _isSaving = false);
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Lỗi kết nối API: $e')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isEdit ? 'CẬP NHẬT DỊCH VỤ' : 'THÊM DỊCH VỤ',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCardGroup({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}
