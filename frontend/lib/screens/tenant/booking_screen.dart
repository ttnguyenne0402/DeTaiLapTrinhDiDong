import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../widgets/tenant/calendar_widget.dart';

class booking_screen extends StatefulWidget {

  final String roomId;
  final String roomName;
  final String address;
  final String price;

  const booking_screen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.address,
    required this.price,
  });

  @override
  State<booking_screen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<booking_screen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isSubmitting = false;

  // Giả lập TenantId (Sau này lấy từ SharedPreferences/Login)
  final String _currentTenantId = 'TENANT01';

  @override
  void dispose() {
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Khởi tạo Client bỏ qua lỗi SSL
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  Future<void> _submitBooking() async {
    FocusScope.of(context).unfocus();

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn ngày và giờ hẹn xem phòng!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);


      // 1. Format Ngày (YYYY-MM-DD)
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      // 2. Format Giờ (HH:mm:00)
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      final requestData = {
        "roomId": widget.roomId,
        "tenantId": _currentTenantId,
        "appointmentDate": dateStr,
        "appointmentTime": timeStr,
        "phone": _phoneController.text.trim(),
        "message": _noteController.text.trim(),
      };

      final client = _getCustomClient();
      try {
        final response = await client.post(
          Uri.parse('https://10.0.2.2:7203/api/viewing-appointments'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(requestData),
        );

        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Gửi lịch hẹn thành công!"),
                backgroundColor: AppColors.primaryGreen,
              ),
            );

            Navigator.pushReplacementNamed(context, '/tenant/booking-history');
          }
        } else {
          print("Lỗi server: ${response.body}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Gửi lịch thất bại. Vui lòng thử lại."),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } catch (e) {
        print("Lỗi kết nối: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Không thể kết nối đến máy chủ."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        client.close();
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          'Đặt lịch xem phòng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roomDetail, (route) => false);
              }
            }
        ),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD THÔNG TIN
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4)
                          )
                        ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                  "Địa chỉ: ${widget.address}",
                                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                            )
                          ],
                        ),
                        const Divider(height: 24, thickness: 1, color: Color(0xFFE5E7EB)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                "Phòng: ${widget.roomName}",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${widget.price} / tháng",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  CalendarWidget(
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    onDateSelected: (date) => setState(() => _selectedDate = date),
                    onTimeSelected: (time) => setState(() => _selectedTime = time),
                  ),
                  const SizedBox(height: 24),

                  const Text("Số điện thoại liên hệ *", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: _buildInputDecoration(hint: "Nhập số điện thoại của bạn", icon: Icons.phone_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                      if (!RegExp(r'^0[0-9]{9}$').hasMatch(value.trim())) return 'Số điện thoại không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text("Ghi chú cho chủ nhà: ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: _buildInputDecoration(hint: "VD: Mình đi làm về muộn...", icon: null),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: AppColors.cardSurface,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4))
            ]),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text("GỬI LỊCH HẸN",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.textSecondary, size: 20) : null,
      filled: true,
      fillColor: AppColors.cardSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      counterText: "",
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }
}