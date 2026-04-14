# Metal Tracker v6 — Beta Release Checklist

> Track progress by marking items [ ] → [x] as completed.
> Phases 1–6 = minimum viable beta. Phases 7–11 = important but not blockers.

---

## Redundant Code Cleanup (do alongside phases, not separately)

- [x] **[ARCH]** Migrate legacy `lib/features/scrapers/` folder — move methods to feature repos, update all callers, remove `scraperRepositoryProvider` from core, delete folder
- [x] **[ARCH]** Delete `lib/features/live_prices/presentation/screens/live_price_mapping_screen.dart` (superseded by mapping_screen.dart)
- [x] **[ARCH]** Migrate `UserMetalTypesNotifier` and `UserRetailersNotifier` in `user_prefs_providers.dart` from manual `AsyncNotifierProvider` to `@Riverpod(keepAlive: true)` + run build_runner
- [x] **[ARCH]** Consolidate best price logic — remove duplicate implementations between `live_prices_repository.dart` and `holdings_providers.dart`

---

## Phase 1 — Critical Bug Fixes ⚠️ BETA BLOCKERS

### 1.1 — Timezone / TimeService
- [x] Create `lib/core/utils/time_service.dart` with `TimeService.parseUtc(String iso)` static helper
- [x] Fix `lib/features/product_listings/data/models/product_listing_model.dart` — add `.toLocal()` to `scrapeDate` and `scrapeTimestamp` parsing
- [x] Audit all `data/models/` files for any remaining `DateTime.parse()` without `.toLocal()`
- [x] Verify footer shows correct local times for Listings, Global Spot, Local Spot (#19.b, #19.c, #19.d)
- [x] Verify home screen local/global spot "last updated" shows local time (#8.d.i, #8.e.i)

### 1.2 — Best Price Calculation Fix
- [x] Rewrite `_getBestPrice()` in `lib/features/live_prices/data/repositories/live_prices_repository.dart`:
  - For each retailer: find their max `captureTimestamp`
  - Find the most recent `captureDate` across all retailers' max timestamps
  - Exclude retailers whose max timestamp is NOT on that date
  - For included retailers, use only their max-timestamp records
  - Return best sell/buyback across filtered set (normalised to $/pure oz)
- [x] Ensure returned `MetalBestPrices` includes retailer abbreviation
- [x] Apply same per-retailer-latest logic to `bestBuybackForMetal()` in `holdings_providers.dart`
- [x] Add retailer abbreviation display below each best price in `_BestPricesBar` (#8.a.iii.2)

### 1.3 — Home: Portfolio No-Holdings Empty State
- [x] Show "You have no holdings to value. Add your first holding on the Holdings page." with nav button when portfolio is empty (#8.b.i)

### 1.4 — Analytics Settings Wiring
- [x] Rename `dealer_spread_screen.dart` → `local_spread_screen.dart`; rename class `DealerSpreadScreen` → `LocalSpreadScreen`; rename all internal "dealer" references to "local" in code (variables, functions, comments)
- [x] `lib/features/analytics/presentation/screens/local_spread_screen.dart` — delete hardcoded `_buyThresholds`/`_holdThresholds`, convert `_InfoCard` to `ConsumerWidget`, read from `userAnalyticsSettingsNotifierProvider`
- [x] `lib/features/analytics/presentation/screens/local_premium_screen.dart` — convert `_InfoCard` to `ConsumerWidget`, replace hardcoded "≥2%"/"<0%"/"0-2%" with settings values (`lpLowMark`, `lpHighMark`, `lpLowText`, `lpHighText`, `lpMidText`)
- [x] Verify `_SpreadChart` threshold line positions and colours use settings values
- [x] Verify analytics summary cards on `analytics_screen.dart` display correct setting-driven values

### 1.5 — Analytics Settings Reset Fix
- [x] `lib/features/settings/data/repositories/user_prefs_repository.dart` — `upsertAnalyticsSettings()` must return `UserAnalyticsSettings` (not void); upsert then re-fetch
- [x] `UserAnalyticsSettingsNotifier.reset()` — verify it triggers a visible UI refresh
- [x] Confirm reset button works end-to-end (#18.e.viii)

---

## Phase 2 — Architecture Cleanup

### 2.1 — Remove Legacy Scrapers Folder
> **⚠ NOTE:** Only migrate methods that are called FROM feature repos/screens. Do NOT duplicate or overwrite any functions already working correctly in `live_prices`, `spot_prices`, or `product_listings`. If a method already exists in the target repo, confirm it is equivalent before deciding whether to keep the scraper version or discard it. Check `lib/core/data/` and `lib/core/providers/` for any common utilities that should live there instead of in a feature repo.

- [x] Audit `scraper_repository.dart` — list every method and identify which feature currently calls it vs which is already duplicated in the feature repo
- [x] Move scraper settings methods (`getRetailerScraperSettings`, etc.) to `lib/features/retailers/data/repositories/retailers_repository.dart` (only if not already there)
- [x] Move `saveLivePrices()`, `getUnmappedLivePrices()` to `lib/features/live_prices/data/repositories/live_prices_repository.dart` (only if not already there)
- [x] Move remaining product listing methods to `lib/features/product_listings/data/repositories/product_listings_repository.dart` (confirm no clash with existing methods)
- [x] Move `saveLocalSpotPrices()`, `getLocalSpotPrices()` to `lib/features/spot_prices/data/repositories/spot_prices_repository.dart` (only if not already there)
- [x] Update `footerTimestampsProvider` to use `productListingsRepositoryProvider` instead of `scraperRepositoryProvider`
- [x] Update all retailer screen callers to use `retailerRepositoryProvider`
- [x] Remove `scraperRepositoryProvider` from `lib/core/providers/repository_providers.dart`
- [x] Delete `lib/features/scrapers/` folder
- [x] Run `flutter analyze` — zero errors

### 2.2 — Consolidate Mapping Screen → Product Profiles
- [x] Create `lib/features/product_profiles/presentation/screens/product_profile_mapping_screen.dart` (from `mapping_screen.dart` content, rename class to `ProductProfileMappingScreen`)
- [x] Add admin-only guard (non-admins see "managed by administrators" message)
- [x] Rename screen title to "Profile Mapping"
- [x] Update `lib/core/widgets/app_drawer.dart` — import, label "Profile Mapping", `if (isAdmin)` guard
- [x] Update `lib/features/product_listings/presentation/screens/product_listings_screen.dart` — import, make mapping button admin-only (#13.d.i)
- [x] Delete `lib/features/live_prices/presentation/screens/live_price_mapping_screen.dart`
- [x] Delete `lib/features/live_prices/presentation/screens/mapping_screen.dart`

### 2.3 — Migrate Manual Providers
- [x] Annotate `UserMetalTypesNotifier` with `@Riverpod(keepAlive: true)` in `user_prefs_providers.dart`
- [x] Annotate `UserRetailersNotifier` with `@Riverpod(keepAlive: true)` in `user_prefs_providers.dart`
- [x] Run `dart run build_runner build --delete-conflicting-outputs`
- [x] Verify all consumers still compile (provider names should be unchanged)

---

## Phase 3 — Common Filter Widget + Nested Sorting

### 3.1 — Common FilterSheet Widget
- [x] Create `lib/core/widgets/filter_sheet.dart` with:
  - `FilterSheet.show()` — standard bottom sheet scaffold (header: title + Reset + close)
  - `FilterSection` — labelled section
  - `FilterChipGroup<T>` — single-select chip group (null = All)
  - `FilterCheckRow` — animated colored checkbox row (multi-select)
  - `FilterDatePreset` — standard All/Today/Week/Month/Year chip group
  - `FilterRangeSlider` — labelled double range slider
  - `FilterSearchField` — single-line text search
- [x] Migrate `live_prices_screen.dart` filter to use `FilterSheet`
- [x] Migrate `spot_prices_screen.dart` filter to use `FilterSheet`
- [x] Migrate `holdings_screen.dart` filter to use `FilterSheet` (Active + Sold tabs)
- [x] Migrate `product_profiles_screen.dart` filter to use `FilterSheet`
- [x] Migrate `product_listings_screen.dart` filter to use `FilterSheet`
- [ ] Verify all filter bottom sheets look identical (#2.b)

### 3.2 — Nested Multi-Column Sorting
- [x] Create `lib/core/utils/sort_config.dart` with `SortEntry<T>` and `SortConfig<T>`
- [x] Apply to `holdings_screen.dart` — primary + secondary sort, header shows priority indicators
- [x] Apply to `product_profiles_screen.dart`
- [x] Apply to `live_prices_screen.dart`
- [x] Apply to `spot_prices_screen.dart`
- [x] Apply to `product_listings_screen.dart`
- [x] Apply to `gsr_screen.dart`

---

## Phase 4 — Header / Footer / Navigation Chrome

### 4.1 — Username in AppBar
- [x] `lib/core/widgets/app_scaffold.dart` — watch `userProfileNotifierProvider`, show username text (12pt, `AppColors.textSecondary`) left of profile icon in all AppBar headers (#7.a, #7.b.ii.1)

### 4.2 — Home Title Bar Fix
- [x] Remove refresh `IconButton` from home screen title bar (#8.a.i.1)
- [x] Add refresh to home action row (sub-header / `_BestPricesBar`) (#8.a.i)

### 4.3 — Label / Name Renames
- [x] "Retailers" → "Retailers & Providers" in `app_drawer.dart` and `retailers_screen.dart` (#15.a)
- [x] "Display name" → "User name" in `onboarding_screen.dart` (#5.a.i)
- [x] "Dealer Spread" → "Local Spread" in `analytics_screen.dart` and `dealer_spread_screen.dart` (#16.a)
- [x] "Low Label" / "Mid Label" / "High Label" → "Low Investment Guidance" / "Neutral Investment Guidance" / "High Investment Guidance" in `analytics_settings_screen.dart` (#18.e.ii, #18.e.iii)
- [x] "Local Spread Labels" → "Local Spread Investment Guidance" in `analytics_settings_screen.dart` (#18.e.vii.1)
- [x] "Low Spread Label" → "Low Spread Investment Guidance", etc. (#18.e.vii.2–4)

### 4.4 — Retailer Abbreviation in Lists
- [x] Verify `LivePrice`, `SpotPrice`, `ProductListing` models include `retailerAbbr` field from joined retailer — add to Supabase select if missing
- [x] `live_prices_screen.dart` — show `retailerAbbr` instead of full name (#11.b.i)
- [x] `spot_prices_screen.dart` — show `retailerAbbr` instead of full name (#12.b.i)
- [x] `product_listings_screen.dart` — show `retailerAbbr` instead of full name (#13.b.i)

---

## Phase 5 — Holdings & Product Profiles

### 5.1 — Holdings Filter Enhancement
- [x] Use `FilterSheet` for holdings filter bottom sheet
- [x] Add Metal Form filter (`FilterChipGroup<MetalForm>`) (#9.a.ii)
- [x] Add Purity range filter (`FilterRangeSlider`, 0–100%) (#9.a.ii)
- [x] Add Current Value range filter (#9.a.ii)
- [x] Add Gain/Loss % range filter (#9.a.ii)

### 5.2 — Shared Searchable Profile Dropdown
- [x] Create `lib/core/widgets/profile_search_field.dart` — `ProfileSearchField` using `Autocomplete<ProductProfile>` with name/type/weight display, optional "Create new profile" action
- [x] Replace profile dropdown in `add_holding_screen.dart` with `ProfileSearchField` (#9.a.i.1)
- [x] Replace profile dropdown in `edit_holding_screen.dart` with `ProfileSearchField` (#9.b.iv.2)
- [x] Use `ProfileSearchField` in `product_profile_mapping_screen.dart` (shared widget)

### 5.3 — Holding Details Improvements
- [x] Add "Copy Holding" button — navigates to `AddHoldingScreen` with pre-filled values (#9.b.iii.2)
- [x] Sell dialog: allow $0.00 (change validation to `>= 0`) (#9.b.v.1)
- [x] Sell dialog: default sale price to current holding value (#9.b.v.2)

### 5.4 — Edit Holding: Fix Create New Profile
- [x] `edit_holding_screen.dart` — ensure "Create new profile" option in `ProfileSearchField` navigates to `AddProductProfileScreen` and returns newly created profile (#9.b.iv.1)

### 5.5 — Product Profiles: Normalised oz Column
> **NOTE:** "Normalised oz" is a straight weight conversion only — purity does NOT factor in. Conversions: 1kg = 32.1507 oz, 1g = 0.03215 oz, 1oz = 1 oz. This is different from "Pure oz" (purity-adjusted). Do NOT use `pureMetalContent` for this column — compute from weight + unit only.
> **REMINDER FOR LATER:** Review the way we handle "Pure oz" / purity in the rest of the app — there may be a conceptual inconsistency, but it's working so leave it for now.

- [x] Add "Norm oz" column to `product_profiles_screen.dart` — computed from weight + weightUnit (straight unit conversion, no purity) (#10.b.i)
- [x] Set default sort to Norm oz ascending (#10.b.i)
- [x] Adjust column flex widths

### 5.6 — Product Profiles: Filter Enhancement
- [x] Add Weight range slider to product profiles filter (#10.a)
- [x] Add Purity range slider (#10.a)
- [x] Add Normalised oz range slider (same straight weight conversion as 5.5 — no purity) (#10.a)

### 5.7 — Sold Tab: Portfolio Valuation Summary
- [x] Add `soldPortfolioSummaryProvider` (@riverpod) in `holdings_providers.dart` — totals from sold holdings (#9.c.i)
- [x] Add summary card to `_SoldTab` in `holdings_screen.dart` — Total Invested | Total Sale Value | Gain/Loss $ | Gain/Loss %

---

## Phase 6 — Live Prices, Spot Prices, Listings, Home

### 6.1 — Live Prices Filter Fixes
- [x] Default date preset to `'month'` (30 days) — change initial state (#11.a.ii)
- [x] Add product name `FilterSearchField` (#11.a.iii)
- [x] Add Sell price `FilterRangeSlider` (#11.a.iv)
- [x] Add Buyback price `FilterRangeSlider` (#11.a.v)
- [x] Rename "$/oz" column header to "BB $/oz" (#11.a.vi)
- [ ] Verify TODAY filter shows correct data after Phase 1.1 timezone fix (#11.a.i)

### 6.2 — Listings: Filter Enhancements
- [x] Add Date `FilterDatePreset` (#13.a.1)
- [x] Add Metal Type `FilterChipGroup` (#13.a.2)
- [x] Add Metal Form `FilterChipGroup` (#13.a.3)
- [x] Add Sell Price `FilterRangeSlider` (#13.a.5)
- [x] Add $/oz `FilterRangeSlider` (#13.a.6)

### 6.3 — Home: Global Spot as Table
- [x] Replace global spot section with Provider | Gold | Silver | Platinum | Updated table (#8.d.ii)
- [x] Group `homeGlobalSpotPricesProvider` data by source, pivot by metal type

---

## Phase 7 — Analytics Screens

### 7.1 — Analytics Filters (All Screens)
- [x] Add filter button to action bar on `gsr_screen.dart` — Global Spot Provider filter (#16.a)
- [x] Add filter button to action bar on `local_premium_screen.dart` — Metal Type (#16.e.i) [Retailer/GlobalSpotProvider omitted — not in entry model without major refactor]
- [x] Add filter button to action bar on `local_spread_screen.dart` — Metal Type (#16.f.i) [Retailer omitted — not in entry model]
- [x] Filters default to All (null) — no user pref persistence needed for these
- [x] Filtering done at UI level (no provider family conversion needed — equivalent UX)
- [x] `GsrDataPoint.source` field added to enable provider-based filtering

### 7.2 — GSR Screen: Layout Consistency
- [x] Refactor `gsr_screen.dart` layout to: Info Card → Chart → History Table (matching Local Premium layout) (#16.d)

### 7.3 — Price Guide: New Analytics Screen ⚠️ Requires Supabase migration
- [ ] **Supabase:** Add price guide threshold columns to `user_analytics_settings` table (~10 columns)
- [ ] Add price guide fields to `lib/features/settings/data/models/user_analytics_settings_model.dart`
- [ ] Add price guide settings section to `analytics_settings_screen.dart` with 6 threshold + guidance label fields (#18.e.i)
- [ ] Add `PriceGuideEntry` model and `priceGuideHistoryProvider` to `analytics_providers.dart`
- [ ] Create `lib/features/analytics/presentation/screens/price_guide_screen.dart` (layout: Filters → Info Card → Chart → History Table) (#16.c)
- [ ] Add Price Guide card to `analytics_screen.dart` (#16.b.i)

### 7.4 — Local Spread: Three Investment Positions
- [x] `analytics_providers.dart` — rename any `dealer`-prefixed functions/variables to `local` equivalents; `_spreadGuide()` uses `settings.spreadLowLabel`, `settings.spreadMidLabel`, `settings.spreadHighLabel` (#16.f.ii)
- [x] `local_spread_screen.dart` — Info card shows 3 explicit zones with user labels; chart legend uses user labels (#16.f.ii)

### 7.5 — Local Premium: Fix Description Values
- [x] `local_premium_screen.dart` — Geographic Premium section shows values from user settings (already done)

### 7.6 — Local Spread: Fix Description Values + Rename
> **NOTE:** Rename "Round-Trip Cost" → "Local Spread" throughout. Change all remaining "dealer" references to "local" in backend, providers, and UI within the Local Spread analytics context.

- [x] `local_spread_screen.dart` — no "Round-Trip Cost" label existed; title/section already "Local Spread"
- [x] `analytics_providers.dart` — all `dealerSpread*` identifiers renamed to `localSpread*`; ran build_runner
- [x] Values shown in description come from user settings (spreadLowLabel/midLabel/highLabel)

---

## Phase 8 — Retailers & Providers

### 8.1 — Providers CRUD (Admin)
- [x] Improve Providers tab list display: status | name | description (captures omitted — no count query available)
- [x] Add "Request Provider Change" button on each provider card for non-admin users (#15.c.iv)
- [x] Move "Request Provider" button to action bar (#15.c.iii)
- [x] Create `lib/features/retailers/presentation/screens/add_edit_provider_screen.dart` (#15.c.v, #15.c.vi)
- [x] Add Admin Add/Edit/Delete provider actions (guard with `isAdminProvider`) (#15.c.v, #15.c.vi, #15.c.vii)
- [x] Verified `global_spot_providers_repository.dart` has `createProvider()`, `updateProvider()`, `deleteProvider()`
- [x] Move "Request Retailer" non-admin button to action bar (#15.b.iii.1)
- [x] `RetailersScreen` converted to `ConsumerStatefulWidget` with `TabController` for per-tab action bar buttons

### 8.2 — Fix Request Submission
- [x] Dart code in `change_request_repository.dart` is correct — RLS issue is a Supabase dashboard config (INSERT policy for `change_requests` table needed for regular users)
- [x] Request Retailer button now in action bar (not floating) (#15.b.iii.1)
- [ ] **Manual step**: Verify RLS INSERT policy on `change_requests` table in Supabase dashboard

### 8.3 — Admin Dashboard: Redesign Pending Requests
- [x] `admin_dashboard_screen.dart` — removed standalone Pending Requests card and User Approvals card
- [x] Replaced with `_CountQuickLink` buttons that show count badge inline (red pill if count > 0, chevron if 0)
- [x] `app_scaffold.dart` — added red dot badge on profile icon for admin users when pending > 0
- [x] `AdminRequestsScreen` and `UserApprovalScreen` navigation preserved via `_CountQuickLink`
- [x] `ChangeRequestDialog` code verified correct — admin update path works (#17.a, #17.b.i)

---

## Phase 9 — Settings Polish

### 9.1 — Profile Section Restructure
- [ ] `profile_settings_screen.dart` — move "Signed in with" and "Session Timeout" into a "Session Preferences" section (#18.a.i)

---

## Phase 10 — OAuth Investigation

### 10.1 — Google / Apple OAuth
- [ ] Investigate Supabase dashboard — Google/Apple provider configuration and redirect URIs (#4.a, #4.b, #6.a.i, #6.a.ii)
- [ ] Check `auth_screen.dart` `signInWithOAuth` `redirectTo` parameter
- [ ] Check `AndroidManifest.xml` for deep link `intent-filter`
- [ ] Check `ios/Runner/Info.plist` for URL schemes
- [ ] Implement fixes based on findings

---

## Phase 11 — MetalType/MetalForm DB-Driven (Admin)

### 11.1 — Metadata Providers
- [ ] Create `lib/features/metadata/presentation/providers/metadata_providers.dart` — `@Riverpod(keepAlive: true)` providers for `metal_type` and `metal_form` tables
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`
- [ ] Update dropdowns in `add_product_profile_screen.dart` and `add_holding_screen.dart` to use DB display names
- [ ] Keep Dart enums in place for model `fromString`/`toJson`

### 11.2 — Admin CRUD Screens for Metal Types/Forms
- [ ] Create `lib/features/admin/presentation/screens/metal_type_admin_screen.dart` (#1.a.i)
- [ ] Create `lib/features/admin/presentation/screens/metal_form_admin_screen.dart` (#1.b.i)
- [ ] Add navigation to both screens from `admin_dashboard_screen.dart`

---

## Outstanding Known Issues (deferred / needs more info)

- [ ] Sign up: Retailer Preferences onboarding — add more info about each retailer (#5.c.i)
- [ ] Holding Details: Growth chart (#9.b.iii.1) — deferred, design needed
- [ ] Retailers tab layout — improve for growing list (#15.b.ii.2)
- [ ] Retailers: "Private" flag for retailers (#15.b.ii.1) — needs schema design before implementing
- [ ] Edit Product Profile (as User): "Could not submit request" error (#10.c) — investigate change request flow
- [ ] Refresh button on non-home screens — confirm it actually refreshes data or remove it (#7.b.v)

---

## Supabase Migrations Needed

| When | Table | Change |
|------|-------|--------|
| Before Phase 7.3 | `user_analytics_settings` | Add ~10 price guide threshold+label columns |
| Phase 8.2 | `change_requests` RLS | Verify INSERT policy for regular users |

## Build Runner Required After

| Phase | Trigger |
|-------|---------|
| Phase 2.3 | `user_prefs_providers.dart` annotation change |
| Phase 7.1 | `analytics_providers.dart` family conversion |
| Phase 11.1 | New `metadata_providers.dart` |
