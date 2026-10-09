import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    //dữ liệu mẫu
    final List<_ChartData> chartData = [
      _ChartData('T2', 120, 80),
      _ChartData('T3', 190, 130),
      _ChartData('T4', 150, 110),
      _ChartData('T5', 240, 180),
      _ChartData('T6', 200, 160),
      _ChartData('T7', 310, 250),
      _ChartData('CN', 280, 210),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Admin",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
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
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                const Text('Tháng này', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                ),
                              ],
                            )
                          ],
                        ),

                        const SizedBox(height: 10),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                          children: const [
                            StarCard(
                              title: 'Tổng người dùng',
                              value: '1.256',
                              icon: Icons.person_outline,
                              iconColor: Colors.green,
                            ),
                            StarCard(
                              title: 'Phòng đăng',
                              value: '2.345',
                              icon: Icons.home_outlined,
                              iconColor: Colors.amber,
                            ),
                            StarCard(
                              title: 'Hợp đồng duyệt',
                              value: '1.890',
                              icon: Icons.description_outlined,
                              iconColor: Colors.blue,
                            ),
                            StarCard(
                              title: 'Báo cáo',
                              value: '456',
                              icon: Icons.assignment_outlined,
                              iconColor: Colors.deepOrange,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            "Thống kê",
                            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // biểu đồ
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Lượt tương tác theo tuần",
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 200, // chiều cao phù hợp cho Dashboard
                                child: SfCartesianChart(
                                  margin: EdgeInsets.zero,
                                  plotAreaBorderWidth: 0,
                                  legend: const Legend(
                                    isVisible: true,
                                    position: LegendPosition.top,
                                    overflowMode: LegendItemOverflowMode.wrap,
                                  ),
                                  primaryXAxis: const CategoryAxis(
                                    majorGridLines: MajorGridLines(width: 0),
                                  ),
                                  primaryYAxis: const NumericAxis(
                                    axisLine: AxisLine(width: 0),
                                    majorTickLines: MajorTickLines(color: Colors.transparent),
                                  ),
                                  series: <CartesianSeries<_ChartData, String>>[
                                    //đường 1: lượt truy cập
                                    LineSeries<_ChartData, String>(
                                      name: 'Lượt truy cập',
                                      dataSource: chartData,
                                      xValueMapper: (_ChartData data, _) => data.day,
                                      yValueMapper: (_ChartData data, _) => data.views,
                                      color: AppColors.primaryGreen,
                                      width: 3,
                                      markerSettings: const MarkerSettings(isVisible: true),
                                    ),

                                    //đường 2:lượt tìm phòng
                                    LineSeries<_ChartData, String>(
                                      name: 'Lượt tìm phòng',
                                      dataSource: chartData,
                                      xValueMapper: (_ChartData data, _) => data.day,
                                      yValueMapper: (_ChartData data, _) => data.searches,
                                      color: Colors.amber,
                                      width: 3,
                                      markerSettings: const MarkerSettings(isVisible: true),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: (index) {
            switch(index){
              case 0:
                Navigator.pushNamed(context, AppRoutes.adminDashboard);
                break;
              case 1:
                Navigator.pushNamed(context, AppRoutes.rewview);
                break;
              case 3:
                Navigator.pushNamed(context, AppRoutes.usersManage);
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.article_outlined), label: 'Quản lý'),
            BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Thống kê'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Tài khoản'),
          ],
        ),
      ),
    );
  }
}

//dữ liệu biểu đồ
class _ChartData {
  _ChartData(this.day, this.views, this.searches);
  final String day;
  final double views;
  final double searches;
}

// Sub-widget Thẻ Thống kê
class StarCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const StarCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}