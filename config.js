/* Public browser configuration only. Never paste service_role/secret/payment secrets here. */
window.JENDORA_CONFIG = Object.freeze({
  storeName: 'JENDORA',
  currency: 'INR',
  supabaseUrl: 'https://YOUR_PROJECT_REF.supabase.co',
  supabaseAnonKey: 'YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY',
  adminEmail: 'YOUR_ADMIN_GMAIL@gmail.com',
  storageBucket: 'jendora-assets',
  paymentMode: 'disabled_until_server_gateway_setup'
});
