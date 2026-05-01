# Metal Tracker v6 — Test Plan

> Version: 0.1.7 | Last updated: 2026-04-15
> Test as both **Admin** and **Standard User** unless noted.

---

## 1. Authentication

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 1.1 | Login — valid credentials | Enter correct email + password, tap Sign In | Navigates to Home screen, username shown in AppBar |
| 1.2 | Login — invalid credentials | Enter wrong password, tap Sign In | Error message shown, stays on login screen |
| 1.3 | Login — empty fields | Tap Sign In with blank fields | Validation error shown |
| 1.4 | Version displayed | View login screen | App version (e.g. v0.1.7) displayed below "Metal Tracker" title |
| 1.5 | Sign Out | Open drawer, tap Sign Out | Returns to login screen, user session cleared |
| 1.6 | Session persistence | Login, close app, reopen | Stays logged in without re-entering credentials |

---

## 2. Navigation & App Chrome

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 2.1 | Drawer opens | Tap hamburger menu from any screen | Drawer slides open showing all navigation items |
| 2.2 | User profile shown | Open drawer | Username and email shown at top; "Administrator" badge shown for admin |
| 2.3 | Admin-only items hidden | Open drawer as Standard User | "Profile Mapping" and "Admin Dashboard" sections not visible |
| 2.4 | Admin-only items visible | Open drawer as Admin | "Profile Mapping" and "Administration" section visible |
| 2.5 | Version in AppBar | Navigate to any non-home screen | Version number shown in AppBar next to screen title |
| 2.6 | Footer timestamps | View any screen with footer | "Live Prices", "Spot Prices", "Listings", "Global Spot" timestamps shown with correct local times |
| 2.7 | Navigate to Settings | Open drawer → Settings | Settings screen opens |

---

## 3. Home Screen

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 3.1 | Best Prices Bar | View home screen | Gold, Silver, Platinum sell/buyback prices shown with retailer abbreviations |
| 3.2 | Best Prices — no data | First launch with no live prices | Best Prices Bar shows "—" placeholders |
| 3.3 | Refresh button | Tap refresh in Best Prices Bar | Live prices data reloads |
| 3.4 | Portfolio Valuation card | View home with holdings | Shows total value, cost, gain/loss $ and % with colour (green/red) |
| 3.5 | Portfolio Movement | View home with recent price changes | Movement chip shows ↑/↓ arrow + % change |
| 3.6 | No holdings empty state | View home with no holdings | "You have no holdings to value. Add your first holding on the Holdings page." shown with nav button |
| 3.7 | Recent Live Prices | View home | Shows at most one row per metal per retailer (most recent only) |
| 3.8 | Live Prices — stale data | Price not scraped today | Row shown dimmed with its capture date |
| 3.9 | Metal filter | Tap Gold/Silver/Platinum chip | Live Prices section filters to selected metal |
| 3.10 | Local Spot Prices | View home | Most recent spot per retailer shown with fetch time |
| 3.11 | Global Spot table | View home | Table shows Provider \| Gold \| Silver \| Platinum \| Updated columns |
| 3.12 | Local time in footer | Check footer timestamps | All timestamps show local time (not UTC) |

---

## 4. Holdings — Active Tab

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 4.1 | Holdings list | Navigate to Holdings | Active holdings listed with metal colour, product name, retailer, value |
| 4.2 | Add holding | Tap + button, fill all fields, save | New holding appears in list, portfolio value updates |
| 4.3 | Add holding — profile search | Type in product profile field | Filtered autocomplete list shown |
| 4.4 | Add holding — create new profile | Tap "Create new profile" in profile search | Navigates to Add Product Profile, returns with new profile selected |
| 4.5 | Holding detail | Tap a holding row | Detail screen shows all purchase info, current value, gain/loss |
| 4.6 | Edit holding | Open holding detail → Edit | Edit form pre-filled with existing values |
| 4.7 | Copy holding | Open holding detail → Copy | Add Holding screen opens pre-filled with same values |
| 4.8 | Sell holding | Open holding detail → Sell | Sale price defaults to current holding value; $0 allowed; holding moves to Sold tab |
| 4.9 | Filter — Metal Type | Open filter → select Gold | Only gold holdings shown |
| 4.10 | Filter — Metal Form | Open filter → select Cast Bar | Only cast bar holdings shown |
| 4.11 | Filter — Purity range | Open filter → set purity range | Holdings outside range hidden |
| 4.12 | Filter — Current Value range | Open filter → set value range | Holdings outside range hidden |
| 4.13 | Filter — Gain/Loss % range | Open filter → set gain/loss range | Holdings outside range hidden |
| 4.14 | Filter reset | Open filter → Reset | All filters cleared, full list shown |
| 4.15 | Multi-column sort | Tap column headers | Primary sort applied; tap second header adds secondary sort with priority indicator |

---

## 5. Holdings — Sold Tab

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 5.1 | Sold list | Tap Sold tab | All sold holdings listed |
| 5.2 | Sold summary card | View Sold tab | Summary card shows Total Invested \| Total Sale Value \| Gain/Loss $ \| Gain/Loss % |
| 5.3 | Filter sold holdings | Open filter on Sold tab | Same filter options as Active tab |

