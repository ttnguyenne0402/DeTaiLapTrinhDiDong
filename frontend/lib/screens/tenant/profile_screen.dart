
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/tenant/profile_info_card.dart';
import '../../widgets/tenant/bank_account_card.dart';
import '../auth/login_screen.dart';
import 'edit_profile_dialog.dart';
import 'bank_account_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>> bankAccounts;

  const ProfileScreen({
    super.key,
    this.user,
    this.bankAccounts = const [],
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _userData;
  late List<Map<String, dynamic>> _bankAccounts;

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

    _bankAccounts = widget.bankAccounts
        .map((account) => Map<String, dynamic>.from(account))
        .toList();

    if (_bankAccounts.isNotEmpty &&
        !_bankAccounts.any(
          (account) => account['IsDefault'] == true,
        )) {
      _bankAccounts.first['IsDefault'] = true;
    }
  }

  // =========================
  // SỬA THÔNG TIN CÁ NHÂN
  // =========================

  Future<void> _editProfile() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EditProfileDialog(
        initialData: _userData,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _userData.addAll(result);
    });

    _showMessage('Đã cập nhật thông tin trên giao diện.');
  }

  // =========================
  // THÊM TÀI KHOẢN NGÂN HÀNG
  // =========================

  Future<void> _addBankAccount() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const BankAccountDialog(),
    );

    if (result == null || !mounted) return;

    setState(() {
      result['Id'] ??=
          'LOCAL_${DateTime.now().microsecondsSinceEpoch}';

      if (result['IsDefault'] == true ||
          _bankAccounts.isEmpty) {
        for (final account in _bankAccounts) {
          account['IsDefault'] = false;
        }

        result['IsDefault'] = true;
      }

      _bankAccounts.add(result);
    });

    _showMessage('Đã thêm tài khoản ngân hàng.');
  }

  // =========================
  // SỬA TÀI KHOẢN NGÂN HÀNG
  // =========================

  Future<void> _editBankAccount(int index) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => BankAccountDialog(
        account: Map<String, dynamic>.from(
          _bankAccounts[index],
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (result['IsDefault'] == true) {
        for (final account in _bankAccounts) {
          account['IsDefault'] = false;
        }
      }

      _bankAccounts[index] = result;
    });

    _showMessage('Đã cập nhật tài khoản ngân hàng.');
  }

  // =========================
  // ĐẶT TÀI KHOẢN MẶC ĐỊNH
  // =========================

  void _setDefaultBankAccount(int index) {
    setState(() {
      for (int i = 0; i < _bankAccounts.length; i++) {
        _bankAccounts[i]['IsDefault'] = i == index;
      }
    });

    _showMessage('Đã đổi tài khoản mặc định.');
  }

  // =========================
  // XÓA TÀI KHOẢN NGÂN HÀNG
  // =========================

  Future<void> _deleteBankAccount(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text(
          'Em có chắc muốn xóa tài khoản ngân hàng này không?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      final wasDefault =
          _bankAccounts[index]['IsDefault'] == true;

      _bankAccounts.removeAt(index);

      if (wasDefault && _bankAccounts.isNotEmpty) {
        _bankAccounts.first['IsDefault'] = true;
      }
    });

    _showMessage('Đã xóa tài khoản ngân hàng.');
  }

  // =========================
  // ĐĂNG XUẤT
  // =========================

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Em có chắc muốn đăng xuất không?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // =========================
  // THÔNG BÁO
  // =========================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // =========================
  // GIAO DIỆN
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        title: const Text(
          'Cá nhân',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // THÔNG TIN CÁ NHÂN
          ProfileInfoCard(
            user: _userData,
            onEdit: _editProfile,
          ),

          const SizedBox(height: 24),

          // TÀI KHOẢN NGÂN HÀNG
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tài khoản ngân hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              FilledButton.icon(
                onPressed: _addBankAccount,
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text('Thêm'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // DANH SÁCH TÀI KHOẢN NGÂN HÀNG
          if (_bankAccounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 42,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Chưa có tài khoản ngân hàng',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Thêm tài khoản để quản lý thông tin nhận tiền.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(
              _bankAccounts.length,
              (index) => BankAccountCard(
                account: _bankAccounts[index],
                onEdit: () => _editBankAccount(index),
                onSetDefault: () {
                  _setDefaultBankAccount(index);
                },
                onDelete: () {
                  _deleteBankAccount(index);
                },
              ),
            ),

          const SizedBox(height: 28),

          // NÚT ĐĂNG XUẤT
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(
                color: Colors.red,
              ),
              minimumSize: const Size(
                double.infinity,
                48,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
