import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'post_form.dart';
import 'post_detail_owner.dart';
import '../../services/local/sqlite_helper.dart';
import '../../services/owner/post_service.dart';

class PostsManageScreen extends StatefulWidget {
  const PostsManageScreen({super.key});

  @override
  State<PostsManageScreen> createState() => _PostsManageScreenState();
}

class _PostsManageScreenState extends State<PostsManageScreen> {
  // Dùng GlobalKey để điều khiển TabBarView từ bên ngoài mà không cần TabController thủ công
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Key _tab3Key = UniqueKey();
  bool _isLoading = true;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadAllPosts();
  }

  // Tải đồng thời: Bài đăng chính thức từ SQL Server + Bản nháp offline từ SQLite
  Future<void> _loadAllPosts() async {
    setState(() => _isLoading = true);
    await _loadPostsFromSqlServer();
    await _loadDraftsFromSqlite();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // 1. Tải bài đăng từ SQL Server
  Future<void> _loadPostsFromSqlServer() async {
    try {
      final list = await PostService.fetchPosts('USER_OWNER_01');
      if (mounted) {
        setState(() {
          _posts = list.map((p) => {
            'id': p.id,
            'roomId': p.roomId,
            'roomName': p.roomName,
            'propertyId': p.propertyId,
            'propertyName': p.propertyName,
            'propertyAddress': p.propertyAddress,
            'room': p.room,
            'roomArea': p.roomArea,
            'roomDeposit': p.roomDeposit,
            'roomMaxPeople': p.roomMaxPeople,
            'roomFloor': p.roomFloor,
            'roomStatus': p.roomStatus,
            'roomDescription': p.roomDescription,
            'title': p.title,
            'description': p.description,
            'rawPrice': p.price,
            'price': p.priceFormatted,
            'amenities': p.amenities,
            'views': p.views,
            'likes': p.likes,
            'date': p.date,
            'status': p.status,
            'submitNote': p.submitNote,
            'rejectReason': p.rejectReason,
            'image': p.image,
            'images': p.images,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải bài đăng từ SQL Server: $e');
    }
  }

  // 2. Tải các bản nháp được lưu trong cơ sở dữ liệu SQLite cục bộ trên điện thoại
  Future<void> _loadDraftsFromSqlite() async {
    try {
      final sqliteDrafts = await SqliteHelper.instance.getDraftPosts();
      if (sqliteDrafts.isNotEmpty && mounted) {
        setState(() {
          _posts.removeWhere((p) => p['isSqlite'] == true);
          for (var draft in sqliteDrafts) {
            final amnStr = (draft['amenities'] ?? '').toString();
            final amnList = amnStr.isNotEmpty
                ? amnStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                : <String>['Wifi', 'Chỗ để xe'];

            _posts.insert(0, {
              'id': 'sqlite_${draft['id']}',
              'sqliteId': draft['id'],
              'isSqlite': true,
              'roomId': draft['room_id'] ?? 'room_101',
              'roomName': draft['room_name'] ?? 'Phòng',
              'propertyName': draft['building_name'] ?? 'Tòa nhà',
              'title': draft['title'] ?? 'Bản nháp tin đăng',
              'description': draft['description'] ?? '',
              'room': '${draft['room_name'] ?? 'Phòng'} - ${draft['building_name'] ?? 'Tòa nhà'} (Bản nháp)',
              'price': draft['price'] ?? 'Thỏa thuận',
              'amenities': amnList,
              'views': 0,
              'likes': 0,
              'date': draft['created_at'] ?? 'Hôm nay',
              'status': 'draft',
              'image': draft['image'] ?? 'frontend/assets/images/anhPhongDemo.jpg',
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách nháp từ SQLite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đếm số lượng theo trạng thái
    final int activeCount = _posts.where((p) => p['status'] == 'active').length;
    final int pendingCount = _posts
        .where((p) => p['status'] == 'pending')
        .length;
    final int hiddenOrDraftCount = _posts
        .where(
          (p) =>
              p['status'] == 'draft' ||
              p['status'] == 'hidden' ||
              p['status'] == 'rejected',
        )
        .length;

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (tabContext) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.primaryGreen,
            drawer: const OwnerDrawer(currentRoute: 'posts'),
            appBar: AppBar(
              backgroundColor: AppColors.primaryGreen,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: const Text(
                'Quản lý tin đăng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Làm mới',
                  onPressed: _loadAllPosts,
                ),
              ],
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.orange,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'Đang hiển thị ($activeCount)'),
                  Tab(text: 'Chờ duyệt ($pendingCount)'),
                  Tab(text: 'Bản nháp / Ẩn ($hiddenOrDraftCount)'),
                ],
              ),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadAllPosts,
                        child: TabBarView(
                          children: [
                            _buildPostList('active'),
                            _buildPostList('pending'),
                            KeyedSubtree(
                              key: _tab3Key,
                              child: _buildPostList('hidden_draft'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final newPost = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostFormScreen(),
                  ),
                );

                if (newPost == true) {
                  await _loadAllPosts();
                } else if (newPost != null && newPost is Map<String, dynamic>) {
                  await _loadAllPosts();
                  setState(() {
                    _posts.insert(0, Map<String, dynamic>.from(newPost));
                    _tab3Key = UniqueKey();
                  });

                  final tabController = DefaultTabController.of(tabContext);

                  // Nếu bấm Gửi Admin duyệt -> Nhảy sang Tab 2 (Chờ duyệt)
                  if (newPost['status'] == 'pending') {
                    tabController.animateTo(1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Đã gửi bài đăng mới cho Admin duyệt thành công!',
                        ),
                        backgroundColor: AppColors.primaryGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  // Nếu bấm Lưu Nháp -> Nhảy sang Tab 3 (Bản nháp / Ẩn)
                  else if (newPost['status'] == 'draft') {
                    tabController.animateTo(2);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đã lưu bài viết vào bản nháp thành công!',
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tạo tin đăng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Danh sách bài đăng theo từng tab
  Widget _buildPostList(String tabKey) {
    List<Map<String, dynamic>> filtered;
    if (tabKey == 'active') {
      filtered = _posts.where((p) => p['status'] == 'active').toList();
    } else if (tabKey == 'pending') {
      filtered = _posts.where((p) => p['status'] == 'pending').toList();
    } else {
      filtered = _posts
          .where(
            (p) =>
                p['status'] == 'draft' ||
                p['status'] == 'hidden' ||
                p['status'] == 'rejected',
          )
          .toList();
    }

    if (filtered.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;
      if (tabKey == 'pending') {
        emptyMessage =
            'Hiện không có bài nào đang chờ duyệt.\nHãy bấm "Gửi duyệt" ở mục Bản nháp để gửi cho Admin.';
        emptyIcon = Icons.hourglass_empty_rounded;
      } else if (tabKey == 'active') {
        emptyMessage =
            'Chưa có bài đăng nào đang hiển thị.\nHãy tạo tin mới hoặc gửi duyệt bài đăng.';
        emptyIcon = Icons.article_outlined;
      } else {
        emptyMessage = 'Không có bài đăng nháp hoặc bị ẩn.';
        emptyIcon = Icons.folder_open_outlined;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 14, left: 14, right: 14, bottom: 85),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final post = filtered[index];
        return _buildPostCard(post);
      },
    );
  }

  // Thẻ hiển thị một bài đăng (thông tin cơ bản, bấm vào để xem chi tiết)
  Widget _buildPostCard(Map<String, dynamic> post) {
    final String status = post['status'] ?? 'draft';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailOwnerScreen(post: post),
            ),
          );
          if (changed == true) {
            _loadAllPosts();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(status),
                Text(
                  post['date'] ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    post['image'] ?? 'frontend/assets/images/anhPhongDemo.jpg',
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 85,
                      height: 85,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post['room'] ?? '',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post['price'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 16,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post['submitNote'] ??
                            'Đang chờ Quản trị viên duyệt bài (PCCC, tính xác thực)...',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 'rejected') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cancel_outlined,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin từ chối: ${post['rejectReason'] ?? 'Chưa đạt tiêu chí phê duyệt'}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.remove_red_eye_outlined,
                      size: 15,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post['views'] ?? 0}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.favorite_border,
                      size: 15,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post['likes'] ?? 0}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (status == 'pending') ...[
                      OutlinedButton.icon(
                        onPressed: () => _confirmCancelApproval(post),
                        icon: const Icon(
                          Icons.undo,
                          size: 15,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          'Thu hồi',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                    if (status == 'draft' ||
                        status == 'hidden' ||
                        status == 'rejected') ...[
                      ElevatedButton.icon(
                        onPressed: () => _showSubmitApprovalBottomSheet(post),
                        icon: const Icon(
                          Icons.send_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        label: Text(
                          status == 'rejected'
                              ? 'Gửi duyệt lại'
                              : 'Gửi Admin duyệt',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (status == 'active') ...[
                      TextButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() {
                            post['status'] = 'hidden';
                          });
                          try {
                            final success = await PostService.updatePostStatus(
                              post['id'].toString(),
                              'hidden',
                            );
                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Ẩn tin đăng thành công'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              _loadAllPosts();
                            } else {
                              setState(() => post['status'] = 'active');
                            }
                          } catch (e) {
                            debugPrint('Lỗi ẩn tin: $e');
                            setState(() => post['status'] = 'active');
                          }
                        },
                        icon: const Icon(
                          Icons.visibility_off,
                          size: 16,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          'Ẩn tin',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                    if (status == 'draft') ...[
                      TextButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          if (post['isSqlite'] == true && post['sqliteId'] != null) {
                            await SqliteHelper.instance.deleteDraftPost(post['sqliteId']);
                          }
                          setState(() {
                            _posts.remove(post);
                          });
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Xóa bản nháp thành công'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Xóa nháp',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                    TextButton.icon(
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostFormScreen(initialData: post),
                          ),
                        );
                        if (res == true) {
                          _loadAllPosts();
                        }
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      label: Text(
                        'Sửa',
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case 'active':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        label = 'Đang hiển thị';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        bg = const Color(0xFFFFF3E0);
        text = const Color(0xFFE65100);
        label = 'Chờ Admin duyệt';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        label = 'Admin từ chối';
        icon = Icons.highlight_off;
        break;
      case 'hidden':
        bg = const Color(0xFFECEFF1);
        text = const Color(0xFF546E7A);
        label = 'Đã ẩn';
        icon = Icons.visibility_off_outlined;
        break;
      case 'draft':
      default:
        bg = const Color(0xFFF5F5F5);
        text = const Color(0xFF757575);
        label = 'Bản nháp';
        icon = Icons.edit_note;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitApprovalBottomSheet(Map<String, dynamic> post) {
    final noteController = TextEditingController();
    bool agreeTruth = true;
    bool agreePccc = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 18,
                right: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gửi Admin xét duyệt tin đăng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                'Admin sẽ thẩm định và xuất bản tin trong vòng 24h',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              post['image'] ??
                                  'frontend/assets/images/anhPhongDemo.jpg',
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 55,
                                height: 55,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  post['room'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  post['price'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tiêu chuẩn kiểm duyệt bắt buộc:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primaryGreen,
                      title: const Text(
                        'Thông tin và hình ảnh phòng trọ chính xác 100%',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      value: agreeTruth,
                      onChanged: (val) {
                        setModalState(() {
                          agreeTruth = val ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primaryGreen,
                      title: const Text(
                        'Phòng trọ đáp ứng đầy đủ tiêu chuẩn an toàn PCCC',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      value: agreePccc,
                      onChanged: (val) {
                        setModalState(() {
                          agreePccc = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Lời nhắn gửi Admin kiểm duyệt (không bắt buộc)...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (!agreeTruth || !agreePccc)
                            ? null
                            : () {
                                Navigator.pop(dialogCtx);
                                _submitPost(post, noteController.text);
                              },
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'XÁC NHẬN GỬI ADMIN DUYỆT',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
    );
  }

  void _submitPost(Map<String, dynamic> post, String note) async {
    final messenger = ScaffoldMessenger.of(context);

    // Nếu là bản nháp từ SQLite cục bộ trên điện thoại:
    if (post['isSqlite'] == true && post['sqliteId'] != null) {
      final cleanPrice = double.tryParse(
            (post['price'] ?? '')
                .toString()
                .replaceAll('.', '')
                .replaceAll(',', '')
                .replaceAll('đ', '')
                .replaceAll('/tháng', '')
                .trim(),
          ) ??
          0;
      // 1. Gửi tin lên máy chủ Backend SQL Server
      await PostService.createPost({
        'roomId': post['roomId'] ?? 'room_101',
        'title': post['title'] ?? 'Tin đăng phòng trọ',
        'description': post['description'] ?? '',
        'price': cleanPrice,
        'amenities': post['amenities'] is List ? post['amenities'] : ['Wifi', 'Chỗ để xe'],
        'submitNote': note.isNotEmpty ? note : 'Gửi duyệt từ bản nháp',
        'status': 'pending',
        'images': ['frontend/assets/images/anhPhongDemo.jpg'],
      });
      // 2. Xóa bản nháp khỏi SQLite vì đã gửi duyệt lên SQL Server
      await SqliteHelper.instance.deleteDraftPost(post['sqliteId']);
      await _loadAllPosts();
    } else if (post['id'] != null) {
      await PostService.updatePostStatus(post['id'].toString(), 'pending');
      await _loadAllPosts();
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryGreen,
        content: const Text('Gửi duyệt tin đăng thành công'),
      ),
    );
  }

  void _confirmCancelApproval(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.undo, color: Colors.orange),
            SizedBox(width: 8),
            Text('Thu hồi duyệt tin?'),
          ],
        ),
        content: const Text(
          'Bài đăng sẽ chuyển về trạng thái Bản nháp để bạn chỉnh sửa và không còn trong hàng đợi duyệt của Admin.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              setState(() {
                post['status'] = 'draft';
              });
              try {
                final success = await PostService.updatePostStatus(
                  post['id'].toString(),
                  'draft',
                );
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Thu hồi tin đăng thành công'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  _loadAllPosts();
                }
              } catch (e) {
                debugPrint('Lỗi thu hồi tin: $e');
              }
            },
            child: const Text('Thu hồi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
