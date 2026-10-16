import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../route/app_routes.dart';

// 1. Đổi sang StatefulWidget
class User extends StatefulWidget {
  const User({super.key});

  @override
  State<User> createState() => _UserState();
}

class _UserState extends State<User> {
  String _selectedRole = "Tất cả";

  // dữ liệu ảo
  final List<Map<String, dynamic>> _allUsers = [
    {
      'name': 'Nguyễn Văn A',
      'email': 'nguyenvana@gmail.com',
      'role': 'Người thuê',
      'status': 'Kích hoạt',
      'avatar': 'https://i.pravatar.cc/150?img=11',
    },
    {
      'name': 'Trần Thị B',
      'email': 'tranthib@gmail.com',
      'role': 'Chủ trọ',
      'status': 'Kích hoạt',
      'avatar': 'https://i.pravatar.cc/150?img=5',
    },
    {
      'name': 'Lê Văn C',
      'email': 'levanc@gmail.com',
      'role': 'Người thuê',
      'status': 'Đã khóa',
      'avatar': 'https://i.pravatar.cc/150?img=3',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filterUser = _allUsers.where((u){
      if(_selectedRole == "Tất cả") return true;
      return u["role"] == _selectedRole;
    }).toList();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
       home: Scaffold(
         backgroundColor: AppColors.primaryGreen,
         appBar: AppBar(
           backgroundColor: AppColors.primaryGreen,
           elevation: 0,
           leading: IconButton(
             onPressed: () {
               Navigator.maybePop(context);
             },
             icon: const Icon(Icons.arrow_back, size: 26, color: Colors.white),
           ),

           centerTitle: true,

           title:const Text(
             "Quản lý tài khoản",
             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
           ),

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
         body: SafeArea(
           bottom: false,
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const SizedBox(height: 8),
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

                   child: Column(
                     children: [
                       Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                         child:  Row(
                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                           children: ["Tất cả", "Người thuê", "Chủ trọ"].map((role) {
                             final isSelected = _selectedRole == role;
                             return ChoiceChip(
                               label: Text(role),
                               selected: isSelected,
                               selectedColor: AppColors.primaryGreen,
                               backgroundColor: AppColors.background,
                               showCheckmark: false,
                               side: BorderSide.none,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               labelStyle: TextStyle(
                                 color: isSelected ? Colors.white : Colors.black,
                                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                 fontSize: 16
                               ),
                               onSelected: (selected){
                                 if(selected){
                                   setState(() {
                                     _selectedRole = role;
                                   });
                                 }
                               },
                             );
                           }).toList(),
                         ),
                       ),

                       Expanded(child: Padding(
                         padding: const EdgeInsets.all(14),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [


                             const SizedBox(height: 10,),

                             // Ô tìm kiếm
                             TextField(
                               decoration: InputDecoration(
                                 hintText: "Tìm kiếm (Tên, Email, SĐT)",
                                 hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                                 prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                 filled: true,
                                 fillColor: AppColors.lightGreen,
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(24),
                                   borderSide: BorderSide.none,
                                 ),
                                 contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                               ),
                             ),
                             const SizedBox(height: 14),
                             
                             Expanded(child: DsanhTK(users: filterUser))



                           ],
                         ),
                       ),)
                     ],
                   )
                 ),
               ),
             ],
           ),
         ),

         bottomNavigationBar: BottomNavigationBar(
           currentIndex: 3,
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


class DsanhTK extends StatelessWidget
{
  final List<Map<String,dynamic>> users;
  const DsanhTK({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    if(users.isEmpty){
      return const Center(
        child: Text("Không có thành tài khoản nào"),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder:(context,index){
        final user = users[index];
        final bool isActive = user['status'] == "Kích hoạt";

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ]
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

            leading: CircleAvatar(
              backgroundImage: NetworkImage(user['avatar']),
              radius: 24,
              backgroundColor: AppColors.lightGreen,
            ),

            title: Text(user["name"],style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  user['email'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  user['role'],
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),

            // phía bên phải
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                // 1. Dùng màu nền nhạt
                color: isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                user["status"],
                style: TextStyle(
                  // 2. Chữ dùng màu đậm tương ứng
                  color: isActive ? AppColors.primaryGreen : Colors.red[800],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: (){
              // xử lí vào sự kiện item bấm xem chi tiết
            },


          ),
        );

      },
    );
  }
}

