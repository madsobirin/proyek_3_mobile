// import 'package:flutter/material.dart';
// import '../pages/dashboard/home_page.dart';
// // import 'bmi_page.dart';
// // import 'menu_page.dart';
// // import 'artikel_page.dart';
// // import 'profile_page.dart';

// class MainNavigation extends StatefulWidget {
//   const MainNavigation({super.key});

//   @override
//   State<MainNavigation> createState() => _MainNavigationState();
// }

// class _MainNavigationState extends State<MainNavigation> {
//   int _selectedIndex = 0;

//   final List<Widget> _pages = const [
//     HomePage(),
//     // BmiPage(),
//     // MenuPage(),
//     // ArtikelPage(),
//     // ProfilePage(),
//   ];

//   void _onTap(int index) {
//     setState(() => _selectedIndex = index);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7FAF7),

//       body: IndexedStack(
//         index: _selectedIndex,
//         children: _pages,
//       ),

//       // ================= MODERN FLOATING NAV =================
//       bottomNavigationBar: SafeArea(
//         child: Container(
//           margin: const EdgeInsets.all(16),
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(30),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.08),
//                 blurRadius: 20,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: List.generate(5, (index) {
//               final isActive = _selectedIndex == index;

//               final icons = [
//                 Icons.home,
//                 Icons.calculate,
//                 Icons.restaurant_menu,
//                 Icons.article,
//                 Icons.person,
//               ];

//               final labels = [
//                 "Home",
//                 "BMI",
//                 "Menu",
//                 "Artikel",
//                 "Profil",
//               ];

//               return GestureDetector(
//                 onTap: () => _onTap(index),
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 250),
//                   curve: Curves.easeInOut,
//                   padding: EdgeInsets.symmetric(
//                     horizontal: isActive ? 16 : 8,
//                     vertical: 8,
//                   ),
//                   decoration: BoxDecoration(
//                     color: isActive
//                         ? const Color(0xFF1AB673).withOpacity(0.15)
//                         : null,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         icons[index],
//                         size: isActive ? 26 : 22,
//                         color: isActive
//                             ? const Color(0xFF1AB673)
//                             : Colors.grey,
//                       ),
//                       if (isActive) ...[
//                         const SizedBox(width: 6),
//                         Text(
//                           labels[index],
//                           style: const TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF1AB673),
//                           ),
//                         ),
//                       ]
//                     ],
//                   ),
//                 ),
//               );
//             }),
//           ),
//         ),
//       ),
//     );
//   }
// }