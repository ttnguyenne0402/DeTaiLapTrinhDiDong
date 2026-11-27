import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';

enum RoomUtilityStatus {
  completed,// đã ghi
  abnormal,// bất thường
  inputting,// đang nhập
  pending,// chưa ghi chỉ số
}

class RoomCardColors {
  static const Color primaryDarkGreen = Color(0xFF0F3E2E);
  static const Color accentGreen = Color(0xFF1B5E20);
  static const Color backgroundLight = Color(0xFFF4F8F5);
  static const Color cardBg = Colors.white;
  static const Color orangeWarning = Color(0xFFFFA726);
  static const Color redAlert = Color(0xFFE53935);
  static const Color redLightBg = Color(0xFFFFEBEE);
  static const Color greenLightBg = Color(0xFFE8F5E9);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color chipGray = Color(0xFFE0E0E0);
}

class RoomUtilityCard extends StatefulWidget {
  final String roomName;
  final String tenantName;
  final String? phone;
  final RoomUtilityStatus status;
  final String? totalAmount;

  final num? elecOld;
  final num? elecNew;
  final String? elecDiff;
  final String? elecCost;

  final num? waterOld;
  final num? waterNew;
  final String? waterDiff;
  final String? waterCost;

  final String? warningTag;
  final String? warningMessage;
  final int proofImagesCount;
  final bool isPaid;

  // Callback để màn hình cha cập nhật trạng thái phòng.
  final VoidCallback? onEnterInput;
  final Future<void> Function(String elec, String water)? onSave;

  const RoomUtilityCard({
    super.key,
    required this.roomName,
    required this.tenantName,
    this.phone,
    required this.status,
    this.isPaid = false,
    this.totalAmount,
    this.elecOld,
    this.elecNew,
    this.elecDiff,
    this.elecCost,
    this.waterOld,
    this.waterNew,
    this.waterDiff,
    this.waterCost,
    this.warningTag,
    this.warningMessage,
    this.proofImagesCount = 0,
    this.onEnterInput,
    this.onSave,
  });

  @override
  State<RoomUtilityCard> createState() => _RoomUtilityCardState();
}

class _RoomUtilityCardState extends State<RoomUtilityCard> {
  static const _meterOcr = MethodChannel('tro_oi/meter_ocr');
  static final _readingFormat = RegExp(r'^\d{1,8}(?:[.,]\d{1,2})?$');
  static final _readingInImage = RegExp(r'(?<![\d.,-])\d{1,8}(?:[.,]\d{1,2})?(?![\d.,])');

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _elecController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();

  File? _electricityImage;
  File? _waterImage;

  bool _saving = false;
  bool _reading = false;
  bool? _scanningElectricity;
  final Map<bool, List<String>> _scanResults = {};
  bool get _supportsMeterScan => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();

    if (widget.elecNew != null) {
      _elecController.text = widget.elecNew.toString();
    }

