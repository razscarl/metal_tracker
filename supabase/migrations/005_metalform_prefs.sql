-- =============================================================================
-- Migration 005: User Metal Form Preferences
-- Apply via: Supabase Dashboard → SQL Editor → paste and run
-- Safe to re-run — CREATE TABLE IF NOT EXISTS is idempotent.
-- =============================================================================

CREATE TABLE IF NOT EXISTS user_metalform_prefs (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  metal_form_id  UUID        NOT NULL REFERENCES metal_forms(id) ON DELETE CASCADE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_metalform_prefs_unique UNIQUE (user_id, metal_form_id)
);

ALTER TABLE user_metalform_prefs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_select_own_metalform_prefs" ON user_metalform_prefs;
CREATE POLICY "user_select_own_metalform_prefs"
  ON user_metalform_prefs FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_insert_own_metalform_prefs" ON user_metalform_prefs;
CREATE POLICY "user_insert_own_metalform_prefs"
  ON user_metalform_prefs FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_delete_own_metalform_prefs" ON user_metalform_prefs;
CREATE POLICY "user_delete_own_metalform_prefs"
  ON user_metalform_prefs FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- End of migration 005
-- =============================================================================
