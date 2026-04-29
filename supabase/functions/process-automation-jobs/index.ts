// process-automation-jobs
// Triggered every minute by pg_cron.
// Picks up pending automation_jobs, executes the appropriate scraper,
// saves results, and handles retry logic on failure.
//
// Retry schedule (per-job):
//   attempt 1 → fail → attempt 2: immediate
//   attempt 2 → fail → attempt 3: +5 minutes
//   attempt 3 → fail → attempt 4: +5 minutes
//   attempt 4 → fail → permanent failure (reported in admin dashboard)
//
// Atomic claiming: jobs are updated status='running' before processing,
// preventing duplicate execution if multiple instances fire concurrently.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { scrapeGbaLivePrices, scrapeGsLivePrices, scrapeImpLivePrices } from '../_shared/live_prices.ts';
import { scrapeGbaLocalSpot, scrapeGsLocalSpot, scrapeImpLocalSpot } from '../_shared/local_spot.ts';
import { fetchGlobalSpot } from '../_shared/global_spot.ts';
import { scrapeGbaListings, scrapeGsListings, scrapeImpListings } from '../_shared/product_listings.ts';
import {
  saveLivePrices,
  saveLocalSpotPrices,
  saveGlobalSpotPrices,
  saveProductListings,
  getAdminUserId,
} from '../_shared/db_save.ts';
import type { AutomationJob } from '../_shared/types.ts';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const MAX_JOBS_PER_RUN = 5;

