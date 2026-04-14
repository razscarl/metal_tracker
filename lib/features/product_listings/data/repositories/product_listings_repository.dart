// lib/features/product_listings/data/repositories/product_listings_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_model.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_scrape_result.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_status_model.dart';

class ProductListingsRepository {
  final SupabaseClient _supabase;

  ProductListingsRepository(this._supabase);

  /// Returns the most recent listing per (retailer_id, listing_name) combo.
  ///
  /// "Most recent" is defined by [scrape_date] DESC then [scrape_timestamp] DESC.
  /// Dart-side deduplication ensures each unique product name per retailer
  /// appears only once regardless of how many scrape runs happened today.
  Future<List<ProductListing>> getLatestListings() async {
    try {
      // Get the most recent scrape date available
      final dateRes = await _supabase
          .from('product_listings')
          .select('scrape_date')
          .order('scrape_date', ascending: false)
          .limit(1)
          .maybeSingle();
      if (dateRes == null) return [];
      final latestDate = dateRes['scrape_date'] as String;

      // Fetch all listings from that date with retailer info
      final response = await _supabase
          .from('product_listings')
          .select('*, retailers!inner(name, retailer_abbr)')
          .eq('scrape_date', latestDate)
          .order('listing_sell_price', ascending: true);
      final all = (response as List)
          .map((j) => ProductListing.fromJson(j as Map<String, dynamic>))
          .toList();

      // Deduplicate: keep only the most recent entry per (retailer_id, listing_name).
      // Since we ordered by scrape_timestamp DESC via the general ordering, the
      // first occurrence of each key is the most recent.
      final seen = <String>{};
      return all.where((l) {
        final key = '${l.retailerId}:${l.listingName}';
        return seen.add(key);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching latest product listings: $e');
      return [];
    }
  }

  /// Returns all unmapped listings across all scrape dates, deduplicated by
  /// (retailer_id, listing_name) keeping the most recent entry per combo.
  /// Used by the Profile Mapping screen.
  Future<List<ProductListing>> getUnmappedListings() async {
    try {
      final response = await _supabase
          .from('product_listings')
          .select('*, retailers!inner(name, retailer_abbr)')
          .order('scrape_date', ascending: false)
          .order('scrape_timestamp', ascending: false);

      final all = (response as List)
          .map((j) => ProductListing.fromJson(j as Map<String, dynamic>))
          .toList();

      // Filter unmapped + deduplicate in Dart (most recent per retailer+name)
      final seen = <String>{};
      return all.where((l) {
        if (l.productProfileId != null) return false;
        final key = '${l.retailerId}:${l.listingName}';
        return seen.add(key);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching unmapped product listings: $e');
      return [];
    }
  }

  /// Returns all distinct scrape dates (for date-picker / history browsing).
  Future<List<String>> getScrapeHistory() async {
    try {
      final response = await _supabase
          .from('product_listings')
          .select('scrape_date')
          .order('scrape_date', ascending: false);
      final dates = (response as List)
          .map((j) => j['scrape_date'] as String)
          .toSet()
          .toList();
      return dates;
    } catch (e) {
      debugPrint('Error fetching scrape history: $e');
      return [];
    }
  }

  /// Links (or unlinks) a product listing to a product profile.
  /// Pass null to remove the mapping.
  Future<void> updateListingMapping(
      String listingId, String? productProfileId) async {
    debugPrint('🔗 Updating listing mapping: id=$listingId → profile=$productProfileId');
    final response = await _supabase
        .from('product_listings')
        .update({'product_profile_id': productProfileId})
        .eq('id', listingId)
        .select();
    debugPrint('🔗 Mapping update response: $response');
  }

  // ── Status mappings ────────────────────────────────────────────────────────

  /// Fetches all active rows from `product_listing_statuses` and returns a
  /// `capturedStatus → storedStatus` map for O(1) lookup at save time.
  Future<Map<String, String>> getStatusMappings() async {
    try {
      final response = await _supabase
          .from('product_listing_statuses')
          .select('captured_status, stored_status')
          .eq('is_active', true);
      return {
        for (final row in (response as List))
          (row['captured_status'] as String): (row['stored_status'] as String),
      };
    } catch (e) {
      debugPrint('Error fetching product listing status mappings: $e');
      return {};
    }
  }

  /// Fetches all rows from `product_listing_statuses` as typed models
  /// (used by the admin status management screen).
  Future<List<ProductListingStatus>> getStatusRules() async {
    try {
      final response = await _supabase
          .from('product_listing_statuses')
          .select()
          .order('captured_status');
      return (response as List)
          .map((j) => ProductListingStatus.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching product listing status rules: $e');
      return [];
    }
  }

  // ── Save listings (self-contained, no scraperRepository dependency) ────────

  /// Saves scraped listings to `product_listings`, resolving availability via
  /// [statusMap] (`capturedStatus → storedStatus`) and auto-mapping to existing
  /// product profiles.
  ///
  /// Returns a record with the list of saved listings and any per-row save errors.
  Future<({List<ProductListing> saved, List<String> errors})> saveListings(
    ProductListingScrapeResult result,
    Map<String, String> statusMap,
  ) async {
    final savedListings = <ProductListing>[];
    final saveErrors = <String>[];
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Load today's existing rows for this retailer in one query (for duplicate detection)
    final existingToday = <String, Map<String, dynamic>>{};
    try {
      final rows = await _supabase
          .from('product_listings')
          .select('id, listing_name, product_profile_id')
          .eq('retailer_id', result.retailerId)
          .eq('scrape_date', todayStr);
      for (final row in (rows as List)) {
        existingToday[row['listing_name'] as String] = row as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('🔴 Could not load today\'s listings for duplicate check: $e');
    }

    // Load any prior mapping for each name (from rows on earlier dates)
    final priorMappings = <String, String>{};
    try {
      final rows = await _supabase
          .from('product_listings')
          .select('listing_name, product_profile_id')
          .eq('retailer_id', result.retailerId)
          .not('product_profile_id', 'is', null);
      for (final row in (rows as List)) {
        priorMappings[row['listing_name'] as String] =
            row['product_profile_id'] as String;
      }
    } catch (e) {
      debugPrint('🔴 Could not load prior mappings: $e');
    }

    for (final listing in result.listings) {
      try {
        final mappedProfileId = priorMappings[listing.listingName];
        final availability =
            statusMap[listing.capturedStatus?.toLowerCase()] ?? 'available';
        final payload = {
          'listing_name': listing.listingName,
          'listing_sell_price': listing.sellPrice,
          'retailer_id': result.retailerId,
          'product_profile_id': mappedProfileId,
          'availability': availability,
          'scrape_status': result.status,
          'scrape_error':
              result.errors.isNotEmpty ? result.errors.join('; ') : null,
          'scrape_date': todayStr,
          'scrape_timestamp': now.toIso8601String(),
        };

        final existing = existingToday[listing.listingName];
        if (existing != null) {
          // Already have a row for today — skip to avoid duplicates
          debugPrint('⏭ Skipped duplicate: ${listing.listingName}');
          continue;
        }

        final response = await _supabase
            .from('product_listings')
            .insert(payload)
            .select()
            .single();
        debugPrint('✅ Saved listing: ${listing.listingName}');
        savedListings.add(ProductListing.fromJson(response));
      } catch (e) {
        debugPrint('🔴 Save failed [${listing.listingName}]: $e');
        saveErrors.add('Save failed [${listing.listingName}]: $e');
      }
    }

    return (saved: savedListings, errors: saveErrors);
  }

  // ── Admin: status rule CRUD ────────────────────────────────────────────────

  Future<ProductListingStatus> createStatusRule({
    required String capturedStatus,
    required String storedStatus,
    required String displayLabel,
  }) async {
    final response = await _supabase
        .from('product_listing_statuses')
        .insert({
          'captured_status': capturedStatus.toLowerCase().trim(),
          'stored_status': storedStatus.trim(),
          'display_label': displayLabel.trim(),
        })
        .select()
        .single();
    return ProductListingStatus.fromJson(response);
  }

  Future<void> toggleStatusRule(String id, bool isActive) async {
    await _supabase
        .from('product_listing_statuses')
        .update({'is_active': isActive})
        .eq('id', id);
  }

  Future<void> deleteStatusRule(String id) async {
    await _supabase
        .from('product_listing_statuses')
        .delete()
        .eq('id', id);
  }
}
