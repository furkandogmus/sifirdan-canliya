---
name: iletisim-formu
description: Statik siteye sunucusuz, ücretsiz bir iletişim formu ekler - Netlify Forms (tuzak alanı ve spam filtresiyle), aynı formun S3/EC2/Cloudflare kopyalarında da çalışması, e-posta bildirimi; domain'i olanlar için Resend + Turnstile yolu. "iletişim formu", "form", "bize yaz", "mesaj gönder", "resend", "turnstile" geçtiğinde kullan.
---

# İletişim formu

Varsayılan yol **Netlify Forms**: kod yok, sunucu yok, ücretsiz planda gönderim sınırı yok, domain gerekmez. Site Netlify'da yayında olmalı (`netlify-yayin`); başka yerlerdeki kopyalar da gönderimi Netlify'a yollar.

## 1. Form algılamayı aç

Yeni Netlify sitelerinde kapalı gelir. Bir kere:

```bash
netlify api updateSite --data '{"site_id":"<site-id>","body":{"processing_settings":{"ignore_html_forms":false}}}' \
  | jq '.processing_settings.ignore_html_forms'      # false olmalı
```

## 2. Form

Statik HTML'de durmalı (JavaScript ile çizilen form algılanmaz). Astro, Hugo, düz HTML: hepsinde aynı.

```html
<form name="iletisim" method="POST" action="/tesekkurler.html"
      data-netlify="true" netlify-honeypot="adres">
  <input type="hidden" name="form-name" value="iletisim" />
  <p hidden><label>Bunu doldurma: <input name="adres" tabindex="-1" autocomplete="off" /></label></p>
  <input name="isim" required maxlength="60" />
  <input name="eposta" type="email" maxlength="120" />
  <textarea name="mesaj" required maxlength="2000"></textarea>
  <button type="submit">Gönder</button>
</form>
```

Kurallar, hepsi testte doğrulandı:
- **`action` göreli olmalı** (`/` ile başlar). Tam adres (`https://…`) yazılırsa Netlify formu kaydetmez ve gönderimler kaybolur.
- `name` alanları Netlify'da sütun olur; sonradan değiştirmek yeni bir alan açar.
- `netlify-honeypot` alanını dolduran gönderim sessizce atılır: bot "200" alır ama kayıt oluşmaz.
- `/tesekkurler.html` sayfasını da oluştur.

## 3. Başka yerlerdeki kopyalar (S3, EC2, Cloudflare Pages)

Aynı HTML başka bir adreste açıldığında göreli `action` o sunucuya gider ve kaybolur. Formun altına:

```html
<script>
  const formSite = "https://<site-adi>.netlify.app";
  if (location.origin !== formSite) {
    document.querySelector('form[name="iletisim"]').action = formSite + "/tesekkurler.html";
  }
</script>
```

Netlify HTML'i göreli adresle görür ve formu kaydeder; diğer kopyalarda tarayıcı gönderimi Netlify'a yollar.

## 4. Yayınla ve doğrula

Değişikliği PR ile gönder (`github-cicd`), merge sonrası:

```bash
netlify api listSiteForms --data '{"site_id":"<site-id>"}' | jq '.[] | {name, fields: [.fields[].name]}'
curl -s -o /dev/null -w '%{http_code}\n' -X POST "https://<site-adi>.netlify.app/tesekkurler" \
  -d 'form-name=iletisim&isim=Test&mesaj=deneme&adres='
netlify api listSiteSubmissions --data '{"site_id":"<site-id>"}' | jq '.[] | {id, data}'
```

Formun listede, test gönderiminin kayıtlarda görünmesi = bitti. Test gönderimini sil:

```bash
netlify api deleteSubmission --data '{"submission_id":"<id>"}'
```

## 5. E-posta bildirimi

Netlify'ın kendi bildirimi ücretsizdir, domain gerekmez. Kullanıcıya panelden açmasını söyle: site › **Project configuration › Notifications › Emails and webhooks › Form submission notifications › Add notification › Email notification**. Bildirim kullanıcının e-postasına gider; bu bir hesap ayarıdır, kullanıcı kendisi seçer.

## Kendi e-postanla: Resend + Turnstile

Ziyaretçiye otomatik cevap ya da kendi tasarımın olan bir e-posta istenirse. Önce kullanıcıya iki şartı söyle:

| Şart | Neden |
|---|---|
| Kendi domain'i | Resend domain doğrulanmadan sadece hesap sahibinin adresine gönderir. Domain ücretlidir: "tamamen ücretsiz" kurulumun dışında kalır |
| Bir fonksiyon | Resend API anahtarı ve Turnstile doğrulaması tarayıcıda yapılamaz |

Akış: form → Cloudflare Worker ya da Supabase Edge Function (ikisi de ücretsiz) → Turnstile token'ını `https://challenges.cloudflare.com/turnstile/v0/siteverify` ile doğrula → Resend API ile gönder. Ücretsiz limitler: Resend günde 100, ayda 3.000 e-posta; Turnstile sınırsız doğrulama.

Ayrıntı için resmî skill'ler: `npx skills add resend/resend-skills` ve `npx skills add cloudflare/skills` (Turnstile ve Workers). Anahtarlar `gh secret set` / `wrangler secret put` ile girilir, koda yazılmaz.

## Kullanıcıya teslim

Form adresi, gönderimlerin nerede görüleceği (Netlify › Forms ya da `listSiteSubmissions`), bildirimin nasıl açılacağı.
