# Sharework — Mockup Parity Restoration (Design Spec)

- **Date:** 2026-05-30
- **Status:** R0 detailed; R1–R3 sketched (each gets its own spec→plan→build cycle)
- **Goal (user-chosen):** **A — 화면을 목업과 100% 일치.** Every screen looks/behaves like the live mockup, restoring UI/UX lost during the backend wire-up, **without regressing the backend** and **without backend changes**.
- **Data policy (user-chosen):** **(a) 순정 복원.** Restore mockup layout/interaction; fill only fields that exist in the real backend; **omit absent fields — never fake data, never re-introduce `dummy_data` into wired screens.**

---

## 1. Background

The "mockup" at `https://hanssam88.github.io/sharework/` is a **Flutter web build of this same repo** at commit **`ae2466d`** (2026-05-11, last *successful* Pages deploy — every deploy since failed on the gitignored `.env` asset). The app at `main` HEAD is the **same 80 screens**, of which a subset was wired to a real Supabase BFF (M1 auth/jobs, M2 create/edit/photos, M3 applications). That wire-up simplified several screens, dropping mockup richness.

So "목업을 그대로 앱으로" = **reproduce the `ae2466d` widget tree on top of the real data layer**, for the screens that diverged. `ae2466d` is the literal verification anchor for every restoration.

## 2. Parity Audit (deterministic)

Compared all 80 screens, mockup (`ae2466d`) vs current worktree, **after normalizing `dart format` on both sides** (a `dart format` pass — commit `f2868b0`, 90 files — postdates the mockup and inflated raw diffs). Full per-screen audit: workflow `wc8b61dmz` output (13 structured reports, 143 gaps).

- **67 screens** are already identical to the mockup (escrow, contracts, checkin, scouts, disputes, KYC, payment methods, regulars, all `me/` & `support/`, etc.) → **goal A already satisfied, no work.**
- **52** of the 65 "changed" screens were **pure `dart format` reflow** → zero UI impact.
- **13 screens** have real fidelity divergence (the M1/M2/M3 wire-up surface):

| screen | fidelity | est | gaps | note |
|---|---|---|---|---|
| job_create | heavily-simplified | XL | 22 | draft/template/address-sheet/date-time pickers/personnel/tags/market-card/recurrence/checklist/publish-mode lost |
| applicants | heavily-simplified | XL | 17 | match-score/sort/stat-chips/rating-distance/skill-chips/compare-dialog/bulk/select-mode lost |
| job_info | heavily-simplified | XL | 16 | rich header/time-personnel/tags/checklist/similar-jobs/rating lost |
| search | heavily-simplified | XL | 15 | filter chips/sort/recent-viewed/discovery sections lost |
| giver_home | heavily-simplified | L | 13 | rich card fields lost |
| worker_home | heavily-simplified | L | 12 | rich card + chrome lost |
| category_jobs | heavily-simplified | L | 12 | rich card + count/sort toolbar + alert action lost |
| job_preview | heavily-simplified | L | 11 | rich sections lost |
| job_edit | moderately-simplified | M | 8 | |
| phone_auth | heavily-simplified | M | 8 | layout/copy |
| categories | heavily-simplified | M | 8 | visual |
| **mypage** | minor-diff | S | 1 | rating/review row — **needs `rating/reviewCount` (absent) → omit under (a) → no-op** |
| **splash** | minor-diff | S | 0 | only diff is the auth-redirect we keep → **already at parity → no-op** |

### Gap categories (all screens)
data-display 47 · interaction 43 · navigation 15 · visual 14 · layout 10 · copy 9 · empty-state 4 · animation 1

### Cross-cutting themes (element → #screens)
status badge (6), chip (6), bottom sheet (5), dialog (5), search (4), snackbar (4), checklist (3), tab (3), template (2), carousel (2), empty state (2). → favors **shared widgets** over per-screen reimplementation.

