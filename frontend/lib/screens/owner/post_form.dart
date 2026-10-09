import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PostFormScreen extends StatefulWidget {
  const PostFormScreen({super.key});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final List<String> amenities = [
    'Wifi',
    'Điều hòa',
    'Máy giặt',
    'Chỗ để xe',
    'Tủ lạnh',
    'Giờ giấc tự do',
    'An ninh 24/7',
  ];
  final List<String> selectedAmenities = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng tin cho thuê',
          style: TextStyle(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Áp dụng cho phòng nào
              _buildSectionTitle('Thông tin cơ bản'),
              _buildDropdownField('Chọn tòa nhà', [
                'Chung cư Mini Q7',
                'Dãy trọ Lê Văn Sỹ',
              ]),
              const SizedBox(height: 12),
              _buildDropdownField('Chọn phòng trống', [
                'Phòng 101',
                'Phòng 102',
              ]),

              const SizedBox(height: 24),

              // Hình ảnh
              _buildSectionTitle('Hình ảnh thực tế (Tối đa 6 ảnh)'),
              _buildImagePickerUI(),

              const SizedBox(height: 24),

              // Nội dung tin đăng
              _buildSectionTitle('Nội dung chi tiết'),
              _buildTextField(
                'Tiêu đề tin đăng',
                'VD: Cho thuê phòng trọ có gác xép mới xây...',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Mô tả chi tiết',
                'Mô tả về không gian, tiện ích xung quanh, yêu cầu người thuê...',
                maxLines: 5,
              ),

              const SizedBox(height: 24),

              // Giá cả
              _buildSectionTitle('Chi phí thuê'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Giá thuê (VNĐ/tháng)',
                      'VD: 3.500.000',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      'Tiền cọc (VNĐ)',
                      'VD: 3.500.000',
                      isNumber: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Tiện ích nổi bật
              _buildSectionTitle('Tiện ích có sẵn'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: amenities.map((item) {
                  final isSelected = selectedAmenities.contains(item);
                  return FilterChip(
                    label: Text(item),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen.withOpacity(0.1),
                    checkmarkColor: AppColors.primaryGreen,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : Colors.grey[300]!,
                      ),
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedAmenities.add(item);
                        } else {
                          selectedAmenities.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'title': 'Cho thuê phòng mới full tiện nghi',
                    'room': 'Phòng 102 - Chung cư Mini Q7',
                    'price': '3.800.000đ/tháng',
                    'views': 0,
                    'likes': 0,
                    'date': 'Hôm nay',
                    'status': 'draft',
                    'image': 'frontend/assets/images/anhPhongDemo.jpg',
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'LƯU NHÁP',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, {
                    'title': 'Cho thuê phòng mới full tiện nghi',
                    'room': 'Phòng 102 - Chung cư Mini Q7',
                    'price': '3.800.000đ/tháng',
                    'views': 0,
                    'likes': 0,
                    'date': 'Vừa gửi',
                    'status': 'pending',
                    'submitNote':
                        'Đang chờ Quản trị viên duyệt (tiêu chuẩn PCCC & giá)',
                    'image': 'frontend/assets/images/anhPhongDemo.jpg',
                  });
                },
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                label: const Text(
                  'GỬI ADMIN DUYỆT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGreen),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {},
    );
  }

  Widget _buildImagePickerUI() {
    return Row(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryGreen,
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, color: AppColors.primaryGreen, size: 28),
              const SizedBox(height: 8),
              Text(
                'Thêm ảnh',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100,
            height: 100,
            color: Colors.grey[200],
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'frontend/assets/images/anhPhongDemo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image, color: Colors.grey),
                ),
                const Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
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
