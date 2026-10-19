# Sıfırdan Canlıya

Bir AI kod ajanıyla (Claude Code ve benzerleri) websitesini sıfırdan canlıya almak için skill'ler. Her rota aynı yerde biter: site **GitHub'dan yönetilir**. Değişiklik PR'la gelir, PR'da önizleme linki ya da Terraform planı görünür, `main`'e merge edilince otomatik olarak yayına çıkar.

## Kurulum

Claude Code içinde:

```
/plugin marketplace add furkandogmus/sifirdan-canliya
/plugin install sifirdan-canliya@sifirdan-canliya
```

Sonra `/sifirdan-canliya` yazın: ajan ne yapmak istediğinizi sorar ve doğru sırayla ilerler. Skill'ler model tarafından da kendiliğinden çağrılır; "siteyi Netlify'da yayınla" demeniz yeterli.

Başka bir ajan kullanıyorsanız `skills/` altındaki klasörleri ajanınızın skill dizinine kopyalayın (Claude Code için `~/.claude/skills/`).

## Skill'ler

| Skill | Ne yapar |
|---|---|
| `sifirdan-canliya` | Rehber: rotayı seçer, diğer skill'leri sıraya koyar (sadece `/sifirdan-canliya` ile) |
| `arac-kontrol` | `gh`, `aws`, `netlify`, `supabase`, `terraform` kurulu ve giriş yapılmış mı |
| `aws-hesap-guvenligi` | SSO profili, root kontrolü, sıfır harcama bütçe alarmı, harcama sorgusu |
| `github-cicd` | Repo, `.gitignore`, Actions secret/değişkenleri, `main` koruması, kırmızı workflow teşhisi |
| `netlify-yayin` | Netlify sitesi + GitHub Actions: PR'da önizleme, merge'de production |
| `aws-statik-site` | S3 + CloudFront (private, OAC) Terraform ile; OIDC rolleri, PR'da plan yorumu, merge'de apply + yayın |
| `supabase-veritabani` | Migration + RLS, tarayıcıdan supabase-js, migration'lar CI'dan |
| `bulut-temizlik` | Açılan her şeyin envanteri ve onaylı silinmesi |

## Rotalar

```
Netlify:  arac-kontrol → github-cicd → netlify-yayin
AWS:      arac-kontrol → aws-hesap-guvenligi → github-cicd → aws-statik-site
Ek:       + supabase-veritabani
Bitiş:    bulut-temizlik
```

## AWS mimarisi

```
infra/bootstrap   (lokalde, bir kere)   state bucket · GitHub OIDC · plan rolü (salt okunur) · deploy rolü (sadece main)
infra/site        (GitHub Actions)      private S3 · CloudFront + OAC · bucket policy   — state: S3, kilit: use_lockfile

PR    → plan rolü   → terraform plan → PR yorumu
merge → deploy rolü → terraform apply → s3 sync → CloudFront invalidation
```

Kalıcı AWS anahtarı hiçbir yerde tutulmaz.

## Gereksinimler

- GitHub hesabı ve `gh`
- Netlify rotası: Netlify hesabı, Node.js (`netlify-cli`)
- AWS rotası: AWS hesabı, IAM Identity Center kullanıcısı, Terraform **1.10+**
- Supabase: Supabase hesabı

## Güvenlik notları

- Token ve şifreleri ajana yapıştırmayın; skill'ler sizden `! gh secret set …` ile kendi terminalinizde girmenizi ister.
- Ajan kalıcı bir şey kuran ya da silen her komuttan önce onay ister. Kendi hesabınızda otomatik onay modunu açmadan önce düşünün; denemeler için ayrı ve boş bir hesap kullanın.
- Demo bitince `bulut-temizlik` çalıştırın.

## Lisans

MIT
