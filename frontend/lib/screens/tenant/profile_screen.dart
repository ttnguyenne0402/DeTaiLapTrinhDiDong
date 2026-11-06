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

  String bankName = '';
  String bankAccount = '';
  String accountHolder = '';
  String? _bankAccountId;

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

      final dynamic bankAccounts = data['bankAccounts'];

      Map<String, dynamic>? selectedBank;

      if (bankAccounts is List) {
        final accounts = bankAccounts
            .whereType<Map<String, dynamic>>()
            .toList();

        for (final account in accounts) {
          if (account['isDefault'] == true) {
            selectedBank = account;
            break;
          }
        }

        selectedBank ??= accounts.isNotEmpty ? accounts.first : null;
      }

      setState(() {
        _userData = {
          'Id': data['id'] ?? '',
          'Name': data['name'] ?? 'Người dùng',
          'Email': data['email'] ?? '',
          'Phone': data['phone'] ?? '',
          'Avatar': data['avatar'] ?? '',
          'Role': data['role'] ?? 'tenant',
        };

        if (selectedBank != null) {
          _bankAccountId = selectedBank['id']?.toString();

          bankName =
              (selectedBank['bankName'] ?? selectedBank['bankCode'] ?? '')
                  .toString();

          bankAccount = (selectedBank['accountNumber'] ?? '').toString();

          accountHolder = (selectedBank['accountHolder'] ?? '').toString();
        } else {
          _bankAccountId = null;
          bankName = '';
          bankAccount = '';
          accountHolder = '';
        }

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

  Future<void> _showBankDialog() async {
    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return BankDialog(
          bankName: bankName,
          bankAccount: bankAccount,
          accountHolder: accountHolder,
        );
      },
    );

    if (!mounted || result == null) return;

    try {
      final newBankName = result['bankName'] ?? '';
      final newBankAccount = result['bankAccount'] ?? '';
      final newAccountHolder = result['accountHolder'] ?? '';

      Map<String, dynamic> savedBank;

      if (_bankAccountId == null || _bankAccountId!.isEmpty) {
        // Chưa có tài khoản: gọi API thêm mới
        savedBank = await ProfileService.addBankAccount(
          bankName: newBankName,
          accountNumber: newBankAccount,
          accountHolder: newAccountHolder,
        );
      } else {
        // Đã có tài khoản: gọi API cập nhật
        savedBank = await ProfileService.updateBankAccount(
          id: _bankAccountId!,
          bankName: newBankName,
          accountNumber: newBankAccount,
          accountHolder: newAccountHolder,
        );
      }

      if (!mounted) return;

      setState(() {
        bankName = newBankName;
        bankAccount = newBankAccount;
        accountHolder = newAccountHolder;

        _bankAccountId = savedBank['id']?.toString() ?? _bankAccountId;
      });

      _showMessage('Lưu tài khoản ngân hàng thành công.');
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
  // THÔNG TIN NGÂN HÀNG
  // =====================================================

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
              icon: const Icon(Icons.edit_outlined, color: primaryColor),
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
                  Icon(Icons.account_balance, size: 32, color: primaryColor),
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
              _infoRow(Icons.account_balance_outlined, 'Ngân hàng', bankName),
              const Divider(height: 1),
              _infoRow(Icons.credit_card_outlined, 'Số tài khoản', bankAccount),
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
                    bankAccount.isEmpty ? Icons.add : Icons.edit_outlined,
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
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showDialogMessage('Họ và tên không được để trống');
      return;
    }

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
  }) {
    return TextField(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa thông tin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_nameController, 'Họ và tên', Icons.person_outline),
            const SizedBox(height: 12),
            _field(
              _emailController,
              'Email',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _field(
              _phoneController,
              'Số điện thoại',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ],
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

  const BankDialog({
    super.key,
    required this.bankName,
    required this.bankAccount,
    required this.accountHolder,
  });

  @override
  State<BankDialog> createState() => _BankDialogState();
}

class _BankDialogState extends State<BankDialog> {
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
    final bank = _bankController.text.trim();
    final account = _accountController.text.trim();
    final holder = _holderController.text.trim();

    if (bank.isEmpty || account.isEmpty || holder.isEmpty) {
      _showDialogMessage('Vui lòng nhập đầy đủ thông tin ngân hàng');
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
  }) {
    return TextField(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(
              _bankController,
              'Tên ngân hàng',
              Icons.account_balance_outlined,
              hint: 'Ví dụ: Vietcombank',
            ),
            const SizedBox(height: 12),
            _field(
              _accountController,
              'Số tài khoản',
              Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field(
              _holderController,
              'Tên chủ tài khoản',
              Icons.person_outline,
            ),
          ],
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
