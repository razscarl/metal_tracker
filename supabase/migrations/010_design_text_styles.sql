-- ============================================================
-- Migration 010: Design Text Styles
-- Named text styles per theme — the CSS class equivalent.
-- Each style combines colour, font family, size and weight tokens.
-- Flutter's ThemeData is built from these at app startup.
-- ============================================================

create table if not exists design_text_styles (
  id                   uuid primary key default gen_random_uuid(),
  theme_id             uuid not null references design_themes(id) on delete cascade,
  style_name           text not null,
  display_name         text not null,
  color_token_id       uuid references design_tokens(id),
  font_size_token_id   uuid references design_tokens(id),
  font_weight_token_id uuid references design_tokens(id),
  font_family_token_id uuid references design_tokens(id),
  sort_order           int not null default 0,
  created_at           timestamptz not null default now(),
  unique (theme_id, style_name)
);

-- ── RLS ──────────────────────────────────────────────────────────────────────

alter table design_text_styles enable row level security;

create policy "text_styles_read" on design_text_styles
  for select to authenticated using (true);

create policy "text_styles_admin_write" on design_text_styles
  for all to authenticated
  using     ((select is_admin from user_profiles where id = auth.uid()))
  with check((select is_admin from user_profiles where id = auth.uid()));

-- ── RPC: resolve_text_styles ─────────────────────────────────────────────────
-- Returns all text styles for a theme with each token resolved to its value.

create or replace function resolve_text_styles(p_theme_id uuid)
returns table (
  style_name    text,
  display_name  text,
  sort_order    int,
  color_value   text,
  font_family   text,
  font_size     text,
  font_weight   text
)
language sql
stable
security definer
as $$
  select
    ts.style_name,
    ts.display_name,
    ts.sort_order,
    -- colour: resolve semantic → primitive value
    (
      select prim_tv.value
      from design_token_values sem_tv
      join design_token_values prim_tv
        on prim_tv.token_id = sem_tv.references_token_id
       and prim_tv.theme_id = p_theme_id
      where sem_tv.token_id = ts.color_token_id
        and sem_tv.theme_id = p_theme_id
      limit 1
    ) as color_value,
    -- font family
    (
      select prim_tv.value
      from design_token_values sem_tv
      join design_token_values prim_tv
        on prim_tv.token_id = sem_tv.references_token_id
       and prim_tv.theme_id = p_theme_id
      where sem_tv.token_id = ts.font_family_token_id
        and sem_tv.theme_id = p_theme_id
      limit 1
    ) as font_family,
    -- font size
    (
      select prim_tv.value
      from design_token_values sem_tv
      join design_token_values prim_tv
        on prim_tv.token_id = sem_tv.references_token_id
       and prim_tv.theme_id = p_theme_id
      where sem_tv.token_id = ts.font_size_token_id
        and sem_tv.theme_id = p_theme_id
      limit 1
    ) as font_size,
    -- font weight
    (
      select prim_tv.value
      from design_token_values sem_tv
      join design_token_values prim_tv
        on prim_tv.token_id = sem_tv.references_token_id
       and prim_tv.theme_id = p_theme_id
      where sem_tv.token_id = ts.font_weight_token_id
        and sem_tv.theme_id = p_theme_id
      limit 1
    ) as font_weight
  from design_text_styles ts
  where ts.theme_id = p_theme_id
  order by ts.sort_order;
$$;

-- ── Seed: dark theme text styles ──────────────────────────────────────────────

insert into design_text_styles (
  theme_id, style_name, display_name,
  color_token_id, font_family_token_id, font_size_token_id, font_weight_token_id,
  sort_order
)
select
  (select id from design_themes where name = 'dark'),
  s.style_name,
  s.display_name,
  (select id from design_tokens where token_name = s.color),
  (select id from design_tokens where token_name = 'font_family_app'),
  (select id from design_tokens where token_name = s.size),
  (select id from design_tokens where token_name = s.weight),
  s.sort_order
from (values
  ('heading_1',    'Heading 1',       'text_primary',   'font_size_heading_md', 'font_weight_semibold', 10),
  ('heading_2',    'Heading 2',       'text_primary',   'font_size_heading_sm', 'font_weight_semibold', 20),
  ('body',         'Body Text',       'text_primary',   'font_size_body',       'font_weight_normal',   30),
  ('body_medium',  'Body Medium',     'text_primary',   'font_size_body_md',    'font_weight_normal',   40),
  ('label',        'Label',           'text_secondary', 'font_size_label',      'font_weight_medium',   50),
  ('caption',      'Caption',         'text_secondary', 'font_size_caption',    'font_weight_normal',   60),
  ('button_label', 'Button',          'text_on_action', 'font_size_base',       'font_weight_semibold', 70),
  ('card_title',   'Card Title',      'text_primary',   'font_size_base',       'font_weight_semibold', 80),
  ('data_value',   'Data Value',      'text_primary',   'font_size_large',      'font_weight_bold',     90),
  ('data_label',   'Data Label',      'text_secondary', 'font_size_label',      'font_weight_normal',  100)
) as s(style_name, display_name, color, size, weight, sort_order);
