
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';
import '../../utils/database_helper.dart';
import 'contract_detail_screen.dart';
import '../../services/auth_storage.dart';

class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({super.key});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  String selectedFilter = 'Tất cả';

  final List<String> filters = [
    'Tất cả',
    'Chờ ký',
    'Hiệu lực',
    'Đã hết hạn',
    'Đã thanh lý'
  ];

  List _contracts = [];
  bool _isLoading = true;
  late String _apiUrl;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final userId = await AuthStorage.getUserId();

    _apiUrl =
    'http://10.0.2.2:5093/api/contracts/tenant/${userId ?? ""}';

    await _loadData();
  }

  IOClient _getCustomClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    return IOClient(httpClient);
  }

  Future<void> _loadData() async {
    final localData =
    await DatabaseHelper.instance.getLocalContracts();

    if (localData.isNotEmpty) {
      setState(() {
        _contracts = List.from(localData);
        _isLoading = false;
      });
    }

    final client = _getCustomClient();

    try {
      final response = await client.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> apiData =
        json.decode(response.body);

        await DatabaseHelper.instance.insertContracts(apiData);

        if (mounted) {
          setState(() {
            _contracts = List.from(apiData);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 2. LỌC ĐÚNG TRẠNG THÁI THEO TAB ĐƯỢC CHỌN
    List filteredContracts = _contracts.where((contract) {
      final st = contract['status'] ?? '';

      if (selectedFilter == 'Tất cả') return true;

      if (selectedFilter == 'Chờ ký') {
        return st == 'pending' || st == 'Chờ ký';
      }

      if (selectedFilter == 'Hiệu lực') {
        return st == 'active' || st == 'Đang hiệu lực';
      }

      if (selectedFilter == 'Đã hết hạn') {
        return st == 'expired' || st == 'Đã hết hạn';
      }

      if (selectedFilter == 'Đã thanh lý') {
        return st == 'terminated' || st == 'Đã thanh lý';
      }

      return false;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        centerTitle: true,
        title: const Text(
          'Hợp đồng của tôi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TABS LỌC ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((filter) {
                      bool isSelected =
                          selectedFilter == filter;

                      return Padding(
                        padding:
                        const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor:
                          AppColors.primaryGreen,
                          backgroundColor:
                          AppColors.cardSurface,
                          showCheckmark: false,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : Colors.grey.shade300,
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

              // --- DANH SÁCH HỢP ĐỒNG ---
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : filteredContracts.isEmpty
                    ? const Center(
                  child: Text(
                    'Không có hợp đồng nào.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount:
                    filteredContracts.length,
                    padding:
                    const EdgeInsets.only(
                      bottom: 20,
                    ),
                    itemBuilder: (context, index) {
                      final contract =
                      filteredContracts[index];

                      final st =
                          contract['status'] ?? '';

                      // 🔴 3. HIỂN THỊ ĐÚNG MÀU SẮC VÀ TÊN NHÃN TRẠNG THÁI
                      String statusText;
                      Color statusBg;
                      Color statusColor;

                      if (st == 'pending' ||
                          st == 'Chờ ký') {
                        statusText = 'Chờ ký';
                        statusBg =
                            Colors.orange.shade100;
                        statusColor =
                            Colors.orange.shade900;
                      } else if (st == 'active' ||
                          st == 'Đang hiệu lực') {
                        statusText = 'Đang hiệu lực';
                        statusBg =
                            AppColors.lightGreen;
                        statusColor =
                            AppColors.primaryGreen;
                      } else if (st == 'expired' ||
                          st == 'Đã hết hạn') {
                        statusText = 'Đã hết hạn';
                        statusBg =
                            Colors.grey.shade200;
                        statusColor =
                            Colors.grey.shade700;
                      } else {
                        statusText = 'Đã thanh lý';
                        statusBg =
                            Colors.red.shade100;
                        statusColor =
                            Colors.red.shade800;
                      }

                      String title =
                          contract['title'] ??
                              contract['roomName'] ??
                              'Hợp đồng thuê phòng';

                      if (contract['contractCode'] !=
                          null) {
                        title =
                        '$title (${contract['contractCode']})';
                      }

                      return Card(
                        color: AppColors.cardSurface,
                        elevation: 2,
                        margin:
                        const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius:
                          BorderRadius.circular(12),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const ContractDetailScreen(),
                                settings: RouteSettings(
                                  arguments:
                                  contract['id'],
                                ),
                              ),
                            );

                            _loadData();
                          },
                          child: Padding(
                            padding:
                            const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style:
                                        const TextStyle(
                                          color: AppColors
                                              .textPrimary,
                                          fontSize: 15,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons
                                          .arrow_forward_ios,
                                      size: 16,
                                      color: AppColors
                                          .textSecondary,
                                    )
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    const Text(
                                      'Trạng thái: ',
                                      style: TextStyle(
                                        color: AppColors
                                            .textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Container(
                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration:
                                      BoxDecoration(
                                        color: statusBg,
                                        borderRadius:
                                        BorderRadius
                                            .circular(6),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Text(
                                      'Thời hạn: ',
                                      style: TextStyle(
                                        color: AppColors
                                            .textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${contract['startDate'] ?? 'N/A'} - ${contract['endDate'] ?? 'N/A'}',
                                      style:
                                      const TextStyle(
                                        color: AppColors
                                            .textPrimary,
                                        fontWeight:
                                        FontWeight.w500,
                                        fontSize: 13,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
