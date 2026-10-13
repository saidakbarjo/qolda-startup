# Qoʻlda — sayt va admin panel

Bitta fayl: `index.html` (sayt + admin panel + backend qatlami).
Admin panel: `sayt-manzili/#admin`.

## Backend qanday tanlanadi

| Holat | Qayerda saqlanadi | Kim ariza yubora oladi |
|---|---|---|
| `CONFIG` da Supabase kalitlari bor | Supabase (Postgres) | Istalgan tashrifchi |
| claude.ai artifact sifatida ochilgan | Artifact ichki bazasi | claude.ai ga kirgan, sahifaga ruxsati bor foydalanuvchi |
| Kalitlarsiz oʻz hostingda | Shu brauzer (demo) | Faqat sinov uchun |

## Oʻz domeningizga joylash (GitHub Pages + Supabase)

1. **Supabase loyihasi** — supabase.com → New project.
2. **Jadval va himoya** — SQL Editor → `supabase-schema.sql` ni toʻliq qoʻyib, Run.
3. **Admin hisobi** — Authentication → Users → Add user (email + parol).
   Keyin SQL Editor’da:
   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'sizning@email.uz';
   ```
4. **Kalitlar** — Project Settings → API: `Project URL` va `anon public` kalitni
   `qolda.html` ichidagi `CONFIG` ga yozing:
   ```js
   const CONFIG = {
     SUPABASE_URL: "https://xxxx.supabase.co",
     SUPABASE_ANON_KEY: "eyJhbGciOi..."
   };
   ```
   `anon` kalit ochiq boʻlishi normal — maʼlumotlar RLS siyosatlari bilan himoyalangan:
   tashrifchi faqat yangi ariza qoʻsha oladi, oʻqish/oʻzgartirish faqat `admins` jadvalidagilar uchun.
   **`service_role` kalitni hech qachon saytga qoʻymang.**
5. **Fayl** — `qolda.html` ni `index.html` deb nomlang va boshiga quyidagini qoʻshing
   (artifact buni avtomatik qoʻshadi, oʻz hostingda esa kerak):
   ```html
   <!doctype html><html lang="uz"><head><meta charset="utf-8">
   <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
   </head><body>
   ```
   oxiriga esa `</body></html>`.
6. **GitHub Pages** — repo → Settings → Pages → Branch: `master` / root.
7. Tekshirish: saytda ariza qoldiring → `/#admin` → email/parol bilan kiring.

## Ariza maydonlari

- **Buyurtmachi**: ism, telefon, tuman, **ish turi** (mebel yigʻish, kichik taʼmirlash, navbatda turish, bogʻ ishlari, yuk koʻtarish, tozalash, boshqa), **ish tavsifi** va **taklif narxi** (10 000 – 10 000 000 soʻm).
- **Ijrochi**: ism, telefon, tuman, bajara oladigan ishlar (koʻnikmalar).

Avvalgi versiyadagi `supabase-schema.sql` ni ishga tushirgan boʻlsangiz, yangisini qayta ishga tushiring: u yangi ustunlarni (`category`, `task`, `price`) qoʻshadi, mavjud maʼlumotlarga tegmaydi.

## Admin panel imkoniyatlari

- **Umumiy koʻrinish**: jami arizalar, ijrochilar maqsadga nisbatan, buyurtmachilar,
  oʻqilmagan xabarlar, oʻrtacha narx va buyurtmalar summasi, ish turlari boʻyicha soni va oʻrtacha narxi, 14 kunlik grafik, tumanlar, holatlar, soʻnggi arizalar.
- **Arizalar**: qidiruv, rol/holat/ish turi boʻyicha filtr, ish turi, tavsif va narx ustunlari, holatni oʻzgartirish
  (Yangi → Bogʻlanildi → Tasdiqlandi / Rad etildi), izoh, oʻchirish (ikki bosqichli), CSV eksport.
- **Xabarlar**: «Aloqa» formasidan kelgan xabarlar, oʻqildi belgisi, oʻchirish.
- **Sozlamalar**: saytdagi sariq eʼlon (UZ/RU), arizalarni ochish/yopish,
  telefon va Telegram (saytda chiqadi), ijrochilar maqsadi raqami.

## Keyingi qadamlar (tavsiya)

- Spamdan himoya: Supabase’da Cloudflare Turnstile yoki Edge Function orqali captcha.
- Yangi ariza haqida Telegram-botga xabar: Supabase Database Webhook → Edge Function → Telegram Bot API.
