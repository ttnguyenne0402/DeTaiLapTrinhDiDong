import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../services/admin/admin_post_service.dart';

class review extends StatefulWidget {
  const review({super.key});

  @override
  State<review> createState() => duyettin();
}

class duyettin extends State<review> {
  String _selectedRole = "Chờ duyệt";
  List<AdminPostItem> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  // Chuyển tab tiếng Việt sang status của SQL
  String _mapTabToStatus(String tab) {
    switch (tab) {
      case 'Đã duyệt':
        return 'published';
      case 'Từ chối':
        return 'rejected';
      case 'Chờ duyệt':
      default:
        return 'pending';
    }
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final status = _mapTabToStatus(_selectedRole);
      final data = await AdminPostService.getPosts(status);
      setState(() {
        _posts = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Lỗi tải bài đăng: $e");
    }
  }

  Future<void> _quickModerate(String id, String action) async {
    final success = await AdminPostService.moderatePost(id: id, action: action);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'approve' ? 'Đã duyệt tin thành công!' : 'Đã từ chối tin!')),
      );
      _fetchPosts(); // Tải lại danh sách
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
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
          "Duyệt tin đăng",
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ["Chờ duyệt", "Đã duyệt", "Từ chối"].map((role) {
                          final isSelected = _selectedRole == role;
                          return ChoiceChip(
                            label: Text(role),
                            selected: isSelected,
                            selectedColor: AppColors.primaryGreen,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedRole = role);
                                _fetchPosts();
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _posts.isEmpty
                          ? const Center(child: Text("Không có tin đăng nào", style: TextStyle(color: Colors.grey)))
                          : RefreshIndicator(
                        onRefresh: _fetchPosts,
                        child: ListView.builder(
                          itemCount: _posts.length,
                          padding: const EdgeInsets.all(14),
                          itemBuilder: (context, index) {
                            final item = _posts[index];
                            return _buildPostCard(item);
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.adminDashboard);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.adminStats);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.usersManage);
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

  Widget _buildPostCard(AdminPostItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Chuyển sang trang chi tiết thẩm định và nhận kết quả cập nhật khi pop về
            await Navigator.pushNamed(
              context,
              AppRoutes.contentModeration,
              arguments: item.id,
            );
            _fetchPosts();
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.thumbnail != null && item.thumbnail!.isNotEmpty
                      ? Image.network(
                    item.thumbnail!,
                    width: 85,
                    height: 95,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 85,
                      height: 95,
                      color: AppColors.lightGreen,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  )
                      : Container(
                    width: 85,
                    height: 95,
                    color: AppColors.lightGreen,
                    child: const Icon(Icons.home, color: AppColors.primaryGreen, size: 32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatCurrency(item.price)} đ/tháng',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Đăng bởi: ${item.ownerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      if (item.status == 'pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _quickModerate(item.id, 'reject'),
                              child: const Text("Từ chối", style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _quickModerate(item.id, 'approve'),
                              child: const Text("Duyệt", style: TextStyle(fontSize: 12, color: Colors.white)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}