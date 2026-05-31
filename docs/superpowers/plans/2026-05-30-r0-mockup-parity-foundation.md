# R0 — Mockup Parity Foundation (ApiJobCard + category_jobs) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the `api.Job`-backed `ApiJobCard` widget and prove the (a) restoration pattern by restoring `category_jobs` to mockup fidelity, with zero backend change and no regression of wired behavior.

**Architecture:** Add a new shared `ApiJobCard` that reproduces the mockup `JobCard` layout over `api.Job`, omitting fields the backend lacks (per policy (a)). Repoint `category_jobs` from a bare `ListTile` list to `ApiJobCard` + the mockup's count/sort toolbar + alert action + `EmptyState`, preserving its `FutureBuilder`/repository/DI wiring. `splash` and `mypage` are verified no-ops under (a).

**Tech Stack:** Flutter, `go_router`, freezed `api.Job` model, `flutter_test` widget tests with a `dio` `HttpClientAdapter` stub.

**Spec:** `docs/superpowers/specs/2026-05-30-mockup-parity-restoration-design.md`

**Verification anchor:** mockup `JobCard` at `git show ae2466d:lib/widgets/shared.dart` (lines ~48–155).

**Commit policy (project rule):** NEVER run raw `git commit`. Commit steps below are **/commit-push gates** — stage the listed files and run the `/commit-push` skill when the user invokes it. Batch task commits if executing several tasks before the user commits.

---

## File Structure

- **Create** `lib/widgets/api_job_card.dart` — `ApiJobCard` stateless widget (api.Job → mockup card layout, (a) omissions). One responsibility: render one job as a card.
- **Create** `test/widgets/api_job_card_test.dart` — widget tests for `ApiJobCard`.
- **Modify** `lib/screens/categories/category_jobs_screen.dart` — restore mockup chrome (alert action, count/sort toolbar, separated list of `ApiJobCard`, `EmptyState`); keep all backend wiring.
- **Modify** `test/screens/category_jobs_screen_test.dart` — extend with card/toolbar/empty/action cases; keep the existing `passes categoryId` case.
- **Unchanged (verify):** `lib/screens/splash/splash_screen.dart`, `lib/screens/worker/mypage/mypage_screen.dart`.

Reused as-is: `fmtMoney` (`lib/widgets/shared.dart:7`), `EmptyState` (`lib/widgets/shared.dart:312`), `AppColors` (`lib/theme/app_theme.dart`). Legacy `JobCard` and `dummy_data.dart` are left untouched (still used by 4 mockup screens).

---

## Task 1: `ApiJobCard` shared widget

**Files:**
- Create: `lib/widgets/api_job_card.dart`
- Test: `test/widgets/api_job_card_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/widgets/api_job_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/models/api_models/job.dart' as api;
import 'package:sharework_mockup/widgets/api_job_card.dart';

api.Job _job({String? schedule}) => api.Job(
      id: 'j1',
      title: '카페 주말 알바',
      description: 'd',
      wageWon: 12000,
      scheduleText: schedule,
      status: 'active',
      categoryId: 'c1',
      locationAddress: '서울시 강남구',
      createdAt: '2026-05-11T00:00:00Z',
      updatedAt: '2026-05-11T00:00:00Z',
    );

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('renders title, location and formatted wage', (tester) async {
    await _pump(tester, ApiJobCard(job: _job()));
    expect(find.text('카페 주말 알바'), findsOneWidget);
    expect(find.text('서울시 강남구'), findsOneWidget);
    expect(find.text('12,000원'), findsOneWidget);
  });

  testWidgets('hides schedule row when scheduleText is null', (tester) async {
    await _pump(tester, ApiJobCard(job: _job()));
    expect(find.byIcon(Icons.access_time), findsNothing);
  });

  testWidgets('shows schedule row when scheduleText is present',
      (tester) async {
    await _pump(tester, ApiJobCard(job: _job(schedule: '매주 토/일 09:00~18:00')));
    expect(find.byIcon(Icons.access_time), findsOneWidget);
    expect(find.text('매주 토/일 09:00~18:00'), findsOneWidget);
  });

  testWidgets('fires onTap', (tester) async {
    var tapped = false;
    await _pump(tester, ApiJobCard(job: _job(), onTap: () => tapped = true));
    await tester.tap(find.byType(ApiJobCard));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widgets/api_job_card_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../api_job_card.dart'` / `ApiJobCard` undefined.

- [ ] **Step 3: Write the minimal implementation**

