import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../services/auth_storage.dart';
import 'package:intl/intl.dart';

class TenantMaintenanceHistoryScreen extends StatefulWidget {
  const TenantMaintenanceHistoryScreen({super.key});

  @override
  State<TenantMaintenanceHistoryScreen> createState() => _TenantMaintenanceHistoryScreenState();
}

class _TenantMaintenanceHistoryScreenState extends State<TenantMaintenanceHistoryScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String _tenantId = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final userId = await AuthStorage.getUserId();
    if (mounted) {
      setState(() {
        _tenantId = userId ?? '';
      });
      await _fetchRequests();
    }
  }

  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  Future<void> _fetchRequests() async {
    final url = 'http://10.0.2.2:5093/api/maintenance/tenant/$_tenantId';
    final client = _getCustomClient();
    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _requests = json.decode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    } finally {
      client.close();
    }
  }
  // HÀM HỦY YÊU CẦU SỬA CHỮA
  Future<void> _cancelRequest(String requestId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy yêu cầu'),
        content: const Text('Bạn đã tự sửa xong hoặc không cần hỗ trợ nữa?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Hủy ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;


    final client = _getCustomClient();
    try {
      final response = await client.delete(
        Uri.parse('http://10.0.2.2:5093/api/maintenance/$requestId/cancel'),
      );

      debugPrint('CANCEL => ${response.statusCode} | ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy yêu cầu thành công'), backgroundColor: AppColors.primaryGreen),
          );
          _fetchRequests();
        }
      } else {
        String msg = 'Không thể hủy yêu cầu (mã lỗi ${response.statusCode})';
        try {
          final body = json.decode(response.body);
          if (body is Map && body['message'] != null) msg = body['message'];
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.orange),
          );
        }
      }
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã hủy yêu cầu thành công'), backgroundColor: AppColors.primaryGreen)
          );
          _fetchRequests();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể hủy lúc này (Chủ trọ đã tiếp nhận)'), backgroundColor: Colors.orange)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối mạng'), backgroundColor: Colors.redAccent));
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text('Lịch sử sửa chữa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _fetchRequests,
            color: AppColors.primaryGreen,
            child: _requests.isEmpty
                ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                const Center(child: Text('Bạn chưa có yêu cầu sửa chữa nào.', style: TextStyle(color: AppColors.textSecondary))),
              ],
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                return _buildRequestCard(_requests[index]);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'pending';
    final title = data['title'] ?? 'Sự cố';
    final description = data['description'] ?? '';
    final ownerNoteStr = data['ownerNote']?.toString() ?? '';
    final createdAt = data['createdAt']?.toString() ?? '';
    final completedAt = data['completedAt']?.toString() ?? '';

    final statusUI = _getStatusUI(status);

    // Bóc tách Ghi chú chủ nhà nếu có định dạng "Chi phí: X | Phân bổ: Y | Ghi chú: Z"
    List<String> notes = ownerNoteStr.isNotEmpty ? ownerNoteStr.split(' | ') : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusUI['bgColor'], borderRadius: BorderRadius.circular(6)),
                  child: Text(statusUI['text'], style: TextStyle(color: statusUI['textColor'], fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text("Gửi lúc: $createdAt", style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            if (completedAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 6),
                  Text("Xong lúc: $completedAt", style: const TextStyle(fontSize: 13, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const Divider(height: 24, color: AppColors.borderLight),
            Text(description, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),

            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: notes.map((note) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right, size: 18, color: Colors.blueGrey),
                        Expanded(child: Text(note.trim(), style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],

            // Nút HỦY YÊU CẦU chỉ hiện khi status là pending
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _cancelRequest(data['id']),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                  label: const Text('Hủy yêu cầu', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusUI(String status) {
    switch (status) {
      case 'pending': return {'text': 'Chờ tiếp nhận', 'bgColor': Colors.orange.shade100, 'textColor': Colors.orange.shade800};
      case 'processing': return {'text': 'Đang xử lý', 'bgColor': Colors.blue.shade100, 'textColor': Colors.blue.shade800};
      case 'completed': return {'text': 'Hoàn thành', 'bgColor': AppColors.lightGreen, 'textColor': AppColors.primaryGreen};
      case 'rejected': return {'text': 'Đã hủy', 'bgColor': Colors.red.shade100, 'textColor': Colors.red.shade800};
      default: return {'text': 'Không xác định', 'bgColor': Colors.grey.shade200, 'textColor': AppColors.textSecondary};
    }
  }
}