import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_storage.dart';
import '../../services/profile_service.dart';
import '../auth/login_screen.dart';

const Color primaryColor = Color(0xFF1B5E55);

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _userData;

  List<Map<String, dynamic>> _bankAccounts = [];

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _userData = Map<String, dynamic>.from(
      widget.user ??
          {
            'Name': 'Người dùng',
            'Email': '',
            'Phone': '',
            'Avatar': '',
            'Role': 'tenant',
          },
    );

    _loadProfile();
  }

  // =====================================================
  // LẤY THÔNG TIN TỪ BACKEND
  // =====================================================

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final data = await ProfileService.getProfile();

      if (!mounted) return;

      final dynamic rawBankAccounts = data['bankAccounts'];
      final bankAccounts = rawBankAccounts is List
          ? rawBankAccounts.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _userData = {
          'Id': data['id'] ?? '',
          'Name': data['name'] ?? 'Người dùng',
          'Email': data['email'] ?? '',
          'Phone': data['phone'] ?? '',
          'Avatar': data['avatar'] ?? '',
          'Role': data['role'] ?? 'tenant',
        };

        _bankAccounts = bankAccounts;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  // =====================================================
  // THÔNG TIN NGƯỜI DÙNG
  // =====================================================

  String get _userRole {
    return _userData['Role']?.toString().trim().toLowerCase() ?? 'tenant';
  }

  String get _roleLabel {
    switch (_userRole) {
      case 'owner':
        return 'Chủ trọ';
      case 'admin':
        return 'Quản trị viên';
      default:
        return 'Người thuê';
    }
  }

  String get _displayName {
    final name = _userData['Name']?.toString().trim();

    return name == null || name.isEmpty ? 'Người dùng' : name;
  }

  String get _email => _userData['Email']?.toString() ?? '';

  String get _phone => _userData['Phone']?.toString() ?? '';

  // =====================================================
  // HIỂN THỊ THÔNG BÁO
  // =====================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // =====================================================
  // CHỈNH SỬA THÔNG TIN CÁ NHÂN
  // =====================================================

  Future<void> _showEditProfileDialog() async {
    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return EditProfileDialog(
          name: _displayName,
          email: _email,
          phone: _phone,
        );
      },
    );

    if (!mounted || result == null) return;

    try {
      // Gọi API cập nhật thông tin xuống SQL Server
      await ProfileService.updateProfile(
        name: result['name'] ?? '',
        email: result['email'] ?? '',
        phone: result['phone'] ?? '',
      );

      if (!mounted) return;

      // Chỉ cập nhật giao diện sau khi API thành công
      setState(() {
        _userData['Name'] = result['name'] ?? _displayName;
        _userData['Email'] = result['email'] ?? _email;
        _userData['Phone'] = result['phone'] ?? _phone;
      });

      _showMessage('Cập nhật thông tin cá nhân thành công.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // =====================================================
  // THÊM / CHỈNH SỬA NGÂN HÀNG
  // =====================================================

  Future<void> _showBankDialog({Map<String, dynamic>? account}) async {
    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return BankDialog(
          bankName: (account?['bankName'] ?? account?['bankCode'] ?? '').toString(),
          bankAccount: (account?['accountNumber'] ?? '').toString(),
          accountHolder: (account?['accountHolder'] ?? '').toString(),
          existingAccounts: _bankAccounts,
          editingAccountId: account?['id']?.toString(),
        );
      },
    );

    if (!mounted || result == null) return;

    try {
      final newBankName = result['bankName'] ?? '';
      final newBankAccount = result['bankAccount'] ?? '';
      final newAccountHolder = result['accountHolder'] ?? '';

      Map<String, dynamic> savedBank;

      final accountId = account?['id']?.toString();
      if (accountId == null || accountId.isEmpty) {
        // Chưa có tài khoản: gọi API thêm mới
        savedBank = await ProfileService.addBankAccount(
          bankName: newBankName,
          accountNumber: newBankAccount,
          accountHolder: newAccountHolder,
        );
      } else {
        // Đã có tài khoản: gọi API cập nhật
        savedBank = await ProfileService.updateBankAccount(
          id: accountId,
          bankName: newBankName,
          accountNumber: newBankAccount,
          accountHolder: newAccountHolder,
        );
      }

      if (!mounted) return;

      setState(() {
        final savedAccount = <String, dynamic>{...savedBank};
        final savedId = savedAccount['id']?.toString();
        final existingIndex = _bankAccounts.indexWhere(
          (item) => item['id']?.toString() == savedId,
        );
        if (existingIndex >= 0) {
          _bankAccounts[existingIndex] = savedAccount;
        } else {
          _bankAccounts.add(savedAccount);
        }
      });

      _showMessage('Lưu tài khoản ngân hàng thành công.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _setDefaultBankAccount(Map<String, dynamic> account) async {
    final id = account['id']?.toString();
    if (id == null || id.isEmpty) return;

    try {
      await ProfileService.setDefaultBankAccount(id: id);
      if (!mounted) return;

      setState(() {
        for (final item in _bankAccounts) {
          item['isDefault'] = item['id']?.toString() == id;
        }
      });
      _showMessage('Đã chọn tài khoản mặc định.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteBankAccount(Map<String, dynamic> account) async {
    final id = account['id']?.toString();
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tài khoản ngân hàng?'),
        content: const Text(
          'Tài khoản sẽ không còn dùng cho hóa đơn mới. Hóa đơn cũ vẫn giữ thông tin tài khoản đã chọn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ProfileService.deleteBankAccount(id: id);
      final data = await ProfileService.getProfile();
      final dynamic rawAccounts = data['bankAccounts'];
      final accounts = rawAccounts is List
          ? rawAccounts.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() => _bankAccounts = accounts);
      _showMessage('Đã xóa tài khoản ngân hàng.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // =====================================================
  // ĐĂNG XUẤT
  // =====================================================

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await AuthStorage.clearLogin();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Đăng xuất tài khoản',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: Color(0xFFFFCDD2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // WIDGET DÙNG CHUNG
  // =====================================================

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF26332F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Chưa cập nhật' : value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value.isEmpty
                        ? Colors.grey
                        : const Color(0xFF26332F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // PHẦN ĐẦU TRANG
  // =====================================================

  Widget _buildHeader() {
    final avatar = _userData['Avatar']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E55), Color(0xFF2D8271)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFFE6F0EB),
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? const Icon(Icons.person, size: 42, color: primaryColor)
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: Color(0xFFFFD166),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _roleLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Chỉnh sửa thông tin',
          ),
        ],
      ),
    );
  }

  // =====================================================
  // THÔNG TIN CÁ NHÂN
  // =====================================================

  Widget _buildPersonalInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _infoRow(Icons.badge_outlined, 'Họ và tên', _displayName),
          const Divider(height: 1),
          _infoRow(Icons.email_outlined, 'Email', _email),
          const Divider(height: 1),
          _infoRow(Icons.phone_outlined, 'Số điện thoại', _phone),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Chỉnh sửa thông tin'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // =====================================================
  // YÊU CẦU SỬA CHỮA
  // =====================================================
  Widget _buildMaintenanceHistoryButton() {
    return Column(
      children: [
        _sectionTitle('Hỗ trợ kỹ thuật', Icons.build_circle_outlined),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lịch sử báo cáo sự cố và sửa chữa của bạn',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    // Điều hướng sang trang Lịch sử sửa chữa đã cấu hình trong app_routes
                    Navigator.pushNamed(context, '/tenant/maintenance/history');
                  },
                  icon: const Icon(Icons.handyman_outlined),
                  label: const Text('Xem yêu cầu sửa chữa của bạn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF09819), // Màu cam nổi bật để phân biệt
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // THÔNG TIN NGÂN HÀNG
  // =====================================================

  Widget _buildBankInfo() {
    String? defaultId;
    for (final account in _bankAccounts) {
      if (account['isDefault'] == true) {
        defaultId = account['id']?.toString();
        break;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionTitle('Tài khoản ngân hàng', Icons.account_balance_outlined),
            ),
            FilledButton.icon(
              onPressed: () => _showBankDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_bankAccounts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text('Chưa có tài khoản ngân hàng.'),
          )
        else
          ..._bankAccounts.map((account) {
            final isDefault = account['isDefault'] == true ||
                (defaultId == null && _bankAccounts.first == account);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_outlined, color: primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (account['bankName'] ?? account['bankCode'] ?? 'Ngân hàng').toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (isDefault)
                        const Chip(
                          label: Text('Mặc định'),
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(fontSize: 12),
                        ),
                      IconButton(
                        tooltip: 'Chỉnh sửa tài khoản',
                        onPressed: () => _showBankDialog(account: account),
                        icon: const Icon(Icons.edit_outlined, color: primaryColor),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Tùy chọn tài khoản',
                        onSelected: (action) {
                          if (action == 'default') {
                            _setDefaultBankAccount(account);
                          } else if (action == 'delete') {
                            _deleteBankAccount(account);
                          }
                        },
                        itemBuilder: (_) => [
                          if (!isDefault)
                            const PopupMenuItem(
                              value: 'default',
                              child: Text('Đặt làm mặc định'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Xóa tài khoản'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _infoRow(Icons.credit_card_outlined, 'Số tài khoản', (account['accountNumber'] ?? '').toString()),
                  const Divider(height: 1),
                  _infoRow(Icons.person_outline, 'Chủ tài khoản', (account['accountHolder'] ?? '').toString()),
                ],
              ),
            );
          }),
      ],
    );
  }

  // =====================================================
  // LƯU Ý BẢO MẬT
  // =====================================================

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF9A6A00)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kiểm tra kỹ thông tin cá nhân và tài khoản ngân hàng. '
              'Không chia sẻ mật khẩu hoặc mã OTP cho người khác.',
              style: TextStyle(
                color: Color(0xFF73551A),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // GIAO DIỆN CHÍNH
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cá nhân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Không thể tải thông tin cá nhân',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _sectionTitle('Thông tin cá nhân', Icons.person_outline),
          const SizedBox(height: 12),
          _buildPersonalInfo(),
          const SizedBox(height: 24),
          if (_userRole == 'tenant') ...[
            _buildMaintenanceHistoryButton(),
            const SizedBox(height: 24),
          ],
          _buildBankInfo(),
          const SizedBox(height: 24),
          _buildPrivacyNote(),
          const SizedBox(height: 24),
          _buildLogoutButton(),
          const SizedBox(height: 24),
        ],
            ),
    );
  }
}

