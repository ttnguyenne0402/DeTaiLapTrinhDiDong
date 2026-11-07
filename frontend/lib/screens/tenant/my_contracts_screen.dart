import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../utils/database_helper.dart';
import 'contract_detail_screen.dart'; // Đảm bảo đã import trang chi tiết

class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({super.key});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  // LỌC
  String selectedFilter = 'Tất cả';
  final List<String> filters = ['Tất cả', 'Hiệu lực', 'Đã hết hạn'];

  List _contracts = [];
  bool _isLoading = true;

  // URL API Backend (Sử dụng 10.0.2.2 cho máy ảo Android)
  final String _apiUrl = 'https://10.0.2.2:7203/api/contracts/tenant/TENANT01';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Hàm tạo Client tùy chỉnh bỏ qua lỗi SSL
  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  Future<void> _loadData() async {
    // 1. Lấy dữ liệu từ SQLite
    final localData = await DatabaseHelper.instance.getLocalContracts();
    if (localData.isNotEmpty) {
      setState(() {
        _contracts = List.from(localData);
        _isLoading = false;
      });
    }

    // 2. Gọi API để lấy dữ liệu mới nhất
    final client = _getCustomClient();
    try {
      final response = await client.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> apiData = json.decode(response.body);

        // 3. Lưu đè dữ liệu mới vào SQLite
        await DatabaseHelper.instance.insertContracts(apiData);

        // 4. Cập nhật lại UI
        if (mounted) {
          setState(() {
            _contracts = List.from(apiData);
            _isLoading = false;
          });
        }
      } else {
        print("Lỗi server: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Lỗi khi lấy hợp đồng từ server: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    // XỬ LÝ LỌC TRÊN DỮ LIỆU THẬT
    List filteredContracts = _contracts.where((contract) {
      if (selectedFilter == 'Tất cả') return true;
      if (selectedFilter == 'Hiệu lực') return contract['status'] == 'active';
      if (selectedFilter == 'Đã hết hạn') return contract['status'] == 'expired';
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        centerTitle: true,
        title: const Text(
          'Hợp đồng của tôi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---  LỌC  ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((filter) {
                      bool isSelected = selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryGreen,
                          backgroundColor: AppColors.cardSurface,
                          showCheckmark: false,
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // --- DANH SÁCH HỢP ĐỒNG  ---
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredContracts.isEmpty
                    ? const Center(
                  child: Text('Không có hợp đồng nào.', style: TextStyle(color: AppColors.textSecondary)),
                )
                    : ListView.builder(
                  itemCount: filteredContracts.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    final contract = filteredContracts[index];
                    bool isActive = contract['status'] == 'active';

                    // Lấy tên phòng
                    String roomName = contract['roomId'] ?? 'Phòng trống';
                    if (contract['contractCode'] != null) {
                      roomName = 'Hợp đồng: ${contract['contractCode']}';
                    }

                    return Card(
                      color: AppColors.cardSurface,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContractDetailScreen(),
                              settings: RouteSettings(arguments: contract['id']),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      roomName,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text(
                                    'Trạng thái: ',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.lightGreen : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isActive ? 'Hiệu lực' : (contract['status'] == 'expired' ? 'Đã hết hạn' : 'Đã thanh lý'),
                                      style: TextStyle(
                                        color: isActive ? AppColors.primaryGreen : AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Bắt đầu: ',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    contract['startDate'] ?? 'N/A',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}