-- JENDORA Supabase schema (PostgreSQL)
-- Run once in Supabase SQL Editor on a NEW project. Review before running on an existing DB.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  created_at timestamptz not null default now()
);
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin','manager')),
  created_at timestamptz not null default now()
);
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.admin_users a where a.user_id = auth.uid()); $$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(), name text not null unique,
  slug text not null unique, image_url text, sort_order int not null default 0,
  active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(), sku text unique,
  title text not null, brand text, category_id uuid references public.categories(id) on delete set null,
  category text, description text, price_paise bigint not null check(price_paise >= 0),
  compare_at_price_paise bigint check(compare_at_price_paise is null or compare_at_price_paise >= 0),
  image_url text, images jsonb not null default '[]'::jsonb,
  sizes text[] not null default '{}', stock int not null default 0 check(stock >= 0),
  tag text, active boolean not null default true, featured boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists products_active_created_idx on public.products(active, created_at desc);
create index if not exists products_category_idx on public.products(category_id);

create table if not exists public.store_settings (
  key text primary key, value jsonb not null, updated_at timestamptz not null default now()
);
insert into public.store_settings(key,value) values
 ('currency','"INR"'::jsonb),('shipping_fee_paise','9900'::jsonb),
 ('free_shipping_threshold_paise','199900'::jsonb),('gst_rate','18'::jsonb),
 ('announcement','"Complimentary shipping on orders over ₹1,999"'::jsonb)
on conflict(key) do nothing;
create table if not exists public.banners (
 id uuid primary key default gen_random_uuid(), title text not null, subtitle text,
 image_url text, link_url text, active boolean not null default true,
 sort_order int not null default 0, created_at timestamptz not null default now()
);
create table if not exists public.coupons (
 id uuid primary key default gen_random_uuid(), code text not null unique,
 discount_type text not null check(discount_type in ('percent','fixed')),
 discount_value numeric(12,2) not null check(discount_value > 0),
 min_order_paise bigint not null default 0, max_uses int, used_count int not null default 0,
 starts_at timestamptz, expires_at timestamptz, active boolean not null default true
);
create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(), order_number text not null unique,
 user_id uuid references auth.users(id) on delete set null,
 customer_name text not null, customer_email text not null, customer_phone text not null,
 shipping_address jsonb not null, subtotal_paise bigint not null,
 discount_paise bigint not null default 0, shipping_paise bigint not null default 0,
 tax_paise bigint not null default 0, total_paise bigint not null,
 status text not null default 'Order placed',
 payment_status text not null default 'PENDING' check(payment_status in ('PENDING','PAID','FAILED','REFUNDED','COD')),
 payment_provider text, payment_reference text, invoice_number text unique,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists orders_user_created_idx on public.orders(user_id,created_at desc);
