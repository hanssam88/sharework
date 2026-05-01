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
  final String jobTitle;
  final DateTime workedAt;
  final int amount;
  final bool paid;

  const PaymentItem({
    required this.id,
    required this.jobTitle,
    required this.workedAt,
    required this.amount,
    required this.paid,
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
