import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/owner_drawer.dart';
import 'service_form.dart';

class ServicesManageScreen extends StatefulWidget {
  const ServicesManageScreen({super.key});

  @override
  State<ServicesManageScreen> createState() => _ServicesManageScreenState();
}

class _ServicesManageScreenState extends State<ServicesManageScreen> {
  final List<Map<String, dynamic>> _services = [
    {
      'id': 's1',
      'name': 'Điện sinh hoạt',
      'price': '3.500',
      'unit': 'kWh',
      'icon': Icons.bolt,
      'iconColor': Colors.amber[700],
      'isMandatory': true,
      'status': true,
      'description': 'Tính theo chỉ số đồng hồ hàng tháng.',
    },
    {
      'id': 's2',
      'name': 'Nước sinh hoạt',
      'price': '100.000',
      'unit': 'người/tháng',
      'icon': Icons.water_drop,
      'iconColor': Colors.blue[600],
      'isMandatory': true,
      'status': true,
      'description': 'Tính khoán theo số lượng người ở thực tế.',
    },
    {
      'id': 's3',
      'name': 'Internet / Wifi tốc độ cao',
      'price': '100.000',
      'unit': 'phòng/tháng',
      'icon': Icons.wifi,
      'iconColor': Colors.green[600],
      'isMandatory': false,
      'status': true,
      'description': 'Gói cước băng thông 150Mbps.',
    },
    {
      'id': 's4',
      'name': 'Phí vệ sinh & Rác thải',
      'price': '50.000',
      'unit': 'phòng/tháng',
      'icon': Icons.cleaning_services,
      'iconColor': Colors.orange[700],
      'isMandatory': true,
      'status': true,
      'description': 'Thu gom rác hàng ngày và lau dọn hành lang.',
    },
    {
      'id': 's5',
      'name': 'Phí bảo trì Thang máy',
      'price': '50.000',
      'unit': 'người/tháng',
      'icon': Icons.elevator,
      'iconColor': Colors.purple[600],
      'isMandatory': false,
      'status': false,
      'description': 'Áp dụng cho các tầng từ tầng 2 trở lên.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      drawer: const OwnerDrawer(currentRoute: 'services'),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Quản lý Dịch vụ & Bảng giá',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9FB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bảng giá dịch vụ này sẽ được áp dụng tự động khi tính hóa đơn tiền trọ hàng tháng.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.primaryGreen,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh sách dịch vụ áp dụng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_services.length} dịch vụ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return _buildServiceCard(service);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ServiceFormScreen()),
          );
          if (result != null && result is Map<String, dynamic>) {
            setState(() {
              _services.add(result);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Đã thêm dịch vụ mới thành công!'),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          }
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm dịch vụ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final bool isActive = service['status'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (service['iconColor'] as Color? ?? AppColors.primaryGreen)
                        .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                service['icon'] as IconData? ?? Icons.miscellaneous_services,
                color: service['iconColor'] as Color? ?? AppColors.primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        service['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (service['isMandatory'] == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Bắt buộc',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      text: '${service['price']}đ ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                      children: [
                        TextSpan(
                          text: '/ ${service['unit']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (service['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      service['description'] ?? '',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: isActive,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (val) {
                    setState(() {
                      service['status'] = val;
                    });
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ServiceFormScreen(initialData: service),
                      ),
                    );
                    setState(() {});
                  },
                  child: Text(
                    'Sửa',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