## 3. Restoration Principle (3-Tier) + Data Policy

- **Tier 1 — restore now:** UI that works on existing data or local state (bottom sheets, pickers, chips, empty states, layout, copy, client-side sort/filter on existing fields). The majority.
- **Tier 2 — restore layout, gate the data:** where the mockup element needs a field the API lacks → restore the visual shell, **bind real data if present, otherwise omit** (policy **(a)**). Never backfill with dummy data.
- **Tier 3 — defer (= goal B, M4+):** elements implying a backend *action* that doesn't exist (messaging, safe-number call, auto-hire, similar-jobs endpoint, draft persistence, address geocoding) → omit or "준비 중", catalogued for later.

**Consequence of (a):** wired list/detail screens render **leaner than the mockup** — `sameDayPayment`, `payType`, `personnel`, `hiredCount`, `tags`, `rating`, `distance` are omitted because the backend (`api.Job`, `Application`, `Profile`) has no such fields. `splash` and `mypage` need **no code** under (a).

## 4. Decomposition (R0 → R3)

Each milestone is its own spec→plan→build cycle, following the project's M-cadence (TDD + multi-agent review per `feedback_dev_process.md`; preserve all "backend-to-preserve" items and widget-test `Key`s).

- **R0 (this spec, detailed):** `ApiJobCard` foundation + **`category_jobs`** proof consumer. `splash`/`mypage` documented no-op. Validates the card pattern, the (a) omit-policy, backend-preservation, and the TDD/build loop on a thin slice.
- **R1 — Worker discovery:** `worker_home`, `search`, `categories`, `job_info` (reuse `ApiJobCard`; add optional cover-photo support to the card; restore Tier-1 chrome: search bar, filter/sort, empty/loading states, rich detail header).
- **R2 — Giver management:** `giver_home`, `job_create`, `job_edit`, `job_preview`, `applicants` (heaviest — Tier-1 bottom sheets/pickers/dialogs; many Tier-2 omits).
- **R3 — Auth & polish:** `phone_auth`, residual polish, and (optional, separate) **fix the broken Pages web build** (declare `.env` optional or provide a CI dummy so the mockup deploy unfreezes).

## 5. R0 — Detailed Design

**Files touched:** add `lib/widgets/api_job_card.dart`; modify `lib/screens/categories/category_jobs_screen.dart`; add/extend their widget tests. **No backend, no model, no router changes.**

### 5.1 `ApiJobCard` (new shared widget)

Reproduces the mockup `JobCard` (`shared.dart:48`) layout on `api.Job`, omitting absent fields per (a). The legacy `JobCard` stays untouched (still used by 4 dummy-data screens: giver_home `_GiverJobCard`, job_boost, recommended, history).

- `ApiJobCard({required api.Job job, VoidCallback? onTap})` — `Card > InkWell(radius 14) > Padding(14) > Column(crossStart)`:
  1. `Row`: `Expanded(Text(job.title, 15/w700, maxLines 1, ellipsis))` — *(omit `당일지급` chip — no `sameDayPayment`)*
  2. `SizedBox(6)`; `Row`: `Icon(location_on_outlined,14,textMuted) + SizedBox(2) + Expanded(Text(job.locationAddress,12 textMuted,ellipsis))` — *(omit distance — no lat/lng)*
  3. `if (job.scheduleText?.trim().isNotEmpty == true)`: `SizedBox(4)`; `Row`: `Icon(access_time,14,textMuted) + SizedBox(2) + Expanded(Text(job.scheduleText!,12 textMuted,ellipsis))` — *(scheduleText replaces structured `fmtDate·fmtTime~fmtTime`)*
  4. `SizedBox(10)`; `Row`: `Flexible(Text(fmtMoney(job.wageWon), 15/w700, brandDark, ellipsis))` — *(omit `payType` prefix and `hiredCount/personnel` — no such fields)*
  - *(omit tag `Wrap` — no `tags`)*
