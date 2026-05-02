import 'package:flutter/material.dart';

import '../models/models.dart';

class Dummy {
  static final AppUser me = AppUser(
    id: 1,
    name: '김알바',
    phone: '010-1234-5678',
    email: 'alba@sharework.kr',
    address: '서울 강남구 테헤란로 123',
    profileUrl: null,
    rating: 4.8,
    reviewCount: 42,
    tags: const ['성실함', '시간엄수', '경험많음', '체력좋음'],
    introduction:
        '안녕하세요. 3년차 단기알바 전문입니다. 카페·매장보조·행사스태프 경험이 풍부하고, 어떤 환경에서도 빠르게 적응합니다.',
    appType: AppType.worker,
    identityVerified: true,
    verificationBadges: const ['본인인증', '바리스타', '위생교육'],
  );

  static final List<AppUser> givers = [
    AppUser(
      id: 101,
      name: '카페 모카',
      phone: '02-1234-1111',
      email: 'mocha@cafe.kr',
      address: '서울 강남구 역삼동',
      profileUrl: null,
      rating: 4.9,
      reviewCount: 128,
      tags: const ['친절함', '정시지급', '깔끔'],
      introduction: '강남역 도보 5분 거리의 카페입니다. 함께 일하실 분 찾습니다.',
      appType: AppType.giver,
      identityVerified: true,
      businessNumber: '123-45-67890',
      businessVerified: true,
      verificationBadges: const ['사업자', '본인인증'],
    ),
    AppUser(
      id: 102,
      name: '한솔이벤트',
      phone: '02-2222-3333',
      email: 'event@hansol.kr',
      address: '서울 송파구 잠실동',
      profileUrl: null,
      rating: 4.6,
      reviewCount: 87,
      tags: const ['행사많음', '식사제공'],
      introduction: '각종 행사 스태프 모집 중입니다.',
      appType: AppType.giver,
    ),
    AppUser(
      id: 103,
      name: '마트친구',
      phone: '02-4444-5555',
      email: 'mart@friend.kr',
      address: '서울 마포구 합정동',
      profileUrl: null,
      rating: 4.7,
      reviewCount: 56,
      tags: const ['교통비지원', '식사제공'],
      introduction: '대형마트 진열·계산 보조 알바입니다.',
      appType: AppType.giver,
    ),
  ];

  static final List<Job> jobs = [
    Job(
      id: 1001,
      giverId: 101,
      giverName: '카페 모카',
      title: '카페 주말 알바 구합니다',
      address: '서울 강남구 역삼동 123-4',
      lat: 37.4979,
      lng: 127.0276,
      startAt: DateTime.now().add(const Duration(days: 1, hours: 9)),
      endAt: DateTime.now().add(const Duration(days: 1, hours: 17)),
      personnel: 2,
      hiredCount: 0,
      tags: const ['카페', '주말', '단기'],
      payType: '시급',
      pay: 12000,
      sameDayPayment: true,
      foodProvided: true,
      extraPay: false,
      description: '주말 오전 9시 ~ 오후 5시까지 카페 홀 서빙·주문 받기 도와주실 분 구합니다. 친절하게 손님 응대 가능하신 분 환영해요.',
      checklists: const ['카페 알바 경험 있으신가요?', '바리스타 자격증 보유?', '주말 8시간 근무 가능?'],
      status: JobStatus.open,
      category: JobCategory.cafe,
      workType: WorkType.shortTerm,
      contractStatus: ContractStatus.none,
    ),
    Job(
      id: 1002,
      giverId: 102,
      giverName: '한솔이벤트',
      title: '잠실 행사 스태프 모집 (식사·교통비 제공)',
      address: '서울 송파구 잠실동 올림픽로 25',
      lat: 37.5145,
      lng: 127.1000,
      startAt: DateTime.now().add(const Duration(days: 2, hours: 8)),
      endAt: DateTime.now().add(const Duration(days: 2, hours: 18)),
      personnel: 10,
      hiredCount: 4,
      tags: const ['행사', '스태프', '식사제공'],
      payType: '일급',
      pay: 100000,
      sameDayPayment: true,
      foodProvided: true,
      extraPay: true,
      description: '잠실 종합운동장 일대에서 진행되는 대형 행사의 안내·진행 보조 인력 모집합니다. 단정한 복장 필수.',
      checklists: const ['장시간 서서 근무 가능?', '행사 진행 경험?'],
      status: JobStatus.open,
      category: JobCategory.event,
      workType: WorkType.oneDay,
      contractStatus: ContractStatus.sent,
    ),
    Job(
      id: 1003,
      giverId: 103,
      giverName: '마트친구',
      title: '대형마트 진열·계산 보조 (저녁 4시간)',
      address: '서울 마포구 합정동 30-12',
      lat: 37.5495,
      lng: 127.9000,
      startAt: DateTime.now().add(const Duration(days: 3, hours: 18)),
      endAt: DateTime.now().add(const Duration(days: 3, hours: 22)),
      personnel: 3,
      hiredCount: 1,
      tags: const ['마트', '저녁', '단기'],
      payType: '시급',
      pay: 11000,
      sameDayPayment: false,
      foodProvided: false,
      extraPay: true,
      description: '저녁 6시~10시 사이 진열 정리 및 계산 보조해주실 분 구합니다.',
      checklists: const ['마트 알바 경험?', '4시간 연속 근무 가능?'],
      status: JobStatus.open,
      category: JobCategory.mart,
      workType: WorkType.recurring,
      recurrenceWeekdays: [1, 3, 5], // 월·수·금
    ),
    Job(
      id: 1004,
      giverId: 101,
      giverName: '카페 모카',
      title: '평일 오전 카페 오픈 알바',
      address: '서울 강남구 역삼동 123-4',
      lat: 37.4979,
      lng: 127.0276,
      startAt: DateTime.now().subtract(const Duration(days: 5)),
      endAt: DateTime.now().subtract(const Duration(days: 5, hours: -6)),
      personnel: 1,
      hiredCount: 1,
      tags: const ['카페', '오픈'],
      payType: '시급',
      pay: 12500,
      sameDayPayment: true,
      foodProvided: false,
      extraPay: false,
      description: '오픈 멤버 모집',
      checklists: const ['오픈 경험?'],
      status: JobStatus.done,
      category: JobCategory.cafe,
      workType: WorkType.shortTerm,
      contractStatus: ContractStatus.signed,
      checkinAt: DateTime.now().subtract(const Duration(days: 5, hours: 0)),
      checkoutAt: DateTime.now().subtract(const Duration(days: 5, hours: -6)),
    ),
  ];

