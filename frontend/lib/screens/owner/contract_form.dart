
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/contract_form_w.dart';

class Contract_form extends StatefulWidget {
  final Map<String, dynamic>? contract;

  const Contract_form({
    super.key,
    this.contract,
  });

  @override
  State<Contract_form> createState() => HopDongMoi();
}

class HopDongMoi extends State<Contract_form> {
  bool _agreeTerms = false;

  late final SignatureController _ownerSignatureController;
  late final SignatureController _tenantSignatureController;

  bool get _isDraft => widget.contract?['status'] == 'Bản nháp';

  bool get _isPendingSignature =>
      widget.contract?['status'] == 'Chờ ký';

  bool get _isActive => widget.contract?['status'] == 'Đang hiệu lực';

  bool get _ownerHasSigned =>
      _ownerSignatureController.points.isNotEmpty;

  bool get _tenantHasSigned =>
      _tenantSignatureController.points.isNotEmpty;

  bool get _bothSigned => _ownerHasSigned && _tenantHasSigned;

  String get _title {
    if (_isDraft) return 'Tiếp tục hợp đồng';
    if (_isPendingSignature) return 'Ký hợp đồng';
    if (_isActive) return 'Chi tiết hợp đồng';
    if (widget.contract?['status'] == 'Sắp hết hạn') {
      return 'Gia hạn hợp đồng';
    }
    return 'Tạo Hợp Đồng Mới';
  }

