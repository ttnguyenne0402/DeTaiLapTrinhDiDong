import 'package:flutter/material.dart';
import '../../widgets/owner/utility_card_w.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/owner/owner_drawer.dart';

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen, //nền xanh đậm cho header phía trên
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            //1. header xanh lá đậm trên cùng
            _buildTopHeader(),

            //2. phần thân bo tròn góc trên phủ lên nền xanh đậm
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24), //bo tròn góc chuẩn theo hình
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Column(
                          children: [
                            //khung xanh chứa thông tin cơ sở và kỳ chốt
                            _buildGreenInfoCard(),
                            const SizedBox(height: 12),

                            //khung tiến độ ghi số
                            _buildProgressCard(),
                            const SizedBox(height: 12),

                            //banner AI OCR
                            _buildOcrBanner(),
                            const SizedBox(height: 12),

                            //thanh filter chuyển tabs
                            _buildFilterTabs(),
                            const SizedBox(height: 12),

                            //thẻ card mẫu 1: đã chốt số (có thumbnail ảnh OCR)
                            const RoomUtilityCard(
                              roomName: 'Phòng 201',
                              tenantName: 'Hoàng Minh Trí (Tầng 2)',
                              status: RoomUtilityStatus.completed,
                              totalAmount: '625.000đ',
                              elecOld: '1.420',
                              elecNew: '1.545',
                              elecDiff: '+125 kWh',
                              elecCost: '475.000đ',
                              waterOld: '85',
                              waterNew: '91',
                              waterDiff: '+6 m³',
                              waterCost: '150.000đ',
                              proofImagesCount: 2,
                            ),
                            const SizedBox(height: 12),

                            //thẻ card mẫu 2: bất thường (có box báo đỏ & nút chụp lại/xác nhận)
                            const RoomUtilityCard(
                              roomName: 'Phòng 302',
                              tenantName: 'Trần Thị Bích',
                              phone: '0933 555 789',
                              status: RoomUtilityStatus.abnormal,
                              warningTag: 'Tăng đột biến +85%',
                              warningMessage:
                              'Số điện tháng này (270 kWh) cao gấp đôi mức trung bình 3 tháng qua (145 kWh). Khuyến nghị đối chiếu lại ảnh đồng hồ trước khi lập hóa đơn.',
                              elecOld: '980',
                              elecNew: '1250',
                              elecDiff: '+270 kWh',
                              waterOld: '42',
                              waterNew: '55',
                              waterDiff: '+13 m³',
                            ),
                            const SizedBox(height: 12),

                            //thẻ card mẫu 3: chờ nhập số (thiết kế ô nhập riêng + chip tăng nhanh)
                            const RoomUtilityCard(
                              roomName: 'Phòng 102',
                              tenantName: 'Lê Văn Cường (Tầng 1)',
                              status: RoomUtilityStatus.inputting,
                              elecOld: '650',
                              waterOld: '38',
                            ),
                            const SizedBox(height: 12),

                            //thẻ card mẫu 4: chưa nhập
                            const RoomUtilityCard(
                              roomName: 'Phòng 204',
                              tenantName: 'Phạm Thị Duyên (Tầng 2)',
                              status: RoomUtilityStatus.pending,
                              elecOld: '810',
                              waterOld: '49',
                            ),
                            const SizedBox(height: 16),

                            //mẹo ghi nhanh
                            _buildTipBox(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    //footer cố định bên dưới
                    _buildBottomFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //widget header màu xanh đậm góc trên
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              );
            },
          ),
          
          Row(
            children: [
              const Text(
                'Ghi số điện nước',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
              const CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 16,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              )
            ],
          )
        ],
      ),
    );
  }

  //khung thông tin cơ sở màu xanh lá
  Widget _buildGreenInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.calendar_today, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Kỳ chốt: Tháng 08/2024',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Row(
                children: const [
                  Text('Lịch sử ghi', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(width: 4),
                  Icon(Icons.history, color: Colors.white70, size: 16),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Text('CƠ SỞ CHO THUÊ', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.corporate_fare, color: AppColors.warningOrange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Khu Trọ Xanh - Bình Thạ...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('12 phòng', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          )
        ],
      ),
    );
  }

  //khung tiến độ ghi số
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text('Tiến độ ghi số', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(width: 4),
                  CircleAvatar(radius: 3, backgroundColor: Colors.brown),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.door_back_door_outlined, size: 12, color: Colors.brown),
                    SizedBox(width: 4),
                    Text('Còn 4 phòng', style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Đã hoàn thành 8 trên 12 phòng', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Text('Tỷ lệ hoàn tất', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Spacer(),
              Text('67%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.67,
              backgroundColor: AppColors.primaryGreen,
              color: AppColors.warningOrange,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  //banner AI OCR
  Widget _buildOcrBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFDCEDC8), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.crop_free, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Quét AI OCR Hàng Loạt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.warningOrange.withOpacity(0.3), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Mới', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Text('Chụp liên tục đồng hồ, tự khớp số phòng', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  //thanh chuyển tabs lọc
  Widget _buildFilterTabs() {
    final filters = [
      {'title': 'Tất cả', 'count': '12'},
      {'title': 'Chưa ghi', 'count': '4'},
      {'title': 'Đã ghi', 'count': '8'},
      {'title': 'Bất thường', 'count': ''},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          bool isSelected = _selectedFilterIndex == index;
          bool isAlert = index == 3;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              showCheckmark: false,
              label: Row(
                children: [
                  if (isAlert) const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.redAccent),
                  if (isAlert) const SizedBox(width: 4),
                  Text(
                    filters[index]['title']!,
                    style: TextStyle(
                      color: isAlert ? Colors.red : (isSelected ? Colors.white : AppColors.textPrimary),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (filters[index]['count']!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        filters[index]['count']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selectedColor: isAlert ? Colors.redAccent : AppColors.primaryGreen,
              backgroundColor: isAlert ? Colors.redAccent : Colors.white,
              onSelected: (val) {
                setState(() => _selectedFilterIndex = index);
              },
            ),
          );
        }),
      ),
    );
  }

  //mẹo ghi nhanh
  Widget _buildTipBox() {
    return Column(
      children: const [
        Icon(Icons.lightbulb_outline, color: AppColors.primaryGreen, size: 28),
        SizedBox(height: 4),
        Text('Mẹo ghi nhanh chỉ số', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        SizedBox(height: 4),
        Text(
          'Bạn có thể bật đèn Flash điện thoại khi mở camera OCR để\nmáy tự nhận diện chính xác kể cả trong hốc tối.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  //khung footer cố định bên dưới
  Widget _buildBottomFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Tổng dự kiến (8 phòng đã ghi)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('6.850.000 đ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.water_drop_outlined, size: 12, color: AppColors.primaryGreen),
                    SizedBox(width: 4),
                    Text('Giá bậc thang', style: TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Lưu nháp', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_long, size: 18, color: Colors.black87),
                  label: const Text('Chốt số & Tạo hóa đơn', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warningOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}