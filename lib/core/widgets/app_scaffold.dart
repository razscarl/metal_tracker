// lib/core/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/home/presentation/providers/home_providers.dart';

/// Shared scaffold used by all screens. Injects a persistent footer bar
/// showing last-updated timestamps for Live Prices, Product Listings, and
/// Spot Prices.
class AppScaffold extends ConsumerWidget {
  final PreferredSizeWidget appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.drawer,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timestampsAsync = ref.watch(footerTimestampsProvider);

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.backgroundDark,
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: body,
      bottomNavigationBar: timestampsAsync.when(
        data: (ts) => _FooterBar(timestamps: ts),
        loading: () => const _FooterBar(
          timestamps: (
            livePrices: null,
            productListings: null,
            spotPrices: null,
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _FooterBar extends StatelessWidget {
  final ({DateTime? livePrices, DateTime? productListings, DateTime? spotPrices})
      timestamps;

  const _FooterBar({required this.timestamps});

  String _fmt(DateTime? dt) {
    if (dt == null) return 'Never';
    return DateFormat('EEE d/M/y').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SafeArea(
        top: false,
        child: Text(
          'Live Prices: ${_fmt(timestamps.livePrices)}'
          '   |   '
          'Product Listings: ${_fmt(timestamps.productListings)}'
          '   |   '
          'Spot Prices: ${_fmt(timestamps.spotPrices)}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
