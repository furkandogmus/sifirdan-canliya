---
name: sifirdan-canliya
description: Bir websitesini sıfırdan canlıya, GitHub'dan yönetilen otomatik deploy ile alma rehberi; hangi skill'in hangi adımda kullanılacağını sıralar. Kullanıcı "/sifirdan-canliya" yazdığında çalışır.
disable-model-invocation: true
---

# Sıfırdan canlıya

Kullanıcıya ne yapmak istediğini sor ve aşağıdaki rotalardan birini öner. Her adımı ilgili skill'le yürüt; bir adımın "bitti" koşulu sağlanmadan sonrakine geçme.

Her rotanın sonu aynı: site GitHub'dan yönetilir. Değişiklik PR'la gelir, PR'da önizleme ya da plan görülür, `main`'e merge edilince otomatik yayına çıkar.

## Rotalar

**Netlify (en hızlı):**
1. `arac-kontrol`: `gh`, `netlify`.
2. `github-cicd`: repo ve `main` koruması.
3. `netlify-yayin`: site, ilk yayın, Actions bağlantısı, PR önizleme akışı.

**AWS (S3 + CloudFront, Terraform):**
1. `arac-kontrol`: `aws`, `terraform` ≥ 1.10, `gh`.
2. `aws-hesap-guvenligi`: SSO profili, bütçe alarmı. Alarm kurulmadan altyapı kurulmaz.
3. `github-cicd`: repo ve `main` koruması.
4. `aws-statik-site`: bootstrap (state, OIDC, roller), GitHub değişkenleri, PR'da plan, merge'de apply + yayın.

**Dinamik parça:** herhangi bir rotanın üstüne `supabase-veritabani` (ziyaretçi defteri, form; migration'lar da CI'dan).

**Bitiş:** iş bir demoysa `bulut-temizlik`: envanter, onay, silme.

## Her rotada geçerli

- Her bulut kaynağı `project=<proje-adı>` etiketi taşır; varsayılan proje adı `demo`.
- Kalıcı bir şey kuran ya da silen her komuttan önce komutu göster ve onay bekle.
- Token, şifre ve anahtarları kullanıcı kendi terminalinde girer (`! gh secret set …`); sohbete yapıştırılmaz.
- Bitirirken kullanıcıya ver: canlı URL, repo URL'i, oluşturulan kaynakların listesi, silme yolu.
