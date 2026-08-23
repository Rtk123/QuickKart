# QuickKart — Flutter + Supabase (fully Supabase-native)

Blinkit-jaisi quick-commerce app: Flutter frontend, Supabase Postgres database, Supabase Auth (email/password + roles), Supabase Edge Functions for Cashfree payments. Koi alag Node.js hosting nahi chahiye — sab kuch Supabase ke andar hai.

## Architecture

```
Flutter App
   |-- reads/writes -->  Supabase Postgres (products, orders, profiles) via anon key + RLS
   |-- calls -------->   Supabase Edge Functions (create-order, order-status)
                              |
                              v
                        Cashfree Payment Gateway
                              |
                              v (webhook)
                        Edge Function (cashfree-webhook) --> updates orders.payment_status
```

## Current status — Devtest project (`kxcfqlciuzkydixjprks`)

Yeh sab **already deploy ho chuka hai** (23 Aug 2026):

- [x] Dono migrations apply — 5 tables (`categories`, `products`, `orders`, `order_items`, `profiles`), RLS policies, signup trigger, 6 categories + 20 sample products
- [x] Teeno Edge Functions deployed aur ACTIVE (`create-order`, `cashfree-webhook`, `order-status`), `verify_jwt = false`
- [x] Secrets set: `CASHFREE_ENV=sandbox`, `PROJECT_URL`
- [ ] **Baaki sirf yeh:** `CASHFREE_APP_ID` aur `CASHFREE_SECRET_KEY` (Step 4 dekhein) — inke bina `create-order` Cashfree se `authentication Failed` deta hai

Neeche ke Step 1-6 sirf reference ke liye hain (ya nayi/production project setup ke liye). Devtest par bas Step 4 aur Step 7 baaki hain.

> **Production project** (`sgfmhutjfrfylbsznarr`) ko abhi haath nahi lagaya gaya hai — wahan schema/functions deploy nahi hue hain.

## Step 1 — Supabase CLI install aur login

```bash
npm install -g supabase
supabase login
```
(Browser khulega, apne Supabase account se login karein)

## Step 2 — Project link karein

```bash
cd quickkart_flutter
supabase link --project-ref kxcfqlciuzkydixjprks
```
Yeh aapka database password maangega (Supabase dashboard -> Project Settings -> Database mein milega, ya wahi jo project banate waqt set kiya tha).

## Step 3 — Migrations push karein (db tables banayein)

```bash
supabase db push
```
Isse `supabase/migrations/` ki dono files (schema + auth/roles) aapke live database par apply ho jaayengi — total 5 tables ban jaayenge: `categories`, `products`, `orders`, `order_items`, `profiles`, saath mein RLS policies aur 20 sample products.

## Step 4 — Cashfree keys ko Edge Function secrets mein daalein

Pehle Cashfree account banayein (agar nahi bana): https://merchant.cashfree.com/merchants/signup — App ID aur Secret Key milegi.

`supabase/functions/.env` file mein apni keys bharein (template `supabase/functions/.env.example` mein hai), phir ek command se sab secrets push karein:

```bash
supabase secrets set --env-file supabase/functions/.env
```

Local testing ke liye functions ko isi file ke saath chalayein:

```bash
supabase functions serve --env-file supabase/functions/.env
```

(`SUPABASE_URL` aur `SUPABASE_SERVICE_ROLE_KEY` Edge Functions mein already automatically available hoti hain — inhe manually set karne ki zaroorat nahi.)

## Step 5 — Edge Functions deploy karein

```bash
supabase functions deploy create-order
supabase functions deploy cashfree-webhook
supabase functions deploy order-status
```

## Step 6 — Cashfree webhook set karein

Cashfree dashboard -> Developers -> Webhooks mein add karein:
```
https://kxcfqlciuzkydixjprks.supabase.co/functions/v1/cashfree-webhook
```

## Step 7 — Flutter app chalayein

```bash
cp .env.example .env    # Windows: copy .env.example .env
flutter pub get
flutter run
```

App apna Supabase URL/key root ki `.env` file se padhta hai (`lib/config/env.dart` ke through) — code mein koi key hardcoded nahi hai.

### Platforms

`android/`, `web/`, aur `windows/` folders `flutter create . --project-name quickkart --platforms=android,web,windows` se generate kiye gaye hain. Kisi bhi platform par chalane ke liye:

```bash
flutter run -d chrome      # sabse tez, UI dekhne ke liye
flutter run -d windows     # native desktop
flutter run -d android     # asli target (pehle JDK chahiye, neeche dekhein)
```

Do zaroori baatein:

- **Android ke liye JDK chahiye.** `flutter doctor` abhi bolta hai *"No Java Development Kit (JDK) found"*. JDK 17 install karke `JAVA_HOME` set karein, tabhi Android build chalega. Android SDK 36.1.0 already installed hai.
- **Payment webview sirf Android/iOS par chalta hai.** `webview_flutter` ka web ya Windows implementation nahi hai, isliye un platforms par baaki app (login, home, cart, settings, theme, language) to chalti hai par Cashfree checkout screen kaam nahi karegi. Poora payment flow test karne ke liye Android par chalayein.

