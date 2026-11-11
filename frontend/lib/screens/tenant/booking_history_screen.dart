import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../../services/auth_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/status_badge.dart';

class booking_history_screen extends StatefulWidget {
  const booking_history_screen({Key? key}) : super(key: key);

  @override
  State<booking_history_screen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<booking_history_screen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  // URL API Backend
  final String _baseUrl = 'http://10.0.2.2:5093/api/viewing-appointments';
  String _tenantId = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }
  Future<void> _initData() async {
    final userId = await AuthStorage.getUserId();
    if (mounted) {
      setState(() {
        _tenantId = userId ?? '';
      });
      await _fetchAppointments();
    }
  }
  // Khởi tạo Custom Client bỏ qua SSL
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  //  API: Lấy danh sách
  Future<void> _fetchAppointments() async {
    final client = _getCustomClient();
    try {
      final response = await client.get(Uri.parse('$_baseUrl/tenant/$_tenantId'));

      if (response.statusCode == 200) {
        setState(() {
          _appointments = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        print("Lỗi từ server: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      setState(() => _isLoading = false);
    } finally {
      client.close();
    }
  }

  //  API: Hủy lịch hẹn
  Future<void> _cancelAppointment(String id) async {
    final client = _getCustomClient();
    try {
      final response = await client.patch(Uri.parse('$_baseUrl/$id/cancel'));

      if (response.statusCode == 200) {
        _showMessage("Đã hủy lịch hẹn thành công", Colors.green);
        _fetchAppointments();
      } else {
        _showMessage("Không thể hủy lịch hẹn này", Colors.redAccent);
      }
    } catch (e) {
      _showMessage("Lỗi kết nối máy chủ", Colors.redAccent);
    } finally {
      client.close();
    }
  }

  // API: Cập nhật trạng thái
  Future<void> _updateStatus(String id, String status) async {
    final client = _getCustomClient();
    try {
      final response = await client.patch(
        Uri.parse('$_baseUrl/$id/status'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"status": status}),
      );

      if (response.statusCode == 200) {
        final message = status == "confirmed" ? "Đã đồng ý giờ hẹn mới" : "Đã từ chối giờ hẹn";
        _showMessage(message, AppColors.primaryGreen);
        _fetchAppointments();
      } else {
        _showMessage("Cập nhật thất bại", Colors.redAccent);
      }
    } catch (e) {
      _showMessage("Lỗi kết nối máy chủ", Colors.redAccent);
    } finally {
      client.close();
    }
  }

  void _showMessage(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.primaryGreen,
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          title: const Text(
            'Lịch xem phòng của tôi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,

          elevation: 0,
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _fetchAppointments,
              color: AppColors.primaryGreen,
              child: _appointments.isEmpty
                  ? ListView(

                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  const Center(
                    child: Text('Bạn chưa có lịch hẹn nào.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(_appointments[index]);
              },
            ),
          ),
        )
    )
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'pending';
    final id = data['id'].toString();

    final roomName = data['roomName'] ?? 'Phòng trọ';
    final address = data['address'] ?? 'Đang cập nhật địa chỉ';

    final date = data['date']?.toString() ?? '';
    final time = data['time']?.toString() ?? '';

    final message = data['message'] ?? '';
    final ownerNote = data['ownerNote'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    roomName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE5E7EB)),

            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  "$time - Ngày $date",
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(address, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ),
              ],
            ),

            if (message.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Lời nhắn: $message",
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],

            if (ownerNote.toString().isNotEmpty && (status == 'rejected' || status == 'rescheduled')) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Chủ nhà: $ownerNote",
                        style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ĐÃ MỞ KHÓA VÀ TRUYỀN ID CHO CÁC NÚT BẤM
            if (status == 'pending' || status == 'rescheduled') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(status, id),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // HÀM TẠO NÚT BẤM DỰA TRÊN TRẠNG THÁI
  List<Widget> _buildActionButtons(String status, String id) {
    if (status == 'pending') {
      return [
        OutlinedButton(
          onPressed: () => _cancelAppointment(id), // Gọi API Hủy
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Hủy lịch"),
        ),
      ];
    } else if (status == 'rescheduled') {
      return [
        OutlinedButton(
          onPressed: () => _updateStatus(id, 'rejected'), // Gọi API Từ chối
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Từ chối"),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _updateStatus(id, 'confirmed'), // Gọi API Đồng ý
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
          child: const Text("Đồng ý giờ mới", style: TextStyle(color: Colors.white)),
        ),
      ];
    }
    return [];
  }
}