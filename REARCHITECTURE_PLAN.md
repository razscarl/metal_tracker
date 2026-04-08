# Metal Tracker v6 — Rearchitecture Plan

> Generated: 2026-03-12
> Status: Planning — do not implement until reviewed and approved section-by-section.

---

## Overview of Changes

The core shift is from a **single-user siloed model** (every table filtered by `user_id`) to a **platform model** with:

- **Global shared data** (retailers, live prices, local spot, product profiles, product listings) managed by admins and read by all users.
- **User-owned data** (holdings, user preferences, analytics tolerances) private to each user.
- **User-contributed data** (global spot prices contributed by users who have an API key, visible to all).
- **Role-based access**: `User` and `Administrator`.
- **Request system**: users submit change requests that admins action.

---

## Phase 0 — Database Schema (Supabase)

> These changes must be done in Supabase first before any Flutter code changes.
> They are the foundation for everything else.

### 0.1 New Tables

#### `user_profiles`
Stores extended user information and role flags.

```sql
create table user_profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text not null,
  phone        text,
  is_admin     boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
-- RLS: user can read/update own row; admins can read all rows; only admins can update is_admin
```

#### `user_live_price_prefs`
Which retailer+metal combinations the user has selected for live prices.

```sql
create table user_live_price_prefs (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  retailer_id  uuid not null references retailers(id) on delete cascade,
  metal_type   text,          -- null = all metals for this retailer
  is_active    boolean not null default true,
  unique (user_id, retailer_id, metal_type)
);
-- RLS: user can CRUD own rows only
```

#### `user_local_spot_prefs`
Which retailer+metal combinations the user has selected for local spot prices.

```sql
create table user_local_spot_prefs (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  retailer_id  uuid not null references retailers(id) on delete cascade,
  metal_type   text,          -- null = all metals for this retailer
  is_active    boolean not null default true,
  unique (user_id, retailer_id, metal_type)
);
-- RLS: user can CRUD own rows only
```

#### `user_global_spot_prefs`
The user's configured global spot price API provider (one active per user for regular users; admins may have multiple).

```sql
create table user_global_spot_prefs (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  provider_key  text not null,   -- 'metalpriceapi' | 'metals_dev'
  api_key       text not null,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
-- RLS: user can CRUD own rows only
```

> **Note:** This replaces `global_spot_price_api_settings`. Migration needed.

#### `global_spot_providers`
Admin-managed registry of available global spot price providers.

```sql
create table global_spot_providers (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,          -- 'Metal Price API'
  provider_key  text not null unique,   -- 'metalpriceapi'
  base_url      text,
  description   text,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);
-- RLS: anyone authenticated can read; only admin can write
-- Seed: insert 'metalpriceapi' and 'metals_dev' rows
```

#### `user_analytics_settings`
Per-user tolerance configuration for analytics screens. One row per user, upserted.

```sql
create table user_analytics_settings (
  user_id                  uuid primary key references auth.users(id) on delete cascade,
  -- Gold-Silver Ratio
  gsr_low_mark             numeric not null default 60.0,
  gsr_high_mark            numeric not null default 70.0,
  gsr_low_text             text not null default 'Buy Silver',
  gsr_high_text            text not null default 'Buy Gold',
  gsr_mid_text             text not null default 'Hold',
  -- Local Premium
  lp_low_mark              numeric not null default -2.0,
  lp_high_mark             numeric not null default 2.0,
  lp_low_text              text not null default 'Buy Now',
  lp_high_text             text not null default 'Avoid',
  lp_mid_text              text not null default 'Neutral',
  -- Dealer Spread — Gold
  spread_gold_buy_pct      numeric not null default 2.0,
  spread_gold_hold_pct     numeric not null default 5.0,
  -- Dealer Spread — Silver
  spread_silver_buy_pct    numeric not null default 10.0,
  spread_silver_hold_pct   numeric not null default 20.0,
  -- Dealer Spread — Platinum
  spread_plat_buy_pct      numeric not null default 25.0,
  spread_plat_hold_pct     numeric not null default 35.0,
  updated_at               timestamptz not null default now()
);
-- RLS: user can read/upsert own row only
```

