import 'package:flutter/material.dart';

import 'chat/chat_screen.dart';
import 'history/history_screen.dart';
import 'home/worker_home_screen.dart';
import 'mypage/mypage_screen.dart';
import 'notification/notification_screen.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int _idx = 0;

  static const _pages = [
    WorkerHomeScreen(),
    HistoryScreen(),
    ChatScreen(),
    NotificationScreen(),
    MyPageScreen(appType: 'worker'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '지원내역'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none), label: '알림'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: '마이페이지'),
        ],
      ),
    );
  }
}
