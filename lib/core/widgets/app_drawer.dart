// lib/core/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:metal_tracker/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:metal_tracker/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/holdings_screen.dart';
import 'package:metal_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:metal_tracker/features/investment_guide/presentation/screens/investment_guide_screen.dart';
import 'package:metal_tracker/features/live_prices/presentation/screens/live_prices_screen.dart';
import 'package:metal_tracker/features/product_profiles/presentation/screens/product_profile_mapping_screen.dart';
import 'package:metal_tracker/features/product_listings/presentation/screens/product_listings_screen.dart';
import 'package:metal_tracker/features/product_profiles/presentation/screens/product_profiles_screen.dart';
import 'package:metal_tracker/features/retailers/presentation/screens/retailers_screen.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:metal_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:metal_tracker/features/spot_prices/presentation/screens/spot_prices_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';

    final profileAsync = ref.watch(userProfileNotifierProvider);
    final username = profileAsync.valueOrNull?.username;
    final displayName = username?.isNotEmpty == true ? username! : email;
    final initials = _initials(displayName);

    final isAdmin = ref.watch(isAdminProvider);
    final pendingCount = isAdmin
        ? ref.watch(pendingRequestCountProvider).valueOrNull ?? 0
        : 0;

    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: Column(
        children: [
          // ── User Header ──────────────────────────────────────────────────
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.backgroundCard),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryGold.withAlpha(50),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            username?.isNotEmpty == true
                                ? username!
                                : 'Metal Tracker',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (isAdmin) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Administrator',
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          const Text(
                            'Tap to manage profile →',
                            style: TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Menu Items ───────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader('PORTFOLIO'),
                _buildMenuItem(context, Icons.home, 'Home',
                    const HomeScreen()),
                _buildMenuItem(context, Icons.inventory_2, 'Holdings',
                    const HoldingsScreen()),
                _buildMenuItem(context, Icons.category, 'Product Profiles',
                    const ProductProfilesScreen()),
                if (isAdmin)
                  _buildMenuItem(context, Icons.link_rounded, 'Profile Mapping',
                      const ProductProfileMappingScreen()),
                _buildSectionHeader('MARKET DATA'),
                _buildMenuItem(context, Icons.price_change, 'Live Prices',
                    const LivePricesScreen()),
                _buildMenuItem(context, Icons.show_chart, 'Spot Prices',
                    const SpotPricesScreen()),
                _buildMenuItem(context, Icons.shopping_cart, 'Listings',
                    const ProductListingsScreen()),
                _buildMenuItem(context, Icons.lightbulb_outline, 'Inv. Guide',
                    const InvestmentGuideScreen()),
                _buildSectionHeader('MANAGEMENT'),
                _buildMenuItem(context, Icons.store, 'Retailers & Providers',
                    const RetailersScreen()),
                _buildMenuItem(context, Icons.pie_chart, 'Analytics',
                    const AnalyticsScreen()),
                if (isAdmin) ...[
                  _buildSectionHeader('ADMINISTRATION'),
                  _buildAdminMenuItem(
                    context,
                    Icons.admin_panel_settings,
                    'Admin Dashboard',
                    const AdminDashboardScreen(),
                    badge: pendingCount,
                  ),
                ],
                const Divider(color: Colors.white10),
                _buildMenuItem(context, Icons.settings, 'Settings',
                    const SettingsScreen()),
                const Divider(color: Colors.white10),
                if (user != null)
                  ListTile(
                    leading: const Icon(Icons.logout,
                        color: AppColors.primaryGold, size: 22),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 15),
                    ),
                    onTap: () async {
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                      await Supabase.instance.client.auth.signOut();
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.login,
                        color: AppColors.primaryGold, size: 22),
                    title: const Text(
                      'Sign In',
                      style: TextStyle(
                          color: AppColors.primaryGold, fontSize: 15),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String nameOrEmail) {
    final trimmed = nameOrEmail.trim();
    if (trimmed.isEmpty) return '?';
    // If it looks like an email, use first 2 chars of local part
    if (trimmed.contains('@')) {
      final local = trimmed.split('@').first;
      return local.length >= 2
          ? local.substring(0, 2).toUpperCase()
          : local.toUpperCase();
    }
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words.first[0]}${words.last[0]}'.toUpperCase();
    }
    return trimmed.length >= 2
        ? trimmed.substring(0, 2).toUpperCase()
        : trimmed[0].toUpperCase();
  }

  Widget _buildAdminMenuItem(
      BuildContext context, IconData icon, String title, Widget screen,
      {int badge = 0}) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 22),
          if (badge > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.lossRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
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
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