  static final List<JobApplication> applications = [
    JobApplication(
      id: 1,
      jobId: 1001,
      workerId: 1,
      status: ApplicationStatus.applied,
      appliedAt: DateTime.now().subtract(const Duration(hours: 3)),
      distanceKm: 1.2,
    ),
    JobApplication(
      id: 2,
      jobId: 1002,
      workerId: 1,
      status: ApplicationStatus.hired,
      appliedAt: DateTime.now().subtract(const Duration(days: 1)),
      distanceKm: 4.7,
    ),
    JobApplication(
      id: 3,
      jobId: 1004,
      workerId: 1,
      status: ApplicationStatus.completed,
      appliedAt: DateTime.now().subtract(const Duration(days: 6)),
      distanceKm: 1.2,
    ),
  ];

  static final List<Review> reviews = [
    Review(
      id: 1,
      fromUserId: 101,
      fromUserName: '카페 모카',
      jobId: 1004,
      jobTitle: '평일 오전 카페 오픈 알바',
      rating: 5.0,
      content: '시간 엄수하시고 너무 친절하게 일해주셨어요. 다음에도 또 부탁드리고 싶습니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      tags: const ['시간엄수', '친절함', '성실'],
    ),
    Review(
      id: 2,
      fromUserId: 102,
      fromUserName: '한솔이벤트',
      jobId: 999,
      jobTitle: '코엑스 행사 스태프',
      rating: 4.5,
      content: '책임감 있고 침착하게 잘 해주셨습니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      tags: const ['책임감', '침착함'],
    ),
    Review(
      id: 3,
      fromUserId: 103,
      fromUserName: '마트친구',
      jobId: 998,
      jobTitle: '주말 마트 진열',
      rating: 4.8,
      content: '꼼꼼하시고 빠르세요. 추천합니다!',
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
      tags: const ['꼼꼼함', '빠릿함'],
    ),
  ];

  static final List<AppNotification> notifications = [
    AppNotification(
      id: 1,
      kind: NotificationKind.hire,
      title: '채용 확정',
      body: '한솔이벤트의 「잠실 행사 스태프 모집」에 채용되었습니다.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
      jobId: 1002,
    ),
    AppNotification(
      id: 2,
      kind: NotificationKind.application,
      title: '지원 완료',
      body: '카페 모카에 지원이 접수되었습니다.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false,
      jobId: 1001,
    ),
    AppNotification(
      id: 3,
      kind: NotificationKind.review,
      title: '리뷰가 도착했어요',
      body: '카페 모카에서 별 5점 리뷰를 남겼어요.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      isRead: true,
      jobId: 1004,
    ),
    AppNotification(
      id: 4,
      kind: NotificationKind.system,
      title: '이용약관 변경 안내',
      body: '2026년 5월 1일부터 이용약관이 일부 변경됩니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      isRead: true,
      jobId: null,
    ),
  ];

