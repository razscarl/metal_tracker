// lib/features/product_listings/presentation/providers/product_listings_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/constants/scraper_constants.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/admin/data/models/automation_job_model.dart';
import 'package:metal_tracker/features/admin/data/models/automation_schedule_model.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_model.dart';
import 'package:metal_tracker/features/product_listings/data/services/gba_product_listing_service.dart';
import 'package:metal_tracker/features/product_listings/data/services/gs_product_listing_service.dart';
import 'package:metal_tracker/features/product_listings/data/services/imp_product_listing_service.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

part 'product_listings_providers.g.dart';

/// Per-retailer report returned by [ProductListingsNotifier.scrapeAll].
class RetailerListingReport {
  final String retailerName;

  /// 'success' | 'partial' | 'failed' | 'error' | 'no_settings'
  final String status;

  /// Number of listings scraped from the retailer's website.
  final int scrapedCount;

  /// Number of listings successfully saved to the database.
  final int savedCount;

  final List<String> errors;

  const RetailerListingReport({
    required this.retailerName,
    required this.status,
    required this.scrapedCount,
    required this.savedCount,
    required this.errors,
  });
}

@riverpod
class ProductListingsNotifier extends _$ProductListingsNotifier {
  @override
  Future<List<ProductListing>> build() async {
    final all = await ref
        .watch(productListingsRepositoryProvider)
        .getLatestListings();
    final retailerIds = await ref.watch(userRetailerIdSetProvider.future);
    final metalNames = await ref.watch(userMetalNameSetProvider.future);
    return all.where((l) {
      if (retailerIds.isNotEmpty && !retailerIds.contains(l.retailerId)) {
        return false;
      }
      if (metalNames.isNotEmpty) {
        final metal = l.metalType?.toLowerCase();
        if (metal == null || !metalNames.contains(metal)) return false;
      }
      return true;
    }).toList();
  }

