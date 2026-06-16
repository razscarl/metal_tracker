# Change Register

Status values: `Open` · `In Progress` · `Done` · `Deferred`

Before starting any change: find the matching entry and set it to `In Progress`.
On completion: set to `Done`. On deferral: set to `Deferred` with a note.

---

## Analytics — Overview Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C001 | Filter: add Retailer + Global Spot Provider filters | Open | Currently only Metal Type filter |
| C002 | Card order (top→bottom): Price Guide → GSR → Local Spread → Local Premium | Open | |
| C003 | Metal type ordering: Gold → Silver → Platinum on all cards | Open | |
| C004 | Each card: Short Description · Tolerances · Data · View button (button must NOT be gold) | Open | |

---

## Analytics — All Detail Screens (Shared Issues)

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C005 | Range filter not working — All/90D/etc. has no effect on data shown | Open | Affects Price Guide, GSR, Local Premium, Local Spread |
| C006 | Latest Card table not responsive to screen width; heading/data column alignment inconsistent | Open | |
| C007 | Graph vertical axis: needs headroom (approx −20% to +20% beyond data range) | Open | |
| C008 | Graph vertical axis must always extend beyond tolerance threshold lines | Open | |
| C009 | Graph: show investment guidance tolerance zones as visual bands | Open | |
| C010 | History table not responsive to screen width; column justification inconsistent across screens | Open | |
| C011 | History table: inconsistent look/feel (movement arrows, colours, alignment) across all 4 screens | Open | |
| C012 | History table: must filter to the selected Range, not show all data | Open | |

---

## Analytics — Price Guide Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C013 | Filter missing Retailer option | Open | |
| C014 | "All" range only loads back to April 2026 — data exists from Sept 2025; investigate provider/query | Open | |
| C015 | Supabase: add ~10 price guide threshold + label columns to `user_analytics_settings` table | Open | Required before price guide settings screen |
| C016 | Add price guide fields to `user_analytics_settings_model.dart` | Open | Blocked by C015 |
| C017 | Add price guide settings section to `analytics_settings_screen.dart` (6 threshold + label fields) | Open | Blocked by C015 |
| C018 | Add `PriceGuideEntry` model + `priceGuideHistoryProvider` to `analytics_providers.dart` | Open | |
| C019 | Add Price Guide card to `analytics_screen.dart` | Open | |

---

## Analytics — GSR Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C020 | Graph: semi-static Y-axis 1–100 with three zones (Gold zone · Mid zone · Silver zone) | Open | |
| C021 | Range not working — only shows last couple of weeks regardless of selection | Open | See also C005 |
| C022 | History table layout inconsistent with other analytics screens | Open | |

---

## Analytics — Local Premium Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C023 | History table column justification uneven; not responsive | Open | |

---

## Analytics — Local Spread Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C024 | History table poorly formatted | Open | |

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
