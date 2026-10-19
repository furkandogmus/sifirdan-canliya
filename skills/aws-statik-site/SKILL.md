---
name: aws-statik-site
description: Statik bir siteyi AWS'de S3 + CloudFront (private bucket, OAC, HTTPS) üzerinde Terraform ile kurar ve GitHub Actions'la sürekli teslimata bağlar - PR'da terraform plan yorumu, main'e merge'de apply + içerik yükleme, anahtarsız OIDC. "AWS'de yayınla", "S3 + CloudFront", "terraform ci/cd" istendiğinde ya da CloudFront 403 / eski içerik sorununda kullan.
---

# AWS'de statik site: Terraform + GitHub Actions

Ön koşullar, sırayla: `arac-kontrol` (`aws`, `terraform` **1.10 veya üstü**, `gh`), `aws-hesap-guvenligi` (SSO profili ve bütçe alarmı), `github-cicd` adım 1 (repo push edilmiş). Bütçe alarmı yoksa önce onu kur.

## Mimari

İki Terraform katmanı, iki farklı sahip:

| Katman | Ne kurar | Kim çalıştırır | State |
|---|---|---|---|
| `infra/bootstrap` | State bucket'ı, GitHub OIDC provider, `plan` (salt okunur) ve `deploy` rolleri | Kullanıcı, lokalde, **bir kere** | Lokal dosya |
| `infra/site` | Private S3 bucket, CloudFront + OAC, bucket policy | GitHub Actions, her merge'de | S3 (bootstrap'in bucket'ı) |

Akış: PR açılır → `plan` rolüyle `terraform plan`, sonucu PR'a yorum → merge → `deploy` rolüyle `terraform apply`, `site/` S3'e yüklenir, CloudFront önbelleği temizlenir. Kalıcı AWS anahtarı hiçbir yerde yok.

Bu skill'in `templates/` klasöründen kopyala:
- `templates/bootstrap/*.tf` → `infra/bootstrap/`
- `templates/site/*.tf` → `infra/site/`
- `templates/workflows/aws.yml` → `.github/workflows/aws.yml`

`.gitignore`'da `.terraform/`, `*.tfstate*`, `tfplan` olduğunu kontrol et. Bootstrap state'i lokal kalır: kullanıcıya bu klasörü silmemesini söyle; silinirse bootstrap kaynakları Terraform'dan kopar ve elle silinir.

## 1. Bootstrap (lokal, bir kere)

```bash
export AWS_PROFILE=demo
aws sts get-caller-identity
aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text
```

Çıktıda `token.actions.githubusercontent.com` varsa `create_oidc_provider=false` kullan (hesap başına bir tane olabilir).

```bash
cd infra/bootstrap
terraform init
terraform plan -out tfplan \
  -var project=<proje> \
  -var github_repo=<sahip>/<repo> \
  -var create_oidc_provider=<true|false>
```

Planı özetle (beklenen: state bucket ve 3 ayarı, OIDC provider, 2 rol, 2 politika). Onay gelince `terraform apply tfplan`.

## 2. GitHub değişkenleri

```bash
gh variable set PROJECT --body "<proje>"
gh variable set AWS_REGION --body "$(terraform output -raw region)"
gh variable set TF_STATE_BUCKET --body "$(terraform output -raw state_bucket)"
gh variable set AWS_PLAN_ROLE_ARN --body "$(terraform output -raw plan_role_arn)"
gh variable set AWS_DEPLOY_ROLE_ARN --body "$(terraform output -raw deploy_role_arn)"
gh variable list
```

Hepsi değişken; gizli değiller. `github-cicd` adım 3 ile `main`'i koru.

## 3. İlk teslimat

`infra/site` ve workflow'u bir PR ile gönder:

```bash
git checkout -b aws-altyapi
git add infra .github .gitignore site
git commit -m "S3 + CloudFront altyapısı ve CD"
git push -u origin aws-altyapi
gh pr create --fill
gh pr checks --watch
```

PR'daki plan yorumunu kullanıcıyla oku: `Plan: 5 to add, 0 to change, 0 to destroy` beklenir. Onaylarsa:

```bash
gh pr merge --squash --delete-branch
gh run watch
```

İlk apply'da CloudFront dağıtımı 5–10 dakika sürer. Workflow özetinde (`gh run view`) "Yayında: https://…cloudfront.net" satırı çıkar.

## 4. Sonraki değişiklikler

- İçerik (`site/**`) ya da altyapı (`infra/site/**`) değişikliği → PR → plan yorumu → merge → otomatik yayın.
- Lokalde plan görmek istenirse:
  ```bash
  cd infra/site
  terraform init -backend-config="bucket=<state-bucket>" -backend-config="region=<region>"
  terraform plan -var project=<proje> -lock=false
  ```
  Lokalde `apply` çalıştırma; tek yazar CI'dır, iki yazar state'i karıştırır.

## Sorun giderme

| Belirti | Sebep | Çözüm |
|---|---|---|
| `Could not assume role` | Güven koşulu repo/dal ile tutmuyor | Bootstrap'te `github_repo` doğru mu; deploy rolü sadece `main`'e güvenir |
| `AccessDenied` apply'da | Deploy rolü sadece `<proje>-site-*` bucket'larına yazabilir | `PROJECT` değişkeni bootstrap'teki `project` ile aynı mı |
| `Unsupported argument use_lockfile` | Terraform 1.10'dan eski | `brew install hashicorp/tap/terraform` ya da workflow'daki sürüm |
| 403 kök adreste | `site/index.html` yok | Dosya adını kontrol et |
| 403 her yerde, ilk dakikalarda | Dağıtım hâlâ kuruluyor | `aws cloudfront get-distribution --id <id> --query Distribution.Status` → `Deployed` |
| Eski içerik | Önbellek | Workflow invalidation yapıyor; tarayıcı önbelleği için gizli sekme |
| Alt sayfa 403 | S3 dizin indeksi yapmaz | Bağlantılar `hakkinda.html` biçiminde |

## Özel domain (istenirse)

CloudFront'un sertifikası **us-east-1**'deki ACM'den gelir; başka region'da açılan sertifika görünmez. `infra/site`'a ikinci bir `provider "aws" { alias = "us_east_1" region = "us-east-1" }`, `aws_acm_certificate` (DNS doğrulama), dağıtıma `aliases` ve `viewer_certificate { acm_certificate_arn = …, ssl_support_method = "sni-only" }` eklenir; deploy rolüne `acm:*` izni gerekir. DNS kaydı domain'in yönetildiği yerde CloudFront adresine CNAME/ALIAS olarak verilir.

## Silme

Sıra önemli: önce site, sonra bootstrap (site state'i bootstrap'in bucket'ında durur).

```bash
cd infra/site
terraform init -backend-config="bucket=<state-bucket>" -backend-config="region=<region>"
terraform plan -destroy -var project=<proje>
```

Listeyi göster, onay alınca `terraform destroy -var project=<proje>`. Sonra `cd ../bootstrap`, aynı şekilde `plan -destroy` → onay → `destroy` (aynı `-var` değerleriyle). Workflow'u da silmek için `.github/workflows/aws.yml`'i kaldıran bir PR aç; yoksa sonraki merge siteyi yeniden kurmaya çalışır ve rol olmadığı için kırmızı olur.

## Kullanıcıya teslim

Canlı URL, repo URL'i, akışın tek cümlelik özeti (PR = plan, merge = yayın), GitHub değişkenlerinin listesi ve silme sırası.
