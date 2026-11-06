JENDORA — SUPABASE CONNECTED WEBSITE
====================================

WHAT IS CONNECTED
- Storefront product/category/banner/settings reads use Supabase.
- Admin uses Supabase Google OAuth and admin_users authorization (RLS enforced).
- Admin product create/edit/delete, category management, banner management, order status updates, settings and Storage uploads use Supabase.
- Customer checkout calls the database place_order RPC; prices, tax, shipping, stock and totals are calculated server-side. Orders remain PENDING.
- Cart exists only in the current page session; it is not a database or localStorage catalog.
- No demo products, fake orders, demo admin shortcut, or localStorage database remains.

REQUIRED BEFORE USE
1. In Supabase SQL Editor run supabase_schema.sql on your project (only if not already run).
2. Edit config.js and set the Supabase Project URL and publishable/anon key. NEVER use service_role/secret key.
3. Supabase Auth > Providers: enable Google and configure OAuth credentials and redirect URLs for your hosted domain.
4. Sign in once with your intended admin Google account.
5. In SQL Editor grant that user admin access (replace email):
   insert into public.admin_users(user_id)
   select id from auth.users where lower(email)=lower('YOUR_ADMIN_GMAIL@gmail.com')
   on conflict(user_id) do nothing;
6. Host all files on HTTPS, keeping index.html, admin.html, config.js and supabase-client.js together.
7. Open admin.html, sign in, then add categories/products/banners.

IMPORTANT LIMITATIONS / SAFETY
- Online payment gateway is NOT integrated. Checkout creates PENDING orders only; no payment is collected and no paid invoice is issued. Add a payment Edge Function + verified webhook before enabling online payments.
- This database schema does not provide a full shipping-provider integration, customer email/OTP notifications, GST-compliant tax invoices, or subscription billing.
- The schema's order_items customer read policy and admin permissions are governed by the supplied SQL/RLS. Test using separate customer/admin accounts.
- Product delete may be blocked when historical order references exist; prefer setting product inactive in that case.
- Product/category/banner image URL fields accept direct URLs; product upload uses the jendora-assets bucket.
- The SQL place_order RPC provided in the original schema decrements inventory and creates PENDING orders. Test stock and checkout carefully before launch.
- Do not expose Supabase secret/service_role keys, payment secrets or private tokens in config.js.

FILES
index.html — Supabase-powered storefront
admin.html — authenticated admin dashboard
config.js — public Supabase configuration placeholders
supabase-client.js — shared Supabase data layer
supabase_schema.sql — database schema/RLS/RPC/storage policies


ORDER AUTHENTICATION UPDATE
---------------------------
Orders now require a valid Supabase Auth session. Guest checkout is disabled in the storefront and the place_order SQL function rejects unauthenticated calls. Re-run the updated supabase_schema.sql in Supabase SQL Editor after backing up any existing data.

Google sign-in prerequisite: enable Google under Supabase Authentication > Providers, configure Google OAuth Client ID/Secret, and add your exact deployed site URL and redirect URL under Authentication > URL Configuration. The browser code cannot enable/configure Google's OAuth provider for you.
