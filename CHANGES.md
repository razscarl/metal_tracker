# Change Register

Status values: `Open` · `In Progress` · `Done` · `Deferred`

Before starting any change: find the matching entry and set it to `In Progress`.
On completion: set to `Done`. On deferral: set to `Deferred` with a brief note.

---

## App-Wide

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C040 | Session timeout not working — app does not lock after user-nominated inactivity period | Open | Settings → Session Preferences timeout not being enforced |
| C041 | App data not auto-refreshing — screens should reload data on each navigation visit; refresh all data on reactivation after timeout | Open | Data reported stale for days despite DB updates |

---

## Analytics — Overview Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C001 | Overview filter: Metal Type + Range + Local Retailer + Global Spot Provider; defaults from user prefs; applies to all cards; Price Guide graph selectors can override Metal Type + Range for Price Guide only | Open | Revises earlier spec; reverses decision to put graph selectors in filter only |
| C002 | Card order (top→bottom): Price Guide → GSR → Local Spread → Local Premium | Open | |
| C003 | Metal type ordering: Gold → Silver → Platinum everywhere — mandatory app-wide rule | Open | Record in CLAUDE.md when implemented |
| C004 | Each card: Short Description · Tolerances · Data · View button (button must NOT be gold) | Open | |
| C042 | Add refresh button to AppBar on analytics overview screen | Open | |
| C043 | GSR card: movement arrow colour should match GSR value colour, not red/green gain/loss | Done | SignalColorHelper.gsrGuideColor — gold/silver/neutral |
| C044 | Local Premium card: reverse movement arrow colours — decreasing LP is good (green), increasing is bad (red) | Done | SignalColorHelper.movementColor(lowerIsBetter:true) |
| C045 | Local Premium card: change description to "Local spot price vs global spot price (lower is better)" | Done | |

---

## Analytics — All Detail Screens (Shared Issues)

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C005 | Range filter not working on graphs — All/90D/etc. has no effect on data shown | Open | Affects all 4 detail screens |
| C006 | Latest Card table not responsive to screen width; heading/data column alignment inconsistent | Open | |
| C007 | Graph vertical axis: consistent increments — round max up to next increment (e.g. $6724 → next $200 = $6800) | Open | Currently max equals exact data max |
| C008 | Graph vertical axis must always extend beyond tolerance threshold lines | Open | |
| C009 | Graph: show investment guidance tolerance zones as visual bands | Open | |
| C010 | History table not responsive to screen width; column justification inconsistent across screens | Open | |
| C011 | History table: inconsistent look/feel (movement arrows, colours, alignment) across all 4 screens | Open | |
| C012 | History table: must filter to the selected Range, not show all data | Open | |
| C046 | Full consistency audit + fix across all 4 detail screens — identical layout, movement arrows, info card structure, history table, graph axis behaviour | Open | Goal: Price Guide, GSR, Local Premium, Local Spread indistinguishable in layout/UX |

---

## Analytics — Price Guide Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C013 | Filter missing Retailer option | Open | |
| C014 | "All" range only loads back to April/May 2026 — data exists from Sept 2025; investigate provider/query | Open | |
| C015 | Supabase: add ~10 price guide threshold + label columns to `user_analytics_settings` table | Open | Required before price guide settings screen |
| C016 | Add price guide fields to `user_analytics_settings_model.dart` | Open | Blocked by C015 |
| C017 | Add price guide settings section to `analytics_settings_screen.dart` (6 threshold + label fields) | Open | Blocked by C015 |
| C018 | Add `PriceGuideEntry` model + `priceGuideHistoryProvider` to `analytics_providers.dart` | Open | |
| C019 | Add Price Guide card to `analytics_screen.dart` | Open | |
| C047 | Add refresh button to Price Guide screen AppBar | Done | onRefresh wired to AppScaffold sub-header |
| C048 | Design system not applied — card titles unreadable (white on light grey), buyback price unreadable, range button style/function wrong, font colours wrong | Done | cs.onSurface / cs.onSurfaceVariant throughout |
| C049 | Current Price Card: convert to table layout (Metal Type \| Sell \| Buyback) | Open | More consistent with app-wide table style |
| C050 | Price Trend graph: add metal type selector on the graph (overrides parent filter for Price Guide only) | Open | Reverts earlier decision to move selectors into filter only |
| C051 | History Card: Sell, Buyback, Sprd$ columns centre-aligned and evenly distributed | Open | |

