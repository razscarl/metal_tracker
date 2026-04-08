# Metal Tracker v6 — Beta Release Checklist

> Track progress by marking items `[ ]` → `[x]` as completed.
> **Phases 1–6** = minimum viable beta. **Phases 7–11** = important but not blockers.

---

## Redundant Code Cleanup *(do alongside phases, not separately)*

- [ ] **[ARCH]** Migrate legacy `lib/features/scrapers/` folder — move methods to feature repos, update all callers, remove `scraperRepositoryProvider` from core, delete folder
- [ ] **[ARCH]** Delete `lib/features/live_prices/presentation/screens/live_price_mapping_screen.dart` (superseded by `mapping_screen.dart`)
- [ ] **[ARCH]** Migrate `UserMetalTypesNotifier` and `UserRetailersNotifier` in `user_prefs_providers.dart` from manual `AsyncNotifierProvider` to `@Riverpod(keepAlive: true)` + run build_runner
- [ ] **[ARCH]** Consolidate best price logic — remove duplicate implementations between `live_prices_repository.dart` and `holdings_providers.dart`

---

## Phase 1 — Critical Bug Fixes ⚠️ BETA BLOCKERS

### 1.1 — Timezone / TimeService
- [ ] Create `lib/core/utils/time_service.dart` with `TimeService.parseUtc(String iso)` static helper
- [ ] Fix `lib/features/product_listings/data/models/product_listing_model.dart` — add `.toLocal()` to `scrapeDate` and `scrapeTimestamp` parsing
- [ ] Audit all `data/models/` files for any remaining `DateTime.parse()` without `.toLocal()`
- [ ] Verify footer shows correct local times for Listings, Global Spot, Local Spot (#19.b, #19.c, #19.d)
- [ ] Verify home screen local/global spot "last updated" shows local time (#8.d.i, #8.e.i)

### 1.2 — Best Price Calculation Fix
- [ ] Rewrite `_getBestPrice()` in `lib/features/live_prices/data/repositories/live_prices_repository.dart`:
  - For each retailer: find their max `captureTimestamp`
  - Find the most recent `captureDate` across all retailers' max timestamps
  - Exclude retailers whose max timestamp is NOT on that date
  - For included retailers, use only their max-timestamp records
  - Return best sell/buyback across filtered set (normalised to $/pure oz)
- [ ] Ensure returned `MetalBestPrices` includes retailer abbreviation
- [ ] Apply same per-retailer-latest logic to `bestBuybackForMetal()` in `holdings_providers.dart`
- [ ] Add retailer abbreviation display below each best price in `_BestPricesBar` (#8.a.iii.2)

### 1.3 — Home: Portfolio No-Holdings Empty State
- [ ] Show "You have no holdings to value. Add your first holding on the Holdings page." with nav button when portfolio is empty (#8.b.i)

### 1.4 — Analytics Settings Wiring
- [ ] `dealer_spread_screen.dart` — delete hardcoded `_buyThresholds`/`_holdThresholds`, convert `_InfoCard` to `ConsumerWidget`, read from `userAnalyticsSettingsNotifierProvider`
- [ ] `local_premium_screen.dart` — convert `_InfoCard` to `ConsumerWidget`, replace hardcoded "≥2%"/"<0%"/"0-2%" with settings values (`lpLowMark`, `lpHighMark`, `lpLowText`, `lpHighText`, `lpMidText`)
- [ ] Verify `_SpreadChart` threshold line positions and colours use settings values
- [ ] Verify analytics summary cards on `analytics_screen.dart` display correct setting-driven values

### 1.5 — Analytics Settings Reset Fix
- [ ] `user_prefs_repository.dart` — `upsertAnalyticsSettings()` must return `UserAnalyticsSettings` (not void); upsert then re-fetch
- [ ] `UserAnalyticsSettingsNotifier.reset()` — verify it triggers a visible UI refresh
- [ ] Confirm reset button works end-to-end (#18.e.viii)

---

## Phase 2 — Architecture Cleanup

### 2.1 — Remove Legacy Scrapers Folder
- [ ] Move scraper settings methods to `lib/features/retailers/data/repositories/retailers_repository.dart`
- [ ] Move `saveLivePrices()`, `getUnmappedLivePrices()` to `lib/features/live_prices/data/repositories/live_prices_repository.dart`
- [ ] Move remaining product listing methods to `lib/features/product_listings/data/repositories/product_listings_repository.dart`
- [ ] Move `saveLocalSpotPrices()`, `getLocalSpotPrices()` to `lib/features/spot_prices/data/repositories/spot_prices_repository.dart`
- [ ] Update `footerTimestampsProvider` to use `productListingsRepositoryProvider` instead of `scraperRepositoryProvider`
- [ ] Update all retailer screen callers to use `retailerRepositoryProvider`
- [ ] Remove `scraperRepositoryProvider` from `lib/core/providers/repository_providers.dart`
- [ ] Delete `lib/features/scrapers/` folder
- [ ] Run `flutter analyze` — zero errors

### 2.2 — Consolidate Mapping Screen → Product Profiles
- [ ] Create `lib/features/product_profiles/presentation/screens/product_profile_mapping_screen.dart` (from `mapping_screen.dart`, rename class to `ProductProfileMappingScreen`)
- [ ] Add admin-only guard (non-admins see "managed by administrators" message)
- [ ] Rename screen title to "Profile Mapping"
- [ ] Update `lib/core/widgets/app_drawer.dart` — import, label "Profile Mapping", `if (isAdmin)` guard
- [ ] Update `lib/features/product_listings/presentation/screens/product_listings_screen.dart` — import, make mapping button admin-only (#13.d.i)
- [ ] Delete `lib/features/live_prices/presentation/screens/live_price_mapping_screen.dart`
- [ ] Delete `lib/features/live_prices/presentation/screens/mapping_screen.dart`

### 2.3 — Migrate Manual Providers
- [ ] Annotate `UserMetalTypesNotifier` with `@Riverpod(keepAlive: true)` in `user_prefs_providers.dart`
- [ ] Annotate `UserRetailersNotifier` with `@Riverpod(keepAlive: true)` in `user_prefs_providers.dart`
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`
- [ ] Verify all consumers still compile (provider names should be unchanged)

---

## Phase 3 — Common Filter Widget + Nested Sorting

### 3.1 — Common FilterSheet Widget
- [ ] Create `lib/core/widgets/filter_sheet.dart` with:
  - `FilterSheet.show()` — standard bottom sheet scaffold (header: "Filters" title + Reset + Apply)
  - `FilterSection` — labelled section
  - `FilterChipGroup<T>` — row of selectable chips
  - `FilterDatePreset` — radio group (All / Today / Week / Month / Year)
  - `FilterRangeSlider` — labelled double range slider with min/max display
  - `FilterSearchField` — single-line text search input
- [ ] Migrate `live_prices_screen.dart` filter to use `FilterSheet`
- [ ] Migrate `spot_prices_screen.dart` filter to use `FilterSheet`
- [ ] Migrate `holdings_screen.dart` filter to use `FilterSheet`
- [ ] Migrate `product_profiles_screen.dart` filter to use `FilterSheet`
- [ ] Migrate `product_listings_screen.dart` filter to use `FilterSheet`
- [ ] Verify all filter bottom sheets look identical (#2.b)

### 3.2 — Nested Multi-Column Sorting
- [ ] Create `lib/core/utils/sort_config.dart` with `SortKey<T>` and `SortConfig<T>`
- [ ] Apply to `holdings_screen.dart` — primary + secondary sort, header shows priority number
- [ ] Apply to `product_profiles_screen.dart`
- [ ] Apply to `live_prices_screen.dart`
- [ ] Apply to `spot_prices_screen.dart`
- [ ] Apply to `product_listings_screen.dart`
- [ ] Apply to `gsr_screen.dart`

---

## Phase 4 — Header / Footer / Navigation Chrome

### 4.1 — Username in AppBar
- [ ] `lib/core/widgets/app_scaffold.dart` — watch `userProfileNotifierProvider`, show username text (12pt, `AppColors.textSecondary`) left of profile `IconButton` in all AppBar headers (#7.a, #7.b.ii.1)

### 4.2 — Home Title Bar Fix
- [ ] Remove refresh `IconButton` from home screen title bar (#8.a.i.1)
- [ ] Add refresh to home action row (sub-header / `_BestPricesBar`) (#8.a.i)

### 4.3 — Label / Name Renames
- [ ] "Retailers" → "Retailers & Providers" in `app_drawer.dart` and `retailers_screen.dart` (#15.a)
- [ ] "Display name" → "User name" in `onboarding_screen.dart` (#5.a.i)
- [ ] "Dealer Spread" → "Local Spread" in `analytics_screen.dart` and `dealer_spread_screen.dart` (#16.a)
- [ ] "Low Label" / "Mid Label" / "High Label" → "Low Investment Guidance" / "Neutral Investment Guidance" / "High Investment Guidance" in `analytics_settings_screen.dart` (#18.e.ii, #18.e.iii)
- [ ] "Local Spread Labels" → "Local Spread Investment Guidance" in `analytics_settings_screen.dart` (#18.e.vii.1)
- [ ] "Low Spread Label" / "High Spread Label" / "Mid Spread Label" → "Low/High/Neutral Spread Investment Guidance" (#18.e.vii.2–4)

### 4.4 — Retailer Abbreviation in Lists
- [ ] Verify `LivePrice`, `SpotPrice`, `ProductListing` models include `retailerAbbr` from joined retailer — add to Supabase select if missing
- [ ] `live_prices_screen.dart` — show `retailerAbbr` instead of full name (#11.b.i)
- [ ] `spot_prices_screen.dart` — show `retailerAbbr` instead of full name (#12.b.i)
- [ ] `product_listings_screen.dart` — show `retailerAbbr` instead of full name (#13.b.i)

---

## Phase 5 — Holdings & Product Profiles

### 5.1 — Holdings Filter Enhancement
- [ ] Use `FilterSheet` for holdings filter bottom sheet
- [ ] Add Metal Form filter (`FilterChipGroup<MetalForm>`) (#9.a.ii)
- [ ] Add Purity range filter (`FilterRangeSlider`, 0–100%) (#9.a.ii)
- [ ] Add Current Value range filter (#9.a.ii)
- [ ] Add Gain/Loss % range filter (#9.a.ii)

### 5.2 — Shared Searchable Profile Dropdown
- [ ] Create `lib/core/widgets/profile_search_field.dart` — `ProfileSearchField` using `Autocomplete<ProductProfile>` with name/type/weight display, optional "Create new profile" action
- [ ] Replace profile dropdown in `add_holding_screen.dart` with `ProfileSearchField` (#9.a.i.1)
- [ ] Replace profile dropdown in `edit_holding_screen.dart` with `ProfileSearchField` (#9.b.iv.2)
- [ ] Use `ProfileSearchField` in `product_profile_mapping_screen.dart`

### 5.3 — Holding Details Improvements
- [ ] Add "Copy Holding" button — navigates to `AddHoldingScreen` with pre-filled values (#9.b.iii.2)
- [ ] Sell dialog: allow $0.00 (change validation to `>= 0`) (#9.b.v.1)
- [ ] Sell dialog: default sale price to current holding value (#9.b.v.2)

### 5.4 — Edit Holding: Fix Create New Profile
- [ ] `edit_holding_screen.dart` — ensure "Create new profile" option navigates to `AddProductProfileScreen` and returns newly created profile (#9.b.iv.1)

### 5.5 — Product Profiles: Normalized oz Column
- [ ] Add "Pure oz" column to `product_profiles_screen.dart` using `profile.pureMetalContent` getter (#10.b.i)
- [ ] Set default sort to Pure oz ascending (#10.b.i)
- [ ] Adjust column flex widths

### 5.6 — Product Profiles: Filter Enhancement
- [ ] Add Weight range slider to product profiles filter (#10.a)
- [ ] Add Purity range slider (#10.a)
- [ ] Add Pure oz range slider (#10.a)

### 5.7 — Sold Tab: Portfolio Valuation Summary
- [ ] Add `soldPortfolioSummaryProvider` (@riverpod) in `holdings_providers.dart` — totals from sold holdings (#9.c.i)
- [ ] Add summary card to `_SoldTab` in `holdings_screen.dart` — Total Invested | Total Sale Value | Gain/Loss $ | Gain/Loss %

---

## Phase 6 — Live Prices, Spot Prices, Listings, Home

### 6.1 — Live Prices Filter Fixes
- [ ] Default date preset to `'month'` (30 days) on initial load (#11.a.ii)
- [ ] Add product name `FilterSearchField` (#11.a.iii)
- [ ] Add Sell price `FilterRangeSlider` (#11.a.iv)
- [ ] Add Buyback price `FilterRangeSlider` (#11.a.v)
- [ ] Rename "$/oz" column header to "BB $/oz" (#11.a.vi)
- [ ] Verify TODAY filter works correctly after Phase 1.1 timezone fix (#11.a.i)

### 6.2 — Listings: Filter Enhancements
- [ ] Add Date `FilterDatePreset` (#13.a.1)
- [ ] Add Metal Type `FilterChipGroup` (#13.a.2)
- [ ] Add Metal Form `FilterChipGroup` (#13.a.3)
- [ ] Add Sell Price `FilterRangeSlider` (#13.a.5)
- [ ] Add $/oz `FilterRangeSlider` (#13.a.6)

### 6.3 — Home: Global Spot as Table
- [ ] Replace current global spot section with table: Provider | Gold | Silver | Platinum | Updated (#8.d.ii)
- [ ] Group `homeGlobalSpotPricesProvider` data by source, pivot by metal type

---

## Phase 7 — Analytics Screens

### 7.1 — Analytics Filters (All Screens)
- [ ] Add filter button to action bar on `gsr_screen.dart` — Global Spot Provider filter (#16.a)
- [ ] Add filter button to action bar on `local_premium_screen.dart` — Metal Type, Retailer, Global Spot Provider (#16.e.i)
- [ ] Add filter button to action bar on `dealer_spread_screen.dart` — Metal Type, Retailer (#16.f.i)
- [ ] Filters default from user preference providers
- [ ] Convert `gsrHistoryProvider`, `localPremiumHistoryProvider`, `dealerSpreadHistoryProvider` to parameterized `@riverpod` families
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`

### 7.2 — GSR Screen: Layout Consistency
- [ ] Refactor `gsr_screen.dart` layout to: Info Card → Chart → History Table (matching `local_premium_screen.dart` layout) (#16.d)

### 7.3 — Price Guide: New Analytics Screen ⚠️ *Requires Supabase migration*
- [ ] **Supabase:** Add ~10 price guide threshold+label columns to `user_analytics_settings` table
- [ ] Add price guide fields to `user_analytics_settings_model.dart` with defaults
- [ ] Add "Price Guide" settings section to `analytics_settings_screen.dart` — 6 threshold + guidance label fields (#18.e.i)
- [ ] Add `PriceGuideEntry` model and `priceGuideHistoryProvider` to `analytics_providers.dart`
- [ ] Create `lib/features/analytics/presentation/screens/price_guide_screen.dart` (layout: Filters → Info Card → Trend Chart → History Table) (#16.c)
- [ ] Add Price Guide card to `analytics_screen.dart` (#16.b.i)

### 7.4 — Local Spread: Three Investment Positions
- [ ] `analytics_providers.dart` — `_spreadGuide()` uses `settings.spreadLowLabel`, `settings.spreadMidLabel`, `settings.spreadHighLabel` (#16.f.ii)
- [ ] `dealer_spread_screen.dart` — Info card shows 3 explicit zones with user-configured labels; chart has 3 colour zones (#16.f.ii)

### 7.5 — Local Premium: Fix Description Values
- [ ] `local_premium_screen.dart` — Geographic Premium section values come from user settings, not hardcoded (#16.e.ii)

### 7.6 — Local Spread: Fix Description Values
- [ ] `dealer_spread_screen.dart` — Round-Trip Cost section values come from user settings, not hardcoded (#16.f.ii)

---

## Phase 8 — Retailers & Providers

### 8.1 — Providers CRUD (Admin)
- [ ] Improve Providers tab list display: status | name | description | captures (metals/currency) (#15.c.ii.1)
- [ ] Add "Request Provider Change" button on each provider card (#15.c.iv)
- [ ] Move "Request Provider" button to action bar (#15.c.iii)
- [ ] Create `lib/features/retailers/presentation/screens/add_edit_provider_screen.dart` (#15.c.v, #15.c.vi)
- [ ] Add Admin Add/Edit/Delete provider actions (guarded with `isAdminProvider`) (#15.c.v–vii)
- [ ] Verify `global_spot_providers_repository.dart` has `createProvider()`, `updateProvider()`, `deleteProvider()`

### 8.2 — Fix Request Submission
- [ ] Investigate and fix RLS INSERT policy on `change_requests` table for regular users (#15.b.iii, #15.b.iv)
- [ ] Verify Request Retailer button is in action bar (#15.b.iii.1)
- [ ] Test Submit request end-to-end for Retailer and Provider requests

### 8.3 — Admin Dashboard: Fix Pending Requests
- [ ] `admin_requests_screen.dart` — verify/fix `onTap` opens `ChangeRequestDialog` (#17.a)
- [ ] Verify change requests list shows data (#17.b.i)
- [ ] Verify `ChangeRequestDialog` can update status and notes

---

## Phase 9 — Settings Polish

### 9.1 — Profile Section Restructure
- [ ] `profile_settings_screen.dart` — move "Signed in with" and "Session Timeout" into a new "Session Preferences" labelled section (#18.a.i)

---

## Phase 10 — OAuth Investigation

### 10.1 — Google / Apple OAuth
- [ ] Investigate Supabase dashboard — Google/Apple provider config and redirect URIs (#4.a, #4.b, #6.a.i, #6.a.ii)
- [ ] Check `auth_screen.dart` `signInWithOAuth` `redirectTo` parameter
- [ ] Check `android/app/src/main/AndroidManifest.xml` for deep link `intent-filter`
- [ ] Check `ios/Runner/Info.plist` for URL schemes
- [ ] Implement fixes based on findings

---

## Phase 11 — MetalType/MetalForm DB-Driven (Admin)

### 11.1 — Metadata Providers
- [ ] Create `lib/features/metadata/presentation/providers/metadata_providers.dart` — `@Riverpod(keepAlive: true)` providers for `metal_type` and `metal_form` tables
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`
- [ ] Update dropdowns in `add_product_profile_screen.dart` and `add_holding_screen.dart` to use DB display names
- [ ] Keep Dart enums for model `fromString`/`toJson` — do NOT remove

### 11.2 — Admin CRUD Screens for Metal Types/Forms
- [ ] Create `lib/features/admin/presentation/screens/metal_type_admin_screen.dart` (#1.a.i)
- [ ] Create `lib/features/admin/presentation/screens/metal_form_admin_screen.dart` (#1.b.i)
- [ ] Add navigation cards to both screens from `admin_dashboard_screen.dart`

---

## Outstanding Known Issues *(deferred / needs more info)*

- [ ] Onboarding: Retailer Preferences — add more info about each retailer (#5.c.i)
- [ ] Holding Details: Growth chart (#9.b.iii.1) — deferred, design needed
- [ ] Retailers tab: layout improvement for growing list (#15.b.ii.2)
- [ ] Retailers: "Private" flag for retailers (#15.b.ii.1) — needs schema design first
- [ ] Edit Product Profile (as User): "Could not submit request" error (#10.c) — investigate change request flow
- [ ] Refresh button on non-home screens — confirm it refreshes data correctly, or remove (#7.b.v)

---

## Supabase Migrations Required

| When | Table | Change |
|------|-------|--------|
| Before Phase 7.3 | `user_analytics_settings` | Add ~10 price guide threshold + label columns |
| Phase 8.2 | `change_requests` | Verify/add RLS INSERT policy for regular users |

## Build Runner Required After

| Phase | Trigger file |
|-------|-------------|
| Phase 2.3 | `user_prefs_providers.dart` |
| Phase 7.1 | `analytics_providers.dart` |
| Phase 11.1 | `metadata_providers.dart` (new file) |
