-- =============================================================================
-- Migration 004: Preference Table Corrections
-- Apply via: Supabase Dashboard → SQL Editor → paste and run
-- Safe to re-run — all statements are idempotent.
--
-- Changes:
--   1. Rename user_metal_prefs → user_metaltype_prefs
--   2. Drop and recreate user_retailer_prefs with correct structure
--      (old version had service_type + metal_type_id — wrong architecture)
--      Correct structure: user_id + retailer_id only. Service capabilities
--      are determined by admin-configured retailer_scraper_settings, not user prefs.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. Rename user_metal_prefs → user_metaltype_prefs
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'user_metal_prefs'
  ) THEN
    ALTER TABLE user_metal_prefs RENAME TO user_metaltype_prefs;
  END IF;
END $$;

-- Rename policies to match new table name (policies keep old names after rename)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_metaltype_prefs' AND policyname = 'user_select_own_metal_prefs'
  ) THEN
    ALTER POLICY "user_select_own_metal_prefs"
      ON user_metaltype_prefs RENAME TO "user_select_own_metaltype_prefs";
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_metaltype_prefs' AND policyname = 'user_insert_own_metal_prefs'
  ) THEN
    ALTER POLICY "user_insert_own_metal_prefs"
      ON user_metaltype_prefs RENAME TO "user_insert_own_metaltype_prefs";
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_metaltype_prefs' AND policyname = 'user_delete_own_metal_prefs'
  ) THEN
    ALTER POLICY "user_delete_own_metal_prefs"
      ON user_metaltype_prefs RENAME TO "user_delete_own_metaltype_prefs";
  END IF;
END $$;


-- ---------------------------------------------------------------------------
-- 2. Drop and recreate user_retailer_prefs with correct structure
--    The existing table has service_type + metal_type_id which was wrong
--    architecture. Correct design: user picks retailers independently of
--    service type and metal type. Service capabilities come from
--    retailer_scraper_settings (admin-configured).
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS user_retailer_prefs;

CREATE TABLE user_retailer_prefs (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  retailer_id  UUID        NOT NULL REFERENCES retailers(id)  ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_retailer_prefs_unique UNIQUE (user_id, retailer_id)
);

-- RLS
ALTER TABLE user_retailer_prefs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_select_own_retailer_prefs"
  ON user_retailer_prefs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "user_insert_own_retailer_prefs"
  ON user_retailer_prefs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_delete_own_retailer_prefs"
  ON user_retailer_prefs FOR DELETE
  USING (auth.uid() = user_id);


-- =============================================================================
-- End of migration 004
-- =============================================================================
