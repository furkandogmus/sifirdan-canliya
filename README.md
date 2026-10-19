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
| AWS S3 + CloudFront | AWS'de sunucusuz, en ucuz | `arac-kontrol` → `aws-hesap-guvenligi` → `github-cicd` → `aws-cicd-temeli` → `aws-statik-site` |
| AWS EC2 | Sunucu öğrenmek ya da sunucuda bir şey çalıştırmak | `arac-kontrol` → `aws-hesap-guvenligi` → `github-cicd` → `aws-cicd-temeli` → `aws-ec2-site` |

Ek olarak `supabase-veritabani` (veritabanı), bitişte `bulut-temizlik`. Rotalar birleşebilir: aynı `site/` klasörü hem Netlify'a hem AWS'ye yayınlanabilir.

## Skill'ler

| Skill | Ne yapar |
|---|---|
| `sifirdan-canliya` | Rehber: rotayı seçer, diğer skill'leri sıraya koyar |
| `arac-kontrol` | `gh`, `aws`, `netlify`, `supabase`, `terraform` kurulu ve giriş yapılmış mı |
| `aws-hesap-guvenligi` | SSO profili, root kontrolü, sıfır harcama bütçe alarmı, harcama sorgusu |
| `github-cicd` | Repo, `.gitignore`, Actions secret/değişkenleri, `main` koruması, kırmızı workflow teşhisi |
| `netlify-yayin` | Netlify + GitHub Actions: PR'da önizleme, merge'de production |
| `aws-cicd-temeli` | Terraform state bucket'ı, GitHub OIDC, plan ve deploy rolleri (bir kere) |
| `aws-statik-site` | Private S3 + CloudFront (OAC), PR'da plan yorumu, merge'de apply + yayın |
| `aws-ec2-site` | EC2 + nginx, içerik S3'ten, önde CloudFront, SSH yerine SSM; aynı CD akışı |
| `supabase-veritabani` | Migration + RLS, tarayıcıdan supabase-js, migration'lar CI'dan |
| `bulut-temizlik` | Açılan her şeyin envanteri ve onaylı silinmesi |

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
- Ajan kalıcı bir şey kuran ya da silen her komuttan önce onay ister. Ajanın otomatik onay modunu açmadan önce düşünün; denemeler için ayrı ve boş bir AWS hesabı kullanın.
- EC2 rotası birkaç dolar/ay tutar (instance, disk, public IPv4). Demo bitince `bulut-temizlik` çalıştırın.

## Lisans

MIT