// =====================================================
// DIALOG CHỈNH SỬA THÔNG TIN CÁ NHÂN
// =====================================================

class EditProfileDialog extends StatefulWidget {
  final String name;
  final String email;
  final String phone;

  const EditProfileDialog({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    Navigator.of(context).pop({'name': name, 'email': email, 'phone': phone});
  }

  void _showDialogMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    required String fieldName,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Vui lòng nhập $fieldName';
        if (isEmail && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
          return 'Email không hợp lệ';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa thông tin'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_nameController, 'Họ và tên', Icons.person_outline, fieldName: 'họ và tên'),
            const SizedBox(height: 12),
            _field(
              _emailController,
              'Email',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              fieldName: 'email',
              isEmail: true,
            ),
            const SizedBox(height: 12),
            _field(
              _phoneController,
              'Số điện thoại',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              fieldName: 'số điện thoại',
            ),
          ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: primaryColor),
          onPressed: _save,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

// =====================================================
// DIALOG THÊM / CHỈNH SỬA TÀI KHOẢN NGÂN HÀNG
// =====================================================

class BankDialog extends StatefulWidget {
  final String bankName;
  final String bankAccount;
  final String accountHolder;
  final List<Map<String, dynamic>> existingAccounts;
  final String? editingAccountId;

  const BankDialog({
    super.key,
    required this.bankName,
    required this.bankAccount,
    required this.accountHolder,
    required this.existingAccounts,
    this.editingAccountId,
  });

  @override
  State<BankDialog> createState() => _BankDialogState();
}

class _BankDialogState extends State<BankDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankController;
  late final TextEditingController _accountController;
  late final TextEditingController _holderController;

  @override
  void initState() {
    super.initState();

    _bankController = TextEditingController(text: widget.bankName);

    _accountController = TextEditingController(text: widget.bankAccount);

    _holderController = TextEditingController(text: widget.accountHolder);
  }

  @override
  void dispose() {
    _bankController.dispose();
    _accountController.dispose();
    _holderController.dispose();

    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final bank = _bankController.text.trim();
    final account = _accountController.text.trim();
    final holder = _holderController.text.trim();

    String normalize(String value) => value.trim().toLowerCase();

    final duplicateAccount = widget.existingAccounts.any((existing) {
      final existingId = existing['id']?.toString();
      final existingBank = (existing['bankName'] ?? existing['bankCode'] ?? '')
          .toString();
      final existingAccount = (existing['accountNumber'] ?? '').toString();
      final existingHolder = (existing['accountHolder'] ?? '').toString().trim().toLowerCase();
      final sameBank = normalize(existingBank) == normalize(bank);
      final sameAccountNumber = normalize(existingAccount) == normalize(account);
      final sameAccountHolder = existingHolder == normalize(holder);

      return existingId != widget.editingAccountId &&
          sameBank &&
          (sameAccountNumber || sameAccountHolder);
    });
    if (duplicateAccount) {
      _showDialogMessage(
        'Trong cùng ngân hàng, số tài khoản và tên chủ tài khoản phải khác các tài khoản đã lưu',
      );
      return;
    }

    Navigator.of(
      context,
    ).pop({'bankName': bank, 'bankAccount': account, 'accountHolder': holder});
  }

  void _showDialogMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    TextInputType? keyboardType,
    required String fieldName,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Vui lòng nhập $fieldName'
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.bankAccount.isEmpty
            ? 'Thêm tài khoản ngân hàng'
            : 'Chỉnh sửa tài khoản ngân hàng',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(
              _bankController,
              'Tên ngân hàng',
              Icons.account_balance_outlined,
              hint: 'Ví dụ: Vietcombank',
              fieldName: 'tên ngân hàng',
            ),
            const SizedBox(height: 12),
            _field(
              _accountController,
              'Số tài khoản',
              Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              fieldName: 'số tài khoản',
            ),
            const SizedBox(height: 12),
            _field(
              _holderController,
              'Tên chủ tài khoản',
              Icons.person_outline,
              fieldName: 'tên chủ tài khoản',
            ),
          ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: primaryColor),
          onPressed: _save,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