#### `change_requests`
Users submit requests for changes that admins then action.

```sql
create table change_requests (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  request_type    text not null,   -- see enum below
  subject         text not null,
  description     text,
  status          text not null default 'pending',  -- pending|in_progress|completed|rejected
  admin_notes     text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
-- RLS: user can insert + read own rows; admin can read/update all rows
```

**`request_type` values:**
- `new_retailer` — request a new retailer be added
- `change_retailer` — request change to existing retailer config
- `new_live_price_retailer` — request live price config for a retailer
- `change_live_price_retailer` — request change to live price config
- `new_local_spot_retailer` — request local spot config for a retailer
- `change_local_spot_retailer`
- `new_global_spot_provider` — request a new global spot API provider
- `change_global_spot_provider`
- `new_product_listing_retailer`
- `change_product_listing_retailer`
- `change_product_profile` — request edit/delete of a product profile
- `new_analytics` — request a new analytics view
- `change_analytics`
- `admin_access` — request administrator privileges
- `remove_admin_access` — request own admin privileges be removed
- `other`

---

### 0.2 Tables to Modify

#### `product_profiles` — Remove user_id from queries
- The column stays in the table for now (backward compat).
- RLS change: **read = any authenticated user; write = admin only**.
- All existing rows: set `user_id = null` or keep as-is (data migration TBD).
- Flutter repositories: remove `.eq('user_id', ...)` from all read queries.
- Flutter repositories: admin-only write operations gated at app layer.

#### `live_prices` — Remove user_id from queries
- Same pattern: keep column, change RLS.
- Read: any authenticated user.
- Write (insert from scrape): admin only.
- Manual entry: admin only.
- Flutter: remove user_id filter from reads; admin gate on writes.

#### `spot_prices` — Split RLS by source_type
- `source_type = 'local_scraper'`: read = any authenticated; write = admin only.
- `source_type = 'global_api'`: read = any authenticated; write = `user_id = current user`.
- Spot prices from any user's API key are visible to everyone.

#### `retailers` — Remove user_id from queries
- Read: any authenticated user.
- Write: admin only.

#### `retailer_scraper_settings` — Remove user_id from queries
- Read: any authenticated user (all including inactive? — show active to users, all to admin).
- Write: admin only.

#### `global_spot_price_api_settings` — Migrate to `user_global_spot_prefs`
- Data migration: copy rows to `user_global_spot_prefs`.
- Drop old table after migration and code cutover.

---

### 0.3 RLS Policy Summary

| Table | User Read | User Write | Admin Read | Admin Write |
|---|---|---|---|---|
| holdings | own rows | own rows | own rows | own rows |
| product_profiles | all rows | none (create only) | all rows | all rows |
| live_prices | all rows | none | all rows | all rows |
| spot_prices (local) | all rows | none | all rows | all rows |
| spot_prices (global) | all rows | own rows | all rows | all rows |
| retailers | all rows | none | all rows | all rows |
| retailer_scraper_settings | active rows | none | all rows | all rows |
| global_spot_providers | all rows | none | all rows | all rows |
| user_profiles | own row | own row | all rows | all rows |
| user_live_price_prefs | own rows | own rows | — | — |
| user_local_spot_prefs | own rows | own rows | — | — |
| user_global_spot_prefs | own rows | own rows | — | — |
| user_analytics_settings | own row | own row | — | — |
| change_requests | own rows | own rows (insert) | all rows | all rows |

> **Admin detection**: `is_admin` in `user_profiles`. This is checked at the app layer via `userProfileProvider`. Supabase RLS admin policies use a helper function `is_admin()` that reads `user_profiles.is_admin` for the current user.

---

## Phase 1 — Core Infrastructure (Flutter)

### 1.1 User Profile Model & Repository

**New file**: `lib/features/settings/data/models/user_profile_model.dart`

