import 'package:flutter/material.dart';

enum AppType { worker, giver }

enum ApplicationStatus { applied, hired, completed, rejected, cancelled }

enum JobStatus { open, ongoing, done, closed }

enum NotificationKind { application, hire, complete, review, system }

enum JobCategory {
  cafe,
  restaurant,
  mart,
  logistics,
  delivery,
  event,
  cleaning,
  office,
  etc,
}

enum WorkType { oneDay, shortTerm, recurring, longTerm }

enum ContractStatus { none, sent, signed }

enum PaymentMethodKind { card, bank }

enum EscrowKind { deposit, payout, refund }

enum CredentialKind {
  idCard, // 신분증
  driverLicense, // 운전면허
  hygieneEdu, // 위생교육
  health, // 건강진단서
  barista,
  cookCert, // 조리사 자격증
  forkLift,
  etc,
}

enum CredentialStatus { pending, verified, expired, rejected }

class CareerEntry {
  final String company;
  final String role;
  final String period; // ex) 2023.03 ~ 2023.09
  final String description;

  const CareerEntry({
    required this.company,
    required this.role,
    required this.period,
    required this.description,
  });
}

class EducationEntry {
  final String school;
  final String degree;
  final String period;

  const EducationEntry({
    required this.school,
    required this.degree,
    required this.period,
  });
}

class Resume {
  final String headline; // 한 줄 소개
  final String summary; // 자기소개
  final List<CareerEntry> careers;
  final List<EducationEntry> educations;
  final List<String> skills;

  const Resume({
    this.headline = '',
    this.summary = '',
    this.careers = const [],
    this.educations = const [],
    this.skills = const [],
  });
}

enum PortfolioKind { image, link }

class PortfolioItem {
  final int id;
  final PortfolioKind kind;
  final String title;
  final String? subtitle;
  final String? url; // link인 경우
  final String? colorTag; // image placeholder 색

  const PortfolioItem({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.url,
    this.colorTag,
  });
}

class AvailabilitySlot {
  final int weekday; // 1=월 ~ 7=일
  final int startHour; // 0~24
  final int endHour;

  const AvailabilitySlot({
    required this.weekday,
    required this.startHour,
    required this.endHour,
  });
}

enum ScoutStatus { sent, accepted, declined, expired }

class Scout {
  final int id;
  final int fromGiverId;
  final String fromGiverName;
  final int toWorkerId;
  final String toWorkerName;
  final int? jobId;
  final String? jobTitle;
  final String message;
  final ScoutStatus status;
  final DateTime createdAt;
  final int? offerHourly;

  const Scout({
    required this.id,
    required this.fromGiverId,
    required this.fromGiverName,
    required this.toWorkerId,
    required this.toWorkerName,
    this.jobId,
    this.jobTitle,
    required this.message,
    required this.status,
    required this.createdAt,
    this.offerHourly,
  });
}

class FavoriteCompany {
  final int giverId;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final List<String> badges;
  final int recentJobsCount;
  final DateTime addedAt;

  const FavoriteCompany({
    required this.giverId,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    this.badges = const [],
    required this.recentJobsCount,
    required this.addedAt,
  });
}

class RegularWorker {
  final int workerId;
  final String name;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final int hireCount; // 함께 일한 횟수
  final DateTime lastWorkedAt;

  const RegularWorker({
    required this.workerId,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.hireCount,
    required this.lastWorkedAt,
  });
}

class JobTemplate {
  final int id;
  final String name; // 템플릿 별명
  final String title;
  final String address;
  final JobCategory category;
  final WorkType workType;
  final int payHourly;
  final int defaultPersonnel;
  final List<String> tags;
  final bool sameDayPayment;
  final bool foodProvided;
  final bool extraPay;
  final List<int> recurrenceWeekdays;
  final int useCount; // 사용 횟수

  const JobTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.address,
    required this.category,
    required this.workType,
    required this.payHourly,
    required this.defaultPersonnel,
    this.tags = const [],
    this.sameDayPayment = false,
    this.foodProvided = false,
    this.extraPay = false,
    this.recurrenceWeekdays = const [],
    this.useCount = 0,
  });
}

