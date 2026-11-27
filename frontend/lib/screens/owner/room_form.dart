import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/room_service.dart';
import '../../services/owner/property_service.dart';
import '../../services/owner/amenity_service.dart';
import '../../services/owner/service_service.dart';
import '../../services/auth_storage.dart';
import '../../widgets/tenant/open_street_map_widget.dart';
import 'contract_form.dart';
import 'contracts_manage.dart';

// Màn hình biểu mẫu thêm mới hoặc chỉnh sửa phòng trọ
class RoomFormScreen extends StatefulWidget {
  final RoomModel? initialData;
  final String? initialPropertyId;
  final String? initialPropertyName;

  const RoomFormScreen({
    super.key,
    this.initialData,
    this.initialPropertyId,
    this.initialPropertyName,
  });

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final Color primaryColor = const Color(0xFF1B5E55);
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  late final TextEditingController _floorController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;

  List<PropertyModel> _properties = [];
  List<RoomModel> _existingRooms = [];
  List<AmenityModel> _availableAmenities = [];
  final List<String> _selectedAmenityIds = [];
  List<ServiceModel> _availableServices = [];
  final List<String> _selectedServiceIds = [];
  String? _selectedPropertyId;
  bool _isLoading = false;
  bool _loadingProperties = true;
  bool _loadingAmenities = true;
  bool _loadingServices = true;

