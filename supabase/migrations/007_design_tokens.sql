-- ============================================================
-- Migration 007: Design Token System
-- Three-tier semantic token system with multi-theme support
-- ============================================================

-- ── Tables ───────────────────────────────────────────────────────────────────

create table if not exists design_themes (
  id            uuid primary key default gen_random_uuid(),
  name          text not null unique,
  display_name  text not null,
  is_default    boolean not null default false,
  is_available  boolean not null default true,
  sort_order    int  not null default 0,
  created_at    timestamptz not null default now()
);

create table if not exists design_tokens (
  id           uuid primary key default gen_random_uuid(),
  token_name   text not null unique,
  tier         text not null check (tier in ('primitive', 'semantic')),
  token_type   text not null check (token_type in (
                 'color', 'spacing', 'radius', 'font_size',
                 'font_weight', 'font_family', 'opacity', 'duration_ms')),
  group_name   text not null,
  reserved_for text not null,
  sort_order   int  not null default 0,
  created_at   timestamptz not null default now()
);

create table if not exists design_token_values (
  id                   uuid primary key default gen_random_uuid(),
  token_id             uuid not null references design_tokens(id) on delete cascade,
  theme_id             uuid not null references design_themes(id) on delete cascade,
  value                text,
  references_token_id  uuid references design_tokens(id),
  created_at           timestamptz not null default now(),
  unique (token_id, theme_id),
  -- exactly one of value or references_token_id must be set
  constraint chk_value_or_ref check (
    (value is not null and references_token_id is null) or
    (value is null and references_token_id is not null)
  )
);

-- ── Add theme preference to user_profiles ────────────────────────────────────

alter table user_profiles
  add column if not exists theme_id uuid references design_themes(id);

-- ── RLS ──────────────────────────────────────────────────────────────────────

alter table design_themes       enable row level security;
alter table design_tokens       enable row level security;
alter table design_token_values enable row level security;

-- All authenticated users can read
create policy "tokens_read" on design_themes
  for select to authenticated using (true);

create policy "tokens_read" on design_tokens
  for select to authenticated using (true);

create policy "tokens_read" on design_token_values
  for select to authenticated using (true);

-- Only admins can write
create policy "tokens_admin_write" on design_themes
  for all to authenticated
  using     ((select is_admin from user_profiles where id = auth.uid()))
  with check((select is_admin from user_profiles where id = auth.uid()));

create policy "tokens_admin_write" on design_tokens
  for all to authenticated
  using     ((select is_admin from user_profiles where id = auth.uid()))
  with check((select is_admin from user_profiles where id = auth.uid()));

create policy "tokens_admin_write" on design_token_values
  for all to authenticated
  using     ((select is_admin from user_profiles where id = auth.uid()))
  with check((select is_admin from user_profiles where id = auth.uid()));

-- ── Seed: Dark theme ─────────────────────────────────────────────────────────

insert into design_themes (name, display_name, is_default, is_available, sort_order) values
  ('dark',  'Dark Theme',          true,  true, 1),
  ('light', 'Light Theme',         false, false, 2),
  ('accessibility', 'Accessibility Theme', false, false, 3);

-- ── Seed: Primitive color tokens ─────────────────────────────────────────────

