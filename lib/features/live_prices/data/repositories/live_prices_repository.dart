// lib/features/live_prices/data/repositories/live_prices_repository.dart
import 'package:flutter/foundation.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_scrape_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    var query = _supabase
        .from('live_prices')
        .select('*, retailers(name, retailer_abbr)');

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
  /// If [retailerIds] is provided, only records from those retailers are considered.
  ///
  /// Per-retailer logic: find each retailer's most recent captureTimestamp,
  /// then find the most recent captureDate across those. Exclude any retailers
  /// whose most recent timestamp is not on that date (i.e. stale retailers are
  /// not included). Within included retailers, only use records at their exact
  /// max timestamp.
  Future<Map<String, dynamic>?> _getBestPrice(
    String metalType, {
    required bool isBuyback,
    Set<String>? retailerIds,
  }) async {
    try {
      // Fetch all records for this metal type joined with profiles and retailers
      final response = await _supabase
          .from('live_prices')
          .select('''
            sell_price,
            buyback_price,
            retailer_id,
            capture_timestamp,
            retailers(name, retailer_abbr),
            product_profiles!inner(weight, weight_unit, purity, metal_type)
          ''')
          .eq('product_profiles.metal_type', metalType);

      if ((response as List).isEmpty) return null;

      // Step 1: Per-retailer max captureTimestamp
      final retailerMaxTs = <String, DateTime>{};
      for (final record in response) {
        final rid = record['retailer_id'] as String?;
        if (rid == null) continue;
        if (retailerIds != null && !retailerIds.contains(rid)) continue;
        final tsStr = record['capture_timestamp'] as String?;
        if (tsStr == null) continue;
        final ts = DateTime.parse(tsStr);
        if (!retailerMaxTs.containsKey(rid) || ts.isAfter(retailerMaxTs[rid]!)) {
          retailerMaxTs[rid] = ts;
        }
      }

      if (retailerMaxTs.isEmpty) return null;

      // Step 2: Find the most recent captureDate among all retailers' max timestamps
      DateTime? latestDate;
      for (final ts in retailerMaxTs.values) {
        final date = DateTime(ts.year, ts.month, ts.day);
        if (latestDate == null || date.isAfter(latestDate)) {
          latestDate = date;
        }
      }
      if (latestDate == null) return null;

      // Step 3: Exclude retailers whose max timestamp is NOT on that date
      final includedRetailers = retailerMaxTs.entries
          .where((e) {
            final ts = e.value;
            final d = DateTime(ts.year, ts.month, ts.day);
            return d.year == latestDate!.year &&
                d.month == latestDate.month &&
                d.day == latestDate.day;
          })
          .map((e) => e.key)
          .toSet();

      // Step 4: Per included retailer, only use records at their max timestamp
      double? bestValue;
      String? bestRetailer;
      String? bestRetailerAbbr;

      for (final record in response) {
        final rid = record['retailer_id'] as String?;
        if (rid == null || !includedRetailers.contains(rid)) continue;

        final tsStr = record['capture_timestamp'] as String?;
        if (tsStr == null) continue;
        final ts = DateTime.parse(tsStr);
        // Only process records at this retailer's max timestamp (within same minute is fine)
        if (ts != retailerMaxTs[rid]) continue;

        final price = isBuyback
            ? (record['buyback_price'] as num?)?.toDouble()
            : (record['sell_price'] as num?)?.toDouble();
        if (price == null) continue;

        final normalized = WeightCalculations.pricePerPureOunce(
          totalPrice: price,
          weight: (record['product_profiles']['weight'] as num).toDouble(),
          unit: WeightUnit.fromString(record['product_profiles']['weight_unit']),
          purity: (record['product_profiles']['purity'] as num).toDouble(),
        );

        final retailerData = record['retailers'] as Map<String, dynamic>?;
        final rName = retailerData?['name'] as String?;
        final rAbbr = retailerData?['retailer_abbr'] as String?;

        if (bestValue == null) {
          bestValue = normalized;
          bestRetailer = rName;
          bestRetailerAbbr = rAbbr;
        } else if (isBuyback ? normalized > bestValue : normalized < bestValue) {
          bestValue = normalized;
          bestRetailer = rName;
          bestRetailerAbbr = rAbbr;
        }
      }

      if (bestValue == null) return null;

      return {
        'pricePerOz': bestValue,
        'retailerName': bestRetailer,
        'retailerAbbr': bestRetailerAbbr,
        'metalType': metalType,
      };
    } catch (e) {
      debugPrint('Error calculating best $metalType price: $e');
      return null;
    }
  }

  /// Returns the lowest normalized sell price available for acquisition.
  Future<Map<String, dynamic>?> getBestSellPrice(
    String metalType, {
    Set<String>? retailerIds,
  }) =>
      _getBestPrice(metalType, isBuyback: false, retailerIds: retailerIds);

  /// Returns the highest normalized buyback price available for valuation.
  Future<Map<String, dynamic>?> getBestBuybackPrice(
    String metalType, {
    Set<String>? retailerIds,
  }) =>
      _getBestPrice(metalType, isBuyback: true, retailerIds: retailerIds);

  /// Returns all live prices joined with product profile data for spread analysis.
  /// Only rows with a mapped product profile and at least one price are included.
  Future<List<Map<String, dynamic>>> getLivePricesWithProfiles() async {
    try {
      final response = await _supabase
          .from('live_prices')
          .select(
              'capture_date, capture_timestamp, sell_price, buyback_price, '
              'product_profiles!inner(metal_type, weight, weight_unit, purity)')
          .order('capture_date', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching live prices with profiles: $e');
      return [];
    }
  }

  Future<void> deleteLivePrice(String id) async {
    await _supabase
        .from('live_prices')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> updateLivePrice({
    required String id,
    double? sellPrice,
    double? buybackPrice,
  }) async {
    await _supabase
        .from('live_prices')
        .update({
          'sell_price': sellPrice,
          'buyback_price': buybackPrice,
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Links an unmapped live price to a product profile.
  Future<LivePrice> updateLivePriceMapping(
    String livePriceId,
    String productProfileId,
  ) async {
    final response = await _supabase
        .from('live_prices')
        .update({'product_profile_id': productProfileId})
        .eq('id', livePriceId)
        .eq('user_id', _userId)
        .select()
        .single();

    return LivePrice.fromJson(response);
  }

  // ==========================================
  // SCRAPE → SAVE
  // ==========================================

  /// Saves live price scrape results with auto-mapping from prior records.
  Future<List<LivePrice>> saveLivePrices(
    LivePriceScrapeResult result,
    Map<String, String> metalTypeToLivePriceName,
  ) async {
    final savedPrices = <LivePrice>[];
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    for (final entry in result.prices.entries) {
      final metalType = entry.key;
      final prices = entry.value;
      final livePriceName = metalTypeToLivePriceName[metalType];

      if (livePriceName == null) {
        debugPrint('Warning: No live price name for $metalType');
        continue;
      }

      try {
        // Try to find an existing record with a product profile mapping
        final existingResponse = await _supabase
            .from('live_prices')
            .select('product_profile_id')
            .eq('user_id', _userId)
            .eq('retailer_id', result.retailerId)
            .eq('live_price_name', livePriceName)
            .not('product_profile_id', 'is', null)
            .limit(1)
            .maybeSingle();

        final mappedProfileId =
            existingResponse?['product_profile_id'] as String?;

        final insertResponse = await _supabase.from('live_prices').insert({
          'user_id': _userId,
          'retailer_id': result.retailerId,
          'metal_type': metalType,
          'live_price_name': livePriceName,
          'product_profile_id': mappedProfileId,
          'capture_date': today,
          'capture_timestamp': now.toIso8601String(),
          'sell_price': prices['sell'],
          'buyback_price': prices['buyback'],
          'scrape_status': result.scrapeStatus,
        }).select();

        if (insertResponse.isNotEmpty) {
          savedPrices.add(LivePrice.fromJson(insertResponse[0]));
        }
      } catch (e) {
        debugPrint('Error saving live price for $metalType: $e');
      }
    }

    return savedPrices;
  }

  // ── Investment Guide ──────────────────────────────────────────────────────────

  /// Returns the most-recent sell and buyback prices for a specific
  /// (retailer, profile) pair. Used by the Investment Guide spread scoring.
  Future<Map<String, dynamic>?> getLatestLivePriceForProfile(
    String retailerId,
    String productProfileId,
  ) async {
    try {
      final response = await _supabase
          .from('live_prices')
          .select('sell_price, buyback_price, capture_timestamp')
          .eq('user_id', _userId)
          .eq('retailer_id', retailerId)
          .eq('product_profile_id', productProfileId)
          .order('capture_timestamp', ascending: false)
          .limit(1)
          .maybeSingle();
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching live price for profile: $e');
      return null;
    }
  }
}
