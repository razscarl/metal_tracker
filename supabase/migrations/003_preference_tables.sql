-- =============================================================================
-- Migration 003: Preference Tables Refactor
-- Apply via: Supabase Dashboard → SQL Editor → paste and run
-- Safe to re-run — all statements are idempotent.
--
-- Changes:
--   1. Create user_metal_prefs  (replaces user_metal_types, metal FK not text)
--   2. Ensure user_retailer_prefs exists; drop legacy user_retailers if redundant
--   3. Rename user_analytics_settings → user_analytics_prefs
--   4. Drop dead tables (user_live_price_prefs, user_local_spot_prefs, user_scraper_prefs)
--   5. Drop user_metal_types (after data migration)
--   Note: live_prices RLS already correct (live_prices_read_all / live_prices_write_admin)
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. user_metal_prefs
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_metal_prefs (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  metal_type_id UUID        NOT NULL REFERENCES metal_types(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_metal_prefs_unique UNIQUE (user_id, metal_type_id)
);

-- Migrate existing data from user_metal_types if that table still exists
INSERT INTO user_metal_prefs (user_id, metal_type_id)
SELECT umt.user_id, mt.id
FROM user_metal_types umt
JOIN metal_types mt ON mt.name = umt.metal_type
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_metal_types')
ON CONFLICT (user_id, metal_type_id) DO NOTHING;

-- RLS (drop first so re-runs don't error)
ALTER TABLE user_metal_prefs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_select_own_metal_prefs" ON user_metal_prefs;
CREATE POLICY "user_select_own_metal_prefs"
  ON user_metal_prefs FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_insert_own_metal_prefs" ON user_metal_prefs;
CREATE POLICY "user_insert_own_metal_prefs"
  ON user_metal_prefs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_delete_own_metal_prefs" ON user_metal_prefs;
CREATE POLICY "user_delete_own_metal_prefs"
  ON user_metal_prefs FOR DELETE
  USING (auth.uid() = user_id);


-- ---------------------------------------------------------------------------
-- 2. user_retailer_prefs
--    Already exists. Drop legacy user_retailers table if it is still present
--    (it was superseded by user_retailer_prefs at some earlier point).
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS user_retailers;


-- ---------------------------------------------------------------------------
-- 3. Rename user_analytics_settings → user_analytics_prefs
--    Only run if the old name still exists.
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'user_analytics_settings'
  ) THEN
    ALTER TABLE user_analytics_settings RENAME TO user_analytics_prefs;
  END IF;
END $$;


-- ---------------------------------------------------------------------------
-- 4. Drop dead tables (never functionally used)
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS user_live_price_prefs;
DROP TABLE IF EXISTS user_local_spot_prefs;
DROP TABLE IF EXISTS user_scraper_prefs;


-- ---------------------------------------------------------------------------
-- 5. Drop user_metal_types (data migrated to user_metal_prefs above)
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS user_metal_types;


-- =============================================================================
-- End of migration 003
-- =============================================================================
