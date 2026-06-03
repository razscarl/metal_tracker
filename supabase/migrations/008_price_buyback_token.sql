-- ============================================================
-- Migration 008: Add price_buyback design token
-- Steel blue #5B9BD5 — industry-standard bid/buyback price colour
-- ============================================================

-- Primitive
insert into design_tokens (token_name, tier, token_type, group_name, reserved_for, sort_order) values
  ('prim_steel_blue', 'primitive', 'color', 'Primitive Colors', 'Raw steel blue value', 60);

-- Semantic
insert into design_tokens (token_name, tier, token_type, group_name, reserved_for, sort_order) values
  ('price_buyback', 'semantic', 'color', 'Financial Signals', 'Buyback and bid price display only', 12);

-- Dark theme — primitive value
insert into design_token_values (token_id, theme_id, value) values
  (
    (select id from design_tokens where token_name = 'prim_steel_blue'),
    (select id from design_themes  where name       = 'dark'),
    '#5B9BD5'
  );

-- Dark theme — semantic reference
insert into design_token_values (token_id, theme_id, references_token_id) values
  (
    (select id from design_tokens where token_name = 'price_buyback'),
    (select id from design_themes  where name       = 'dark'),
    (select id from design_tokens where token_name = 'prim_steel_blue')
  );
