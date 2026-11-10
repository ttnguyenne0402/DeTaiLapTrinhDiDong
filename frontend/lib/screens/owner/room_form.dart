import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/room_service.dart';
import '../../services/owner/property_service.dart';

// Màn hình biểu mẫu thêm mới hoặc chỉnh sửa phòng trọ
class RoomFormScreen extends StatefulWidget {
  final RoomModel? initialData;

  const RoomFormScreen({super.key, this.initialData});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final Color primaryColor = const Color(0xFF1B5E55);
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  late final TextEditingController _floorController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;

  List<PropertyModel> _properties = [];
  String? _selectedPropertyId;
  bool _isLoading = false;
  bool _loadingProperties = true;

  // Trạng thái phòng mặc định
  String _selectedStatus = 'Còn trống';

  @override
  void initState() {
    super.initState();
    final item = widget.initialData;

    _nameController = TextEditingController(text: item?.name ?? '');
    _areaController = TextEditingController(
      text: (item != null && item.area > 0) ? '${item.area.toInt()}' : '',
    );
    _floorController = TextEditingController(
      text: item?.floor != null ? '${item!.floor}' : '',
    );
    _priceController = TextEditingController(
      text: (item != null && item.price > 0) ? '${item.price.toInt()}' : '',
    );
    _descController = TextEditingController(text: item?.description ?? '');

    if (item != null) {
      _selectedStatus = item.statusText;
      _selectedPropertyId = item.propertyId;
    }

    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final list = await PropertyService.fetchProperties('USER_OWNER_01', 'all');
      if (mounted) {
        setState(() {
          _properties = list;
          if (_selectedPropertyId == null && _properties.isNotEmpty) {
            _selectedPropertyId = _properties.first.id;
          }
          _loadingProperties = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách tòa nhà: $e');
      if (mounted) {
        setState(() => _loadingProperties = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _floorController.dispose();
    _priceController.dispose();
    _descController.dispose();
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
          isEdit ? 'Chỉnh sửa phòng' : 'Thêm phòng mới',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      // Thân màn hình bo góc lồng 2 lớp Container
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
                        // Chọn bất động sản / tòa nhà trực tiếp từ CSDL
                        _buildSectionTitle('Chọn Tòa nhà / Bất động sản'),
                        const SizedBox(height: 8),
                        _buildPropertyDropdown(),
                        const SizedBox(height: 20),

                        // Tải ảnh thực tế phòng
                        _buildSectionTitle('Hình ảnh phòng'),
                        const SizedBox(height: 8),
                        _buildImagePickerSection(),
                        const SizedBox(height: 20),

                        // Nhập thông tin cơ bản
                        _buildSectionTitle('Thông tin cơ bản'),
                        const SizedBox(height: 8),
                        _buildCardGroup(
                          children: [
                            _buildTextField(
                              label: 'Tên phòng',
                              hint: 'VD: Phòng 101',
                              controller: _nameController,
                              icon: Icons.meeting_room_outlined,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Diện tích',
                                    hint: '25',
                                    controller: _areaController,
                                    suffixText: 'm²',
                                    keyboardType: TextInputType.number,
                                    icon: Icons.square_foot_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Tầng thứ',
                                    hint: '2',
                                    controller: _floorController,
                                    keyboardType: TextInputType.number,
                                    icon: Icons.layers_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Giá thuê phòng',
                              hint: '4000000',
                              controller: _priceController,
                              suffixText: 'đ/tháng',
                              keyboardType: TextInputType.number,
                              icon: Icons.payments_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Chọn trạng thái phòng
                        _buildSectionTitle('Trạng thái phòng'),
                        const SizedBox(height: 8),
                        _buildStatusSelector(),
                        const SizedBox(height: 20),

                        // Mô tả nội thất & Ghi chú
                        _buildSectionTitle('Mô tả thêm'),
                        const SizedBox(height: 8),
                        _buildCardGroup(
                          children: [
                            _buildTextField(
                              label: 'Mô tả ngắn hoặc ghi chú',
                              hint: 'Nhập thông tin nội thất, điện nước...',
                              controller: _descController,
                              maxLines: 3,
                              icon: Icons.description_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Nút xác nhận thêm / cập nhật phòng
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
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  if (_nameController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng nhập tên phòng'),
                                      ),
                                    );
                                    return;
                                  }

                                  final messenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);

                                  setState(() => _isLoading = true);

                                  final targetPropId = _selectedPropertyId ??
                                      (_properties.isNotEmpty ? _properties.first.id : 'prop_01');

                                  final cleanPrice = _priceController.text
                                      .replaceAll('.', '')
                                      .replaceAll(',', '')
                                      .replaceAll(' ', '')
                                      .trim();

                                  final payload = {
                                    'propertyId': targetPropId,
                                    'name': _nameController.text.trim(),
                                    'area': double.tryParse(_areaController.text.trim()) ?? 20.0,
                                    'floor': int.tryParse(_floorController.text.trim()) ?? 1,
                                    'price': double.tryParse(cleanPrice) ?? 3500000.0,
                                    'status': _selectedStatus == 'Còn trống'
                                        ? 'available'
                                        : (_selectedStatus == 'Đang cho thuê' ? 'rented' : 'maintenance'),
                                    'description': _descController.text.trim(),
                                  };

                                  bool success = false;
                                  if (isEdit) {
                                    success = await RoomService.updateRoom(
                                      widget.initialData!.id,
                                      payload,
                                    );
                                  } else {
                                    success = await RoomService.createRoom(payload);
                                  }

                                  if (!mounted) return;
                                  setState(() => _isLoading = false);

                                  if (success) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(isEdit
                                            ? 'Cập nhật phòng thành công'
                                            : 'Thêm phòng thành công'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    navigator.pop(true);
                                  } else {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(isEdit
                                            ? 'Cập nhật phòng thất bại'
                                            : 'Thêm phòng thất bại'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isEdit ? 'CẬP NHẬT PHÒNG' : 'THÊM PHÒNG',
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
      ),
    );
  }

  Widget _buildPropertyDropdown() {
    if (_loadingProperties) {
      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
    }

    if (_properties.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Chưa có tòa nhà nào. Vui lòng tạo tòa nhà trước!'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedPropertyId,
          items: _properties.map((p) {
            return DropdownMenuItem<String>(
              value: p.id,
              child: Text(
                '${p.name} (${p.address})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedPropertyId = val);
            }
          },
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
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

  // Khu vực chọn và tải ảnh phòng
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
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            child: Icon(Icons.add_a_photo_outlined, color: primaryColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thêm hình ảnh thực tế phòng',
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

  // Khung chọn trạng thái khả dụng của phòng
  Widget _buildStatusSelector() {
    final statuses = ['Còn trống', 'Đang cho thuê', 'Bảo trì'];

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
              fontSize: 12,
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
