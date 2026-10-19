# Sıfırdan Canlıya

Bir AI kod ajanıyla websitesini sıfırdan canlıya almak için skill'ler. Her rota aynı yerde biter: site **GitHub'dan yönetilir**. Değişiklik PR'la gelir, PR'da önizleme linki ya da Terraform planı görünür, `main`'e merge edilince otomatik olarak yayına çıkar.

Skill'ler açık [Agent Skills](https://agentskills.io) biçimindedir (`SKILL.md`): Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot ve bu biçimi okuyan diğer ajanlarla çalışır.

## Kurulum

**Herhangi bir ajan** ([skills CLI](https://github.com/vercel-labs/skills) ile; hangi ajanlara kurulacağını sorar):

```bash
npx skills add furkandogmus/sifirdan-canliya
```

**Claude Code** (plugin olarak):

```
/plugin marketplace add furkandogmus/sifirdan-canliya
/plugin install sifirdan-canliya@sifirdan-canliya
```

**Elle:** `skills/` altındaki klasörleri ajanınızın skill dizinine kopyalayın.

Başlamak için ajana "sifirdan-canliya skill'iyle başlayalım" deyin (Claude Code'da `/sifirdan-canliya`). Ya da doğrudan isteyin: "siteyi Netlify'da yayınla, GitHub'dan otomatik deploy olsun".

## Rotalar

| Rota | Ne zaman | Sıra |
|---|---|---|
| Netlify | En hızlı yol, sunucu yok | `arac-kontrol` → `github-cicd` → `netlify-yayin` |
| Cloudflare Pages | Netlify'ın kredi sınırı istenmiyorsa | `arac-kontrol` → `github-cicd` → `cloudflare-pages` |
| AWS S3 + CloudFront | AWS'de sunucusuz, en ucuz | `arac-kontrol` → `aws-hesap-guvenligi` → `github-cicd` → `aws-cicd-temeli` → `aws-statik-site` |
| AWS EC2 | Sunucu öğrenmek ya da sunucuda bir şey çalıştırmak | `arac-kontrol` → `aws-hesap-guvenligi` → `github-cicd` → `aws-cicd-temeli` → `aws-ec2-site` |

Ek olarak `alan-adi` (kendi domain'in), `iletisim-formu` (e-posta gönderen form), `supabase-veritabani` (veritabanı), bitişte `bulut-temizlik`. Rotalar birleşebilir: aynı `site/` klasörü hem Netlify'a hem AWS'ye yayınlanabilir.

## Skill'ler

| Skill | Ne yapar |
|---|---|
| `sifirdan-canliya` | Rehber: rotayı seçer, diğer skill'leri sıraya koyar |
| `arac-kontrol` | `gh`, `aws`, `netlify`, `supabase`, `terraform` kurulu ve giriş yapılmış mı |
| `aws-hesap-guvenligi` | SSO profili, root kontrolü, sıfır harcama bütçe alarmı, harcama sorgusu |
| `github-cicd` | Repo, `.gitignore`, Actions secret/değişkenleri, `main` koruması, kırmızı workflow teşhisi |
| `netlify-yayin` | Netlify + GitHub Actions: PR'da önizleme, merge'de production |
| `cloudflare-pages` | Cloudflare Pages + GitHub Actions: aynı akış, kredi sınırı yok |
| `alan-adi` | Domain'i Cloudflare DNS'e taşır, Netlify'a ve HTTPS'e bağlar, servisler için DNS kaydı ekler |
| `iletisim-formu` | Cloudflare Worker + Turnstile + Resend: kendi domain'inden e-posta gönderen form, Worker CI/CD'si |
| `aws-cicd-temeli` | Terraform state bucket'ı, GitHub OIDC, plan ve deploy rolleri (bir kere) |
| `aws-statik-site` | Private S3 + CloudFront (OAC), PR'da plan yorumu, merge'de apply + yayın |
| `aws-ec2-site` | EC2 + nginx, içerik S3'ten, önde CloudFront, SSH yerine SSM; aynı CD akışı |
| `supabase-veritabani` | Migration + RLS, tarayıcıdan supabase-js, migration'lar CI'dan |
| `bulut-temizlik` | Açılan her şeyin envanteri ve onaylı silinmesi |
| `turkiye-ucretsiz` | Şablonlara sabit yazılmış Türkiye ayarları ve her parçanın ücretsiz kalma koşulu |

## Resmî skill'leri de kurun

Bu repo akışı yönetir: hangi adım, hangi sırayla, nerede durulacak. Servislerin ayrıntısını sağlayıcıların kendi skill'leri daha iyi bilir. Birlikte kurun:

```bash
npx skills add cloudflare/skills          # Workers, Pages, wrangler, Turnstile
npx skills add supabase/agent-skills      # Supabase CLI, auth, RLS, Postgres
npx skills add resend/resend-skills       # E-posta gönderme, react-email
npx @netlify/skills@latest add --all      # Netlify deploy, functions
npx skills add vercel-labs/skills@find-skills   # ihtiyaç duyduğun yeni skill'i bul
```

## Ücretsiz eklentiler

| Ne | Servis | Ücretsiz |
|---|---|---|
| İletişim formu | Cloudflare Worker | Günde 100.000 istek (`iletisim-formu`) |
| Spam koruması | Cloudflare Turnstile | Sınırsız doğrulama |
| E-posta | Resend | Günde 100, ayda 3.000; kendi domain'i gerekir (`alan-adi`) |
| Ziyaretçi istatistiği | Cloudflare Web Analytics | Çerezsiz, ücretsiz |
| Site ayakta mı? | UptimeRobot | 50 monitör, 5 dakikada bir |
| Hata izleme | Sentry Developer | 5.000 hata |

Kaçının: Vercel Hobby ticari kullanıma kapalı; Better Stack'in uptime monitörü kart ister.

## Türkiye için, ücretsiz

Ayarlar şablonlara sabit yazılı, seçim yapmanız gerekmez:

| Ayar | Değer |
|---|---|
| AWS region | `eu-central-1` (Frankfurt) |
| CloudFront | `PriceClass_100`: Türkiye uç noktaları dahil, en ucuz sınıf |
| EC2 | `t3.micro`, 8 GB gp3, NAT Gateway yok (Free Tier) |
| Supabase | Central EU (Frankfurt) |
| Netlify | Ücretsiz plan kredi tabanlı: ayda 300 kredi, production deploy başına 15 |

Süresiz ücretsiz rota: Netlify ya da S3 + CloudFront (+ Supabase). Tek ücretli kalem isteğe bağlı domain (Türkiye'de .com, ilk yıl yaklaşık 100 ₺; yenileme ücretine bakın). Ayrıntı: `turkiye-ucretsiz`.

## AWS mimarisi

```
infra/bootstrap   (lokalde, bir kere)  state bucket · GitHub OIDC · plan rolü (salt okunur) · deploy rolü (sadece main)
infra/s3-site     (GitHub Actions)     private S3 · CloudFront + OAC
infra/ec2-site    (GitHub Actions)     EC2 + nginx · içerik bucket'ı · CloudFront · SG: 80 sadece CloudFront'tan

PR    → plan rolü   → terraform plan  → PR yorumu
merge → deploy rolü → terraform apply → içerik S3'e (EC2'de SSM ile sunucuya) → CloudFront invalidation
```

Kalıcı AWS anahtarı ya da SSH anahtarı hiçbir yerde tutulmaz.

## Gereksinimler

- GitHub hesabı ve `gh`
- Netlify rotası: Netlify hesabı, Node.js (`netlify-cli`)
- AWS rotaları: AWS hesabı, IAM Identity Center kullanıcısı, Terraform **1.10+**
- Supabase: Supabase hesabı

## Güvenlik notları

- Token ve şifreleri ajana yapıştırmayın; skill'ler bunları `gh secret set …` ile kendi terminalinizde girmenizi ister.
- Ajan kurulumu baştan sona kendisi yürütür: repo, PR, merge ve silme içermeyen Terraform planlarının apply'ı. Durup sadece iki durumda sorar: bir şey silinecekse ve ücretli bir kaynak (EC2) ilk kez kurulacaksa. Denemeler için ayrı ve boş bir AWS hesabı kullanın.
- Ajanınız her komut için izin soruyorsa, bu repoyla çalışırken `gh`, `git`, `terraform`, `netlify`, `aws` komutlarına izin verebilirsiniz (Claude Code'da `/permissions`).
- EC2 rotası Free plan kredisinden ya da 12 aylık Free Tier'dan düşer; süresiz ücretsiz değildir. Demo bitince `bulut-temizlik` çalıştırın.

## Lisans

MIT