---

## 6. Product Profiles

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 6.1 | Profiles list | Navigate to Product Profiles | All profiles listed with metal icon, name, type, form, weight, purity, norm oz |
| 6.2 | Default sort | View list | Sorted by Norm oz ascending by default |
| 6.3 | Add profile | Tap + button, fill all fields, save | New profile appears in list |
| 6.4 | Metal Type dropdown | Tap Metal Type in add/edit form | Dropdown shows Gold, Silver, Platinum options |
| 6.5 | Metal Form dropdown | Tap Metal Form in add/edit form | Dropdown shows all form options |
| 6.6 | Edit profile (Admin) | Tap a profile row as Admin | Edit form opens pre-filled |
| 6.7 | Edit profile (User) | Tap a profile row as Standard User | Read-only view or edit not available |
| 6.8 | Delete profile (Admin) | Open profile → Delete | Profile removed from list |
| 6.9 | Filter — Weight range | Open filter → set weight range | Profiles outside range hidden |
| 6.10 | Filter — Purity range | Open filter → set purity range | Profiles outside range hidden |
| 6.11 | Filter — Norm oz range | Open filter → set norm oz range | Profiles outside range hidden |
| 6.12 | Profiles are global | Log in as different user | Same profiles visible regardless of which user created them |

---

## 7. Profile Mapping (Admin Only)

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 7.1 | Access as Admin | Open drawer → Profile Mapping | Mapping screen opens with Live Prices + Listings tabs |
| 7.2 | Access as User | Navigate to Profile Mapping | "Profile mapping is managed by administrators" message shown |
| 7.3 | Unmapped live prices | View Live Prices tab | All unmapped live price records listed |
| 7.4 | Unmapped listings | View Listings tab | All unmapped product listings listed (across all scrape dates) |
| 7.5 | Map a live price | Select profile in search field → Save | Record disappears from unmapped list |
| 7.6 | Map a listing | Select profile in search field → Save | Record disappears from unmapped list |
| 7.7 | Profile search | Type in search field | Filtered profile list shown |
| 7.8 | Navigate from unmapped listing | Tap unmapped listing row in Listings screen (as Admin) | Profile Mapping screen opens on Listings tab with that listing pinned at top with gold border |
| 7.9 | Remap mapped listing | Tap mapped listing row in Listings screen (as Admin) | Remapping sheet opens with ProfileSearchField pre-selected with current profile |
| 7.10 | All mapped state | All items mapped | "All live prices/listings mapped!" message shown |

---

## 8. Live Prices

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 8.1 | Live prices list | Navigate to Live Prices | All live price records listed with retailer abbr, product name, sell/buyback, $/oz |
| 8.2 | Scrape live prices (Admin) | Tap sync icon | Progress indicator shown; prices fetched and saved; result dialog shown |
| 8.3 | Scrape result dialog | After scrape | Shows per-retailer success/failure status with counts |
| 8.4 | Filter — Date preset | Open filter → select Today | Only today's prices shown |
| 8.5 | Filter — Month default | Open Live Prices fresh | Default filter is last 30 days |
| 8.6 | Filter — Product name search | Open filter → type product name | Only matching products shown |
| 8.7 | Filter — Sell price range | Open filter → set sell range | Records outside range hidden |
| 8.8 | Filter — Buyback price range | Open filter → set buyback range | Records outside range hidden |
| 8.9 | Multi-column sort | Tap column headers | Sorts correctly; secondary sort shown |
| 8.10 | Manual entry (Admin) | Tap + button, fill fields | New live price record created |
| 8.11 | BB $/oz column | View table | Column header shows "BB $/oz" |

---

## 9. Spot Prices

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 9.1 | Spot prices list | Navigate to Spot Prices | Local spot and global spot prices listed |
| 9.2 | Scrape local spot (Admin) | Tap local sync icon | Local spot prices fetched per retailer; result dialog shown |
| 9.3 | Fetch global spot (Admin) | Tap global sync icon | Global spot prices fetched from configured provider; result dialog shown |
| 9.4 | No provider configured | Fetch global spot with no provider set | "No global spot provider configured" snackbar shown |
| 9.5 | Global spot table | View global spot section | Table shows Provider \| Gold \| Silver \| Platinum \| Updated |
| 9.6 | Filter — Source type | Open filter → select Global | Only global spot records shown |
| 9.7 | Retailer abbreviation | View local spot rows | Retailer abbreviation shown, not full name |

---

