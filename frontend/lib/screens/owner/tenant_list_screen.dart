import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Thư viện để gọi điện
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../services/auth_storage.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'owner_dashboard.dart';
import 'properties_manage.dart';
import 'owner_profile_screen.dart';
import '../tenant/profile_screen.dart';
import 'tenant_detail_owner.dart';
class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  // BIẾN QUẢN LÝ TRẠNG THÁI VÀ DỮ LIỆU
  List<dynamic> _tenants = [];
  List<dynamic> _filteredTenants = [];
  bool _isLoading = true;
  String _ownerId = '';

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  // Khởi tạo Custom Client bỏ qua SSL
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  // Lấy ID chủ nhà từ AuthStorage và gọi API
  Future<void> _loadOwnerData() async {
    final userId = await AuthStorage.getUserId();
    if (mounted) {
      setState(() {
        _ownerId = userId ?? '';
      });
      await _fetchTenants();
    }
  }

  // Gọi API lấy danh sách người thuê
  Future<void> _fetchTenants() async {
    setState(() => _isLoading = true);

    final url = 'http://10.0.2.2:5093/api/OwnerContracts/tenants/$_ownerId';
    final client = _getCustomClient();

    try {
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _tenants = data;
            _filteredTenants = data;
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

  // Hàm xử lý tìm kiếm cục bộ (Offline search)
  void _onSearchChanged(String keyword) {
    setState(() {
      if (keyword.trim().isEmpty) {
        _filteredTenants = _tenants;
      } else {
        final lowerKeyword = keyword.trim().toLowerCase();
        _filteredTenants = _tenants.where((tenant) {
          final name = (tenant['name'] ?? '').toLowerCase();
          final phone = (tenant['phone'] ?? '').toLowerCase();
          final room = (tenant['room'] ?? '').toLowerCase();
          return name.contains(lowerKeyword) || phone.contains(lowerKeyword) || room.contains(lowerKeyword);
        }).toList();
      }
    });
  }

  // Hàm Mở trình gọi điện của hệ điều hành
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
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
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      drawer: const OwnerDrawer(currentRoute: 'tenant',),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text('Người thuê', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // THANH TÌM KIẾM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo tên, SĐT, số phòng...',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // DANH SÁCH NGƯỜI THUÊ
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                  : _filteredTenants.isEmpty
                  ? const Center(child: Text('Không tìm thấy người thuê nào', style: TextStyle(color: AppColors.textSecondary)))
                  : RefreshIndicator(
                onRefresh: _fetchTenants,
                color: AppColors.primaryGreen,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredTenants.length,
                  itemBuilder: (context, index) {
                    final tenant = _filteredTenants[index];
                    return _buildTenantItem(tenant);
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.accentYellow,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Trang chủ', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()))),
            _buildNavItem(Icons.apartment, 'Tòa nhà', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PropertiesManageScreen()))),
            const SizedBox(width: 40),
            _buildNavItem(Icons.people_alt, 'Người thuê', true, () {}),
            _buildNavItem(Icons.person_outline, 'Cá nhân', false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen(user: {'Name': 'Nguyễn Văn A', 'Role': 'owner'})))),
          ],
        ),
      ),
    );
  }

  // XÂY DỰNG ITEM TỪNG NGƯỜI THUÊ THẬT
  Widget _buildTenantItem(Map<String, dynamic> tenant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1.0)
      ),
      // BỌC INKWELL VÀO ĐÂY
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // CHUYỂN SANG TRANG CHI TIẾT
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TenantDetailOwnerScreen(
                contractId: tenant['contractId'].toString(),
              ),
            ),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.lightGreen,
            child: Icon(Icons.person, color: AppColors.primaryGreen, size: 28),
          ),
          title: Text(
            tenant['name'] ?? 'Khách',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Phòng ${tenant['room']} • HĐ từ ${tenant['date']}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.phone_in_talk, color: AppColors.primaryGreen),
            onPressed: () {
              // Lấy sđt và gọi
              final phone = tenant['phone'];
              if (phone != null && phone.toString().isNotEmpty) {
                _makePhoneCall(phone.toString());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Khách hàng này chưa có số điện thoại.')));
              }
            },
          ),
        ),
      ),
    );
  }
  // Thanh Navigation Item
  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? AppColors.primaryGreen : Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: isActive ? AppColors.primaryGreen : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}