Create `lib/widgets/api_job_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/api_models/job.dart' as api;
import '../theme/app_theme.dart';
import 'shared.dart' show fmtMoney;

/// Renders an [api.Job] in the mockup JobCard layout.
///
/// Per restoration policy (a), fields the backend does not expose are omitted
/// (no `sameDayPayment` chip, no distance, no `payType` prefix, no
/// headcount, no tags). Structured start/end times are replaced by the free
/// `scheduleText` line, shown only when present.
class ApiJobCard extends StatelessWidget {
  final api.Job job;
  final VoidCallback? onTap;
  const ApiJobCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    final schedule = job.scheduleText?.trim() ?? '';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      job.locationAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              if (schedule.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        schedule,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Text(
                fmtMoney(job.wageWon),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/widgets/api_job_card_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: /commit-push gate**

Stage `lib/widgets/api_job_card.dart` and `test/widgets/api_job_card_test.dart`. Suggested message: `feat(flutter): R0 ApiJobCard — api.Job mockup card (policy-a omissions)`. Do not run raw `git commit`; await `/commit-push`.

---

## Task 2: Restore `category_jobs` to mockup fidelity

**Files:**
- Modify: `lib/screens/categories/category_jobs_screen.dart`
- Test: `test/screens/category_jobs_screen_test.dart`

- [ ] **Step 1: Write the failing tests (extend the existing file)**

Replace the contents of `test/screens/category_jobs_screen_test.dart` with (keeps the original `passes categoryId` case, adds five):

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/categories/category_jobs_screen.dart';
import 'package:sharework_mockup/widgets/api_job_card.dart';
import 'package:sharework_mockup/widgets/shared.dart' show EmptyState;

class _Stub implements HttpClientAdapter {
  Map<String, List<String>>? lastQuery;
  String body;
  _Stub(this.body);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async {
    lastQuery = o.uri.queryParametersAll;
    return ResponseBody.fromString(body, 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

String _job(String id, String title, int wage, String created) =>
    '{"id":"$id","title":"$title","description":"d","wage_won":$wage,'
    '"schedule_text":null,"status":"active","category_id":"c1",'
    '"location_address":"서울","giver":{"public_id":"GVR1","name":"홍길동"},'
    '"photos":[],"created_at":"$created","updated_at":"$created"}';

String _page(List<String> jobs) =>
    '{"data":[${jobs.join(",")}],"page":{"total":${jobs.length},"page":1,"limit":20}}';

Future<JobRepository> _repoWith(String body) async {
  final dio = Dio()..httpClientAdapter = _Stub(body);
  return JobRepository(dio);
}

Future<void> _pump(WidgetTester tester, JobRepository repo) async {
  await tester.pumpWidget(MaterialApp(
    home: CategoryJobsScreen(
        categoryId: 'c1', categoryName: '카페', jobRepository: repo),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('passes categoryId to listJobs', (tester) async {
    final adapter = _Stub(_page([_job('j1', '카페 알바', 12000, '2026-05-11T00:00:00Z')]));
    final repo = JobRepository(Dio()..httpClientAdapter = adapter);
    await _pump(tester, repo);
    expect(adapter.lastQuery!['category'], ['c1']);
    expect(find.text('카페 알바'), findsOneWidget);
  });

  testWidgets('renders jobs via ApiJobCard with count toolbar', (tester) async {
    await _pump(
        tester,
        await _repoWith(_page([
          _job('j1', '카페 알바', 12000, '2026-05-11T00:00:00Z'),
        ])));
    expect(find.byType(ApiJobCard), findsOneWidget);
    expect(find.text('1건'), findsOneWidget);
    expect(find.text('최신순'), findsOneWidget); // default sort label
  });

  testWidgets('empty result shows EmptyState', (tester) async {
    await _pump(tester, await _repoWith(_page([])));
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('해당 카테고리에 공고가 없어요'), findsOneWidget);
    expect(find.byIcon(Icons.work_off_outlined), findsOneWidget);
  });

  testWidgets('AppBar exposes the category-alert action', (tester) async {
    await _pump(
        tester,
        await _repoWith(_page([_job('j1', '카페 알바', 12000, '2026-05-11T00:00:00Z')])));
    expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
  });

  testWidgets('default order is latest-first by createdAt', (tester) async {
    // j_old created earlier, j_new later -> j_new should appear above j_old
    await _pump(
        tester,
        await _repoWith(_page([
          _job('old', '오래된 공고', 10000, '2026-05-01T00:00:00Z'),
          _job('new', '최신 공고', 9000, '2026-05-20T00:00:00Z'),
        ])));
    final yNew = tester.getTopLeft(find.text('최신 공고')).dy;
    final yOld = tester.getTopLeft(find.text('오래된 공고')).dy;
    expect(yNew, lessThan(yOld));
  });

  testWidgets('switching to 시급순 orders by wage desc', (tester) async {
    await _pump(
        tester,
        await _repoWith(_page([
          _job('lo', '저시급', 9000, '2026-05-20T00:00:00Z'),
          _job('hi', '고시급', 15000, '2026-05-01T00:00:00Z'),
        ])));
    await tester.tap(find.text('최신순'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시급순').last);
    await tester.pumpAndSettle();
    final yHi = tester.getTopLeft(find.text('고시급')).dy;
    final yLo = tester.getTopLeft(find.text('저시급')).dy;
    expect(yHi, lessThan(yLo));
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/screens/category_jobs_screen_test.dart`
Expected: FAIL — no `ApiJobCard`/`EmptyState`/`최신순`/`1건`/alert icon yet (current screen renders bare `ListTile`s).

