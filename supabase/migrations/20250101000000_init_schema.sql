-- QuickKart Supabase schema
-- Supabase dashboard -> SQL editor mein yeh poora paste karke run karein.

-- ================= Categories =================
create table if not exists categories (
  id text primary key,
  name text not null,
  sort_order int default 0
);

insert into categories (id, name, sort_order) values
  ('grocery', 'ग्रोसरी', 1),
  ('electronics', 'इलेक्ट्रॉनिक्स', 2),
  ('fashion', 'फैशन', 3),
  ('home', 'होम एंड किचन', 4),
  ('beauty', 'ब्यूटी', 5),
  ('baby', 'बेबी केयर', 6)
on conflict (id) do nothing;

-- ================= Products =================
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  unit text not null,
  category_id text references categories(id),
  price numeric(10,2) not null,
  mrp numeric(10,2) not null,
  icon text default '📦',
  image_url text,
  stock int default 100,
  is_active boolean default true,
  created_at timestamptz default now()
);

create index if not exists idx_products_category on products(category_id);

-- ================= Orders =================
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  order_ref text unique not null,          -- Cashfree order_id yahan store hoga
  user_id uuid references auth.users(id),
  customer_name text not null,
  customer_phone text not null,
  customer_email text not null,
  delivery_address text not null,
  item_total numeric(10,2) not null,
  delivery_fee numeric(10,2) not null default 0,
  total_amount numeric(10,2) not null,
  payment_status text not null default 'pending',  -- pending | paid | failed
  order_status text not null default 'placed',      -- placed | packed | out_for_delivery | delivered | cancelled
  created_at timestamptz default now()
);

create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  product_id uuid references products(id),
  product_name text not null,
  quantity int not null,
  price numeric(10,2) not null
);

-- ================= Row Level Security =================
alter table products enable row level security;
alter table categories enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;

-- कोई भी (logged-in ya anonymous) products/categories padh sake
create policy "Public can read active products" on products
  for select using (is_active = true);

create policy "Public can read categories" on categories
  for select using (true);

-- User sirf apne orders dekh sake, apna naya order bana sake
create policy "Users can insert own orders" on orders
  for insert with check (auth.uid() = user_id or user_id is null);

create policy "Users can view own orders" on orders
  for select using (auth.uid() = user_id or user_id is null);

create policy "Users can insert own order items" on order_items
  for insert with check (
    exists (select 1 from orders where orders.id = order_id and (orders.user_id = auth.uid() or orders.user_id is null))
  );

create policy "Users can view own order items" on order_items
  for select using (
    exists (select 1 from orders where orders.id = order_id and (orders.user_id = auth.uid() or orders.user_id is null))
  );

-- NOTE: payment_status ko सिर्फ backend (service_role key से, Cashfree webhook) update karega,
-- isliye orders table par 'update' policy jaan-bujhkar client ke liye nahi rakhi गई है।

-- ================= Sample products =================
insert into products (name, unit, category_id, price, mrp, icon) values
  ('ताज़ा टमाटर', '1 kg', 'grocery', 38, 45, '🍅'),
  ('अमूल दूध', '500 ml', 'grocery', 29, 32, '🥛'),
  ('बासमती चावल', '5 kg', 'grocery', 399, 450, '🍚'),
  ('सरसों तेल', '1 L', 'grocery', 145, 160, '🛢️'),
  ('आलू', '1 kg', 'grocery', 22, 28, '🥔'),
  ('ब्रेड', '400 g', 'grocery', 35, 40, '🍞'),
  ('वायरलेस ईयरबड्स', '1 यूनिट', 'electronics', 1299, 2499, '🎧'),
  ('पावर बैंक 10000mAh', '1 यूनिट', 'electronics', 899, 1499, '🔋'),
  ('USB-C चार्जिंग केबल', '1 यूनिट', 'electronics', 149, 299, '🔌'),
  ('ब्लूटूथ स्पीकर', '1 यूनिट', 'electronics', 1099, 1999, '🔊'),
  ('कॉटन कुर्ता (पुरुष)', '1 यूनिट', 'fashion', 599, 999, '👕'),
  ('महिलाओं की साड़ी', '1 यूनिट', 'fashion', 899, 1499, '🥻'),
  ('स्नीकर्स', '1 जोड़ी', 'fashion', 1299, 2199, '👟'),
  ('नॉन-स्टिक तवा', '1 यूनिट', 'home', 349, 599, '🍳'),
  ('LED बल्ब 9W', '1 यूनिट', 'home', 89, 150, '💡'),
  ('कॉटन बेडशीट', '1 सेट', 'home', 499, 899, '🛏️'),
  ('फेस वॉश', '100 g', 'beauty', 159, 220, '🧴'),
  ('शैम्पू', '340 ml', 'beauty', 189, 249, '🧴'),
  ('बेबी डायपर', 'पैक ऑफ 30', 'baby', 499, 649, '🍼'),
  ('बेबी वाइप्स', '80 शीट्स', 'baby', 99, 140, '🧻')
on conflict do nothing;