class JobStats {
  final int impressions; // 노출 수
  final int clicks; // 상세 진입 수
  final int applications; // 지원 수
  final int hires; // 채용 확정
  final int avgPay; // 동일 카테고리 평균 시급
  final List<int> last7DaysImpressions; // 최근 7일 노출 추이

  const JobStats({
    required this.impressions,
    required this.clicks,
    required this.applications,
    required this.hires,
    required this.avgPay,
    required this.last7DaysImpressions,
  });

  double get hireRate =>
      applications == 0 ? 0 : hires / applications;
  double get clickRate =>
      impressions == 0 ? 0 : clicks / impressions;
  double get applyRate =>
      clicks == 0 ? 0 : applications / clicks;
}

enum BoostKind { topPin, brandColor, push, premium }

enum CouponStatus { available, used, expired }

class Coupon {
  final int id;
  final String name;
  final String desc;
  final int discountPercent; // 0이면 정액
  final int discountAmount;
  final int minOrder;
  final DateTime expiresAt;
  final CouponStatus status;

  const Coupon({
    required this.id,
    required this.name,
    required this.desc,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.minOrder = 0,
    required this.expiresAt,
    this.status = CouponStatus.available,
  });
}

enum MissionStatus { ongoing, completed, claimed }

class Mission {
  final int id;
  final String title;
  final String desc;
  final int progress;
  final int goal;
  final int rewardPoint;
  final MissionStatus status;
  final IconData icon;

  const Mission({
    required this.id,
    required this.title,
    required this.desc,
    required this.progress,
    required this.goal,
    required this.rewardPoint,
    required this.icon,
    this.status = MissionStatus.ongoing,
  });

  double get rate => goal == 0 ? 0 : (progress / goal).clamp(0.0, 1.0);
}

class LevelInfo {
  final String name; // ex) Bronze / Silver / Gold / Platinum
  final int currentPoint;
  final int nextLevelPoint;
  final List<String> benefits;
  final IconData icon;
  final Color color;

  const LevelInfo({
    required this.name,
    required this.currentPoint,
    required this.nextLevelPoint,
    required this.benefits,
    required this.icon,
    required this.color,
  });

  double get progress =>
      nextLevelPoint == 0 ? 1 : (currentPoint / nextLevelPoint).clamp(0.0, 1.0);
}

class EventBanner {
  final int id;
  final String title;
  final String subtitle;
  final String? cta;
  final DateTime endAt;
  final String colorTag;

  const EventBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    this.cta,
    required this.endAt,
    this.colorTag = '#E6F8F6',
  });
}

enum ChatMessageKind {
  text,
  image,
  location,
  jobCard,
  contract,
  paymentCard,
  system,
}

class ChatMessage {
  final int id;
  final ChatMessageKind kind;
  final String body;
  final String? attachment; // image url / job id / contract id 등
  final bool mine;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.kind,
    required this.body,
    this.attachment,
    required this.mine,
    required this.createdAt,
  });
}

class BoostProduct {
  final BoostKind kind;
  final String name;
  final String desc;
  final int price;
  final Duration duration;

  const BoostProduct({
    required this.kind,
    required this.name,
    required this.desc,
    required this.price,
    required this.duration,
  });
}

class WorkerPreferences {
  final int preferredHourly;
  final int preferredRadiusKm;
  final List<JobCategory> preferredCategories;
  final List<WorkType> preferredWorkTypes;
  final bool allowSameDay; // 당일 지원 알림
  final bool allowNight; // 야간 근무 가능

  const WorkerPreferences({
    this.preferredHourly = 12000,
    this.preferredRadiusKm = 5,
    this.preferredCategories = const [],
    this.preferredWorkTypes = const [],
    this.allowSameDay = true,
    this.allowNight = false,
  });