insert into design_tokens (token_name, tier, token_type, group_name, reserved_for, sort_order) values
  -- Golds
  ('prim_gold',          'primitive', 'color', 'Primitive Colors', 'Raw gold value',             10),
  ('prim_gold_light',    'primitive', 'color', 'Primitive Colors', 'Raw light gold value',        11),
  ('prim_gold_dark',     'primitive', 'color', 'Primitive Colors', 'Raw dark gold value',         12),
  -- Metals
  ('prim_silver',        'primitive', 'color', 'Primitive Colors', 'Raw silver value',            20),
  ('prim_cyan',          'primitive', 'color', 'Primitive Colors', 'Raw cyan value',              21),
  -- Signals
  ('prim_green_bright',  'primitive', 'color', 'Primitive Colors', 'Raw bright green value',      30),
  ('prim_red_bright',    'primitive', 'color', 'Primitive Colors', 'Raw bright red value',        31),
  -- Neutrals
  ('prim_white',         'primitive', 'color', 'Primitive Colors', 'Raw white value',             40),
  ('prim_gray_mid',      'primitive', 'color', 'Primitive Colors', 'Raw mid-gray value',          41),
  ('prim_dark_bg',       'primitive', 'color', 'Primitive Colors', 'Raw dark background value',   42),
  ('prim_dark_card',     'primitive', 'color', 'Primitive Colors', 'Raw dark card surface value', 43),
  ('prim_light_bg',      'primitive', 'color', 'Primitive Colors', 'Raw light background value',  44),
  ('prim_dark_text',     'primitive', 'color', 'Primitive Colors', 'Raw dark text value',         45),
  -- System status
  ('prim_amber',         'primitive', 'color', 'Primitive Colors', 'Raw amber value',             50),
  ('prim_green_material','primitive', 'color', 'Primitive Colors', 'Raw material green value',    51),
  ('prim_red_material',  'primitive', 'color', 'Primitive Colors', 'Raw material red value',      52);

-- ── Seed: Primitive typography tokens ────────────────────────────────────────

insert into design_tokens (token_name, tier, token_type, group_name, reserved_for, sort_order) values
  ('prim_font_inter',      'primitive', 'font_family', 'Primitive Typography', 'Inter font family',   10),
  ('prim_size_10',         'primitive', 'font_size',   'Primitive Typography', 'Raw size 10',         20),
  ('prim_size_11',         'primitive', 'font_size',   'Primitive Typography', 'Raw size 11',         21),
  ('prim_size_12',         'primitive', 'font_size',   'Primitive Typography', 'Raw size 12',         22),
  ('prim_size_13',         'primitive', 'font_size',   'Primitive Typography', 'Raw size 13',         23),
  ('prim_size_14',         'primitive', 'font_size',   'Primitive Typography', 'Raw size 14',         24),
  ('prim_size_16',         'primitive', 'font_size',   'Primitive Typography', 'Raw size 16',         25),
  ('prim_size_20',         'primitive', 'font_size',   'Primitive Typography', 'Raw size 20',         26),
  ('prim_size_24',         'primitive', 'font_size',   'Primitive Typography', 'Raw size 24',         27),
  ('prim_size_36',         'primitive', 'font_size',   'Primitive Typography', 'Raw size 36',         28),
  ('prim_size_48',         'primitive', 'font_size',   'Primitive Typography', 'Raw size 48',         29),
  ('prim_weight_400',      'primitive', 'font_weight', 'Primitive Typography', 'Raw weight 400',      30),
  ('prim_weight_500',      'primitive', 'font_weight', 'Primitive Typography', 'Raw weight 500',      31),
  ('prim_weight_600',      'primitive', 'font_weight', 'Primitive Typography', 'Raw weight 600',      32),
  ('prim_weight_700',      'primitive', 'font_weight', 'Primitive Typography', 'Raw weight 700',      33);

-- ── Seed: Primitive spacing + radius + opacity tokens ────────────────────────

insert into design_tokens (token_name, tier, token_type, group_name, reserved_for, sort_order) values
  ('prim_space_4',    'primitive', 'spacing', 'Primitive Spacing', 'Raw spacing 4',    10),
  ('prim_space_8',    'primitive', 'spacing', 'Primitive Spacing', 'Raw spacing 8',    11),
  ('prim_space_12',   'primitive', 'spacing', 'Primitive Spacing', 'Raw spacing 12',   12),
  ('prim_space_14',   'primitive', 'spacing', 'Primitive Spacing', 'Raw spacing 14',   13),
  ('prim_space_16',   'primitive', 'spacing', 'Primitive Spacing', 'Raw spacing 16',   14),
  ('prim_space_24',   'primitive', 'spacing', 'Primitive Spacing', 'Raw spacing 24',   15),
  ('prim_space_32',   'primitive', 'spacing', 'Primitive Spacing', 'Raw spacing 32',   16),
  ('prim_radius_8',   'primitive', 'radius',  'Primitive Spacing', 'Raw radius 8',     20),
  ('prim_radius_12',  'primitive', 'radius',  'Primitive Spacing', 'Raw radius 12',    21),
  ('prim_opacity_40', 'primitive', 'opacity', 'Primitive Spacing', 'Raw opacity 0.4',  30),
  ('prim_opacity_60', 'primitive', 'opacity', 'Primitive Spacing', 'Raw opacity 0.6',  31);

