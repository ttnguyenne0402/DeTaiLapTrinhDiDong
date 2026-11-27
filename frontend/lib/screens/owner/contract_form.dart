import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../widgets/common/contract_signing_decision.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_storage.dart';
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
  bool _isSubmitting = false;

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

  String _normalizeText(String text, {bool removeRoomPrefix = false}) {
    String clean = text.toLowerCase();
    // Gom các chữ cái tiếng Việt bị Syncfusion tách dấu cách (VD: "ph ò ng" -> "phòng", "t â n" -> "tân")
    clean = clean.replaceAllMapped(
      RegExp(r'([a-zà-ỹ])\s+([ăâđêôơưàáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵ])'),
          (m) => '${m[1]}${m[2]}',
    );
    clean = clean.replaceAllMapped(
      RegExp(r'([ăâêôơưàáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵ])\s+([a-z]{1,2})\b'),
          (m) => '${m[1]}${m[2]}',
    );
    // Xóa toàn bộ dấu cách
    clean = clean.replaceAll(RegExp(r'\s+'), '');
    // Xóa chữ "phòng" sau khi đã gom liền chữ
    if (removeRoomPrefix) {
      clean = clean.replaceAll('phòng', '');
    }
    return clean;
  }

  String _fixVietnameseSpacing(String text) {
    String res = text;
    // Bước 1: Gom ký tự có dấu vào chữ cái đứng trước nó (VD: "Nguy ễ" -> "Nguyễ", "T ấ" -> "Tấ", "K ỳ" -> "Kỳ")
    res = res.replaceAllMapped(
      RegExp(r'([a-zA-ZÀ-ỹ])\s+([ăâđêôơưàáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵĂÂĐÊÔƠƯÀÁẢÃẠẰẮẲẴẶẦẤẨẪẬÈÉẺẼẸỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌỒỐỔỖỘỜỚỞỠỢÙÚỦŨỤỪỨỬỮỰỲÝỶỸỴ])'),
          (m) => '${m[1]}${m[2]}',
    );
    // Bước 2: Gom tiếp phụ âm cuối bị tách sau nguyên âm có dấu (VD: "Nguyễ n" -> "Nguyễn", "Tấ n" -> "Tấn")
    res = res.replaceAllMapped(
      RegExp(r'([ăâêôơưàáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵĂÂÊÔƠƯÀÁẢÃẠẰẮẲẴẶẦẤẨẪẬÈÉẺẼẸỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌỒỐỔỖỘỜỚỞỠỢÙÚỦŨỤỪỨỬỮỰỲÝỶỸỴ])\s+([a-zA-Z]{1,2})\b'),
          (m) => '${m[1]}${m[2]}',
    );
    return res.trim();
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

  String? _selectedPdfFileName;
  String? _pdfRoomName;
  String? _pdfPropertyName;
  String? _pdfFloor;

  Future<void> _pickPdfFile() async {
    if (!_canImportPdf) return;

    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result.isNotEmpty) {
        final platformFile = result.first;
        final fileName = platformFile.name;
        String extractedText = '';

        try {
          if (platformFile.path != null) {
            final bytes = await File(platformFile.path!).readAsBytes();
            if (bytes.isNotEmpty) {
              final PdfDocument document = PdfDocument(inputBytes: bytes);
              final PdfTextExtractor extractor = PdfTextExtractor(document);
              extractedText = extractor.extractText();
              document.dispose();
            }
          }
        } catch (e) {
          debugPrint('Lỗi đọc nội dung PDF bằng Syncfusion: $e');
        }

        if (!mounted || !_canImportPdf) return;

        setState(() {
          _selectedPdfFileName = fileName;
          if (extractedText.trim().isNotEmpty) {
            _parseAndPopulatePdfText(extractedText);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(extractedText.trim().isNotEmpty
                  ? 'Đã chọn file "$fileName"!'
                  : 'Không đọc được chữ từ "$fileName".'),
              backgroundColor: extractedText.trim().isNotEmpty ? AppColors.primaryGreen : Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi chọn file PDF: $e');
    }
  }

  void _parseAndPopulatePdfText(String text) {
    final flat = text
        .replaceAll(RegExp(r'[\r\n\t\u00A0]+'), ' ')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();



    // 2. SỐ ĐIỆN THOẠI BÊN B (đưa lên trước để làm mốc bắt Tên Bên B)
    final allPhones = RegExp(r'\b(0[35789]\d{8})\b').allMatches(flat).map((m) => m.group(1)!).toList();
    String? tenantPhone;
    if (allPhones.length >= 2) {
      tenantPhone = allPhones[1];
      _tenantPhoneController.text = tenantPhone;
    } else if (allPhones.length == 1) {
      tenantPhone = allPhones[0];
      _tenantPhoneController.text = tenantPhone;
    }

    // 1. TÊN KHÁCH THUÊ: Cắt trực tiếp chuỗi nằm giữa dấu ":" và số điện thoại Bên B (0328091979)
    if (tenantPhone != null) {
      final beforePhone = flat.split(tenantPhone).first;
      final parts = beforePhone.split(':');
      if (parts.length >= 2) {
        String candidate = parts[parts.length - 2].trim();
        candidate = candidate.replaceAll(RegExp(r'\s+S\S*.*$'), '').trim();
        if (candidate.isNotEmpty) {
          _tenantNameController.text = _fixVietnameseSpacing(candidate);
        }
      }
    }

    // Dự phòng nếu chưa có tên: lấy phần sau dấu ":" của cụm "Họ ... tên" thứ 2
    if (_tenantNameController.text.trim().isEmpty) {
      final fallbackName = RegExp(r':\s*([^\d:]{4,40}?)\s*\S+\s+\S+\s+\S+\s*:\s*0[35789]\d{8}')
          .allMatches(flat)
          .toList();
      if (fallbackName.isNotEmpty) {
        _tenantNameController.text = fallbackName.last.group(1)!.trim();
      }
    }

    // 3. SỐ CCCD: Bắt chuỗi đúng 12 chữ số trong văn bản
    final cccdMatch = RegExp(r'\b(\d{12})\b').firstMatch(flat);
    if (cccdMatch != null) {
      _cccdController.text = cccdMatch.group(1)!;
    }

    // 4. CÁC MỐC NGÀY (dd/MM/yyyy):
    // Thứ tự trong file: [0] Ngày lập (01/11/2026), [1] Ngày cấp CCCD (15/08/2022), [2] Ngày bắt đầu (01/11/2026), [3] Ngày kết thúc (31/10/2027)
    final allDates = RegExp(r'\b(\d{2}\/\d{2}\/\d{4})\b').allMatches(flat).map((m) => m.group(1)!).toList();
    if (allDates.length >= 4) {
      _issueDateController.text = allDates[1];
      _startDateController.text = allDates[2];
      _endDateController.text = allDates[3];
    } else if (allDates.length >= 2) {
      _startDateController.text = allDates[allDates.length - 2];
      _endDateController.text = allDates[allDates.length - 1];
    }

    // 5. NƠI CẤP
    final issuePlaceMatch = RegExp(r'N[ơo]i\s*c[ấa]p\s*:\s*(.+?)(?=\s*ĐIỀU|$)', caseSensitive: false).firstMatch(flat);
    if (issuePlaceMatch != null) {
      _issuePlaceController.text = issuePlaceMatch.group(1)!.trim();
    }

    // 6. GIÁ THUÊ & TIỀN CỌC: Bắt các số tiền có định dạng dấu chấm hàng nghìn (VD: 4.200.000)
    final moneyMatches = RegExp(r'\b(\d{1,3}(?:\.\d{3})+)\b')
        .allMatches(flat)
        .map((m) => m.group(1)!.replaceAll('.', ''))
        .toList();
    if (moneyMatches.isNotEmpty) {
      _rentPriceController.text = moneyMatches[0];
      _depositPriceController.text = moneyMatches.length >= 2 ? moneyMatches[1] : moneyMatches[0];
    }

    // 7. CHỈ SỐ ĐIỆN & NƯỚC
    final elecMatch = RegExp(r'(\d+)\s*kWh', caseSensitive: false).firstMatch(flat);
    if (elecMatch != null) {
      _electricIndexController.text = elecMatch.group(1)!;
      // Lấy chuỗi ngay sau "kWh" và bắt con số đầu tiên xuất hiện -> chính là chỉ số nước (92)
      final afterKwh = flat.substring(elecMatch.end);
      final nextNumMatch = RegExp(r':\s*(\d+)').firstMatch(afterKwh) ?? RegExp(r'\b(\d{1,5})\b').firstMatch(afterKwh);
      if (nextNumMatch != null) {
        _waterIndexController.text = nextNumMatch.group(1)!;
      }
    }

    // 8. BÓC TÁCH TÊN PHÒNG, SỐ TẦNG & TÊN TÒA NHÀ TRONG ĐIỀU 1
    _pdfRoomName = null;
    _pdfPropertyName = null;
    _pdfFloor = null;

    String dieu1Block = flat;
    final startDateStr = _startDateController.text;
    final lastDateIdx = startDateStr.isNotEmpty ? flat.lastIndexOf(startDateStr) : -1;
    if (lastDateIdx != -1) {
      dieu1Block = flat.substring(0, lastDateIdx);
      final cccdIdx = _cccdController.text.isNotEmpty ? dieu1Block.indexOf(_cccdController.text) : -1;
      if (cccdIdx != -1) {
        dieu1Block = dieu1Block.substring(cccdIdx);
      }
    }

    // Bắt số tầng nếu có (VD: "Tầng 2", "Lầu 2", "Tầng trệt" -> "0")
    final roomSectionIdx = dieu1Block.indexOf(':');
    final roomOnlyBlock = roomSectionIdx != -1 ? dieu1Block.substring(roomSectionIdx) : dieu1Block;
    final floorMatch = RegExp(r'(?:T\s*[ầa]\s*n\s*g|L\s*[ầa]\s*u)\s*(\d+|tr[ệe]t)', caseSensitive: false).firstMatch(roomOnlyBlock);
    if (floorMatch != null) {
      final rawFloor = floorMatch.group(1)!.toLowerCase().replaceAll(' ', '');
      _pdfFloor = rawFloor.contains('tr') ? '0' : rawFloor;
    }

    final dashParts = dieu1Block.split(RegExp(r'[\-\–\—]'));
    if (dashParts.length >= 2) {
      final leftSide = dashParts[0];
      if (leftSide.contains(':')) {
        _pdfRoomName = _fixVietnameseSpacing(leftSide.split(':').last.trim());
      }

      // Lấy phần tử cuối chứa "Thuộc tòa nhà : ..." (tránh bị lệch nếu có thêm "- Tầng 2 -" ở giữa)
      final propSegment = dashParts.lastWhere(
            (p) => p.contains(':'),
        orElse: () => dashParts.last,
      );
      final rightColons = propSegment.split(':');
      if (rightColons.length >= 2) {
        String propRaw = rightColons[1].trim();
        propRaw = propRaw.replaceAll(RegExp(r'\s+T\s*h\s*[ờo]\s*i.*$', caseSensitive: false), '').trim();
        propRaw = _fixVietnameseSpacing(propRaw);
        if (propRaw.isNotEmpty) {
          _pdfPropertyName = propRaw;
        }
      }
    }

    // Tự động chọn đúng phòng trống trong dropdown (khớp Tên phòng + Tòa nhà + Tầng nếu có)
    if (_pdfRoomName != null && _pdfRoomName!.isNotEmpty && _availableRooms.isNotEmpty) {
      final targetRoom = _normalizeText(_pdfRoomName!, removeRoomPrefix: true);
      final targetProp = _normalizeText(_pdfPropertyName ?? '');

      final candidates = _availableRooms.where((r) {
        final rName = _normalizeText((r['roomName'] ?? r['name'] ?? '').toString(), removeRoomPrefix: true);
        final pName = _normalizeText((r['propertyName'] ?? '').toString());
        final rFloor = (r['floor'] ?? r['floorNumber'] ?? '').toString().trim();

        final roomOk = rName == targetRoom;
        final propOk = targetProp.isEmpty || pName.isEmpty || pName == targetProp;
        final floorOk = _pdfFloor == null || rFloor.isEmpty || rFloor == _pdfFloor;
        return roomOk && propOk && floorOk;
      }).toList();

      if (candidates.length == 1) {
        _selectedRoom = Map<String, dynamic>.from(candidates.first as Map);
        final rId = _getRoomId(_selectedRoom);
        if (rId.isNotEmpty) _fetchRoomServices(rId);
      } else if (candidates.length > 1) {
        // Có nhiều phòng trùng tên ở các tầng khác nhau -> Nhắc chủ trọ chọn tay trên Dropdown
        _showMessage('Có ${candidates.length} phòng tên "$_pdfRoomName" đang trống. Vui lòng chọn đúng tầng trên danh sách!');
      }
    }

    // 9. Tự động khớp Nguồn khách thuê: Khách đặt lịch hay Khách vãng lai
    _selectedAppointment = null; // Mặc định là Khách vãng lai
    if (_selectedRoom != null && tenantPhone != null && tenantPhone.isNotEmpty) {
      final cleanPdfPhone = tenantPhone.trim();
      final matchedApt = _appointmentsForSelectedRoom.firstWhere(
            (a) {
          final aptPhone = (a['tenantPhone'] ?? a['TenantPhone'] ?? a['phone'] ?? '').toString().trim();
          return aptPhone == cleanPdfPhone;
        },
        orElse: () => null,
      );

      if (matchedApt != null) {
        _selectedAppointment = Map<String, dynamic>.from(matchedApt as Map);
      }
    }


  }

  Widget _buildPdfUploadSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.blue.shade800, size: 20),
              const SizedBox(width: 8),
              const Text('Đính kèm File PDF Hợp đồng (Mẫu / Bản Scan)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedPdfFileName ?? 'Chưa chọn file PDF hợp đồng mẫu',
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedPdfFileName != null ? AppColors.primaryGreen : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
                label: const Text('Tải PDF', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: _pickPdfFile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _isDraft => widget.contract?['status'] == 'Bản nháp' || widget.contract?['status'] == 'draft';
  bool get _canImportPdf => widget.contract == null || _isDraft;
  bool get _isPendingSignature => widget.contract?['status'] == 'Chờ ký' || widget.contract?['status'] == 'pending';
  bool get _isActive => widget.contract?['status'] == 'Đang hiệu lực' || widget.contract?['status'] == 'active';

  bool get _ownerHasSigned => _ownerSignatureController.points.isNotEmpty || (_existingOwnerSignature != null && _existingOwnerSignature!.isNotEmpty);
  bool get _tenantHasSigned => _tenantSignatureController.points.isNotEmpty || (_existingTenantSignature != null && _existingTenantSignature!.isNotEmpty);
  bool get _bothSigned => _ownerHasSigned || _tenantHasSigned;

  String get _title {
    if (_isDraft) return 'Tiếp tục hợp đồng';
    if (_isPendingSignature) return 'Ký hợp đồng';
    if (_isActive) return 'Chi tiết hợp đồng';
    if (widget.contract?['status'] == 'Sắp hết hạn') {
      return 'Gia hạn hợp đồng';
    }
    return 'Tạo hợp đồng mới';
  }

  String? _existingOwnerSignature;
  String? _existingTenantSignature;

  @override
  void initState() {
    super.initState();

    final c = widget.contract;
    _existingOwnerSignature = c?['ownerSignature']?.toString() ?? c?['OwnerSignature']?.toString();
    _existingTenantSignature = c?['tenantSignature']?.toString() ?? c?['TenantSignature']?.toString();

    _tenantNameController = TextEditingController(text: c?['tenantName'] ?? '');
    _tenantPhoneController = TextEditingController(text: c?['tenantPhone'] ?? '');
    _cccdController = TextEditingController( text: c?['cccd'] ?? c?['CCCD'] ?? c?['identityCard'] ?? '', );
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
    final ownerId = await AuthStorage.getUserId() ?? '';
    final currentRoomId = widget.contract?['roomId']?.toString();
    final rooms = await ContractService.getAvailableRooms(
      ownerId: ownerId,
      selectedRoomId: _isPendingSignature ? currentRoomId : null,
    );
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

        // Lấy danh sách ID các dịch vụ đã lưu trong bản nháp (nếu đang xem/sửa bản nháp)
        final savedServices = widget.contract?['services'] as List<dynamic>?;
        final Set<String> savedServiceIds = savedServices != null
            ? savedServices.map((s) => (s['serviceId'] ?? s['ServiceId'] ?? '').toString()).toSet()
            : {};

        setState(() {
          _appliedServices = defaultsRaw.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            final rawPrice = m['price'] ?? m['Price'];
            final sId = (m['serviceId'] ?? m['ServiceId'] ?? '').toString();
            final sName = (m['name'] ?? m['Name'] ?? '').toString();
            final isMandatory = m['isMandatory'] == true ||
                m['IsMandatory'] == true ||
                sName.toLowerCase().contains('điện') ||
                sName.toLowerCase().contains('nước');

            bool isSelected = isMandatory;
            if (savedServices != null) {
              isSelected = savedServiceIds.contains(sId);
            }

            return {
              'serviceId': sId,
              'name': sName,
              'unit': m['unit'] ?? m['Unit'] ?? '',
              'price': rawPrice != null ? (rawPrice as num).toDouble() : 0.0,
              'isMandatory': isMandatory,
              'selected': isSelected,
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

    final res = await ContractService.createContract(body);
    if (mounted) {
      if (res != null && res['error'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu bản nháp vào hệ thống!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errorMsg = res != null ? (res['message'] ?? 'Không thể lưu bản nháp.') : 'Lỗi khi lưu bản nháp.';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
                SizedBox(width: 8),
                Text('Thông báo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              errorMsg,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  // 2. Hoàn tất & Gửi ký
  Future<void> _completeContract() async {
    if (_selectedRoom == null || _getRoomId(_selectedRoom).isEmpty) {
      _showMessage('Vui lòng chọn phòng trống trong hệ thống để tạo hợp đồng!');
      return;
    }

    // RÀNG BUỘC KHỚP CHÍNH XÁC PHÒNG & TÒA NHÀ TRONG PDF VỚI CSDL PHÒNG TRỐNG CỦA CHỦ TRỌ
    final currentSelectedRoomName = (_selectedRoom?['roomName'] ?? _selectedRoom?['name'] ?? '').toString().trim();
    final currentSelectedPropName = (_selectedRoom?['propertyName'] ?? '').toString().trim();

    if (_pdfRoomName != null && _pdfRoomName!.isNotEmpty) {
      final cleanPdfRoom = _normalizeText(_pdfRoomName!, removeRoomPrefix: true);
      final cleanSelectedRoom = _normalizeText(currentSelectedRoomName, removeRoomPrefix: true);

      final cleanPdfProp = _normalizeText(_pdfPropertyName ?? '');
      final cleanSelectedProp = _normalizeText(currentSelectedPropName);

      final bool isRoomMatched = cleanPdfRoom == cleanSelectedRoom;
      final bool isPropMatched = cleanPdfProp.isEmpty || cleanSelectedProp.isEmpty || cleanPdfProp == cleanSelectedProp;

      final currentSelectedFloor = (_selectedRoom?['floor'] ?? _selectedRoom?['floorNumber'] ?? '').toString().trim();
      final bool isFloorMatched = _pdfFloor == null || currentSelectedFloor.isEmpty || _pdfFloor == currentSelectedFloor;

      if (!isRoomMatched || !isPropMatched || !isFloorMatched) {
        final floorText = _pdfFloor != null ? ' (Tầng $_pdfFloor)' : '';
        final pdfFullLabel = (_pdfPropertyName != null && _pdfPropertyName!.isNotEmpty)
            ? '$_pdfRoomName$floorText - $_pdfPropertyName'
            : '$_pdfRoomName$floorText';
        final selectedFloorText = currentSelectedFloor.isNotEmpty ? ' (Tầng $currentSelectedFloor)' : '';
        final selectedFullLabel = currentSelectedPropName.isNotEmpty
            ? '$currentSelectedRoomName$selectedFloorText - $currentSelectedPropName'
            : '$currentSelectedRoomName$selectedFloorText';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 26),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lỗi không khớp phòng trọ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
            content: Text(
              'File PDF ghi hợp đồng cho "$pdfFullLabel", nhưng phòng trống bạn đang chọn là "$selectedFullLabel" (hoặc phòng trong PDF không nằm trong danh sách phòng trống của bạn).\n\nVui lòng chọn đúng phòng hoặc tải lại file PDF hợp lệ.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return; // Chặn lại không cho tạo hợp đồng
      }
    }

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

    final double dbRentPrice = ((_selectedRoom?['price'] ?? 0) as num).toDouble();
    final double dbDepositPrice = ((_selectedRoom?['deposit'] ?? 0) as num).toDouble();

    final bool isRentMismatch = dbRentPrice > 0 && rentPrice != dbRentPrice;
    final bool isDepositMismatch = dbDepositPrice > 0 && depositPrice != dbDepositPrice;

    if (isRentMismatch || isDepositMismatch) {
      final List<String> diffs = [];
      if (isRentMismatch) {
        diffs.add('• Giá thuê: Hợp đồng ghi ${_formatCurrency(rentPrice)}đ (Giá gốc SQL: ${_formatCurrency(dbRentPrice)}đ)');
      }
      if (isDepositMismatch) {
        diffs.add('• Tiền đặt cọc: Hợp đồng ghi ${_formatCurrency(depositPrice)}đ (Cọc gốc SQL: ${_formatCurrency(dbDepositPrice)}đ)');
      }

      final bool? proceedWithDiffPrice = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chênh lệch giá so với hệ thống',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
            ],
          ),
          content: Text(
            'Thông tin tài chính trên hợp đồng đang khác với dữ liệu phòng trong hệ thống:\n\n'
                '${diffs.join('\n')}\n\n'
                'Bạn muốn dùng lại giá gốc trong SQL hay vẫn tiếp tục tạo hợp đồng với mức giá này?',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  if (dbRentPrice > 0) _rentPriceController.text = dbRentPrice.toInt().toString();
                  if (dbDepositPrice > 0) _depositPriceController.text = dbDepositPrice.toInt().toString();
                });
                Navigator.pop(ctx, false);
              },
              child: const Text('Lấy theo giá ban đầu', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vẫn tạo hợp đồng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (proceedWithDiffPrice != true) {
        return;
      }
    }

    if (!_agreeTerms) {
      _showMessage('Vui lòng xác nhận đồng thuận với các quy định trọ.');
      return;
    }

    final String initialStatus = 'pending';

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
      'status': initialStatus,
      'pdfUrl': _selectedPdfFileName != null ? 'http://10.0.2.2:5093/uploads/contracts/$_selectedPdfFileName' : null,
      'services': _appliedServices.where((s) => s['selected'] == true).toList(),
    };

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final res = await ContractService.createContract(body);
    if (mounted) {
      if (res != null && res['error'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo hợp đồng và gửi ký thành công!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() => _isSubmitting = false);
        final errorMsg = res != null ? (res['message'] ?? 'Lỗi khi tạo hợp đồng.') : 'Lỗi khi tạo hợp đồng.';
        _showMessage(errorMsg);
      }
    }
  }

  // 3. Ký hợp đồng
  Future<void> _signContract() async {
    if (_isSubmitting) return;
    if (!_agreeTerms) {
      _showMessage('Vui lòng đồng ý với điều khoản hợp đồng.');
      return;
    }

    if (!_ownerHasSigned && !_tenantHasSigned) {
      _showMessage('Vui lòng vẽ chữ ký trước khi xác nhận.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận ký hợp đồng'),
        content: const Text(
          'Bạn có muốn lưu chữ ký cho hợp đồng này?',
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
    if (!mounted || _isSubmitting) return;

    String ownerBase64 = ownerBytes != null ? base64Encode(ownerBytes) : (_existingOwnerSignature ?? '');
    String tenantBase64 = tenantBytes != null ? base64Encode(tenantBytes) : (_existingTenantSignature ?? '');

    if (ownerBase64.isEmpty && tenantBase64.isEmpty) {
      _showMessage('Vui lòng vẽ chữ ký trước khi xác nhận.');
      return;
    }

    final contractId = widget.contract?['code'] ?? widget.contract?['id'];
    if (contractId == null) {
      _showMessage('Không tìm thấy mã hợp đồng để ký.');
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ContractService.signContract(
      contractId: contractId.toString(),
      ownerSignatureBase64: ownerBase64,
      tenantSignatureBase64: tenantBase64,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      setState(() {
        if (ownerBase64.isNotEmpty) _existingOwnerSignature = ownerBase64;
        if (tenantBase64.isNotEmpty) _existingTenantSignature = tenantBase64;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu chữ ký hợp đồng.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      _showMessage('Lỗi khi lưu chữ ký hợp đồng.');
    }
  }

  Future<void> _withdrawSigning() async {
    final id = widget.contract?['id'] ?? widget.contract?['code'];
    if (id == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final closed = await closeContractSigning(
        context,
        contractId: id.toString(),
        reject: false,
      );
      if (closed && mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
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
                    const SizedBox(height: 6),
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
                          value: _selectedRoom != null ? _getRoomId(_selectedRoom) : null,
                          hint: const Text('Chọn phòng trống trong danh sách...', style: TextStyle(fontSize: 13)),
                          isExpanded: true,
                          items: _availableRooms.map((r) {
                            final rId = _getRoomId(r);
                            final rName = (r['roomName'] ?? r['name'])?.toString() ?? 'Phòng';
                            final pName = (r['propertyName'] ?? r['address'])?.toString() ?? 'Khu trọ';
                            final floor = (r['floor'] ?? r['floorNumber'])?.toString().trim() ?? '';
                            final floorStr = floor.isNotEmpty ? ' (Tầng $floor)' : '';
                            final price = ((r['price'] ?? 0) as num).toInt();

                            return DropdownMenuItem(
                              value: rId,
                              child: Text(
                                '$rName$floorStr - $pName (${_formatCurrency(price.toDouble())} đ/tháng)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final chosen = _availableRooms.firstWhere(
                                    (r) => _getRoomId(r) == val,
                                orElse: () => _availableRooms.first,
                              );
                              setState(() {
                                _selectedRoom = Map<String, dynamic>.from(chosen as Map);
                                _rentPriceController.text = ((chosen['price'] ?? 0) as num).toInt().toString();
                                _depositPriceController.text = ((chosen['deposit'] ?? 0) as num).toInt().toString();
                                _selectedAppointment = null;
                                _tenantNameController.clear();
                                _tenantPhoneController.clear();
                              });
                              _fetchRoomServices(val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Nguồn khách thuê', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
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
                                child: Text('Lịch hẹn: $name ($phone)', style: const TextStyle(fontSize: 13)),
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
                                orElse: () => null,
                              );
                              if (match != null) {
                                setState(() {
                                  _selectedAppointment = Map<String, dynamic>.from(match as Map);
                                  _tenantNameController.text = match['tenantName'] ?? match['TenantName'] ?? '';
                                  _tenantPhoneController.text = match['tenantPhone'] ?? match['TenantPhone'] ?? '';
                                });
                              }
                            }
                          },
                        ),
                      ),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            srv['name'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: srv['isMandatory'] == true
                                                ? Colors.red.shade50
                                                : Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: srv['isMandatory'] == true
                                                  ? Colors.red.shade200
                                                  : Colors.blue.shade200,
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            srv['isMandatory'] == true ? 'Bắt buộc' : 'Theo phòng',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: srv['isMandatory'] == true
                                                  ? Colors.red.shade700
                                                  : Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (srv['isMandatory'] != true)
                                      Text(
                                        'Chỉ tích chọn nếu phòng này đăng ký',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                  ],
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
                    if (_canImportPdf) ...[
                      const SizedBox(height: 12),
                      _buildPdfUploadSection(),
                    ],
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
          _buildSignatureBox(title: 'Chữ ký chủ trọ (Bên A)', controller: _ownerSignatureController, existingBase64: _existingOwnerSignature),
          const SizedBox(height: 12),
          _buildSignatureBox(title: 'Chữ ký khách thuê (Bên B)', controller: _tenantSignatureController, existingBase64: _existingTenantSignature),
        ],
      ),
    );
  }

  Widget _buildSignatureBox({required String title, required SignatureController controller, String? existingBase64}) {
    final bool hasSavedSig = existingBase64 != null && existingBase64.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasSavedSig ? AppColors.primaryGreen : Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Row(
                children: [
                  Icon(hasSavedSig ? Icons.check_circle : Icons.edit_note, size: 14, color: hasSavedSig ? AppColors.primaryGreen : Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    hasSavedSig ? 'Đã ký số' : 'Vẽ chữ ký',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasSavedSig ? AppColors.primaryGreen : Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (title.contains('Bên A')) {
                          _existingOwnerSignature = null;
                        } else {
                          _existingTenantSignature = null;
                        }
                      });
                      controller.clear();
                    },
                    icon: const Icon(Icons.refresh, size: 12),
                    label: Text(hasSavedSig ? 'Ký lại' : 'Xóa', style: const TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasSavedSig)
            _renderSignatureImage(existingBase64)
          else
            Container(
              height: 100,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
              child: Signature(controller: controller, backgroundColor: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _renderSignatureImage(String base64Str) {
    try {
      final clean = base64Str.contains(',') ? base64Str.split(',').last : base64Str;
      final bytes = base64Decode(clean);
      return Container(
        height: 100,
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.primaryGreen)),
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    } catch (_) {
      return const SizedBox(height: 60, child: Center(child: Text('Đã có chữ ký điện tử', style: TextStyle(color: AppColors.primaryGreen))));
    }
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: !_isSubmitting && _agreeTerms && _bothSigned ? _signContract : null,
            icon: const Icon(Icons.draw, color: Colors.white),
            label: const Text('Xác nhận ký hợp đồng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isSubmitting ? null : _withdrawSigning,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Thu hồi yêu cầu ký'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : _saveDraft,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('Lưu bản nháp', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _completeContract,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Hoàn tất & Gửi ký', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