## Home screen aur delivery location

Home screen ka layout quick-commerce apps (Blinkit jaisa) ke pattern par hai:

```
┌──────────────────────────────┐  ← sticky header
│ ⚡ QuickKart              ⚙  │
│ Delivery in 12 minutes        │
│ 📍 Sector 12, Noida  ▾        │  ← tap → location sheet
│ [ 🔍 Search groceries…      ] │
├──────────────────────────────┤
│ 🛍️  🥬  🎧  👕  🍳  🧴  🍼   │  ← category tiles
│ [ hero banner ]               │
│ ┌────────┐ ┌────────┐         │
│ │ 15% OFF│ │        │         │  ← product cards
│ │  🍅    │ │  🥛    │         │
│ │⚡12 MINS│ │⚡12 MINS│        │
│ │Tomatoes│ │Amul Milk│        │
│ │₹38 ₹45 │ │₹29 ₹32 │        │
│ │  [ADD] │ │  [ADD] │         │
│ └────────┘ └────────┘         │
└──────────────────────────────┘
```

### Catalog — 30,020 products

`20250101000004_bulk_catalog.sql` har category ke liye **25 brands × 25 items × 8 variants = 5,000 SKUs** banati hai (6 categories = 30,000), plus pehle se maujood 20 curated products.

Rows database ke andar hi `CROSS JOIN` se generate hoti hain, isliye migration file chhoti rehti hai — 30,000 INSERT lines bhejne ki zaroorat nahi.

> Yeh naam brand × item combinations se bane hain (jaise "Amul Butter 500 g"), Blinkit ka asli catalog copy nahi kiya gaya — woh unka proprietary data hai.

**Itne saare products ke saath pagination zaroori hai:**

| Cheez | Kaise |
| --- | --- |
| Page size | 30 products, `SupabaseService.fetchProducts(page: n)` |
| Infinite scroll | List ke end se 600px pehle agla page load |
| Total count | PostgREST ke `Content-Range` se (`count: exact`) |
| Search | `search_text` generated column (`name + name_hi`) par GIN trigram index — ~250ms at 30k rows |
| Search debounce | 350ms, taaki har keystroke par query na chale |

> **Kabhi bhi `fetchProducts()` bina page ke poora catalog laane mat do.** PostgREST 1000 rows par cap kar deta hai aur UI ek saath 1000 cards banane lagta hai.

### Product images

`products.image_url` mein asli product photos hain (migration `20250101000003_product_images.sql`). Saari images **Wikimedia Commons** se hain — freely licensed, aur unka CDN `Access-Control-Allow-Origin: *` bhejta hai, isliye Flutter **web** par bhi load hoti hain (yeh zaroori hai, warna browser CORS block kar deta).

`ProductImage` widget (`lib/widgets/product_image.dart`) teen fallbacks handle karta hai, isliye card kabhi toota hua nahi dikhta:

| Situation | Kya dikhta hai |
| --- | --- |
| `image_url` null | `icon` emoji |
| Photo load ho rahi hai | Chhota progress spinner |
| Load fail (offline / 404 / CORS) | `icon` emoji |

> 20 mein se 19 products ki photo hai. "Face Wash" ke liye Commons par koi theek image nahi mili, isliye woh emoji par fallback karta hai — accha hai, isse fallback path live dikh bhi jaata hai.

**Location = State → District → Pincode.** Bas teen tap, koi lamba address form nahi:

```
┌──────────────────────────────┐   ┌──────────────────────────────┐   ┌──────────────────────────────┐
│ ←  Select state           ✕  │   │ ←  Select district        ✕  │   │ ←  Select pincode         ✕  │
│ 🔍 Search state              │   │ 📍 Uttar Pradesh             │   │ 📍 Uttar Pradesh › G.B.Nagar │
│                              │ → │ 🔍 Search district           │ → │ 🔍 Search pincode            │
│ SAVED                        │   │                              │   │                              │
│ 📍 Gautam Buddha Nagar,      │   │ 📍 Agra                    › │   │ ✉ 201301                     │
│    201301                    │   │ 📍 Aligarh                 › │   │ ✉ 201303                     │
│ STATE                        │   │ 📍 Ambedkar Nagar          › │   │ ✉ 201304                     │
│ 📍 Andhra Pradesh          › │   │ 📍 Gautam Buddha Nagar     › │   │ ✉ 201305                     │
└──────────────────────────────┘   └──────────────────────────────┘   └──────────────────────────────┘
```

Data Supabase ki `pincodes` table se aata hai — **35 states/UTs, 658 districts, 20,609 pincodes** — GeoNames ke free Indian postal dataset (CC BY 4.0) se, `20250101000006_pincodes.sql` mein.

- Header mein sabse chhoti line dikhti hai: `Gautam Buddha Nagar, 201301`
- Checkout ka address field is location se prefill hota hai (`District, State - Pincode`), ghar/gali user khud add karta hai
- Saved locations (max 8) pehle step par sabse upar, ek tap mein select
- Selection `SharedPreferences` mein rehti hai

