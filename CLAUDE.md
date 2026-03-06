# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (Windows desktop is primary target)
flutter run -d windows

# Build
flutter build windows
flutter build apk

# Analyze (linting)
flutter analyze

# Tests
flutter test
flutter test test/path/to/specific_test.dart

# Code generation (required after modifying @riverpod-annotated providers)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs
```

## Architecture

Flutter app with a **feature-first folder structure** under `lib/`:

```
lib/
  main.dart                        # App entry point, Supabase init, ProviderScope
  core/
    constants/
      app_constants.dart           # Enums: MetalType, MetalForm, WeightUnit; AppConstants
      scraper_constants.dart       # ScraperType, ScraperNames, ScrapeStatus
      supabase_config.dart         # Supabase URL + anon key (hardcoded)
    providers/
      repository_providers.dart    # Shared Riverpod providers for repositories
    theme/app_theme.dart           # AppTheme.darkTheme + AppColors (dark-only)
    utils/
      weight_converter.dart        # WeightCalculations static helpers (oz/g/kg + purity)
      metal_color_helper.dart      # Color lookup by metal type
    widgets/                       # Shared widgets: neumorphic_container, metal_button, app_drawer
  features/
    auth/          
    holdings/       
    product_profiles/
    live_prices/   
    product_listings/  
    spot_prices/
    retailers/  
    metadata/
    home/          
    analytics/      
    settings/
```

Each feature follows `data/` → `presentation/` layering:
- `data/models/` — plain Dart classes with `fromJson`/`toJson`
- `data/repositories/` — Supabase CRUD, all queries filtered by `user_id` for RLS
- `data/services/` — HTTP scrapers (live prices, product listings, spot prices)
- `presentation/providers/` — Riverpod state
- `presentation/screens/` — UI screens
- `presentation/widgets/` — Feature-specific widgets

## State Management

**Use `@riverpod` annotation (code-generated) as the standard pattern** for all new providers. Run `build_runner` after any change to an annotated provider file.

Some older files (`holdings_providers.dart`, `retailers_providers.dart`) still use manual `FutureProvider` / `StateNotifierProvider` / `StateNotifier`. These are legacy — do not add new manual providers. When significantly modifying a legacy provider file, migrate it to `@riverpod`.

Repository providers are defined in two places — `core/providers/repository_providers.dart` (canonical) and locally duplicated in some feature provider files. **Always use `core/providers/repository_providers.dart` for repository providers.** Remove local duplicates when touching those files.

## Backend: Supabase

- Auth via Supabase (email/password). `AuthWrapper` routes to `AuthScreen` or `HomeScreen`.
- All repository queries include `.eq('user_id', _userId)` for Row Level Security.
- `_userId` is accessed via `_supabase.auth.currentUser!.id` (will throw if unauthenticated).
- `sqflite` is a dependency but not yet used — reserved for future offline/caching support. All current data goes through Supabase.

## Scraping

Retailers scraped: **GBA**, **GS**, **IMP** (three Australian precious metal dealers).

`BaseScraperService` (abstract) provides `fetchHtml()`, `fetchHtmlPost()`, `parsePrice()`, `normalizeToOunces()`. Each retailer has concrete service classes for live prices, product listings, and spot prices. Scraper settings (CSS selectors, URLs) are stored per-retailer in Supabase via `RetailerScraperSetting`.

New scrapers belong in the relevant feature's `data/services/` folder (e.g. `live_prices/data/services/`). The `features/scrapers/` folder is legacy infrastructure — do not add new code there.

## Key Domain Concepts

- **ProductProfile**: Defines a normalised metal product (type, form, weight, purity). Holdings, Live Prices, Product Listings map to profiles.
- **Holding**: A purchase of an item from a retailer (price, date, retailer). Can be marked as sold. Mapped to a product profile
- **LivePrice**: Scraped sell/buyback price from a retailer mapped to a product profile.
- **PortfolioValuation**: Computed from holdings × live prices via `portfolioValuationProvider` in `holdings_providers.dart`. Uses `WeightCalculations.holdingValue()` to convert weight+purity to troy-oz value.
- **SpotPrice**: Local (retailer-scraped) and global (API) spot prices per metal type.

## Enums

Defined in `lib/core/constants/app_constants.dart`:
- `MetalType`: `gold`, `silver`, `platinum`
- `MetalForm`: `castBar`, `mintedBar`, `coin`, `granule`, `round`, `jewellery`, `other`
- `WeightUnit`: `oz`, `g`, `kg`

All have `fromString()` and `displayName`. String storage in Supabase, enum conversion via `.fromString()` / getters like `metalTypeEnum`, `weightUnitEnum`.

## UI

- Mobile first by design:  The primary tool used to access the application will be Mobile, so we will design it to provide a modern, professional UI.
- Preferred UI widgets: `NeumorphicContainer`, `MetalButton`, `AppDrawer`.
- Dark theme option (`AppTheme.darkTheme`). 
- Color palette in `AppColors`: gold (`#D4AF37`), silver (`#C0C0C0`), platinum (`#00D4FF`), dark background (`#1A1A1A`), card background (`#2A2A2A`).
- Font: Google Fonts Inter.
- Gain shown in `gainGreen` (`#00C853`), loss in `lossRed` (`#FF1744`).
- Simplify Navigation: Use short and easily understandable labels on the navigation menu and tab bars while ensuring they don’t take up too much screen space.
- Stay focused: Use a consistent button shape and color to indicate these actions throughout your app to make it easy for users to know what to do.
- Reduce clutter: Keep your user interface (UI) design simple and streamlined so that users can easily find the information they need. 
- Prioritise key content: Put the most critical content and calls-to-action (CTAs) in the user’s natural reach zone and use visual elements to draw attention to them.
- Design for humans: optimize button size, shape, and color for Android phones.
- Follow UX mobile design converntaions: Use widely accepted icons, design elements, layouts, and gestures to simplify page design and improve usability.
- Improve readability: Select a typeface that works well in different sizes and weights. Set body text at 12 points to ensure the content is legible without zooming. Use white space, ample line height, and padding to reduce clutter and make it easy for users to click on links and buttons.
- Optimise mobile UI load time:  Improve load time by optimizing your images, simplifying page layout, minifying resources, reducing redirects, etc. You can also use lazy loading to load resources only when needed.
- Stay consistent: All user interactions should be consistent across the application.



