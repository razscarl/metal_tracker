// Database save helpers — mirrors Dart saveLivePrices, saveSpotPrice, saveListings
// Called by process-automation-jobs with a service-role Supabase client.

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import type {
  GlobalSpotScrapeResult,
  LivePriceScrapeResult,
  LocalSpotScrapeResult,
  ProductListingScrapeResult,
} from './types.ts';

// ── Live Prices ───────────────────────────────────────────────────────────────

export async function saveLivePrices(
  supabase: SupabaseClient,
  result: LivePriceScrapeResult,
  nameMap: Record<string, string>, // metalType → searchString (= live_price_name)
  userId: string,
): Promise<{ saved: number; errors: string[] }> {
  const now = new Date();
  const today = now.toISOString().split('T')[0];
  let saved = 0;
  const errors: string[] = [];

  for (const [metalType, prices] of Object.entries(result.prices)) {
    const livePriceName = nameMap[metalType];
    if (!livePriceName) continue;

    try {
      // Look for prior mapping from an existing record
      const { data: existing } = await supabase
        .from('live_prices')
        .select('product_profile_id')
        .eq('user_id', userId)
        .eq('retailer_id', result.retailerId)
        .eq('live_price_name', livePriceName)
        .not('product_profile_id', 'is', null)
        .limit(1)
        .maybeSingle();

      await supabase.from('live_prices').insert({
        user_id: userId,
        retailer_id: result.retailerId,
        metal_type: metalType,
        live_price_name: livePriceName,
        product_profile_id: existing?.product_profile_id ?? null,
        capture_date: today,
        capture_timestamp: now.toISOString(),
        sell_price: prices.sell,
        buyback_price: prices.buyback,
        scrape_status: result.scrapeStatus,
      });
      saved++;
    } catch (e) {
      errors.push(`${metalType}: ${e}`);
    }
  }

  return { saved, errors };
}

// ── Local Spot Prices ─────────────────────────────────────────────────────────

export async function saveLocalSpotPrices(
  supabase: SupabaseClient,
  result: LocalSpotScrapeResult,
  retailerId: string,
  retailerName: string,
  userId: string,
): Promise<{ saved: number; duplicates: number; errors: string[] }> {
  const batchTimestamp = new Date().toISOString();
  const today = batchTimestamp.split('T')[0];
  let saved = 0;
  let duplicates = 0;
  const errors: string[] = [];

  for (const [metalType, price] of Object.entries(result.prices)) {
    try {
      const { data: existing } = await supabase
        .from('spot_prices')
        .select('id')
        .eq('user_id', userId)
        .eq('metal_type', metalType)
        .eq('price', price)
        .eq('source_type', 'local_scraper')
        .eq('source', retailerName)
        .eq('fetch_timestamp', batchTimestamp)
        .maybeSingle();

      if (existing) { duplicates++; continue; }

      await supabase.from('spot_prices').insert({
        user_id: userId,
        metal_type: metalType,
        price,
        source_type: 'local_scraper',
        source: retailerName,
        retailer_id: retailerId,
        fetch_date: today,
        fetch_timestamp: batchTimestamp,
        status: 'success',
      });
      saved++;
    } catch (e) {
      errors.push(`${metalType}: ${e}`);
    }
  }

  return { saved, duplicates, errors };
}

// ── Global Spot Prices ────────────────────────────────────────────────────────

export async function saveGlobalSpotPrices(
  supabase: SupabaseClient,
  result: GlobalSpotScrapeResult,
  userId: string,
): Promise<{ saved: number; duplicates: number; errors: string[] }> {
  const fetchTimestamp = new Date().toISOString();
  const today = fetchTimestamp.split('T')[0];
  let saved = 0;
  let duplicates = 0;
  const errors: string[] = [];

  for (const [metalType, price] of Object.entries(result.prices)) {
    try {
      const { data: existing } = await supabase
        .from('spot_prices')
        .select('id')
        .eq('user_id', userId)
        .eq('metal_type', metalType)
        .eq('price', price)
        .eq('source_type', 'global_api')
        .eq('source', result.displayName)
        .eq('fetch_timestamp', fetchTimestamp)
        .maybeSingle();

      if (existing) { duplicates++; continue; }

      await supabase.from('spot_prices').insert({
        user_id: userId,
        metal_type: metalType,
        price,
        source_type: 'global_api',
        source: result.displayName,
        retailer_id: null,
        fetch_date: today,
        fetch_timestamp: fetchTimestamp,
        status: 'success',
      });
      saved++;
    } catch (e) {
      errors.push(`${metalType}: ${e}`);
    }
  }

  return { saved, duplicates, errors };
}

