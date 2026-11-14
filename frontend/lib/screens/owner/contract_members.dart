import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/contract_service.dart';

class TenantManagementScreen extends StatefulWidget {
  final Map<String, dynamic>? contract;

  const TenantManagementScreen({super.key, this.contract});

  @override
  State<TenantManagementScreen> createState() => _TenantManagementScreenState();
}

class _TenantManagementScreenState extends State<TenantManagementScreen> {
  Map<String, dynamic> get _c => widget.contract ?? {};
  String get _contractId => (_c['id'] ?? _c['code'] ?? '').toString();

  List<dynamic> _members = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    if (_contractId.isEmpty) return;
    setState(() => _isLoading = true);
    final list = await ContractService.getContractMembers(_contractId);
    if (mounted) {
      setState(() {
        _members = list;
        _isLoading = false;
      });
    }
  }

  // BottomSheet Thêm người ở ghép chuẩn chỉnh
  void _showAddMemberBottomSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final cccdController = TextEditingController();
    String selectedRelationship = 'Bạn cùng phòng';

    bool frontCccdUploaded = false;
    bool backCccdUploaded = false;

    final relationships = ['Bạn cùng phòng', 'Vợ / Chồng', 'Anh / Em', 'Người thân khác'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.person_add_alt_1, color: AppColors.primaryGreen, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Thêm thành viên ở cùng',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Text(
                  'Khai báo lưu trú và đăng ký tạm trú cho phòng',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Họ và tên
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên thành viên (*)',
                    hintText: 'VD: Lê Thị Hoa',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Số điện thoại & CCCD
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại',
                          hintText: '0908xxxxxx',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cccdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Số CCCD (12 số)',
                          hintText: '079xxxxxxxxx',
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quan hệ với chủ hộ
                DropdownButtonFormField<String>(
                  value: selectedRelationship,
                  decoration: InputDecoration(
                    labelText: 'Mối quan hệ với đại diện hợp đồng',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: relationships.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRelationship = val);
                  },
                ),
                const SizedBox(height: 16),

                // Khu vực tải ảnh CCCD 2 mặt
                const Text('Ảnh chụp CCCD 2 mặt (Lưu trữ xác thực)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setModalState(() => frontCccdUploaded = !frontCccdUploaded);
                        },
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: frontCccdUploaded ? Colors.green.shade50 : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: frontCccdUploaded ? AppColors.primaryGreen : Colors.grey.shade300, width: 1.2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(frontCccdUploaded ? Icons.check_circle : Icons.add_a_photo_outlined, color: frontCccdUploaded ? AppColors.primaryGreen : Colors.grey, size: 24),
                              const SizedBox(height: 4),
                              Text(frontCccdUploaded ? 'Đã tải mặt trước' : 'Mặt trước CCCD', style: TextStyle(fontSize: 11, color: frontCccdUploaded ? AppColors.primaryGreen : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setModalState(() => backCccdUploaded = !backCccdUploaded);
                        },
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: backCccdUploaded ? Colors.green.shade50 : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: backCccdUploaded ? AppColors.primaryGreen : Colors.grey.shade300, width: 1.2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(backCccdUploaded ? Icons.check_circle : Icons.add_a_photo_outlined, color: backCccdUploaded ? AppColors.primaryGreen : Colors.grey, size: 24),
                              const SizedBox(height: 4),
                              Text(backCccdUploaded ? 'Đã tải mặt sau' : 'Mặt sau CCCD', style: TextStyle(fontSize: 11, color: backCccdUploaded ? AppColors.primaryGreen : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nút Thêm
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập họ và tên thành viên.')),
                        );
                        return;
                      }

                      final body = {
                        'fullName': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'cccd': cccdController.text.trim(),
                        'relationship': selectedRelationship,
                      };

                      final success = await ContractService.addContractMember(_contractId, body);
                      if (mounted) {
                        Navigator.pop(ctx);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã thêm thành viên ở cùng vào phòng!')),
                          );
                          _fetchMembers();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lỗi khi lưu dữ liệu thành viên.')),
                          );
                        }
                      }
                    },
                    child: const Text('Xác nhận thêm thành viên', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMember(String memberId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thành viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Bạn có chắc muốn xóa "$name" khỏi danh sách lưu trú của phòng này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ContractService.deleteContractMember(memberId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa thành viên khỏi phòng.')),
          );
          _fetchMembers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi xóa thành viên.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomName = _c['room'] ?? 'Phòng trọ';
    final code = _c['code'] ?? '';
    final tenantName = _c['tenantName'] ?? 'Người đại diện';
    final tenantPhone = _c['tenantPhone'] ?? 'Chưa rõ';
    final totalPeople = 1 + _members.length;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cardSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Người ở cùng',
          style: TextStyle(color: AppColors.cardSurface, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 1. Thẻ thông tin phòng
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.meeting_room, color: AppColors.accentYellow, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    roomName,
                                    style: const TextStyle(color: AppColors.cardSurface, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'HĐ $code',
                                  style: const TextStyle(color: AppColors.cardSurface, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tổng nhân khẩu lưu trú: $totalPeople người (1 đại diện + ${_members.length} ở ghép)',
                            style: const TextStyle(color: AppColors.cardSurface, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Thẻ chủ hộ đứng tên
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.badge, color: AppColors.primaryGreen, size: 18),
                                  SizedBox(width: 6),
                                  Text('Đại diện hợp đồng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Chủ hộ đứng tên', style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.lightGreen,
                                child: Icon(Icons.person, color: AppColors.primaryGreen, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tenantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                    Text('SĐT: $tenantPhone', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Danh sách người ở cùng động
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.group_add, color: AppColors.primaryGreen, size: 18),
                            SizedBox(width: 6),
                            Text('Người ở cùng (Ở ghép)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                          ],
                        ),
                        Text('${_members.length} thành viên', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_members.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.people_outline, size: 36, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Chưa có người ở ghép nào trong phòng.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),

                    ..._members.map((mem) {
                      final mId = (mem['id'] ?? mem['Id'] ?? '').toString();
                      final mName = (mem['name'] ?? mem['Name'] ?? 'Chưa rõ').toString();
                      final mPhone = (mem['phone'] ?? mem['Phone'] ?? 'Chưa có SĐT').toString();
                      final mCccd = (mem['identityCard'] ?? mem['IdentityCard'] ?? '').toString();
                      final mRel = (mem['relationship'] ?? mem['Relationship'] ?? 'Ở chung').toString();

                      return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.lightGreen,
                                child: Icon(Icons.person_outline, color: AppColors.primaryGreen, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(mName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(mRel, style: const TextStyle(color: AppColors.warningOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('SĐT: $mPhone', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                    if (mCccd.isNotEmpty)
                                      Text('CCCD: $mCccd (Đã xác minh)', style: const TextStyle(color: AppColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                onPressed: () => _deleteMember(mId, mName),
                              ),
                            ],
                          ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // Nút thêm nhanh
                    InkWell(
                      onTap: _showAddMemberBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_alt_1, color: AppColors.primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text('+ Thêm thành viên ở ghép mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryGreen)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _showAddMemberBottomSheet,
            icon: const Icon(Icons.person_add, size: 18, color: Colors.white),
            label: const Text('Thêm người ở ghép', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}