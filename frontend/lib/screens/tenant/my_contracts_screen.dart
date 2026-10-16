import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';



class ContractMock {
  final String title;
  final String status;
  final String startDate;

  ContractMock({
    required this.title,
    required this.status,
    required this.startDate,
  });
}

class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({super.key});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  // LỌC
  String selectedFilter = 'Tất cả';
  final List<String> filters = ['Tất cả', 'Hiệu lực', 'Đã hết hạn'];


  final List<ContractMock> dummyContracts = [
    ContractMock(
      title: 'KDC Nhơn Đức, Huyện Nhà Bè',
      status: 'Hiệu lực',
      startDate: '01/10/2026',
    ),
    ContractMock(
      title: 'KTX ĐH Công Thương, Tân Phú',
      status: 'Đã hết hạn',
      startDate: '15/08/2025',
    ),
    ContractMock(
      title: 'Phòng trọ 102 - Quận 7',
      status: 'Hiệu lực',
      startDate: '15/09/2026',
    ),
  ];

  @override
  Widget build(BuildContext context) {

    List<ContractMock> filteredContracts = dummyContracts.where((contract) {
      if (selectedFilter == 'Tất cả') return true;
      return contract.status == selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        centerTitle: true,
        title: const Text(
          'Hợp đồng của tôi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        elevation: 0,
      ),
      body: Column(
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
            child: ListView.builder(
              itemCount: filteredContracts.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final contract = filteredContracts[index];
                bool isActive = contract.status == 'Hiệu lực';

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
                      // CHUYỂN SANG CHI TIẾT HỢP ĐỒNG
                      Navigator.pushNamed(context, '/tenant/contracts/detail');
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
                                  contract.title,
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
                                  contract.status,
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
                                contract.startDate,
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
    );
  }
}