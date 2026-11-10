import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/local/sqlite_helper.dart';
import '../../services/owner/post_service.dart';
import '../../services/owner/room_service.dart';

class PostFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const PostFormScreen({super.key, this.initialData});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;

  List<RoomModel> _rooms = [];
  String? _selectedRoomId;
  String _selectedBuildingName = 'Tòa nhà';
  String _selectedRoomName = 'Phòng';
  bool _isLoading = false;
  bool _loadingRooms = true;

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
  void initState() {
    super.initState();
    final item = widget.initialData;

    _titleController = TextEditingController(text: item?['title'] ?? '');
    _descController = TextEditingController(text: item?['description'] ?? '');

    String priceStr = '';
    if (item != null) {
      if (item['rawPrice'] != null && item['rawPrice'] is num && (item['rawPrice'] as num) > 0) {
        priceStr = '${(item['rawPrice'] as num).toInt()}';
      } else if (item['price'] != null) {
        priceStr = item['price']
            .toString()
            .replaceAll('.', '')
            .replaceAll(',', '')
            .replaceAll('đ', '')
            .replaceAll('/tháng', '')
            .trim();
      }
      _selectedRoomId = item['roomId'];

      final existingAmenities = item['amenities'];
      if (existingAmenities is List) {
        for (var a in existingAmenities) {
          final str = a.toString().trim();
          if (str.isNotEmpty && !selectedAmenities.contains(str)) {
            selectedAmenities.add(str);
          }
        }
      } else if (existingAmenities is String && existingAmenities.isNotEmpty) {
        for (var a in existingAmenities.split(',')) {
          final str = a.trim();
          if (str.isNotEmpty && !selectedAmenities.contains(str)) {
            selectedAmenities.add(str);
          }
        }
      }
    } else {
      selectedAmenities.addAll(['Wifi', 'Chỗ để xe']);
    }
    _priceController = TextEditingController(text: priceStr);

    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final list = await RoomService.fetchRooms('USER_OWNER_01', status: 'all');
      if (mounted) {
        setState(() {
          _rooms = list;
          if (_rooms.isNotEmpty) {
            if (_selectedRoomId != null) {
              final found = _rooms.firstWhere(
                (r) => r.id == _selectedRoomId,
                orElse: () => _rooms.first,
              );
              _selectedRoomId = found.id;
              _selectedBuildingName = found.propertyName;
              _selectedRoomName = found.name;
            } else {
              final first = _rooms.first;
              _selectedRoomId = first.id;
              _selectedBuildingName = first.propertyName;
              _selectedRoomName = first.name;
              if (_priceController.text.isEmpty && first.price > 0) {
                _priceController.text = '${first.price.toInt()}';
              }
              if (_titleController.text.isEmpty) {
                _titleController.text = 'Cho thuê ${first.name} - ${first.propertyName}';
              }
            }
          }
          _loadingRooms = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách phòng: $e');
      if (mounted) {
        setState(() => _loadingRooms = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Chỉnh sửa tin đăng' : 'Đăng tin cho thuê',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chọn phòng áp dụng
              _buildSectionTitle('Chọn phòng cần đăng tin'),
              const SizedBox(height: 8),
              _buildRoomDropdown(),

              const SizedBox(height: 24),

              // Hình ảnh
              _buildSectionTitle('Hình ảnh thực tế (Tối đa 6 ảnh)'),
              const SizedBox(height: 8),
              _buildImagePickerUI(),

              const SizedBox(height: 24),

              // Nội dung tin đăng
              _buildSectionTitle('Nội dung chi tiết'),
              const SizedBox(height: 8),
              _buildTextField(
                'Tiêu đề tin đăng',
                'VD: Cho thuê phòng trọ có gác xép mới xây...',
                controller: _titleController,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Giá thuê (đ/tháng)',
                'VD: 3500000',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Mô tả phòng',
                'Mô tả vị trí, nội thất, tiện ích xung quanh, giờ giấc...',
                controller: _descController,
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              // Tiện ích
              _buildSectionTitle('Tiện ích có sẵn'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: amenities.map((item) {
                  final isSelected = selectedAmenities.contains(item);
                  return FilterChip(
                    label: Text(item),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryGreen.withValues(alpha: 0.15),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: isEdit ? _buildEditBottomBar() : _buildCreateBottomBar(),
      ),
    );
  }

  // Thanh nút bấm khi Chỉnh sửa tin
  Widget _buildEditBottomBar() {
    final item = widget.initialData!;
    final bool isSqlite = item['isSqlite'] == true;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                if (_titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tiêu đề tin đăng')),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                setState(() => _isLoading = true);

                bool success = false;
                if (isSqlite && item['sqliteId'] != null) {
                  await SqliteHelper.instance.updateDraftPost(item['sqliteId'], {
                    'room_id': _selectedRoomId,
                    'building_name': _selectedBuildingName,
                    'room_name': _selectedRoomName,
                    'title': _titleController.text.trim(),
                    'description': _descController.text.trim(),
                    'price': _priceController.text.trim().isNotEmpty
                        ? '${_priceController.text.trim()}đ/tháng'
                        : 'Thỏa thuận',
                    'amenities': selectedAmenities.join(','),
                  });
                  success = true;
                } else {
                  final cleanPrice = double.tryParse(_priceController.text
                          .replaceAll('.', '')
                          .replaceAll(',', '')
                          .trim()) ??
                      0;

                  success = await PostService.updatePost(item['id'].toString(), {
                    'roomId': _selectedRoomId,
                    'title': _titleController.text.trim(),
                    'description': _descController.text.trim(),
                    'price': cleanPrice,
                    'amenities': selectedAmenities,
                    'status': item['status'] ?? 'pending',
                  });
                }

                if (!mounted) return;
                setState(() => _isLoading = false);

                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật tin đăng thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  navigator.pop(true);
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật tin đăng thất bại'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'CẬP NHẬT TIN ĐĂNG',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // Thanh nút bấm khi Tạo tin mới (Lưu nháp SQLite hoặc Gửi duyệt)
  Widget _buildCreateBottomBar() {
    return Row(
      children: [
        // Nút 1: Lưu nháp vào SQLite
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tiêu đề trước khi lưu nháp')),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    setState(() => _isLoading = true);

                    // LƯU BẢN NHÁP VÀO CSDL SQLITE CỦA THIẾT BỊ
                    await SqliteHelper.instance.insertDraftPost({
                      'room_id': _selectedRoomId,
                      'building_name': _selectedBuildingName,
                      'room_name': _selectedRoomName,
                      'title': _titleController.text.trim(),
                      'description': _descController.text.trim(),
                      'price': _priceController.text.trim().isNotEmpty
                          ? '${_priceController.text.trim()}đ/tháng'
                          : 'Thỏa thuận',
                      'amenities': selectedAmenities.join(','),
                      'image': 'frontend/assets/images/anhPhongDemo.jpg',
                      'created_at': DateTime.now().toString().substring(0, 10),
                    });

                    if (!mounted) return;
                    setState(() => _isLoading = false);

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Lưu bản nháp thành công'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                    navigator.pop(true);
                  },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'LƯU NHÁP (SQLITE)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Nút 2: Gửi duyệt lên SQL Server
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tiêu đề tin đăng')),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    setState(() => _isLoading = true);

                    final targetRoomId = _selectedRoomId ?? (_rooms.isNotEmpty ? _rooms.first.id : 'room_101');

                    final cleanPrice = double.tryParse(_priceController.text
                            .replaceAll('.', '')
                            .replaceAll(',', '')
                            .trim()) ??
                        0;

                    // GỬI TIN ĐĂNG LÊN MÁY CHỦ BACKEND (LƯU VÀO SQL SERVER)
                    final success = await PostService.createPost({
                      'roomId': targetRoomId,
                      'title': _titleController.text.trim(),
                      'description': _descController.text.trim(),
                      'price': cleanPrice,
                      'amenities': selectedAmenities,
                      'status': 'pending',
                      'submitNote': 'Gửi duyệt từ ứng dụng di động',
                      'images': ['frontend/assets/images/anhPhongDemo.jpg'],
                    });

                    if (!mounted) return;
                    setState(() => _isLoading = false);

                    if (success) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Tạo tin đăng thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      navigator.pop(true);
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Tạo tin đăng thất bại. Vui lòng thử lại!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            icon: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 16,
            ),
            label: const Text(
              'GỬI DUYỆT (SQL SERVER)',
              style: TextStyle(
                fontSize: 12,
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
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomDropdown() {
    if (_loadingRooms) {
      return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
    }

    if (_rooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Text('Chưa có phòng nào. Vui lòng tạo phòng trước!'),
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
          value: _selectedRoomId,
          items: _rooms.map((r) {
            return DropdownMenuItem<String>(
              value: r.id,
              child: Text(
                '${r.name} - ${r.propertyName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              final found = _rooms.firstWhere((r) => r.id == val);
              setState(() {
                _selectedRoomId = val;
                _selectedBuildingName = found.propertyName;
                _selectedRoomName = found.name;
                _priceController.text = found.price > 0 ? '${found.price.toInt()}' : _priceController.text;
                if (widget.initialData == null) {
                  _titleController.text = 'Cho thuê ${found.name} - ${found.propertyName}';
                }
              });
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

  Widget _buildTextField(
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
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
