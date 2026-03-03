// lib/features/live_prices/data/repositories/live_prices_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/live_price_model.dart';
import '../../../../core/utils/weight_converter.dart';
import '../../../../core/constants/app_constants.dart';

class LivePricesRepository {
  final SupabaseClient _supabase;

  LivePricesRepository(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  // ==========================================
  // LIVE PRICES CRUD
  // ==========================================

  Future<LivePrice> createLivePrice({
    required String retailerId,
    required String productProfileId,
    required DateTime captureDate,
    double? sellPrice,
    double? buybackPrice,
  }) async {
    final response = await _supabase
        .from('live_prices')
        .insert({
          'user_id': _userId,
          'retailer_id': retailerId,
          'product_profile_id': productProfileId,
          'capture_date': captureDate.toIso8601String().split('T')[0],
          'capture_timestamp': DateTime.now().toIso8601String(),
          'sell_price': sellPrice,
          'buyback_price': buybackPrice,
          'scrape_status': 'success',
        })
        .select()
        .single();

    return LivePrice.fromJson(response);
  }

  Future<List<LivePrice>> getLivePrices({DateTime? forDate}) async {
    var query = _supabase.from('live_prices').select().eq('user_id', _userId);

    if (forDate != null) {
      query = query.eq('capture_date', forDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('capture_date', ascending: false);

    return (response as List).map((json) => LivePrice.fromJson(json)).toList();
  }

  // ==========================================
  // MARKET VALUATION LOGIC
  // ==========================================

  /// Finds the best (lowest sell or highest buyback) normalized price for a metal.
  /// Used for both Portfolio Valuation (Buyback) and Market Benchmarks (Sell).
  Future<Map<String, dynamic>?> _getBestPrice(String metalType,
      {required bool isBuyback}) async {
    try {
      // 1. Determine the most recent date with price data
      final latestDateRecord = await _supabase
          .from('live_prices')
          .select('capture_date')
          .order('capture_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latestDateRecord == null) return null;
      final latestDate = latestDateRecord['capture_date'];

      // 2. Fetch prices joined with profiles and retailers
      final response = await _supabase
          .from('live_prices')
          .select('''
            sell_price, 
            buyback_price, 
            retailers(name),
            product_profiles!inner(weight, weight_unit, purity, metal_type)
          ''')
          .eq('product_profiles.metal_type', metalType)
          .eq('capture_date', latestDate);

      if (response == null || (response as List).isEmpty) return null;

      double? bestValue;
      String? bestRetailer;

      for (var record in (response as List)) {
        final price = isBuyback
            ? (record['buyback_price'] as num?)?.toDouble()
            : (record['sell_price'] as num?)?.toDouble();

        if (price == null) continue;

        // Normalization via Weight Converter Utility
        final normalized = WeightCalculations.pricePerPureOunce(
          totalPrice: price,
          weight: (record['product_profiles']['weight'] as num).toDouble(),
          unit:
              WeightUnit.fromString(record['product_profiles']['weight_unit']),
          purity: (record['product_profiles']['purity'] as num).toDouble(),
        );

        if (bestValue == null) {
          bestValue = normalized;
          bestRetailer = record['retailers']['name'];
        } else {
          if (isBuyback) {
            // Valuation Logic: We want the highest price a retailer pays us
            if (normalized > bestValue) {
              bestValue = normalized;
              bestRetailer = record['retailers']['name'];
            }
          } else {
            // Acquisition Logic: We want the lowest price we pay them
            if (normalized < bestValue) {
              bestValue = normalized;
              bestRetailer = record['retailers']['name'];
            }
          }
        }
      }

      if (bestValue == null) return null;

      return {
        'pricePerOz': bestValue,
        'retailerName': bestRetailer,
        'metalType': metalType,
      };
    } catch (e) {
      print('Error calculating best $metalType price: $e');
      return null;
    }
  }

  /// Returns the lowest normalized sell price available for acquisition.
  Future<Map<String, dynamic>?> getBestSellPrice(String metalType) =>
      _getBestPrice(metalType, isBuyback: false);

  /// Returns the highest normalized buyback price available for valuation.
  Future<Map<String, dynamic>?> getBestBuybackPrice(String metalType) =>
      _getBestPrice(metalType, isBuyback: true);
}
