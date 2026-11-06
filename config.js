// ===== CONFIG: yaha apni keys daalo =====
window.CONFIG = {
  STORE_NAME: "SHOP.CO",
  SUPABASE_URL: "https://ngammkyrbbfwhryytnwx.supabase.co",
  SUPABASE_ANON_KEY: "sb_publishable_sDQyJ0EyU-rlcmSm0x-VLg_dWOzPrup",
  RAZORPAY_KEY_ID: "rzp_test_TusCjAN4XOJTkH",       // sirf key_id, secret kabhi nahi
  WORKER_URL: "mute-morning-6227.kajgarvarad.workers.dev", // Cloudflare Worker (razorpay order + verify, shopify proxy)
  SHOPIFY_DOMAIN: "realisticmart.myshopify.com",
  SHOPIFY_STOREFRONT_TOKEN: "f11a8d8ee0d54180f59a89c81ea89da8",
  ADMIN_EMAILS: ["admin@gmail.com"],
  FREE_SHIPPING_ABOVE: 999, SHIPPING_FEE: 79, GST_PERCENT: 5, RETURN_DAYS: 7
};
/* ===== SUPABASE SQL (SQL Editor me run karo) =====
create table products(id uuid primary key default gen_random_uuid(),title text,price numeric,mrp numeric,image text,category text,stock int default 50,active bool default true);
create table orders(id uuid primary key default gen_random_uuid(),user_id uuid default auth.uid(),email text,name text,phone text,address text,pin text,items jsonb,total numeric,status text default 'Placed',payment_id text,created_at timestamptz default now());
create table returns(id uuid primary key default gen_random_uuid(),order_id uuid,user_id uuid default auth.uid(),email text,reason text,status text default 'Requested',created_at timestamptz default now());
create table subscribers(email text primary key,created_at timestamptz default now());
create table profiles(id uuid primary key default auth.uid(),name text,phone text,address text,pin text);
alter table products enable row level security; alter table orders enable row level security; alter table returns enable row level security; alter table subscribers enable row level security; alter table profiles enable row level security;
create function is_admin() returns bool language sql as $$ select (auth.jwt()->>'email') = any(array['youradmin@gmail.com']) $$;
create policy p_read on products for select using(true);
create policy p_admin on products for all using(is_admin());
create policy o_own on orders for select using(user_id=auth.uid() or is_admin());
create policy o_ins on orders for insert with check(user_id=auth.uid());
create policy o_upd on orders for update using(is_admin());
create policy r_own on returns for select using(user_id=auth.uid() or is_admin());
create policy r_ins on returns for insert with check(user_id=auth.uid());
create policy r_upd on returns for update using(is_admin());
create policy s_ins on subscribers for insert with check(true);
create policy s_adm on subscribers for select using(is_admin());
create policy pr_own on profiles for all using(id=auth.uid()) with check(id=auth.uid());
*/