- [ ] **Step 3: Implement the restore**

Replace the contents of `lib/screens/categories/category_jobs_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/job_repository.dart';
import '../../models/api_models/job.dart' as api;
import '../../widgets/api_job_card.dart';
import '../../widgets/shared.dart' show EmptyState;

enum _Sort { latest, wage }

class CategoryJobsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final JobRepository? jobRepository;
  const CategoryJobsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.jobRepository,
  });
  @override
  State<CategoryJobsScreen> createState() => _CategoryJobsScreenState();
}

class _CategoryJobsScreenState extends State<CategoryJobsScreen> {
  late final JobRepository _repo;
  late Future<({List<api.Job> items, int total})> _future;
  _Sort _sort = _Sort.latest;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? JobRepository.fromApi();
    _future = _repo.listJobs(category: widget.categoryId);
  }

  List<api.Job> _sorted(List<api.Job> items) {
    final list = [...items];
    switch (_sort) {
      case _Sort.latest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Sort.wage:
        list.sort((a, b) => b.wageWon.compareTo(a.wageWon));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: '이 카테고리 알림 받기',
            onPressed: () => context.push('/me/saved-searches/new'),
          ),
        ],
      ),
      body: FutureBuilder<({List<api.Job> items, int total})>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('연결이 불안정합니다'));
          }
          final items = snap.data?.items ?? const <api.Job>[];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.work_off_outlined,
              message: '해당 카테고리에 공고가 없어요',
            );
          }
          final total = snap.data?.total ?? items.length;
          final sorted = _sorted(items);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Text('$total건',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    DropdownButton<_Sort>(
                      value: _sort,
                      underline: const SizedBox.shrink(),
                      onChanged: (v) {
                        if (v != null) setState(() => _sort = v);
                      },
                      items: const [
                        DropdownMenuItem(
                            value: _Sort.latest, child: Text('최신순')),
                        DropdownMenuItem(
                            value: _Sort.wage, child: Text('시급순')),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final j = sorted[i];
                    return ApiJobCard(
                      job: j,
                      onTap: () => context.push('/job/${j.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/screens/category_jobs_screen_test.dart`
Expected: PASS (6 tests, including the preserved `passes categoryId`).

- [ ] **Step 5: /commit-push gate**

Stage `lib/screens/categories/category_jobs_screen.dart` and `test/screens/category_jobs_screen_test.dart`. Suggested message: `feat(flutter): R0 restore category_jobs — ApiJobCard + count/sort toolbar + alert + EmptyState`. Await `/commit-push`.

---

## Task 3: Verify no-op screens and full regression

**Files:** none modified (verification only).

- [ ] **Step 1: Confirm splash/mypage are untouched**

Run: `git status --porcelain lib/screens/splash/splash_screen.dart lib/screens/worker/mypage/mypage_screen.dart`
Expected: empty output (no changes). Rationale: under (a) both are already at parity — `splash`'s only diff is the kept auth-redirect; `mypage`'s sole gap is the rating row, which needs `rating`/`reviewCount` absent from `Profile` → omitted.

- [ ] **Step 2: Run the full test suite (no regressions)**

Run: `flutter test`
Expected: all tests PASS (prior baseline + 4 new `ApiJobCard` + the extended `category_jobs` cases). 0 failures.

- [ ] **Step 3: Static analysis (no new issues)**

Run: `flutter analyze --no-fatal-infos`
Expected: no new warnings/errors in `lib/widgets/api_job_card.dart` or `lib/screens/categories/category_jobs_screen.dart` (pre-existing infos in unrelated files are acceptable).

- [ ] **Step 4: iOS simulator build smoke**

Run: `flutter build ios --simulator --no-codesign`
Expected: build succeeds.

- [ ] **Step 5: Multi-agent review (project rule)**

Dispatch Code Reviewer + UI Designer/UX Architect on the R0 diff (restored UI). Land any must_fix inline (re-run Steps 2–4 after). Security Engineer not required (no auth/payment/LLM surface).

- [ ] **Step 6: /commit-push gate (if review produced fixes)**

If Step 5 changed files, stage them and await `/commit-push`.

---

## Self-Review (completed by plan author)

- **Spec coverage:** §5.1 `ApiJobCard` → Task 1; §5.2 `category_jobs` (alert action, count/sort toolbar dropping 거리순, Divider, separated list, `EmptyState`, preserved DI/FutureBuilder/listJobs/String-id nav) → Task 2; §5.3 `splash`/`mypage` no-op → Task 3 Step 1; §6 testing/analyze/build/review → Task 3. No gaps.
- **Placeholder scan:** none — all steps carry full code and exact commands.
- **Type consistency:** `ApiJobCard({required api.Job job, VoidCallback? onTap})`, `fmtMoney(int)`, `EmptyState({required IconData icon, required String message})`, `JobRepository.listJobs({category})→({List<api.Job> items, int total})`, `_Sort {latest, wage}` — consistent across Tasks 1–2 and tests.
