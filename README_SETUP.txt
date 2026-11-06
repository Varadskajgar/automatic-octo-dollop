JENDORA — SUPABASE BACKEND FOUNDATION
====================================

IMPORTANT STATUS
This package contains the Supabase database foundation, RLS policies, storage bucket,
secure admin-role table, server-calculated order-creation RPC, browser client helpers,
and your existing storefront/admin files for reference.
It is NOT a finished live-commerce deployment yet: the existing legacy pages still
contain localStorage/demo flows and must be migrated to call JENDORA_DB. Online payment
verification, GST-compliant invoice issuance, email/OTP delivery and shipping-provider
tracking require separate server-side integrations. Do not accept real payments until
those are implemented and tested.

FILES
- index.html / admin.html: existing JENDORA pages (legacy prototype)
- config.js: public Supabase URL/key placeholders + admin email placeholder
- supabase-client.js: Supabase JS v2 client and data helper functions
- supabase_schema.sql: complete initial database schema, RLS, RPC, storage policies

SETUP
1. Create a NEW Supabase project.
2. Open SQL Editor > New query. Paste all of supabase_schema.sql and Run.
3. In Project Settings > API, copy Project URL and the publishable key (or legacy anon
   key). Put those two values in config.js. Never use the secret/service_role key.
4. In Supabase Authentication > Providers, enable Google and configure Google OAuth
   credentials + authorized redirect URLs for your deployed domain and localhost.
5. Sign up / sign in once using the Gmail that will own the JENDORA admin account.
6. In SQL Editor run the following, replacing the email:

   insert into public.admin_users(user_id)
   select id from auth.users where lower(email)=lower('YOUR_ADMIN_GMAIL@gmail.com')
   on conflict(user_id) do nothing;

7. Include these scripts in each page BEFORE the page's own application script:

   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
   <script src="config.js"></script>
   <script src="supabase-client.js"></script>

8. Host on HTTPS. Test with two separate browser profiles: customer and admin.

DATABASE FEATURES
- Products, categories, banners, store settings, coupons
- Customer profiles, orders, order items, reviews, wishlists
- Admin role table + RLS authorization
- Public read of active catalog; admin-only catalog/settings writes
- Customer can read only own orders; admin can manage orders
- Product stock is checked/decremented in place_order RPC
- Order totals are calculated from DB prices in integer paise
- Public product/banner image bucket with admin-only uploads

SECURITY / PRODUCTION NOTES
- Never expose Supabase secret/service_role keys or payment gateway secrets in config.js.
- Never trust a total, product price, tax amount, or PAID status supplied by the browser.
- place_order creates an order as PENDING; it does not mark payment paid.
- A payment Edge Function + verified gateway webhook must be added before live UPI/cards.
- GST invoice number should be issued only after verified payment / valid COD collection,
  using seller GSTIN, HSN, place of supply and CGST/SGST or IGST rules reviewed by a CA.
- Configure Auth email/Google provider, SMTP, domain allowlists, backups and rate limits.
- SQL bootstrap admin query must be run only after the intended user has signed up.
- For an existing production database, review SQL carefully before running migrations.

SUPABASE DOCS
https://supabase.com/docs
https://supabase.com/docs/guides/auth/social-login/auth-google
https://supabase.com/docs/guides/database/postgres/row-level-security