-- ── Seed: Semantic color tokens ───────────────────────────────────────────────

insert into design_tokens (token_name, tier, token_type, group_name, reserved_for, sort_order) values
  -- Metal types
  ('metal_gold',       'semantic', 'color', 'Metal Colors',     'Gold metal type label and icon',            10),
  ('metal_gold_light', 'semantic', 'color', 'Metal Colors',     'Gold metal hover tint',                     11),
  ('metal_gold_dark',  'semantic', 'color', 'Metal Colors',     'Gold metal pressed state',                  12),
  ('metal_silver',     'semantic', 'color', 'Metal Colors',     'Silver metal type label and icon',          13),
  ('metal_platinum',   'semantic', 'color', 'Metal Colors',     'Platinum metal type label and icon',        14),
  -- Financial signals
  ('signal_gain',      'semantic', 'color', 'Financial Signals','Portfolio gain and positive signal only',   10),
  ('signal_loss',      'semantic', 'color', 'Financial Signals','Portfolio loss and negative signal only',   11),
  -- Price display (price_buyback intentionally omitted — color TBD)
  -- Actions
  ('action_primary',   'semantic', 'color', 'Actions',          'CTA buttons and active/selected state',     10),
  -- Text
  ('text_primary',     'semantic', 'color', 'Text',             'Primary readable text',                     10),
  ('text_secondary',   'semantic', 'color', 'Text',             'Secondary text, labels and hints',          11),
  ('text_on_action',   'semantic', 'color', 'Text',             'Text on action/CTA buttons',                12),
  -- Backgrounds
  ('bg_app',           'semantic', 'color', 'Backgrounds',      'App scaffold background',                   10),
  ('bg_card',          'semantic', 'color', 'Backgrounds',      'Card and surface background',               11),
  -- System status
  ('status_success',   'semantic', 'color', 'System Status',    'Success toasts and badges',                 10),
  ('status_warning',   'semantic', 'color', 'System Status',    'Warning toasts and badges',                 11),
  ('status_error',     'semantic', 'color', 'System Status',    'Error toasts and badges',                   12);

-- ── Seed: Semantic typography tokens ─────────────────────────────────────────

insert into design_tokens (token_name, tier, token_type, group_name, reserved_for, sort_order) values
  ('font_family_app',    'semantic', 'font_family', 'Typography', 'App-wide font family',              10),
  ('font_size_caption',  'semantic', 'font_size',   'Typography', 'Smallest labels and captions',      20),
  ('font_size_label',    'semantic', 'font_size',   'Typography', 'Table column labels and small text', 21),
  ('font_size_body',     'semantic', 'font_size',   'Typography', 'Standard body text',                22),
  ('font_size_body_md',  'semantic', 'font_size',   'Typography', 'Medium body text',                  23),
  ('font_size_base',     'semantic', 'font_size',   'Typography', 'Base UI text size',                 24),
  ('font_size_large',    'semantic', 'font_size',   'Typography', 'Large body and card values',        25),
  ('font_size_heading_sm','semantic','font_size',   'Typography', 'Small heading',                     26),
  ('font_size_heading_md','semantic','font_size',   'Typography', 'Medium heading',                    27),
  ('font_weight_normal',  'semantic','font_weight', 'Typography', 'Normal weight text',                30),
  ('font_weight_medium',  'semantic','font_weight', 'Typography', 'Medium weight text',                31),
  ('font_weight_semibold','semantic','font_weight', 'Typography', 'Semibold headings and labels',      32),
  ('font_weight_bold',    'semantic','font_weight', 'Typography', 'Bold display text',                 33);