  static final List<ChatRoom> chatRooms = [
    ChatRoom(
      id: 1,
      otherUserName: '한솔이벤트',
      otherUserAvatar: null,
      lastMessage: '내일 8시까지 잠실역 2번 출구로 와주세요!',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 12)),
      unreadCount: 2,
      jobTitle: '잠실 행사 스태프 모집',
    ),
    ChatRoom(
      id: 2,
      otherUserName: '카페 모카',
      otherUserAvatar: null,
      lastMessage: '주말 근무 가능하신가요?',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 4)),
      unreadCount: 0,
      jobTitle: '카페 주말 알바',
    ),
    ChatRoom(
      id: 3,
      otherUserName: '마트친구',
      otherUserAvatar: null,
      lastMessage: '확인했습니다. 감사합니다.',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      jobTitle: '대형마트 진열·계산',
    ),
  ];

  static final List<LocationFavorite> locationFavorites = [
    LocationFavorite(
      id: 1,
      label: '집',
      address: '서울 강남구 테헤란로 123',
      lat: 37.5,
      lng: 127.0,
    ),
    LocationFavorite(
      id: 2,
      label: '학교',
      address: '서울 관악구 신림동',
      lat: 37.48,
      lng: 126.95,
    ),
  ];

  static final List<PaymentItem> payments = [
    PaymentItem(
      id: 1,
      jobId: 1004,
      jobTitle: '평일 오전 카페 오픈 알바',
      giverName: '카페 모카',
      workedAt: DateTime.now().subtract(const Duration(days: 5)),
      amount: 75000,
      fee: 0,
      tax: 2475, // 3.3%
      netAmount: 72525,
      bankAccount: '카카오뱅크 ****-**-1234',
      paid: true,
      paidAt: DateTime.now().subtract(const Duration(days: 5, hours: -8)),
    ),
    PaymentItem(
      id: 2,
      jobId: null,
      jobTitle: '코엑스 행사 스태프',
      giverName: '한솔이벤트',
      workedAt: DateTime.now().subtract(const Duration(days: 12)),
      amount: 100000,
      fee: 0,
      tax: 3300,
      netAmount: 96700,
      bankAccount: '카카오뱅크 ****-**-1234',
      paid: true,
      paidAt: DateTime.now().subtract(const Duration(days: 12, hours: -10)),
    ),
    PaymentItem(
      id: 3,
      jobId: null,
      jobTitle: '주말 마트 진열',
      giverName: '마트친구',
      workedAt: DateTime.now().subtract(const Duration(days: 22)),
      amount: 88000,
      fee: 0,
      tax: 2904,
      netAmount: 85096,
      bankAccount: '카카오뱅크 ****-**-1234',
      paid: true,
      paidAt: DateTime.now().subtract(const Duration(days: 22, hours: -12)),
    ),
  ];

  static final List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 1,
      kind: PaymentMethodKind.card,
      label: '신한카드',
      maskedNumber: '****-****-****-1234',
      isDefault: true,
    ),
    PaymentMethod(
      id: 2,
      kind: PaymentMethodKind.bank,
      label: '카카오뱅크',
      maskedNumber: '3333-**-1234567',
    ),
  ];

  static final List<EscrowEntry> escrow = [
    EscrowEntry(
      id: 1,
      kind: EscrowKind.deposit,
      description: '카페 주말 알바 공고 예치',
      amount: 240000,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    EscrowEntry(
      id: 2,
      kind: EscrowKind.payout,
      description: '평일 오전 카페 오픈 알바 정산',
      amount: -75000,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    EscrowEntry(
      id: 3,
      kind: EscrowKind.deposit,
      description: '잠실 행사 스태프 공고 예치',
      amount: 1000000,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    EscrowEntry(
      id: 4,
      kind: EscrowKind.refund,
      description: '취소된 공고 환불',
      amount: -50000,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ];

  static final List<AppUser> workers = [
    me,
    AppUser(
      id: 2,
      name: '이성실',
      phone: '010-2222-3333',
      email: 'lee@sharework.kr',
      address: '서울 송파구 잠실동',
      profileUrl: null,
      rating: 4.7,
      reviewCount: 31,
      tags: const ['친절함', '시간엄수', '서빙경험'],
      introduction: '서빙·홀 경험 2년차입니다. 시간 엄수가 강점이에요.',
      appType: AppType.worker,
    ),
    AppUser(
      id: 3,
      name: '박빠릿',
      phone: '010-3333-4444',
      email: 'park@sharework.kr',
      address: '서울 마포구 합정동',
      profileUrl: null,
      rating: 4.5,
      reviewCount: 18,
      tags: const ['체력좋음', '꼼꼼함'],
      introduction: '물류·진열 경험 많고 체력 자신 있습니다.',
      appType: AppType.worker,
    ),
    AppUser(
      id: 4,
      name: '최열심',
      phone: '010-4444-5555',
      email: 'choi@sharework.kr',
      address: '서울 강남구 역삼동',
      profileUrl: null,
      rating: 4.9,
      reviewCount: 64,
      tags: const ['책임감', '경험많음', '바리스타'],
      introduction: '바리스타 자격증 보유, 카페 경력 3년.',
      appType: AppType.worker,
    ),
  ];

  static List<JobApplication> applicantsForJob(int jobId) {
    final base = DateTime.now();
    return [
      JobApplication(
        id: 9001,
        jobId: jobId,
        workerId: 2,
        status: ApplicationStatus.applied,
        appliedAt: base.subtract(const Duration(hours: 2)),
        distanceKm: 3.2,
      ),
      JobApplication(
        id: 9002,
        jobId: jobId,
        workerId: 3,
        status: ApplicationStatus.applied,
        appliedAt: base.subtract(const Duration(hours: 5)),
        distanceKm: 5.8,
      ),
      JobApplication(
        id: 9003,
        jobId: jobId,
        workerId: 4,
        status: ApplicationStatus.hired,
        appliedAt: base.subtract(const Duration(hours: 12)),
        distanceKm: 1.4,
      ),
    ];
  }

  static final List<Notice> notices = [
    Notice(
      id: 1,
      title: '[필독] 2026년 5월 이용약관 개정 안내',
      body:
          '안녕하세요, Sharework 팀입니다.\n2026년 5월 1일부터 이용약관 일부가 개정됩니다.\n\n주요 변경사항:\n• 분쟁 조정 절차 신설\n• 정산 처리 기간 명확화 (영업일 기준 D+1)\n• 개인정보 위탁 처리 업체 추가\n\n자세한 내용은 변경된 이용약관에서 확인해주세요.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      pinned: true,
    ),
    Notice(
      id: 2,
      title: '추천인 코드 이벤트 (5월 한정)',
      body: '친구 초대 시 양쪽 모두 5,000원 쿠폰을 지급합니다. 자세한 내용은 이벤트 페이지를 참고해주세요.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Notice(
      id: 3,
      title: '서버 정기 점검 안내 (5/15 02:00~04:00)',
      body: '서비스 안정화를 위한 정기 점검이 진행됩니다. 해당 시간 동안 일시적으로 서비스 이용이 제한될 수 있습니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Notice(
      id: 4,
      title: '신고센터 운영시간 변경',
      body: '4월 1일부터 신고센터 운영시간이 평일 09:00~18:00 → 매일 08:00~22:00 으로 확대됩니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  static const List<FaqItem> faqs = [
    FaqItem(
      category: '계정',
      question: '회원가입은 어떻게 하나요?',
      answer: '휴대폰 본인인증 후 이름·이메일·약관 동의를 거쳐 가입할 수 있어요. 만 14세 미만은 가입이 제한됩니다.',
    ),
    FaqItem(
      category: '계정',
      question: '구직자/구인자 모드는 어떻게 전환하나요?',
      answer: '마이페이지 상단의 "모드 전환" 버튼으로 언제든 두 모드를 오갈 수 있습니다. 두 모드는 같은 계정·전화번호를 공유합니다.',
    ),
    FaqItem(
      category: '지원·채용',
      question: '지원을 취소할 수 있나요?',
      answer: '지원내역 → 지원중 탭의 더보기에서 취소가 가능합니다. 잦은 취소는 신뢰 점수에 반영될 수 있어요.',
    ),
    FaqItem(
      category: '지원·채용',
      question: '채용된 후 잠수하면 어떻게 되나요?',
      answer: '노쇼는 평점 차감 및 일정 기간 매칭 제한 사유가 됩니다. 부득이한 사정은 채팅으로 미리 알려주세요.',
    ),
    FaqItem(
      category: '정산',
      question: '당일지급은 어떻게 받나요?',
      answer: '근무 종료 후 출퇴근 체크가 확인되면 등록한 계좌로 자동 송금됩니다. 영업시간 외에는 익영업일 처리될 수 있어요.',
    ),
    FaqItem(
      category: '정산',
      question: '플랫폼 수수료는 얼마인가요?',
      answer: '구인자에게만 결제 금액의 일정 비율이 부과되며, 구직자에게는 수수료가 없습니다. 자세한 내역은 정산 명세서에서 확인하세요.',
    ),
    FaqItem(
      category: '신고·안전',
      question: '부적절한 사용자를 신고하려면?',
      answer: '프로필 또는 채팅방의 더보기에서 "신고하기"를 누르면 사유를 선택해 신고할 수 있습니다.',
    ),
    FaqItem(
      category: '신고·안전',
      question: '안심번호란 무엇인가요?',
      answer: '실제 휴대폰 번호 대신 050으로 시작하는 가상 번호로 통화·문자할 수 있어 개인정보가 노출되지 않습니다.',
    ),
  ];

  static final List<Inquiry> inquiries = [
    Inquiry(
      id: 1,
      category: '정산',
      title: '당일지급이 안 들어왔어요',
      body: '어제 카페 알바 끝나고 당일지급 처리됐다고 알림이 왔는데 통장에 입금이 안 됐어요.',
      status: InquiryStatus.answered,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      answer: '확인해보니 등록 계좌 정보 오류로 보류된 상태였습니다. 정상 계좌로 재처리하여 오늘 14:00 입금 완료되었습니다.',
    ),
    Inquiry(
      id: 2,
      category: '계정',
      title: '비밀번호를 잊어버렸어요',
      body: '로그인이 안 되는데 어떻게 해야 하나요?',
      status: InquiryStatus.open,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  static final List<BlockedUser> blocked = [
    BlockedUser(
      userId: 999,
      name: '익명 사용자',
      blockedAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
  ];

  static const NotificationPrefs notificationPrefs = NotificationPrefs();

  static const Resume resume = Resume(
    headline: '시간 엄수 · 카페·서빙 3년차',
    summary:
        '안녕하세요. 3년차 단기알바 전문입니다.\n카페·매장보조·행사스태프 경험이 풍부하고, 어떤 환경에서도 빠르게 적응합니다.\n새로운 메뉴·매장 시스템 학습이 빠른 편이며, 손님 응대를 좋아합니다.',
    careers: [
      CareerEntry(
        company: '카페 모카 강남점',
        role: '바리스타 / 홀',
        period: '2024.03 ~ 현재',
        description: '오픈 ~ 점심 피크 운영. 신메뉴 시즌 메뉴 5종 개발 보조.',
      ),
      CareerEntry(
        company: '한솔 이벤트',
        role: '행사 스태프',
        period: '2023.05 ~ 2024.02',
        description: '코엑스·잠실 등 대형 행사 안내 및 관람객 대응. 누적 12회.',
      ),
      CareerEntry(
        company: '편의점 GS25',
        role: '야간 알바',
        period: '2022.06 ~ 2023.04',
        description: '야간 (22:00~07:00) 매대 정리·발주 보조.',
      ),
    ],
    educations: [
      EducationEntry(
        school: '한국대학교 경영학과',
        degree: '재학',
        period: '2021.03 ~ 현재',
      ),
    ],
    skills: ['바리스타 (라떼아트)', '엑셀 기본', '영어 회화 가능', '운전면허 1종 보통'],
  );

  static final List<PortfolioItem> portfolio = [
    PortfolioItem(
      id: 1,
      kind: PortfolioKind.image,
      title: '카페 시즌 메뉴 개발',
      subtitle: '2024 봄 — 라떼 4종',
      colorTag: '#E6F8F6',
    ),
    PortfolioItem(
      id: 2,
      kind: PortfolioKind.image,
      title: '코엑스 행사 운영',
      subtitle: '2023.11 IT 컨퍼런스',
      colorTag: '#FFF6E5',
    ),
    PortfolioItem(
      id: 3,
      kind: PortfolioKind.image,
      title: '점포 디스플레이',
      subtitle: '연말 시즌 데코',
      colorTag: '#EEF4FF',
    ),
    PortfolioItem(
      id: 4,
      kind: PortfolioKind.link,
      title: '개인 인스타그램',
      subtitle: '@kim_alba',
      url: 'https://instagram.com/example',
    ),
  ];

  static const List<AvailabilitySlot> availability = [
    AvailabilitySlot(weekday: 1, startHour: 9, endHour: 18),
    AvailabilitySlot(weekday: 2, startHour: 9, endHour: 18),
    AvailabilitySlot(weekday: 3, startHour: 14, endHour: 22),
    AvailabilitySlot(weekday: 6, startHour: 9, endHour: 22),
    AvailabilitySlot(weekday: 7, startHour: 9, endHour: 22),
  ];

  static final List<JobTemplate> jobTemplates = [
    JobTemplate(
      id: 1,
      name: '주말 카페 알바 (자주 사용)',
      title: '카페 주말 알바 구합니다',
      address: '서울 강남구 역삼동 123-4',
      category: JobCategory.cafe,
      workType: WorkType.shortTerm,
      payHourly: 12000,
      defaultPersonnel: 2,
      tags: const ['카페', '주말'],
      sameDayPayment: true,
      foodProvided: true,
      recurrenceWeekdays: [6, 7],
      useCount: 8,
    ),
    JobTemplate(
      id: 2,
      name: '평일 저녁 클로징',
      title: '평일 저녁 카페 클로징 알바',
      address: '서울 강남구 역삼동 123-4',
      category: JobCategory.cafe,
      workType: WorkType.recurring,
      payHourly: 13000,
      defaultPersonnel: 1,
      tags: const ['카페', '저녁', '클로징'],
      sameDayPayment: false,
      recurrenceWeekdays: [1, 2, 3, 4, 5],
      useCount: 12,
    ),
    JobTemplate(
      id: 3,
      name: '대형 행사 스태프',
      title: '행사 스태프 모집',
      address: '서울 송파구 잠실동',
      category: JobCategory.event,
      workType: WorkType.oneDay,
      payHourly: 100000,
      defaultPersonnel: 10,
      tags: const ['행사', '스태프'],
      sameDayPayment: true,
      foodProvided: true,
      extraPay: true,
      useCount: 3,
    ),
  ];

  static const List<BoostProduct> boostProducts = [
    BoostProduct(
      kind: BoostKind.topPin,
      name: '상단 고정',
      desc: '검색 결과 상단에 24시간 고정 노출',
      price: 5000,
      duration: Duration(hours: 24),
    ),
    BoostProduct(
      kind: BoostKind.brandColor,
      name: '브랜드 강조',
      desc: '리스트에서 카드 테두리·배지를 브랜드 컬러로 강조 (3일)',
      price: 9000,
      duration: Duration(days: 3),
    ),
    BoostProduct(
      kind: BoostKind.push,
      name: '관심 워커 푸시',
      desc: '조건이 맞는 워커에게 즉시 푸시 알림 전송',
      price: 12000,
      duration: Duration(hours: 6),
    ),
    BoostProduct(
      kind: BoostKind.premium,
      name: '프리미엄 패키지',
      desc: '상단 고정 + 푸시 + 추천 피드 노출 (7일)',
      price: 25000,
      duration: Duration(days: 7),
    ),
  ];

  static JobStats statsForJob(int jobId) {
    // 목업: jobId 기반 결정적 더미값
    final base = jobId % 10;
    return JobStats(
      impressions: 1240 + base * 87,
      clicks: 320 + base * 22,
      applications: 18 + base * 2,
      hires: 3 + (base % 4),
      avgPay: 11800,
      last7DaysImpressions: List.generate(
          7, (i) => 100 + ((i + base) * 27) % 240),
    );
  }

  static final List<Coupon> coupons = [
    Coupon(
      id: 1,
      name: '신규 가입 축하 쿠폰',
      desc: '첫 정산 시 5,000원 즉시 할인',
      discountAmount: 5000,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    ),
    Coupon(
      id: 2,
      name: '친구초대 쿠폰',
      desc: '플랫폼 수수료 10% 할인',
      discountPercent: 10,
      minOrder: 50000,
      expiresAt: DateTime.now().add(const Duration(days: 14)),
    ),
    Coupon(
      id: 3,
      name: '5월 봄맞이 쿠폰',
      desc: '에스크로 충전 3,000원 할인',
      discountAmount: 3000,
      minOrder: 30000,
      expiresAt: DateTime.now().add(const Duration(days: 3)),
    ),
    Coupon(
      id: 4,
      name: '재방문 환영 쿠폰',
      desc: '시급 알바 1회 무료',
      discountAmount: 12000,
      expiresAt: DateTime.now().subtract(const Duration(days: 2)),
      status: CouponStatus.expired,
    ),
  ];

  static final List<Mission> missions = [
    Mission(
      id: 1,
      title: '이번 주 3건 근무',
      desc: '한 주 3건 이상 근무 완료 시 500P 적립',
      progress: 2,
      goal: 3,
      rewardPoint: 500,
      icon: Icons.directions_run,
    ),
    Mission(
      id: 2,
      title: '리뷰 5개 받기',
      desc: '리뷰 누적 5개 달성 시 1,000P',
      progress: 5,
      goal: 5,
      rewardPoint: 1000,
      icon: Icons.rate_review_outlined,
      status: MissionStatus.completed,
    ),
    Mission(
      id: 3,
      title: '연속 출석 7일',
      desc: '7일 연속 앱 출석 시 300P',
      progress: 4,
      goal: 7,
      rewardPoint: 300,
      icon: Icons.calendar_month_outlined,
    ),
    Mission(
      id: 4,
      title: '친구 1명 초대',
      desc: '추천코드로 친구가 가입 시 양쪽 5,000원 쿠폰',
      progress: 0,
      goal: 1,
      rewardPoint: 0,
      icon: Icons.group_add_outlined,
    ),
  ];

  static const LevelInfo levelInfo = LevelInfo(
    name: 'Silver',
    currentPoint: 1240,
    nextLevelPoint: 2000,
    benefits: [
      '일감 추천 우선순위 +5%',
      '플랫폼 수수료 5% 할인',
      'Silver 전용 쿠폰',
    ],
    icon: Icons.workspace_premium,
    color: Color(0xFF94A3B8),
  );

  static final List<EventBanner> eventBanners = [
    EventBanner(
      id: 1,
      title: '5월 친구초대 더블 이벤트',
      subtitle: '친구초대 시 양쪽 5,000원 쿠폰 지급',
      cta: '초대하기',
      endAt: DateTime.now().add(const Duration(days: 12)),
      colorTag: '#E6F8F6',
    ),
    EventBanner(
      id: 2,
      title: '주말 한정 시급 +500원',
      subtitle: '카페·서빙 카테고리 주말 공고에 자동 적용',
      endAt: DateTime.now().add(const Duration(days: 5)),
      colorTag: '#FFF6E5',
    ),
    EventBanner(
      id: 3,
      title: '신규 워커 첫 정산 5,000원 할인',
      subtitle: '가입 7일 이내 워커 한정',
      endAt: DateTime.now().add(const Duration(days: 7)),
      colorTag: '#EEF4FF',
    ),
  ];

  static final List<ChatMessage> demoChatMessages = [
    ChatMessage(
      id: 1,
      kind: ChatMessageKind.text,
      body: '안녕하세요, 지원해주셔서 감사합니다.',
      mine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    ChatMessage(
      id: 2,
      kind: ChatMessageKind.text,
      body: '네 안녕하세요! 잘 부탁드립니다.',
      mine: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 28)),
    ),
    ChatMessage(
      id: 3,
      kind: ChatMessageKind.jobCard,
      body: '잠실 행사 스태프 모집',
      attachment: '1002',
      mine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    ChatMessage(
      id: 4,
      kind: ChatMessageKind.location,
      body: '잠실역 2번 출구',
      attachment: '37.5145,127.1000',
      mine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    ChatMessage(
      id: 5,
      kind: ChatMessageKind.text,
      body: '내일 8시까지 잠실역 2번 출구로 와주세요!',
      mine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    ChatMessage(
      id: 6,
      kind: ChatMessageKind.contract,
      body: '근로계약서 발송',
      attachment: '1002',
      mine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    ChatMessage(
      id: 7,
      kind: ChatMessageKind.text,
      body: '네, 계약서 확인하고 서명할게요.',
      mine: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    ChatMessage(
      id: 8,
      kind: ChatMessageKind.system,
      body: '근로계약서 서명이 완료되었습니다.',
      mine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    ChatMessage(
      id: 9,
      kind: ChatMessageKind.image,
      body: '오시는 길 사진',
      attachment: 'image1',
      mine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    ChatMessage(
      id: 10,
      kind: ChatMessageKind.text,
      body: '확인했습니다 :)',
      mine: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  static final List<Scout> scouts = [
    Scout(
      id: 1,
      fromGiverId: 101,
      fromGiverName: '카페 모카',
      toWorkerId: 1,
      toWorkerName: '김알바',
      jobId: 1001,
      jobTitle: '카페 주말 알바 구합니다',
      message:
          '안녕하세요! 프로필 보고 연락드려요. 다음 주말 함께 일하실 수 있을까요? 시급 우대해드릴게요.',
      status: ScoutStatus.sent,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      offerHourly: 13500,
    ),
    Scout(
      id: 2,
      fromGiverId: 102,
      fromGiverName: '한솔이벤트',
      toWorkerId: 1,
      toWorkerName: '김알바',
      message: '5월에 진행되는 행사 스태프 풀에 등록해두고 싶어요. 관심 있으시면 회신 부탁드립니다!',
      status: ScoutStatus.accepted,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static final List<FavoriteCompany> favoriteCompanies = [
    FavoriteCompany(
      giverId: 101,
      name: '카페 모카',
      address: '서울 강남구 역삼동',
      rating: 4.9,
      reviewCount: 128,
      badges: const ['사업자', '본인인증', '단골'],
      recentJobsCount: 4,
      addedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    FavoriteCompany(
      giverId: 102,
      name: '한솔이벤트',
      address: '서울 송파구 잠실동',
      rating: 4.6,
      reviewCount: 87,
      badges: const ['사업자'],
      recentJobsCount: 2,
      addedAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];

  static final List<RegularWorker> regulars = [
    RegularWorker(
      workerId: 4,
      name: '최열심',
      rating: 4.9,
      reviewCount: 64,
      tags: const ['책임감', '경험많음', '바리스타'],
      hireCount: 8,
      lastWorkedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    RegularWorker(
      workerId: 2,
      name: '이성실',
      rating: 4.7,
      reviewCount: 31,
      tags: const ['친절함', '시간엄수', '서빙경험'],
      hireCount: 3,
      lastWorkedAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
  ];

  static const WorkerPreferences preferences = WorkerPreferences(
    preferredHourly: 13000,
    preferredRadiusKm: 5,
    preferredCategories: [
      JobCategory.cafe,
      JobCategory.event,
      JobCategory.restaurant,
    ],
    preferredWorkTypes: [WorkType.shortTerm, WorkType.oneDay],
    allowSameDay: true,
    allowNight: false,
  );

  static final List<Credential> credentials = [
    Credential(
      id: 1,
      kind: CredentialKind.idCard,
      issuedAt: DateTime.now().subtract(const Duration(days: 800)),
      status: CredentialStatus.verified,
      memo: '주민등록증',
    ),
    Credential(
      id: 2,
      kind: CredentialKind.barista,
      issuedAt: DateTime.now().subtract(const Duration(days: 400)),
      status: CredentialStatus.verified,
      memo: 'SCA Barista Foundation',
    ),
    Credential(
      id: 3,
      kind: CredentialKind.hygieneEdu,
      issuedAt: DateTime.now().subtract(const Duration(days: 60)),
      expiresAt: DateTime.now().add(const Duration(days: 305)),
      status: CredentialStatus.verified,
      memo: '식약처 위생교육 수료',
    ),
    Credential(
      id: 4,
      kind: CredentialKind.health,
      issuedAt: DateTime.now().subtract(const Duration(days: 350)),
      expiresAt: DateTime.now().subtract(const Duration(days: 5)),
      status: CredentialStatus.expired,
      memo: '갱신 필요',
    ),
    Credential(
      id: 5,
      kind: CredentialKind.driverLicense,
      issuedAt: DateTime.now().subtract(const Duration(days: 1800)),
      expiresAt: DateTime.now().add(const Duration(days: 1100)),
      status: CredentialStatus.pending,
      memo: '검토 중 (1~2 영업일)',
    ),
  ];

  static const Map<String, String> legalContents = {
    'terms': '''Sharework 서비스 이용약관 (요약본)

제1조 (목적)
이 약관은 Sharework(이하 "회사")가 제공하는 긱워크 매칭 서비스의 이용에 관한 사항을 규정합니다.

제2조 (정의)
1. "구직자(Worker)"란 일자리를 검색·지원하는 회원을 말합니다.
2. "구인자(Giver)"란 일자리를 등록·채용하는 회원을 말합니다.
3. "공고"란 구인자가 등록한 일자리 모집 게시물을 말합니다.

제3조 (서비스의 제공)
회사는 다음과 같은 서비스를 제공합니다.
• 일자리 매칭 (검색·지원·채용)
• 전자근로계약서 작성·서명
• 안전결제(에스크로) 및 정산
• 신원인증·자격증 검증
• 분쟁 조정

제4조 (이용계약의 성립 및 해지)
이용계약은 회원가입 신청 후 회사가 승낙함으로써 성립합니다. 회원은 언제든 탈퇴를 신청할 수 있습니다.

(이하 약관 본문이 이어집니다 — 목업 화면)''',
    'privacy': '''개인정보 처리방침 (요약본)

1. 수집하는 개인정보
회사는 회원가입·서비스 제공을 위해 다음 정보를 수집합니다.
• 필수: 이름, 휴대폰 번호, 이메일, 주민등록번호(본인확인용 단방향 암호화)
• 선택: 프로필 사진, 자격증, 가용 시간

2. 개인정보의 이용 목적
• 회원 식별·본인확인·연령 확인
• 일자리 매칭·정산·세금 신고
• 분쟁 조정·고객 응대
• 부정 이용 방지

3. 개인정보 보유·이용 기간
관련 법령에 따라 거래 기록은 5년, 본인확인 기록은 6개월 보관됩니다.

4. 개인정보 처리 위탁
• 결제 PG: 토스페이먼츠
• SMS 발송: NHN Cloud
• 클라우드: AWS

5. 정보주체의 권리
회원은 언제든 본인 정보 열람·수정·삭제를 요청할 수 있습니다.

(이하 본문이 이어집니다 — 목업 화면)''',
    'guide': '''Sharework 이용가이드

🎯 구직자(Worker) 가이드
1. 홈에서 주변 일자리를 확인하거나 상단 검색바로 직접 검색
2. 마음에 드는 공고에 지원 → 구인자가 검토 후 채용 확정
3. 채팅으로 세부 일정 조율 → 출퇴근 체크 → 정산 수령
4. 근무 후 리뷰 작성 (양방향)

🏪 구인자(Giver) 가이드
1. "일감등록" 탭에서 공고 작성 (제목·시간·임금·태그)
2. 지원자 관리 화면에서 프로필 확인 후 채용 확정
3. 전자근로계약서 발송 → 서명 받기
4. 근무 완료 후 자동 정산 (에스크로)

🔒 안전 가이드
• 처음 보는 사용자와는 안심번호로 통화하세요
• 채팅 외부에서 별도 송금을 요구하면 신고해주세요
• 사고·분쟁 시 24시간 내 신고센터 접수

(자세한 영상 가이드는 추후 추가될 예정 — 목업 화면)''',
  };

  static const List<String> reviewTagPresets = [
    '시간엄수',
    '친절함',
    '성실함',
    '책임감',
    '꼼꼼함',
    '체력좋음',
    '소통원활',
    '재고용의향',
  ];

  static final List<BankAccount> bankAccounts = [
    BankAccount(
      id: 1,
      bank: '카카오뱅크',
      holder: '김알바',
      maskedNumber: '3333-**-1234567',
      status: BankAccountStatus.verified,
      isDefault: true,
    ),
    BankAccount(
      id: 2,
      bank: '신한은행',
      holder: '김알바',
      maskedNumber: '110-***-456789',
      status: BankAccountStatus.pending,
    ),
  ];

  static final List<Dispute> disputes = [
    Dispute(
      id: 1,
      jobId: 1004,
      jobTitle: '평일 오전 카페 오픈 알바',
      otherPartyName: '카페 모카',
      reason: DisputeReason.payAmount,
      description:
          '근무 시간은 6시간으로 합의했는데 정산서에는 5.5시간으로 처리되어 차액 6,000원 정산을 요청합니다.',
      stage: DisputeStage.mediation,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      timeline: [
        DisputeEvent(
          stage: DisputeStage.received,
          description: '분쟁 조정 신청이 접수되었습니다.',
          at: DateTime.now().subtract(const Duration(days: 3)),
        ),
        DisputeEvent(
          stage: DisputeStage.reviewing,
          description: '담당자가 양측 자료를 검토 중입니다.',
          at: DateTime.now().subtract(const Duration(days: 2)),
        ),
        DisputeEvent(
          stage: DisputeStage.mediation,
          description: '조정안이 제시되었습니다. 24시간 이내 동의 여부를 선택해 주세요.',
          at: DateTime.now().subtract(const Duration(hours: 6)),
        ),
      ],
    ),
    Dispute(
      id: 2,
      jobId: 1002,
      jobTitle: '잠실 행사 스태프 모집',
      otherPartyName: '한솔이벤트',
      reason: DisputeReason.workCondition,
      description: '식사 제공 공고였으나 현장에서 식사가 제공되지 않았습니다.',
      stage: DisputeStage.resolved,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      timeline: [
        DisputeEvent(
          stage: DisputeStage.received,
          description: '분쟁 조정 신청이 접수되었습니다.',
          at: DateTime.now().subtract(const Duration(days: 18)),
        ),
        DisputeEvent(
          stage: DisputeStage.reviewing,
          description: '담당자 검토 완료.',
          at: DateTime.now().subtract(const Duration(days: 16)),
        ),
        DisputeEvent(
          stage: DisputeStage.resolved,
          description: '구인자가 식대 1만원을 추가 정산하여 종결되었습니다.',
          at: DateTime.now().subtract(const Duration(days: 14)),
        ),
      ],
    ),
  ];

  static final List<SavedSearch> savedSearches = [
    SavedSearch(
      id: 1,
      label: '강남 카페 시급 1.3만↑',
      keyword: '카페',
      categories: const [JobCategory.cafe],
      minHourly: 13000,
      radiusKm: 3,
      pushEnabled: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    SavedSearch(
      id: 2,
      label: '주말 행사 스태프 (식사제공)',
      keyword: '행사',
      categories: const [JobCategory.event],
      minHourly: 90000,
      sameDayOnly: false,
      pushEnabled: true,
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
    ),
    SavedSearch(
      id: 3,
      label: '야간 마트 진열',
      categories: const [JobCategory.mart, JobCategory.logistics],
      nightOk: true,
      radiusKm: 5,
      pushEnabled: false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  static final List<EmergencyContact> emergencyContacts = [
    EmergencyContact(
      id: 1,
      name: '엄마',
      relation: '가족',
      phone: '010-9876-5432',
    ),
    EmergencyContact(
      id: 2,
      name: '이성실',
      relation: '친구',
      phone: '010-2222-3333',
    ),
  ];

  static const SecurityPrefs securityPrefs = SecurityPrefs(
    pinEnabled: false,
    biometricEnabled: false,
    autoLock: Duration(minutes: 5),
    requireAuthOnPay: true,
  );

  static Job jobById(int id) =>
      jobs.firstWhere((j) => j.id == id, orElse: () => jobs.first);

  static AppUser userById(int id) {
    if (id == me.id) return me;
    final w = workers.where((u) => u.id == id);
    if (w.isNotEmpty) return w.first;
    return givers.firstWhere((u) => u.id == id, orElse: () => givers.first);
  }
}
