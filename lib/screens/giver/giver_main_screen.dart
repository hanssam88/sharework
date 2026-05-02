import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../worker/chat/chat_screen.dart';
import '../worker/mypage/mypage_screen.dart';
import '../worker/notification/notification_screen.dart';
import 'home/giver_home_screen.dart';

class GiverMainScreen extends StatefulWidget {
  const GiverMainScreen({super.key});

  @override
  State<GiverMainScreen> createState() => _GiverMainScreenState();
}

class _GiverMainScreenState extends State<GiverMainScreen> {
  int _idx = 0;

  static const _pages = [
    GiverHomeScreen(),
    ChatScreen(),
    SizedBox.shrink(), // job create slot — opened as full-screen route
    NotificationScreen(),
    MyPageScreen(appType: 'giver'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) {
          if (i == 2) {
            context.push('/giver/job/create');
          } else {
            setState(() => _idx = i);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined), label: '일감등록'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none), label: '알림'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: '마이페이지'),
        ],
      ),
    );
  }
}
