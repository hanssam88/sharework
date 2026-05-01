import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/identity_screen.dart';
import '../screens/auth/phone_auth_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/common/job_info_screen.dart';
import '../screens/common/payment_history_screen.dart';
import '../screens/common/profile_screen.dart';
import '../screens/common/report_screen.dart';
import '../screens/common/review_write_screen.dart';
import '../screens/common/search_screen.dart';
import '../screens/common/user_info_update_screen.dart';
import '../screens/giver/applicants/applicants_screen.dart';
import '../screens/giver/business_verification_screen.dart';
import '../screens/giver/escrow_screen.dart';
import '../screens/giver/giver_main_screen.dart';
import '../screens/giver/job_create/job_create_screen.dart';
import '../screens/giver/job_edit/job_edit_screen.dart';
import '../screens/giver/payment_methods_screen.dart';
import '../screens/job/checkin_screen.dart';
import '../screens/job/contract_screen.dart';
import '../screens/job/contract_sign_screen.dart';
import '../screens/legal/legal_screen.dart';
import '../screens/me/blocklist_screen.dart';
import '../screens/me/credentials_list_screen.dart';
import '../screens/me/credentials_new_screen.dart';
import '../screens/me/identity_status_screen.dart';
import '../screens/me/notification_settings_screen.dart';
import '../screens/me/payment_detail_screen.dart';
import '../screens/notice/notice_detail_screen.dart';
import '../screens/notice/notice_list_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/support/faq_screen.dart';
import '../screens/support/inquiry_list_screen.dart';
import '../screens/support/inquiry_new_screen.dart';
import '../screens/support/support_hub_screen.dart';
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
        path: '/auth/identity',
        builder: (_, __) => const IdentityVerificationScreen(),
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
        path: '/job/:id/checkin',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return CheckinScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/job/:id/contract',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ContractScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/job/:id/contract/sign',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ContractSignScreen(jobId: id);
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
      GoRoute(
        path: '/me/payments/:id',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return PaymentDetailScreen(paymentId: id);
        },
      ),
      GoRoute(
        path: '/giver/payment-methods',
        builder: (_, __) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/giver/escrow',
        builder: (_, __) => const EscrowScreen(),
      ),
      GoRoute(
        path: '/me/blocklist',
        builder: (_, __) => const BlocklistScreen(),
      ),
      GoRoute(
        path: '/me/identity',
        builder: (_, __) => const IdentityStatusScreen(),
      ),
      GoRoute(
        path: '/me/credentials',
        builder: (_, __) => const CredentialsListScreen(),
      ),
      GoRoute(
        path: '/me/credentials/new',
        builder: (_, __) => const CredentialsNewScreen(),
      ),
      GoRoute(
        path: '/giver/business-verification',
        builder: (_, __) => const BusinessVerificationScreen(),
      ),
      GoRoute(
        path: '/me/notification-settings',
        builder: (_, __) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/report/:targetType/:targetId',
        builder: (ctx, state) {
          final type = state.pathParameters['targetType'] ?? 'user';
          final id = int.tryParse(state.pathParameters['targetId'] ?? '') ?? 0;
          return ReportScreen(targetType: type, targetId: id);
        },
      ),
      GoRoute(
        path: '/support',
        builder: (_, __) => const SupportHubScreen(),
      ),
      GoRoute(
        path: '/support/faq',
        builder: (_, __) => const FaqScreen(),
      ),
      GoRoute(
        path: '/support/inquiry',
        builder: (_, __) => const InquiryListScreen(),
      ),
      GoRoute(
        path: '/support/inquiry/new',
        builder: (_, __) => const InquiryNewScreen(),
      ),
      GoRoute(
        path: '/notice',
        builder: (_, __) => const NoticeListScreen(),
      ),
      GoRoute(
        path: '/notice/:id',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return NoticeDetailScreen(noticeId: id);
        },
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const LegalScreen(docType: 'terms'),
      ),
      GoRoute(
        path: '/privacy',
        builder: (_, __) => const LegalScreen(docType: 'privacy'),
      ),
      GoRoute(
        path: '/guide',
        builder: (_, __) => const LegalScreen(docType: 'guide'),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('오류')),
      body: Center(child: Text('경로를 찾을 수 없어요\n${state.uri}')),
    ),
  );
}