  WorkerPreferences copyWith({
    int? preferredHourly,
    int? preferredRadiusKm,
    List<JobCategory>? preferredCategories,
    List<WorkType>? preferredWorkTypes,
    bool? allowSameDay,
    bool? allowNight,
  }) =>
      WorkerPreferences(
        preferredHourly: preferredHourly ?? this.preferredHourly,
        preferredRadiusKm: preferredRadiusKm ?? this.preferredRadiusKm,
        preferredCategories: preferredCategories ?? this.preferredCategories,
        preferredWorkTypes: preferredWorkTypes ?? this.preferredWorkTypes,
        allowSameDay: allowSameDay ?? this.allowSameDay,
        allowNight: allowNight ?? this.allowNight,
      );
}

extension CredentialKindX on CredentialKind {
  String get label {
    switch (this) {
      case CredentialKind.idCard:
        return '신분증';
      case CredentialKind.driverLicense:
        return '운전면허';
      case CredentialKind.hygieneEdu:
        return '위생교육 수료증';
      case CredentialKind.health:
        return '건강진단서';
      case CredentialKind.barista:
        return '바리스타 자격증';
      case CredentialKind.cookCert:
        return '조리사 자격증';
      case CredentialKind.forkLift:
        return '지게차 운전면허';
      case CredentialKind.etc:
        return '기타';
    }
  }

  IconData get icon {
    switch (this) {
      case CredentialKind.idCard:
        return Icons.badge_outlined;
      case CredentialKind.driverLicense:
        return Icons.directions_car_outlined;
      case CredentialKind.hygieneEdu:
        return Icons.school_outlined;
      case CredentialKind.health:
        return Icons.local_hospital_outlined;
      case CredentialKind.barista:
        return Icons.coffee_outlined;
      case CredentialKind.cookCert:
        return Icons.restaurant_menu_outlined;
      case CredentialKind.forkLift:
        return Icons.precision_manufacturing_outlined;
      case CredentialKind.etc:
        return Icons.description_outlined;
    }
  }
}

extension JobCategoryX on JobCategory {
  String get label {
    switch (this) {
      case JobCategory.cafe:
        return '카페';
      case JobCategory.restaurant:
        return '음식점';
      case JobCategory.mart:
        return '마트/매장';
      case JobCategory.logistics:
        return '물류/창고';
      case JobCategory.delivery:
        return '배달/운반';
      case JobCategory.event:
        return '행사/스태프';
      case JobCategory.cleaning:
        return '청소';
      case JobCategory.office:
        return '사무보조';
      case JobCategory.etc:
        return '기타';
    }
  }
}

extension WorkTypeX on WorkType {
  String get label {
    switch (this) {
      case WorkType.oneDay:
        return '하루';
      case WorkType.shortTerm:
        return '단기';
      case WorkType.recurring:
        return '정기';
      case WorkType.longTerm:
        return '장기';
    }
  }
}

class AppUser {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String? profileUrl;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final String introduction;
  final AppType appType;
  final bool identityVerified;
  final String? businessNumber; // Giver만
  final bool businessVerified;
  final List<String> verificationBadges; // 본인인증/사업자/위생교육 등 표시용

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.profileUrl,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.introduction,
    required this.appType,
    this.identityVerified = false,
    this.businessNumber,
    this.businessVerified = false,
    this.verificationBadges = const [],
  });
}

class Credential {
  final int id;
  final CredentialKind kind;
  final String? fileUrl; // 목업: 미사용
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final CredentialStatus status;
  final String? memo;

  const Credential({
    required this.id,
    required this.kind,
    this.fileUrl,
    required this.issuedAt,
    this.expiresAt,
    this.status = CredentialStatus.pending,
    this.memo,
  });
}

class Job {
  final int id;
  final int giverId;
  final String giverName;
  final String title;
  final String address;
  final double lat;
  final double lng;
  final DateTime startAt;
  final DateTime endAt;
  final int personnel;
  final int hiredCount;
  final List<String> tags;
  final String payType;
  final int pay;
  final bool sameDayPayment;
  final bool foodProvided;
  final bool extraPay;
  final String description;
  final List<String> checklists;
  final JobStatus status;
  final JobCategory category;
  final WorkType workType;
  final ContractStatus contractStatus;
  final DateTime? checkinAt;
  final DateTime? checkoutAt;
  final List<int> recurrenceWeekdays; // 1=월 ~ 7=일, 비어있으면 1회성
  final DateTime? boostUntil;

