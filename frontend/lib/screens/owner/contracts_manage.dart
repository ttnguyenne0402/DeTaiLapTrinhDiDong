import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/contract_card.dart';
import '../../route/app_routes.dart';
import 'contract_detail_owner.dart';
import 'properties_manage.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'contract_form.dart';
import 'tenant_list_screen.dart';
import '../../services/owner/contract_service.dart';
import '../../screens/owner/termination_screen.dart';


class Contracts_manager extends StatefulWidget {
  const Contracts_manager({super.key});

  @override
  State<StatefulWidget> createState() => HienThiQuanLyHopDong();
}

class HienThiQuanLyHopDong extends State<Contracts_manager> {
  String _selectedRole = "Tất cả";
  String _searchKeyword = "";

  List<dynamic> _contracts = [];
  int _activeCount = 0;
  double _expectedRevenue = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchContracts();
  }

  // Tải danh sách hợp đồng thực tế từ API Backend
  Future<void> _fetchContracts() async {
    setState(() => _isLoading = true);
    try {
      final res = await ContractService.getContracts(
        status: _selectedRole,
        search: _searchKeyword,
      );
      setState(() {
        _contracts = res.contracts;
        _activeCount = res.activeCount;
        _expectedRevenue = res.expectedRevenue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Lỗi nạp danh sách hợp đồng: $e");
    }
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
      drawer: const OwnerDrawer(currentRoute: 'contracts'),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          'Quản lý hợp đồng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 16,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Contract_form()),
          );
          if (result == true && mounted) {
            _fetchContracts();
          }
        },
        backgroundColor: const Color(0xFFFFA726),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        label: const Text(
          "Tạo hợp đồng",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _fetchContracts,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 120),
            child: Column(
              children: [
                // 1. Ô tìm kiếm
                TextField(
                  onChanged: (value) {
                    _searchKeyword = value.toLowerCase().trim();
                    _fetchContracts();
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm mã HĐ, tên hoặc SĐT khách thuê...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 2. Thẻ thống kê
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'HỢP ĐỒNG',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                Icon(Icons.shield_outlined, color: Colors.white54, size: 18),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_activeCount',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Đang hoạt động',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
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
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DOANH THU DỰ KIẾN',
                              style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatCurrency(_expectedRevenue)}đ',
                              style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Tổng tiền thuê / tháng',
                              style: TextStyle(color: Colors.black45, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 3. Tab bộ lọc
                SizedBox(
                  height: 42,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        "Tất cả",
                        "Đang hiệu lực",
                        "Sắp hết hạn",
                        "Chờ ký",
                        "Bản nháp",
                      ].map((role) {
                        final select = _selectedRole == role;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(role),
                            selected: select,
                            selectedColor: AppColors.primaryGreen,
                            backgroundColor: AppColors.background,
                            side: BorderSide.none,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            labelStyle: TextStyle(
                              color: select ? AppColors.background : Colors.grey,
                              fontSize: 13,
                              fontWeight: select ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedRole = role);
                                _fetchContracts();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Danh sách hợp đồng
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )
                else if (_contracts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('Không có hợp đồng phù hợp', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ..._contracts.map(
                        (contract) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildContractCard(contract),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Trang chủ', true, () {}),
            _buildNavItem(Icons.apartment, 'Tòa nhà', false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PropertiesManageScreen()),
              );
            }),
            const SizedBox(width: 40),
            _buildNavItem(Icons.people_outline, 'Người thuê', false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TenantListScreen()),
              );
            }),
            _buildNavItem(Icons.person_outline, 'Cá nhân', false, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard(dynamic contract) {
    final status = contract['status'] ?? '';


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
      room: contract['room'] ?? '',
      address: contract['address'] ?? '',
      status: status,
      statusBgColor: statusBgColor,
      statusTextColor: statusTextColor,
      code: contract['code'] ?? '',
      timeText: contract['timeText'] ?? '',
      timeColor: timeColor,
      tenantName: contract['tenantName'] ?? '',
      tenantPhone: contract['tenantPhone'] ?? '',
      rentPrice: contract['rentPrice'] ?? '',
      depositPrice: contract['depositPrice'] ?? '',
      duration: contract['duration'] ?? '',
      cycleText: contract['cycleText'] ?? '',
      noteText: contract['noteText'] ?? '',
      primaryBtnText: primaryBtnText,
      primaryBtnColor: primaryBtnColor,
      onTapDetail: () {
        final status = contract['status'] ?? '';


        if (status == 'Bản nháp' || status == 'draft') {
          _openContract(Map<String, dynamic>.from(contract));
          return;
        }


        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractDetailScreen(contract: Map<String, dynamic>.from(contract)),
          ),
        );
      },
      onTapPrimaryBtn: () {
        _handlePrimaryButton(Map<String, dynamic>.from(contract));
      },
    );
  }

  Future<void> _openContract(Map<String, dynamic> contract) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Contract_form(contract: contract)),
    );

    if (result == true && mounted) {
      _fetchContracts();
    }
  }

  void _handlePrimaryButton(Map<String, dynamic> contract) {
    final status = contract['status'];
    if (status == 'Đang hiệu lực') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContractLiquidationScreen(
            contractId: contract['id']?.toString(),
          ),
        ),
      );
    } else if (status == 'Sắp hết hạn') {
      _showMessage('Mở chức năng gia hạn hợp đồng');
    } else {
      _openContract(contract);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? AppColors.primaryGreen : Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.primaryGreen : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}