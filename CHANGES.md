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
| C082 | Refresh button behaviour is wrong — on Home it does nothing; on Market Data screens it only refreshes the current screen. The refresh button must invalidate ALL app data providers regardless of which screen it is pressed on, so every screen shows fresh data when next visited | Open | Global refresh required; current per-screen invalidation is insufficient |
| C066 | Grey = Silver: neutral data values across analytics screens use grey (textSecondary / onSurfaceVariant) which visually implies Silver metal — replace all neutral data colours with cs.onSurface | In Progress | Affects SignalColorHelper + all analytics screens |
| C067 | Range/metal/date chip colour: all analytics selectors use gold for selected state — must use cs.primaryContainer (Royal Indigo theme default). Applies to AnalyticsRangeChips, DateRangeSelector, MetalTypeSelector widgets; fixing these widgets fixes all screens at once | In Progress | |
| C068 | Movement arrow global audit: CLAUDE.md movement arrow rules must be applied across the ENTIRE app — (a) never in their own table column, (b) always use MovementArrow widget not raw Icon, (c) colour always via SignalColorHelper.movementColor(). Audit all screens, not just analytics | In Progress | Applied: GSR history (removed Move column, inlined with GSR value), LP summary + history (removed move column, inlined with Premium%), LS summary + history (same), portfolio valuation _MovementChip (raw Icon → MovementArrow), analytics overview C043/C044 already correct; awaiting user confirmation |

---

## Analytics — Overview Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C001 | Overview filter: Metal Type + Range + Local Retailer + Global Spot Provider; defaults from user prefs; applies to all cards; Price Guide graph selectors can override Metal Type + Range for Price Guide only | Open | Revises earlier spec; reverses decision to put graph selectors in filter only |
| C002 | Card order (top→bottom): Price Guide → GSR → Local Spread → Local Premium | Open | |
| C003 | Metal type ordering: Gold → Silver → Platinum everywhere — mandatory app-wide rule | Open | CLAUDE.md rule added. Overview LP/LS cards fixed (C065). LP detail latest card, LS detail latest card + summary table still in wrong order (see C071, C072) |
| C004 | Each card: Short Description · Tolerances · Data · View button (button must NOT be gold) | Open | |
| C042 | Add refresh button to AppBar on analytics overview screen | In Progress | |
| C043 | GSR card: movement arrow colour should match GSR value colour, not red/green gain/loss | In Progress | analytics_screen.dart verified: MovementArrow uses cs.primary matching GSR value colour — appears already correct; awaiting user confirmation |
| C044 | Local Premium card: reverse movement arrow colours — decreasing LP is good (green), increasing is bad (red) | In Progress | analytics_screen.dart verified: MovementArrow uses SignalColorHelper.movementColor(lowerIsBetter: true) — appears already correct; awaiting user confirmation |
| C045 | Local Premium card: change description to "Local spot price vs global spot price (lower is better)" | In Progress | analytics_screen.dart line 635 still shows "Geographic premium vs global spot price" |
| C050 | Price Guide overview card: metal type + range selectors added but must sit top-right of the card; metal selector not yet wired to the chart on the Price Guide detail screen | In Progress | Selectors position = top-right of card header row |
| C065 | LP and LS overview cards: order metal types Gold → Silver → Platinum (consistent with C003 rule) | In Progress | |

---

## Analytics — All Detail Screens (Shared Issues)

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C005 | **HIGHEST PRIORITY** Range filter not showing full dataset — providers only load a limited window of data; "All" shows only what was fetched, not all historical data in the database. Critical investment information investors need access to | Open | Affects all 4 detail screens + overview Price Guide card; requires provider/query changes to load full history |
| C006 | Latest Card table not responsive to screen width; heading/data column alignment inconsistent | Open | |
| C007 | Graph vertical axis: round min DOWN and max UP to next clean increment (e.g. min $6,650 → $6,600; max $6,724 → $6,800). Applies to ALL charts including overview Price Guide card | Open | Currently both min and max are pinned to exact data values |
| C074 | Metal type icon: add the metal type icon (small, inline) to the LEFT of the metal type name in all analytics detail-screen tables — LP Latest card, LP History table, LS Latest card, LS History table, GSR History table | Open | Investor visual aid; consistent with metal icon usage on Home and Live Prices screens |
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
| C013 | Price Guide filter missing Retailer Selector AND Global Spot Provider Selector; principle: all analytics screens must filter by user's selected retailers and providers | Open | |
| C014 | "All" range only loads back to April/May 2026 — data exists from Sept 2025; investigate provider/query | Open | |
| C015 | Supabase: add ~10 price guide threshold + label columns to `user_analytics_settings` table | Open | Required before price guide settings screen |
| C016 | Add price guide fields to `user_analytics_settings_model.dart` | Open | Blocked by C015 |
| C017 | Add price guide settings section to `analytics_settings_screen.dart` (6 threshold + label fields) | Open | Blocked by C015 |
| C018 | Add `PriceGuideEntry` model + `priceGuideHistoryProvider` to `analytics_providers.dart` | Open | |
| C019 | Add Price Guide card to `analytics_screen.dart` | Open | |
| C047 | Add refresh button to Price Guide screen AppBar | Done | Refresh button present; no loading indicator so user cannot confirm it worked (see C064) |
| C048 | Design system — card titles and buyback price readable: Fixed. Range button colour/function wrong; history movement arrows completely gone (regression) | Open | Titles + prices fixed; range chips still wrong colour; arrows missing in history table |
| C049 | Current Price Card: convert to table layout (Metal Type \| Sell \| Buyback); font weights also wrong | Open | Current bold layout looks bad; table is more consistent with app-wide style |
| C050 | Price Guide detail screen: metal selector not yet wired to the Price Trend chart; range selector position wrong | Open | Metal selector on overview card works; detail screen chart ignores it |
| C051 | History Card: Sell, Buyback, Sprd$ columns centre-aligned and evenly distributed | Open | |
| C062 | Price Guide detail: history table movement arrows completely missing (regression from M3 migration) | In Progress | Applied — MovementArrow added inline with Sprd$ column (lowerIsBetter: true); awaiting user confirmation |

