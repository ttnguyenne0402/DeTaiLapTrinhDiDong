import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/contract_form_w.dart';
import '../../services/owner/contract_service.dart';

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
  bool _isLoadingData = false;

  // Dữ liệu phòng trống & Lịch hẹn
  List<dynamic> _availableRooms = [];
  Map<String, dynamic>? _selectedRoom;

  List<dynamic> _appointments = [];
  Map<String, dynamic>? _selectedAppointment; // null = Khách vãng lai

  // Dịch vụ áp dụng & Dịch vụ còn lại trong CSDL
  List<dynamic> _appliedServices = [];
  List<dynamic> _availableOtherServices = [];

  // Lấy ID chuẩn của một object phòng bất kỳ
  String _getRoomId(Map<dynamic, dynamic>? room) {
    if (room == null) return '';
    return (room['roomId'] ?? room['RoomId'] ?? room['id'] ?? room['Id'])?.toString().trim() ?? '';
  }

  // Lọc lịch hẹn của đúng phòng đang chọn (bắt mọi định dạng ID)
  List<dynamic> get _appointmentsForSelectedRoom {
    final currentRoomId = _getRoomId(_selectedRoom);
    if (currentRoomId.isEmpty) return [];

    final filtered = _appointments.where((a) {
      if (a is! Map) return false;
      final aptRoomId = (a['roomId'] ?? a['RoomId'] ?? a['room_id'] ?? a['id'] ?? a['Id'])?.toString().trim();
      return aptRoomId != null && aptRoomId.toLowerCase() == currentRoomId.toLowerCase();
    }).toList();

    // Nếu đang mở bản nháp mà lịch hẹn đã chọn chưa nằm trong danh sách lọc thì đưa vào đầu
    if (_selectedAppointment != null) {
      final selectedId = (_selectedAppointment!['id'] ?? _selectedAppointment!['Id'])?.toString();
      final exists = filtered.any((a) => (a['id'] ?? a['Id'])?.toString() == selectedId);
      if (!exists) {
        filtered.insert(0, _selectedAppointment);
      }
    }

    return filtered;
  }

  // Kỳ thanh toán
  String _selectedPaymentCycle = 'Hàng tháng (Từ ngày 01 đến 05)';
  final List<String> _paymentCycles = [
    'Hàng tháng (Từ ngày 01 đến 05)',
    'Hàng quý (3 tháng / lần)',
    'Nửa năm (6 tháng / lần)',
  ];

  // Danh mục nội quy phòng trọ
  final List<String> _houseRules = [
    'Giữ gìn an ninh trật tự chung; không gây ồn ào, hát karaoke sau 23h00.',
    'Thanh toán tiền thuê phòng và phí dịch vụ đúng hạn từ ngày 01 đến ngày 05 hàng tháng.',
    'Tuyệt đối nghiêm cấm tàng trữ, sử dụng chất cấm, pháo nổ hoặc vũ khí trái phép.',
    'Giữ gìn vệ sinh chung, bỏ rác đúng nơi và đúng khung giờ quy định của dãy trọ.',
    'Bảo quản tài sản, thiết bị phòng; không tự ý khoan đục, thay đổi kết cấu xây dựng.',
    'Người ở ngoài qua đêm phải thông báo trước với chủ trọ để khai báo tạm trú theo quy định pháp luật.',
    'Báo trước tối thiểu 30 ngày trước khi trả phòng để được đối soát và hoàn tiền cọc.',
  ];

  late final TextEditingController _tenantNameController;
  late final TextEditingController _tenantPhoneController;
  late final TextEditingController _cccdController;
  late final TextEditingController _issueDateController;
  late final TextEditingController _issuePlaceController;

  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _rentPriceController;
  late final TextEditingController _depositPriceController;

  late final TextEditingController _electricIndexController;
  late final TextEditingController _waterIndexController;

  late final SignatureController _ownerSignatureController;
  late final SignatureController _tenantSignatureController;

  bool get _isDraft => widget.contract?['status'] == 'Bản nháp' || widget.contract?['status'] == 'draft';
  bool get _isPendingSignature => widget.contract?['status'] == 'Chờ ký' || widget.contract?['status'] == 'pending';
  bool get _isActive => widget.contract?['status'] == 'Đang hiệu lực' || widget.contract?['status'] == 'active';

  bool get _ownerHasSigned => _ownerSignatureController.points.isNotEmpty;
  bool get _tenantHasSigned => _tenantSignatureController.points.isNotEmpty;
  bool get _bothSigned => _ownerHasSigned && _tenantHasSigned;

  String get _title {
    if (_isDraft) return 'Tiếp tục hợp đồng';
    if (_isPendingSignature) return 'Ký hợp đồng';
    if (_isActive) return 'Chi tiết hợp đồng';
    if (widget.contract?['status'] == 'Sắp hết hạn') {
      return 'Gia hạn hợp đồng';
    }
    return 'Tạo hợp đồng mới';
  }

  @override
  void initState() {
    super.initState();

    final c = widget.contract;

    _tenantNameController = TextEditingController(text: c?['tenantName'] ?? '');
    _tenantPhoneController = TextEditingController(text: c?['tenantPhone'] ?? '');
    _cccdController = TextEditingController(text: c?['cccd'] ?? '');
    _issueDateController = TextEditingController(text: c?['issueDate'] ?? '12/04/2021');
    _issuePlaceController = TextEditingController(text: c?['issuePlace'] ?? 'Cục CSQLHC về trật tự xã hội');

    _startDateController = TextEditingController(text: c?['startDate'] ?? '01/11/2026');
    _endDateController = TextEditingController(text: c?['endDate'] ?? '31/10/2027');
    _rentPriceController = TextEditingController(
      text: (c?['rentPrice'] ?? '3500000').toString().replaceAll('đ', '').replaceAll('.', '').trim(),
    );
    _depositPriceController = TextEditingController(
      text: (c?['depositPrice'] ?? '3500000').toString().replaceAll('đ', '').replaceAll('.', '').trim(),
    );

    _electricIndexController = TextEditingController(text: c?['electricIndex'] ?? '1420');
    _waterIndexController = TextEditingController(text: c?['waterIndex'] ?? '85');

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

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    final rooms = await ContractService.getAvailableRooms();
    final apts = await ContractService.getAppointments();

    debugPrint('--> [LOG] Số phòng trống: ${rooms.length} | Số lịch hẹn: ${apts.length}');

    if (mounted) {
      setState(() {
        _availableRooms = rooms;
        _appointments = apts;
        _isLoadingData = false;

        final c = widget.contract;

        if (c != null) {
          final targetRoomId = (c['roomId'] ?? c['RoomId'])?.toString().trim();
          final targetRoomText = (c['room'] ?? c['Room'] ?? c['roomName'])?.toString().trim();
          final targetAptId = (c['viewingAppointmentId'] ?? c['ViewingAppointmentId'])?.toString().trim();
          final targetPhone = (c['tenantPhone'] ?? c['TenantPhone'])?.toString().trim();

          // 1. Tìm lại lịch hẹn
          Map<String, dynamic>? matchedApt;
          if (targetAptId != null && targetAptId.isNotEmpty) {
            final found = _appointments.firstWhere(
                  (a) => (a['id'] ?? a['Id'] ?? a['appointmentId'])?.toString().trim() == targetAptId,
              orElse: () => null,
            );
            if (found != null) matchedApt = Map<String, dynamic>.from(found);
          }

          if (matchedApt == null && targetPhone != null && targetPhone.isNotEmpty) {
            final found = _appointments.firstWhere(
                  (a) => (a['tenantPhone'] ?? a['TenantPhone'] ?? a['phone'])?.toString().trim() == targetPhone,
              orElse: () => null,
            );
            if (found != null) matchedApt = Map<String, dynamic>.from(found);
          }

          if (matchedApt != null) {
            _selectedAppointment = matchedApt;
          }

          // 2. Tìm đúng phòng tương ứng
          final expectedRoomId = targetRoomId ?? (matchedApt != null ? (matchedApt['roomId'] ?? matchedApt['RoomId']) : null)?.toString();

          final matchedRoom = _availableRooms.firstWhere(
                (r) {
              final rId = _getRoomId(r);
              final rName = (r['roomName'] ?? r['name'])?.toString() ?? '';
              if (expectedRoomId != null && expectedRoomId.isNotEmpty && rId.toLowerCase() == expectedRoomId.toLowerCase()) {
                return true;
              }
              if (targetRoomText != null && targetRoomText.isNotEmpty && targetRoomText.contains(rName)) {
                return true;
              }
              return false;
            },
            orElse: () => _availableRooms.isNotEmpty ? _availableRooms.first : null,
          );

          if (matchedRoom != null) {
            _selectedRoom = Map<String, dynamic>.from(matchedRoom);
          }
        } else if (_availableRooms.isNotEmpty) {
          _selectedRoom = Map<String, dynamic>.from(_availableRooms.first);
        }

        // 3. Tải dịch vụ cho phòng đã chọn
        if (_selectedRoom != null) {
          final roomId = _getRoomId(_selectedRoom);
          if (c == null) {
            _rentPriceController.text = ((_selectedRoom!['price'] ?? 0) as num).toInt().toString();
            _depositPriceController.text = ((_selectedRoom!['deposit'] ?? 0) as num).toInt().toString();
          }
          if (roomId.isNotEmpty) {
            _fetchRoomServices(roomId);
          }
        }
      });
    }
  }

  // Tự nạp dịch vụ khi chọn phòng
  Future<void> _fetchRoomServices(String roomId) async {
    try {
      final result = await ContractService.getRoomServices(roomId);
      if (result is Map && mounted) {
        final defaultsRaw = (result['defaultServices'] ?? result['DefaultServices']) as List<dynamic>? ?? [];
        final othersRaw = (result['otherServices'] ?? result['OtherServices']) as List<dynamic>? ?? [];

        setState(() {
          _appliedServices = defaultsRaw.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            final rawPrice = m['price'] ?? m['Price'];
            return {
              'serviceId': m['serviceId'] ?? m['ServiceId'] ?? '',
              'name': m['name'] ?? m['Name'] ?? '',
              'unit': m['unit'] ?? m['Unit'] ?? '',
              'price': rawPrice != null ? (rawPrice as num).toDouble() : 0.0,
              'selected': true,
            };
          }).toList();

          _availableOtherServices = othersRaw.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            final rawPrice = m['price'] ?? m['Price'];
            return {
              'serviceId': m['serviceId'] ?? m['ServiceId'] ?? '',
              'name': m['name'] ?? m['Name'] ?? '',
              'unit': m['unit'] ?? m['Unit'] ?? '',
              'price': rawPrice != null && (rawPrice as num) > 0 ? (rawPrice as num).toDouble() : 50000.0,
              'selected': false,
            };
          }).toList();
        });
      }
    } catch (_) {}
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

    _tenantNameController.dispose();
    _tenantPhoneController.dispose();
    _cccdController.dispose();
    _issueDateController.dispose();
    _issuePlaceController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _rentPriceController.dispose();
    _depositPriceController.dispose();
    _electricIndexController.dispose();
    _waterIndexController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime initial = DateTime.now();
    try {
      final parts = controller.text.split('/');
      if (parts.length == 3) {
        initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final d = picked.day.toString().padLeft(2, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final y = picked.year.toString();
      setState(() {
        controller.text = '$d/$m/$y';
      });
    }
  }

  // Thêm dịch vụ khác từ CSDL
  void _showAddServiceFromDbDialog() {
    if (_availableOtherServices.isEmpty) {
      _showMessage('Không còn dịch vụ nào khác trong cơ sở dữ liệu.');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm dịch vụ từ hệ thống', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableOtherServices.length,
            itemBuilder: (context, index) {
              final srv = _availableOtherServices[index];
              return ListTile(
                title: Text(srv['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Đơn vị: ${srv['unit']}'),
                trailing: const Icon(Icons.add_circle, color: AppColors.primaryGreen),
                onTap: () {
                  setState(() {
                    _appliedServices.add({
                      'serviceId': srv['serviceId'],
                      'name': srv['name'],
                      'unit': srv['unit'],
                      'price': (srv['price'] as num?)?.toDouble() ?? 50000.0,
                      'selected': true,
                    });
                    _availableOtherServices.removeAt(index);
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  // Xóa bản nháp
  Future<void> _deleteDraft() async {
    final contractId = widget.contract?['id'] ?? widget.contract?['code'];
    if (contractId == null) {
      _showMessage('Không tìm thấy mã hợp đồng để xóa.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa bản nháp?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text('Bản nháp hợp đồng này sẽ bị xóa vĩnh viễn khỏi hệ thống.'),
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

    if (confirmed == true && mounted) {
      final success = await ContractService.deleteDraftContract(contractId.toString());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bản nháp thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        _showMessage('Không thể xóa bản nháp này.');
      }
    }
  }

  // 1. Lưu bản nháp
  Future<void> _saveDraft() async {
    final body = {
      'viewingAppointmentId': _selectedAppointment?['id'] ?? _selectedAppointment?['Id'],
      'roomId': _getRoomId(_selectedRoom),
      'tenantName': _tenantNameController.text.trim(),
      'tenantPhone': _tenantPhoneController.text.trim(),
      'cccd': _cccdController.text.trim(),
      'issueDate': _issueDateController.text.trim(),
      'issuePlace': _issuePlaceController.text.trim(),
      'startDate': _startDateController.text.trim(),
      'endDate': _endDateController.text.trim(),
      'rentPrice': double.tryParse(_rentPriceController.text.replaceAll('.', '').trim()) ?? 0,
      'depositPrice': double.tryParse(_depositPriceController.text.replaceAll('.', '').trim()) ?? 0,
      'electricIndex': int.tryParse(_electricIndexController.text.trim()) ?? 0,
      'waterIndex': int.tryParse(_waterIndexController.text.trim()) ?? 0,
      'status': 'draft',
      'services': _appliedServices.where((s) => s['selected'] == true).toList(),
    };

    final success = await ContractService.createContract(body);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu bản nháp vào hệ thống!')),
      );
      Navigator.pop(context, true);
    } else {
      _showMessage('Lỗi khi lưu bản nháp.');
    }
  }

  // 2. Hoàn tất & Gửi ký
  Future<void> _completeContract() async {
    if (_tenantNameController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập họ và tên khách thuê.');
      return;
    }

    final phone = _tenantPhoneController.text.trim();
    final phoneRegex = RegExp(r'^0[0-9]{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      _showMessage('Số điện thoại không hợp lệ (phải gồm 10 chữ số bắt đầu bằng 0).');
      return;
    }

    final cccd = _cccdController.text.trim();
    if (cccd.length != 12 || int.tryParse(cccd) == null) {
      _showMessage('Số CCCD không hợp lệ (phải đủ 12 chữ số).');
      return;
    }

    if (_issueDateController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập ngày cấp CCCD.');
      return;
    }
    if (_issuePlaceController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập nơi cấp CCCD.');
      return;
    }

    final rentPrice = double.tryParse(_rentPriceController.text.replaceAll('.', '').trim()) ?? 0;
    if (rentPrice <= 0) {
      _showMessage('Giá thuê hàng tháng phải lớn hơn 0đ.');
      return;
    }

    final depositPrice = double.tryParse(_depositPriceController.text.replaceAll('.', '').trim()) ?? 0;
    if (depositPrice <= 0) {
      _showMessage('Tiền đặt cọc phải lớn hơn 0đ.');
      return;
    }

    if (!_agreeTerms) {
      _showMessage('Vui lòng xác nhận đồng thuận với các quy định trọ.');
      return;
    }

    final body = {
      'viewingAppointmentId': _selectedAppointment?['id'] ?? _selectedAppointment?['Id'],
      'roomId': _getRoomId(_selectedRoom),
      'tenantName': _tenantNameController.text.trim(),
      'tenantPhone': _tenantPhoneController.text.trim(),
      'cccd': _cccdController.text.trim(),
      'issueDate': _issueDateController.text.trim(),
      'issuePlace': _issuePlaceController.text.trim(),
      'startDate': _startDateController.text.trim(),
      'endDate': _endDateController.text.trim(),
      'rentPrice': rentPrice,
      'depositPrice': depositPrice,
      'electricIndex': int.tryParse(_electricIndexController.text.trim()) ?? 0,
      'waterIndex': int.tryParse(_waterIndexController.text.trim()) ?? 0,
      'status': 'pending',
      'services': _appliedServices.where((s) => s['selected'] == true).toList(),
    };

    final success = await ContractService.createContract(body);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo hợp đồng và gửi ký thành công!')),
      );
      Navigator.pop(context, true);
    } else {
      _showMessage('Lỗi khi tạo hợp đồng.');
    }
  }

  // 3. Ký hợp đồng
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
          'Hai bên đã ký và đồng ý các điều khoản nội quy. '
              'Bạn có chắc chắn muốn xác nhận hợp đồng không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
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

    final contractId = widget.contract?['code'] ?? widget.contract?['id'];
    if (contractId == null) {
      _showMessage('Không tìm thấy mã hợp đồng để ký.');
      return;
    }

    final success = await ContractService.signContract(
      contractId: contractId.toString(),
      ownerSignatureBase64: base64Encode(ownerBytes),
      tenantSignatureBase64: base64Encode(tenantBytes),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hợp đồng đã ký thành công và có hiệu lực!')),
      );
      Navigator.pop(context, true);
    } else {
      _showMessage('Lỗi khi lưu chữ ký hợp đồng.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showRulesDetailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Quy định & Nội quy trọ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Các điều khoản chung bắt buộc áp dụng đối với tất cả thành viên lưu trú:',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ..._houseRules.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}. ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryGreen),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 13, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
          icon: const Icon(Icons.arrow_back, size: 26, color: Colors.white),
        ),
        title: Text(
          _title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isDraft)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Xóa bản nháp',
              onPressed: _deleteDraft,
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. NGUỒN TẠO VÀ LIÊN KẾT PHÒNG
              ContractFormWidgets.buildSectionCard(
                step: '1',
                title: 'Chọn phòng & Nguồn người thuê',
                subtitle: 'Chọn phòng trống trước, sau đó chọn khách hẹn hoặc nhập khách vãng lai',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chọn phòng còn trống', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                                    Text(
                                      widget.contract?['area'] != null
                                          ? '${widget.contract!['area']} m²'
                                          : '25 m²',
                                      style: const TextStyle(
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
                                  widget.contract?['rentPrice'] != null
                                      ? '${widget.contract!['rentPrice']} đ/tháng'
                                      : '4.500.000 đ/tháng',
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
                      widget.contract?['propertyName'] ??
                          widget.contract?['address'] ??
                          'Khu trọ Bình Thạnh (12 phòng)',
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAppointment?['id'] ?? _selectedAppointment?['Id'] ?? 'walkin',
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                              value: 'walkin',
                              child: Text('Khách trực tiếp / Vãng lai (Tự gõ thông tin)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            ..._appointmentsForSelectedRoom.map((a) {
                              final aptId = (a['id'] ?? a['Id']).toString();
                              final name = a['tenantName'] ?? a['TenantName'] ?? 'Khách xem phòng';
                              final phone = a['tenantPhone'] ?? a['TenantPhone'] ?? '';
                              return DropdownMenuItem(
                                value: aptId,
                                child: Text(
                                  'Lịch hẹn: $name ($phone)',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val == 'walkin') {
                              setState(() {
                                _selectedAppointment = null;
                                _tenantNameController.clear();
                                _tenantPhoneController.clear();
                              });
                            } else {
                              final match = _appointmentsForSelectedRoom.firstWhere(
                                    (a) => (a['id'] ?? a['Id']).toString() == val,
                              );
                              setState(() {
                                _selectedAppointment = Map<String, dynamic>.from(match);
                                _tenantNameController.text = match['tenantName'] ?? match['TenantName'] ?? '';
                                _tenantPhoneController.text = match['tenantPhone'] ?? match['TenantPhone'] ?? '';
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    ContractFormWidgets.buildDropdownField(
                      widget.contract?['appointmentInfo'] ??
                          '#AF-8823 - Nguyễn Văn An - 10:00 24/08/...',
                    ),
                  ],
                ),
              ),

              // 2. THÔNG TIN NGƯỜI THUÊ
              ContractFormWidgets.buildSectionCard(
                step: '2',
                title: 'Thông tin Người thuê & Ở ghép',
                subtitle: 'Chủ thể ký hợp đồng',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Họ và tên khách',
                            controller: _tenantNameController,
                            hint: 'Nguyễn Văn An',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInputField(
                            label: 'Số điện thoại',
                            controller: _tenantPhoneController,
                            hint: '0908123456',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Số CCCD (12 số)',
                            controller: _cccdController,
                            hint: '079098001234',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDateField(
                            label: 'Ngày cấp',
                            controller: _issueDateController,
                            onTap: () => _selectDate(_issueDateController),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInputField(
                      label: 'Nơi cấp',
                      controller: _issuePlaceController,
                      hint: 'Cục CSQLHC về trật tự xã hội',
                    ),
                  ],
                ),
              ),

              // 3. THỜI HẠN VÀ TIỀN PHÒNG
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
                          child: _buildDateField(
                            label: 'Ngày bắt đầu',
                            controller: _startDateController,
                            onTap: () => _selectDate(_startDateController),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDateField(
                            label: 'Ngày kết thúc',
                            controller: _endDateController,
                            onTap: () => _selectDate(_endDateController),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Giá thuê hàng tháng (VNĐ)',
                            controller: _rentPriceController,
                            hint: '3500000',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInputField(
                            label: 'Tiền đặt cọc (VNĐ)',
                            controller: _depositPriceController,
                            hint: '3500000',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Kỳ thanh toán tiền trọ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPaymentCycle,
                          isExpanded: true,
                          items: _paymentCycles.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPaymentCycle = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. CHỈ SỐ BÀN GIAO & DỊCH VỤ ÁP DỤNG
              ContractFormWidgets.buildSectionCard(
                step: '4',
                title: 'Chỉ số ban đầu & Dịch vụ áp dụng',
                subtitle: 'Chốt mốc bàn giao thiết bị và các khoản phí dịch vụ',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Số điện ban đầu (kWh)',
                            controller: _electricIndexController,
                            hint: '1420',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInputField(
                            label: 'Số nước ban đầu (m³)',
                            controller: _waterIndexController,
                            hint: '85',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Dịch vụ áp dụng cho phòng:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        InkWell(
                          onTap: _showAddServiceFromDbDialog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, size: 16, color: AppColors.primaryGreen),
                                SizedBox(width: 4),
                                Text('Thêm dịch vụ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_appliedServices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Chưa có dịch vụ nào được nạp.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                      ),
                    Column(
                      children: _appliedServices.map((srv) {
                        final isSelected = srv['selected'] == true;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? AppColors.primaryGreen.withOpacity(0.5) : Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: AppColors.primaryGreen,
                                onChanged: (val) {
                                  setState(() => srv['selected'] = val ?? false);
                                },
                              ),
                              Expanded(
                                child: Text(
                                  srv['name'] ?? '',
                                  style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                ),
                              ),
                              Text(
                                '${((srv['price'] ?? 0) as num).toInt()}đ / ${srv['unit']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primaryGreen : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // 5. ĐIỀU KHOẢN VÀ NỘI QUY PHÒNG TRỌ
              ContractFormWidgets.buildSectionCard(
                step: '5',
                title: 'Điều khoản hợp đồng & Quy định trọ',
                subtitle: 'Cam kết an ninh, nề nếp và trách nhiệm đôi bên',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.rule, size: 18, color: Colors.amber.shade900),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tóm tắt quy chế nhà trọ',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _showRulesDetailDialog,
                                child: const Text(
                                  'Chi tiết',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          ..._houseRules.take(3).map((rule) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    rule,
                                    style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                          if (_houseRules.length > 3)
                            GestureDetector(
                              onTap: _showRulesDetailDialog,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '+ Còn ${_houseRules.length - 3} quy định khác (Bấm để xem)...',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeTerms,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                        ),
                        const Expanded(
                          child: Text(
                            'Tôi và bên thuê cam kết đã đọc, hiểu rõ và đồng ý tuân thủ toàn bộ điều khoản & nội quy trên.',
                            style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryGreen)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: IgnorePointer(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                suffixIcon: const Icon(Icons.calendar_month, size: 18, color: AppColors.primaryGreen),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ),
        ),
      ],
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
              const Text('Ký xác nhận hợp đồng điện tử', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSignatureBox(title: 'Chữ ký chủ trọ', controller: _ownerSignatureController, hasSigned: _ownerHasSigned),
          const SizedBox(height: 12),
          _buildSignatureBox(title: 'Chữ ký khách thuê', controller: _tenantSignatureController, hasSigned: _tenantHasSigned),
        ],
      ),
    );
  }

  Widget _buildSignatureBox({required String title, required SignatureController controller, required bool hasSigned}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: hasSigned ? Colors.green : Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              TextButton.icon(
                onPressed: () => controller.clear(),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Ký lại', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          Container(
            height: 120,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(6)),
            child: Signature(controller: controller, backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContractInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.verified, color: Colors.green),
          SizedBox(width: 8),
          Expanded(child: Text('Hợp đồng đang có hiệu lực pháp lý.', style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_isPendingSignature) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (_agreeTerms && _bothSigned) ? _signContract : null,
          icon: const Icon(Icons.draw, color: Colors.white),
          label: const Text('Xác nhận ký hợp đồng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saveDraft,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('Lưu bản nháp', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _completeContract,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('Hoàn tất & Gửi ký', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}