    if (widget.waterNew != null) {
      _waterController.text = widget.waterNew.toString();
    }
  }

  @override
  void dispose() {
    _elecController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  // Mở camera hoặc thư viện ảnh.
  Future<void> _showImageSourcePicker({
    required bool isElectricity,
    bool scan = false,
  }) async {
    if (!mounted || _saving || _reading) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isElectricity
                      ? '${scan ? 'Quét' : 'Ảnh'} công tơ điện - ${widget.roomName}'
                      : '${scan ? 'Quét' : 'Ảnh'} công tơ nước - ${widget.roomName}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: RoomCardColors.accentGreen,
                    size: 30,
                  ),
                  title: const Text('Chụp ảnh bằng camera'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: RoomCardColors.accentGreen,
                    size: 30,
                  ),
                  title: const Text('Chọn ảnh từ thư viện'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || source == null) return;
    await _pickImage(source, isElectricity: isElectricity, scan: scan);
  }

  // Chụp ảnh hoặc lấy ảnh từ thư viện bằng image_picker.
  Future<void> _pickImage(
      ImageSource source, {
        required bool isElectricity,
        required bool scan,
      }) async {
    if (_reading || _saving) return;
    setState(() => _reading = true);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (!mounted || pickedFile == null) return;

      setState(() {
        if (isElectricity) {
          _electricityImage = File(pickedFile.path);
        } else {
          _waterImage = File(pickedFile.path);
        }
      });

      if (scan) {
        setState(() {
          _scanningElectricity = isElectricity;
          _scanResults.remove(isElectricity);
        });
        await _scanMeter(pickedFile.path, isElectricity: isElectricity);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isElectricity
                ? 'Đã thêm ảnh công tơ điện phòng ${widget.roomName}'
                : 'Đã thêm ảnh công tơ nước phòng ${widget.roomName}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scan
              ? 'Không thể quét ảnh. Hãy chụp rõ dãy số hoặc nhập tay.'
              : 'Không thể mở ảnh. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reading = false;
          _scanningElectricity = null;
        });
      }
    }
  }

  Future<void> _scanMeter(String path, {required bool isElectricity}) async {
    final text = await _meterOcr.invokeMethod<String>(
      'readText',
      {'path': path},
    ).timeout(const Duration(seconds: 12));
    if (!mounted || widget.isPaid) return;

    final oldReading = (isElectricity ? widget.elecOld : widget.waterOld) ?? 0;
    final candidates = _readingInImage.allMatches(text ?? '')
        .map((match) => match.group(0)!)
        .where((value) => (_parseReading(value) ?? -1) >= oldReading)
        .toSet()
        .take(12)
        .toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chưa đọc được chỉ số hợp lệ. Hãy chụp sát dãy số hoặc nhập tay.'),
      ));
      return;
    }

    setState(() {
      _scanResults[isElectricity] = candidates;
    });
  }

  num? _parseReading(String raw) {
    final value = raw.trim();
    return _readingFormat.hasMatch(value)
        ? num.tryParse(value.replaceAll(',', '.'))
        : null;
  }

  void _increaseReading({
    required TextEditingController controller,
    required int amount,
  }) {
    final currentValue = _parseReading(controller.text) ?? 0;
    controller.text = (currentValue + amount).toStringAsFixed(2);
  }

  Future<void> _saveReading() async {
    final save = widget.onSave;
    if (_saving || _reading || widget.isPaid || save == null) return;

    final electricity = _parseReading(_elecController.text);
    final water = _parseReading(_waterController.text);

    if (electricity == null ||
        water == null ||
        electricity < (widget.elecOld ?? 0) ||
        water < (widget.waterOld ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập chỉ số hợp lệ và không nhỏ hơn chỉ số cũ.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await save(electricity.toString(), water.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoomCardColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.status == RoomUtilityStatus.abnormal
              ? RoomCardColors.redAlert.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                widget.tenantName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: RoomCardColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: RoomCardColors.accentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: RoomCardColors.accentGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: RoomCardColors.accentGreen),
                    SizedBox(width: 4),
                    Text(
                      'Đang thuê',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: RoomCardColors.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.phone != null && widget.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'SĐT: ${widget.phone}',
              style: const TextStyle(
                fontSize: 12,
                color: RoomCardColors.textSecondary,
              ),
            ),
          ],
          if (widget.status == RoomUtilityStatus.abnormal) //bất thường
            _buildWarning(),
          const SizedBox(height: 14),
          if (widget.status == RoomUtilityStatus.inputting)
            _buildInputSection()
          else if (widget.status == RoomUtilityStatus.pending)
            _buildPendingSection()
          else
            _buildRecordedSection(), // khi đã hoàn thành
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.meeting_room_outlined,
          color: RoomCardColors.accentGreen,
          size: 25,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.roomName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RoomCardColors.textPrimary,
            ),
          ),
        ),
        Flexible(child: _buildStatusBadge()),
      ],
    );
  }

  Widget _buildStatusBadge() {
    if (widget.isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: RoomCardColors.accentGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 12, color: RoomCardColors.accentGreen),
            SizedBox(width: 4),
            Text(
              'Đã thanh toán',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoomCardColors.accentGreen),
            ),
          ],
        ),
      );
    }

    Color color;
    String label;

    switch (widget.status) {
      case RoomUtilityStatus.completed:
        color = RoomCardColors.accentGreen;
        label = 'Đã ghi';
        break;
      case RoomUtilityStatus.abnormal:
        color = RoomCardColors.redAlert;
        label = widget.warningTag ?? 'Bất thường';
        break;
      case RoomUtilityStatus.inputting:
        color = Colors.orange.shade800;
        label = 'Đang nhập';
        break;
      case RoomUtilityStatus.pending:
        color = RoomCardColors.textSecondary;
        label = 'Chưa ghi';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoomCardColors.redLightBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: RoomCardColors.redAlert,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.warningMessage ?? 'Chỉ số điện nước bất thường.',
              style: const TextStyle(
                fontSize: 12,
                color: RoomCardColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOldReading('Điện', widget.elecOld, 'kWh'),
        const SizedBox(height: 8),
        _buildOldReading('Nước', widget.waterOld, 'm³'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showImageSourcePicker(
                  isElectricity: true,
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Chụp điện'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showImageSourcePicker(
                  isElectricity: false,
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Chụp nước'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onEnterInput,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Nhập số'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        _buildPhotoPreviews(),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputMeter(
          title: 'CÔNG TƠ ĐIỆN',
          oldValue: widget.elecOld ?? 0,
          unit: 'kWh',
          controller: _elecController,
          isElectricity: true,
          quickValues: const [100, 125, 150],
        ),
        const SizedBox(height: 16),
        _buildInputMeter(
          title: 'CÔNG TƠ NƯỚC',
          oldValue: widget.waterOld ?? 0,
          unit: 'm³',
          controller: _waterController,
          isElectricity: false,
          quickValues: const [5, 8, 12],
        ),
        const SizedBox(height: 12),
        _buildPhotoPreviews(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving || _reading ? null : _saveReading,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu số'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputMeter({
    required String title,
    required num oldValue,
    required String unit,
    required TextEditingController controller,
    required bool isElectricity,
    required List<int> quickValues,
  }) {
    final results = _scanResults[isElectricity];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoomCardColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: RoomCardColors.accentGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chỉ số cũ: $oldValue $unit',
            style: const TextStyle(
              color: RoomCardColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Chỉ số mới',
                    suffixText: unit,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: RoomCardColors.greenLightBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  tooltip: _supportsMeterScan ? 'Quét công tơ' : 'Chụp hoặc chọn ảnh',
                  onPressed: _reading || _saving
                      ? null
                      : () => _showImageSourcePicker(
                            isElectricity: isElectricity,
                            scan: _supportsMeterScan,
                          ),
                  icon: Icon(
                    _supportsMeterScan ? Icons.document_scanner_outlined : Icons.camera_alt,
                    color: RoomCardColors.accentGreen,
                  ),
                ),
              ),
            ],
          ),
          if (_scanningElectricity == isElectricity) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
            const SizedBox(height: 4),
            const Text('Đang đọc chỉ số...'),
          ],
          if (results != null) ...[
            const SizedBox(height: 10),
            const Text('Chọn đúng dãy số trên công tơ:'),
            Wrap(
              spacing: 8,
              children: [
                for (final value in results)
                  ActionChip(
                    label: Text('$value $unit'),
                    onPressed: widget.isPaid ? null : () {
                      controller.text = value;
                      setState(() {
                        _scanResults.remove(isElectricity);
                      });
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Tăng nhanh:',
            style: TextStyle(
              fontSize: 12,
              color: RoomCardColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: quickValues.map((value) {
              return ActionChip(
                label: Text('+$value $unit'),
                onPressed: () => _increaseReading(
                  controller: controller,
                  amount: value,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOldReading(String title, num? value, String unit) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Chỉ số $title cũ',
            style: const TextStyle(
              color: RoomCardColors.textSecondary,
            ),
          ),
        ),
        Text(
          '${value ?? 0} $unit',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRecordedSection() {
    return Column(
      children: [
        _buildMetricRow(
          title: 'Điện',
          oldValue: widget.elecOld,
          newValue: widget.elecNew,
          diff: widget.elecDiff,
          cost: widget.elecCost,
          unit: 'kWh',
        ),
        const SizedBox(height: 10),
        _buildMetricRow(
          title: 'Nước',
          oldValue: widget.waterOld,
          newValue: widget.waterNew,
          diff: widget.waterDiff,
          cost: widget.waterCost,
          unit: 'm³',
        ),
        if (widget.totalAmount != null) ...[
          const Divider(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng tiền điện nước',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                widget.totalAmount!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: RoomCardColors.accentGreen,
                ),
              ),
            ],
          ),
        ],
        if (widget.status == RoomUtilityStatus.abnormal) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showImageSourcePicker(
                    isElectricity: true,
                  ),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Chụp lại'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving || _reading || widget.isPaid ? null : _saveReading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ),
            ],
          ),
        ],
        if (widget.isPaid)
          const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 14, color: RoomCardColors.accentGreen),
                  SizedBox(width: 4),
                  Text('Đã thanh toán (Khóa)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoomCardColors.accentGreen)),
                ],
              ),
            ),
          )
        else if (widget.status == RoomUtilityStatus.completed)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onEnterInput,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa số'),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricRow({
    required String title,
    required num? oldValue,
    required num? newValue,
    required String? diff,
    required String? cost,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoomCardColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: RoomCardColors.accentGreen,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _metricValue(
                  'Chỉ số cũ',
                  '${oldValue ?? 0}',
                ),
              ),
              Expanded(
                child: _metricValue(
                  'Chỉ số mới',
                  '${newValue ?? 0}',
                ),
              ),
              Expanded(
                child: _metricValue(
                  'Tiêu thụ',
                  diff ?? '—',
                ),
              ),
            ],
          ),
          if (cost != null) ...[
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Thành tiền ($unit)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  cost,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: RoomCardColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreviews() {
    if (_electricityImage == null && _waterImage == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          if (_electricityImage != null)
            _buildPhotoThumbnail(
              title: 'Công tơ điện',
              file: _electricityImage!,
              isElectricity: true,
            ),
          if (_waterImage != null)
            _buildPhotoThumbnail(
              title: 'Công tơ nước',
              file: _waterImage!,
              isElectricity: false,
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail({
    required String title,
    required File file,
    required bool isElectricity,
  }) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  file,
                  width: 130,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 130,
                      height: 100,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    );
                  },
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                  ),
                  onPressed: () {
                    setState(() {
                      if (isElectricity) {
                        _electricityImage = null;
                      } else {
                        _waterImage = null;
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Đã đính kèm ảnh',
            style: TextStyle(
              fontSize: 11,
              color: RoomCardColors.accentGreen,
            ),
          ),
        ],
      ),
    );
  }
}