  /// Scrapes product listings from configured retailers.
  /// [restrictToRetailerIds] limits scraping to specific retailers (admin selection).
  /// Null = scrape all (used by automated jobs).
  Future<List<RetailerListingReport>> scrapeAll({
    List<String>? restrictToRetailerIds,
  }) async {
    final reports = <RetailerListingReport>[];
    state = const AsyncValue.loading();

    try {
      final productListingsRepo = ref.read(productListingsRepositoryProvider);

      // Load status mappings once before the retailer loop
      Map<String, String> statusMap;
      try {
        statusMap = await productListingsRepo.getStatusMappings();
      } catch (e) {
        // Non-fatal — proceed with empty map (all listings default to 'available')
        statusMap = {};
        reports.add(RetailerListingReport(
          retailerName: 'Status Config',
          status: 'error',
          scrapedCount: 0,
          savedCount: 0,
          errors: ['Failed to load status mappings: $e'],
        ));
      }

      final retailers =
          await ref.read(retailerRepositoryProvider).getRetailers();

      final activeRetailers = retailers
          .where((r) => r.isActive)
          .where((r) =>
              restrictToRetailerIds == null ||
              restrictToRetailerIds.contains(r.id))
          .toList();
      if (activeRetailers.isEmpty) {
        reports.add(const RetailerListingReport(
          retailerName: 'System',
          status: 'no_settings',
          scrapedCount: 0,
          savedCount: 0,
          errors: ['No active retailers configured.'],
        ));
      }

      for (final retailer in activeRetailers) {
        final settings = await ref
            .read(retailerRepositoryProvider)
            .getScraperSettingsForType(
              retailer.id,
              ScraperType.productListing,
            );

        final activeSettings =
            settings.where((s) => s.isActive).toList();
        if (activeSettings.isEmpty) {
          reports.add(RetailerListingReport(
            retailerName: retailer.name,
            status: 'no_settings',
            scrapedCount: 0,
            savedCount: 0,
            errors: [
              settings.isEmpty
                  ? 'Product listings not configured for this retailer.'
                  : 'Product listings disabled for this retailer.',
            ],
          ));
          continue;
        }

        final abbr = retailer.retailerAbbr?.toUpperCase();

        // Log manual scrape to automation_jobs (best-effort — never blocks scraping)
        AutomationJob? job;
        try {
          job = await ref.read(automationRepositoryProvider).insertJob(AutomationJob(
            id: '',
            jobType: ScrapeType.productListings,
            retailerId: retailer.id,
            retailerName: retailer.name,
            scheduledAt: DateTime.now(),
            startedAt: DateTime.now(),
            status: JobStatus.running,
            triggeredBy: JobTrigger.manual,
          ));
        } catch (_) {}

        try {
          final result = switch (abbr) {
            'GBA' => await GbaProductListingService().scrape(retailer.id, activeSettings),
            'GS' => await GsProductListingService().scrape(retailer.id, activeSettings),
            'IMP' => await ImpProductListingService().scrape(retailer.id, activeSettings),
            _ => null,
          };

          if (result == null) {
            try {
              if (job != null) {
                await ref.read(automationRepositoryProvider).updateJob(
                  job.id,
                  status: JobStatus.failed,
                  completedAt: DateTime.now(),
                  errorLog: {'error': 'No scraper for abbreviation "${abbr ?? 'null'}"'},
                );
              }
            } catch (_) {}

            reports.add(RetailerListingReport(
              retailerName: retailer.name,
              status: 'error',
              scrapedCount: 0,
              savedCount: 0,
              errors: ['Retailer abbreviation "${abbr ?? 'null'}" has no matching scraper.'],
            ));
            continue;
          }

          final saveResult =
              await productListingsRepo.saveListings(result, statusMap);

          final allErrors = [...result.errors, ...saveResult.errors];
          final effectiveStatus = saveResult.saved.isEmpty && result.listings.isNotEmpty
              ? 'error'
              : saveResult.errors.isNotEmpty
                  ? 'partial'
                  : result.status;

          try {
            if (job != null) {
              await ref.read(automationRepositoryProvider).updateJob(
                job.id,
                status: effectiveStatus == 'error' ? JobStatus.failed : JobStatus.success,
                completedAt: DateTime.now(),
                resultSummary: {
                  'scraped': result.listings.length,
                  'saved': saveResult.saved.length,
                  'scrape_status': effectiveStatus,
                  if (allErrors.isNotEmpty) 'warnings': allErrors,
                },
              );
            }
          } catch (_) {}

          reports.add(RetailerListingReport(
            retailerName: retailer.name,
            status: effectiveStatus,
            scrapedCount: result.listings.length,
            savedCount: saveResult.saved.length,
            errors: allErrors,
          ));
        } catch (e) {
          try {
            if (job != null) {
              await ref.read(automationRepositoryProvider).updateJob(
                job.id,
                status: JobStatus.failed,
                completedAt: DateTime.now(),
                errorLog: {'error': e.toString(), 'retailer': retailer.name},
              );
            }
          } catch (_) {}

          reports.add(RetailerListingReport(
            retailerName: retailer.name,
            status: 'error',
            scrapedCount: 0,
            savedCount: 0,
            errors: [e.toString()],
          ));
        }
      }

      try {
        final newList = await productListingsRepo.getLatestListings();
        state = AsyncValue.data(newList);
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
        reports.add(RetailerListingReport(
          retailerName: 'System',
          status: 'error',
          scrapedCount: 0,
          savedCount: 0,
          errors: ['Failed to reload listings after save: $e'],
        ));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [
        RetailerListingReport(
          retailerName: 'System',
          status: 'error',
          scrapedCount: 0,
          savedCount: 0,
          errors: ['Unexpected error: $e'],
        ),
      ];
    }

    return reports;
  }

  /// Re-loads listings (e.g. after a mapping change).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(productListingsRepositoryProvider).getLatestListings(),
    );
  }
}

/// All unmapped listings across all scrape dates — used by Profile Mapping screen.
/// Uses a dedicated repo query so listings from older scrape dates are included.
final unmappedProductListingsProvider =
    FutureProvider<List<ProductListing>>((ref) async {
  // Invalidate when the notifier changes (e.g. after a mapping is saved)
  ref.watch(productListingsNotifierProvider);
  return ref.read(productListingsRepositoryProvider).getUnmappedListings();
});