-- ── Seed: Semantic spacing + radius tokens ────────────────────────────────────

insert into design_tokens (token_name, tier, token_type, group_name, reserved_for, sort_order) values
  ('spacing_xs',      'semantic', 'spacing', 'Spacing', 'Extra small gap',                   10),
  ('spacing_sm',      'semantic', 'spacing', 'Spacing', 'Small gap and inner padding',       11),
  ('spacing_md',      'semantic', 'spacing', 'Spacing', 'Medium padding',                    12),
  ('spacing_card',    'semantic', 'spacing', 'Spacing', 'Card inner padding',                13),
  ('spacing_screen',  'semantic', 'spacing', 'Spacing', 'Screen edge padding',               14),
  ('spacing_xl',      'semantic', 'spacing', 'Spacing', 'Large section gap',                 15),
  ('spacing_2xl',     'semantic', 'spacing', 'Spacing', 'Extra large section gap',           16),
  ('radius_button',   'semantic', 'radius',  'Spacing', 'Button corner radius',              20),
  ('radius_card',     'semantic', 'radius',  'Spacing', 'Card corner radius',                21),
  ('opacity_subtle',  'semantic', 'opacity', 'Spacing', 'Subtle transparency for overlays',  30),
  ('opacity_medium',  'semantic', 'opacity', 'Spacing', 'Medium transparency for overlays',  31);

-- ── Seed: Dark theme — primitive values ──────────────────────────────────────

