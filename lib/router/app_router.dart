import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/identity_screen.dart';
import '../screens/auth/phone_auth_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/categories/category_jobs_screen.dart';
import '../screens/events/events_screen.dart';
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
import '../screens/giver/job_boost/job_boost_screen.dart';
import '../screens/giver/escrow_topup_screen.dart';
import '../models/api_models/job.dart';
import '../models/api_models/job_photo.dart';
import '../screens/giver/job_create/job_create_screen.dart';
import '../screens/giver/job_create/job_preview_screen.dart';
import '../screens/giver/job_edit/job_edit_screen.dart';
import '../screens/giver/job_stats/job_stats_screen.dart';
import '../screens/giver/job_templates/job_templates_screen.dart';
import '../screens/giver/payment_methods_screen.dart';
import '../screens/giver/regulars_screen.dart';
import '../screens/giver/workers/worker_detail_screen.dart';
import '../screens/giver/workers/workers_search_screen.dart';
import '../screens/job/checkin_screen.dart';
import '../screens/job/contract_screen.dart';
import '../screens/job/contract_sign_screen.dart';
import '../screens/legal/legal_screen.dart';
import '../screens/me/activity_report_screen.dart';
import '../screens/me/availability_screen.dart';
import '../screens/me/bank_account_screen.dart';
import '../screens/me/blocklist_screen.dart';
import '../screens/me/coupons_screen.dart';
import '../screens/me/credentials_list_screen.dart';
import '../screens/me/credentials_new_screen.dart';
import '../screens/me/favorite_companies_screen.dart';
import '../screens/me/identity_status_screen.dart';
import '../screens/me/invite_screen.dart';
import '../screens/me/level_screen.dart';
import '../screens/me/notification_settings_screen.dart';
import '../screens/me/payment_detail_screen.dart';
import '../screens/me/portfolio_screen.dart';
import '../screens/me/preferences_screen.dart';
import '../screens/me/resume_screen.dart';
import '../screens/me/safety_screen.dart';
import '../screens/me/saved_search_new_screen.dart';
import '../screens/me/saved_searches_screen.dart';
import '../screens/me/security_screen.dart';
import '../screens/me/tax_docs_screen.dart';
import '../screens/me/withdraw_screen.dart';
import '../screens/worker/recommended_screen.dart';
import '../screens/worker/scouts/scout_detail_screen.dart';
import '../screens/worker/scouts/scouts_screen.dart';
import '../screens/notice/notice_detail_screen.dart';
import '../screens/notice/notice_list_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/permissions_screen.dart';
import '../screens/permissions/location_priming_screen.dart';
import '../screens/permissions/notification_priming_screen.dart';
import '../screens/permissions/permission_center_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/support/dispute_detail_screen.dart';
import '../screens/support/dispute_list_screen.dart';
import '../screens/support/dispute_new_screen.dart';
import '../screens/support/faq_screen.dart';
import '../screens/support/inquiry_list_screen.dart';
import '../screens/support/inquiry_new_screen.dart';
import '../screens/support/support_hub_screen.dart';
import '../screens/worker/worker_main_screen.dart';

