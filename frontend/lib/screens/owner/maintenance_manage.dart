import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../../services/auth_storage.dart';
import 'maintenance_detail.dart';
class MaintenanceManageScreen extends StatefulWidget {
  const MaintenanceManageScreen({super.key});

  @override
  State<MaintenanceManageScreen> createState() =>
      _MaintenanceManageScreenState();
}

class _MaintenanceManageScreenState
    extends State<MaintenanceManageScreen> {
  // --- BIẾN MỚI THÊM ĐỂ GỌI API ---
  List<dynamic> _maintenanceRequests = [];
  bool _isLoading = true;
  String _ownerId = '';

  @override
  void initState() {
    super.initState();
    _loadOwnerData(); // Gọi hàm load data khi vừa mở trang
  }

  // Khởi tạo Custom Client bỏ qua SSL
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  // Lấy Owner ID từ bộ nhớ và gọi API
  Future<void> _loadOwnerData() async {
    final userId = await AuthStorage.getUserId();
    if (mounted) {
      setState(() {
        _ownerId = userId ?? ''; // Có thể gán cứng 'OWNER01' để test nhanh
      });
      await _fetchMaintenanceRequests();
    }
  }

  // Gọi API lấy danh sách sự cố của Chủ nhà
  Future<void> _fetchMaintenanceRequests() async {
    setState(() {
      _isLoading = true;
    });

    final url = 'http://10.0.2.2:5093/api/OwnerMaintenance/owner/$_ownerId';
    final client = _getCustomClient();

    try {
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _maintenanceRequests = data;
            _isLoading = false;
          });
        }
      } else {
        print("Lỗi server: ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      if (mounted) setState(() => _isLoading = false);
    } finally {
      client.close();
    }
  }
  // --- KẾT THÚC PHẦN THÊM ---
  int _selectedFilterIndex = 0;

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;

  final List<String> _filters = [
    'Tất cả (5)',
    'Chờ xử lý (2)',
    'Đang sửa (1)',
    'Đã xong (2)',
  ];

  // hàm chọn nguồn ảnh
  void _showImageSourcePicker(StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primaryGreen,
                ),
                title: const Text('Chụp ảnh hiện trạng'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera, setModalState);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primaryGreen,
                ),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery, setModalState);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // hàm chụp ảnh hoặc chọn ảnh từ thư viện
  Future<void> _pickImage(
      ImageSource source,
      StateSetter setModalState,
      ) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (image != null && mounted) {
        setModalState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: $e'),
        ),
      );
    }
  }

  // hàm mở modal bottom sheet tạo sự cố dành cho chủ trọ ghi nhận tại chỗ
  void _showCreateIssueBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    String selectedProperty = 'Khu Trọ Tân Bình 1';
    String selectedRoom = 'Khu vực chung';

    _selectedImage = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // tiêu đề modal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chủ trọ ghi nhận sự cố',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // dropdown chọn khu trọ
                    DropdownButtonFormField<String>(
                      value: selectedProperty,
                      decoration: InputDecoration(
                        labelText: 'Khu trọ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        'Khu Trọ Tân Bình 1',
                        'Khu Trọ Bình Thạnh 2',
                      ].map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedProperty = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // dropdown chọn phòng hoặc khu vực chung
                    DropdownButtonFormField<String>(
                      value: selectedRoom,
                      decoration: InputDecoration(
                        labelText: 'Vị trí / Phòng',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        'Khu vực chung',
                        'Phòng 101',
                        'Phòng 201',
                        'Phòng 302',
                      ].map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedRoom = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // ô nhập tiêu đề sự cố
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText:
                        'Tiêu đề sự cố (ví dụ: Hỏng ổ khóa cổng)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ô nhập mô tả chi tiết
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Mô tả ngắn (không bắt buộc)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // nút chụp ảnh hoặc chọn ảnh
                    OutlinedButton.icon(
                      onPressed: () {
                        _showImageSourcePicker(setModalState);
                      },
                      icon: const Icon(
                        Icons.camera_alt,
                        color: AppColors.primaryGreen,
                      ),
                      label: const Text(
                        'Chụp ảnh hiện trạng',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          48,
                        ),
                        side: const BorderSide(
                          color: AppColors.primaryGreen,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // hiển thị ảnh đã chọn
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImage!.path),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              _selectedImage = null;
                            });
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Xóa ảnh',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // nút xác nhận lưu sự cố
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng nhập tiêu đề sự cố',
                                ),
                              ),
                            );
                            return;
                          }

                          // hiện tại lưu sự cố chưa kết nối database/api
                          Navigator.pop(context);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã ghi nhận thông tin sự cố',
                              ),
                            ),
                          );

                          titleController.dispose();
                          descriptionController.dispose();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Lưu sự cố & Tiến hành sửa',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      drawer: OwnerDrawer(
        currentRoute: 'maintenance',
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Quản lý sửa chữa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 16,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // phần thân chứa danh sách sự cố với góc bo 24px
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                    : RefreshIndicator(
                  onRefresh: _fetchMaintenanceRequests,
                  color: AppColors.primaryGreen,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildFilterChips(),
                      const SizedBox(height: 16),

                      // --- ĐỔ DỮ LIỆU TỪ API VÀO ĐÂY ---
                      if (_maintenanceRequests.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('Không có sự cố nào.', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      else
                        ..._maintenanceRequests.map((request) {
                          final status = request['status'];

                          // Logic Lọc (Filter)
                          if (_selectedFilterIndex == 1 && status != 'pending') return const SizedBox.shrink();
                          if (_selectedFilterIndex == 2 && status != 'processing') return const SizedBox.shrink();
                          if (_selectedFilterIndex == 3 && status != 'completed') return const SizedBox.shrink();

                          final isCompleted = status == 'completed';
                          final isPending = status == 'pending';

                          return Column(
                            children: [
                              _buildMaintenanceCard(
                                propertyName: request['propertyName'] ?? 'Khu trọ',
                                room: request['roomName'] ?? 'Phòng',
                                floor: '', // Tạm ẩn tầng
                                tenantName: request['tenantName'] ?? 'Khách thuê',
                                tenantPhone: request['tenantPhone'] ?? '',
                                title: request['title'] ?? 'Sự cố',
                                description: request['description'] ?? '',
                                timeAgo: request['createdAt'] != null
                                    ? request['createdAt'].toString().substring(0, 10)
                                    : '',
                                imageCount: request['image'] != null ? 1 : 0,

                                // Hiển thị Priority
                                priorityText: request['priority'] == 'urgent' ? 'Khẩn cấp'
                                    : request['priority'] == 'high' ? 'Ưu tiên cao'
                                    : 'Bình thường',
                                priorityColor: request['priority'] == 'urgent' ? Colors.red
                                    : AppColors.warningOrange,

                                // Hiển thị Status
                                statusText: isPending ? 'Chờ tiếp nhận'
                                    : isCompleted ? 'Đã hoàn thành'
                                    : 'Đang xử lý',
                                statusColor: isPending ? AppColors.textSecondary
                                    : isCompleted ? AppColors.primaryGreen
                                    : AppColors.warningOrange,

                                costText: isCompleted ? 'Đã nghiệm thu' : null,

                                actionButtons: isCompleted ? const SizedBox.shrink() : Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.phone, size: 16, color: AppColors.primaryGreen),
                                        label: const Text('Gọi khách', style: TextStyle(color: AppColors.primaryGreen)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          // DÙNG MATERIAL PAGE ROUTE ĐỂ TRUYỀN ID CHẮC CHẮN 100%
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MaintenanceDetailScreen(
                                                issueId: request['id'].toString(), // TRUYỀN ID VÀO ĐÂY
                                              ),
                                            ),
                                          );

                                          _fetchMaintenanceRequests();
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                                        child: Text(
                                          isPending ? 'Tiếp nhận' : 'Chi tiết',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
                ),
            ),
          ),
          )
        ],
      ),

      // nút fab mở modal thêm sự cố mới cho chủ trọ
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateIssueBottomSheet(context),
        backgroundColor: AppColors.accentYellow,
        icon: const Icon(
          Icons.add,
          color: AppColors.textPrimary,
        ),
        label: const Text(
          'Tạo sự cố mới',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // widget thẻ tổng quan chỉ số sự cố và chi phí
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'THÁNG 08/2024\nTổng quan sự cố kỹ thuật',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business_center,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng sự cố',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '5 ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'vụ việc',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dự toán chi phí',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '1.450.000 đ',
                        style: TextStyle(
                          color: AppColors.accentYellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // widget ô tìm kiếm sự cố
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo khu trọ, số phòng, tên khách...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Icon(Icons.tune, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  // widget thanh cuộn danh sách chip lọc trạng thái
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(_filters[index]),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              backgroundColor: AppColors.cardSurface,
              selectedColor: AppColors.primaryGreen,
              onSelected: (bool selected) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.borderLight,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // widget khung hiển thị chi tiết thẻ sự cố
  Widget _buildMaintenanceCard({
    required String propertyName,
    required String room,
    required String floor,
    required String tenantName,
    required String tenantPhone,
    required String title,
    required String description,
    required String timeAgo,
    required int imageCount,
    required String priorityText,
    required Color priorityColor,
    required String statusText,
    required Color statusColor,
    required Widget actionButtons,
    String? costText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // tiêu đề thẻ: tên khu trọ, số phòng, tên khách thuê và nhãn trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // tên khu trọ
                    Row(
                      children: [
                        const Icon(
                          Icons.location_city,
                          size: 14,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            propertyName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          room,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $floor',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$tenantName • $tenantPhone',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priorityText,
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(
            height: 20,
            color: AppColors.borderLight,
          ),

          // nội dung sự cố kèm ảnh đính kèm
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageCount > 0) ...[
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // dòng hiển thị chi phí sửa chữa nếu đã hoàn thành
          if (costText != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                costText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],

          // các nút bấm hành động phía dưới thẻ
          if (actionButtons is! SizedBox) ...[
            const SizedBox(height: 16),
            actionButtons,
          ],
        ],
      ),
    );
  }
}