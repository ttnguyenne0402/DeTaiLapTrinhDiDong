
import 'package:flutter/material.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  static const Color primaryColor = Color(0xFF1B5E55);
  static const Color backgroundColor = Color(0xFFF7F9F8);

  String name = 'Nguyễn Văn A';
  String email = 'nguyenvana@gmail.com';
  String phone = '0901234567';

  String bankName = '';
  String bankAccount = '';
  String accountHolder = '';

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameController, 'Họ và tên', Icons.person_outline),
              const SizedBox(height: 12),
              _dialogField(emailController, 'Email', Icons.email_outlined),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;

              setState(() {
                name = nameController.text.trim();
                email = emailController.text.trim();
                phone = phoneController.text.trim();
              });

              Navigator.pop(dialogContext);
              _showMessage('Đã cập nhật thông tin trên giao diện');
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showBankDialog() {
    final bankController = TextEditingController(text: bankName);
    final accountController = TextEditingController(text: bankAccount);
    final holderController = TextEditingController(text: accountHolder);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          bankAccount.isEmpty ? 'Thêm tài khoản ngân hàng' : 'Sửa tài khoản ngân hàng',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
            onPressed: () => Navigator.pop(dialogContext),
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
                return;
              }

              setState(() {
                bankName = bankController.text.trim();
                bankAccount = accountController.text.trim();
                accountHolder = holderController.text.trim().toUpperCase();
              });

              Navigator.pop(dialogContext);
              _showMessage('Đã cập nhật thông tin ngân hàng trên giao diện');
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF26332F),
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
                    color: value.isEmpty ? Colors.grey : const Color(0xFF26332F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
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
          // Thông tin chủ trọ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E55), Color(0xFF2D8271)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFE6F0EB),
                    child: Icon(
                      Icons.person,
                      size: 42,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                            color: Color(0xFFFFD166),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Chủ trọ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
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
          ),

          const SizedBox(height: 24),

          // Thông tin cá nhân
          _sectionTitle('Thông tin cá nhân', Icons.person_outline),
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
                _infoRow(Icons.badge_outlined, 'Họ và tên', name),
                const Divider(height: 1),
                _infoRow(Icons.email_outlined, 'Email', email),
                const Divider(height: 1),
                _infoRow(Icons.phone_outlined, 'Số điện thoại', phone),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Thông tin ngân hàng
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
                tooltip: 'Chỉnh sửa ngân hàng',
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 32,
                        color: primaryColor,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tài khoản nhận tiền thuê phòng',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Lưu ý bảo mật
          Container(
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
                    'Kiểm tra kỹ thông tin ngân hàng trước khi sử dụng '
                    'để nhận tiền thuê phòng. Không chia sẻ mật khẩu '
                    'hoặc mã OTP cho người khác.',
                    style: TextStyle(
                      color: Color(0xFF73551A),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
