// lib/core/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/holdings/presentation/screens/holdings_screen.dart';
import '../../features/product_profiles/presentation/screens/add_product_profile_screen.dart';
import '../../features/live_prices/presentation/screens/live_price_mapping_screen.dart';
import '../../features/product_listings/presentation/screens/product_listings_screen.dart';
// import '../../features/spot_prices/presentation/screens/spot_prices_screen.dart';
import '../../features/retailers/presentation/screens/retailers_screen.dart';
// import '../../features/scraper/presentation/screens/scraper_settings_screen.dart';
// import '../../features/analytics/presentation/screens/analytics_screen.dart';
// import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: Column(
        children: [
          // Drawer Header
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, color: AppColors.primaryGold, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'METAL TRACKER',
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader('PORTFOLIO'),
                _buildMenuItem(
                  context,
                  Icons.home,
                  'Home',
                  const HomeScreen(),
                ),
                _buildMenuItem(
                  context,
                  Icons.inventory_2,
                  'Holdings',
                  const HoldingsScreen(),
                ),
                /*_buildMenuItem(
                  context,
                  Icons.category,
                  'Product Profiles',
                  const ProductProfilesScreen(),
                ),*/
                /*_buildSectionHeader('MARKET DATA'),
                _buildMenuItem(
                  context,
                  Icons.price_change,
                  'Live Prices',
                  const LivePricesScreen(),
                ),*/
                _buildMenuItem(
                  context,
                  Icons.shopping_cart,
                  'Product Listings',
                  const ProductListingsScreen(),
                ),
                /*_buildMenuItem(
                  context,
                  Icons.show_chart,
                  'Spot Prices',
                  const SpotPricesScreen(),
                ),*/
                _buildSectionHeader('MANAGEMENT'),
                _buildMenuItem(
                  context,
                  Icons.store,
                  'Retailers',
                  const RetailersScreen(),
                ),
                /*_buildMenuItem(
                  context,
                  Icons.settings_applications,
                  'Scraper Settings',
                  const ScraperSettingsScreen(),
                ),*/
                /*_buildMenuItem(
                  context,
                  Icons.pie_chart,
                  'Analytics',
                  const AnalyticsScreen(),
                ),*/
                const Divider(color: Colors.white10),
                /*_buildMenuItem(
                  context,
                  Icons.settings,
                  'Settings',
                  const SettingsScreen(),
                ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGold, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
