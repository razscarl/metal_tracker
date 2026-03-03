// lib/features/scrapers/data/repositories/scraper_repository.dart:Scraper Repository
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../product_listings/data/models/product_listing_model.dart';
import '../../../spot_prices/data/models/local_spot_price_model.dart';
import '../../../spot_prices/data/models/global_spot_price_model.dart';
import '../../data/models/scrape_result_models.dart';
import '../../../retailers/data/models/retailer_scraper_setting_model.dart';
import '../../../live_prices/data/models/live_price_model.dart';

class ScraperRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  // ==========================================
  // LIVE PRICES
  // ==========================================

  /// Save live price scrape results to database with auto-mapping
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
        // Step 1: Try to find existing live price with same name & retailer that HAS a product_profile_id
        String? mappedProfileId;

        final existingResponse = await _supabase
            .from('live_prices')
            .select('product_profile_id')
            .eq('user_id', _userId)
            .eq('retailer_id', result.retailerId)
            .eq('live_price_name', livePriceName)
            .not('product_profile_id', 'is', null)
            .limit(1)
            .maybeSingle();

        if (existingResponse != null) {
          // Found existing live price with mapping - copy the product_profile_id
          mappedProfileId = existingResponse['product_profile_id'] as String?;
          debugPrint('🔵 Auto-mapped $livePriceName to profile $mappedProfileId');
        }

        // Step 2: Insert new live price (always save, regardless of mapping)
        final insertResponse = await _supabase.from('live_prices').insert({
          'user_id': _userId,
          'retailer_id': result.retailerId,
          'live_price_name': livePriceName,
          'product_profile_id': mappedProfileId,
          'capture_date': today,
          'capture_timestamp': now.toIso8601String(),
          'sell_price': prices['sell'],
          'buyback_price': prices['buyback'],
          'scrape_status': result.scrapeStatus,
        }).select();

        // Handle the response - it's a list, take the first element
        if (insertResponse.isNotEmpty) {
          savedPrices.add(LivePrice.fromJson(insertResponse[0]));
        }
      } catch (e) {
        // Log error but continue with other metals
        debugPrint('Error saving live price for $metalType: $e');
      }
    }

    return savedPrices;
  }

  /// Get unmapped live prices from most recent scrape
  Future<List<LivePrice>> getUnmappedLivePrices() async {
    try {
      final response = await _supabase
          .from('live_prices')
          .select()
          .eq('user_id', _userId)
          .isFilter('product_profile_id', null)
          .order('capture_date', ascending: false)
          .order('capture_timestamp', ascending: false);

      return (response as List)
          .map((json) => LivePrice.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching unmapped live prices: $e');
      return [];
    }
  }

  /// Update live price mapping to product profile
  Future<LivePrice?> updateLivePriceMapping(
    String livePriceId,
    String productProfileId,
  ) async {
    try {
      final response = await _supabase
          .from('live_prices')
          .update({'product_profile_id': productProfileId})
          .eq('id', livePriceId)
          .eq('user_id', _userId)
          .select()
          .single();

      return LivePrice.fromJson(response);
    } catch (e) {
      debugPrint('Error updating live price mapping: $e');
      return null;
    }
  }

  // ==========================================
  // PRODUCT LISTINGS
  // ==========================================

  /// Save product listing scrape results with auto-mapping
  Future<List<ProductListing>> saveProductListings(
    ProductListingScrapeResult result,
  ) async {
    final savedListings = <ProductListing>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final product in result.products) {
      try {
        // Step 1: Try to find existing listing with same name for auto-mapping
        String? mappedProfileId;

        final existingResponse = await _supabase
            .from('product_listings')
            .select('product_profile_id')
            .eq('retailer_id', result.retailerId)
            .eq('listing_name', product.listingName)
            .not('product_profile_id', 'is', null)
            .maybeSingle();

        if (existingResponse != null) {
          // Found existing listing with mapping - copy the profile_id
          mappedProfileId = existingResponse['product_profile_id'] as String?;
        }

        // Step 2: Insert new listing (always append, never update)
        final response = await _supabase
            .from('product_listings')
            .insert({
              'listing_name': product.listingName,
              'listing_sell_price': product.listingSellPrice,
              'retailer_id': result.retailerId,
              'product_profile_id': mappedProfileId,
              'scrape_status': result.scrapeStatus,
              'scrape_error': result.scrapeErrors.isNotEmpty
                  ? result.scrapeErrors.join('; ')
                  : null,
              'scrape_date': today.toIso8601String().split('T')[0],
              'scrape_timestamp': now.toIso8601String(),
            })
            .select()
            .single();

        savedListings.add(ProductListing.fromJson(response));
      } catch (e) {
        debugPrint('Error saving product listing ${product.listingName}: $e');
      }
    }

    return savedListings;
  }

  /// Get unmapped product listings from most recent scrape
  Future<List<ProductListing>> getUnmappedListings() async {
    try {
      // Get most recent scrape date
      final dateResponse = await _supabase
          .from('product_listings')
          .select('scrape_date')
          .order('scrape_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (dateResponse == null) return [];

      final mostRecentDate = dateResponse['scrape_date'] as String;

      // Get all unmapped listings from that date
      final response = await _supabase
          .from('product_listings')
          .select()
          .eq('scrape_date', mostRecentDate)
          .isFilter('product_profile_id', null)
          .order('listing_name');

      return (response as List)
          .map((json) => ProductListing.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching unmapped listings: $e');
      return [];
    }
  }

  /// Get all product listings for a specific retailer and date
  Future<List<ProductListing>> getProductListings({
    String? retailerId,
    DateTime? forDate,
  }) async {
    try {
      var query = _supabase.from('product_listings').select();

      if (retailerId != null) {
        query = query.eq('retailer_id', retailerId);
      }

      if (forDate != null) {
        query =
            query.eq('scrape_date', forDate.toIso8601String().split('T')[0]);
      }

      final response = await query
          .order('scrape_date', ascending: false)
          .order('listing_name');

      return (response as List)
          .map((json) => ProductListing.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching product listings: $e');
      return [];
    }
  }

  /// Update product listing mapping to product profile
  Future<ProductListing?> updateListingMapping(
    String listingId,
    String productProfileId,
  ) async {
    try {
      final response = await _supabase
          .from('product_listings')
          .update({'product_profile_id': productProfileId})
          .eq('id', listingId)
          .select()
          .single();

      return ProductListing.fromJson(response);
    } catch (e) {
      debugPrint('Error updating listing mapping: $e');
      return null;
    }
  }

  // ==========================================
  // LOCAL SPOT PRICES
  // ==========================================

  /// Save local spot price scrape results
  Future<List<LocalSpotPrice>> saveLocalSpotPrices(
    LocalSpotScrapeResult result,
  ) async {
    final savedPrices = <LocalSpotPrice>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final entry in result.spotPrices.entries) {
      final metalType = entry.key;
      final spotPrice = entry.value;

      try {
        final response = await _supabase
            .from('local_spot_prices')
            .insert({
              'retailer_id': result.retailerId,
              'metal_type': metalType,
              'local_spot_price': spotPrice,
              'scrape_date': today.toIso8601String().split('T')[0],
              'scrape_timestamp': now.toIso8601String(),
              'scrape_status': result.scrapeStatus,
              'scrape_error': result.scrapeErrors.isNotEmpty
                  ? result.scrapeErrors.join('; ')
                  : null,
            })
            .select()
            .single();

        savedPrices.add(LocalSpotPrice.fromJson(response));
      } catch (e) {
        debugPrint('Error saving local spot price for $metalType: $e');
      }
    }

    return savedPrices;
  }

  /// Get local spot prices for a retailer
  Future<List<LocalSpotPrice>> getLocalSpotPrices({
    String? retailerId,
    DateTime? forDate,
  }) async {
    try {
      var query = _supabase.from('local_spot_prices').select();

      if (retailerId != null) {
        query = query.eq('retailer_id', retailerId);
      }

      if (forDate != null) {
        query =
            query.eq('scrape_date', forDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('scrape_date', ascending: false);

      return (response as List)
          .map((json) => LocalSpotPrice.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching local spot prices: $e');
      return [];
    }
  }

  // ==========================================
  // GLOBAL SPOT PRICES
  // ==========================================

  /// Save global spot price
  Future<GlobalSpotPrice?> saveGlobalSpotPrice({
    required String metalType,
    required double globalSpotPrice,
    required String source,
    String fetchStatus = 'success',
    String? fetchError,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final response = await _supabase
          .from('global_spot_prices')
          .insert({
            'metal_type': metalType,
            'global_spot_price': globalSpotPrice,
            'source': source,
            'fetch_date': today.toIso8601String().split('T')[0],
            'fetch_timestamp': now.toIso8601String(),
            'fetch_status': fetchStatus,
            'fetch_error': fetchError,
          })
          .select()
          .single();

      return GlobalSpotPrice.fromJson(response);
    } catch (e) {
      debugPrint('Error saving global spot price for $metalType: $e');
      return null;
    }
  }

  /// Get global spot prices
  Future<List<GlobalSpotPrice>> getGlobalSpotPrices({
    DateTime? forDate,
  }) async {
    try {
      var query = _supabase.from('global_spot_prices').select();

      if (forDate != null) {
        query = query.eq('fetch_date', forDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('fetch_date', ascending: false);

      return (response as List)
          .map((json) => GlobalSpotPrice.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching global spot prices: $e');
      return [];
    }
  }

  // ==========================================
  // RETAILER SCRAPER SETTINGS
  // ==========================================

  /// Get all scraper settings
  Future<List<RetailerScraperSetting>> getRetailerScraperSettings({
    String? retailerId,
    String? scraperType,
  }) async {
    try {
      var query = _supabase.from('retailer_scraper_settings').select();

      if (retailerId != null) {
        query = query.eq('retailer_id', retailerId);
      }
      if (scraperType != null) {
        query = query.eq('scraper_type', scraperType);
      }

      query = query.eq('is_active', true);

      final response = await query;
      return (response as List)
          .map((json) => RetailerScraperSetting.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching scraper settings: $e');
      return [];
    }
  }

  /// Get scraper settings for specific scraper type and retailer
  Future<List<RetailerScraperSetting>> getScraperSettingsForScraper({
    required String retailerId,
    required String scraperType,
  }) async {
    try {
      final response = await _supabase
          .from('retailer_scraper_settings')
          .select()
          .eq('retailer_id', retailerId)
          .eq('scraper_type', scraperType)
          .eq('is_active', true)
          .order('metal_type');

      return (response as List)
          .map((json) => RetailerScraperSetting.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching scraper settings: $e');
      return [];
    }
  }

  /// Create scraper setting
  Future<RetailerScraperSetting?> createScraperSetting({
    required String retailerId,
    required String scraperType,
    String? metalType,
    required String searchString,
    String? searchUrl, // Add this
    bool isActive = true,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('retailer_scraper_settings')
          .insert({
            'retailer_id': retailerId,
            'scraper_type': scraperType,
            'metal_type': metalType,
            'search_string': searchString,
            'search_url': searchUrl, // Add this
            'is_active': isActive,
            'notes': notes,
          })
          .select()
          .single();

      return RetailerScraperSetting.fromJson(response);
    } catch (e) {
      debugPrint('Error creating scraper setting: $e');
      return null;
    }
  }

  /// Update scraper setting
  Future<RetailerScraperSetting?> updateScraperSetting({
    required String settingId,
    String? searchString,
    bool? isActive,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (searchString != null) updates['search_string'] = searchString;
      if (isActive != null) updates['is_active'] = isActive;
      if (notes != null) updates['notes'] = notes;

      if (updates.isEmpty) return null;

      final response = await _supabase
          .from('retailer_scraper_settings')
          .update(updates)
          .eq('id', settingId)
          .select()
          .single();

      return RetailerScraperSetting.fromJson(response);
    } catch (e) {
      debugPrint('Error updating scraper setting: $e');
      return null;
    }
  }

  /// Delete scraper setting
  Future<bool> deleteScraperSetting(String settingId) async {
    try {
      await _supabase
          .from('retailer_scraper_settings')
          .delete()
          .eq('id', settingId);
      return true;
    } catch (e) {
      debugPrint('Error deleting scraper setting: $e');
      return false;
    }
  }
}
