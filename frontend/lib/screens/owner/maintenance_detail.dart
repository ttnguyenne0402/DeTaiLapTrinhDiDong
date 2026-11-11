import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/app_colors.dart';

class MaintenanceDetailScreen extends StatefulWidget {
  final String issueId; // Bắt buộc phải có ID truyền vào

  const MaintenanceDetailScreen({super.key, required this.issueId});

  @override
  State<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  Map<String, dynamic>? _detailData;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  int _costPayerGroup = 0; // 0: chủ nhà chịu, 1: trừ vào cọc/khách
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDetail(); // Lấy dữ liệu ngay lập tức bằng ID có sẵn
  }

  @override
  void dispose() {
    _costController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  Future<void> _fetchDetail() async {
    final url = 'http://10.0.2.2:5093/api/OwnerMaintenance/${widget.issueId}';
    print("ĐANG GỌI API: $url"); // Log ra console để debug

    final client = _getCustomClient();
    try {
      final response = await client.get(Uri.parse(url));
      print("STATUS CODE: ${response.statusCode}");

      if (response.statusCode == 200) {
        setState(() {
          _detailData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Lỗi Server (${response.statusCode}): ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối ứng dụng: $e';
        _isLoading = false;
      });
    } finally {
      client.close();
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isSubmitting = true);

    String? ownerNoteFinal;
    if (newStatus == 'completed') {
      final payer = _costPayerGroup == 0 ? "Chủ nhà chịu" : "Trừ cọc/Khách trả";
      final cost = _costController.text.isNotEmpty ? _costController.text : "0";
      ownerNoteFinal = "Chi phí: $cost đ | Phân bổ: $payer | Ghi chú: ${_noteController.text}";
    }

    final url = 'http://10.0.2.2:5093/api/OwnerMaintenance/${widget.issueId}/process';
    final client = _getCustomClient();

    try {
      final response = await client.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "status": newStatus,
          "ownerNote": ownerNoteFinal
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: AppColors.primaryGreen),
        );
        _fetchDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối mạng'), backgroundColor: Colors.red),
      );
    } finally {
      client.close();
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // NẾU CÓ LỖI, SẼ HIỆN RÕ DÒNG CHỮ LỖI RA MÀN HÌNH ĐỂ DEBUG
    if (_errorMessage.isNotEmpty || _detailData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi tải dữ liệu')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Dữ liệu trống (Null)',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final status = _detailData!['status'] ?? 'pending';
    final isCompleted = status == 'completed';

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chi Tiết Sửa Chữa', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeaderInfoCard(),
                    const SizedBox(height: 16),
                    _buildTenantInfoCard(),
                    const SizedBox(height: 16),
                    if (_detailData!['image'] != null && _detailData!['image'].toString().isNotEmpty) ...[
                      _buildImagesCard(),
                      const SizedBox(height: 16),
                    ],
                    if (status == 'processing') _buildCostAndPayerCard(),
                    if (isCompleted && _detailData!['ownerNote'] != null) _buildCompletedNoteCard(),
                    const SizedBox(height: 16),
                    _buildTimelineCard(status),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (!isCompleted) _buildBottomActionButtons(status),
              const SizedBox(height: 10)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfoCard() {
    final status = _detailData!['status'] ?? 'pending';
    String statusText = 'Chờ tiếp nhận';
    Color statusColor = AppColors.textSecondary;
    if (status == 'processing') { statusText = 'Đang xử lý'; statusColor = AppColors.warningOrange; }
    if (status == 'completed') { statusText = 'Hoàn thành'; statusColor = AppColors.primaryGreen; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${_detailData!['id'].toString().toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_detailData!['title'] ?? 'Sự cố', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                _detailData!['createdAt'] != null ? _detailData!['createdAt'].toString().substring(0, 10) : '',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MÔ TẢ SỰ CỐ TỪ KHÁCH:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  _detailData!['description'] ?? 'Không có mô tả',
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.home_work, color: AppColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_detailData!['roomName'] ?? 'Phòng', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(_detailData!['propertyName'] ?? 'Khu trọ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderLight),
          Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: AppColors.lightGreen, child: Icon(Icons.person, color: AppColors.primaryGreen, size: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_detailData!['tenantName'] ?? 'Khách', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(_detailData!['tenantPhone'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_library, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('Hình ảnh hiện trường', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(12)),
            child: const Center(
              child: Text('Hình ảnh (Đã tải lên)', style: TextStyle(color: AppColors.primaryGreen)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCostAndPayerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('Nhập chi phí & Phân bổ (Để Nghiệm thu)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _costController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Chi phí thực tế (đ)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Phân bổ chi trả:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<int>(
                  value: 0, groupValue: _costPayerGroup,
                  title: const Text('Chủ nhà', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero, activeColor: AppColors.primaryGreen,
                  onChanged: (val) => setState(() => _costPayerGroup = val!),
                ),
              ),
              Expanded(
                child: RadioListTile<int>(
                  value: 1, groupValue: _costPayerGroup,
                  title: const Text('Trừ khách', style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero, activeColor: AppColors.primaryGreen,
                  onChanged: (val) => setState(() => _costPayerGroup = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Ghi chú vật tư / hạng mục sửa',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedNoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.lightGreen.withOpacity(0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryGreen.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('Ghi chú nghiệm thu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_detailData!['ownerNote'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(String status) {
    bool isProcessing = status == 'processing' || status == 'completed';
    bool isCompleted = status == 'completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('Lịch sử tiến trình', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(title: 'Khách báo sự cố', subtitle: 'Hệ thống ghi nhận', isDone: true),
          _buildTimelineItem(title: 'Chủ trọ tiếp nhận', subtitle: 'Chuyển sang Đang xử lý', isDone: isProcessing),
          _buildTimelineItem(title: 'Nghiệm thu & Hoàn thành', subtitle: 'Lưu chi phí & Đóng', isDone: isCompleted, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required String title, required String subtitle, required bool isDone, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: isDone ? AppColors.primaryGreen : AppColors.textSecondary),
            if (!isLast) Container(width: 2, height: 30, color: AppColors.borderLight),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDone ? AppColors.textPrimary : AppColors.textSecondary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons(String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: AppColors.cardSurface, border: Border(top: BorderSide(color: AppColors.borderLight))),
      child: Row(
        children: [
          if (status == 'pending') ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _updateStatus('processing'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Tiếp nhận sửa chữa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
          if (status == 'processing') ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _updateStatus('completed'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: AppColors.accentYellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                    : const Text('Lưu chi phí & Nghiệm thu', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}