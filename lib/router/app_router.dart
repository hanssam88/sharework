import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/phone_auth_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/common/job_info_screen.dart';
import '../screens/common/payment_history_screen.dart';
import '../screens/common/profile_screen.dart';
import '../screens/common/review_write_screen.dart';
import '../screens/common/search_screen.dart';
import '../screens/common/user_info_update_screen.dart';
import '../screens/giver/applicants/applicants_screen.dart';
import '../screens/giver/giver_main_screen.dart';
import '../screens/giver/job_create/job_create_screen.dart';
import '../screens/giver/job_edit/job_edit_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/worker/worker_main_screen.dart';

class AppRouter {
  static final GoRouter config = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (_, __) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/worker',
        builder: (_, __) => const WorkerMainScreen(),
      ),
      GoRoute(
        path: '/giver',
        builder: (_, __) => const GiverMainScreen(),
      ),
      GoRoute(
        path: '/giver/job/create',
        builder: (_, __) => const JobCreateScreen(),
      ),
      GoRoute(
        path: '/giver/job/:id/edit',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return JobEditScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/giver/job/:id/applicants',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ApplicantsScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/job/:id',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return JobInfoScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/job/:id/review/write',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ReviewWriteScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ProfileScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/me/edit',
        builder: (_, __) => const UserInfoUpdateScreen(),
      ),
      GoRoute(
        path: '/me/payments',
        builder: (_, __) => const PaymentHistoryScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('오류')),
      body: Center(child: Text('경로를 찾을 수 없어요\n${state.uri}')),
    ),
  );
}
