import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../../services/auth_storage.dart';
import '../../core/constants/app_colors.dart';

class TenantMaintenanceRequestScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const TenantMaintenanceRequestScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<TenantMaintenanceRequestScreen> createState() =>
      _TenantMaintenanceRequestScreenState();
}

class _TenantMaintenanceRequestScreenState
    extends State<TenantMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedPriority = 'medium';

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  bool _isSubmitting = false;

  // Giả lập ID người thuê hiện tại
  String _currentTenantId = '';
  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  Future<void> _loadTenantData() async {
    final userId = await AuthStorage.getUserId();
    if (mounted) {
      setState(() {
        _currentTenantId = userId ?? '';
      });
    }
  }
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Khởi tạo Client bỏ qua SSL
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                title: const Text('Chụp ảnh hiện trạng', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryGreen),
                title: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải ảnh: $e')),
      );
    }
  }

  // Chuyển đổi File ảnh thành chuỗi Base64
  Future<String?> _imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("Lỗi chuyển đổi ảnh: $e");
      return null;
    }
  }

  Future<void> _submitRequest() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vui lòng cung cấp ít nhất 1 hình ảnh hiện trường!"),
            backgroundColor: AppColors.warningOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      // Chuyển ảnh thành Base64
      String? base64Image = await _imageToBase64(File(_selectedImage!.path));

      final requestData = {
        "roomId": widget.roomId,
        "tenantId": _currentTenantId,
        "title": _titleController.text.trim(),
        "description": _descriptionController.text.trim(),
        "priority": _selectedPriority,
        "image": base64Image, // Gửi chuỗi Base64
      };

      final client = _getCustomClient();
      try {
        final response = await client.post(
          Uri.parse('http://10.0.2.2:5093/api/maintenance'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(requestData),
        );

        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Gửi yêu cầu sửa chữa thành công!"),
                backgroundColor: AppColors.primaryGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          print("Lỗi server: ${response.body}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Gửi thất bại. Vui lòng thử lại."),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        print("Lỗi kết nối: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Không thể kết nối đến máy chủ."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        client.close();
        if (mounted) setState(() => _isSubmitting = false);
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yêu Cầu Sửa Chữa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildRoomInfoCard(),
                      const SizedBox(height: 24),
                      const Text(
                        "THÔNG TIN SỰ CỐ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('Tiêu đề sự cố *'),
                      TextFormField(
                        controller: _titleController,
                        decoration: _buildInputDecoration(
                          hint: 'Ví dụ: Hư ống nước, Hỏng bóng đèn...',
                          icon: Icons.title,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề sự cố';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Mức độ ưu tiên *'),
                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: _buildInputDecoration(
                          hint: 'Chọn mức độ',
                          icon: Icons.priority_high,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Thấp (Không gấp)')),
                          DropdownMenuItem(value: 'medium', child: Text('Bình thường')),
                          DropdownMenuItem(value: 'high', child: Text('Cao (Ảnh hưởng sinh hoạt)')),
                          DropdownMenuItem(
                              value: 'urgent',
                              child: Text('Khẩn cấp (Nguy hiểm/Tràn nước)',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPriority = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Mô tả chi tiết *'),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: _buildInputDecoration(
                          hint: 'Vui lòng mô tả chi tiết tình trạng...',
                          icon: null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mô tả sự cố';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "HÌNH ẢNH HIỆN TRƯỜNG *",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildImageUploadArea(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home_work, color: AppColors.primaryGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã phòng: ${widget.roomId}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.textSecondary, size: 20) : null,
      filled: true,
      fillColor: AppColors.cardSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildImageUploadArea() {
    return _selectedImage == null
        ? InkWell(
      onTap: _showImageSourcePicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.lightGreen.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGreen, width: 1, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primaryGreen),
            SizedBox(height: 12),
            Text(
              'Nhấn để chụp hoặc chọn ảnh',
              style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Giúp chủ nhà chuẩn bị đúng dụng cụ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    )
        : Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(_selectedImage!.path),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedImage = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text(
              'GỬI YÊU CẦU SỬA CHỮA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}