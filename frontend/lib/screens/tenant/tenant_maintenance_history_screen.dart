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
    final ownerNote = data['ownerNote'] ?? '';
    final createdAt = data['createdAt']?.toString() ?? '';

    final statusUI = _getStatusUI(status);

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
            const Divider(height: 24, color: AppColors.borderLight),
            Text(description, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            if (ownerNote.toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("Phản hồi từ chủ nhà:\n$ownerNote", style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
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
      case 'rejected': return {'text': 'Từ chối', 'bgColor': Colors.red.shade100, 'textColor': Colors.red.shade800};
      default: return {'text': 'Không xác định', 'bgColor': Colors.grey.shade200, 'textColor': AppColors.textSecondary};
    }
  }
}