import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';

class InvestmentGuideContext {
  final double? currentGsr;
  final bool? gsrMovementUp;
  final List<LocalPremiumEntry> premiumSummary;
  final List<LocalSpreadEntry> spreadSummary;

  const InvestmentGuideContext({
    this.currentGsr,
    this.gsrMovementUp,
    required this.premiumSummary,
    required this.spreadSummary,
  });

  LocalPremiumEntry? premiumFor(String metalType) {
    try {
      return premiumSummary.firstWhere((e) => e.metalType == metalType);
    } catch (_) {
      return null;
    }
  }

  LocalSpreadEntry? spreadFor(String metalType) {
    try {
      return spreadSummary.firstWhere((e) => e.metalType == metalType);
    } catch (_) {
      return null;
    }
  }
}
