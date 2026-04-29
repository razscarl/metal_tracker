-- =============================================================================
-- Migration 002: pg_cron schedules for automation
-- Apply via: Supabase Dashboard → SQL Editor → paste and run
--
-- PREREQUISITES:
--   - pg_cron extension must be enabled (Supabase Dashboard → Database → Extensions → pg_cron)
--   - Edge Functions must be deployed before these fire:
--       supabase functions deploy seed-automation-jobs
--       supabase functions deploy process-automation-jobs
-- =============================================================================

-- Enable pg_cron extension (safe to run if already enabled)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Edge Functions are called via HTTP from pg_cron using the project URL + anon key.
-- The Edge Functions themselves use the service_role key (injected automatically).
-- Replace <YOUR_PROJECT_REF> with your Supabase project reference ID.
-- Replace <YOUR_ANON_KEY> with your project's anon/public key.
-- Both are available in: Supabase Dashboard → Project Settings → API

-- ── seed-automation-jobs: every minute ───────────────────────────────────────
-- Checks if current local time matches a scheduled slot and seeds pending jobs.

SELECT cron.schedule(
  'seed-automation-jobs',          -- job name (unique)
  '* * * * *',                     -- every minute
  $$
  SELECT net.http_post(
    url     := 'https://mtbyvqlfkknityxlgwje.supabase.co/functions/v1/seed-automation-jobs',
    headers := jsonb_build_object(
      'Authorization', 'Bearer sb_publishable_8YsMmlTuV83B8SfTGSb7jA_E7bSQPD6',
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);

-- ── process-automation-jobs: every minute ────────────────────────────────────
-- Picks up pending jobs, executes scrapers, handles retry logic.

SELECT cron.schedule(
  'process-automation-jobs',       -- job name (unique)
  '* * * * *',                     -- every minute
  $$
  SELECT net.http_post(
    url     := 'https://mtbyvqlfkknityxlgwje.supabase.co/functions/v1/process-automation-jobs',
    headers := jsonb_build_object(
      'Authorization', 'Bearer sb_publishable_8YsMmlTuV83B8SfTGSb7jA_E7bSQPD6',
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);

-- =============================================================================
-- To view scheduled jobs:
--   SELECT * FROM cron.job;
--
-- To view recent execution history:
--   SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 20;
--
-- To remove a job:
--   SELECT cron.unschedule('seed-automation-jobs');
--   SELECT cron.unschedule('process-automation-jobs');
-- =============================================================================
