import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class TenantDetailOwnerScreen extends StatefulWidget {
  final String contractId;

  const TenantDetailOwnerScreen({super.key, required this.contractId});

  @override
  State<TenantDetailOwnerScreen> createState() => _TenantDetailOwnerScreenState();
}

class _TenantDetailOwnerScreenState extends State<TenantDetailOwnerScreen> {
  Map<String, dynamic>? _tenantData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTenantDetail();
  }

  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  Future<void> _fetchTenantDetail() async {
    final url = 'http://10.0.2.2:5093/api/OwnerContracts/tenant-detail/${widget.contractId}';
    final client = _getCustomClient();
    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _tenantData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Lỗi Server: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: $e';
        _isLoading = false;
      });
    } finally {
      client.close();
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gọi số này.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: AppColors.primaryGreen, body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    if (_errorMessage.isNotEmpty || _tenantData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi tải dữ liệu')),
        body: Center(child: Text(_errorMessage.isNotEmpty ? _errorMessage : 'Không có dữ liệu', style: const TextStyle(color: Colors.red))),
      );
    }

    final members = _tenantData!['members'] as List<dynamic>? ?? [];

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
        title: const Text('Hồ Sơ Người Thuê', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thẻ thông tin cá nhân
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.lightGreen,
                      child: const Icon(Icons.person, size: 40, color: AppColors.primaryGreen),
                    ),
                    const SizedBox(height: 12),
                    Text(_tenantData!['tenantName'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(_tenantData!['tenantPhone'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(_tenantData!['tenantPhone'] ?? ''),
                          icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                          label: const Text('Gọi điện', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Thông tin Hợp đồng
              const Text('THÔNG TIN THUÊ PHÒNG', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
                child: Column(
                  children: [
                    _buildInfoRow('Khu trọ:', _tenantData!['propertyName']),
                    const Divider(height: 20),
                    _buildInfoRow('Phòng đang thuê:', _tenantData!['roomName'], isBold: true),
                    const Divider(height: 20),
                    _buildInfoRow('Mã hợp đồng:', _tenantData!['contractCode']),
                    const Divider(height: 20),
                    _buildInfoRow('Thời hạn:', '${_tenantData!['startDate']} - ${_tenantData!['endDate']}'),
                    const Divider(height: 20),
                    _buildInfoRow('Tiền thuê/tháng:', '${_formatCurrency(_tenantData!['rent'])} đ', valueColor: AppColors.primaryGreen),
                    const Divider(height: 20),
                    _buildInfoRow('Tiền cọc:', '${_formatCurrency(_tenantData!['deposit'])} đ'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Danh sách người ở cùng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('NGƯỜI Ở CÙNG', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  Text('${members.length} người', style: const TextStyle(fontSize: 13, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              if (members.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
                  child: const Text('Khách hàng này đang ở một mình.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                )
              else
                ...members.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.background, child: Icon(Icons.person_outline, color: AppColors.textSecondary)),
                    title: Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${m['relationship']} • ${m['phone'] ?? 'Không có SĐT'}', style: const TextStyle(fontSize: 12)),
                  ),
                )).toList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    double val = amount is int ? amount.toDouble() : amount;
    String result = val.toInt().toString();
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return result;
  }
}