  const Job({
    required this.id,
    required this.giverId,
    required this.giverName,
    required this.title,
    required this.address,
    required this.lat,
    required this.lng,
    required this.startAt,
    required this.endAt,
    required this.personnel,
    required this.hiredCount,
    required this.tags,
    required this.payType,
    required this.pay,
    required this.sameDayPayment,
    required this.foodProvided,
    required this.extraPay,
    required this.description,
    required this.checklists,
    required this.status,
    this.category = JobCategory.etc,
    this.workType = WorkType.shortTerm,
    this.contractStatus = ContractStatus.none,
    this.checkinAt,
    this.checkoutAt,
    this.recurrenceWeekdays = const [],
    this.boostUntil,
  });
}

class JobApplication {
  final int id;
  final int jobId;
  final int workerId;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final double distanceKm;
  final String? cancelReason;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.status,
    required this.appliedAt,
    required this.distanceKm,
    this.cancelReason,
  });
}

class Review {
  final int id;
  final int fromUserId;
  final String fromUserName;
  final int jobId;
  final String jobTitle;
  final double rating;
  final String content;
  final DateTime createdAt;
  final List<String> tags;

  const Review({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.jobId,
    required this.jobTitle,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.tags = const [],
  });
}

class AppNotification {
  final int id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final int? jobId;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.jobId,
  });
}

class ChatRoom {
  final int id;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String jobTitle;

  const ChatRoom({
    required this.id,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.jobTitle,
  });
}

class LocationFavorite {
  final int id;
  final String label;
  final String address;
  final double lat;
  final double lng;

  const LocationFavorite({
    required this.id,
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class PaymentItem {
  final int id;
  final int? jobId;
  final String jobTitle;
  final String giverName;
  final DateTime workedAt;
  final int amount; // 총 지급액 (gross)
  final int fee; // 플랫폼 수수료 (구직자에게는 0)
  final int tax; // 원천징수 (3.3% 등)
  final int netAmount; // 실수령액
  final String? bankAccount; // 입금 계좌 마스킹
  final bool paid;
  final DateTime? paidAt;

  const PaymentItem({
    required this.id,
    this.jobId,
    required this.jobTitle,
    this.giverName = '',
    required this.workedAt,
    required this.amount,
    this.fee = 0,
    this.tax = 0,
    int? netAmount,
    this.bankAccount,
    required this.paid,
    this.paidAt,
  }) : netAmount = netAmount ?? amount;
}

class PaymentMethod {
  final int id;
  final PaymentMethodKind kind;
  final String label; // ex) 신한카드 1234, 카카오뱅크 1111
  final String maskedNumber;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.kind,
    required this.label,
    required this.maskedNumber,
    this.isDefault = false,
  });
}

class EscrowEntry {
  final int id;
  final EscrowKind kind;
  final String description;
  final int amount; // + 입금, - 출금
  final DateTime createdAt;

  const EscrowEntry({
    required this.id,
    required this.kind,
    required this.description,
    required this.amount,
    required this.createdAt,
  });
}

class Notice {
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool pinned;

  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.pinned = false,
  });
}

class FaqItem {
  final String category;
  final String question;
  final String answer;

  const FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}

enum InquiryStatus { open, answered }

class Inquiry {
  final int id;
  final String category;
  final String title;
  final String body;
  final InquiryStatus status;
  final DateTime createdAt;
  final String? answer;

  const Inquiry({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    this.answer,
  });
}

class BlockedUser {
  final int userId;
  final String name;
  final DateTime blockedAt;

  const BlockedUser({
    required this.userId,
    required this.name,
    required this.blockedAt,
  });
}

class SavedSearch {
  final int id;
  final String label;
  final String? keyword;
  final List<JobCategory> categories;
  final int? minHourly;
  final double? radiusKm;
  final bool sameDayOnly;
  final bool nightOk;
  final bool pushEnabled;
  final DateTime createdAt;

  const SavedSearch({
    required this.id,
    required this.label,
    this.keyword,
    this.categories = const [],
    this.minHourly,
    this.radiusKm,
    this.sameDayOnly = false,
    this.nightOk = false,
    this.pushEnabled = true,
    required this.createdAt,
  });