  final List<String> _selectedImages = [];

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
      text: item?.floor != null ? '${item!.floor}' : '1',
    );
    _priceController = TextEditingController(
      text: (item != null && item.price > 0)
          ? _formatNumberDots('${item.price.toInt()}')
          : '',
    );
    _descController = TextEditingController(text: item?.description ?? '');

    if (item != null) {
      _selectedStatus = item.statusText;
      _selectedPropertyId = item.propertyId;
      if (item.images.isNotEmpty) {
        _selectedImages.add(item.images);
      }
      if (item.amenityIds.isNotEmpty) {
        _selectedAmenityIds.addAll(item.amenityIds);
      }
      if (item.serviceIds.isNotEmpty) {
        _selectedServiceIds.addAll(item.serviceIds);
      }
    } else if (widget.initialPropertyId != null &&
        widget.initialPropertyId!.isNotEmpty) {
      _selectedPropertyId = widget.initialPropertyId;
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final ownerId = await AuthStorage.getUserId() ?? 'USER_OWNER_01';
      final targetPropId = _selectedPropertyId ?? widget.initialPropertyId ?? widget.initialData?.propertyId;
      final results = await Future.wait([
        PropertyService.fetchProperties(ownerId, 'all'),
        RoomService.fetchRooms(ownerId, status: 'all'),
        AmenityManagementService.fetchAmenities(ownerId),
        ServiceManagementService.fetchServices(ownerId, propertyId: targetPropId),
      ]);
      if (mounted) {
        final props = results[0] as List<PropertyModel>;
        final rooms = results[1] as List<RoomModel>;
        final amenities = results[2] as List<AmenityModel>;
        final servicesList = results[3] as List<ServiceModel>;
        setState(() {
          _properties = props;
          _existingRooms = rooms;
          _availableAmenities = amenities;
          _availableServices = servicesList;

          // Loại bỏ các ID dịch vụ bắt buộc (nếu lỡ được gán vào _selectedServiceIds)
          final mandatoryIds = servicesList.where((s) => s.isMandatory).map((s) => s.id).toSet();
          _selectedServiceIds.removeWhere((id) => mandatoryIds.contains(id));

          // Nếu đang sửa phòng và danh sách tiện ích của phòng trước đó có tên tiện ích
          if (widget.initialData != null && _selectedAmenityIds.isEmpty && widget.initialData!.amenities.isNotEmpty) {
            for (final aName in widget.initialData!.amenities) {
              final matchedList = amenities.where(
                (am) => am.name.trim().toLowerCase() == aName.trim().toLowerCase(),
              );
              if (matchedList.isNotEmpty) {
                final matched = matchedList.first;
                if (!_selectedAmenityIds.contains(matched.id)) {
                  _selectedAmenityIds.add(matched.id);
                }
              }
            }
          }

          // Khôi phục các dịch vụ theo nhu cầu đã lưu nếu có (chỉ nhận dịch vụ tùy chọn / không bắt buộc)
          if (widget.initialData != null && _selectedServiceIds.isEmpty && widget.initialData!.services.isNotEmpty) {
            for (final sName in widget.initialData!.services) {
              final matched = servicesList.where(
                (s) => !s.isMandatory && s.name.trim().toLowerCase() == sName.trim().toLowerCase(),
              );
              if (matched.isNotEmpty && !_selectedServiceIds.contains(matched.first.id)) {
                _selectedServiceIds.add(matched.first.id);
              }
            }
          }

          if (_selectedPropertyId != null) {
            final match = _properties.where(
              (p) => p.id.toLowerCase() == _selectedPropertyId!.toLowerCase(),
            );
            if (match.isNotEmpty) {
              _selectedPropertyId = match.first.id;
            } else if (_properties.isNotEmpty) {
              _selectedPropertyId = _properties.first.id;
            }
          } else if (_properties.isNotEmpty) {
            _selectedPropertyId = _properties.first.id;
          }
          _loadingProperties = false;
          _loadingAmenities = false;
          _loadingServices = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách tòa nhà, phòng, tiện ích & dịch vụ: $e');
      if (mounted) {
        setState(() {
          _loadingProperties = false;
          _loadingAmenities = false;
          _loadingServices = false;
        });
      }
    }
  }

  // Tải lại bảng dịch vụ theo nhu cầu khi chủ trọ đổi khu trọ khác
  Future<void> _loadServicesForProperty(String? propId) async {
    setState(() => _loadingServices = true);
    try {
      final ownerId = await AuthStorage.getUserId() ?? 'USER_OWNER_01';
      final servicesList = await ServiceManagementService.fetchServices(ownerId, propertyId: propId);
      if (mounted) {
        setState(() {
          _availableServices = servicesList;
          _loadingServices = false;
          // Loại bỏ ID dịch vụ bắt buộc (nếu có)
          final mandatoryIds = servicesList.where((s) => s.isMandatory).map((s) => s.id).toSet();
          _selectedServiceIds.removeWhere((id) => mandatoryIds.contains(id));
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dịch vụ cho khu trọ $propId: $e');
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  String _formatNumberDots(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    final numVal = int.tryParse(digits);
    if (numVal == null || numVal <= 0) return '';
    return numVal.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => '.',
        );
  }

  // Chuẩn hóa tên phòng để kiểm tra trùng không phân biệt hoa thường (vd "Phòng 101" == "phòng 101" == "101")
  String _normalizeRoomCode(String input) {
    var s = input.trim().toLowerCase();
    if (s.startsWith('phòng ')) {
      s = s.substring(6).trim();
    } else if (s.startsWith('phong ')) {
      s = s.substring(6).trim();
    }
    return s;
  }

  // Chọn ảnh từ Camera hoặc Thư viện
  Future<void> _showImageSourceSheet() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 5 ảnh cho mỗi phòng')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn hình ảnh phòng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: primaryColor),
                title: const Text('Chụp ảnh từ Camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: primaryColor),
                title: const Text('Chọn ảnh từ Thư viện (Gallery)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() {
          _selectedImages.insert(0, file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở Camera: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty && mounted) {
        setState(() {
          for (final f in files) {
            if (_selectedImages.length < 5) {
              _selectedImages.add(f.path);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở Thư viện ảnh: $e')),
        );
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
                        _buildSectionTitle(
                          (widget.initialPropertyId != null &&
                                  widget.initialPropertyId!.isNotEmpty)
                              ? 'Tòa nhà / Bất động sản trực thuộc'
                              : 'Chọn Tòa nhà / Bất động sản',
                        ),
                        const SizedBox(height: 8),
                        _buildPropertyDropdown(),
                        const SizedBox(height: 10),
                        _buildPropertyLocationPreview(),
                        const SizedBox(height: 20),

                        // Tải ảnh thực tế phòng (Từ Gallery hoặc Camera)
                        _buildSectionTitle('Hình ảnh phòng (Từ Thư viện / Camera)'),
                        const SizedBox(height: 8),
                        _buildImagePickerSection(),
                        const SizedBox(height: 20),

                        // Nhập thông tin cơ bản
                        _buildSectionTitle('Thông tin cơ bản'),
                        const SizedBox(height: 8),
                        _buildCardGroup(
                          children: [
                            _buildTextField(
                              label: 'Tên / Số phòng',
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
                                    hint: '1',
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
                              hint: '4.000.000',
                              controller: _priceController,
                              suffixText: 'đ/tháng',
                              keyboardType: TextInputType.number,
                              icon: Icons.payments_outlined,
                              isCurrency: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Chọn trạng thái phòng
                        _buildSectionTitle('Trạng thái phòng'),
                        const SizedBox(height: 8),
                        _buildStatusSelector(),
                        const SizedBox(height: 20),

                        // Tiện ích riêng của phòng (Máy lạnh, Tủ lạnh, Gác lửng...)
                        _buildSectionTitle('Tiện ích riêng của phòng này'),
                        const SizedBox(height: 4),
                        const Text(
                          'Tích chọn tiện ích thực tế có sẵn trong phòng này (phòng có máy lạnh thì chọn máy lạnh, phòng không có thì bỏ trống).',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        _buildRoomAmenitiesSection(),
                        const SizedBox(height: 20),

                        // Dịch vụ theo nhu cầu của phòng (Xe máy, Wifi, Dọn dẹp...)
                        _buildSectionTitle('Dịch vụ theo nhu cầu của phòng này'),
                        const SizedBox(height: 4),
                        const Text(
                          'Tích chọn dịch vụ tùy chọn mà phòng này có nhu cầu đăng ký sử dụng (phòng không dùng thì bỏ trống để không bị tính tiền). Các dịch vụ bắt buộc chung của khu trọ (như điện, nước, rác...) sẽ tự động được áp dụng khi lập hợp đồng.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        _buildRoomServicesSection(),
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
                                  final roomName = _nameController.text.trim();
                                  if (roomName.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng nhập tên phòng'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final targetPropId = (widget.initialPropertyId != null &&
                                          widget.initialPropertyId!.isNotEmpty)
                                      ? widget.initialPropertyId!
                                      : (_selectedPropertyId ??
                                          (_properties.isNotEmpty
                                              ? _properties.first.id
                                              : 'prop_01'));
                                  final targetFloor =
                                      int.tryParse(_floorController.text.trim()) ?? 1;

                                  // Kiểm tra trùng tên phòng trong cùng bất động sản (không phân biệt hoa/thường)
                                  final inputNorm = _normalizeRoomCode(roomName);
                                  final duplicate = _existingRooms.any((r) {
                                    if (isEdit &&
                                        r.id.toLowerCase() ==
                                            widget.initialData!.id.toLowerCase()) {
                                      return false;
                                    }
                                    final sameProp = r.propertyId.trim().toLowerCase() ==
                                        targetPropId.trim().toLowerCase();
                                    final sameName = r.name.trim().toLowerCase() ==
                                            roomName.toLowerCase() ||
                                        _normalizeRoomCode(r.name) == inputNorm;
                                    return sameProp && sameName;
                                  });

                                  if (duplicate) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Phòng "$roomName" đã tồn tại trong tòa nhà này! Vui lòng đặt tên khác.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  if (_selectedStatus == 'Đang cho thuê' &&
                                      widget.initialData?.statusText != 'Đang cho thuê') {
                                    _handleSelectRentedStatus();
                                    return;
                                  }

                                  if (_selectedStatus != 'Đang cho thuê' && _hasActiveContract()) {
                                    _handleBlockChangeFromRentedStatus(_selectedStatus);
                                    return;
                                  }

                                  final messenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);

                                  setState(() => _isLoading = true);

                                  final cleanPrice = _priceController.text
                                      .replaceAll('.', '')
                                      .replaceAll(',', '')
                                      .replaceAll(' ', '')
                                      .trim();

                                  final payload = {
                                    'propertyId': targetPropId,
                                    'name': roomName,
                                    'area': double.tryParse(_areaController.text.trim()) ?? 20.0,
                                    'floor': targetFloor,
                                    'price': double.tryParse(cleanPrice) ?? 3500000.0,
                                    'status': _selectedStatus == 'Còn trống'
                                        ? 'available'
                                        : (_selectedStatus == 'Đang cho thuê'
                                            ? 'rented'
                                            : 'maintenance'),
                                    'description': _descController.text.trim(),
                                    'images': _selectedImages.isNotEmpty
                                        ? _selectedImages.first
                                        : 'frontend/assets/images/anhPhongDemo.jpg',
                                    'amenityIds': _selectedAmenityIds,
                                    'serviceIds': _selectedServiceIds,
                                  };

                                  String? errMessage;
                                  if (isEdit) {
                                    errMessage = await RoomService.updateRoomWithMessage(
                                      widget.initialData!.id,
                                      payload,
                                    );
                                  } else {
                                    errMessage = await RoomService.createRoomWithMessage(
                                      payload,
                                    );
                                  }

                                  if (!mounted) return;
                                  setState(() => _isLoading = false);

                                  if (errMessage == null) {
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
                                        content: Text(errMessage),
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
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
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
    final bool isLocked = widget.initialPropertyId != null &&
        widget.initialPropertyId!.isNotEmpty;

    if (isLocked) {
      String propName = widget.initialPropertyName ?? '';
      String propAddress = '';
      final match = _properties.where(
        (p) => p.id.toLowerCase() == widget.initialPropertyId!.toLowerCase(),
      );
      if (match.isNotEmpty) {
        propName = match.first.name;
        propAddress = match.first.address;
      } else if (propName.isEmpty) {
        propName = 'Bất động sản hiện tại';
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.apartment, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    propName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (propAddress.isNotEmpty)
                    Text(
                      propAddress,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Đã chọn',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_loadingProperties) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      );
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
              _loadServicesForProperty(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPropertyLocationPreview() {
    final selected = _properties.where(
      (property) => property.id == _selectedPropertyId,
    );
    if (selected.isEmpty) return const SizedBox.shrink();

    final property = selected.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vị trí phòng sẽ theo dãy trọ đã chọn',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        OpenStreetMapWidget(
          address: property.address,
          latitude: property.latitude,
          longitude: property.longitude,
        ),
      ],
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
    bool isCurrency = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: isCurrency
          ? (val) {
              final formatted = _formatNumberDots(val);
              if (formatted != val) {
                controller.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            }
          : null,
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

  Widget _buildPreviewThumbnail(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    if (path.startsWith('frontend/') || path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.image, color: Colors.grey),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.image, color: Colors.grey),
    );
  }

  // Khu vực chọn ảnh phòng từ Gallery hoặc Camera
  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showImageSourceSheet,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
                style: BorderStyle.solid,
              ),
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
                  'Bấm để chọn ảnh từ Thư viện hoặc Chụp ảnh',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đã chọn ${_selectedImages.length}/5 ảnh',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final imgPath = _selectedImages[idx];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildPreviewThumbnail(imgPath),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(idx);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSelectRentedStatus() async {
    final isEdit = widget.initialData != null;
    if (!isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng lưu thông tin tạo phòng trước khi lập hợp đồng cho thuê!',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.description_outlined, color: primaryColor),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Lập hợp đồng thuê phòng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Để chuyển trạng thái phòng sang "Đang cho thuê", bạn cần tạo Hợp đồng thuê phòng cho người thuê.\n\nBạn có muốn chuyển sang màn hình Lập hợp đồng ngay bây giờ không?',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Làm hợp đồng ngay',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final contractCreated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => Contract_form(
            initialRoomId: widget.initialData!.id,
          ),
        ),
      );

      if (contractCreated == true && mounted) {
        setState(() {
          _selectedStatus = 'Đang cho thuê';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tạo hợp đồng thành công! Phòng đã được chuyển sang trạng thái Đang cho thuê.',
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  bool _hasActiveContract() {
    if (widget.initialData != null) {
      if (widget.initialData!.hasActiveContract) return true;
      if (widget.initialData!.statusText == 'Đang cho thuê' || widget.initialData!.isRented) {
        return true;
      }
    }
    return false;
  }

  void _handleBlockChangeFromRentedStatus(String targetStatus) {
    final contractCode = widget.initialData?.activeContractCode;
    final codeText = (contractCode != null && contractCode.isNotEmpty) ? ' (Mã HĐ: $contractCode)' : '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Hợp đồng còn hiệu lực',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Phòng này hiện đang có hợp đồng thuê còn hiệu lực$codeText.\n\nBạn chỉ có thể chuyển phòng sang trạng thái "$targetStatus" sau khi hợp đồng đã được Thanh lý hoặc Xóa khỏi hệ thống!',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Contracts_manager()),
              );
            },
            child: const Text('Xem hợp đồng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
                if (status == 'Đang cho thuê' && _selectedStatus != 'Đang cho thuê') {
                  _handleSelectRentedStatus();
                  return;
                }
                if (status != 'Đang cho thuê' && _hasActiveContract()) {
                  _handleBlockChangeFromRentedStatus(status);
                  return;
                }
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

  Widget _buildRoomAmenitiesSection() {
    if (_loadingAmenities) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_availableAmenities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          'Chưa có danh mục tiện ích trong hệ thống.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text(
                'Đã chọn ${_selectedAmenityIds.length} tiện ích',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableAmenities.map((amenity) {
              final isSelected = _selectedAmenityIds.contains(amenity.id);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getAmenityIcon(amenity.icon),
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amenity.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryGreen,
                backgroundColor: Colors.grey.shade100,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
                  ),
                ),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenityIds.add(amenity.id);
                    } else {
                      _selectedAmenityIds.remove(amenity.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'ac_unit':
        return Icons.ac_unit;
      case 'wifi':
        return Icons.wifi;
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
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'bed':
        return Icons.bed;
      case 'wc':
        return Icons.wc;
      default:
        return Icons.check_circle_outline;
    }
  }

  Widget _buildRoomServicesSection() {
    if (_loadingServices) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final displayServices = _availableServices.where((s) {
      // 1. Chỉ hiển thị các dịch vụ KHÔNG bắt buộc (theo nhu cầu của từng phòng)
      if (s.isMandatory) return false;

      // 2. Không hiển thị các dịch vụ điện/nước cơ bản (vì tính theo đồng hồ chỉ số)
      final name = s.name.toLowerCase();
      if (name.contains('điện') || name.contains('nước')) return false;

      // 3. Nếu dịch vụ này đang bị tắt ở khu trọ thì ẩn
      if (!s.status) return false;

      return true;
    }).toList();

    if (displayServices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          'Khu trọ này hiện chưa có dịch vụ tùy chọn theo nhu cầu nào (các dịch vụ bắt buộc chung như điện, nước, rác... sẽ tự động áp dụng khi lập hợp đồng).',
          style: TextStyle(fontSize: 12.5, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.room_service_outlined, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text(
                'Đã chọn ${_selectedServiceIds.length} dịch vụ sử dụng',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayServices.map((service) {
              final isSelected = _selectedServiceIds.contains(service.id);
              final priceText = service.priceFormatted.isNotEmpty ? service.priceFormatted : '${service.price.toInt()}đ';
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getServiceIcon(service.icon),
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${service.name} ($priceText/${service.unit})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryGreen,
                backgroundColor: Colors.grey.shade100,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
                  ),
                ),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedServiceIds.add(service.id);
                    } else {
                      _selectedServiceIds.remove(service.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String iconName) {
    switch (iconName.toLowerCase()) {
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
      case 'ac_unit':
        return Icons.ac_unit;
      default:
        return Icons.miscellaneous_services;
    }
  }
}
