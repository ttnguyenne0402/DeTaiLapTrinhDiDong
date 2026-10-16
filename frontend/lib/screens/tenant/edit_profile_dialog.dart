import 'package:flutter/material.dart';

class EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfileDialog({
    super.key,
    required this.initialData,
  });

  @override
  State<EditProfileDialog> createState() =>
      _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialData['Name']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialData['Email']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialData['Phone']?.toString() ?? '',
    );
    _avatarController = TextEditingController(
      text: widget.initialData['Avatar']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sửa thông tin cá nhân'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(
                controller: _nameController,
                label: 'Họ và tên',
                required: true,
              ),
              _buildField(
                controller: _emailController,
                label: 'Email',
                required: true,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildField(
                controller: _phoneController,
                label: 'Số điện thoại',
                keyboardType: TextInputType.phone,
              ),
              _buildField(
                controller: _avatarController,
                label: 'Đường dẫn ảnh đại diện',
                keyboardType: TextInputType.url,
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
          child: const Text('Lưu thay đổi'),
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

          if (label == 'Email' &&
              value != null &&
              value.trim().isNotEmpty &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value.trim())) {
            return 'Email không hợp lệ';
          }

          return null;
        },
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, <String, dynamic>{
      'Name': _nameController.text.trim(),
      'Email': _emailController.text.trim(),
      'Phone': _phoneController.text.trim(),
      'Avatar': _avatarController.text.trim(),
    });
  }
}