---

## Analytics — GSR Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C020 | Graph: semi-static Y-axis 1–100 with three zones (Gold zone · Mid zone · Silver zone) | Open | |
| C021 | Range not working — only shows last couple of weeks regardless of selection | Open | See also C005 |
| C022 | History table layout inconsistent with other analytics screens | Open | |
| C052 | Add refresh button to GSR screen AppBar | Done | Refresh button present; no loading indicator so user cannot confirm it worked (see C064) |
| C053 | Design system — titles and history GSR value readable: Fixed. Movement arrows in own column (violates C068); history table layout wrong; range selector wrong colour (fixed) but in wrong position — must be top-right of chart card header row | Open | Partial; arrow column placement, table layout, and range position still outstanding |
| C069 | GSR Trend chart has no title | Open | |
| C070 | GSR Trend chart has no legend | Open | |
| C075 | GSR Current card: currently shows just a GSR number — should display the full GSR slider visual (the same slider used in analytics context), not a plain numeric value | Open | User specifically requested the slider, not just a number |

---

## Analytics — Local Premium Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C023 | History table column justification uneven; not responsive | Open | |
| C054 | Add refresh button to Local Premium screen AppBar | Done | Confirmed working |
| C055 | Design system — titles, prices, and history premium readable: Fixed. Movement arrow colours wrong (C063); range selector colour fixed but must be top-right of chart card header row | Open | Partial; arrow colours, range position still outstanding |
| C063 | LP detail screen: movement arrow colours wrong — lowerIsBetter rule not applied; up should be red, down should be green | Open | Distinct from C044 which is the overview card |
| C071 | LP detail screen: Latest Premium card (a) metals in wrong order — Gold → Silver → Platinum; (b) movement arrow in own column — violates C068; (c) table not well distributed/aligned; (d) metal type icon missing — see C074 | Open | |

---

## Analytics — Local Spread Screen

| ID | Description | Status | Notes |
|----|-------------|--------|-------|
| C024 | History table poorly formatted | Open | |
| C056 | Add refresh button to Local Spread screen AppBar | Done | Confirmed working |
| C057 | Design system — titles, prices, spread %, movement arrows: Fixed. History table layout wrong; range selector colour fix applied (DateRangeSelector at line 503) but must verify with fresh build; range selector must be top-right of chart card header row | Open | Partial; table layout and range position still outstanding; verify LS chips are now indigo |
| C072 | LS detail screen: Latest Spread card (a) metals in wrong order — Gold → Silver → Platinum; (b) movement arrow in own column — violates C068; (c) table not well distributed/aligned; (d) metal type icon missing — see C074 | Open | |

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
| C058 | Sort UX (all table views): sort cannot be deactivated once activated; needs conventional discoverable sort interaction; sort column heading turns gold when sorted — must use cs.primary or onSurface; use Date column sort arrow spacing as reference for correct implementation | Open | Raised in Price Guide history; applies app-wide |
| C059 | Humanise Design Token language — token names and descriptions in the Design Tokens admin screen use developer terminology; should be plain English so non-developers can understand and manage them | Open | |
| C060 | Portfolio Valuation card: replace raw Icon(arrow_upward/downward) in _MovementChip with MovementArrow widget | In Progress | Applied — awaiting user confirmation |
| C061 | UI componentisation backlog — extract repeated patterns into shared core widgets: card header row (icon + title), sortable table header cell, table data row container, loading state, error state, empty state. Currently duplicated across 10+ screens. | Open | Address incrementally alongside related screen work; table header/row to be done in Cluster 4 |
| C073 | Widget/class naming audit — review all widget and class names across the codebase and rename any that describe WHERE they are used rather than WHAT they do (e.g. AnalyticsRangeChips → DateRangeSelector). Purpose-named objects are discoverable; location-named objects cause duplication. | Open | |
| C064 | Refresh buttons: no visual feedback when triggered — user cannot tell if refresh worked. All analytics screens + overview affected. | Open | Need loading indicator or success snackbar |
| C076 | Analytics Detail Screen standard scaffold — create shared `AnalyticsInfoCard`, `AnalyticsLatestCard`, `AnalyticsTrendCard`, `AnalyticsHistoryCard` widgets with standard layout per CLAUDE.md spec; filter (Metal · Range · Retailer · Provider) is a top-level scaffold concern not re-implemented per screen; one change fixes all four detail screens. Building blocks: CardHeading, TableColumnHeading, TableDataRow, AxisRangeHelper | In Progress | HIGHEST PRIORITY architectural item; all subsequent analytics screen fixes depend on this |
| C077 | Price Guide history card: Range Selector missing from top-right of card header | Open | |
| C078 | GSR history card: Range Selector missing from top-right of card header | Open | |
| C079 | LP Trend card: X axis date compression / bunching at right edge — dates overlap | Open | |
| C080 | LS Trend card: Metal Type Selector missing from card | Open | |
| C081 | Investment Guide screen: all text colours were dark-theme legacy values (white/grey) — invisible on light theme. Fixed across investment_guide_screen.dart, recommendation_card.dart, market_context_banner.dart, score_breakdown_sheet.dart. Raw movement arrows also replaced with MovementArrow widget. | Done | |