Ab bhi **koi GPS permission ya external geocoding service nahi** — pincode data app ke apne Supabase backend mein hai, isliye web/Windows/Android teeno par same chalta hai.

> `pincode_states` aur `pincode_districts` views isliye hain kyunki PostgREST khud `DISTINCT` nahi kar sakta — inke bina dropdown ke liye poori 20k rows client tak aa jaatin.

## Settings, theme aur language

App ki default language **English** hai. Settings screen (Home/Admin ke top-right gear icon) mein teen cheezein hain:

| Setting | Options | Kahan save hota hai |
| --- | --- | --- |
| Theme | Light / Dark / System default | `SharedPreferences` (device par) |
| Notifications | Order updates on/off | `SharedPreferences` |
| Language | English / हिंदी | `SharedPreferences` |

Kuch details:

- **Theme** — `lib/theme/app_theme.dart` mein light aur dark dono `ThemeData` hain. Kisi bhi screen mein hardcoded color nahi hai; sab `ColorScheme` ya `AppPalette` (custom `ThemeExtension`) se aata hai, isliye dark mode har screen par sahi dikhta hai.
- **Language** — UI strings `lib/l10n/app_strings.dart` mein hain (English pehle, Hindi doosra). Product/category naam DB se aate hain: `name` English hai aur `name_hi` Hindi — language ke hisaab se sahi wala dikhta hai, Hindi missing ho to English par fallback. Search dono languages mein kaam karta hai.
- **Notifications** — abhi yeh **in-app alerts** control karta hai (order place hone par SnackBar). Push notifications wire nahi hain, kyunki is repo mein `android/` aur `ios/` folders hi nahi hain — pehle `flutter create .` chalana padega, phir FCM setup.

## Environment files

| File | Kiske liye | Git mein? |
| --- | --- | --- |
| `.env` | Flutter app — `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Nahi (gitignored) |
| `.env.example` | Upar wali file ka template | Haan |
| `supabase/functions/.env` | Edge Functions — Cashfree keys, `PROJECT_URL` | Nahi (gitignored) |
| `supabase/functions/.env.example` | Uska template | Haan |

Anon (publishable) key client app mein rehna safe hai — database ko RLS policies protect karti hain. **Service role key aur Cashfree secret key kabhi bhi `.env` (app wali) mein na daalein** — woh sirf Edge Function secrets mein rehti hain.

## Verify karein sab sahi se hua

```bash
supabase functions list      # teeno functions dikhni chahiye
supabase db diff             # empty aana chahiye (matlab db sync hai)
```
Dashboard -> Table Editor mein jaakar `products` table check karein (20 rows honi chahiye), aur `profiles` table (login ke baad aapka user dikhega).

## Login kaise kaam karta hai

1. Signup -> Supabase `auth.users` mein entry + trigger se `profiles` mein `role='customer'` row auto-create
2. Login -> app `profiles` se role padhta hai -> customer ko Home, admin ko Admin dashboard
3. Khud ko admin banane ke liye, SQL Editor mein ek baar run karein:
   ```sql
   update profiles set role = 'admin' where email = 'aapka-email@example.com';
   ```

## Troubleshooting — "Email not confirmed"

Supabase project mein by default **email confirmation ON** hoti hai. Matlab signup ke baad user ko pehle apne email par aaya link click karna padta hai, warna login `email_not_confirmed` (400) se fail hota hai.

Testing ke waqt yeh dikkat deta hai, kyunki Supabase ki built-in SMTP bahut rate-limited hai (kuch hi mails per hour) aur aksar Gmail tak pahunchti hi nahi.

**Option A — ek user ko manually confirm karein** (project ki security policy waisi hi rehti hai):

```bash
# service_role key: Dashboard -> Project Settings -> API
curl -X PUT "https://kxcfqlciuzkydixjprks.supabase.co/auth/v1/admin/users/<USER_ID>" \
  -H "apikey: <SERVICE_ROLE_KEY>" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"email_confirm": true}'
```

**Option B — Devtest project par email confirmation poori tarah band kar dein** (har naya test account turant login kar payega):

Dashboard -> Authentication -> Providers -> Email -> "Confirm email" off. Ya Management API se:

```bash
curl -X PATCH "https://api.supabase.com/v1/projects/kxcfqlciuzkydixjprks/config/auth" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"mailer_autoconfirm": true}'
```

> Yeh sirf Devtest par karein. Production project par email confirmation ON rehni chahiye, warna koi bhi kisi aur ka email daal kar account bana sakta hai.

## Testing

Sandbox mode mein Cashfree ke test cards use karein: https://www.cashfree.com/docs/payments/online/testing/test-payment

## Production checklist

- [ ] Sandbox mein poora payment flow test karne ke baad `CASHFREE_ENV=production` + live keys secrets mein set karein
- [ ] `supabase functions deploy` dobara chalayein production keys ke saath
- [ ] App icon, splash screen, store listing
- [ ] Real delivery/logistics flow
