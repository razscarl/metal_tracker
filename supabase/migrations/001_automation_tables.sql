-- =============================================================================
-- Migration 001: Automation Tables
-- Apply via: Supabase Dashboard → SQL Editor → paste and run
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. automation_config
--    Single-row table holding global automation settings (timezone, on/off).
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS automation_config (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  timezone    TEXT        NOT NULL DEFAULT 'Australia/Brisbane',
  enabled     BOOLEAN     NOT NULL DEFAULT true,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed the single config row (only insert if table is empty)
INSERT INTO automation_config (timezone, enabled)
SELECT 'Australia/Brisbane', true
WHERE NOT EXISTS (SELECT 1 FROM automation_config);

-- RLS
ALTER TABLE automation_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_select_automation_config"
  ON automation_config FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "admin_update_automation_config"
  ON automation_config FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- ---------------------------------------------------------------------------
-- 2. automation_schedules
--    One row per scrape type, storing local run times as a text array.
--    The Edge Function reads these + the timezone from automation_config
--    to determine when to seed jobs — no pg_cron changes needed when
--    the admin updates schedules or timezone.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS automation_schedules (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  scrape_type TEXT        NOT NULL,   -- 'live_prices' | 'local_spot' | 'global_spot' | 'product_listings'
  run_times   TEXT[]      NOT NULL DEFAULT '{}',  -- e.g. ARRAY['10:00', '13:00', '17:00']
  enabled     BOOLEAN     NOT NULL DEFAULT true,
  CONSTRAINT automation_schedules_scrape_type_unique UNIQUE (scrape_type)
);

-- Seed default schedules
INSERT INTO automation_schedules (scrape_type, run_times, enabled) VALUES
  ('live_prices',       ARRAY['10:00', '13:00', '17:00'], true),
  ('local_spot',        ARRAY['10:00', '13:00', '17:00'], true),
  ('global_spot',       ARRAY['10:00', '13:00', '17:00'], true),
  ('product_listings',  ARRAY['13:00'],                   true)
ON CONFLICT (scrape_type) DO NOTHING;

-- RLS
ALTER TABLE automation_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_select_automation_schedules"
  ON automation_schedules FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "admin_update_automation_schedules"
  ON automation_schedules FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- ---------------------------------------------------------------------------
-- 3. automation_jobs
--    Job queue and full history.
--    Written by:
--      - Edge Functions (service_role — bypasses RLS)
--      - Flutter admin UI for manual scrape logging (authenticated admin user)
--    Read by:
--      - Flutter admin dashboard
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS automation_jobs (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  job_type        TEXT        NOT NULL,               -- 'live_prices' | 'local_spot' | 'global_spot' | 'product_listings'
  retailer_id     UUID        REFERENCES retailers(id) ON DELETE SET NULL,
  retailer_name   TEXT,                               -- denormalised for log readability after retailer changes
  scheduled_at    TIMESTAMPTZ NOT NULL,
  started_at      TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,
  status          TEXT        NOT NULL DEFAULT 'pending',  -- 'pending' | 'running' | 'success' | 'failed'
  attempt_number  INTEGER     NOT NULL DEFAULT 1,
  parent_job_id   UUID        REFERENCES automation_jobs(id) ON DELETE SET NULL,
  triggered_by    TEXT        NOT NULL DEFAULT 'scheduler',  -- 'scheduler' | 'retry' | 'manual'
  error_log       JSONB,                              -- structured error detail on failure
  result_summary  JSONB,                              -- structured success info (items scraped, duration, etc.)
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
-- Processor query: fetch pending jobs where scheduled_at <= NOW()
CREATE INDEX IF NOT EXISTS idx_automation_jobs_pending
  ON automation_jobs (status, scheduled_at)
  WHERE status = 'pending';

-- Admin dashboard: sort by most recent
CREATE INDEX IF NOT EXISTS idx_automation_jobs_created_desc
  ON automation_jobs (created_at DESC);

-- Retry chain: look up children of a parent job
CREATE INDEX IF NOT EXISTS idx_automation_jobs_parent
  ON automation_jobs (parent_job_id)
  WHERE parent_job_id IS NOT NULL;

-- RLS
ALTER TABLE automation_jobs ENABLE ROW LEVEL SECURITY;

-- Admin can read all jobs (dashboard)
CREATE POLICY "admin_select_automation_jobs"
  ON automation_jobs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Admin can insert jobs (manual scrape logging from Flutter)
CREATE POLICY "admin_insert_automation_jobs"
  ON automation_jobs FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Admin can update jobs (e.g. marking a manual scrape as complete)
CREATE POLICY "admin_update_automation_jobs"
  ON automation_jobs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- NOTE: Edge Functions use the Supabase service_role key which bypasses RLS.
-- No additional policies are needed for server-side automated operations.

-- =============================================================================
-- End of migration 001
-- =============================================================================