// ── Product Listings ──────────────────────────────────────────────────────────

export async function saveProductListings(
  supabase: SupabaseClient,
  result: ProductListingScrapeResult,
): Promise<{ saved: number; skipped: number; errors: string[] }> {
  const now = new Date();
  const todayStr = now.toISOString().split('T')[0];
  let savedCount = 0;
  let skipped = 0;
  const saveErrors: string[] = [];

  // Load today's existing listing names for this retailer (dedup check)
  const existingToday = new Set<string>();
  try {
    const { data: rows } = await supabase
      .from('product_listings')
      .select('listing_name')
      .eq('retailer_id', result.retailerId)
      .eq('scrape_date', todayStr);
    for (const row of (rows ?? [])) {
      existingToday.add(row.listing_name as string);
    }
  } catch (e) {
    console.warn('Could not load today listings for dedup:', e);
  }

  // Load prior profile mappings (listing_name → product_profile_id)
  const priorMappings = new Map<string, string>();
  try {
    const { data: rows } = await supabase
      .from('product_listings')
      .select('listing_name, product_profile_id')
      .eq('retailer_id', result.retailerId)
      .not('product_profile_id', 'is', null);
    for (const row of (rows ?? [])) {
      priorMappings.set(row.listing_name as string, row.product_profile_id as string);
    }
  } catch (e) {
    console.warn('Could not load prior mappings:', e);
  }

  // Load status mappings (capturedStatus → storedStatus)
  const statusMap = new Map<string, string>();
  try {
    const { data: rows } = await supabase
      .from('product_listing_statuses')
      .select('captured_status, stored_status')
      .eq('is_active', true);
    for (const row of (rows ?? [])) {
      statusMap.set(
        (row.captured_status as string).toLowerCase(),
        row.stored_status as string,
      );
    }
  } catch (e) {
    console.warn('Could not load status mappings:', e);
  }

  for (const listing of result.listings) {
    try {
      if (listing.sellPrice <= 1.00) {
        skipped++;
        continue;
      }
      if (existingToday.has(listing.listingName)) {
        skipped++;
        continue;
      }

      const availability =
        (listing.capturedStatus ? statusMap.get(listing.capturedStatus.toLowerCase()) : null) ??
        'available';

      const { error } = await supabase.from('product_listings').insert({
        listing_name: listing.listingName,
        listing_sell_price: listing.sellPrice,
        retailer_id: result.retailerId,
        product_profile_id: priorMappings.get(listing.listingName) ?? null,
        availability,
        scrape_status: result.status,
        scrape_error: result.errors.length > 0 ? result.errors.join('; ') : null,
        scrape_date: todayStr,
        scrape_timestamp: now.toISOString(),
      });
      if (error) throw new Error(error.message);
      savedCount++;
    } catch (e) {
      saveErrors.push(`Save failed [${listing.listingName}]: ${e}`);
    }
  }

  return { saved: savedCount, skipped, errors: saveErrors };
}

// ── Admin user lookup ─────────────────────────────────────────────────────────
// Automated scrapes write records under the primary admin user's ID.
// This ensures auto-mapping lookups (which filter by user_id) work correctly.

export async function getAdminUserId(supabase: SupabaseClient): Promise<string | null> {
  const { data } = await supabase
    .from('user_profiles')
    .select('id')
    .eq('is_admin', true)
    .order('created_at', { ascending: true })
    .limit(1)
    .maybeSingle();
  return data?.id ?? null;
}