```dart
class UserProfile {
  final String id;        // = auth user id
  final String username;
  final String? phone;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**New file**: `lib/features/settings/data/repositories/user_profile_repository.dart`
- `getProfile(userId)` → `UserProfile`
- `upsertProfile(UserProfile)` → `UserProfile`
- `checkProfileExists(userId)` → `bool`

### 1.2 User Preferences Models & Repository

**New file**: `lib/features/settings/data/models/user_prefs_models.dart`

```dart
class UserLivePricePref   { String retailerId; String? metalType; bool isActive; }
class UserLocalSpotPref   { String retailerId; String? metalType; bool isActive; }
class UserGlobalSpotPref  { String id; String providerKey; String apiKey; bool isActive; }
class UserAnalyticsSettings { /* all tolerance fields with defaults */ }
```

**New file**: `lib/features/settings/data/repositories/user_prefs_repository.dart`
- `getLivePricePrefs()` → `List<UserLivePricePref>`
- `setLivePricePrefs(List<UserLivePricePref>)` — replace all for user
- `getLocalSpotPrefs()` → `List<UserLocalSpotPref>`
- `setLocalSpotPrefs(List<UserLocalSpotPref>)`
- `getGlobalSpotPrefs()` → `List<UserGlobalSpotPref>` (multiple for admin, one for user)
- `upsertGlobalSpotPref(UserGlobalSpotPref)`
- `deleteGlobalSpotPref(String id)`
- `getAnalyticsSettings()` → `UserAnalyticsSettings`
- `upsertAnalyticsSettings(UserAnalyticsSettings)`

### 1.3 Global Spot Providers Repository

**New file**: `lib/features/spot_prices/data/repositories/global_spot_providers_repository.dart`
- `getProviders()` → `List<GlobalSpotProvider>`
- `getActiveProviders()` → `List<GlobalSpotProvider>`
- `createProvider(GlobalSpotProvider)` — admin only
- `updateProvider(GlobalSpotProvider)` — admin only
- `deleteProvider(String id)` — admin only

### 1.4 Change Request Model & Repository

**New file**: `lib/features/admin/data/models/change_request_model.dart`

```dart
class ChangeRequest {
  final String id;
  final String userId;
  final String requestType;
  final String subject;
  final String? description;
  final String status;  // pending|in_progress|completed|rejected
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**New file**: `lib/features/admin/data/repositories/change_request_repository.dart`
- `submitRequest(ChangeRequest)` — user
- `getMyRequests()` — user sees own
- `getAllRequests({String? status})` — admin only
- `updateRequest(ChangeRequest)` — admin only (status + admin_notes)

### 1.5 Core Providers

**Update**: `lib/core/providers/repository_providers.dart`
- Add providers for all new repositories.

**New file**: `lib/features/settings/presentation/providers/user_profile_provider.dart`

```dart
@riverpod
Future<UserProfile?> userProfile(Ref ref) async { ... }

@riverpod
Future<bool> isAdmin(Ref ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.isAdmin ?? false;
}

@riverpod
Future<UserAnalyticsSettings> userAnalyticsSettings(Ref ref) async { ... }

@riverpod
Future<List<UserLivePricePref>> userLivePricePrefs(Ref ref) async { ... }

@riverpod
Future<List<UserLocalSpotPref>> userLocalSpotPrefs(Ref ref) async { ... }

@riverpod
Future<UserGlobalSpotPref?> activeUserGlobalSpotPref(Ref ref) async { ... }
```

> Run `build_runner` after creating annotated providers.

---

## Phase 2 — Auth & Onboarding

### 2.1 Auth Flow Changes

**Current flow**: Sign in → Home | Sign up → Home
**New flow**:

```
Sign in (any method) ──→ profile exists? ──Yes──→ Home
                                        └──No───→ Onboarding

Sign up (email/pass) ──→ Onboarding
Sign up (Google/Apple) ──→ Onboarding (profile created from OAuth data)
```

**`auth_wrapper.dart` changes**:
- After successful auth, call `userProfileRepository.checkProfileExists(userId)`.
- If false → navigate to `OnboardingScreen`.
- If true → navigate to `HomeScreen`.

### 2.2 Onboarding Screen

**New file**: `lib/features/auth/presentation/screens/onboarding_screen.dart`

Multi-step wizard (`PageView` or `Stepper`):

**Step 1 — Profile**
- Username (required)
- Phone (optional)

**Step 2 — Live Price Retailers**
- List of retailers with active live price scraper settings.
- Each entry: Retailer name + Metal (e.g., "Gold Secure — Gold").
- Multi-select checkboxes.
- "Select All" / "Clear All".

**Step 3 — Local Spot Retailers**
- Same pattern as Step 2 but for local_spot scraper type.

**Step 4 — Global Spot Provider**
- Informational message: _"To generate Global Spot Prices you will need an account with a provider and an API Key. The prices you capture will be shared across the Metal Tracker platform."_
- Dropdown: Select provider (from `global_spot_providers` table) or "Skip for now".
- If provider selected: API Key text field.

**Step 5 — Done**
- Summary of selections.
- "Get Started" → saves profile + prefs → navigates to `HomeScreen`.

### 2.3 Auth Screen Minor Changes

- Already has Google and Apple buttons — confirm these work (they exist in `auth_screen.dart`).
- Ensure sign-up with email/password routes to Onboarding.
- Email prefill from `savedEmailProvider` already exists — no change needed.

---

## Phase 3 — Settings Screen (Full Rebuild)

**Current state**: `features/settings/` has GSR settings only.
**New state**: Full multi-section settings screen.

**New file**: `lib/features/settings/presentation/screens/settings_screen.dart`

Use a `ListView` with expandable `ExpansionTile` sections or a dedicated screen per section with `ListTile` navigation rows (preferred for mobile).

### 3.1 Profile Section

`lib/features/settings/presentation/screens/profile_settings_screen.dart`

- Username (editable)
- Email (editable — calls Supabase `updateUser`)
- Password (change password flow)
- Phone (editable)
- "Request Administration Access" button → submits `change_request` of type `admin_access`
- Admin only: "Request Removal of Administration Access" → type `remove_admin_access`

### 3.2 Live Price Retailers Section

`lib/features/settings/presentation/screens/live_price_prefs_screen.dart`

- Checklist of all active live price retailer+metal combinations.
- Pre-selected based on current `user_live_price_prefs`.
- Save button → calls `setLivePricePrefs`.
- "Request New Retailer" → submits `change_request` of type `new_live_price_retailer`.

### 3.3 Local Spot Retailers Section

`lib/features/settings/presentation/screens/local_spot_prefs_screen.dart`

- Same pattern as Live Price section but for local spot.

### 3.4 Global Spot Provider Section

`lib/features/settings/presentation/screens/global_spot_pref_screen.dart`

- Dropdown: list of active providers from `global_spot_providers`.
- API Key field.
- Save / Update / Remove buttons.
- Admin: can have multiple — show list with add/remove capability.
- "Request New Provider" → submits `change_request` of type `new_global_spot_provider`.

### 3.5 Analytics Section

`lib/features/settings/presentation/screens/analytics_settings_screen.dart`

- GSR: low mark, low mark text, high mark, high mark text, mid range text.
- Local Premium: same 5 fields.
- Dealer Spread — Gold: buy threshold %, hold threshold %.
- Dealer Spread — Silver: same.
- Dealer Spread — Platinum: same.
- All numeric fields have `TextEditingController` with decimal input.
- Save → `upsertAnalyticsSettings`.
- Reset to Defaults button.

### 3.6 Administration Section (admin only)

Only visible when `isAdmin = true`.

`lib/features/settings/presentation/screens/admin_settings_screen.dart`

- Link → "View Change Requests" (admin request queue screen).
- Admin-managed global settings (TBD — placeholder for now).

---

## Phase 4 — Role-Based Access

### 4.1 `isAdminProvider`

All screens that need role gating watch `isAdminProvider`. This is an `AsyncValue<bool>`. Handle loading/error states gracefully (default to `false` on error).

### 4.2 App Drawer

`lib/core/widgets/app_drawer.dart` changes:

- Add "Settings" nav item (currently missing or placeholder).
- Add "Administration" section at bottom — only visible when `isAdmin = true`.
  - Admin Dashboard / Requests

### 4.3 Admin-Gated UI Elements

Each screen section below notes which elements are admin-only. Common pattern:

```dart
final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
if (isAdmin) ... show admin widget ...
```

---

## Phase 5 — Screen Updates

### 5.1 Home Screen (`home_screen.dart`)

**Provider changes** (`home_providers.dart`):

- `homeBestPricesProvider` — add `userLivePrefs` parameter filter.
  Filter logic: `live_price.retailer_id IN user_live_price_prefs.retailer_id WHERE user_id = currentUser`.
- `homeRecentLivePricesProvider` — same filter.
- `homeLocalSpotPricesProvider` — filter by `user_local_spot_prefs`.
- `homeGlobalSpotPricesProvider` — if user has active `user_global_spot_prefs`, filter by `source = user's provider name`; else show most recent from any source.

These filtered providers consume `userLivePricePrefsProvider` and `userLocalSpotPrefsProvider` via `ref.watch`.

**UI changes**: None structural. Data will naturally update when providers filter.

### 5.2 Live Prices Screen (`live_prices_screen.dart`)

- **Remove** fetch all button (admin-only → move to admin UI or admin-gated).
- **Auto-apply** retailer filter from `userLivePricePrefsProvider` on screen load.
- Retain manual filter override capability (user can still view any retailer by changing filter).
- Add "Request New Retailer" `TextButton` or `OutlinedButton` in app bar or body.
- Admin only: show fetch button.

### 5.3 Spot Prices Screen (`spot_prices_screen.dart`)

- **Merge** date + time into single column: format as `d MMM HH:mm` (already done on home screen; replicate here).
- **Auto-apply** local spot filter from `userLocalSpotPrefsProvider`.
- **Auto-apply** global spot filter from `activeUserGlobalSpotPrefProvider` (if set).
- Allow manual override of filters.
- **Remove** "Fetch Local Spot" button for non-admins.
- **Keep** "Fetch Global Spot" button for all users who have a configured provider.
- "Fetch Global Spot" triggers fetch using `activeUserGlobalSpotPref.providerKey + apiKey`.
- Admin: show all fetch buttons; can fetch all active local spot services.
- Add "Request new local spot retailer" and "Request new global spot provider" links.

### 5.4 Holdings Screen (`holdings_screen.dart`)

- Already user-specific via `user_id` filter — no query changes.
- Portfolio valuation: update `portfolioValuationProvider` to filter best prices by `user_live_price_prefs`.
- Edit Holding: allow user to create new Product Profile (already exists) + add "Request change to profile" button when viewing an existing profile.

### 5.5 Product Profiles Screen (`product_profiles_screen.dart`)

- **Remove** `user_id` filter from repository read query → show all profiles.
- **Keep** create button (user can create new profiles).
- **Replace** edit/delete buttons with "Request Change" button for regular users.
- Admin: show full edit + delete buttons.
- "Request Change" → opens `ChangeRequestDialog` pre-filled with profile details.

### 5.6 Retailers Screen → Retailers & Providers Screen

`lib/features/retailers/presentation/screens/retailers_screen.dart` restructure:

- Wrap in `DefaultTabController` with 2 tabs: **Retailers** | **Global Spot Providers**.

**Retailers Tab**:
- Show all retailers with their scraper settings grouped (Live Price / Local Spot / Product Listing).
- Read-only for users.
- "Request New Retailer" button (FAB or app bar action).
- "Request Change" per retailer row.
- Admin: show add/edit/delete buttons as now.

**Global Spot Providers Tab**:
- List all `global_spot_providers` from DB.
- For each: name, description, website link.
- "Request New Provider" button.
- "Request Change" per provider row.
- Admin: show add/edit/delete buttons.

### 5.7 Analytics Screens

- All analytics providers consume `userAnalyticsSettingsProvider` for thresholds instead of hardcoded values.
- `gsrHistoryProvider` — use `userAnalyticsSettings.gsrLowMark` / `gsrHighMark` for guide calculation.
- `localPremiumHistoryProvider` — use `userAnalyticsSettings.lpLowMark` / `lpHighMark`.
- `dealerSpreadHistoryProvider` — use per-metal spread thresholds from settings.
- Filter data by user's selected retailers where applicable.
- Add "Request New Analytics" button on analytics screen.

---

## Phase 6 — Request System UI

### 6.1 Reusable `ChangeRequestDialog`

`lib/features/admin/presentation/widgets/change_request_dialog.dart`

```dart
showChangeRequestDialog(context, {
  required String requestType,
  String? prefillSubject,
  String? prefillDescription,
})
```

- Shows a `showModalBottomSheet` or `AlertDialog`.
- Subject field (pre-filled if provided).
- Description field (free text).
- Submit → calls `changeRequestRepository.submitRequest(...)`.
- Shows success/error snackbar.

Used from: Live Prices, Spot Prices, Product Profiles, Retailers, Analytics, Settings.

### 6.2 Admin Request Queue Screen

`lib/features/admin/presentation/screens/admin_requests_screen.dart`

- List of all `change_requests` with filter tabs: **All | Pending | In Progress | Completed | Rejected**.
- Each row: request type badge, subject, submitter (username from user_profiles), date.
- Tap → `AdminRequestDetailScreen`:
  - Full request details.
  - Status dropdown (pending → in_progress → completed | rejected).
  - Admin notes field.
  - Save button.

### 6.3 Admin Dashboard

`lib/features/admin/presentation/screens/admin_dashboard_screen.dart`

- Pending requests count badge.
- Quick links: Requests, Retailers, Live Prices (fetch), Spot Prices (fetch).

---

## Phase 7 — Admin-Only Fetch Flows

### 7.1 Live Price Fetch (Admin)

Currently the fetch button is in the Live Prices screen. Keep it but gate behind `isAdmin`.

Admin sees: Fetch button → triggers `LivePricesNotifier.scrapeAll()` → shows results dialog (unchanged).

### 7.2 Local Spot Fetch (Admin)

Same pattern — fetch button in Spot Prices screen, admin-gated.

Admin fetch: all active local spot scraper settings regardless of admin's own prefs.

### 7.3 Global Spot Fetch (All users with provider configured)

User fetch: uses `activeUserGlobalSpotPref` (single provider, single API key).
Admin fetch: iterates all active entries in `user_global_spot_prefs` where `user_id = adminId` (admin can have multiple).

The saved `spot_prices` row records `user_id = fetchingUser` but is visible to all.

---

## Phase 8 — Migration Steps

These must be done carefully, table by table, to avoid breaking the live app.

1. **Create new tables** (Phase 0.1) — additive, no breakage.
2. **Seed `global_spot_providers`** with metalpriceapi and metals_dev rows.
3. **Migrate `global_spot_price_api_settings` → `user_global_spot_prefs`** — copy data, update Flutter code, then drop old table.
4. **Update RLS on existing tables** — change read policies to allow all authenticated users. Tighten write policies.
5. **Update Flutter repositories** — remove `user_id` filter from global-data reads.
6. **Create user_profiles for existing users** — run a one-time script or handle gracefully in AuthWrapper (if no profile exists, redirect to onboarding).
7. **Migrate settings from SharedPreferences → `user_analytics_settings`** — read from Supabase first; fall back to SharedPreferences defaults on first load.

---

## Phase 9 — File Structure (New Files)

```
lib/
  features/
    admin/
      data/
        models/
          change_request_model.dart
        repositories/
          change_request_repository.dart
      presentation/
        providers/
          admin_providers.dart
          admin_providers.g.dart
        screens/
          admin_dashboard_screen.dart
          admin_requests_screen.dart
          admin_request_detail_screen.dart
        widgets/
          change_request_dialog.dart
          request_status_badge.dart
    settings/
      data/
        models/
          user_profile_model.dart
          user_prefs_models.dart
          user_analytics_settings_model.dart
        repositories/
          user_profile_repository.dart
          user_prefs_repository.dart
          user_analytics_settings_repository.dart
      presentation/
        providers/
          user_profile_providers.dart
          user_profile_providers.g.dart
          user_prefs_providers.dart
          user_prefs_providers.g.dart
          settings_providers.dart        ← extend existing
        screens/
          settings_screen.dart           ← replace existing
          profile_settings_screen.dart
          live_price_prefs_screen.dart
          local_spot_prefs_screen.dart
          global_spot_pref_screen.dart
          analytics_settings_screen.dart
    spot_prices/
      data/
        models/
          global_spot_provider_model.dart
        repositories/
          global_spot_providers_repository.dart
    auth/
      presentation/
        screens/
          onboarding_screen.dart
```

---

## Phase 10 — Implementation Order

Given dependencies, implement in this order:

| # | Phase | Prerequisite |
|---|---|---|
| 1 | Database schema (Phase 0) | Nothing |
| 2 | Core models & repositories (Phase 1.1–1.4) | Phase 0 |
| 3 | Core providers (Phase 1.5) | Phase 1.1–1.4 |
| 4 | Auth & Onboarding (Phase 2) | Phase 1.5 |
| 5 | Settings screen (Phase 3) | Phase 1.5 |
| 6 | Role-based access in drawer + isAdmin provider (Phase 4) | Phase 1.5 |
| 7 | Home screen provider updates (Phase 5.1) | Phases 1.5 + 3 |
| 8 | Live Prices screen (Phase 5.2) | Phase 4 |
| 9 | Spot Prices screen (Phase 5.3) | Phases 4 + 3.4 |
| 10 | Holdings screen updates (Phase 5.4) | Phase 5.1 |
| 11 | Product Profiles screen (Phase 5.5) | Phase 6.1 |
| 12 | Retailers & Providers screen (Phase 5.6) | Phase 6.1 |
| 13 | Analytics updates (Phase 5.7) | Phase 3.5 |
| 14 | Request system UI (Phase 6) | Phase 1.4 |
| 15 | Admin screens (Phase 6.2–6.3) | Phases 4 + 6 |
| 16 | Admin fetch flows (Phase 7) | Phases 4 + 6 |
| 17 | Data migration (Phase 8) | All above |

---

## Decisions Log

| # | Question | Decision |
|---|---|---|
| 1 | How does the first admin get created? | **Manually via Supabase dashboard** — set `user_profiles.is_admin = true` directly. ✅ |
| 2 | Product Profile `user_id` after going global? | **Keep column for audit trail; remove from all read queries.** ✅ |
| 3 | Global spot prices — expose `user_id` in UI? | **No** — store internally; UI shows only provider name (`source` field). ✅ (default applied) |
| 4 | Can users skip onboarding? | **Yes** — Steps 2–4 have "Skip" option; user sees unfiltered data until prefs set. ✅ |
| 5 | Product Listing tab on Retailers screen? | **Show with "Coming Soon" badge** — greyed out, not interactive. ✅ (default applied) |
| 6 | Admin notifications for change requests? | **Out of scope** — badge count on admin drawer item is sufficient for now. ✅ (default applied) |
| 7 | What `user_id` inserted when user creates a product profile? | **The creating user's `user_id`** as `created_by` reference; read queries ignore it. ✅ (default applied) |
| 8 | Session timeout — keep 15 min idle lock? | **Yes, unchanged.** ✅ (default applied) |

---

## What Stays the Same

- All scraping logic (GBA, GS, IMP services).
- Base scraper service.
- All existing data models' internal fields (schema additions only, no removals).
- Portfolio valuation calculation logic.
- Neumorphic UI component library.
- Dark theme.
- Holdings CRUD flows.
- Supabase auth email/password + Google/Apple (already implemented in auth_screen.dart).
