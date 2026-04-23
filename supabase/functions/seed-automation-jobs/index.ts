// seed-automation-jobs
// Triggered every minute by pg_cron.
// Reads automation_config (timezone) + automation_schedules (run times),
// checks if the current local minute matches a scheduled slot,
// and inserts pending automation_jobs for each scrape type / retailer.
//
// Dedup window: skips creating a job if one already exists for the same
// type + retailer within the last 5 minutes (prevents double-firing).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

Deno.serve(async (_req) => {
  try {
    await run();
    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (e) {
    console.error('seed-automation-jobs error:', e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

async function run() {
  // 1. Read global config
  const { data: config } = await supabase
    .from('automation_config')
    .select('timezone, enabled')
    .limit(1)
    .maybeSingle();

  if (!config?.enabled) {
    console.log('Automation is disabled — skipping seed.');
    return;
  }

  const timezone = config.timezone ?? 'Australia/Brisbane';

  // 2. Get current local HH:MM in configured timezone
  const now = new Date();
  const localHHMM = localTimeHHMM(now, timezone);
  console.log(`Now UTC: ${now.toISOString()} | Local (${timezone}): ${localHHMM}`);

  // 3. Read all enabled schedules
  const { data: schedules } = await supabase
    .from('automation_schedules')
    .select('scrape_type, run_times, enabled')
    .eq('enabled', true);

  if (!schedules?.length) {
    console.log('No enabled schedules found.');
    return;
  }

  // 4. For each schedule that matches the current minute, seed jobs
  for (const schedule of schedules) {
    const runTimes: string[] = schedule.run_times ?? [];
    if (!runTimes.includes(localHHMM)) continue;

    console.log(`Matched schedule: ${schedule.scrape_type} at ${localHHMM}`);
    await seedJobsForType(schedule.scrape_type, now);
  }
}

async function seedJobsForType(scrapeType: string, scheduledAt: Date) {
  const scheduledAtStr = scheduledAt.toISOString();

  if (scrapeType === 'global_spot') {
    // One job per active global spot provider (provider_key stored in retailer_name)
    const { data: adminProfile } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('is_admin', true)
      .order('created_at', { ascending: true })
      .limit(1)
      .maybeSingle();

    if (!adminProfile) {
      console.log('No admin user found — cannot seed global spot jobs');
      return;
    }

    const { data: prefs } = await supabase
      .from('user_global_spot_prefs')
      .select('provider_key')
      .eq('user_id', adminProfile.id)
      .eq('is_active', true);

    if (!prefs?.length) {
      console.log('No active global spot providers configured');
      return;
    }

    for (const pref of prefs) {
      await maybeInsertJob({
        job_type: scrapeType,
        retailer_id: null,
        retailer_name: pref.provider_key,
        scheduled_at: scheduledAtStr,
      });
    }
    return;
  }

  // For live_prices, local_spot, product_listings: one job per active retailer
  const { data: retailers } = await supabase
    .from('retailers')
    .select('id, name, retailer_abbr, is_active')
    .eq('is_active', true);

  if (!retailers?.length) {
    console.log(`No active retailers found for ${scrapeType}`);
    return;
  }

  for (const retailer of retailers) {
    const abbr = String(retailer.retailer_abbr ?? '').toUpperCase();
    if (!['GBA', 'GS', 'IMP'].includes(abbr)) continue;

    // Check retailer has settings for this scrape type
    const scraperTypeDb =
      scrapeType === 'live_prices' ? 'live_price'
      : scrapeType === 'local_spot' ? 'local_spot'
      : 'product_listing';

    const { data: settings } = await supabase
      .from('retailer_scraper_settings')
      .select('id')
      .eq('retailer_id', retailer.id)
      .eq('scraper_type', scraperTypeDb)
      .eq('is_active', true)
      .limit(1);

    if (!settings?.length) continue;

    await maybeInsertJob({
      job_type: scrapeType,
      retailer_id: retailer.id,
      retailer_name: retailer.name,
      scheduled_at: scheduledAtStr,
    });
  }
}

async function maybeInsertJob(payload: {
  job_type: string;
  retailer_id: string | null;
  retailer_name: string | null;
  scheduled_at: string;
}) {
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();

  // Dedup: has this job already been seeded within the last 5 minutes?
  let query = supabase
    .from('automation_jobs')
    .select('id')
    .eq('job_type', payload.job_type)
    .neq('status', 'failed')
    .gte('scheduled_at', fiveMinutesAgo);

  if (payload.retailer_id) {
    query = query.eq('retailer_id', payload.retailer_id);
  } else if (payload.retailer_name) {
    // Global spot: dedup per provider key (stored in retailer_name)
    query = query.is('retailer_id', null).eq('retailer_name', payload.retailer_name);
  } else {
    query = query.is('retailer_id', null);
  }

  const { data: existing } = await query.limit(1).maybeSingle();
  if (existing) {
    console.log(`Skipping duplicate: ${payload.job_type} / ${payload.retailer_name ?? 'global'}`);
    return;
  }

  await supabase.from('automation_jobs').insert({
    ...payload,
    status: 'pending',
    attempt_number: 1,
    triggered_by: 'scheduler',
  });

  console.log(`Seeded: ${payload.job_type} / ${payload.retailer_name ?? 'global'}`);
}

// Returns HH:MM string in the given timezone (24h, zero-padded)
function localTimeHHMM(date: Date, timezone: string): string {
  const parts = new Intl.DateTimeFormat('en-AU', {
    timeZone: timezone,
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(date);

  const hour = parts.find((p) => p.type === 'hour')?.value ?? '00';
  const minute = parts.find((p) => p.type === 'minute')?.value ?? '00';
  return `${hour}:${minute}`;
}