## 🛠 Tech Stack
- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Riverpod 2.x (Generator Pattern)
- **Backend/Auth:** Supabase
- **Local Storage:** sqflite (planned — not yet implemented)

## 🏗 Architecture Principles
Follow a **Layered Architecture** (Domain, Data, Application, Presentation):
- **Domain:** Entities and Repository Interfaces (Abstractions).
- **Data:** Repository Implementations and Data Sources (Supabase, sqflite).
- **Application:** Riverpod Notifiers (AsyncNotifier/Notifier) that coordinate between Data and UI.
- **Presentation:** Flutter Widgets (ConsumerWidget or ConsumerStatefulWidget).

## 🚀 Riverpod Best Practices (STRICT)
- **NO MANUAL PROVIDERS:** Use `@riverpod` annotations for all providers. 
- **NO StateNotifier:** Use `AsyncNotifier` (for async state) or `Notifier` (for synchronous state).
- **Auto-Dispose:** Let providers dispose automatically unless `keepAlive: true` is specifically required.
- **AsyncValue:** Always handle state using `.when()`, `.maybeWhen()`, or `.whenData()` in the UI to ensure loading/error states are covered.
- **Code Gen:** Remind the user to run `dart run build_runner build --delete-conflicting-outputs` after provider changes.

## 🎨 UI & Styling
- **Widget Selection:** Prefer `ConsumerWidget` over `StatelessWidget`.
- **Naming:** Providers should be named after their purpose (e.g., `userProvider`, `productListProvider`).
- **Separation:** Keep business logic out of `build()` methods. All logic goes into the Notifier.

## 📝 Code Style
- **Formatting:** Follow standard `dart format`.
- **Naming:** use `lowerCamelCase` for variables/functions, `UpperCamelCase` for classes/enums.
- **Constructors:** Use `const` constructors wherever possible for performance.
- **Imports:** Use package imports (e.g., `import 'package:metal_tracker/...'`) instead of relative imports. When modifying a file that uses relative imports, update those imports to package imports in the same change.

## 🛠 Commands
- Build Runner: `dart run build_runner build`
- Watch Runner: `dart run build_runner watch --delete-conflicting-outputs`
- Test: `flutter test`

## 🛑 Constraints & Anti-Drift
- **NO HALLUCINATED DEPENDENCIES:** Do not add or use any packages not already in `pubspec.yaml` without asking first. **Never modify `pubspec.yaml` without explicit user approval.**
- **READ BEFORE WRITING:** Before creating a new file or feature, check existing files in the same layer to maintain consistency in style and patterns.
- **NO ASSUMPTIONS ON API:** If an API endpoint or Data Model structure is unknown, ask for the schema or look at existing `DataSources`. Do not mock data unless explicitly asked.
- **STAY IN SCOPE:** Solve the specific problem requested. Do not refactor unrelated files unless they are breaking the current task.
- **STATE MANAGEMENT CONSISTENCY:** If you see a `StateProvider` or `ChangeNotifier` in old code, do not use it as a template. Always use the modern `Notifier/AsyncNotifier` pattern for new code.

## 📁 Project Structure (Strict)
- **Feature-first over Layer-first:** Group files by feature (e.g., `features/auth/`, `features/profile/`) rather than by type (e.g., `all_models/`, `all_widgets/`).
- **File Naming:** Use `snake_case` for all files. 
- **Generated Files:** Never attempt to manually edit `.g.dart` or `.freezed.dart` files. If a change is needed, edit the source `.dart` file and suggest running `build_runner`.