insert into design_token_values (token_id, theme_id, value) values
  -- Colors
  ((select id from design_tokens where token_name = 'prim_gold'),           (select id from design_themes where name = 'dark'), '#D4AF37'),
  ((select id from design_tokens where token_name = 'prim_gold_light'),     (select id from design_themes where name = 'dark'), '#E8D090'),
  ((select id from design_tokens where token_name = 'prim_gold_dark'),      (select id from design_themes where name = 'dark'), '#A8892A'),
  ((select id from design_tokens where token_name = 'prim_silver'),         (select id from design_themes where name = 'dark'), '#C0C0C0'),
  ((select id from design_tokens where token_name = 'prim_cyan'),           (select id from design_themes where name = 'dark'), '#00D4FF'),
  ((select id from design_tokens where token_name = 'prim_green_bright'),   (select id from design_themes where name = 'dark'), '#00C853'),
  ((select id from design_tokens where token_name = 'prim_red_bright'),     (select id from design_themes where name = 'dark'), '#FF1744'),
  ((select id from design_tokens where token_name = 'prim_white'),          (select id from design_themes where name = 'dark'), '#FFFFFF'),
  ((select id from design_tokens where token_name = 'prim_gray_mid'),       (select id from design_themes where name = 'dark'), '#B0B0B0'),
  ((select id from design_tokens where token_name = 'prim_dark_bg'),        (select id from design_themes where name = 'dark'), '#1A1A1A'),
  ((select id from design_tokens where token_name = 'prim_dark_card'),      (select id from design_themes where name = 'dark'), '#2A2A2A'),
  ((select id from design_tokens where token_name = 'prim_light_bg'),       (select id from design_themes where name = 'dark'), '#F5F5F5'),
  ((select id from design_tokens where token_name = 'prim_dark_text'),      (select id from design_themes where name = 'dark'), '#1A1A1A'),
  ((select id from design_tokens where token_name = 'prim_amber'),          (select id from design_themes where name = 'dark'), '#FFC107'),
  ((select id from design_tokens where token_name = 'prim_green_material'), (select id from design_themes where name = 'dark'), '#4CAF50'),
  ((select id from design_tokens where token_name = 'prim_red_material'),   (select id from design_themes where name = 'dark'), '#F44336'),
  -- Typography
  ((select id from design_tokens where token_name = 'prim_font_inter'),     (select id from design_themes where name = 'dark'), 'Inter'),
  ((select id from design_tokens where token_name = 'prim_size_10'),        (select id from design_themes where name = 'dark'), '10'),
  ((select id from design_tokens where token_name = 'prim_size_11'),        (select id from design_themes where name = 'dark'), '11'),
  ((select id from design_tokens where token_name = 'prim_size_12'),        (select id from design_themes where name = 'dark'), '12'),
  ((select id from design_tokens where token_name = 'prim_size_13'),        (select id from design_themes where name = 'dark'), '13'),
  ((select id from design_tokens where token_name = 'prim_size_14'),        (select id from design_themes where name = 'dark'), '14'),
  ((select id from design_tokens where token_name = 'prim_size_16'),        (select id from design_themes where name = 'dark'), '16'),
  ((select id from design_tokens where token_name = 'prim_size_20'),        (select id from design_themes where name = 'dark'), '20'),
  ((select id from design_tokens where token_name = 'prim_size_24'),        (select id from design_themes where name = 'dark'), '24'),
  ((select id from design_tokens where token_name = 'prim_size_36'),        (select id from design_themes where name = 'dark'), '36'),
  ((select id from design_tokens where token_name = 'prim_size_48'),        (select id from design_themes where name = 'dark'), '48'),
  ((select id from design_tokens where token_name = 'prim_weight_400'),     (select id from design_themes where name = 'dark'), '400'),
  ((select id from design_tokens where token_name = 'prim_weight_500'),     (select id from design_themes where name = 'dark'), '500'),
  ((select id from design_tokens where token_name = 'prim_weight_600'),     (select id from design_themes where name = 'dark'), '600'),
  ((select id from design_tokens where token_name = 'prim_weight_700'),     (select id from design_themes where name = 'dark'), '700'),
  -- Spacing
  ((select id from design_tokens where token_name = 'prim_space_4'),        (select id from design_themes where name = 'dark'), '4'),
  ((select id from design_tokens where token_name = 'prim_space_8'),        (select id from design_themes where name = 'dark'), '8'),
  ((select id from design_tokens where token_name = 'prim_space_12'),       (select id from design_themes where name = 'dark'), '12'),
  ((select id from design_tokens where token_name = 'prim_space_14'),       (select id from design_themes where name = 'dark'), '14'),
  ((select id from design_tokens where token_name = 'prim_space_16'),       (select id from design_themes where name = 'dark'), '16'),
  ((select id from design_tokens where token_name = 'prim_space_24'),       (select id from design_themes where name = 'dark'), '24'),
  ((select id from design_tokens where token_name = 'prim_space_32'),       (select id from design_themes where name = 'dark'), '32'),
  ((select id from design_tokens where token_name = 'prim_radius_8'),       (select id from design_themes where name = 'dark'), '8'),
  ((select id from design_tokens where token_name = 'prim_radius_12'),      (select id from design_themes where name = 'dark'), '12'),
  ((select id from design_tokens where token_name = 'prim_opacity_40'),     (select id from design_themes where name = 'dark'), '0.4'),
  ((select id from design_tokens where token_name = 'prim_opacity_60'),     (select id from design_themes where name = 'dark'), '0.6');

-- ── RPC: resolve_design_tokens ───────────────────────────────────────────────
-- Returns one row per token with its resolved primitive value for the theme.

create or replace function resolve_design_tokens(p_theme_id uuid)
returns table (
  token_name      text,
  token_type      text,
  resolved_value  text
)
language sql
stable
security definer
as $$
  -- Primitive tokens: return their direct value
  select
    t.token_name,
    t.token_type,
    tv.value as resolved_value
  from design_token_values tv
  join design_tokens t on t.id = tv.token_id
  where tv.theme_id = p_theme_id
    and t.tier = 'primitive'
    and tv.value is not null

  union all

  -- Semantic tokens: follow one hop to the primitive's value
  select
    t.token_name,
    t.token_type,
    prim_tv.value as resolved_value
  from design_token_values tv
  join design_tokens t      on t.id = tv.token_id
  join design_token_values prim_tv on prim_tv.token_id = tv.references_token_id
                                   and prim_tv.theme_id = p_theme_id
  where tv.theme_id = p_theme_id
    and t.tier = 'semantic'
    and tv.references_token_id is not null;
$$;

-- ── Seed: Dark theme — semantic references ────────────────────────────────────

