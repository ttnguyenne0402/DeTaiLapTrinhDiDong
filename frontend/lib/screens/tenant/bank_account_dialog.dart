import 'package:flutter/material.dart';

class BankAccountDialog extends StatefulWidget {
  final Map<String, dynamic>? account;

  const BankAccountDialog({
    super.key,
    this.account,
  });

  @override
  State<BankAccountDialog> createState() =>
      _BankAccountDialogState();
}

class _BankAccountDialogState
    extends State<BankAccountDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _bankCodeController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _accountHolderController;

  late bool _isDefault;

  @override
  void initState() {
    super.initState();

    final account = widget.account ?? {};

    _bankCodeController = TextEditingController(
      text: account['BankCode']?.toString() ?? '',
    );
    _bankNameController = TextEditingController(
      text: account['BankName']?.toString() ?? '',
    );
    _accountNumberController = TextEditingController(
      text: account['AccountNumber']?.toString() ?? '',
    );
    _accountHolderController = TextEditingController(
      text: account['AccountHolder']?.toString() ?? '',
    );

    _isDefault = account['IsDefault'] == true;
  }

  @override
  void dispose() {
    _bankCodeController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? 'Sửa tài khoản ngân hàng'
            : 'Thêm tài khoản ngân hàng',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(
                controller: _bankCodeController,
                label: 'Mã ngân hàng',
                required: true,
              ),
              _buildField(
                controller: _bankNameController,
                label: 'Tên ngân hàng',
              ),
              _buildField(
                controller: _accountNumberController,
                label: 'Số tài khoản',
                required: true,
                keyboardType: TextInputType.number,
              ),
              _buildField(
                controller: _accountHolderController,
                label: 'Tên chủ tài khoản',
                required: true,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                title: const Text(
                  'Đặt làm tài khoản mặc định',
                ),
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required &&
              (value == null || value.trim().isEmpty)) {
            return 'Vui lòng nhập $label';
          }

          return null;
        },
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, <String, dynamic>{
      if (widget.account?['Id'] != null)
        'Id': widget.account!['Id'],
      if (widget.account?['UserId'] != null)
        'UserId': widget.account!['UserId'],
      'BankCode': _bankCodeController.text.trim(),
      'BankName': _bankNameController.text.trim(),
      'AccountNumber': _accountNumberController.text.trim(),
      'AccountHolder': _accountHolderController.text.trim(),
      'IsDefault': _isDefault,
      'Status': widget.account?['Status'] ?? 'ACTIVE',
    });
  }
}