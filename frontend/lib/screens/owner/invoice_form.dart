import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/owner/invoice_service.dart';
import '../../widgets/owner/invoice_form_w.dart';
import '../../screens/owner/invoices_manage..dart';

class Invoice_form extends StatefulWidget {
  final InvoiceData? invoice;
  final String? contractId;

  const Invoice_form({super.key, required this.invoice, this.contractId});

  @override
  State<Invoice_form> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<Invoice_form> {
  final TextEditingController _dienCuController = TextEditingController(text: '0');
  final TextEditingController _dienMoiController = TextEditingController(text: '0');

  final TextEditingController _nuocCuController = TextEditingController(text: '0');
  final TextEditingController _nuocMoiController = TextEditingController(text: '0');

  final TextEditingController _discountController = TextEditingController(text: '0');

  final ImagePicker _picker = ImagePicker();

  String? _dienImagePath;
  String? _nuocImagePath;

  bool _isLoading = false;
  String? _selectedPropertyId;
  String? _selectedContractId;

  // Danh sách tài khoản ngân hàng & tài khoản được chọn
  List<dynamic> _bankAccounts = [];
  String? _selectedBankAccountId;

  var _activeContracts = [];
  var _otherServices = [];

  String _roomName = 'Chưa chọn phòng';
  String _tenantName = '';
  String _tenantPhone = '';
  double _rentPrice = 0.0;
  double _electricUnitPrice = 3800.0;
  double _waterUnitPrice = 25000.0;

  @override
  void initState() {
    super.initState();
    _selectedContractId = widget.contractId ?? widget.invoice?.id;
    _initData();

    _dienCuController.addListener(() => setState(() {}));
    _dienMoiController.addListener(() => setState(() {}));
    _nuocCuController.addListener(() => setState(() {}));
    _nuocMoiController.addListener(() => setState(() {}));
    _discountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _dienCuController.dispose();
    _dienMoiController.dispose();
    _nuocCuController.dispose();
    _nuocMoiController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  // Danh sách Khu trọ
  get _propertiesList {
    final propMap = {};

    for (var c in _activeContracts) {
      final pId = c['propertyId']?.toString() ?? '';
      final pName = c['propertyName']?.toString() ?? 'Khu trọ';

      if (pId.isNotEmpty) {
        propMap[pId] = pName;
      }
    }

    return propMap.entries
        .map((e) => {
      'id': e.key.toString(),
      'name': e.value.toString(),
    })
        .toList();
  }

  // Lọc phòng theo Khu trọ
  get _filteredRooms {
    if (_selectedPropertyId == null || _selectedPropertyId!.isEmpty) return [];
    return _activeContracts
        .where((c) => c['propertyId']?.toString() == _selectedPropertyId)
        .toList();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);

    // 1. Tải danh sách hợp đồng đang hoạt động
    final contractsRes = await OwnerInvoiceService.getActiveContracts();

    // 2. Tải danh sách tài khoản ngân hàng của chủ trọ
    try {
      final banksRes = await OwnerInvoiceService.getBankAccounts();
      if (banksRes != null && banksRes is List) {
        _bankAccounts = banksRes;
        if (_bankAccounts.isNotEmpty) {
          final defaultBank = _bankAccounts.firstWhere(
                (b) => b['isDefault'] == true || b['is_default'] == 1 || b['is_default'] == true,
            orElse: () => _bankAccounts.first,
          );
          _selectedBankAccountId = (defaultBank['id'] ?? '').toString();
        }
      }
    } catch (_) {}

    if (mounted && contractsRes != null && contractsRes.isNotEmpty) {
      _activeContracts = contractsRes;

      if (_selectedContractId != null && _selectedContractId!.isNotEmpty) {
        final matched = _activeContracts.firstWhere(
              (c) => c['contractId']?.toString() == _selectedContractId,
          orElse: () => null,
        );
        if (matched != null) {
          _selectedPropertyId = matched['propertyId']?.toString();
        }
      } else {
        final firstContract = _activeContracts.first;
        _selectedPropertyId = firstContract['propertyId']?.toString();
        _selectedContractId = firstContract['contractId']?.toString();
      }

      if (_selectedContractId != null && _selectedContractId!.isNotEmpty) {
        await _loadPreviousReading(_selectedContractId!);
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseNumStr(dynamic val) {
    if (val == null) return '0';
    if (val is num) return val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2);
    final parsed = double.tryParse(val.toString()) ?? 0;
    return parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2);
  }

  Future<void> _loadPreviousReading(String contractId) async {
    setState(() => _isLoading = true);

    final data = await OwnerInvoiceService.getPreviousReading(contractId);
    if (mounted && data != null && data is Map) {
      setState(() {
        _roomName = data['roomName']?.toString() ?? 'Phòng';
        _tenantName = data['tenantName']?.toString() ?? 'Khách thuê';
        _tenantPhone = data['tenantPhone']?.toString() ?? '';
        _rentPrice = (data['rentPrice'] is num) ? (data['rentPrice'] as num).toDouble() : 0.0;
        _electricUnitPrice = (data['electricUnitPrice'] is num) ? (data['electricUnitPrice'] as num).toDouble() : 3800.0;
        _waterUnitPrice = (data['waterUnitPrice'] is num) ? (data['waterUnitPrice'] as num).toDouble() : 25000.0;
        _otherServices = (data['otherServices'] ?? []);

        final oldElRaw = data['oldElectric'] ??
            data['oldElectricity'] ??
            data['electricityOld'] ??
            data['initialElectricityReading'] ??
            data['initial_electricity_reading'] ??
            0;

        final oldWtRaw = data['oldWater'] ??
            data['waterOld'] ??
            data['initialWaterReading'] ??
            data['initial_water_reading'] ??
            0;

        final oldEl = _parseNumStr(oldElRaw);
        final oldWt = _parseNumStr(oldWtRaw);

        _dienCuController.text = oldEl;
        _nuocCuController.text = oldWt;
        _dienMoiController.text = oldEl;
        _nuocMoiController.text = oldWt;

        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _electricUsage {
    final oldVal = double.tryParse(_dienCuController.text) ?? 0;
    final newVal = double.tryParse(_dienMoiController.text) ?? 0;
    return (newVal > oldVal) ? (newVal - oldVal) : 0;
  }

  double get _waterUsage {
    final oldVal = double.tryParse(_nuocCuController.text) ?? 0;
    final newVal = double.tryParse(_nuocMoiController.text) ?? 0;
    return (newVal > oldVal) ? (newVal - oldVal) : 0;
  }

  double get _totalElectricAmount => _electricUsage * _electricUnitPrice;
  double get _totalWaterAmount => _waterUsage * _waterUnitPrice;

  double get _totalServicesAmount {
    double sum = 0;
    for (var s in _otherServices) {
      if (s['price'] is num) sum += (s['price'] as num).toDouble();
    }
    return sum;
  }

  double get _subtotal => _rentPrice + _totalElectricAmount + _totalWaterAmount + _totalServicesAmount;
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _finalTotal => (_subtotal - _discount) > 0 ? (_subtotal - _discount) : 0;

  String _formatMoney(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    )} đ';
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          if (type == 'điện') {
            _dienImagePath = image.path;
          } else {
            _nuocImagePath = image.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh: $e')));
      }
    }
  }

  void _showImagePickerSheet(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cập nhật ảnh chỉ số $type', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                  title: const Text('Chụp ảnh từ Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(type, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primaryGreen),
                  title: const Text('Chọn ảnh từ Thư viện'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(type, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitInvoice(String status) async {
    if (_selectedContractId == null || _selectedContractId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng để lập hóa đơn!')),
      );
      return;
    }

    final newEl = double.tryParse(_dienMoiController.text) ?? 0;
    final newWt = double.tryParse(_nuocMoiController.text) ?? 0;
    final oldEl = double.tryParse(_dienCuController.text) ?? 0;
    final oldWt = double.tryParse(_nuocCuController.text) ?? 0;

    if (newEl < oldEl || newWt < oldWt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ số mới không được nhỏ hơn chỉ số cũ!')),
      );
      return;
    }

    final now = DateTime.now();

    final body = {
      'contractId': _selectedContractId,
      'month': now.month,
      'year': now.year,
      'oldElectric': oldEl,
      'newElectric': newEl,
      'oldWater': oldWt,
      'newWater': newWt,
      'discountAmount': _discount,
      'status': status,
      'bankAccountId': _selectedBankAccountId, // Đính kèm ID tài khoản ngân hàng được chọn
    };

    setState(() => _isLoading = true);
    final res = await OwnerInvoiceService.createInvoice(body);
    setState(() => _isLoading = false);

    if (mounted) {
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'draft' ? 'Đã lưu hóa đơn nháp!' : 'Đã phát hành hóa đơn thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi lập hóa đơn. Vui lòng kiểm tra lại!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        ),
        title: const Text(
          'Ghi Điện Nước Lập Hóa Đơn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LẬP HÓA ĐƠN MỚI',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                          ),
                        ),
                        Text(
                          'Kỳ thu: T${now.month.toString().padLeft(2, '0')}/${now.year}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // KHU VỰC CHỌN KHU TRỌ, PHÒNG & TÀI KHOẢN NGÂN HÀNG
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Chọn Khu trọ / Tòa nhà',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                isExpanded: true,
                                hint: const Text('Chọn khu trọ'),
                                value: _selectedPropertyId,
                                items: [
                                  for (var p in _propertiesList)
                                    DropdownMenuItem(
                                      value: p['id'].toString(),
                                      child: Text(
                                        p['name'].toString(),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                                onChanged: (propId) {
                                  if (propId != null && propId != _selectedPropertyId) {
                                    setState(() {
                                      _selectedPropertyId = propId.toString();
                                      final roomsInProp = _activeContracts
                                          .where((c) => c['propertyId']?.toString() == propId.toString())
                                          .toList();
                                      if (roomsInProp.isNotEmpty) {
                                        _selectedContractId = roomsInProp.first['contractId']?.toString();
                                        _loadPreviousReading(_selectedContractId!);
                                      } else {
                                        _selectedContractId = null;
                                        _dienCuController.text = '0';
                                        _nuocCuController.text = '0';
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            '2. Chọn Phòng đang thuê',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                isExpanded: true,
                                hint: const Text('Chọn phòng'),
                                value: _selectedContractId,
                                items: [
                                  for (var c in _filteredRooms)
                                    DropdownMenuItem(
                                      value: c['contractId'].toString(),
                                      child: Text(
                                        '${c['roomName'] ?? 'Phòng'} - ${c['tenantName'] ?? 'Khách'}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary),
                                      ),
                                    ),
                                ],
                                onChanged: (contractId) {
                                  if (contractId != null) {
                                    setState(() => _selectedContractId = contractId.toString());
                                    _loadPreviousReading(contractId.toString());
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: AppColors.primaryGreen),
                              const SizedBox(width: 6),
                              Text('Khách thuê: $_tenantName',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              if (_tenantPhone.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text('($_tenantPhone)',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ]
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 14),

                          // MỤC CHỌN TÀI KHOẢN NGÂN HÀNG NHẬN TIỀN
                          const Text(
                            '3. Tài khoản nhận tiền chuyển khoản',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text('Chọn tài khoản ngân hàng'),
                                value: _selectedBankAccountId,
                                items: [
                                  for (var b in _bankAccounts)
                                    DropdownMenuItem(
                                      value: b['id']?.toString(),
                                      child: Text(
                                        '${b['bankName'] ?? b['bankCode']} - ${b['accountNumber']} (${b['accountHolder']})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                                onChanged: (bankId) {
                                  if (bankId != null) {
                                    setState(() => _selectedBankAccountId = bankId);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Chỉ số Điện & Nước', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),

                    InvoiceWidgetHelpers.buildUtilityCard(
                      icon: Icons.electric_bolt,
                      title: 'Điện sinh hoạt',
                      unitPrice: 'Đơn giá: ${_formatMoney(_electricUnitPrice)}/kWh',
                      totalAmount: _formatMoney(_totalElectricAmount),
                      oldController: _dienCuController,
                      newController: _dienMoiController,
                      unitLabel: 'kWh',
                      consumption: '${_electricUsage.toStringAsFixed(0)} kWh',
                      actionText: _dienImagePath != null ? 'Đổi ảnh' : 'Chụp ảnh',
                      actionIcon: Icons.camera_alt_outlined,
                      onActionPressed: () => _showImagePickerSheet('điện'),
                    ),
                    const SizedBox(height: 10),

                    InvoiceWidgetHelpers.buildUtilityCard(
                      icon: Icons.water_drop,
                      title: 'Nước sinh hoạt',
                      unitPrice: 'Đơn giá: ${_formatMoney(_waterUnitPrice)}/m³',
                      totalAmount: _formatMoney(_totalWaterAmount),
                      oldController: _nuocCuController,
                      newController: _nuocMoiController,
                      unitLabel: 'm³',
                      consumption: '${_waterUsage.toStringAsFixed(0)} m³',
                      actionText: _nuocImagePath != null ? 'Đổi ảnh' : 'Chụp ảnh',
                      actionIcon: Icons.camera_alt_outlined,
                      onActionPressed: () => _showImagePickerSheet('nước'),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withAlpha(100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chi tiết các khoản thu',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 10),
                          InvoiceWidgetHelpers.buildFeeItem(
                              'Tiền phòng cố định', _formatMoney(_rentPrice),
                              icon: Icons.bed),
                          InvoiceWidgetHelpers.buildFeeItem(
                              'Tiền điện sinh hoạt', _formatMoney(_totalElectricAmount),
                              subtitle: '${_electricUsage.toStringAsFixed(0)} kWh',
                              icon: Icons.electric_bolt),
                          InvoiceWidgetHelpers.buildFeeItem(
                              'Tiền nước sinh hoạt', _formatMoney(_totalWaterAmount),
                              subtitle: '${_waterUsage.toStringAsFixed(0)} m³',
                              icon: Icons.water_drop),
                          for (var s in _otherServices)
                            InvoiceWidgetHelpers.buildFeeItem(
                              s['name']?.toString() ?? 'Dịch vụ',
                              _formatMoney((s['price'] is num) ? (s['price'] as num).toDouble() : 0),
                              icon: Icons.miscellaneous_services,
                            ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Text('Giảm trừ / Khuyến mãi (đ): ',
                                  style: TextStyle(fontSize: 12, color: Colors.red)),
                              Expanded(
                                child: TextField(
                                  controller: _discountController,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                  const InputDecoration(isDense: true, border: UnderlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TỔNG CỘNG THỰC THU',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            _formatMoney(_finalTotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 10,
                      offset: const Offset(0, -2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _submitInvoice('draft'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Lưu nháp',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _submitInvoice('unpaid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentYellow,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Phát hành & Báo khách',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}