insert into design_token_values (token_id, theme_id, references_token_id) values
  -- Metal colors
  ((select id from design_tokens where token_name = 'metal_gold'),        (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_gold')),
  ((select id from design_tokens where token_name = 'metal_gold_light'),  (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_gold_light')),
  ((select id from design_tokens where token_name = 'metal_gold_dark'),   (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_gold_dark')),
  ((select id from design_tokens where token_name = 'metal_silver'),      (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_silver')),
  ((select id from design_tokens where token_name = 'metal_platinum'),    (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_cyan')),
  -- Financial signals
  ((select id from design_tokens where token_name = 'signal_gain'),       (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_green_bright')),
  ((select id from design_tokens where token_name = 'signal_loss'),       (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_red_bright')),
  -- Actions
  ((select id from design_tokens where token_name = 'action_primary'),    (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_gold')),
  -- Text
  ((select id from design_tokens where token_name = 'text_primary'),      (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_white')),
  ((select id from design_tokens where token_name = 'text_secondary'),    (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_gray_mid')),
  ((select id from design_tokens where token_name = 'text_on_action'),    (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_dark_text')),
  -- Backgrounds
  ((select id from design_tokens where token_name = 'bg_app'),            (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_dark_bg')),
  ((select id from design_tokens where token_name = 'bg_card'),           (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_dark_card')),
  -- System status
  ((select id from design_tokens where token_name = 'status_success'),    (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_green_material')),
  ((select id from design_tokens where token_name = 'status_warning'),    (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_amber')),
  ((select id from design_tokens where token_name = 'status_error'),      (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_red_material')),
  -- Typography
  ((select id from design_tokens where token_name = 'font_family_app'),   (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_font_inter')),
  ((select id from design_tokens where token_name = 'font_size_caption'), (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_size_10')),
  ((select id from design_tokens where token_name = 'font_size_label'),   (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_size_11')),
  ((select id from design_tokens where token_name = 'font_size_body'),    (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_size_12')),
  ((select id from design_tokens where token_name = 'font_size_body_md'), (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_size_13')),
  ((select id from design_tokens where token_name = 'font_size_base'),    (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_size_14')),
  ((select id from design_tokens where token_name = 'font_size_large'),   (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_size_16')),
  ((select id from design_tokens where token_name = 'font_size_heading_sm'),(select id from design_themes where name = 'dark'),(select id from design_tokens where token_name = 'prim_size_20')),
  ((select id from design_tokens where token_name = 'font_size_heading_md'),(select id from design_themes where name = 'dark'),(select id from design_tokens where token_name = 'prim_size_24')),
  ((select id from design_tokens where token_name = 'font_weight_normal'),  (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_weight_400')),
  ((select id from design_tokens where token_name = 'font_weight_medium'),  (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_weight_500')),
  ((select id from design_tokens where token_name = 'font_weight_semibold'),(select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_weight_600')),
  ((select id from design_tokens where token_name = 'font_weight_bold'),    (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_weight_700')),
  -- Spacing
  ((select id from design_tokens where token_name = 'spacing_xs'),      (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_space_4')),
  ((select id from design_tokens where token_name = 'spacing_sm'),      (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_space_8')),
  ((select id from design_tokens where token_name = 'spacing_md'),      (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_space_12')),
  ((select id from design_tokens where token_name = 'spacing_card'),    (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_space_14')),
  ((select id from design_tokens where token_name = 'spacing_screen'),  (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_space_16')),
  ((select id from design_tokens where token_name = 'spacing_xl'),      (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_space_24')),
  ((select id from design_tokens where token_name = 'spacing_2xl'),     (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_space_32')),
  ((select id from design_tokens where token_name = 'radius_button'),   (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_radius_8')),
  ((select id from design_tokens where token_name = 'radius_card'),     (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_radius_12')),
  ((select id from design_tokens where token_name = 'opacity_subtle'),  (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_opacity_40')),
  ((select id from design_tokens where token_name = 'opacity_medium'),  (select id from design_themes where name = 'dark'), (select id from design_tokens where token_name = 'prim_opacity_60'));