  SavedSearch copyWith({bool? pushEnabled}) => SavedSearch(
        id: id,
        label: label,
        keyword: keyword,
        categories: categories,
        minHourly: minHourly,
        radiusKm: radiusKm,
        sameDayOnly: sameDayOnly,
        nightOk: nightOk,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        createdAt: createdAt,
      );
}

class EmergencyContact {
  final int id;
  final String name;
  final String relation;
  final String phone;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
  });
}

class SecurityPrefs {
  final bool pinEnabled;
  final bool biometricEnabled;
  final Duration autoLock;
  final bool requireAuthOnPay;

  const SecurityPrefs({
    this.pinEnabled = false,
    this.biometricEnabled = false,
    this.autoLock = const Duration(minutes: 5),
    this.requireAuthOnPay = true,
  });

  SecurityPrefs copyWith({
    bool? pinEnabled,
    bool? biometricEnabled,
    Duration? autoLock,
    bool? requireAuthOnPay,
  }) =>
      SecurityPrefs(
        pinEnabled: pinEnabled ?? this.pinEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        autoLock: autoLock ?? this.autoLock,
        requireAuthOnPay: requireAuthOnPay ?? this.requireAuthOnPay,
      );
}

enum BankAccountStatus { unverified, pending, verified }

class BankAccount {
  final int id;
  final String bank;
  final String holder;
  final String maskedNumber;
  final BankAccountStatus status;
  final bool isDefault;

  const BankAccount({
    required this.id,
    required this.bank,
    required this.holder,
    required this.maskedNumber,
    required this.status,
    this.isDefault = false,
  });
}

enum DisputeStage { received, reviewing, mediation, resolved }

enum DisputeReason {
  noShowGiver,
  noShowWorker,
  payDelay,
  payAmount,
  workCondition,
  injury,
  etc,
}

extension DisputeReasonX on DisputeReason {
  String get label {
    switch (this) {
      case DisputeReason.noShowGiver:
        return '구인자 노쇼';
      case DisputeReason.noShowWorker:
        return '구직자 노쇼';
      case DisputeReason.payDelay:
        return '정산 지연';
      case DisputeReason.payAmount:
        return '정산 금액 불일치';
      case DisputeReason.workCondition:
        return '근무 조건 불일치';
      case DisputeReason.injury:
        return '근무 중 사고/부상';
      case DisputeReason.etc:
        return '기타';
    }
  }
}

class DisputeEvent {
  final DisputeStage stage;
  final String description;
  final DateTime at;

  const DisputeEvent({
    required this.stage,
    required this.description,
    required this.at,
  });
}

class Dispute {
  final int id;
  final int? jobId;
  final String jobTitle;
  final String otherPartyName;
  final DisputeReason reason;
  final String description;
  final DisputeStage stage;
  final DateTime createdAt;
  final List<DisputeEvent> timeline;

  const Dispute({
    required this.id,
    this.jobId,
    required this.jobTitle,
    required this.otherPartyName,
    required this.reason,
    required this.description,
    required this.stage,
    required this.createdAt,
    this.timeline = const [],
  });
}

class NotificationPrefs {
  final bool application;
  final bool hire;
  final bool chat;
  final bool review;
  final bool system;
  final bool marketing;
  final bool nightQuiet;

  const NotificationPrefs({
    this.application = true,
    this.hire = true,
    this.chat = true,
    this.review = true,
    this.system = true,
    this.marketing = false,
    this.nightQuiet = true,
  });

  NotificationPrefs copyWith({
    bool? application,
    bool? hire,
    bool? chat,
    bool? review,
    bool? system,
    bool? marketing,
    bool? nightQuiet,
  }) =>
      NotificationPrefs(
        application: application ?? this.application,
        hire: hire ?? this.hire,
        chat: chat ?? this.chat,
        review: review ?? this.review,
        system: system ?? this.system,
        marketing: marketing ?? this.marketing,
        nightQuiet: nightQuiet ?? this.nightQuiet,
      );
}
