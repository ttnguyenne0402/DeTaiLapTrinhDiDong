import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../services/admin/admin_user_service.dart';

class User extends StatefulWidget {
  const User({super.key});

  @override
  State<User> createState() => _UserState();
}

class _UserState extends State<User> {
  String _selectedRole = "Tất cả";
  String _searchKeyword = "";
  List<AdminUserModel> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  String _mapTabToRole(String tab) {
    switch (tab) {
      case 'Người thuê':
        return 'tenant';
      case 'Chủ trọ':
        return 'owner';
      default:
        return 'all';
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final role = _mapTabToRole(_selectedRole);
      final data = await AdminUserService.getUsers(
        role: role,
        search: _searchKeyword,
      );
      setState(() {
        _users = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Lỗi tải users: $e");
    }
  }

  // Hàm chuyển đổi trạng thái Khóa / Mở khóa
  Future<void> _showStatusDialog(AdminUserModel user) async {
    final nextStatus = user.isActive ? 'blocked' : 'active';
    final actionText = user.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(actionText),
        content: Text('Bạn có chắc chắn muốn ${actionText.toLowerCase()} "${user.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.redAccent : AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(user.isActive ? 'Khóa' : 'Mở khóa', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminUserService.toggleUserStatus(user.id, nextStatus);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: nextStatus == 'active' ? AppColors.primaryGreen : Colors.red,
            content: Text('${actionText} thành công!'),
          ),
        );
        _fetchUsers();
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
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, size: 26, color: Colors.white),
        ),
        centerTitle: true,
        title: const Text(
          "Quản lý tài khoản",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Tab chọn vai trò
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ["Tất cả", "Người thuê", "Chủ trọ"].map((role) {
                          final isSelected = _selectedRole == role;
                          return ChoiceChip(
                            label: Text(role),
                            selected: isSelected,
                            selectedColor: AppColors.primaryGreen,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedRole = role);
                                _fetchUsers();
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    // Khối nội dung chính
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          children: [
                            const SizedBox(height: 6),
                            // Ô tìm kiếm
                            TextField(
                              onChanged: (value) {
                                _searchKeyword = value.trim();
                                _fetchUsers();
                              },
                              decoration: InputDecoration(
                                hintText: "Tìm kiếm (Tên, Email, SĐT)",
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                filled: true,
                                fillColor: AppColors.lightGreen,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Danh sách hiển thị
                            Expanded(
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : _users.isEmpty
                                  ? const Center(child: Text("Không có tài khoản nào", style: TextStyle(color: Colors.grey)))
                                  : RefreshIndicator(
                                onRefresh: _fetchUsers,
                                child: ListView.builder(
                                  itemCount: _users.length,
                                  itemBuilder: (context, index) {
                                    final user = _users[index];
                                    final bool isActive = user.isActive;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.03),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        leading: CircleAvatar(
                                          backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                                              ? NetworkImage(user.avatar!)
                                              : null,
                                          radius: 24,
                                          backgroundColor: AppColors.lightGreen,
                                          child: (user.avatar == null || user.avatar!.isEmpty)
                                              ? const Icon(Icons.person, color: AppColors.primaryGreen)
                                              : null,
                                        ),
                                        title: Text(
                                          user.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 2),
                                            Text(
                                              user.email,
                                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${user.displayRole}${user.phone != null ? ' • ${user.phone}' : ''}',
                                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        trailing: InkWell(
                                          onTap: () => _showStatusDialog(user),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isActive ? Colors.green[100] : Colors.red[100],
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              user.displayStatus,
                                              style: TextStyle(
                                                color: isActive ? AppColors.primaryGreen : Colors.red[800],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        onTap: () => _showStatusDialog(user),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, AppRoutes.adminDashboard);
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.rewview);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.adminStats);
              break;
            case 3:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.article_outlined), label: 'Quản lý'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Thống kê'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Tài khoản'),
        ],
      ),
    );
  }
}