Deno.serve(async (_req) => {
  try {
    const processed = await run();
    return new Response(JSON.stringify({ ok: true, processed }), { status: 200 });
  } catch (e) {
    console.error('process-automation-jobs error:', e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

async function run(): Promise<number> {
  // Fetch pending jobs that are due (scheduled_at <= NOW())
  const { data: pendingJobs } = await supabase
    .from('automation_jobs')
    .select('*')
    .eq('status', 'pending')
    .lte('scheduled_at', new Date().toISOString())
    .order('scheduled_at', { ascending: true })
    .limit(MAX_JOBS_PER_RUN);

  if (!pendingJobs?.length) return 0;

  let processed = 0;

  for (const job of pendingJobs as AutomationJob[]) {
    // Atomically claim the job — skip if another instance already claimed it
    const { data: claimed } = await supabase
      .from('automation_jobs')
      .update({ status: 'running', started_at: new Date().toISOString() })
      .eq('id', job.id)
      .eq('status', 'pending')
      .select()
      .maybeSingle();

    if (!claimed) continue;

    await processJob(job);
    processed++;
  }

  return processed;
}

async function processJob(job: AutomationJob) {
  console.log(`Processing job ${job.id}: ${job.job_type} / ${job.retailer_name ?? 'global'} attempt ${job.attempt_number}`);

  let resultSummary: Record<string, unknown> | null = null;
  let errorLog: Record<string, unknown> | null = null;

  try {
    switch (job.job_type) {
      case 'live_prices':
        resultSummary = await runLivePrices(job);
        break;
      case 'local_spot':
        resultSummary = await runLocalSpot(job);
        break;
      case 'global_spot':
        resultSummary = await runGlobalSpot(job);
        break;
      case 'product_listings':
        resultSummary = await runProductListings(job);
        break;
      default:
        throw new Error(`Unknown job_type: ${job.job_type}`);
    }

    // Mark success
    await supabase
      .from('automation_jobs')
      .update({
        status: 'success',
        completed_at: new Date().toISOString(),
        result_summary: resultSummary,
      })
      .eq('id', job.id);

    console.log(`✅ Job ${job.id} succeeded`);
  } catch (e) {
    console.error(`❌ Job ${job.id} failed (attempt ${job.attempt_number}):`, e);

    errorLog = {
      message: String(e),
      stack: e instanceof Error ? e.stack : undefined,
      job_type: job.job_type,
      retailer: job.retailer_name,
      attempt: job.attempt_number,
      timestamp: new Date().toISOString(),
    };

    await supabase
      .from('automation_jobs')
      .update({
        status: 'failed',
        completed_at: new Date().toISOString(),
        error_log: errorLog,
      })
      .eq('id', job.id);

    // Schedule retry if attempts remain
    if (job.attempt_number < 4) {
      const delayMinutes = job.attempt_number === 1 ? 0 : 5; // immediate on 1→2, +5min on 2→3, 3→4
      const retryAt = new Date(Date.now() + delayMinutes * 60 * 1000).toISOString();

      await supabase.from('automation_jobs').insert({
        job_type: job.job_type,
        retailer_id: job.retailer_id,
        retailer_name: job.retailer_name,
        scheduled_at: retryAt,
        status: 'pending',
        attempt_number: job.attempt_number + 1,
        parent_job_id: job.id,
        triggered_by: 'retry',
      });

      console.log(`↩ Retry scheduled: attempt ${job.attempt_number + 1} at ${retryAt}`);
    } else {
      console.log(`🚨 Job ${job.id} exhausted all retries — failure logged in admin dashboard`);
    }
  }
}

// ── Live Prices ───────────────────────────────────────────────────────────────

async function runLivePrices(job: AutomationJob): Promise<Record<string, unknown>> {
  const { retailer, settings } = await loadRetailerAndSettings(job, 'live_price');
  const abbr = String(retailer.retailer_abbr ?? '').toUpperCase();

  const result =
    abbr === 'GBA' ? await scrapeGbaLivePrices(retailer.id, settings)
    : abbr === 'GS' ? await scrapeGsLivePrices(retailer.id, settings)
    : await scrapeImpLivePrices(retailer.id, settings);

  if (result.scrapeStatus === 'failed') {
    throw new Error(`Scrape failed: ${result.scrapeErrors.join('; ')}`);
  }

  const nameMap: Record<string, string> = {};
  for (const s of settings) {
    if (s.metal_type) nameMap[s.metal_type] = s.search_string;
  }

  const userId = await getAdminUserId(supabase);
  if (!userId) throw new Error('No admin user found for saving live prices');

  const { saved, errors } = await saveLivePrices(supabase, result, nameMap, userId);

  return {
    scrapeStatus: result.scrapeStatus,
    saved,
    priceCount: Object.keys(result.prices).length,
    errors: [...result.scrapeErrors, ...errors],
  };
}

// ── Local Spot ────────────────────────────────────────────────────────────────

async function runLocalSpot(job: AutomationJob): Promise<Record<string, unknown>> {
  const { retailer, settings } = await loadRetailerAndSettings(job, 'local_spot');
  const abbr = String(retailer.retailer_abbr ?? '').toUpperCase();

  const result =
    abbr === 'GBA' ? await scrapeGbaLocalSpot(settings)
    : abbr === 'GS' ? await scrapeGsLocalSpot(settings)
    : await scrapeImpLocalSpot(settings);

  if (Object.keys(result.prices).length === 0) {
    throw new Error(`No prices scraped: ${result.errors.join('; ')}`);
  }

  const userId = await getAdminUserId(supabase);
  if (!userId) throw new Error('No admin user found for saving spot prices');

  const { saved, duplicates, errors } = await saveLocalSpotPrices(
    supabase, result, retailer.id, retailer.name, userId,
  );

  return { saved, duplicates, metalCount: Object.keys(result.prices).length, errors };
}

// ── Global Spot ───────────────────────────────────────────────────────────────

async function runGlobalSpot(job: AutomationJob): Promise<Record<string, unknown>> {
  const userId = await getAdminUserId(supabase);
  if (!userId) throw new Error('No admin user found');

  const providerKey = job.retailer_name;
  if (!providerKey) throw new Error('Job is missing provider key (retailer_name)');

  const { data: pref } = await supabase
    .from('user_global_spot_prefs')
    .select('provider_key, api_key')
    .eq('user_id', userId)
    .eq('provider_key', providerKey)
    .eq('is_active', true)
    .maybeSingle();

  if (!pref) throw new Error(`Provider "${providerKey}" not found or inactive`);

  const result = await fetchGlobalSpot(pref.provider_key, pref.api_key);

  if (result.errorMessage) {
    throw new Error(`${result.displayName}: ${result.errorMessage}`);
  }

  const { saved, duplicates, errors } = await saveGlobalSpotPrices(supabase, result, userId);

  if (saved === 0 && errors.length > 0) {
    throw new Error(errors.join('; '));
  }

  return { saved, duplicates, errors };
}

// ── Product Listings ──────────────────────────────────────────────────────────

async function runProductListings(job: AutomationJob): Promise<Record<string, unknown>> {
  const { retailer, settings } = await loadRetailerAndSettings(job, 'product_listing');
  const abbr = String(retailer.retailer_abbr ?? '').toUpperCase();

  const result =
    abbr === 'GBA' ? await scrapeGbaListings(retailer.id, settings)
    : abbr === 'GS' ? await scrapeGsListings(retailer.id, settings)
    : await scrapeImpListings(retailer.id, settings);

  if (result.status === 'failed') {
    throw new Error(`Scrape failed: ${result.errors.join('; ')}`);
  }

  const { saved, skipped, errors } = await saveProductListings(supabase, result);

  return {
    scrapeStatus: result.status,
    listingsScraped: result.listings.length,
    saved,
    skipped,
    errors: [...result.errors, ...errors],
  };
}

// ── Shared: load retailer + settings ─────────────────────────────────────────

async function loadRetailerAndSettings(job: AutomationJob, scraperType: string) {
  if (!job.retailer_id) throw new Error(`Job ${job.id} has no retailer_id`);

  const { data: retailer } = await supabase
    .from('retailers')
    .select('id, name, retailer_abbr')
    .eq('id', job.retailer_id)
    .single();

  if (!retailer) throw new Error(`Retailer ${job.retailer_id} not found`);

  const abbr = String(retailer.retailer_abbr ?? '').toUpperCase();
  if (!['GBA', 'GS', 'IMP'].includes(abbr)) {
    throw new Error(`No scraper configured for retailer "${retailer.name}" (abbr="${abbr}")`);
  }

  const { data: settings } = await supabase
    .from('retailer_scraper_settings')
    .select('*')
    .eq('retailer_id', job.retailer_id)
    .eq('scraper_type', scraperType)
    .eq('is_active', true);

  if (!settings?.length) {
    throw new Error(`No active ${scraperType} settings for ${retailer.name}`);
  }

  return { retailer, settings };
}
