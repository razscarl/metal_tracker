-- Migration 003: Add Investment Guide premium tolerance columns to user_analytics_settings
-- Run in Supabase SQL editor (Database → SQL Editor)

ALTER TABLE user_analytics_settings
  ADD COLUMN IF NOT EXISTS premium_gold_low_pct    numeric(6,2) NOT NULL DEFAULT 1.0,
  ADD COLUMN IF NOT EXISTS premium_gold_high_pct   numeric(6,2) NOT NULL DEFAULT 8.0,
  ADD COLUMN IF NOT EXISTS premium_silver_low_pct  numeric(6,2) NOT NULL DEFAULT 3.0,
  ADD COLUMN IF NOT EXISTS premium_silver_high_pct numeric(6,2) NOT NULL DEFAULT 25.0,
  ADD COLUMN IF NOT EXISTS premium_plat_low_pct    numeric(6,2) NOT NULL DEFAULT 5.0,
  ADD COLUMN IF NOT EXISTS premium_plat_high_pct   numeric(6,2) NOT NULL DEFAULT 40.0;

-- Backfill any existing rows with defaults (ADD COLUMN with DEFAULT handles new rows,
-- but existing rows already have the default applied by Postgres).
-- Nothing extra needed — Postgres fills defaults on ADD COLUMN for existing rows.
