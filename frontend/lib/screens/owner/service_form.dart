import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ServiceFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ServiceFormScreen({super.key, this.initialData});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  String _selectedUnit = 'kWh';
  bool _isMandatory = false;
  IconData _selectedIcon = Icons.miscellaneous_services;

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
    _priceController = TextEditingController(text: data?['price'] ?? '');
    _descriptionController = TextEditingController(
      text: data?['description'] ?? '',
    );

    if (data != null) {
      _selectedUnit = data['unit'] ?? 'kWh';
      _isMandatory = data['isMandatory'] ?? false;
      _selectedIcon = data['icon'] ?? Icons.miscellaneous_services;
    }
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
                            validator: (val) => val == null || val.isEmpty
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
                                  validator: (val) => val == null || val.isEmpty
                                      ? 'Nhập đơn giá'
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: 'Đơn giá (VNĐ)',
                                    hintText: '3.500',
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
                                  value: _selectedUnit,
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
                                    if (val != null)
                                      setState(() => _selectedUnit = val);
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
                              labelText: 'Mô tả / Cách tính',
                              hintText:
                                  'VD: Thu theo chỉ số đồng hồ chốt ngày 30 hàng tháng',
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
                          activeColor: AppColors.primaryGreen,
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            'id':
                                widget.initialData?['id'] ??
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            'name': _nameController.text,
                            'price': _priceController.text,
                            'unit': _selectedUnit,
                            'icon': _selectedIcon,
                            'iconColor': AppColors.primaryGreen,
                            'isMandatory': _isMandatory,
                            'status': true,
                            'description': _descriptionController.text,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
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
        fontSize: 15,
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}
