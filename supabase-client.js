/* JENDORA Supabase browser client + safe data helpers.
   Load after config.js and before app scripts. Supabase JS v2 is loaded from CDN. */
(function(){
  const cfg=window.JENDORA_CONFIG||{};
  if(!cfg.supabaseUrl||cfg.supabaseUrl.includes('YOUR_PROJECT_REF')||!cfg.supabaseAnonKey||cfg.supabaseAnonKey.startsWith('YOUR_')){
    console.warn('JENDORA: Add Supabase URL and publishable/anon key in config.js'); return;
  }
  if(!window.supabase?.createClient){console.error('Supabase JS SDK missing');return;}
  const client=window.supabase.createClient(cfg.supabaseUrl,cfg.supabaseAnonKey,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
  window.JENDORA_DB={client,
    async products(){const {data,error}=await client.from('products').select('*').eq('active',true).order('created_at',{ascending:false});if(error)throw error;return (data||[]).map(p=>({...p,price:Number(p.price_paise)/100,image:p.image_url,images:p.images||[],category:p.category||'Other'}));},
    async addProduct(p){const row={sku:p.sku||null,title:p.title,brand:p.brand||null,category:p.category||'Other',description:p.desc||p.description||'',price_paise:Math.round(Number(p.price)*100),image_url:p.image||p.image_url||null,images:p.images||[],sizes:p.sizes||[],stock:Number(p.stock||0),tag:p.tag||null,active:true};const q=p.id?client.from('products').update(row).eq('id',p.id).select().single():client.from('products').insert(row).select().single();const {data,error}=await q;if(error)throw error;return data;},
    async deleteProduct(id){const {error}=await client.from('products').delete().eq('id',id);if(error)throw error;},
    async categories(){const {data,error}=await client.from('categories').select('*').eq('active',true).order('sort_order');if(error)throw error;return data||[];},
    async orders(){const {data,error}=await client.from('orders').select('*,order_items(*)').order('created_at',{ascending:false});if(error)throw error;return data||[];},
    async updateOrder(id,status){const {error}=await client.from('orders').update({status,updated_at:new Date().toISOString()}).eq('id',id);if(error)throw error;},
    async settings(){const {data,error}=await client.from('store_settings').select('*');if(error)throw error;return Object.fromEntries((data||[]).map(x=>[x.key,x.value]));},
    async saveSetting(key,value){const {error}=await client.from('store_settings').upsert({key,value});if(error)throw error;},
    async signInWithGoogle(){return client.auth.signInWithOAuth({provider:'google',options:{redirectTo:location.origin+location.pathname}});},
    async isAdmin(){const {data:{user}}=await client.auth.getUser();if(!user)return false;const {data,error}=await client.from('admin_users').select('user_id').eq('user_id',user.id).maybeSingle();if(error)throw error;return !!data;},
    async placeOrder(payload){const {data,error}=await client.rpc('place_order',payload);if(error)throw error;return data;},
    async signOut(){return client.auth.signOut();}
  };
})();
