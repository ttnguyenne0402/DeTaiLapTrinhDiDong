import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/contract_card.dart';
import '../../route/app_routes.dart';
import 'properties_manage.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'contract_form.dart';
import 'tenant_list_screen.dart';

class Contracts_manager extends StatefulWidget {
  const Contracts_manager({super.key});

  @override
  State<StatefulWidget> createState() => HienThiQuanLyHopDong();
}

class HienThiQuanLyHopDong extends State<Contracts_manager> {
  String _selectedRole = "Tất cả";

  // dữ liệu mẫu
  final List<Map<String, dynamic>> contracts = [
    {
      'status': 'Đang hiệu lực',
      'room': 'Phòng 201 • Tầng 2',
      'address': 'Khu trọ Bình Thạnh • 35 m²',
      'code': 'HD-2024-P201',
      'timeText': 'Còn 6 tháng',
      'tenantName': 'Nguyễn Văn An',
      'tenantPhone': '0908 123 456',
      'rentPrice': '4.500.000đ',
      'depositPrice': '9.000.000đ',
      'duration': '📅 01/03/2024 - 28/02/2025',
      'cycleText': 'Kỳ thu: Ngày 05',
      'noteText': '2 người ở ghép (An, Hoa • Đã khai báo tạm trú)',
    },
    {
      'status': 'Sắp hết hạn',
      'room': 'Phòng 302 • Tầng 3',
      'address': 'Khu trọ Bình Thạnh • Ban công',
      'code': 'HD-2024-P302',
      'timeText': 'Hết hạn sau 5 ngày!',
      'tenantName': 'Trần Thị Bích',
      'tenantPhone': '0933 555 789',
      'rentPrice': '5.200.000đ',
      'depositPrice': '10.400.000đ',
      'duration': '📅 15/09/2023 - 15/09/2024',
      'cycleText': 'Cần xử lý hoàn cọc',
      'noteText': 'Đang chờ xử lý gia hạn / thanh lý',
    },
    {
      'status': 'Bản nháp',
      'room': 'Phòng 105 • Studio',
      'address': 'Chưa kích hoạt hiệu lực',
      'code': 'HD-2024-P105',
      'timeText': 'Tạo từ lịch hẹn #AP-8823',
      'tenantName': 'Phạm Hoàng Nam',
      'tenantPhone': 'Chờ điền CCCD & ngày dọn vào',
      'rentPrice': '6.000.000đ',
      'depositPrice': '6.000.000đ',
      'duration': '📅 Chưa hoàn tất',
      'cycleText': 'Chưa thiết lập',
      'noteText': 'Hợp đồng đang ở trạng thái bản nháp',
    },
    {
      'status': 'Chờ ký',
      'room': 'Phòng 108 • Tầng 1',
      'address': 'Khu trọ Bình Thạnh • 30 m²',
      'code': 'HD-2024-P108',
      'timeText': 'Đang chờ khách thuê ký',
      'tenantName': 'Lê Minh Tuấn',
      'tenantPhone': '0912 345 678',
      'rentPrice': '5.000.000đ',
      'depositPrice': '10.000.000đ',
      'duration': '📅 01/10/2024 - 30/09/2025',
      'cycleText': 'Kỳ thu: Ngày 05',
      'noteText': 'Chủ trọ đã hoàn tất hợp đồng, chờ người thuê ký',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredContracts = contracts.where((contract) {
      if (_selectedRole == "Tất cả") {
        return true;
      }

      return contract['status'] == _selectedRole;
    }).toList();

    final activeCount = contracts.where(
          (contract) => contract['status'] == 'Đang hiệu lực',
    ).length;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,

      drawer: OwnerDrawer(
        currentRoute: 'contracts',
      ),

      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          'Quản lý hợp đồng',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 16,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.contractForm,
          );
        },
        backgroundColor: const Color(0xFFFFA726),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        label: const Text(
          "Tạo hợp đồng",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: 120,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // tìm kiếm
              TextField(
                decoration: InputDecoration(
                  hintText:
                  'Tìm mã HĐ, tên hoặc SĐT khách thuê...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // thống kê
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'HỢP ĐỒNG',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.shield_outlined,
                                color: Colors.white54,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$activeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Đang hoạt động',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOANH THU DỰ KIẾN',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '72.500.000đ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tổng tiền thuê / tháng',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // bộ lọc
              SizedBox(
                height: 42,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      "Tất cả",
                      "Đang hiệu lục",
                      "Sắp hết hạn",
                      "Chờ ký",
                      "Bản nháp",
                    ].map((role) {
                      final select =
                          _selectedRole == role;

                      return Padding(
                        padding:
                        const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(role),
                          selected: select,
                          selectedColor:
                          AppColors.primaryGreen,
                          backgroundColor:
                          AppColors.background,
                          side: BorderSide.none,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(26),
                          ),
                          labelStyle: TextStyle(
                            color: select
                                ? AppColors.background
                                : Colors.grey,
                            fontSize: 13,
                            fontWeight: select
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedRole = role;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // danh sách hợp đồng
              ...filteredContracts.map(
                    (contract) => Padding(
                  padding:
                  const EdgeInsets.only(bottom: 16),
                  child: _buildContractCard(contract),
                ),
              ),

              if (filteredContracts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'Không có hợp đồng phù hợp',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.home,
              'Trang chủ',
              true,
                  () {},
            ),
            _buildNavItem(
              Icons.apartment,
              'Tòa nhà',
              false,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const PropertiesManageScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 40),
            _buildNavItem(
              Icons.people_outline,
              'Người thuê',
              false,
                  () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TenantListScreen(),
                        ),);
                  },
            ),
            _buildNavItem(
              Icons.person_outline,
              'Cá nhân',
              false,
                  () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard(
      Map<String, dynamic> contract) {
    final status = contract['status'];

    Color statusBgColor;
    Color statusTextColor;
    Color timeColor;
    String primaryBtnText;
    Color primaryBtnColor;

    if (status == 'Đang hiệu lực') {
      statusBgColor = Colors.green.shade100;
      statusTextColor = Colors.green.shade800;
      timeColor = Colors.green;
      primaryBtnText = 'Thanh lý';
      primaryBtnColor = AppColors.primaryGreen;

    } else if (status == 'Sắp hết hạn') {
      statusBgColor = Colors.orange.shade100;
      statusTextColor = const Color(0xFFE68A00);
      timeColor = Colors.red;
      primaryBtnText = 'Gia hạn hợp đồng';
      primaryBtnColor = const Color(0xFFFFA726);
    } else if (status == 'Chờ ký') {
      statusBgColor = Colors.blue.shade100;
      statusTextColor = Colors.blue.shade800;
      timeColor = Colors.blue;
      primaryBtnText = 'Ký hợp đồng';
      primaryBtnColor = AppColors.primaryGreen;
    } else {
      statusBgColor = Colors.grey.shade200;
      statusTextColor = Colors.grey.shade700;
      timeColor = Colors.grey;
      primaryBtnText = 'Tiếp tục';
      primaryBtnColor = AppColors.primaryGreen;
    }

    return ContractCard(
      room: contract['room'],
      address: contract['address'],
      status: status,
      statusBgColor: statusBgColor,
      statusTextColor: statusTextColor,
      code: contract['code'],
      timeText: contract['timeText'],
      timeColor: timeColor,
      tenantName: contract['tenantName'],
      tenantPhone: contract['tenantPhone'],
      rentPrice: contract['rentPrice'],
      depositPrice: contract['depositPrice'],
      duration: contract['duration'],
      cycleText: contract['cycleText'],
      noteText: contract['noteText'],
      primaryBtnText: primaryBtnText,
      primaryBtnColor: primaryBtnColor,

      // xem chi tiết
      onTapDetail: () {
        Navigator.pushNamed(context,AppRoutes.contractDetailOwner);
      },

      // nút chính
      onTapPrimaryBtn: () {
        _handlePrimaryButton(contract);
      },
    );
  }




  void _openContract(
      Map<String, dynamic> contract) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Contract_form(
          contract: contract,
        ),
      ),
    );
  }

  void _handlePrimaryButton(
      Map<String, dynamic> contract) {
    final status = contract['status'];

    if (status == 'Đang hiệu lực') {
      Navigator.pushNamed(context, AppRoutes.termination);
    } else if (status == 'Sắp hết hạn') {
      _showMessage(
        'Mở chức năng gia hạn hợp đồng',
      );
    } else if (status == 'Chờ ký') {
      _openContract(contract);
    } else if (status == 'Bản nháp') {
      _openContract(contract);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
    ) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 8.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive
                ? AppColors.primaryGreen
                : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive
                  ? AppColors.primaryGreen
                  : Colors.grey,
              fontWeight: isActive
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}