---

## Analytics — GSR Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C020 | Graph: semi-static Y-axis 1–100 with three zones (Gold zone · Mid zone · Silver zone) | Open | |
| C021 | Range not working — only shows last couple of weeks regardless of selection | Open | See also C005 |
| C022 | History table layout inconsistent with other analytics screens | Open | |
| C052 | Add refresh button to GSR screen AppBar | Done | onRefresh wired to AppScaffold sub-header |
| C053 | Design system not applied — card titles unreadable, GSR price in history table unreadable, movement arrows inconsistent, range buttons wrong style/function | Done | Full M3 migration; MovementArrow widget |

---

## Analytics — Local Premium Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C023 | History table column justification uneven; not responsive | Open | |
| C054 | Add refresh button to Local Premium screen AppBar | Done | onRefresh wired to AppScaffold sub-header |
| C055 | Design system not applied — card titles unreadable, global/local prices unreadable, premium in history table unreadable, range buttons wrong | Done | Full M3 migration; MovementArrow; nested Card removed |

---

## Analytics — Local Spread Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C024 | History table poorly formatted | Open | |
| C056 | Add refresh button to Local Spread screen AppBar | Done | onRefresh wired to AppScaffold sub-header |
| C057 | Design system not applied — card titles unreadable, spread % in history table unreadable, history table layout, range buttons wrong | Done | Full M3 migration; MovementArrow; colour logic consistent |

---

## Live Prices

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C025 | Verify TODAY filter shows correct data after Phase 1.1 timezone fix (#11.a.i) | Open | |

---

## Settings

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C026 | Profile settings: move "Signed in with" + "Session Timeout" into a "Session Preferences" section | Open | Phase 9.1 |

---

## Admin

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C027 | Verify RLS INSERT policy on `change_requests` table in Supabase dashboard | Open | Phase 8.2 — manual Supabase step |
| C028 | Create `metal_type_admin_screen.dart` + add navigation from admin dashboard | Open | Phase 11.2 |
| C029 | Create `metal_form_admin_screen.dart` + add navigation from admin dashboard | Open | Phase 11.2 |

---

## Architecture / Technical

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C030 | Create `metadata_providers.dart` — `@Riverpod(keepAlive: true)` providers for `metal_type` + `metal_form` tables | Open | Phase 11.1 |
| C031 | Update dropdowns in `add_product_profile_screen.dart` + `add_holding_screen.dart` to use DB display names | Open | Blocked by C030 |

---

## Auth / OAuth

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C032 | Investigate + implement Google/Apple OAuth (Supabase config, redirectTo, AndroidManifest, Info.plist) | Open | Phase 10.1 |

---

## UI Polish / Miscellaneous

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C033 | Verify all filter bottom sheets look identical (#2.b) | Open | Phase 3.1 |
| C034 | Sign up: add more info about each retailer in onboarding (#5.c.i) | Deferred | Design needed first |
| C035 | Holding Details: Growth chart (#9.b.iii.1) | Deferred | Design needed first |
| C036 | Retailers tab layout — improve for growing list (#15.b.ii.2) | Deferred | |
| C037 | Retailers: "Private" flag (#15.b.ii.1) | Deferred | Needs schema design |
| C038 | Edit Product Profile (User): "Could not submit request" error (#10.c) | Open | Investigate change request flow |
| C039 | Refresh button on non-home screens — confirm it refreshes data or remove it (#7.b.v) | Open | |
| C058 | Sort UX (all table views): sort cannot be deactivated once activated; needs conventional discoverable sort interaction | Open | Raised in Price Guide history; applies app-wide |
| C059 | Humanise Design Token language — token names and descriptions in the Design Tokens admin screen use developer terminology; should be plain English so non-developers can understand and manage them | Open | |
| C060 | Portfolio Valuation card: replace Unicode ↑↓ movement arrows with the standard `MovementArrow` widget once built | Open | MovementArrow now available — ready to action |
| C061 | UI componentisation backlog — extract repeated patterns into shared core widgets: card header row (icon + title), sortable table header cell, table data row container, loading state, error state, empty state. Currently duplicated across 10+ screens. | Open | Address incrementally alongside related screen work; table header/row to be done in Cluster 4 |
