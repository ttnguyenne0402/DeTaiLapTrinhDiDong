import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/property_service.dart';
import '../../services/auth_storage.dart';

class PropertyFormScreen extends StatefulWidget {
  const PropertyFormScreen({super.key});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final Color primaryColor = const Color(0xFF1B5E55);
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  final TextEditingController _roomsController = TextEditingController();
  final TextEditingController _descController = TextEditingController();


  String _selectedStatus = 'Đang hoạt động';
  String _selectedType = 'rooming_house';
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final ownerId = await AuthStorage.getUserId();
      final data = {
        'ownerId': ownerId.toString().trim(),
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'address': _addressController.text.trim(),
        'district': _districtController.text.trim(), // Lấy dữ liệu quận động
        'ward': _wardController.text.trim(),         // Lấy dữ liệu phường động
        'totalRooms': int.tryParse(_roomsController.text.trim()) ?? 1,
        'status': _selectedStatus == 'Đang hoạt động' ? 'active' : 'inactive',
        'description': _descController.text.trim(),
        'image': 'frontend/assets/images/anhPhongDemo.jpg',
      };

      try {
        bool success = await PropertyService.createProperty(data);
        setState(() => _isLoading = false);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm tòa nhà thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm tòa nhà thất bại. Vui lòng thử lại!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi kết nối: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thêm Bất động sản mới',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: AppColors.primaryGreen,
        child: Container(
          clipBehavior: Clip.antiAlias,
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
                        _buildSectionTitle('Hình ảnh Tòa nhà / Bất động sản'),
                        const SizedBox(height: 8),
                        _buildImagePickerSection(),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Thông tin cơ bản'),
                        const SizedBox(height: 8),
                        _buildCardGroup(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Tên Tòa nhà / Dãy trọ',
                              hint: 'VD: Chung cư Mini Q7',
                              icon: Icons.apartment_outlined,
                              validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _addressController,
                              label: 'Địa chỉ chi tiết',
                              hint: 'VD: 123 Nguyễn Thị Thập',
                              icon: Icons.location_on_outlined,
                              validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _districtController,
                                    label: 'Quận / Huyện',
                                    hint: 'VD: Quận 7',
                                    icon: Icons.map_outlined,
                                    validator: (val) => val == null || val.isEmpty ? 'Nhập quận' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _wardController,
                                    label: 'Phường / Xã',
                                    hint: 'VD: Tân Quy',
                                    icon: Icons.location_city_outlined,
                                    validator: (val) => val == null || val.isEmpty ? 'Nhập phường' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Quy mô bất động sản'),
                        const SizedBox(height: 8),
                        _buildCardGroup(
                          children: [
                            _buildTextField(
                              controller: _roomsController,
                              label: 'Số lượng phòng',
                              hint: '20',
                              keyboardType: TextInputType.number,
                              icon: Icons.meeting_room_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Trạng thái hoạt động'),
                        const SizedBox(height: 8),
                        _buildStatusSelector(),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Mô tả & Tiện ích chung'),
                        const SizedBox(height: 8),
                        _buildCardGroup(
                          children: [
                            _buildTextField(
                              controller: _descController,
                              label: 'Mô tả tiện ích hoặc quy định',
                              hint: 'VD: Có thang máy, giờ giấc tự do...',
                              maxLines: 3,
                              icon: Icons.description_outlined,
                            ),
                          ],
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
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Thêm bất động sản',
                                style: TextStyle(
                                  fontSize: 16,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: primaryColor) : null,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9F9FB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(Icons.add_a_photo_outlined, color: primaryColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thêm hình ảnh tổng quan tòa nhà',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Hỗ trợ JPG, PNG (Tối đa 5 ảnh)',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    final statuses = ['Đang hoạt động', 'Bảo trì'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: statuses.map((status) {
          final isSelected = _selectedStatus == status;
          return ChoiceChip(
            label: Text(status),
            selected: isSelected,
            selectedColor: primaryColor,
            backgroundColor: Colors.grey[100],
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            showCheckmark: false,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedStatus = status;
                });
              }
            },
          );
        }).toList(),
      ),
    );
  }
}