create table if not exists public.order_items (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null,
 product_title text not null, sku text, selected_size text,
 unit_price_paise bigint not null, quantity int not null check(quantity > 0),
 line_total_paise bigint not null
);
create table if not exists public.reviews (
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 user_id uuid references auth.users(id) on delete set null,
 customer_name text not null, rating int not null check(rating between 1 and 5),
 review_text text not null, approved boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.wishlists (
 user_id uuid not null references auth.users(id) on delete cascade,
 product_id uuid not null references public.products(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(user_id,product_id)
);
create table if not exists public.audit_log (
 id bigint generated always as identity primary key, actor uuid references auth.users(id),
 action text not null, entity text not null, entity_id text, details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

-- Public storefront read access; writes are admin-only.
alter table public.profiles enable row level security;
alter table public.admin_users enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.store_settings enable row level security;
alter table public.banners enable row level security;
alter table public.coupons enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.reviews enable row level security;
alter table public.wishlists enable row level security;
alter table public.audit_log enable row level security;

drop policy if exists "profiles own read" on public.profiles;
create policy "profiles own read" on public.profiles for select to authenticated using(id=auth.uid() or public.is_admin());
drop policy if exists "profiles own update" on public.profiles;
create policy "profiles own update" on public.profiles for update to authenticated using(id=auth.uid() or public.is_admin()) with check(id=auth.uid() or public.is_admin());
drop policy if exists "admins read admin list" on public.admin_users;
create policy "admins read admin list" on public.admin_users for select to authenticated using(user_id=auth.uid() or public.is_admin());

drop policy if exists "public active categories" on public.categories;
create policy "public active categories" on public.categories for select to anon,authenticated using(active or public.is_admin());
drop policy if exists "admin manage categories" on public.categories;
create policy "admin manage categories" on public.categories for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "public active products" on public.products;
create policy "public active products" on public.products for select to anon,authenticated using(active or public.is_admin());
drop policy if exists "admin manage products" on public.products;
create policy "admin manage products" on public.products for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "public store settings read" on public.store_settings;
create policy "public store settings read" on public.store_settings for select to anon,authenticated using(true);
drop policy if exists "admin manage settings" on public.store_settings;
create policy "admin manage settings" on public.store_settings for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "public active banners" on public.banners;
create policy "public active banners" on public.banners for select to anon,authenticated using(active or public.is_admin());
drop policy if exists "admin manage banners" on public.banners;
create policy "admin manage banners" on public.banners for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "public active coupons" on public.coupons;
create policy "public active coupons" on public.coupons for select to anon,authenticated using(active);
drop policy if exists "admin manage coupons" on public.coupons;
create policy "admin manage coupons" on public.coupons for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "customer own orders" on public.orders;
create policy "customer own orders" on public.orders for select to authenticated using(user_id=auth.uid() or public.is_admin());
drop policy if exists "admin manage orders" on public.orders;
create policy "admin manage orders" on public.orders for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "customer own order items" on public.order_items;
create policy "customer own order items" on public.order_items for select to authenticated using(exists(select 1 from public.orders o where o.id=order_id and (o.user_id=auth.uid() or public.is_admin())));
drop policy if exists "admin manage order items" on public.order_items;
create policy "admin manage order items" on public.order_items for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "approved reviews public" on public.reviews;
create policy "approved reviews public" on public.reviews for select to anon,authenticated using(approved or user_id=auth.uid() or public.is_admin());
drop policy if exists "customer submit review" on public.reviews;
create policy "customer submit review" on public.reviews for insert to authenticated with check(user_id=auth.uid() and approved=false);
drop policy if exists "admin moderate reviews" on public.reviews;
create policy "admin moderate reviews" on public.reviews for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "own wishlist" on public.wishlists;
create policy "own wishlist" on public.wishlists for all to authenticated using(user_id=auth.uid() or public.is_admin()) with check(user_id=auth.uid() or public.is_admin());
drop policy if exists "admin audit read" on public.audit_log;
create policy "admin audit read" on public.audit_log for select to authenticated using(public.is_admin());
drop policy if exists "admin audit insert" on public.audit_log;
create policy "admin audit insert" on public.audit_log for insert to authenticated with check(public.is_admin());

-- Order placement RPC: totals and product prices are calculated from database rows, not browser prices.
create or replace function public.place_order(
 p_customer_name text, p_customer_email text, p_customer_phone text,
 p_shipping_address jsonb, p_items jsonb, p_coupon_code text default null
) returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_order_id uuid; v_order_no text; v_subtotal bigint:=0; v_shipping bigint:=0;
 v_tax bigint:=0; v_total bigint:=0; v_discount bigint:=0; v_rate numeric:=18;
 v_ship_fee bigint:=9900; v_free_threshold bigint:=199900; v_item jsonb; v_product public.products%rowtype;
 v_qty int; v_line bigint; v_coupon public.coupons%rowtype;
begin
 if auth.uid() is null then raise exception 'AUTH_SESSION_MISSING: Sign in before placing an order'; end if;
 if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items)=0 then raise exception 'Cart is empty'; end if;
 if length(trim(coalesce(p_customer_name,'')))<2 or position('@' in coalesce(p_customer_email,''))<2 then raise exception 'Valid customer name and email required'; end if;
 select coalesce((value#>>'{}')::numeric,18) into v_rate from public.store_settings where key='gst_rate';
 select coalesce((value#>>'{}')::bigint,9900) into v_ship_fee from public.store_settings where key='shipping_fee_paise';
 select coalesce((value#>>'{}')::bigint,199900) into v_free_threshold from public.store_settings where key='free_shipping_threshold_paise';
 for v_item in select * from jsonb_array_elements(p_items) loop
   v_qty:=greatest(1,least(20,coalesce((v_item->>'quantity')::int,1)));
   select * into v_product from public.products where id=(v_item->>'product_id')::uuid and active=true for update;
   if not found then raise exception 'Product unavailable'; end if;
   if v_product.stock < v_qty then raise exception 'Insufficient stock for %',v_product.title; end if;
   v_line:=v_product.price_paise*v_qty; v_subtotal:=v_subtotal+v_line;
 end loop;
 if p_coupon_code is not null and trim(p_coupon_code)<>'' then
   select * into v_coupon from public.coupons where code=upper(trim(p_coupon_code)) and active=true
    and (starts_at is null or starts_at<=now()) and (expires_at is null or expires_at>now())
    and (max_uses is null or used_count<max_uses) for update;
   if found and v_subtotal>=v_coupon.min_order_paise then
     if v_coupon.discount_type='percent' then v_discount:=least(v_subtotal,round(v_subtotal*v_coupon.discount_value/100));
     else v_discount:=least(v_subtotal,round(v_coupon.discount_value*100)); end if;
     update public.coupons set used_count=used_count+1 where id=v_coupon.id;
   end if;
 end if;
 if v_subtotal-v_discount < v_free_threshold then v_shipping:=v_ship_fee; end if;
 v_tax:=round(((v_subtotal-v_discount)::numeric)*v_rate/100);
 v_total:=v_subtotal-v_discount+v_shipping+v_tax;
 v_order_no:='JD-'||to_char(now(),'YYMMDD')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
 insert into public.orders(order_number,user_id,customer_name,customer_email,customer_phone,shipping_address,subtotal_paise,discount_paise,shipping_paise,tax_paise,total_paise,payment_status)
 values(v_order_no,auth.uid(),trim(p_customer_name),lower(trim(p_customer_email)),trim(p_customer_phone),p_shipping_address,v_subtotal,v_discount,v_shipping,v_tax,v_total,'PENDING')
 returning id into v_order_id;
 for v_item in select * from jsonb_array_elements(p_items) loop
   v_qty:=greatest(1,least(20,coalesce((v_item->>'quantity')::int,1)));
   select * into v_product from public.products where id=(v_item->>'product_id')::uuid and active=true for update;
   v_line:=v_product.price_paise*v_qty;
   insert into public.order_items(order_id,product_id,product_title,sku,selected_size,unit_price_paise,quantity,line_total_paise)
    values(v_order_id,v_product.id,v_product.title,v_product.sku,nullif(v_item->>'size',''),v_product.price_paise,v_qty,v_line);
   update public.products set stock=stock-v_qty,updated_at=now() where id=v_product.id;
 end loop;
 return jsonb_build_object('order_id',v_order_id,'order_number',v_order_no,'subtotal_paise',v_subtotal,'discount_paise',v_discount,'shipping_paise',v_shipping,'tax_paise',v_tax,'total_paise',v_total,'payment_status','PENDING');
end; $$;
revoke all on function public.place_order(text,text,text,jsonb,jsonb,text) from public;
revoke execute on function public.place_order(text,text,text,jsonb,jsonb,text) from anon;
grant execute on function public.place_order(text,text,text,jsonb,jsonb,text) to authenticated;

-- Storage bucket for public product/banner images. Admin-only upload/update/delete.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('jendora-assets','jendora-assets',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;
drop policy if exists "public read jendora assets" on storage.objects;
create policy "public read jendora assets" on storage.objects for select using(bucket_id='jendora-assets');
drop policy if exists "admin upload jendora assets" on storage.objects;
create policy "admin upload jendora assets" on storage.objects for insert to authenticated with check(bucket_id='jendora-assets' and public.is_admin());
drop policy if exists "admin update jendora assets" on storage.objects;
create policy "admin update jendora assets" on storage.objects for update to authenticated using(bucket_id='jendora-assets' and public.is_admin()) with check(bucket_id='jendora-assets' and public.is_admin());
drop policy if exists "admin delete jendora assets" on storage.objects;
create policy "admin delete jendora assets" on storage.objects for delete to authenticated using(bucket_id='jendora-assets' and public.is_admin());

-- Bootstrap admin: after creating the admin user via Supabase Auth, replace the email below
-- and run this insert. This script intentionally does NOT grant admin based on a browser email field.
-- insert into public.admin_users(user_id)
-- select id from auth.users where lower(email)=lower('YOUR_ADMIN_GMAIL@gmail.com')
-- on conflict(user_id) do nothing;
