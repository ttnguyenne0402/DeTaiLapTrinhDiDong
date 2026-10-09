import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/tenant/profile_info_card.dart';
import '../auth/login_screen.dart';
import 'edit_profile_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _userData;

  String bankName = '';
  String bankAccount = '';
  String accountHolder = '';

  static const Color primaryColor = Color(0xFF1B5E55);
  static const Color backgroundColor = Color(0xFFF7F9F8);

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
  }

  // Đọc vai trò từ model được truyền vào.
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

  // =========================
  // ĐĂNG XUẤT
  // =========================

  void _logout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
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
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
          ),
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

  // =========================
  // CHỈNH SỬA THÔNG TIN CÁ NHÂN
  // =========================

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _displayName);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(
                nameController,
                'Họ và tên',
                Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _dialogField(
                emailController,
                'Email',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _dialogField(
                phoneController,
                'Số điện thoại',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              nameController.dispose();
              emailController.dispose();
              phoneController.dispose();
            },
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                _showMessage('Họ và tên không được để trống');
                return;
              }

              setState(() {
                _userData = {
                  ..._userData,
                  'Name': nameController.text.trim(),
                  'Email': emailController.text.trim(),
                  'Phone': phoneController.text.trim(),
                };
              });

              Navigator.pop(dialogContext);
              _showMessage('Đã cập nhật thông tin trên giao diện');

              nameController.dispose();
              emailController.dispose();
              phoneController.dispose();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // =========================
  // THÊM / CHỈNH SỬA NGÂN HÀNG
  // =========================

  void _showBankDialog() {
    final bankController = TextEditingController(text: bankName);
    final accountController = TextEditingController(text: bankAccount);
    final holderController = TextEditingController(text: accountHolder);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          bankAccount.isEmpty
              ? 'Thêm tài khoản ngân hàng'
              : 'Chỉnh sửa tài khoản ngân hàng',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(
                bankController,
                'Tên ngân hàng',
                Icons.account_balance_outlined,
                hint: 'Ví dụ: Vietcombank',
              ),
              const SizedBox(height: 12),
              _dialogField(
                accountController,
                'Số tài khoản',
                Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _dialogField(
                holderController,
                'Tên chủ tài khoản',
                Icons.person_outline,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bankController.dispose();
              accountController.dispose();
              holderController.dispose();
            },
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              if (bankController.text.trim().isEmpty ||
                  accountController.text.trim().isEmpty ||
                  holderController.text.trim().isEmpty) {
                _showMessage('Vui lòng nhập đầy đủ thông tin ngân hàng');
                return;
              }

              setState(() {
                bankName = bankController.text.trim();
                bankAccount = accountController.text.trim();
                accountHolder =
                    holderController.text.trim().toUpperCase();
              });

              Navigator.pop(dialogContext);
              _showMessage('Đã cập nhật thông tin ngân hàng trên giao diện');

              bankController.dispose();
              accountController.dispose();
              holderController.dispose();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // =========================
  // WIDGET DÙNG CHUNG
  // =========================

  Widget _dialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
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

  // =========================
  // PHẦN ĐẦU TRANG
  // =========================

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
              backgroundImage: avatar.isNotEmpty
                  ? NetworkImage(avatar)
                  : null,
              child: avatar.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 42,
                      color: primaryColor,
                    )
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
            icon: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
            ),
            tooltip: 'Chỉnh sửa thông tin',
          ),
        ],
      ),
    );
  }

  // =========================
  // THÔNG TIN CÁ NHÂN
  // =========================

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

  // =========================
  // THÔNG TIN NGÂN HÀNG
  // =========================

  Widget _buildBankInfo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionTitle(
                'Thông tin ngân hàng',
                Icons.account_balance_outlined,
              ),
            ),
            IconButton(
              onPressed: _showBankDialog,
              icon: const Icon(
                Icons.edit_outlined,
                color: primaryColor,
              ),
              tooltip: 'Chỉnh sửa tài khoản ngân hàng',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 32,
                    color: primaryColor,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Thông tin tài khoản ngân hàng',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _infoRow(
                Icons.account_balance_outlined,
                'Ngân hàng',
                bankName,
              ),
              const Divider(height: 1),
              _infoRow(
                Icons.credit_card_outlined,
                'Số tài khoản',
                bankAccount,
              ),
              const Divider(height: 1),
              _infoRow(
                Icons.person_outline,
                'Tên chủ tài khoản',
                accountHolder,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showBankDialog,
                  icon: Icon(
                    bankAccount.isEmpty
                        ? Icons.add
                        : Icons.edit_outlined,
                  ),
                  label: Text(
                    bankAccount.isEmpty
                        ? 'Thêm tài khoản ngân hàng'
                        : 'Chỉnh sửa tài khoản ngân hàng',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // LƯU Ý BẢO MẬT
  // =========================

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF9A6A00),
          ),
          const SizedBox(width: 10),
          const Expanded(
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

  // =========================
  // GIAO DIỆN CHÍNH
  // =========================

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          _sectionTitle('Thông tin cá nhân', Icons.person_outline),
          const SizedBox(height: 12),
          _buildPersonalInfo(),
          const SizedBox(height: 24),

          // Tất cả vai trò đều có phần ngân hàng.
          _buildBankInfo(),
          const SizedBox(height: 24),

          _buildPrivacyNote(),
          const SizedBox(height: 24),

          // Nút đăng xuất nằm trong trang Cá nhân.
          _buildLogoutButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
