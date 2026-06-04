-- ============================================================
-- Migration 009: Fix design_themes sort_order
-- Ensures Dark → Light → Accessibility display order
-- ============================================================

update design_themes set sort_order = 1 where name = 'dark';
update design_themes set sort_order = 2 where name = 'light';
update design_themes set sort_order = 3 where name = 'accessibility';
