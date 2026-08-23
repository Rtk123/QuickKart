-- ============================================================
-- QuickKart — search ko 30k catalog par tez banana (migration 6)
--
-- Pehle app do columns par OR karta tha:
--   name.ilike.%term% OR name_hi.ilike.%term%
-- Do alag columns par OR hone ki wajah se Postgres trigram index use nahi
-- kar paata tha aur 30,000 rows par search ~1-2 second le raha tha.
--
-- Ab ek generated column `search_text` (name + name_hi) hai jiske upar GIN
-- trigram index laga hai — wahi search ab ~250ms mein ho jaati hai, aur
-- English/Hindi dono naam usi ek column mein aa jaate hain.
-- ============================================================

create extension if not exists pg_trgm with schema extensions;

alter table products
  add column if not exists search_text text
  generated always as (name || ' ' || coalesce(name_hi, '')) stored;

create index if not exists idx_products_search_trgm
  on products using gin (search_text extensions.gin_trgm_ops);

-- Category filter + is_active ke liye composite index.
create index if not exists idx_products_active_cat
  on products (is_active, category_id);

-- Pagination hamesha `order by name` karta hai, isliye uspar bhi index.
create index if not exists idx_products_name on products (name);

analyze products;