- Reuse `fmtMoney` (defined in `lib/widgets/shared.dart`) and `AppColors` (`lib/theme/app_theme.dart`); import, do not duplicate.
- **No cover-photo param in R0** (kept minimal; R1 adds an optional `coverPhotoUrl` so giver_home/worker_home can preserve their wired thumbnail).
- **Tests** (`test/widgets/api_job_card_test.dart`, TDD-first): renders title/location/pay; shows schedule row only when `scheduleText` non-empty/non-null; `onTap` fires; no crash when `scheduleText == null` and `photos`/`giver` empty.

### 5.2 `category_jobs_screen.dart` restore

Keep ALL current backend wiring; restore mockup chrome.

- **Preserve (must not regress):** `jobRepository` DI (`?? JobRepository.fromApi()`); `_repo.listJobs(category: categoryId)` returning `({items, total})`; `FutureBuilder` loading (`CircularProgressIndicator`) and error (`'연결이 불안정합니다'`) states; `api.Job` binding; String-id nav `context.push('/job/${j.id}')`.
- **Restore (Tier 1):**
  - AppBar `actions: [IconButton(Icons.notifications_active_outlined, tooltip '이 카테고리 알림 받기', onPressed: () => context.push('/me/saved-searches/new'))]`.
  - Success body = `Column`: header `Row` (white, padded) `Text('${total}건', 13/bold) + Spacer + DropdownButton(_sort)`; `Divider(height:1)`; `Expanded(ListView.separated(padding: EdgeInsets.all(16), separatorBuilder: SizedBox(height:10), itemBuilder: ApiJobCard(job:item, onTap: …)))`.
  - **Sort under (a):** options **`최신순` (default, `createdAt` desc)** and **`시급순` (`wageWon` desc)**, applied client-side over the loaded page. **Drop `거리순`** (no distance) — documented (a)-deviation; mockup's default `거리순` becomes `최신순`.
  - Empty state → existing `EmptyState(icon: Icons.work_off_outlined, '아직 이 카테고리에 공고가 없어요')` (verbatim mockup copy).
- **Tests:** extend/add `test/screens/category_jobs_screen_test.dart` — loading/error/empty/success branches; `ApiJobCard` rendered per item; sort toggle reorders; AppBar alert action navigates; preserve any existing `Key`s.

### 5.3 `splash` / `mypage` — documented no-op under (a)

- `splash`: 0 gaps; mockup unconditional `/onboarding` vs current session-checked `/worker`|`/onboarding` is the auth-redirect we keep. Visually identical → **no change.**
- `mypage`: sole gap is the gold-star `rating · 리뷰 N개` row, which needs `rating`/`reviewCount` — **absent from `Profile`** → omit under (a) → **no change.** (Revisit if R-light-up / goal B adds review data.)

## 6. Testing & Verification

- **TDD** (tests first) per `feedback_dev_process.md`; multi-agent review (Code Reviewer; UI Designer/UX Architect for restored UI). Security Engineer not required (no auth/payment/LLM surface; per `feedback_security_review.md`).
- Preserve every existing widget-test `Key`; keep `flutter test` and `flutter analyze` green (no new issues); `flutter build ios --simulator` smoke.
- **Verification anchor:** each restored screen is checked against the `ae2466d` widget tree (`git show ae2466d:<path>`); optional `git worktree` build of `ae2466d` for live visual reference.

## 7. Out of Scope / Risks

- **Broken Pages deploy** (`.env` asset) — separate cheap fix, parked in R3.
- **R1–R3 detail deferred** to their own specs.
- **(a) leanness risk:** stakeholders may later want the omitted fields populated — that is the bounded "light-up" step toward goal B (add nullable columns + projection), explicitly out of scope here.
- Legacy `JobCard`/`dummy_data.dart` remain live for the 67 untouched screens — do **not** delete or repurpose them during R0–R3.
