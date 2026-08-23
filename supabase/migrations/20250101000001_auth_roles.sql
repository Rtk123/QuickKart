-- ============================================================
-- QuickKart — Auth + Role-based access (migration 2)
-- Supabase SQL Editor mein yeh poora paste karke run karein
-- (pehle schema.sql already run ho chuka hona chahiye)
-- ============================================================

-- ================= 5th table: profiles =================
-- Supabase Auth khud "auth.users" table manage karta hai (email, password,
-- hashed, sessions — sab wahi handle hota hai). Hum sirf ek "profiles" table
-- banate hain jo har user se judi extra jaankari (naam, role) store karti hai.

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  role text not null default 'customer' check (role in ('customer', 'admin', 'delivery_partner')),
  created_at timestamptz default now()
);

alter table profiles enable row level security;

-- ================= Helper function: check current user's role =================
-- IMPORTANT: yeh function profiles ki policies se PEHLE banana zaroori hai,
-- kyunki neeche wali admin policy isi ko call karti hai.
--
-- `security definer` yahan sirf convenience nahi — yeh zaroori hai. Agar policy
-- seedha `select ... from profiles` karegi, to profiles ki policy dobara chalegi,
-- jo phir se profiles ko query karegi -> Postgres error:
--   42P17 infinite recursion detected in policy for relation "profiles"
-- security definer function table owner ke roop mein chalta hai, isliye RLS
-- bypass ho jaata hai aur recursion nahi hoti.
create or replace function public.current_role()
returns text
language sql
security definer set search_path = public
stable
as $$
  select role from profiles where id = auth.uid();
$$;

-- User apni hi profile padh/update kar sake
create policy "Users can view own profile" on profiles
  for select using (auth.uid() = id);

create policy "Users can update own profile" on profiles
  for update using (auth.uid() = id);

-- Admin sabki profiles dekh sake (recursion se bachne ke liye helper function se)
create policy "Admins can view all profiles" on profiles
  for select using (public.current_role() = 'admin');

-- ================= Auto-create profile on signup =================
-- Jab bhi koi naya user Supabase Auth se signup karta hai (email/password),
-- yeh trigger automatically uski profile row bana deta hai, role='customer' default.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    coalesce(new.raw_user_meta_data->>'role', 'customer')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- (Helper function public.current_role() upar profiles policies se pehle bana di gayi hai.)

-- ================= orders table: link to logged-in user + role rules =================
-- (orders.user_id column pehle se schema.sql mein hai)

-- Ab jab user logged in ho, order उसी ke user_id se banna chahiye — guest checkout band:
drop policy if exists "Users can insert own orders" on orders;
create policy "Logged-in users can insert own orders" on orders
  for insert with check (auth.uid() = user_id);

drop policy if exists "Users can view own orders" on orders;
create policy "Users view own orders, admins view all" on orders
  for select using (
    auth.uid() = user_id or public.current_role() in ('admin', 'delivery_partner')
  );

-- Admin/delivery partner order status update kar sakein (packed, out_for_delivery, delivered)
create policy "Admins and delivery can update orders" on orders
  for update using (public.current_role() in ('admin', 'delivery_partner'));

-- ================= products table: admin hi add/edit kar sake =================
create policy "Admins can insert products" on products
  for insert with check (public.current_role() = 'admin');

create policy "Admins can update products" on products
  for update using (public.current_role() = 'admin');

create policy "Admins can delete products" on products
  for delete using (public.current_role() = 'admin');

-- ================= (optional) apne pehle account ko admin banayein =================
-- Signup karne ke baad, apna email yahan daal kar yeh ek baar run karein:
-- update profiles set role = 'admin' where email = 'aapka-email@example.com';