## 10. Product Listings

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 10.1 | Listings list | Navigate to Listings | All current listings with date, metal icon, product name, retailer, sell price, $/oz |
| 10.2 | Scrape listings (Admin) | Tap sync icon | Listings fetched and saved; result dialog shown |
| 10.3 | Mapped listing shows profile name | View a mapped listing | Product Profile name shown (not raw scrape name) |
| 10.4 | Unmapped listing indicator | View an unmapped listing | Question mark icon shown in metal column |
| 10.5 | Tap unmapped listing (Admin) | Tap an unmapped row | Navigates to Profile Mapping screen, Listings tab, that listing pinned at top |
| 10.6 | Tap mapped listing (Admin) | Tap a mapped row | Remapping bottom sheet opens with ProfileSearchField |
| 10.7 | Tap any listing (User) | Tap any row as Standard User | Nothing happens |
| 10.8 | Filter — Date preset | Open filter → select Today | Only today's listings shown |
| 10.9 | Filter — Metal Type | Open filter → select Silver | Only silver listings shown (requires mapping) |
| 10.10 | Filter — Metal Form | Open filter → select Coin | Only coin listings shown |
| 10.11 | Filter — Sell Price range | Open filter → set sell range | Listings outside range hidden |
| 10.12 | Filter — $/oz range | Open filter → set $/oz range | Listings outside range hidden |
| 10.13 | Multi-column sort | Tap column headers | Sorts correctly |

---

## 11. Retailers & Providers

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 11.1 | Retailers list | Navigate to Retailers & Providers | Retailers tab shows GBA, GS, IMP with status |
| 11.2 | Retailer detail | Tap a retailer | Scraper settings shown grouped by type (Live Price / Local Spot / Product Listing) |
| 11.3 | Toggle scraper active (Admin) | Tap active toggle on a scraper setting | Status updates immediately |
| 11.4 | Edit scraper setting (Admin) | Tap a scraper setting row | Edit form opens |
| 11.5 | Providers tab | Tap Providers tab | Global spot providers listed with status/description |
| 11.6 | Request provider change (User) | Tap "Request Change" on a provider | Request submitted; confirmation shown |
| 11.7 | Add provider (Admin) | Tap + on Providers tab | Add provider form opens |

---

## 12. Analytics

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 12.1 | Analytics home | Navigate to Analytics | Cards shown for GSR, Local Premium, Local Spread |
| 12.2 | GSR screen | Tap GSR card | Info card → Chart → History table layout |
| 12.3 | GSR filter | Open filter on GSR screen | Global spot provider filter options shown |
| 12.4 | Local Spread screen | Tap Local Spread card | Info card with 3 investment zones → Chart → History table |
| 12.5 | Local Spread investment zones | View info card | Zone labels match user-configured settings |
| 12.6 | Local Premium screen | Tap Local Premium card | Info card → Chart → History table |
| 12.7 | Analytics filter — Metal Type | Open filter on Local Spread/Premium | Metal type filter applies correctly |
| 12.8 | Multi-column sort | Tap history table columns | Sorts correctly |

---

## 13. Settings

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 13.1 | Profile section | Navigate to Settings | "Profile" section shown with username and email |
| 13.2 | Edit username | Tap username → edit → save | Username updates in Settings and AppBar |
| 13.3 | Scraper preferences | View scraper prefs section | Per-metal live price scraper selection shown |
| 13.4 | Global spot provider | View global spot section | Configured provider shown; can change |
| 13.5 | Analytics settings | Tap Analytics Settings | Settings form for GSR, Local Spread, Local Premium thresholds and labels |
| 13.6 | Analytics settings reset | Tap Reset in analytics settings | Values revert to defaults; UI updates immediately |
| 13.7 | Session lock | Lock/unlock settings | Session lock behaves correctly |

---

## 14. Admin Dashboard (Admin Only)

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 14.1 | Access as Admin | Open drawer → Admin Dashboard | Dashboard opens; badge shows pending count |
| 14.2 | Access as User | Navigate to Admin Dashboard URL | Access denied or not visible in menu |
| 14.3 | Metal Types | Tap Metal Types | List of metal types shown; add/edit/delete works |
| 14.4 | Metal Forms | Tap Metal Forms | List of metal forms shown; add/edit/delete works |
| 14.5 | Product Listing Statuses | Tap Product Listing Statuses | Status rules listed; add/toggle/delete works |
| 14.6 | User Approvals | Tap User Approvals | Pending users shown; approve/reject works |
| 14.7 | Change Requests | Tap Change Requests | Pending requests listed; approve/reject works |
| 14.8 | Pending badge | Pending approvals exist | Number badge shown on Admin Dashboard in drawer |

---

## 15. Cross-Cutting Checks

| # | Test | Steps | Expected Result |
|---|------|-------|-----------------|
| 15.1 | Dark theme consistent | Browse all screens | Dark theme applied consistently; no white flash screens |
| 15.2 | Loading states | Open any data screen on slow connection | Loading spinner shown while data fetches |
| 15.3 | Error states | Disable network, refresh any screen | Error message shown (not blank screen or crash) |
| 15.4 | Pull to refresh | Pull down on any list screen | Data reloads |
| 15.5 | Timestamps local time | Check all dates/times in app | All timestamps show local time (not UTC) |
| 15.6 | Retailer abbreviations | View live prices, spot prices, listings | Abbreviation (e.g. GBA) shown, not full name |
| 15.7 | Filter sheets consistent | Open filter on different screens | All filter sheets look and behave the same way |
| 15.8 | Version number | Check AppBar and login screen | Shows v0.1.7 |
| 15.9 | Data isolation | Log in as different user | Each user's holdings/preferences are separate; profiles are shared |