  @override
  void initState() {
    super.initState();

    _ownerSignatureController = SignatureController(
      penStrokeWidth: 2.5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    _tenantSignatureController = SignatureController(
      penStrokeWidth: 2.5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    _ownerSignatureController.addListener(_refreshSignatureState);
    _tenantSignatureController.addListener(_refreshSignatureState);
  }

  void _refreshSignatureState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ownerSignatureController.removeListener(_refreshSignatureState);
    _tenantSignatureController.removeListener(_refreshSignatureState);
    _ownerSignatureController.dispose();
    _tenantSignatureController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _contractData(String status) {
    return {
      ...?widget.contract,
      'status': status,
      'termsAccepted': _agreeTerms,
      'ownerSigned': _ownerHasSigned,
      'tenantSigned': _tenantHasSigned,
    };
  }

  Future<void> _saveDraft() async {
    final result = _contractData('Bản nháp');
    Navigator.pop(context, result);
  }

  Future<void> _completeContract() async {
    if (!_agreeTerms) {
      _showMessage('Vui lòng xác nhận đã phổ biến nội quy.');
      return;
    }

    final result = _contractData('Chờ ký');
    Navigator.pop(context, result);
  }

  Future<void> _signContract() async {
    if (!_agreeTerms) {
      _showMessage('Vui lòng đồng ý với điều khoản hợp đồng.');
      return;
    }

    if (!_ownerHasSigned || !_tenantHasSigned) {
      _showMessage('Cả chủ trọ và người thuê đều phải ký.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận ký hợp đồng'),
        content: const Text(
          'Hai bên đã ký và đồng ý điều khoản. '
              'Bạn có chắc chắn muốn xác nhận hợp đồng không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ownerBytes = await _ownerSignatureController.toPngBytes();
    final tenantBytes = await _tenantSignatureController.toPngBytes();

    if (ownerBytes == null || tenantBytes == null) {
      _showMessage('Không thể lưu chữ ký. Vui lòng ký lại.');
      return;
    }

    final result = <String, dynamic>{
      ..._contractData('Đang hiệu lực'),
      'ownerSignature': base64Encode(ownerBytes),
      'tenantSignature': base64Encode(tenantBytes),
      'signedAt': DateTime.now().toIso8601String(),
    };

    Navigator.pop(context, result);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            size: 26,
            color: Colors.white,
          ),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tiến độ thiết lập hợp đồng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isPendingSignature
                          ? 'Chờ ký'
                          : _isActive
                          ? 'Đang hiệu lực'
                          : _isDraft
                          ? 'Bản nháp'
                          : 'Bước 6/6 Hoàn chỉnh',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isPendingSignature
                      ? Colors.blue
                      : AppColors.accentYellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _isPendingSignature
                        ? Icons.edit_document
                        : Icons.verified_outlined,
                    size: 14,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _isPendingSignature
                          ? 'Hợp đồng đã hoàn tất, đang chờ xác nhận ký.'
                          : 'Dữ liệu đã tự động điền từ Lịch hẹn chốt cọc',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. NGUỒN TẠO VÀ LIÊN KẾT PHÒNG
              ContractFormWidgets.buildSectionCard(
                step: '1',
                title: 'Nguồn tạo & Liên kết phòng',
                subtitle: 'Xác định cơ sở và căn phòng ký kết',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.home,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.contract?['room'] ??
                                            'Phòng 201 - Tầng 2',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '25 m²',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  widget.contract?['address'] ??
                                      'Khu trọ Bình Thạnh (12 phòng)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.contract?['rentPrice'] ??
                                      '4.500.000 đ/tháng',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.brown,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Khu trọ áp dụng',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ContractFormWidgets.buildDropdownField(
                      'Khu trọ Bình Thạnh (12 phòng)',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Phòng thuê',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ContractFormWidgets.buildDropdownField(
                      widget.contract?['room'] ??
                          'Phòng 201 - Tầng 2 (Giá niêm yết: 4.500.000)',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Liên kết lịch xem phòng',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ContractFormWidgets.buildDropdownField(
                      '#AF-8823 - Nguyễn Văn An - 10:00 24/08/...',
                    ),
                  ],
                ),
              ),

              // 2. THÔNG TIN NGƯỜI THUÊ
              ContractFormWidgets.buildSectionCard(
                step: '2',
                title: 'Thông tin Người thuê & Ở ghép',
                subtitle: 'Chủ thể ký và người đồng ký tạm trú',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'NGƯỜI ĐỨNG TÊN HỢP ĐỒNG',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Chủ thuê',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ContractFormWidgets.buildTextField(
                                  'Họ và tên',
                                  widget.contract?['tenantName'] ??
                                      'Nguyễn Văn An',
                                  false,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ContractFormWidgets.buildTextField(
                                  'Số điện thoại',
                                  widget.contract?['tenantPhone'] ??
                                      '0908123456',
                                  false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ContractFormWidgets.buildTextField(
                                  'Số CCCD / CMND',
                                  '079098001234',
                                  false,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ContractFormWidgets.buildTextField(
                                  'Ngày cấp',
                                  '12/04/2021',
                                  false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ContractFormWidgets.buildTextField(
                            'Nơi cấp',
                            'Cục CSQLHC về trật tự xã hội',
                            false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Thành viên đi cùng (Khai báo tạm trú)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '1 người',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'LH',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lê Thị Hoa',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'CCCD: 079199005678 • Vợ/Bạn',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text(
                        'Thêm người ở cùng',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.lightGreen,
                        minimumSize: const Size(double.infinity, 36),
                        side: BorderSide.none,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. THỜI HẠN VÀ TIỀN
              ContractFormWidgets.buildSectionCard(
                step: '3',
                title: 'Thời hạn & Tiền phòng, Đặt cọc',
                subtitle: 'Cài đặt định kỳ và cam kết tài chính',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ContractFormWidgets.buildTextField(
                            'Ngày bắt đầu',
                            '01/09/2024',
                            true,
                            suffixIcon: Icons.calendar_today,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ContractFormWidgets.buildTextField(
                            'Ngày kết thúc',
                            '31/08/2025',
                            true,
                            suffixIcon: Icons.calendar_today,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Thời hạn hợp đồng: 12 tháng',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ContractFormWidgets.buildTextField(
                            'Giá thuê hàng tháng',
                            widget.contract?['rentPrice'] ?? '4.500.000',
                            true,
                            suffixText: 'đ',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ContractFormWidgets.buildTextField(
                            'Tiền đặt cọc (Deposit)',
                            widget.contract?['depositPrice'] ?? '9.000.000',
                            true,
                            suffixText: 'đ',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Đã thu đủ cọc ngày 25/08/2024',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Đã xác nhận',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kỳ thanh toán tiền trọ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ContractFormWidgets.buildDropdownField(
                      'Hàng tháng (Từ ngày 01 đến 05)',
                    ),
                  ],
                ),
              ),

              // 4. ĐIỆN NƯỚC
              ContractFormWidgets.buildSectionCard(
                step: '4',
                title: 'Chỉ số điện nước ban đầu bàn giao',
                subtitle: 'Chốt mốc bàn giao thiết bị phòng',
                content: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildUtilityBox(
                            icon: Icons.flash_on,
                            title: 'Điện ban đầu',
                            value: '1420',
                            unit: 'kWh',
                            iconColor: AppColors.accentYellow,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildUtilityBox(
                            icon: Icons.water_drop,
                            title: 'Nước ban đầu',
                            value: '85',
                            unit: 'm³',
                            iconColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ngày chốt chỉ số bàn giao:',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '01/09/2024',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 5. DỊCH VỤ
              ContractFormWidgets.buildSectionCard(
                step: '5',
                title: 'Bảng dịch vụ áp dụng riêng',
                subtitle: 'Thời giá dịch vụ bám theo phòng 201',
                content: Column(
                  children: [
                    ContractFormWidgets.buildServiceRow(
                      Icons.flash_on,
                      'Điện sinh hoạt',
                      '3.800 đ / kWh',
                    ),
                    ContractFormWidgets.buildServiceRow(
                      Icons.water_drop,
                      'Nước sinh hoạt',
                      '35.000 đ / m³',
                    ),
                    ContractFormWidgets.buildServiceRow(
                      Icons.wifi,
                      'Internet / Wifi',
                      '100.000 đ / phòng / tháng',
                    ),
                    ContractFormWidgets.buildServiceRow(
                      Icons.cleaning_services,
                      'Phí vệ sinh, rác',
                      '50.000 đ / phòng',
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Thêm dịch vụ khác',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.lightGreen,
                        minimumSize: const Size(double.infinity, 36),
                        side: BorderSide.none,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 6. ĐIỀU KHOẢN
              ContractFormWidgets.buildSectionCard(
                step: '6',
                title: 'Điều khoản hợp đồng & Quy định trọ',
                subtitle: 'Các cam kết an toàn & nội quy phòng trọ',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          ContractFormWidgets.buildRuleItem(
                            Icons.security,
                            'An toàn PCCC:',
                            'Nghiêm cấm đun nấu bằng bếp gas, tắt toàn bộ thiết bị điện có công suất lớn khi ra khỏi phòng.',
                          ),
                          const SizedBox(height: 6),
                          ContractFormWidgets.buildRuleItem(
                            Icons.access_time,
                            'Giờ giấc & Trật tự:',
                            'Cửa đóng tự động lúc 22:30. Giữ yên lặng chung sau 22:00, không tổ chức tiệc tùng gây mất trật tự.',
                          ),
                          const SizedBox(height: 6),
                          ContractFormWidgets.buildRuleItem(
                            Icons.policy,
                            'Chính sách hoàn cọc:',
                            'Khách thuê muốn chấm dứt hợp đồng phải thông báo trước tối thiểu 30 ngày để nhận hoàn lại 100% tiền cọc.',
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: Checkbox(
                            value: _agreeTerms,
                            activeColor: AppColors.primaryGreen,
                            onChanged: (value) {
                              setState(() {
                                _agreeTerms = value ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tôi đã phổ biến và gửi kèm bộ Nội quy cho khách thuê.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 7. KHU VỰC KÝ
              if (_isPendingSignature) _buildSignatureSection(),

              if (_isActive) _buildActiveContractInfo(),

              const SizedBox(height: 16),
              _buildBottomButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityBox({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Xác nhận ký hợp đồng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Cả chủ trọ và người thuê cần ký vào vùng tương ứng bên dưới.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          _buildSignatureBox(
            title: 'Chữ ký chủ trọ',
            controller: _ownerSignatureController,
            hasSigned: _ownerHasSigned,
          ),

          const SizedBox(height: 14),

          _buildSignatureBox(
            title: 'Chữ ký người thuê',
            controller: _tenantSignatureController,
            hasSigned: _tenantHasSigned,
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _agreeTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeTerms = value ?? false;
                      });
                    },
                    activeColor: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tôi xác nhận thông tin chính xác và đồng ý với điều khoản hợp đồng.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Trạng thái: ${_ownerHasSigned ? "Chủ trọ đã ký" : "Chủ trọ chưa ký"} • ${_tenantHasSigned ? "Người thuê đã ký" : "Người thuê chưa ký"}',
            style: TextStyle(
              fontSize: 11,
              color: _bothSigned ? Colors.green.shade700 : Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureBox({
    required String title,
    required SignatureController controller,
    required bool hasSigned,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasSigned ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                hasSigned ? Icons.check_circle : Icons.edit,
                size: 17,
                color: hasSigned ? Colors.green : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 140,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Signature(
              controller: controller,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vẽ chữ ký vào khung trên',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  controller.clear();
                },
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text(
                  'Ký lại',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContractInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hợp đồng đang có hiệu lực. Mọi khoản tiền thuê, điện nước và dịch vụ sẽ được tính theo hợp đồng này.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_isPendingSignature) {
      final canSign = _agreeTerms && _bothSigned;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canSign ? _signContract : null,
          icon: const Icon(Icons.draw, size: 18, color: Colors.white),
          label: Text(
            canSign
                ? 'Xác nhận ký hợp đồng'
                : 'Cần đủ 2 chữ ký và đồng ý điều khoản',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            disabledBackgroundColor: Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    if (_isActive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showTerminateDialog,
          icon: const Icon(
            Icons.assignment_return_outlined,
            size: 18,
            color: Colors.white,
          ),
          label: const Text(
            'Thanh lý hợp đồng',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text(
              'Lưu bản nháp',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.primaryGreen),
              foregroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _completeContract,
            icon: const Icon(Icons.check, size: 16, color: Colors.white),
            label: const Text(
              'Hoàn tất & Gửi ký',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTerminateDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thanh lý hợp đồng'),
        content: const Text(
          'Bạn muốn chuyển hợp đồng này sang trạng thái đã thanh lý?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final result = {
                ..._contractData('Đã thanh lý'),
                'terminatedAt': DateTime.now().toIso8601String(),
              };
              Navigator.pop(dialogContext);
              Navigator.pop(this.context, result);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text(
              'Thanh lý',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