class AppRouter {
  static final GoRouter config = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      Session? session;
      try {
        session = Supabase.instance.client.auth.currentSession;
      } catch (_) {
        // Supabase 미초기화 (test 환경 등) — guard 비활성
        return null;
      }
      final loc = state.matchedLocation;
      final isProtected = loc.startsWith('/worker') ||
          loc.startsWith('/giver') ||
          loc.startsWith('/me');
      if (session == null && isProtected) {
        return '/auth/phone';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/permissions',
        builder: (_, __) => const PermissionsScreen(),
      ),
      GoRoute(
        path: '/onboarding/permissions/location',
        builder: (_, __) => const LocationPrimingScreen(),
      ),
      GoRoute(
        path: '/onboarding/permissions/notification',
        builder: (_, __) => const NotificationPrimingScreen(),
      ),
      GoRoute(
        path: '/me/permissions',
        builder: (_, __) => const PermissionCenterScreen(),
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
        path: '/giver/job/templates',
        builder: (_, __) => const JobTemplatesScreen(),
      ),
      GoRoute(
        path: '/giver/job/preview',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, Object?>?;
          final job = extra?['job'] as Job?;
          final photos = (extra?['photos'] as List?)?.cast<JobPhoto>() ??
              const <JobPhoto>[];
          if (job == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('오류')),
              body: const Center(child: Text('미리보기 데이터가 없어요')),
            );
          }
          return JobPreviewScreen(job: job, photos: photos);
        },
      ),
      GoRoute(
        path: '/giver/job/:id/stats',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return JobStatsScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/giver/job/:id/boost',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return JobBoostScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/giver/job/:id/edit',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
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
        path: '/categories',
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/categories/:id',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          final name = (state.extra as String?) ?? '카테고리';
          return CategoryJobsScreen(categoryId: id, categoryName: name);
        },
      ),
      GoRoute(
        path: '/job/:id',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
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
        path: '/giver/escrow/topup',
        builder: (_, __) => const EscrowTopupScreen(),
      ),
      GoRoute(
        path: '/me/blocklist',
        builder: (_, __) => const BlocklistScreen(),
      ),
      GoRoute(
        path: '/me/bank-account',
        builder: (_, __) => const BankAccountScreen(),
      ),
      GoRoute(
        path: '/me/withdraw',
        builder: (_, __) => const WithdrawScreen(),
      ),
      GoRoute(
        path: '/me/saved-searches',
        builder: (_, __) => const SavedSearchesScreen(),
      ),
      GoRoute(
        path: '/me/saved-searches/new',
        builder: (_, __) => const SavedSearchNewScreen(),
      ),
      GoRoute(
        path: '/me/report',
        builder: (_, __) => const ActivityReportScreen(),
      ),
      GoRoute(
        path: '/me/payments/tax-docs',
        builder: (_, __) => const TaxDocsScreen(),
      ),
      GoRoute(
        path: '/me/safety',
        builder: (_, __) => const SafetyScreen(),
      ),
      GoRoute(
        path: '/me/security',
        builder: (_, __) => const SecurityScreen(),
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
        path: '/me/resume',
        builder: (_, __) => const ResumeScreen(),
      ),
      GoRoute(
        path: '/me/portfolio',
        builder: (_, __) => const PortfolioScreen(),
      ),
      GoRoute(
        path: '/me/availability',
        builder: (_, __) => const AvailabilityScreen(),
      ),
      GoRoute(
        path: '/me/preferences',
        builder: (_, __) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/me/favorite-companies',
        builder: (_, __) => const FavoriteCompaniesScreen(),
      ),
      GoRoute(
        path: '/me/invite',
        builder: (_, __) => const InviteScreen(),
      ),
      GoRoute(
        path: '/me/coupons',
        builder: (_, __) => const CouponsScreen(),
      ),
      GoRoute(
        path: '/me/level',
        builder: (_, __) => const LevelScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (_, __) => const EventsScreen(),
      ),
      GoRoute(
        path: '/recommended',
        builder: (_, __) => const RecommendedScreen(),
      ),
      GoRoute(
        path: '/worker/scouts',
        builder: (_, __) => const ScoutsScreen(),
      ),
      GoRoute(
        path: '/worker/scouts/:id',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ScoutDetailScreen(scoutId: id);
        },
      ),
      GoRoute(
        path: '/giver/workers',
        builder: (_, __) => const WorkersSearchScreen(),
      ),
      GoRoute(
        path: '/giver/workers/:id',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return WorkerDetailScreen(workerId: id);
        },
      ),
      GoRoute(
        path: '/giver/regulars',
        builder: (_, __) => const RegularsScreen(),
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
        path: '/support/dispute',
        builder: (_, __) => const DisputeListScreen(),
      ),
      GoRoute(
        path: '/support/dispute/new',
        builder: (_, __) => const DisputeNewScreen(),
      ),
      GoRoute(
        path: '/support/dispute/:id',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return DisputeDetailScreen(disputeId: id);
        },
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
